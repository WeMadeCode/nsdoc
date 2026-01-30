//
//  ContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/20.
//

import SwiftUI
import SwiftData

struct ListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var articles: [Article]

    var body: some View {
        List {
            ForEach(articles) { article in
                NavigationLink(destination:
                    EditorView(
                        article: article
                    )
                    .toolbar(.hidden, for: .tabBar)
                ) {
                    ArticleRow(article: article)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    EditorView(
                        article: nil
                    )
                    .toolbar(.hidden, for: .tabBar)
                } label: {
                    Image(systemName: "pencil.tip.crop.circle.badge.plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(articles[index])
            }
        }
    }
}

// 列表行视图
struct ArticleRow: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题和日期
            HStack {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(article.createDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Markdown预览 (限制2行)
            Text(article.markdownText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    ListView()
        .modelContainer(for: Article.self, inMemory: true)
}
