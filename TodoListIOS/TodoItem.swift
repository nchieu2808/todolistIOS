//
//  TodoItem.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 6/8/26.
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    @Attribute(.unique)
    var id: String
    var title: String
    /// Stored as `description` on Android / Firestore.
    var todoDescription: String?
    var isCompleted: Bool
    var imageUrl: String?
    var dueDate: Int64?

    init(
        id: String = "",
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
}
