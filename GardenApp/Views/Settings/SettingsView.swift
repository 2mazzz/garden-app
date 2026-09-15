import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage(GardenTheme.storageKey) private var themeRawValue: String = GardenTheme.handDrawnJournal.rawValue

    @Query(sort: \MapArea.name) private var mapAreas: [MapArea]

    private var currentTheme: GardenTheme { GardenTheme(rawValue: themeRawValue) ?? .handDrawnJournal }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(GardenTheme.allCases) { theme in
                        Button {
                            themeRawValue = theme.rawValue
                        } label: {
                            themeRow(theme)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Garden style")
                } footer: {
                    Text("Changes the look of the map, beds, and structures. Each device can pick its own.")
                }

                Section {
                    ForEach(mapAreas) { area in
                        mapAreaSizeControls(area)
                    }
                } header: {
                    Text("Garden size")
                } footer: {
                    Text("Each grid cell represents about 0.5 meters. Shrinking a map moves anything outside the new bounds back inside it — nothing is deleted.")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func themeRow(_ theme: GardenTheme) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(Array(theme.previewSwatchColors.enumerated()), id: \.offset) { _, color in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: 14, height: 28)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.3)))

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.displayName)
                    .font(theme.headingFont)
                    .foregroundStyle(.primary)
                Text(theme.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if theme.rawValue == themeRawValue {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.accentColor)
            }
        }
        .contentShape(Rectangle())
    }

    private func mapAreaSizeControls(_ area: MapArea) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(area.name)
                .font(.headline)
            Stepper(value: Binding(
                get: { area.columns },
                set: { area.resize(toColumns: $0, rows: area.rows) }
            ), in: 4...400, step: 5) {
                Text("Width: \(area.columns) cells (~\(metersLabel(for: area.columns))m)")
            }
            Stepper(value: Binding(
                get: { area.rows },
                set: { area.resize(toColumns: area.columns, rows: $0) }
            ), in: 4...400, step: 5) {
                Text("Height: \(area.rows) cells (~\(metersLabel(for: area.rows))m)")
            }
        }
        .padding(.vertical, 2)
    }

    private func metersLabel(for cells: Int) -> String {
        let meters = Double(cells) * 0.5
        return meters.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", meters)
            : String(format: "%.1f", meters)
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
