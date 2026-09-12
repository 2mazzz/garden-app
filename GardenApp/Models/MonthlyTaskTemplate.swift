import Foundation
import SwiftData

/// A recurring, general gardening task tied to a calendar month (1-12),
/// shown in the Care Calendar tab. Not tied to a specific plant instance —
/// these are the "what should I be doing in the garden this month" reminders.
@Model
final class MonthlyTaskTemplate: Identifiable {
    var id: UUID = UUID()
    var month: Int = 1
    var title: String = ""
    var details: String = ""
    var categoryRaw: String = TaskCategory.other.rawValue
    /// True for tasks seeded by the app; false for tasks the user added themselves.
    var isBuiltIn: Bool = false

    init(
        id: UUID = UUID(),
        month: Int,
        title: String,
        details: String = "",
        category: TaskCategory,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.month = month
        self.title = title
        self.details = details
        self.categoryRaw = category.rawValue
        self.isBuiltIn = isBuiltIn
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
