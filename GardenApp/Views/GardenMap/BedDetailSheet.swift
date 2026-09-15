import SwiftUI
import SwiftData

/// A deliberately small menu, not a full-screen form — position and size
/// are set by dragging the bed directly on the map (see BedView), so this
/// only needs to cover what dragging can't: naming, color, adding a plant
/// into the bed, and deleting it.
struct BedDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var bed: Bed
    let mapArea: MapArea

    @State private var showingAddPlant = false

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: bed.colorHex) },
            set: { bed.colorHex = $0.toHexString() }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $bed.name)
                    ColorPicker("Color", selection: colorBinding)
                }

                Section {
                    Button("Add a plant to this bed") {
                        showingAddPlant = true
                    }
                }

                Section {
                    Text(bed.shape == .triangle
                        ? "Drag inside the triangle to move it. Drag any corner dot to reshape it."
                        : "Drag the bed on the map to move it. Drag the corner handle to resize it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Delete bed", role: .destructive) {
                        modelContext.delete(bed)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Bed")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                AddPlantSheet(mapArea: mapArea, defaultPoint: nil, defaultBed: bed)
            }
        }
        // A single detent, not a small-height one first: a too-short
        // initial height silently cut off the Delete row below the fold
        // (Form/List rows below the visible area aren't even instantiated
        // until scrolled into view) — found by actually running the UI
        // test, not by reading the code. See docs/decisions/0010.
        .presentationDetents([.medium])
    }
}
