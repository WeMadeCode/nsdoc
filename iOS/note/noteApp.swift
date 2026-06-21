//
//  NoteApp.swift
//  note
//
//  Created by 倪申雷 on 2025/6/20.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
import Security
#endif

#if os(macOS)
private final class MacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
    }
}
#endif

@main
struct NoteApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    #endif

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Folder.self,
            Document.self,
            DocumentContent.self,
            Attachment.self,
        ])

        #if os(macOS)
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase =
            Self.hasCloudKitEntitlement
            ? .private(CloudKitConfig.containerIdentifier)
            : .none
        #else
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase =
            .private(CloudKitConfig.containerIdentifier)
        #endif

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitDatabase
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    #if os(macOS)
    private static var hasCloudKitEntitlement: Bool {
        guard let task = SecTaskCreateFromSelf(nil) else {
            return false
        }

        let entitlement = SecTaskCopyValueForEntitlement(
            task,
            "com.apple.developer.icloud-container-identifiers" as CFString,
            nil
        )

        guard let containerIdentifiers = entitlement as? [String] else {
            return false
        }

        return containerIdentifiers.contains(CloudKitConfig.containerIdentifier)
    }
    #endif
    
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MacMainContentView()
                .preferredColorScheme(.light)
            #else
            MainContentView()
                .preferredColorScheme(.light)
            #endif
        }
        .modelContainer(sharedModelContainer)
    }
}
