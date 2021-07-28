precision highp float;

struct Sphere {
    vec3 center;
    float radius;
};

float distance_func(in Sphere sphere, in vec3 p) { return length(p - sphere.center) - sphere.radius; }

vec3 get_normal(in Sphere sphere, in vec3 p) {
    float d = 0.0001;
    return normalize(
        vec3(distance_func(sphere, p + vec3(d, 0.0, 0.0)) - distance_func(sphere, p + vec3(-d, 0.0, 0.0)),
             distance_func(sphere, p + vec3(0.0, d, 0.0)) - distance_func(sphere, p + vec3(0.0, -d, 0.0)),
             distance_func(sphere, p + vec3(0.0, 0.0, d)) - distance_func(sphere, p + vec3(0.0, 0.0, -d))));
}
