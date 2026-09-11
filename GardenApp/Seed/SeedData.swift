import Foundation
import SwiftData

/// Populates first-launch data: the two MapAreas (garden + greenhouse), a
/// starter plant/tree catalog for the wiki, and a generic set of monthly
/// tasks. Runs once — checks for existing data before inserting anything,
/// so it's safe to call on every launch.
///
/// Planting/harvest months below assume the Northern Hemisphere. If that's
/// wrong for your garden, edit the months on each wiki entry — see
/// docs/decisions/0004-seed-data-assumptions.md.
enum SeedData {
    static func populateIfNeeded(in context: ModelContext) {
        seedMapAreasIfNeeded(in: context)
        seedSpeciesIfNeeded(in: context)
        seedTasksIfNeeded(in: context)
        try? context.save()
    }

    private static func seedMapAreasIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<MapArea>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        context.insert(MapArea(name: "Garden", kind: .outdoor, columns: 10, rows: 14))
        context.insert(MapArea(name: "Greenhouse", kind: .greenhouse, columns: 6, rows: 8))
    }

    private static func seedSpeciesIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<PlantSpecies>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for species in starterSpecies {
            context.insert(species)
        }
    }

    private static func seedTasksIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<MonthlyTaskTemplate>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for task in starterTasks {
            context.insert(task)
        }
    }

    private static var starterSpecies: [PlantSpecies] {
        [
            PlantSpecies(
                commonName: "Tomato",
                scientificName: "Solanum lycopersicum",
                category: .vegetable,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Stake or cage as it grows. Pinch off suckers for bigger fruit. Water at the base to avoid leaf blight.",
                soilNotes: "Rich, well-drained soil with compost worked in.",
                spacingNotes: "45-60cm apart.",
                plantingMonths: [4, 5],
                harvestMonths: [7, 8, 9],
                symbolName: "carrot.fill",
                colorHex: "#D64545"
            ),
            PlantSpecies(
                commonName: "Carrot",
                scientificName: "Daucus carota",
                category: .vegetable,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Thin seedlings once they sprout so roots have room. Keep soil consistently moist.",
                soilNotes: "Loose, stone-free soil so roots grow straight.",
                spacingNotes: "Thin to 5-8cm apart.",
                plantingMonths: [3, 4, 5],
                harvestMonths: [7, 8, 9],
                symbolName: "carrot.fill",
                colorHex: "#E8823C"
            ),
            PlantSpecies(
                commonName: "Basil",
                scientificName: "Ocimum basilicum",
                category: .herb,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Pinch off flower buds to keep leaves coming. Harvest from the top down.",
                soilNotes: "Well-drained, moderately rich soil.",
                spacingNotes: "20-25cm apart.",
                plantingMonths: [5, 6],
                harvestMonths: [6, 7, 8, 9],
                symbolName: "leaf.fill",
                colorHex: "#4E7A3D"
            ),
            PlantSpecies(
                commonName: "Rosemary",
                scientificName: "Salvia rosmarinus",
                category: .herb,
                sunRequirement: .fullSun,
                waterRequirement: .low,
                careNotes: "Let soil dry between waterings. Prune after flowering to keep shape. Can overwinter indoors in cold climates.",
                soilNotes: "Sandy, well-drained soil.",
                spacingNotes: "60cm apart if left to grow into a shrub.",
                plantingMonths: [4, 5],
                harvestMonths: [6, 7, 8, 9, 10],
                symbolName: "leaf.fill",
                colorHex: "#5C7A5C"
            ),
            PlantSpecies(
                commonName: "Sunflower",
                scientificName: "Helianthus annuus",
                category: .flower,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Stake tall varieties in windy spots. Deadhead to prolong blooming, or leave heads for birds in autumn.",
                soilNotes: "Any well-drained soil.",
                spacingNotes: "30-60cm apart depending on variety.",
                plantingMonths: [4, 5],
                harvestMonths: [8, 9],
                symbolName: "camera.macro",
                colorHex: "#E8B93C"
            ),
            PlantSpecies(
                commonName: "Tulip",
                scientificName: "Tulipa",
                category: .flower,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Let foliage die back naturally after blooming before removing — it feeds next year's bulb.",
                soilNotes: "Well-drained soil; bulbs rot in standing water.",
                spacingNotes: "10-15cm apart, planted 15-20cm deep.",
                plantingMonths: [10, 11],
                harvestMonths: [4, 5],
                symbolName: "camera.macro",
                colorHex: "#C24C8C"
            ),
            PlantSpecies(
                commonName: "Blueberry Bush",
                scientificName: "Vaccinium",
                category: .shrub,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Needs acidic soil. Mulch with pine bark or needles. Prune out old canes in late winter.",
                soilNotes: "Acidic, well-drained soil (pH 4.5-5.5).",
                spacingNotes: "1.2-1.5m apart.",
                plantingMonths: [3, 4, 10, 11],
                harvestMonths: [7, 8],
                symbolName: "tree.fill",
                colorHex: "#3E5C8A"
            ),
            PlantSpecies(
                commonName: "Lavender",
                scientificName: "Lavandula",
                category: .shrub,
                sunRequirement: .fullSun,
                waterRequirement: .low,
                careNotes: "Prune hard after flowering to keep it compact and prevent it going woody. Avoid overwatering.",
                soilNotes: "Poor to average, very well-drained soil.",
                spacingNotes: "45-60cm apart.",
                plantingMonths: [4, 5],
                harvestMonths: [6, 7, 8],
                symbolName: "leaf.fill",
                colorHex: "#8B7CC2"
            ),
            PlantSpecies(
                commonName: "Apple Tree",
                scientificName: "Malus domestica",
                category: .tree,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                isTree: true,
                careNotes: "Prune in late winter while dormant to keep an open shape. Thin fruit clusters in early summer for bigger apples.",
                soilNotes: "Deep, well-drained loam.",
                spacingNotes: "3-5m apart depending on rootstock.",
                plantingMonths: [11, 12, 2, 3],
                harvestMonths: [9, 10],
                symbolName: "tree.fill",
                colorHex: "#6B8E4E"
            ),
            PlantSpecies(
                commonName: "Cherry Tree",
                scientificName: "Prunus avium",
                category: .tree,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                isTree: true,
                careNotes: "Prune in summer, never winter, to avoid silver leaf disease. Net against birds as fruit ripens.",
                soilNotes: "Well-drained, slightly acidic to neutral soil.",
                spacingNotes: "4-6m apart.",
                plantingMonths: [11, 12, 2, 3],
                harvestMonths: [6, 7],
                symbolName: "tree.fill",
                colorHex: "#7A3E4E"
            ),
            PlantSpecies(
                commonName: "Lemon Tree",
                scientificName: "Citrus limon",
                category: .fruit,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                isTree: true,
                careNotes: "Frost-sensitive — best in a greenhouse or brought indoors over winter in cold climates. Feed with citrus fertilizer through the growing season.",
                soilNotes: "Well-drained, slightly acidic soil.",
                spacingNotes: "1.5-2m if potted; more if in open ground.",
                plantingMonths: [4, 5],
                harvestMonths: [11, 12, 1],
                symbolName: "applelogo",
                colorHex: "#D9C23C"
            ),
            PlantSpecies(
                commonName: "Bell Pepper",
                scientificName: "Capsicum annuum",
                category: .vegetable,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Slow to start — good greenhouse candidate in cooler climates. Support heavier fruiting varieties with stakes.",
                soilNotes: "Rich, well-drained soil.",
                spacingNotes: "40-50cm apart.",
                plantingMonths: [5, 6],
                harvestMonths: [8, 9],
                symbolName: "carrot.fill",
                colorHex: "#4E9A4E"
            ),
            PlantSpecies(
                commonName: "Cucumber",
                scientificName: "Cucumis sativus",
                category: .vegetable,
                sunRequirement: .fullSun,
                waterRequirement: .high,
                careNotes: "Give it a trellis to climb to keep fruit straight and reduce disease. Water consistently — irregular watering causes bitter fruit.",
                soilNotes: "Rich, well-drained soil high in organic matter.",
                spacingNotes: "30-45cm apart along a trellis.",
                plantingMonths: [5, 6],
                harvestMonths: [7, 8, 9],
                symbolName: "carrot.fill",
                colorHex: "#3E8A5C"
            ),
            PlantSpecies(
                commonName: "Strawberry",
                scientificName: "Fragaria × ananassa",
                category: .fruit,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Mulch with straw to keep fruit off the soil. Remove runners unless you want to propagate more plants.",
                soilNotes: "Rich, well-drained, slightly acidic soil.",
                spacingNotes: "30cm apart.",
                plantingMonths: [3, 4, 9],
                harvestMonths: [6, 7],
                symbolName: "applelogo",
                colorHex: "#C23C4C"
            )
        ]
    }

    private static var starterTasks: [MonthlyTaskTemplate] {
        [
            (1, "Plan the year's planting", "Review the wiki and order seeds for spring.", TaskCategory.other),
            (1, "Prune dormant fruit trees", "Prune apple, pear and cherry while they're fully dormant.", .pruning),
            (2, "Chit early potatoes", "Start seed potatoes indoors or in the greenhouse.", .planting),
            (2, "Service tools", "Sharpen and clean pruners, spades and shears before the season starts.", .cleanup),
            (3, "Start sowing hardy vegetables", "Carrots, peas and salad greens can go in once soil is workable.", .planting),
            (3, "Feed beds with compost", "Top-dress beds with compost before the main growing season.", .fertilizing),
            (4, "Sow tender vegetables under cover", "Start tomatoes, peppers and cucumbers in the greenhouse.", .greenhouse),
            (4, "Watch for slugs", "Protect new seedlings as slugs become active.", .pestControl),
            (5, "Harden off and transplant", "Move greenhouse seedlings outside gradually before planting out.", .planting),
            (5, "Mulch beds", "Mulch to retain moisture as the weather warms.", .other),
            (6, "Water consistently", "Increase watering frequency as temperatures rise, especially in the greenhouse.", .watering),
            (6, "Stake and support", "Tie in tomatoes, cucumbers and tall flowers as they grow.", .other),
            (7, "Harvest summer crops", "Pick regularly to keep plants productive.", .harvesting),
            (7, "Deadhead flowers", "Remove spent blooms to encourage more flowering.", .pruning),
            (8, "Keep up with watering", "Peak heat — check containers and the greenhouse daily.", .watering),
            (8, "Summer-prune trained fruit trees", "Prune trained apples and pears to control growth.", .pruning),
            (9, "Plant autumn/winter crops", "Sow overwintering vegetables and spring bulbs.", .planting),
            (9, "Harvest and store", "Bring in the last of the summer harvest before frosts.", .harvesting),
            (10, "Clear spent summer plants", "Compost finished crops and tidy beds.", .cleanup),
            (10, "Plant spring bulbs", "Tulips, daffodils and other spring bulbs go in now.", .planting),
            (11, "Protect tender plants", "Move frost-sensitive potted plants into the greenhouse.", .greenhouse),
            (11, "Bare-root planting", "Good month to plant bare-root trees and shrubs.", .planting),
            (12, "Insulate the greenhouse", "Add bubble insulation or a heater if frost is expected.", .greenhouse),
            (12, "Rest and review", "Reflect on what worked this year and update the wiki with notes.", .other)
        ].map { month, title, details, category in
            MonthlyTaskTemplate(month: month, title: title, details: details, category: category, isBuiltIn: true)
        }
    }
}
