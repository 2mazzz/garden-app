import SwiftUI
import SwiftData
import CoreLocation
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("frostAlertsEnabled") private var frostAlertsEnabled: Bool = false

    @Query(sort: \MapArea.name) private var mapAreas: [MapArea]
    @Query private var gardenLocations: [GardenLocation]

    @State private var locationSearchText = ""
    @State private var isGeocoding = false
    @State private var locationErrorMessage: String?

    private var gardenLocation: GardenLocation? { gardenLocations.first }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(mapAreas) { area in
                        mapAreaSizeControls(area)
                    }
                } header: {
                    sectionHeader("Garden size")
                } footer: {
                    Text("Each grid cell represents about 0.5 meters. Shrinking a map moves anything outside the new bounds back inside it — nothing is deleted.")
                        .font(GreenhouseTheme.Font.small())
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                }

                Section {
                    if let location = gardenLocation {
                        LabeledContent("Location", value: location.placeName)
                            .font(GreenhouseTheme.Font.body())
                            .foregroundStyle(GreenhouseTheme.Color.ink)
                        Button("Change location") {
                            locationSearchText = location.placeName
                        }
                        .font(GreenhouseTheme.Font.body())
                    }
                    TextField("Address or place (e.g. \"Södertälje\")", text: $locationSearchText)
                        .font(GreenhouseTheme.Font.body())
                    Button {
                        Task { await geocodeAndSaveLocation() }
                    } label: {
                        if isGeocoding {
                            ProgressView()
                        } else {
                            Text(gardenLocation == nil ? "Set location" : "Update")
                        }
                    }
                    .font(GreenhouseTheme.Font.body())
                    .disabled(locationSearchText.trimmingCharacters(in: .whitespaces).isEmpty || isGeocoding)
                    if let locationErrorMessage {
                        Text(locationErrorMessage)
                            .font(GreenhouseTheme.Font.small())
                            .foregroundStyle(.red)
                    }

                    Toggle("Frost alerts", isOn: $frostAlertsEnabled)
                        .font(GreenhouseTheme.Font.body())
                        .disabled(gardenLocation == nil)
                        .onChange(of: frostAlertsEnabled) { _, enabled in
                            if enabled { requestNotificationPermission() }
                        }
                } header: {
                    sectionHeader("Garden weather")
                } footer: {
                    Text("Set once — the garden's location, not your phone's. Used to warn about frost so you can protect frost-tender plants placed outdoors. Requires a location before alerts can be turned on.")
                        .font(GreenhouseTheme.Font.small())
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                }
            }
            .tint(GreenhouseTheme.Color.green)
            .scrollContentBackground(.hidden)
            .background(GreenhouseTheme.Color.paper)
            .listSectionSpacing(GreenhouseTheme.Spacing.md)
            .listRowSeparatorTint(GreenhouseTheme.Color.cardDivider)
            .navigationTitle("Settings")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(GreenhouseTheme.Font.label())
            .textCase(.uppercase)
            .kerning(1.1)
            .foregroundStyle(GreenhouseTheme.Color.metaText)
    }

    private func mapAreaSizeControls(_ area: MapArea) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(area.name)
                .font(GreenhouseTheme.Font.cardTitle())
                .foregroundStyle(GreenhouseTheme.Color.ink)
            Stepper(value: Binding(
                get: { area.columns },
                set: { area.resize(toColumns: $0, rows: area.rows) }
            ), in: 4...400, step: 5) {
                Text("Width: \(area.columns) cells (~\(metersLabel(for: area.columns))m)")
                    .font(GreenhouseTheme.Font.body())
                    .foregroundStyle(GreenhouseTheme.Color.bodyText)
            }
            Stepper(value: Binding(
                get: { area.rows },
                set: { area.resize(toColumns: area.columns, rows: $0) }
            ), in: 4...400, step: 5) {
                Text("Height: \(area.rows) cells (~\(metersLabel(for: area.rows))m)")
                    .font(GreenhouseTheme.Font.body())
                    .foregroundStyle(GreenhouseTheme.Color.bodyText)
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

    private func geocodeAndSaveLocation() async {
        isGeocoding = true
        locationErrorMessage = nil
        defer { isGeocoding = false }

        do {
            let placemarks = try await CLGeocoder().geocodeAddressString(locationSearchText)
            guard let placemark = placemarks.first, let coordinate = placemark.location?.coordinate else {
                locationErrorMessage = "Couldn't find that place — try a more specific address."
                return
            }
            let name = [placemark.locality, placemark.country]
                .compactMap { $0 }
                .joined(separator: ", ")
            let resolvedName = name.isEmpty ? locationSearchText : name

            if let existing = gardenLocation {
                existing.latitude = coordinate.latitude
                existing.longitude = coordinate.longitude
                existing.placeName = resolvedName
            } else {
                modelContext.insert(GardenLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    placeName: resolvedName
                ))
            }
            try? modelContext.save()
            locationSearchText = ""
        } catch {
            locationErrorMessage = "Couldn't look up that place — check your connection and try again."
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
