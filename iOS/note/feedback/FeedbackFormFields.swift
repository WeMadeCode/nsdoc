//
//  FeedbackFormFields.swift
//  note
//
//  Created by Codex on 2026/6/3.
//

import SwiftUI

struct FeedbackFormFields: View {
    @Binding var category: FeedbackCategory
    @Binding var message: String
    @Binding var contact: String
    @FocusState.Binding var focusedField: FeedbackFocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            categoryPicker
            messageInput
            contactInput
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
                .focused($focusedField, equals: .message)
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
                .focused($focusedField, equals: .contact)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
