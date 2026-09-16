import SwiftUI

/// The app's one fixed visual system, from the "Greenhouse" design handoff
/// (design/design_handoff_garden_app/README.md). See
/// docs/decisions/0018-greenhouse-design-system.md for why this replaced
/// the old switchable GardenTheme.
enum GreenhouseTheme {
    enum Color {
        // Color roles
        static let ink = SwiftUI.Color(hex: "#1F3024")
        static let green = SwiftUI.Color(hex: "#2F5D3A")
        static let leaf = SwiftUI.Color(hex: "#7E9A5C")
        static let lichen = SwiftUI.Color(hex: "#C9D6B3")
        static let clay = SwiftUI.Color(hex: "#A9552C")
        static let paper = SwiftUI.Color(hex: "#FBFAF6")
        static let mist = SwiftUI.Color(hex: "#F1F3EC")
        static let card = SwiftUI.Color(hex: "#FFFFFF")
        static let line = SwiftUI.Color(hex: "#E4E6DE")

        // Supporting text/border/tint values
        static let bodyText = SwiftUI.Color(hex: "#4A5449")
        static let metaText = SwiftUI.Color(hex: "#6A7268")
        static let placeholderText = SwiftUI.Color(hex: "#9BA396")
        static let inputBorder = SwiftUI.Color(hex: "#D7DCCF")
        static let cardDivider = SwiftUI.Color(hex: "#EDEFE8")
        static let disabledFill = SwiftUI.Color(hex: "#E9EBE4")
        static let checkboxStroke = SwiftUI.Color(hex: "#B9C1AF")

        static let greenTint = SwiftUI.Color(hex: "#E8EFDF")
        static let greenTintInk = green
        static let deepTintInk = SwiftUI.Color(hex: "#26402C")

        static let overdueTint = SwiftUI.Color(hex: "#F6E6DC")
        static let overdueInk = SwiftUI.Color(hex: "#8A4320")
        static let overdueSecondaryInk = SwiftUI.Color(hex: "#7A4526")

        static let primaryButtonHover = SwiftUI.Color(hex: "#244A2D")
        static let ghostHoverFill = SwiftUI.Color(hex: "#F1F3EC")
        static let cardHoverBorder = SwiftUI.Color(hex: "#C7CEBD")

        static let plotMapGround = SwiftUI.Color(hex: "#EFEDE2")
        static let plotBorder = SwiftUI.Color(hex: "#DDDACB")
    }

    enum Font {
        static func display() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 34) }
        static func screenTitle() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 26) }
        static func section() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 20) }
        static func cardTitle() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 17) }
        static func body() -> SwiftUI.Font { .custom("Work Sans", size: 15) }
        static func listItem() -> SwiftUI.Font { .custom("Work Sans Medium", size: 15) }
        static func small() -> SwiftUI.Font { .custom("Work Sans", size: 13) }
        /// UPPERCASE + ~+10% tracking in the handoff. `Font` can't carry text
        /// case, so apply `.textCase(.uppercase)` and `.kerning(1.1)` at call
        /// sites (Task 3's components and later restyle tasks).
        static func label() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 11) }
        static func mono(_ size: CGFloat = 13) -> SwiftUI.Font { .custom("IBM Plex Mono", size: size) }
        static func monoMedium(_ size: CGFloat = 13) -> SwiftUI.Font { .custom("IBM Plex Mono Medium", size: size) }
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let screenPadding: CGFloat = 20
    }

    enum Radius {
        static let chip: CGFloat = 4
        static let control: CGFloat = 8   // button, input, small tile
        static let card: CGFloat = 10
        static let panel: CGFloat = 12
        static let sheet: CGFloat = 16
        static let pill: CGFloat = 999
    }
}

extension View {
    /// Flat elevation — lists, rows: hairline border, no shadow.
    func gh_flat() -> some View {
        overlay(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card).stroke(GreenhouseTheme.Color.line, lineWidth: 1))
    }

    /// Raised elevation — cards. Shadow approximates the handoff's
    /// `0 10px 30px -22px rgba(31,48,36,0.55)` — SwiftUI's shadow model has
    /// no spread/negative-offset equivalent, so the opacity and radius here
    /// are a reasonable translation, not a pixel match.
    func gh_raised() -> some View {
        self
            .overlay(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card).stroke(GreenhouseTheme.Color.line, lineWidth: 1))
            .shadow(color: GreenhouseTheme.Color.ink.opacity(0.055), radius: 15, x: 0, y: 10)
    }
}
