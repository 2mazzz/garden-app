import SwiftUI

/// A draggable, resizable plant/tree footprint — the same direct-
/// manipulation pattern as BedView, applied to plants so a strawberry zone
/// inside a bed or a tree's canopy reads as a real area instead of a
/// fixed-size icon. See docs/decisions/0017-bed-shapes-and-plant-zones.md.
struct PlacedPlantView: View {
    let placedPlant: PlacedPlant
    let mapArea: MapArea
    var onTap: () -> Void

    /// Same fixed-opacity/border rationale as BedView — no GreenhouseTheme
    /// numeric-opacity token exists, so these replace the old theme's
    /// per-theme values with one reasonable constant.
    private let fillOpacity: Double = 0.55
    private let borderWidth: CGFloat = 1.5

    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false
    @State private var resizeTranslation: CGSize = .zero
    @State private var isResizing = false

    private var species: PlantSpecies? { placedPlant.species }
    private var colorHex: String { species?.colorHex ?? "#3A7D44" }

    private var committedWidth: CGFloat { CGFloat(placedPlant.width) * mapCellSize }
    private var committedHeight: CGFloat { CGFloat(placedPlant.height) * mapCellSize }

    private var liveWidth: CGFloat {
        guard isResizing else { return committedWidth }
        return max(mapCellSize, committedWidth + resizeTranslation.width)
    }

    private var liveHeight: CGFloat {
        guard isResizing else { return committedHeight }
        return max(mapCellSize, committedHeight + resizeTranslation.height)
    }

    private var liveLeadingX: CGFloat {
        CGFloat(placedPlant.x) * mapCellSize + (isDragging ? dragTranslation.width : 0)
    }

    private var liveLeadingY: CGFloat {
        CGFloat(placedPlant.y) * mapCellSize + (isDragging ? dragTranslation.height : 0)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(Color(hex: colorHex).opacity(fillOpacity))
                .overlay(
                    Circle()
                        .stroke(Color(hex: colorHex), lineWidth: (isDragging || isResizing) ? borderWidth + 1.5 : borderWidth)
                )
                .overlay {
                    VStack(spacing: 2) {
                        Image(systemName: species?.symbolName ?? "leaf.fill")
                            .foregroundStyle(Color(hex: colorHex))
                        if liveWidth > mapCellSize * 1.4 {
                            Text(species?.commonName ?? "Plant")
                                .font(GreenhouseTheme.Font.small())
                                .foregroundStyle(GreenhouseTheme.Color.metaText)
                                .lineLimit(1)
                        }
                    }
                }
                .opacity(placedPlant.status == .removed ? 0.3 : 1.0)
                .overlay(alignment: .topLeading) {
                    if placedPlant.status == .harvested {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                            .padding(3)
                    }
                }

            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(5)
                .background(Color(hex: colorHex))
                .clipShape(Circle())
                .offset(x: 8, y: 8)
                .gesture(resizeGesture)
        }
        .frame(width: liveWidth, height: liveHeight)
        .position(x: liveLeadingX + liveWidth / 2, y: liveLeadingY + liveHeight / 2)
        .gesture(moveOrTapGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(species?.commonName ?? "Plant")
        .accessibilityAddTraits(.isButton)
    }

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
                placedPlant.x = clamp(placedPlant.x + deltaX, 0, max(0, mapArea.columns - placedPlant.width))
                placedPlant.y = clamp(placedPlant.y + deltaY, 0, max(0, mapArea.rows - placedPlant.height))
                dragTranslation = .zero
            }
    }

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
                placedPlant.width = clamp(placedPlant.width + deltaW, 1, max(1, mapArea.columns - placedPlant.x))
                placedPlant.height = clamp(placedPlant.height + deltaH, 1, max(1, mapArea.rows - placedPlant.y))
                resizeTranslation = .zero
            }
    }

    private func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
