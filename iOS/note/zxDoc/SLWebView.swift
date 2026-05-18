//
//  SLWebView.swift
//  note
//
//  Created by 倪申雷 on 2025/7/9.
//

import SwiftUI
import WebKit

final class MyWKWebView: WKWebView {
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
        let configuration = WKWebViewConfiguration()
        let wkWebView = MyWKWebView(frame: .zero, configuration: configuration)
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = .clear
        wkWebView.isInspectable = true
        let request = URLRequest(url: url)
        wkWebView.load(request)
        return wkWebView
    }
    
    func updateUIView(_ uiView: MyWKWebView, context: Context) {
        if let javaScriptCommand {
            javaScriptCommand.completion?(nil)
            self.javaScriptCommand = nil
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
