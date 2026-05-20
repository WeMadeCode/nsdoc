//
//  NSBridgeWebViewInstaller.swift
//  note
//

import WebKit

enum NSBridgeWebViewInstaller {
    static func makeConfiguration(bridge: NSBridgeNative) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(bridge, name: "nsBridge")
        return configuration
    }
}
