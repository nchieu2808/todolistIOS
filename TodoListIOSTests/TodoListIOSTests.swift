//
//  TodoListIOSTests.swift
//  TodoListIOSTests
//
//  Created by Nguyễn Chí Hiếu on 1/8/26.
//

import Foundation
import Testing
@testable import TodoListIOS

struct TodoListIOSTests {

    @Test @MainActor
    func containerInjectsStoreIntoViewModelPersistence() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("todos-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let seed = [
            TodoItem(id: "a", title: "Alpha", isCompleted: false),
            TodoItem(id: "b", title: "Beta", isCompleted: true)
        ]
        let container = AppContainer.testing(fileURL: fileURL, seedTodos: seed)

        let viewModel = container.makeTodoListViewModel()
        await viewModel.loadTodos()
        #expect(viewModel.todos.map(\.id).sorted() == ["a", "b"])

        let didAdd = await viewModel.addTodo(
            TodoDraft(title: "Gamma", todoDescription: "From test")
        )
        #expect(didAdd)
        let createdID = viewModel.todos.first(where: { $0.title == "Gamma" })?.id
        #expect(createdID != nil)

        if let alpha = viewModel.todos.first(where: { $0.id == "a" }) {
            await viewModel.toggleCompleted(alpha)
        }

        if let betaIndex = viewModel.todos.firstIndex(where: { $0.id == "b" }) {
            await viewModel.deleteTodos(at: IndexSet(integer: betaIndex))
        }

        let reloaded = AppContainer.testing(fileURL: fileURL, seedTodos: [])
            .makeTodoListViewModel()
        await reloaded.loadTodos()

        #expect(reloaded.todos.map(\.id).sorted() == [createdID!, "a"].sorted())
        #expect(reloaded.todos.first(where: { $0.id == "a" })?.isCompleted == true)
        #expect(reloaded.todos.first(where: { $0.id == createdID })?.todoDescription == "From test")
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
