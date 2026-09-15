import Foundation
import SwiftData

/// A top-level map surface: either the outdoor garden or the greenhouse.
/// The app seeds exactly one of each on first launch; both are rendered by
/// the same GardenMapView, parameterized by this model.
@Model
final class MapArea: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var kindRaw: String = MapAreaKind.outdoor.rawValue
    /// Size of the map in grid cells (columns x rows). Kept small and fixed
    /// for v1 so the canvas fits comfortably on an iPhone screen.
    var columns: Int = 10
    var rows: Int = 14

    @Relationship(deleteRule: .cascade, inverse: \Bed.mapArea)
    var beds: [Bed]? = []

    @Relationship(deleteRule: .cascade, inverse: \PlacedPlant.mapArea)
    var placedPlants: [PlacedPlant]? = []

    /// Structures placed on this map (e.g. the Greenhouse, placed on the Garden).
    @Relationship(deleteRule: .cascade, inverse: \Structure.mapArea)
    var structures: [Structure]? = []

    /// Structures elsewhere that lead into this map when tapped (e.g. the
    /// Greenhouse structure on the Garden map links into this MapArea when
    /// this is the Greenhouse map itself).
    @Relationship(inverse: \Structure.linkedMapArea)
    var enteredByStructures: [Structure]? = []

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

    /// Changes the grid size. Existing beds/structures/plants are clamped
    /// back inside the new bounds rather than deleted, so shrinking never
    /// loses data — see docs/decisions/0012-garden-scale-and-zoom.md.
    func resize(toColumns columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows

        for bed in beds ?? [] {
            bed.width = min(bed.width, columns)
            bed.height = min(bed.height, rows)
            bed.x = min(bed.x, max(0, columns - bed.width))
            bed.y = min(bed.y, max(0, rows - bed.height))
        }
        for structure in structures ?? [] {
            structure.width = min(structure.width, columns)
            structure.height = min(structure.height, rows)
            structure.x = min(structure.x, max(0, columns - structure.width))
            structure.y = min(structure.y, max(0, rows - structure.height))
        }
        for plant in placedPlants ?? [] {
            plant.x = min(plant.x, max(0, columns - 1))
            plant.y = min(plant.y, max(0, rows - 1))
        }
    }
}
