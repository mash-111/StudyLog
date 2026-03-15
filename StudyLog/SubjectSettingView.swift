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
    @Environment(\.editMode) private var editMode

    var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(subjectStore.subjects.enumerated()), id: \.offset) { index, subject in
                    if isEditing {
                        TextField("項目名", text: Binding(
                            get: { subjectStore.subjects[index] },
                            set: { subjectStore.update(at: index, to: $0) }
                        ))
                    } else {
                        Text(subject)
                    }
                }
                .onDelete { offsets in
                    subjectStore.delete(at: offsets)
                }
                .onMove { source, destination in
                    subjectStore.move(from: source, to: destination)
                }

                if isEditing {
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
    }

    func addSubject() {
        let trimmed = newSubject.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        subjectStore.add(trimmed)
        newSubject = ""
    }
}
