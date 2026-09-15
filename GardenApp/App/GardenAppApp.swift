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
        let cloudKitConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.tomasrojder.gardenapp")
        )

        // Creating a CloudKit-backed container throws if the container
        // isn't provisioned for the current signing identity (e.g. running
        // on the Simulator with "Sign to Run Locally", or before the app
        // has ever been run once with a real Apple ID team so Xcode can
        // register the container). Rather than crash in that case, fall
        // back to local-only storage so the app is still usable — data
        // just won't sync until it's run with real signing. See
        // docs/decisions/0008-cloudkit-fallback.md.
        if let container = try? ModelContainer(for: schema, configurations: [cloudKitConfiguration]) {
            modelContainer = container
        } else {
            let localConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch {
                fatalError("Failed to create ModelContainer even without CloudKit: \(error)")
            }
        }

        SeedData.populateIfNeeded(in: modelContainer.mainContext)
        GridSizeMigration.migrateIfNeeded(in: modelContainer.mainContext)
        try? modelContainer.mainContext.save()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(modelContainer)
    }
}
