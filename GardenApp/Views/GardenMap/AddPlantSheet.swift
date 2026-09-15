import SwiftUI
import SwiftData

/// No position/size fields — a plant is inserted with a sensible default
/// footprint (small for most species, larger for trees) and then dragged
/// into place/resized on the map, the same direct-manipulation flow as a
/// bed. See docs/decisions/0017-bed-shapes-and-plant-zones.md.
///
/// Placement rule: on the outdoor Garden map, only trees can be placed
/// without a bed (on the open ground); everything else must go in a bed.
/// On the Greenhouse map, any species can go directly on the open floor
/// or in a bed.
struct AddPlantSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PlantSpecies.commonName) private var allSpecies: [PlantSpecies]

    let mapArea: MapArea
    let defaultPoint: GridPoint?
    var defaultBed: Bed? = nil

    @State private var selectedSpecies: PlantSpecies?
    @State private var selectedBed: Bed?
    @State private var status: PlantStatus = .planned
    @State private var showingAddSpecies = false

    private var beds: [Bed] { mapArea.beds ?? [] }

    /// Whether a bed is required for the currently selected species —
    /// true only on the outdoor map, for non-tree species.
    private var bedRequired: Bool {
        mapArea.kind == .outdoor && selectedSpecies?.isTree != true
    }

    private var availableSpecies: [PlantSpecies] {
        guard mapArea.kind == .outdoor, selectedBed == nil else { return allSpecies }
        return allSpecies.filter(\.isTree)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Species", selection: $selectedSpecies) {
                        Text("Choose one").tag(PlantSpecies?.none)
                        ForEach(availableSpecies) { species in
                            Text(species.commonName).tag(PlantSpecies?.some(species))
                        }
                    }
                    Button("Add a new species to the wiki") {
                        showingAddSpecies = true
                    }
                } header: {
                    Text("Species")
                } footer: {
                    if mapArea.kind == .outdoor && selectedBed == nil {
                        Text("Only trees can be placed on the open ground. Choose a bed below to place other plants.")
                    }
                }

                if !beds.isEmpty || mapArea.kind == .outdoor {
                    Section {
                        Picker("Bed", selection: $selectedBed) {
                            if mapArea.kind != .outdoor || selectedSpecies?.isTree == true || beds.isEmpty {
                                Text("None — open ground").tag(Bed?.none)
                            }
                            ForEach(beds) { bed in
                                Text(bed.name).tag(Bed?.some(bed))
                            }
                        }
                        .onChange(of: selectedBed) { _, newBed in
                            if mapArea.kind == .outdoor, newBed == nil, selectedSpecies?.isTree != true {
                                selectedSpecies = nil
                            }
                        }
                    } header: {
                        Text(bedRequired ? "Bed (required)" : "Bed (optional)")
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
                        .disabled(selectedSpecies == nil || (bedRequired && selectedBed == nil))
                }
            }
            .sheet(isPresented: $showingAddSpecies) {
                AddSpeciesSheet { newSpecies in
                    selectedSpecies = newSpecies
                }
            }
            .onAppear {
                selectedBed = defaultBed
            }
        }
    }

    private func addPlant() {
        guard let selectedSpecies else { return }
        let size = footprintSize(for: selectedSpecies)
        let origin = origin(for: size)

        let plant = PlacedPlant(
            species: selectedSpecies,
            mapArea: mapArea,
            bed: selectedBed,
            x: origin.x,
            y: origin.y,
            width: size.width,
            height: size.height,
            status: status,
            datePlanted: status == .planted || status == .growing ? .now : nil
        )
        modelContext.insert(plant)
        dismiss()
    }

    /// Trees default to a footprint reflecting real canopy size; everything
    /// else starts small and gets dragged/resized into the area it should
    /// cover (e.g. a strawberry patch inside a bed).
    private func footprintSize(for species: PlantSpecies) -> (width: Int, height: Int) {
        species.isTree ? (min(3, mapArea.columns), min(3, mapArea.rows)) : (1, 1)
    }

    private func origin(for size: (width: Int, height: Int)) -> GridPoint {
        if let defaultPoint {
            return clamp(defaultPoint, size: size)
        }
        if let selectedBed {
            let box = selectedBed.boundingBox
            return clamp(GridPoint(x: box.x, y: box.y), size: size)
        }
        // Grid (0,0) is usually off-screen on the large, centered map —
        // default to the middle instead. See docs/decisions/0014-endless-grid.md.
        let x = max(0, min(mapArea.columns - size.width, mapArea.columns / 2 - size.width / 2))
        let y = max(0, min(mapArea.rows - size.height, mapArea.rows / 2 - size.height / 2))
        return GridPoint(x: x, y: y)
    }

    private func clamp(_ point: GridPoint, size: (width: Int, height: Int)) -> GridPoint {
        let x = min(max(point.x, 0), max(0, mapArea.columns - size.width))
        let y = min(max(point.y, 0), max(0, mapArea.rows - size.height))
        return GridPoint(x: x, y: y)
    }
}
