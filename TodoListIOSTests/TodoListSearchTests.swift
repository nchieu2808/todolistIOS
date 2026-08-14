//
//  TodoListSearchTests.swift
//  TodoListIOSTests
//

import Foundation
import Testing
@testable import TodoListIOS

@MainActor
struct TodoListSearchTests {

    @Test
    func searchFiltersByTitleAfterDebounce() async {
        let viewModel = makeViewModel(todos: [
            TodoItem(id: "1", title: "Buy milk", isCompleted: false),
            TodoItem(id: "2", title: "Call mom", isCompleted: false),
            TodoItem(id: "3", title: "Buy coffee", isCompleted: true)
        ])
        await viewModel.loadTodos()

        viewModel.searchText = "buy"
        #expect(viewModel.activeQuery.isEmpty)
        #expect(viewModel.filteredTodos.count == 3)

        await waitForDebounce(viewModel, query: "buy")

        #expect(viewModel.activeQuery == "buy")
        #expect(viewModel.filteredTodos.map(\.id) == ["1", "3"])
    }

    @Test
    func searchFiltersByDescription() async {
        let viewModel = makeViewModel(todos: [
            TodoItem(
                id: "1",
                title: "Errand",
                todoDescription: "Pick up dry cleaning",
                isCompleted: false
            ),
            TodoItem(id: "2", title: "Workout", isCompleted: false)
        ])
        await viewModel.loadTodos()

        viewModel.searchText = "cleaning"
        await waitForDebounce(viewModel, query: "cleaning")

        #expect(viewModel.filteredTodos.map(\.id) == ["1"])
    }

    @Test
    func rapidTypingKeepsOnlyLatestQuery() async {
        let viewModel = makeViewModel(todos: [
            TodoItem(id: "1", title: "Alpha", isCompleted: false),
            TodoItem(id: "2", title: "Beta", isCompleted: false),
            TodoItem(id: "3", title: "Alpine", isCompleted: false)
        ])
        await viewModel.loadTodos()

        viewModel.searchText = "a"
        viewModel.searchText = "al"
        viewModel.searchText = "alp"
        await waitForDebounce(viewModel, query: "alp")

        #expect(viewModel.activeQuery == "alp")
        #expect(viewModel.filteredTodos.map(\.id).sorted() == ["1", "3"])
    }

    @Test
    func clearingSearchShowsAllTodos() async {
        let viewModel = makeViewModel(todos: [
            TodoItem(id: "1", title: "Alpha", isCompleted: false),
            TodoItem(id: "2", title: "Beta", isCompleted: false)
        ])
        await viewModel.loadTodos()

        viewModel.searchText = "alpha"
        await waitForDebounce(viewModel, query: "alpha")
        #expect(viewModel.filteredTodos.map(\.id) == ["1"])

        viewModel.searchText = ""
        await waitForDebounce(viewModel, query: "")

        #expect(viewModel.activeQuery.isEmpty)
        #expect(viewModel.filteredTodos.map(\.id).sorted() == ["1", "2"])
    }

    @Test
    func deleteUsesFilteredOffsets() async {
        let store = MockTodoStore(todos: [
            TodoItem(id: "1", title: "Alpha", isCompleted: false),
            TodoItem(id: "2", title: "Beta", isCompleted: false),
            TodoItem(id: "3", title: "Alpine", isCompleted: false)
        ])
        let viewModel = TodoListViewModel(
            store: store,
            searchDebounceNanoseconds: 20_000_000
        )
        await viewModel.loadTodos()

        viewModel.searchText = "alp"
        await waitForDebounce(viewModel, query: "alp")
        #expect(viewModel.filteredTodos.map(\.id).sorted() == ["1", "3"])

        // Delete first filtered row ("Alpha" or "Alpine" depending on sort).
        let deletedID = viewModel.filteredTodos[0].id
        await viewModel.deleteTodos(at: IndexSet(integer: 0))

        #expect(!viewModel.todos.contains(where: { $0.id == deletedID }))
        #expect(store.todos.map(\.id).sorted() == viewModel.todos.map(\.id).sorted())
        #expect(viewModel.todos.count == 2)
    }

    private func makeViewModel(todos: [TodoItem]) -> TodoListViewModel {
        TodoListViewModel(
            store: MockTodoStore(todos: todos),
            searchDebounceNanoseconds: 20_000_000
        )
    }

    private func waitForDebounce(_ viewModel: TodoListViewModel, query: String) async {
        let deadline = ContinuousClock.now + .seconds(1)
        while viewModel.activeQuery != query, ContinuousClock.now < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
