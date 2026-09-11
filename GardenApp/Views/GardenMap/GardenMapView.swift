import SwiftUI
import SwiftData

let mapCellSize: CGFloat = 32

/// Renders one MapArea (either the outdoor garden or the greenhouse) as a
/// grid canvas. Beds are drawn as colored rectangles; plants and trees are
/// drawn as icons on top. Tapping an empty cell places a new plant there;
/// tapping an existing plant opens its detail sheet.
struct GardenMapView: View {
    @Bindable var mapArea: MapArea

    @State private var isAddingBed = false
    @State private var isAddingPlant = false
    @State private var prefilledPoint: GridPoint?
    @State private var selectedPlacedPlant: PlacedPlant?

    private var beds: [Bed] { mapArea.beds ?? [] }
    private var placedPlants: [PlacedPlant] { mapArea.placedPlants ?? [] }

    var body: some View {
        NavigationStack {
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
    }

    /// Invisible tap targets over every empty cell, so tapping open space
    /// on the map is a shortcut to placing a plant there.
    private var emptyCellTapTargets: some View {
        ForEach(0..<mapArea.rows, id: \.self) { row in
            ForEach(0..<mapArea.columns, id: \.self) { col in
                if placedPlant(atX: col, y: row) == nil {
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
