//
//  SubjectSettingView.swift
//  StudyLog
//
//  Created by Masaaki Honda on 2026/03/15.
//

import SwiftUI

struct SubjectSettingsView: View {
    @ObservedObject var subjectStore: SubjectStore
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive

    @State private var newSubjectName = ""
    @State private var showEditAlert = false
    @State private var editTargetID: UUID? = nil
    @State private var editAlertText = ""
    @State private var showDuplicateAlert = false
    @State private var duplicateMessage = ""

    private var isEditing: Bool {
        editMode.isEditing
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if subjectStore.subjects.isEmpty {
                        Text("カテゴリーがありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(subjectStore.subjects) { subject in
                            Text(subject.name)
                                .onTapGesture {
                                    guard !isEditing else { return }
                                    editTargetID = subject.id
                                    editAlertText = subject.name
                                    showEditAlert = true
                                }
                        }
                        .onDelete { offsets in
                            subjectStore.delete(at: offsets)
                        }
                        .onMove { source, destination in
                            subjectStore.move(from: source, to: destination)
                        }
                    }
                }

                if !isEditing {
                    Section {
                        HStack {
                            TextField("新しい項目を追加", text: $newSubjectName)
                            Button(action: addSubject) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("カテゴリー設定")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .alert("カテゴリー名を編集", isPresented: $showEditAlert) {
                TextField("カテゴリー名", text: $editAlertText)
                Button("キャンセル", role: .cancel) {}
                Button("保存") {
                    saveEdit()
                }
            }
            .alert("エラー", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(duplicateMessage)
            }
        }
    }

    private func addSubject() {
        let trimmed = newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let isDuplicate = subjectStore.subjects.contains { $0.name == trimmed }
        if isDuplicate {
            duplicateMessage = "同じ名前のカテゴリーが既にあります"
            showDuplicateAlert = true
            return
        }
        subjectStore.add(trimmed)
        newSubjectName = ""
    }

    private func saveEdit() {
        guard let id = editTargetID else { return }
        let trimmed = editAlertText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let isDuplicate = subjectStore.subjects.contains { $0.id != id && $0.name == trimmed }
        if isDuplicate {
            duplicateMessage = "同じ名前のカテゴリーが既にあります"
            showDuplicateAlert = true
            return
        }
        subjectStore.update(id: id, to: trimmed)
    }
}
