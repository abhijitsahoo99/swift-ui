//
//  DummyData.swift
//  xSidebarAnimation
//

import SwiftUI

// MARK: - Color tokens (approximations of Suzi's DesignSystem)

extension Color {
    static let accentPink         = Color(red: 1.0,    green: 0.18,  blue: 0.55)
    static let accentPinkLight    = Color(red: 1.0,    green: 0.54,  blue: 0.80)
    static let appBackground      = Color(red: 0.04,   green: 0.04,  blue: 0.05)
    static let backgroundSecondary = Color(red: 0.09,  green: 0.09,  blue: 0.10)
    static let surfaceRaised      = Color(red: 0.11,   green: 0.12,  blue: 0.13)
    static let overlayFill        = Color.white.opacity(0.06)
    static let overlayBorder      = Color.white.opacity(0.10)
    static let textPrimary        = Color(red: 0.93,   green: 0.93,  blue: 0.93)
    static let textSecondary      = Color(red: 0.65,   green: 0.65,  blue: 0.67)
    static let textMuted          = Color(red: 0.45,   green: 0.45,  blue: 0.47)
    static let mutedLabel         = Color(red: 0.55,   green: 0.55,  blue: 0.58)
    static let walletBluePurple   = Color(red: 0.55,   green: 0.50,  blue: 1.00)
    static let walletBlue         = Color(red: 0.43,   green: 0.66,  blue: 1.00)
    static let successGreen       = Color(red: 0.30,   green: 0.80,  blue: 0.40)
    static let errorRed           = Color(red: 1.00,   green: 0.35,  blue: 0.40)
}

// MARK: - Conversations

struct DummyConversation: Identifiable, Hashable {
    let id: UUID = UUID()
    let title: String
    let lastUpdated: String   // pre-formatted relative time
    let isPinned: Bool
    let hasUnreadReply: Bool
}

enum DummyConversations {
    static let pinned: [DummyConversation] = [
        .init(title: "Tax season planning",      lastUpdated: "2d",  isPinned: true,  hasUnreadReply: false),
        .init(title: "SOL price thesis",         lastUpdated: "1w",  isPinned: true,  hasUnreadReply: false),
    ]

    static let recents: [DummyConversation] = [
        .init(title: "Bridge USDC to base",            lastUpdated: "12m", isPinned: false, hasUnreadReply: true),
        .init(title: "Why is ETH lagging today",       lastUpdated: "1h",  isPinned: false, hasUnreadReply: false),
        .init(title: "Polymarket election odds",       lastUpdated: "3h",  isPinned: false, hasUnreadReply: false),
        .init(title: "Best yield on USDCe right now",  lastUpdated: "5h",  isPinned: false, hasUnreadReply: false),
        .init(title: "Set a 5% stop on my SOL",        lastUpdated: "8h",  isPinned: false, hasUnreadReply: false),
        .init(title: "What's BONK doing this week",    lastUpdated: "1d",  isPinned: false, hasUnreadReply: false),
        .init(title: "Hyperliquid funding rates",      lastUpdated: "2d",  isPinned: false, hasUnreadReply: false),
        .init(title: "Bookmark: jito airdrop notes",   lastUpdated: "3d",  isPinned: false, hasUnreadReply: false),
    ]
}

// MARK: - Messages

enum DummyMessageRole {
    case user
    case assistant
}

struct DummyMessage: Identifiable, Hashable {
    let id: UUID = UUID()
    let role: DummyMessageRole
    let text: String
}

enum DummyMessages {
    static let sample: [DummyMessage] = [
        .init(role: .user,      text: "hey, what's SOL doing today?"),
        .init(role: .assistant, text: "SOL is up ~2.4% in the last 24h, trading around $148. Volume's been steady — nothing unusual."),
        .init(role: .user,      text: "any catalyst?"),
        .init(role: .assistant, text: "Mostly broader market strength. The Firedancer testnet milestone hit yesterday — some traders are pricing in faster mainnet rollout."),
        .init(role: .user,      text: "should I rotate part of my position into JTO?"),
        .init(role: .assistant, text: "JTO is more leveraged to Solana staking flows. If you believe SOL keeps climbing, JTO usually outperforms by 1.5-2x. But the drawdowns are sharper. Size accordingly."),
        .init(role: .user,      text: "what's my SOL exposure currently?"),
        .init(role: .assistant, text: "You're holding 0.2302 SOL (~$18.75) — about 27% of your spot bag. No JTO position yet."),
        .init(role: .user,      text: "ok let's bridge some USDC over and pick up some JTO"),
        .init(role: .assistant, text: "Got it — I can prep a bridge from your ETH address to Solana. How much USDC do you want to send over?"),
    ]
}

// MARK: - Holdings

struct DummyHolding: Identifiable, Hashable {
    let id: UUID = UUID()
    let symbol: String
    let detail: String         // e.g. "25.495 USDCE"
    let usdValue: String       // e.g. "$25.50"
    let changePercent: String  // e.g. "+0.02%"
    let isPositive: Bool
    let logoTint: Color
}

enum DummyHoldings {
    static let total = "$67.41"

    static let all: [DummyHolding] = [
        .init(symbol: "USDCE",       detail: "25.495 USDCE",  usdValue: "$25.50", changePercent: "+0.02%", isPositive: true,  logoTint: .walletBlue),
        .init(symbol: "USDC",        detail: "20.67 USDC",    usdValue: "$20.66", changePercent: "-0.01%", isPositive: false, logoTint: .walletBlue),
        .init(symbol: "SOL",         detail: "0.2302 SOL",    usdValue: "$18.75", changePercent: "-2.90%", isPositive: false, logoTint: .walletBluePurple),
        .init(symbol: "USDC (Perps)",detail: "2.48 USDC",     usdValue: "$2.48",  changePercent: "+0.04%", isPositive: true,  logoTint: .walletBlue),
        .init(symbol: "CLOUD",       detail: "0.8 CLOUD",     usdValue: "$1.01",  changePercent: "-3.73%", isPositive: false, logoTint: .walletBluePurple),
        .init(symbol: "JTO",         detail: "0.42 JTO",      usdValue: "$0.88",  changePercent: "+1.12%", isPositive: true,  logoTint: .successGreen),
    ]
}

// MARK: - Agents

struct DummyAgent: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let tagline: String
    let icon: String   // SF Symbol
    let gradient: [Color]
}

enum DummyAgents {
    static let all: [DummyAgent] = [
        .init(name: "Token Researcher", tagline: "Deep-dive on any ticker", icon: "magnifyingglass",                    gradient: [.accentPink, .walletBluePurple]),
        .init(name: "Trade Copilot",    tagline: "Live entry & exit calls", icon: "bolt.fill",                          gradient: [.walletBluePurple, .walletBlue]),
        .init(name: "Yield Hunter",     tagline: "Top APY across chains",   icon: "chart.line.uptrend.xyaxis",          gradient: [.successGreen, .walletBlue]),
        .init(name: "News Digest",      tagline: "Daily crypto recap",      icon: "newspaper.fill",                     gradient: [.accentPink, .errorRed]),
        .init(name: "Tax Helper",       tagline: "P&L + cost basis tracker",icon: "doc.text.fill",                      gradient: [.walletBlue, .successGreen]),
        .init(name: "Portfolio Coach",  tagline: "Risk + diversification",  icon: "shield.lefthalf.filled",             gradient: [.walletBluePurple, .accentPink]),
    ]
}

// MARK: - User profile (dummy)

enum DummyUser {
    static let handle = "justabhi99"
    static let solanaAddress = "4CJJ....Byg3"
    static let evmAddress = "0xF2....3E25"
    static let netWorth = "$67.97"
}
