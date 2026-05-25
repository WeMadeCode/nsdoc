//
//  MediaBridgeHandlers.swift
//  note
//

import Foundation

struct MediaBridgeHandlers {
    static func register(
        on bridge: NSBridgeNative,
        pickImage: @escaping ([String: Any]?, @escaping NSBridgeHandlerCompletion) -> Void,
        resolveImage: @escaping ([String: Any]?) -> Result<Any?, NSBridgeRuntimeError>
    ) {
        bridge.registry.register(namespace: "media", method: "pickImage") { message, completion in
            pickImage(message.params, completion)
        }

        bridge.registry.register(namespace: "media", method: "resolveImage") { message, completion in
            completion(resolveImage(message.params))
        }
    }
}
