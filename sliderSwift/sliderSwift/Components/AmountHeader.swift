//
//  AmountHeader.swift
//  sliderSwift
//
//  Figma nodes 12254:13655 — the 64pt amount and the token conversion row.
//

import SwiftUI

struct AmountHeader: View {
    /// What the keypad has produced. Already carries its own display form, so
    /// this view never has to know how the digits are stored.
    let amount: AmountEntry
    /// Token quantity the amount converts into.
    let receiveQuantity: Decimal
    let receiveSymbol: String
    var onSwap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("$" + amount.display)
                .figmaStyle(Theme.display, tracking: Theme.displayTracking, color: Theme.grayWhite)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.22), value: amount.digits)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            HStack(spacing: 6) {
                Image(.pudgy)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(.circle)

                Text(receiveText)
                    .figmaStyle(Theme.callout, tracking: Theme.calloutTracking, color: Theme.gray)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.22), value: receiveQuantity)

                Button(action: onSwap) {
                    Image(systemName: "arrow.trianglehead.swap")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.grayWhite)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Theme.swapButton))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Swap input currency")
            }
        }
    }

    private var receiveText: String {
        let quantity = receiveQuantity.formatted(
            .number.precision(.fractionLength(2)).grouping(.automatic)
        )
        return "\(quantity) \(receiveSymbol)"
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        AmountHeader(amount: AmountEntry("126.89"), receiveQuantity: .money("118.68"), receiveSymbol: "PUDGY") {}
    }
    .preferredColorScheme(.dark)
}
