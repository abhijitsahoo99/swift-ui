//
//  Theme.swift
//  sliderSwift
//
//  Design tokens lifted straight from the Figma file
//  (mobile-ios · UUIJ7JRhScxoWJp7pbCf0N · node 12242:20097).
//

import SwiftUI

enum Theme {

    // MARK: - Colors

    /// Backgrounds/Primary
    static let background = Color(hex: 0x131313)
    /// Grays/Gray 6 — the Fee & Details tab, the base of the confirmation pulse
    static let gray6 = Color(hex: 0x1C1C1E)
    /// Grays/Gray 5 — one step up the dark ramp from `gray6`
    static let gray5 = Color(hex: 0x2C2C2E)
    /// Grays/Gray 4 — the confirmation pulse bands
    static let gray4 = Color(hex: 0x3A3A3C)
    /// Grays/White — headings, amounts, keypad digits
    static let grayWhite = Color(hex: 0xE9E9E9)
    /// Grays/Gray — secondary copy, the grabber
    static let gray = Color(hex: 0xA9A9A9)
    /// Grays/Gray 3 — the tint under the "Close" pill's glass
    static let gray3 = Color(hex: 0x48484A)
    /// Labels - Vibrant - Controls/Primary — the slider label
    static let labelPrimary = Color(hex: 0xF5F5F5)
    /// Labels - Vibrant - Controls/Secondary — "Fee & Details"
    static let labelSecondary = Color(hex: 0x8A8A8A)
    /// Semantic/Success — the slide-to-buy track, the "Buy Again" pill.
    /// Figma's Finance/Positive (the confirmation seal) is the same value.
    static let success = Color(hex: 0x30D158)
    /// Finance/Negative — the failed-transaction seal (Figma node 12552:49072)
    static let negative = Color(hex: 0xFF383C)

    /// The colours of the success flush live in `SweepPalette` (OutcomeSweep),
    /// not here: they are a five-stop ramp fed to a Metal shader rather than
    /// flat tokens, and only one of them (`light`) is a design value.

    /// The slide-to-buy button as the design actually *renders*. Figma's
    /// "Button - Liquid Glass - Text" runs Semantic/Success through a blend
    /// stack — white 75%, a saturation pass, #999 overlay — and then a glass
    /// effect over the dark background. That lands on this deeper green, not
    /// the #30D158 token. Sampled from the exported node (12376:32478).
    static let successButton = Color(hex: 0x01A129)

    /// Brand/Pink Light → Brand/Pink → Brand/Pink Dark (deposit meter)
    static let pinkLight = Color(hex: 0xFF99D6)
    static let pink = Color(hex: 0xFF4DA9)
    static let pinkDark = Color(hex: 0xFF006F)

    /// Fills/Quaternary — the hairline divider inside the pay-with pill
    static let fillQuaternary = Color(hex: 0x767680, opacity: 0.18)
    /// The unfilled remainder of the deposit meter
    static let meterTrack = Color(hex: 0xD9D9D9, opacity: 0.2)
    /// The circular swap button behind the PUDGY row
    static let swapButton = Color(hex: 0x2B2B2B)
    /// Statics/Black — the chain badge disc
    static let staticBlack = Color.black

    /// Border on the pay-with pill: rgba(115, 115, 115, 0.1)
    static let pillStroke = Color(hex: 0x737373, opacity: 0.1)

    /// The pay-with pill fill: a 182.33° wash from white-10% to gray-10%.
    /// SwiftUI angles run clockwise from +x, so a 182.33° Figma gradient is a
    /// near-vertical top→bottom sweep tilted ~2° to the left.
    static let pillFill = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.1), location: 0.0209),
            .init(color: Color(hex: 0x999999, opacity: 0.1), location: 0.9293)
        ],
        startPoint: UnitPoint(x: 0.52, y: 0),
        endPoint: UnitPoint(x: 0.48, y: 1)
    )

    // MARK: - Type ramp
    //
    // Every style in the design is SF Pro Rounded Semibold, which maps to
    // `.system(design: .rounded)` with `.semibold`. Figma tracking is in points,
    // which is exactly what SwiftUI's `.tracking(_:)` takes.

    /// 64 / 64, +0.4 — the keypad amount. A bespoke display size the buy sheet
    /// hardcodes, *not* the Large Title token.
    static let display = Font.system(size: 64, weight: .semibold, design: .rounded)
    static let displayTracking: CGFloat = 0.4

    /// 34 / 41, +0.4 — Large Title proper. The confirmation headline.
    static let largeTitle = Font.system(size: 34, weight: .semibold, design: .rounded)
    static let largeTitleTracking: CGFloat = 0.4

    /// 28 / 34, +0.38 — the keypad digits
    static let title1 = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let title1Tracking: CGFloat = 0.38

    /// 22 / 28, −0.26 — the "Buy" header
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title2Tracking: CGFloat = -0.26

    /// 20 / 25, −0.26 — the "You bought" caption
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let title3Tracking: CGFloat = -0.26

    /// 17 / 22, −0.26 — the slider label
    static let body = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyTracking: CGFloat = -0.26

    /// 16 / 21, −0.26 — the PUDGY row, the balance
    static let callout = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let calloutTracking: CGFloat = -0.26

    /// 15 / 20, −0.23 — "USDC", "Fee & Details"
    static let subheadline = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let subheadlineTracking: CGFloat = -0.23

    /// 13 / 18, −0.08 — the "View Txn" pill
    static let footnote = Font.system(size: 13, weight: .semibold, design: .rounded)
    static let footnoteTracking: CGFloat = -0.08
}

// MARK: - Hex helper

extension Color {
    /// `Color(hex: 0xFF4DA9)` — the same notation the Figma variables use.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Text sugar

extension Text {
    /// Applies a font and its matching Figma letter-spacing in one go.
    func figmaStyle(_ font: Font, tracking: CGFloat, color: Color) -> Text {
        self.font(font)
            .tracking(tracking)
            .foregroundColor(color)
    }
}
