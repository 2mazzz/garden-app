import Foundation
import SwiftData

/// The garden grid used to be small and fixed (10x14 outdoor, 6x8
/// greenhouse) so it fit on one screen. It's now a large, mostly-empty
/// canvas you scroll around in every direction, with the original layout
/// centered inside it — see docs/decisions/0014-endless-grid.md.
enum GardenGridDefaults {
    static let size = 100

    static let legacyOutdoorColumns = 10
    static let legacyOutdoorRows = 14
    static let legacyGreenhouseColumns = 6
    static let legacyGreenhouseRows = 8

    static var outdoorOffsetX: Int { (size - legacyOutdoorColumns) / 2 }
    static var outdoorOffsetY: Int { (size - legacyOutdoorRows) / 2 }
    static var greenhouseOffsetX: Int { (size - legacyGreenhouseColumns) / 2 }
    static var greenhouseOffsetY: Int { (size - legacyGreenhouseRows) / 2 }
}

enum GridSizeMigration {
    /// Enlarges any MapArea still sitting at its old small default size to
    /// the new large canvas, shifting its beds/structures/plants by the
    /// same offset so the existing layout ends up centered rather than
    /// jumping to the top-left corner. MapAreas the user has already
    /// resized (via Settings) no longer match the legacy dimensions, so
    /// they're left alone — this only touches never-resized installs.
    static func migrateIfNeeded(in context: ModelContext) {
        migrate(
            kind: .outdoor,
            legacyColumns: GardenGridDefaults.legacyOutdoorColumns,
            legacyRows: GardenGridDefaults.legacyOutdoorRows,
            offsetX: GardenGridDefaults.outdoorOffsetX,
            offsetY: GardenGridDefaults.outdoorOffsetY,
            in: context
        )
        migrate(
            kind: .greenhouse,
            legacyColumns: GardenGridDefaults.legacyGreenhouseColumns,
            legacyRows: GardenGridDefaults.legacyGreenhouseRows,
            offsetX: GardenGridDefaults.greenhouseOffsetX,
            offsetY: GardenGridDefaults.greenhouseOffsetY,
            in: context
        )
    }

    private static func migrate(
        kind: MapAreaKind,
        legacyColumns: Int,
        legacyRows: Int,
        offsetX: Int,
        offsetY: Int,
        in context: ModelContext
    ) {
        let rawValue = kind.rawValue
        let descriptor = FetchDescriptor<MapArea>(predicate: #Predicate { $0.kindRaw == rawValue })
        guard let areas = try? context.fetch(descriptor) else { return }

        for area in areas where area.columns == legacyColumns && area.rows == legacyRows {
            for bed in area.beds ?? [] {
                if bed.shape == .triangle {
                    bed.translateVertices(dx: offsetX, dy: offsetY)
                } else {
                    bed.x += offsetX
                    bed.y += offsetY
                }
            }
            for structure in area.structures ?? [] {
                structure.x += offsetX
                structure.y += offsetY
            }
            for plant in area.placedPlants ?? [] {
                plant.x += offsetX
                plant.y += offsetY
            }
            area.columns = GardenGridDefaults.size
            area.rows = GardenGridDefaults.size
        }
    }
}
