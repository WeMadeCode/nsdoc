//
//  EditorBridgeHandlers.swift
//  note
//

import Foundation

struct EditorContentSnapshot {
    let changeVersion: Int
    let title: String
    let content: Any
    let isEmpty: Bool
    let reason: String?

    init?(params: [String: Any]?) {
        guard
            let params,
            let content = params["content"]
        else {
            return nil
        }

        self.changeVersion = params["changeVersion"] as? Int ?? 0
        self.title = params["title"] as? String ?? ""
        self.content = content
        self.isEmpty = params["isEmpty"] as? Bool ?? false
        self.reason = params["reason"] as? String
    }
}

struct EditorSelectionContext {
    let isInTitle: Bool
    let textColor: String?
    let backgroundColor: String?
    let canUndo: Bool
    let canRedo: Bool

    init(params: [String: Any]?) {
        let selectionContext = params?["selectionContext"] as? [String: Any] ?? [:]
        let editorState = params?["editorState"] as? [String: Any] ?? [:]
        self.isInTitle = selectionContext["isInTitle"] as? Bool ?? false
        self.textColor = selectionContext["textColor"] as? String
        self.backgroundColor = selectionContext["backgroundColor"] as? String
        self.canUndo = editorState["canUndo"] as? Bool ?? false
        self.canRedo = editorState["canRedo"] as? Bool ?? false
    }
}

struct EditorBridgeHandlers {
    static func register(
        on bridge: NSBridgeNative,
        appInfo: [String: String],
        onReady: @escaping () -> Void,
        onContentChanged: @escaping (EditorContentSnapshot) -> Void,
        onSelectionChanged: @escaping ([ToolType: Bool], EditorSelectionContext) -> Void,
        onError: @escaping (String) -> Void
    ) {
        bridge.registry.register(namespace: "editor", method: "getAppInfo") { _, completion in
            completion(.success(appInfo))
        }

        bridge.registry.register(namespace: "editor", method: "ready") { _, completion in
            DispatchQueue.main.async {
                onReady()
            }
            completion(.success(["ack": true]))
        }

        bridge.registry.register(namespace: "editor", method: "contentChanged") { message, completion in
            guard let snapshot = EditorContentSnapshot(params: message.params) else {
                completion(.failure(NSBridgeRuntimeError(code: .invalidParams, message: "editor.contentChanged requires content")))
                return
            }

            DispatchQueue.main.async {
                onContentChanged(snapshot)
            }
            completion(.success(["ack": true]))
        }

        bridge.registry.register(namespace: "editor", method: "selectionChanged") { message, completion in
            let activeTools = mapActiveTools(from: message.params)
            let selectionContext = EditorSelectionContext(params: message.params)
            DispatchQueue.main.async {
                onSelectionChanged(activeTools, selectionContext)
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
            .text: activeTools["paragraph"] as? Bool ?? false,
            .bold: activeTools["bold"] as? Bool ?? false,
            .italic: activeTools["italic"] as? Bool ?? false,
            .underline: activeTools["underline"] as? Bool ?? false,
            .strikethrough: activeTools["strike"] as? Bool ?? false,
            .inlineCode: activeTools["code"] as? Bool ?? false,
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
