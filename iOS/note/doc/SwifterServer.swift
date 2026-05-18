import Swifter
import Foundation

class SwifterServer {
    static let shared = SwifterServer()
    private let server = HttpServer()
    private let port: UInt16 = 8080
    
    func start() {
        // 1. 获取 doc.bundle 路径
        guard let bundlePath = Bundle.main.path(forResource: "doc", ofType: "bundle") else {
            print("❌ doc.bundle 未找到")
            return
        }
        
        // 2. 设置路由
        setupRoutes(bundlePath: bundlePath)
        
        // 3. 启动服务器
        do {
            try server.start(port)
            print("✅ 服务器已启动: http://localhost:\(port)")
            print("📄 访问地址: http://localhost:\(port)/index.html")
        } catch {
            print("❌ 服务器启动失败: \(error)")
        }
    }
    
    func stop() {
        server.stop()
        print("🛑 服务器已停止")
    }
    
    private func setupRoutes(bundlePath: String) {
        // A. 根路径重定向到 index.html
        server["/"] = { _ in
            return .movedPermanently("/index.html")
        }
        
        // B. 处理 HTML 文件
        server["/index.html"] = { _ in
            let indexPath = "\(bundlePath)/index.html"
            return self.serveFile(at: indexPath)
        }
        
        // C. 处理 assets 文件夹下的资源
        server["/assets/:path"] = { request in
            guard let resourcePath = request.params[":path"] else {
                return .notFound
            }
            let fullPath = "\(bundlePath)/assets/\(resourcePath)"
            return self.serveFile(at: fullPath)
        }
        
        // D. 处理其他文件
        server["/:path"] = { request in
            guard let path = request.params[":path"] else {
                return .notFound
            }
            let fullPath = "\(bundlePath)/\(path)"
            return self.serveFile(at: fullPath)
        }
    }
    
    private func serveFile(at path: String) -> HttpResponse {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir) else {
            return .notFound
        }
        
        // 处理目录请求
        if isDir.boolValue {
            let indexPath = "\(path)/index.html"
            if fileManager.fileExists(atPath: indexPath) {
                return self.serveFile(at: indexPath)
            }
            return .forbidden
        }
        
        // 返回文件内容
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // 使用自定义 MIME 类型映射
            let contentType = mimeType(for: path)
            
            return .raw(200, "OK", ["Content-Type": contentType], { writer in
                try writer.write(data)
            })
        } catch {
            print("⚠️ 文件读取错误: \(path) - \(error)")
            return .internalServerError
        }
    }
    
    // 自定义 MIME 类型映射函数
    private func mimeType(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "html", "htm": return "text/html"
        case "css": return "text/css"
        case "js": return "application/javascript"
        case "json": return "application/json"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "ico": return "image/x-icon"
        case "ttf": return "font/ttf"
        case "otf": return "font/otf"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "txt": return "text/plain"
        case "xml": return "application/xml"
        case "pdf": return "application/pdf"
        case "zip": return "application/zip"
        case "mp3": return "audio/mpeg"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }
}
