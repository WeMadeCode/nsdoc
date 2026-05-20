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
    @Query(sort: \Document.updatedAt, order: .reverse) private var documents: [Document]

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
                        .padding(.top, 14)
                        .padding(.bottom, 34)

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
            .background(Color(.systemBackground))
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

private struct HomeHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            HStack(spacing: 12) {
                Image("yiyue-logo-mark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

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
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.18), value: isExpanded)

                    Spacer()

                    Text("\(documentCount)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
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
    private let rowHeight: CGFloat = 62
    private let rowSpacing: CGFloat = 2
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
                .listRowBackground(Color(.systemBackground))
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
        .background(Color(.systemBackground))
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
                initialContentJSON: DocumentContentDefaults.emptyTiptapJSON
            )
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

    @MainActor
    private func createDocumentAndOpen() {
        do {
            let folder = try DefaultFolderService.findOrCreateDefaultFolder(in: modelContext)
            let now = Date()
            let document = Document(
                folderId: folder.id,
                sortOrder: documents.count,
                createdAt: now,
                updatedAt: now
            )
            let content = DocumentContent(
                documentId: document.id,
                contentFormat: DocumentContentFormat.tiptapJSON,
                contentJSON: DocumentContentDefaults.emptyTiptapJSON,
                createdAt: now
            )

            modelContext.insert(document)
            modelContext.insert(content)
            try modelContext.save()
            newDocument = document
        } catch {}
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
    let documents: [Document]
    @State private var keyword = ""

    private var searchResults: [Document] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else {
            return documents
        }

        return documents.filter { document in
            document.title.localizedCaseInsensitiveContains(trimmedKeyword) ||
            document.excerpt.localizedCaseInsensitiveContains(trimmedKeyword) ||
            document.plainText.localizedCaseInsensitiveContains(trimmedKeyword)
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

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text")
                .font(.system(size: 29, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.title.isEmpty ? "未命名文档" : document.title)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !document.excerpt.isEmpty {
                    Text(document.excerpt)
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
