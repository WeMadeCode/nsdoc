//
//  NSBridgeNative.swift
//  note
//

import Foundation
import WebKit

final class NSBridgeNative: NSObject, WKScriptMessageHandler {
    private struct PendingRequest {
        let completion: NSBridgeHandlerCompletion
    }

    let registry = NSBridgeHandlerRegistry()

    private weak var webView: WKWebView?
    private let permissionGuard = NSBridgePermissionGuard()
    private var pendingRequests: [String: PendingRequest] = [:]
    private(set) var isReady = false

    func attach(webView: WKWebView) {
        self.webView = webView
    }

    func resetForNavigation() {
        isReady = false
        let requests = pendingRequests
        pendingRequests.removeAll()
        requests.values.forEach {
            $0.completion(.failure(NSBridgeRuntimeError(code: .webUnavailable, message: "WebView navigation reset", recoverable: true)))
        }
    }

    func callWeb(
        namespace: String,
        method: String,
        params: [String: Any]? = nil,
        timeout: TimeInterval = 2,
        completion: @escaping NSBridgeHandlerCompletion
    ) {
        guard webView != nil else {
            completion(.failure(NSBridgeRuntimeError(code: .webUnavailable, message: "WebView is unavailable", recoverable: true)))
            return
        }

        let id = "req_\(UUID().uuidString)"
        let message = NSBridgeMessage(id: id, type: .request, namespace: namespace, method: method, params: params)
        pendingRequests[id] = PendingRequest(completion: completion)

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            guard let self, let pending = self.pendingRequests.removeValue(forKey: id) else {
                return
            }

            pending.completion(.failure(NSBridgeRuntimeError(code: .timeout, message: "Bridge request \(namespace).\(method) timed out", recoverable: true)))
        }

        sendToWeb(message.dictionary) { [weak self] error in
            guard let error, let pending = self?.pendingRequests.removeValue(forKey: id) else {
                return
            }

            pending.completion(.failure(error))
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive scriptMessage: WKScriptMessage) {
        guard
            scriptMessage.name == JSBridgeChannel.nsBridge,
            let dictionary = scriptMessage.body as? [String: Any],
            let message = NSBridgeMessage(dictionary: dictionary)
        else {
            return
        }

        if let error = permissionGuard.validateIncoming(message) {
            respond(to: message, result: .failure(error))
            return
        }

        switch message.type {
        case .response:
            handleResponse(message)
        case .ready:
            isReady = true
            handleRequestOrEvent(message)
        case .request, .event:
            handleRequestOrEvent(message)
        }
    }

    private func handleResponse(_ message: NSBridgeMessage) {
        guard let pending = pendingRequests.removeValue(forKey: message.id) else {
            return
        }

        if message.status == .success {
            pending.completion(.success(message.data))
            return
        }

        pending.completion(.failure(message.error ?? NSBridgeRuntimeError(code: .handlerError, message: "Bridge request failed", recoverable: true)))
    }

    private func handleRequestOrEvent(_ message: NSBridgeMessage) {
        guard let handler = registry.handler(namespace: message.namespace, method: message.method) else {
            respond(to: message, result: .failure(NSBridgeRuntimeError(code: .methodNotFound, message: "Handler \(message.namespace).\(message.method) is not registered")))
            return
        }

        handler(message) { [weak self] result in
            self?.respond(to: message, result: result)
        }
    }

    private func respond(to message: NSBridgeMessage, result: Result<Any?, NSBridgeRuntimeError>) {
        let response: NSBridgeMessage

        switch result {
        case .success(let data):
            response = NSBridgeMessage(
                id: message.id,
                type: .response,
                namespace: message.namespace,
                method: message.method,
                status: .success,
                data: data ?? [:]
            )
        case .failure(let error):
            response = NSBridgeMessage(
                id: message.id,
                type: .response,
                namespace: message.namespace,
                method: message.method,
                status: .error,
                error: error
            )
        }

        sendToWeb(response.dictionary)
    }

    private func sendToWeb(_ dictionary: [String: Any], completion: ((NSBridgeRuntimeError?) -> Void)? = nil) {
        guard JSONSerialization.isValidJSONObject(dictionary) else {
            completion?(NSBridgeRuntimeError(code: .invalidMessage, message: "Bridge message is not JSON serializable"))
            return
        }

        guard
            let data = try? JSONSerialization.data(withJSONObject: dictionary),
            let json = String(data: data, encoding: .utf8)
        else {
            completion?(NSBridgeRuntimeError(code: .invalidMessage, message: "Failed to encode bridge message"))
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript("window.__NSBridge && window.__NSBridge.receiveFromNative(\(json));") { _, error in
                if let error {
                    completion?(NSBridgeRuntimeError(code: .webUnavailable, message: error.localizedDescription, recoverable: true))
                } else {
                    completion?(nil)
                }
            }
        }
    }
}
