import SwiftUI

struct StructureView: View {
    let structure: Structure

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hex: structure.colorHex).opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: structure.colorHex), lineWidth: 2)
            )
            .overlay {
                VStack(spacing: 2) {
                    Image(systemName: structure.symbolName)
                        .font(.title3)
                        .accessibilityHidden(true)
                    Text(structure.name)
                        .font(.caption2.bold())
                }
                .foregroundStyle(.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(structure.name)
    }
}
