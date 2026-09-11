import SwiftUI
import SwiftData

struct PlacedPlantDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var placedPlant: PlacedPlant

    var body: some View {
        NavigationStack {
            Form {
                if let species = placedPlant.species {
                    Section("Species") {
                        NavigationLink(species.commonName) {
                            PlantWikiDetailView(species: species)
                        }
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $placedPlant.status) {
                        ForEach(PlantStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    DatePicker(
                        "Date planted",
                        selection: Binding(
                            get: { placedPlant.datePlanted ?? .now },
                            set: { placedPlant.datePlanted = $0 }
                        ),
                        displayedComponents: .date
                    )
                }

                Section("Notes") {
                    TextEditor(text: $placedPlant.notes)
                        .frame(minHeight: 100)
                }

                Section {
                    Button("Remove from map", role: .destructive) {
                        modelContext.delete(placedPlant)
                        dismiss()
                    }
                }
            }
            .navigationTitle(placedPlant.species?.commonName ?? "Plant")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
