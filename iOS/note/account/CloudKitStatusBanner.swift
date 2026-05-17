//
//  CloudKitStatusBanner.swift
//  note
//
//  Created by Codex on 2026/5/17.
//

import SwiftUI

struct CloudKitStatusBanner: View {
    let state: CloudKitAccountState
    let refresh: () -> Void

    var body: some View {
        if shouldShowBanner {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(state.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("重新检查 CloudKit 状态")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
        }
    }

    private var shouldShowBanner: Bool {
        switch state {
        case .available:
            return false
        default:
            return true
        }
    }

    private var iconName: String {
        switch state {
        case .checking:
            return "icloud"
        case .available:
            return "icloud"
        case .noAccount:
            return "person.crop.circle.badge.exclamationmark"
        case .restricted:
            return "lock.icloud"
        case .couldNotDetermine, .error:
            return "exclamationmark.icloud"
        }
    }

    private var iconColor: Color {
        switch state {
        case .checking:
            return .secondary
        case .available:
            return .green
        case .couldNotDetermine:
            return .orange
        case .noAccount, .restricted, .error:
            return .red
        }
    }
}

#Preview {
    VStack {
        CloudKitStatusBanner(state: .noAccount, refresh: {})
        CloudKitStatusBanner(state: .couldNotDetermine, refresh: {})
        CloudKitStatusBanner(state: .available, refresh: {})
    }
}
