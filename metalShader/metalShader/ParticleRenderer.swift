//
//  ParticleRenderer.swift
//  metalShader
//

import Foundation
import Metal
import MetalKit
import simd

enum ParticleMode: UInt32 {
    case idle = 0
    case explosion = 1
}

struct Particle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var restPosition: SIMD2<Float>
    var age: Float
    var lifespan: Float
    var size: Float
    var seed: Float
    var kind: Float  // 0 = core (visible in idle), 1 = bloom (explosion-only)
}

// Packed uniform layout — mirrored by Particles.metal. Total stride 144 bytes.
// Each orb is packed as float4 (xy=position, z=radiusScale, w=activation).
struct ParticleUniforms {
    var time: Float                 // 0
    var dt: Float                   // 4
    var progress: Float             // 8
    var mode: UInt32                // 12
    var screenSize: SIMD2<Float>    // 16
    var restRectMin: SIMD2<Float>   // 24 (cluster rect)
    var restRectMax: SIMD2<Float>   // 32
    var cardRectMin: SIMD2<Float>   // 40 (card reveal rect)
    var cardRectMax: SIMD2<Float>   // 48
    var orbCount: UInt32            // 56
    var bandPersist: Float          // 60 — 0..1 over the 3s post-main petal window
    var bandPhase: Float            // 64 — pre-computed cubic ease-in for orb→band morph (linear-time domain)
    var _pad0: Float                // 68
    var _pad1: Float                // 72
    var _pad2: Float                // 76
    // 80-byte boundary (float4 alignment).
    var orbs: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)
}

final class ParticleRenderer: NSObject, MTKViewDelegate {
    // MARK: - Tunables
    // 2400 core + 3000 bloom = total 5400 during animation (+50% more than
    // the previous 3600). Idle still shows just the 2400 core; bloom is
    // invisible until the reveal starts.
    static let coreParticleCount = 2400
    static let bloomParticleCount = 3000
    static let particleCount = coreParticleCount + bloomParticleCount
    static let orbCount: UInt32 = 4

    // Idle cluster — rectangular, matches reference frame 1 (tap-to-reveal state).
    static let clusterWidthFraction: CGFloat = 0.42
    static let clusterHeightFraction: CGFloat = 0.22

    // Card reveal rectangle — must match ExplosionRevealView's visible card size.
    // Card is full-width minus 24pt padding per side; height derived from image
    // aspect (1024×616 ≈ 1.66). Fractions below are tuned for iPhone portrait
    // (~393×852). Mild drift on other aspects is cosmetic (orb mask sits slightly off).
    static let cardWidthFraction: CGFloat = 0.878
    static let cardHeightFraction: CGFloat = 0.244

    // MARK: - Metal
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let computePipeline: MTLComputePipelineState
    let particleRenderPipeline: MTLRenderPipelineState
    let orbRenderPipeline: MTLRenderPipelineState

    var particleBuffer: MTLBuffer
    var uniformBuffer: MTLBuffer

    // MARK: - Animation state
    var mode: ParticleMode = .idle
    var progress: Double = 0.0
    /// Pre-computed cubic ease-in (`bandT³`) from ContentView, driven by linear
    /// rawReveal. Keeps orb→band morph accelerating right up to landing instead
    /// of inheriting the smoothstep-progress ease-out tail.
    var bandPhase: Double = 0.0
    /// 0..1 animated over the 3 s petal window (starts at petal launch).
    /// Extends orb 2/3 activation and drifts their Y position downward so the
    /// pink bottom band persists while petals are visible, then fades at the end.
    var bandPersist: Double = 0.0

    private var viewSize: CGSize = .zero
    private var lastFrameTime: CFTimeInterval = CACurrentMediaTime()
    private var startTime: CFTimeInterval = CACurrentMediaTime()
    private var particlesSeededForSize: CGSize = .zero

    // MARK: - Init
    init?(device: MTLDevice) {
        self.device = device
        guard let queue = device.makeCommandQueue() else { return nil }
        self.commandQueue = queue

        guard let library = device.makeDefaultLibrary(),
              let updateFunc = library.makeFunction(name: "update_particles"),
              let pVertex = library.makeFunction(name: "particle_vertex"),
              let pFragment = library.makeFunction(name: "particle_fragment"),
              let oVertex = library.makeFunction(name: "orb_vertex"),
              let oFragment = library.makeFunction(name: "orb_fragment")
        else {
            print("ParticleRenderer: failed to load shader functions")
            return nil
        }

        do {
            self.computePipeline = try device.makeComputePipelineState(function: updateFunc)
        } catch {
            print("ParticleRenderer: compute pipeline error \(error)")
            return nil
        }

        // Particles use premultiplied source-over (alpha-over) so they
        // literally render *on top of* the orbs — drawn after the orb pass,
        // they cover orb pixels in proportion to particle alpha. (Orbs
        // remain additive against the transparent black framebuffer below.)
        let particleDesc = MTLRenderPipelineDescriptor()
        particleDesc.vertexFunction = pVertex
        particleDesc.fragmentFunction = pFragment
        particleDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        particleDesc.colorAttachments[0].isBlendingEnabled = true
        particleDesc.colorAttachments[0].rgbBlendOperation = .add
        particleDesc.colorAttachments[0].alphaBlendOperation = .add
        particleDesc.colorAttachments[0].sourceRGBBlendFactor = .one
        particleDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        particleDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        particleDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        let orbDesc = MTLRenderPipelineDescriptor()
        orbDesc.vertexFunction = oVertex
        orbDesc.fragmentFunction = oFragment
        orbDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        orbDesc.colorAttachments[0].isBlendingEnabled = true
        orbDesc.colorAttachments[0].rgbBlendOperation = .add
        orbDesc.colorAttachments[0].alphaBlendOperation = .add
        orbDesc.colorAttachments[0].sourceRGBBlendFactor = .one
        orbDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        orbDesc.colorAttachments[0].destinationRGBBlendFactor = .one
        orbDesc.colorAttachments[0].destinationAlphaBlendFactor = .one

        do {
            self.particleRenderPipeline = try device.makeRenderPipelineState(descriptor: particleDesc)
            self.orbRenderPipeline = try device.makeRenderPipelineState(descriptor: orbDesc)
        } catch {
            print("ParticleRenderer: render pipeline error \(error)")
            return nil
        }

        let bufLen = MemoryLayout<Particle>.stride * Self.particleCount
        guard let pBuf = device.makeBuffer(length: bufLen, options: [.storageModeShared]) else {
            return nil
        }
        self.particleBuffer = pBuf

        guard let uBuf = device.makeBuffer(length: MemoryLayout<ParticleUniforms>.stride, options: [.storageModeShared]) else {
            return nil
        }
        self.uniformBuffer = uBuf

        super.init()
    }

    // MARK: - Seeding
    // Rectangular cluster with triangular (center-biased) distribution.
    private func seedParticles(in size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        let cx = Float(size.width) * 0.5
        let cy = Float(size.height) * 0.5
        let halfW = Float(size.width * Self.clusterWidthFraction * 0.5)
        let halfH = Float(size.height * Self.clusterHeightFraction * 0.5)

        let ptr = particleBuffer.contents().bindMemory(to: Particle.self, capacity: Self.particleCount)
        for i in 0..<Self.particleCount {
            let isBloom = i >= Self.coreParticleCount
            let ux = (Float.random(in: -1...1) + Float.random(in: -1...1)) * 0.5
            let uy = (Float.random(in: -1...1) + Float.random(in: -1...1)) * 0.5
            let px = cx + ux * halfW * 1.15
            let py = cy + uy * halfH * 1.15
            let rest = SIMD2<Float>(px, py)
            // Bloom particles are slightly finer so the extra density reads as filling-in dust.
            let sz: Float = isBloom ? Float.random(in: 0.35...1.2) : Float.random(in: 0.45...1.5)
            ptr[i] = Particle(
                position: rest,
                velocity: .zero,
                restPosition: rest,
                age: 0,
                lifespan: 1.0,
                size: sz,
                seed: Float.random(in: 0...1),
                kind: isBloom ? 1.0 : 0.0
            )
        }
        particlesSeededForSize = size
    }

    func resetForReplay(in size: CGSize) {
        seedParticles(in: size)
        startTime = CACurrentMediaTime()
        lastFrameTime = startTime
    }

    /// Zero every particle's velocity but leave positions intact. Used on
    /// idle → explosion so the cluster doesn't snap back to rest, and so the
    /// idle jitter velocity bias doesn't contaminate the radial scatter.
    func resetVelocities() {
        let ptr = particleBuffer.contents().bindMemory(to: Particle.self, capacity: Self.particleCount)
        for i in 0..<Self.particleCount {
            ptr[i].velocity = .zero
        }
    }

    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewSize = size
        if particlesSeededForSize != size {
            seedParticles(in: size)
        }
    }

    func draw(in view: MTKView) {
        guard viewSize.width > 1, viewSize.height > 1 else { return }
        if particlesSeededForSize != viewSize {
            seedParticles(in: viewSize)
        }

        let now = CACurrentMediaTime()
        let dt = max(Float(min(now - lastFrameTime, 1.0 / 30.0)), 0.001)
        lastFrameTime = now
        let elapsed = Float(now - startTime)

        let t = Float(progress)
        let bp = Float(bandPersist)
        let bphase = Float(bandPhase)
        let orbPacked = computeOrbs(progress: t, time: elapsed, size: viewSize, bandPersist: bp, bandPhase: bphase)

        let cx = Float(viewSize.width) * 0.5
        let cy = Float(viewSize.height) * 0.5
        let halfClusterW = Float(viewSize.width * Self.clusterWidthFraction * 0.5)
        let halfClusterH = Float(viewSize.height * Self.clusterHeightFraction * 0.5)
        let halfCardW = Float(viewSize.width * Self.cardWidthFraction * 0.5)
        let halfCardH = Float(viewSize.height * Self.cardHeightFraction * 0.5)

        var u = ParticleUniforms(
            time: elapsed,
            dt: dt,
            progress: t,
            mode: mode.rawValue,
            screenSize: SIMD2<Float>(Float(viewSize.width), Float(viewSize.height)),
            restRectMin: SIMD2<Float>(cx - halfClusterW, cy - halfClusterH),
            restRectMax: SIMD2<Float>(cx + halfClusterW, cy + halfClusterH),
            cardRectMin: SIMD2<Float>(cx - halfCardW, cy - halfCardH),
            cardRectMax: SIMD2<Float>(cx + halfCardW, cy + halfCardH),
            orbCount: Self.orbCount,
            bandPersist: bp,
            bandPhase: bphase,
            _pad0: 0,
            _pad1: 0,
            _pad2: 0,
            orbs: orbPacked
        )
        memcpy(uniformBuffer.contents(), &u, MemoryLayout<ParticleUniforms>.stride)

        guard let cmdBuf = commandQueue.makeCommandBuffer() else { return }

        if let compute = cmdBuf.makeComputeCommandEncoder() {
            compute.setComputePipelineState(computePipeline)
            compute.setBuffer(particleBuffer, offset: 0, index: 0)
            compute.setBuffer(uniformBuffer, offset: 0, index: 1)
            let w = computePipeline.threadExecutionWidth
            let tg = MTLSize(width: w, height: 1, depth: 1)
            let grid = MTLSize(width: Self.particleCount, height: 1, depth: 1)
            compute.dispatchThreads(grid, threadsPerThreadgroup: tg)
            compute.endEncoding()
        }

        guard let rpd = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let renderEncoder = cmdBuf.makeRenderCommandEncoder(descriptor: rpd)
        else {
            cmdBuf.commit()
            return
        }

        renderEncoder.setRenderPipelineState(orbRenderPipeline)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

        renderEncoder.setRenderPipelineState(particleRenderPipeline)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: Self.particleCount)

        renderEncoder.endEncoding()
        cmdBuf.present(drawable)
        cmdBuf.commit()
    }

    // MARK: - Orb choreography  (orb-fit-001)
    // Coordinates in pixel space — origin top-left, y-down.
    // Each orb packed as float4(x, y, radiusScale, activation).
    //
    // Three-stage story (matches reference frames):
    //   A (0.00 → 0.18): only orb 0 is active, at screen center — single
    //       compact pink orb the particle cluster is swirling around.
    //   B (0.18 → 0.70): orb 0 drifts up to the top plume position, and
    //       orbs 1/2/3 fade in at their quadrant positions — the classic
    //       4-orb bloom.
    //   C (0.70 → 1.00): orbs 0 and 1 fade. Orbs 2 and 3 migrate down to
    //       the bottom edge; the orb shader stretches their shape into a
    //       wide horizontal band (see orb_fragment → bandPhase).
    private func computeOrbs(progress t: Float, time: Float, size: CGSize, bandPersist bp: Float, bandPhase: Float) -> (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) {
        let w = Float(size.width)
        let h = Float(size.height)
        let cx = w * 0.5
        let cy = h * 0.5

        // Post-reveal downward drift: kicks in only after the reveal ends
        // (bp ≈ 0.30 = real ~2.0 s). Coefficient is tuned so the position
        // velocity through `mix(four, band+yDrift, bandPhase≈1.125)` matches
        // (slightly exceeds) the linear migration velocity at landing — no
        // deceleration gap, slight forward push so motion never reads as
        // slowing. Orbs keep falling off-screen smoothly while fading.
        let yDrift: Float = max(0, bp - 0.30) * h * 0.7
        // Unified fade across all orbs *and* the particles (in shader). Window
        // is bp [0.30, 0.40] = real [2.00 s, 2.40 s] = 400 ms. bp keeps ticking
        // past reveal end, which lets orbs 2/3 land at full alpha (real 1.90 s)
        // before fade starts. All four orbs and the dust dissolve together.
        let unifiedFade: Float = 1.0 - smoothstep(0.30, 0.40, bp)

        // ---- Orb 0: starts at screen center, drifts up to top plume. ----
        // Position eases from center (stage A) to top plume (stage B).
        let riseT  = smoothstep(0.05, 0.55, t)
        let o0x = mix(cx, cx + w * 0.04, riseT) + sin(time * 2.1) * 5.0
        let o0y = mix(cy, cy - h * 0.38, riseT) + cos(time * 1.8) * 4.0
        // Size grows as it rises (matches "elongate" in reference frames 1→3).
        let r0: Float = 0.75 + smoothstep(0.05, 0.55, t) * 1.15
        // Fades in normally; fade-out is the unified bp-driven curve.
        let a0 = smoothstep(0.02, 0.12, t) * unifiedFade
        let orb0 = SIMD4<Float>(o0x, o0y, r0, a0)

        // ---- Orb 1: left-middle helper — 4-orb phase only. ----
        let p1 = smoothstep(0.22, 0.55, t)
        let o1x = cx - w * 0.22 - p1 * w * 0.04 + sin(time * 1.5) * 9.0
        let o1y = cy - h * 0.02 - p1 * h * 0.05 + cos(time * 1.9) * 7.0
        let r1: Float = 0.65 + smoothstep(0.25, 0.50, t) * 0.35
        let a1 = smoothstep(0.20, 0.35, t) * unifiedFade
        let orb1 = SIMD4<Float>(o1x, o1y, r1, a1)

        // ---- Orb 2: lower-left, migrates to bottom-band (left half). ----
        let p2 = smoothstep(0.30, 0.65, t)
        let four2X = cx - w * 0.16 - p2 * w * 0.04 + sin(time * 1.3) * 4.0
        let four2Y = cy + h * 0.08 + p2 * h * 0.20
        // Subtle jitter on the band targets so the orbs feel alive at the
        // moment they "land" rather than visually pinned (orb 0 has the same
        // sin/cos floating offset at the top of its arc).
        let band2X = cx - w * 0.22 + sin(time * 1.3) * 3.0
        let band2Y = cy + h * 0.42 + yDrift + cos(time * 1.7) * 4.0
        let o2x = mix(four2X, band2X, bandPhase)
        let o2y = mix(four2Y, band2Y, bandPhase)
        let r2: Float = 1.0 + smoothstep(0.55, 0.90, t) * 1.6
        let a2 = smoothstep(0.28, 0.45, t) * unifiedFade
        let orb2 = SIMD4<Float>(o2x, o2y, r2, a2)

        // ---- Orb 3: lower-right, migrates to bottom-band (right half). ----
        let p3 = smoothstep(0.32, 0.65, t)
        let four3X = cx + w * 0.16 - p3 * w * 0.04 + sin(time * 1.6 + 1.2) * 5.0
        let four3Y = cy + h * 0.05 + p3 * h * 0.22
        let band3X = cx + w * 0.22 + sin(time * 1.6 + 1.2) * 3.0
        let band3Y = cy + h * 0.42 + yDrift + cos(time * 1.9 + 0.7) * 4.0
        let o3x = mix(four3X, band3X, bandPhase)
        let o3y = mix(four3Y, band3Y, bandPhase)
        let r3: Float = 1.15 + smoothstep(0.55, 0.90, t) * 1.9
        let a3 = smoothstep(0.30, 0.45, t) * unifiedFade
        let orb3 = SIMD4<Float>(o3x, o3y, r3, a3)

        return (orb0, orb1, orb2, orb3)
    }
}

private func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
    let t = max(0, min(1, (x - edge0) / max(edge1 - edge0, 1e-6)))
    return t * t * (3 - 2 * t)
}

private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
    return a + (b - a) * t
}
