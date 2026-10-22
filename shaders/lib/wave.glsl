// Wind for foliage and wave height for water. Needs lib/settings.glsl.
uniform float frameTimeCounter;
uniform float rainStrength;

// world-space vertex offset for leaves (id 10000) and plants (id 10001, top vertices only)
vec3 foliageWave(vec3 wp, float id, float isTop) {
    float amp = 0.0;
    if (id == 10000.0) amp = 0.07;
    else if (id == 10001.0) amp = 0.14 * isTop;
    if (amp == 0.0) return vec3(0.0);
    amp *= WAVING_STRENGTH * (1.0 + rainStrength * 1.3);

    float t = frameTimeCounter;
    float gust = 0.55 + 0.45 * sin(t * 0.45 + wp.x * 0.09 + wp.z * 0.06);
    float wx = sin(t * 1.9 + wp.x * 0.9 + wp.z * 0.55) + 0.45 * sin(t * 3.4 + wp.z * 1.7 + wp.y * 0.8);
    float wz = cos(t * 1.6 + wp.z * 0.8 + wp.x * 0.45) + 0.45 * cos(t * 3.0 + wp.x * 1.5 + wp.y * 0.7);
    vec3 o = vec3(wx, 0.0, wz) * amp * gust;
    if (id == 10000.0) o.y = sin(t * 2.2 + wp.x * 1.1 + wp.z * 1.3) * amp * 0.5;
    return o;
}

// water surface height, roughly -1..1
float waveH(vec2 p) {
    float t = frameTimeCounter;
    p += 0.35 * vec2(sin(p.y * 0.8 + t * 0.5), cos(p.x * 0.7 + t * 0.4));
    float h = 0.0;
    h += sin(dot(p, vec2(0.90, 0.40)) * 1.3 + t * 1.2) * 0.55;
    h += sin(dot(p, vec2(-0.50, 0.85)) * 2.1 + t * 1.6) * 0.30;
    h += sin(dot(p, vec2(0.20, -1.00)) * 3.7 + t * 2.3) * 0.16;
    h += sin(dot(p, vec2(1.00, -0.30)) * 6.3 + t * 3.2) * 0.08;
    return h;
}
