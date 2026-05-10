//
//  MetalParticleView.swift
//  metalShader
//

import SwiftUI
import MetalKit

struct MetalParticleView: UIViewRepresentable {
    var mode: ParticleMode
    var progress: Double
    var bandPhase: Double = 0.0
    var bandPersist: Double = 0.0

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        // Transparent clear so the PNL card (rendered below this MTKView in
        // the ZStack) shows through in areas where no particle/orb is drawn.
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false

        if let device = view.device, let renderer = ParticleRenderer(device: device) {
            context.coordinator.renderer = renderer
            renderer.mode = mode
            renderer.progress = progress
            renderer.bandPhase = bandPhase
            renderer.bandPersist = bandPersist
            view.delegate = renderer
        }

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        guard let renderer = context.coordinator.renderer else { return }
        let previousMode = renderer.mode
        renderer.mode = mode
        renderer.progress = progress
        renderer.bandPhase = bandPhase
        renderer.bandPersist = bandPersist

        // Idle → explosion: keep positions, just zero velocities so idle jitter
        // bias can't contaminate the clean radial scatter.
        // Explosion → idle: full hard reset so particles snap straight back to
        // their rest positions (no bouncy spring overshoot) and are ready for
        // the next cycle.
        if previousMode == .idle && mode == .explosion {
            renderer.resetVelocities()
        } else if previousMode == .explosion && mode == .idle {
            renderer.resetForReplay(in: uiView.drawableSize)
        }
    }

    final class Coordinator {
        var renderer: ParticleRenderer?
    }
}
