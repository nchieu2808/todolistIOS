//
//  TodoListView.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 7/8/26.
//

import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.title) private var todos: [TodoItem]

    var body: some View {
        NavigationStack {
            Group {
                if todos.isEmpty {
                    ContentUnavailableView(
                        "No Todos",
                        systemImage: "checklist",
                        description: Text("Tap + to add your first todo.")
                    )
                } else {
                    List {
                        ForEach(todos) { todo in
                            TodoRowView(todo: todo)
                        }
                        .onDelete(perform: deleteTodos)
                    }
                }
            }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addTodo) {
                        Label("Add Todo", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addTodo() {
        withAnimation {
            let todo = TodoItem(
                id: UUID().uuidString,
                title: "New Todo",
                todoDescription: nil,
                isCompleted: false
            )
            modelContext.insert(todo)
        }
    }

    private func deleteTodos(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(todos[index])
            }
        }
    }
}

private struct TodoRowView: View {
    @Bindable var todo: TodoItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                todo.isCompleted.toggle()
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.headline)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                if let description = todo.todoDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let dueDate = todo.dueDateValue {
                    Label(dueDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

private extension TodoItem {
    var dueDateValue: Date? {
        guard let dueDate else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(dueDate) / 1000)
    }
}

#Preview {
    TodoListView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
