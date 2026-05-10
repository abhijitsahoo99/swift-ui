//
//  ExplosionRevealView.swift
//  metalShader
//

import SwiftUI

struct ExplosionRevealView: View {
    let onDismiss: () -> Void

    @State private var startDate: Date = .init()
    @State private var progress: Double = 0.0
    @State private var canDismiss: Bool = false
    @State private var petalsActive: Bool = false

    // Animation length in seconds. Matches pacing of reference frames.
    private let duration: Double = 3.0

    // Card size — full width minus 24pt padding on each side; height from image aspect.
    private let horizontalPadding: CGFloat = 24
    private let imageAspect: CGFloat = PnlCardView.imageAspect

    var body: some View {
        GeometryReader { geo in
            let cardW = max(0, geo.size.width - horizontalPadding * 2)
            let cardH = cardW / imageAspect

            ZStack {
                Color.black.ignoresSafeArea()

                PnlCardView(progress: progress)
                    .frame(width: cardW, height: cardH)
                    .opacity(cardAlpha(progress))
                    .scaleEffect(0.88 + 0.12 * cardAlpha(progress))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                TimelineView(.animation) { timeline in
                    let elapsed = max(0.0, timeline.date.timeIntervalSince(startDate))
                    let raw = min(elapsed / duration, 1.0)
                    // Ease-in-out (smoothstep cubic) — slow start, fast middle, slow settle.
                    let eased = raw * raw * (3.0 - 2.0 * raw)

                    MetalParticleView(mode: .explosion, progress: eased)
                        .ignoresSafeArea()
                        .onChange(of: eased) { _, newValue in
                            progress = newValue
                            if raw >= 1.0 {
                                if !canDismiss { canDismiss = true }
                                if !petalsActive { petalsActive = true }
                            }
                        }
                }

                // Petal burst fires once progress hits 1.0 — above particles.
                PetalEmitterView(
                    isActive: petalsActive,
                    origin: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
                    canvasSize: geo.size
                )
                .ignoresSafeArea()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if canDismiss {
                    petalsActive = false
                    onDismiss()
                }
            }
        }
        .onAppear {
            startDate = .now
            progress = 0.0
            canDismiss = false
            petalsActive = false
        }
    }

    // Card opacity curve — fades in from progress 0.15 → 0.95 so the card
    // reaches 100% exactly as the last orb disappears.
    private func cardAlpha(_ p: Double) -> Double {
        let t = (p - 0.15) / 0.80
        let c = max(0.0, min(1.0, t))
        return c * c * (3.0 - 2.0 * c)
    }
}

#Preview {
    ExplosionRevealView(onDismiss: {})
}
