import SwiftUI
import SwiftData

struct RootTabView: View {
    @Query(filter: #Predicate<MapArea> { $0.kindRaw == "outdoor" })
    private var outdoorAreas: [MapArea]

    @AppStorage(GardenTheme.storageKey) private var themeRawValue: String = GardenTheme.handDrawnJournal.rawValue

    private var theme: GardenTheme { GardenTheme(rawValue: themeRawValue) ?? .handDrawnJournal }

    var body: some View {
        TabView {
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

            CareCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            PlantWikiListView()
                .tabItem { Label("Wiki", systemImage: "book.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(theme.accentColor)
        .environment(\.gardenTheme, theme)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
}
