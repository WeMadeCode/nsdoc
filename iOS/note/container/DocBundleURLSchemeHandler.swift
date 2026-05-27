//
//  DocBundleURLSchemeHandler.swift
//  note
//

import Foundation
import UniformTypeIdentifiers
import WebKit

final class DocBundleURLSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "nsdocbundle"
    static let indexURL = URL(string: "\(scheme)://editor/index.html")!

    private let bundleRootURL: URL?

    override init() {
        bundleRootURL = Bundle.main.url(forResource: "doc", withExtension: "bundle")
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard
            let requestURL = urlSchemeTask.request.url,
            let fileURL = fileURL(for: requestURL)
        else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let response = URLResponse(
                url: requestURL,
                mimeType: mimeType(for: fileURL),
                expectedContentLength: data.count,
                textEncodingName: nil
            )
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    }

    private func fileURL(for requestURL: URL) -> URL? {
        guard let bundleRootURL else {
            return nil
        }

        let relativePath = requestURL.path == "/" ? "index.html" : String(requestURL.path.dropFirst())
        let candidateURL = bundleRootURL.appendingPathComponent(relativePath).standardizedFileURL
        let rootPath = bundleRootURL.standardizedFileURL.path

        guard candidateURL.path.hasPrefix(rootPath + "/") || candidateURL.path == rootPath else {
            return nil
        }

        return candidateURL
    }

    private func mimeType(for fileURL: URL) -> String {
        if let mimeType = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType {
            return mimeType
        }

        switch fileURL.pathExtension.lowercased() {
        case "js", "mjs":
            return "text/javascript"
        case "css":
            return "text/css"
        case "html":
            return "text/html"
        case "svg":
            return "image/svg+xml"
        default:
            return "application/octet-stream"
        }
    }
}
