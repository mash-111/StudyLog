//
//  StudyRecord.swift
//  StudyLog
//
//  Created by Masaaki Honda on 2026/03/15.
//

import Foundation

struct StudyRecord: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var duration: TimeInterval  // 秒数
    var subject: String
}
