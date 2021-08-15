vec4 checker(in vec3 p, in vec4 mtl1, in vec4 mtl2) {
    vec3 q = floor(mod(p, 2.0));

    if (mod(q.x + q.y + q.z, 2.0) == 0.0) {
        return mtl1;
    } else {
        return mtl2;
    }
}
