import SwiftUI
import SwiftData

struct PlantWikiDetailView: View {
    @Bindable var species: PlantSpecies

    private static let monthNames = Calendar.current.shortMonthSymbols

    var body: some View {
        Form {
            Section {
                LabeledContent("Category", value: species.category.displayName)
                if let scientificName = species.scientificName, !scientificName.isEmpty {
                    LabeledContent("Scientific name", value: scientificName)
                }
                LabeledContent("Sun", value: species.sunRequirement.displayName)
                LabeledContent("Water", value: species.waterRequirement.displayName)
            }

            if !species.plantingMonths.isEmpty {
                Section("Planting months") {
                    Text(monthList(species.plantingMonths))
                }
            }

            if !species.harvestMonths.isEmpty {
                Section("Harvest / bloom months") {
                    Text(monthList(species.harvestMonths))
                }
            }

            if !species.soilNotes.isEmpty {
                Section("Soil") {
                    Text(species.soilNotes)
                }
            }

            if !species.spacingNotes.isEmpty {
                Section("Spacing") {
                    Text(species.spacingNotes)
                }
            }

            if !species.careNotes.isEmpty {
                Section("Care") {
                    Text(species.careNotes)
                }
            }

            if let placements = species.placements, !placements.isEmpty {
                Section("Placed in your garden") {
                    Text("\(placements.count) placed")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(species.commonName)
    }

    private func monthList(_ months: [Int]) -> String {
        months.sorted().compactMap { month -> String? in
            guard month >= 1, month <= 12 else { return nil }
            return Self.monthNames[month - 1]
        }.joined(separator: ", ")
    }
}
