//
//  SLWebView.swift
//  note
//
//  Created by 倪申雷 on 2025/7/9.
//

import SwiftUI
import WebKit
import ObjectiveC.runtime

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

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let wkWebView = WKWebView(frame: .zero, configuration: configuration)
        wkWebView.hideKeyboardAccessoryBar()
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = .clear
        wkWebView.isInspectable = true
        wkWebView.scrollView.isScrollEnabled = false
        wkWebView.scrollView.bounces = false
        let request = URLRequest(url: url)
        wkWebView.load(request)
        return wkWebView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
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
            webView.hideKeyboardAccessoryBar()
            parent.isLoadFinsh?()
        }
    
    }
    
}

private extension WKWebView {
    func hideKeyboardAccessoryBar() {
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []

        scrollView.subviews.forEach { subview in
            subview.inputAssistantItem.leadingBarButtonGroups = []
            subview.inputAssistantItem.trailingBarButtonGroups = []

            guard String(describing: type(of: subview)).hasPrefix("WKContent") else {
                return
            }

            subview.removeInputAccessoryView()
        }
    }
}

private extension UIView {
    func removeInputAccessoryView() {
        let originalClass: AnyClass = type(of: self)
        let className = String(cString: class_getName(originalClass))
        let subclassName = "\(className)_NoInputAccessoryView"

        if let subclass = NSClassFromString(subclassName) {
            object_setClass(self, subclass)
            return
        }

        guard
            let subclass = objc_allocateClassPair(originalClass, subclassName, 0),
            let method = class_getInstanceMethod(NoInputAccessoryViewProvider.self, #selector(getter: NoInputAccessoryViewProvider.inputAccessoryView))
        else {
            return
        }

        class_addMethod(
            subclass,
            #selector(getter: UIResponder.inputAccessoryView),
            method_getImplementation(method),
            method_getTypeEncoding(method)
        )
        objc_registerClassPair(subclass)
        object_setClass(self, subclass)
    }
}

private final class NoInputAccessoryViewProvider: UIResponder {
    override var inputAccessoryView: UIView? {
        nil
    }
}


#Preview {
    // WebView(url: URL(string: "https://www.baidu.com")!, isLoadDidFinish: true)
}
