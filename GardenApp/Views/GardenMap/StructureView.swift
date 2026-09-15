import SwiftUI

/// A draggable, resizable structure rectangle — the same direct-manipulation
/// pattern as BedView (see docs/decisions/0010-direct-manipulation-beds.md
/// and 0011-structure-direct-manipulation.md). Tapping a structure with a
/// linked map area (e.g. the greenhouse) navigates into it; tapping one with
/// no link (e.g. a house or driveway) opens its edit sheet instead. The
/// pencil button always opens the edit sheet, so a linked structure like the
/// greenhouse can still be renamed, recolored, or deleted.
struct StructureView: View {
    let structure: Structure
    let mapArea: MapArea
    var onTap: () -> Void
    var onEdit: () -> Void

    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false
    @State private var resizeTranslation: CGSize = .zero
    @State private var isResizing = false

    private var committedWidth: CGFloat { CGFloat(structure.width) * mapCellSize }
    private var committedHeight: CGFloat { CGFloat(structure.height) * mapCellSize }

    private var liveWidth: CGFloat {
        guard isResizing else { return committedWidth }
        return max(mapCellSize, committedWidth + resizeTranslation.width)
    }

    private var liveHeight: CGFloat {
        guard isResizing else { return committedHeight }
        return max(mapCellSize, committedHeight + resizeTranslation.height)
    }

    private var liveLeadingX: CGFloat {
        CGFloat(structure.x) * mapCellSize + (isDragging ? dragTranslation.width : 0)
    }

    private var liveLeadingY: CGFloat {
        CGFloat(structure.y) * mapCellSize + (isDragging ? dragTranslation.height : 0)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: structure.colorHex).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: structure.colorHex), lineWidth: (isDragging || isResizing) ? 3 : 2)
                )
                .overlay {
                    VStack(spacing: 2) {
                        Image(systemName: structure.symbolName)
                            .font(.title3)
                            .accessibilityHidden(true)
                        Text(structure.name)
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.primary)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 16))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color(hex: structure.colorHex))
                        .padding(4)
                        .contentShape(Circle())
                        .onTapGesture { onEdit() }
                }

            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(5)
                .background(Color(hex: structure.colorHex))
                .clipShape(Circle())
                .offset(x: 8, y: 8)
                .gesture(resizeGesture)
        }
        .frame(width: liveWidth, height: liveHeight)
        .position(x: liveLeadingX + liveWidth / 2, y: liveLeadingY + liveHeight / 2)
        .gesture(moveOrTapGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(structure.name)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(structure.linkedMapArea != nil ? "Double tap to enter." : "Double tap to edit.")
    }

    /// Same tap/drag disambiguation as BedView's moveOrTapGesture.
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
                structure.x = clamp(structure.x + deltaX, 0, max(0, mapArea.columns - structure.width))
                structure.y = clamp(structure.y + deltaY, 0, max(0, mapArea.rows - structure.height))
                dragTranslation = .zero
            }
    }

    /// Named coordinate space, not local — see BedView.resizeGesture for
    /// why (the handle's local frame resizes live during this very
    /// gesture, which causes bad flicker on diagonal drags if translation
    /// is tracked against it instead of a stable ancestor space).
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
                structure.width = clamp(structure.width + deltaW, 1, max(1, mapArea.columns - structure.x))
                structure.height = clamp(structure.height + deltaH, 1, max(1, mapArea.rows - structure.y))
                resizeTranslation = .zero
            }
    }

    private func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
