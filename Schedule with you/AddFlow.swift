//
//  AddFlow.swift
//  Schedule with you
//
//  加日程（宪法 R5：从左侧抽入，⊕ 把手在左缘；后续步骤页从右推入，右滑退回上一步）。
//  两条确认路（手稿）：「输入确定」= 直接输时间；「拖动确定」= 把粗块拖到开始时间。
//

import SwiftUI

struct AddFlowView: View {
    @ObservedObject var store: ScheduleStore
    var initialDay: Date
    var onClose: () -> Void
    /// 是否停在第一步（大类）——此时右滑交给抽屉引擎去关闭，才有滑出的动画
    @Binding var atFirstStep: Bool

    private enum Step: Int {
        case category = 0, activity, configure, place
    }

    @State private var step: Step = .category
    @State private var forward = true

    @State private var categoryID = ""
    @State private var activity = ""
    @State private var note = ""
    @State private var day = Calendar.current.startOfDay(for: Date())
    @State private var startHour: Double = 9
    @State private var duration: Double = 1

    @State private var addingCustomActivity = false
    @State private var customActivityName = ""
    @State private var showingTimeInput = false
    @State private var showingCustomDate = false
    @State private var inputHour = 9
    @State private var inputMinute = 0
    @State private var placedPulse = false

    private var category: ActivityCategory? { store.category(id: categoryID) }

    var body: some View {
        VStack(spacing: 0) {
            header

            ZStack {
                if step == .category { categoryStep.transition(stepTransition) }
                if step == .activity { activityStep.transition(stepTransition) }
                if step == .configure { configureStep.transition(stepTransition) }
                if step == .place { placeStep.transition(stepTransition) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(Paper.sketchSpring, value: step)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 30)
        .padding(.top, 64)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Paper.background.ignoresSafeArea())
        .simultaneousGesture(
            DragGesture(minimumDistance: 26)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height),
                          value.translation.width > 70 else { return }
                    back()
                }
        )
    }

    private var stepTransition: AnyTransition {
        if forward {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
        return .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(stepCaption)
                .font(.sketch(13))
                .foregroundStyle(Paper.faint.opacity(0.75))
            Spacer()
            Text(stepProgress)
                .font(.sketch(12))
                .foregroundStyle(Paper.faint.opacity(0.55))
        }
        .padding(.bottom, 22)
    }

    private var stepCaption: String {
        switch step {
        case .category: return "想放进哪一类时间"
        case .activity: return "做点什么"
        case .configure: return "大概多久"
        case .place: return "把它放到什么时候"
        }
    }

    private var stepProgress: String {
        let names = ["大类", "小事", "时长", "放置"]
        let index = min(Int(step.rawValue), names.count - 1)
        return names[index]
    }

    private func advance(to next: Step) {
        guard next.rawValue > step.rawValue else { return }
        atFirstStep = false
        withAnimation(Paper.sketchSpring) {
            forward = true
            step = next
        }
    }

    private func back() {
        if showingTimeInput {
            withAnimation { showingTimeInput = false }
            return
        }
        // 第一步时右滑什么都不做：抽屉引擎会接管，把抽屉滑回右边
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        if previous == .category { atFirstStep = true }
        withAnimation(Paper.sketchSpring) {
            forward = false
            step = previous
        }
    }

    // MARK: - 第一步：大类（手稿：竖排的大框）

    private var categoryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(store.categories) { candidate in
                Button {
                    categoryID = candidate.id
                    activity = candidate.activities.first ?? ""
                    advance(to: .activity)
                } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(candidate.color.opacity(0.85))
                            .frame(width: 8, height: 8)
                        Text(candidate.name)
                            .font(.sketch(20))
                            .foregroundStyle(Paper.ink)
                        Spacer()
                        Text("\(candidate.activities.count)")
                            .font(.sketch(11))
                            .foregroundStyle(Paper.faint.opacity(0.55))
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 58)
                    .background(SketchyRect(corner: 15).fill(Paper.raised.opacity(0.5)))
                    .overlay(SketchyRect(corner: 15).stroke(Paper.hairline, lineWidth: 1.1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - 第二步：小事（含自定义，开放接口）

    private var activityStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let category {
                FlowChips(
                    items: category.activities.isEmpty ? ["（先加一个）"] : category.activities,
                    selected: activity
                ) { chosen in
                    activity = chosen
                    advance(to: .configure)
                }

                if addingCustomActivity {
                    HStack(spacing: 12) {
                        TextField("它的名字", text: $customActivityName)
                            .font(.sketch(15))
                            .textFieldStyle(.plain)
                        Rectangle().fill(Paper.hairline).frame(width: 34, height: 1)
                        Button("好") {
                            store.addCustomActivity(customActivityName, to: category.id)
                            activity = customActivityName
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            customActivityName = ""
                            addingCustomActivity = false
                            advance(to: .configure)
                        }
                        .font(.sketch(15))
                        .foregroundStyle(Paper.accent)
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                    .transition(.opacity)
                } else {
                    Button {
                        withAnimation { addingCustomActivity = true }
                    } label: {
                        HStack(spacing: 8) {
                            SeamGlyphView(glyph: .plus, color: Paper.faint.opacity(0.8))
                                .frame(width: 11, height: 11)
                            Text("加自定义")
                                .font(.sketch(13))
                                .foregroundStyle(Paper.faint)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding(.top, 10)
        .animation(.easeOut(duration: 0.25), value: addingCustomActivity)
    }

    // MARK: - 第三步：时长 / 日期 / 两条确认路

    private var configureStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(displayTitle)
                .font(.sketch(27))
                .foregroundStyle(Paper.ink)

            durationRow

            dayRow

            HStack(spacing: 10) {
                TextField("备注（可以不写）", text: $note)
                    .font(.sketch(13))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Paper.ink.opacity(0.8))
                Rectangle().fill(Paper.hairline).frame(height: 1)
            }
            .padding(.top, 2)

            Spacer()

            if showingTimeInput {
                timeInputPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                confirmCircles
                    .transition(.opacity)
            }
        }
        .padding(.top, 8)
        .animation(.easeOut(duration: 0.28), value: showingTimeInput)
    }

    private var displayTitle: String {
        activity
    }

    private var durationRow: some View {
        HStack {
            Text("时长")
                .font(.sketch(13))
                .foregroundStyle(Paper.faint)
            Spacer()
            Button {
                duration = max(0.5, duration - 0.5)
            } label: {
                Text("−").font(.sketch(20, .light)).foregroundStyle(Paper.faint)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(durationText)
                .font(.sketch(17))
                .foregroundStyle(Paper.ink)
                .frame(minWidth: 66)

            Button {
                duration = min(12, duration + 0.5)
            } label: {
                Text("+").font(.sketch(20, .light)).foregroundStyle(Paper.faint)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var durationText: String {
        duration.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(duration)) 小时"
            : "\(duration) 小时"
    }

    private var dayRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("哪天")
                    .font(.sketch(13))
                    .foregroundStyle(Paper.faint)
                    .padding(.trailing, 2)
                ForEach([-1, 0, 1, 2], id: \.self) { offset in
                    let candidateDay = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                    dayChip(candidateDay, label: dayChipLabel(offset))
                }
                Button {
                    withAnimation(.easeOut(duration: 0.22)) { showingCustomDate.toggle() }
                } label: {
                    Text("自选")
                        .font(.sketch(13))
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(showingCustomDate ? Paper.background : Paper.faint)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(showingCustomDate ? Paper.ink.opacity(0.85) : Color.clear))
                        .overlay(Capsule().stroke(showingCustomDate ? Color.clear : Paper.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            if showingCustomDate {
                DatePicker("", selection: $day, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .font(.sketch(13))
                    .transition(.opacity)
            }
        }
    }

    private func dayChipLabel(_ offset: Int) -> String {
        switch offset {
        case -1: return "昨天"
        case 0: return "今天"
        case 1: return "明天"
        default: return "后天"
        }
    }

    private func dayChip(_ candidateDay: Date, label: String) -> some View {
        let selected = Calendar.current.isDate(day, inSameDayAs: candidateDay)
        return Button {
            withAnimation(Paper.sketchSpring) { day = candidateDay }
        } label: {
            Text(label)
                .font(.sketch(13))
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(selected ? Paper.background : Paper.faint)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(selected ? Paper.ink.opacity(0.85) : Color.clear)
                )
                .overlay(Capsule().stroke(selected ? Color.clear : Paper.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    /// 两个确认圆（手稿：右下的两个小圈）
    private var confirmCircles: some View {
        HStack {
            Spacer()
            HStack(spacing: 40) {
                confirmCircle(label: "输入确定") {
                    inputHour = Int(startHour) % 24
                    inputMinute = [0, 15, 30, 45].first(where: { abs($0 - Int((startHour - startHour.rounded(.down)) * 60)) <= 7 }) ?? 0
                    withAnimation { showingTimeInput = true }
                }
                confirmCircle(label: "拖动确定") {
                    advance(to: .place)
                }
            }
            .padding(.trailing, 26)
        }
        .padding(.bottom, 6)
    }

    private func confirmCircle(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().stroke(Paper.hairline, lineWidth: 1.2)
                    SeamGlyphView(glyph: label.hasPrefix("输入") ? .dots : .plus, color: Paper.faint)
                }
                .frame(width: 46, height: 46)
                Text(label)
                    .font(.sketch(12))
                    .foregroundStyle(Paper.faint)
            }
        }
        .buttonStyle(.plain)
    }

    /// 输入确定：小时/分钟两个小转轮
    private var timeInputPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Picker("", selection: $inputHour) {
                    ForEach(0..<24, id: \.self) { Text("\($0) 时").font(.sketch(14)).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(width: 110, height: 104)
                .clipped()

                Picker("", selection: $inputMinute) {
                    ForEach([0, 15, 30, 45], id: \.self) { Text("\($0) 分").font(.sketch(14)).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(width: 110, height: 104)
                .clipped()
            }

            Button {
                startHour = Double(inputHour) + Double(inputMinute) / 60
                createItem()
            } label: {
                Text("就定这个时候")
                    .font(.sketch(15))
                    .foregroundStyle(Paper.accent)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - 第四步：拖到时间轴上

    private let placeUnit: CGFloat = 26

    private var placeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("长按块拖到开始的时间，松手就放好")
                .font(.sketch(12))
                .foregroundStyle(Paper.faint.opacity(0.8))

            ScrollView(showsIndicators: false) {
                PlacementTimeline(
                    day: day,
                    unit: placeUnit,
                    duration: duration,
                    startHour: startHour,
                    dotColor: category?.color ?? Paper.faint,
                    title: activity,
                    pulse: placedPulse
                ) { newStart in
                    startHour = newStart
                    placedPulse = true
                    Task {
                        try? await Task.sleep(nanoseconds: 330_000_000)
                        createItem()
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private func createItem() {
        let item = ScheduleItem(
            day: day,
            categoryID: categoryID,
            activity: activity,
            note: note,
            startHour: startHour,
            duration: duration
        )
        store.add(item)
        onClose()
    }
}

// MARK: - 放置时间轴（短横刻度 + 可拖的粗块）

struct PlacementTimeline: View {
    var day: Date
    var unit: CGFloat
    var duration: Double
    var startHour: Double
    var dotColor: Color
    var title: String
    var pulse: Bool
    var onPlace: (Double) -> Void

    @State private var dragOffset: CGFloat = 0

    private var nowHour: Double? {
        Calendar.current.isDateInToday(day) ? Date().hourDouble : nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0...24, id: \.self) { hour in
                    HStack(spacing: 10) {
                        HourTick(
                            width: hour % 6 == 0 ? 20 : 10,
                            color: isNowHour(hour) ? Paper.faint : Paper.hairline
                        )
                        if hour % 6 == 0 && hour < 24 {
                            Text(String(format: "%02d", hour))
                                .font(.sketch(10))
                                .foregroundStyle(Paper.faint.opacity(0.55))
                        }
                        Spacer()
                    }
                    .frame(height: unit)
                }
            }

            block
                .offset(y: CGFloat(startHour) * unit + dragOffset)
        }
        .frame(height: 25 * unit, alignment: .top)
        .padding(.top, 4)
    }

    private func isNowHour(_ hour: Int) -> Bool {
        guard let nowHour else { return false }
        return hour == Int(nowHour)
    }

    private var block: some View {
        HStack(spacing: 8) {
            Circle().fill(dotColor).frame(width: 6, height: 6)
            Text(title)
                .font(.sketch(14))
                .foregroundStyle(Paper.ink)
                .lineLimit(1)
            if duration >= 1 {
                Text(duration.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(duration))h" : "\(duration)h")
                    .font(.sketch(10))
                    .foregroundStyle(Paper.faint)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: max(duration * unit - 8, 30), alignment: .center)
        .background(
            SketchyRect(corner: 12).fill(dotColor.opacity(0.10))
        )
        .overlay(
            SketchyRect(corner: 12)
                .stroke(dotColor.opacity(0.55), style: StrokeStyle(lineWidth: 1.3, dash: [5, 4]))
        )
        .scaleEffect(pulse ? 0.94 : 1)
        .animation(Paper.sketchSpring, value: pulse)
        .padding(.trailing, 30)
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    let raw = startHour + Double(value.translation.height / unit)
                    let snapped = min(max((raw * 2).rounded() / 2, 0), 24 - duration)
                    dragOffset = 0
                    onPlace(snapped)
                }
        )
    }
}

// MARK: - 细分小片

struct FlowChips: View {
    var items: [String]
    var selected: String
    var select: (String) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 74), spacing: 14)],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(items, id: \.self) { item in
                Button {
                    select(item)
                } label: {
                    Text(item)
                        .font(.sketch(14))
                        .foregroundStyle(item == selected ? Paper.background : Paper.ink.opacity(0.75))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(item == selected ? Paper.ink.opacity(0.8) : Color.clear))
                        .overlay(Capsule().stroke(item == selected ? Color.clear : Paper.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
