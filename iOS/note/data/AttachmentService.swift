//
//  AttachmentService.swift
//  note
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

enum AttachmentService {
    static func storeImageData(
        _ data: Data,
        filename: String?,
        mimeType: String,
        document: Document,
        modelContext: ModelContext
    ) throws -> [String: Any] {
        guard mimeType.hasPrefix("image/") else {
            throw NSBridgeRuntimeError(code: .invalidParams, message: "Only image attachments are supported")
        }

        let attachmentId = UUID()
        let filename = normalizedFilename(
            filename,
            attachmentId: attachmentId,
            mimeType: mimeType
        )
        let relativePath = "Attachments/\(document.id.uuidString)/\(attachmentId.uuidString)-\(filename)"
        let fileURL = try applicationSupportDirectory().appendingPathComponent(relativePath, isDirectory: false)

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: [.atomic])

        let attachment = Attachment(
            id: attachmentId,
            documentId: document.id,
            kind: AttachmentKind.image,
            filename: filename,
            mimeType: mimeType,
            byteSize: data.count,
            localPath: relativePath,
            syncStatus: DocumentSyncStatus.pendingUpload
        )

        modelContext.insert(attachment)
        document.syncStatus = DocumentSyncStatus.pendingUpload
        document.updatedAt = Date()
        try modelContext.save()

        return [
            "attachmentId": attachmentId.uuidString,
            "src": "attachment://\(attachmentId.uuidString)",
            "filename": filename,
            "mimeType": mimeType,
            "byteSize": data.count
        ]
    }

    static func resolveImage(
        params: [String: Any]?,
        modelContext: ModelContext
    ) throws -> [String: Any] {
        guard
            let attachmentIdString = params?["attachmentId"] as? String,
            let attachmentId = UUID(uuidString: attachmentIdString)
        else {
            throw NSBridgeRuntimeError(code: .invalidParams, message: "media.resolveImage requires attachmentId")
        }

        var descriptor = FetchDescriptor<Attachment>(
            predicate: #Predicate { attachment in
                attachment.id == attachmentId
            }
        )
        descriptor.fetchLimit = 1

        guard let attachment = try modelContext.fetch(descriptor).first else {
            throw NSBridgeRuntimeError(code: .invalidParams, message: "Attachment not found")
        }

        guard attachment.kind == AttachmentKind.image else {
            throw NSBridgeRuntimeError(code: .invalidParams, message: "Attachment is not an image")
        }

        let fileURL = try applicationSupportDirectory().appendingPathComponent(attachment.localPath, isDirectory: false)
        let data = try Data(contentsOf: fileURL)
        let mimeType = attachment.mimeType.isEmpty ? "application/octet-stream" : attachment.mimeType

        return [
            "src": "data:\(mimeType);base64,\(data.base64EncodedString())",
            "mimeType": mimeType
        ]
    }

    private static func applicationSupportDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    private static func normalizedFilename(_ filename: String?, attachmentId: UUID, mimeType: String) -> String {
        let fallbackExtension = UTType(mimeType: mimeType)?.preferredFilenameExtension ?? "img"
        let rawName = filename?.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = rawName?.isEmpty == false ? rawName! : "\(attachmentId.uuidString).\(fallbackExtension)"
        let sanitized = baseName
            .components(separatedBy: CharacterSet(charactersIn: "/\\:"))
            .joined(separator: "-")

        guard sanitized.contains(".") else {
            return "\(sanitized).\(fallbackExtension)"
        }

        return sanitized
    }
}
