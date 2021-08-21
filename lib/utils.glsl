vec3 RED = vec3(1.0, 0.0, 0.0);
vec3 GREEN = vec3(0.0, 1.0, 0.0);
vec3 BLUE = vec3(0.0, 0.0, 1.0);
vec3 CYAN = vec3(0.0, 1.0, 1.0);
vec3 MAGENTA = vec3(1.0, 0.0, 1.0);
vec3 YELLOW = vec3(1.0, 1.0, 0.0);
vec3 WHITE = vec3(1.0, 1.0, 1.0);
vec3 GRAY = vec3(0.5, 0.5, 0.5);
vec3 BLACK = vec3(0.0, 0.0, 0.0);

struct HitPoint {
    float d;   // distance
    vec4 mtl;  // RGB, Speculer
};

vec4 blend_mtl(in vec4 mtl1, in vec4 mtl2, in float t) { return (1.0 - t) * mtl1 + t * mtl2; }
