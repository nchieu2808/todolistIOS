//
//  TodoListIOSApp.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 1/8/26.
//

import SwiftUI

@main
struct TodoListIOSApp: App {
    private let container = AppContainer.live

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appContainer(container)
        }
    }
}
