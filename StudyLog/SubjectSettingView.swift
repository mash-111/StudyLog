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

    var body: some View {
        NavigationStack {
            List {
                ForEach(subjectStore.subjects) { subject in
                    if editingID == subject.id {
                        TextField("項目名", text: $editingText)
                            .onSubmit { commitEdit(id: subject.id) }
                    } else {
                        Text(subject.name)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !editMode.isEditing else { return }
                                editingID = subject.id
                                editingText = subject.name
                            }
                    }
                }
                .onDelete { offsets in
                    subjectStore.delete(at: offsets)
                }
                .onMove { source, destination in
                    subjectStore.move(from: source, to: destination)
                }

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
            .onChange(of: editMode) { _, newMode in
                if newMode.isEditing, let id = editingID {
                    commitEdit(id: id)
                }
            }
            .navigationTitle("カテゴリー設定")
            .toolbar {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
    }

    func commitEdit(id: UUID) {
        let trimmed = editingText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            subjectStore.update(id: id, to: trimmed)
        }
        editingID = nil
        editingText = ""
    }

    func addSubject() {
        let trimmed = newSubject.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        subjectStore.add(trimmed)
        newSubject = ""
    }
}
