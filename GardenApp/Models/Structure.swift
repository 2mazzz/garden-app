import Foundation
import SwiftData

/// A physical structure placed on a MapArea — currently just the Greenhouse,
/// placed on the outdoor Garden map. Tapping a structure that has a
/// `linkedMapArea` navigates into that area's own map (e.g. tapping the
/// greenhouse on the garden overview enters the greenhouse's own grid).
@Model
final class Structure: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var x: Int = 0
    var y: Int = 0
    var width: Int = 1
    var height: Int = 1
    var colorHex: String = "#6B6B6B"
    var symbolName: String = "house.fill"

    /// The MapArea this structure sits on (e.g. the outdoor Garden).
    var mapArea: MapArea?
    /// The MapArea entered by tapping this structure (e.g. the Greenhouse).
    /// Optional so structures with no interior of their own (a shed, a
    /// compost bin) can be added later without a migration.
    var linkedMapArea: MapArea?

    init(
        id: UUID = UUID(),
        name: String,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        colorHex: String = "#6B6B6B",
        symbolName: String = "house.fill",
        mapArea: MapArea? = nil,
        linkedMapArea: MapArea? = nil
    ) {
        self.id = id
        self.name = name
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.mapArea = mapArea
        self.linkedMapArea = linkedMapArea
    }

    func occupies(x: Int, y: Int) -> Bool {
        x >= self.x && x < self.x + width && y >= self.y && y < self.y + height
    }
}
