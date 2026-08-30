//
//  DrawerPages.swift
//  Schedule with you
//
//  换角色（从上方落入）与 个人主页（从右侧抽入）。
//

import SwiftUI

// MARK: - 换角色（宪法 R5：从上方落入，返回把手在下缘）

struct CompanionsPage: View {
    @ObservedObject var store: ScheduleStore
    @State private var pulse = false

    private var companionState: CompanionState {
        if let current = store.currentItem() {
            return store.isSleepActivity(current.activity) ? .asleep : .doing(current.activity)
        }
        return .idle
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("换角色")
                    .font(.sketch(13))
                    .foregroundStyle(Paper.faint.opacity(0.75))
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 70)

            Spacer(minLength: 10)

            ZStack {
                CompanionStage(companion: store.selectedCompanion, state: companionState, quip: nil, scale: 1.22, onTap: { pulse.toggle() })
                    .id(store.selectedCompanion)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
            .animation(.easeInOut(duration: 0.35), value: store.selectedCompanion)

            // 三个小圆点 = 三位陪伴者（手稿里的 o o o）
            HStack(spacing: 20) {
                ForEach(CompanionID.allCases) { candidate in
                    Button {
                        store.select(companion: candidate)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(candidate == store.selectedCompanion
                                      ? candidateColor(candidate)
                                      : Color.clear)
                                .frame(width: 12, height: 12)
                            Circle()
                                .stroke(candidate == store.selectedCompanion ? candidateColor(candidate) : Paper.hairline,
                                        lineWidth: 1.2)
                                .frame(width: 18, height: 18)
                        }
                        .frame(width: 34, height: 34)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)

            Text(store.selectedCompanion.name)
                .font(.sketch(26))
                .foregroundStyle(Paper.ink)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("about")
                    .font(.sketch(12))
                    .foregroundStyle(Paper.faint.opacity(0.7))
                HourTick(width: 42, color: Paper.hairline)
                Text(store.selectedCompanion.about)
                    .font(.sketch(13))
                    .foregroundStyle(Paper.faint)
                    .lineSpacing(5)
                    .frame(width: 240, alignment: .leading)
            }
            .padding(.top, 18)

            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Paper.background.ignoresSafeArea())
    }

    private func candidateColor(_ candidate: CompanionID) -> Color {
        switch candidate {
        case .jing: return Paper.ink.opacity(0.8)
        case .ya: return Color(paperHex: "7FA25C")
        case .yue: return Color(paperHex: "9287AC")
        }
    }
}

// MARK: - 个人主页（宪法 R5：从右侧抽入，返回把手在右缘）

struct ProfilePage: View {
    @ObservedObject var store: ScheduleStore

    // 上方落入的抽屉：退出是上滑，页面不用 ScrollView，避免和滚动冲突
    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            header

            growthSection

            achievementSection

            Text("小点数 · \(store.points)")
                .font(.sketch(12))
                .foregroundStyle(Paper.faint.opacity(0.8))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 34)
        .padding(.top, 60)
        .padding(.bottom, 70)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Paper.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Paper.hairline, lineWidth: 1.2)
                CompanionFigure(figureID: store.selectedCompanion)
                    .stroke(Paper.ink.opacity(0.75), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .padding(9)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text("个人")
                    .font(.sketch(22))
                    .foregroundStyle(Paper.ink)
                Text("和\(store.selectedCompanion.name)一起攒下的日子")
                    .font(.sketch(11))
                    .foregroundStyle(Paper.faint.opacity(0.75))
            }
            Spacer()
        }
    }

    /// 经验积累线（手稿：一条竖线上的小圆点和数字）
    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("积累")
                .font(.sketch(15))
                .foregroundStyle(Paper.ink.opacity(0.85))

            VStack(spacing: 0) {
                ForEach(Array(store.categories.enumerated()), id: \.element.id) { index, category in
                    growthRow(category)
                    if index < store.categories.count - 1 {
                        Rectangle()
                            .fill(Paper.hairline.opacity(0.7))
                            .frame(width: 1, height: 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4.5)
                    }
                }
            }

            Text("目标 100 · 一万小时理论")
                .font(.sketch(10))
                .foregroundStyle(Paper.faint.opacity(0.6))
        }
    }

    private func growthRow(_ category: ActivityCategory) -> some View {
        let value = store.experienceByCategory[category.id, default: 0]
        return HStack(spacing: 14) {
            Circle()
                .fill(category.color.opacity(value > 0 ? 0.9 : 0.35))
                .frame(width: 10, height: 10)
            Text(category.name)
                .font(.sketch(14))
                .foregroundStyle(Paper.ink.opacity(0.8))
            Spacer()
            Text(String(format: "%.2f", min(value, ScheduleStore.experienceGoal)))
                .font(.sketch(12))
                .foregroundStyle(Paper.faint)
        }
    }

    /// 成就（宪法 §17-19：观察而非目标；彩蛋未解锁时只显示"？？？"）
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("成就")
                .font(.sketch(15))
                .foregroundStyle(Paper.ink.opacity(0.85))

            VStack(alignment: .leading, spacing: 13) {
                ForEach(store.achievementDefs) { def in
                    achievementRow(def)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SketchyRect(corner: 18).fill(Paper.raised.opacity(0.45)))
            .overlay(
                SketchyRect(corner: 18)
                    .stroke(Paper.hairline, lineWidth: 1.1)
            )
        }
    }

    private func achievementRow(_ def: ScheduleStore.AchievementDef) -> some View {
        let isUnlocked = store.unlocked.contains(def.id)
        return HStack(spacing: 12) {
            Circle()
                .fill(isUnlocked ? Paper.accent.opacity(0.85) : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(isUnlocked ? Color.clear : Paper.hairline, lineWidth: 1.1))

            Text(isUnlocked || !def.isWhimsy ? def.title : "？？？")
                .font(.sketch(13.5))
                .foregroundStyle(isUnlocked ? Paper.ink : Paper.faint.opacity(0.65))

            Spacer()

            if isUnlocked {
                Text("·\(def.reward)")
                    .font(.sketch(11))
                    .foregroundStyle(Paper.faint.opacity(0.75))
            } else if !def.isWhimsy {
                Text("\(Int(min(def.progress(store) / max(def.target, 0.001), 1) * 100))%")
                    .font(.sketch(10))
                    .foregroundStyle(Paper.faint.opacity(0.55))
            }
        }
    }
}
