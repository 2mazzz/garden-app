import SwiftUI
import SwiftData

struct PlacedPlantDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var placedPlant: PlacedPlant

    @State private var showingLogHarvest = false
    @State private var showingAddNote = false
    @State private var showingWikiEntry = false

    private var sortedHarvestLogs: [HarvestLog] {
        (placedPlant.harvestLogs ?? []).sorted { $0.date > $1.date }
    }

    private var sortedNotes: [PlantNote] {
        (placedPlant.journalEntries ?? []).sorted { $0.date > $1.date }
    }

    /// Lifetime harvest total for **this one planting only** — grouped by
    /// unit, same pattern as PlantWikiDetailView.totalHarvestedByUnit, but
    /// scoped to `placedPlant.harvestLogs` instead of every placement of
    /// the species across the whole garden.
    private var pickedTotalByUnit: [(unit: String, total: Double)] {
        let logs = placedPlant.harvestLogs ?? []
        let totalsByUnit = Dictionary(grouping: logs, by: { $0.unit })
            .mapValues { $0.compactMap(\.quantity).reduce(0, +) }
        return totalsByUnit
            .filter { $0.value > 0 }
            .map { (unit: $0.key, total: $0.value) }
            .sorted { $0.unit < $1.unit }
    }

    private var pickedText: String {
        guard let first = pickedTotalByUnit.first else { return "—" }
        return "\(formatted(first.total)) \(first.unit)"
    }

    private var sownText: String {
        guard let date = placedPlant.datePlanted else { return "—" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var locationText: String {
        placedPlant.bed?.name ?? placedPlant.mapArea?.name ?? ""
    }

    /// Union of planting + harvest months, converted from the app's 1-12
    /// numbering to the strip's 0-11 index.
    private var activeMonths: Set<Int> {
        guard let species = placedPlant.species else { return [] }
        let months = species.plantingMonths + species.harvestMonths
        return Set(months.map { $0 - 1 }.filter { (0...11).contains($0) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    hero
                }
                .ghRow()

                Section {
                    titleBlock
                }
                .ghRow()

                Section {
                    statTiles
                }
                .ghRow()

                Section {
                    Text("Its year")
                        .font(GreenhouseTheme.Font.section())
                        .foregroundStyle(GreenhouseTheme.Color.ink)
                    SeasonStripView(activeMonths: activeMonths)
                }
                .ghRow()

                Section("Status") {
                    Picker("Status", selection: $placedPlant.status) {
                        ForEach(PlantStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .font(GreenhouseTheme.Font.body())
                    .foregroundStyle(GreenhouseTheme.Color.ink)

                    DatePicker(
                        "Date planted",
                        selection: Binding(
                            get: { placedPlant.datePlanted ?? .now },
                            set: { placedPlant.datePlanted = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .font(GreenhouseTheme.Font.body())
                    .foregroundStyle(GreenhouseTheme.Color.ink)
                }

                Section("Notes") {
                    TextEditor(text: $placedPlant.notes)
                        .font(GreenhouseTheme.Font.body())
                        .foregroundStyle(GreenhouseTheme.Color.bodyText)
                        .frame(minHeight: 100)
                }

                Section {
                    logSectionContent
                }
                .ghRow()

                Section {
                    ForEach(sortedHarvestLogs) { log in
                        HStack {
                            Text(log.date, style: .date)
                                .font(GreenhouseTheme.Font.body())
                                .foregroundStyle(GreenhouseTheme.Color.ink)
                            Spacer()
                            if let quantity = log.quantity {
                                Text("\(formatted(quantity)) \(log.unit)")
                                    .font(GreenhouseTheme.Font.mono())
                                    .foregroundStyle(GreenhouseTheme.Color.metaText)
                            }
                        }
                    }
                    .onDelete(perform: deleteHarvestLogs)
                } header: {
                    Text("Harvest log")
                }

                Section {
                    footerButtons
                }
                .ghRow()

                Section {
                    Button("Remove from map", role: .destructive) {
                        modelContext.delete(placedPlant)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle(placedPlant.species?.commonName ?? "Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingLogHarvest) {
                LogHarvestSheet(placedPlant: placedPlant)
            }
            .sheet(isPresented: $showingAddNote) {
                AddPlantNoteSheet(placedPlant: placedPlant)
            }
            .navigationDestination(isPresented: $showingWikiEntry) {
                if let species = placedPlant.species {
                    PlantWikiDetailView(species: species)
                }
            }
        }
    }

    // MARK: - Sections

    private var hero: some View {
        GeometryReader { proxy in
            GHArtPlaceholder(
                caption: placedPlant.species?.commonName ?? "Plant",
                size: CGSize(width: proxy.size.width, height: 196)
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
            HStack(alignment: .top, spacing: GreenhouseTheme.Spacing.xs) {
                Text(placedPlant.species?.commonName ?? "Plant")
                    .font(GreenhouseTheme.Font.screenTitle())
                    .foregroundStyle(GreenhouseTheme.Color.ink)
                Spacer(minLength: GreenhouseTheme.Spacing.xs)
                if !locationText.isEmpty {
                    locationBadge
                }
            }
            if let scientificName = placedPlant.species?.scientificName, !scientificName.isEmpty {
                Text(scientificName)
                    .font(GreenhouseTheme.Font.small())
                    .foregroundStyle(GreenhouseTheme.Color.metaText)
                    .italic()
            }
        }
    }

    private var locationBadge: some View {
        Text(locationText)
            .font(GreenhouseTheme.Font.small())
            .foregroundStyle(GreenhouseTheme.Color.green)
            .padding(.horizontal, GreenhouseTheme.Spacing.xs)
            .padding(.vertical, GreenhouseTheme.Spacing.xxs)
            .background(GreenhouseTheme.Color.greenTint)
            .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.chip))
    }

    private var statTiles: some View {
        HStack(spacing: 10) {
            statTile(label: "Sown", value: sownText)
            statTile(label: "Water", value: placedPlant.species?.waterRequirement.displayName ?? "—")
            statTile(label: "Picked", value: pickedText)
        }
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
            Text(label)
                .font(GreenhouseTheme.Font.label())
                .textCase(.uppercase)
                .kerning(1.1)
                .foregroundStyle(GreenhouseTheme.Color.metaText)
            Text(value)
                .font(GreenhouseTheme.Font.mono(15))
                .foregroundStyle(GreenhouseTheme.Color.ink)
                .lineLimit(1)
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

    private var logSectionContent: some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.sm) {
            HStack {
                Text("Log")
                    .font(GreenhouseTheme.Font.section())
                    .foregroundStyle(GreenhouseTheme.Color.ink)
                Spacer()
                Button("Add note") { showingAddNote = true }
                    .font(GreenhouseTheme.Font.small())
                    .fontWeight(.semibold)
                    .foregroundStyle(GreenhouseTheme.Color.green)
                    .buttonStyle(.plain)
            }

            if sortedNotes.isEmpty {
                Text("No notes yet.")
                    .font(GreenhouseTheme.Font.small())
                    .foregroundStyle(GreenhouseTheme.Color.metaText)
            } else {
                VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.sm) {
                    ForEach(sortedNotes) { note in
                        noteRow(note)
                    }
                }
            }
        }
    }

    private func noteRow(_ note: PlantNote) -> some View {
        HStack(alignment: .top, spacing: GreenhouseTheme.Spacing.xs) {
            Circle()
                .fill(GreenhouseTheme.Color.leaf)
                .frame(width: 7, height: 7)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(note.text)
                    .font(GreenhouseTheme.Font.body())
                    .foregroundStyle(GreenhouseTheme.Color.bodyText)
                Text(note.date, format: .dateTime.day().month(.abbreviated))
                    .font(GreenhouseTheme.Font.mono(11))
                    .foregroundStyle(GreenhouseTheme.Color.metaText)
            }
            Spacer(minLength: 0)
        }
    }

    private var footerButtons: some View {
        HStack(spacing: GreenhouseTheme.Spacing.sm) {
            Button("Log harvest") { showingLogHarvest = true }
                .buttonStyle(GHButtonStyle(kind: .primary))
                .frame(maxWidth: .infinity)

            Button("Wiki") { showingWikiEntry = true }
                .buttonStyle(GHButtonStyle(kind: .secondary))
                .frame(maxWidth: .infinity)
                .disabled(placedPlant.species == nil)
        }
    }

    // MARK: - Actions

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

/// Full-bleed custom Form row: same horizontal rhythm as the screen's
/// padding, no default row background — used for the hero/title/stat-tile/
/// season-strip/log/footer blocks that aren't native Form controls.
private extension View {
    func ghRow() -> some View {
        self
            .listRowInsets(EdgeInsets(
                top: GreenhouseTheme.Spacing.xs,
                leading: GreenhouseTheme.Spacing.screenPadding,
                bottom: GreenhouseTheme.Spacing.xs,
                trailing: GreenhouseTheme.Spacing.screenPadding
            ))
            .listRowBackground(SwiftUI.Color.clear)
    }
}
