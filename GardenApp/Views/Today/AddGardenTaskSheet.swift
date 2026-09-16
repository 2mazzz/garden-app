import SwiftUI
import SwiftData

/// Minimal add-task form for `GardenTask`. The handoff leaves "add task"
/// undesigned (see docs/plans/2026-09-15-greenhouse-redesign-design.md),
/// so this follows Calendar's `AddTaskSheet` structural conventions
/// (NavigationStack + Form + Section, Cancel/Add toolbar, disabled-until-
/// valid) rather than inventing a new form style.
struct AddGardenTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Bed.name) private var beds: [Bed]
    @Query private var placedPlants: [PlacedPlant]

    @State private var title = ""
    @State private var dueDate: Date = .now
    @State private var locationText = ""
    @State private var selectedBed: Bed?
    @State private var selectedPlant: PlacedPlant?

    private var sortedPlants: [PlacedPlant] {
        placedPlants.sorted {
            ($0.species?.commonName ?? "") < ($1.species?.commonName ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                }

                Section {
                    TextField("Location (optional)", text: $locationText)

                    Picker("Bed", selection: $selectedBed) {
                        Text("None").tag(Bed?.none)
                        ForEach(beds) { bed in
                            Text(bed.name).tag(Bed?.some(bed))
                        }
                    }
                    .onChange(of: selectedBed) { _, newBed in
                        // Prefill, don't overwrite — only fills in the
                        // location line when the user hasn't typed one.
                        if let newBed, locationText.isEmpty {
                            locationText = newBed.name
                        }
                    }

                    Picker("Plant", selection: $selectedPlant) {
                        Text("None").tag(PlacedPlant?.none)
                        ForEach(sortedPlants) { plant in
                            Text(plant.species?.commonName ?? "Plant").tag(PlacedPlant?.some(plant))
                        }
                    }
                    .onChange(of: selectedPlant) { _, newPlant in
                        if let name = newPlant?.species?.commonName, locationText.isEmpty {
                            locationText = name
                        }
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("Choosing a bed or plant fills in the location line if it's empty.")
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
        let task = GardenTask(
            title: title.trimmingCharacters(in: .whitespaces),
            locationText: locationText.trimmingCharacters(in: .whitespaces),
            dueDate: dueDate,
            placedPlant: selectedPlant,
            bed: selectedBed
        )
        modelContext.insert(task)
        // Explicit save, not just insert() — on a freshly-created,
        // CloudKit-backed-or-fallback store, @Query's live update appears
        // to key off the context save notification rather than the raw
        // in-context insert; without this, the new row was confirmed
        // present via fetchCount() but the Today list didn't re-render
        // until some other, unrelated save eventually flushed it. See
        // docs/decisions/0008-cloudkit-fallback.md /
        // 0009-cloudkit-attribute-defaults.md for the same class of
        // CloudKit-fallback-only issue only visible on a real build.
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddGardenTaskSheet()
        .modelContainer(PreviewData.container)
}
