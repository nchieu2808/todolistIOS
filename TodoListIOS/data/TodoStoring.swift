//
//  TodoStoring.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 8/8/26.
//

import Foundation

/// Abstraction over todo persistence so callers depend on a protocol, not a concrete store.
protocol TodoStoring {
    func load() throws -> [TodoItem]
    func save(_ todos: [TodoItem]) throws
}

struct TodoDraft {
    var title: String
    var todoDescription: String?
    var dueDate: Date?
    var imageUrl: String?
}

enum TodoStoreError: LocalizedError {
    case invalidTitle
    case persistenceFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidTitle:
            "Title can’t be empty."
        case .persistenceFailed(let underlying):
            "Could not save todos: \(underlying.localizedDescription)"
        }
    }
}
