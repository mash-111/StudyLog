//
//  SubjectStore.swift
//  StudyLog
//
//  Created by Masaaki Honda on 2026/03/15.
//

import Foundation
import Combine
import SwiftUI

class SubjectStore: ObservableObject {
    @Published var subjects: [String] = []

    init() {
        load()
        if subjects.isEmpty {
            subjects = ["項目1", "項目2", "項目3"]
            save()
        }
    }

    func add(_ subject: String) {
        subjects.append(subject)
        save()
    }

    func delete(at offsets: IndexSet) {
        subjects.remove(atOffsets: offsets)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        subjects.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func update(at index: Int, to name: String) {
        subjects[index] = name
        save()
    }

    private func save() {
        UserDefaults.standard.set(subjects, forKey: "studySubjects")
    }

    private func load() {
        subjects = UserDefaults.standard.stringArray(forKey: "studySubjects") ?? []
    }
}
