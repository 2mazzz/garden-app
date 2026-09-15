import SwiftUI
import SwiftData

struct PlacedPlantDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var placedPlant: PlacedPlant
    @State private var showingLogHarvest = false

    private var sortedHarvestLogs: [HarvestLog] {
        (placedPlant.harvestLogs ?? []).sorted { $0.date > $1.date }
    }

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
                    ForEach(sortedHarvestLogs) { log in
                        HStack {
                            Text(log.date, style: .date)
                            Spacer()
                            if let quantity = log.quantity {
                                Text("\(formatted(quantity)) \(log.unit)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteHarvestLogs)
                    Button("Log harvest") {
                        showingLogHarvest = true
                    }
                } header: {
                    Text("Harvest log")
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
            .sheet(isPresented: $showingLogHarvest) {
                LogHarvestSheet(placedPlant: placedPlant)
            }
        }
    }

    private func deleteHarvestLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedHarvestLogs[index])
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
