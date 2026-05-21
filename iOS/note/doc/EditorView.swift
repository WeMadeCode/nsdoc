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
    
    @StateObject var viewModel = EditorViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var workingDocument: Document?
    @State private var initialContentJSON: String?
    @State private var isKeyboardShow: Bool = false
    @State private var didApplyInitialContent = false
    @State private var isDirty = false
    @State private var isSaving = false
    @State private var didRecordAccess = false
    @State private var editorChangeVersion = 0
    @State private var autosaveTask: Task<Void, Never>?
    @State var javaScriptCommand: JavaScriptCommand? = nil
    @Environment(\.dismiss) var dismiss

    init(document: Document?, initialContentJSON: String? = nil, showsCloseButton: Bool = true) {
        self.showsCloseButton = showsCloseButton
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
                    saveInfo(cancelPendingAutosave: true)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { noti in
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
                SLWebView(url: editorURL, javaScriptCommand: $javaScriptCommand) {
                } bridgeReady: {
                    applyInitialContentIfNeeded()
                } contentChanged: {
                    scheduleAutosave()
                } toolsUpdate: { activeTools in
                    viewModel.updateSelected(activeTools: activeTools)
                }
            } else {
                Text("文档编辑器资源未找到")
                    .foregroundStyle(.secondary)
            }

            Spacer()
            if isKeyboardShow {
                Tools(javaScriptCommand: $javaScriptCommand, viewModel: viewModel)
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

        guard
            let content = initialContentJSON ?? loadContentJSON(),
            let contentObject = jsonObject(from: content)
        else {
            return
        }

        initialContentJSON = nil

        javaScriptCommand = JavaScriptCommand(
            methodName: "setContent",
            params: [
                "content": contentObject,
                "focus": false
            ],
            timeout: 3
        )
    }

    private func scheduleAutosave() {
        editorChangeVersion += 1
        isDirty = true
        restartAutosaveTimer()
    }

    private func restartAutosaveTimer() {
        autosaveTask?.cancel()
        autosaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 900_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            await saveInfoAsync()
        }
    }

    private func saveInfo(cancelPendingAutosave: Bool = false) {
        if cancelPendingAutosave {
            autosaveTask?.cancel()
            autosaveTask = nil
        }

        Task {
            await saveInfoAsync()
        }
    }

    private func closeEditor() {
        autosaveTask?.cancel()
        autosaveTask = nil

        Task { @MainActor in
            await waitForCurrentSave()
            if isDirty {
                await saveInfoAsync()
            }
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
    private func saveInfoAsync() async {
        guard !isSaving else {
            return
        }

        let saveVersion = editorChangeVersion
        isSaving = true

        do {
            let titleResult = try await requestJavaScriptResult(methodName: "getTitle", timeout: 3) as? [String: Any]
            let contentResult = try await requestJavaScriptResult(methodName: "getContent", timeout: 3) as? [String: Any]
            let contentJSONResult = contentJSONString(from: contentResult?["content"])
            let plainTextResult = contentResult?["plainText"] as? String

            let saveResult: Document
            if let workingDocument {
                saveResult = workingDocument
            } else {
                saveResult = try makeNewDocument()
                workingDocument = saveResult
            }

            if let title = titleResult?["title"] as? String {
                saveResult.title = title
            }
            if let contentJSONResult {
                saveContentJSON(contentJSONResult, for: saveResult)
                let plainText = plainTextResult ?? extractPlainText(from: contentJSONResult)
                saveResult.plainText = plainText
                saveResult.excerpt = String(plainText.prefix(120))
                saveResult.contentVersion += 1
            }
            saveResult.updatedAt = Date()
            saveResult.syncStatus = DocumentSyncStatus.pendingUpload

            try modelContext.save()
            if editorChangeVersion == saveVersion {
                isDirty = false
            } else {
                isDirty = true
                restartAutosaveTimer()
            }
        } catch {
        }

        isSaving = false
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

    private func jsonObject(from jsonString: String) -> Any? {
        guard
            let data = jsonString.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data)
        else {
            return nil
        }

        return object
    }

    private func loadContentJSON() -> String? {
        guard let document = workingDocument else {
            return DocumentContentDefaults.emptyTiptapJSON
        }

        do {
            return try fetchContent(for: document)?.contentJSON ?? DocumentContentDefaults.emptyTiptapJSON
        } catch {
            return DocumentContentDefaults.emptyTiptapJSON
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

    private func extractPlainText(from contentJSON: String) -> String {
        guard
            let data = contentJSON.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data)
        else {
            return ""
        }

        var textParts: [String] = []

        func collectText(from value: Any) {
            if let dictionary = value as? [String: Any] {
                if let text = dictionary["text"] as? String {
                    textParts.append(text)
                }
                dictionary.values.forEach { collectText(from: $0) }
                return
            }

            if let array = value as? [Any] {
                array.forEach { collectText(from: $0) }
            }
        }

        collectText(from: object)
        return textParts.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
}
