//
//  NSBridgeWebViewInstaller.swift
//  note
//

import WebKit

enum NSBridgeWebViewInstaller {
    static func makeConfiguration(bridge: NSBridgeNative) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        #if DEBUG
        WebConsoleBridge.install(on: userContentController)
        #endif

        userContentController.add(bridge, name: JSBridgeChannel.nsBridge)

        configuration.userContentController = userContentController
        return configuration
    }
}
