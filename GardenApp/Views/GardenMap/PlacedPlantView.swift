import SwiftUI

struct PlacedPlantView: View {
    let placedPlant: PlacedPlant

    private var species: PlantSpecies? { placedPlant.species }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: species?.colorHex ?? "#3A7D44"))
            Image(systemName: species?.symbolName ?? "leaf.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white)
        }
        .opacity(placedPlant.status == .removed ? 0.3 : 1.0)
        .overlay(alignment: .bottomTrailing) {
            if placedPlant.status == .harvested {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(species?.commonName ?? "Plant")
        .accessibilityAddTraits(.isButton)
    }
}
