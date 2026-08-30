//
//  TimelineSection.swift
//  Schedule with you
//
//  2026-08-30 定稿：从首页"小时间轴"原地展开的 24 小时视图。
//  几何匹配动画：展开起点 = 小时间轴的框，收起时缩回原处。
//  退出：滚回最顶部、再向下拉一次（幅度门槛防误触）。
//  时间轴：只有短短横刻度，没有竖线（宪法 R1）；块可以拖动微调（15 分钟一档）。
//

import SwiftUI

struct ExpandedTimeline: View {
    @ObservedObject var store: ScheduleStore
    @Binding var day: Date
    var ns: Namespace.ID
    var onExit: () -> Void
    var onAdd: () -> Void

    @State private var atTop = true

    let unit: CGFloat = 54

    var body: some View {
        ZStack(alignment: .top) {
            Paper.background.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    timeline
                        .padding(.horizontal, 30)
                        .padding(.top, 104)
                        .padding(.bottom, 60)
                        .background(
                            GeometryReader { marker in
                                Color.clear.preference(
                                    key: ExpandedTopKey.self,
                                    value: marker.frame(in: .named("expandedTL")).minY
                                )
                            }
                        )
                }
                .coordinateSpace(name: "expandedTL")
                .onPreferenceChange(ExpandedTopKey.self) { value in
                    atTop = value > -2
                }
                .onAppear {
                    // 展开时正对着"现在"——和小时间轴关注的是同一段时间
                    proxy.scrollTo("now", anchor: .center)
                }
                .onChange(of: day) { _, _ in
                    if Calendar.current.isDateInToday(day) {
                        proxy.scrollTo("now", anchor: .center)
                    }
                }
                .simultaneousGesture(
                    // 退出：在最顶部再向下拉一次，收回到小时间轴
                    DragGesture(minimumDistance: 25)
                        .onEnded { value in
                            let dy = value.translation.height
                            guard atTop else { return }
                            guard dy > 110, dy > abs(value.translation.width) * 1.4 else { return }
                            onExit()
                        }
                )
            }

            header
        }
        .matchedGeometryEffect(id: "timelineFocus", in: ns, isSource: false)
    }

    // MARK: 顶栏：日期切换 + 加日程

    private var header: some View {
        HStack(spacing: 14) {
            dayPill

            Text(dayCaption)
                .font(.sketch(12))
                .foregroundStyle(Paper.faint.opacity(0.7))

            Spacer()

            Button(action: onAdd) {
                HStack(spacing: 7) {
                    SeamGlyphView(glyph: .plus, color: Paper.accent)
                        .frame(width: 12, height: 12)
                    Text("加日程")
                        .font(.sketch(13))
                        .foregroundStyle(Paper.accent)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 30)
        .padding(.top, 58)
        .padding(.bottom, 12)
        .background(Paper.background)
    }

    private var dayPill: some View {
        HStack(spacing: 14) {
            Button {
                moveDay(-1)
            } label: {
                Text("‹")
                    .font(.sketch(18, .light))
                    .foregroundStyle(Paper.faint)
                    .frame(width: 26, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(dayTitle)
                .font(.sketch(14))
                .foregroundStyle(Paper.ink.opacity(0.85))
                .frame(minWidth: 44)

            Button {
                moveDay(1)
            } label: {
                Text("›")
                    .font(.sketch(18, .light))
                    .foregroundStyle(Paper.faint)
                    .frame(width: 26, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            SketchyRect(corner: 15).fill(Paper.raised.opacity(0.9))
        )
        .overlay(
            SketchyRect(corner: 15).stroke(Paper.hairline, lineWidth: 1.1)
        )
    }

    // MARK: 24 小时时间轴

    private var dayItems: [ScheduleItem] { store.items(on: day) }

    private var timeline: some View {
        ZStack(alignment: .topLeading) {
            ticks
            nowMark
            ForEach(dayItems) { item in
                ScheduleBlock(
                    item: item,
                    unit: unit,
                    dotColor: store.category(id: item.categoryID)?.color ?? Paper.faint,
                    canAppreciate: store.canAppreciate(item),
                    onMove: { newStart in
                        store.updateStart(itemID: item.id, startHour: newStart)
                    },
                    onAppreciate: {
                        store.appreciate(itemID: item.id)
                    }
                )
                .offset(y: CGFloat(item.startHour) * unit)
            }

            if dayItems.isEmpty {
                Text("这一天还空着 · 也很好")
                    .font(.sketch(13))
                    .foregroundStyle(Paper.faint.opacity(0.6))
                    .padding(.leading, 96)
                    .padding(.top, 26)
            }
        }
        .frame(height: 24 * unit + 80, alignment: .top)
    }

    private var ticks: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0...24, id: \.self) { hour in
                HStack(spacing: 12) {
                    HourTick(
                        width: hour % 6 == 0 ? 22 : 11,
                        color: Paper.hairline
                    )
                    .padding(.leading, 26)

                    if (hour == 6 || hour == 12 || hour == 18) && hour < 24 {
                        Text(String(format: "%02d", hour))
                            .font(.sketch(10))
                            .foregroundStyle(Paper.faint.opacity(0.5))
                    }
                    Spacer()
                }
                .frame(height: unit)
            }
        }
    }

    @ViewBuilder
    private var nowMark: some View {
        if Calendar.current.isDateInToday(day) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Paper.accent.opacity(0.75))
                    .frame(width: 5, height: 5)
                    .padding(.leading, 24)
                HourTick(width: 26, color: Paper.accent.opacity(0.55), thickness: 1.2)
                Text("现在")
                    .font(.sketch(9.5))
                    .foregroundStyle(Paper.accent.opacity(0.7))
                Spacer()
            }
            .overlay(
                Color.clear.frame(width: 1, height: 1).id("now"),
                alignment: .leading
            )
            .offset(y: CGFloat(Date().hourDouble) * unit - 2)
        }
    }

    private func moveDay(_ delta: Int) {
        guard let moved = Calendar.current.date(byAdding: .day, value: delta, to: day) else { return }
        withAnimation(Paper.sketchSpring) { day = moved }
    }

    private var dayTitle: String {
        let offset = day.dayOffset(from: Date())
        switch offset {
        case 0: return "今天"
        case -1: return "昨天"
        case 1: return "明天"
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日"
            return formatter.string(from: day)
        }
    }

    private var dayCaption: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter.string(from: day)
    }
}

struct ExpandedTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 时间轴上的日程块

struct ScheduleBlock: View {
    var item: ScheduleItem
    var unit: CGFloat
    var dotColor: Color
    var canAppreciate: Bool
    var onMove: (Double) -> Void
    var onAppreciate: () -> Void

    @State private var dragOffset: CGFloat = 0

    private var height: CGFloat { max(item.duration * unit - 6, 32) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 7) {
                Circle().fill(dotColor).frame(width: 5.5, height: 5.5)
                Text(timeRange)
                    .font(.sketch(10.5))
                    .foregroundStyle(Paper.faint)
                if item.isAppreciated {
                    Text("还不错")
                        .font(.sketch(9.5))
                        .foregroundStyle(Paper.accent.opacity(0.8))
                }
            }
            Text(item.activity)
                .font(.sketch(16.5))
                .foregroundStyle(Paper.ink)
                .lineLimit(1)
            if height > 66 && !item.note.isEmpty {
                Text(item.note)
                    .font(.sketch(11))
                    .foregroundStyle(Paper.faint.opacity(0.85))
                    .lineLimit(2)
            }
            if canAppreciate && height > 40 {
                Button(action: onAppreciate) {
                    Text("还不错 · ×1.2")
                        .font(.sketch(11))
                        .foregroundStyle(Paper.accent.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().stroke(Paper.accent.opacity(0.4), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .frame(width: 272, height: height, alignment: .topLeading)
        .background(SketchyRect(corner: 13).fill(dotColor.opacity(0.10)))
        .overlay(
            SketchyRect(corner: 13)
                .stroke(dotColor.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
        )
        .offset(x: 68, y: dragOffset)
        .scaleEffect(dragOffset == 0 ? 1 : 1.015)
        .animation(Paper.sketchSpring, value: dragOffset == 0)
        .highPriorityGesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    let raw = item.startHour + Double(value.translation.height / unit)
                    let snapped = min(max((raw * 4).rounded() / 4, 0), 24 - item.duration)
                    dragOffset = 0
                    if abs(snapped - item.startHour) > 0.01 {
                        onMove(snapped)
                    }
                }
        )
    }

    private var timeRange: String {
        func format(_ hour: Double) -> String {
            String(format: "%02d:%02d", Int(hour) % 24, Int((hour.truncatingRemainder(dividingBy: 1)) * 60))
        }
        return "\(format(item.startHour)) – \(format(item.endHour))"
    }
}
