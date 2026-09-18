import SwiftUI
import SwiftData

struct CareCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [MonthlyTaskTemplate]
    @Query private var allPlacedPlants: [PlacedPlant]

    @State private var selectedMonth = Calendar.current.component(.month, from: .now)
    @State private var calendarMode: CalendarMode = .month
    @State private var showingAddTask = false
    @State private var frostRisk: FrostAlertService.FrostRisk?

    private enum CalendarMode {
        case month, year
    }

    private var currentMonthHarvestNames: Set<String> {
        Set(plantsToHarvestThisMonth.compactMap { $0.species?.commonName })
    }

    private static let monthNames = Calendar.current.monthSymbols

    private var tasksForMonth: [MonthlyTaskTemplate] {
        allTasks
            .filter { $0.month == selectedMonth }
            .sorted { $0.title < $1.title }
    }

    private var plantsToPlantThisMonth: [PlacedPlant] {
        allPlacedPlants.filter {
            $0.status != .removed && ($0.species?.isGoodToPlant(inMonth: selectedMonth) ?? false)
        }
    }

    private var plantsToHarvestThisMonth: [PlacedPlant] {
        allPlacedPlants.filter {
            $0.status != .removed && ($0.species?.harvestMonths.contains(selectedMonth) ?? false)
        }
    }

    /// One entry per species currently placed (non-removed) anywhere in the
    /// garden, for the Whole year grid.
    private var inGardenSpecies: [PlantSpecies] {
        var seenIDs = Set<UUID>()
        var result: [PlantSpecies] = []
        for plant in allPlacedPlants where plant.status != .removed {
            guard let species = plant.species, seenIDs.insert(species.id).inserted else { continue }
            result.append(species)
        }
        return result.sorted { $0.commonName < $1.commonName }
    }

    private var headerSubtitle: String? {
        let plantCount = plantsToPlantThisMonth.count
        let harvestCount = plantsToHarvestThisMonth.count
        guard plantCount > 0 || harvestCount > 0 else { return nil }
        var parts: [String] = []
        if plantCount > 0 { parts.append("\(plantCount) to plant") }
        if harvestCount > 0 { parts.append("\(harvestCount) to harvest") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, GreenhouseTheme.Spacing.screenPadding)
                    .padding(.top, GreenhouseTheme.Spacing.sm)

                modeSegmentedControl
                    .padding(.horizontal, GreenhouseTheme.Spacing.screenPadding)
                    .padding(.vertical, GreenhouseTheme.Spacing.sm)

                switch calendarMode {
                case .month:
                    monthBody
                case .year:
                    ScrollView {
                        YearGridView(species: inGardenSpecies)
                            .padding(.horizontal, GreenhouseTheme.Spacing.screenPadding)
                            .padding(.bottom, GreenhouseTheme.Spacing.lg)
                    }
                }
            }
            .background(GreenhouseTheme.Color.paper)
            .navigationTitle("Care Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet(defaultMonth: selectedMonth)
            }
            .task {
                frostRisk = try? await FrostAlertService.checkFrostRisk(in: modelContext)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
                Text(Self.monthNames[selectedMonth - 1])
                    .font(GreenhouseTheme.Font.screenTitle())
                    .foregroundStyle(GreenhouseTheme.Color.ink)
                if let headerSubtitle {
                    Text(headerSubtitle)
                        .font(GreenhouseTheme.Font.small())
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                }
            }
            Spacer(minLength: GreenhouseTheme.Spacing.sm)
            HStack(spacing: GreenhouseTheme.Spacing.xs) {
                monthStepButton(systemImage: "chevron.left", label: "Previous month") { stepMonth(by: -1) }
                monthStepButton(systemImage: "chevron.right", label: "Next month") { stepMonth(by: 1) }
            }
        }
    }

    private func monthStepButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GreenhouseTheme.Color.ink)
                .frame(width: 34, height: 34)
                .background(GreenhouseTheme.Color.card)
                .overlay(
                    RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.control)
                        .stroke(GreenhouseTheme.Color.inputBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.control))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func stepMonth(by delta: Int) {
        selectedMonth = ((selectedMonth - 1 + delta + 12) % 12) + 1
    }

    // MARK: - Segmented control

    private var modeSegmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "This month", isSelected: calendarMode == .month) { calendarMode = .month }
            segmentButton(title: "Whole year", isSelected: calendarMode == .year) { calendarMode = .year }
        }
        .padding(4)
        .background(GreenhouseTheme.Color.disabledFill)
        .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.control))
    }

    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                // 14px/600 per the handoff spec; no exact-matching
                // GreenhouseTheme.Font token, so hardcoded rather than
                // substituting a mismatched size (same rationale as
                // GHButtonStyle's own hardcoded label font).
                .font(.custom("Work Sans SemiBold", size: 14))
                .foregroundStyle(isSelected ? GreenhouseTheme.Color.ink : GreenhouseTheme.Color.bodyText)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(isSelected ? GreenhouseTheme.Color.card : .clear)
                // 6pt per the handoff spec — between Radius.chip (4) and
                // Radius.control (8), so hardcoded rather than rounding to
                // either existing token.
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - This month

    private var monthBody: some View {
        List {
            if let frostRisk {
                Section {
                    GHAlertRow(
                        headline: "Frost risk — \(frostRisk.date.formatted(date: .abbreviated, time: .omitted))",
                        detail: "Protect or bring these frost-tender plants indoors."
                    )
                    .ghListRow()

                    ForEach(Array(Set(frostRisk.atRiskPlants.compactMap { $0.species?.commonName })).sorted(), id: \.self) { name in
                        jobCardRow(
                            icon: "thermometer.snowflake",
                            title: name,
                            badge: currentMonthHarvestNames.contains(name) ? ("Harvest", .harvest) : nil
                        )
                        .ghListRow()
                    }
                }
            }

            if !plantsToPlantThisMonth.isEmpty {
                Section("Good time to plant") {
                    ForEach(plantsToPlantThisMonth) { plant in
                        jobCardRow(
                            icon: "hand.point.up.left.and.text",
                            title: plant.species?.commonName ?? "Plant",
                            badge: ("Sow", .sowing)
                        )
                        .ghListRow()
                    }
                }
            }

            if !plantsToHarvestThisMonth.isEmpty {
                Section("Ready around now") {
                    ForEach(plantsToHarvestThisMonth) { plant in
                        jobCardRow(
                            icon: "basket.fill",
                            title: plant.species?.commonName ?? "Plant",
                            badge: ("Harvest", .harvest)
                        )
                        .ghListRow()
                    }
                }
            }

            Section("Tasks") {
                if tasksForMonth.isEmpty {
                    Text("No tasks added for this month yet.")
                        .font(GreenhouseTheme.Font.small())
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                        .ghListRow()
                }
                ForEach(tasksForMonth) { task in
                    jobCardRow(
                        icon: task.category.symbolName,
                        title: task.title,
                        subtitle: task.details.isEmpty ? nil : task.details
                    )
                    .ghListRow()
                }
                .onDelete(perform: deleteTasks)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func jobCardRow(
        icon: String,
        title: String,
        subtitle: String? = nil,
        badge: (text: String, kind: GHBadge.Kind)? = nil
    ) -> some View {
        HStack(spacing: GreenhouseTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GreenhouseTheme.Color.green)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GreenhouseTheme.Font.listItem())
                    .foregroundStyle(GreenhouseTheme.Color.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(GreenhouseTheme.Font.small())
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                }
            }

            Spacer(minLength: GreenhouseTheme.Spacing.sm)

            if let badge {
                GHBadge(text: badge.text, kind: badge.kind)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(GreenhouseTheme.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card))
        .gh_flat()
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = tasksForMonth[index]
            guard !task.isBuiltIn else { continue }
            modelContext.delete(task)
        }
    }
}

/// Full-bleed custom List row: no default row background/separator, own
/// vertical rhythm — used for the card-style rows that replace this
/// screen's old plain Label rows. Same pattern as PlacedPlantDetailSheet's
/// private `ghRow()`, named distinctly since this one also hides the
/// separator (there's no native divider between "cards").
private extension View {
    func ghListRow() -> some View {
        self
            .listRowInsets(EdgeInsets(
                top: GreenhouseTheme.Spacing.xxs,
                leading: GreenhouseTheme.Spacing.screenPadding,
                bottom: GreenhouseTheme.Spacing.xxs,
                trailing: GreenhouseTheme.Spacing.screenPadding
            ))
            .listRowBackground(SwiftUI.Color.clear)
            .listRowSeparator(.hidden)
    }
}
