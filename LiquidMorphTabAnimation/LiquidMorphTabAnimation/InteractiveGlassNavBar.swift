//
//  InteractiveGlassNavBar.swift
//  LiquidMorphTabAnimation
//
//  Demo host that shows the ONE LiquidGlassNavBar with a switch between its two looks:
//    Lens  → GSControl metal liquid-lens refraction (the original).
//    Glass → CustomGlassTabBar pink interactive-glass pill that squishes while scrubbing.
//
//  There is no second bar component any more. The toggle only flips `look`, so the bar's
//  morph/scrub state is never rebuilt → no jitter on switch, no double-animated morph.
//

import SwiftUI

enum BarStyle: String, CaseIterable, Identifiable {
    case lens  = "Lens"
    case glass = "Glass"
    var id: String { rawValue }
    var look: NavBarLook { self == .lens ? .lens : .glass }
}

struct NavBarLab: View {
    @State private var selected: NavTab = .portfolio
    @State private var isMenuOpen: Bool = false
    @State private var barStyle: BarStyle = .glass

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

            // Style switcher floats just above the bar (clear of the Portfolio header).
            VStack(spacing: 12) {
                Picker("Bar style", selection: $barStyle) {
                    ForEach(BarStyle.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                .opacity(isMenuOpen ? 0 : 1)

                // ONE bar — only `look` changes when the toggle flips.
                LiquidGlassNavBar(selected: $selected,
                                  look: barStyle.look,
                                  onFabTap: { isMenuOpen.toggle() },
                                  fabHidden: isMenuOpen)
            }
            .padding(.bottom, K.bottomInset)

            // Backdrop — tap to dismiss the action menu.
            if isMenuOpen {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { isMenuOpen = false }
                    .transition(.opacity)
            }

            WalletActionMenu(isExpanded: $isMenuOpen) { _ in
                isMenuOpen = false
            }
            .padding(.trailing, K.horizontalInset)
            .padding(.bottom, K.bottomInset)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: selected)
        .animation(.easeInOut(duration: 0.18), value: isMenuOpen)
        .preferredColorScheme(.dark)
    }
}

#Preview { NavBarLab() }
