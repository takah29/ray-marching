#iUniform float ring_size = 3.0 in{0.0, 20.0 }
#iUniform float angle = 60.0 in{30.0, 90.0 }
#iUniform float speed = 0.1 in{0.0, 4.0 }
#iUniform float morphing = 0.0 in{0.0, 1.0 }
#iUniform float sparseness = 0.4 in{0.3, 2.0 }

precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#include "object.glsl"
#include "operation.glsl"
#include "transform.glsl"

const float PI = 3.14159265;
const vec3 light = vec3(0.577, 0.577, 0.577);

const int ITER = 128;

// オブジェクト
Sphere sphere = Sphere(vec3(0.0, 0.0, 0.0), 3.0);
Box box = Box(vec3(0.0, 0.0, 0.0), vec3(0.05, 0.05, 0.05), 0.07);
Torus torus = Torus(vec3(0.0, 0.0, 0.0), 2.0, 1.0);
Plane plane = Plane(vec3(0.0, -2.0, 0.0), vec3(0.0, 1.0, 0.0));

HitPoint distance_scene(in vec3 p) {
    vec3 q = rotate_z(rotate_x(rotate_y(p, time * speed * 0.5), time * speed * 0.2), time * speed * 0.1);
    float d1 = distance_func(box, repetition(q, vec3(0.0), vec3(sparseness)));
    torus.radius_a = ring_size;
    float d2 = distance_func(torus, q);

    float d3 = distance_func(plane, p);

    // float d = mix(d2, d1, (-cos(time * 2.0) + 1.0) * 0.99 / 2.0);
    float d = mix(d2, d1, morphing);
    return smooth_union(HitPoint(d, vec4(RED + 0.5, 1.0)), HitPoint(d3, vec4(BLUE + 0.5, 1.0)), 0.5);
}

// シーンの法線ベクトルの計算
vec3 get_normal(in vec3 p) {
    float d = 0.0001;
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
    return clamp(res, 0.3, 1.0);
}

float ambient_occlusion(in vec3 pos, in vec3 normal) {
    float ao = 0.0;
    float amp = 0.5;
    float distance = 0.02;
    for (int i = 0; i < 6; i++) {
        pos = pos + distance * normal;
        ao += amp * clamp(distance_scene(pos).d / distance, 0.0, 1.0);
        amp *= 0.5;
        distance += 0.02;
    }
    return ao;
}

vec3 ray_march(vec3 p, in vec3 ray) {
    float distance = 0.0;
    float len = 0.0;
    vec3 pos = p;  // レイの先端位置
    vec3 color = vec3(0.0);

    // marching loop
    HitPoint hp;
    int s;
    for (s = 0; s < ITER; s++) {
        hp = distance_scene(pos);
        len += hp.d;
        pos = p + ray * len;

        // hit check
        if (abs(hp.d) < 0.0001) {
            vec3 normal = get_normal(pos);

            // light
            vec3 halfLE = normalize(light - ray);

            vec3 diff = clamp(dot(light, normal), 0.1, 1.0) * hp.mtl.xyz;
            float spec = pow(clamp(dot(halfLE, normal), 0.0, 1.0), 500.0) * hp.mtl.w;
            color = vec3(diff) + vec3(spec);

            // shadow
            float shadow = soft_shadow(pos + normal * 0.01, light, 10.0);

            // ambient occulusion
            float ao = ambient_occlusion(pos, normal);

            color = color * shadow * ao;

            break;
        }
    }

    return color * (1.0 - float(s + 1) / float(ITER));
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
