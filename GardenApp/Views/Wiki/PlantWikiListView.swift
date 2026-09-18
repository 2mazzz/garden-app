import SwiftUI
import SwiftData

struct PlantWikiListView: View {
    @Query(sort: \PlantSpecies.commonName) private var allSpecies: [PlantSpecies]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingAddSpecies = false
    @State private var inGardenOnly = false
    @State private var selectedCategory: PlantCategory?

    /// Only categories actually present in the current catalog, in the
    /// enum's declared order — avoids showing empty chips for categories
    /// nothing has been seeded/added under yet.
    private var presentCategories: [PlantCategory] {
        let present = Set(allSpecies.map(\.category))
        return PlantCategory.allCases.filter { present.contains($0) }
    }

    private var filteredSpecies: [PlantSpecies] {
        allSpecies.filter { species in
            if !searchText.isEmpty {
                let matchesSearch = species.commonName.localizedCaseInsensitiveContains(searchText)
                    || (species.scientificName?.localizedCaseInsensitiveContains(searchText) ?? false)
                guard matchesSearch else { return false }
            }
            if inGardenOnly, !isInGarden(species) { return false }
            if let selectedCategory, species.category != selectedCategory { return false }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChips

                List {
                    ForEach(filteredSpecies) { species in
                        NavigationLink(value: species) {
                            speciesRow(species)
                        }
                    }
                    .onDelete(perform: deleteSpecies)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(GreenhouseTheme.Color.paper)
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

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GreenhouseTheme.Spacing.xs) {
                GHChip(title: "In my garden", isSelected: inGardenOnly) {
                    inGardenOnly.toggle()
                }
                ForEach(presentCategories) { category in
                    GHChip(title: category.displayName, isSelected: selectedCategory == category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, GreenhouseTheme.Spacing.screenPadding)
            .padding(.vertical, GreenhouseTheme.Spacing.xs)
        }
    }

    // MARK: - Row

    private func speciesRow(_ species: PlantSpecies) -> some View {
        HStack(spacing: GreenhouseTheme.Spacing.sm) {
            GHArtPlaceholder(caption: species.commonName, size: CGSize(width: 46, height: 46))

            VStack(alignment: .leading, spacing: 2) {
                Text(species.commonName)
                    .font(GreenhouseTheme.Font.listItem())
                    .foregroundStyle(GreenhouseTheme.Color.ink)

                let summary = firstSentence(of: species.careNotes)
                if !summary.isEmpty {
                    Text(summary)
                        .font(GreenhouseTheme.Font.small())
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if isInGarden(species) {
                GHBadge(text: "Growing", kind: .sowing)
            }
        }
        .padding(.vertical, GreenhouseTheme.Spacing.xxs)
    }

    private func firstSentence(of text: String) -> String {
        guard let range = text.range(of: ". ") else { return text }
        return String(text[..<range.lowerBound]) + "."
    }

    private func isInGarden(_ species: PlantSpecies) -> Bool {
        (species.placements ?? []).contains { $0.status != .removed }
    }

    private func deleteSpecies(_ offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredSpecies[index])
        }
    }
}
