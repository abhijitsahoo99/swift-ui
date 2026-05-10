//
//  IdleClusterView.swift
//  metalShader
//

import SwiftUI

struct IdleClusterView: View {
    let onTapReveal: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                MetalParticleView(mode: .idle, progress: 0.0)
                    .ignoresSafeArea()

                // "Tap to reveal" overlays centered on the particle cluster.
                Text("Tap to reveal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .shadow(color: .black.opacity(0.95), radius: 6)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTapReveal() }
    }
}

#Preview {
    IdleClusterView(onTapReveal: {})
        .background(Color.black)
}
