import SwiftUI
import SwiftData

struct PlantWikiListView: View {
    @Query(sort: \PlantSpecies.commonName) private var allSpecies: [PlantSpecies]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingAddSpecies = false

    private var filteredSpecies: [PlantSpecies] {
        guard !searchText.isEmpty else { return allSpecies }
        return allSpecies.filter {
            $0.commonName.localizedCaseInsensitiveContains(searchText)
                || ($0.scientificName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var speciesByCategory: [(category: PlantCategory, species: [PlantSpecies])] {
        Dictionary(grouping: filteredSpecies, by: \.category)
            .map { (category: $0.key, species: $0.value.sorted { $0.commonName < $1.commonName }) }
            .sorted { $0.category.displayName < $1.category.displayName }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(speciesByCategory, id: \.category) { group in
                    Section(group.category.displayName) {
                        ForEach(group.species) { species in
                            NavigationLink(value: species) {
                                Label(species.commonName, systemImage: species.symbolName)
                            }
                        }
                        .onDelete { offsets in
                            deleteSpecies(offsets, in: group.species)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search the wiki")
            .navigationTitle("Plant Wiki")
            .navigationDestination(for: PlantSpecies.self) { species in
                PlantWikiDetailView(species: species)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSpecies = true
                    } label: {
                        Label("Add Species", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSpecies) {
                AddSpeciesSheet(onAdd: nil)
            }
            .overlay {
                if allSpecies.isEmpty {
                    ContentUnavailableView(
                        "No plants yet",
                        systemImage: "book",
                        description: Text("Add a plant or tree to start building your care wiki.")
                    )
                }
            }
        }
    }

    private func deleteSpecies(_ offsets: IndexSet, in species: [PlantSpecies]) {
        for index in offsets {
            modelContext.delete(species[index])
        }
    }
}
