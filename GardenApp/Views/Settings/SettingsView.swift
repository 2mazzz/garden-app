import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \MapArea.name) private var mapAreas: [MapArea]

    var body: some View {
        NavigationStack {
            Form {
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

    private func mapAreaSizeControls(_ area: MapArea) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(area.name)
                .font(.headline)
            Stepper(value: Binding(
                get: { area.columns },
                set: { area.resize(toColumns: $0, rows: area.rows) }
            ), in: 4...40, step: 2) {
                Text("Width: \(area.columns) cells (~\(metersLabel(for: area.columns))m)")
            }
            Stepper(value: Binding(
                get: { area.rows },
                set: { area.resize(toColumns: area.columns, rows: $0) }
            ), in: 4...40, step: 2) {
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
