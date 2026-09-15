import SwiftUI
import SwiftData

struct LogHarvestSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let placedPlant: PlacedPlant

    @State private var date = Date.now
    @State private var quantityText = ""
    @State private var unit = "kg"
    @State private var notes = ""

    private static let units = ["kg", "g", "st"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Quantity (optional)", text: $quantityText)
                        .keyboardType(.decimalPad)
                    Picker("Unit", selection: $unit) {
                        ForEach(Self.units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Log Harvest")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let quantity = Double(quantityText.replacingOccurrences(of: ",", with: "."))
        let log = HarvestLog(
            date: date,
            quantity: quantity,
            unit: unit,
            notes: notes,
            placedPlant: placedPlant
        )
        modelContext.insert(log)
        dismiss()
    }
}
