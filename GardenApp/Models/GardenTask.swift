import Foundation
import SwiftData

/// A hand-entered, dated task shown in the Today tab — distinct from
/// MonthlyTaskTemplate (which is a recurring, month-level reminder shown
/// in the Care Calendar, not a checkable dated instance). See
/// docs/plans/2026-09-15-greenhouse-redesign-design.md.
@Model
final class GardenTask: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    /// Freeform "where" line, e.g. "Bed 1", "Glass". Independent of
    /// placedPlant/bed so a task can name a location without a formal link.
    var locationText: String = ""
    var dueDate: Date = Date.now
    var isDone: Bool = false
    var notes: String = ""
    var createdAt: Date = Date.now

    var placedPlant: PlacedPlant?
    var bed: Bed?

    init(
        id: UUID = UUID(),
        title: String,
        locationText: String = "",
        dueDate: Date = .now,
        isDone: Bool = false,
        notes: String = "",
        placedPlant: PlacedPlant? = nil,
        bed: Bed? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.locationText = locationText
        self.dueDate = dueDate
        self.isDone = isDone
        self.notes = notes
        self.placedPlant = placedPlant
        self.bed = bed
        self.createdAt = createdAt
    }

    /// True when overdue and not yet done. Computed, not stored — a stored
    /// flag would need a daily background job to stay correct.
    var isLate: Bool {
        !isDone && dueDate < Calendar.current.startOfDay(for: .now)
    }
}
