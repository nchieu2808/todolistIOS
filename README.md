# TodoListIOS

A native iOS todo list app built with **SwiftUI** and **SwiftData**. Todos are stored on-device and the data model is shaped to stay compatible with an Android / Firestore counterpart.

## Features

- Add and delete todos
- Mark todos as complete / incomplete
- Empty state when there are no items
- Edit mode for managing the list
- Optional description and due date on each item
- Local persistence with SwiftData

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
├── TodoListIOSApp.swift     # App entry point & SwiftData container
├── data/
│   ├── TodoItem.swift       # Todo model (@Model)
│   └── Item.swift           # Legacy template model
├── ui/
│   ├── ContentView.swift    # Root view
│   └── TodoListView.swift   # List, add, delete, complete
├── Assets.xcassets/
└── Info.plist
```

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
