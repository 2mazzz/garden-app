import SwiftUI
import SwiftData

struct PlantWikiDetailView: View {
    @Bindable var species: PlantSpecies

    @State private var openPlacement: PlacedPlant?

    private static let shortMonthNames = Calendar.current.shortMonthSymbols

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.lg) {
                GHArtPlaceholder(caption: species.commonName, size: CGSize(width: 390, height: 168))
                    .frame(maxWidth: .infinity)

                titleBlock

                factTiles

                if !species.careNotes.isEmpty {
                    proseSection(label: "Care", text: species.careNotes)
                }

                if !species.soilNotes.isEmpty {
                    proseSection(label: "Soil", text: species.soilNotes)
                }

                if let placement = mostRecentInGardenPlacement {
                    inGardenFooter(placement)
                }
            }
            .padding(.horizontal, GreenhouseTheme.Spacing.screenPadding)
            .padding(.vertical, GreenhouseTheme.Spacing.sm)
        }
        .background(GreenhouseTheme.Color.paper)
        .navigationTitle(species.commonName)
        .sheet(item: $openPlacement) { placement in
            PlacedPlantDetailSheet(placedPlant: placement)
        }
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
            Text(species.commonName)
                .font(GreenhouseTheme.Font.screenTitle())
                .foregroundStyle(GreenhouseTheme.Color.ink)

            if let scientificName = species.scientificName, !scientificName.isEmpty {
                Text(scientificName)
                    .font(GreenhouseTheme.Font.small())
                    .foregroundStyle(GreenhouseTheme.Color.metaText)
                    .italic()
            }
        }
    }

    // MARK: - Fact tiles

    private var factTiles: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                factTile(label: "Sow", value: monthRangeText(species.plantingMonths))
                factTile(label: "Harvest", value: monthRangeText(species.harvestMonths))
            }
            HStack(spacing: 10) {
                factTile(label: "Spacing", value: species.spacingNotes.isEmpty ? "—" : species.spacingNotes)
                factTile(label: "Water", value: species.waterRequirement.displayName)
            }
        }
    }

    private func factTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
            Text(label)
                .font(GreenhouseTheme.Font.label())
                .textCase(.uppercase)
                .kerning(1.1)
                .foregroundStyle(GreenhouseTheme.Color.metaText)
            Text(value)
                .font(GreenhouseTheme.Font.mono(15))
                .foregroundStyle(GreenhouseTheme.Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GreenhouseTheme.Spacing.sm)
        .background(GreenhouseTheme.Color.card)
        .overlay(
            RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card)
                .stroke(GreenhouseTheme.Color.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card))
    }

    // MARK: - Prose

    private func proseSection(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
            Text(label)
                .font(GreenhouseTheme.Font.section())
                .foregroundStyle(GreenhouseTheme.Color.ink)
            Text(text)
                .font(GreenhouseTheme.Font.body())
                .foregroundStyle(GreenhouseTheme.Color.bodyText)
        }
    }

    // MARK: - In-garden cross-link

    private var mostRecentInGardenPlacement: PlacedPlant? {
        (species.placements ?? [])
            .filter { $0.status != .removed }
            .max { ($0.datePlanted ?? .distantPast) < ($1.datePlanted ?? .distantPast) }
    }

    private func inGardenFooter(_ placement: PlacedPlant) -> some View {
        let locationName = placement.bed?.name ?? placement.mapArea?.name ?? ""
        return HStack {
            Text("You're growing this in \(locationName)")
                .font(GreenhouseTheme.Font.body())
                .foregroundStyle(GreenhouseTheme.Color.bodyText)
            Spacer(minLength: GreenhouseTheme.Spacing.sm)
            Button("Open") { openPlacement = placement }
                .buttonStyle(GHButtonStyle(kind: .secondary))
        }
        .padding(GreenhouseTheme.Spacing.sm)
        .background(GreenhouseTheme.Color.mist)
        .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card))
    }

    // MARK: - Month formatting

    /// Collapses a set of 1-12 month numbers into a human range ("Mar – Apr")
    /// when contiguous, or a plain list when not (e.g. a species sown in
    /// both spring and late summer isn't one continuous range).
    private func monthRangeText(_ months: [Int]) -> String {
        let sorted = Set(months).sorted()
        guard !sorted.isEmpty else { return "—" }

        func name(_ month: Int) -> String {
            (1...12).contains(month) ? Self.shortMonthNames[month - 1] : ""
        }

        let isContiguous = zip(sorted, sorted.dropFirst()).allSatisfy { $1 == $0 + 1 }
        if isContiguous {
            guard let first = sorted.first, let last = sorted.last else { return "—" }
            return first == last ? name(first) : "\(name(first)) – \(name(last))"
        }
        return sorted.map(name).joined(separator: ", ")
    }
}
