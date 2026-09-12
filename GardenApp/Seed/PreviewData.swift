import Foundation
import SwiftData

/// An in-memory, seeded ModelContainer used only by SwiftUI #Preview blocks.
enum PreviewData {
    @MainActor
    static let container: ModelContainer = {
        let schema = Schema([
            PlantSpecies.self,
            MapArea.self,
            Bed.self,
            Structure.self,
            PlacedPlant.self,
            MonthlyTaskTemplate.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        SeedData.populateIfNeeded(in: container.mainContext)
        return container
    }()
}
