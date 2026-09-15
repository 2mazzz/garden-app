import Foundation
import SwiftData

/// The garden's real-world location, set once by hand (not live device GPS
/// — the garden doesn't move). A single row; used to fetch forecast data
/// for frost warnings. See docs/decisions/0015-weather-data-source.md.
@Model
final class GardenLocation: Identifiable {
    var id: UUID = UUID()
    var latitude: Double = 0
    var longitude: Double = 0
    var placeName: String = ""

    init(id: UUID = UUID(), latitude: Double, longitude: Double, placeName: String) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
    }
}
