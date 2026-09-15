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

    @Environment(\.gardenTheme) private var theme

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
            RoundedRectangle(cornerRadius: theme.bedCornerRadius)
                .fill(Color(hex: bed.colorHex).opacity(theme.bedFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.bedCornerRadius)
                        .stroke(Color(hex: bed.colorHex), lineWidth: (isDragging || isResizing) ? theme.bedBorderWidth + 1.5 : theme.bedBorderWidth)
                )
                .overlay(alignment: .topLeading) {
                    Text(bed.name)
                        .font(theme.labelFont)
                        .padding(3)
                        .foregroundStyle(.secondary)
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

    private var canvasWidth: CGFloat { CGFloat(mapArea.columns) * mapCellSize }
    private var canvasHeight: CGFloat { CGFloat(mapArea.rows) * mapCellSize }

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

    private var trianglePath: Path {
        var path = Path()
        let points = (0..<3).map { liveVertexPoint($0) }
        path.move(to: points[0])
        path.addLine(to: points[1])
        path.addLine(to: points[2])
        path.closeSubpath()
        return path
    }

    private var triangleCentroid: CGPoint {
        let points = (0..<3).map { liveVertexPoint($0) }
        return CGPoint(x: points.reduce(0) { $0 + $1.x } / 3, y: points.reduce(0) { $0 + $1.y } / 3)
    }

    private var triangleBody: some View {
        ZStack(alignment: .topLeading) {
            trianglePath
                .fill(Color(hex: bed.colorHex).opacity(theme.bedFillOpacity))
            trianglePath
                .stroke(
                    Color(hex: bed.colorHex),
                    lineWidth: (isDraggingBody || draggingVertexIndex != nil) ? theme.bedBorderWidth + 1.5 : theme.bedBorderWidth
                )
            Text(bed.name)
                .font(theme.labelFont)
                .foregroundStyle(.secondary)
                .position(triangleCentroid)

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(hex: bed.colorHex))
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .frame(width: 14, height: 14)
                    .position(liveVertexPoint(index))
                    .gesture(vertexDragGesture(index))
            }
        }
        .contentShape(trianglePath)
        .gesture(moveTriangleGesture)
        .frame(width: canvasWidth, height: canvasHeight, alignment: .topLeading)
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
