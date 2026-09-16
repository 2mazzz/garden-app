import SwiftUI
import SwiftData

struct RootTabView: View {
    @Query(filter: #Predicate<MapArea> { $0.kindRaw == "outdoor" })
    private var outdoorAreas: [MapArea]

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "square.fill") }

            Group {
                if let garden = outdoorAreas.first {
                    NavigationStack {
                        GardenMapView(mapArea: garden)
                    }
                } else {
                    ProgressView()
                }
            }
            .tabItem { Label("Garden", systemImage: "leaf.fill") }

            PlantWikiListView()
                .tabItem { Label("Wiki", systemImage: "book.fill") }

            CareCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(GreenhouseTheme.Color.green)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
}
