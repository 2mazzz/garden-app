import Foundation
import SwiftData

/// A catalog entry describing a *type* of plant or tree (e.g. "Tomato", "Apple Tree").
/// This is the wiki: care instructions live here, independent of any specific
/// plant that has actually been placed on the map.
@Model
final class PlantSpecies: Identifiable {
    var id: UUID = UUID()
    var commonName: String = ""
    var scientificName: String?
    var categoryRaw: String = PlantCategory.other.rawValue
    var sunRequirementRaw: String = SunRequirement.fullSun.rawValue
    var waterRequirementRaw: String = WaterRequirement.medium.rawValue
    var isTree: Bool = false

    /// Freeform care instructions (watering, pruning, feeding, winter care, etc.)
    var careNotes: String = ""
    var soilNotes: String = ""
    var spacingNotes: String = ""

    /// Months (1-12) that are good for planting this species outdoors.
    var plantingMonths: [Int] = []
    /// Months (1-12) when this species is typically harvested or blooms.
    var harvestMonths: [Int] = []

    /// SF Symbol name used to render this species on the map and in lists.
    var symbolName: String = "leaf.fill"
    /// Hex color (e.g. "#3A7D44") used as a tint for the species' marker.
    var colorHex: String = "#3A7D44"

    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \PlacedPlant.species)
    var placements: [PlacedPlant]? = []

    init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String? = nil,
        category: PlantCategory,
        sunRequirement: SunRequirement,
        waterRequirement: WaterRequirement,
        isTree: Bool = false,
        careNotes: String = "",
        soilNotes: String = "",
        spacingNotes: String = "",
        plantingMonths: [Int] = [],
        harvestMonths: [Int] = [],
        symbolName: String = "leaf.fill",
        colorHex: String = "#3A7D44",
        createdAt: Date = .now
    ) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.categoryRaw = category.rawValue
        self.sunRequirementRaw = sunRequirement.rawValue
        self.waterRequirementRaw = waterRequirement.rawValue
        self.isTree = isTree
        self.careNotes = careNotes
        self.soilNotes = soilNotes
        self.spacingNotes = spacingNotes
        self.plantingMonths = plantingMonths
        self.harvestMonths = harvestMonths
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.createdAt = createdAt
    }

    var category: PlantCategory {
        get { PlantCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var sunRequirement: SunRequirement {
        get { SunRequirement(rawValue: sunRequirementRaw) ?? .fullSun }
        set { sunRequirementRaw = newValue.rawValue }
    }

    var waterRequirement: WaterRequirement {
        get { WaterRequirement(rawValue: waterRequirementRaw) ?? .medium }
        set { waterRequirementRaw = newValue.rawValue }
    }

    func isGoodToPlant(inMonth month: Int) -> Bool {
        plantingMonths.contains(month)
    }
}
