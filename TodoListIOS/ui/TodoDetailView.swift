//
//  TodoDetailView.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 8/8/26.
//

import SwiftUI

struct TodoDetailView: View {
    let todo: TodoItem
    let onToggleCompleted: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let imageUrl = todo.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            imagePlaceholder
                        default:
                            ZStack {
                                Color(.secondarySystemBackground)
                                ProgressView()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(todo.title)
                        .font(.largeTitle.bold())
                        .strikethrough(todo.isCompleted)
                        .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                    Button(action: onToggleCompleted) {
                        Label(
                            todo.isCompleted ? "Completed" : "Incomplete",
                            systemImage: todo.isCompleted
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(todo.isCompleted ? .green : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                        .animation(.snappy(duration: 0.2), value: todo.isCompleted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        todo.isCompleted ? "Mark incomplete" : "Mark complete"
                    )
                }

                if let description = todo.todoDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                if let dueDate = todo.dueDateValue {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due")
                            .font(.headline)
                        Label(
                            dueDate.formatted(date: .complete, time: .shortened),
                            systemImage: "calendar"
                        )
                        .font(.body)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }

    private var imagePlaceholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        TodoDetailView(
            todo: TodoItem.sampleTodos[0],
            onToggleCompleted: {}
        )
    }
}
