#iUniform float angle = 50.0 in{10.0, 90.0 }
#iUniform float speed = 0.1 in{0.0, 4.0 }
#iUniform float scale = 2.6 in{2.0, 3.4 }
#iUniform float min_radius = 0.4 in{0.0, 1.0 }
#iUniform float fixed_radius = 1.0 in{0.8, 1.4 }

precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#include "lib/fractal.glsl"
#include "lib/object.glsl"
#include "lib/operation.glsl"
#include "lib/transform.glsl"

const float PI = 3.14159265;
const int ITER = 256;
const float MAX_RAY_LENGTH = 100.0;

const vec3 light = vec3(0.577, 0.577, 0.577);

MandelBox mb = MandelBox(3.0, 0.5, 1.0, 10);
Plane plane = Plane(vec3(0.0, -4.0, 0.0), vec3(0.0, 1.0, 0.0));

HitPoint distance_scene(in vec3 p) {
    // オブジェクトの回転
    vec3 q = rotate_z(rotate_x(rotate_y(p, time * speed * 0.5), time * speed * 0.2), time * speed * 0.1);

    // パラメータ設定
    mb.scale = scale;
    mb.min_radius = min_radius;
    mb.fixed_radius = fixed_radius;

    float d1 = distance_estimate(mb, q * 2.0);
    float d2 = distance_func(plane, p);

    return smooth_union(HitPoint(d1, vec4(YELLOW * 0.1 + 0.5, 1.0)), HitPoint(d2, vec4(BLUE + 0.5, 1.0)), 0.0);
}

// シーンの法線ベクトルの計算
vec3 get_normal(in vec3 pos) {
    const float ep = 0.001;
    vec2 e = vec2(1.0, -1.0) * 0.5773;
    return normalize(e.xyy * distance_scene(pos + e.xyy * ep).d + e.yyx * distance_scene(pos + e.yyx * ep).d +
                     e.yxy * distance_scene(pos + e.yxy * ep).d + e.xxx * distance_scene(pos + e.xxx * ep).d);
}

float soft_shadow(in vec3 ro, in vec3 rd, in float k) {
    float res = 1.0;
    float t = 0.0;
    for (int i = 0; i < 80; i++) {
        float h = distance_scene(ro + rd * t).d;
        res = min(res, k * h / t);
        if (res < 0.001) break;
        t += clamp(h, 0.01, 0.2);
    }
    return clamp(res, 0.2, 1.0);
}

vec3 ray_march(vec3 p, in vec3 ray) {
    vec3 pos = p;  // レイの先端位置
    vec3 color = vec3(0.0);

    // marching loop
    HitPoint hp;
    int s;
    float len;
    for (s = 0; s < ITER; s++) {
        hp = distance_scene(pos);

        len += hp.d;
        if (len > MAX_RAY_LENGTH) {
            break;
        }

        pos = pos + ray * hp.d;

        // hit check
        if (abs(hp.d) < 0.01) {
            vec3 normal = get_normal(pos);

            // directional light
            vec3 rd = normalize(light);
            vec3 halfLE = normalize(rd - ray);

            vec3 diff = clamp(dot(rd, normal), 0.1, 1.0) * hp.mtl.xyz * 1.3;
            float spec = pow(clamp(dot(halfLE, normal), 0.0, 1.0), 10.0) * hp.mtl.w;
            color += vec3(diff) + vec3(spec);

            float shadow = soft_shadow(pos + normal * 0.001, rd, 100.0);

            color *= shadow;

            break;
        }
    }

    return color * (1.0 - len / MAX_RAY_LENGTH);
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
