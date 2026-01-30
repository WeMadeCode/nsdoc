//
//  SLWebView.swift
//  note
//
//  Created by 倪申雷 on 2025/7/9.
//

import SwiftUI
import WebKit

class MyWKWebView: DWKWebView {
    
    // 去除键盘上方的上下按钮和done按钮
    override var inputAccessoryView: UIView? {
        return nil
    }

}

struct JavaScriptCommand {
    let id: UUID = UUID()
    let methodName: String
    let arguments: [Any]?
    var completion: ((Any?) -> Void)?
}

struct SLWebView: UIViewRepresentable {
    
    let url: URL
    let jsBridge = JSBridge()
    @Binding var javaScriptCommand: JavaScriptCommand?
    let isLoadFinsh: (() -> Void)?
    let toolsUpdate: (([ToolType: Bool]) -> Void)?
    
    init(url: URL,
         javaScriptCommand: Binding<JavaScriptCommand?>,
         isLoadFinsh: (() -> Void)? = nil,
         toolsUpdate: (([ToolType: Bool]) -> Void)? = nil
    ) {
        self.url = url
        self._javaScriptCommand = javaScriptCommand
        self.isLoadFinsh = isLoadFinsh
        self.toolsUpdate = toolsUpdate
    }

    func makeUIView(context: Context) -> MyWKWebView {
        let wkWebView = MyWKWebView()
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = .clear
        wkWebView.isInspectable = true
        jsBridge.setup(toolsUpdate: toolsUpdate)
        wkWebView.addJavascriptObject(jsBridge, namespace: nil)
        let request = URLRequest(url: url)
        wkWebView.load(request)
        return wkWebView
    }
    
    func updateUIView(_ uiView: MyWKWebView, context: Context) {
        if let javaScriptCommand {
            uiView.callHandler(
                javaScriptCommand.methodName,
                arguments: javaScriptCommand.arguments
            ) { result in
                javaScriptCommand.completion?(result)
                self.javaScriptCommand = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator 处理委托事件
    class Coordinator: NSObject, WKNavigationDelegate {
        
        var parent: SLWebView
        
        init(_ parent: SLWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoadFinsh?()
        }
    
    }
    
}


#Preview {
    // WebView(url: URL(string: "https://www.baidu.com")!, isLoadDidFinish: true)
}
