import Foundation
import SwiftData
import UserNotifications

/// Checks the forecast for the garden's location and warns about frost
/// risk to outdoor frost-tender plants. See
/// docs/plans/2026-09-14-weather-and-harvest-design.md.
enum FrostAlertService {
    static let backgroundTaskIdentifier = "com.tomasrojder.gardenapp.frostcheck"

    /// Ground frost ("markfrost") routinely occurs a couple of degrees
    /// above the air-temperature freezing point, and an early warning is
    /// the right failure mode for a feature whose job is preventing lost
    /// plants.
    static let frostRiskThresholdCelsius = 2.0

    struct FrostRisk {
        let date: Date
        let atRiskPlants: [PlacedPlant]
    }

    /// Fetches the forecast and cross-references it against outdoor,
    /// frost-tender, currently-placed plants. Returns nil if no
    /// `GardenLocation` has been set, or no frost risk was found.
    static func checkFrostRisk(in context: ModelContext) async throws -> FrostRisk? {
        var locationDescriptor = FetchDescriptor<GardenLocation>()
        locationDescriptor.fetchLimit = 1
        guard let location = try context.fetch(locationDescriptor).first else { return nil }

        let forecast = try await SMHIWeatherService.fetchDailyMinTemperatures(
            latitude: location.latitude,
            longitude: location.longitude
        )
        guard let firstRiskDay = forecast.first(where: { $0.minTemperatureCelsius <= frostRiskThresholdCelsius }) else {
            return nil
        }

        let atRiskStatuses: Set<PlantStatus> = [.planned, .planted, .growing]
        let allPlants = try context.fetch(FetchDescriptor<PlacedPlant>())
        let atRisk = allPlants.filter { plant in
            plant.mapArea?.kind == .outdoor
                && plant.species?.isFrostTender == true
                && atRiskStatuses.contains(plant.status)
        }

        guard !atRisk.isEmpty else { return nil }
        return FrostRisk(date: firstRiskDay.date, atRiskPlants: atRisk)
    }

    /// Runs the check and, if there's a risk, posts a local notification.
    /// Safe to call any time (foreground open, or a background refresh) —
    /// errors (no location set, network failure) are swallowed since this
    /// is a best-effort nudge, not a critical path.
    static func checkAndNotify(in context: ModelContext) async {
        guard let risk = try? await checkFrostRisk(in: context), !risk.atRiskPlants.isEmpty else { return }

        let names = Set(risk.atRiskPlants.compactMap { $0.species?.commonName }).sorted()
        guard !names.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "Frost risk in your garden"
        content.body = "Frost forecast — protect or bring in: \(names.joined(separator: ", "))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "frost-risk-\(Int(risk.date.timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
