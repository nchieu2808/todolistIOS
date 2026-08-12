//
//  TodoJSONStore.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 8/8/26.
//

import Foundation

struct TodoDraft {
    var title: String
    var todoDescription: String?
    var dueDate: Date?
    var imageUrl: String?
}

enum TodoStoreError: LocalizedError {
    case invalidTitle
    case persistenceFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidTitle:
            "Title can’t be empty."
        case .persistenceFailed(let underlying):
            "Could not save todos: \(underlying.localizedDescription)"
        }
    }
}

/// Reads and writes todos as pretty-printed JSON on disk.
struct TodoJSONStore: TodoStoring {
    let fileURL: URL
    private let seedTodos: [TodoItem]

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder = JSONDecoder()

    init(
        fileURL: URL = TodoJSONStore.defaultFileURL,
        seedTodos: [TodoItem] = TodoJSONStore.sampleTodos
    ) {
        self.fileURL = fileURL
        self.seedTodos = seedTodos
    }

    /// Loads todos from disk, seeding sample data when the file is missing.
    func load() throws -> [TodoItem] {
        if let saved = try loadIfPresent() {
            return saved
        }
        try save(seedTodos)
        return seedTodos
    }

    func save(_ todos: [TodoItem]) throws {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(todos)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw TodoStoreError.persistenceFailed(underlying: error)
        }
    }

    private func loadIfPresent() throws -> [TodoItem]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([TodoItem].self, from: data)
        } catch {
            throw TodoStoreError.persistenceFailed(underlying: error)
        }
    }

    static var defaultFileURL: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documents.appendingPathComponent("item.json", isDirectory: false)
    }

    static let sampleTodos: [TodoItem] = {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        var items = [
            TodoItem(
                id: "todo-1",
                title: "Buy groceries",
                todoDescription: "Milk, eggs, bread, and coffee beans",
                isCompleted: false,
                imageUrl: "https://picsum.photos/seed/groceries/200",
                dueDate: TodoItem.milliseconds(from: tomorrow)
            ),
            TodoItem(
                id: "todo-2",
                title: "Finish iOS homework",
                todoDescription: "Wire list screen to JSON persistence",
                isCompleted: false,
                dueDate: TodoItem.milliseconds(from: nextWeek)
            ),
            TodoItem(
                id: "todo-3",
                title: "Call mom",
                todoDescription: "Wish her a happy weekend",
                isCompleted: true
            ),
            TodoItem(
                id: "todo-4",
                title: "Dentist appointment",
                todoDescription: "Bring insurance card",
                isCompleted: false,
                imageUrl: "https://picsum.photos/seed/dentist/200",
                dueDate: TodoItem.milliseconds(
                    from: calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date()
                )
            ),
            TodoItem(
                id: "todo-5",
                title: "Read SwiftUI docs",
                todoDescription: "NavigationStack, sheets, and forms",
                isCompleted: false
            )
        ]

        let extras: [(String, String, Bool)] = [
            ("todo-6", "Water plants", false),
            ("todo-7", "Pay electricity bill", false),
            ("todo-8", "Plan weekend trip", false),
            ("todo-9", "Update resume", true),
            ("todo-10", "Clean kitchen", false),
            ("todo-11", "Book flight tickets", false),
            ("todo-12", "Reply to emails", true),
            ("todo-13", "Buy birthday gift", false),
            ("todo-14", "Practice guitar", false),
            ("todo-15", "Meal prep Sunday", false),
            ("todo-16", "Review pull requests", false),
            ("todo-17", "Schedule haircut", true),
            ("todo-18", "Backup laptop", false),
            ("todo-19", "Organize photo library", false),
            ("todo-20", "Write weekly journal", false),
            ("todo-21", "Stretch after workout", false),
            ("todo-22", "Order printer ink", true),
            ("todo-23", "Fix bike tire", false),
            ("todo-24", "Watch WWDC session", false),
            ("todo-25", "Donate old clothes", false)
        ]

        items.append(contentsOf: extras.map { id, title, isCompleted in
            TodoItem(id: id, title: title, isCompleted: isCompleted)
        })
        return items
    }()
}
