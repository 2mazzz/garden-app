import SwiftUI
import SwiftData

/// Presets for the common non-functional structures a garden map needs
/// (house, driveway, shed) — Structure itself has no "kind" field (see
/// docs/decisions/0006-garden-home-with-structures.md), these are purely
/// sheet-local defaults for name/icon/color/size that get baked into a
/// plain Structure on creation. "Custom" lets you type your own name/icon
/// for anything else (a fence, a pond, a compost bin, ...).
private enum StructurePreset: String, CaseIterable, Identifiable {
    case house, driveway, shed, custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .house: return "House"
        case .driveway: return "Driveway"
        case .shed: return "Shed"
        case .custom: return "Custom"
        }
    }

    var symbolName: String {
        switch self {
        case .house: return "house.fill"
        case .driveway: return "car.fill"
        case .shed: return "shippingbox.fill"
        case .custom: return "square.dashed"
        }
    }

    var colorHex: String {
        switch self {
        case .house: return "#8B7355"
        case .driveway: return "#8A8A8A"
        case .shed: return "#6B6B4E"
        case .custom: return "#6B6B6B"
        }
    }

    var defaultWidth: Int {
        switch self {
        case .house: return 4
        case .driveway: return 2
        case .shed: return 2
        case .custom: return 2
        }
    }

    var defaultHeight: Int {
        switch self {
        case .house: return 4
        case .driveway: return 4
        case .shed: return 2
        case .custom: return 2
        }
    }
}

struct AddStructureSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mapArea: MapArea

    @State private var preset: StructurePreset = .house
    @State private var name = StructurePreset.house.displayName
    @State private var symbolName = StructurePreset.house.symbolName
    @State private var color = Color(hex: StructurePreset.house.colorHex)

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $preset) {
                        ForEach(StructurePreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Name", text: $name)
                    ColorPicker("Color", selection: $color)
                    if preset == .custom {
                        TextField("SF Symbol name (e.g. \"leaf.fill\")", text: $symbolName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Section {
                    Text("It's placed near the middle of the map — drag it into place afterward, and drag its corner handle to resize it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Structure")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addStructure() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: preset) { _, newPreset in applyDefaults(for: newPreset) }
        }
    }

    private func applyDefaults(for preset: StructurePreset) {
        name = preset.displayName
        symbolName = preset.symbolName
        color = Color(hex: preset.colorHex)
    }

    private func addStructure() {
        let width = min(preset.defaultWidth, mapArea.columns)
        let height = min(preset.defaultHeight, mapArea.rows)
        // Near the middle of the map, not grid (0,0) — with a large grid
        // and a centered starter layout, (0,0) is usually off-screen.
        let x = max(0, min(mapArea.columns - width, mapArea.columns / 2 - width / 2))
        let y = max(0, min(mapArea.rows - height, mapArea.rows / 2 - height / 2))
        let structure = Structure(
            name: name,
            x: x,
            y: y,
            width: width,
            height: height,
            colorHex: color.toHexString(),
            symbolName: symbolName.isEmpty ? "square.dashed" : symbolName,
            mapArea: mapArea
        )
        modelContext.insert(structure)
        // Explicit save, not just insert() — see ADR 0020.
        try? modelContext.save()
        dismiss()
    }
}
