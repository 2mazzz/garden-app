import Foundation
import SwiftData

/// One freeform journal entry for a planting — the "Log" section on Plant
/// detail. Deliberately separate from HarvestLog: harvest keeps its own
/// quantity/unit shape, this is just a dated note.
@Model
final class PlantNote: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date.now
    var text: String = ""
    var placedPlant: PlacedPlant?

    init(id: UUID = UUID(), date: Date = .now, text: String, placedPlant: PlacedPlant?) {
        self.id = id
        self.date = date
        self.text = text
        self.placedPlant = placedPlant
    }
}
