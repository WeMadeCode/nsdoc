//
//  MainContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/23.
//

import SwiftUI

#if os(iOS)
struct MainContentView: View {
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            ListView()
                .opacity(showsSplash ? 0 : 1)

            if showsSplash {
                AppSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(950))

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.34)) {
                    showsSplash = false
                }
            }
        }
    }
}

#Preview {
    MainContentView()
}
#endif
