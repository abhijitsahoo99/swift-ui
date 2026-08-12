//
//  GlassPillButton.swift
//  sliderSwift
//
//  Figma nodes 12260:14511 / 12260:14512 ("Button - Liquid Glass - Text"),
//  which the file documents against
//  https://developer.apple.com/design/human-interface-guidelines/buttons
//

import SwiftUI

/// A 56pt capsule in tinted Liquid Glass that fills the width it's given.
///
/// Figma draws this as a "Tint + Shadow" stack — an rgba(255,255,255,0.75) base
/// with `mix-blend-saturation` and `mix-blend-overlay` passes over the tint.
/// That is Figma's approximation of the real material, not a recipe, so none of
/// it is transliterated: the system glass button styles produce the look, and
/// they bring the press behaviour and vibrancy with them.
struct GlassPillButton: View {
    /// Which of the two glass weights the pill uses. Figma renders the pair
    /// with one component and two tints, but the tints are doing the job iOS
    /// splits across two styles: the success pill is the screen's primary
    /// action, the gray one recedes into the sheet.
    enum Emphasis {
        /// `.glassProminent` — the tint reads at full strength.
        case prominent
        /// `.glass` — translucent, so the tint settles toward the background.
        case standard
    }

    let title: String
    /// The colour under the glass — Grays/Gray 3 for "Close", Semantic/Success
    /// for "Buy Again".
    let tint: Color
    var emphasis: Emphasis = .prominent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .figmaStyle(Theme.body, tracking: Theme.bodyTracking, color: Theme.labelPrimary)
                /// The label, not the style's intrinsic padding, is what sets
                /// the pill's size — without `maxHeight` the glass background
                /// sizes to its own content and the 56pt frame just centres a
                /// shorter capsule inside itself.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(for: emphasis)
        .buttonBorderShape(.capsule)
        .tint(tint)
        .frame(height: 56)
        /// Figma: 0 8 40 rgba(0,0,0,0.12). CSS blur is twice SwiftUI's radius,
        /// so 40 → 20 — the same shadow the slide-to-buy bar carries.
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
    }
}

private extension View {
    @ViewBuilder
    func buttonStyle(for emphasis: GlassPillButton.Emphasis) -> some View {
        switch emphasis {
        case .prominent: buttonStyle(.glassProminent)
        case .standard:  buttonStyle(.glass)
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        HStack(spacing: 10) {
            GlassPillButton(title: "Close", tint: Theme.gray3, emphasis: .standard) {}
            GlassPillButton(title: "Buy Again", tint: Theme.success) {}
        }
        .frame(width: 354)
    }
    .preferredColorScheme(.dark)
}
