//
//  TodoCoreDataStoreTests.swift
//  TodoListIOSTests
//

import Foundation
import Testing
@testable import TodoListIOS

@MainActor
struct TodoCoreDataStoreTests {

    @Test
    func loadSeedsWhenStoreIsEmpty() throws {
        let storeURL = uniqueStoreURL()
        defer { removeSQLiteStore(at: storeURL) }

        let store = TodoCoreDataStore(
            storeURL: storeURL,
            seedTodos: [
                TodoItem(id: "seed", title: "Seeded", isCompleted: false)
            ]
        )

        let loaded = try store.load()
        #expect(loaded.map(\.id) == ["seed"])
    }

    @Test
    func loadDoesNotReseedWhenDataExists() throws {
        let storeURL = uniqueStoreURL()
        defer { removeSQLiteStore(at: storeURL) }

        let first = TodoCoreDataStore(
            storeURL: storeURL,
            seedTodos: [TodoItem(id: "a", title: "Alpha", isCompleted: false)]
        )
        #expect(try first.load().map(\.id) == ["a"])

        let second = TodoCoreDataStore(
            storeURL: storeURL,
            seedTodos: [TodoItem(id: "b", title: "Should not appear", isCompleted: false)]
        )
        #expect(try second.load().map(\.id) == ["a"])
    }

    @Test
    func saveRoundTripsAllFields() throws {
        let storeURL = uniqueStoreURL()
        defer { removeSQLiteStore(at: storeURL) }

        let store = TodoCoreDataStore(storeURL: storeURL, seedTodos: [])
        _ = try store.load()

        let due = TodoItem.milliseconds(from: Date(timeIntervalSince1970: 1_700_000_000))
        let item = TodoItem(
            id: "full",
            title: "Full item",
            todoDescription: "Details",
            isCompleted: true,
            imageUrl: "https://example.com/todo.png",
            dueDate: due
        )
        try store.save([item])

        let loaded = try store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].id == "full")
        #expect(loaded[0].title == "Full item")
        #expect(loaded[0].todoDescription == "Details")
        #expect(loaded[0].isCompleted == true)
        #expect(loaded[0].imageUrl == "https://example.com/todo.png")
        #expect(loaded[0].dueDate == due)
    }

    @Test
    func saveDeletesItemsMissingFromTheNewList() throws {
        let storeURL = uniqueStoreURL()
        defer { removeSQLiteStore(at: storeURL) }

        let store = TodoCoreDataStore(
            storeURL: storeURL,
            seedTodos: [
                TodoItem(id: "keep", title: "Keep", isCompleted: false),
                TodoItem(id: "drop", title: "Drop", isCompleted: false)
            ]
        )
        var todos = try store.load()
        todos.removeAll { $0.id == "drop" }
        try store.save(todos)

        #expect(try store.load().map(\.id) == ["keep"])
    }

    @Test
    func sqliteChangesSurviveANewStoreInstance() throws {
        let storeURL = uniqueStoreURL()
        defer { removeSQLiteStore(at: storeURL) }

        let first = TodoCoreDataStore(storeURL: storeURL, seedTodos: [])
        try first.save([
            TodoItem(id: "persisted", title: "Persisted", isCompleted: false)
        ])

        let second = TodoCoreDataStore(storeURL: storeURL, seedTodos: [])
        #expect(try second.load().map(\.id) == ["persisted"])
    }
}

private func uniqueStoreURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("todos-\(UUID().uuidString).sqlite")
}
