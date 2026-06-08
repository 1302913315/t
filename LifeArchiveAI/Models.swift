import Foundation

enum ArchiveCategory: String, Codable, CaseIterable, Identifiable {
    case notes = "Notes"
    case documents = "Documents"
    case photos = "Photos"
    case reminders = "Reminders"
    case tasks = "Tasks"
    case finance = "Finance"
    case tools = "Tools"
    case privateVault = "Private Vault"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .notes: return "Notes"
        case .documents: return "Files"
        case .photos: return "Album"
        case .reminders: return "Calendar"
        case .tasks: return "Tasks"
        case .finance: return "Ledger"
        case .tools: return "Tools"
        case .privateVault: return "Private"
        }
    }

    var symbolName: String {
        switch self {
        case .notes: return "note.text"
        case .documents: return "doc.text"
        case .photos: return "photo.on.rectangle"
        case .reminders: return "calendar.badge.clock"
        case .tasks: return "checklist"
        case .finance: return "chart.pie"
        case .tools: return "wand.and.stars"
        case .privateVault: return "lock.shield"
        }
    }
}

enum DocumentKind: String, Codable, CaseIterable, Identifiable {
    case text
    case markdown
    case pdf
    case image
    case office
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "Text"
        case .markdown: return "Markdown"
        case .pdf: return "PDF"
        case .image: return "Image"
        case .office: return "Office"
        case .other: return "Other"
        }
    }
}

struct DocumentItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var kind: DocumentKind
    var storedFileName: String?
    var originalFileName: String?
    var extractedText: String
    var aiSummary: String
    var category: ArchiveCategory
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?

    var searchableText: String {
        ([title, originalFileName ?? "", extractedText, aiSummary, category.localizedTitle] + tags)
            .joined(separator: " ")
    }
}

struct NoteItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var category: ArchiveCategory
    var tags: [String]
    var aiSummary: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    var searchableText: String {
        ([title, body, aiSummary, category.localizedTitle] + tags).joined(separator: " ")
    }
}

struct ChatSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
}

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    var id: UUID = UUID()
    var role: Role
    var content: String
    var relatedDocumentIDs: [UUID]
    var createdAt: Date
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"

    var id: String { rawValue }
}

struct TaskItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var notes: String
    var priority: TaskPriority
    var dueDate: Date?
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct ReminderItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var repeats: Bool
    var notes: String
    var isDone: Bool
    var createdAt: Date
}

enum LedgerType: String, Codable, CaseIterable, Identifiable {
    case expense = "Expense"
    case income = "Income"

    var id: String { rawValue }
}

struct LedgerEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var type: LedgerType
    var category: String
    var date: Date
    var note: String
}

struct ProviderConfig: Codable, Hashable {
    enum AuthMode: String, Codable, CaseIterable, Identifiable {
        case bearer = "Bearer Token"
        case apiKey = "API-Key Header"
        case xAPIKey = "X-API-Key Header"
        case custom = "Custom Header"

        var id: String { rawValue }
    }

    var baseURL: String = ""
    var requestPath: String = "/chat/completions"
    var apiKey: String = ""
    var modelName: String = ""
    var authMode: AuthMode = .bearer
    var customHeaderName: String = ""
    var timeoutSeconds: Double = 45
}

struct AppSettings: Codable, Hashable {
    var provider: ProviderConfig = ProviderConfig()
    var useDarkMode: Bool = false
    var enableAppLock: Bool = false
    var showPrivacyReminder: Bool = true
    var preferredSearchLimit: Int = 6
}

struct ArchiveSnapshot: Codable {
    var documents: [DocumentItem]
    var notes: [NoteItem]
    var chatSessions: [ChatSession]
    var tasks: [TaskItem]
    var reminders: [ReminderItem]
    var ledgerEntries: [LedgerEntry]
    var settings: AppSettings

    init(
        documents: [DocumentItem],
        notes: [NoteItem],
        chatSessions: [ChatSession],
        tasks: [TaskItem],
        reminders: [ReminderItem],
        ledgerEntries: [LedgerEntry],
        settings: AppSettings
    ) {
        self.documents = documents
        self.notes = notes
        self.chatSessions = chatSessions
        self.tasks = tasks
        self.reminders = reminders
        self.ledgerEntries = ledgerEntries
        self.settings = settings
    }

    static var sample: ArchiveSnapshot {
        let now = Date()
        return ArchiveSnapshot(
            documents: [
                DocumentItem(
                    title: "Welcome Guide",
                    kind: .markdown,
                    storedFileName: nil,
                    originalFileName: "Welcome.md",
                    extractedText: "Import files, write notes, search locally, then ask AI with only selected context.",
                    aiSummary: "A quick guide for the local-first knowledge workspace.",
                    category: .documents,
                    tags: ["guide", "local"],
                    isFavorite: true,
                    createdAt: now,
                    updatedAt: now,
                    lastOpenedAt: now
                )
            ],
            notes: [
                NoteItem(
                    title: "First Note",
                    body: "This app keeps personal notes and files on device first. AI calls are optional and configurable.",
                    category: .notes,
                    tags: ["idea"],
                    aiSummary: "Local-first starter note.",
                    isFavorite: true,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            chatSessions: [
                ChatSession(
                    title: "Local AI Assistant",
                    messages: [
                        ChatMessage(
                            role: .assistant,
                            content: "Ask about your local library. I will show when no local evidence is available.",
                            relatedDocumentIDs: [],
                            createdAt: now
                        )
                    ],
                    createdAt: now,
                    updatedAt: now
                )
            ],
            tasks: [
                TaskItem(
                    title: "Import first reference file",
                    notes: "Use the Library tab to add a local document.",
                    priority: .normal,
                    dueDate: Calendar.current.date(byAdding: .day, value: 1, to: now),
                    isCompleted: false,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            reminders: [
                ReminderItem(
                    title: "Review knowledge library",
                    date: Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now,
                    repeats: false,
                    notes: "Check imported files and generate summaries.",
                    isDone: false,
                    createdAt: now
                )
            ],
            ledgerEntries: [
                LedgerEntry(
                    title: "Notebook",
                    amount: 12.8,
                    type: .expense,
                    category: "Study",
                    date: now,
                    note: "Sample ledger entry."
                )
            ],
            settings: AppSettings()
        )
    }
}

struct SearchResult: Identifiable, Hashable {
    enum Source: String, Hashable {
        case document = "Document"
        case note = "Note"
    }

    var id: String
    var source: Source
    var title: String
    var excerpt: String
    var tags: [String]
    var score: Int
}

extension ArchiveSnapshot {
    enum CodingKeys: String, CodingKey {
        case documents
        case notes
        case chatSessions
        case tasks
        case reminders
        case ledgerEntries
        case settings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        documents = try container.decodeIfPresent([DocumentItem].self, forKey: .documents) ?? []
        notes = try container.decodeIfPresent([NoteItem].self, forKey: .notes) ?? []
        chatSessions = try container.decodeIfPresent([ChatSession].self, forKey: .chatSessions) ?? []
        tasks = try container.decodeIfPresent([TaskItem].self, forKey: .tasks) ?? []
        reminders = try container.decodeIfPresent([ReminderItem].self, forKey: .reminders) ?? []
        ledgerEntries = try container.decodeIfPresent([LedgerEntry].self, forKey: .ledgerEntries) ?? []
        settings = try container.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
    }
}
