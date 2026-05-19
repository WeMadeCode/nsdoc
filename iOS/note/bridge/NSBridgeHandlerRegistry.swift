//
//  NSBridgeHandlerRegistry.swift
//  note
//

import Foundation

typealias NSBridgeHandlerCompletion = (Result<Any?, NSBridgeRuntimeError>) -> Void
typealias NSBridgeHandler = (NSBridgeMessage, @escaping NSBridgeHandlerCompletion) -> Void

final class NSBridgeHandlerRegistry {
    private var handlers: [String: NSBridgeHandler] = [:]

    func register(namespace: String, method: String, handler: @escaping NSBridgeHandler) {
        handlers[key(namespace: namespace, method: method)] = handler
    }

    func handler(namespace: String, method: String) -> NSBridgeHandler? {
        handlers[key(namespace: namespace, method: method)]
    }

    private func key(namespace: String, method: String) -> String {
        "\(namespace).\(method)"
    }
}

