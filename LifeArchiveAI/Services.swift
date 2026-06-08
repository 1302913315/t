import Foundation
import UniformTypeIdentifiers

enum StorageError: LocalizedError {
    case unableToCreateDirectory
    case unableToReadFile

    var errorDescription: String? {
        switch self {
        case .unableToCreateDirectory:
            return "Unable to prepare the local storage directory."
        case .unableToReadFile:
            return "Unable to read the selected file."
        }
    }
}

enum AIServiceError: LocalizedError {
    case missingConfiguration
    case invalidURL
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "AI provider is not configured."
        case .invalidURL:
            return "AI provider URL is invalid."
        case .emptyResponse:
            return "AI provider returned an empty response."
        }
    }
}

final class LocalFileStorage {
    private let fileManager = FileManager.default

    var rootURL: URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("LifeArchiveAI", isDirectory: true)
    }

    var importsURL: URL {
        rootURL.appendingPathComponent("Imports", isDirectory: true)
    }

    var snapshotURL: URL {
        rootURL.appendingPathComponent("archive-store.json")
    }

    func prepareDirectories() throws {
        do {
            try fileManager.createDirectory(at: importsURL, withIntermediateDirectories: true)
        } catch {
            throw StorageError.unableToCreateDirectory
        }
    }

    func loadSnapshot() throws -> ArchiveSnapshot? {
        try prepareDirectories()
        guard fileManager.fileExists(atPath: snapshotURL.path) else { return nil }
        let data = try Data(contentsOf: snapshotURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ArchiveSnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: ArchiveSnapshot) throws {
        try prepareDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: [.atomic])
    }

    func copyIntoImports(from sourceURL: URL) throws -> URL {
        try prepareDirectories()
        let targetName = UUID().uuidString + "-" + sourceURL.lastPathComponent
        let targetURL = importsURL.appendingPathComponent(targetName)

        if sourceURL.startAccessingSecurityScopedResource() {
            defer { sourceURL.stopAccessingSecurityScopedResource() }
            try fileManager.copyItem(at: sourceURL, to: targetURL)
        } else {
            try fileManager.copyItem(at: sourceURL, to: targetURL)
        }

        return targetURL
    }
}

struct DocumentParserService {
    func parse(url: URL) throws -> (kind: DocumentKind, extractedText: String) {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt":
            return (.text, try readText(url: url))
        case "md", "markdown":
            return (.markdown, try readText(url: url))
        case "pdf":
            return (.pdf, "PDF imported. Text extraction is reserved for the PDFKit implementation pass.")
        case "png", "jpg", "jpeg", "heic", "webp":
            return (.image, "Image imported for local management. OCR is reserved for a later version.")
        case "doc", "docx", "xls", "xlsx", "ppt", "pptx":
            return (.office, "Office file imported for local management. Deep parsing is reserved for a later version.")
        default:
            return (.other, "File imported for local management.")
        }
    }

    private func readText(url: URL) throws -> String {
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        if let text = try? String(contentsOf: url, encoding: .unicode) {
            return text
        }
        throw StorageError.unableToReadFile
    }
}

struct SearchService {
    func search(query: String, documents: [DocumentItem], notes: [NoteItem], limit: Int) -> [SearchResult] {
        let terms = query
            .lowercased()
            .split { $0.isWhitespace || $0.isPunctuation }
            .map(String.init)

        guard !terms.isEmpty else { return [] }

        let documentResults = documents.compactMap { document -> SearchResult? in
            scoreResult(
                sourceID: document.id.uuidString,
                source: .document,
                title: document.title,
                searchable: document.searchableText,
                fallbackExcerpt: document.extractedText,
                tags: document.tags,
                terms: terms
            )
        }

        let noteResults = notes.compactMap { note -> SearchResult? in
            scoreResult(
                sourceID: note.id.uuidString,
                source: .note,
                title: note.title,
                searchable: note.searchableText,
                fallbackExcerpt: note.body,
                tags: note.tags,
                terms: terms
            )
        }

        return (documentResults + noteResults)
            .sorted { lhs, rhs in
                if lhs.score == rhs.score { return lhs.title < rhs.title }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map { $0 }
    }

    private func scoreResult(
        sourceID: String,
        source: SearchResult.Source,
        title: String,
        searchable: String,
        fallbackExcerpt: String,
        tags: [String],
        terms: [String]
    ) -> SearchResult? {
        let lower = searchable.lowercased()
        let score = terms.reduce(0) { partial, term in
            partial + lower.components(separatedBy: term).count - 1
        }

        guard score > 0 else { return nil }

        return SearchResult(
            id: source.rawValue + "-" + sourceID,
            source: source,
            title: title,
            excerpt: excerpt(from: fallbackExcerpt, matching: terms.first ?? ""),
            tags: tags,
            score: score
        )
    }

    private func excerpt(from text: String, matching term: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
        guard !clean.isEmpty else { return "No extracted text yet." }
        guard let range = clean.lowercased().range(of: term.lowercased()) else {
            return String(clean.prefix(120))
        }

        let distance = clean.distance(from: clean.startIndex, to: range.lowerBound)
        let startOffset = max(0, distance - 40)
        let start = clean.index(clean.startIndex, offsetBy: startOffset)
        let endDistance = min(clean.count, distance + 120)
        let end = clean.index(clean.startIndex, offsetBy: endDistance)
        return String(clean[start..<end])
    }
}

struct AIService {
    func privacyNotice(settings: AppSettings) -> String {
        guard settings.showPrivacyReminder else { return "" }
        return "Only selected snippets should be sent to your configured provider. Choose a trusted relay before enabling AI calls."
    }

    func localAnswer(for question: String, results: [SearchResult]) -> String {
        guard !results.isEmpty else {
            return "No clear evidence was found in the local library. Add or import relevant notes before asking AI to summarize them."
        }

        let sourceLines = results.prefix(3).map { "- \($0.title): \($0.excerpt)" }.joined(separator: "\n")
        return "Local evidence found:\n\(sourceLines)\n\nAI provider calls can be enabled from Settings after configuring the API endpoint."
    }

    func summary(from text: String) -> String {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "No extracted text is available for summary." }
        let sentences = clean
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let summary = sentences.prefix(3).joined(separator: ". ")
        return summary.isEmpty ? String(clean.prefix(240)) : summary
    }

    func keywords(from text: String) -> [String] {
        let stopwords: Set<String> = ["the", "and", "for", "with", "that", "this", "from", "have", "your", "you", "are", "will", "local", "file", "text"]
        let words = text
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 4 && !stopwords.contains($0) }

        let counts = Dictionary(grouping: words, by: { $0 }).mapValues(\.count)
        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(5)
            .map(\.key)
    }

    func todoSuggestions(from text: String) -> [String] {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
        let markers = ["TODO", "todo", "next", "should", "need", "must", "follow up"]
        let sentences = clean
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return sentences
            .filter { sentence in
                markers.contains { sentence.localizedCaseInsensitiveContains($0) }
            }
            .prefix(5)
            .map { sentence in
                sentence.count > 80 ? String(sentence.prefix(80)) : sentence
            }
    }

    func answer(question: String, results: [SearchResult], settings: AppSettings) async throws -> String {
        let provider = settings.provider
        guard !provider.baseURL.isEmpty, !provider.apiKey.isEmpty, !provider.modelName.isEmpty else {
            return localAnswer(for: question, results: results)
        }

        guard var components = URLComponents(string: provider.baseURL) else {
            throw AIServiceError.invalidURL
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let requestPath = provider.requestPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, requestPath].filter { !$0.isEmpty }.joined(separator: "/")

        guard let url = components.url else {
            throw AIServiceError.invalidURL
        }

        let context = results.prefix(settings.preferredSearchLimit).map {
            "Source: \($0.title)\nExcerpt: \($0.excerpt)"
        }.joined(separator: "\n\n")

        let systemPrompt = """
        You are a local-first personal archive assistant. Answer only from the supplied local context when it exists. If the context is insufficient, say that the local library has no clear evidence. Keep answers concise and actionable.
        """

        let body = ChatCompletionRequest(
            model: provider.modelName,
            messages: [
                ChatCompletionMessage(role: "system", content: systemPrompt),
                ChatCompletionMessage(role: "user", content: "Local context:\n\(context.isEmpty ? "No matching local context." : context)\n\nQuestion:\n\(question)")
            ],
            temperature: 0.2
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = provider.timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        switch provider.authMode {
        case .bearer:
            request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        case .apiKey:
            request.setValue(provider.apiKey, forHTTPHeaderField: "API-Key")
        case .xAPIKey:
            request.setValue(provider.apiKey, forHTTPHeaderField: "X-API-Key")
        case .custom:
            guard !provider.customHeaderName.isEmpty else { throw AIServiceError.missingConfiguration }
            request.setValue(provider.apiKey, forHTTPHeaderField: provider.customHeaderName)
        }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let serverMessage = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "AIService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: serverMessage])
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw AIServiceError.emptyResponse
        }
        return content
    }
}

private struct ChatCompletionRequest: Encodable {
    var model: String
    var messages: [ChatCompletionMessage]
    var temperature: Double
}

private struct ChatCompletionMessage: Codable {
    var role: String
    var content: String
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        var message: ChatCompletionMessage
    }

    var choices: [Choice]
}
