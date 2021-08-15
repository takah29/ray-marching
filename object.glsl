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
