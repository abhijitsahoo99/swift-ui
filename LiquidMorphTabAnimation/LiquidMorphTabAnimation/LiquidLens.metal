//
//  LiquidLens.metal
//  LiquidMorphTabAnimation
//
//  Ported from GSControl. Used as a `layerEffect` under the nav-bar
//  selection pill while scrubbing: it refracts (bends/magnifies) whatever sits inside a
//  capsule-shaped lens. GEOMETRY ONLY — it shifts sample positions, it never changes
//  colour or brightness, so the subtle pill never flares bright.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Signed distance to a capsule (rounded rect with corner `radius`).
float d2Capsule(float2 p, float2 halfSize, float radius) {
    float2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

[[stitchable]] half4 liquidLens(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float positionX,
    float refractionAmount,
    float refractionDepth
) {
    float2 pillCenter = size * 0.5 + float2(positionX, 0.0);
    float2 local = position - pillCenter;
    float2 halfSize = size * 0.5;
    float radius = size.y * 0.5;

    float dist = d2Capsule(local, halfSize, radius);

    // Outside the lens (or no bend): pass the pixel through untouched.
    if (dist > 0.0 || refractionAmount <= 0.0) {
        return layer.sample(position);
    }

    float2 outward = normalize(float2(
       d2Capsule(local + float2(1, 0), halfSize, radius) - d2Capsule(local - float2(1, 0), halfSize, radius),
       d2Capsule(local + float2(0, 1), halfSize, radius) - d2Capsule(local - float2(0, 1), halfSize, radius)
    ));

    float depthInside = -dist;
    float edge = 1.0 - smoothstep(0.0, refractionDepth, depthInside);

    float bend = edge * edge * refractionAmount;

    return layer.sample(position - outward * bend);
}
