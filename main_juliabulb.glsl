#iUniform float angle = 60.0 in{30.0, 90.0 }
#iUniform float speed = 0.1 in{0.0, 4.0 }
#iUniform float power = 8.0 in{1.0, 20.0 }

precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#include "object.glsl"
#include "operation.glsl"
#include "transform.glsl"

const float PI = 3.14159265;
const vec3 light = vec3(0.6, 0.6, 0.6);

const int ITER = 256;

Mandelbulb mb = Mandelbulb(8.0, 4);
Plane plane = Plane(vec3(0.0, -2.0, 0.0), vec3(0.0, 1.0, 0.0));

HitPoint distance_scene(in vec3 p) {
    // オブジェクトの回転
    vec3 q = rotate_z(rotate_x(rotate_y(p, time * speed * 0.5), time * speed * 0.2), time * speed * 0.1);

    float t = time * 0.2;
    vec3 cc = vec3(0.9 * cos(3.9 + 1.2 * t) - .3, 0.8 * cos(2.5 + 1.1 * t), 0.8 * cos(3.4 + 1.3 * t));
    if (length(cc) < 0.50) cc = 0.50 * normalize(cc);
    if (length(cc) > 0.95) cc = 0.95 * normalize(cc);

    vec4 trap;
    mb.power = power;
    float d = distance_func_jb_tri(mb, q / 4.0, cc, trap);
    vec3 col = trap_to_color(trap);

    // フロア
    float d3 = distance_func(plane, p);

    return smooth_union(HitPoint(d, vec4(col, 0.8)), HitPoint(d3, vec4(BLUE + 0.5, 1.0)), 0.3);
}

// シーンの法線ベクトルの計算
vec3 get_normal(in vec3 p) {
    float d = 0.001;
    return normalize(vec3(distance_scene(p + vec3(d, 0.0, 0.0)).d - distance_scene(p + vec3(-d, 0.0, 0.0)).d,
                          distance_scene(p + vec3(0.0, d, 0.0)).d - distance_scene(p + vec3(0.0, -d, 0.0)).d,
                          distance_scene(p + vec3(0.0, 0.0, d)).d - distance_scene(p + vec3(0.0, 0.0, -d)).d));
}

float soft_shadow(in vec3 ro, in vec3 rd, in float k) {
    float res = 1.0;
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        float h = distance_scene(ro + rd * t).d;
        res = min(res, k * h / t);
        if (res < 0.001) break;
        t += clamp(h, 0.01, 0.2);
    }
    return clamp(res, 0.4, 1.0);
}

vec3 ray_march(vec3 p, in vec3 ray) {
    float distance = 0.0;
    float len = 0.0;
    vec3 pos = p;  // レイの先端位置
    vec3 color = vec3(0.0);

    // marching loop
    HitPoint hp;
    for (int i = 0; i < ITER; i++) {
        hp = distance_scene(pos);
        len += hp.d;
        pos = p + ray * len;

        // hit check
        if (abs(hp.d) < 0.001) {
            vec3 normal = get_normal(pos);

            // light
            vec3 halfLE = normalize(light - ray);

            vec3 diff = clamp(dot(light, normal), 0.1, 1.0) * hp.mtl.xyz;
            float spec = pow(clamp(dot(halfLE, normal), 0.0, 1.0), 500.0) * hp.mtl.w;
            color = vec3(diff) + vec3(spec);

            // shadow
            float shadow = soft_shadow(pos + normal * 0.01, light, 20.0);

            color = color * shadow;

            break;
        }
    }

    return color;
}

void main(void) {
    // fragment pos
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    // camera
    vec3 c_pos = vec3(0.0, 0.0, 8.0);

    // ray
    float fov = angle * 0.5 * PI / 180.0;
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));

    vec3 color = ray_march(c_pos, ray);
    gl_FragColor = vec4(color, 1.0);
}
