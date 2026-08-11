//
//  TodoStatusFilterTests.swift
//  TodoListIOSTests
//

import Foundation
import Testing
@testable import TodoListIOS

@MainActor
struct TodoStatusFilterTests {

    @Test
    func statusFilterShowsPendingOnly() async {
        let viewModel = makeViewModel()
        await viewModel.loadTodos()

        viewModel.statusFilter = .pending

        #expect(viewModel.filteredTodos.map(\.id) == ["1", "2"])
        #expect(viewModel.filteredTodos.allSatisfy { !$0.isCompleted })
    }

    @Test
    func statusFilterShowsCompletedOnly() async {
        let viewModel = makeViewModel()
        await viewModel.loadTodos()

        viewModel.statusFilter = .completed

        #expect(viewModel.filteredTodos.map(\.id) == ["3"])
        #expect(viewModel.filteredTodos.allSatisfy { $0.isCompleted })
    }

    @Test
    func statusFilterAllShowsEveryTodo() async {
        let viewModel = makeViewModel()
        await viewModel.loadTodos()

        viewModel.statusFilter = .completed
        viewModel.statusFilter = .all

        #expect(viewModel.filteredTodos.map(\.id).sorted() == ["1", "2", "3"])
    }

    @Test
    func statusFilterCombinesWithSearch() async {
        let viewModel = makeViewModel()
        await viewModel.loadTodos()

        viewModel.statusFilter = .pending
        viewModel.searchText = "buy"
        try? await Task.sleep(nanoseconds: 40_000_000)

        #expect(viewModel.filteredTodos.map(\.id) == ["1"])
    }

    private func makeViewModel() -> TodoListViewModel {
        TodoListViewModel(
            store: MockTodoStore(todos: [
                TodoItem(id: "1", title: "Buy milk", isCompleted: false),
                TodoItem(id: "2", title: "Call mom", isCompleted: false),
                TodoItem(id: "3", title: "Buy coffee", isCompleted: true)
            ]),
            searchDebounceNanoseconds: 20_000_000
        )
    }
}
