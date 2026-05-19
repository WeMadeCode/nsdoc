//
//  EditorBridgeHandlers.swift
//  note
//

import Foundation

struct EditorBridgeHandlers {
    static func register(
        on bridge: NSBridgeNative,
        onReady: @escaping () -> Void,
        onContentChanged: @escaping () -> Void,
        onSelectionChanged: @escaping ([ToolType: Bool]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        bridge.registry.register(namespace: "editor", method: "ready") { _, completion in
            DispatchQueue.main.async {
                onReady()
            }
            completion(.success(["ack": true]))
        }

        bridge.registry.register(namespace: "editor", method: "contentChanged") { _, completion in
            DispatchQueue.main.async {
                onContentChanged()
            }
            completion(.success(["ack": true]))
        }

        bridge.registry.register(namespace: "editor", method: "selectionChanged") { message, completion in
            let activeTools = mapActiveTools(from: message.params)
            DispatchQueue.main.async {
                onSelectionChanged(activeTools)
            }
            completion(.success(["ack": true]))
        }

        bridge.registry.register(namespace: "editor", method: "focusChanged") { _, completion in
            completion(.success(["ack": true]))
        }

        bridge.registry.register(namespace: "editor", method: "error") { message, completion in
            let errorMessage = message.params?["message"] as? String ?? "Unknown editor error"
            DispatchQueue.main.async {
                onError(errorMessage)
            }
            completion(.success(["ack": true]))
        }
    }

    private static func mapActiveTools(from params: [String: Any]?) -> [ToolType: Bool] {
        let activeTools = params?["activeTools"] as? [String: Any] ?? [:]
        var result: [ToolType: Bool] = [
            .bold: activeTools["bold"] as? Bool ?? false,
            .italic: activeTools["italic"] as? Bool ?? false,
            .strikethrough: activeTools["strike"] as? Bool ?? false,
            .code: activeTools["codeBlock"] as? Bool ?? false,
            .reference: activeTools["blockquote"] as? Bool ?? false,
            .order: activeTools["orderedList"] as? Bool ?? false,
            .unOrder: activeTools["bulletList"] as? Bool ?? false,
            .check: activeTools["taskList"] as? Bool ?? false
        ]

        if let heading = activeTools["heading"] as? [String: Any] {
            let headingIsActive = heading["active"] as? Bool ?? false
            let level = heading["level"] as? Int
            result[.h1] = headingIsActive && level == 1
            result[.h2] = headingIsActive && level == 2
            result[.h3] = headingIsActive && level == 3
            result[.h4] = headingIsActive && level == 4
            result[.h5] = headingIsActive && level == 5
        }

        if let align = activeTools["textAlign"] as? String {
            result[.left] = align == "left"
            result[.center] = align == "center"
            result[.right] = align == "right"
        }

        return result
    }
}

