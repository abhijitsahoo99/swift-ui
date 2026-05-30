//
//  LiquidGlassDockBar.swift
//  xSidebarAnimation
//
//  Adapted from Suzi's PortfolioFloatingDock — generic 3-item dock with
//  sliding indicator capsule and a separate "+" FAB.
//

import SwiftUI

enum AppScreen: String, CaseIterable, Identifiable {
    case chat
    case agents
    case portfolio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat:      return "Chat"
        case .agents:    return "Agents"
        case .portfolio: return "Portfolio"
        }
    }

    var iconSF: String {
        switch self {
        case .chat:      return "message.fill"
        case .agents:    return "sparkles"
        case .portfolio: return "chart.pie.fill"
        }
    }
}

struct LiquidGlassDockBar: View {
    @Binding var selection: AppScreen
    var onPlusTap: () -> Void = {}

    @Namespace private var indicatorNS

    private let barHeight: CGFloat = 68
    private let selectorInset: CGFloat = 4

    var body: some View {
        HStack(spacing: 12) {
            tabPill
            plusButton
        }
        .padding(.horizontal, 16)
    }

    private var tabPill: some View {
        GeometryReader { geo in
            let items = AppScreen.allCases
            let innerWidth = geo.size.width - selectorInset * 2
            let itemWidth = innerWidth / CGFloat(items.count)
            let indicatorHeight = barHeight - selectorInset * 2
            let activeIndex = items.firstIndex(of: selection) ?? 0

            ZStack {
                barBackground

                // Sliding indicator
                indicatorCapsule(width: itemWidth, height: indicatorHeight)
                    .position(
                        x: selectorInset + itemWidth * 0.5 + itemWidth * CGFloat(activeIndex),
                        y: geo.size.height / 2
                    )
                    .animation(.snappy(duration: 0.35, extraBounce: 0.08), value: activeIndex)

                HStack(spacing: 0) {
                    ForEach(items) { item in
                        tabButton(item, isActive: item == selection)
                            .frame(width: itemWidth, height: indicatorHeight)
                    }
                }
                .padding(.horizontal, selectorInset)
            }
            .frame(width: geo.size.width, height: barHeight)
            .contentShape(Capsule())
        }
        .frame(height: barHeight)
    }

    private func tabButton(_ item: AppScreen, isActive: Bool) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.35, extraBounce: 0.08)) {
                selection = item
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.iconSF)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isActive ? .textPrimary : .textSecondary)
                Text(item.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(isActive ? .textPrimary : .textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func indicatorCapsule(width: CGFloat, height: CGFloat) -> some View {
        Capsule()
            .fill(Color.white.opacity(0.10))
            .overlay {
                Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.5)
            }
            .frame(width: width, height: height)
    }

    @ViewBuilder
    private var barBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: .capsule)
                .overlay {
                    Capsule().fill(Color.black.opacity(0.2)).blendMode(.screen)
                }
        } else {
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(Color.white.opacity(0.04))
                Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            }
        }
    }

    private var plusButton: some View {
        Button {
            onPlusTap()
        } label: {
            ZStack {
                plusBackground
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.accentPink)
            }
            .frame(width: barHeight, height: barHeight)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var plusBackground: some View {
        if #available(iOS 26.0, *) {
            Circle()
                .fill(.clear)
                .glassEffect(.regular.interactive(), in: .circle)
                .overlay {
                    Circle().fill(Color.black.opacity(0.2)).blendMode(.screen)
                }
        } else {
            ZStack {
                Circle().fill(.ultraThinMaterial)
                Circle().fill(Color.white.opacity(0.04))
                Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            }
        }
    }
}
