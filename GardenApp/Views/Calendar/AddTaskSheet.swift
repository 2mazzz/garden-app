import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let defaultMonth: Int

    @State private var title = ""
    @State private var details = ""
    @State private var month: Int
    @State private var category: TaskCategory = .other

    private static let monthNames = Calendar.current.monthSymbols

    init(defaultMonth: Int) {
        self.defaultMonth = defaultMonth
        _month = State(initialValue: defaultMonth)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Details (optional)", text: $details, axis: .vertical)
                }

                Section("When") {
                    Picker("Month", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(Self.monthNames[m - 1]).tag(m)
                        }
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.symbolName).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addTask() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let task = MonthlyTaskTemplate(
            month: month,
            title: title,
            details: details,
            category: category,
            isBuiltIn: false
        )
        modelContext.insert(task)
        // Explicit save, not just insert() — see ADR 0020.
        try? modelContext.save()
        dismiss()
    }
}
