const float PI = 3.14159265;

const vec3 RED = vec3(1.0, 0.0, 0.0);
const vec3 GREEN = vec3(0.0, 1.0, 0.0);
const vec3 BLUE = vec3(0.0, 0.0, 1.0);
const vec3 CYAN = vec3(0.0, 1.0, 1.0);
const vec3 MAGENTA = vec3(1.0, 0.0, 1.0);
const vec3 YELLOW = vec3(1.0, 1.0, 0.0);
const vec3 WHITE = vec3(1.0, 1.0, 1.0);
const vec3 GRAY = vec3(0.5, 0.5, 0.5);
const vec3 BLACK = vec3(0.0, 0.0, 0.0);

struct Camera {
    vec3 pos;
    vec3 dir;
    vec3 right;
    vec3 top;
    float angle;
};

struct HitPoint {
    float d;   // distance
    vec4 mtl;  // RGB, Speculer
};

vec4 blend_mtl(in vec4 mtl1, in vec4 mtl2, in float t) { return (1.0 - t) * mtl1 + t * mtl2; }

vec3 get_ray(in Camera camera, in vec2 coord) {
    float fov = camera.angle * 0.5 * PI / 180.0;
    float sin_fov = sin(fov);
    return normalize(camera.dir * cos(fov) + camera.right * coord.x * sin_fov + camera.top * coord.y * sin_fov);
}

void look_at_origin(inout Camera camera, in vec3 pos) {
    camera.pos = pos;
    camera.dir = -normalize(camera.pos);
    vec3 up = vec3(0.0, 1.0, 0.0);
    camera.right = normalize(cross(camera.dir, up));
    camera.top = normalize(cross(camera.right, camera.dir));
}

vec3 spherical_to_orthogonal(in vec3 s) {
    return vec3(s.r * sin(s.t) * sin(s.p), s.r * cos(s.t), s.r * sin(s.t) * cos(s.p));
}

vec3 mouse_coord_to_hemisphere(in vec2 mouse_coord, in float r) {
    float c = 1.9; // フロアに接触しない値を設定する
    return vec3(r, (1.001 + mouse_coord.y) / 2.0 * (PI / c), -1.5 * mouse_coord.x * PI);
}
