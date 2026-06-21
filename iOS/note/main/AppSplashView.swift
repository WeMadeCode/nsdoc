//
//  AppSplashView.swift
//  note
//
//  Created by Codex on 2026/5/28.
//

import SwiftUI

#if os(iOS)
struct AppSplashView: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                SplashPalette.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image("yiyue-logo-mark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .accessibilityLabel("一页")

                    VStack(spacing: 7) {
                        Text("一页")
                            .font(.system(size: 30, weight: .semibold, design: .default))
                            .foregroundStyle(SplashPalette.title)
                            .lineLimit(1)

                        Text("写下只属于你的想法")
                            .font(.system(size: 17, weight: .medium, design: .default))
                            .foregroundStyle(SplashPalette.slogan)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)
                    }
                }
                .padding(.horizontal, 40)
                .position(
                    x: proxy.size.width / 2,
                    y: proxy.size.height / 2 - 24
                )
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

private enum SplashPalette {
    static let background = Color(red: 0.976, green: 0.980, blue: 0.992)
    static let title = Color(red: 0.090, green: 0.102, blue: 0.125)
    static let slogan = Color(red: 0.353, green: 0.380, blue: 0.439)
}

#Preview {
    AppSplashView()
}
#endif
