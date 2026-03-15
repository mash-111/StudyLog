//
//  StudyStore.swift
//  StudyLog
//
//  Created by Masaaki Honda on 2026/03/15.
//

import Foundation
import Combine

class StudyStore: ObservableObject {
    @Published var records: [StudyRecord] = []

    init() {
        load()
    }

    func add(duration: TimeInterval, subject: String) {
        let record = StudyRecord(date: Date(), duration: duration, subject: subject)
        records.append(record)
        save()
    }
    
    func delete(at offsets: IndexSet) {
        let reversed = Array(records.reversed())
        let toDelete = offsets.map { reversed[$0].id }
        records.removeAll { toDelete.contains($0.id) }
        save()
    }

    func totalSeconds(for date: Date) -> TimeInterval {
        let calendar = Calendar.current
        return records
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.duration }
    }

    func totalSecondsThisWeek() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        return records
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.duration }
    }
    
    func delete(byId id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }

    var totalSecondsAllTime: TimeInterval {
        records.reduce(0) { $0 + $1.duration }
    }

    var streakDays: Int {
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: Date())
        var streak = 0
        while true {
            let studied = records.contains {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            if studied {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        return streak
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "studyRecords")
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "studyRecords"),
           let records = try? JSONDecoder().decode([StudyRecord].self, from: data) {
            self.records = records
        }
    }
}
