import SwiftUI

/// A draggable, resizable bed rectangle. Dragging the body moves the bed
/// (snapped to the grid); dragging the corner handle resizes it. A tap
/// with negligible movement opens the compact edit menu instead of
/// committing a move — see docs/decisions/0010-direct-manipulation-beds.md.
struct BedView: View {
    let bed: Bed
    let mapArea: MapArea
    var onTap: () -> Void

    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false
    @State private var resizeTranslation: CGSize = .zero
    @State private var isResizing = false

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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: bed.colorHex).opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: bed.colorHex), lineWidth: (isDragging || isResizing) ? 3 : 1.5)
                )
                .overlay(alignment: .topLeading) {
                    Text(bed.name)
                        .font(.caption2)
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

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 2)
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

    private func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
