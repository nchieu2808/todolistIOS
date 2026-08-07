//
//  FakeTodoAPI.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 7/8/26.
//

import Foundation

protocol TodoAPI {
    func fetchTodos() async throws -> [TodoItem]
    func createTodo(_ draft: TodoDraft) async throws -> TodoItem
    func updateTodo(_ todo: TodoItem) async throws -> TodoItem
    func deleteTodo(id: String) async throws
}

struct TodoDraft {
    var title: String
    var todoDescription: String?
    var dueDate: Date?
    var imageUrl: String?
}

enum TodoAPIError: LocalizedError {
    case notFound
    case invalidTitle

    var errorDescription: String? {
        switch self {
        case .notFound:
            "Todo not found."
        case .invalidTitle:
            "Title can’t be empty."
        }
    }
}

/// In-memory fake backend with a short delay to simulate networking.
@MainActor
final class FakeTodoAPI: TodoAPI {
    static let shared = FakeTodoAPI()

    private var todos: [TodoItem]
    private let delayNanoseconds: UInt64

    init(
        initialTodos: [TodoItem] = FakeTodoAPI.sampleTodos,
        delayNanoseconds: UInt64 = 450_000_000
    ) {
        self.todos = initialTodos
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchTodos() async throws -> [TodoItem] {
        try await simulateNetwork()
        return todos.sortedForDisplay()
    }

    func createTodo(_ draft: TodoDraft) async throws -> TodoItem {
        try await simulateNetwork()
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw TodoAPIError.invalidTitle }

        let description = draft.todoDescription?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let todo = TodoItem(
            id: UUID().uuidString,
            title: title,
            todoDescription: (description?.isEmpty == false) ? description : nil,
            isCompleted: false,
            imageUrl: draft.imageUrl,
            dueDate: draft.dueDate.map(TodoItem.milliseconds(from:))
        )
        todos.insert(todo, at: 0)
        return todo
    }

    func updateTodo(_ todo: TodoItem) async throws -> TodoItem {
        try await simulateNetwork()
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
            throw TodoAPIError.notFound
        }
        todos[index] = todo
        return todo
    }

    func deleteTodo(id: String) async throws {
        try await simulateNetwork()
        guard todos.contains(where: { $0.id == id }) else {
            throw TodoAPIError.notFound
        }
        todos.removeAll { $0.id == id }
    }

    private func simulateNetwork() async throws {
        try await Task.sleep(nanoseconds: delayNanoseconds)
    }

    static let sampleTodos: [TodoItem] = {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        return [
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
                todoDescription: "Wire list screen to the fake API and polish the UI",
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
    }()
}
