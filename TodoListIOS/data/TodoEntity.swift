//
//  TodoEntity.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 14/8/26.
//

import CoreData
import Foundation

@objc(TodoEntity)
nonisolated final class TodoEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var title: String
    @NSManaged var todoDescription: String?
    @NSManaged var isCompleted: Bool
    @NSManaged var imageUrl: String?
    @NSManaged var dueDate: NSNumber?
}
