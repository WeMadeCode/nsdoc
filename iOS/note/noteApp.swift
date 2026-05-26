//
//  NoteApp.swift
//  note
//
//  Created by 倪申雷 on 2025/6/20.
//

import SwiftUI
import SwiftData

@main
struct NoteApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Folder.self,
            Document.self,
            DocumentContent.self,
            Attachment.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(CloudKitConfig.containerIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
