//
//  Models.swift
//  Schedule with you
//
//  数据模型：分类体系完全数据驱动、可扩展（宪法 R2）；
//  日程以具体日期存储，避免"dayOffset 相对今天"在持久化后漂移。
//

import Foundation
import SwiftUI

struct ActivityCategory: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var colorHex: String
    var activities: [String]
    var isBuiltIn: Bool

    var color: Color { Color(paperHex: colorHex) }
}

enum CategoryDefaults {
    // 宪法 §5 / 修订 R2：学习 / 创造 / 健康 / 生活 + 自定义，随时可改
    static let categories: [ActivityCategory] = [
        ActivityCategory(id: "learning", name: "学习", colorHex: "7B93B5",
                         activities: ["阅读", "刷题", "语言", "复盘"], isBuiltIn: true),
        ActivityCategory(id: "creating", name: "创造", colorHex: "5F9C8A",
                         activities: ["画画", "音乐", "写作", "动手做"], isBuiltIn: true),
        ActivityCategory(id: "health", name: "健康", colorHex: "7FA25C",
                         activities: ["运动", "拉伸", "散步", "休息", "睡觉"], isBuiltIn: true),
        ActivityCategory(id: "living", name: "生活", colorHex: "BE8F55",
                         activities: ["吃饭", "通勤", "家务", "社交"], isBuiltIn: true),
        ActivityCategory(id: "custom", name: "自定义", colorHex: "B57F8B",
                         activities: [], isBuiltIn: false)
    ]
}

enum CompanionID: String, Codable, CaseIterable, Identifiable {
    case jing, ya, yue

    var id: String { rawValue }

    var name: String {
        switch self {
        case .jing: return "小静"
        case .ya: return "芽芽"
        case .yue: return "月团"
        }
    }

    var about: String {
        switch self {
        case .jing:
            return "安安静静的，喜欢陪你做事。你在忙的时候，她也在忙。"
        case .ya:
            return "带着一点发芽的劲头，最喜欢看你动手做点什么。"
        case .yue:
            return "圆滚滚的，夜里更有精神，习惯把日子看得很慢。"
        }
    }

    func mood(for categoryName: String?) -> String {
        guard let categoryName else { return "空白也算一种安排" }
        switch categoryName {
        case "学习": return "陪你安静进入学习"
        case "创造": return "一起做点什么吧"
        case "健康": return "身体先醒过来"
        case "生活": return "照顾生活的小秩序"
        default: return "跟着你的节奏走"
        }
    }
}

struct ScheduleItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var day: Date
    var categoryID: String
    var activity: String
    var note: String = ""
    var startHour: Double
    var duration: Double
    var isAccrued: Bool = false
    var isAppreciated: Bool = false
    var createdAt: Date = Date()

    var endHour: Double { startHour + duration }

    func dayOffset(from reference: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: reference), to: day).day ?? 0
    }

    func hourOn(_ date: Date, calendar: Calendar = .current) -> Double {
        Double(calendar.component(.hour, from: date)) + Double(calendar.component(.minute, from: date)) / 60.0
    }

    func endDate(calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .second, value: Int((startHour + duration) * 3600), to: day) ?? day
    }
}

struct BehaviorCounters: Codable, Equatable {
    var tapsDuringFocus = 0
    var tapsDuringSleep = 0
    var movesByKey: [String: Int] = [:]
    var lateNightOpens = 0
}
