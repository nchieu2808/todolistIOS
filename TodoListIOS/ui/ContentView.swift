//
//  ContentView.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 1/8/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.appContainer) private var container

    var body: some View {
        TodoListView(viewModel: container.makeTodoListViewModel())
    }
}

#Preview {
    ContentView()
        .appContainer(.preview)
}
