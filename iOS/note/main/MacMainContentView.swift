//
//  MacMainContentView.swift
//  note
//
//  Created by Codex on 2026/6/10.
//

#if os(macOS)
import SwiftData
import SwiftUI

struct MacMainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.sortOrder, order: .forward) private var folders: [Folder]
    @Query(sort: \Document.accessedAt, order: .reverse) private var documents: [Document]
    @State private var selectedDocumentID: UUID?
    @State private var searchText = ""

    private var defaultFolder: Folder? {
        folders.first { $0.isDefault && $0.deletedAt == nil }
    }

    private var folderDocuments: [Document] {
        guard let defaultFolder else {
            return []
        }

        return documents.filter { document in
            document.folderId == defaultFolder.id && document.deletedAt == nil
        }
    }

    private var visibleDocuments: [Document] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            return folderDocuments
        }

        return folderDocuments.filter { document in
            document.title.localizedCaseInsensitiveContains(keyword) ||
            document.excerpt.localizedCaseInsensitiveContains(keyword)
        }
    }

    private var selectedDocument: Document? {
        guard let selectedDocumentID else {
            return nil
        }

        return documents.first { $0.id == selectedDocumentID && $0.deletedAt == nil }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 260, ideal: 310, max: 380)
        } detail: {
            detail
        }
        .frame(minWidth: 920, minHeight: 640)
        .task {
            ensureDefaultFolder()
            selectInitialDocumentIfNeeded()
        }
        .onChange(of: documents.map(\.id)) { _, _ in
            selectInitialDocumentIfNeeded()
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    createDocumentAndSelect()
                } label: {
                    Label("新建笔记", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)

                Button(role: .destructive) {
                    deleteSelectedDocument()
                } label: {
                    Label("删除", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(selectedDocument == nil)
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("一页")
                    .font(.system(size: 28, weight: .semibold))

                TextField("搜索文档", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(20)

            List(selection: $selectedDocumentID) {
                Section {
                    ForEach(visibleDocuments) { document in
                        MacDocumentRow(document: document)
                            .tag(document.id)
                    }
                } header: {
                    Text(DefaultFolderService.defaultFolderName)
                }
            }
            .listStyle(.sidebar)
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var detail: some View {
        if let selectedDocument {
            EditorView(
                document: selectedDocument,
                showsCloseButton: false
            )
            .id(selectedDocument.id)
        } else {
            VStack(spacing: 14) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundStyle(.secondary)

                Text("选择或新建一篇笔记")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Button {
                    createDocumentAndSelect()
                } label: {
                    Label("新建笔记", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }

    @MainActor
    private func ensureDefaultFolder() {
        do {
            _ = try DefaultFolderService.findOrCreateDefaultFolder(in: modelContext)
        } catch {}
    }

    @MainActor
    private func selectInitialDocumentIfNeeded() {
        if let selectedDocumentID, folderDocuments.contains(where: { $0.id == selectedDocumentID }) {
            return
        }

        selectedDocumentID = folderDocuments.first?.id
    }

    @MainActor
    private func createDocumentAndSelect() {
        do {
            let folder = try DefaultFolderService.findOrCreateDefaultFolder(in: modelContext)
            let now = Date()
            let document = Document(
                folderId: folder.id,
                sortOrder: folderDocuments.count,
                createdAt: now,
                updatedAt: now,
                accessedAt: now
            )

            modelContext.insert(document)
            try modelContext.save()
            selectedDocumentID = document.id
        } catch {}
    }

    @MainActor
    private func deleteSelectedDocument() {
        guard let document = selectedDocument else {
            return
        }

        let documentID = document.id

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
            selectedDocumentID = folderDocuments.first { $0.id != documentID }?.id
        } catch {}
    }
}

private struct MacDocumentRow: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(document.title.isEmpty ? "未命名文档" : document.title)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)

            if !document.excerpt.isEmpty {
                Text(document.excerpt)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text(document.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}
#endif
