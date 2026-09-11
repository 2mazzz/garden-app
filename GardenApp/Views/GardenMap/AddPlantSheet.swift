import SwiftUI
import SwiftData

struct AddPlantSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PlantSpecies.commonName) private var allSpecies: [PlantSpecies]

    let mapArea: MapArea
    let defaultPoint: GridPoint?

    @State private var selectedSpecies: PlantSpecies?
    @State private var x = 0
    @State private var y = 0
    @State private var selectedBed: Bed?
    @State private var status: PlantStatus = .planned
    @State private var showingAddSpecies = false

    private var beds: [Bed] { mapArea.beds ?? [] }

    var body: some View {
        NavigationStack {
            Form {
                Section("Species") {
                    Picker("Species", selection: $selectedSpecies) {
                        Text("Choose one").tag(PlantSpecies?.none)
                        ForEach(allSpecies) { species in
                            Text(species.commonName).tag(PlantSpecies?.some(species))
                        }
                    }
                    Button("Add a new species to the wiki") {
                        showingAddSpecies = true
                    }
                }

                Section("Position") {
                    Stepper("Column: \(x)", value: $x, in: 0...(mapArea.columns - 1))
                    Stepper("Row: \(y)", value: $y, in: 0...(mapArea.rows - 1))
                }

                if !beds.isEmpty {
                    Section("Bed (optional)") {
                        Picker("Bed", selection: $selectedBed) {
                            Text("None").tag(Bed?.none)
                            ForEach(beds) { bed in
                                Text(bed.name).tag(Bed?.some(bed))
                            }
                        }
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(PlantStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Place Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addPlant() }
                        .disabled(selectedSpecies == nil)
                }
            }
            .sheet(isPresented: $showingAddSpecies) {
                AddSpeciesSheet { newSpecies in
                    selectedSpecies = newSpecies
                }
            }
            .onAppear {
                if let point = defaultPoint {
                    x = point.x
                    y = point.y
                }
            }
        }
    }

    private func addPlant() {
        guard let selectedSpecies else { return }
        let plant = PlacedPlant(
            species: selectedSpecies,
            mapArea: mapArea,
            bed: selectedBed,
            x: x,
            y: y,
            status: status,
            datePlanted: status == .planted || status == .growing ? .now : nil
        )
        modelContext.insert(plant)
        dismiss()
    }
}
