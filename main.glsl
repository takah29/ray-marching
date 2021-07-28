precision mediump float;
uniform float time;
uniform vec2  mouse;
uniform vec2  resolution;

#include "object/sphere.glsl"
#include "object/box.glsl"

const float PI = 3.14159265;
const float angle = 60.0;
const float fov = angle * 0.5 * PI / 180.0;

const vec3 lightDir = vec3(-0.577, 0.577, 0.577);

vec3 trans(in vec3 p, in float scale){
    return mod(p, scale) - scale / 2.0;
}

void main(void){
    // fragment position
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    // オブジェクト
    Sphere sphere = Sphere(vec3(0.0, 0.0, 0.0), 1.0);
    Box box = Box(vec3(0.0, 0.0,0.0), vec3(0.5, 0.5, 0.5), 0.1);

    // camera
    vec3 cPos = vec3(mouse * 4.0 - 2.0,  2.0);
    vec3 cDir = vec3(0.0,  0.0, -1.0);
    vec3 cUp  = vec3(0.0,  1.0,  0.0);
    vec3 cSide = cross(cDir, cUp);
    float targetDepth = 1.0;

    // ray
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));

    // marching loop
    float distance = 0.0; // レイとオブジェクト間の最短距離
    float rLen = 0.0;     // レイに継ぎ足す長さ
    vec3  rPos = cPos;    // レイの先端位置
    for(int i = 0; i < 640; i++){
        distance = distance_func(box, trans(rPos, 4.0));
        rLen += distance;
        rPos = cPos + ray * rLen;
    }

    // hit check
    if(abs(distance) < 0.001){
        vec3 normal = get_normal(box, trans(rPos, 4.0));
        float diff = clamp(dot(lightDir, normal), 0.1, 1.0);
        gl_FragColor = vec4(vec3(diff), 1.0);
    }else{
        gl_FragColor = vec4(vec3(0.0), 1.0);
    }
}
