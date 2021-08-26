#iUniform float dist = 7.0 in{4.5, 15.0 }
#iUniform float speed = 0.5 in{0.0, 4.0 }
#iUniform float ring_size = 3.0 in{0.0, 20.0 }
#iUniform float morphing = 0.5 in{0.0, 1.0 }
#iUniform float sparseness = 0.4 in{0.3, 2.0 }

precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#include "lib/object.glsl"
#include "lib/operation.glsl"
#include "lib/transform.glsl"

const int ITER = 128;

const vec3 light = vec3(0.577, 0.577, 0.577);
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
vec3 get_normal(in vec3 pos) {
    const float ep = 0.001;
    vec2 e = vec2(1.0, -1.0) * 0.5773;
    return normalize(e.xyy * distance_scene(pos + e.xyy * ep).d + e.yyx * distance_scene(pos + e.yyx * ep).d +
                     e.yxy * distance_scene(pos + e.yxy * ep).d + e.xxx * distance_scene(pos + e.xxx * ep).d);
}

float soft_shadow(in vec3 p, in vec3 ray, in float k) {
    vec3 pos = p;
    float res = 1.0;
    float len = 0.0;
    for (int i = 0; i < 80; i++) {
        float d = distance_scene(pos).d;
        res = min(res, k * d / len);

        if (res < 0.001) {
            break;
        }

        len += clamp(d, 0.01, 0.5);
        pos = p + ray * len;
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
        if (abs(hp.d) < len * 0.0001) {
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
    vec2 coord = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    // camera
    vec3 c_pos = vec3(0.0, 0.0, 8.0);
    vec3 dir = vec3(0.0, 0.0, -1.0);
    vec3 right = vec3(1.0, 0.0, 0.0);
    vec3 top = vec3(0.0, 1.0, 0.0);

    Camera camera = Camera(c_pos, dir, right, top, 60.0);
    c_pos = spherical_to_orthogonal(mouse_coord_to_hemisphere(mouse * 2.0 - 1.0, dist));
    look_at_origin(camera, c_pos);

    // ray
    vec3 ray = get_ray(camera, coord);

    vec3 color = ray_march(camera.pos, ray);
    gl_FragColor = vec4(color, 1.0);
}
