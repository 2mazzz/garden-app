import SwiftUI
import SwiftData

@main
struct GardenAppApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            PlantSpecies.self,
            MapArea.self,
            Bed.self,
            Structure.self,
            PlacedPlant.self,
            MonthlyTaskTemplate.self
        ])

        // CloudKit sync via the private database of whichever iCloud account
        // is signed in on-device. Both of our phones are signed into the
        // same shared iCloud account, so this is how data stays in sync
        // between us without running any backend. See docs/decisions/0003-icloud-sync.md.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.tomasrojder.gardenapp")
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        SeedData.populateIfNeeded(in: modelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(modelContainer)
    }
}
