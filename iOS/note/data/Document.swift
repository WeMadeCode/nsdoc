//
//  Document.swift
//  note
//
//  Created by Codex on 2026/5/19.
//

import Foundation
import SwiftData

enum DocumentType {
    static let page = "page"
    static let mindMap = "mindMap"
    static let whiteboard = "whiteboard"
    static let flowchart = "flowchart"
}

enum DocumentSyncStatus {
    static let localOnly = "localOnly"
    static let pendingUpload = "pendingUpload"
    static let synced = "synced"
    static let failed = "failed"
}

@Model
final class Document {
    var id: UUID = UUID()
    var folderId: UUID = UUID()
    var documentType: String = DocumentType.page
    var title: String = ""
    var excerpt: String = ""
    var plainText: String = ""
    var sortOrder: Int = 0
    var contentVersion: Int = 1
    var syncStatus: String = DocumentSyncStatus.localOnly
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        folderId: UUID,
        documentType: String = DocumentType.page,
        title: String = "",
        excerpt: String = "",
        plainText: String = "",
        sortOrder: Int = 0,
        contentVersion: Int = 1,
        syncStatus: String = DocumentSyncStatus.localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.folderId = folderId
        self.documentType = documentType
        self.title = title
        self.excerpt = excerpt
        self.plainText = plainText
        self.sortOrder = sortOrder
        self.contentVersion = contentVersion
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

