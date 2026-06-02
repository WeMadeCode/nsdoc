//
//  FeedbackContactSheet.swift
//  note
//
//  Created by Codex on 2026/6/2.
//

import MessageUI
import SwiftUI
import UIKit

private enum FeedbackContactConfig {
    static let email = "wemadecode@gmail.com"
    static let weChatID = "AnyObserver"
}

private enum FeedbackPalette {
    static let background = Color(red: 0.975, green: 0.980, blue: 0.992)
    static let card = Color(.systemBackground)
    static let primaryBlue = Color(red: 0.118, green: 0.365, blue: 0.976)
}

private enum FeedbackCategory: String, CaseIterable, Identifiable {
    case problem = "遇到问题"
    case suggestion = "功能建议"
    case experience = "体验反馈"
    case other = "其他"

    var id: String { rawValue }
}

private struct FeedbackMailDraft: Identifiable {
    let id = UUID()
    let subject: String
    let body: String
}

struct FeedbackContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var category: FeedbackCategory = .suggestion
    @State private var message = ""
    @State private var contact = ""
    @State private var mailDraft: FeedbackMailDraft?
    @State private var alert: FeedbackAlert?

    private var mailBody: String {
        """
        反馈类型：\(category.rawValue)

        反馈内容：
        \(message.isEmpty ? "请在这里补充你的想法或遇到的问题。" : message)

        联系方式：
        \(contact.isEmpty ? "未填写" : contact)
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    categoryPicker
                    messageInput
                    contactInput
                    contactActions
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 34)
            }
            .background(FeedbackPalette.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $mailDraft) { draft in
                MailComposer(
                    recipient: FeedbackContactConfig.email,
                    subject: draft.subject,
                    body: draft.body
                )
            }
            .alert(item: $alert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("好"))
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("反馈与联系")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)

            Text("遇到问题、想提建议，或者希望进一步聊聊，都可以从这里告诉我。")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("反馈类型")
                .font(.system(size: 16, weight: .semibold))

            Picker("反馈类型", selection: $category) {
                ForEach(FeedbackCategory.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var messageInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("反馈内容")
                .font(.system(size: 16, weight: .semibold))

            TextEditor(text: $message)
                .frame(minHeight: 132)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("比如：哪里不好用、希望增加什么、哪一步让你困惑...")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var contactInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("可选联系方式")
                .font(.system(size: 16, weight: .semibold))

            TextField("邮箱或微信号，方便我追问细节", text: $contact)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var contactActions: some View {
        VStack(spacing: 12) {
            Button {
                presentMailComposer()
            } label: {
                ContactActionRow(
                    systemImage: "envelope.fill",
                    title: "发送邮件",
                    subtitle: FeedbackContactConfig.email
                )
            }
            .buttonStyle(.plain)

            Button {
                UIPasteboard.general.string = FeedbackContactConfig.weChatID
                alert = FeedbackAlert(
                    title: "已复制微信号",
                    message: "添加时可以备注“产品反馈”。"
                )
            } label: {
                ContactActionRow(
                    systemImage: "qrcode.viewfinder",
                    title: "复制微信号",
                    subtitle: "\(FeedbackContactConfig.weChatID)，添加时可备注“产品反馈”"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func presentMailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            UIPasteboard.general.string = "\(mailBody)\n\n收件人：\(FeedbackContactConfig.email)"
            alert = FeedbackAlert(
                title: "无法直接发送邮件",
                message: "当前设备没有可用的邮件账户。我已把反馈内容和收件邮箱复制到剪贴板。"
            )
            return
        }

        mailDraft = FeedbackMailDraft(
            subject: "一页文档反馈 - \(category.rawValue)",
            body: mailBody
        )
    }
}

private struct ContactActionRow: View {
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

private struct MailComposer: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
        }
    }
}

private struct FeedbackAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
