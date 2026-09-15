import SwiftUI
import SwiftData

let mapCellSize: CGFloat = 32

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

    private var beds: [Bed] { mapArea.beds ?? [] }
    private var placedPlants: [PlacedPlant] { mapArea.placedPlants ?? [] }
    private var structures: [Structure] { mapArea.structures ?? [] }

    var body: some View {
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

                emptyCellTapTargets

                ForEach(placedPlants) { plant in
                    PlacedPlantView(placedPlant: plant)
                        .frame(width: mapCellSize, height: mapCellSize)
                        .position(
                            x: (CGFloat(plant.x) + 0.5) * mapCellSize,
                            y: (CGFloat(plant.y) + 0.5) * mapCellSize
                        )
                        .onTapGesture { selectedPlacedPlant = plant }
                }
            }
            .frame(
                width: CGFloat(mapArea.columns) * mapCellSize,
                height: CGFloat(mapArea.rows) * mapCellSize
            )
            .padding()
        }
        .navigationTitle(mapArea.name)
        .navigationDestination(item: $structureNavigationTarget) { area in
            GardenMapView(mapArea: area)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    addBed()
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
    /// at the top-left of the map. Rename, recolor, resize (drag the
    /// corner handle), reposition (drag the bed), or delete it afterward.
    private func addBed() {
        let bed = Bed(
            name: "New bed",
            x: 0,
            y: 0,
            width: min(2, mapArea.columns),
            height: min(2, mapArea.rows),
            mapArea: mapArea
        )
        modelContext.insert(bed)
    }

    /// Invisible tap targets over every empty, unoccupied cell, so tapping
    /// open space on the map is a shortcut to placing a plant there. Cells
    /// under a structure or a bed are excluded — a bed's own drag gestures
    /// need the whole rectangle free to move/resize it, and planting into a
    /// bed goes through its "Add a plant to this bed" menu action instead.
    private var emptyCellTapTargets: some View {
        ForEach(0..<mapArea.rows, id: \.self) { row in
            ForEach(0..<mapArea.columns, id: \.self) { col in
                if placedPlant(atX: col, y: row) == nil && !isBlockedForDirectPlacement(x: col, y: row) {
                    Color.clear
                        .frame(width: mapCellSize, height: mapCellSize)
                        .contentShape(Rectangle())
                        .position(
                            x: (CGFloat(col) + 0.5) * mapCellSize,
                            y: (CGFloat(row) + 0.5) * mapCellSize
                        )
                        .onTapGesture {
                            prefilledPoint = GridPoint(x: col, y: row)
                            isAddingPlant = true
                        }
                }
            }
        }
    }

    private func placedPlant(atX x: Int, y: Int) -> PlacedPlant? {
        placedPlants.first { $0.x == x && $0.y == y }
    }

    private func isBlockedForDirectPlacement(x: Int, y: Int) -> Bool {
        structures.contains { $0.occupies(x: x, y: y) } || beds.contains { $0.occupies(x: x, y: y) }
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
            context.stroke(path, with: .color(.secondary.opacity(0.25)), lineWidth: 0.5)
        }
        .frame(
            width: CGFloat(mapArea.columns) * mapCellSize,
            height: CGFloat(mapArea.rows) * mapCellSize
        )
    }
}

struct GridPoint: Hashable {
    let x: Int
    let y: Int
}
