//
//  TodoStoring.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 8/8/26.
//

import Foundation

/// Abstraction over todo persistence so callers depend on a protocol, not a concrete store.
protocol TodoStoring {
    func load() throws -> [TodoItem]
    func save(_ todos: [TodoItem]) throws
}
