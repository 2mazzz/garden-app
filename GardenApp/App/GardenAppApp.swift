import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct GardenAppApp: App {
    let modelContainer: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let schema = Schema([
            PlantSpecies.self,
            MapArea.self,
            Bed.self,
            Structure.self,
            PlacedPlant.self,
            MonthlyTaskTemplate.self,
            GardenLocation.self,
            HarvestLog.self,
            GardenTask.self,
            PlantNote.self
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
        let container: ModelContainer
        if let cloudKitContainer = try? ModelContainer(for: schema, configurations: [cloudKitConfiguration]) {
            container = cloudKitContainer
        } else {
            let localConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                container = try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch {
                fatalError("Failed to create ModelContainer even without CloudKit: \(error)")
            }
        }
        modelContainer = container

        SeedData.populateIfNeeded(in: container.mainContext)
        GridSizeMigration.migrateIfNeeded(in: container.mainContext)
        try? container.mainContext.save()

        // Best-effort daily background frost check — see
        // docs/plans/2026-09-14-weather-and-harvest-design.md. Background
        // task timing is opportunistic, not guaranteed; the scenePhase
        // foreground check below is the reliable path.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: FrostAlertService.backgroundTaskIdentifier, using: nil) { task in
            Self.handleFrostCheckTask(task as! BGAppRefreshTask, modelContainer: container)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task { await FrostAlertService.checkAndNotify(in: modelContainer.mainContext) }
            case .background:
                Self.scheduleFrostCheck()
            default:
                break
            }
        }
    }

    private static func scheduleFrostCheck() {
        let request = BGAppRefreshTaskRequest(identifier: FrostAlertService.backgroundTaskIdentifier)
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 12, to: .now)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleFrostCheckTask(_ task: BGAppRefreshTask, modelContainer: ModelContainer) {
        scheduleFrostCheck()

        let context = ModelContext(modelContainer)
        let work = Task {
            await FrostAlertService.checkAndNotify(in: context)
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
        }
    }
}
