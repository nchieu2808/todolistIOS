//
//  Item.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 1/8/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
