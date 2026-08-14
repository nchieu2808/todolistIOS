//
//  TodoCoreDataStore.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 14/8/26.
//

import CoreData
import Foundation

/// Reads and writes todos with Core Data (SQLite, or an in-memory store for previews/tests).
final class TodoCoreDataStore: TodoStoring {
    let storeURL: URL?
    let isInMemory: Bool

    private let container: NSPersistentContainer
    private let seedTodos: [TodoItem]
    private let legacyJSONURL: URL?
    private var didLoadStore = false
    private var storeLoadError: Error?

    private var context: NSManagedObjectContext {
        container.viewContext
    }

    init(
        storeURL: URL? = TodoCoreDataStore.defaultStoreURL,
        inMemory: Bool = false,
        seedTodos: [TodoItem] = TodoItem.sampleTodos,
        legacyJSONURL: URL? = nil
    ) {
        self.isInMemory = inMemory
        self.storeURL = inMemory ? nil : storeURL
        self.seedTodos = seedTodos
        self.legacyJSONURL = legacyJSONURL
        self.container = TodoCoreDataStore.makeContainer(
            storeURL: storeURL,
            inMemory: inMemory
        )
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Loads todos from Core Data, importing leftover JSON or seeding samples when empty.
    func load() throws -> [TodoItem] {
        try loadStoreIfNeeded()

        let existing = try fetchItems()
        if !existing.isEmpty {
            return existing
        }

        if let imported = importLegacyJSONIfPresent() {
            try persist(imported)
            if let legacyJSONURL {
                try? FileManager.default.removeItem(at: legacyJSONURL)
            }
            return imported
        }

        if !seedTodos.isEmpty {
            try persist(seedTodos)
            return seedTodos
        }

        return []
    }

    func save(_ todos: [TodoItem]) throws {
        try loadStoreIfNeeded()
        try persist(todos)
    }

    private func persist(_ todos: [TodoItem]) throws {
        let existing = try fetchEntities()
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let incomingIDs = Set(todos.map(\.id))

        for item in todos {
            let entity = existingByID[item.id] ?? TodoEntity(context: context)
            apply(item, to: entity)
        }

        for entity in existing where !incomingIDs.contains(entity.id) {
            context.delete(entity)
        }

        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            context.rollback()
            throw TodoStoreError.persistenceFailed(underlying: error)
        }
    }

    private func fetchItems() throws -> [TodoItem] {
        try fetchEntities().map(makeItem(from:))
    }

    private func makeItem(from entity: TodoEntity) -> TodoItem {
        TodoItem(
            id: entity.id,
            title: entity.title,
            todoDescription: entity.todoDescription,
            isCompleted: entity.isCompleted,
            imageUrl: entity.imageUrl,
            dueDate: entity.dueDate?.int64Value
        )
    }

    private func apply(_ item: TodoItem, to entity: TodoEntity) {
        entity.id = item.id
        entity.title = item.title
        entity.todoDescription = item.todoDescription
        entity.isCompleted = item.isCompleted
        entity.imageUrl = item.imageUrl
        entity.dueDate = item.dueDate.map { NSNumber(value: $0) }
    }

    private func fetchEntities() throws -> [TodoEntity] {
        let request = NSFetchRequest<TodoEntity>(entityName: "TodoEntity")
        do {
            return try context.fetch(request)
        } catch {
            throw TodoStoreError.persistenceFailed(underlying: error)
        }
    }

    private func importLegacyJSONIfPresent() -> [TodoItem]? {
        guard let legacyJSONURL,
              FileManager.default.fileExists(atPath: legacyJSONURL.path)
        else { return nil }

        guard let data = try? Data(contentsOf: legacyJSONURL),
              let items = try? JSONDecoder().decode([TodoItem].self, from: data)
        else { return nil }

        return items
    }

    private func loadStoreIfNeeded() throws {
        if let storeLoadError {
            throw TodoStoreError.persistenceFailed(underlying: storeLoadError)
        }
        guard !didLoadStore else { return }

        if let storeURL {
            let directory = storeURL.deletingLastPathComponent()
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            } catch {
                throw TodoStoreError.persistenceFailed(underlying: error)
            }
        }

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            storeLoadError = loadError
            throw TodoStoreError.persistenceFailed(underlying: loadError)
        }
        didLoadStore = true
    }

    static var defaultStoreURL: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documents.appendingPathComponent("TodoList.sqlite", isDirectory: false)
    }

    static var legacyJSONFileURL: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documents.appendingPathComponent("item.json", isDirectory: false)
    }

    private static func makeContainer(
        storeURL: URL?,
        inMemory: Bool
    ) -> NSPersistentContainer {
        let container = NSPersistentContainer(
            name: "TodoList",
            managedObjectModel: makeManagedObjectModel()
        )
        let description = NSPersistentStoreDescription()
        if inMemory {
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null/\(UUID().uuidString)")
        } else {
            description.type = NSSQLiteStoreType
            description.url = storeURL ?? defaultStoreURL
        }
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        return container
    }

    /// Builds a fresh in-memory model per container. Compiled `.momd` files are immutable,
    /// so the schema is constructed in code instead of mutating the bundled model.
    static func makeManagedObjectModel() -> NSManagedObjectModel {
        makeProgrammaticModel()
    }

    private static func makeProgrammaticModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "TodoEntity"
        entity.managedObjectClassName = NSStringFromClass(TodoEntity.self)

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .stringAttributeType
        id.isOptional = false

        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = false

        let todoDescription = NSAttributeDescription()
        todoDescription.name = "todoDescription"
        todoDescription.attributeType = .stringAttributeType
        todoDescription.isOptional = true

        let isCompleted = NSAttributeDescription()
        isCompleted.name = "isCompleted"
        isCompleted.attributeType = .booleanAttributeType
        isCompleted.isOptional = false
        isCompleted.defaultValue = false

        let imageUrl = NSAttributeDescription()
        imageUrl.name = "imageUrl"
        imageUrl.attributeType = .stringAttributeType
        imageUrl.isOptional = true

        let dueDate = NSAttributeDescription()
        dueDate.name = "dueDate"
        dueDate.attributeType = .integer64AttributeType
        dueDate.isOptional = true

        entity.properties = [id, title, todoDescription, isCompleted, imageUrl, dueDate]
        model.entities = [entity]
        return model
    }
}
