//
//  Editor2View.swift
//  note
//
//  Created by 倪申雷 on 2025/7/11.
//

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import UIKit

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
    @State private var isImagePickerPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var didReceiveImagePickerSelection = false
    @State private var pendingImagePickerCompletion: NSBridgeHandlerCompletion?
    @State private var isColorPanelPresented = false
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
        mainView
        .navigationBarBackButtonHidden(showsCloseButton)
        .toolbar(.visible, for: .navigationBar)
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
                HStack(spacing: 8) {
                    editorNavigationButton(
                        systemName: "arrow.uturn.backward",
                        accessibilityLabel: "撤销",
                        isEnabled: viewModel.canUndo,
                        action: undo
                    )
                    editorNavigationButton(
                        systemName: "arrow.uturn.forward",
                        accessibilityLabel: "重做",
                        isEnabled: viewModel.canRedo,
                        action: redo
                    )
                }
            }
        })
        .background(InteractivePopGestureEnabler())
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
        .sheet(isPresented: $isColorPanelPresented) {
            ColorAndHighlightSheet(
                selectedTextColor: viewModel.selectedTextColor,
                selectedBackgroundColor: viewModel.selectedBackgroundColor,
                onDismiss: {
                    isColorPanelPresented = false
                },
                onSetTextColor: { color in
                    viewModel.selectedTextColor = color
                    javaScriptCommand = JavaScriptCommand(methodName: "setTextColor", params: ["color": color])
                },
                onSetBackgroundColor: { color in
                    viewModel.selectedBackgroundColor = color
                    javaScriptCommand = JavaScriptCommand(methodName: "setBackgroundColor", params: ["color": color])
                },
                onUnsetBackgroundColor: {
                    viewModel.selectedBackgroundColor = nil
                    javaScriptCommand = JavaScriptCommand(methodName: "setBackgroundColor", params: ["color": NSNull()])
                },
                onReset: {
                    viewModel.selectedTextColor = nil
                    viewModel.selectedBackgroundColor = nil
                    javaScriptCommand = JavaScriptCommand(methodName: "unsetColors")
                }
            )
            .presentationDetents([.height(422)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(24)
        }
        .photosPicker(
            isPresented: $isImagePickerPresented,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else {
                return
            }

            didReceiveImagePickerSelection = true
            Task {
                await handlePickedPhotoItem(newItem)
            }
        }
        .onChange(of: isImagePickerPresented) { _, isPresented in
            guard !isPresented else {
                return
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                if !didReceiveImagePickerSelection, let completion = pendingImagePickerCompletion {
                    pendingImagePickerCompletion = nil
                    completion(.failure(NSBridgeRuntimeError(code: .handlerError, message: "Image selection cancelled", recoverable: true)))
                }
            }
        }
    }
    
    private var mainView: some View {
        ZStack(alignment: .bottom) {
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
                } pickImageAttachment: { params, completion in
                    pickImageAttachment(params, completion: completion)
                } resolveImageAttachment: { params in
                    resolveImageAttachment(params)
                }
            } else {
                Text("文档编辑器资源未找到")
                    .foregroundStyle(.secondary)
            }

            if isKeyboardShow || viewModel.isCustomKeyboardVisible {
                Tools(
                    javaScriptCommand: $javaScriptCommand,
                    viewModel: viewModel,
                    isSystemKeyboardVisible: isKeyboardShow,
                    keyboardHeight: keyboardHeight,
                    onPresentColorPanel: {
                        isColorPanelPresented = true
                    }
                )
            }
        }
    }

    private static var editorURL: URL? {
        #if DEBUG && targetEnvironment(simulator)
        URL(string: "http://localhost:5173/")
        #else
        DocBundleURLSchemeHandler.indexURL
        #endif
    }

    private func editorNavigationButton(
        systemName: String,
        accessibilityLabel: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard isEnabled else {
                return
            }
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 36, height: 36)
                .foregroundStyle(Color(.label).opacity(isEnabled ? 0.84 : 0.24))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
    }

    private func undo() {
        guard viewModel.canUndo else {
            return
        }
        javaScriptCommand = JavaScriptCommand(methodName: "undo")
    }

    private func redo() {
        guard viewModel.canRedo else {
            return
        }
        javaScriptCommand = JavaScriptCommand(methodName: "redo")
    }

    private func applyInitialContentIfNeeded() {
        guard !didApplyInitialContent else {
            return
        }
        didApplyInitialContent = true

        let contentObject = contentObject(from: initialContentJSON ?? loadContentJSON()) ?? NSNull()

        initialContentJSON = nil

        javaScriptCommand = JavaScriptCommand(
            methodName: "openDoc",
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

    @MainActor
    private func pickImageAttachment(_ params: [String: Any]?, completion: @escaping NSBridgeHandlerCompletion) {
        if let pendingImagePickerCompletion {
            pendingImagePickerCompletion(.failure(NSBridgeRuntimeError(code: .handlerError, message: "Another image selection was started", recoverable: true)))
        }

        selectedPhotoItem = nil
        didReceiveImagePickerSelection = false
        pendingImagePickerCompletion = completion
        isImagePickerPresented = true
    }

    @MainActor
    private func handlePickedPhotoItem(_ item: PhotosPickerItem) async {
        guard let completion = pendingImagePickerCompletion else {
            return
        }

        pendingImagePickerCompletion = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw NSBridgeRuntimeError(code: .handlerError, message: "Failed to read selected image", recoverable: true)
            }

            let contentType = item.supportedContentTypes.first { $0.conforms(to: .image) }
            let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
            let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
            let filename = "Image-\(Int(Date().timeIntervalSince1970)).\(fileExtension)"
            let document = try currentOrNewDocument()

            let result = try AttachmentService.storeImageData(
                data,
                filename: filename,
                mimeType: mimeType,
                document: document,
                modelContext: modelContext
            )

            completion(.success(result))
        } catch let error as NSBridgeRuntimeError {
            completion(.failure(error))
        } catch {
            completion(.failure(NSBridgeRuntimeError(code: .handlerError, message: error.localizedDescription, recoverable: true)))
        }
    }

    private func currentOrNewDocument() throws -> Document {
        if let workingDocument {
            return workingDocument
        }

        let document = try makeNewDocument()
        workingDocument = document
        return document
    }

    private func resolveImageAttachment(_ params: [String: Any]?) -> Result<Any?, NSBridgeRuntimeError> {
        do {
            return .success(try AttachmentService.resolveImage(
                params: params,
                modelContext: modelContext
            ))
        } catch let error as NSBridgeRuntimeError {
            return .failure(error)
        } catch {
            return .failure(NSBridgeRuntimeError(code: .handlerError, message: error.localizedDescription, recoverable: true))
        }
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

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            guard let navigationController = uiViewController.navigationController else {
                return
            }

            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}
