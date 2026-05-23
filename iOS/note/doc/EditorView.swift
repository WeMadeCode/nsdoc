//
//  Editor2View.swift
//  note
//
//  Created by 倪申雷 on 2025/7/11.
//

import SwiftUI
import SwiftData

struct EditorView: View {
    
    let showsCloseButton: Bool
    let autoFocusOnLoad: Bool
    
    @StateObject var viewModel = EditorViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var workingDocument: Document?
    @State private var initialContentJSON: String?
    @State private var isKeyboardShow: Bool = false
    @State private var keyboardHeight: CGFloat = 336
    @State private var didApplyInitialContent = false
    @State private var isSaving = false
    @State private var didRecordAccess = false
    @State var javaScriptCommand: JavaScriptCommand? = nil
    @Environment(\.dismiss) var dismiss

    init(
        document: Document?,
        initialContentJSON: String? = nil,
        showsCloseButton: Bool = true,
        autoFocusOnLoad: Bool = false
    ) {
        self.showsCloseButton = showsCloseButton
        self.autoFocusOnLoad = autoFocusOnLoad
        _workingDocument = State(initialValue: document)
        _initialContentJSON = State(initialValue: initialContentJSON)
    }
    
    var body: some View {
        NavigationStack {
            mainView
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            if showsCloseButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        closeEditor()
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    flushEditorContent()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { noti in
            if
                let frame = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                frame.height > 0
            {
                keyboardHeight = frame.height
            }
            isKeyboardShow = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { noti in
            isKeyboardShow = false
        }
        .task {
            recordDocumentAccessIfNeeded()
        }
    }
    
    private var mainView: some View {
        VStack {
            if let editorURL = Self.editorURL {
                SLWebView(
                    url: editorURL,
                    javaScriptCommand: $javaScriptCommand,
                    viewModel: viewModel,
                    customKeyboardHeight: keyboardHeight
                ) {
                } bridgeReady: {
                    applyInitialContentIfNeeded()
                } contentChanged: { snapshot in
                    saveContentSnapshot(snapshot)
                } toolsUpdate: { activeTools, selectionContext in
                    viewModel.updateSelected(activeTools: activeTools, selectionContext: selectionContext)
                }
            } else {
                Text("文档编辑器资源未找到")
                    .foregroundStyle(.secondary)
            }

            Spacer()
            if isKeyboardShow || viewModel.isCustomKeyboardVisible {
                Tools(
                    javaScriptCommand: $javaScriptCommand,
                    viewModel: viewModel,
                    isSystemKeyboardVisible: isKeyboardShow,
                    keyboardHeight: keyboardHeight
                )
            }
        }
    }

    private static var editorURL: URL? {
        URL(string: "http://localhost:5173/")
    }

    private func applyInitialContentIfNeeded() {
        guard !didApplyInitialContent else {
            return
        }
        didApplyInitialContent = true

        let contentObject = contentObject(from: initialContentJSON ?? loadContentJSON()) ?? NSNull()

        initialContentJSON = nil

        javaScriptCommand = JavaScriptCommand(
            methodName: "setContent",
            params: [
                "content": contentObject,
                "focus": autoFocusOnLoad
            ],
            timeout: 3
        )
    }

    private func flushEditorContent() {
        Task {
            await flushEditorContentAsync()
        }
    }

    private func closeEditor() {
        Task { @MainActor in
            await flushEditorContentAsync()
            await waitForCurrentSave()
            dismiss()
        }
    }

    @MainActor
    private func recordDocumentAccessIfNeeded() {
        guard !didRecordAccess, let workingDocument else {
            return
        }

        didRecordAccess = true
        workingDocument.accessedAt = Date()

        do {
            try modelContext.save()
        } catch {}
    }

    @MainActor
    private func waitForCurrentSave() async {
        while isSaving {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    @MainActor
    private func flushEditorContentAsync() async {
        do {
            _ = try await requestJavaScriptResult(methodName: "flushContent", timeout: 3)
        } catch {
        }
    }

    @MainActor
    private func saveContentSnapshot(_ snapshot: EditorContentSnapshot) {
        guard !isSaving else {
            return
        }

        isSaving = true
        defer {
            isSaving = false
        }

        do {
            guard let contentJSONResult = contentJSONString(from: snapshot.content) else {
                return
            }

            let saveResult: Document
            if let workingDocument {
                saveResult = workingDocument
            } else {
                saveResult = try makeNewDocument()
                workingDocument = saveResult
            }

            saveResult.title = snapshot.title
            saveContentJSON(contentJSONResult, for: saveResult)
            saveResult.contentVersion += 1
            saveResult.updatedAt = Date()
            saveResult.syncStatus = DocumentSyncStatus.pendingUpload

            try modelContext.save()
        } catch {
        }
    }

    @MainActor
    private func requestJavaScriptResult(methodName: String, params: [String: Any]? = nil, timeout: TimeInterval = 2) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            javaScriptCommand = JavaScriptCommand(methodName: methodName, params: params, timeout: timeout) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func contentJSONString(from result: Any?) -> String? {
        guard let result else {
            return nil
        }

        guard JSONSerialization.isValidJSONObject(result) else {
            return nil
        }

        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: result),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return nil
        }

        return jsonString
    }

    private func contentObject(from jsonString: String?) -> Any? {
        guard
            let jsonString,
            let data = jsonString.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data)
        else {
            return nil
        }

        return object
    }

    private func loadContentJSON() -> String? {
        guard let document = workingDocument else {
            return nil
        }

        do {
            return try fetchContent(for: document)?.contentJSON
        } catch {
            return nil
        }
    }

    private func makeNewDocument() throws -> Document {
        let folder = try DefaultFolderService.findOrCreateDefaultFolder(in: modelContext)
        let now = Date()
        let document = Document(
            folderId: folder.id,
            createdAt: now,
            updatedAt: now,
            accessedAt: now
        )
        modelContext.insert(document)
        return document
    }

    private func saveContentJSON(_ contentJSON: String, for document: Document) {
        do {
            if let content = try fetchContent(for: document) {
                content.contentJSON = contentJSON
                return
            }
        } catch {}

        let content = DocumentContent(
            documentId: document.id,
            contentFormat: DocumentContentFormat.tiptapJSON,
            contentJSON: contentJSON
        )
        modelContext.insert(content)
    }

    private func fetchContent(for document: Document) throws -> DocumentContent? {
        let documentId = document.id
        var descriptor = FetchDescriptor<DocumentContent>(
            predicate: #Predicate { content in
                content.documentId == documentId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

}

#Preview {
}
