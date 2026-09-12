import SwiftUI
import SwiftData

let mapCellSize: CGFloat = 32

/// Renders one MapArea (the outdoor garden, or an area entered by tapping a
/// structure like the greenhouse) as a grid canvas. Beds are drawn as
/// colored rectangles, structures (e.g. the greenhouse) as tappable
/// buildings you can enter, and plants/trees as icons on top.
///
/// Expects to be hosted inside a NavigationStack owned by the caller (see
/// RootTabView) rather than providing its own, so that entering a linked
/// structure (garden -> greenhouse) is a normal push, not a new stack.
struct GardenMapView: View {
    @Bindable var mapArea: MapArea

    @State private var isAddingBed = false
    @State private var isAddingPlant = false
    @State private var prefilledPoint: GridPoint?
    @State private var selectedPlacedPlant: PlacedPlant?

    private var beds: [Bed] { mapArea.beds ?? [] }
    private var placedPlants: [PlacedPlant] { mapArea.placedPlants ?? [] }
    private var structures: [Structure] { mapArea.structures ?? [] }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                gridBackground

                ForEach(beds) { bed in
                    BedView(bed: bed)
                        .frame(width: CGFloat(bed.width) * mapCellSize, height: CGFloat(bed.height) * mapCellSize)
                        .position(
                            x: (CGFloat(bed.x) + CGFloat(bed.width) / 2) * mapCellSize,
                            y: (CGFloat(bed.y) + CGFloat(bed.height) / 2) * mapCellSize
                        )
                }

                ForEach(structures) { structure in
                    NavigationLink(value: structure.linkedMapArea) {
                        StructureView(structure: structure)
                    }
                    .buttonStyle(.plain)
                    .disabled(structure.linkedMapArea == nil)
                    .frame(width: CGFloat(structure.width) * mapCellSize, height: CGFloat(structure.height) * mapCellSize)
                    .position(
                        x: (CGFloat(structure.x) + CGFloat(structure.width) / 2) * mapCellSize,
                        y: (CGFloat(structure.y) + CGFloat(structure.height) / 2) * mapCellSize
                    )
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
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    isAddingBed = true
                } label: {
                    Label("Add Bed", systemImage: "square.dashed")
                }
                Button {
                    prefilledPoint = nil
                    isAddingPlant = true
                } label: {
                    Label("Add Plant", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingBed) {
            AddBedSheet(mapArea: mapArea)
        }
        .sheet(isPresented: $isAddingPlant) {
            AddPlantSheet(mapArea: mapArea, defaultPoint: prefilledPoint)
        }
        .sheet(item: $selectedPlacedPlant) { plant in
            PlacedPlantDetailSheet(placedPlant: plant)
        }
    }

    /// Invisible tap targets over every empty, unoccupied cell, so tapping
    /// open space on the map is a shortcut to placing a plant there. Cells
    /// under a structure (e.g. the greenhouse building) are excluded so
    /// they don't shadow the structure's own tap target.
    private var emptyCellTapTargets: some View {
        ForEach(0..<mapArea.rows, id: \.self) { row in
            ForEach(0..<mapArea.columns, id: \.self) { col in
                if placedPlant(atX: col, y: row) == nil && !isOccupiedByStructure(x: col, y: row) {
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

    private func isOccupiedByStructure(x: Int, y: Int) -> Bool {
        structures.contains { $0.occupies(x: x, y: y) }
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

struct GridPoint {
    let x: Int
    let y: Int
}
