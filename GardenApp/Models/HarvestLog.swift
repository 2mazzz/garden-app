import Foundation
import SwiftData

/// One harvest event for a specific planting — how much was picked, and when.
@Model
final class HarvestLog: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date.now
    var quantity: Double?
    var unit: String = "kg"
    var notes: String = ""
    var placedPlant: PlacedPlant?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        quantity: Double? = nil,
        unit: String = "kg",
        notes: String = "",
        placedPlant: PlacedPlant?
    ) {
        self.id = id
        self.date = date
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
        self.placedPlant = placedPlant
    }
}
