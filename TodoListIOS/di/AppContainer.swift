//
//  AppContainer.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 8/8/26.
//

import Foundation
import SwiftUI

/// Composition root that owns shared dependencies and builds feature objects.
@MainActor
final class AppContainer {
    let todoStore: any TodoStoring

    init(todoStore: any TodoStoring) {
        self.todoStore = todoStore
    }

    func makeTodoListViewModel() -> TodoListViewModel {
        TodoListViewModel(store: todoStore)
    }
}

extension AppContainer {
    static let live = AppContainer(
        todoStore: TodoCoreDataStore(
            storeURL: TodoCoreDataStore.defaultStoreURL,
            seedTodos: TodoItem.sampleTodos,
            legacyJSONURL: TodoCoreDataStore.legacyJSONFileURL
        )
    )

    static var preview: AppContainer {
        AppContainer(
            todoStore: TodoCoreDataStore(
                inMemory: true,
                seedTodos: TodoItem.sampleTodos
            )
        )
    }

    static func testing(
        storeURL: URL,
        seedTodos: [TodoItem]
    ) -> AppContainer {
        AppContainer(
            todoStore: TodoCoreDataStore(
                storeURL: storeURL,
                seedTodos: seedTodos
            )
        )
    }
}

private struct AppContainerKey: EnvironmentKey {
    @MainActor static let defaultValue = AppContainer.live
}

extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}

extension View {
    func appContainer(_ container: AppContainer) -> some View {
        environment(\.appContainer, container)
    }
}
