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

extension Array where Element == HarvestLog {
    /// Sums quantities by unit across whatever set of logs the caller
    /// passes in — the same summarization math whether that's one
    /// planting's own logs or every placement of a species pooled
    /// together; only the *scoping* differs at each call site.
    var totalsByUnit: [(unit: String, total: Double)] {
        let totalsByUnit = Dictionary(grouping: self, by: { $0.unit })
            .mapValues { $0.compactMap(\.quantity).reduce(0, +) }
        return totalsByUnit
            .filter { $0.value > 0 }
            .map { (unit: $0.key, total: $0.value) }
            .sorted { $0.unit < $1.unit }
    }
}
