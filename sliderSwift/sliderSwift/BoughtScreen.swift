//
//  BoughtScreen.swift
//  sliderSwift
//
//  Figma: mobile-ios · UUIJ7JRhScxoWJp7pbCf0N
//    · 12562:52343 — the settled success frame
//    · 12580:54475 — the settled failure frame
//
//  Replaces `BuyScreen`'s keypad half once the slide-to-buy completes. A full
//  page, so no grabber.
//
//  The Figma frames are *settled* states. Getting to either runs two beats:
//
//    processing (2s) — the 172pt token rises out of centre screen into its
//                      place, spinning twice on the way, and stops. Once it
//                      lands, "Buying PUDGY" shimmers in 24pt beneath it
//                      (Figma 12626:54725) over a faint ripple. No badge:
//                      nothing claims a result before there is one.
//    success         — the tick lands and the headline appears above the
//                      status line. The token itself does not move — the
//                      block reserves its settled height and pins to the top.
//                      The ripple then releases as the sheet flushes black →
//                      green behind a bright travelling edge (Cash App's card
//                      switch), the two overlapping so one dissolves into the
//                      other. The Metal field it uncovers is the resting
//                      state, and keeps drifting until the screen is closed.
//    failure         — a cross in Finance/Negative lands and "Transaction
//                      Failed" stays where "Buying PUDGY" was, 24pt under the
//                      token. No amount, no link, no flush.
//

import SwiftUI
import UIKit

struct BoughtScreen: View {
    /// How the buy resolves once the processing beat is over.
    enum Outcome { case success, failure }

    enum Phase: Equatable {
        case processing
        case settled(Outcome)

        var isSettled: Bool { self != .processing }
    }

    /// How much of the token the buy produced — 118.68 in the design.
    /// `Decimal`, not `Double`: see `AmountEntry` for why money never rides on
    /// binary floating point here.
    let quantity: Decimal
    let symbol: String
    /// Decided by the caller before the screen opens; the screen only reveals
    /// it after `processingDuration`.
    var outcome: Outcome = .success
    var onClose: () -> Void
    var onBuyAgain: () -> Void
    /// Opens the transaction in an explorer.
    var onViewTransaction: () -> Void = {}

    /// The explorer pill, straight off Figma 12626:54943.
    private static let viewTxnSize = CGSize(width: 103, height: 34)

    /// How long the token spins before the buy resolves.
    private static let processingDuration: Duration = .seconds(2)
    /// How far below its resting place the token starts, so it begins at the
    /// middle of the screen and rises into the stack.
    private static let tokenRise: CGFloat = 102
    /// How long the rise takes. The move itself runs on a spring of about
    /// this length — a touch of give at the end lands the token more softly
    /// than an easeOut — and the copy and ripple key off the same number.
    private static let riseDuration: TimeInterval = 0.38
    /// The Cash App flush, compressed from the recording's 4.7s.
    private static let sweepDuration: TimeInterval = 1.6
    /// How long the settled layout gets to itself before the flush starts.
    private static let settleBeforeSweep: TimeInterval = 0.4

    /// Reduce Motion is not "no animation" — it is *no large or unexpected
    /// movement*. So the spin, the 102pt rise, the travelling ripple and the
    /// wipe are all dropped, and what is left is opacity: the token fades in,
    /// the result fades in, the green field cross-fades up. Nothing on this
    /// screen is conveyed by movement alone, so nothing is lost.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: Phase = .processing
    /// Fires once on appear and drives the token's rise out of centre screen.
    @State private var entered = false
    /// Held back until the token has landed, so the copy arrives *after* the
    /// move rather than riding up with it.
    @State private var labelShown = false
    /// Drives the rings' repeating expansion.
    @State private var pulsing = false
    /// Whether the ripple is on screen at all. Raised once the token lands and
    /// dropped the instant the flush starts, so the two never share the stage.
    @State private var rippling = false
    /// Bumped once, when the buy resolves, to fire the farewell wave.
    @State private var releaseTrigger = 0
    /// 0 parks the green flush below the screen, 1 has it fully arrived.
    @State private var sweepProgress: Double = 0

    /// How long the ripple takes to collapse. Short: it is getting out of the
    /// way of the flush, not performing.
    private static let releaseDuration: TimeInterval = 0.45

    /// The loop's four bands are staggered by exactly a quarter of its cycle,
    /// so at any instant they sit at these four scales and opacities. Starting
    /// the release from the same numbers is what makes the hand-off read as
    /// one continuous wave rather than a cut.
    /// Where the three bands sit at any instant, in diameters — the points an
    /// easeOut reaches at 0, ⅓ and ⅔ of a cycle across `ringMin → ringMax`.
    /// The release picks them up from exactly here, so the loop hands over
    /// without a jump.
    private static let bandStartDiameters: [CGFloat] = [176, 229, 268]
    private static let bandStartOpacities: [Double] = [1, 0.5, 0.13]

    /// The rings are animated by **diameter**, not by `scaleEffect`.
    ///
    /// Scaling a stroked circle scales its stroke too: a 13.5pt ring became
    /// 27pt by the end of its travel, and four fattening bands blurred into
    /// one another. Animating the frame keeps every ring the same weight the
    /// whole way out, which is what lets them read as separate ripples.
    ///
    /// 176 starts them just clear of the 172pt token and cannot come in any
    /// further without hiding them inside it. The reach is what tightens: the
    /// span was 176pt of growth, now 106 — 40% less — putting the outermost
    /// ring at a 141pt radius rather than 176.
    private static let ringMin: CGFloat = 176
    private static let ringMax: CGFloat = 282
    /// One ring's journey, and the gap between successive ones — a third of
    /// the period, so the three are evenly spread around the loop.
    private static let ringPeriod: TimeInterval = 1.8
    private static let ringStagger: TimeInterval = 0.6


    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            /// The flush's colour field, behind the content so the copy stays
            /// readable once the colour has arrived. Success only — a failed
            /// buy stays on Backgrounds/Primary, with the red cross and the
            /// copy carrying the outcome on their own.
            if outcome == .success {
                /// One driver, read two ways: normally `sweepProgress` moves
                /// the wipe across the screen; under Reduce Motion the field is
                /// already fully uncovered and the same value fades it up.
                OutcomeSweep(
                    progress: reduceMotion ? 1 : sweepProgress,
                    palette: .success,
                    layer: .field,
                    animates: !reduceMotion
                )
                .opacity(reduceMotion ? sweepProgress : 1)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                confirmation

                Spacer(minLength: 0)

                buttons
            }

            /// The bright edge, *in front* of the content — it washes over the
            /// mark and the copy as it travels, the way the reference does to
            /// its keypad. Behind the content it would slide past invisibly.
            /// The bright edge only exists to be watched travelling, so under
            /// Reduce Motion there is nothing for it to do.
            if outcome == .success && !reduceMotion {
                OutcomeSweep(progress: sweepProgress, palette: .success, layer: .band)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .task {
            entered = true

            /// Both the copy and the ripple wait for the token to land: they
            /// belong to the *waiting* state, and starting them mid-flight
            /// makes the rise look cluttered.
            Task {
                try? await Task.sleep(for: .seconds(Self.riseDuration))
                withAnimation(.smooth(duration: 0.35)) { labelShown = true }
                rippling = true
                /// One tick later, so the rings are mounted before `pulsing`
                /// changes — a `repeatForever` bound to a value that is
                /// already true when the view appears never starts.
                try? await Task.sleep(for: .milliseconds(16))
                pulsing = true
            }

            try? await Task.sleep(for: Self.processingDuration)

            UINotificationFeedbackGenerator()
                .notificationOccurred(outcome == .success ? .success : .error)

            /// The loop's fade-out overlaps the wave taking over — that
            /// overlap is what hides the hand-off between them.
            withAnimation(.smooth(duration: 0.6)) { phase = .settled(outcome) }

            /// The flush is the *result*, so it waits for the mark to land and
            /// the layout to settle first. Starting it on the same frame as
            /// the phase flip runs the colour up the screen while the token is
            /// still moving, and the whole thing reads as part of processing.
            try? await Task.sleep(for: .seconds(Self.settleBeforeSweep))

            /// The ripple bows out exactly as the flush arrives — the loop
            /// stops and its four bands hand straight to the release, which
            /// carries them off while the colour comes up behind.
            withAnimation(.smooth(duration: 0.35)) { rippling = false }
            releaseTrigger += 1

            /// Accelerating, not decelerating: the recording's edge took 1.7s
            /// to cover its first 122px and 0.22s to cover a later 158px. An
            /// easeOut curve fills 80% of the screen in the first third of a
            /// second and the flush reads as a cut.
            ///
            /// Not a pure `.easeIn` either — over this duration that hangs at
            /// the bottom and then whips across. This curve keeps the build
            /// but lets the band actually travel.
            /// Nothing green belongs on a failed buy — the cross and the copy
            /// carry that result on their own, on Backgrounds/Primary.
            guard outcome == .success else { return }

            let flush: Animation = reduceMotion
                ? .easeInOut(duration: 0.45)
                : .timingCurve(0.45, 0, 0.85, 1, duration: Self.sweepDuration)
            withAnimation(flush) { sweepProgress = 1 }
        }
    }

    // MARK: - Pieces

    /// The block is given a fixed height and pinned to its top, which is what
    /// holds the token still.
    ///
    /// The obvious alternative — keeping every slot present and merely
    /// transparent — would put the hidden headline between the token and
    /// "Buying PUDGY" and push that line 71pt down instead of the 24 it wants.
    /// Reserving the *height* rather than the slots gets both: the status line
    /// sits 24pt under the token throughout, and the token does not move when
    /// the headline arrives above it.
    private var confirmation: some View {
        VStack(spacing: 0) {
            tokenMark

            VStack(spacing: 6) {
                /// The failure frame (12580:54475) carries the status line on
                /// its own — nothing was bought, so there is no quantity to
                /// report and no transaction to go and look at.
                if phase.isSettled && outcome == .success {
                    Text(headline)
                        .figmaStyle(Theme.largeTitle, tracking: Theme.largeTitleTracking, color: Theme.pink)
                }

                statusText
                    .opacity(labelShown ? 1 : 0)
            }
            .multilineTextAlignment(.center)
            .frame(width: 297)
            .padding(.top, textTopGap)

            if outcome == .success {
                viewTxn
                    .padding(.top, 48)
                    .opacity(phase.isSettled ? 1 : 0)
            }
        }
        .frame(height: blockHeight, alignment: .top)
        .padding(.horizontal, 24)
        .animation(.smooth(duration: 0.4), value: phase)
    }

    /// 24 under the token while the buy is in flight, so "Buying PUDGY" sits
    /// close to it; either result then opens the gap to the 48 the settled
    /// frames set (12626:54880, 12580:54475).
    private var textTopGap: CGFloat {
        phase.isSettled ? 48 : 24
    }

    /// Sized for the settled state so the token's place is fixed from the
    /// first frame: token 172 + 48 + headline 41 + 6 + status 28 + 48 + link
    /// 34 on success, and token + 48 + status where there is no headline and
    /// no link.
    private var blockHeight: CGFloat {
        outcome == .success ? 377 : 248
    }

    /// "Buying PUDGY" while in flight, the result afterwards. Both sit at
    /// Title2 so the swap is a change of words rather than of weight.
    @ViewBuilder
    private var statusText: some View {
        if phase.isSettled {
            Text(statusLine)
                .figmaStyle(Theme.title2, tracking: Theme.title2Tracking, color: Theme.grayWhite)
        } else {
            ShimmerLabel(text: "Buying \(symbol)")
        }
    }

    /// The token at 172pt with the outcome badge sitting on its lower edge.
    /// Figma puts the badge's 65×62 box at y 132.5 inside the 172pt circle, so
    /// its centre lands 77.5pt below the token's.
    ///
    /// It makes **one** move: from the middle of the screen up to its place in
    /// the stack, turning once about the vertical axis on the way — the
    /// rotation is what narrows the disc to a sliver and back. Then it stops.
    ///
    /// One turn over 0.38s is ~950°/s, the same angular rate two turns over
    /// the original 0.75s gave. Halving the duration while keeping both turns
    /// doubled the speed, which is not what shortening it was meant to do.
    private var tokenMark: some View {
        Image(.pudgy)
            .resizable()
            .scaledToFill()
            .frame(width: 172, height: 172)
            .clipShape(.circle)
            .rotation3DEffect(
                .degrees(entered && !reduceMotion ? 360 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.35
            )
            /// The stack is laid out at its settled height from the start, so
            /// the token's resting place is already 102pt above the block's
            /// centre. Starting it that far *down* puts it mid-screen.
            .offset(y: entered || reduceMotion ? 0 : Self.tokenRise)
            .opacity(entered ? 1 : 0)
            .animation(.spring(response: 0.42, dampingFraction: 0.88), value: entered)
            .background { pulse }
            .overlay { sealBadge.offset(y: 77.5) }
    }

    /// The explorer link. Hidden until the buy resolves — there is no
    /// transaction to look at while it is still in flight.
    private var viewTxn: some View {
        Button(action: onViewTransaction) {
            HStack(spacing: 4) {
                Image(.txnExplorer)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)

                Text("View Txn")
                    .figmaStyle(Theme.footnote, tracking: Theme.footnoteTracking, color: .white)
            }
            /// Figma's node (12626:54943) hangs 8pt of padding off the right of
            /// the content row inside a 103×34 pill, which leaves the icon and
            /// the label sitting 4pt left of the pill's centre. That is a
            /// layout leftover rather than intent, so the row is centred and
            /// the pill keeps the size the design gives it.
            .frame(width: Self.viewTxnSize.width, height: Self.viewTxnSize.height)
        }
        .buttonStyle(.plain)
        /// The node's "Glass Effect" layer is the design asking for real Liquid
        /// Glass, so this is the system material rather than a flat tint.
        ///
        /// `.glassEffect` rather than `.buttonStyle(.glass)`: the button style
        /// wraps the label in its own control padding, which rendered the pill
        /// at 121×39 instead of the 103×34 the node specifies. This applies the
        /// material to exactly the shape it is given.
        .glassEffect(.regular.interactive(), in: .capsule)
        .accessibilityLabel("View transaction")
    }

    /// The badge only exists once there is an answer to put on it. Nothing
    /// marks the token while the buy is in flight — a badge with no glyph and
    /// no colour change is just an ornament, and any *tick* would be claiming
    /// a result that hasn't arrived.
    ///
    /// Both Figma frames are a flat mark: Semantic/Success for the tick
    /// (12562:52343), Finance/Negative for the cross (12552:49072).
    @ViewBuilder
    private var sealBadge: some View {
        if case .settled(let outcome) = phase {
            /// Monochrome knocks the tick or cross *out* of the badge, so the
            /// screen behind shows through it — palette mode paints both parts
            /// solid instead.
            ///
            /// Layer order is glyph-then-badge, not badge-then-glyph: passing
            /// one colour paints the *tick* and leaves the badge black.
            sealMark(outcome == .success ? "checkmark.seal.fill" : "xmark.seal.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.black, outcome == .success ? Theme.success : Theme.negative)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    /// The pulse now rings the 172pt token rather than the badge, so it hangs
    /// off the token's `.background`.
    ///
    /// It has to be a background and not a `ZStack` sibling: as a sibling its
    /// cloud sized the whole block and shoved the copy below it 91pt down the
    /// screen. A background is laid out against its subject and is free to
    /// overflow without touching the layout.
    private var pulse: some View {
        ZStack {
            if rippling && !reduceMotion {
                /// Removed outright rather than cross-faded: the release picks
                /// the bands up at exactly the diameters and opacities the loop
                /// left them at, so fading the loop too would double them.
                pulseBands
                    .transition(.identity)
            }

            pulseRelease
        }
    }

    /// All the marks share the `.seal.fill` family, so all share this sizing.
    private func sealMark(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            /// Figma's glyph measures 56×56 of ink inside a 62pt line box.
            /// `.font(.system(size: 56))` renders 62pt of ink, so the size is
            /// pinned on the image rather than the font — 58 of frame nets 56
            /// of ink once the symbol's bearing comes off.
            .frame(width: 58, height: 62)
    }

    /// The pulse doesn't blink out when the buy lands — it releases. The loop
    /// hands its three bands straight to this, which fades them out where they
    /// stand as the flush comes up behind.
    ///
    /// Always mounted and fired by `releaseTrigger`, never mounted on demand:
    /// a `keyframeAnimator(repeating: false)` that first appears inside an
    /// animated transaction doesn't play — the bands just sit at their initial
    /// value. Each track therefore starts from an invisible initial state and
    /// `MoveKeyframe`s to its real opening value the moment it fires.
    private var pulseRelease: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { band in
                Circle()
                    .stroke(Theme.gray3.opacity(0.16), lineWidth: 8)
                    .blur(radius: 3)
                    .keyframeAnimator(
                        initialValue: PulseRelease(
                            diameter: Self.bandStartDiameters[band],
                            opacity: 0
                        ),
                        trigger: releaseTrigger
                    ) { content, wave in
                        content
                            .frame(width: wave.diameter, height: wave.diameter)
                            .opacity(wave.opacity)
                    } keyframes: { _ in
                        /// A plain fade, holding position. Pushing the rings
                        /// outward as the flush arrived put two expanding
                        /// things on screen at once and read as a mess; pulling
                        /// them inward drew the eye back to the token just as
                        /// the colour was meant to take over. Standing still
                        /// and going quiet stays out of the way of both.
                        KeyframeTrack(\.opacity) {
                            MoveKeyframe(Self.bandStartOpacities[band])
                            LinearKeyframe(0, duration: Self.releaseDuration)
                        }
                    }
            }
        }
        .allowsHitTesting(false)
    }

    /// Three rings travelling out from behind the token, one every
    /// `ringStagger` so all three are in flight at once.
    ///
    /// There is deliberately no radial cloud behind them any more. It was
    /// meant to bind the bands into one soft mass, and it did exactly that —
    /// too well. With the cloud gone and the stroke held at a constant weight,
    /// what is left actually reads as ripples.
    private var pulseBands: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { band in
                Circle()
                    .stroke(Theme.gray3.opacity(0.16), lineWidth: 8)
                    .blur(radius: 3)
                    .frame(
                        width: pulsing ? Self.ringMax : Self.ringMin,
                        height: pulsing ? Self.ringMax : Self.ringMin
                    )
                    .opacity(pulsing ? 0 : 1)
                    .animation(
                        .easeOut(duration: Self.ringPeriod)
                            .repeatForever(autoreverses: false)
                            .delay(Double(band) * Self.ringStagger),
                        value: pulsing
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            GlassPillButton(title: "Close", tint: Theme.gray3, emphasis: .standard, action: onClose)
            /// "Buy Again" would be claiming the buy went through, so a failed
            /// transaction offers the retry instead — and the failure frame
            /// tints it Brand/Pink rather than Semantic/Success, which would
            /// read as a result rather than an action.
            GlassPillButton(
                title: outcome == .success ? "Buy Again" : "Try Again",
                tint: outcome == .success ? Theme.success : Theme.pink,
                action: onBuyAgain
            )
        }
        .frame(width: 354)
        .offset(y: phase.isSettled || reduceMotion ? 0 : 130)
        .opacity(phase.isSettled ? 1 : 0)
        .padding(.bottom, 24)
    }

    // MARK: - Derived

    /// "1,000 PUDGY" in the design — grouped, and only as many decimals as the
    /// quantity actually has.
    private var headline: String {
        let amount = quantity.formatted(
            .number.grouping(.automatic).precision(.fractionLength(0...2))
        )
        return "\(amount) \(symbol)"
    }

    /// "Bought Successfully" is a claim, so the failed state must not keep
    /// making it.
    ///
    /// Both frames set these lower-case ("bought succesfully", "transaction
    /// failed"); title case is a deliberate override. The success frame's
    /// spelling is also a typo — one 's' — and is corrected here.
    private var statusLine: String {
        phase == .settled(.failure) ? "Transaction Failed" : "Bought Successfully"
    }

}


/// What one band of the farewell wave animates. Diameter rather than scale,
/// so the ring's stroke stays the same weight the whole way out.
private struct PulseRelease {
    var diameter: CGFloat = 176
    var opacity: Double = 1
}

#Preview("Success") {
    BoughtScreen(quantity: .money("118.68"), symbol: "PUDGY", outcome: .success) {} onBuyAgain: {}
}

#Preview("Failure") {
    BoughtScreen(quantity: .money("118.68"), symbol: "PUDGY", outcome: .failure) {} onBuyAgain: {}
}
