//
//  ContentView.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 1/8/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TodoListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
