#iUniform float ring_size = 3.0 in{0.0, 20.0 }
#iUniform float speed = 1.0 in{0.1, 10.0 }
#iUniform float morphing = 0.0 in{0.0, 1.0 }
#iUniform float sparseness = 0.4 in{0.3, 2.0 }

precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#include "object.glsl"
#include "operation.glsl"
#include "texture.glsl"
#include "transform.glsl"

const float PI = 3.14159265;
const float angle = 60.0;
const float fov = angle * 0.5 * PI / 180.0;

const vec3 light = vec3(0.577, 0.477, 0.177);

const int ITER = 256;
const int AO_STEP = 64;
const int AO_STEPSIZE = 64;

// オブジェクト
Sphere sphere = Sphere(vec3(0.0, 0.0, 0.0), 3.0);
Box box = Box(vec3(0.0, 0.0, 0.0), vec3(0.05, 0.05, 0.05), 0.07);
Torus torus = Torus(vec3(0.0, 0.0, 0.0), 2.0, 1.0);
Plane plane = Plane(vec3(0.0, -2.0, 0.0), vec3(0.0, 1.0, 0.0));

HitPoint distance_scene(in vec3 p) {
    vec3 q = rotate_z(rotate_x(rotate_y(p, time * speed * 0.5), time * speed * 0.2), 0.1);
    float d1 = distance_func(box, repetition(q, vec3(0.0), vec3(sparseness)));
    torus.radius_a = ring_size;
    float d2 = distance_func(torus, q);

    float d3 = distance_func(plane, p);

    // float d = mix(d2, d1, pow(sin(time * 1.0) * 0.99, 2.0));
    float d = mix(d2, d1, morphing);
    return smooth_union(HitPoint(d, vec4(BLUE, 1.0)), HitPoint(d3, vec4(MAGENTA, 1.0)), 0.5);
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
    for (int i = 0; i < ITER / 4; i++) {
        h = distance_scene(ro + rd * c).d;
        if (abs(h) < 0.001) {
            return shadow_coef;
        }
        r = min(r, h * 64.0 / c);
        c += h;
    }
    return 1.0 - shadow_coef + r * shadow_coef;
}

float ambient_occlusion(in vec3 pos, in vec3 normal) {
    float sum = 0.0;
    float max_sum = 0.0;
    for (int i = 0; i < AO_STEP; i++) {
        vec3 p = pos + normal * float((i + 1) * AO_STEPSIZE);
        sum += 1. / pow(2., float(i)) * distance_scene(pos).d;
        max_sum += 1. / pow(2., float(i)) * float((i + 1) * AO_STEPSIZE);
    }
    return sum / max_sum;
}

vec3 ray_march(vec3 p, in vec3 ray) {
    float distance = 0.0;
    float len = 0.0;
    vec3 pos = p;  // レイの先端位置
    vec3 color = vec3(0.0);

    // marching loop
    float shadow = 1.0;
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

            // shadow
            shadow = gen_shadow(pos + normal * 0.001, light);

            color = vec3(diff) + vec3(spec);

            // float ao = ambient_occlusion(pos, normal);
            // color *= ao;

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
