//
//  FeedbackContactSheet.swift
//  note
//
//  Created by Codex on 2026/6/2.
//

import MessageUI
import SwiftUI
import UIKit

struct FeedbackContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var category: FeedbackCategory = .suggestion
    @State private var message = ""
    @State private var contact = ""
    @State private var mailDraft: FeedbackMailDraft?
    @State private var alert: FeedbackAlert?
    @State private var shouldDismissAfterAlert = false
    @FocusState private var focusedField: FeedbackFocusedField?

    private let draftBuilder = FeedbackDraftBuilder()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    FeedbackFormFields(
                        category: $category,
                        message: $message,
                        contact: $contact,
                        focusedField: $focusedField
                    )

                    FeedbackContactActions(
                        onSendMail: presentMailComposer,
                        onCopyWeChat: copyWeChatID
                    )
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

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("完成") {
                        focusedField = nil
                    }
                }
            }
            .sheet(item: $mailDraft) { draft in
                FeedbackMailComposer(
                    recipient: FeedbackContactConfig.email,
                    subject: draft.subject,
                    body: draft.body,
                    onFinish: handleMailComposerResult
                )
            }
            .alert(item: $alert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("好")) {
                        if shouldDismissAfterAlert {
                            shouldDismissAfterAlert = false
                            dismiss()
                        }
                    }
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

    private func presentMailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            UIPasteboard.general.string = draftBuilder.clipboardText(
                category: category,
                message: message,
                contact: contact
            )
            alert = FeedbackAlert(
                title: "无法直接发送邮件",
                message: "当前设备没有可用的邮件账户。我已把反馈内容和收件邮箱复制到剪贴板。"
            )
            return
        }

        mailDraft = draftBuilder.mailDraft(
            category: category,
            message: message,
            contact: contact
        )
    }

    private func copyWeChatID() {
        UIPasteboard.general.string = FeedbackContactConfig.weChatID
        alert = FeedbackAlert(
            title: "已复制微信号",
            message: "添加时可以备注“产品反馈”。"
        )
    }

    private func handleMailComposerResult(_ result: MFMailComposeResult, error: Error?) {
        guard result == .sent else { return }

        shouldDismissAfterAlert = true
        alert = FeedbackAlert(
            title: "发送成功",
            message: "感谢你的反馈，我会尽快查看。"
        )
    }
}
