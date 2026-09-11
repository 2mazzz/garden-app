import Foundation
import SwiftData

/// One actual plant or tree that exists in the garden or greenhouse —
/// an instance of a PlantSpecies, positioned on a MapArea and optionally
/// inside a Bed.
@Model
final class PlacedPlant: Identifiable {
    var id: UUID
    var species: PlantSpecies?
    var mapArea: MapArea?
    var bed: Bed?

    /// Position in grid cells, relative to the owning MapArea.
    var x: Int
    var y: Int

    var statusRaw: String
    var datePlanted: Date?
    var notes: String

    init(
        id: UUID = UUID(),
        species: PlantSpecies?,
        mapArea: MapArea?,
        bed: Bed? = nil,
        x: Int,
        y: Int,
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
        self.statusRaw = status.rawValue
        self.datePlanted = datePlanted
        self.notes = notes
    }

    var status: PlantStatus {
        get { PlantStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }
}
