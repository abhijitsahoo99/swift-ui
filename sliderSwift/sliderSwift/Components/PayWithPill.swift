//
//  PayWithPill.swift
//  sliderSwift
//
//  Figma node 12260:13828 ("button toggle") — the USDC / balance selector.
//

import SwiftUI

struct PayWithPill: View {
    let symbol: String
    let balance: Decimal
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                avatar

                Text(symbol)
                    .figmaStyle(Theme.subheadline, tracking: Theme.subheadlineTracking, color: Theme.grayWhite)

                /// The 2x20 hairline between the symbol and the balance.
                Capsule()
                    .fill(Theme.fillQuaternary)
                    .frame(width: 2, height: 20)

                Text(balanceText)
                    .figmaStyle(Theme.callout, tracking: Theme.calloutTracking, color: Theme.gray)

                Image(.caretUpDown)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(-90))
            }
            .padding(.leading, 9)
            .padding(.trailing, 14)
            .padding(.vertical, 7)
            .frame(height: 42)
            .background {
                Capsule().fill(Theme.pillFill)
            }
            .overlay {
                Capsule().stroke(Theme.pillStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pay with \(symbol), balance \(balanceText)")
    }

    private var balanceText: String {
        balance.formatted(.number.precision(.fractionLength(2)).grouping(.automatic))
    }

    /// The token avatar with the Solana chain badge notched into its lower-right.
    private var avatar: some View {
        Image(.usdc)
            .resizable()
            .scaledToFill()
            .frame(width: 26.5, height: 26.4)
            .clipShape(.circle)
            .frame(width: 28, height: 28, alignment: .topLeading)
            .overlay(alignment: .center) {
                Image(.solana)
                    .resizable()
                    .scaledToFit()
                    .padding(1.4)
                    .frame(width: 14, height: 14)
                    .background(Circle().fill(Theme.staticBlack))
                    .overlay(Circle().stroke(Theme.background, lineWidth: 1.273))
                    .offset(x: 7, y: 7)
            }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        PayWithPill(symbol: "USDC", balance: .money("325.65")) {}
    }
    .preferredColorScheme(.dark)
}
