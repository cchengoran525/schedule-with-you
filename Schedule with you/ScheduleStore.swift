//
//  ScheduleStore.swift
//  Schedule with you
//
//  单一数据源 + JSON 轻量持久化（宪法 R4）。
//  经验规则（宪法 §14/§16）：每小时 +0.01，目标 100；"还不错" ×1.2，完全可选、不打扰。
//  成就（宪法 §17-20）：观察而非目标；彩蛋奖励极小。
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ScheduleStore: ObservableObject {
    @Published var categories: [ActivityCategory] = CategoryDefaults.categories
    @Published var items: [ScheduleItem] = []
    @Published var experienceByCategory: [String: Double] = [:]
    @Published var experienceByActivity: [String: Double] = [:]
    @Published var selectedCompanion: CompanionID = .jing
    @Published var unlocked: Set<String> = []
    @Published var points = 0
    @Published var counters = BehaviorCounters()

    static let experienceGoal: Double = 100

    private let fileURL: URL

    // MARK: - 持久化

    private struct PersistedState: Codable {
        var categories: [ActivityCategory]
        var items: [ScheduleItem]
        var experienceByCategory: [String: Double]
        var experienceByActivity: [String: Double]
        var selectedCompanion: CompanionID
        var unlocked: Set<String>
        var points: Int
        var counters: BehaviorCounters
    }

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("ScheduleSketchbook", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("state.json")

        if let data = try? Data(contentsOf: fileURL),
           let state = try? JSONDecoder().decode(PersistedState.self, from: data) {
            categories = state.categories
            items = state.items
            experienceByCategory = state.experienceByCategory
            experienceByActivity = state.experienceByActivity
            selectedCompanion = state.selectedCompanion
            unlocked = state.unlocked
            points = state.points
            counters = state.counters
        } else {
            seed()
        }

        settleGrowth()
        evaluateAchievements()
        save()
    }

    private func save() {
        let state = PersistedState(
            categories: categories,
            items: items,
            experienceByCategory: experienceByCategory,
            experienceByActivity: experienceByActivity,
            selectedCompanion: selectedCompanion,
            unlocked: unlocked,
            points: points,
            counters: counters
        )
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func seed() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        func offsetDay(_ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: today) ?? today }

        items = [
            ScheduleItem(day: offsetDay(-1), categoryID: "living", activity: "家务", startHour: 20, duration: 1),
            ScheduleItem(day: today, categoryID: "learning", activity: "阅读", startHour: 8, duration: 1.5),
            ScheduleItem(day: today, categoryID: "creating", activity: "动手做", startHour: 10, duration: 2),
            ScheduleItem(day: today, categoryID: "health", activity: "散步", startHour: 18, duration: 1),
            ScheduleItem(day: offsetDay(1), categoryID: "learning", activity: "复盘", startHour: 19, duration: 1)
        ]
        experienceByCategory = ["learning": 0.12, "creating": 0.06, "health": 0.08, "living": 0.05]
        experienceByActivity = ["阅读": 0.08, "动手做": 0.06, "睡觉": 0.10]
    }

    // MARK: - 分类（开放接口，宪法 R2）

    func select(companion: CompanionID) {
        guard selectedCompanion != companion else { return }
        selectedCompanion = companion
        save()
    }

    func category(id: String) -> ActivityCategory? {
        categories.first(where: { $0.id == id })
    }

    func addCustomActivity(_ name: String, to categoryID: String) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !categories[index].activities.contains(trimmed) else { return }
        categories[index].activities.append(trimmed)
        save()
    }

    /// 预留接口：以后允许用户自建大类
    @discardableResult
    func addCustomCategory(name: String, colorHex: String = "B57F8B") -> ActivityCategory {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = ActivityCategory(
            id: "custom-\(UUID().uuidString.prefix(6))",
            name: trimmed.isEmpty ? "新类别" : trimmed,
            colorHex: colorHex,
            activities: [],
            isBuiltIn: false
        )
        categories.insert(category, at: max(categories.count - 1, 0))
        save()
        return category
    }

    // MARK: - 日程

    func items(on day: Date) -> [ScheduleItem] {
        let start = Calendar.current.startOfDay(for: day)
        return items
            .filter { Calendar.current.isDate($0.day, inSameDayAs: start) }
            .sorted { $0.startHour < $1.startHour }
    }

    /// 当前正在发生的日程；没有则返回 nil（空档不是失败，宪法 §11）
    func currentItem(now: Date = Date()) -> ScheduleItem? {
        let calendar = Calendar.current
        guard calendar.isDateInToday(now) else { return nil }
        let hour = now.hourDouble
        return items.first { $0.day.isSameDayAsToday && $0.startHour <= hour && hour < $0.endHour }
    }

    func add(_ item: ScheduleItem) {
        items.append(item)
        evaluateAchievements()
        save()
    }

    func remove(_ itemID: UUID) {
        items.removeAll(where: { $0.id == itemID })
        save()
    }

    /// 拖动微调开始时间（15 分钟一档），顺带记录"反复横跳"彩蛋计数
    func updateStart(itemID: UUID, startHour: Double) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].startHour = startHour
        let key = itemID.uuidString
        counters.movesByKey[key, default: 0] += 1
        evaluateAchievements()
        save()
    }

    // MARK: - 成长（宪法 §14/§16）

    /// 日程结束即自动积累——不需要用户点"完成"，完成本身不是一个任务
    func settleGrowth(now: Date = Date()) {
        var changed = false
        for index in items.indices where !items[index].isAccrued {
            if items[index].endDate() <= now {
                accrue(index: index, amount: items[index].duration * 0.01)
                changed = true
            }
        }
        if changed {
            evaluateAchievements()
            save()
        }
    }

    /// "还不错"：结束后 24 小时内可点一次，×1.2；不点就是 ×1，不点也不会少
    func appreciate(itemID: UUID, now: Date = Date()) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        guard !items[index].isAppreciated else { return }
        let end = items[index].endDate()
        guard end <= now, now.timeIntervalSince(end) < 24 * 3600 else { return }
        items[index].isAppreciated = true
        accrue(index: index, amount: items[index].duration * 0.01 * 0.2)
        save()
    }

    func canAppreciate(_ item: ScheduleItem, now: Date = Date()) -> Bool {
        guard !item.isAppreciated else { return false }
        let end = item.endDate()
        return end <= now && now.timeIntervalSince(end) < 24 * 3600
    }

    private func accrue(index: Int, amount: Double) {
        items[index].isAccrued = true
        experienceByCategory[items[index].categoryID, default: 0] += amount
        experienceByActivity[items[index].activity, default: 0] += amount
    }

    // MARK: - 成就（宪法 §17-20）

    enum AchievementFamily: String {
        case growth
        case whimsy
    }

    struct AchievementDef: Identifiable {
        let id: String
        let title: String
        let note: String
        let family: AchievementFamily
        let reward: Int
        let target: Double
        let progress: (ScheduleStore) -> Double

        var isWhimsy: Bool { family == .whimsy }
    }

    var achievementDefs: [AchievementDef] {
        [
            AchievementDef(id: "first_schedule", title: "第一个日程", note: "第一次把一段时间放进了日子里",
                           family: .growth, reward: 5, target: 1,
                           progress: { Double(min($0.items.count, 1)) }),
            AchievementDef(id: "full_day", title: "满满的一天", note: "有一天被安排得很满",
                           family: .growth, reward: 8, target: 12,
                           progress: { store in
                               store.groupedPlannedHours.values.max() ?? 0
                           }),
            AchievementDef(id: "empty_day", title: "空空白白的一天", note: "有一天什么都没安排——这样也很好",
                           family: .growth, reward: 5, target: 1,
                           progress: { Double($0.hasEmptyPastDay ? 1 : 0) }),
            AchievementDef(id: "first_1", title: "第一个 1.00", note: "某一方面攒到了 1.00",
                           family: .growth, reward: 10, target: 1,
                           progress: { $0.experienceByCategory.values.max() ?? 0 }),
            AchievementDef(id: "first_10", title: "第一个 10.00", note: "某一方面攒到了 10.00",
                           family: .growth, reward: 12, target: 10,
                           progress: { $0.experienceByCategory.values.max() ?? 0 }),
            AchievementDef(id: "fish_100", title: "别摸鱼啦", note: "专注的时候被戳了一百下",
                           family: .whimsy, reward: 1, target: 100,
                           progress: { Double($0.counters.tapsDuringFocus) }),
            AchievementDef(id: "sleep_tap", title: "你真的在睡觉吗", note: "它在睡觉的时候被戳了一下",
                           family: .whimsy, reward: 1, target: 1,
                           progress: { Double(min($0.counters.tapsDuringSleep, 1)) }),
            AchievementDef(id: "mover", title: "反复横跳", note: "同一个日程被挪来挪去",
                           family: .whimsy, reward: 1, target: 5,
                           progress: { Double($0.counters.movesByKey.values.max() ?? 0) }),
            AchievementDef(id: "night_owl", title: "夜猫子", note: "凌晨来看过它",
                           family: .whimsy, reward: 1, target: 3,
                           progress: { Double($0.counters.lateNightOpens) })
        ]
    }

    func evaluateAchievements() {
        for def in achievementDefs where !unlocked.contains(def.id) {
            if def.progress(self) >= def.target {
                unlocked.insert(def.id)
                points += def.reward
            }
        }
    }

    private var groupedPlannedHours: [Date: Double] {
        var hours: [Date: Double] = [:]
        for item in items {
            hours[item.day, default: 0] += item.duration
        }
        return hours
    }

    private var hasEmptyPastDay: Bool {
        let calendar = Calendar.current
        guard let earliest = items.map(\.day).min() else { return false }
        var day = calendar.startOfDay(for: earliest)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date())) ?? earliest
        let planned = Set(items.map { calendar.startOfDay(for: $0.day) })
        while day <= yesterday {
            if !planned.contains(day) { return true }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? yesterday
        }
        return false
    }

    // MARK: - 陪伴者语境计数（宪法 §13）

    func registerCompanionTap(now: Date = Date()) {
        if let current = currentItem(now: now) {
            if isSleepActivity(current.activity) {
                counters.tapsDuringSleep += 1
            } else if isFocusActivity(current.activity) {
                counters.tapsDuringFocus += 1
            }
        }
        evaluateAchievements()
        save()
    }

    func registerAppOpen(now: Date = Date()) {
        let hour = now.hourDouble
        if hour >= 1 && hour < 5 {
            counters.lateNightOpens += 1
            evaluateAchievements()
            save()
        }
    }

    func isSleepActivity(_ activity: String) -> Bool {
        ["睡觉", "午休", "睡眠"].contains(activity)
    }

    func isFocusActivity(_ activity: String) -> Bool {
        let focusSet: Set<String> = ["阅读", "刷题", "语言", "复盘", "画画", "音乐", "写作", "动手做"]
        return focusSet.contains(activity)
    }
}

extension Date {
    var hourDouble: Double {
        let calendar = Calendar.current
        return Double(calendar.component(.hour, from: self)) + Double(calendar.component(.minute, from: self)) / 60.0
    }

    var isSameDayAsToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func dayOffset(from reference: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: reference), to: self).day ?? 0
    }
}
