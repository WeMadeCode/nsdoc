//
//  FeedbackContactActions.swift
//  note
//
//  Created by Codex on 2026/6/3.
//

import SwiftUI

struct FeedbackContactActions: View {
    let onSendMail: () -> Void
    let onCopyWeChat: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onSendMail) {
                FeedbackContactActionRow(
                    systemImage: "envelope.fill",
                    title: "发送邮件",
                    subtitle: FeedbackContactConfig.email
                )
            }
            .buttonStyle(.plain)

            Button(action: onCopyWeChat) {
                FeedbackContactActionRow(
                    systemImage: "qrcode.viewfinder",
                    title: "复制微信号",
                    subtitle: "\(FeedbackContactConfig.weChatID)，添加时可备注“产品反馈”"
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FeedbackContactActionRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(FeedbackPalette.primaryBlue, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(FeedbackPalette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        }
    }
}
