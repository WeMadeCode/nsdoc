//
//  FeedbackContactModels.swift
//  note
//
//  Created by Codex on 2026/6/3.
//

import SwiftUI

enum FeedbackContactConfig {
    static let email = "wemadecode@gmail.com"
    static let weChatID = "AnyObserver"
}

enum FeedbackPalette {
    static let background = Color(red: 0.975, green: 0.980, blue: 0.992)
    static let card = Color(.systemBackground)
    static let primaryBlue = Color(red: 0.118, green: 0.365, blue: 0.976)
}

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case problem = "遇到问题"
    case suggestion = "功能建议"
    case experience = "体验反馈"
    case other = "其他"

    var id: String { rawValue }
}

struct FeedbackMailDraft: Identifiable {
    let id = UUID()
    let subject: String
    let body: String
}

struct FeedbackAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum FeedbackFocusedField {
    case message
    case contact
}
