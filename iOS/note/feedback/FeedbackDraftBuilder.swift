//
//  FeedbackDraftBuilder.swift
//  note
//
//  Created by Codex on 2026/6/3.
//

struct FeedbackDraftBuilder {
    func mailDraft(
        category: FeedbackCategory,
        message: String,
        contact: String
    ) -> FeedbackMailDraft {
        FeedbackMailDraft(
            subject: "一页文档反馈 - \(category.rawValue)",
            body: mailBody(category: category, message: message, contact: contact)
        )
    }

    func clipboardText(
        category: FeedbackCategory,
        message: String,
        contact: String
    ) -> String {
        """
        \(mailBody(category: category, message: message, contact: contact))

        收件人：\(FeedbackContactConfig.email)
        """
    }

    private func mailBody(
        category: FeedbackCategory,
        message: String,
        contact: String
    ) -> String {
        """
        反馈类型：\(category.rawValue)

        反馈内容：
        \(message.isEmpty ? "请在这里补充你的想法或遇到的问题。" : message)

        联系方式：
        \(contact.isEmpty ? "未填写" : contact)
        """
    }
}
