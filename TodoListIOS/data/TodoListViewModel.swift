//
//  TodoListViewModel.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 7/8/26.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class TodoListViewModel {
    private(set) var todos: [TodoItem] = []
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?

    private let api: any TodoAPI

    init(api: any TodoAPI = FakeTodoAPI.shared) {
        self.api = api
    }

    func loadTodos() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            todos = try await api.fetchTodos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTodo(_ draft: TodoDraft) async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let created = try await api.createTodo(draft)
            withAnimation(Self.listAnimation) {
                todos.insert(created, at: 0)
                todos = todos.sortedForDisplay()
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

        // Re-sort immediately so the row moves without waiting on the network.
        withAnimation(Self.listAnimation) {
            apply(updated)
        }

        do {
            _ = try await api.updateTodo(updated)
        } catch {
            withAnimation(Self.listAnimation) {
                apply(todo)
            }
            errorMessage = error.localizedDescription
        }
    }

    func deleteTodos(at offsets: IndexSet) async {
        let ids = offsets.map { todos[$0].id }

        withAnimation(Self.listAnimation) {
            todos = todos.enumerated().compactMap { offset, item in
                offsets.contains(offset) ? nil : item
            }
        }

        for id in ids {
            do {
                try await api.deleteTodo(id: id)
            } catch {
                errorMessage = error.localizedDescription
                todos = (try? await api.fetchTodos()) ?? todos
                break
            }
        }
    }

    private func apply(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index] = todo
        todos = todos.sortedForDisplay()
    }

    private static let listAnimation = Animation.snappy(duration: 0.28, extraBounce: 0.05)
}
