//
//  Companion.swift
//  Schedule with you
//
//  陪伴者：不是宠物（宪法 §9-13）。
//  反映当前时间节律：有日程就做相关的事，空档可以发呆，偶尔离开留下小牌子。
//  互动：短、微妙、可选、看语境。
//

import SwiftUI

enum CompanionState: Equatable {
    case idle
    case doing(String)   // 活动名
    case asleep
    case away
}

struct Quip: Equatable {
    let text: String
    private let identifier = UUID()
}

struct CompanionStage: View {
    var companion: CompanionID
    var state: CompanionState
    var quip: Quip?
    var scale: CGFloat = 1
    var onTap: () -> Void

    @State private var breathe = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                if state == .away {
                    AwaySign()
                        .transition(.opacity)
                } else {
                    figure
                    prop
                    if let quip {
                        Text(quip.text)
                            .font(.sketch(13))
                            .foregroundStyle(Paper.faint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(SketchyRect(corner: 8).fill(Paper.raised.opacity(0.85)))
                            .offset(y: -30)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .id(String(describing: quip))
                    }
                }
            }
            .frame(height: 150 * scale)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
        .animation(Paper.sketchSpring, value: quip)
        .animation(.easeInOut(duration: 0.5), value: state == .away)
        .onAppear { breathe = true }
    }

    private var figure: some View {
        CompanionFigure(figureID: companion, asleep: state == .asleep)
            .stroke(Paper.ink.opacity(0.82), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .frame(width: 128, height: 114)
            .scaleEffect(breathe ? 1.016 : 1, anchor: .bottom)
            .scaleEffect(scale, anchor: .bottom)
            .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: breathe)
            .offset(y: state == .asleep ? 8 : 0)
    }

    @ViewBuilder
    private var prop: some View {
        switch state {
        case .asleep:
            Text("z z")
                .font(.sketch(14, .light))
                .foregroundStyle(Paper.faint.opacity(0.8))
                .scaleEffect(scale, anchor: .bottom)
                .offset(x: 62, y: 6)
        case .doing(let activity):
            CompanionProp(activity: activity)
                .stroke(Paper.ink.opacity(0.66), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .frame(width: 34, height: 24)
                .scaleEffect(scale, anchor: .bottom)
                .offset(y: 62)
        default:
            EmptyView()
        }
    }
}

/// 手绘小人：三种角色在耳朵/头顶装饰上略有差别
struct CompanionFigure: Shape {
    var figureID: CompanionID
    var asleep = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // 头
        path.addEllipse(in: CGRect(x: w * 0.30, y: h * 0.08, width: w * 0.40, height: h * 0.36))

        // 头顶装饰（角色差异）
        switch figureID {
        case .jing: // 猫耳
            path.move(to: CGPoint(x: w * 0.33, y: h * 0.15))
            path.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.03), control: CGPoint(x: w * 0.24, y: h * 0.11))
            path.addQuadCurve(to: CGPoint(x: w * 0.40, y: h * 0.08), control: CGPoint(x: w * 0.30, y: h * 0.03))
            path.move(to: CGPoint(x: w * 0.67, y: h * 0.15))
            path.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.03), control: CGPoint(x: w * 0.76, y: h * 0.11))
            path.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.08), control: CGPoint(x: w * 0.70, y: h * 0.03))
        case .ya: // 新芽
            path.move(to: CGPoint(x: w * 0.50, y: h * 0.10))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.01))
            path.move(to: CGPoint(x: w * 0.50, y: h * 0.045))
            path.addQuadCurve(to: CGPoint(x: w * 0.40, y: h * -0.01), control: CGPoint(x: w * 0.43, y: h * 0.01))
            path.move(to: CGPoint(x: w * 0.50, y: h * 0.045))
            path.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * -0.01), control: CGPoint(x: w * 0.57, y: h * 0.01))
        case .yue: // 月牙发髻
            path.move(to: CGPoint(x: w * 0.62, y: h * 0.085))
            path.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.075), control: CGPoint(x: w * 0.72, y: h * -0.01))
            path.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.13), control: CGPoint(x: w * 0.75, y: h * 0.09))
        }

        // 眼睛与嘴
        let eyeY = h * 0.27
        if asleep {
            path.move(to: CGPoint(x: w * 0.40, y: eyeY + 2))
            path.addQuadCurve(to: CGPoint(x: w * 0.46, y: eyeY + 2), control: CGPoint(x: w * 0.43, y: eyeY - 2))
            path.move(to: CGPoint(x: w * 0.54, y: eyeY + 2))
            path.addQuadCurve(to: CGPoint(x: w * 0.60, y: eyeY + 2), control: CGPoint(x: w * 0.57, y: eyeY - 2))
        } else {
            path.move(to: CGPoint(x: w * 0.43, y: eyeY))
            path.addLine(to: CGPoint(x: w * 0.43, y: eyeY + 0.8))
            path.move(to: CGPoint(x: w * 0.57, y: eyeY))
            path.addLine(to: CGPoint(x: w * 0.57, y: eyeY + 0.8))
        }
        path.move(to: CGPoint(x: w * 0.45, y: h * 0.345))
        path.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * 0.345), control: CGPoint(x: w * 0.50, y: h * 0.385))

        // 身体
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.44))
        path.addQuadCurve(to: CGPoint(x: w * 0.28, y: h * 0.88), control: CGPoint(x: w * 0.20, y: h * 0.62))
        path.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.88), control: CGPoint(x: w * 0.50, y: h * 1.02))
        path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.44), control: CGPoint(x: w * 0.80, y: h * 0.62))

        // 小手
        path.move(to: CGPoint(x: w * 0.36, y: h * 0.58))
        path.addQuadCurve(to: CGPoint(x: w * 0.47, y: h * 0.67), control: CGPoint(x: w * 0.40, y: h * 0.66))
        path.move(to: CGPoint(x: w * 0.64, y: h * 0.58))
        path.addQuadCurve(to: CGPoint(x: w * 0.53, y: h * 0.67), control: CGPoint(x: w * 0.60, y: h * 0.66))

        return path
    }
}

/// 陪同一件事时手边的小道具（占位线稿）
struct CompanionProp: Shape {
    var activity: String

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        switch activity {
        case "阅读", "刷题", "语言", "复盘", "写作": // 摊开的书
            path.move(to: CGPoint(x: w * 0.5, y: h * 0.2))
            path.addQuadCurve(to: CGPoint(x: w * 0.06, y: h * 0.35), control: CGPoint(x: w * 0.28, y: h * 0.14))
            path.addLine(to: CGPoint(x: w * 0.06, y: h * 0.8))
            path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.62), control: CGPoint(x: w * 0.28, y: h * 0.58))
            path.move(to: CGPoint(x: w * 0.5, y: h * 0.2))
            path.addQuadCurve(to: CGPoint(x: w * 0.94, y: h * 0.35), control: CGPoint(x: w * 0.72, y: h * 0.14))
            path.addLine(to: CGPoint(x: w * 0.94, y: h * 0.8))
            path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.62), control: CGPoint(x: w * 0.72, y: h * 0.58))
        case "画画", "动手做": // 小铅笔
            path.move(to: CGPoint(x: w * 0.15, y: h * 0.8))
            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.16))
            path.move(to: CGPoint(x: w * 0.75, y: h * 0.16))
            path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.30))
            path.move(to: CGPoint(x: w * 0.15, y: h * 0.8))
            path.addLine(to: CGPoint(x: w * 0.30, y: h * 0.84))
        case "音乐": // 音符
            path.addEllipse(in: CGRect(x: w * 0.18, y: h * 0.55, width: w * 0.22, height: h * 0.3))
            path.move(to: CGPoint(x: w * 0.40, y: h * 0.7))
            path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.06))
        default: // 小杯子
            path.move(to: CGPoint(x: w * 0.25, y: h * 0.15))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.75))
            path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.75))
            path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.15))
            path.move(to: CGPoint(x: w * 0.72, y: h * 0.3))
            path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.42), control: CGPoint(x: w * 0.86, y: h * 0.28))
        }
        return path
    }
}

/// 偶尔离开时留下的小牌子（宪法 §11 C）
struct AwaySign: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("去散步了")
                .font(.sketch(13))
                .foregroundStyle(Paper.faint)
            HourTick(width: 34, color: Paper.hairline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            SketchyRect(corner: 10)
                .stroke(Paper.hairline, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
        )
    }
}
