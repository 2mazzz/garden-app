import Foundation

enum PlantCategory: String, Codable, CaseIterable, Identifiable {
    case vegetable, herb, flower, shrub, tree, fruit, other

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var symbolName: String {
        switch self {
        case .vegetable: return "carrot.fill"
        case .herb: return "leaf.fill"
        case .flower: return "camera.macro"
        case .shrub: return "tree"
        case .tree: return "tree.fill"
        // No real "fruit" SF Symbol exists — "applelogo" (Apple's own
        // trademark) was wrong here, not just a poor fit. A plain filled
        // dot, tinted with the species' own color, reads fine for a berry
        // bush without claiming to be something it isn't.
        case .fruit: return "circle.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

enum SunRequirement: String, Codable, CaseIterable, Identifiable {
    case fullSun, partialSun, shade

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullSun: return "Full sun"
        case .partialSun: return "Partial sun"
        case .shade: return "Shade"
        }
    }
}

enum WaterRequirement: String, Codable, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

enum PlantStatus: String, Codable, CaseIterable, Identifiable {
    case planned, planted, growing, harvested, removed

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case planting, pruning, watering, fertilizing, pestControl, harvesting, cleanup, greenhouse, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pestControl: return "Pest control"
        default: return rawValue.capitalized
        }
    }

    var symbolName: String {
        switch self {
        case .planting: return "hand.point.up.left.and.text"
        case .pruning: return "scissors"
        case .watering: return "drop.fill"
        case .fertilizing: return "sparkles"
        case .pestControl: return "ladybug.fill"
        case .harvesting: return "basket.fill"
        case .cleanup: return "trash.fill"
        case .greenhouse: return "house.fill"
        case .other: return "checklist"
        }
    }
}

enum MapAreaKind: String, Codable, CaseIterable, Identifiable {
    case outdoor, greenhouse

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .outdoor: return "Garden"
        case .greenhouse: return "Greenhouse"
        }
    }
}
