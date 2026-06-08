import SwiftUI

struct DocumentDetailView: View {
    @EnvironmentObject private var store: ArchiveStore
    let documentID: UUID

    private var document: DocumentItem? {
        store.documents.first { $0.id == documentID }
    }

    var body: some View {
        Group {
            if let document {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(document)
                        aiActions(document)
                        metadata(document)
                        extractedText(document)
                    }
                    .padding()
                }
                .background(AppTheme.background)
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("Document missing", systemImage: "questionmark.folder")
            }
        }
    }

    private func header(_ document: DocumentItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: document.kind == .image ? "photo" : "doc.text")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.originalFileName ?? document.title)
                        .font(.headline)
                    Text(document.kind.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    store.toggleFavorite(document: document)
                } label: {
                    Image(systemName: document.isFavorite ? "star.fill" : "star")
                }
            }

            if !document.aiSummary.isEmpty {
                Text(document.aiSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            FlowTags(tags: document.tags)
        }
        .padding()
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
    }

    private func aiActions(_ document: DocumentItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("AI organize")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                Button {
                    store.summarize(document: document)
                } label: {
                    Label("Summary", systemImage: "text.justify.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    store.generateTags(document: document)
                } label: {
                    Label("Tags", systemImage: "tag")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    store.generateTasks(from: document)
                } label: {
                    Label("To-dos", systemImage: "checklist")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    store.askAI("Summarize and explain \(document.title) using the local library context.")
                } label: {
                    Label("Ask", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func metadata(_ document: DocumentItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Details")
            LabeledContent("Category", value: document.category.localizedTitle)
            LabeledContent("Created", value: document.createdAt.compactDateTime)
            LabeledContent("Updated", value: document.updatedAt.compactDateTime)
            if let lastOpenedAt = document.lastOpenedAt {
                LabeledContent("Last opened", value: lastOpenedAt.compactDateTime)
            }
        }
        .padding()
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
    }

    private func extractedText(_ document: DocumentItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Extracted text")
            Text(document.extractedText.isEmpty ? "No extracted text available." : document.extractedText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding()
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
    }
}
