import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var query = ""
    @State private var mode = SearchMode.standard

    var results: [SearchResult] {
        store.search(query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(SearchMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        EmptyStateView(symbol: "magnifyingglass", title: "Search locally", message: "Find notes and imported files by title, content, category, or tag.")
                            .listRowSeparator(.hidden)
                    } else if results.isEmpty {
                        EmptyStateView(symbol: "questionmark.folder", title: "No evidence found", message: "The local library has no clear match for this query.")
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(results) { result in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(result.title)
                                        .font(.headline)
                                    Spacer()
                                    Text(result.source.rawValue)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                                Text(result.excerpt)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                FlowTags(tags: result.tags)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: mode.prompt)
        }
    }
}

enum SearchMode: String, CaseIterable, Identifiable {
    case standard
    case ai

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .ai: return "AI Search"
        }
    }

    var prompt: String {
        switch self {
        case .standard: return "Search title, text, tags"
        case .ai: return "Ask a natural question"
        }
    }
}
