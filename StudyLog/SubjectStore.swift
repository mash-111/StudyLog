//
//  SubjectStore.swift
//  StudyLog
//
//  Created by Masaaki Honda on 2026/03/15.
//

import Foundation
import Combine
import SwiftUI

struct Subject: Identifiable, Codable {
    let id: UUID
    var name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

class SubjectStore: ObservableObject {
    @Published var subjects: [Subject] = []

    init() {
        load()
        if subjects.isEmpty {
            subjects = ["項目1", "項目2", "項目3"].map { Subject(name: $0) }
            save()
        }
    }

    func add(_ name: String) {
        subjects.append(Subject(name: name))
        save()
    }

    func delete(at offsets: IndexSet) {
        subjects.remove(atOffsets: offsets)
        save()
    }

    func update(id: UUID, to name: String) {
        if let index = subjects.firstIndex(where: { $0.id == id }) {
            subjects[index].name = name
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(subjects) {
            UserDefaults.standard.set(data, forKey: "studySubjects")
        }
    }

    private func load() {
        // 新フォーマット（UUID付き）を試みる
        if let data = UserDefaults.standard.data(forKey: "studySubjects"),
           let saved = try? JSONDecoder().decode([Subject].self, from: data) {
            subjects = saved
            return
        }
        // 旧フォーマット（文字列配列）からマイグレーション
        if let oldSubjects = UserDefaults.standard.stringArray(forKey: "studySubjects") {
            subjects = oldSubjects.map { Subject(name: $0) }
            save()
            return
        }
        subjects = []
    }
}
