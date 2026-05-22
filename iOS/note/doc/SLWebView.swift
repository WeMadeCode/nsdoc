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
    let namespace: String
    let methodName: String
    let params: [String: Any]?
    let timeout: TimeInterval
    var completion: ((Result<Any?, NSBridgeRuntimeError>) -> Void)?

    init(
        namespace: String = "editor",
        methodName: String,
        params: [String: Any]? = nil,
        timeout: TimeInterval = 2,
        completion: ((Result<Any?, NSBridgeRuntimeError>) -> Void)? = nil
    ) {
        self.namespace = namespace
        self.methodName = methodName
        self.params = params
        self.timeout = timeout
        self.completion = completion
    }
}

struct SLWebView: UIViewRepresentable {
    
    let url: URL
    @Binding var javaScriptCommand: JavaScriptCommand?
    let isLoadFinsh: (() -> Void)?
    let bridgeReady: (() -> Void)?
    let contentChanged: ((EditorContentSnapshot) -> Void)?
    let toolsUpdate: (([ToolType: Bool]) -> Void)?
    
    init(url: URL,
         javaScriptCommand: Binding<JavaScriptCommand?>,
         isLoadFinsh: (() -> Void)? = nil,
         bridgeReady: (() -> Void)? = nil,
         contentChanged: ((EditorContentSnapshot) -> Void)? = nil,
         toolsUpdate: (([ToolType: Bool]) -> Void)? = nil
    ) {
        self.url = url
        self._javaScriptCommand = javaScriptCommand
        self.isLoadFinsh = isLoadFinsh
        self.bridgeReady = bridgeReady
        self.contentChanged = contentChanged
        self.toolsUpdate = toolsUpdate
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = NSBridgeWebViewInstaller.makeConfiguration(bridge: context.coordinator.bridge)
        let wkWebView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.bridge.attach(webView: wkWebView)
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
        context.coordinator.parent = self

        if let javaScriptCommand {
            guard context.coordinator.lastExecutedCommandID != javaScriptCommand.id else {
                return
            }
            context.coordinator.lastExecutedCommandID = javaScriptCommand.id

            context.coordinator.bridge.callWeb(
                namespace: javaScriptCommand.namespace,
                method: javaScriptCommand.methodName,
                params: javaScriptCommand.params,
                timeout: javaScriptCommand.timeout
            ) { result in
                javaScriptCommand.completion?(result)
            }

            DispatchQueue.main.async {
                if self.javaScriptCommand?.id == javaScriptCommand.id {
                    self.javaScriptCommand = nil
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        
        var parent: SLWebView
        let bridge = NSBridgeNative()
        var lastExecutedCommandID: UUID?
        
        init(_ parent: SLWebView) {
            self.parent = parent
            super.init()
            EditorBridgeHandlers.register(
                on: bridge,
                onReady: { [weak self] in
                    self?.parent.bridgeReady?()
                },
                onContentChanged: { [weak self] snapshot in
                    self?.parent.contentChanged?(snapshot)
                },
                onSelectionChanged: { [weak self] activeTools in
                    self?.parent.toolsUpdate?(activeTools)
                },
                onError: { _ in
                }
            )
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            bridge.resetForNavigation()
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
}
