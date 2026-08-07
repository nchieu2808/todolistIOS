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
