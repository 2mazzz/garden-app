import SwiftUI
import SwiftData

struct AddSpeciesSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Called with the newly created species, so callers (like AddPlantSheet)
    /// can immediately select it.
    var onAdd: ((PlantSpecies) -> Void)?

    @State private var commonName = ""
    @State private var scientificName = ""
    @State private var category: PlantCategory = .vegetable
    @State private var isTree = false
    @State private var sunRequirement: SunRequirement = .fullSun
    @State private var waterRequirement: WaterRequirement = .medium
    @State private var careNotes = ""
    @State private var soilNotes = ""
    @State private var spacingNotes = ""
    @State private var plantingMonths: Set<Int> = []
    @State private var harvestMonths: Set<Int> = []

    private static let monthNames = Calendar.current.shortMonthSymbols

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Common name (e.g. \"Tomato\")", text: $commonName)
                    TextField("Scientific name (optional)", text: $scientificName)
                    Picker("Category", selection: $category) {
                        ForEach(PlantCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    Toggle("This is a tree", isOn: $isTree)
                }

                Section("Needs") {
                    Picker("Sun", selection: $sunRequirement) {
                        ForEach(SunRequirement.allCases) { req in
                            Text(req.displayName).tag(req)
                        }
                    }
                    Picker("Water", selection: $waterRequirement) {
                        ForEach(WaterRequirement.allCases) { req in
                            Text(req.displayName).tag(req)
                        }
                    }
                }

                Section("Planting months") {
                    monthGrid(selection: $plantingMonths)
                }

                Section("Harvest / bloom months") {
                    monthGrid(selection: $harvestMonths)
                }

                Section("Care notes") {
                    TextField("Soil", text: $soilNotes, axis: .vertical)
                    TextField("Spacing", text: $spacingNotes, axis: .vertical)
                    TextField("Care instructions", text: $careNotes, axis: .vertical)
                }
            }
            .navigationTitle("New Wiki Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addSpecies() }
                        .disabled(commonName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func monthGrid(selection: Binding<Set<Int>>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
            ForEach(1...12, id: \.self) { month in
                let isSelected = selection.wrappedValue.contains(month)
                Text(Self.monthNames[month - 1])
                    .font(.caption)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                    )
                    .onTapGesture {
                        if isSelected {
                            selection.wrappedValue.remove(month)
                        } else {
                            selection.wrappedValue.insert(month)
                        }
                    }
            }
        }
    }

    private func addSpecies() {
        let species = PlantSpecies(
            commonName: commonName,
            scientificName: scientificName.isEmpty ? nil : scientificName,
            category: category,
            sunRequirement: sunRequirement,
            waterRequirement: waterRequirement,
            isTree: isTree,
            careNotes: careNotes,
            soilNotes: soilNotes,
            spacingNotes: spacingNotes,
            plantingMonths: Array(plantingMonths).sorted(),
            harvestMonths: Array(harvestMonths).sorted(),
            symbolName: category.symbolName
        )
        modelContext.insert(species)
        onAdd?(species)
        dismiss()
    }
}
