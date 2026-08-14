//
//  TodoItem.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 6/8/26.
//

import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var todoDescription: String?
    var isCompleted: Bool
    var imageUrl: String?
    /// Unix timestamp in milliseconds (matches Android `Long?`).
    var dueDate: Int64?

    init(
        id: String = UUID().uuidString,
        title: String = "",
        todoDescription: String? = nil,
        isCompleted: Bool = false,
        imageUrl: String? = nil,
        dueDate: Int64? = nil
    ) {
        self.id = id
        self.title = title
        self.todoDescription = todoDescription
        self.isCompleted = isCompleted
        self.imageUrl = imageUrl
        self.dueDate = dueDate
    }

    var dueDateValue: Date? {
        guard let dueDate else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(dueDate) / 1000)
    }

    static func milliseconds(from date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970 * 1000)
    }
}

extension Array where Element == TodoItem {
    /// Incomplete first, then title A→Z.
    func sortedForDisplay() -> [TodoItem] {
        sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted && rhs.isCompleted
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }
}

extension TodoItem {
    static let sampleTodos: [TodoItem] = {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        var items = [
            TodoItem(
                id: "todo-1",
                title: "Buy groceries",
                todoDescription: "Milk, eggs, bread, and coffee beans",
                isCompleted: false,
                imageUrl: "https://picsum.photos/seed/groceries/200",
                dueDate: TodoItem.milliseconds(from: tomorrow)
            ),
            TodoItem(
                id: "todo-2",
                title: "Finish iOS homework",
                todoDescription: "Wire list screen to Core Data persistence",
                isCompleted: false,
                dueDate: TodoItem.milliseconds(from: nextWeek)
            ),
            TodoItem(
                id: "todo-3",
                title: "Call mom",
                todoDescription: "Wish her a happy weekend",
                isCompleted: true
            ),
            TodoItem(
                id: "todo-4",
                title: "Dentist appointment",
                todoDescription: "Bring insurance card",
                isCompleted: false,
                imageUrl: "https://picsum.photos/seed/dentist/200",
                dueDate: TodoItem.milliseconds(
                    from: calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date()
                )
            ),
            TodoItem(
                id: "todo-5",
                title: "Read SwiftUI docs",
                todoDescription: "NavigationStack, sheets, and forms",
                isCompleted: false
            )
        ]

        let extras: [(String, String, Bool)] = [
            ("todo-6", "Water plants", false),
            ("todo-7", "Pay electricity bill", false),
            ("todo-8", "Plan weekend trip", false),
            ("todo-9", "Update resume", true),
            ("todo-10", "Clean kitchen", false),
            ("todo-11", "Book flight tickets", false),
            ("todo-12", "Reply to emails", true),
            ("todo-13", "Buy birthday gift", false),
            ("todo-14", "Practice guitar", false),
            ("todo-15", "Meal prep Sunday", false),
            ("todo-16", "Review pull requests", false),
            ("todo-17", "Schedule haircut", true),
            ("todo-18", "Backup laptop", false),
            ("todo-19", "Organize photo library", false),
            ("todo-20", "Write weekly journal", false),
            ("todo-21", "Stretch after workout", false),
            ("todo-22", "Order printer ink", true),
            ("todo-23", "Fix bike tire", false),
            ("todo-24", "Watch WWDC session", false),
            ("todo-25", "Donate old clothes", false)
        ]

        items.append(contentsOf: extras.map { id, title, isCompleted in
            TodoItem(id: id, title: title, isCompleted: isCompleted)
        })
        return items
    }()
}
