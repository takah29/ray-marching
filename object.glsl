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
