//
//  DefaultFolderService.swift
//  note
//
//  Created by Codex on 2026/5/19.
//

import Foundation
import SwiftData

enum DefaultFolderService {
    static let defaultFolderName = "默认文件夹"

    @MainActor
    static func findOrCreateDefaultFolder(in modelContext: ModelContext) throws -> Folder {
        var descriptor = FetchDescriptor<Folder>(
            predicate: #Predicate { folder in
                folder.isDefault && folder.deletedAt == nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 1

        if let folder = try modelContext.fetch(descriptor).first {
            return folder
        }

        let folder = Folder(name: defaultFolderName, isDefault: true)
        modelContext.insert(folder)
        try modelContext.save()
        return folder
    }
}

