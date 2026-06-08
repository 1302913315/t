import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var prompt = ""

    var messages: [ChatMessage] {
        store.latestSession?.messages ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !store.privacyNotice().isEmpty {
                    Text(store.privacyNotice())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cream)
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                        }
                        if store.isProcessingAI {
                            HStack {
                                ProgressView()
                                Text("Thinking with local context...")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }

                HStack(spacing: 10) {
                    TextField("Ask your local library", text: $prompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)

                    Button {
                        submit()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle("AI Chat")
        }
    }

    private func submit() {
        let question = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        prompt = ""
        store.askAI(question)
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.content)
                .font(.subheadline)
                .padding(12)
                .background(isUser ? AppTheme.accent.opacity(0.22) : AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            if !isUser { Spacer(minLength: 40) }
        }
    }
}
