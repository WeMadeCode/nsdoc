//
//  NSBridgeMessage.swift
//  note
//

import Foundation

enum NSBridgeMessageType: String {
    case request
    case response
    case event
    case ready
}

enum NSBridgeResponseStatus: String {
    case success
    case error
}

struct NSBridgeMessage {
    static let bridgeVersion = "1.0"

    let bridgeVersion: String
    let id: String
    let type: NSBridgeMessageType
    let namespace: String
    let method: String
    let params: [String: Any]?
    let status: NSBridgeResponseStatus?
    let data: Any?
    let error: NSBridgeRuntimeError?
    let timestamp: Double

    init(
        id: String,
        type: NSBridgeMessageType,
        namespace: String,
        method: String,
        params: [String: Any]? = nil,
        status: NSBridgeResponseStatus? = nil,
        data: Any? = nil,
        error: NSBridgeRuntimeError? = nil,
        timestamp: Double = Date().timeIntervalSince1970 * 1000
    ) {
        self.bridgeVersion = Self.bridgeVersion
        self.id = id
        self.type = type
        self.namespace = namespace
        self.method = method
        self.params = params
        self.status = status
        self.data = data
        self.error = error
        self.timestamp = timestamp
    }

    init?(dictionary: [String: Any]) {
        guard
            let bridgeVersion = dictionary["bridgeVersion"] as? String,
            let id = dictionary["id"] as? String,
            let typeValue = dictionary["type"] as? String,
            let type = NSBridgeMessageType(rawValue: typeValue),
            let namespace = dictionary["namespace"] as? String,
            let method = dictionary["method"] as? String
        else {
            return nil
        }

        self.bridgeVersion = bridgeVersion
        self.id = id
        self.type = type
        self.namespace = namespace
        self.method = method
        self.params = dictionary["params"] as? [String: Any]

        if let statusValue = dictionary["status"] as? String {
            self.status = NSBridgeResponseStatus(rawValue: statusValue)
        } else {
            self.status = nil
        }

        self.data = dictionary["data"]

        if
            let errorDictionary = dictionary["error"] as? [String: Any],
            let codeValue = errorDictionary["code"] as? String,
            let code = NSBridgeErrorCode(rawValue: codeValue)
        {
            self.error = NSBridgeRuntimeError(
                code: code,
                message: errorDictionary["message"] as? String ?? code.rawValue,
                recoverable: errorDictionary["recoverable"] as? Bool ?? false
            )
        } else {
            self.error = nil
        }

        self.timestamp = dictionary["timestamp"] as? Double ?? Date().timeIntervalSince1970 * 1000
    }

    var dictionary: [String: Any] {
        var result: [String: Any] = [
            "bridgeVersion": bridgeVersion,
            "id": id,
            "type": type.rawValue,
            "namespace": namespace,
            "method": method,
            "timestamp": timestamp
        ]

        if let params {
            result["params"] = params
        }

        if let status {
            result["status"] = status.rawValue
        }

        if let data {
            result["data"] = data
        }

        if let error {
            result["error"] = error.payload
        }

        return result
    }
}

