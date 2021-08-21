// 指定したサイズの空間を繰り返す
vec3 repetition(in vec3 p, in vec3 center, in vec3 size) { return mod(p - center + size / 2.0, size) - size / 2.0; }

// 指定したサイズの空間を有限回繰り返す
vec3 finite_repetition(in vec3 p, in vec3 center, in vec3 size, in vec3 repeat) {
    vec3 q = p - center;
    return q - size * clamp(round(q / size), -repeat, repeat);
}

vec3 rotate_x(in vec3 p, in float rad) {
    return vec3(p.x, p.y * cos(rad) - p.z * sin(rad), p.y * sin(rad) + p.z * cos(rad));
}
vec3 rotate_y(in vec3 p, in float rad) {
    return vec3(p.x * cos(rad) + p.z * sin(rad), p.y, -p.x * sin(rad) + p.z * cos(rad));
}
vec3 rotate_z(in vec3 p, in float rad) {
    return vec3(p.x * cos(rad) - p.y * sin(rad), p.x * sin(rad) + p.y * cos(rad), p.z);
}

vec3 twist_x(in vec3 p, in float power) {
    float s = sin(power * p.x);
    float c = cos(power * p.x);
    mat3 m = mat3(1.0, 0.0, 0.0, 0.0, c, s, 0.0, -s, c);
    return m * p;
}

vec3 twist_y(in vec3 p, in float power) {
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    mat3 m = mat3(c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c);
    return m * p;
}

vec3 twist_z(in vec3 p, in float power) {
    float s = sin(power * p.z);
    float c = cos(power * p.z);
    mat3 m = mat3(c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0);
    return m * p;
}

vec3 scale_x(in vec3 p, in float s) { return vec3(p.x * s, p.yz); }

vec3 scale_y(in vec3 p, in float s) { return vec3(p.x, p.y * s, p.z); }

vec3 scale_z(in vec3 p, in float s) { return vec3(p.xy, p.z * s); }

vec3 scale_xyz(in vec3 p, in float s) { return p * s; }

// クオータニオンによる回転
vec4 mult_quat(in vec4 p, in vec4 q) {
    float a = q.w * p.x - q.z * p.y + q.y * p.z + q.x * p.w;
    float b = q.z * p.x + q.w * p.y - q.x * p.z + q.y * p.w;
    float c = -q.y * p.x + q.x * p.y + q.w * p.z + q.z * p.w;
    float d = -q.x * p.x - q.y * p.y - q.z * p.z + q.w * p.w;
    return vec4(a, b, c, d);
}
vec3 angle_axis(in vec3 p, in float rad, in vec3 axis) {
    vec4 q = vec4(normalize(axis) * sin(rad / 2.0), cos(rad / 2.0));
    vec4 q_ = vec4(-q.xyz, q.w);
    return mult_quat(mult_quat(q, vec4(p, 0.0)), q_).xyz;
}