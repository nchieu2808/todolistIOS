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
    func testingFactoryWiresCoreDataStoreWithSeed() async throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("todos-di-\(UUID().uuidString).sqlite")
        defer { removeSQLiteStore(at: storeURL) }

        let seed = [TodoItem(id: "seed", title: "Seeded", isCompleted: false)]
        let container = AppContainer.testing(storeURL: storeURL, seedTodos: seed)

        let coreDataStore = try #require(container.todoStore as? TodoCoreDataStore)
        #expect(coreDataStore.storeURL == storeURL)

        let viewModel = container.makeTodoListViewModel()
        await viewModel.loadTodos()

        #expect(viewModel.todos.map(\.id) == ["seed"])
        #expect(FileManager.default.fileExists(atPath: storeURL.path))
    }

    @Test
    func liveUsesDefaultCoreDataStore() throws {
        let container = AppContainer.live
        let store = try #require(container.todoStore as? TodoCoreDataStore)
        #expect(store.storeURL == TodoCoreDataStore.defaultStoreURL)
    }

    @Test
    func previewUsesTemporarySQLiteStore() async throws {
        let previewURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("todos-preview.sqlite")
        removeSQLiteStore(at: previewURL)

        let container = AppContainer.preview
        let store = try #require(container.todoStore as? TodoCoreDataStore)
        #expect(store.storeURL == previewURL)

        let viewModel = container.makeTodoListViewModel()
        await viewModel.loadTodos()

        #expect(viewModel.todos.isEmpty)

        removeSQLiteStore(at: previewURL)
    }
}
