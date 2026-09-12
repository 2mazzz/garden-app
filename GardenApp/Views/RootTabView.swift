import SwiftUI
import SwiftData

struct RootTabView: View {
    @Query(filter: #Predicate<MapArea> { $0.kindRaw == "outdoor" })
    private var outdoorAreas: [MapArea]

    var body: some View {
        TabView {
            Group {
                if let garden = outdoorAreas.first {
                    NavigationStack {
                        GardenMapView(mapArea: garden)
                            .navigationDestination(for: MapArea.self) { area in
                                GardenMapView(mapArea: area)
                            }
                    }
                } else {
                    ProgressView()
                }
            }
            .tabItem { Label("Garden", systemImage: "leaf.fill") }

            CareCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            PlantWikiListView()
                .tabItem { Label("Wiki", systemImage: "book.fill") }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
}
