#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

float suziCapsuleDistance(float2 point, float2 halfSize, float radius) {
    float2 delta = abs(point) - halfSize + radius;
    return length(max(delta, 0.0)) + min(max(delta.x, delta.y), 0.0) - radius;
}

// Liquid-glass refraction lens: bends the layer's samples outward inside a
// capsule centered at `positionX`, faking the light-bending of a glass pill
// riding over the tab content. Drives the tab-switcher indicator on drag.
[[stitchable]] half4 suziLiquidLens(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float positionX,
    float refractionAmount,
    float refractionDepth
) {
    float2 pillCenter = size * 0.5 + float2(positionX, 0.0);
    float2 localPosition = position - pillCenter;
    float2 halfSize = size * 0.5;
    float radius = size.y * 0.5;

    float distance = suziCapsuleDistance(localPosition, halfSize, radius);

    if (distance > 0.0 || refractionAmount <= 0.0) {
        return layer.sample(position);
    }

    float depthInside = -distance;
    float edge = 1.0 - smoothstep(0.0, refractionDepth, depthInside);
    float bend = edge * edge * refractionAmount;

    if (bend <= 0.0001) {
        return layer.sample(position);
    }

    float2 gradient = float2(
        suziCapsuleDistance(localPosition + float2(1.0, 0.0), halfSize, radius) - suziCapsuleDistance(localPosition - float2(1.0, 0.0), halfSize, radius),
        suziCapsuleDistance(localPosition + float2(0.0, 1.0), halfSize, radius) - suziCapsuleDistance(localPosition - float2(0.0, 1.0), halfSize, radius)
    );
    float gradientLengthSquared = dot(gradient, gradient);

    if (gradientLengthSquared <= 0.0001) {
        return layer.sample(position);
    }

    float2 outward = gradient * rsqrt(gradientLengthSquared);

    return layer.sample(position - outward * bend);
}
