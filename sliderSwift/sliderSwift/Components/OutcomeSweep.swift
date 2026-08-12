//
//  OutcomeSweep.swift
//  sliderSwift
//
//  The flush the screen runs once a buy resolves, from the Cash App
//  card-switch recording.
//
//  The shape of it, read off the reference frames: along the sweep axis there
//  are *four* zones, not two —
//
//      ┌ black ─────────── nothing has arrived yet
//      ├ dark green ────── a narrow herald just ahead of the edge
//      ├ CREAM BAND ────── wide, bright, the thing you actually watch
//      ├ pale green ────── immediately behind the edge
//      └ teal ──────────── long behind, the deepest part of the trail
//
//  So the field is a ramp that *travels with* the edge, and when the edge
//  finally leaves the top of the screen what remains is the tail of that ramp:
//  bright at the head, teal at the foot. That is exactly the profile measured
//  off the recording's settled frame (#81DC60 at 5% down to #2A5551 at 95%),
//  which is the proof the two descriptions are the same thing.
//
//  It draws in two layers because they sit on opposite sides of the content:
//
//    · `.field` goes *behind* the screen's content, so the copy stays readable
//      once the colour has arrived.
//    · `.band` goes *in front* of it, so the bright edge washes over the text
//      as it passes — which is what the reference frames show happening to the
//      keypad, and what a single layer behind the content can never reproduce.
//
//  Geometry: the boundary is a straight line at −18.0°, higher on the right,
//  arriving from the bottom-right and travelling to the top-left, accelerating
//  as it goes.
//

import SwiftUI

/// The five palette stops the Metal field is run through, darkest first, plus
/// the colour of the bright band that uncovers it.
///
/// The ramp is built *around* Semantic/Success rather than merely including
/// it: `light` is `#30D158` exactly, and `deep`/`mid`/`pale` are shades of the
/// same hue. Putting the design green at one stop among five unrelated
/// colours leaves it a minority of the field — the shader's palette function
/// spends most of its range between the first three stops.
///
/// The dark end still has to reach near-black. That is what gives the bright
/// stops somewhere to fall from; a ramp bottoming out mid-tone has no depth
/// anywhere in it.
struct SweepPalette {
    let deep: Color
    let mid: Color
    let light: Color
    let pale: Color
    /// The wide bright band that travels ahead of the field.
    let band: Color

    static let success = SweepPalette(
        deep: Color(hex: 0x04140A),
        mid: Color(hex: 0x0F4420),
        light: Color(hex: 0x30D158),
        pale: Color(hex: 0x8DE6A3),
        band: Color(hex: 0xEEF7CD)
    )
}

struct OutcomeSweep: View {
    /// Which side of the screen's content this instance draws on.
    enum Layer {
        /// The travelling colour ramp. Goes behind the content.
        case field
        /// The bright edge. Goes in front, and washes over the content.
        case band
    }

    /// 0 parks the edge below the screen, 1 has it clear of the top. Animate
    /// this and the whole flush follows.
    var progress: Double
    var palette: SweepPalette
    var layer: Layer
    /// Passed through to the shader. Off freezes the field on one frame, which
    /// is what Reduce Motion wants and also what a battery-conscious build
    /// wants once the screen has settled.
    var animates = true

    /// How wide the bright band is as a fraction of the axis. The reference's
    /// band covers roughly a third of the screen at its widest — it is a broad
    /// wash, not the hairline a first reading of the footage suggests.
    private let bandWidth: Double = 0.32

    /// The recording's boundary is a straight line at **−18.0°** — measured by
    /// least-squares over the detected edge across five frames, which returned
    /// −0.324, −0.337, −0.324, −0.324, −0.324 — sitting *higher on the right*.
    ///
    /// A plain `.bottomTrailing → .topLeading` corner gradient is −402/874 =
    /// −0.460, i.e. −24.7°: too steep, and a `.bottomLeading` one is mirrored
    /// outright.
    ///
    /// SwiftUI puts the gradient axis through `(s.x·W, s.y·H) → (e.x·W, e.y·H)`,
    /// and the visible boundary is the line *perpendicular* to it, so the unit
    /// points solve `Δu/Δv = 0.324 · H / W` = 0.7045. Getting that ratio the
    /// other way up gives a −4.0° boundary — right direction, far too shallow.
    private var sweepStart: UnitPoint { UnitPoint(x: 0.852, y: 1) }
    private var sweepEnd: UnitPoint { UnitPoint(x: 0.148, y: 0) }

    @ViewBuilder
    var body: some View {
        switch layer {
        case .field:
            /// The Metal field, uncovered by the wipe. The mask is what makes
            /// it travel; the shader itself just fills whatever it is given.
            WallpaperGradient(palette: palette, animates: animates)
                .mask(alignment: .center) { fieldMask }
                .ignoresSafeArea()
                .allowsHitTesting(false)

        case .band:
            LinearGradient(stops: bandStops, startPoint: sweepStart, endPoint: sweepEnd)
                .opacity(edgeVisibility)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    // MARK: - Pieces

    /// The wipe that uncovers the field, positioned relative to the edge
    /// rather than to the screen — which is what makes the whole thing travel
    /// instead of cross-fading.
    ///
    /// The two half-strength stops just ahead of the edge are the dark herald
    /// the reference shows between the bright band and the black: the field
    /// arrives dimmed for a moment before it comes up to full.
    private var fieldMask: some View {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: clamp(edgePosition - 0.06)),
                .init(color: .white.opacity(0.55), location: clamp(edgePosition + 0.06)),
                .init(color: .white.opacity(0.18), location: clamp(edgePosition + 0.16)),
                .init(color: .clear, location: clamp(edgePosition + 0.26)),
                .init(color: .clear, location: 1)
            ],
            startPoint: sweepStart,
            endPoint: sweepEnd
        )
    }

    /// The band. Every stop is the band colour varying only in alpha — ramping
    /// to `Color.clear` instead fades through transparent *black*, which drags
    /// the midtones down and leaves a dim smear where the band should be.
    private var bandStops: [Gradient.Stop] {
        let edge = edgePosition
        let glow = palette.band
        return [
            .init(color: glow.opacity(0), location: 0),
            .init(color: glow.opacity(0), location: clamp(edge - bandWidth)),
            .init(color: glow.opacity(0.5), location: clamp(edge - bandWidth * 0.5)),
            .init(color: glow, location: clamp(edge - bandWidth * 0.12)),
            .init(color: glow.opacity(0.45), location: clamp(edge + bandWidth * 0.16)),
            .init(color: glow.opacity(0), location: clamp(edge + bandWidth * 0.5)),
            .init(color: glow.opacity(0), location: 1)
        ]
    }

    /// Travel overshoots at both ends so the edge starts fully off the bottom
    /// and finishes fully off the top.
    private var edgePosition: Double {
        -0.25 + progress * 1.5
    }

    /// The band fades in off the bottom and out past the top, so it never pops
    /// into or sticks in a corner. The field has no such treatment — it is
    /// meant to stay once it has arrived.
    private var edgeVisibility: Double {
        if edgePosition < 0 { return max(0, 1 + edgePosition / 0.25) }
        if edgePosition > 1 { return max(0, 1 - (edgePosition - 1) / 0.3) }
        return 1
    }

    /// Gradient stops must stay inside 0...1 and non-decreasing; a negative
    /// location silently scrambles the whole gradient.
    private func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

#Preview {
    struct Demo: View {
        let palette: SweepPalette
        @State private var progress: Double = 0

        var body: some View {
            ZStack {
                Theme.background.ignoresSafeArea()
                OutcomeSweep(progress: progress, palette: palette, layer: .field)
                Text("118.68")
                    .figmaStyle(Theme.display, tracking: Theme.displayTracking, color: Theme.grayWhite)
                OutcomeSweep(progress: progress, palette: palette, layer: .band)
            }
            .onTapGesture { replay() }
            .task { replay() }
        }

        private func replay() {
            progress = 0
            withAnimation(.timingCurve(0.45, 0, 0.85, 1, duration: 1.6)) { progress = 1 }
        }
    }

    return Demo(palette: .success)
        .preferredColorScheme(.dark)
}
