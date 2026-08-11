//
//  AppContainerTests.swift
//  TodoListIOSTests
//

import Foundation
import Testing
@testable import TodoListIOS

@MainActor
struct AppContainerTests {

    @Test
    func initRetainsInjectedStore() {
        let store = MockTodoStore()
        let container = AppContainer(todoStore: store)

        #expect((container.todoStore as? MockTodoStore) === store)
    }

    @Test
    func makeTodoListViewModelUsesInjectedStore() async {
        let seed = [
            TodoItem(id: "1", title: "One", isCompleted: false),
            TodoItem(id: "2", title: "Two", isCompleted: true)
        ]
        let store = MockTodoStore(todos: seed)
        let container = AppContainer(todoStore: store)

        let viewModel = container.makeTodoListViewModel()
        await viewModel.loadTodos()

        #expect(store.loadCallCount == 1)
        #expect(viewModel.todos.map(\.id).sorted() == ["1", "2"])
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func viewModelsFromSameContainerShareStore() async {
        let store = MockTodoStore(todos: [
            TodoItem(id: "shared", title: "Shared", isCompleted: false)
        ])
        let container = AppContainer(todoStore: store)

        let first = container.makeTodoListViewModel()
        let second = container.makeTodoListViewModel()

        await first.loadTodos()
        let didAdd = await first.addTodo(TodoDraft(title: "New from first"))
        #expect(didAdd)

        await second.loadTodos()

        #expect(store.saveCallCount == 1)
        #expect(second.todos.contains(where: { $0.title == "New from first" }))
        #expect(second.todos.contains(where: { $0.id == "shared" }))
    }

    @Test
    func injectedStoreErrorsSurfaceOnViewModel() async {
        let store = MockTodoStore()
        store.loadError = TodoStoreError.persistenceFailed(
            underlying: CocoaError(.fileReadNoSuchFile)
        )
        let container = AppContainer(todoStore: store)

        let viewModel = container.makeTodoListViewModel()
        await viewModel.loadTodos()

        #expect(viewModel.todos.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func testingFactoryWiresJSONStoreWithSeed() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("item-di-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let seed = [TodoItem(id: "seed", title: "Seeded", isCompleted: false)]
        let container = AppContainer.testing(fileURL: fileURL, seedTodos: seed)

        let jsonStore = try #require(container.todoStore as? TodoJSONStore)
        #expect(jsonStore.fileURL == fileURL)

        let viewModel = container.makeTodoListViewModel()
        await viewModel.loadTodos()

        #expect(viewModel.todos.map(\.id) == ["seed"])
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test
    func liveUsesDefaultJSONStore() throws {
        let container = AppContainer.live
        let store = try #require(container.todoStore as? TodoJSONStore)
        #expect(store.fileURL == TodoJSONStore.defaultFileURL)
    }

    @Test
    func previewUsesTemporaryJSONStoreWithSampleTodos() async throws {
        let previewURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("item-preview.json")
        try? FileManager.default.removeItem(at: previewURL)

        let container = AppContainer.preview
        let store = try #require(container.todoStore as? TodoJSONStore)
        #expect(store.fileURL == previewURL)

        let viewModel = container.makeTodoListViewModel()
        await viewModel.loadTodos()

        #expect(viewModel.todos.count == TodoJSONStore.sampleTodos.count)
        #expect(
            Set(viewModel.todos.map(\.id)) == Set(TodoJSONStore.sampleTodos.map(\.id))
        )

        try? FileManager.default.removeItem(at: previewURL)
    }
}
