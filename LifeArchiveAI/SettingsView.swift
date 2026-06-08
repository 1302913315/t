import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ArchiveStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Dark mode", isOn: $store.settings.useDarkMode)
                    Toggle("Show privacy reminder", isOn: $store.settings.showPrivacyReminder)
                    Stepper("Search results: \(store.settings.preferredSearchLimit)", value: $store.settings.preferredSearchLimit, in: 3...20)
                }

                Section("AI Provider") {
                    TextField("API Base URL", text: $store.settings.provider.baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Request path", text: $store.settings.provider.requestPath)
                        .textInputAutocapitalization(.never)
                    SecureField("API Key", text: $store.settings.provider.apiKey)
                        .textInputAutocapitalization(.never)
                    TextField("Model name", text: $store.settings.provider.modelName)
                        .textInputAutocapitalization(.never)
                    Picker("Auth", selection: $store.settings.provider.authMode) {
                        ForEach(ProviderConfig.AuthMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    if store.settings.provider.authMode == .custom {
                        TextField("Custom header", text: $store.settings.provider.customHeaderName)
                    }
                }

                Section("Privacy") {
                    Toggle("App lock placeholder", isOn: $store.settings.enableAppLock)
                    Text("Sensitive values should move to Keychain in the next hardening pass. This scaffold keeps provider settings local for development visibility.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Status") {
                    LabeledContent("Documents", value: "\(store.documents.count)")
                    LabeledContent("Notes", value: "\(store.notes.count)")
                    LabeledContent("Chats", value: "\(store.chatSessions.count)")
                    if let lastError = store.lastError {
                        Text(lastError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.saveSettings()
                    }
                }
            }
            .onDisappear {
                store.saveSettings()
            }
        }
    }
}
