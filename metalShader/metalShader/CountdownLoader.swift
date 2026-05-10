//
//  CountdownLoader.swift
//  metalShader
//
//  Replaces the old "Tap to reveal" label. A circular arc that fills 0 → 360°
//  over 4 seconds, then signals the reveal to auto-start. 4pt stroke, rounded
//  caps, soft white.
//

import SwiftUI

struct CountdownLoader: View {
    /// 0..1 fill progress.
    var progress: Double
    var size: CGFloat = 36
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            // Dim track.
            Circle()
                .stroke(Color.white.opacity(0.16), lineWidth: lineWidth)
            // Progress arc.
            Circle()
                .trim(from: 0, to: max(0.001, progress))   // avoid zero-length cap artifact
                .stroke(
                    Color.white.opacity(0.88),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))             // start at 12 o'clock
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 24) {
        CountdownLoader(progress: 0.0)
        CountdownLoader(progress: 0.35)
        CountdownLoader(progress: 0.80)
        CountdownLoader(progress: 1.0)
    }
    .padding(40)
    .background(Color.black)
}
