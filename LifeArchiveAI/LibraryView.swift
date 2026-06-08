import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var selectedCategory: ArchiveCategory?
    @State private var showingImporter = false

    var filteredDocuments: [DocumentItem] {
        guard let selectedCategory else { return store.documents }
        return store.documents.filter { $0.category == selectedCategory }
    }

    var filteredNotes: [NoteItem] {
        guard let selectedCategory else { return store.notes }
        return store.notes.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryButton(title: "All", category: nil)
                            ForEach(ArchiveCategory.allCases) { category in
                                categoryButton(title: category.localizedTitle, category: category)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Documents") {
                    if filteredDocuments.isEmpty {
                        EmptyStateView(symbol: "doc.badge.plus", title: "No documents", message: "Import files from the dashboard or toolbar.")
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredDocuments) { document in
                            NavigationLink {
                                DocumentDetailView(documentID: document.id)
                            } label: {
                                DocumentRow(document: document) {
                                    store.toggleFavorite(document: document)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }

                Section("Notes") {
                    if filteredNotes.isEmpty {
                        EmptyStateView(symbol: "note.text.badge.plus", title: "No notes", message: "Create a note to capture thoughts, tasks, or snippets.")
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredNotes) { note in
                            NavigationLink {
                                NoteEditorView(note: note)
                            } label: {
                                NoteRow(note: note) {
                                    store.toggleFavorite(note: note)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Library")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        store.addQuickNote()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "tray.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingImporter) {
                ImportDocumentPicker { url in
                    store.importFile(from: url)
                }
            }
        }
    }

    private func categoryButton(title: String, category: ArchiveCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.accent.opacity(0.22) : AppTheme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct NoteEditorView: View {
    @EnvironmentObject private var store: ArchiveStore
    @Environment(\.dismiss) private var dismiss
    let note: NoteItem
    @State private var title: String
    @State private var body: String

    init(note: NoteItem) {
        self.note = note
        _title = State(initialValue: note.title)
        _body = State(initialValue: note.body)
    }

    var body: some View {
        Form {
            Section("Title") {
                TextField("Note title", text: $title)
            }
            Section("Body") {
                TextEditor(text: $body)
                    .frame(minHeight: 260)
            }
            Section("Tags") {
                if note.tags.isEmpty {
                    Text("No tags yet")
                        .foregroundStyle(.secondary)
                } else {
                    FlowTags(tags: note.tags)
                }
            }
        }
        .navigationTitle("Edit Note")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.update(note: note, title: title, body: body)
                    dismiss()
                }
            }
        }
    }
}

struct FlowTags: View {
    let tags: [String]

    var body: some View {
        HStack {
            ForEach(tags, id: \.self) { tag in
                TagPill(text: tag)
            }
        }
    }
}
