//
//  SlideToBuyBar.swift
//  sliderSwift
//
//  The Figma-configured wrapper around `LiquidGlassSlider`: the slider stays
//  generic, and everything this screen needs it to look like lives here.
//  Figma node 12376:32478 ("Button - Liquid Glass - Text").
//

import SwiftUI

struct SlideToBuyBar: View {
    /// What the bar says at rest — "Buy PUDGY" normally, and the reason it is
    /// unusable when it is. A dimmed bar with no explanation leaves the user
    /// guessing at which of the two rules they broke.
    var title: String
    var isEnabled: Bool = true
    @Binding var reset: Bool
    var onBuy: () -> Void

    var body: some View {
        let config = LiquidGlassSlider.Config(
            tint: Theme.successButton,
            isEnabled: isEnabled,
            height: 56,
            knobSize: CGSize(width: 55, height: 40),
            knobInset: 8,
            knobFill: Theme.grayWhite,
            completedText: "Bought",
            resetToggle: reset
        )

        LiquidGlassSlider(text: title, config: config) { _ in
            // Progress is surfaced for callers that want to drive something
            // alongside the drag; this screen doesn't need it.
        } onFinish: { didComplete in
            if didComplete { onBuy() }
        }
        .frame(width: 354, height: 56)
        .accessibilityLabel(isEnabled ? "Slide to \(title)" : title)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        VStack(spacing: 16) {
            SlideToBuyBar(title: "Buy PUDGY", reset: .constant(false)) {}
            SlideToBuyBar(title: "Enter an Amount", isEnabled: false, reset: .constant(false)) {}
        }
    }
    .preferredColorScheme(.dark)
}
