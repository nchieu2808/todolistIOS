//
//  TodoListViewModel.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 7/8/26.
//

import Foundation
import Observation
import SwiftUI

enum TodoStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case completed

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All"
        case .pending: "Pending"
        case .completed: "Completed"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "list.bullet"
        case .pending: "circle"
        case .completed: "checkmark.circle"
        }
    }

    func matches(_ todo: TodoItem) -> Bool {
        switch self {
        case .all: true
        case .pending: !todo.isCompleted
        case .completed: todo.isCompleted
        }
    }
}

@Observable
@MainActor
final class TodoListViewModel {
    private(set) var todos: [TodoItem] = []
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var isLoadingMore = false
    /// Debounced query used for filtering. Updates after `searchDebounceNanoseconds`.
    private(set) var activeQuery = ""
    /// How many matching todos are currently visible (grows via `loadMore`).
    private(set) var displayedCount = 0
    var errorMessage: String?
    /// Status dropdown filter: all, pending, or completed.
    var statusFilter: TodoStatusFilter = .all {
        didSet {
            guard oldValue != statusFilter else { return }
            resetPagination()
        }
    }
    /// Immediate search-field text. Filtering waits for debounce.
    var searchText = "" {
        didSet { scheduleSearchDebounce() }
    }

    /// Full match set for the active search + status filter (not paginated).
    var matchingTodos: [TodoItem] {
        let query = activeQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return todos.filter { todo in
            statusFilter.matches(todo)
                && (query.isEmpty || todo.matchesSearch(query))
        }
    }

    /// Visible page of `matchingTodos`.
    var filteredTodos: [TodoItem] {
        Array(matchingTodos.prefix(displayedCount))
    }

    var hasMorePages: Bool {
        displayedCount < matchingTodos.count
    }

    private let store: any TodoStoring
    private let searchDebounceNanoseconds: UInt64
    private let pageSize: Int
    private var searchDebounceTask: Task<Void, Never>?

    init(
        store: any TodoStoring,
        searchDebounceNanoseconds: UInt64 = 300_000_000,
        pageSize: Int = 10
    ) {
        self.store = store
        self.searchDebounceNanoseconds = searchDebounceNanoseconds
        self.pageSize = max(pageSize, 1)
        self.displayedCount = self.pageSize
    }

    func loadTodos() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            todos = try store.load().sortedForDisplay()
            resetPagination()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTodo(_ draft: TodoDraft) async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { throw TodoStoreError.invalidTitle }

            let description = draft.todoDescription?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let created = TodoItem(
                id: UUID().uuidString,
                title: title,
                todoDescription: (description?.isEmpty == false) ? description : nil,
                isCompleted: false,
                imageUrl: draft.imageUrl,
                dueDate: draft.dueDate.map(TodoItem.milliseconds(from:))
            )

            var next = todos
            next.insert(created, at: 0)
            try store.save(next)

            withAnimation(Self.listAnimation) {
                todos = next.sortedForDisplay()
                resetPagination()
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func toggleCompleted(_ todo: TodoItem) async {
        guard todos.contains(where: { $0.id == todo.id }) else { return }

        var updated = todo
        updated.isCompleted.toggle()

        withAnimation(Self.listAnimation) {
            apply(updated)
        }

        do {
            try store.save(todos)
        } catch {
            withAnimation(Self.listAnimation) {
                apply(todo)
            }
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes items at offsets in `filteredTodos`, then persists the full list.
    func deleteTodos(at offsets: IndexSet) async {
        let idsToDelete = Set(offsets.compactMap { offset -> String? in
            guard filteredTodos.indices.contains(offset) else { return nil }
            return filteredTodos[offset].id
        })
        guard !idsToDelete.isEmpty else { return }

        let previous = todos
        let previousDisplayedCount = displayedCount

        withAnimation(Self.listAnimation) {
            todos = todos.filter { !idsToDelete.contains($0.id) }
            clampDisplayedCount()
        }

        do {
            try store.save(todos)
        } catch {
            withAnimation(Self.listAnimation) {
                todos = previous
                displayedCount = previousDisplayedCount
            }
            errorMessage = error.localizedDescription
        }
    }

    /// Loads the next page when `currentItem` is near the end of the visible list.
    func loadMoreIfNeeded(currentItem: TodoItem) async {
        guard hasMorePages,
              let index = filteredTodos.firstIndex(where: { $0.id == currentItem.id }),
              index >= filteredTodos.count - 2
        else { return }
        await loadMore()
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        // Brief yield so the footer spinner can appear during pagination.
        try? await Task.sleep(nanoseconds: 150_000_000)
        guard !Task.isCancelled else { return }

        displayedCount = min(displayedCount + pageSize, matchingTodos.count)
    }

    private func scheduleSearchDebounce() {
        searchDebounceTask?.cancel()
        let pending = searchText
        let delay = searchDebounceNanoseconds
        searchDebounceTask = Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            activeQuery = pending
            resetPagination()
        }
    }

    private func resetPagination() {
        displayedCount = min(pageSize, matchingTodos.count)
    }

    private func clampDisplayedCount() {
        if matchingTodos.isEmpty {
            displayedCount = 0
        } else {
            displayedCount = min(max(displayedCount, min(pageSize, matchingTodos.count)), matchingTodos.count)
        }
    }

    private func apply(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index] = todo
        todos = todos.sortedForDisplay()
        clampDisplayedCount()
    }

    private static let listAnimation = Animation.snappy(duration: 0.28, extraBounce: 0.05)
}

extension TodoItem {
    func matchesSearch(_ query: String) -> Bool {
        if title.localizedCaseInsensitiveContains(query) {
            return true
        }
        if let todoDescription, todoDescription.localizedCaseInsensitiveContains(query) {
            return true
        }
        return false
    }
}
