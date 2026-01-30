//
//  MainContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/23.
//

import SwiftUI

struct MainContentView: View {
    @State private var selectedTab = 0
        
    var body: some View {
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
}

#Preview {
    MainContentView()
}
