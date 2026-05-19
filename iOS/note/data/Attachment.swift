//
//  Attachment.swift
//  note
//
//  Created by Codex on 2026/5/19.
//

import Foundation
import SwiftData

enum AttachmentKind {
    static let image = "image"
    static let file = "file"
    static let video = "video"
    static let audio = "audio"
    static let canvasAsset = "canvasAsset"
}

@Model
final class Attachment {
    var id: UUID = UUID()
    var documentId: UUID = UUID()
    var kind: String = AttachmentKind.file
    var filename: String = ""
    var mimeType: String = ""
    var byteSize: Int = 0
    var checksum: String?
    var localPath: String = ""
    var cloudAssetRecordName: String?
    var syncStatus: String = DocumentSyncStatus.localOnly
    var createdAt: Date = Date()
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        documentId: UUID,
        kind: String = AttachmentKind.file,
        filename: String = "",
        mimeType: String = "",
        byteSize: Int = 0,
        checksum: String? = nil,
        localPath: String = "",
        cloudAssetRecordName: String? = nil,
        syncStatus: String = DocumentSyncStatus.localOnly,
        createdAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.documentId = documentId
        self.kind = kind
        self.filename = filename
        self.mimeType = mimeType
        self.byteSize = byteSize
        self.checksum = checksum
        self.localPath = localPath
        self.cloudAssetRecordName = cloudAssetRecordName
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
}

