//
//  SearchView.swift
//  note
//
//  Created by Codex on 2026/6/2.
//

import SwiftUI

struct SearchView: View {
    let documents: [Document]
    @State private var keyword = ""

    private var searchResults: [Document] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else {
            return documents
        }

        return documents.filter { document in
            document.title.localizedCaseInsensitiveContains(trimmedKeyword) ||
            document.excerpt.localizedCaseInsensitiveContains(trimmedKeyword)
        }
    }

    var body: some View {
        List {
            ForEach(searchResults) { document in
                NavigationLink {
                    EditorView(document: document)
                } label: {
                    SearchResultRow(document: document)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("搜索")
        .searchable(text: $keyword, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索文档")
        .overlay {
            if searchResults.isEmpty {
                GeometryReader { proxy in
                    SearchEmptyState()
                        .frame(maxWidth: .infinity)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.43)
                }
            }
        }
    }
}

private struct SearchEmptyState: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)

            Text("未找到结果")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .padding(.bottom, 8)

            Text("请检查关键词或尝试重新搜索")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SearchResultRow: View {
    let document: Document

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text(document.title.isEmpty ? "未命名文档" : document.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(document.excerpt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}
