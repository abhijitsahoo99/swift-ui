#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

#define PARTICLE_BASE_SIZE   1.9375   // 1.55 × 1.25 (+25% larger)
#define ORB_PUSH             1600.0
#define ORB_SWIRL            820.0
#define IDLE_JITTER          14.0
#define VELOCITY_DAMPING     0.94

struct Particle {
    float2 position;
    float2 velocity;
    float2 restPosition;
    float  age;
    float  lifespan;
    float  size;
    float  seed;
    float  kind;   // 0 = core (visible in idle), 1 = bloom (explosion-only)
};

// Mirror of ParticleRenderer.ParticleUniforms — stride 144 bytes.
// Each orb is a float4: xy = position, z = radiusScale, w = activation (0..1).
struct Uniforms {
    float  time;
    float  dt;
    float  progress;
    uint   mode;
    float2 screenSize;
    float2 restRectMin;
    float2 restRectMax;
    float2 cardRectMin;
    float2 cardRectMax;
    uint   orbCount;
    float  bandPersist;   // 0..1 over the 3 s petal window; see ParticleRenderer.
    float  bandPhase;     // pre-computed cubic ease-in for orb→band morph (linear-time domain).
    float  _pad0;
    float  _pad1;
    float  _pad2;
    float4 orbs[4];
};

static inline float2 hash22(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract(float2((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y));
}

static inline float hash21(float2 p) {
    p = fract(p * float2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

static inline float valueNoise(float2 p) {
    float2 ip = floor(p);
    float2 fp = fract(p);
    fp = fp * fp * (3.0 - 2.0 * fp);
    float a = hash21(ip);
    float b = hash21(ip + float2(1.0, 0.0));
    float c = hash21(ip + float2(0.0, 1.0));
    float d = hash21(ip + float2(1.0, 1.0));
    return mix(mix(a, b, fp.x), mix(c, d, fp.x), fp.y);
}

static inline float fbm2(float2 p) {
    float f = 0.0;
    f += 0.50 * valueNoise(p); p *= 2.03;
    f += 0.25 * valueNoise(p); p *= 2.07;
    f += 0.125 * valueNoise(p);
    return f;
}

kernel void update_particles(
    device Particle* particles [[ buffer(0) ]],
    constant Uniforms& u       [[ buffer(1) ]],
    uint id                    [[ thread_position_in_grid ]]
) {
    Particle p = particles[id];
    float dt = u.dt;
    float2 force = float2(0.0);

    if (u.mode == 1u) {
        float pr = u.progress;

        // Particles ignore the orb's push/swirl — the orb is purely a background
        // glow, so top and bottom of the explosion stay symmetric.

        // Radial push — particles move outward equally in every direction from
        // the card center, as if the emerging card is an expanding bubble that
        // pushes them aside. Left/right hit screen edges first (narrower axis)
        // and fade via edge-fade; top/bottom have more room and stay visible.
        //
        // 10% baseline at progress 0 so force is non-zero from the instant of
        // tap (no dead interval before motion starts), ramping smoothly to
        // full strength by progress ~0.50, then fading out at the end.
        float partingRamp = smoothstep(0.0, 0.50, pr);
        float parting = (0.10 + 0.90 * partingRamp) * (1.0 - smoothstep(0.92, 1.0, pr));
        float2 cardCntr = (u.cardRectMin + u.cardRectMax) * 0.5;
        float2 toP = p.position - cardCntr;
        float dR = max(length(toP), 8.0);
        float2 radialDir = toP / dR;
        // Force reduced 220 → 50: at the original 220, steady-state velocity
        // pushed particles past screen edges in ~50 ms, so they vanished via
        // edgeFade long before the unified time-fade could run. 50 keeps
        // particles drifting *on-screen* through the full reveal so they
        // dissolve together with the orbs at real 2.0–2.4 s.
        force += radialDir * 50.0 * parting;

    } else {
        // IDLE — gentle jitter with soft rect boundary.
        float2 j = hash22(float2(p.seed * 17.0, u.time * 1.6)) - 0.5;
        force += j * IDLE_JITTER * 3.0;
        force += (p.restPosition - p.position) * 2.4;

        float2 cntr = (u.restRectMin + u.restRectMax) * 0.5;
        float2 ext  = (u.restRectMax - u.restRectMin) * 0.5;
        float2 nd   = (p.position - cntr) / max(ext, float2(1.0));
        if (abs(nd.x) > 1.0) force.x -= sign(nd.x) * 60.0 * (abs(nd.x) - 1.0);
        if (abs(nd.y) > 1.0) force.y -= sign(nd.y) * 60.0 * (abs(nd.y) - 1.0);
    }

    p.velocity = (p.velocity + force * dt) * VELOCITY_DAMPING;
    p.position += p.velocity * dt * 60.0;
    p.age += dt;
    particles[id] = p;
}

// ===== Particle render =====

struct ParticleVertexOut {
    float4 clipPos  [[ position ]];
    float2 uv;
    float  alpha;
    float  intensity;
};

vertex ParticleVertexOut particle_vertex(
    uint vid                     [[ vertex_id ]],
    uint iid                     [[ instance_id ]],
    constant Particle* particles [[ buffer(0) ]],
    constant Uniforms& u         [[ buffer(1) ]]
) {
    float2 quad[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };

    Particle p = particles[iid];
    float2 corner = quad[vid];
    bool isBloom = (p.kind > 0.5);

    // Particle size: idle = 1×, explosion grows to 1.30× (+30%) by the end
    // of the reveal. Progress already carries the cubic-smoothstep spring
    // ease from the Swift side, so the growth feels spring-animated without
    // any extra curve math here.
    float sizeScale = (u.mode == 1u) ? (1.0 + 0.3 * u.progress) : 1.0;
    float sizePx = max(p.size * PARTICLE_BASE_SIZE * sizeScale, 0.5);
    // Bloom stays invisible (and collapsed) in idle.
    if (isBloom && u.mode == 0u) { sizePx = 0.0; }

    float2 worldPos = p.position + corner * sizePx;

    float2 ndc = (worldPos / u.screenSize) * 2.0 - 1.0;
    ndc.y = -ndc.y;

    ParticleVertexOut out;
    out.clipPos = float4(ndc, 0.0, 1.0);
    out.uv = corner;
    out.intensity = 0.60 + 0.40 * p.seed;

    if (u.mode == 1u) {
        float pr = u.progress;
        // Core particles are already visible from idle — keep alpha at 1 so the
        // tap → reveal transition has no blank gap. Bloom fades in gradually.
        float fadeIn = isBloom ? smoothstep(0.0, 0.30, pr) : 1.0;
        // Unified fade — same bp-driven window as every orb (see
        // ParticleRenderer.computeOrbs). All particles + orbs dissolve together
        // over real [2.00 s, 2.40 s].
        float fadeOut = 1.0 - smoothstep(0.30, 0.40, u.bandPersist);
        float alpha = fadeIn * fadeOut;

        // (cardMask + edgeFade both removed — they were the actual reasons
        // particles "faded early." cardMask killed in-card particles by
        // progress=0.78; edgeFade killed every particle that drifted past
        // the screen edge — and with the original 220 force, that was almost
        // all of them. The only fade-out factor now is `fadeOut`, which is
        // shared with the orbs.)

        out.alpha = alpha;
    } else {
        // Idle: bloom is invisible; core is fully visible.
        out.alpha = isBloom ? 0.0 : 1.0;
    }

    return out;
}

fragment half4 particle_fragment(ParticleVertexOut in [[stage_in]]) {
    float d = length(in.uv);
    if (d > 1.0) discard_fragment();
    float soft = pow(1.0 - d, 1.7);
    float a = soft * in.alpha * in.intensity;
    half3 color = half3(1.0h, 1.0h, 1.0h);
    return half4(color * half(a), half(a));
}

// ===== Orb render (fullscreen quad, additive) =====

struct OrbVertexOut {
    float4 clipPos [[ position ]];
    float2 ndc;
};

vertex OrbVertexOut orb_vertex(uint vid [[ vertex_id ]]) {
    float2 quad[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };
    float2 p = quad[vid];
    OrbVertexOut out;
    out.clipPos = float4(p, 0.0, 1.0);
    out.ndc = p;
    return out;
}

fragment half4 orb_fragment(
    OrbVertexOut in       [[ stage_in ]],
    constant Uniforms& u  [[ buffer(0) ]]
) {
    // Idle mode: no sparkle, no glow.
    if (u.mode == 0u) {
        return half4(0.0h, 0.0h, 0.0h, 1.0h);
    }

    // NDC (-1..1) → screen-space pixel coordinates (y flipped).
    float2 uv = in.ndc * 0.5 + 0.5;
    uv.y = 1.0 - uv.y;
    float2 pos = uv * u.screenSize;

    half3 accum = half3(0.0h);

    // orb-fit-001: blend every active orb toward a wide horizontal band shape
    // (screenSize.x * 0.55 wide, screenSize.y * 0.08 tall). bandPhase is a
    // cubic ease-in (bandT³) computed in ContentView from linear rawReveal
    // — keeps the morph accelerating right up to landing, no tail.
    //
    // u.bandPhase can exceed 1 (Swift side keeps it growing past the planned
    // landing for continuous motion), but the band *shape* mustn't grow past
    // its target — clamp here for the sigma morph only.
    float bandPhase = clamp(u.bandPhase, 0.0, 1.0);
    float bandSigmaX = u.screenSize.x * 0.55;
    float bandSigmaY = u.screenSize.y * 0.08;

    for (uint i = 0; i < u.orbCount; i++) {
        float4 orb = u.orbs[i];
        float w = orb.w;
        if (w <= 0.0) continue;
        float rScale = orb.z;
        float2 op = orb.xy;

        // Per-orb compact sigma — each orb is a blob, not a wide band.
        float baseSigma = 95.0 * rScale;
        float sigmaX = baseSigma;
        float sigmaY = baseSigma;
        // Orb 0 is the top plume — stretches vertically as it rises.
        if (i == 0u) {
            sigmaY *= (1.0 + smoothstep(0.15, 0.55, u.progress) * 1.8);
        }
        // Blend toward the wide horizontal band shape in the final phase.
        sigmaX = mix(sigmaX, bandSigmaX, bandPhase);
        sigmaY = mix(sigmaY, bandSigmaY, bandPhase);

        float2 d = pos - op;
        float dx = d.x / sigmaX;
        float dy = d.y / sigmaY;
        float body = exp(-(dx * dx + dy * dy) * 0.5);

        float rHalo = max(sigmaX, sigmaY) * 2.4;
        float dh = length(d) / rHalo;
        float halo = exp(-dh * dh * 0.5);

        // fBm modulation — breaks circular symmetry into organic cloud shapes.
        float2 np = d * 0.012 + float2(u.time * 0.25, u.time * -0.18 + float(i) * 3.7);
        float n = fbm2(np);
        float cloud = body * (0.50 + 1.10 * n);

        // Secondary noise-displaced lobe.
        float2 lobeOff = float2(
            (valueNoise(float2(u.time * 0.5, float(i) * 7.1)) - 0.5) * sigmaX * 0.6,
            (valueNoise(float2(u.time * 0.4 + 3.2, float(i) * 5.3)) - 0.5) * sigmaY * 0.6
        );
        float2 d2 = pos - (op + lobeOff);
        float lobe = exp(-(d2.x * d2.x / (sigmaX * sigmaX * 1.3) + d2.y * d2.y / (sigmaY * sigmaY * 1.3)) * 0.5);

        // Softer peak weights — tonemap below will still compress if orbs stack.
        float m = (cloud * 0.55 + lobe * 0.32 + halo * 0.48) * w;
        // Softer pink tint — channels can't clip toward pure white.
        accum += half3(0.82h, 0.50h, 0.72h) * half(m);
    }

    // Mask orb glow inside the card rect so the card reveals on clean black.
    {
        float2 cntr = (u.cardRectMin + u.cardRectMax) * 0.5;
        float2 ext  = (u.cardRectMax - u.cardRectMin) * 0.5;
        float2 nd   = abs(pos - cntr) / max(ext, float2(1.0));
        float inside = 1.0 - smoothstep(0.78, 1.12, max(nd.x, nd.y));
        float maskStrength = smoothstep(0.45, 0.75, u.progress);
        accum *= half(1.0 - inside * maskStrength * 0.95);
    }

    // Soft tonemap — prevents any channel from clipping to white when particles
    // blend on top. Keeps the center as lighter pink, not a bright blob.
    accum = accum / (half3(1.0h, 1.0h, 1.0h) + accum);

    // Premultiplied-alpha output — alpha tracks intensity so empty pixels stay
    // transparent and the card behind the MTKView shows through.
    half a = max(max(accum.r, accum.g), accum.b);
    return half4(accum, a);
}

// ===== Card overlay — SwiftUI stitchable color effect =====
// Applied via .colorEffect() on the PNL card image.
//  • During reveal (progress 0.30 → 0.90): diagonal shimmer band sweeps across.
//  • At rest (progress ≥ 1.0): soft holographic sheen + sparse twinkling sparkles.

[[stitchable]] half4 pnlCardEffect(
    float2 position,
    half4 color,
    float time,
    float progress,
    float2 cardSize,
    float tiltX,   // degrees, pitch (positive = top tilts back)
    float tiltY    // degrees, yaw   (positive = right side tilts back)
) {
    if (color.a <= 0.0h) return color;

    float2 uv = position / max(cardSize, float2(1.0));  // 0..1 within card

    // Parallax — simulate a glass plate hovering slightly above the card, so
    // the holographic foil / sparkles shift relative to the image underneath
    // as the card tilts. Offset is in pixels; clamped to a subtle range.
    float2 parallaxPx = float2(tiltY * 2.0, -tiltX * 2.0);
    float2 parallaxPos = position + parallaxPx;
    float2 parallaxUV = parallaxPos / max(cardSize, float2(1.0));

    half3 add = half3(0.0h, 0.0h, 0.0h);

    // --- Shimmer sweep (reveal phase) ---
    float sweepT = clamp((progress - 0.30) / 0.60, 0.0, 1.0);
    if (sweepT > 0.0 && sweepT < 1.0) {
        float axisPos  = parallaxUV.x + (1.0 - parallaxUV.y);
        float sweepPos = sweepT * 2.4 - 0.2;
        float dBand    = axisPos - sweepPos;
        float band     = exp(-dBand * dBand / (2.0 * 0.12 * 0.12));
        float envelope = smoothstep(0.02, 0.15, sweepT) * (1.0 - smoothstep(0.85, 1.0, sweepT));
        add += half3(0.95h, 0.82h, 0.92h) * half(band * envelope * 0.55);
    }

    // --- Resting holographic sheen + sparkles (after reveal) ---
    float restT = smoothstep(0.95, 1.10, progress);
    if (restT > 0.0) {
        // Hue shift driven by tilt + position + time. Tilt contribution is
        // strong so the iridescence visibly tracks the card's angle —
        // Apple Card-style titanium iridescence.
        float hueShift = parallaxUV.x * 0.80
                       + parallaxUV.y * 0.50
                       + time * 0.10
                       + tiltY * 0.065
                       + tiltX * 0.050;
        float h = fract(hueShift);
        half3 holo = half3(
            0.5h + 0.5h * half(sin(h * 6.2831)),
            0.5h + 0.5h * half(sin(h * 6.2831 + 2.094)),
            0.5h + 0.5h * half(sin(h * 6.2831 + 4.188))
        );
        float tiltMag = clamp((abs(tiltX) + abs(tiltY)) / 24.0, 0.0, 1.0);
        // Base amplitude bumped for always-visible iridescence; tilt adds more.
        float holoAmp = 0.20 + 0.25 * tiltMag;
        half3 holoTint = (holo - half3(0.5h, 0.5h, 0.5h)) * half(holoAmp);
        float pulse = 0.5 + 0.5 * sin(time * 1.3);
        add += holoTint * half(restT * (0.7 + 0.3 * pulse));

        // Grid-cell sparkles sampled from the parallax-shifted position so
        // twinkles appear to live on the glass plate, not glued to the image.
        float cellSize = 22.0;
        float2 cell     = floor(parallaxPos / cellSize);
        float2 cellFrac = fract(parallaxPos / cellSize);
        float2 r1       = fract(sin(cell * 12.9898 + float2(78.233, 37.719)) * 43758.5453);
        float bucket    = floor(time * 0.6 + r1.x * 17.0);
        float on        = fract(sin(bucket * 91.1 + r1.x * 3.7 + r1.y * 11.3) * 12345.6);
        if (on > 0.985) {
            float dSpark  = distance(cellFrac, r1);
            float twinkle = exp(-dSpark * dSpark / (2.0 * 0.08 * 0.08));
            float subT    = fract(time * 0.6 + r1.x * 17.0);
            float life    = sin(subT * 3.14159);
            add += half3(1.0h, 0.9h, 0.95h) * half(twinkle * life * restT * 0.7);
        }
    }

    half3 result = min(color.rgb + add, half3(1.0h, 1.0h, 1.0h));
    return half4(result, color.a);
}

