import SwiftUI

/// Reusable 12-column "season strip" — one bar per calendar month, lit up
/// for whichever months are in `activeMonths` (0 = Jan ... 11 = Dec). Used
/// on Plant detail as the "Its year" strip. Deliberately generic (just a
/// `Set<Int>` of active months, no plant-specific coupling) so it can be
/// reused elsewhere later — see the design handoff's "Its year" pattern.
struct SeasonStripView: View {
    var activeMonths: Set<Int>

    private static let monthInitials = Calendar.current.veryShortMonthSymbols
    private let inactiveColor = SwiftUI.Color(hex: "#E7EBE0")

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<12, id: \.self) { month in
                VStack(spacing: GreenhouseTheme.Spacing.xxs) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(activeMonths.contains(month) ? GreenhouseTheme.Color.green : inactiveColor)
                        .frame(height: 30)
                    Text(Self.monthInitials.indices.contains(month) ? Self.monthInitials[month] : "")
                        .font(GreenhouseTheme.Font.mono(10))
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                }
            }
        }
    }
}

#Preview("SeasonStripView") {
    VStack(spacing: GreenhouseTheme.Spacing.md) {
        SeasonStripView(activeMonths: [2, 3, 4, 5, 6, 7])
        SeasonStripView(activeMonths: [])
    }
    .padding()
    .background(GreenhouseTheme.Color.paper)
}
