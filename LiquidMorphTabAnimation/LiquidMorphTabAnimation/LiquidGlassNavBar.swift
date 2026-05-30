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
//   `internal` (not private) so InteractiveGlassNavBar can share these exact metrics.
enum K {
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

    static let morph         = Animation.smooth(duration: 0.5)
    static let indicatorAnim = Animation.snappy(duration: 0.35, extraBounce: 0.08)

    // Liquid-lens refraction (GSControl LiquidLens.metal) — applied only while scrubbing.
    static let refractAmount: CGFloat = 10      // pixel bend at the lens edge
    static let refractDepth:  CGFloat = 16      // edge falloff depth in points
    static let refractionEnabled = true         // needs LiquidLens.metal + Metal toolchain installed
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

/// The two skins of the ONE bar. The morph + scrub are identical; only the selection highlight differs.
///   .lens  — subtle pink pill + GSControl metal liquid-lens refraction under it (geometry bend).
///   .glass — CustomGlassTabBar pink interactive-glass pill that squishes as it scrubs.
enum NavBarLook { case lens, glass }

// MARK: - Public bar
struct LiquidGlassNavBar: View {
    @Binding var selected: NavTab
    var look: NavBarLook = .lens
    var onFabTap: () -> Void = {}
    var fabHidden: Bool = false
    @State private var progress: CGFloat = 0     // 0 = pill + FAB, 1 = 3-tab bar
    @State private var barIndex: Int = 0         // last chat/agents tab (indicator slot)
    private let haptic = UISelectionFeedbackGenerator()

    var body: some View {
        MorphingBar(progress: progress, selected: selected, barIndex: barIndex, look: look, fabHidden: fabHidden, onFabTap: onFabTap) { tab in
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
    var look: NavBarLook
    var fabHidden: Bool
    var onFabTap: () -> Void
    var onTap: (NavTab) -> Void

    @State private var dragX: CGFloat? = nil      // active scrub position (nil when not dragging)
    @State private var hoverTab: NavTab? = nil    // tab under the pill mid-scrub (live label colour)

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var scaleProgress: CGFloat { progress > 0.5 ? (1 - progress) / 0.5 : progress / 0.5 }
    private var portfolioOpacity: CGFloat { max(0, (progress - 0.45) / 0.55) }

    var body: some View {
        // Cubic ease-out applied only to the bar geometry, so the right edge reaches
        // its final position in the first ~75% of the morph and the trailing pixels
        // settle imperceptibly — instead of visibly stretching after Chat looks done.
        let inv = 1 - progress
        let widthEase = 1 - inv * inv * inv
        let barWidth = K.pillW + (K.fullW - K.pillW) * widthEase        // 204 → 316
        let fabCX    = K.fabCX0 - (K.fabCX0 - K.portfolioCX) * widthEase // 318 → 278.67
        let chatX    = K.chatPillX + (K.chatBarX   - K.chatPillX)   * progress
        let agentsX  = K.agentsPillX + (K.agentsBarX - K.agentsPillX) * progress
        let indicatorBarX = (barIndex == 0 ? K.chatBarX : K.agentsBarX)
        let indicatorPillX = (barIndex == 0 ? K.chatPillX : K.agentsPillX)
        let restingIndicatorX = indicatorPillX + (indicatorBarX - indicatorPillX) * progress
        let indicatorX = dragX ?? restingIndicatorX        // follow the finger while scrubbing
        let isDragging = dragX != nil
        let showFab = progress < 0.9 && !fabHidden

        // Layers are extracted into helpers below so the type-checker stays fast (inline
        // conditionals in one big ZStack trip the "expression too complex" builder error).
        ZStack {
            glassLayer(barWidth: barWidth, fabCX: fabCX, widthEase: widthEase,
                       indicatorX: indicatorX, isDragging: isDragging, showFab: showFab)

            lensHighlight(indicatorX: indicatorX, isDragging: isDragging)

            contentLayer(chatX: chatX, agentsX: agentsX, indicatorX: indicatorX, isDragging: isDragging)

            plusGlyph                                  // crossfades with the Portfolio tab at 263.33
                .position(x: fabCX, y: K.barH / 2)
                .opacity(fabHidden ? 0 : (1 - progress))
                .allowsHitTesting(false)

            // Scrub hit layer — full frame so the DragGesture reads frame coordinates. It sits
            // BELOW the FAB button (added next) so ＋ taps win; inSpan() limits which touches act.
            Color.clear
                .frame(width: K.frameW, height: K.barH)
                .contentShape(Rectangle())
                .gesture(scrubGesture)

            // Invisible tap target over the FAB — only active while the ＋ is the visible affordance.
            Button(action: onFabTap) {
                Color.clear
                    .frame(width: K.fabD, height: K.fabD)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .position(x: fabCX, y: K.barH / 2)
            .allowsHitTesting(progress < 0.5 && !fabHidden)
        }
        .frame(width: K.frameW, height: K.barH)
        .scaleEffect(x: 1 + scaleProgress * 0.02, y: 1 - scaleProgress * 0.03)
    }

    // MARK: - Layers

    // 1. Bar glass + FAB, fused by the container. In GLASS look the pink interactive-glass pill
    //    also lives inside the container so it liquid-merges with the bar and squishes on drag.
    @ViewBuilder
    private func glassLayer(barWidth: CGFloat, fabCX: CGFloat, widthEase: CGFloat,
                            indicatorX: CGFloat, isDragging: Bool, showFab: Bool) -> some View {
        glassContainer(spacing: 30 * progress) {
            ZStack {
                if showFab {
                    glassCircle
                        .frame(width: K.fabD, height: K.fabD)
                        .position(x: fabCX, y: K.barH / 2)
                }
                capsuleGlass
                    .frame(width: barWidth, height: K.barH)
                    .position(x: barWidth / 2 + K.barShift * widthEase, y: K.barH / 2)

                if look == .glass {
                    interactiveGlassPill
                        .frame(width: K.itemW, height: K.barH - K.inset * 2)
                        .scaleEffect(x: isDragging ? 1.12 : 1.0, y: isDragging ? 0.90 : 1.0)
                        .position(x: indicatorX, y: K.barH / 2)
                        .opacity(isDragging ? 1 : progress)
                        .animation(K.indicatorAnim, value: barIndex)     // same trigger as lens — no morph fight
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isDragging)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: K.frameW, height: K.barH)
        }
    }

    // 2. LENS look: the SUBTLE pink pill (accentPink @ 0.14 / stroke @ 0.08). Never flares bright.
    @ViewBuilder
    private func lensHighlight(indicatorX: CGFloat, isDragging: Bool) -> some View {
        if look == .lens {
            Capsule()
                .fill(Colors.accentPink.opacity(0.14))
                .overlay(Capsule().stroke(Colors.accentPink.opacity(0.08), lineWidth: 1.5))
                .frame(width: K.itemW, height: K.barH - K.inset * 2)
                .position(x: indicatorX, y: K.barH / 2)
                .opacity(isDragging ? 1 : progress)
                .animation(K.indicatorAnim, value: barIndex)
                .allowsHitTesting(false)
        }
    }

    // 3. Crisp icons + labels. In LENS look the metal liquid-lens bends what's under the pill while
    //    scrubbing (geometry only); in GLASS look there is no shader.
    private func contentLayer(chatX: CGFloat, agentsX: CGFloat, indicatorX: CGFloat, isDragging: Bool) -> some View {
        ZStack {
            tabContent(.chat,      x: chatX)
            tabContent(.agents,    x: agentsX)
            tabContent(.portfolio, x: K.portfolioCX).opacity(portfolioOpacity)
        }
        .frame(width: K.frameW, height: K.barH)
        .liquidLens(centerX: indicatorX, amount: (look == .lens && isDragging) ? K.refractAmount : 0)
    }

    // MARK: - Scrub gesture (press a tab, drag the pill across, snap on release)
    // One DragGesture handles BOTH a plain tap (no movement → select the tab under the finger)
    // and a scrub (drag the subtle pill, snap to the nearest tab on release). No morph happens
    // mid-drag — the bar keeps its current state until the finger lifts.
    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard inSpan(value.startLocation.x) else { return }
                guard abs(value.translation.width) > 4 else { return }   // ignore until it's really a drag
                let cs = centres
                let x = min(max(value.location.x, cs.first!), cs.last!)
                dragX = x
                let tab = tabs[nearestIndex(to: x, in: cs)]
                if tab != hoverTab {
                    hoverTab = tab
                    Haptics.scrub()                  // tick as the pill crosses into a new tab
                }
            }
            .onEnded { value in
                defer { hoverTab = nil }
                guard inSpan(value.startLocation.x) else { dragX = nil; return }
                let cs = centres
                let x = min(max(value.location.x, cs.first!), cs.last!)
                onTap(tabs[nearestIndex(to: x, in: cs)])           // commit (handles haptic + morph)
                withAnimation(K.indicatorAnim) { dragX = nil }     // spring the pill to the settled slot
            }
    }

    // Tabs / x-centres / hit-span for the CURRENT state (visible-tabs scope; no morph mid-drag).
    private var tabs: [NavTab] {
        progress >= 0.5 ? [.chat, .agents, .portfolio] : [.chat, .agents]
    }
    private var centres: [CGFloat] {
        progress >= 0.5 ? [K.chatBarX, K.agentsBarX, K.portfolioCX] : [K.chatPillX, K.agentsPillX]
    }
    private func inSpan(_ x: CGFloat) -> Bool {
        let pad: CGFloat = 16
        return progress >= 0.5 ? (x >= K.barShift - pad && x <= K.barShift + K.fullW + pad)
                               : (x >= -pad && x <= K.pillW + pad)
    }
    private func nearestIndex(to x: CGFloat, in cs: [CGFloat]) -> Int {
        cs.enumerated().min { abs($0.element - x) < abs($1.element - x) }!.offset
    }

    // MARK: tab content
    private func tabContent(_ tab: NavTab, x: CGFloat) -> some View {
        // Active = the tab under the pill while scrubbing (hoverTab), else the committed tab.
        let active = (hoverTab ?? selected) == tab
        return VStack(spacing: 0.5) {             // Suzi develop: VStack(spacing: 0.5)
            Image(tab.asset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)     // Metrics.tabIconSize = 28
            Text(tab.title)
                .font(.labelMedium)               // Suzi develop: .labelMedium (13pt semibold rounded)
                .tracking(-0.08)                  // Suzi develop: tracking(-0.08)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .allowsTightening(true)
                .truncationMode(.tail)
        }
        .foregroundStyle(active ? Color.accent : Colors.mutedLabel)   // Suzi develop colours
        .frame(width: K.itemW, height: K.barH - K.inset * 2)          // 60 = indicatorHeight
        .compositingGroup()                       // Suzi develop: rasterise icon+label together
        .position(x: x, y: K.barH / 2)
        .allowsHitTesting(false)                  // selection handled by the parent scrub gesture
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

    // GLASS look highlight — CustomGlassTabBar's interactive liquid-glass lens wearing our brand
    // pink. The pink is a glass TINT (not a rigid overlay) so it deforms WITH the glass when the
    // pill squishes. `glassTint` is the single knob to dial the pink strength.
    private static let glassTint: Double = 0.22
    @ViewBuilder private var interactiveGlassPill: some View {
        if #available(iOS 26, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(Colors.accentPink.opacity(Self.glassTint)).interactive(), in: .capsule)
                .overlay(Capsule().stroke(Colors.accentPink.opacity(0.10), lineWidth: 1.5))
        } else {
            Capsule()
                .fill(Colors.accentPink.opacity(0.14))
                .background(.ultraThinMaterial, in: .capsule)
                .overlay(Capsule().stroke(Colors.accentPink.opacity(0.08), lineWidth: 1.5))
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

// MARK: - Liquid-lens refraction (GSControl LiquidLens.metal)
private extension View {
    /// Bends content within a pill-shaped lens centred at `centerX` (frame coords).
    /// `amount == 0` is identity, so it's safe to keep applied when not scrubbing.
    @ViewBuilder
    func liquidLens(centerX: CGFloat, amount: CGFloat) -> some View {
        if #available(iOS 17, *), K.refractionEnabled {
            layerEffect(
                ShaderLibrary.liquidLens(
                    .float2(K.itemW, K.barH),         // lens size (pill width × bar height)
                    .float(centerX - K.itemW / 2),    // positionX → pillCenter.x == centerX
                    .float(amount),
                    .float(K.refractDepth)
                ),
                maxSampleOffset: CGSize(width: 200, height: 100)
            )
        } else {
            self
        }
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
    @State private var isMenuOpen: Bool = false

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

            LiquidGlassNavBar(selected: $selected, onFabTap: {
                isMenuOpen.toggle()
            }, fabHidden: isMenuOpen)
            .padding(.bottom, K.bottomInset)              // Suzi Metrics.bottomInset = 25

            // Backdrop — ultraThinMaterial blur covering everything (incl. dock), tap to dismiss.
            // Matches suzi-swift PortfolioFloatingDock lines 450-460.
            if isMenuOpen {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { isMenuOpen = false }
                    .transition(.opacity)
            }

            // Action menu — bottom-right, same insets as the FAB so the Swap button lands on the FAB position.
            WalletActionMenu(isExpanded: $isMenuOpen) { _ in
                isMenuOpen = false
            }
            .padding(.trailing, K.horizontalInset)
            .padding(.bottom, K.bottomInset)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea(.container, edges: .bottom)          // ZStack extends to screen edge → dock sits at the actual bottom
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: selected)
        .animation(.easeInOut(duration: 0.18), value: isMenuOpen)
        .preferredColorScheme(.dark)
    }
}

#Preview { NavBarDemo() }
