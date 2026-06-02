//
//  HomeActionBar.swift
//  note
//
//  Created by Codex on 2026/6/2.
//

import SwiftData
import SwiftUI

struct HomeActionBar: View {
    let documents: [Document]
    @Binding var navigationPath: [HomeRoute]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 14) {
            Button {
                navigationPath.append(.search)
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
            navigationPath.append(.editor(document.id, autoFocusOnLoad: true))
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
