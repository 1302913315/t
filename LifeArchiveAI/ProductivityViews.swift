import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskPriority = .normal
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    var body: some View {
        Form {
            Section("New task") {
                TextField("Title", text: $title)
                TextField("Notes", text: $notes, axis: .vertical)
                Picker("Priority", selection: $priority) {
                    ForEach(TaskPriority.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                Toggle("Due date", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("Due", selection: $dueDate)
                }
                Button {
                    store.addTask(title: title, notes: notes, priority: priority, dueDate: hasDueDate ? dueDate : nil)
                    title = ""
                    notes = ""
                    priority = .normal
                    hasDueDate = false
                } label: {
                    Label("Add Task", systemImage: "plus.circle")
                }
            }

            Section("Tasks") {
                ForEach(store.tasks) { task in
                    Button {
                        store.toggleTask(task)
                    } label: {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isCompleted ? .green : AppTheme.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .strikethrough(task.isCompleted)
                                Text("\(task.priority.rawValue)\(task.dueDate.map { " - \($0.compactDateTime)" } ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Tasks")
    }
}

struct RemindersView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var title = ""
    @State private var date = Date()
    @State private var repeats = false
    @State private var notes = ""

    var body: some View {
        Form {
            Section("New reminder") {
                TextField("Title", text: $title)
                DatePicker("Time", selection: $date)
                Toggle("Repeat", isOn: $repeats)
                TextField("Notes", text: $notes, axis: .vertical)
                Button {
                    store.addReminder(title: title, date: date, repeats: repeats, notes: notes)
                    title = ""
                    notes = ""
                    repeats = false
                    date = Date()
                } label: {
                    Label("Add Reminder", systemImage: "calendar.badge.plus")
                }
            }

            Section("Schedule") {
                ForEach(store.reminders.sorted { $0.date < $1.date }) { reminder in
                    Button {
                        store.toggleReminder(reminder)
                    } label: {
                        HStack {
                            Image(systemName: reminder.isDone ? "checkmark.circle.fill" : "bell")
                                .foregroundStyle(reminder.isDone ? .green : AppTheme.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.title)
                                    .strikethrough(reminder.isDone)
                                Text("\(reminder.date.compactDateTime)\(reminder.repeats ? " - repeats" : "")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Reminders")
    }
}

struct LedgerView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var title = ""
    @State private var amount = 0.0
    @State private var type: LedgerType = .expense
    @State private var category = ""
    @State private var note = ""

    var body: some View {
        Form {
            Section("This month") {
                LabeledContent("Balance", value: store.monthlyBalance.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
            }

            Section("New entry") {
                TextField("Title", text: $title)
                TextField("Amount", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Type", selection: $type) {
                    ForEach(LedgerType.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                Picker("Category", selection: $category) {
                    Text("General").tag("")
                    Text("Study").tag("Study")
                    Text("Work").tag("Work")
                    Text("Life").tag("Life")
                    Text("Health").tag("Health")
                }
                TextField("Note", text: $note, axis: .vertical)
                Button {
                    store.addLedgerEntry(title: title, amount: amount, type: type, category: category, note: note)
                    title = ""
                    amount = 0
                    category = ""
                    note = ""
                } label: {
                    Label("Add Entry", systemImage: "plus.circle")
                }
            }

            Section("Entries") {
                ForEach(store.ledgerEntries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                            Text("\(entry.category) - \(entry.date.compactDateTime)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(entry.amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                            .foregroundStyle(entry.type == .income ? .green : .red)
                    }
                }
            }
        }
        .navigationTitle("Ledger")
    }
}
