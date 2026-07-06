// PositionsScreen.swift
// Standalone reproduction of Suzi's Positions / Orders sheet for animation
// testing. Header with rolling title + Live/Closed pill, protocol-grouped
// collapsible cards, and the floating liquid-glass tab switcher + filter FAB.

import SwiftUI

struct PositionsScreen: View {
    @State private var selectedTab: PositionsTab = .positions
    @State private var showClosed = false
    @State private var collapsedKeys: Set<String> = []
    @State private var contentHeights: [String: CGFloat] = [:]
    @State private var tabLineSequence = 0
    // Live section positions, so collapsing a pinned section can scroll it to the
    // top (keeps it visible) rather than letting it jump away.
    @State private var sectionMinY = SectionMinYStore()
    // Measured scroll viewport height — the trailing space below the last section
    // is sized to this so the last section's header can pin to the very top and
    // stay there when collapsed (without the scroll clamping up and dragging the
    // previous section into view).
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                scrollContent
            }

            bottomDock
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { _, _ in tabLineSequence += 1 }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Colors.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack(alignment: .center) {
                RollingWord(
                    wordA: "Positions",
                    wordB: "Orders",
                    showingB: selectedTab == .orders,
                    font: Typography.title2,
                    color: .textPrimary,
                    height: 28,
                    rollDistance: 24
                )

                Spacer()

                liveClosedPill
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.md)
        }
    }

    private var liveClosedPill: some View {
        Button {
            Haptics.selection()
            showClosed.toggle()
        } label: {
            HStack(spacing: 6) {
                RollingWord(
                    wordA: "Live",
                    wordB: "Closed",
                    showingB: showClosed,
                    font: Typography.bodySemibold,
                    color: .textPrimary,
                    height: 20,
                    rollDistance: 18
                )
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Colors.mutedLabel)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(GlassSurface.CapsuleGlass())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
      ScrollViewReader { proxy in
        ScrollView {
            ZStack {
                if showClosed {
                    emptyClosedState
                } else if selectedTab == .positions {
                    positionsContent(proxy)
                } else {
                    ordersContent(proxy)
                }
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.sm)
            // Trailing room = one viewport (minus a header) so the LAST section's
            // header can pin to the very top and stay put when collapsed, instead
            // of the scroll clamping up and dragging the previous section in.
            .padding(.bottom, max(viewportHeight - CardMetrics.headerHeight, 400))
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Bottom-only edge fade so rows dissolve into the dock. No TOP fade — a
        // fade-to-clear there would dissolve the sticky headers as they pin; the
        // fixed title bar above already provides the top separation.
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0.0),
                    .init(color: .black, location: 0.94),
                    .init(color: .clear, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
      }
    }

    private func positionsContent(_ proxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: Spacing.xxl) {
            ForEach(Array(Mock.positionSections.enumerated()), id: \.element.id) { index, section in
                let key = "pos-\(section.id)"
                ProtocolCard(
                    sectionKey: key,
                    name: section.name,
                    logo: section.logo,
                    total: section.total,
                    showValue: true,
                    sectionIndex: index,
                    lineSequence: tabLineSequence,
                    isLast: index == Mock.positionSections.count - 1,
                    collapsedKeys: $collapsedKeys,
                    contentHeights: $contentHeights,
                    minYStore: sectionMinY,
                    // Quick scroll (faster than the 0.28s collapse) so the pinned
                    // header rolls up to the top cleanly as it collapses — minY
                    // reaches 0 before the height fully shrinks, so the exit-fade
                    // never dips and the section stays visible.
                    scrollToTop: { withAnimation(.easeOut(duration: 0.18)) { proxy.scrollTo(key, anchor: .top) } }
                ) {
                    LazyVStack(spacing: 0) {
                        ForEach(section.items) { item in
                            VStack(spacing: 0) {
                                if item.id != section.items.first?.id { RowDivider() }
                                positionRow(item)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.md)
                            }
                        }
                    }
                    .padding(.bottom, Spacing.md)
                }
                .id(key)
            }
        }
    }

    private func ordersContent(_ proxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: Spacing.xxl) {
            ForEach(Array(Mock.orderSections.enumerated()), id: \.element.id) { index, section in
                let key = "ord-\(section.id)"
                ProtocolCard(
                    sectionKey: key,
                    name: section.name,
                    logo: section.logo,
                    total: section.total,
                    showValue: true,
                    sectionIndex: index,
                    lineSequence: tabLineSequence,
                    isLast: index == Mock.orderSections.count - 1,
                    collapsedKeys: $collapsedKeys,
                    contentHeights: $contentHeights,
                    minYStore: sectionMinY,
                    // Quick scroll (faster than the 0.28s collapse) so the pinned
                    // header rolls up to the top cleanly as it collapses — minY
                    // reaches 0 before the height fully shrinks, so the exit-fade
                    // never dips and the section stays visible.
                    scrollToTop: { withAnimation(.easeOut(duration: 0.18)) { proxy.scrollTo(key, anchor: .top) } }
                ) {
                    LazyVStack(spacing: 0) {
                        ForEach(section.items) { order in
                            VStack(spacing: 0) {
                                if order.id != section.items.first?.id { RowDivider() }
                                OrderRowView(order: order)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.md)
                            }
                        }
                    }
                    .padding(.bottom, Spacing.md)
                }
                .id(key)
            }
        }
    }

    @ViewBuilder
    private func positionRow(_ item: PositionItem) -> some View {
        switch item.kind {
        case let .perp(symbol, subtitle, leverage, value, pnl, logo):
            PerpRowView(symbol: symbol, subtitle: subtitle, leverage: leverage,
                        value: value, pnl: pnl, logo: logo)
        case let .prediction(question, outcome, priceCents, pnl, value, avatar):
            PredictionRowView(question: question, outcome: outcome, priceCents: priceCents,
                              pnl: pnl, value: value, avatar: avatar)
        }
    }

    private var emptyClosedState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Colors.mutedLabel)
            Text("No closed \(selectedTab == .positions ? "positions" : "orders")")
                .font(Typography.bodySemibold)
                .foregroundColor(Colors.mutedLabel)
        }
        .frame(maxWidth: .infinity, minHeight: 480)
    }

    // MARK: - Bottom dock

    private var bottomDock: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            LensTabSwitcher(selectedTab: $selectedTab)
            Spacer()
            filterButton
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.bottom, Spacing.xxl)
    }

    private var filterButton: some View {
        Button {
            Haptics.selection()
        } label: {
            ZStack {
                GlassSurface.CircleGlass()
                    .frame(width: 68, height: 68)
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Colors.accentPink)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PositionsScreen()
}
