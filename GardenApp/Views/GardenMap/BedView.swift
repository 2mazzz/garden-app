import SwiftUI

/// A draggable, resizable bed. Rectangle beds: dragging the body moves the
/// bed (snapped to the grid); dragging the corner handle resizes it.
/// Triangle beds: dragging the body moves all 3 vertices together;
/// dragging any vertex dot reshapes it independently. Either way, a tap
/// with negligible movement opens the compact edit menu instead of
/// committing a move — see docs/decisions/0010-direct-manipulation-beds.md
/// and docs/decisions/0017-bed-shapes-and-plant-zones.md.
struct BedView: View {
    let bed: Bed
    let mapArea: MapArea
    var onTap: () -> Void

    /// Flat fill opacity applied over the bed's own user-chosen `colorHex` —
    /// not a GreenhouseTheme token (the design system has no numeric-opacity
    /// scale), just a fixed reasonable value replacing the old theme's
    /// per-theme opacity.
    private let fillOpacity: Double = 0.35
    private let borderWidth: CGFloat = 1.5

    // Rectangle drag/resize state.
    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false
    @State private var resizeTranslation: CGSize = .zero
    @State private var isResizing = false

    // Triangle drag/reshape state.
    @State private var isDraggingBody = false
    @State private var bodyDragTranslation: CGSize = .zero
    @State private var draggingVertexIndex: Int?
    @State private var vertexDragTranslation: CGSize = .zero

    var body: some View {
        switch bed.shape {
        case .rectangle:
            rectangleBody
        case .triangle:
            triangleBody
        }
    }

    // MARK: - Rectangle

    private var committedWidth: CGFloat { CGFloat(bed.width) * mapCellSize }
    private var committedHeight: CGFloat { CGFloat(bed.height) * mapCellSize }

    private var liveWidth: CGFloat {
        guard isResizing else { return committedWidth }
        return max(mapCellSize, committedWidth + resizeTranslation.width)
    }

    private var liveHeight: CGFloat {
        guard isResizing else { return committedHeight }
        return max(mapCellSize, committedHeight + resizeTranslation.height)
    }

    /// Top-left corner in pixels — stays anchored while resizing, moves
    /// live while dragging.
    private var liveLeadingX: CGFloat {
        CGFloat(bed.x) * mapCellSize + (isDragging ? dragTranslation.width : 0)
    }

    private var liveLeadingY: CGFloat {
        CGFloat(bed.y) * mapCellSize + (isDragging ? dragTranslation.height : 0)
    }

    private var rectangleBody: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card)
                .fill(Color(hex: bed.colorHex).opacity(fillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card)
                        .stroke(Color(hex: bed.colorHex), lineWidth: (isDragging || isResizing) ? borderWidth + 1.5 : borderWidth)
                )
                .overlay(alignment: .topLeading) {
                    Text(bed.name)
                        .font(GreenhouseTheme.Font.small())
                        .padding(3)
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                }

            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(5)
                .background(Color(hex: bed.colorHex))
                .clipShape(Circle())
                .offset(x: 8, y: 8)
                .gesture(resizeGesture)
        }
        .frame(width: liveWidth, height: liveHeight)
        .position(x: liveLeadingX + liveWidth / 2, y: liveLeadingY + liveHeight / 2)
        .gesture(moveOrTapGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bed.name)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to edit. Use the app's drag gestures to move or resize.")
    }

    /// A single DragGesture with minimumDistance 0 disambiguates tap vs.
    /// drag by the final displacement — this avoids fighting SwiftUI over
    /// two competing gesture recognizers on the same view.
    private var moveOrTapGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                dragTranslation = value.translation
            }
            .onEnded { value in
                isDragging = false
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance >= 6 else {
                    dragTranslation = .zero
                    onTap()
                    return
                }
                let deltaX = Int((value.translation.width / mapCellSize).rounded())
                let deltaY = Int((value.translation.height / mapCellSize).rounded())
                bed.x = clamp(bed.x + deltaX, 0, max(0, mapArea.columns - bed.width))
                bed.y = clamp(bed.y + deltaY, 0, max(0, mapArea.rows - bed.height))
                dragTranslation = .zero
            }
    }

    /// Measured in the map's named coordinate space (declared on
    /// GardenMapView's content ZStack), not the handle's own local space.
    /// The handle sits inside a frame sized to liveWidth/liveHeight, which
    /// changes every time this gesture updates — tracking translation
    /// against that constantly-resizing local frame is a feedback loop
    /// (the frame moves under the finger as a side effect of the drag
    /// itself) that showed up as bad flickering on diagonal resizes.
    /// Anchoring to a stable named ancestor space fixes it.
    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(mapCanvasCoordinateSpace))
            .onChanged { value in
                isResizing = true
                resizeTranslation = value.translation
            }
            .onEnded { value in
                isResizing = false
                let deltaW = Int((value.translation.width / mapCellSize).rounded())
                let deltaH = Int((value.translation.height / mapCellSize).rounded())
                bed.width = clamp(bed.width + deltaW, 1, max(1, mapArea.columns - bed.x))
                bed.height = clamp(bed.height + deltaH, 1, max(1, mapArea.rows - bed.y))
                resizeTranslation = .zero
            }
    }

    // MARK: - Triangle

    /// Corner rounding radius for the triangle's fill/stroke/hit-test path —
    /// matches the rectangle bed's RoundedRectangle radius for visual
    /// consistency.
    private let triangleCornerRadius: CGFloat = GreenhouseTheme.Radius.card

    /// Absolute position (in the map canvas's own coordinate space) of one
    /// vertex, including any in-flight drag translation.
    private func liveVertexPoint(_ index: Int) -> CGPoint {
        let v = bed.vertex(at: index)
        var point = CGPoint(x: CGFloat(v.x) * mapCellSize, y: CGFloat(v.y) * mapCellSize)
        if isDraggingBody {
            point.x += bodyDragTranslation.width
            point.y += bodyDragTranslation.height
        }
        if draggingVertexIndex == index {
            point.x += vertexDragTranslation.width
            point.y += vertexDragTranslation.height
        }
        return point
    }

    /// Bounding box of the live vertices, in the map canvas's coordinate
    /// space. Unlike the rectangle case, this view previously sized itself
    /// to the *entire map canvas* (so its Path could use absolute
    /// coordinates) — every triangle bed's hit-testable frame silently
    /// overlapped the whole map, making it hard to tap/drag anything nearby
    /// precisely. Sizing tightly to this box, like the rectangle bed does,
    /// fixes that.
    private var triangleBoundingBox: (origin: CGPoint, size: CGSize) {
        let points = (0..<3).map { liveVertexPoint($0) }
        let minX = points.map(\.x).min() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let maxY = points.map(\.y).max() ?? 0
        return (
            CGPoint(x: minX, y: minY),
            CGSize(width: max(mapCellSize, maxX - minX), height: max(mapCellSize, maxY - minY))
        )
    }

    /// Every triangle vertex sits exactly on its own bounding box's edge
    /// (that's what "bounding box" means) — so with zero margin, each
    /// vertex's enlarged hit circle (see below) would be flush against this
    /// view's own frame boundary, right where SwiftUI's hit-testing is
    /// least reliable for a child positioned via `.position()`. This margin
    /// keeps every vertex, and its hit circle, safely inside the frame.
    private var trianglePadding: CGFloat { 20 }

    private var triangleBody: some View {
        let box = triangleBoundingBox
        // Vertex points relative to `box.origin`, inset by `trianglePadding`
        // — this view's own frame (below) is sized/positioned to the
        // bounding box plus that padding, not the whole canvas.
        let localPoints = (0..<3).map { index -> CGPoint in
            let p = liveVertexPoint(index)
            return CGPoint(x: p.x - box.origin.x + trianglePadding, y: p.y - box.origin.y + trianglePadding)
        }
        let path = roundedPolygonPath(points: localPoints, radius: triangleCornerRadius)
        let centroid = CGPoint(
            x: localPoints.reduce(0) { $0 + $1.x } / 3,
            y: localPoints.reduce(0) { $0 + $1.y } / 3
        )

        return ZStack(alignment: .topLeading) {
            path
                .fill(Color(hex: bed.colorHex).opacity(fillOpacity))
            path
                .stroke(
                    Color(hex: bed.colorHex),
                    lineWidth: (isDraggingBody || draggingVertexIndex != nil) ? borderWidth + 1.5 : borderWidth
                )
            Text(bed.name)
                .font(GreenhouseTheme.Font.small())
                .foregroundStyle(GreenhouseTheme.Color.metaText)
                .position(centroid)

            ForEach(0..<3, id: \.self) { index in
                let neighborA = localPoints[(index + 1) % 3]
                let neighborB = localPoints[(index + 2) % 3]
                let shorterAdjacentEdge = min(
                    localPoints[index].distance(to: neighborA),
                    localPoints[index].distance(to: neighborB)
                )
                // Visual dot stays 14pt, but the draggable area is enlarged
                // past it — a bare 14pt target is far below the ~44pt a
                // finger can reliably hit, which was part of why reshaping
                // felt hard to grab. Capped at a fraction of the shorter
                // adjacent edge so on the small default triangle (2x2
                // cells) the 3 enlarged corners don't swallow the entire
                // shape and leave no room to grab the body to move it.
                let hitRadius = min(20, shorterAdjacentEdge * 0.22)
                Circle()
                    .fill(Color(hex: bed.colorHex))
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .frame(width: 14, height: 14)
                    .contentShape(Circle().inset(by: 7 - hitRadius))
                    .position(localPoints[index])
                    .gesture(vertexDragGesture(index))
            }
        }
        .contentShape(path)
        .gesture(moveTriangleGesture)
        .frame(width: box.size.width + trianglePadding * 2, height: box.size.height + trianglePadding * 2, alignment: .topLeading)
        .position(x: box.origin.x + box.size.width / 2, y: box.origin.y + box.size.height / 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bed.name)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to edit. Drag inside to move, drag a corner dot to reshape.")
    }

    /// Moves all 3 vertices together, clamped so the bounding box stays on
    /// the map — same tap/drag disambiguation as the rectangle case.
    private var moveTriangleGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDraggingBody = true
                bodyDragTranslation = value.translation
            }
            .onEnded { value in
                isDraggingBody = false
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance >= 6 else {
                    bodyDragTranslation = .zero
                    onTap()
                    return
                }
                var deltaX = Int((value.translation.width / mapCellSize).rounded())
                var deltaY = Int((value.translation.height / mapCellSize).rounded())
                let box = bed.boundingBox
                deltaX = clamp(deltaX, -box.x, max(0, mapArea.columns - box.x - box.width))
                deltaY = clamp(deltaY, -box.y, max(0, mapArea.rows - box.y - box.height))
                bed.translateVertices(dx: deltaX, dy: deltaY)
                bodyDragTranslation = .zero
            }
    }

    /// Reshapes the triangle by moving a single vertex independently —
    /// same named-coordinate-space rationale as the rectangle resize handle.
    private func vertexDragGesture(_ index: Int) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(mapCanvasCoordinateSpace))
            .onChanged { value in
                draggingVertexIndex = index
                vertexDragTranslation = value.translation
            }
            .onEnded { value in
                draggingVertexIndex = nil
                let deltaX = Int((value.translation.width / mapCellSize).rounded())
                let deltaY = Int((value.translation.height / mapCellSize).rounded())
                let current = bed.vertex(at: index)
                let newX = clamp(current.x + deltaX, 0, max(0, mapArea.columns - 1))
                let newY = clamp(current.y + deltaY, 0, max(0, mapArea.rows - 1))
                bed.setVertex(index, x: newX, y: newY)
                vertexDragTranslation = .zero
            }
    }

    private func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}

/// Builds a closed Path visiting `points` in order with each corner rounded
/// to `radius` — a quadratic curve from a point `radius` back along the
/// incoming edge to a point `radius` along the outgoing edge, using the
/// original vertex as the curve's control point. Each corner's radius is
/// clamped to half its shorter adjacent edge so thin/small triangles don't
/// produce overlapping or self-intersecting curves.
private func roundedPolygonPath(points: [CGPoint], radius: CGFloat) -> Path {
    var path = Path()
    let count = points.count
    guard count >= 3 else { return path }

    for i in 0..<count {
        let prev = points[(i - 1 + count) % count]
        let curr = points[i]
        let next = points[(i + 1) % count]

        let r = min(radius, curr.distance(to: prev) / 2, curr.distance(to: next) / 2)
        let startPoint = curr.interpolated(towards: prev, distance: r)
        let endPoint = curr.interpolated(towards: next, distance: r)

        if i == 0 {
            path.move(to: startPoint)
        } else {
            path.addLine(to: startPoint)
        }
        path.addQuadCurve(to: endPoint, control: curr)
    }
    path.closeSubpath()
    return path
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(other.x - x, other.y - y)
    }

    func interpolated(towards other: CGPoint, distance: CGFloat) -> CGPoint {
        let length = self.distance(to: other)
        guard length > 0 else { return self }
        let t = distance / length
        return CGPoint(x: x + (other.x - x) * t, y: y + (other.y - y) * t)
    }
}
