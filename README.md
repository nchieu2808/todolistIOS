# TodoListIOS

A native iOS todo list app built with **SwiftUI** and **Core Data**. Todos are stored on-device and the data model is shaped to stay compatible with an Android / Firestore counterpart.

## Features

- Add and delete todos
- Mark todos as complete / incomplete
- Empty state when there are no items
- Search and status filters with paginated list loading
- Optional description, due date, and image URL on each item
- Local persistence with Core Data (SQLite)

## Requirements

- Xcode (with iOS Simulator or a physical device)
- iOS 26.5+ deployment target (as configured in the project)

## Getting started

1. Clone the repository:

   ```bash
   git clone https://github.com/nchieu2808/todolistIOS.git
   cd todolistIOS
   ```

2. Open `TodoListIOS.xcodeproj` in Xcode.

3. Select a simulator or device, then run the app (`⌘R`).

## Project structure

```
TodoListIOS/
├── TodoListIOSApp.swift          # App entry point
├── data/
│   ├── TodoItem.swift            # Todo value type
│   ├── TodoStoring.swift         # Persistence protocol
│   ├── TodoCoreDataStore.swift   # Core Data store
│   ├── TodoEntity.swift          # NSManagedObject
│   ├── TodoList.xcdatamodeld     # Core Data model
│   └── TodoListViewModel.swift
├── di/
│   └── AppContainer.swift        # Composition root
├── ui/
│   ├── ContentView.swift
│   ├── TodoListView.swift
│   ├── AddTodoView.swift
│   └── TodoDetailView.swift
├── Assets.xcassets/
└── Info.plist
```

## Persistence

`TodoCoreDataStore` implements `TodoStoring` and saves todos with Core Data SQLite on disk. The live app uses `TodoList.sqlite` in the documents directory. Previews and tests use temporary SQLite files.

## Data model

`TodoItem` fields:

| Field | Type | Notes |
|--------|------|--------|
| `id` | `String` | Unique identifier |
| `title` | `String` | Todo title |
| `todoDescription` | `String?` | Maps to `description` on Android / Firestore |
| `isCompleted` | `Bool` | Completion state |
| `imageUrl` | `String?` | Optional image URL |
| `dueDate` | `Int64?` | Unix timestamp in milliseconds |

## License

Personal project — no license specified yet.
