//
//  TodoListView.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 7/8/26.
//

import SwiftUI

struct TodoListView: View {
    @State private var viewModel: TodoListViewModel
    @State private var isPresentingAddTodo = false

    init(viewModel: TodoListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.todos.isEmpty {
                    ProgressView("Loading todos…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.todos.isEmpty {
                    ContentUnavailableView(
                        "No Todos",
                        systemImage: "checklist",
                        description: Text("Tap + to add your first todo.")
                    )
                } else if viewModel.filteredTodos.isEmpty {
                    emptyFilteredContent
                } else {
                    List {
                        ForEach(viewModel.filteredTodos) { todo in
                            NavigationLink(value: todo.id) {
                                TodoRowView(todo: todo) {
                                    Task { await viewModel.toggleCompleted(todo) }
                                }
                            }
                            .onAppear {
                                Task { await viewModel.loadMoreIfNeeded(currentItem: todo) }
                            }
                        }
                        .onDelete { offsets in
                            Task { await viewModel.deleteTodos(at: offsets) }
                        }

                        if viewModel.hasMorePages || viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 8)
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .onAppear {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                    .animation(
                        .snappy(duration: 0.28, extraBounce: 0.05),
                        value: viewModel.filteredTodos.map(\.id)
                    )
                }
            }
            .navigationTitle("Todos")
            .searchable(text: $viewModel.searchText, prompt: "Search todos")
            .navigationDestination(for: String.self) { todoID in
                if let todo = viewModel.todos.first(where: { $0.id == todoID }) {
                    TodoDetailView(todo: todo) {
                        Task {
                            guard let current = viewModel.todos.first(where: { $0.id == todoID }) else {
                                return
                            }
                            await viewModel.toggleCompleted(current)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Todo Not Found",
                        systemImage: "checklist",
                        description: Text("This todo may have been deleted.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Show", selection: $viewModel.statusFilter) {
                            ForEach(TodoStatusFilter.allCases) { filter in
                                Label(filter.title, systemImage: filter.systemImage)
                                    .tag(filter)
                            }
                        }
                    } label: {
                        Label(
                            viewModel.statusFilter.title,
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                    .accessibilityLabel("Filter tasks")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAddTodo = true
                    } label: {
                        Label("Add Todo", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddTodo) {
                NavigationStack {
                    AddTodoView { draft in
                        await viewModel.addTodo(draft)
                    }
                }
            }
            .refreshable {
                await viewModel.loadTodos()
            }
            .task {
                await viewModel.loadTodos()
            }
            .alert("Something went wrong", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    @ViewBuilder
    private var emptyFilteredContent: some View {
        let query = viewModel.activeQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            ContentUnavailableView.search(text: viewModel.activeQuery)
        } else {
            ContentUnavailableView(
                "No \(viewModel.statusFilter.title) Todos",
                systemImage: viewModel.statusFilter.systemImage,
                description: Text("Nothing matches this filter right now.")
            )
        }
    }
}

private struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .animation(.snappy(duration: 0.2), value: todo.isCompleted)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(todo.isCompleted ? "Mark incomplete" : "Mark complete")

            if let imageUrl = todo.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    default:
                        ProgressView()
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

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
                    Label(
                        dueDate.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TodoListView(viewModel: AppContainer.preview.makeTodoListViewModel())
}
