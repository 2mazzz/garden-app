import SwiftUI

struct BedView: View {
    let bed: Bed

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(hex: bed.colorHex).opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: bed.colorHex), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                Text(bed.name)
                    .font(.caption2)
                    .padding(3)
                    .foregroundStyle(.secondary)
            }
    }
}
