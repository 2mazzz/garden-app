import SwiftUI
import UIKit

extension Color {
    /// Builds a Color from a "#RRGGBB" hex string. Falls back to gray if malformed.
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgbValue: UInt64 = 0
        guard hexString.count == 6, Scanner(string: hexString).scanHexInt64(&rgbValue) else {
            self = .gray
            return
        }

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// The inverse of `init(hex:)`, so a native ColorPicker's selection can be
    /// stored back into a model's "#RRGGBB" colorHex attribute.
    func toHexString() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }
}
