//
//  ContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/20.
//

import SwiftUI

struct ListView: View {
    @State private var isPrivateFolderExpanded = true

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    HomeHeader()
                        .padding(.horizontal, 22)
                        .padding(.top, 14)
                        .padding(.bottom, 22)

                    RecentRow()
                        .padding(.horizontal, 22)
                        .padding(.bottom, 42)

                    PrivateSectionHeader(
                        folder: MockLibraryData.privateFolder,
                        isExpanded: isPrivateFolderExpanded
                    ) {
                        withAnimation(.snappy(duration: 0.22)) {
                            isPrivateFolderExpanded.toggle()
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)

                    if isPrivateFolderExpanded {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(MockLibraryData.privateFolder.notes) { note in
                                NavigationLink {
                                    EditorView(article: note.article)
                                } label: {
                                    NoteRow(note: note)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.bottom, 116)
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                HomeActionBar()
            }
        }
    }
}

private struct HomeHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))

                    Text("一")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 34, height: 34)

                Text("一页")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.leading, 8)
            .padding(.trailing, 18)
            .frame(height: 56)
            .background(Color(.secondarySystemBackground), in: Capsule())

            Spacer()

            HeaderIconButton(systemImage: "tray")
            HeaderIconButton(systemImage: "ellipsis")
        }
    }
}

private struct HeaderIconButton: View {
    let systemImage: String

    var body: some View {
        Button {
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: systemImage == "ellipsis" ? .bold : .medium))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
                .background(Color(.secondarySystemBackground), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct RecentRow: View {
    var body: some View {
        Button {
        } label: {
            HStack(spacing: 8) {
                Text("最近")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PrivateSectionHeader: View {
    let folder: MockFolder
    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggle) {
                HStack(spacing: 8) {
                    Text(folder.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(folder.notes.count)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Button {
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)

            NavigationLink {
                EditorView(article: nil)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct HomeActionBar: View {
    var body: some View {
        HStack(spacing: 14) {
            NavigationLink {
                SearchView(notes: MockLibraryData.privateFolder.notes)
            } label: {
                HomeSearchField()
            }
            .buttonStyle(.plain)

            NavigationLink {
                EditorView(article: nil)
            } label: {
                FloatingActionButton(systemImage: "square.and.pencil")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground).opacity(0),
                    Color(.systemBackground).opacity(0.92),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

private struct HomeSearchField: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.secondary)

            Text("搜索文档")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
    }
}

private struct FloatingActionButton: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 28, weight: .regular))
            .foregroundStyle(.primary)
            .frame(width: 66, height: 66)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
    }
}

private struct SearchView: View {
    let notes: [MockNote]
    @State private var keyword = ""

    private var searchResults: [MockNote] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else {
            return notes
        }

        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(trimmedKeyword) ||
            note.preview.localizedCaseInsensitiveContains(trimmedKeyword)
        }
    }

    var body: some View {
        List {
            ForEach(searchResults) { note in
                NavigationLink {
                    EditorView(article: note.article)
                } label: {
                    SearchResultRow(note: note)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("搜索")
        .searchable(text: $keyword, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索文档")
        .overlay {
            if searchResults.isEmpty {
                ContentUnavailableView.search(text: keyword)
            }
        }
    }
}

private struct NoteRow: View {
    let note: MockNote

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "chevron.right")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(width: 20, height: 44)

            Image(systemName: "doc.text")
                .font(.system(size: 29, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !note.preview.isEmpty {
                    Text(note.preview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 62)
    }
}

private struct SearchResultRow: View {
    let note: MockNote

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text(note.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(note.preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct MockFolder: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let summary: String
    let notes: [MockNote]

    static func == (lhs: MockFolder, rhs: MockFolder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private struct MockNote: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let preview: String
    let updatedAt: Date

    var article: Article {
        Article(title: title, markdownText: preview, createDate: updatedAt, updateDate: updatedAt)
    }
}

private enum MockLibraryData {
    static let privateFolder = MockFolder(
        name: "私人",
        summary: "默认文件夹，所有新文档都会先放在这里",
        notes: [
            MockNote(title: "欢迎使用一页", preview: "默认私人文件夹，文档在首页展开查看。", updatedAt: .now.addingTimeInterval(-1800)),
            MockNote(title: "2026-05-19 产品记录", preview: "首页参考 Notion，底部悬浮搜索和新建。", updatedAt: .now.addingTimeInterval(-3600)),
            MockNote(title: "2026-05-18 设计回顾", preview: "文件夹展开、文档列表、浅色键盘工具条。", updatedAt: .now.addingTimeInterval(-7200)),
            MockNote(title: "Todo", preview: "把假数据替换成 SwiftData 查询。", updatedAt: .now.addingTimeInterval(-86400)),
            MockNote(title: "新页面", preview: "空文档创建后默认属于私人文件夹。", updatedAt: .now.addingTimeInterval(-86400 * 2)),
            MockNote(title: "搜索体验", preview: "支持标题和正文摘要搜索。", updatedAt: .now.addingTimeInterval(-86400 * 3)),
            MockNote(title: "编辑器工具栏优化", preview: "键盘上方工具条采用 iOS 浅色模式样式。", updatedAt: .now.addingTimeInterval(-86400 * 4)),
            MockNote(title: "CloudKit 状态处理", preview: "未登录 iCloud 时本地可编辑。", updatedAt: .now.addingTimeInterval(-86400 * 5)),
            MockNote(title: "2026-05-12", preview: "记录一个完整的产品迭代节奏。", updatedAt: .now.addingTimeInterval(-86400 * 6)),
            MockNote(title: "2026-05-10", preview: "首页列表需要更像工作台，而不是设置页。", updatedAt: .now.addingTimeInterval(-86400 * 8)),
            MockNote(title: "2026-05-08", preview: "文档行保持轻量，少用边框和卡片。", updatedAt: .now.addingTimeInterval(-86400 * 10)),
            MockNote(title: "读书摘录", preview: "把值得回看的句子收在一个页面里。", updatedAt: .now.addingTimeInterval(-86400 * 12)),
            MockNote(title: "会议纪要模板", preview: "背景、结论、行动项。", updatedAt: .now.addingTimeInterval(-86400 * 14)),
            MockNote(title: "旅行清单", preview: "证件、充电器、耳机、备用衣物。", updatedAt: .now.addingTimeInterval(-86400 * 16)),
            MockNote(title: "灵感池", preview: "不急着分类，先把东西写下来。", updatedAt: .now.addingTimeInterval(-86400 * 18)),
            MockNote(title: "年度计划", preview: "产品、学习、健康、财务。", updatedAt: .now.addingTimeInterval(-86400 * 21)),
            MockNote(title: "App 发布检查表", preview: "图标、权限、隐私、首屏、崩溃日志。", updatedAt: .now.addingTimeInterval(-86400 * 24)),
            MockNote(title: "长期想法", preview: "有些想法先放着，隔一段时间再判断。", updatedAt: .now.addingTimeInterval(-86400 * 30))
        ]
    )
}

#Preview {
    ListView()
}
