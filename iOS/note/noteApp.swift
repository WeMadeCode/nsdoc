//
//  noteApp.swift
//  note
//
//  Created by 倪申雷 on 2025/6/20.
//

import SwiftUI
import SwiftData

@main
struct noteApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Article.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                SwifterServer.shared.start()
            case .inactive:
                SwifterServer.shared.stop()
            case .background:
                break
            @unknown default:
                break
            }
        }
    }
}
