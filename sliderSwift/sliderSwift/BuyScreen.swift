//
//  BuyScreen.swift
//  sliderSwift
//
//  Figma: mobile-ios · UUIJ7JRhScxoWJp7pbCf0N · node 12242:20097
//  ("swap up selected, down selected").
//

import SwiftUI

struct BuyScreen: View {
    /// What the keypad has produced. Starts at the value in the design.
    @State private var amount = AmountEntry("126.89")
    @State private var resetSlider: Bool = false
    /// Flips once the slide-to-buy lands, swapping the sheet's contents for
    /// `BoughtScreen`.
    @State private var didBuy: Bool = false
    /// How many buys this session has run. Nothing here talks to a network, so
    /// the outcome alternates off this counter — the first buy succeeds, the
    /// second fails, and so on, which makes both states reachable just by
    /// using the app. Swap this for the real result when there is one.
    @State private var buyCount: Int = 0

    private var nextOutcome: BoughtScreen.Outcome {
        buyCount.isMultiple(of: 2) ? .success : .failure
    }

    /// The wallet total shown in the pay-with pill (Figma: 325.65).
    private let balance: Decimal = .money("325.65")

    /// What may actually be committed, which is deliberately *not* the whole
    /// balance — the rest is held back for network fees. The design's meter
    /// reads 44% at $126.89, which is what fixes this at 126.89 / 0.44.
    ///
    /// One number, used three ways, so they can never disagree: the meter
    /// measures against it, "Max" fills it, and the buy is refused above it.
    private let spendable: Decimal = .money("288.39")

    /// The funding token. Named because the "not enough" message uses it.
    private let fundingSymbol = "USDC"
    private let tokenSymbol = "PUDGY"

    /// $1 buys this many PUDGY — chosen so $126.89 converts to the 118.68 in
    /// the design. A real integration replaces this with a quoted price, and
    /// should re-quote while the sheet is open.
    private let pudgyPerDollar: Decimal = .money("118.68") / .money("126.89")

    private var quantity: Decimal { amount.value * pudgyPerDollar }

    /// Why the buy is refused, or `nil` if it isn't.
    private var problem: AmountEntry.Problem? { amount.problem(spending: spendable) }

    /// The bar carries the reason rather than just greying out — "disabled with
    /// no explanation" is the version of this users complain about.
    private var slideTitle: String {
        switch problem {
        case .noAmount: "Enter an Amount"
        case .aboveBalance: "Not Enough \(fundingSymbol)"
        case nil: "Buy \(tokenSymbol)"
        }
    }

    private var fillFraction: Double {
        guard spendable > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: amount.value / spendable).doubleValue
        return min(max(ratio, 0), 1)
    }

    var body: some View {
        ZStack {
            if didBuy {
                BoughtScreen(
                    quantity: quantity,
                    symbol: tokenSymbol,
                    outcome: nextOutcome,
                    onClose: { dismissConfirmation(clearingAmount: true) },
                    onBuyAgain: { dismissConfirmation(clearingAmount: false) },
                    onViewTransaction: {
                        // Opens the txn in an explorer — no chain behind this
                        // demo, so there is no hash to open yet.
                    }
                )
                .transition(.opacity)
            } else {
                buySheet
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.35), value: didBuy)
    }

    /// The keypad half of the sheet — everything the design shows before the
    /// slide completes.
    private var buySheet: some View {
        VStack(spacing: 0) {
            grabber

            header

            Spacer(minLength: 0)

            VStack(spacing: 24) {
                AmountHeader(
                    amount: amount,
                    receiveQuantity: quantity,
                    receiveSymbol: tokenSymbol
                ) {
                    // Flip the input currency — not wired up in this demo.
                }

                PayWithPill(symbol: fundingSymbol, balance: balance) {
                    // Opens the funding-token picker — not wired up in this demo.
                }
            }

            Spacer(minLength: 0)

            numpadSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Theme.background.ignoresSafeArea() }
        .preferredColorScheme(.dark)
    }

    // MARK: - Pieces

    private var grabber: some View {
        Capsule()
            .fill(Theme.gray)
            .frame(width: 48, height: 4)
            .frame(height: 17)
    }

    private var header: some View {
        Text("Buy")
            .figmaStyle(Theme.title2, tracking: Theme.title2Tracking, color: Theme.grayWhite)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    private var numpadSection: some View {
        VStack(spacing: 24) {
            DepositMeter(fraction: fillFraction) {
                withAnimation(.snappy(duration: 0.25)) { amount.fill(with: spendable) }
            }

            VStack(spacing: 16) {
                Numpad(entry: $amount)

                VStack(spacing: 0) {
                    FeeDetailsTab(feePercent: 0.12) {
                        // Expands the fee breakdown — not wired up in this demo.
                    }

                    SlideToBuyBar(
                        title: slideTitle,
                        isEnabled: problem == nil,
                        reset: $resetSlider
                    ) {
                        // The buy fired. `BoughtScreen` opens on its own
                        // processing beat, so the hand-off is immediate — the
                        // bar's "Bought" label would contradict it.
                        didBuy = true
                    }
                }
                .frame(width: 354)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    /// Both confirmation buttons return to the keypad; they differ only in what
    /// they leave in the field. "Close" wipes it, "Buy Again" keeps the amount
    /// so the next slide is one gesture away.
    private func dismissConfirmation(clearingAmount: Bool) {
        if clearingAmount { amount.clear() }
        resetSlider.toggle()
        didBuy = false
        /// Advanced on the way out, not on the way in, so `nextOutcome` stays
        /// stable for every frame the confirmation is on screen.
        buyCount += 1
    }
}

#Preview {
    BuyScreen()
}
