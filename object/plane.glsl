precision highp float;

struct Plane {
    vec3 center;
    vec3 normal;
};

float distance_func(in Plane plane, in vec3 p) { return dot(p - plane.center, plane.normal); }

vec3 get_normal(in Plane plane, in vec3 p) {
    float d = 0.0001;
    return normalize(vec3(distance_func(plane, p + vec3(d, 0.0, 0.0)) - distance_func(plane, p + vec3(-d, 0.0, 0.0)),
                          distance_func(plane, p + vec3(0.0, d, 0.0)) - distance_func(plane, p + vec3(0.0, -d, 0.0)),
                          distance_func(plane, p + vec3(0.0, 0.0, d)) - distance_func(plane, p + vec3(0.0, 0.0, -d))));
}
