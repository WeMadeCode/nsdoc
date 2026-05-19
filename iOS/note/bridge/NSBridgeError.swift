//
//  NSBridgeError.swift
//  note
//

import Foundation

enum NSBridgeErrorCode: String {
    case bridgeNotReady = "BRIDGE_NOT_READY"
    case nativeUnavailable = "NATIVE_UNAVAILABLE"
    case webUnavailable = "WEB_UNAVAILABLE"
    case timeout = "TIMEOUT"
    case methodNotFound = "METHOD_NOT_FOUND"
    case invalidMessage = "INVALID_MESSAGE"
    case invalidParams = "INVALID_PARAMS"
    case unauthorized = "UNAUTHORIZED"
    case payloadTooLarge = "PAYLOAD_TOO_LARGE"
    case handlerError = "HANDLER_ERROR"
    case versionUnsupported = "VERSION_UNSUPPORTED"
}

struct NSBridgeRuntimeError: Error {
    let code: NSBridgeErrorCode
    let message: String
    let recoverable: Bool

    init(code: NSBridgeErrorCode, message: String, recoverable: Bool = false) {
        self.code = code
        self.message = message
        self.recoverable = recoverable
    }

    var payload: [String: Any] {
        [
            "code": code.rawValue,
            "message": message,
            "recoverable": recoverable
        ]
    }
}

