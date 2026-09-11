import Foundation
import SwiftData

/// A "pallet" / raised bed / plot within a MapArea. Plants are typically
/// placed inside a bed; trees are usually placed directly on the map instead.
@Model
final class Bed: Identifiable {
    var id: UUID
    var name: String
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    var colorHex: String
    var mapArea: MapArea?

    @Relationship(deleteRule: .cascade, inverse: \PlacedPlant.bed)
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
}
