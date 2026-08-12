//
//  TodoListPaginationTests.swift
//  TodoListIOSTests
//

import Foundation
import Testing
@testable import TodoListIOS

@MainActor
struct TodoListPaginationTests {

    @Test
    func initialLoadShowsOnlyFirstPage() async {
        let viewModel = makeViewModel(itemCount: 25, pageSize: 10)
        await viewModel.loadTodos()

        #expect(viewModel.matchingTodos.count == 25)
        #expect(viewModel.filteredTodos.count == 10)
        #expect(viewModel.hasMorePages)
    }

    @Test
    func loadMoreAppendsNextPage() async {
        let viewModel = makeViewModel(itemCount: 25, pageSize: 10)
        await viewModel.loadTodos()

        await viewModel.loadMore()
        #expect(viewModel.filteredTodos.count == 20)
        #expect(viewModel.hasMorePages)

        await viewModel.loadMore()
        #expect(viewModel.filteredTodos.count == 25)
        #expect(!viewModel.hasMorePages)
    }

    @Test
    func searchResetsPaginationToFirstPageOfMatches() async {
        let todos = (1...30).map { index in
            TodoItem(
                id: "\(index)",
                title: index <= 15 ? "Alpha \(index)" : "Beta \(index)",
                isCompleted: false
            )
        }
        let viewModel = TodoListViewModel(
            store: MockTodoStore(todos: todos),
            searchDebounceNanoseconds: 20_000_000,
            pageSize: 5
        )
        await viewModel.loadTodos()
        await viewModel.loadMore()
        #expect(viewModel.filteredTodos.count == 10)

        viewModel.searchText = "alpha"
        await waitForDebounce()

        #expect(viewModel.matchingTodos.count == 15)
        #expect(viewModel.filteredTodos.count == 5)
        #expect(viewModel.hasMorePages)

        await viewModel.loadMore()
        #expect(viewModel.filteredTodos.count == 10)
    }

    @Test
    func statusFilterResetsPagination() async {
        let todos = (1...20).map { index in
            TodoItem(
                id: "\(index)",
                title: "Task \(index)",
                isCompleted: index > 12
            )
        }
        let viewModel = TodoListViewModel(
            store: MockTodoStore(todos: todos),
            searchDebounceNanoseconds: 20_000_000,
            pageSize: 5
        )
        await viewModel.loadTodos()
        await viewModel.loadMore()
        #expect(viewModel.filteredTodos.count == 10)

        viewModel.statusFilter = .completed

        #expect(viewModel.matchingTodos.count == 8)
        #expect(viewModel.filteredTodos.count == 5)
        #expect(viewModel.hasMorePages)
    }

    @Test
    func loadMoreIfNeededTriggersNearEnd() async {
        let viewModel = makeViewModel(itemCount: 15, pageSize: 5)
        await viewModel.loadTodos()

        let nearEnd = viewModel.filteredTodos[3]
        await viewModel.loadMoreIfNeeded(currentItem: nearEnd)

        #expect(viewModel.filteredTodos.count == 10)
    }

    private func makeViewModel(itemCount: Int, pageSize: Int) -> TodoListViewModel {
        let todos = (1...itemCount).map { index in
            TodoItem(id: "\(index)", title: "Task \(index)", isCompleted: false)
        }
        return TodoListViewModel(
            store: MockTodoStore(todos: todos),
            searchDebounceNanoseconds: 20_000_000,
            pageSize: pageSize
        )
    }

    private func waitForDebounce() async {
        try? await Task.sleep(nanoseconds: 40_000_000)
    }
}
