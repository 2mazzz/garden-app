import SwiftUI
import SwiftData

struct CareCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [MonthlyTaskTemplate]
    @Query private var allPlacedPlants: [PlacedPlant]

    @State private var selectedMonth = Calendar.current.component(.month, from: .now)
    @State private var showingAddTask = false

    private static let monthNames = Calendar.current.monthSymbols

    private var tasksForMonth: [MonthlyTaskTemplate] {
        allTasks
            .filter { $0.month == selectedMonth }
            .sorted { $0.title < $1.title }
    }

    private var plantsToPlantThisMonth: [PlacedPlant] {
        allPlacedPlants.filter {
            $0.status != .removed && ($0.species?.isGoodToPlant(inMonth: selectedMonth) ?? false)
        }
    }

    private var plantsToHarvestThisMonth: [PlacedPlant] {
        allPlacedPlants.filter {
            $0.status != .removed && ($0.species?.harvestMonths.contains(selectedMonth) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(Self.monthNames[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if !plantsToPlantThisMonth.isEmpty {
                    Section("Good time to plant") {
                        ForEach(plantsToPlantThisMonth) { plant in
                            Label(plant.species?.commonName ?? "Plant", systemImage: "hand.point.up.left.and.text")
                        }
                    }
                }

                if !plantsToHarvestThisMonth.isEmpty {
                    Section("Ready around now") {
                        ForEach(plantsToHarvestThisMonth) { plant in
                            Label(plant.species?.commonName ?? "Plant", systemImage: "basket.fill")
                        }
                    }
                }

                Section("Tasks") {
                    if tasksForMonth.isEmpty {
                        Text("No tasks added for this month yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(tasksForMonth) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(task.title, systemImage: task.category.symbolName)
                                .font(.headline)
                            if !task.details.isEmpty {
                                Text(task.details)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
            .navigationTitle("Care Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet(defaultMonth: selectedMonth)
            }
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = tasksForMonth[index]
            guard !task.isBuiltIn else { continue }
            modelContext.delete(task)
        }
    }
}
