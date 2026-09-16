import Foundation
import SwiftData

/// A "pallet" / raised bed / plot within a MapArea. Plants are placed
/// inside a bed as resizable zones (see PlacedPlant); trees are the one
/// exception and are placed directly on the open map instead. A bed is
/// either a rectangle (x/y/width/height, drag-move + corner-resize) or a
/// freeform triangle (3 independently draggable vertices) — chosen once at
/// creation and not switchable afterward, since converting between the two
/// isn't well-defined. See docs/decisions/0017-bed-shapes-and-plant-zones.md.
@Model
final class Bed: Identifiable {
    // Every stored attribute needs a default value at the declaration
    // (not just as an init parameter default) — CloudKit-backed SwiftData
    // sync requires every non-optional attribute to have one. See
    // docs/decisions/0008-cloudkit-fallback.md.
    var id: UUID = UUID()
    var name: String = ""
    var shapeRaw: String = BedShape.rectangle.rawValue

    // Rectangle geometry — authoritative when shape == .rectangle. Also
    // holds the bed's bounding box at creation time for a triangle bed,
    // but isn't kept in sync with its vertices afterward — use
    // `boundingBox` for a triangle bed's current extent.
    var x: Int = 0
    var y: Int = 0
    var width: Int = 1
    var height: Int = 1

    // Triangle geometry — authoritative when shape == .triangle.
    var vertex1X: Int = 0
    var vertex1Y: Int = 0
    var vertex2X: Int = 1
    var vertex2Y: Int = 0
    var vertex3X: Int = 0
    var vertex3Y: Int = 1

    var colorHex: String = "#8B5E3C"
    var mapArea: MapArea?

    // .nullify, not .cascade: deleting a bed should just detach the plants
    // inside it (they keep their map position and stay visible), not
    // delete them along with the bed.
    @Relationship(deleteRule: .nullify, inverse: \PlacedPlant.bed)
    var placedPlants: [PlacedPlant]? = []

    // .nullify, not .cascade: a GardenTask naming this bed is a freeform
    // to-do, not owned data about the bed — deleting the bed should just
    // detach the task, not delete it. CloudKit-backed SwiftData requires
    // every relationship to declare an inverse, so GardenTask.bed needs
    // this counterpart.
    @Relationship(deleteRule: .nullify, inverse: \GardenTask.bed)
    var gardenTasks: [GardenTask]? = []

    init(
        id: UUID = UUID(),
        name: String,
        shape: BedShape = .rectangle,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        vertices: [(x: Int, y: Int)]? = nil,
        colorHex: String = "#8B5E3C",
        mapArea: MapArea? = nil
    ) {
        self.id = id
        self.name = name
        self.shapeRaw = shape.rawValue
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        if let vertices, vertices.count == 3 {
            vertex1X = vertices[0].x
            vertex1Y = vertices[0].y
            vertex2X = vertices[1].x
            vertex2Y = vertices[1].y
            vertex3X = vertices[2].x
            vertex3Y = vertices[2].y
        } else {
            vertex1X = x
            vertex1Y = y + height
            vertex2X = x + width
            vertex2Y = y + height
            vertex3X = x + width / 2
            vertex3Y = y
        }
        self.colorHex = colorHex
        self.mapArea = mapArea
    }

    var shape: BedShape {
        get { BedShape(rawValue: shapeRaw) ?? .rectangle }
        set { shapeRaw = newValue.rawValue }
    }

    func vertex(at index: Int) -> (x: Int, y: Int) {
        switch index {
        case 0: return (vertex1X, vertex1Y)
        case 1: return (vertex2X, vertex2Y)
        default: return (vertex3X, vertex3Y)
        }
    }

    func setVertex(_ index: Int, x: Int, y: Int) {
        switch index {
        case 0: vertex1X = x; vertex1Y = y
        case 1: vertex2X = x; vertex2Y = y
        default: vertex3X = x; vertex3Y = y
        }
    }

    func translateVertices(dx: Int, dy: Int) {
        vertex1X += dx; vertex1Y += dy
        vertex2X += dx; vertex2Y += dy
        vertex3X += dx; vertex3Y += dy
    }

    /// The smallest axis-aligned box containing the bed, regardless of
    /// shape — used for scanning/clamping without needing to know the
    /// shape at every call site.
    var boundingBox: (x: Int, y: Int, width: Int, height: Int) {
        switch shape {
        case .rectangle:
            return (x, y, width, height)
        case .triangle:
            let xs = [vertex1X, vertex2X, vertex3X]
            let ys = [vertex1Y, vertex2Y, vertex3Y]
            let minX = xs.min() ?? 0, maxX = xs.max() ?? 0
            let minY = ys.min() ?? 0, maxY = ys.max() ?? 0
            return (minX, minY, max(1, maxX - minX), max(1, maxY - minY))
        }
    }

    func occupies(x: Int, y: Int) -> Bool {
        switch shape {
        case .rectangle:
            return x >= self.x && x < self.x + width && y >= self.y && y < self.y + height
        case .triangle:
            return Self.pointInTriangle(
                px: Double(x) + 0.5, py: Double(y) + 0.5,
                ax: Double(vertex1X), ay: Double(vertex1Y),
                bx: Double(vertex2X), by: Double(vertex2Y),
                cx: Double(vertex3X), cy: Double(vertex3Y)
            )
        }
    }

    private static func pointInTriangle(
        px: Double, py: Double,
        ax: Double, ay: Double,
        bx: Double, by: Double,
        cx: Double, cy: Double
    ) -> Bool {
        func sign(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ x3: Double, _ y3: Double) -> Double {
            (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3)
        }
        let d1 = sign(px, py, ax, ay, bx, by)
        let d2 = sign(px, py, bx, by, cx, cy)
        let d3 = sign(px, py, cx, cy, ax, ay)
        let hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0)
        let hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0)
        return !(hasNeg && hasPos)
    }
}
