import SwiftUI

/// The Calendar tab's "Whole year" mode: a season grid showing every
/// in-garden species' sow/grow/harvest months at a glance. See the design
/// handoff README's "Calendar" section and
/// docs/plans/2026-09-15-greenhouse-redesign-design.md.
struct YearGridView: View {
    /// Already deduped, one entry per species currently placed (non-removed)
    /// somewhere in the garden — computed by the caller (CareCalendarView),
    /// which already queries PlacedPlant for its own "this month" groups.
    var species: [PlantSpecies]

    private static let monthInitials = Calendar.current.veryShortMonthSymbols
    private let labelColumnWidth: CGFloat = 92
    private let cellHeight: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.sm) {
            legend

            if species.isEmpty {
                Text("No plants placed in the garden yet.")
                    .font(GreenhouseTheme.Font.small())
                    .foregroundStyle(GreenhouseTheme.Color.metaText)
            } else {
                VStack(spacing: 0) {
                    monthHeaderRow
                    ForEach(species) { one in
                        speciesRow(one)
                        Divider()
                            .overlay(GreenhouseTheme.Color.cardDivider)
                    }
                }
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: GreenhouseTheme.Spacing.md) {
            legendSwatch(color: GreenhouseTheme.Color.greenTint, label: "Sow")
            legendSwatch(color: GreenhouseTheme.Color.leaf, label: "Grow")
            legendSwatch(color: GreenhouseTheme.Color.green, label: "Harvest")
        }
    }

    private func legendSwatch(color: SwiftUI.Color, label: String) -> some View {
        HStack(spacing: GreenhouseTheme.Spacing.xxs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(GreenhouseTheme.Font.small())
                .foregroundStyle(GreenhouseTheme.Color.bodyText)
        }
    }

    // MARK: - Grid

    private var monthHeaderRow: some View {
        HStack(spacing: 3) {
            Color.clear.frame(width: labelColumnWidth, height: 1)
            ForEach(0..<12, id: \.self) { index in
                Text(Self.monthInitials.indices.contains(index) ? Self.monthInitials[index] : "")
                    .font(GreenhouseTheme.Font.mono(9))
                    .foregroundStyle(GreenhouseTheme.Color.metaText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func speciesRow(_ species: PlantSpecies) -> some View {
        let phases = monthPhases(for: species)
        return HStack(spacing: 3) {
            Text(species.commonName)
                .font(GreenhouseTheme.Font.small())
                .foregroundStyle(GreenhouseTheme.Color.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: labelColumnWidth, alignment: .leading)

            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color(for: phases[index]))
                    .frame(maxWidth: .infinity)
                    .frame(height: cellHeight)
            }
        }
        .padding(.vertical, 7)
    }

    private enum MonthPhase {
        case none, sow, grow, harvest
    }

    private func color(for phase: MonthPhase) -> SwiftUI.Color {
        switch phase {
        case .none: return GreenhouseTheme.Color.mist
        case .sow: return GreenhouseTheme.Color.greenTint
        case .grow: return GreenhouseTheme.Color.leaf
        case .harvest: return GreenhouseTheme.Color.green
        }
    }

    /// One phase per month index (0-11), precedence harvest > grow > sow.
    /// "Grow" is inferred as the span strictly between the earliest sow
    /// month and the earliest harvest month — there's no separate "grow"
    /// data in the model — and is only shown when that span makes sense
    /// (harvest starts after sow starts); otherwise no grow band is drawn
    /// for that species, per the design doc's stated fallback.
    private func monthPhases(for species: PlantSpecies) -> [MonthPhase] {
        let sowMonths = Set(species.plantingMonths.filter { (1...12).contains($0) })
        let harvestMonths = Set(species.harvestMonths.filter { (1...12).contains($0) })

        var growMonths = Set<Int>()
        if let sowStart = sowMonths.min(), let harvestStart = harvestMonths.min(), harvestStart > sowStart {
            growMonths = Set((sowStart + 1)..<harvestStart)
        }

        return (1...12).map { month in
            if harvestMonths.contains(month) { return .harvest }
            if sowMonths.contains(month) { return .sow }
            if growMonths.contains(month) { return .grow }
            return .none
        }
    }
}

#Preview {
    YearGridView(species: [])
        .padding()
        .background(GreenhouseTheme.Color.paper)
}
