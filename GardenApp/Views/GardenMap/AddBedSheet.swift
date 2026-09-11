import SwiftUI
import SwiftData

struct AddBedSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mapArea: MapArea

    @State private var name = ""
    @State private var x = 0
    @State private var y = 0
    @State private var width = 3
    @State private var height = 2
    @State private var colorHex = "#8B5E3C"

    private let colorOptions = ["#8B5E3C", "#5B7B4B", "#B08968", "#4A6670", "#A3623E"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Bed") {
                    TextField("Name (e.g. \"Raised bed 1\")", text: $name)
                }

                Section("Position") {
                    Stepper("Column: \(x)", value: $x, in: 0...(max(0, mapArea.columns - width)))
                    Stepper("Row: \(y)", value: $y, in: 0...(max(0, mapArea.rows - height)))
                }

                Section("Size (grid cells)") {
                    Stepper("Width: \(width)", value: $width, in: 1...mapArea.columns)
                    Stepper("Height: \(height)", value: $height, in: 1...mapArea.rows)
                }

                Section("Color") {
                    Picker("Color", selection: $colorHex) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Text(hex).tag(hex)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Bed")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addBed() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addBed() {
        let bed = Bed(
            name: name,
            x: x,
            y: y,
            width: width,
            height: height,
            colorHex: colorHex,
            mapArea: mapArea
        )
        modelContext.insert(bed)
        dismiss()
    }
}
