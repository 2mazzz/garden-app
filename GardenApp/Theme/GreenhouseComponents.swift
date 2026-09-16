import SwiftUI

// MARK: - GHButtonStyle

/// Primary/secondary/ghost button style per the Greenhouse handoff's
/// "Buttons" spec. iOS has no hover concept; `configuration.isPressed` is
/// used as the "pressed" feedback stand-in for the handoff's hover states.
struct GHButtonStyle: ButtonStyle {
    enum Kind {
        case primary, secondary, ghost
    }

    var kind: Kind

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // 15px/600 per spec; no matching 15px/SemiBold token exists on
            // GreenhouseTheme.Font (listItem() is 15px/Medium), so this is
            // hardcoded rather than substituting a mismatched weight.
            .font(.custom("Work Sans SemiBold", size: 15))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, GreenhouseTheme.Spacing.sm) // 12px per spec
            .frame(minHeight: 44)
            .background(background(configuration: configuration))
            .foregroundStyle(foreground)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.control))
    }

    /// Primary/secondary get 20px horizontal padding; ghost gets 16px — the
    /// handoff specifies ghost padding as `12px 16px`, distinct from the
    /// other two kinds' `12px 20px`.
    private var horizontalPadding: CGFloat {
        switch kind {
        case .primary, .secondary: return GreenhouseTheme.Spacing.md + 4 // 20px
        case .ghost: return GreenhouseTheme.Spacing.md // 16px
        }
    }

    private var foreground: SwiftUI.Color {
        guard isEnabled else { return GreenhouseTheme.Color.placeholderText }
        switch kind {
        case .primary: return GreenhouseTheme.Color.paper
        case .secondary: return GreenhouseTheme.Color.ink
        case .ghost: return GreenhouseTheme.Color.bodyText
        }
    }

    private func background(configuration: Configuration) -> SwiftUI.Color {
        guard isEnabled else { return GreenhouseTheme.Color.disabledFill }
        switch kind {
        case .primary:
            return configuration.isPressed ? GreenhouseTheme.Color.primaryButtonHover : GreenhouseTheme.Color.green
        case .secondary:
            return configuration.isPressed ? GreenhouseTheme.Color.ghostHoverFill : GreenhouseTheme.Color.card
        case .ghost:
            return configuration.isPressed ? GreenhouseTheme.Color.ghostHoverFill : .clear
        }
    }

    @ViewBuilder
    private var border: some View {
        if kind == .secondary {
            RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.control)
                .stroke(GreenhouseTheme.Color.inputBorder, lineWidth: 1)
        }
    }
}

#Preview("GHButtonStyle") {
    VStack(spacing: GreenhouseTheme.Spacing.sm) {
        Button("Primary") {}.buttonStyle(GHButtonStyle(kind: .primary))
        Button("Secondary") {}.buttonStyle(GHButtonStyle(kind: .secondary))
        Button("Ghost") {}.buttonStyle(GHButtonStyle(kind: .ghost))
        Button("Primary disabled") {}.buttonStyle(GHButtonStyle(kind: .primary)).disabled(true)
    }
    .padding()
    .background(GreenhouseTheme.Color.paper)
}

// MARK: - GHChip

/// A single-select filter chip. See handoff "Filter chips" spec.
struct GHChip: View {
    enum Style {
        case `default`, tinted
    }

    var title: String
    var isSelected: Bool
    var style: Style = .default
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GreenhouseTheme.Font.small())
                .fontWeight(isSelected ? .medium : .regular)
                .foregroundStyle(foreground)
                .padding(.horizontal, 14)
                .padding(.vertical, GreenhouseTheme.Spacing.xs)
                .frame(minHeight: 44)
                .background(background)
                .overlay(
                    RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.chip)
                        .stroke(borderColor ?? .clear, lineWidth: borderColor == nil ? 0 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.chip))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foreground: SwiftUI.Color {
        if isSelected { return GreenhouseTheme.Color.paper }
        switch style {
        case .default: return GreenhouseTheme.Color.bodyText
        case .tinted: return GreenhouseTheme.Color.green
        }
    }

    private var background: SwiftUI.Color {
        if isSelected { return GreenhouseTheme.Color.green }
        switch style {
        case .default: return GreenhouseTheme.Color.mist
        case .tinted: return GreenhouseTheme.Color.greenTint
        }
    }

    private var borderColor: SwiftUI.Color? {
        guard !isSelected else { return nil }
        switch style {
        case .default: return GreenhouseTheme.Color.line
        case .tinted: return GreenhouseTheme.Color.lichen
        }
    }
}

#Preview("GHChip") {
    HStack {
        GHChip(title: "All", isSelected: true) {}
        GHChip(title: "Tomatoes", isSelected: false) {}
        GHChip(title: "Herbs", isSelected: false, style: .tinted) {}
    }
    .padding()
    .background(GreenhouseTheme.Color.paper)
}

// MARK: - GHBadge

/// Status badge. See handoff "Status badges" spec.
struct GHBadge: View {
    enum Kind {
        case sowing, harvest, overdue, dormant
    }

    var text: String
    var kind: Kind

    var body: some View {
        Text(text)
            .font(GreenhouseTheme.Font.label())
            .textCase(.uppercase)
            .kerning(0.7) // +6% tracking approximation at this point size
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.chip))
    }

    private var background: SwiftUI.Color {
        switch kind {
        case .sowing: return GreenhouseTheme.Color.greenTint
        case .harvest: return GreenhouseTheme.Color.lichen
        case .overdue: return GreenhouseTheme.Color.overdueTint
        case .dormant: return GreenhouseTheme.Color.mist
        }
    }

    private var foreground: SwiftUI.Color {
        switch kind {
        case .sowing: return GreenhouseTheme.Color.green
        case .harvest: return GreenhouseTheme.Color.deepTintInk
        case .overdue: return GreenhouseTheme.Color.overdueInk
        case .dormant: return GreenhouseTheme.Color.bodyText
        }
    }
}

#Preview("GHBadge") {
    HStack {
        GHBadge(text: "Sowing", kind: .sowing)
        GHBadge(text: "Harvest", kind: .harvest)
        GHBadge(text: "Late", kind: .overdue)
        GHBadge(text: "Dormant", kind: .dormant)
    }
    .padding()
    .background(GreenhouseTheme.Color.paper)
}

// MARK: - GHCheckbox

/// 20x20 checkbox. See handoff "Checkbox" spec.
struct GHCheckbox: View {
    var isChecked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isChecked ? GreenhouseTheme.Color.green : .clear)
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isChecked ? .clear : GreenhouseTheme.Color.checkboxStroke, lineWidth: 1.5)
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GreenhouseTheme.Color.paper)
                }
            }
            .frame(width: 20, height: 20)
            // Expand the tappable area to the 44pt minimum hit target without
            // growing the visible 20x20 box, per the handoff's "min hit target" rule.
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? [.isSelected] : [])
        .accessibilityValue(isChecked ? "Checked" : "Not checked")
    }
}

#Preview("GHCheckbox") {
    HStack {
        GHCheckbox(isChecked: false) {}
        GHCheckbox(isChecked: true) {}
    }
    .padding()
    .background(GreenhouseTheme.Color.paper)
}

// MARK: - GHToggleStyle

/// 40x24 pill toggle. See handoff "Toggle" spec.
struct GHToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.pill)
                        .fill(configuration.isOn ? GreenhouseTheme.Color.green : GreenhouseTheme.Color.inputBorder)
                        .frame(width: 40, height: 24)
                    Circle()
                        .fill(GreenhouseTheme.Color.card)
                        .frame(width: 18, height: 18)
                        .padding(3)
                }
                .frame(width: 40, height: 24)
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}

#Preview("GHToggleStyle") {
    VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.sm) {
        Toggle("Notifications", isOn: .constant(true)).toggleStyle(GHToggleStyle())
        Toggle("Frost alerts", isOn: .constant(false)).toggleStyle(GHToggleStyle())
    }
    .padding()
    .background(GreenhouseTheme.Color.paper)
}

// MARK: - GHProgressBar

/// 8px track progress bar with an optional label row. See handoff
/// "Progress bar" spec.
struct GHProgressBar: View {
    var progress: Double // 0...1
    var label: String? = nil
    var valueText: String? = nil

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
            if label != nil || valueText != nil {
                HStack {
                    if let label {
                        Text(label)
                            .font(GreenhouseTheme.Font.small())
                            .foregroundStyle(GreenhouseTheme.Color.bodyText)
                    }
                    Spacer()
                    if let valueText {
                        Text(valueText)
                            .font(GreenhouseTheme.Font.mono())
                            .foregroundStyle(GreenhouseTheme.Color.bodyText)
                    }
                }
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(GreenhouseTheme.Color.disabledFill)
                    Capsule()
                        .fill(GreenhouseTheme.Color.leaf)
                        .frame(width: proxy.size.width * clampedProgress)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview("GHProgressBar") {
    VStack(spacing: GreenhouseTheme.Spacing.md) {
        GHProgressBar(progress: 0.6, label: "Beds planted", valueText: "6/10")
        GHProgressBar(progress: 0.3)
    }
    .padding()
    .background(GreenhouseTheme.Color.paper)
}

// MARK: - GHEmptyState

/// Dashed-border empty state block with a striped art placeholder,
/// headline, body, and primary action. See handoff "Empty state" spec.
struct GHEmptyState: View {
    var headline: String
    var bodyText: String
    var buttonTitle: String
    var action: () -> Void

    /// External label stays `body:` to match the handoff's component API;
    /// stored internally as `bodyText` since `View` already reserves the
    /// name `body` for its required computed property.
    init(headline: String, body: String, buttonTitle: String, action: @escaping () -> Void) {
        self.headline = headline
        self.bodyText = body
        self.buttonTitle = buttonTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: GreenhouseTheme.Spacing.sm) {
            GHArtPlaceholder(caption: headline, size: CGSize(width: 120, height: 60))

            Text(headline)
                // 16px/600 per spec; cardTitle() is 17px/600 (1px off), so
                // hardcoded here rather than reusing the mismatched token.
                .font(.custom("Work Sans SemiBold", size: 16))
                .foregroundStyle(GreenhouseTheme.Color.ink)
                .multilineTextAlignment(.center)

            Text(bodyText)
                .font(GreenhouseTheme.Font.small())
                .foregroundStyle(GreenhouseTheme.Color.bodyText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260) // ~34ch cap per handoff

            Button(buttonTitle, action: action)
                .buttonStyle(GHButtonStyle(kind: .primary))
        }
        .padding(.horizontal, 18) // 18px per spec (`22px 18px`); no exact Spacing token
        .padding(.vertical, 22) // 22px per spec (`22px 18px`)
        .frame(maxWidth: .infinity)
        .background(GreenhouseTheme.Color.mist)
        .overlay(
            RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .foregroundStyle(GreenhouseTheme.Color.cardHoverBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card))
    }
}

#Preview("GHEmptyState") {
    GHEmptyState(
        headline: "No beds yet",
        body: "Add your first bed to start planning what grows where.",
        buttonTitle: "Add a bed",
        action: {}
    )
    .padding()
    .background(GreenhouseTheme.Color.paper)
}

// MARK: - GHAlertRow

/// Overdue-tinted attention row with a clay dot. See handoff
/// "Alert / attention row" spec.
struct GHAlertRow: View {
    var headline: String
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: GreenhouseTheme.Spacing.xs) {
            Circle()
                .fill(GreenhouseTheme.Color.clay)
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    // 14px/600 per spec; no matching token (listItem() is
                    // 15px/Medium), so hardcoded rather than substituted.
                    .font(.custom("Work Sans SemiBold", size: 14))
                    .foregroundStyle(GreenhouseTheme.Color.overdueInk)
                Text(detail)
                    .font(GreenhouseTheme.Font.small())
                    .foregroundStyle(GreenhouseTheme.Color.overdueSecondaryInk)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, GreenhouseTheme.Spacing.sm)
        .background(GreenhouseTheme.Color.overdueTint)
        .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card))
    }
}

#Preview("GHAlertRow") {
    GHAlertRow(headline: "Watering overdue", detail: "Tomatoes in Bed 2 — last watered 4 days ago")
        .padding()
        .background(GreenhouseTheme.Color.paper)
}

// MARK: - GHArtPlaceholder

/// Stand-in for unbuilt botanical line art: a 45°-striped block with a
/// small mono caption, matching the handoff's
/// `repeating-linear-gradient(135deg, #E7EBE0 0 7px, #F3F5EE 7px 14px)`.
struct GHArtPlaceholder: View {
    var caption: String
    var size: CGSize

    private let stripeWidth: CGFloat = 7
    private let stripeColorA = SwiftUI.Color(hex: "#E7EBE0")
    private let stripeColorB = SwiftUI.Color(hex: "#F3F5EE")

    var body: some View {
        ZStack {
            Canvas { context, canvasSize in
                context.fill(Path(CGRect(origin: .zero, size: canvasSize)), with: .color(stripeColorB))

                // 45-degree stripes: draw a series of parallel diagonal bands
                // wide enough to cover the canvas regardless of aspect ratio.
                let diagonal = canvasSize.width + canvasSize.height
                let period = stripeWidth * 2
                var x = -diagonal
                while x < diagonal {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + stripeWidth, y: 0))
                    path.addLine(to: CGPoint(x: x + stripeWidth + canvasSize.height, y: canvasSize.height))
                    path.addLine(to: CGPoint(x: x + canvasSize.height, y: canvasSize.height))
                    path.closeSubpath()
                    context.fill(path, with: .color(stripeColorA))
                    x += period
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.control))

            Text("art · \(caption)")
                .font(GreenhouseTheme.Font.mono(11))
                .foregroundStyle(GreenhouseTheme.Color.metaText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
        }
        .frame(width: size.width, height: size.height)
    }
}

#Preview("GHArtPlaceholder") {
    VStack(spacing: GreenhouseTheme.Spacing.md) {
        GHArtPlaceholder(caption: "tomato", size: CGSize(width: 160, height: 100))
        GHArtPlaceholder(caption: "greenhouse", size: CGSize(width: 300, height: 60))
    }
    .padding()
    .background(GreenhouseTheme.Color.paper)
}
