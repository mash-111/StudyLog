//
//  ContentView.swift
//  StudyLog
//
//  Created by Masaaki Honda on 2026/03/15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = StudyStore()
    @StateObject private var subjectStore = SubjectStore()
    @State private var showSubjectSettings = false
    @State private var isStudying = false
    @State private var startDate: Date? = nil
    @State private var elapsedSeconds = 0
    @State private var timer: Timer? = nil
    @State private var subject = ""
    @State private var showHistory = false


    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            // タイマータブ
            NavigationStack {
                VStack(spacing: 32) {
                    HStack(spacing: 16) {
                        StatCard(title: "今日", value: timeString(Int(store.totalSeconds(for: Date()))))
                        StatCard(title: "今週", value: timeString(Int(store.totalSecondsThisWeek())))
                        StatCard(title: "累計", value: timeString(Int(store.totalSecondsAllTime)))
                    }
                    .padding(.horizontal)

                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("連続 \(store.streakDays) 日")
                            .font(.headline)
                    }

                    Text(timeString(elapsedSeconds))
                        .font(.system(size: 64, weight: .thin, design: .monospaced))

                    if !isStudying {
                        Picker("科目", selection: $subject) {
                            ForEach(subjectStore.subjects) { s in Text(s.name).tag(s.name) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }

                    Button(action: toggleTimer) {
                        Text(isStudying ? "終了して保存" : "勉強開始")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 60)
                            .background(isStudying ? Color.red : Color.blue)
                            .cornerRadius(30)
                    }

                    Spacer()
                }
                .padding(.top)
                .navigationTitle("StudyLog")
                .toolbar {
                    Button("履歴") { showHistory = true }
                    Button(action: { showSubjectSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                .sheet(isPresented: $showHistory) {
                    HistoryView(store: store)
                }
                .sheet(isPresented: $showSubjectSettings) {
                    SubjectSettingsView(subjectStore: subjectStore)
                }
                .onAppear {
                    if subject.isEmpty || !subjectStore.subjects.map(\.name).contains(subject) {
                        subject = subjectStore.subjects.first?.name ?? ""
                    }
                }
                .onChange(of: showSubjectSettings) { _, isShowing in
                    if !isShowing {
                        if !subjectStore.subjects.map(\.name).contains(subject) {
                            subject = subjectStore.subjects.first?.name ?? ""
                        }
                    }
                }
            }
            .tabItem {
                Label("タイマー", systemImage: "timer")
            }
            .tag(0)

            // カレンダータブ
            NavigationStack {
                ScrollView {
                    CalendarView(store: store)
                }
                .navigationTitle("カレンダー")
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }
            .tag(1)
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .global)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard abs(horizontal) > abs(vertical) else { return }
                    withAnimation {
                        if horizontal < 0 && selectedTab < 1 {
                            selectedTab += 1
                        } else if horizontal > 0 && selectedTab > 0 {
                            selectedTab -= 1
                        }
                    }
                }
        )
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && isStudying {
                timer?.invalidate()
                timer = nil
                if let start = startDate {
                    let duration = Date().timeIntervalSince(start)
                    store.add(duration: duration, subject: subject)
                }
                startDate = nil
                elapsedSeconds = 0
                isStudying = false
            }
        }
    }

    func toggleTimer() {
        if isStudying {
            timer?.invalidate()
            timer = nil
            if let start = startDate {
                let duration = Date().timeIntervalSince(start)
                store.add(duration: duration, subject: subject)
            }
            startDate = nil
            elapsedSeconds = 0
        } else {
            startDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if let start = startDate {
                    elapsedSeconds = Int(Date().timeIntervalSince(start))
                }
            }
        }
        isStudying.toggle()
    }

    func timeString(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

struct StatCard: View {
    var title: String
    var value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HistoryView: View {
    @ObservedObject var store: StudyStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.records.reversed()) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(record.subject)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(timeString(Int(record.duration)))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete { offsets in
                    store.delete(at: offsets)
                }
            }
            .navigationTitle("勉強履歴")
        }
    }

    func timeString(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

#Preview {
    ContentView()
}
