import SwiftUI
import SwiftData

/// Small sheet for adding one freeform PlantNote to a planting's "Log"
/// section. Deliberately just the note text — date defaults to `.now`,
/// no picker, matching the design handoff's simple "Add note" flow.
struct AddPlantNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let placedPlant: PlacedPlant

    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("What's happening with this plant?", text: $text, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("Add Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let note = PlantNote(text: text.trimmingCharacters(in: .whitespacesAndNewlines), placedPlant: placedPlant)
        modelContext.insert(note)
        // See docs/decisions/0020-query-requires-save.md — @Query views
        // don't reliably observe a fresh insert on a clean install without
        // an explicit save.
        try? modelContext.save()
        dismiss()
    }
}
