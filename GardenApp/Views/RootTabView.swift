import SwiftUI
import SwiftData

struct RootTabView: View {
    @Query(filter: #Predicate<MapArea> { $0.kindRaw == "outdoor" })
    private var outdoorAreas: [MapArea]

    @Query(filter: #Predicate<MapArea> { $0.kindRaw == "greenhouse" })
    private var greenhouseAreas: [MapArea]

    var body: some View {
        TabView {
            Group {
                if let garden = outdoorAreas.first {
                    GardenMapView(mapArea: garden)
                } else {
                    ProgressView()
                }
            }
            .tabItem { Label("Garden", systemImage: "leaf.fill") }

            Group {
                if let greenhouse = greenhouseAreas.first {
                    GardenMapView(mapArea: greenhouse)
                } else {
                    ProgressView()
                }
            }
            .tabItem { Label("Greenhouse", systemImage: "house.fill") }

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
