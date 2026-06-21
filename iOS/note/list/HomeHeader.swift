//
//  HomeHeader.swift
//  note
//
//  Created by Codex on 2026/6/2.
//

import SwiftUI

#if os(iOS)
struct HomeFloatingHeader: View {
    let onFeedback: () -> Void

    var body: some View {
        HomeHeader(onFeedback: onFeedback)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .top)

                    LinearGradient(
                        colors: [
                            HomePalette.background.opacity(0),
                            HomePalette.background.opacity(0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 28)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.white.opacity(0.36))
                    .frame(height: 0.5)
            }
    }
}

private struct HomeHeader: View {
    let onFeedback: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 12) {
                Image("yiyue-logo-mark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text("一页文档")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onFeedback) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HomePalette.primaryBlue)
                    .frame(width: 42, height: 42)
                    .background(HomePalette.card, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(HomePalette.primaryBlue.opacity(0.10), lineWidth: 1)
                    }
                    .shadow(color: HomePalette.primaryBlue.opacity(0.10), radius: 12, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("反馈与联系")
        }
        .frame(height: 58)
    }
}
#endif
