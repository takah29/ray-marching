// Sphere
struct Sphere {
    vec3 center;
    float radius;
};
float distance_func(in Sphere sphere, in vec3 p) { return length(p - sphere.center) - sphere.radius; }

// Box
struct Box {
    vec3 center;
    vec3 size;
    float expansion;
};
float distance_func(in Box box, in vec3 p) {
    vec3 q = abs(p - box.center);
    return length(max(q - box.size, 0.0)) - box.expansion;
}

// Plane
struct Plane {
    vec3 center;
    vec3 normal;
};
float distance_func(in Plane plane, in vec3 p) { return dot(p - plane.center, plane.normal); }

// Torus
struct Torus {
    vec3 center;
    float radius_a;
    float radius_b;
};
float distance_func(in Torus torus, in vec3 p) {
    vec2 q = vec2(length(p.xz - torus.center.xz) - torus.radius_a, p.y - torus.center.y);
    return length(q) - torus.radius_b;
}

// Capsule
struct Capsule {
    vec3 a;
    vec3 b;
    float radius;
};
float distance_func(in Capsule capsule, in vec3 p) {
    vec3 pa = p - capsule.a, ba = capsule.b - capsule.a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - capsule.radius;
}

// RecursiveTetrahedron
struct RecursiveTetrahedron {
    vec3 offset;
    float scale;
    int iterations;
};
float distance_func(in RecursiveTetrahedron rt, in vec3 p) {
    vec4 z = vec4(p, 1.0);
    for (int i = 0; i < rt.iterations; i++) {
        if (z.x + z.y < 0.0) z.xy = -z.yx;
        if (z.x + z.z < 0.0) z.xz = -z.zx;
        if (z.y + z.z < 0.0) z.zy = -z.yz;
        z *= rt.scale;
        z.xyz -= rt.offset * (rt.scale - 1.0);
    }
    return (length(z.xyz) - 1.5) / z.w;
}

// MengerSponge
struct MengerSponge {
    vec3 offset;
    float scale;
    int iterations;
};
float distance_func(in MengerSponge ms, in vec3 p) {
    vec4 z = vec4(p, 1.0);
    for (int i = 0; i < ms.iterations; i++) {
        z = abs(z);
        if (z.x < z.z) z.xz = z.zx;
        if (z.y < z.z) z.yz = z.zy;
        z *= ms.scale;
        z.xyz -= ms.offset * (ms.scale - 1.0);
        if (z.z < -0.5 * ms.offset.z * (ms.scale - 1.0)) {
            z.z += ms.offset.z * (ms.scale - 1.0);
        }
    }
    return (length(max(abs(z.xyz) - vec3(1.0, 1.0, 1.0), 0.0))) / z.w;
}

// HexTiling
struct HexTiling {
    float y_pos;
    float radius;
    float scale;
};
float distance_func(in HexTiling ht, in vec3 p) {
    vec2 rep = vec2(2.0 * sqrt(3.0), 2.0) * ht.radius;
    vec2 p1 = mod(p.zx, rep) - rep * 0.5;
    vec2 p2 = mod(p.zx + 0.5 * rep, rep) - rep * 0.5;

    float h = ht.scale * ht.radius;

    vec3 k = vec3(-0.8660254, 0.57735, 0.5);
    p1 = abs(p1);
    p1 -= 2.0 * min(dot(k.xz, p1), 0.0) * k.xz;
    float d1 = length(p1 - vec2(clamp(p1.x, -k.y * h, k.y * h), h)) * sign(p1.y - h);

    p2 = abs(p2);
    p2 -= 2.0 * min(dot(k.xz, p2), 0.0) * k.xz;
    float d2 = length(p2 - vec2(clamp(p2.x, -k.y * h, k.y * h), h)) * sign(p2.y - h);

    return max(min(d1, d2), p.y - ht.y_pos);
}

// Mandelbulb
struct Mandelbulb {
    float power;
    int iterations;
};
float distance_func_mb_simple(in Mandelbulb mb, in vec3 p) {
    vec3 z = p;
    float dr = 1.0;
    float r;
    for (int i = 0; i < mb.iterations; i++) {
        r = length(z);
        if (r > 10.0) break;
        float theta = acos(z.y / r);
        float phi = atan(z.z, z.x);
        dr = pow(r, mb.power - 1.0) * mb.power * dr + 1.0;

        float zr = pow(r, mb.power);
        theta = theta * mb.power;
        phi = phi * mb.power;

        z = zr * vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi));
        z += p;
    }
    return 0.5 * log(r) * r / dr;
}
float distance_func_mandelbulb(in Mandelbulb mb, in vec3 p, out vec4 res_color) {
    vec3 w = p;
    float m = dot(w, w);

    vec4 trap = vec4(abs(w), m);
    float dz = 1.0;

    for (int i = 0; i < mb.iterations; i++) {
        // trigonometric version

        // dz = 8*z^7*dz
        dz = 8.0 * pow(m, 3.5) * dz + 1.0;
        // dz = 8.0*pow(sqrt(m),7.0)*dz + 1.0;

        // z = z^8+z
        float r = length(w);
        float b = mb.power * acos(w.y / r);
        float a = mb.power * atan(w.x, w.z);
        w = p + pow(r, 8.0) * vec3(sin(b) * sin(a), cos(b), sin(b) * cos(a));

        trap = min(trap, vec4(abs(w), m));

        m = dot(w, w);
        if (m > 256.0) break;
    }

    res_color = vec4(m, trap.yzw);

    // distance estimation (through the Hubbard-Douady potential)
    return 0.25 * log(m) * sqrt(m) / dz;
}
vec3 trap_to_color(in vec4 trap, in vec3 lowcol, in vec3 middlecol, in vec3 highcol) {
    vec3 color = vec3(0.01);
    color = mix(color, lowcol, clamp(trap.y, 0.0, 1.0));
    color = mix(color, middlecol, clamp(trap.z * trap.z, 0.0, 1.0));
    color = mix(color, highcol, clamp(pow(trap.w, 6.0), 0.0, 1.0));
    color *= 5.0;
    return color;
}

// Juliabulb
float distance_func_juliabulb(in Mandelbulb mb, in vec3 p, in vec3 c, out vec4 res_color) {
    vec3 z = p;
    float m = dot(z, z);
    vec4 trap = vec4(abs(z), m);
    float dz = 1.0;

    for (int i = 0; i < mb.iterations; i++) {
        // dz = 8*z^7*dz
        dz = 8.0 * pow(m, 3.5) * dz;

        // z = z^8+z
        float r = length(z);
        float b = mb.power * acos(clamp(z.y / r, -1.0, 1.0));
        float a = mb.power * atan(z.x, z.z);
        z = pow(r, 8.0) * vec3(sin(b) * sin(a), cos(b), sin(b) * cos(a)) + c;

        // orbit trapping
        trap = min(trap, vec4(abs(z), m));

        m = dot(z, z);
        if (m > 4.0) break;
    }

    res_color = trap;

    float w = length(z);
    return 0.5 * w * log(w) / dz;
}

// MandelBox
struct MandelBox {
    float scale;
    float min_radius;
    float fixed_radius;
    int iterations;
};
float distance_func_mandelbox(in MandelBox mb, in vec3 p) {
    vec3 z = p;
    float dr = 1.0;
    for (int i = 0; i < mb.iterations; i++) {
        // Box Fold
        float folding_limit = 1.0;
        z = clamp(z, -folding_limit, folding_limit) * 2.0 - z;

        // Sphere Fold
        float m2 = mb.min_radius * mb.min_radius;
        float f2 = mb.fixed_radius * mb.fixed_radius;
        float r2 = dot(z, z);
        if (r2 < m2) {
            float temp = (f2 / m2);
            z *= temp;
            dr *= temp;
        } else if (r2 < f2) {
            float temp = (f2 / r2);
            z *= temp;
            dr *= temp;
        }

        z = mb.scale * z + p;
        dr = dr * abs(mb.scale) + 1.0;
    }
    float r = length(z);
    return r / abs(dr);
}
