// LensTabSwitcher.swift
// Floating glass pill tab switcher (Positions / Orders) with a pink lens
// indicator and drag-to-scrub. The liquid-glass refraction (suziLiquidLens)
// engages only while dragging. Ported from PositionsOrdersSheetView.

import SwiftUI

enum PositionsTab: String, CaseIterable, Identifiable {
    case positions
    case orders

    var id: String { rawValue }

    var title: String {
        switch self {
        case .positions: return "Positions"
        case .orders:    return "Orders"
        }
    }

    /// SF Symbol stand-ins for the app's custom `PositionIcon` / `OrdersIcon`.
    var systemIcon: String {
        switch self {
        case .positions: return "building.columns.fill"
        case .orders:    return "basket.fill"
        }
    }
}

struct LensTabSwitcher: View {
    @Binding var selectedTab: PositionsTab
    var isDisabled: Bool = false

    @State private var indicatorIndex = 0
    @State private var dragX: CGFloat?
    @State private var hoverTab: PositionsTab?

    private let tabs = Array(PositionsTab.allCases)

    private static let barWidth: CGFloat = 204
    private static let barHeight: CGFloat = 68
    private static let selectorInset: CGFloat = 4
    private static let tabSpacing: CGFloat = 8
    private static let iconSize: CGFloat = LensMetrics.tabIconSize
    private static let itemWidth: CGFloat = (barWidth - selectorInset * 2 - tabSpacing) / 2
    private static let indicatorHeight: CGFloat = barHeight - selectorInset * 2
    private static let morphAnimation = Animation.smooth(duration: 0.5)
    private static let indicatorAnimation = Animation.snappy(duration: 0.35, extraBounce: 0.08)

    var body: some View {
        let indicatorX = dragX ?? center(for: indicatorIndex)
        let isDragging = dragX != nil

        ZStack {
            glassLayer
            lensHighlight(indicatorX: indicatorX)
            contentLayer(indicatorX: indicatorX, isDragging: isDragging)

            Color.clear
                .frame(width: Self.barWidth, height: Self.barHeight)
                .contentShape(Rectangle())
                .gesture(scrubGesture)
        }
        .frame(width: Self.barWidth, height: Self.barHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Positions and orders")
        .accessibilityValue(selectedTab.title)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: moveSelection(by: 1)
            case .decrement: moveSelection(by: -1)
            default: break
            }
        }
        .onAppear { syncIndicator(animated: false) }
        .onChange(of: selectedTab) { _, _ in syncIndicator(animated: true) }
    }

    @ViewBuilder
    private var glassLayer: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 0) {
                GlassSurface.CapsuleGlass()
                    .frame(width: Self.barWidth, height: Self.barHeight)
            }
        } else {
            GlassSurface.CapsuleGlass()
                .frame(width: Self.barWidth, height: Self.barHeight)
        }
    }

    private func lensHighlight(indicatorX: CGFloat) -> some View {
        Capsule()
            .fill(Colors.accentPink.opacity(0.14))
            .overlay { Capsule().stroke(Colors.accentPink.opacity(0.08), lineWidth: 1.5) }
            .frame(width: Self.itemWidth, height: Self.indicatorHeight)
            .position(x: indicatorX, y: Self.barHeight / 2)
            .animation(Self.indicatorAnimation, value: indicatorIndex)
            .allowsHitTesting(false)
    }

    private func contentLayer(indicatorX: CGFloat, isDragging: Bool) -> some View {
        ZStack {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                tabContent(tab)
                    .position(x: center(for: index), y: Self.barHeight / 2)
            }
        }
        .frame(width: Self.barWidth, height: Self.barHeight)
        .suziLiquidLens(
            centerX: indicatorX,
            lensSize: CGSize(width: Self.itemWidth, height: Self.barHeight),
            amount: isDragging ? LensMetrics.lensRefractionAmount : 0,
            depth: LensMetrics.lensRefractionDepth
        )
    }

    private func tabContent(_ tab: PositionsTab) -> some View {
        let active = (hoverTab ?? selectedTab) == tab

        return VStack(spacing: 0.5) {
            Image(systemName: tab.systemIcon)
                .font(.system(size: Self.iconSize * 0.64, weight: .semibold))
                .frame(width: Self.iconSize, height: Self.iconSize)

            Text(tab.title)
                .font(.labelMedium)
                .tracking(-0.08)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .allowsTightening(true)
                .truncationMode(.tail)
        }
        .foregroundStyle(active ? Color.accent : Colors.mutedLabel)
        .frame(width: Self.itemWidth, height: Self.indicatorHeight)
        .compositingGroup()
        .allowsHitTesting(false)
        .geometryGroup()
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard !isDisabled else { return }
                guard inSpan(value.startLocation.x) else { return }
                guard abs(value.translation.width) > 4 else { return }

                let x = min(max(value.location.x, centers.first!), centers.last!)
                dragX = x

                let tab = tabs[nearestIndex(to: x)]
                if tab != hoverTab {
                    hoverTab = tab
                    Haptics.scrub()
                }
            }
            .onEnded { value in
                defer { hoverTab = nil }
                guard !isDisabled else { dragX = nil; return }
                guard inSpan(value.startLocation.x) else { dragX = nil; return }

                let x = min(max(value.location.x, centers.first!), centers.last!)
                select(tabs[nearestIndex(to: x)])
                withAnimation(Self.indicatorAnimation) { dragX = nil }
            }
    }

    private var centers: [CGFloat] { tabs.indices.map { center(for: $0) } }

    private func center(for index: Int) -> CGFloat {
        Self.selectorInset + Self.itemWidth / 2 + CGFloat(index) * (Self.itemWidth + Self.tabSpacing)
    }

    private func inSpan(_ x: CGFloat) -> Bool {
        let touchPadding: CGFloat = 16
        return x >= -touchPadding && x <= Self.barWidth + touchPadding
    }

    private func nearestIndex(to x: CGFloat) -> Int {
        centers.enumerated().min { abs($0.element - x) < abs($1.element - x) }?.offset ?? 0
    }

    private func select(_ tab: PositionsTab) {
        guard tab != selectedTab else { return }
        Haptics.selection()
        if let index = tabs.firstIndex(of: tab) { indicatorIndex = index }
        withAnimation(Self.morphAnimation) { selectedTab = tab }
    }

    private func syncIndicator(animated: Bool) {
        guard let index = tabs.firstIndex(of: selectedTab), indicatorIndex != index else { return }
        if animated {
            withAnimation(Self.indicatorAnimation) { indicatorIndex = index }
        } else {
            indicatorIndex = index
        }
    }

    private func moveSelection(by offset: Int) {
        guard let currentIndex = tabs.firstIndex(of: selectedTab) else { return }
        let newIndex = min(max(currentIndex + offset, 0), tabs.count - 1)
        guard newIndex != currentIndex else { return }
        select(tabs[newIndex])
    }
}
