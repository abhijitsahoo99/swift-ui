//
//  Theme.swift
//  LiquidMorphTabAnimation
//
//  Design tokens copied from suzi-swift (DesignSystem/Theme) — dark values only,
//  since the demo runs in forced dark mode.
//

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
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Color tokens
extension Color {
    static let appBackground       = Color(hex: "#131313")
    static let backgroundSecondary = Color(hex: "#1C1C1E")
    static let surface             = Color(hex: "#1A1A1A")
    static let surfaceRaised       = Color(hex: "#1C1C1E")
    static let surfaceTextPrimary  = Color(hex: "#E9E9E9")

    static let accent      = Color(hex: "#FF2D92")
    static let accentLight = Color(hex: "#FF5CAD")

    static let textPrimary   = Color(hex: "#E9E9E9")
    static let textSecondary = Color(hex: "#A9A9A9")
    static let textMuted     = Color(hex: "#666666")

    static let success      = Color(hex: "#22C55E")
    static let successLight = Color(hex: "#4ADE80")
    static let error        = Color(hex: "#EF4444")
    static let accentGreen  = Color(hex: "#30D158")
    static let accentRed    = Color(hex: "#FF4245")

    static let overlayFill   = Color.white.opacity(0.04)
    static let overlayBorder = Color.white.opacity(0.06)
    static let overlayStrong = Color.white.opacity(0.10)

    static let portfolioSpot          = Color(hex: "#FF2D92")
    static let portfolioSpotLight     = Color(hex: "#FF5CAD")
    static let portfolioExposure      = Color(hex: "#C850C0")
    static let portfolioExposureLight = Color(hex: "#D88AD8")
    static let portfolioOrders        = Color(hex: "#7F5AF0")
    static let portfolioOrdersLight   = Color(hex: "#A78BFA")

    static let cardGradientStart = Color(hex: "#1A0A12")
    static let cardGradientMid   = Color(hex: "#1A0F1A")
    static let cardGradientEnd   = Color(hex: "#130F1A")

    static let navStroke     = Color(hex: "#342D31")
    static let indicatorPink = Color(hex: "#FF4DA9")
}

// MARK: - Spacing (copied)
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let xsm: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let radiusXl: CGFloat = 24
}

// MARK: - Typography (subset, SF Pro Rounded)
extension Font {
    static let bodyLarge   = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium  = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodySmall   = Font.system(size: 13, weight: .regular, design: .rounded)
    static let labelMedium = Font.system(size: 13, weight: .semibold, design: .rounded)
}

enum Typography {
    static let title3          = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyMedium      = Font.system(size: 14, weight: .medium, design: .rounded)
    static let bodySemibold17  = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let iconSmall       = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let balance         = Font.system(size: 44.8, weight: .semibold, design: .rounded)
    static let balanceTracking: CGFloat = 0.53
    static let balanceFraction = Font.system(size: 29, weight: .regular, design: .rounded)
    static let balanceFractionTracking: CGFloat = -0.34
}

// MARK: - Namespaced color tokens (copied)
enum Colors {
    static let walletBluePurple = Color(hex: "#6D7CFF")
    static let walletBlue       = Color(hex: "#0091FF")
    static let walletGreen      = Color(hex: "#30D158")
    static let gray             = Color(hex: "#A9A9A9")
    static let mutedLabel       = Color(hex: "#8F8F8F")   // dark-mode value
    static let accentPink       = Color(hex: "#FF4DA9")
}

// MARK: - Haptics (stub)
enum Haptics {
    static func light()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()    { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func scrub()     { UISelectionFeedbackGenerator().selectionChanged() }
    static func success()   { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

// MARK: - Formatting helpers
enum Fmt {
    /// "$12,402.58" (detailed) or "$8.2K" (compact)
    static func fiat(_ value: Double, compact: Bool = false) -> String {
        if compact, abs(value) >= 1000 {
            let k = value / 1000
            return "$\(String(format: "%.1f", k))K"
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return "$" + (f.string(from: NSNumber(value: value)) ?? "\(value)")
    }

    static func percent(_ value: Double, signed: Bool = false) -> String {
        let sign = signed && value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))%"
    }
}
