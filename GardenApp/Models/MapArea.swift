import Foundation
import SwiftData

/// A top-level map surface: either the outdoor garden or the greenhouse.
/// The app seeds exactly one of each on first launch; both are rendered by
/// the same GardenMapView, parameterized by this model.
@Model
final class MapArea: Identifiable {
    var id: UUID
    var name: String
    var kindRaw: String
    /// Size of the map in grid cells (columns x rows). Kept small and fixed
    /// for v1 so the canvas fits comfortably on an iPhone screen.
    var columns: Int
    var rows: Int

    @Relationship(deleteRule: .cascade, inverse: \Bed.mapArea)
    var beds: [Bed]? = []

    @Relationship(deleteRule: .cascade, inverse: \PlacedPlant.mapArea)
    var placedPlants: [PlacedPlant]? = []

    init(
        id: UUID = UUID(),
        name: String,
        kind: MapAreaKind,
        columns: Int = 10,
        rows: Int = 14
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.columns = columns
        self.rows = rows
    }

    var kind: MapAreaKind {
        get { MapAreaKind(rawValue: kindRaw) ?? .outdoor }
        set { kindRaw = newValue.rawValue }
    }
}
