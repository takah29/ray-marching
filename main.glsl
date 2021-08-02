#iUniform int n = 10 in{10, 1280 }
#iUniform float d = 0.01 in {0.01, 1.0}

precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#include "object.glsl"
#include "transform.glsl"
#include "operation.glsl"

const float PI = 3.14159265;
const float angle = 60.0;
const float fov = angle * 0.5 * PI / 180.0;

const vec3 lightDir = vec3(-0.577, 0.577, 0.577);

// オブジェクト
Sphere sphere = Sphere(vec3(0.0, 0.0, 0.0), 1.0);
Box box = Box(vec3(0.0, 0.0, 0.0), vec3(0.5, 0.5, 0.5), 0.1);
Torus torus = Torus(vec3(0.0, 1.0, -10.0), 10.0, 3.0);
Plane plane = Plane(vec3(0.0, -0.5, 0.0), vec3(0.0, 1.0, 0.0));


// float distance_scene(vec3 p)
// {
//     float t = time;
//     float a = PI * t;
//     float s = pow(sin(a), 2.0);
//     float d1 = distance_func(Sphere(vec3(0.0, 0.0, 0.0), 0.75), p);
//     float d2 = distance_func(Sphere(vec3(0.0), 0.1), trans(p, 0.5));
//     return mix(d1, d2, s);
// }

float distance_scene(in vec3 p) {
    float d1 = distance_func(sphere, repetition(p, vec3(0.0), vec3(4.0)));
    float d2 = distance_func(torus, p);
    float d3 = distance_func(plane, p);

    float d = mix(d1, d2, pow(sin(time), 2.0));
    return op_union(d, d3);
}

vec3 get_normal(in vec3 p) {
    float d = 0.0001;
    return normalize(vec3(distance_scene(p + vec3(d, 0.0, 0.0)) - distance_scene(p + vec3(-d, 0.0, 0.0)),
                          distance_scene(p + vec3(0.0, d, 0.0)) - distance_scene(p + vec3(0.0, -d, 0.0)),
                          distance_scene(p + vec3(0.0, 0.0, d)) - distance_scene(p + vec3(0.0, 0.0, -d))));
}

vec3 ray_march(vec3 p, in vec3 ray) {
    float distance = 0.0;
    float len = 0.0;
    vec3 pos = p;  // レイの先端位置
    vec3 color = vec3(0.0);

    // marching loop
    for (int i = 0; i < n; i++) {
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
    vec3 c_pos = vec3(mouse * 4.0 - vec2(2.0, -10.0), 16.0);
    vec3 c_dir = vec3(0.0, -1.0, -0.0);
    // vec3 c_up = vec3(0.0    , 1.0, 0.0);
    // vec3 c_side = cross(c_dir, c_up);
    // float targetDepth = 1.0;

    // ray
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));

    vec3 color = ray_march(c_pos, ray);
    gl_FragColor = vec4(color, 1.0);
}
