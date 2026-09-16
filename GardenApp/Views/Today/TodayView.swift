import SwiftUI
import SwiftData

/// The first tab: what needs doing today, grouped by day. See
/// docs/plans/2026-09-15-greenhouse-redesign-design.md ("Today (new)").
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var gardenLocations: [GardenLocation]
    @Query private var allTasks: [GardenTask]

    @State private var weatherSummary: String?
    @State private var showingAddTask = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            Group {
                if allTasks.isEmpty {
                    ScrollView {
                        VStack(spacing: GreenhouseTheme.Spacing.lg) {
                            header
                            GHEmptyState(
                                headline: "No tasks yet",
                                body: "Add what needs doing in the garden and it'll show up here, grouped by day.",
                                buttonTitle: "Add a task"
                            ) {
                                showingAddTask = true
                            }
                        }
                        .padding(.horizontal, GreenhouseTheme.Spacing.screenPadding)
                        .padding(.top, GreenhouseTheme.Spacing.sm)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.lg) {
                            header

                            if !overdueTasks.isEmpty {
                                GHAlertRow(headline: overdueHeadline, detail: overdueDetail)
                            }

                            ForEach(dayGroups) { group in
                                dayGroupSection(group)
                            }
                        }
                        .padding(.horizontal, GreenhouseTheme.Spacing.screenPadding)
                        .padding(.top, GreenhouseTheme.Spacing.sm)
                        .padding(.bottom, GreenhouseTheme.Spacing.lg)
                    }
                }
            }
            .background(GreenhouseTheme.Color.paper)
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
                AddGardenTaskSheet()
            }
            .task {
                await loadWeatherSummary()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xxs) {
            Text(greeting)
                .font(GreenhouseTheme.Font.screenTitle())
                .foregroundStyle(GreenhouseTheme.Color.ink)

            if let weatherSummary {
                Text(weatherSummary)
                    // 14px per handoff's header subtitle; no exact-matching
                    // token (small() is 13px, body() is 15px), so hardcoded
                    // rather than substituting a mismatched size.
                    .font(.custom("Work Sans", size: 14))
                    .foregroundStyle(GreenhouseTheme.Color.bodyText)
            }
        }
    }

    private var greeting: String {
        switch calendar.component(.hour, from: .now) {
        case ..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    /// Non-blocking: the greeting renders immediately; this fills in the
    /// subtitle afterward, or leaves it absent on no location / failure.
    private func loadWeatherSummary() async {
        guard let location = gardenLocations.first else { return }
        do {
            let forecast = try await SMHIWeatherService.fetchDailyMinTemperatures(
                latitude: location.latitude,
                longitude: location.longitude
            )
            guard let todayForecast = forecast.first(where: { calendar.isDateInToday($0.date) }) ?? forecast.first else {
                return
            }
            let roundedTemp = Int(todayForecast.minTemperatureCelsius.rounded())
            if location.placeName.isEmpty {
                weatherSummary = "Low today \(roundedTemp)°C"
            } else {
                weatherSummary = "Low today \(roundedTemp)°C in \(location.placeName)"
            }
        } catch {
            // Best-effort only — stay without a weather line.
        }
    }

    // MARK: - Overdue alert

    private var overdueTasks: [GardenTask] {
        allTasks.filter(\.isLate)
    }

    private var overdueHeadline: String {
        let count = overdueTasks.count
        return count == 1 ? "1 task slipped" : "\(count) tasks slipped"
    }

    private var overdueDetail: String {
        let oldest = overdueTasks.map(\.dueDate).min() ?? .now
        return "Overdue since \(Self.dayDateFormatter.string(from: oldest))"
    }

    // MARK: - Day groups

    private struct DayGroup: Identifiable {
        let id: Date
        let label: String
        let dateText: String
        let tasks: [GardenTask]
    }

    /// Groups all tasks by due-day for today through +6 days, regardless of
    /// done state — the handoff's own prototype content shows a pre-checked
    /// task still sitting in its day's list, and the design doc's "done
    /// tasks keep their position, no reordering" rule means toggling a
    /// card done must not make it vanish. Tasks due before today (folded
    /// into the Today group so they aren't dropped or scattered across
    /// arbitrary past-dated groups — see the handoff's "empty days
    /// collapsed" note and this task's edge-case guidance) keep showing
    /// under Today even once marked done, since `dueDate` never changes;
    /// GardenTask intentionally has no separate "completed on" date, so
    /// there's no other signal to age a finished, once-overdue task out of
    /// view. Tasks due more than 6 days out fall outside this window and
    /// aren't shown here.
    private var dayGroups: [DayGroup] {
        let startOfToday = calendar.startOfDay(for: .now)
        guard let endOfWindow = calendar.date(byAdding: .day, value: 6, to: startOfToday) else { return [] }

        var buckets: [Date: [GardenTask]] = [:]
        for task in allTasks {
            let day = calendar.startOfDay(for: task.dueDate)
            let bucketDay = max(day, startOfToday)
            guard bucketDay <= endOfWindow else { continue }
            buckets[bucketDay, default: []].append(task)
        }

        return buckets.keys.sorted().map { day in
            let tasks = buckets[day]!.sorted { lhs, rhs in
                if lhs.dueDate != rhs.dueDate { return lhs.dueDate < rhs.dueDate }
                return lhs.title < rhs.title
            }
            return DayGroup(id: day, label: dayLabel(for: day, startOfToday: startOfToday), dateText: Self.dayDateFormatter.string(from: day), tasks: tasks)
        }
    }

    private func dayLabel(for day: Date, startOfToday: Date) -> String {
        if day == startOfToday { return "Today" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday), day == tomorrow {
            return "Tomorrow"
        }
        return Self.weekdayFormatter.string(from: day)
    }

    private static let dayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter
    }()

    @ViewBuilder
    private func dayGroupSection(_ group: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: GreenhouseTheme.Spacing.xs) {
            HStack {
                Text(group.label)
                    .font(GreenhouseTheme.Font.label())
                    .textCase(.uppercase)
                    .kerning(1.1)
                    .foregroundStyle(GreenhouseTheme.Color.metaText)
                Spacer()
                Text(group.dateText)
                    .font(GreenhouseTheme.Font.mono())
                    .foregroundStyle(GreenhouseTheme.Color.metaText)
            }

            VStack(spacing: GreenhouseTheme.Spacing.xs) {
                ForEach(group.tasks) { task in
                    GardenTaskCardRow(task: task, onToggle: { toggle(task) })
                }
            }
        }
    }

    private func toggle(_ task: GardenTask) {
        task.isDone.toggle()
        try? modelContext.save()
    }
}

/// One task card: checkbox · title + location line · optional Late badge.
/// The whole card toggles done, matching the handoff's "tappable, toggles
/// done" behavior; the checkbox does the same for a smaller, precise
/// target.
private struct GardenTaskCardRow: View {
    let task: GardenTask
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: GreenhouseTheme.Spacing.sm) {
            GHCheckbox(isChecked: task.isDone, action: onToggle)
                .accessibilityIdentifier("taskCheckbox-\(task.id.uuidString)")

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(GreenhouseTheme.Font.listItem())
                    .foregroundStyle(task.isDone ? GreenhouseTheme.Color.metaText : GreenhouseTheme.Color.ink)

                if !task.locationText.isEmpty {
                    Text(task.locationText)
                        .font(GreenhouseTheme.Font.small())
                        .foregroundStyle(GreenhouseTheme.Color.metaText)
                }
            }

            Spacer(minLength: 0)

            if task.isLate {
                GHBadge(text: "Late", kind: .overdue)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(GreenhouseTheme.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card))
        .gh_flat()
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewData.container)
}
