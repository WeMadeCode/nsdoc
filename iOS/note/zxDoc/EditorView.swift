//
//  Editor2View.swift
//  note
//
//  Created by 倪申雷 on 2025/7/11.
//

import SwiftUI

struct EditorView: View {
    
    let article: Article?
    
    @StateObject var viewModel = EditorViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var isKeyboardShow: Bool = false
    @State var javaScriptCommand: JavaScriptCommand? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            mainView
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
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
            // 使用 manager 中的 webView
            SLWebView(url: URL(string: "http://localhost:8080/index.html")!, javaScriptCommand: $javaScriptCommand) {
                Task {
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.1秒
                    await MainActor.run {
                        guard let content = article?.markdownText else {
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

            Spacer()
            if isKeyboardShow {
                Tools(javaScriptCommand: $javaScriptCommand, viewModel: viewModel)
            }
        }
    }
    
    private func saveInfo() {
        DispatchQueue.global().async {
            var titleResult: String?
            var markdownTextResult: String?
            let group = DispatchGroup()
            group.enter()
            javaScriptCommand = JavaScriptCommand(methodName: "getDocTitle", arguments: nil) { result in
                if let title = result as? String {
                    titleResult = title
                }
                group.leave()
            }
            group.wait()
            
            group.enter()
            javaScriptCommand = JavaScriptCommand(methodName: "getContent", arguments: nil) { result in
                if let dictionary = result as? [String: Any] {
                    // 1. 将字典转换为 Data
                    let jsonData = try? JSONSerialization.data(
                        withJSONObject: dictionary
                    )
                    // 2. 将 Data 转换为 String
                    if let jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
                        markdownTextResult = jsonString
                    }
                }
                group.leave()
            }
            group.wait()
            DispatchQueue.main.async {
                let saveResult = article ?? Article()
                if let titleResult {
                    saveResult.title = titleResult
                }
                if let markdownTextResult {
                    saveResult.markdownText = markdownTextResult
                }
                if article == nil {
                    modelContext.insert(saveResult)
                    print("插入成功：\(saveResult.title)")
                } else {
                    do {
                        try modelContext.save()
                        print("保存成功：\(saveResult.title)")
                    } catch {
                        print("保存失败：\(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

#Preview {
    // EditorView(article: Article())
}
