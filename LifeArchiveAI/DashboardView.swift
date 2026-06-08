import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var showingImporter = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricTile(title: "Notes today", value: "\(store.todayNoteCount)", symbol: "note.text", tint: AppTheme.blush)
                        MetricTile(title: "Library files", value: "\(store.documents.count)", symbol: "folder", tint: AppTheme.accent)
                        MetricTile(title: "Open tasks", value: "\(store.openTaskCount)", symbol: "checklist", tint: AppTheme.lilac)
                        MetricTile(title: "Month balance", value: store.monthlyBalance.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")), symbol: "chart.pie", tint: .teal)
                    }

                    quickActions
                    moduleGrid

                    SectionHeader("Recent imports")
                    if store.recentDocuments.isEmpty {
                        EmptyStateView(symbol: "tray", title: "No imports yet", message: "Import a text, Markdown, PDF, image, or Office file to start building your local library.")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(store.recentDocuments) { document in
                                NavigationLink {
                                    DocumentDetailView(documentID: document.id)
                                } label: {
                                    DocumentRow(document: document)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    SectionHeader("Latest AI context")
                    if let session = store.latestSession, let message = session.messages.last {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.title)
                                .font(.subheadline.weight(.semibold))
                            Text(message.content)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                            Text(session.updatedAt.compactDateTime)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Life Archive AI")
            .sheet(isPresented: $showingImporter) {
                ImportDocumentPicker { url in
                    store.importFile(from: url)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image("AppMascot")
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 5) {
                Text("Personal memory, local first")
                    .font(.title3.bold())
                Text("Files, notes, search, and AI context in one quiet workspace.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [AppTheme.mint.opacity(0.7), AppTheme.cream], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Quick actions")
            HStack(spacing: 10) {
                Button {
                    store.addQuickNote()
                } label: {
                    Label("Note", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showingImporter = true
                } label: {
                    Label("Import", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var moduleGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Modules")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                NavigationLink {
                    TasksView()
                } label: {
                    ModuleTile(title: "Tasks", symbol: "checklist", subtitle: "\(store.openTaskCount) open")
                }
                NavigationLink {
                    RemindersView()
                } label: {
                    ModuleTile(title: "Reminders", symbol: "calendar.badge.clock", subtitle: "\(store.upcomingReminderCount) upcoming")
                }
                NavigationLink {
                    LedgerView()
                } label: {
                    ModuleTile(title: "Ledger", symbol: "chart.pie", subtitle: "Monthly view")
                }
                NavigationLink {
                    ToolsView()
                } label: {
                    ModuleTile(title: "Tools", symbol: "wand.and.stars", subtitle: "Text and units")
                }
                NavigationLink {
                    PrivacyVaultView()
                } label: {
                    ModuleTile(title: "Private", symbol: "lock.shield", subtitle: "Protected area")
                }
                NavigationLink {
                    BackupView()
                } label: {
                    ModuleTile(title: "Backup", symbol: "externaldrive", subtitle: "Local snapshot")
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct ModuleTile: View {
    let title: String
    let symbol: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding()
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
    }
}
