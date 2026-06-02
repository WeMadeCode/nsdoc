//
//  PrivateSectionHeader.swift
//  note
//
//  Created by Codex on 2026/6/2.
//

import SwiftUI

struct PrivateSectionHeader: View {
    let title: String
    let documentCount: Int
    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggle) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.18), value: isExpanded)

                    Spacer()

                    Text("\(documentCount)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HomePalette.primaryBlue)
                        .monospacedDigit()
                }
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
