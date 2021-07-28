precision highp float;

struct Box {
    vec3 center;
    vec3 size;
    float expansion;
};

float distance_func(in Box box, in vec3 p) {
    vec3 q = abs(p - box.center);
    return length(max(q - box.size, 0.0)) - box.expansion;
}

vec3 get_normal(in Box box, in vec3 p) {
    float d = 0.0001;
    return normalize(vec3(distance_func(box, p + vec3(d, 0.0, 0.0)) - distance_func(box, p + vec3(-d, 0.0, 0.0)),
                          distance_func(box, p + vec3(0.0, d, 0.0)) - distance_func(box, p + vec3(0.0, -d, 0.0)),
                          distance_func(box, p + vec3(0.0, 0.0, d)) - distance_func(box, p + vec3(0.0, 0.0, -d))));
}
