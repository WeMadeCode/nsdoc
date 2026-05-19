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
    @State private var isKeyboardShow: Bool = false
    @State var javaScriptCommand: JavaScriptCommand? = nil
    @Environment(\.dismiss) var dismiss

    init(document: Document?, showsCloseButton: Bool = true) {
        self.showsCloseButton = showsCloseButton
        _workingDocument = State(initialValue: document)
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
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveInfo()
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
    }
    
    private var mainView: some View {
        VStack {
            if let editorURL = Self.editorURL {
                SLWebView(url: editorURL, javaScriptCommand: $javaScriptCommand) {
                    Task {
                        try await Task.sleep(nanoseconds: 300_000_000)
                        await MainActor.run {
                            guard let content = loadContentJSON() else {
                                return
                            }
                            javaScriptCommand = JavaScriptCommand(
                                methodName: "setContent",
                                arguments: [[
                                    "content": content,
                                    "isFocus": false
                                ]]
                            )
                        }
                    }
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
    
    private func saveInfo() {
        DispatchQueue.global().async {
            let titleResult = requestJavaScriptResult(methodName: "getDocTitle") as? String
            let contentJSONResult = contentJSONString(
                from: requestJavaScriptResult(methodName: "getContent")
            )

            DispatchQueue.main.async {
                do {
                    let saveResult: Document
                    if let workingDocument {
                        saveResult = workingDocument
                    } else {
                        saveResult = try makeNewDocument()
                        workingDocument = saveResult
                    }

                    if let titleResult {
                        saveResult.title = titleResult
                    }
                    if let contentJSONResult {
                        saveContentJSON(contentJSONResult, for: saveResult)
                        let plainText = extractPlainText(from: contentJSONResult)
                        saveResult.plainText = plainText
                        saveResult.excerpt = String(plainText.prefix(120))
                        saveResult.contentVersion += 1
                    }
                    saveResult.updatedAt = Date()
                    saveResult.syncStatus = DocumentSyncStatus.pendingUpload

                    try modelContext.save()
                    print("保存成功：\(saveResult.title)")
                } catch {
                    print("保存失败：\(error.localizedDescription)")
                }
            }
        }
    }

    private func requestJavaScriptResult(methodName: String) -> Any? {
        var resultValue: Any?
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.main.async {
            javaScriptCommand = JavaScriptCommand(methodName: methodName, arguments: nil) { result in
                resultValue = result
                group.leave()
            }
        }
        group.wait()

        return resultValue
    }

    private func contentJSONString(from result: Any?) -> String? {
        guard let dictionary = result as? [String: Any] else {
            return nil
        }

        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return nil
        }

        return jsonString
    }

    private func loadContentJSON() -> String? {
        guard let document = workingDocument else {
            return nil
        }

        do {
            return try fetchContent(for: document)?.contentJSON
        } catch {
            print("读取文档内容失败：\(error.localizedDescription)")
            return nil
        }
    }

    private func makeNewDocument() throws -> Document {
        let folder = try DefaultFolderService.findOrCreateDefaultFolder(in: modelContext)
        let document = Document(folderId: folder.id)
        modelContext.insert(document)
        return document
    }

    private func saveContentJSON(_ contentJSON: String, for document: Document) {
        do {
            if let content = try fetchContent(for: document) {
                content.contentJSON = contentJSON
                return
            }
        } catch {
            print("读取已有内容失败，准备创建新内容：\(error.localizedDescription)")
        }

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
    // EditorView(document: nil)
}
