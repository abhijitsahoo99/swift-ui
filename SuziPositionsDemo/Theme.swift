// Theme.swift
// Design tokens (dark-only) lifted from Suzi's DesignSystem.
// Colors / Typography / Spacing / Haptics + a hex Color initializer.

import SwiftUI
import UIKit

// MARK: - Color(hex:)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Semantic color tokens (dark theme)

extension Color {
    static let appBackground       = Color(hex: "#131313")
    static let backgroundSecondary = Color(hex: "#1C1C1E")
    static let cardFill            = Color(hex: "#1C1C1E") // protocol section card
    static let surfaceTertiary     = Color(hex: "#2C2C2E")

    static let textPrimary   = Color(hex: "#E9E9E9")
    static let textSecondary = Color(hex: "#EBEBF5").opacity(0.6)

    static let success        = Color(hex: "#30D158")
    static let error          = Color(hex: "#FF4245")
    static let polymarketBlue = Color(hex: "#235AE1")
    static let redeemable     = Color(hex: "#FFD600")

    static let accent    = Color(hex: "#FF2D92")
    static let navStroke = Color(hex: "#342D31")
    static let graysGray = Color(hex: "#A9A9A9")

    // adaptive overlay helpers (white overlay on dark)
    static let overlayFill   = Color.white.opacity(0.04)
    static let overlayBorder = Color.white.opacity(0.06)
    static let overlayStrong = Color.white.opacity(0.10)
}

// MARK: - Namespaced brand tokens

enum Colors {
    static let accentPink     = Color(hex: "#FF4DA9")
    static let accentPinkDark = Color(hex: "#D91E85")
    static let mutedLabel     = Color(hex: "#8F8F8F")
    static let gray           = Color(hex: "#A9A9A9")
}

// MARK: - Typography (SF Pro Rounded)

extension Font {
    static let labelMedium = Font.system(size: 13, weight: .semibold, design: .rounded)
}

enum Typography {
    static let title2         = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let bodySemibold   = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let bodySemibold14 = Font.system(size: 14, weight: .semibold, design: .rounded)
}

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs:  CGFloat = 4
    static let xsm: CGFloat = 6
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Haptics

@MainActor
enum Haptics {
    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func light()  { impact(.light) }
    static func medium() { impact(.medium) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }

    // throttled selection feedback for continuous scrubbing
    private static var lastScrubTime: TimeInterval = 0
    static func scrub() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastScrubTime > 0.03 else { return }
        lastScrubTime = now
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
