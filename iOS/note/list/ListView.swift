//
//  ContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/20.
//

import SwiftUI
import SwiftData

#if os(iOS)
enum HomeRoute: Hashable {
    case search
    case editor(UUID, autoFocusOnLoad: Bool = false)
}

struct ListView: View {
    @State private var isPrivateFolderExpanded = true
    @State private var deletingDocumentIDs: Set<UUID> = []
    @State private var isFeedbackPresented = false
    @State private var navigationPath: [HomeRoute] = []
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.sortOrder, order: .forward) private var folders: [Folder]
    @Query(sort: \Document.accessedAt, order: .reverse) private var documents: [Document]
    private let rowHeight: CGFloat = 76
    private let rowDeleteAnimation = Animation.easeInOut(duration: 0.24)

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

    private var visibleDocuments: [Document] {
        currentFolderDocuments.filter { document in
            !deletingDocumentIDs.contains(document.id)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    Color.clear
                        .frame(height: 88)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(HomePalette.background)
                }

                Section {
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
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(HomePalette.background)

                    if isPrivateFolderExpanded {
                        ForEach(visibleDocuments) { document in
                            NavigationLink(value: HomeRoute.editor(document.id)) {
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
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(HomePalette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .top) {
                HomeFloatingHeader {
                    isFeedbackPresented = true
                }
            }
            .safeAreaInset(edge: .bottom) {
                HomeActionBar(
                    documents: currentFolderDocuments,
                    navigationPath: $navigationPath
                )
            }
            .navigationDestination(for: HomeRoute.self) { route in
                destination(for: route)
            }
            .sheet(isPresented: $isFeedbackPresented) {
                FeedbackContactSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                ensureDefaultFolder()
            }
            .animation(.easeInOut(duration: 0.18), value: isPrivateFolderExpanded)
            .animation(rowDeleteAnimation, value: visibleDocuments.map(\.id))
        }
    }

    @ViewBuilder
    private func destination(for route: HomeRoute) -> some View {
        switch route {
        case .search:
            SearchView(documents: currentFolderDocuments) { document in
                navigationPath = [.editor(document.id)]
            }
        case let .editor(documentID, autoFocusOnLoad):
            if let document = documents.first(where: { $0.id == documentID && $0.deletedAt == nil }) {
                EditorView(
                    document: document,
                    autoFocusOnLoad: autoFocusOnLoad
                )
            } else {
                Text("文档不存在")
            }
        }
    }

    @MainActor
    private func ensureDefaultFolder() {
        do {
            _ = try DefaultFolderService.findOrCreateDefaultFolder(in: modelContext)
        } catch {}
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

#Preview {
    ListView()
}
#endif
