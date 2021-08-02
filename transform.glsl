// 指定したサイズの空間を繰り返す
vec3 repetition(in vec3 p, in vec3 center, in vec3 size) { return mod(p - center + size / 2.0, size) - size / 2.0; }

// 指定したサイズの空間を有限回繰り返す
vec3 finite_repetition(in vec3 p, in vec3 center, in vec3 size, in vec3 repeat) {
    vec3 q = p - center;
    return q - size * clamp(round(q / size), -repeat, repeat);
}