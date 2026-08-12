//
//  ShimmerLabel.swift
//  sliderSwift
//
//  Figma node 12626:54725 — "Buying PUDGY".
//
//  The design specifies the text filled with a horizontal `#E9E9E9 → #838383`
//  gradient (a `bg-clip-text`), which is the *base*. The shimmer is a brighter
//  copy of the same text swept by a narrow mask, the same technique the
//  slide-to-buy bar already uses for its label.
//

import SwiftUI

struct ShimmerLabel: View {
    let text: String

    /// Seconds for one pass of the highlight.
    private let period: TimeInterval = 1.6
    /// Width of the sweeping band.
    private let bandWidth: CGFloat = 46

    var body: some View {
        ZStack {
            label.foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: 0xE9E9E9), Color(hex: 0x838383)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            label
                .foregroundStyle(Color.white)
                .mask(alignment: .leading) { sweep }
        }
        .fixedSize()
    }

    private var label: some View {
        Text(text)
            .font(Theme.title2)
            .tracking(Theme.title2Tracking)
    }

    /// A tilted band running left to right, off-screen at both ends so the
    /// highlight enters and leaves rather than popping.
    private var sweep: some View {
        GeometryReader { geo in
            Rectangle()
                .frame(width: bandWidth)
                .blur(radius: 7)
                .rotationEffect(.degrees(14))
                .offset(x: -bandWidth)
                .keyframeAnimator(initialValue: CGFloat.zero, repeating: true) { content, offset in
                    content.offset(x: offset)
                } keyframes: { _ in
                    LinearKeyframe(geo.size.width + bandWidth * 2, duration: period)
                }
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        ShimmerLabel(text: "Buying PUDGY")
    }
    .preferredColorScheme(.dark)
}
