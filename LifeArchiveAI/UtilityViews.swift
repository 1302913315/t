import SwiftUI

struct ToolsView: View {
    @State private var text = ""
    @State private var copiedText = ""
    @State private var lengthInput = 1.0
    @State private var fromUnit = UnitLength.meters
    @State private var toUnit = UnitLength.centimeters

    private let lengthUnits: [UnitLength] = [.meters, .centimeters, .kilometers, .inches, .feet]

    var convertedLength: Double {
        Measurement(value: lengthInput, unit: fromUnit).converted(to: toUnit).value
    }

    var body: some View {
        Form {
            Section("Text tools") {
                TextField("Paste text", text: $text, axis: .vertical)
                    .lineLimit(3...8)
                LabeledContent("Characters", value: "\(text.count)")
                LabeledContent("Words", value: "\(text.split { $0.isWhitespace || $0.isNewline }.count)")
                Button("Trim whitespace") {
                    copiedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    text = copiedText
                }
            }

            Section("Unit converter") {
                TextField("Value", value: $lengthInput, format: .number)
                    .keyboardType(.decimalPad)
                Picker("From", selection: $fromUnit) {
                    ForEach(lengthUnits, id: \.symbol) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
                Picker("To", selection: $toUnit) {
                    ForEach(lengthUnits, id: \.symbol) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
                LabeledContent("Result", value: convertedLength.formatted(.number.precision(.fractionLength(2))) + " \(toUnit.symbol)")
            }

            Section("Quick utilities") {
                NavigationLink("Password vault placeholder") {
                    PrivacyVaultView()
                }
                NavigationLink("Backup and export") {
                    BackupView()
                }
            }
        }
        .navigationTitle("Tools")
    }
}

struct PrivacyVaultView: View {
    @State private var locked = true
    @State private var passcode = ""

    var body: some View {
        Form {
            Section("Local privacy") {
                SecureField("Passcode placeholder", text: $passcode)
                Button(locked ? "Unlock" : "Lock") {
                    locked.toggle()
                }
            }

            Section("Protected area") {
                if locked {
                    ContentUnavailableView("Locked", systemImage: "lock.fill", description: Text("Face ID and Keychain storage belong in the next hardening pass."))
                } else {
                    Text("Private notes, hidden folders, and encrypted files will live here.")
                }
            }
        }
        .navigationTitle("Private")
    }
}

struct BackupView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var backupText = ""

    var body: some View {
        Form {
            Section("Local backup") {
                Button {
                    store.save()
                    backupText = "Saved \(Date().compactDateTime). Documents: \(store.documents.count), notes: \(store.notes.count), tasks: \(store.tasks.count)."
                } label: {
                    Label("Save Snapshot", systemImage: "externaldrive")
                }
                if !backupText.isEmpty {
                    Text(backupText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Export roadmap") {
                Text("A share-sheet JSON export and selective backup picker are reserved for the next implementation pass.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Backup")
    }
}
