// GlassSurface.swift
// Capsule glass background used by the tab bar and pills.
// Native `glassEffect` on iOS 26+, `ultraThinMaterial`-style fallback below.

import SwiftUI

enum GlassSurface {
    static var navStroke: Color { Color.navStroke }
    static var navOverlayColor: Color { Color.black.opacity(0.2) }

    struct CapsuleGlass: View {
        var body: some View {
            if #available(iOS 26.0, *) {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular, in: .capsule)
                    .overlay { Capsule().fill(GlassSurface.navOverlayColor).blendMode(.screen) }
                    .overlay { Capsule().stroke(GlassSurface.navStroke, lineWidth: 1.5) }
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay { Capsule().fill(GlassSurface.navOverlayColor).blendMode(.screen) }
                    .overlay { Capsule().stroke(GlassSurface.navStroke, lineWidth: 1.5) }
            }
        }
    }

    struct CircleGlass: View {
        var body: some View {
            if #available(iOS 26.0, *) {
                Circle()
                    .fill(.clear)
                    .glassEffect(.regular, in: .circle)
                    .overlay { Circle().fill(GlassSurface.navOverlayColor).blendMode(.screen) }
                    .overlay { Circle().stroke(GlassSurface.navStroke, lineWidth: 1.5) }
            } else {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay { Circle().fill(GlassSurface.navOverlayColor).blendMode(.screen) }
                    .overlay { Circle().stroke(GlassSurface.navStroke, lineWidth: 1.5) }
            }
        }
    }
}
