//
//  MainContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/23.
//

import SwiftUI

struct MainContentView: View {
    @StateObject private var cloudKitAccountService = CloudKitAccountService()
    @Environment(\.scenePhase) private var scenePhase
        
    var body: some View {
        VStack(spacing: 0) {
            CloudKitStatusBanner(
                state: cloudKitAccountService.state,
                refresh: cloudKitAccountService.refresh
            )

            NavigationStack {
                ListView()
            }
        }
        .task {
            cloudKitAccountService.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                cloudKitAccountService.refresh()
            }
        }
    }
}

#Preview {
    MainContentView()
}
