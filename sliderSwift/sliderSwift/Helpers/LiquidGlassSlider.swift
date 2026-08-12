//
//  LiquidGlassSlider.swift
//  sliderSwift
//
//  Slide-to-confirm, drawn exactly as the Figma design specifies: a flat
//  Semantic/Success track, a solid white pill knob with the chevron inside, and
//  a centred label. No Liquid Glass material, no refraction, no shimmer — the
//  only motion is the knob scaling up while you drag it.
//
//  Adapted from a third-party slide-to-confirm control; the drag/spring core is
//  that original's, and the glass dressing it shipped with was dropped. See
//  CLAUDE.md ("Provenance") before shipping.
//

import SwiftUI
import UIKit

struct LiquidGlassSlider: View {
    var text: String
    var config: Config
    var onProgressChange: (CGFloat) -> () = { _ in }
    var onFinish: (Bool) -> () = { _ in }

    /// The disabled treatment, from Figma 12269:25270.
    ///
    /// The design dims the bar **layer by layer**, not as one flattened
    /// control, and nothing is desaturated — the track keeps its green and
    /// simply recedes into the sheet. Flattening it to a single `.opacity` on
    /// the whole bar gives the label the track's strength instead of its own.
    ///
    /// The numbers are taken from what the node *renders*, not from the layer
    /// opacities the inspector lists. The node's background is a stack — a 75%
    /// white, a saturation pass, a `#999` overlay, Semantic/Success, and a
    /// glass effect over the lot — set to 40%, and that stack does not resolve
    /// to 40% of the enabled button. Sampled over Backgrounds/Primary the
    /// design's disabled track is `#0F2916`, which `successButton` reaches at
    /// **15%**; at 40% it comes out `#0C4C1C`, near twice as green.
    private static let disabledTrack: Double = 0.15
    /// The knob sits *on* the track, so its 40% is measured against the dimmed
    /// green rather than the sheet: `#E9E9E9` at 0.4 over `#0F2916` is
    /// `#657569`, which is the design to the byte.
    private static let disabledKnob: Double = 0.4
    /// Plus-lighter, per the node — and it is not cosmetic. Additive at 30%
    /// over the track gives `#597360`, exactly what the design renders; plain
    /// 30% alpha lands at `#546659` and reads noticeably deader.
    private static let disabledLabel: Double = 0.3

    @GestureState private var isActive: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var isCompleted: Bool = false
    @State private var resetTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            /// How far the knob can travel: the track minus the inset on both
            /// sides minus the knob itself.
            let maxOffset = max(0, geo.size.width - (config.knobInset * 2) - config.knobSize.width)

            ZStack(alignment: .leading) {
                /// Track — flat Semantic/Success, per the design.
                Capsule()
                    .fill(config.tint)
                    /// Figma: 0 / 8 / 40 at black 12%. CSS blur maps to ~half
                    /// in SwiftUI. It hangs off the track rather than the whole
                    /// control so that dimming the track dims its shadow too,
                    /// the way the design nests them.
                    .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
                    .opacity(config.isEnabled ? 1 : Self.disabledTrack)

                label
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(config.isEnabled ? 1 : Self.disabledLabel)
                    /// Only when disabled. The enabled bar is already matched
                    /// to its own node and blending it there would move a
                    /// verified colour for no gain.
                    .blendMode(config.isEnabled ? .normal : .plusLighter)

                knob
                    .frame(width: config.knobSize.width, height: config.knobSize.height)
                    .contentShape(.capsule)
                    /// The one piece of motion: the pill grows while dragging.
                    .scaleEffect(isActive ? config.activeScale : config.restScale)
                    .opacity(config.isEnabled ? 1 : Self.disabledKnob)
                    .offset(x: config.knobInset + offsetX)
                    .allowsHitTesting(!isCompleted && config.isEnabled)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .updating($isActive, body: { _, out, _ in
                                out = true
                            })
                            .onChanged({ value in
                                resetTask?.cancel()
                                let translation = value.translation.width
                                let cappedOffset = min(max(translation, 0), maxOffset)
                                offsetX = cappedOffset
                                onProgressChange(maxOffset > 0 ? cappedOffset / maxOffset : 0)
                            })
                            .onEnded({ _ in
                                /// Float-safe rather than an exact `==`, since
                                /// maxOffset comes out of a layout proxy.
                                let didComplete = offsetX >= maxOffset - 0.5
                                onFinish(didComplete)

                                if didComplete {
                                    complete(at: maxOffset)
                                } else {
                                    withAnimation(.smooth) { offsetX = 0 }
                                    onProgressChange(0)
                                }
                            })
                    )
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
        }
        .frame(height: config.height)
        .animation(.smooth(duration: 0.25), value: config.isEnabled)
        .accessibilityAddTraits(config.isEnabled ? [] : .isButton)
        .onChange(of: config.isEnabled) { _, enabled in
            /// A knob left mid-track when the amount stops being valid would
            /// read as still draggable.
            guard !enabled else { return }
            withAnimation(.smooth) { offsetX = 0 }
            onProgressChange(0)
        }
        .onChange(of: config.resetToggle) { _, _ in
            resetTask?.cancel()
            isCompleted = false
            offsetX = .zero
        }
        .onDisappear { resetTask?.cancel() }
    }

    // MARK: - Pieces

    private var label: some View {
        ZStack {
            Text(text)
                .figmaStyle(config.textFont, tracking: config.textTracking, color: config.textColor)
                .opacity(isCompleted ? 0 : 1)

            completedLabel
                .opacity(isCompleted ? 1 : 0)
        }
        .animation(.smooth(duration: 0.25), value: isCompleted)
        .lineLimit(1)
    }

    private var completedLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: config.completedSymbol)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(config.completedText)
                .figmaStyle(config.textFont, tracking: config.textTracking, color: config.textColor)
        }
        .foregroundStyle(config.textColor)
    }

    /// Solid white pill with Figma's chevron centred in it.
    private var knob: some View {
        Capsule()
            .fill(config.knobFill)
            .overlay {
                Image(config.knobImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: config.knobImageWidth)
            }
    }

    // MARK: - Completion

    private func complete(at maxOffset: CGFloat) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.smooth) { offsetX = maxOffset }
        isCompleted = true
        onProgressChange(1)

        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            isCompleted = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { offsetX = 0 }
            onProgressChange(0)
        }
    }

    struct Config {
        /// Track fill — Semantic/Success (#30D158) in the design.
        var tint: Color
        /// False dims the bar and refuses the drag. The caller decides what
        /// makes an amount valid; this only reflects it.
        var isEnabled: Bool = true
        var height: CGFloat = 56
        /// The knob is a pill, not a circle: 55x40 inset 8pt inside a 56pt track.
        var knobSize: CGSize = CGSize(width: 55, height: 40)
        var knobInset: CGFloat = 8
        /// Grays/White (#E9E9E9).
        var knobFill: Color = Theme.grayWhite

        /// Figma's exported arrow: four #30D158 chevrons at a baked
        /// 1 / 0.7 / 0.4 / 0.1 alpha ramp, 27.008pt wide. `.slideArrowSingle`
        /// is the rightmost chevron on its own, if you ever want just one.
        ///
        /// An `ImageResource` rather than a name: a mistyped string is a blank
        /// space at runtime, a mistyped symbol is a build error.
        var knobImage: ImageResource = .slideArrow
        var knobImageWidth: CGFloat = 27

        /// 1.0 at rest keeps the knob at the exact 55x40 the design specifies;
        /// it grows to `activeScale` only while being dragged.
        var restScale: CGFloat = 1
        var activeScale: CGFloat = 1.15

        var textFont: Font = Theme.body
        var textTracking: CGFloat = Theme.bodyTracking
        /// The design sets this label to plain white, not the #F5F5F5 label token.
        var textColor: Color = .white

        var completedText: String = "Bought"
        var completedSymbol: String = "checkmark"
        /// Toggling this returns the knob to zero — see `BuyScreen`'s
        /// `resetSlider`, which flips it when the confirmation is dismissed.
        var resetToggle: Bool = false
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        LiquidGlassSlider(
            text: "Buy Pudgy",
            config: .init(tint: Theme.success)
        )
        .frame(width: 354)
    }
    .preferredColorScheme(.dark)
}
