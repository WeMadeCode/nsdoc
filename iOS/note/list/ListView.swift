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
    @Query(sort: \Article.updateDate, order: .reverse) private var articles: [Article]

    @State private var searchText = ""
    @State private var selectedFolderID = HomeFolder.primaryID
    @FocusState private var isSearchFocused: Bool

    private var folders: [HomeFolder] {
        [
            HomeFolder(id: HomeFolder.primaryID, name: "全部文档", icon: "tray.full", count: articles.count),
            HomeFolder(id: "default", name: "默认文件夹", icon: "folder", count: articles.count),
            HomeFolder(id: "ideas", name: "灵感", icon: "sparkle", count: 0),
            HomeFolder(id: "study", name: "学习", icon: "book.closed", count: 0),
            HomeFolder(id: "work", name: "工作", icon: "briefcase", count: 0)
        ]
    }

    private var visibleArticles: [Article] {
        if selectedFolderID == HomeFolder.primaryID || selectedFolderID == "default" {
            return articles
        }
        return []
    }

    var body: some View {
        ZStack {
            Color.yiyuePaperBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    folderSection
                    documentSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 92)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomSearchBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    EditorView(article: nil)
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("新建文档")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("一页")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)

            Text("把想法收进文件夹，回到需要的那一页。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "文件夹", actionTitle: "管理")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(folders) { folder in
                    FolderTile(
                        folder: folder,
                        isSelected: selectedFolderID == folder.id
                    ) {
                        selectedFolderID = folder.id
                    }
                }
            }
        }
    }

    private var documentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: selectedFolderName, actionTitle: "\(visibleArticles.count) 篇")

            if visibleArticles.isEmpty {
                EmptyDocumentView(isFolderEmpty: selectedFolderID != HomeFolder.primaryID && selectedFolderID != "default")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visibleArticles.enumerated()), id: \.element.persistentModelID) { index, article in
                        NavigationLink {
                            EditorView(article: article)
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            DocumentRow(article: article) {
                                delete(article)
                            }
                        }
                        .buttonStyle(.plain)

                        if index < visibleArticles.count - 1 {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                }
            }
        }
    }

    private var selectedFolderName: String {
        folders.first { $0.id == selectedFolderID }?.name ?? "文档"
    }

    private var bottomSearchBar: some View {
        HStack(spacing: 10) {
            if isSearchFocused || !searchText.isEmpty {
                focusedSearchPill

                Button {
                    searchText = ""
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(.secondary)
                        .frame(width: 58, height: 58)
                        .background(Color(.systemBackground).opacity(0.94))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                }
                .accessibilityLabel("关闭搜索")
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    isSearchFocused = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(width: 58, height: 58)
                        .background(Color(.systemBackground).opacity(0.94))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                }
                .accessibilityLabel("搜索")

                idleSearchPill

                NavigationLink {
                    EditorView(article: nil)
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(width: 58, height: 58)
                        .background(Color(.systemBackground).opacity(0.94))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                }
                .accessibilityLabel("新建文档")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isSearchFocused)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: searchText.isEmpty)
    }

    private var idleSearchPill: some View {
        Button {
            isSearchFocused = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())

                Text("搜索或问 AI")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(.leading, 10)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.black.opacity(0.045), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("搜索或问 AI")
    }

    private var focusedSearchPill: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.secondary)

            TextField("搜索或问 AI", text: $searchText)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .font(.system(size: 17, weight: .medium))

            Button {
                searchText = ""
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel("搜索筛选")
        }
        .padding(.leading, 18)
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.black.opacity(0.045), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
    }

    private func delete(_ article: Article) {
        withAnimation {
            modelContext.delete(article)
        }
    }
}

private struct HomeFolder: Identifiable {
    static let primaryID = "all"

    let id: String
    let name: String
    let icon: String
    let count: Int
}

private struct SectionHeader: View {
    let title: String
    let actionTitle: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Text(actionTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .textCase(.none)
    }
}

private struct FolderTile: View {
    let folder: HomeFolder
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: folder.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.yiyueInk : .secondary)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? Color.yiyueSoftGold : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(folder.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(folder.count) 篇")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
            .background(isSelected ? Color(.systemBackground) : Color(.secondarySystemBackground).opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.yiyueInk.opacity(0.16) : Color.black.opacity(0.05), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DocumentRow: View {
    let article: Article
    let delete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(displayTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(article.updateDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Text(displayExcerpt)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Menu {
                Button(role: .destructive, action: delete) {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("更多操作")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 13)
    }

    private var displayTitle: String {
        let trimmedTitle = article.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "未命名笔记" : trimmedTitle
    }

    private var displayExcerpt: String {
        let trimmedText = article.markdownText
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedText.isEmpty ? "暂无正文预览" : trimmedText
    }
}

private struct EmptyDocumentView: View {
    let isFolderEmpty: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isFolderEmpty ? "folder" : "doc.badge.plus")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)

            Text(isFolderEmpty ? "这个文件夹还没有文档" : "还没有文档")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            Text(isFolderEmpty ? "文件夹功能先完成界面，后续再接入真实归档。" : "从右上角新建一页，开始记录。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .padding(.horizontal, 18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
    }
}

private extension Color {
    static let yiyuePaperBackground = Color(red: 0.969, green: 0.953, blue: 0.918)
    static let yiyueSoftGold = Color(red: 0.827, green: 0.706, blue: 0.435).opacity(0.22)
    static let yiyueInk = Color(red: 0.122, green: 0.137, blue: 0.157)
}

#Preview {
    NavigationStack {
        ListView()
    }
    .modelContainer(for: Article.self, inMemory: true)
}
