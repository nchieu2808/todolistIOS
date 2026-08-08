//
//  MockTodoStore.swift
//  TodoListIOSTests
//

import Foundation
@testable import TodoListIOS

/// In-memory `TodoStoring` double for DI and ViewModel tests.
final class MockTodoStore: TodoStoring {
    var todos: [TodoItem]
    private(set) var loadCallCount = 0
    private(set) var saveCallCount = 0
    var loadError: Error?
    var saveError: Error?

    init(todos: [TodoItem] = []) {
        self.todos = todos
    }

    func load() throws -> [TodoItem] {
        loadCallCount += 1
        if let loadError { throw loadError }
        return todos
    }

    func save(_ todos: [TodoItem]) throws {
        saveCallCount += 1
        if let saveError { throw saveError }
        self.todos = todos
    }
}
