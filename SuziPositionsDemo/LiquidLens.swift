// LiquidLens.swift
// SwiftUI bridge to the `suziLiquidLens` Metal shader (LiquidLens.metal) +
// the metric constants the tab bar borrows from the app's floating dock.

import SwiftUI

enum LensMetrics {
    // Tab icons — 28×28 per the Figma `Solid/*` glyph frame.
    static let tabIconSize: CGFloat = 28
    // Refraction tuning for the lens shader.
    static let lensRefractionAmount: CGFloat = 10
    static let lensRefractionDepth: CGFloat = 16
}

extension View {
    /// Applies the liquid-glass refraction lens as a `layerEffect`. Bends the
    /// content beneath a capsule centered at `centerX`. `amount == 0` is a
    /// no-op passthrough, so pass 0 at rest and a positive value while dragging.
    @ViewBuilder
    func suziLiquidLens(
        centerX: CGFloat,
        lensSize: CGSize,
        amount: CGFloat,
        depth: CGFloat
    ) -> some View {
        if #available(iOS 17.0, *), lensSize.width > 0, lensSize.height > 0 {
            let sampleOffset = max(amount, 0)
            layerEffect(
                ShaderLibrary.suziLiquidLens(
                    .float2(lensSize.width, lensSize.height),
                    .float(centerX - lensSize.width / 2),
                    .float(amount),
                    .float(depth)
                ),
                maxSampleOffset: CGSize(width: sampleOffset, height: sampleOffset)
            )
        } else {
            self
        }
    }
}
