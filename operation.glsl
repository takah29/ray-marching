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
