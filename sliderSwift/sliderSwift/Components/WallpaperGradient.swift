//
//  WallpaperGradient.swift
//  sliderSwift
//
//  SwiftUI's side of `WallpaperGradient.metal` — a domain-warped fbm field run
//  through a five-stop palette. It is what the success flush uncovers, and it
//  is the screen's resting state once the edge has passed.
//
//  Every constant below is the value supplied with the shader rather than one
//  chosen here. That matters: guessing at them produced a flat, washed field.
//  The two that carry the look are `warp` (2.8 — the domain warp is what folds
//  the field into ribbons instead of blobs) and the palette's dark end, which
//  bottoms out near-black so the bright stops have somewhere to fall from.
//

import SwiftUI

struct WallpaperGradient: View {
    /// The five palette stops, darkest first.
    var palette: SweepPalette

    /// Turns the field over. Off freezes it on one frame, which is worth doing
    /// if this ever becomes a screen people sit on — a live `TimelineView`
    /// shader redraws at 60fps for as long as it is on screen.
    var animates = true

    // MARK: - Look

    /// 0 is the smooth mode; 1 banks the field into `bands` contours.
    private let mode: Float = 0
    private let scale: Float = 1.0
    /// The domain warp. This is the single most consequential value in here.
    private let warp: Float = 3.45
    private let contrast: Float = 1.5
    private let bands: Float = 1
    private let rotation: Float = 90
    private let lift: Float = -0.04
    /// Note the shader folds this into both `scale` and `warp`.
    private let softness: Float = 0.17
    /// The shader lays its own grain over the field, and it is part of the
    /// look rather than a separate texture layer.
    private let grain: Float = 1
    private let vignette: Float = 1
    private let seed: Float = 68.5
    private let speed: Float = 1
    private let amount: Float = 0.075
    private let waves: Float = 15

    /// Elapsed since the view appeared, so `time` starts at zero. Handing a
    /// `Float` the raw seconds-since-2001 (~8×10⁸) spends the whole mantissa
    /// on the integer part and the drift quantises into visible steps.
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !animates)) { context in
            Color.black
                .colorEffect(
                    ShaderLibrary.wallpaperGradient(
                        .boundingRect,
                        .float(Float(context.date.timeIntervalSince(start))),
                        .float(mode),
                        .float(scale),
                        .float(warp),
                        .float(contrast),
                        .float(bands),
                        .float(rotation),
                        .float(lift),
                        .float(softness),
                        .float(grain),
                        .float(vignette),
                        .float(seed),
                        .float(animates ? 1 : 0),
                        .float(speed),
                        .float(amount),
                        .float(waves),
                        .color(palette.deep),
                        .color(palette.mid),
                        .color(palette.light),
                        .color(palette.pale),
                        .color(palette.band)
                    )
                )
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    WallpaperGradient(palette: .success)
        .ignoresSafeArea()
}
