//
//  NoteRow.swift
//  note
//
//  Created by Codex on 2026/6/2.
//

import SwiftUI

struct NoteRow: View {
    let document: Document

    private var iconStyle: (Color, Color, String) {
        switch document.documentType {
        case DocumentType.mindMap:
            return (HomePalette.violet, Color(red: 0.733, green: 0.439, blue: 0.961), "square.grid.2x2.fill")
        case DocumentType.whiteboard:
            return (Color(red: 0.067, green: 0.651, blue: 0.780), HomePalette.mint, "scribble.variable")
        case DocumentType.flowchart:
            return (Color(red: 0.984, green: 0.537, blue: 0.180), HomePalette.yellow, "flowchart.fill")
        default:
            return (HomePalette.primaryBlue, HomePalette.cyan, "doc.text.fill")
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconStyle.0.opacity(0.10))

                Image(systemName: iconStyle.2)
                    .font(.system(size: 24, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(iconStyle.0, iconStyle.1)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 7) {
                Text(document.title.isEmpty ? "未命名文档" : document.title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .baselineOffset(0.5)

                    Text("最近访问于 \(document.accessedAt.homeRecentAccessedText)")
                        .font(.system(size: 14, weight: .regular))
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 76)
    }
}

private extension Date {
    var homeRecentAccessedText: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")

        if calendar.isDateInToday(self) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: self)
        }

        if calendar.component(.year, from: self) == calendar.component(.year, from: Date()) {
            formatter.dateFormat = "M月d日 HH:mm"
            return formatter.string(from: self)
        }

        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: self)
    }
}
