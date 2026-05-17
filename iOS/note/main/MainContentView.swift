//
//  MainContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/23.
//

import SwiftUI

struct MainContentView: View {
    @State private var selectedTab = 0
    @StateObject private var cloudKitAccountService = CloudKitAccountService()
    @Environment(\.scenePhase) private var scenePhase
        
    var body: some View {
        VStack(spacing: 0) {
            CloudKitStatusBanner(
                state: cloudKitAccountService.state,
                refresh: cloudKitAccountService.refresh
            )

            TabView(selection: $selectedTab) {
                // 首页标签
                NavigationStack{
                    ListView()
                }
                .tabItem {
                    Label("最近", systemImage: "pencil.and.list.clipboard")
                }
                .tag(0)
                
                // 统计
                NavigationStack{
                    YearCalendarView()
                }
                .tabItem {
                    Label("统计", systemImage: "square.grid.3x2")
                }
                .tag(1)
            }
            .tint(.blue) // 统一设置选中颜色
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
