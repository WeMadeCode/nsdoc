//
//  WebConsoleBridge.swift
//  note
//

import Foundation
import WebKit

final class WebConsoleBridge: NSObject, WKScriptMessageHandler {
    static func install(on userContentController: WKUserContentController) {
        userContentController.addUserScript(makeUserScript())
        userContentController.add(WebConsoleBridge(), name: JSBridgeChannel.webConsoleLog)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == JSBridgeChannel.webConsoleLog else {
            return
        }

        guard let body = message.body as? [String: Any] else {
            print("[Web console] \(message.body)")
            return
        }

        let level = body["level"] as? String ?? "log"
        let text = body["message"] as? String ?? ""
        print("[Web console.\(level)] \(text)")
    }

    private static func makeUserScript() -> WKUserScript {
        WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
    }

    private static let scriptSource = """
    (function() {
        if (window.__NSWebConsoleInstalled) {
            return;
        }
        window.__NSWebConsoleInstalled = true;

        var handler = window.webkit &&
            window.webkit.messageHandlers &&
            window.webkit.messageHandlers.\(JSBridgeChannel.webConsoleLog);

        if (!handler) {
            return;
        }

        function serialize(value) {
            if (value instanceof Error) {
                return value.stack || value.message || String(value);
            }

            if (typeof value === 'undefined') {
                return 'undefined';
            }

            if (typeof value === 'function' || typeof value === 'symbol') {
                return value.toString();
            }

            if (typeof value === 'bigint') {
                return value.toString() + 'n';
            }

            if (value === null || typeof value !== 'object') {
                return String(value);
            }

            try {
                var seen = [];
                return JSON.stringify(value, function(key, nestedValue) {
                    if (typeof nestedValue === 'bigint') {
                        return nestedValue.toString() + 'n';
                    }

                    if (nestedValue && typeof nestedValue === 'object') {
                        if (seen.indexOf(nestedValue) >= 0) {
                            return '[Circular]';
                        }
                        seen.push(nestedValue);
                    }

                    return nestedValue;
                });
            } catch (error) {
                return String(value);
            }
        }

        function send(level, args) {
            try {
                handler.postMessage({
                    level: level,
                    message: Array.prototype.map.call(args, serialize).join(' ')
                });
            } catch (error) {
            }
        }

        ['log', 'info', 'warn', 'error', 'debug'].forEach(function(level) {
            var original = console[level];

            console[level] = function() {
                send(level, arguments);

                if (typeof original === 'function') {
                    original.apply(console, arguments);
                }
            };
        });
    })();
    """
}
