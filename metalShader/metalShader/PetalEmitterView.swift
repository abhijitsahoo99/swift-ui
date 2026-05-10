//
//  PetalEmitterView.swift
//  metalShader
//
//  Ports the flower-petal burst from PnlCardLive.jsx: 130 pink petals launch
//  upward from the card centre, swirl with a sine offset, spin, fall with
//  gravity and damping, fade in the lower half of the screen.
//

import SwiftUI

private struct Petal: Identifiable {
    let id: Int
    let delay: Double      // seconds before this petal becomes active
    var active: Bool = false
    var dead: Bool = false
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    let swirl: Double
    let swirlFreq: Double
    let swirlPhase: Double
    var angle: Double      // rotation in degrees
    let spin: Double       // degrees per tick
    let scale: Double
    let color: Color
    let pathIndex: Int
    var life: Double = 1.0
}

struct PetalEmitterView: View {
    /// Trip from false → true to launch petals.
    var isActive: Bool
    /// Origin in the view's own coordinate space (usually screen centre).
    var origin: CGPoint
    /// Full canvas size (used for off-screen culling and fade threshold).
    var canvasSize: CGSize

    @State private var petals: [Petal] = []
    @State private var emitStart: Date? = nil
    @State private var lastTick: Date? = nil

    // Colour palette from the JSX.
    private static let palette: [Color] = [
        Color(hex: 0xFFD6E8), Color(hex: 0xFFAECE), Color(hex: 0xFFC2DA),
        Color(hex: 0xFFE4F0), Color(hex: 0xFFB8D4), Color(hex: 0xFFF0F6),
        Color(hex: 0xF9A8C9), Color(hex: 0xFFCCE4), Color(hex: 0xFFD9EC)
    ]

    private static let count = 130

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                guard !petals.isEmpty else { return }
                for p in petals where !p.dead && p.active {
                    let path = Self.petalPath(index: p.pathIndex)
                    var tx = CGAffineTransform.identity
                    tx = tx.translatedBy(x: p.x, y: p.y)
                    tx = tx.rotated(by: p.angle * .pi / 180)
                    tx = tx.scaledBy(x: p.scale, y: p.scale)
                    let transformed = path.applying(tx)
                    ctx.opacity = max(0, p.life)
                    ctx.fill(transformed, with: .color(p.color))
                }
            }
            .onChange(of: timeline.date) { _, newDate in
                tick(at: newDate)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newVal in
            if newVal { launch() }
            else { petals.removeAll() ; emitStart = nil ; lastTick = nil }
        }
    }

    // MARK: - Lifecycle

    private func launch() {
        var seeded: [Petal] = []
        seeded.reserveCapacity(Self.count)
        for i in 0..<Self.count {
            let angle = Double.pi / 2 + Double.random(in: -1.0...1.0)   // upward ± 1 rad
            let speed = Double.random(in: 7...22)
            seeded.append(Petal(
                id: i,
                delay: Double.random(in: 0...0.30),
                x: origin.x,
                y: origin.y,
                vx: cos(angle) * speed,
                vy: -sin(angle) * speed,      // screen-space: -y is up
                swirl: Double.random(in: 2.5...5.5),
                swirlFreq: Double.random(in: 0.24...0.54),  // rad/s (JSX 0.004–0.009 rad/ms)
                swirlPhase: Double.random(in: 0...(2 * .pi)),
                angle: Double.random(in: 0...360),
                spin: Double.random(in: -0.8...0.8),
                scale: Double.random(in: 0.35...0.9),
                color: Self.palette.randomElement()!,
                pathIndex: Int.random(in: 0..<3)
            ))
        }
        petals = seeded
        emitStart = Date()
        lastTick = Date()
    }

    private func tick(at now: Date) {
        guard let start = emitStart else { return }
        guard let prev = lastTick else { lastTick = now ; return }
        let dt = now.timeIntervalSince(prev)
        if dt <= 0 { return }
        lastTick = now

        // JSX constants are per-frame @ ~60 fps. Convert to per-second.
        let frames = dt * 60.0
        let elapsed = now.timeIntervalSince(start)
        let screenH = canvasSize.height
        let screenW = canvasSize.width
        let fadeStartY = screenH * 0.55

        var allDead = true
        for i in 0..<petals.count {
            if petals[i].dead { continue }
            allDead = false

            if !petals[i].active {
                if elapsed >= petals[i].delay { petals[i].active = true }
                else { continue }
            }

            // Gravity bumped 0.07 → 0.12 so petals fall noticeably faster
            // after their initial upward burst — reaches the bottom sooner
            // without needing a life-cap. Damping unchanged.
            petals[i].vy += 0.12 * frames
            petals[i].vx *= pow(0.992, frames)
            petals[i].vy *= pow(0.992, frames)

            let t = elapsed * petals[i].swirlFreq + petals[i].swirlPhase
            petals[i].x += (petals[i].vx + sin(t) * petals[i].swirl) * frames
            petals[i].y += (petals[i].vy + cos(t) * petals[i].swirl * 0.3) * frames
            petals[i].angle += petals[i].spin * frames

            if petals[i].y > fadeStartY { petals[i].life -= 0.006 * frames }
            if petals[i].x < -80 || petals[i].x > screenW + 80 { petals[i].life -= 0.015 * frames }

            if petals[i].y > screenH + 80 || petals[i].life <= 0 {
                petals[i].dead = true
            }
        }

        if allDead {
            petals.removeAll()
            self.emitStart = nil
            self.lastTick = nil
        }
    }

    // MARK: - Petal shapes (ported from PETAL_PATHS in the JSX)

    private static func petalPath(index: Int) -> Path {
        switch index {
        case 0: return path0
        case 1: return path1
        default: return path2
        }
    }

    private static let path0: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -14))
        p.addCurve(to: CGPoint(x: 15, y: 2),   control1: CGPoint(x: 5, y: -12),  control2: CGPoint(x: 13, y: -6))
        p.addCurve(to: CGPoint(x: 6, y: 22),   control1: CGPoint(x: 17, y: 10),  control2: CGPoint(x: 13, y: 18))
        p.addCurve(to: CGPoint(x: -6, y: 22),  control1: CGPoint(x: 2, y: 24),   control2: CGPoint(x: -2, y: 24))
        p.addCurve(to: CGPoint(x: -15, y: 2),  control1: CGPoint(x: -13, y: 18), control2: CGPoint(x: -17, y: 10))
        p.addCurve(to: CGPoint(x: 0, y: -14),  control1: CGPoint(x: -13, y: -6), control2: CGPoint(x: -5, y: -12))
        p.closeSubpath()
        return p
    }()

    private static let path1: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -13))
        p.addCurve(to: CGPoint(x: 13, y: 3),   control1: CGPoint(x: 6, y: -10),   control2: CGPoint(x: 12, y: -4))
        p.addCurve(to: CGPoint(x: 4, y: 22),   control1: CGPoint(x: 15, y: 11),   control2: CGPoint(x: 10, y: 19))
        p.addCurve(to: CGPoint(x: -7, y: 21),  control1: CGPoint(x: 1, y: 24),    control2: CGPoint(x: -3, y: 23))
        p.addCurve(to: CGPoint(x: -14, y: 2),  control1: CGPoint(x: -14, y: 17),  control2: CGPoint(x: -16, y: 9))
        p.addCurve(to: CGPoint(x: 0, y: -13),  control1: CGPoint(x: -12, y: -5),  control2: CGPoint(x: -5, y: -11))
        p.closeSubpath()
        return p
    }()

    private static let path2: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -15))
        p.addCurve(to: CGPoint(x: 14, y: 3),   control1: CGPoint(x: 4, y: -12),   control2: CGPoint(x: 11, y: -5))
        p.addCurve(to: CGPoint(x: 5, y: 23),   control1: CGPoint(x: 16, y: 11),   control2: CGPoint(x: 12, y: 20))
        p.addCurve(to: CGPoint(x: -7, y: 21),  control1: CGPoint(x: 1, y: 25),    control2: CGPoint(x: -3, y: 24))
        p.addCurve(to: CGPoint(x: -15, y: 1),  control1: CGPoint(x: -14, y: 17),  control2: CGPoint(x: -17, y: 8))
        p.addCurve(to: CGPoint(x: 0, y: -15),  control1: CGPoint(x: -12, y: -6),  control2: CGPoint(x: -4, y: -12))
        p.closeSubpath()
        return p
    }()
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
