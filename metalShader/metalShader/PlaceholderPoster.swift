//
//  PlaceholderPoster.swift
//  metalShader
//
//  Hosts PnlCardView — the real PNL card image (extracted from PnlCardLive.jsx)
//  with a SwiftUI stitchable Metal overlay: shimmer sweep during reveal +
//  holographic sheen + sparkles at rest.
//

import SwiftUI

struct PnlCardView: View {
    /// Overall animation progress (0..1+). Drives the shader phase.
    var progress: Double
    /// Tilt angles in degrees (X = pitch, Y = yaw). Fed into the shader so the
    /// holographic foil and sparkle parallax react to the card's orientation.
    var tiltX: Double = 0
    var tiltY: Double = 0

    // Image aspect — 1024 × 616 (from the PnLCard.png asset).
    static let imageAspect: CGFloat = 1024.0 / 616.0

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = Float(timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 1000.0))

            GeometryReader { geo in
                Image("PnlCard")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .colorEffect(ShaderLibrary.pnlCardEffect(
                        .float(time),
                        .float(Float(progress)),
                        .float2(Float(geo.size.width), Float(geo.size.height)),
                        .float(Float(tiltX)),
                        .float(Float(tiltY))
                    ))
            }
        }
    }
}

#Preview {
    PnlCardView(progress: 1.0)
        .frame(width: 280, height: 168)
        .padding()
        .background(Color.black)
}
