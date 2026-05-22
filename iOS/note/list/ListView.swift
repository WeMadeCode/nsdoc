//
//  ContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/20.
//

import SwiftUI
import SwiftData

struct ListView: View {
    @State private var isPrivateFolderExpanded = true
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.sortOrder, order: .forward) private var folders: [Folder]
    @Query(sort: \Document.accessedAt, order: .reverse) private var documents: [Document]

    private var defaultFolder: Folder? {
        folders.first { $0.isDefault && $0.deletedAt == nil }
    }

    private var currentFolderName: String {
        defaultFolder?.name ?? DefaultFolderService.defaultFolderName
    }

    private var currentFolderDocuments: [Document] {
        guard let defaultFolder else {
            return []
        }

        return documents.filter { document in
            document.folderId == defaultFolder.id && document.deletedAt == nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HomeHeader()
                        .padding(.horizontal, 22)
                        .padding(.top, 12)
                        .padding(.bottom, 18)

                    PrivateSectionHeader(
                        title: currentFolderName,
                        documentCount: currentFolderDocuments.count,
                        isExpanded: isPrivateFolderExpanded
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isPrivateFolderExpanded.toggle()
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, isPrivateFolderExpanded ? 12 : 0)
                    .zIndex(1)

                    NotesTree(
                        documents: currentFolderDocuments,
                        isExpanded: isPrivateFolderExpanded
                    )
                }
                .padding(.bottom, 116)
            }
            .background(HomePalette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                HomeActionBar(documents: currentFolderDocuments)
            }
            .task {
                ensureDefaultFolder()
            }
        }
    }

    @MainActor
    private func ensureDefaultFolder() {
        do {
            _ = try DefaultFolderService.findOrCreateDefaultFolder(in: modelContext)
        } catch {}
    }
}

private enum HomePalette {
    static let background = Color(red: 0.975, green: 0.980, blue: 0.992)
    static let card = Color(.systemBackground)
    static let primaryBlue = Color(red: 0.118, green: 0.365, blue: 0.976)
    static let cyan = Color(red: 0.000, green: 0.706, blue: 0.902)
    static let mint = Color(red: 0.122, green: 0.812, blue: 0.624)
    static let yellow = Color(red: 1.000, green: 0.733, blue: 0.082)
    static let violet = Color(red: 0.553, green: 0.392, blue: 0.941)
}

private struct HomeHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 12) {
                Image("yiyue-logo-mark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text("一页文档")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .frame(height: 58)
    }
}

private struct PrivateSectionHeader: View {
    let title: String
    let documentCount: Int
    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggle) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.18), value: isExpanded)

                    Spacer()

                    Text("\(documentCount)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HomePalette.primaryBlue)
                        .monospacedDigit()
                }
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(HomePalette.card, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

private struct NotesTree: View {
    let documents: [Document]
    let isExpanded: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var deletingDocumentIDs: Set<UUID> = []
    private let rowHeight: CGFloat = 76
    private let rowSpacing: CGFloat = 4
    private let rowDeleteAnimation = Animation.easeInOut(duration: 0.24)

    private var visibleDocuments: [Document] {
        documents.filter { document in
            !deletingDocumentIDs.contains(document.id)
        }
    }

    private var expandedHeight: CGFloat {
        guard !visibleDocuments.isEmpty else {
            return 0
        }

        return CGFloat(visibleDocuments.count) * rowHeight + CGFloat(visibleDocuments.count - 1) * rowSpacing
    }

    var body: some View {
        List {
            ForEach(visibleDocuments) { document in
                NavigationLink {
                    EditorView(document: document)
                } label: {
                    NoteRow(document: document)
                        .frame(height: rowHeight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                    } label: {
                        Label("取消", systemImage: "xmark")
                    }
                    .tint(Color(.systemGray3))

                    Button(role: .destructive) {
                        hardDeleteDocument(document)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(HomePalette.background)
                .transition(
                    .asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    )
                )
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .background(HomePalette.background)
        .frame(height: expandedHeight, alignment: .top)
        .frame(height: isExpanded ? expandedHeight : 0, alignment: .top)
        .clipped()
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
        .animation(rowDeleteAnimation, value: visibleDocuments.map(\.id))
    }

    @MainActor
    private func hardDeleteDocument(_ document: Document) {
        let documentID = document.id

        withAnimation(rowDeleteAnimation) {
            _ = deletingDocumentIDs.insert(documentID)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            do {
                let contentDescriptor = FetchDescriptor<DocumentContent>(
                    predicate: #Predicate { content in
                        content.documentId == documentID
                    }
                )
                let attachmentDescriptor = FetchDescriptor<Attachment>(
                    predicate: #Predicate { attachment in
                        attachment.documentId == documentID
                    }
                )

                try modelContext.fetch(contentDescriptor).forEach { content in
                    modelContext.delete(content)
                }
                try modelContext.fetch(attachmentDescriptor).forEach { attachment in
                    modelContext.delete(attachment)
                }
                modelContext.delete(document)
                try modelContext.save()
            } catch {
                withAnimation(rowDeleteAnimation) {
                    _ = deletingDocumentIDs.remove(documentID)
                }
            }
        }
    }
}

private struct HomeActionBar: View {
    let documents: [Document]
    @Environment(\.modelContext) private var modelContext
    @State private var newDocument: Document?

    var body: some View {
        HStack(spacing: 14) {
            NavigationLink {
                SearchView(documents: documents)
            } label: {
                HomeSearchField()
            }
            .buttonStyle(.plain)

            Button {
                createDocumentAndOpen()
            } label: {
                FloatingActionButton(systemImage: "square.and.pencil")
            }
            .buttonStyle(.plain)
        }
        .navigationDestination(item: $newDocument) { document in
            EditorView(
                document: document,
                autoFocusOnLoad: true
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [
                    HomePalette.background.opacity(0),
                    HomePalette.background.opacity(0.94),
                    HomePalette.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    @MainActor
    private func createDocumentAndOpen() {
        do {
            let folder = try DefaultFolderService.findOrCreateDefaultFolder(in: modelContext)
            let now = Date()
            let document = Document(
                folderId: folder.id,
                sortOrder: documents.count,
                createdAt: now,
                updatedAt: now,
                accessedAt: now
            )

            modelContext.insert(document)
            try modelContext.save()
            newDocument = document
        } catch {}
    }
}

private struct HomeSearchField: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(HomePalette.primaryBlue.opacity(0.82))

            Text("搜索文档")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(HomePalette.card, in: Capsule())
        .overlay {
            Capsule()
                .stroke(HomePalette.primaryBlue.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: HomePalette.primaryBlue.opacity(0.10), radius: 18, x: 0, y: 8)
    }
}

private struct FloatingActionButton: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 27, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 62, height: 62)
            .background(HomePalette.primaryBlue, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: HomePalette.primaryBlue.opacity(0.35), radius: 18, x: 0, y: 8)
    }
}

private struct SearchView: View {
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
                ContentUnavailableView.search(text: keyword)
            }
        }
    }
}

private struct NoteRow: View {
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

#Preview {
    ListView()
}
