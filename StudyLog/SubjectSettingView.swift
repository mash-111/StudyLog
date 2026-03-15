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

    var body: some View {
        NavigationStack {
            List {
                ForEach(subjectStore.subjects) { subject in
                    if editMode.isEditing {
                        TextField("項目名", text: Binding(
                            get: { subject.name },
                            set: { subjectStore.update(id: subject.id, to: $0) }
                        ))
                    } else {
                        Text(subject.name)
                    }
                }
                .onDelete { offsets in
                    subjectStore.delete(at: offsets)
                }
                .onMove { source, destination in
                    subjectStore.move(from: source, to: destination)
                }

                if editMode.isEditing {
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
            .navigationTitle("カテゴリー設定")
            .toolbar {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
    }

    func addSubject() {
        let trimmed = newSubject.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        subjectStore.add(trimmed)
        newSubject = ""
    }
}
