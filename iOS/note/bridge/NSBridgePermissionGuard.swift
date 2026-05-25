//
//  NSBridgePermissionGuard.swift
//  note
//

import Foundation

struct NSBridgePermissionGuard {
    private let allowedWebMethods: Set<String> = [
        "editor.ready",
        "editor.contentChanged",
        "editor.selectionChanged",
        "editor.focusChanged",
        "editor.error",
        "media.pickImage",
        "media.resolveImage"
    ]

    func validateIncoming(_ message: NSBridgeMessage) -> NSBridgeRuntimeError? {
        guard message.bridgeVersion == NSBridgeMessage.bridgeVersion else {
            return NSBridgeRuntimeError(
                code: .versionUnsupported,
                message: "Unsupported bridge version \(message.bridgeVersion)"
            )
        }

        guard !message.namespace.isEmpty, !message.method.isEmpty else {
            return NSBridgeRuntimeError(code: .invalidMessage, message: "Bridge namespace and method are required")
        }

        if message.type == .response {
            return nil
        }

        let fullMethod = "\(message.namespace).\(message.method)"
        guard allowedWebMethods.contains(fullMethod) else {
            return NSBridgeRuntimeError(code: .unauthorized, message: "Unauthorized bridge method \(fullMethod)")
        }

        return nil
    }
}
