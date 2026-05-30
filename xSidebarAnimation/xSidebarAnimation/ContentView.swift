//
//  ContentView.swift
//  xSidebarAnimation
//

import SwiftUI

struct ContentView: View {
    @State private var activeScreen: AppScreen = .chat
    @State private var isSidebarExpanded: Bool = false
    @State private var selectedConversationId: UUID? = nil

    var body: some View {
        CustomSideMenu(
            isEnabled: activeScreen == .chat,
            isExpanded: $isSidebarExpanded
        ) { _ in
            ChatSidebar(
                isExpanded: $isSidebarExpanded,
                selectedConversationId: $selectedConversationId
            )
        } content: { _ in
            ZStack(alignment: .bottom) {
                screenContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                LiquidGlassDockBar(selection: $activeScreen)
                    .padding(.bottom, 16)
                    .opacity(isSidebarExpanded ? 0 : 1)
                    .allowsHitTesting(!isSidebarExpanded)
                    .animation(.easeInOut(duration: 0.15), value: isSidebarExpanded)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch activeScreen {
        case .chat:
            ChatScreen(onToggleDrawer: {
                isSidebarExpanded.toggle()
            })
        case .agents:
            AgentsScreen()
        case .portfolio:
            PortfolioScreen()
        }
    }
}

#Preview {
    ContentView()
}
