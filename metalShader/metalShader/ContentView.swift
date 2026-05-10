//
//  ContentView.swift
//  metalShader
//

import SwiftUI

enum RevealPhase {
    case cluster
    case explosion
}

struct ContentView: View {
    @State private var phase: RevealPhase = .cluster
    @State private var loaderStart: Date = .distantPast
    @State private var revealStart: Date? = nil
    @State private var petalStart: Date? = nil
    @State private var canDismiss: Bool = false
    @State private var petalsActive: Bool = false

    private let loaderDuration: Double = 1.0
    private let revealDuration: Double = 2.0
    // Tracks the pink-band hold window. Slightly longer than the old 3 s so
    // the band stays visible while the petals fall naturally to the bottom.
    private let petalDuration: Double = 4.0
    private let horizontalPadding: CGFloat = 24
    private let imageAspect: CGFloat = PnlCardView.imageAspect

    // When the eased reveal progress crosses this value, the shimmer starts
    // and we fire petals + band-hold simultaneously.
    private let shimmerTriggerProgress: Double = 0.30

    var body: some View {
        GeometryReader { geo in
            let cardW = max(0, geo.size.width - horizontalPadding * 2)
            let cardH = cardW / imageAspect

            // TimelineView drives continuous per-frame values so the shader
            // receives smoothly-interpolated progress for the orbs/card/shimmer.
            TimelineView(.animation) { timeline in
                let now = timeline.date

                // Loader countdown 0..1 over 4 s.
                let loaderProgress: Double = {
                    let elapsed = now.timeIntervalSince(loaderStart)
                    return min(1, max(0, elapsed / loaderDuration))
                }()

                // Main reveal: raw elapsed / 2 s, then cubic smoothstep for a
                // spring-like ease-in-out shape.
                let rawReveal: Double = {
                    guard let start = revealStart else { return 0 }
                    return min(1, max(0, now.timeIntervalSince(start) / revealDuration))
                }()
                let progress = rawReveal * rawReveal * (3.0 - 2.0 * rawReveal)

                // Band migration (orbs 2/3 → bottom pink band).
                //
                // Window starts at rawReveal=0.55 — the exact moment the 4-orb
                // formation finishes (`p2 = smoothstep(0.30, 0.65, progress)`
                // hits 1 there). This eliminates the 300 ms static gap between
                // 4-orb landing and band-migration kickoff that previously
                // read as a "stop."
                //
                // bandPhase is *linear* (not bandT³). Linear has non-zero
                // velocity from the first frame, so motion is visible
                // immediately — no sub-perceptual cubic ramp-up. Constant
                // velocity through landing, then yDrift continues smoothly
                // past it. Not clamped above 1 — bandT runs to ~1.125 by
                // rawReveal=1.0, extending position past planned landing
                // (shader clamps for the shape morph only).
                let bandT = max(0.0, (rawReveal - 0.55) / 0.40)
                let bandPhase = bandT

                // Band-hold: raw elapsed / 3 s after petals launch (no curve —
                // we want a steady fade in the last 15% of the window).
                let bandPersist: Double = {
                    guard let start = petalStart else { return 0 }
                    return min(1, max(0, now.timeIntervalSince(start) / petalDuration))
                }()

                let cardAlphaNow = phase == .explosion ? cardAlpha(progress) : 0.0

                ZStack {
                    Color.black.ignoresSafeArea()

                    // Petals behind the card.
                    PetalEmitterView(
                        isActive: petalsActive,
                        origin: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
                        canvasSize: geo.size
                    )
                    .ignoresSafeArea()

                    // Card with 3D tilt.
                    TiltableCard { tX, tY in
                        PnlCardView(progress: progress, tiltX: tX, tiltY: tY)
                    }
                    .frame(width: cardW, height: cardH)
                    .opacity(cardAlphaNow)
                    .scaleEffect(0.88 + 0.12 * cardAlphaNow)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .allowsHitTesting(canDismiss)

                    // Persistent particle / orb MTKView.
                    MetalParticleView(
                        mode: phase == .explosion ? .explosion : .idle,
                        progress: progress,
                        bandPhase: bandPhase,
                        bandPersist: bandPersist
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                    // "Closing Position" label + 4 s countdown loader with a
                    // 4 pt gap between them. Shown only in idle phase.
                    if phase == .cluster {
                        HStack(spacing: 4) {
                            Text("Closing Position")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.88))
                                .shadow(color: .black.opacity(0.9), radius: 6)
                            CountdownLoader(progress: loaderProgress, size: 16, lineWidth: 2)
                        }
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .transition(.opacity)
                    }
                }
                .onChange(of: progress) { _, newValue in
                    // Fire petals + band-hold exactly when the shader shimmer
                    // starts — not after the reveal ends.
                    if phase == .explosion
                        && newValue >= shimmerTriggerProgress
                        && !petalsActive
                    {
                        petalsActive = true
                        petalStart = now
                    }
                    // Dismiss is available the moment the reveal finishes — we
                    // don't wait for petals to finish falling.
                    if newValue >= 1.0 && phase == .explosion && !canDismiss {
                        canDismiss = true
                    }
                }
                .onChange(of: loaderProgress) { _, newValue in
                    // Auto-start the reveal the instant the countdown finishes.
                    if newValue >= 1.0 && phase == .cluster && revealStart == nil {
                        startReveal()
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if phase == .explosion && canDismiss {
                    returnToIdle()
                }
            }
        }
        .onAppear {
            startCountdown()
        }
    }

    // MARK: - Lifecycle

    private func startCountdown() {
        phase = .cluster
        revealStart = nil
        petalStart = nil
        canDismiss = false
        petalsActive = false
        loaderStart = Date()
    }

    private func startReveal() {
        phase = .explosion
        revealStart = Date()
    }

    private func returnToIdle() {
        petalsActive = false
        canDismiss = false
        withAnimation(.spring(duration: 0.35, bounce: 0.0)) {
            // SwiftUI-level phase change; progress/band reset to 0 via revealStart/petalStart = nil
        }
        phase = .cluster
        revealStart = nil
        petalStart = nil
        startCountdown()
    }

    // MARK: - Card opacity curve

    private func cardAlpha(_ p: Double) -> Double {
        let t = (p - 0.15) / 0.80
        let c = max(0.0, min(1.0, t))
        return c * c * (3.0 - 2.0 * c)
    }
}

#Preview {
    ContentView()
}
