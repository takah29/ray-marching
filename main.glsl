precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#include "object/box.glsl"
#include "object/plane.glsl"
#include "object/sphere.glsl"

const float PI = 3.14159265;
const float angle = 60.0;
const float fov = angle * 0.5 * PI / 180.0;

const vec3 lightDir = vec3(-0.577, 0.577, 0.577);

vec3 trans(in vec3 p, in float scale) { return mod(p, scale) - scale / 2.0; }

// オブジェクト
Sphere sphere = Sphere(vec3(0.0, 0.0, 0.0), 1.0);
Box box = Box(vec3(0.0, 0.0, 0.0), vec3(0.5, 0.5, 0.5), 0.1);
Plane plane = Plane(vec3(0.0, -2.0, 0.0), vec3(0.0, 1.0, 0.0));

float distance_scene(in vec3 p) {
    float d1 = distance_func(sphere, trans(p, 4.0));
    float d2 = distance_func(plane, p);
    return min(d1, d2);
}

vec3 get_normal(in vec3 p) {
    float d = 0.0001;
    return normalize(vec3(distance_scene(p + vec3(d, 0.0, 0.0)) - distance_scene(p + vec3(-d, 0.0, 0.0)),
                          distance_scene(p + vec3(0.0, d, 0.0)) - distance_scene(p + vec3(0.0, -d, 0.0)),
                          distance_scene(p + vec3(0.0, 0.0, d)) - distance_scene(p + vec3(0.0, 0.0, -d))));
}

vec3 ray_march(vec3 p, in vec3 ray) {
    float distance = 0.0;  // レイとオブジェクト間の最短距離
    float len = 0.0;       // レイに継ぎ足す長さ
    vec3 pos = p;          // レイの先端位置
    vec3 color = vec3(0.0);

    // marching loop
    for (int i = 0; i < 128; i++) {
        distance = distance_scene(pos);
        len += distance;
        pos = p + ray * len;

        // hit check
        if (distance < 0.001) {
            vec3 normal = get_normal(pos);
            float diff = clamp(dot(lightDir, normal), 0.1, 1.0);
            color = vec3(diff);
            break;
        }
    }

    return color;
}

void main(void) {
    // fragment position
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    // camera
    vec3 c_pos = vec3(mouse * 4.0 - 2.0, 2.0);
    vec3 c_dir = vec3(0.0, 0.0, -1.0);
    // vec3 c_up = vec3(0.0    , 1.0, 0.0);
    // vec3 c_side = cross(c_dir, c_up);
    // float targetDepth = 1.0;

    // ray
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));

    vec3 color = ray_march(c_pos, ray);
    gl_FragColor = vec4(color, 1.0);
}
