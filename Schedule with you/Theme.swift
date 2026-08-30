//
//  Theme.swift
//  Schedule with you
//
//  纸面视觉基调：米白纸、暖墨色、细淡线。
//  线条纪律（宪法 R1）：全局少线，不形成格子，不用纯黑。
//

import SwiftUI

enum Paper {
    static let background = Color(red: 0.980, green: 0.963, blue: 0.912)
    static let raised = Color(red: 0.956, green: 0.937, blue: 0.876)
    static let ink = Color(red: 0.216, green: 0.199, blue: 0.171)
    static let faint = Color(red: 0.552, green: 0.508, blue: 0.440)
    static let hairline = Color(red: 0.842, green: 0.802, blue: 0.720)
    static let accent = Color(red: 0.878, green: 0.486, blue: 0.220)

    static let sketchSpring = Animation.spring(response: 0.42, dampingFraction: 0.82)
}

extension Font {
    static func sketch(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

extension Color {
    init(paperHex hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}

/// 角落略微不均匀的圆角矩形——"活的框"（宪法 R6）
struct SketchyRect: Shape {
    var corner: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            topLeadingRadius: corner * 1.22,
            bottomLeadingRadius: corner * 0.82,
            bottomTrailingRadius: corner * 1.12,
            topTrailingRadius: corner * 0.74
        )
        .path(in: rect)
    }
}

/// 短横刻度：整个 App 里唯一被允许大量出现的线（宪法 R1）
struct HourTick: View {
    var width: CGFloat = 10
    var color: Color = Paper.hairline
    var thickness: CGFloat = 1.4

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: thickness)
    }
}

/// 抽屉页缘的返回小图标（手绘笔画，不用 SF Symbol）
enum SeamGlyph {
    case plus
    case person
    case dots
}

struct SeamGlyphView: View {
    let glyph: SeamGlyph
    var color: Color = Paper.faint

    var body: some View {
        Group {
            switch glyph {
            case .plus:
                PlusGlyph()
                    .stroke(color, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            case .person:
                PersonGlyph()
                    .stroke(color, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
            case .dots:
                HStack(spacing: 2.5) {
                    ForEach(0..<3) { _ in
                        Circle().fill(color).frame(width: 2.6, height: 2.6)
                    }
                }
            }
        }
        .frame(width: 15, height: 15)
    }
}

struct PlusGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + 1))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 1))
        p.move(to: CGPoint(x: rect.minX + 1, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.midY))
        return p
    }
}

struct PersonGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let headSize = rect.width * 0.38
        p.addEllipse(in: CGRect(
            x: rect.midX - headSize / 2,
            y: rect.minY + rect.height * 0.08,
            width: headSize,
            height: headSize
        ))
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - 1))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY - 1),
            control: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.52)
        )
        return p
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
