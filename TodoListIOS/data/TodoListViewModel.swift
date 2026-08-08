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

    private let store: any TodoStoring

    init(store: any TodoStoring) {
        self.store = store
    }

    func loadTodos() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            todos = try store.load().sortedForDisplay()
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

    func deleteTodos(at offsets: IndexSet) async {
        let previous = todos

        withAnimation(Self.listAnimation) {
            todos = todos.enumerated().compactMap { offset, item in
                offsets.contains(offset) ? nil : item
            }
        }

        do {
            try store.save(todos)
        } catch {
            withAnimation(Self.listAnimation) {
                todos = previous
            }
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index] = todo
        todos = todos.sortedForDisplay()
    }

    private static let listAnimation = Animation.snappy(duration: 0.28, extraBounce: 0.05)
}
