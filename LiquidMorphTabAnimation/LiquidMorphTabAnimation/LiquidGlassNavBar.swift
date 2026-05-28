//
//  LiquidGlassNavBar.swift
//  LiquidMorphTabAnimation
//
//  Suzi floating dock with a liquid-glass morph: in the Portfolio state the bar is a
//  Chat·Agents pill with a separate ＋ FAB; tapping Chat/Agents grows the bar into one
//  clean Chat·Agents·Portfolio bar while the FAB melts into it (and splits back apart).
//  Fusion uses a GlassEffectContainer — the technique from GlassMorphicTabs.
//

import SwiftUI
import UIKit

// MARK: - Layout metrics (matched 1:1 to suzi-swift `develop` branch)
//   PortfolioFloatingDock.Metrics + LiquidGlassDockBar's barHeight/selectorInset.
//   Frame is the (screen − horizontalInset*2) container width, so the same .padding(.leading/.trailing, 25)
//   positions Suzi uses translate to leading-anchored pill + trailing-anchored FAB inside this frame.
private enum K {
    static let pillW: CGFloat   = 204                       // Metrics.portfolioPillWidth
    static let pillH: CGFloat   = 68                        // Metrics.portfolioPillHeight
    static let fullW: CGFloat   = 316                       // Metrics.secondaryPillWidth
    static let frameW: CGFloat  = 352                       // iPhone 17 Pro width (402) − horizontalInset*2 (50)
    static let barH: CGFloat    = 68                        // LiquidGlassDockBar.barHeight
    static let inset: CGFloat   = 4                         // LiquidGlassDockBar.selectorInset
    static let fabD: CGFloat    = 68                        // Metrics.fabDiameter (was 60 on main)
    static let itemW: CGFloat   = (316 - 8) / 3             // LiquidGlassDockBar.itemWidth = 102.67
    static let barShift: CGFloat = (352 - 316) / 2          // 18 — bar centred in the 352 frame in state B
    static let bottomInset: CGFloat = 25                    // Metrics.bottomInset
    static let horizontalInset: CGFloat = 25                // Metrics.horizontalInset

    // Tab x-centres in the frame coord space.
    // Pill (state A): leading-aligned [0, 204]. HStack(spacing:8).padding(4) → button widths 94 each.
    //   Tab centres: 4+47 = 51, 4+94+8+47 = 153.
    // Bar (state B): bar 316 centred in 352 frame → at [18, 334]. Tab centres = barShift + inset + itemW*(i+0.5).
    static let chatPillX: CGFloat   = 51
    static let agentsPillX: CGFloat = 153
    static let chatBarX: CGFloat    = 18 + 4 + 102.6667 * 0.5   // 73.33
    static let agentsBarX: CGFloat  = 18 + 4 + 102.6667 * 1.5   // 176.00
    static let portfolioCX: CGFloat = 18 + 4 + 102.6667 * 2.5   // 278.67

    static let fabCX0: CGFloat = 352 - 68 / 2               // FAB centre at frame right (318)

    static let morph         = Animation.bouncy(duration: 0.55, extraBounce: 0.07)
    static let indicatorAnim = Animation.snappy(duration: 0.35, extraBounce: 0.08)
}

enum NavTab: String, CaseIterable, Identifiable {
    case chat, agents, portfolio
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    /// Suzi asset names from `develop` branch's PortfolioFloatingDock.dockIcon(for:).
    var asset: String {
        switch self {
        case .chat:      "TradeIcon"
        case .agents:    "Suzimascot"     // was "Icons" on main
        case .portfolio: "Portfolio"      // was SF dollarsign on main
        }
    }
    static let barTabs: [NavTab] = [.chat, .agents]
}

// MARK: - Public bar
struct LiquidGlassNavBar: View {
    @Binding var selected: NavTab
    @State private var progress: CGFloat = 0     // 0 = pill + FAB, 1 = 3-tab bar
    @State private var barIndex: Int = 0         // last chat/agents tab (indicator slot)
    private let haptic = UISelectionFeedbackGenerator()

    var body: some View {
        MorphingBar(progress: progress, selected: selected, barIndex: barIndex) { tab in
            guard tab != selected else { return }
            haptic.selectionChanged()
            if let i = NavTab.barTabs.firstIndex(of: tab) { barIndex = i }
            withAnimation(K.morph) {
                selected = tab
                progress = tab == .portfolio ? 0 : 1
            }
        }
        .frame(width: K.frameW, height: K.barH)
        .onAppear {
            progress = selected == .portfolio ? 0 : 1
            if let i = NavTab.barTabs.firstIndex(of: selected) { barIndex = i }
        }
    }
}

// MARK: - Animatable morphing bar
private struct MorphingBar: View, Animatable {
    var progress: CGFloat
    var selected: NavTab
    var barIndex: Int
    var onTap: (NavTab) -> Void

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var scaleProgress: CGFloat { progress > 0.5 ? (1 - progress) / 0.5 : progress / 0.5 }
    private var portfolioOpacity: CGFloat { max(0, (progress - 0.45) / 0.55) }

    var body: some View {
        let barWidth = K.pillW + (K.fullW - K.pillW) * progress         // 220 → 316
        let fabCX    = K.fabCX0 - (K.fabCX0 - K.portfolioCX) * progress // 302 → 263.33
        let chatX    = K.chatPillX + (K.chatBarX   - K.chatPillX)   * progress
        let agentsX  = K.agentsPillX + (K.agentsBarX - K.agentsPillX) * progress
        let indicatorBarX = (barIndex == 0 ? K.chatBarX : K.agentsBarX)
        let indicatorPillX = (barIndex == 0 ? K.chatPillX : K.agentsPillX)
        let indicatorX = indicatorPillX + (indicatorBarX - indicatorPillX) * progress
        let showFab = progress < 0.9

        ZStack {
            // 1. Glass — one clean bar capsule + the FAB, fused by the container as the
            //    growing bar reaches the FAB (FAB sits behind, so the bar engulfs it).
            glassContainer(spacing: 30 * progress) {
                ZStack {
                    if showFab {
                        glassCircle
                            .frame(width: K.fabD, height: K.fabD)
                            .position(x: fabCX, y: K.barH / 2)
                    }
                    capsuleGlass
                        .frame(width: barWidth, height: K.barH)
                        .position(x: barWidth / 2 + K.barShift * progress, y: K.barH / 2)
                }
                .frame(width: K.frameW, height: K.barH)
            }

            // 2. Sliding pink indicator — Suzi develop: fill accentPink @ 0.14, stroke @ 0.08, width = itemWidth.
            Capsule()
                .fill(Colors.accentPink.opacity(0.14))
                .overlay(Capsule().stroke(Colors.accentPink.opacity(0.08), lineWidth: 1.5))
                .frame(width: K.itemW, height: K.barH - K.inset * 2)
                .position(x: indicatorX, y: K.barH / 2)
                .opacity(progress)
                .animation(K.indicatorAnim, value: barIndex)
                .allowsHitTesting(false)

            // 3. Crisp content on top — eases between pill and bar positions.
            tabContent(.chat,      x: chatX)
            tabContent(.agents,    x: agentsX)
            tabContent(.portfolio, x: K.portfolioCX).opacity(portfolioOpacity)

            plusGlyph                                  // crossfades with the Portfolio tab at 263.33
                .position(x: fabCX, y: K.barH / 2)
                .opacity(1 - progress)
                .allowsHitTesting(false)
        }
        .frame(width: K.frameW, height: K.barH)
        .scaleEffect(x: 1 + scaleProgress * 0.02, y: 1 - scaleProgress * 0.03)
    }

    // MARK: tab content
    private func tabContent(_ tab: NavTab, x: CGFloat) -> some View {
        let active = tab == selected
        return Button { onTap(tab) } label: {
            VStack(spacing: 0.5) {                // Suzi develop: VStack(spacing: 0.5)
                Image(tab.asset)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28) // Metrics.tabIconSize = 28
                Text(tab.title)
                    .font(.labelMedium)           // Suzi develop: .labelMedium (13pt semibold rounded)
                    .tracking(-0.08)              // Suzi develop: tracking(-0.08)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .allowsTightening(true)
                    .truncationMode(.tail)
            }
            .foregroundStyle(active ? Color.accent : Colors.mutedLabel)   // Suzi develop colours
            .frame(width: K.itemW, height: K.barH - K.inset * 2)          // 60 = indicatorHeight
            .contentShape(Rectangle())
            .compositingGroup()                   // Suzi develop: rasterise icon+label together
        }
        .buttonStyle(.plain)
        .position(x: x, y: K.barH / 2)
        .allowsHitTesting(tab != .portfolio || progress > 0.9)
        .geometryGroup()                          // Suzi develop: resolve geometry atomically
    }

    // MARK: glass surfaces
    @ViewBuilder
    private func glassContainer<C: View>(spacing: CGFloat, @ViewBuilder _ content: () -> C) -> some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content() }
        } else {
            content()
        }
    }

    // Suzi develop's GlassSurface.CapsuleGlass / CircleGlass — glass + black-screen
    // overlay (no-op visually but mirrored for code parity) + 1.5pt navStroke.
    private static let navOverlay = Color.black.opacity(0.2)

    @ViewBuilder private var capsuleGlass: some View {
        if #available(iOS 26, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: .capsule)
                .overlay(Capsule().fill(Self.navOverlay).blendMode(.screen))
                .overlay(Capsule().stroke(Color.navStroke, lineWidth: 1.5))
        } else {
            Capsule()
                .fill(Color.backgroundSecondary)
                .overlay(Capsule().fill(Self.navOverlay).blendMode(.screen))
                .overlay(Capsule().stroke(Color.navStroke, lineWidth: 1.5))
        }
    }

    @ViewBuilder private var glassCircle: some View {
        if #available(iOS 26, *) {
            Circle()
                .fill(.clear)
                .glassEffect(.regular, in: .circle)
                .overlay(Circle().fill(Self.navOverlay).blendMode(.screen))
                .overlay(Circle().stroke(Color.navStroke, lineWidth: 1.5))
        } else {
            Circle()
                .fill(Color.backgroundSecondary)
                .overlay(Circle().fill(Self.navOverlay).blendMode(.screen))
                .overlay(Circle().stroke(Color.navStroke, lineWidth: 1.5))
        }
    }

    private var plusGlyph: some View {              // exact ＋ from Suzi's fabButton metrics
        ZStack {
            Capsule(style: .continuous).fill(Color.accent).frame(width: 15.7, height: 3.2)
            Capsule(style: .continuous).fill(Color.accent).frame(width: 3.2, height: 19.2)
        }
        .frame(width: 24, height: 24)                // Suzi develop: outer 24×24 frame
    }
}

// MARK: - Coming Soon (matches suzi-swift's ComingSoonScreen, with the tab name above)
struct ComingSoonScreen: View {
    let title: String
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Coming Soon")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.86))
            }
        }
    }
}

// MARK: - Demo host (screen content + floating dock)
struct NavBarDemo: View {
    @State private var selected: NavTab = .portfolio

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .portfolio: PortfolioScreen()
                case .chat:      ComingSoonScreen(title: "Chat")
                case .agents:    ComingSoonScreen(title: "Agents")
                }
            }
            .transition(.opacity)

            LiquidGlassNavBar(selected: $selected)
                .padding(.bottom, K.bottomInset)              // Suzi Metrics.bottomInset = 25
        }
        .ignoresSafeArea(.container, edges: .bottom)          // ZStack extends to screen edge → dock sits at the actual bottom
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: selected)
        .preferredColorScheme(.dark)
    }
}

#Preview { NavBarDemo() }
