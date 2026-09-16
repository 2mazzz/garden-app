import Foundation
import SwiftData

/// One actual plant or tree that exists in the garden or greenhouse —
/// an instance of a PlantSpecies, positioned on a MapArea and optionally
/// inside a Bed.
@Model
final class PlacedPlant: Identifiable {
    var id: UUID = UUID()
    var species: PlantSpecies?
    var mapArea: MapArea?
    var bed: Bed?

    /// Position in grid cells, relative to the owning MapArea.
    var x: Int = 0
    var y: Int = 0
    /// Footprint in grid cells — a real area (a strawberry zone inside a
    /// bed, a tree's canopy), not a fixed-size point icon. Draggable and
    /// resizable the same way beds are. See
    /// docs/decisions/0017-bed-shapes-and-plant-zones.md.
    var width: Int = 1
    var height: Int = 1

    var statusRaw: String = PlantStatus.planned.rawValue
    var datePlanted: Date?
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \HarvestLog.placedPlant)
    var harvestLogs: [HarvestLog]? = []

    @Relationship(deleteRule: .cascade, inverse: \PlantNote.placedPlant)
    var notes_log: [PlantNote]? = []

    // .nullify, not .cascade: a GardenTask referencing this plant is a
    // freeform to-do, not owned data about the plant — deleting the plant
    // should just detach the task, not delete it. CloudKit-backed SwiftData
    // requires every relationship to declare an inverse (see
    // docs/decisions/0009-cloudkit-attribute-defaults.md's sibling
    // constraint), so GardenTask.placedPlant needs this counterpart.
    @Relationship(deleteRule: .nullify, inverse: \GardenTask.placedPlant)
    var gardenTasks: [GardenTask]? = []

    init(
        id: UUID = UUID(),
        species: PlantSpecies?,
        mapArea: MapArea?,
        bed: Bed? = nil,
        x: Int,
        y: Int,
        width: Int = 1,
        height: Int = 1,
        status: PlantStatus = .planned,
        datePlanted: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.species = species
        self.mapArea = mapArea
        self.bed = bed
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.statusRaw = status.rawValue
        self.datePlanted = datePlanted
        self.notes = notes
    }

    var status: PlantStatus {
        get { PlantStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }
}
