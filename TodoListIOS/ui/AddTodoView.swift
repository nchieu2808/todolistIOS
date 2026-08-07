//
//  AddTodoView.swift
//  TodoListIOS
//
//  Created by Nguyễn Chí Hiếu on 7/8/26.
//

import SwiftUI

struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (TodoDraft) async -> Bool

    @State private var title = ""
    @State private var todoDescription = ""
    @State private var hasDueDate = false
    @State private var dueDate = Calendar.current.date(
        byAdding: .day,
        value: 1,
        to: Date()
    ) ?? Date()
    @State private var isSaving = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                    .textInputAutocapitalization(.sentences)

                TextField("Description", text: $todoDescription, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Schedule") {
                Toggle("Due date", isOn: $hasDueDate.animation())

                if hasDueDate {
                    DatePicker(
                        "Due",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
        }
        .navigationTitle("New Todo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isSaving)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(!canSave)
            }
        }
        .interactiveDismissDisabled(isSaving)
        .overlay {
            if isSaving {
                ProgressView("Saving…")
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let draft = TodoDraft(
            title: title,
            todoDescription: todoDescription,
            dueDate: hasDueDate ? dueDate : nil,
            imageUrl: nil
        )

        let didSave = await onSave(draft)
        if didSave {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        AddTodoView { _ in true }
    }
}
