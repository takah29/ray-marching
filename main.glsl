#iUniform float u = 1.0 in{0.0, 10.0 }

precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#include "object.glsl"
#include "operation.glsl"
#include "transform.glsl"

const float PI = 3.14159265;
const float angle = 60.0;
const float fov = angle * 0.5 * PI / 180.0;

const vec3 light = vec3(0.577, 0.477, 0.177);

// オブジェクト
Sphere sphere = Sphere(vec3(0.0, 0.0, 0.0), 3.0);
Box box = Box(vec3(0.0, 0.0, 0.0), vec3(0.06, 0.06, 0.06), 0.06);
Torus torus = Torus(vec3(0.0, 0.0, 0.0), 2.0, 1.0);
Plane plane = Plane(vec3(0.0, -2.0, 0.0), vec3(0.0, 1.0, 0.0));

HitPoint distance_scene(in vec3 p) {
    vec3 q = rotate_z(rotate_x(rotate_y(p, time * 0.5), time * 0.2), 0.1);
    float d1 = distance_func(box, repetition(q, vec3(0.0), vec3(0.4)));
    torus.radius_a = u;
    float d2 = distance_func(torus, q);

    float d3 = distance_func(plane, p);

    float d = mix(d2, d1, pow(sin(time * 1.0) * 0.99, 2.0));
    return smooth_union(HitPoint(d, vec4(BLUE, 1.0)), HitPoint(d3, vec4(GREEN, 0.0)), 0.5);
}

// シーンの法線ベクトルの計算
vec3 get_normal(in vec3 p) {
    float d = 0.0001;
    return normalize(vec3(distance_scene(p + vec3(d, 0.0, 0.0)).d - distance_scene(p + vec3(-d, 0.0, 0.0)).d,
                          distance_scene(p + vec3(0.0, d, 0.0)).d - distance_scene(p + vec3(0.0, -d, 0.0)).d,
                          distance_scene(p + vec3(0.0, 0.0, d)).d - distance_scene(p + vec3(0.0, 0.0, -d)).d));
}

float gen_shadow(vec3 ro, vec3 rd) {
    float h = 0.0;
    float c = 0.001;
    float r = 1.0;
    float shadow_coef = 0.5;
    for (int i = 0; i < 64; i++) {
        h = distance_scene(ro + rd * c).d;
        if (abs(h) < 0.001) {
            return shadow_coef;
        }
        r = min(r, h * 32.0 / c);
        c += h;
    }
    return 1.0 - shadow_coef + r * shadow_coef;
}

vec3 ray_march(vec3 p, in vec3 ray) {
    float distance = 0.0;
    float len = 0.0;
    vec3 pos = p;  // レイの先端位置
    vec3 color = vec3(0.0);

    // marching loop
    float shadow = 1.0;
    HitPoint hp;
    for (int i = 0; i < 256; i++) {
        hp = distance_scene(pos);
        len += hp.d;
        pos = p + ray * len;

        // hit check
        if (abs(hp.d) < 0.001) {
            vec3 normal = get_normal(pos);

            // light
            vec3 halfLE = normalize(light - ray);
            vec3 diff = clamp(dot(light, normal), 0.1, 1.0) * hp.mtl.xyz;
            float spec = pow(clamp(dot(halfLE, normal), 0.0, 1.0), 50.0) * hp.mtl.w;

            // shadow
            shadow = gen_shadow(pos + normal * 0.001, light);

            color = vec3(diff) + vec3(spec);
            break;
        }
    }

    return color * max(0.5, shadow);
}

void main(void) {
    // fragment position
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    // camera
    vec3 c_pos = vec3(0.0, 0.0, 8.0);

    // ray
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));

    vec3 color = ray_march(c_pos, ray);
    gl_FragColor = vec4(color, 1.0);
}
