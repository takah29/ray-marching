#include "utils.glsl"

float op_union(in float d1, in float d2) { return min(d1, d2); }
float op_intersection(in float d1, in float d2) { return max(d1, d2); }
float op_subtraction(in float d1, in float d2) { return max(-d1, d2); }

// smooth operation (0 < k <= 1.0)
float smooth_union(in float d1, in float d2, in float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}
float smooth_intersection(in float d1, in float d2, in float k) {
    float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) + k * h * (1.0 - h);
}
float smooth_subtraction(in float d1, in float d2, in float k) {
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return mix(d2, -d1, h) + k * h * (1.0 - h);
}

HitPoint smooth_union(in HitPoint hp1, in HitPoint hp2, in float k) {
    float h = clamp(0.5 + 0.5 * (hp2.d - hp1.d) / k, 0.0, 1.0);
    float d = mix(hp2.d, hp1.d, h) - k * h * (1.0 - h);
    vec4 mtl = blend_mtl(hp2.mtl, hp1.mtl, h);
    return HitPoint(d, mtl);
}
HitPoint smooth_intersection(in HitPoint hp1, in HitPoint hp2, in float k) {
    float h = clamp(0.5 - 0.5 * (hp2.d - hp1.d) / k, 0.0, 1.0);
    float d = mix(hp2.d, hp1.d, h) + k * h * (1.0 - h);
    vec4 mtl = blend_mtl(hp2.mtl, hp1.mtl, h);
    return HitPoint(d, mtl);
}
HitPoint smooth_subtraction(in HitPoint hp1, in HitPoint hp2, in float k) {
    float h = clamp(0.5 - 0.5 * (hp2.d + hp1.d) / k, 0.0, 1.0);
    float d = mix(hp2.d, -hp1.d, h) - k * h * (1.0 - h);
    vec4 mtl = blend_mtl(hp2.mtl, hp1.mtl, h);
    return HitPoint(d, mtl);
}
