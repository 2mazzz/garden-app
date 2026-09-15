import SwiftUI
import SwiftData

/// A small edit menu, matching BedDetailSheet — position and size are set
/// by dragging the structure directly on the map (see StructureView), so
/// this only needs to cover naming, color, and deleting.
struct StructureDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var structure: Structure
    let mapArea: MapArea

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: structure.colorHex) },
            set: { structure.colorHex = $0.toHexString() }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $structure.name)
                    ColorPicker("Color", selection: colorBinding)
                }

                if structure.linkedMapArea != nil {
                    Section {
                        Text("Tap this structure on the map to enter \(structure.linkedMapArea?.name ?? "it").")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("Drag the structure on the map to move it. Drag the corner handle to resize it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Delete structure", role: .destructive) {
                        modelContext.delete(structure)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Structure")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
