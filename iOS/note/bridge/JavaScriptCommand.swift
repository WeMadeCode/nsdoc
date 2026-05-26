//
//  JavaScriptCommand.swift
//  note
//
//  Created by 周翔 on 2026/5/26.
//

import SwiftUI

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
