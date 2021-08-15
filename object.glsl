// Sphere
struct Sphere {
    vec3 center;
    float radius;
};
float distance_func(in Sphere sphere, in vec3 p) { return length(p - sphere.center) - sphere.radius; }

// Box
struct Box {
    vec3 center;
    vec3 size;
    float expansion;
};
float distance_func(in Box box, in vec3 p) {
    vec3 q = abs(p - box.center);
    return length(max(q - box.size, 0.0)) - box.expansion;
}

// Plane
struct Plane {
    vec3 center;
    vec3 normal;
};
float distance_func(in Plane plane, in vec3 p) { return dot(p - plane.center, plane.normal); }

// Torus
struct Torus {
    vec3 center;
    float radius_a;
    float radius_b;
};
float distance_func(in Torus torus, in vec3 p) {
    vec2 q = vec2(length(p.xz - torus.center.xz) - torus.radius_a, p.y - torus.center.y);
    return length(q) - torus.radius_b;
}

// Capsule
struct Capsule {
    vec3 a;
    vec3 b;
    float radius;
};
float distance_func(in Capsule capsule, in vec3 p) {
    vec3 pa = p - capsule.a, ba = capsule.b - capsule.a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - capsule.radius;
}

// RecursiveTetrahedron
struct RecursiveTetrahedron {
    vec3 offset;
    float scale;
    int iterations;
};
float distance_func(in RecursiveTetrahedron rt, in vec3 p) {
    vec4 z = vec4(p, 1.0);
    for (int i = 0; i < rt.iterations; i++) {
        if (z.x + z.y < 0.0) z.xy = -z.yx;
        if (z.x + z.z < 0.0) z.xz = -z.zx;
        if (z.y + z.z < 0.0) z.zy = -z.yz;
        z *= rt.scale;
        z.xyz -= rt.offset * (rt.scale - 1.0);
    }
    return (length(z.xyz) - 1.5) / z.w;
}

// MengerSponge
struct MengerSponge {
    vec3 offset;
    float scale;
    int iterations;
};
float distance_func(in MengerSponge ms, in vec3 p) {
    vec4 z = vec4(p, 1.0);
    for (int i = 0; i < ms.iterations; i++) {
        z = abs(z);
        if (z.x < z.z) z.xz = z.zx;
        if (z.y < z.z) z.yz = z.zy;
        z *= ms.scale;
        z.xyz -= ms.offset * (ms.scale - 1.0);
        if (z.z < -0.5 * ms.offset.z * (ms.scale - 1.0)) {
            z.z += ms.offset.z * (ms.scale - 1.0);
        }
    }
    return (length(max(abs(z.xyz) - vec3(1.0, 1.0, 1.0), 0.0))) / z.w;
}

// HexTiling
struct HexTiling{
    float y_pos;
    float radius;
    float scale;
};
float distance_func(in HexTiling ht, in vec3 p) {
    vec2 rep = vec2(2.0 * sqrt(3.0), 2.0) * ht.radius;
    vec2 p1 = mod(p.zx, rep) - rep * 0.5;
    vec2 p2 = mod(p.zx + 0.5 * rep, rep) - rep * 0.5;

    float h = ht.scale * ht.radius;

    vec3 k = vec3(-0.8660254, 0.57735, 0.5);
    p1 = abs(p1);
    p1 -= 2.0 * min(dot(k.xz, p1), 0.0) * k.xz;
    float d1 = length(p1 - vec2(clamp(p1.x, -k.y * h, k.y * h), h)) * sign(p1.y - h);

    p2 = abs(p2);
    p2 -= 2.0 * min(dot(k.xz, p2), 0.0) * k.xz;
    float d2 = length(p2 - vec2(clamp(p2.x, -k.y * h, k.y * h), h)) * sign(p2.y - h);

    return max(min(d1, d2), p.y - ht.y_pos);
}
