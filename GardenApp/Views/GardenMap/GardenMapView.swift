import SwiftUI
import SwiftData

let mapCellSize: CGFloat = 32

/// Named coordinate space for the map's content ZStack (declared below the
/// zoom `.scaleEffect`, above any individual bed/structure). Resize
/// gestures measure against this stable space rather than their own local
/// one — see the comment on `BedView.resizeGesture` for why.
let mapCanvasCoordinateSpace = "mapCanvas"

/// Each grid cell represents about 0.5 meters — see
/// docs/decisions/0012-garden-scale-and-zoom.md.
let metersPerCell: Double = 0.5

/// Renders one MapArea (the outdoor garden, or an area entered by tapping a
/// structure like the greenhouse) as a grid canvas. Beds are drawn as
/// colored rectangles, structures (e.g. the greenhouse, a house, a
/// driveway) as draggable/resizable rectangles you can optionally enter,
/// and plants/trees as icons on top.
///
/// Expects to be hosted inside a NavigationStack owned by the caller (see
/// RootTabView) rather than providing its own, so that entering a linked
/// structure (garden -> greenhouse) is a normal push, not a new stack.
struct GardenMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var mapArea: MapArea

    @State private var isAddingPlant = false
    @State private var isAddingStructure = false
    @State private var prefilledPoint: GridPoint?
    @State private var selectedPlacedPlant: PlacedPlant?
    @State private var selectedBed: Bed?
    @State private var selectedStructure: Structure?
    @State private var structureNavigationTarget: MapArea?

    @State private var committedZoom: CGFloat = 1.0
    @State private var liveZoom: CGFloat = 1.0

    private var beds: [Bed] { mapArea.beds ?? [] }
    private var placedPlants: [PlacedPlant] { mapArea.placedPlants ?? [] }
    private var structures: [Structure] { mapArea.structures ?? [] }

    /// Active (non-removed) plants currently placed on this map, for the
    /// header subtitle.
    private var activePlantCount: Int {
        placedPlants.filter { $0.status != .removed }.count
    }

    /// "Areas" = distinct beds/structures laid out on this map — the plots
    /// someone could tap into, not a count of plants.
    private var areaCount: Int {
        beds.count + structures.count
    }

    private var headerSubtitle: String {
        let plantWord = activePlantCount == 1 ? "plant" : "plants"
        let areaWord = areaCount == 1 ? "area" : "areas"
        return "\(activePlantCount) \(plantWord) across \(areaCount) \(areaWord)"
    }

    private var zoomScale: CGFloat { committedZoom * liveZoom }
    private var unscaledWidth: CGFloat { CGFloat(mapArea.columns) * mapCellSize }
    private var unscaledHeight: CGFloat { CGFloat(mapArea.rows) * mapCellSize }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    gridBackground

                    ForEach(beds) { bed in
                        BedView(bed: bed, mapArea: mapArea) { selectedBed = bed }
                    }

                    ForEach(structures) { structure in
                        StructureView(structure: structure, mapArea: mapArea) {
                            if let linked = structure.linkedMapArea {
                                structureNavigationTarget = linked
                            } else {
                                selectedStructure = structure
                            }
                        } onEdit: {
                            selectedStructure = structure
                        }
                    }

                    ForEach(placedPlants) { plant in
                        PlacedPlantView(placedPlant: plant, mapArea: mapArea) { selectedPlacedPlant = plant }
                    }
                }
                .frame(width: unscaledWidth, height: unscaledHeight)
                .coordinateSpace(name: mapCanvasCoordinateSpace)
                .scaleEffect(zoomScale, anchor: .topLeading)
                .frame(width: unscaledWidth * zoomScale, height: unscaledHeight * zoomScale, alignment: .topLeading)
                .padding()
            }
            .defaultScrollAnchor(.center)
            .background(GreenhouseTheme.Color.plotMapGround)
            .gesture(magnificationGesture)
            .overlay(alignment: .bottomLeading) { scaleLegend }
        }
        .background(GreenhouseTheme.Color.paper)
        // Kept (not cleared) rather than replaced by the custom header
        // below: existing UI tests and the toolbar/back-button wiring
        // locate this screen by `app.navigationBars["Garden"]` /
        // `["Greenhouse"]` (keyed off this exact title), so this can't be
        // blanked out. In inline display mode (the default — no
        // `.navigationBarTitleDisplayMode(.large)` here) it's a small
        // compact bar, so it doesn't visually duplicate the large custom
        // header beneath it.
        .navigationTitle(mapArea.name)
        .navigationDestination(item: $structureNavigationTarget) { area in
            GardenMapView(mapArea: area)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button("Rectangle") { addBed(shape: .rectangle) }
                    Button("Triangle") { addBed(shape: .triangle) }
                } label: {
                    Label("Add Bed", systemImage: "square.dashed")
                }
                Button {
                    isAddingStructure = true
                } label: {
                    Label("Add Structure", systemImage: "house.fill")
                }
                Button {
                    prefilledPoint = nil
                    isAddingPlant = true
                } label: {
                    Label("Add Plant", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingPlant) {
            AddPlantSheet(mapArea: mapArea, defaultPoint: prefilledPoint)
        }
        .sheet(isPresented: $isAddingStructure) {
            AddStructureSheet(mapArea: mapArea)
        }
        .sheet(item: $selectedPlacedPlant) { plant in
            PlacedPlantDetailSheet(placedPlant: plant)
        }
        .sheet(item: $selectedBed) { bed in
            BedDetailSheet(bed: bed, mapArea: mapArea)
        }
        .sheet(item: $selectedStructure) { structure in
            StructureDetailSheet(structure: structure, mapArea: mapArea)
        }
    }

    /// No popup — a new bed is created immediately with sensible defaults
    /// near the center of the map (where the view is already scrolled to,
    /// not off in a far corner of the large grid — see
    /// docs/decisions/0014-endless-grid.md). Rename, recolor, resize (drag
    /// the corner handle, or for a triangle, any of its 3 corner dots), or
    /// reposition (drag the bed) after. Shape is fixed at creation — see
    /// docs/decisions/0017-bed-shapes-and-plant-zones.md.
    private func addBed(shape: BedShape) {
        let width = min(2, mapArea.columns)
        let height = min(2, mapArea.rows)
        let origin = centeredOrigin(width: width, height: height)
        let bed = Bed(
            name: "New bed",
            shape: shape,
            x: origin.x,
            y: origin.y,
            width: width,
            height: height,
            mapArea: mapArea
        )
        modelContext.insert(bed)
        // Explicit save, not just insert() — see ADR 0020.
        try? modelContext.save()
    }

    /// A top-left origin for a new width x height item so it lands near
    /// the middle of the map instead of grid (0,0), which — now that the
    /// grid is large and the seeded layout sits centered within it — is
    /// usually off-screen.
    private func centeredOrigin(width: Int, height: Int) -> (x: Int, y: Int) {
        let x = max(0, min(mapArea.columns - width, mapArea.columns / 2 - width / 2))
        let y = max(0, min(mapArea.rows - height, mapArea.rows / 2 - height / 2))
        return (x, y)
    }

    /// Tapping empty space on the map is a shortcut to placing a plant
    /// there. This is a single gesture on the background grid rather than
    /// one invisible view per empty cell — with a grid that can now run to
    /// hundreds of cells per side (see docs/decisions/0014-endless-grid.md),
    /// per-cell views stopped scaling. Beds/structures/plants sit above the
    /// background and have their own gestures, so a tap only reaches this
    /// one when it lands on genuinely empty space.
    ///
    /// This must be a real tap gesture (SpatialTapGesture), not a
    /// DragGesture(minimumDistance: 0) — a drag gesture claims the touch
    /// the instant a finger goes down, before the ScrollView's own pan
    /// gesture can recognize a scroll, so panning the map broke entirely
    /// (every drag was read as "add a plant at wherever you lifted your
    /// finger"). A tap gesture only fires on a genuine tap and lets any
    /// real drag fall through to the ScrollView to pan as normal.
    private var backgroundTapGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let col = Int(value.location.x / mapCellSize)
                let row = Int(value.location.y / mapCellSize)
                guard col >= 0, col < mapArea.columns, row >= 0, row < mapArea.rows else { return }
                prefilledPoint = GridPoint(x: col, y: row)
                isAddingPlant = true
            }
    }

    /// Pinch to zoom in/out on the canvas. The committed/live split mirrors
    /// BedView's drag pattern: liveZoom is the in-progress pinch delta,
    /// folded into committedZoom once the gesture ends.
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                liveZoom = value
            }
            .onEnded { value in
                committedZoom = min(max(committedZoom * value, 0.5), 3.0)
                liveZoom = 1.0
            }
    }

    /// Fixed (non-scrolling) header above the pannable/zoomable map canvas —
    /// reused for both the outdoor Garden and, via the same view, a
    /// Structure's linked MapArea (e.g. the Greenhouse), so it reads
    /// `mapArea.name` rather than hardcoding either context's copy.
    private var header: some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
            Text(mapArea.name)
                .font(GreenhouseTheme.Font.screenTitle())
                .foregroundStyle(GreenhouseTheme.Color.ink)
            Text(headerSubtitle)
                .font(GreenhouseTheme.Font.small())
                .foregroundStyle(GreenhouseTheme.Color.metaText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, GreenhouseTheme.Spacing.screenPadding)
        .padding(.top, GreenhouseTheme.Spacing.sm)
        .padding(.bottom, GreenhouseTheme.Spacing.xs)
        .background(GreenhouseTheme.Color.paper)
    }

    private var gridBackground: some View {
        Canvas { context, _ in
            let cols = mapArea.columns
            let rows = mapArea.rows
            var path = Path()
            for c in 0...cols {
                let x = CGFloat(c) * mapCellSize
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: CGFloat(rows) * mapCellSize))
            }
            for r in 0...rows {
                let y = CGFloat(r) * mapCellSize
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: CGFloat(cols) * mapCellSize, y: y))
            }
            context.stroke(
                path,
                with: .color(GreenhouseTheme.Color.line),
                style: StrokeStyle(lineWidth: 1)
            )
        }
        .frame(width: unscaledWidth, height: unscaledHeight)
        .contentShape(Rectangle())
        .gesture(backgroundTapGesture)
    }

    /// A fixed (non-zooming) reminder of what one grid cell represents,
    /// pinned to the corner of the scroll view rather than the scaled
    /// content, so it stays legible at any zoom level.
    private var scaleLegend: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(GreenhouseTheme.Color.green)
                .frame(width: 16, height: 4)
            Text("= \(metersPerCell, specifier: "%.1f") m")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
        .padding(8)
    }
}

struct GridPoint: Hashable {
    let x: Int
    let y: Int
}
