//
//  ContentView.swift
//  Schedule with you
//
//  2026-08-30 定稿：详细时间线是从首页下方"小时间轴原地展开"的，
//  不是翻页也不是盖层——展开起点就是小时间轴的位置（几何匹配动画）。
//  进入：刻意上滑（幅度+速度门槛）或点小时间轴；退出：展开后拉回顶部再下拉一次。
//  三个抽屉（左/上/右）是换页逻辑：进入只许点击，退出反向滑或点把手。
//

import SwiftUI

enum AppPage: String, CaseIterable, Identifiable {
    case companions   // 左侧抽入（左钮）
    case profile      // 上方落入（中钮）
    case add          // 右侧抽入（右钮）

    var id: String { rawValue }

    var edge: Edge {
        switch self {
        case .companions: return .leading
        case .profile: return .top
        case .add: return .trailing
        }
    }

    var glyph: SeamGlyph {
        switch self {
        case .companions: return .dots
        case .profile: return .person
        case .add: return .plus
        }
    }
}

struct ContentView: View {
    @StateObject private var store = ScheduleStore()
    @Environment(\.scenePhase) private var scenePhase

    @State private var activePage: AppPage?
    @State private var homeDay = Calendar.current.startOfDay(for: Date())
    @State private var addAtFirstStep = true
    @State private var timelineExpanded = false
    @Namespace private var timelineNS

    var body: some View {
        ZStack(alignment: .top) {
            Paper.background.ignoresSafeArea()

            HomeSection(
                store: store,
                day: $homeDay,
                expanded: timelineExpanded,
                ns: timelineNS,
                openPage: { activePage = $0 },
                onEnter: {
                    withAnimation(.spring(response: 0.52, dampingFraction: 0.88)) {
                        timelineExpanded = true
                    }
                }
            )
            .opacity(timelineExpanded ? 0.18 : 1)
            .scaleEffect(timelineExpanded ? 0.98 : 1)
            .allowsHitTesting(!timelineExpanded)
            .animation(.easeOut(duration: 0.3), value: timelineExpanded)

            if timelineExpanded {
                ExpandedTimeline(
                    store: store,
                    day: $homeDay,
                    ns: timelineNS,
                    onExit: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                            timelineExpanded = false
                        }
                    },
                    onAdd: { activePage = .add }
                )
                .zIndex(2)
            }
        }
        .overlay {
            if let page = activePage {
                DrawerHost(
                    edge: page.edge,
                    glyph: page.glyph,
                    allowsExitGesture: page != .add || addAtFirstStep
                ) {
                    activePage = nil
                } content: {
                    switch page {
                    case .companions:
                        CompanionsPage(store: store)
                    case .profile:
                        ProfilePage(store: store)
                    case .add:
                        AddFlowView(
                            store: store,
                            initialDay: homeDay,
                            onClose: { activePage = nil },
                            atFirstStep: $addAtFirstStep
                        )
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            store.settleGrowth()
            store.registerAppOpen()
        }
        .onChange(of: activePage) { _, page in
            if page == .add { addAtFirstStep = true }
        }
        .environmentObject(store)
    }
}

// MARK: - 首页

struct HomeSection: View {
    @ObservedObject var store: ScheduleStore
    @Binding var day: Date
    var expanded: Bool
    var ns: Namespace.ID
    var openPage: (AppPage) -> Void
    var onEnter: () -> Void

    @State private var quip: Quip?
    @State private var quipTask: Task<Void, Never>?

    private var calendar: Calendar { Calendar.current }
    private var todayItems: [ScheduleItem] { store.items(on: day) }

    /// 当前/附近的日程（首页只看此刻，宪法 §7）
    private var contextItems: (previous: ScheduleItem?, current: ScheduleItem?, next: ScheduleItem?) {
        let list = todayItems
        guard !list.isEmpty else { return (nil, nil, nil) }
        let hour = Date().hourDouble
        let isToday = calendar.isDateInToday(day)
        let currentIndex: Int?
        if isToday, let idx = list.firstIndex(where: { $0.startHour <= hour && hour < $0.endHour }) {
            currentIndex = idx
        } else if isToday {
            currentIndex = list.firstIndex(where: { $0.startHour > hour })
        } else {
            currentIndex = list.firstIndex(where: { $0.startHour <= hour && hour < $0.endHour })
                ?? (hour < (list.first?.startHour ?? 0) ? 0 : nil)
        }
        guard let index = currentIndex else {
            return (list.last, nil, nil)
        }
        return (list[safe: index - 1], list[safe: index], list[safe: index + 1])
    }

    private var currentCategoryName: String? {
        contextItems.current.flatMap { store.category(id: $0.categoryID)?.name }
    }

    private var companionState: CompanionState {
        if let current = contextItems.current {
            if store.isSleepActivity(current.activity) { return .asleep }
            return .doing(current.activity)
        }
        // 空档：它过自己的小日子，偶尔散步去了
        if Int(Date().timeIntervalSince1970 / 900) % 7 == 0 { return .away }
        return .idle
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 12)

            companionArea
                .padding(.top, 6)

            controls
                .padding(.top, 18)

            Spacer(minLength: 24)

            contextTimeline

            flowTicks
                .padding(.top, 4)
                .padding(.bottom, 6)

            Spacer(minLength: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 30)
        .padding(.top, 6)
        .padding(.bottom, 40)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    // 展开：主轴明确 + 幅度与速度都够，避免误触
                    let deliberatePull = value.translation.height < -120 &&
                        (value.predictedEndTranslation.height < -220 || value.translation.height < -170)
                    if !expanded && vertical > horizontal * 1.4 && deliberatePull {
                        onEnter()
                    } else if horizontal > vertical * 1.4 && horizontal > 80 {
                        let delta = value.translation.width > 0 ? -1 : 1
                        if let moved = calendar.date(byAdding: .day, value: delta, to: day) {
                            withAnimation(Paper.sketchSpring) { day = moved }
                        }
                    }
                }
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(dayCaption)
                    .font(.sketch(15))
                    .foregroundStyle(Paper.faint)
                Text(store.selectedCompanion.mood(for: currentCategoryName))
                    .font(.sketch(12))
                    .foregroundStyle(Paper.faint.opacity(0.72))
            }
            Spacer()
            Text(dayBadge)
                .font(.sketch(14))
                .foregroundStyle(Paper.ink.opacity(0.85))
        }
    }

    private var companionArea: some View {
        CompanionStage(
            companion: store.selectedCompanion,
            state: companionState,
            quip: quip,
            scale: 1.38,
            onTap: handleCompanionTap
        )
    }

    /// 首页三按钮（宪法 R7）：位置对应抽屉方向
    private var controls: some View {
        HStack(spacing: 52) {
            controlButton(title: "换角色", glyph: .dots) { openPage(.companions) }

            controlButton(title: "个人", glyph: .person) { openPage(.profile) }

            Button {
                openPage(.add)
            } label: {
                VStack(spacing: 6) {
                    SeamGlyphView(glyph: .plus, color: Paper.accent)
                        .frame(width: 17, height: 17)
                    Text("加日程")
                        .font(.sketch(11))
                        .foregroundStyle(Paper.accent)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func controlButton(title: String, glyph: SeamGlyph, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                SeamGlyphView(glyph: glyph)
                    .frame(width: 17, height: 17)
                Text(title)
                    .font(.sketch(11))
                    .foregroundStyle(Paper.faint)
            }
        }
        .buttonStyle(.plain)
    }

    /// 小时间轴：上一个/当前/下一个 + 短横刻度。它是 24 小时视图的"种子"——展开从这里开始
    @ViewBuilder
    private var contextTimeline: some View {
        if expanded {
            // 展开时占住位置（首页已淡出，尺寸只需接近）
            Color.clear.frame(height: 236)
        } else {
            VStack(spacing: 0) {
                if let previous = contextItems.previous {
                    ContextRow(item: previous, dayLabel: dayLabel(for: previous))
                }
                HourTick(width: 16, color: Paper.hairline)
                    .padding(.vertical, 9)

                if let current = contextItems.current {
                    CurrentBlock(
                        item: current,
                        dotColor: store.category(id: current.categoryID)?.color ?? Paper.faint
                    )
                    .padding(.vertical, 4)
                } else {
                    emptyBlock
                }

                HourTick(width: 16, color: Paper.hairline)
                    .padding(.vertical, 9)
                if let next = contextItems.next {
                    ContextRow(item: next, dayLabel: dayLabel(for: next))
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .matchedGeometryEffect(id: "timelineFocus", in: ns)
            .onTapGesture { onEnter() }
        }
    }

    /// 时间还在继续流动的暗示：几道渐隐的短横线
    private var flowTicks: some View {
        VStack(spacing: 7) {
            ForEach(0..<4, id: \.self) { index in
                HourTick(width: CGFloat(14 - index * 3), color: Paper.hairline.opacity(1.0 - Double(index) * 0.22))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 2)
    }

    private var emptyBlock: some View {
        VStack(spacing: 8) {
            Text("留白")
                .font(.sketch(24))
                .foregroundStyle(Paper.ink.opacity(0.75))
            Text(todayItems.isEmpty ? "这段日子还空着" : "今天剩下的时间，空着也好")
                .font(.sketch(12))
                .foregroundStyle(Paper.faint.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .background(
            SketchyRect(corner: 16)
                .fill(Paper.raised.opacity(0.35))
        )
        .overlay(
            SketchyRect(corner: 16)
                .stroke(Paper.hairline, style: StrokeStyle(lineWidth: 1.2, dash: [6, 5]))
        )
    }

    private func dayLabel(for item: ScheduleItem) -> String? {
        guard !calendar.isDate(item.day, inSameDayAs: day) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "d日"
        return formatter.string(from: item.day)
    }

    private var dayCaption: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 · EEE"
        return formatter.string(from: day)
    }

    private var dayBadge: String {
        let offset = day.dayOffset(from: Date())
        switch offset {
        case 0: return "今天"
        case -1: return "昨天"
        case 1: return "明天"
        default: return offset > 0 ? "+\(offset)天" : "\(offset)天"
        }
    }

    // MARK: 陪伴者互动（宪法 §12/§13）

    private func handleCompanionTap() {
        store.registerCompanionTap()

        var text: String?
        switch companionState {
        case .asleep:
            text = store.counters.tapsDuringSleep >= 1 ? "你真的在睡觉吗？" : "……呼"
        case .doing(let activity) where store.isFocusActivity(activity):
            let taps = store.counters.tapsDuringFocus
            if taps >= 20 && taps % 15 == 0 {
                text = "别摸鱼啦"
            } else if taps % 4 == 0 {
                text = ["嗯？", "在呢", "陪你"].randomElement()
            }
        case .doing:
            text = Int.random(in: 0..<4) == 0 ? ["嗯？", "在呢"].randomElement() : nil
        case .idle:
            text = Int.random(in: 0..<3) == 0 ? ["嗯？", "陪你", "·"].randomElement() : nil
        case .away:
            text = nil
        }

        guard let text else { return }
        quipTask?.cancel()
        withAnimation(.easeOut(duration: 0.22)) { quip = Quip(text: text) }
        quipTask = Task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.3)) { quip = nil }
        }
    }
}

// MARK: - 首页时间线行

struct ContextRow: View {
    let item: ScheduleItem
    let dayLabel: String?

    var body: some View {
        HStack(spacing: 12) {
            HourTick(width: 12, color: Paper.hairline.opacity(0.8))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(timeText)
                        .font(.sketch(11))
                        .foregroundStyle(Paper.faint.opacity(0.8))
                    if let dayLabel {
                        Text(dayLabel)
                            .font(.sketch(10))
                            .foregroundStyle(Paper.faint.opacity(0.6))
                    }
                }
                Text(item.activity)
                    .font(.sketch(16))
                    .foregroundStyle(Paper.ink.opacity(0.55))
            }
            Spacer()
        }
        .padding(.vertical, 3)
        .opacity(0.55)
    }

    private var timeText: String {
        String(format: "%02d:%02d", Int(item.startHour) % 24, Int((item.startHour.truncatingRemainder(dividingBy: 1)) * 60))
    }
}

/// 当前日程：虚线"活框"（宪法 R6）
struct CurrentBlock: View {
    let item: ScheduleItem
    let dotColor: Color

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 7) {
                Circle().fill(dotColor).frame(width: 6, height: 6)
                Text(timeRange)
                    .font(.sketch(12))
                    .foregroundStyle(Paper.faint)
                Spacer()
                if item.duration.truncatingRemainder(dividingBy: 1) == 0 {
                    Text("\(Int(item.duration))h")
                        .font(.sketch(11))
                        .foregroundStyle(Paper.faint.opacity(0.8))
                } else {
                    Text("\(item.duration)h")
                        .font(.sketch(11))
                        .foregroundStyle(Paper.faint.opacity(0.8))
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(item.activity)
                    .font(.sketch(25))
                    .foregroundStyle(Paper.ink)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.sketch(12))
                        .foregroundStyle(Paper.faint)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(SketchyRect(corner: 16).fill(Paper.raised.opacity(0.55)))
        .overlay(
            SketchyRect(corner: 16)
                .stroke(Paper.faint.opacity(0.55), style: StrokeStyle(lineWidth: 1.3, dash: [6, 5], dashPhase: 3))
        )
    }

    private var timeRange: String {
        func format(_ hour: Double) -> String {
            String(format: "%02d:%02d", Int(hour) % 24, Int((hour.truncatingRemainder(dividingBy: 1)) * 60))
        }
        return "\(format(item.startHour)) – \(format(item.endHour))"
    }
}
