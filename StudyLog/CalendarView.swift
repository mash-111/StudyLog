//
//  CalendarView.swift
//  StudyLog
//
//  Created by Masaaki Honda on 2026/03/15.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var store: StudyStore
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var selectedRecords: [StudyRecord] {
        guard let selected = selectedDate else { return [] }
        return store.records.filter {
            calendar.isDate($0.date, inSameDayAs: selected)
        }.reversed()
    }

    var body: some View {
        VStack(spacing: 16) {

            // 月ナビゲーション
            HStack {
                Button(action: prevMonth) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthTitle)
                    .font(.headline)
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // 曜日ヘッダー
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日付グリッド
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let seconds = store.totalSeconds(for: date)
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

                        VStack(spacing: 2) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                                .foregroundColor(isSelected ? .white : isToday ? .blue : .primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isSelected ? Color.blue : seconds > 0 ? Color.blue.opacity(0.2) : Color.clear)
                                )
                            if seconds > 0 {
                                Text(shortTime(seconds))
                                    .font(.system(size: 9))
                                    .foregroundColor(.blue)
                            } else {
                                Text(" ")
                                    .font(.system(size: 9))
                            }
                        }
                        .onTapGesture {
                            if isSelected {
                                selectedDate = nil
                            } else {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)

            Divider()

            // 選択日の履歴
            if let selected = selectedDate {
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateTitle(selected))
                        .font(.headline)
                        .padding(.horizontal)

                    if selectedRecords.isEmpty {
                        Text("この日の記録はありません")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(selectedRecords) { record in
                            HStack {
                                Text(record.subject)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(timeString(Int(record.duration)))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                Button(role: .destructive) {
                                    store.delete(byId: record.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
            } else {
                Text("日付をタップすると履歴を表示します")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(.vertical)
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日の記録"
        return formatter.string(from: date)
    }

    var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        let firstPadding = (firstWeekday - 1) % 7
        var result: [Date?] = Array(repeating: nil, count: firstPadding)

        var current = monthInterval.start
        while current < monthInterval.end {
            result.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return result
    }

    func prevMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
        selectedDate = nil
    }

    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
        selectedDate = nil
    }

    func shortTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let h = m / 60
        if h > 0 { return "\(h)h\(m % 60)m" }
        return "\(m)m"
    }

    func timeString(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
