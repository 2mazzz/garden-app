import Foundation
import SwiftData

/// A "pallet" / raised bed / plot within a MapArea. Plants are typically
/// placed inside a bed; trees are usually placed directly on the map instead.
@Model
final class Bed: Identifiable {
    // Every stored attribute needs a default value at the declaration
    // (not just as an init parameter default) — CloudKit-backed SwiftData
    // sync requires every non-optional attribute to have one. See
    // docs/decisions/0008-cloudkit-fallback.md.
    var id: UUID = UUID()
    var name: String = ""
    var x: Int = 0
    var y: Int = 0
    var width: Int = 1
    var height: Int = 1
    var colorHex: String = "#8B5E3C"
    var mapArea: MapArea?

    // .nullify, not .cascade: deleting a bed should just detach the plants
    // inside it (they keep their map position and stay visible), not
    // delete them along with the bed.
    @Relationship(deleteRule: .nullify, inverse: \PlacedPlant.bed)
    var placedPlants: [PlacedPlant]? = []

    init(
        id: UUID = UUID(),
        name: String,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        colorHex: String = "#8B5E3C",
        mapArea: MapArea? = nil
    ) {
        self.id = id
        self.name = name
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.colorHex = colorHex
        self.mapArea = mapArea
    }

    func occupies(x: Int, y: Int) -> Bool {
        x >= self.x && x < self.x + width && y >= self.y && y < self.y + height
    }
}
