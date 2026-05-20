//
//  DocumentContent.swift
//  note
//
//  Created by Codex on 2026/5/19.
//

import Foundation
import SwiftData

enum DocumentContentFormat {
    static let tiptapJSON = "tiptap-json"
    static let mindMapJSON = "mindmap-json"
    static let whiteboardJSON = "whiteboard-json"
    static let flowchartJSON = "flowchart-json"
}

enum DocumentContentDefaults {
    static let emptyTiptapJSON = """
    {"type":"doc","content":[{"type":"title"},{"type":"paragraph"}]}
    """
}

@Model
final class DocumentContent {
    var id: UUID = UUID()
    var documentId: UUID = UUID()
    var contentFormat: String = DocumentContentFormat.tiptapJSON
    var contentJSON: String = ""
    var schemaVersion: Int = 1
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        documentId: UUID,
        contentFormat: String = DocumentContentFormat.tiptapJSON,
        contentJSON: String = "",
        schemaVersion: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.documentId = documentId
        self.contentFormat = contentFormat
        self.contentJSON = contentJSON
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
    }
}
