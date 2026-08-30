//
//  Navigation.swift
//  Schedule with you
//
//  抽屉导航引擎（宪法 R5 + 2026-08-30 修订）：
//  - 按钮位置对应抽屉方向：左钮出左抽屉，中钮出上抽屉，右钮出右抽屉
//  - 抽屉只出 95%，露出的原界面模糊处理
//  - 进入只允许点击；退出 = 往反方向滑动，或点击页缘细线上的返回图标
//  - 手势轴向锁定：拉抽屉时只认左右，拉上下页时只认上下
//

import SwiftUI

struct DrawerHost<Content: View>: View {
    let edge: Edge
    let glyph: SeamGlyph
    var allowsExitGesture = true
    let onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var shown = false
    @State private var dragOffset: CGFloat = 0
    @State private var lockedAxis: Axis?

    private var isVerticalDrawer: Bool { edge == .top || edge == .bottom }

    /// 退出抽屉只认这个轴，其他轴的动作一律忽略
    private var exitAxis: Axis { isVerticalDrawer ? .vertical : .horizontal }

    var body: some View {
        GeometryReader { geo in
            let full = (isVerticalDrawer ? geo.size.height : geo.size.width) + 60

            ZStack {
                Paper.background.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { close() }

                content()
                    .frame(
                        width: isVerticalDrawer ? nil : geo.size.width * 0.95,
                        height: isVerticalDrawer ? geo.size.height * 0.95 : nil
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: restAnchor)
                    .background(Paper.background.ignoresSafeArea())
                    .overlay(alignment: seamAlignment) { seam }
                    .offset(offsetVector(full: full))
                    .simultaneousGesture(exitGesture(full: full))
            }
            .onAppear {
                guard !shown else { return }
                withAnimation(Paper.sketchSpring) { shown = true }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: 位移

    private var restAnchor: Alignment {
        switch edge {
        case .leading: return .leading
        case .trailing: return .trailing
        case .top, .bottom: return .top
        }
    }

    private func closedOffset(full: CGFloat) -> CGFloat {
        switch edge {
        case .leading: return -full
        case .trailing: return full
        case .top, .bottom: return -full
        }
    }

    private func offsetVector(full: CGFloat) -> CGSize {
        let base = shown ? 0 : closedOffset(full: full)
        switch edge {
        case .leading: return CGSize(width: base + min(dragOffset, 0), height: 0)
        case .trailing: return CGSize(width: base + max(dragOffset, 0), height: 0)
        case .top, .bottom: return CGSize(width: 0, height: base + min(dragOffset, 0))
        }
    }

    private func exitGesture(full: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard allowsExitGesture else { return }
                // 轴向锁定：第一次明显的移动决定方向，之后整段手势只认这个轴
                if lockedAxis == nil {
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    if max(dx, dy) > 14 {
                        lockedAxis = dx > dy ? .horizontal : .vertical
                    }
                }
                guard lockedAxis == exitAxis else { return }
                switch edge {
                case .leading: dragOffset = min(value.translation.width, 0)
                case .trailing: dragOffset = max(value.translation.width, 0)
                case .top, .bottom: dragOffset = min(value.translation.height, 0)
                }
            }
            .onEnded { value in
                defer {
                    lockedAxis = nil
                    withAnimation(Paper.sketchSpring) { dragOffset = 0 }
                }
                guard allowsExitGesture, lockedAxis == exitAxis else { return }

                let moved: CGFloat
                switch edge {
                case .leading: moved = -value.translation.width
                case .trailing: moved = value.translation.width
                case .top, .bottom: moved = -value.translation.height
                }
                if moved > 90 {
                    withAnimation(Paper.sketchSpring) {
                        dragOffset = 0
                        shown = false
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        onDismiss()
                    }
                }
            }
    }

    private func close() {
        guard shown else { return }
        withAnimation(.easeIn(duration: 0.26)) { shown = false }
        Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            onDismiss()
        }
    }

    // MARK: 页缘细线 + 返回图标（宪法 R1/R5）
    // 细线画在抽屉与原界面相接的那条边上，把手是抽屉的"脸"

    private var seamAlignment: Alignment {
        switch edge {
        case .leading: return .trailing   // 左抽屉 → 内缘在右侧
        case .trailing: return .leading   // 右抽屉 → 内缘在左侧
        case .top, .bottom: return .bottom
        }
    }

    @ViewBuilder
    private var seam: some View {
        switch edge {
        case .leading:
            ZStack(alignment: .trailing) {
                Rectangle()
                    .fill(Paper.hairline)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 90)
                SeamHandle(glyph: glyph) { close() }
                    .offset(x: -13.5)
            }
        case .trailing:
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Paper.hairline)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 90)
                SeamHandle(glyph: glyph) { close() }
                    .offset(x: 13.5)
            }
        case .top, .bottom:
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Paper.hairline)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 26)
                SeamHandle(glyph: glyph) { close() }
                    .offset(y: -13.5)
            }
        }
    }
}

/// 页缘返回图标：抽屉的"把手"
struct SeamHandle: View {
    let glyph: SeamGlyph
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Paper.background)
                Circle()
                    .stroke(Paper.hairline, lineWidth: 1.2)
                SeamGlyphView(glyph: glyph)
            }
            .frame(width: 27, height: 27)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
