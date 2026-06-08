import Foundation
import SwiftUI

@MainActor
final class ArchiveStore: ObservableObject {
    @Published var documents: [DocumentItem] = []
    @Published var notes: [NoteItem] = []
    @Published var chatSessions: [ChatSession] = []
    @Published var tasks: [TaskItem] = []
    @Published var reminders: [ReminderItem] = []
    @Published var ledgerEntries: [LedgerEntry] = []
    @Published var settings = AppSettings()
    @Published var lastError: String?
    @Published var isProcessingAI = false

    private let storage = LocalFileStorage()
    private let parser = DocumentParserService()
    private let searchService = SearchService()
    private let aiService = AIService()

    init() {
        load()
    }

    var latestSession: ChatSession? {
        chatSessions.sorted { $0.updatedAt > $1.updatedAt }.first
    }

    var todayNoteCount: Int {
        notes.filter { Calendar.current.isDateInToday($0.createdAt) }.count
    }

    var recentDocuments: [DocumentItem] {
        documents.sorted { $0.updatedAt > $1.updatedAt }.prefix(5).map { $0 }
    }

    func load() {
        do {
            if let snapshot = try storage.loadSnapshot() {
                documents = snapshot.documents
                notes = snapshot.notes
                chatSessions = snapshot.chatSessions
                tasks = snapshot.tasks
                reminders = snapshot.reminders
                ledgerEntries = snapshot.ledgerEntries
                settings = snapshot.settings
            } else {
                let sample = ArchiveSnapshot.sample
                documents = sample.documents
                notes = sample.notes
                chatSessions = sample.chatSessions
                tasks = sample.tasks
                reminders = sample.reminders
                ledgerEntries = sample.ledgerEntries
                settings = sample.settings
                save()
            }
        } catch {
            lastError = error.localizedDescription
            let sample = ArchiveSnapshot.sample
            documents = sample.documents
            notes = sample.notes
            chatSessions = sample.chatSessions
            tasks = sample.tasks
            reminders = sample.reminders
            ledgerEntries = sample.ledgerEntries
            settings = sample.settings
        }
    }

    func save() {
        do {
            try storage.saveSnapshot(
                ArchiveSnapshot(
                    documents: documents,
                    notes: notes,
                    chatSessions: chatSessions,
                    tasks: tasks,
                    reminders: reminders,
                    ledgerEntries: ledgerEntries,
                    settings: settings
                )
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    func addQuickNote() {
        let now = Date()
        notes.insert(
            NoteItem(
                title: "Untitled Note",
                body: "",
                category: .notes,
                tags: [],
                aiSummary: "",
                isFavorite: false,
                createdAt: now,
                updatedAt: now
            ),
            at: 0
        )
        save()
    }

    func update(note: NoteItem, title: String, body: String) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].title = title.isEmpty ? "Untitled Note" : title
        notes[index].body = body
        notes[index].updatedAt = Date()
        save()
    }

    func toggleFavorite(document: DocumentItem) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index].isFavorite.toggle()
        documents[index].updatedAt = Date()
        save()
    }

    func toggleFavorite(note: NoteItem) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isFavorite.toggle()
        notes[index].updatedAt = Date()
        save()
    }

    func summarize(document: DocumentItem) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index].aiSummary = aiService.summary(from: document.extractedText)
        documents[index].updatedAt = Date()
        save()
    }

    func generateTags(document: DocumentItem) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        let generated = aiService.keywords(from: document.extractedText)
        documents[index].tags = Array(Set(documents[index].tags + generated)).sorted()
        documents[index].updatedAt = Date()
        save()
    }

    func generateTasks(from document: DocumentItem) {
        let suggestions = aiService.todoSuggestions(from: document.extractedText)
        guard !suggestions.isEmpty else { return }
        let now = Date()
        let newTasks = suggestions.map {
            TaskItem(
                title: $0,
                notes: "Generated from \(document.title).",
                priority: .normal,
                dueDate: nil,
                isCompleted: false,
                createdAt: now,
                updatedAt: now
            )
        }
        tasks.insert(contentsOf: newTasks, at: 0)
        save()
    }

    func importFile(from url: URL) {
        do {
            let copied = try storage.copyIntoImports(from: url)
            let parsed = try parser.parse(url: copied)
            let now = Date()
            documents.insert(
                DocumentItem(
                    title: url.deletingPathExtension().lastPathComponent,
                    kind: parsed.kind,
                    storedFileName: copied.lastPathComponent,
                    originalFileName: url.lastPathComponent,
                    extractedText: parsed.extractedText,
                    aiSummary: "",
                    category: .documents,
                    tags: [parsed.kind.title.lowercased()],
                    isFavorite: false,
                    createdAt: now,
                    updatedAt: now,
                    lastOpenedAt: now
                ),
                at: 0
            )
            save()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func search(_ query: String) -> [SearchResult] {
        searchService.search(
            query: query,
            documents: documents,
            notes: notes,
            limit: settings.preferredSearchLimit
        )
    }

    func askLocalAI(_ question: String) {
        let now = Date()
        var session = latestSession ?? ChatSession(title: "Local AI Assistant", messages: [], createdAt: now, updatedAt: now)
        session.messages.append(
            ChatMessage(role: .user, content: question, relatedDocumentIDs: [], createdAt: now)
        )

        let results = search(question)
        let answer = aiService.localAnswer(for: question, results: results)
        session.messages.append(
            ChatMessage(
                role: .assistant,
                content: answer,
                relatedDocumentIDs: [],
                createdAt: Date()
            )
        )
        session.updatedAt = Date()
        upsert(session: session)
        save()
    }

    func askAI(_ question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isProcessingAI else { return }

        let now = Date()
        var session = latestSession ?? ChatSession(title: "Local AI Assistant", messages: [], createdAt: now, updatedAt: now)
        let localResults = search(trimmed)
        session.messages.append(
            ChatMessage(role: .user, content: trimmed, relatedDocumentIDs: [], createdAt: now)
        )
        session.updatedAt = now
        upsert(session: session)
        isProcessingAI = true
        save()

        Task {
            let answer: String
            do {
                answer = try await aiService.answer(
                    question: trimmed,
                    results: localResults,
                    settings: settings
                )
            } catch {
                answer = "AI request failed: \(error.localizedDescription)\n\n" + aiService.localAnswer(for: trimmed, results: localResults)
            }

            await MainActor.run {
                var updated = self.latestSession ?? session
                updated.messages.append(
                    ChatMessage(
                        role: .assistant,
                        content: answer,
                        relatedDocumentIDs: [],
                        createdAt: Date()
                    )
                )
                updated.updatedAt = Date()
                self.upsert(session: updated)
                self.isProcessingAI = false
                self.save()
            }
        }
    }

    func addTask(title: String, notes: String, priority: TaskPriority, dueDate: Date?) {
        let now = Date()
        tasks.insert(
            TaskItem(
                title: title.isEmpty ? "Untitled Task" : title,
                notes: notes,
                priority: priority,
                dueDate: dueDate,
                isCompleted: false,
                createdAt: now,
                updatedAt: now
            ),
            at: 0
        )
        save()
    }

    func toggleTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].updatedAt = Date()
        save()
    }

    func addReminder(title: String, date: Date, repeats: Bool, notes: String) {
        let now = Date()
        reminders.insert(
            ReminderItem(
                title: title.isEmpty ? "Untitled Reminder" : title,
                date: date,
                repeats: repeats,
                notes: notes,
                isDone: false,
                createdAt: now
            ),
            at: 0
        )
        save()
    }

    func toggleReminder(_ reminder: ReminderItem) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isDone.toggle()
        save()
    }

    func addLedgerEntry(title: String, amount: Double, type: LedgerType, category: String, note: String) {
        ledgerEntries.insert(
            LedgerEntry(
                title: title.isEmpty ? "Untitled Entry" : title,
                amount: amount,
                type: type,
                category: category.isEmpty ? "General" : category,
                date: Date(),
                note: note
            ),
            at: 0
        )
        save()
    }

    var openTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var upcomingReminderCount: Int {
        reminders.filter { !$0.isDone && $0.date >= Date() }.count
    }

    var monthlyBalance: Double {
        let calendar = Calendar.current
        return ledgerEntries
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { total, entry in
                total + (entry.type == .income ? entry.amount : -entry.amount)
            }
    }

    func saveSettings() {
        save()
    }

    func privacyNotice() -> String {
        aiService.privacyNotice(settings: settings)
    }

    private func upsert(session: ChatSession) {
        if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
            chatSessions[index] = session
        } else {
            chatSessions.insert(session, at: 0)
        }
    }
}
