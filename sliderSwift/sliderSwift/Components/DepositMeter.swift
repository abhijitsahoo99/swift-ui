//
//  DepositMeter.swift
//  sliderSwift
//
//  Figma nodes 12242:20263–20273. The bar is three separate pieces laid out in a
//  row, not a single track with an overlay: a gradient fill, a dark-pink position
//  marker, then the unfilled remainder.
//

import SwiftUI

struct DepositMeter: View {
    /// 0…1
    let fraction: Double
    var onMax: () -> Void

    private let barHeight: CGFloat = 12
    private let markerWidth: CGFloat = 4
    private let markerHeight: CGFloat = 10
    private let gap: CGFloat = 6

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 9) {
                Text("Deposit")
                    .figmaStyle(Theme.callout, tracking: Theme.calloutTracking, color: Theme.gray)

                Text("\(Int((fraction * 100).rounded()))%")
                    .figmaStyle(Theme.callout, tracking: Theme.calloutTracking, color: Theme.grayWhite)
                    .contentTransition(.numericText())

                Spacer(minLength: 0)

                Button(action: onMax) {
                    Text("Max")
                        .figmaStyle(Theme.callout, tracking: Theme.calloutTracking, color: Theme.pinkLight)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Use maximum amount")
            }

            GeometryReader { geo in
                /// Space the fill and remainder share, once the marker and the
                /// two 6pt gaps are taken out.
                let usable = max(0, geo.size.width - markerWidth - (gap * 2))
                let fillWidth = usable * min(max(fraction, 0), 1)

                HStack(spacing: gap) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.pinkLight, Theme.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth)

                    Capsule()
                        .fill(Theme.pinkDark)
                        .frame(width: markerWidth, height: markerHeight)

                    Capsule()
                        .fill(Theme.meterTrack)
                        .frame(width: max(0, usable - fillWidth))
                }
                .frame(height: barHeight)
            }
            .frame(height: barHeight)
        }
        .animation(.snappy(duration: 0.25), value: fraction)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        DepositMeter(fraction: 0.44) {}
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}
