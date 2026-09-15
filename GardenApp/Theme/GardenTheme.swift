import SwiftUI

/// The app's selectable visual style — see
/// docs/decisions/0013-theme-system.md. Three "gardeny" directions, applied
/// across the map (grid, beds, structures, plants) and as the app's accent
/// color. Stored per-device (not synced), so each of the two users on the
/// shared iCloud account can pick their own.
enum GardenTheme: String, CaseIterable, Identifiable {
    case handDrawnJournal
    case rusticWoodSoil
    case botanicalIllustration

    static let storageKey = "gardenTheme"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .handDrawnJournal: return "Garden Journal"
        case .rusticWoodSoil: return "Rustic Wood & Soil"
        case .botanicalIllustration: return "Botanical Illustration"
        }
    }

    var tagline: String {
        switch self {
        case .handDrawnJournal: return "Warm parchment, soft pencil grid, leafy markers"
        case .rusticWoodSoil: return "Wooden planter boxes on a potting-bench backdrop"
        case .botanicalIllustration: return "Crisp field-guide linework on soft sage"
        }
    }

    /// The map's canvas background, behind the grid.
    var backgroundColor: Color {
        switch self {
        case .handDrawnJournal: return Color(hex: "#F5EEDD")
        case .rusticWoodSoil: return Color(hex: "#D8C6A3")
        case .botanicalIllustration: return Color(hex: "#F4F7F0")
        }
    }

    var gridLineColor: Color {
        switch self {
        case .handDrawnJournal: return Color(hex: "#8B7355").opacity(0.35)
        case .rusticWoodSoil: return Color(hex: "#5A4632").opacity(0.4)
        case .botanicalIllustration: return Color(hex: "#4C6B4C").opacity(0.25)
        }
    }

    /// Grid line dash pattern — empty means a solid line.
    var gridLineDash: [CGFloat] {
        switch self {
        case .handDrawnJournal: return [3, 3]
        case .rusticWoodSoil: return []
        case .botanicalIllustration: return [1, 0]
        }
    }

    var gridLineWidth: CGFloat {
        switch self {
        case .handDrawnJournal: return 0.75
        case .rusticWoodSoil: return 1.25
        case .botanicalIllustration: return 0.5
        }
    }

    var bedCornerRadius: CGFloat {
        switch self {
        case .handDrawnJournal: return 10
        case .rusticWoodSoil: return 3
        case .botanicalIllustration: return 4
        }
    }

    var bedFillOpacity: Double {
        switch self {
        case .handDrawnJournal: return 0.4
        case .rusticWoodSoil: return 0.55
        case .botanicalIllustration: return 0.18
        }
    }

    var bedBorderWidth: CGFloat {
        switch self {
        case .handDrawnJournal: return 1.5
        case .rusticWoodSoil: return 2.5
        case .botanicalIllustration: return 1
        }
    }

    var structureCornerRadius: CGFloat {
        switch self {
        case .handDrawnJournal: return 12
        case .rusticWoodSoil: return 2
        case .botanicalIllustration: return 4
        }
    }

    var headingFont: Font {
        switch self {
        case .handDrawnJournal: return .system(.title3, design: .rounded).weight(.semibold)
        case .rusticWoodSoil: return .system(.title3, design: .serif).weight(.bold)
        case .botanicalIllustration: return .system(.title3, design: .serif)
        }
    }

    var bodyFont: Font {
        switch self {
        case .handDrawnJournal: return .system(.body, design: .rounded)
        case .rusticWoodSoil: return .system(.body, design: .default)
        case .botanicalIllustration: return .system(.body, design: .serif)
        }
    }

    var labelFont: Font {
        switch self {
        case .handDrawnJournal: return .system(.caption2, design: .rounded).weight(.medium)
        case .rusticWoodSoil: return .system(.caption2, design: .default).weight(.bold)
        case .botanicalIllustration: return .system(.caption2, design: .serif)
        }
    }

    var accentColor: Color {
        switch self {
        case .handDrawnJournal: return Color(hex: "#5C8A4E")
        case .rusticWoodSoil: return Color(hex: "#7A5C3E")
        case .botanicalIllustration: return Color(hex: "#4C6B4C")
        }
    }

    /// A few representative colors for the Settings preview swatch.
    var previewSwatchColors: [Color] {
        [backgroundColor, accentColor, gridLineColor.opacity(1)]
    }
}

private struct GardenThemeKey: EnvironmentKey {
    static let defaultValue: GardenTheme = .handDrawnJournal
}

extension EnvironmentValues {
    var gardenTheme: GardenTheme {
        get { self[GardenThemeKey.self] }
        set { self[GardenThemeKey.self] = newValue }
    }
}
