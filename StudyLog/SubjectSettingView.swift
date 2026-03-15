//
//  SubjectSettingView.swift
//  StudyLog
//
//  Created by Masaaki Honda on 2026/03/15.
//

import SwiftUI

struct SubjectSettingsView: View {
    @ObservedObject var subjectStore: SubjectStore
    @State private var newSubject = ""
    @State private var editMode: EditMode = .inactive
    @State private var editingID: UUID? = nil
    @State private var editingText = ""
    @FocusState private var focusedID: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(subjectStore.subjects) { subject in
                    TextField("項目名", text: Binding(
                        get: { editingID == subject.id ? editingText : subject.name },
                        set: { editingText = $0 }
                    ))
                    .focused($focusedID, equals: subject.id)
                    .disabled(!editMode.isEditing)
                    .onSubmit { commitEdit(id: subject.id) }
                }
                .onDelete { offsets in
                    subjectStore.delete(at: offsets)
                }
                .onMove(perform: editMode.isEditing ? { source, destination in
                    subjectStore.move(from: source, to: destination)
                } : nil)

                if !editMode.isEditing {
                    HStack {
                        TextField("新しい項目を追加", text: $newSubject)
                        Button(action: addSubject) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newSubject.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .onChange(of: focusedID) { _, newValue in
                if let oldID = editingID, oldID != newValue {
                    saveEdit(id: oldID)
                }
                if let newValue,
                   let subject = subjectStore.subjects.first(where: { $0.id == newValue }) {
                    editingID = newValue
                    editingText = subject.name
                } else {
                    editingID = nil
                    editingText = ""
                }
            }
            .onChange(of: editMode) { _, newMode in
                if !newMode.isEditing {
                    focusedID = nil
                }
            }
            .onDisappear {
                if let id = editingID {
                    saveEdit(id: id)
                }
            }
            .navigationTitle("カテゴリー設定")
            .toolbar {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
    }

    private func saveEdit(id: UUID) {
        let trimmed = editingText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let isDuplicate = subjectStore.subjects.contains { $0.id != id && $0.name == trimmed }
        guard !isDuplicate else { return }
        subjectStore.update(id: id, to: trimmed)
    }

    func commitEdit(id: UUID) {
        saveEdit(id: id)
        editingID = nil
        editingText = ""
        focusedID = nil
    }

    func addSubject() {
        let trimmed = newSubject.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let isDuplicate = subjectStore.subjects.contains { $0.name == trimmed }
        guard !isDuplicate else { return }
        subjectStore.add(trimmed)
        newSubject = ""
    }
}
