// Procedural sky: gradient, sunset, sun/moon glow, stars, aurora borealis, volumetric clouds.
// Requires lib/settings.glsl. All colours returned are linear HDR.
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform mat4 gbufferModelViewInverse;

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // quintic: no visible grid
    return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
               mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

const mat2 ROT = mat2(0.80, -0.60, 0.60, 0.80);

float fbm(vec2 p) {
    float a = 0.5;
    float s = 0.0;
    for (int i = 0; i < 3; i++) {
        s += a * vnoise(p);
        p = ROT * p * 2.03 + vec2(17.1, 9.2); // rotate each octave
        a *= 0.5;
    }
    return s / 0.875;
}

float fbm3(vec2 p) {
    return fbm(p);
}

float skySunHeight() {
    return dot(normalize(sunPosition), normalize(upPosition));
}

float skyNightFactor() {
    return 1.0 - smoothstep(-0.25, 0.0, skySunHeight());
}

// colour of the active light (sun or moon) as seen by the sky
vec3 skyLightColor() {
    float sh = skySunHeight();
    float warm = pow(1.0 - smoothstep(0.0, 0.5, sh), 1.6);
    vec3 sunC = mix(vec3(1.0, 0.92, 0.80), vec3(1.0, 0.40, 0.12), warm) * smoothstep(-0.06, 0.12, sh) * 2.8;
    vec3 moonC = vec3(0.40, 0.55, 1.0) * 0.45 * smoothstep(-0.06, 0.12, -sh);
    return (sunC + moonC) * mix(1.0, 0.25, rainStrength);
}

// dirV: normalised view-space direction
vec3 skyBase(vec3 dirV) {
    vec3 up = normalize(upPosition);
    vec3 sunV = normalize(sunPosition);
    float sh = dot(sunV, up);
    float h = dot(dirV, up);
    float day = smoothstep(-0.12, 0.22, sh);

    vec3 zenD = pow(vec3(0.16, 0.38, 0.82), vec3(2.2));
    vec3 horD = pow(vec3(0.62, 0.82, 1.00), vec3(2.2));
    vec3 zenN = pow(vec3(0.02, 0.04, 0.14), vec3(2.2));
    vec3 horN = pow(vec3(0.10, 0.16, 0.34), vec3(2.2)) * 0.8;
    vec3 zen = mix(zenN, zenD, day);
    vec3 hor = mix(horN, horD, day);

    float hp = clamp(h, 0.0, 1.0);
    vec3 col = mix(hor, zen, pow(hp, 0.55));

    // sunrise / sunset
    float sunset = 1.0 - smoothstep(0.0, 0.38, abs(sh + 0.02));
    float sd = max(dot(dirV, sunV), 0.0);
    float md = max(dot(dirV, -sunV), 0.0);
    float lowBand = pow(1.0 - hp, 5.0);
    vec3 sunsetCol = mix(vec3(1.0, 0.30, 0.10), vec3(1.0, 0.45, 0.62), clamp(h * 2.5 + 0.2, 0.0, 1.0));
    col += sunsetCol * sunset * (pow(sd, 2.5) * 1.1 + lowBand * 0.55);
    col = mix(col, col * vec3(0.9, 0.7, 0.9), sunset * 0.3 * (1.0 - sd));

    // sun and moon glow
    col += vec3(1.0, 0.78, 0.5) * (pow(sd, 48.0) * 0.7 + pow(sd, 6.0) * 0.12) * smoothstep(-0.1, 0.1, sh);
    col += vec3(0.45, 0.6, 1.0) * (pow(md, 60.0) * 0.5 + pow(md, 8.0) * 0.06) * smoothstep(-0.1, 0.1, -sh);

    col *= mix(1.0, 0.55, clamp(-h * 3.0, 0.0, 1.0));

    float lum = dot(col, vec3(0.333));
    col = mix(col, vec3(lum) * vec3(0.75, 0.8, 0.88), rainStrength * 0.75);
    return col;
}

vec3 skyStars(vec3 wd, float night) {
    if (night < 0.01) return vec3(0.0);
    vec3 p = wd * 230.0;
    vec3 ip = floor(p);
    vec3 fp = p - ip;
    float h = hash13(ip);
    if (h < 0.992) return vec3(0.0);
    vec3 c = vec3(hash13(ip + 7.1), hash13(ip + 13.7), hash13(ip + 29.3));
    float d = length(fp - (0.3 + c * 0.4));
    float s = smoothstep(0.32, 0.0, d);
    float tw = 0.7 + 0.3 * sin(frameTimeCounter * (1.5 + (h - 0.992) * 400.0) + h * 400.0);
    vec3 tint = mix(vec3(0.7, 0.82, 1.0), vec3(1.0, 0.88, 0.72), c.x);
    return tint * s * tw * (1.5 + c.y * 2.5) * night * (1.0 - rainStrength);
}

vec3 skyAurora(vec3 wd, float night) {
    vec3 acc = vec3(0.0);
#ifdef AURORA
    if (wd.y < 0.03 || night < 0.01) return acc;
    float t = frameTimeCounter;
    for (int i = 0; i < 9; i++) {
        float fi = float(i) / 8.0;
        float hgt = 6.0 + fi * 5.0;
        vec2 p = wd.xz / wd.y * hgt;
        float n = fbm(p * 0.045 + vec2(t * 0.012, fi * 0.7));
        float band = 1.0 - abs(n * 2.0 - 1.0);
        band = pow(band, 7.0);
        float rays = 0.55 + 0.45 * vnoise(vec2(p.x * 0.35 + t * 0.25, p.y * 0.06));
        vec3 col = mix(vec3(0.10, 1.00, 0.45), vec3(0.50, 0.22, 1.00), smoothstep(0.25, 1.0, fi));
        col = mix(col, vec3(1.0, 0.2, 0.55), smoothstep(0.85, 1.0, fi) * 0.5);
        acc += col * band * rays * (1.0 - fi * 0.45);
    }
    acc *= 0.62 * smoothstep(0.03, 0.4, wd.y) * night * (1.0 - rainStrength) * AURORA_INTENSITY;
#endif
    return acc;
}

#ifdef CLOUDS
const float CLOUD_H = 720.0;

float hgPhase(float c, float g) {
    return (1.0 - g * g) / pow(1.0 + g * g - 2.0 * g * c, 1.5) * 0.25;
}

// Single thick layer, shaded by how much cloud lies toward the light.
// 3 fbm + 1 noise lookups per pixel (cheap) instead of a ray march.
// returns (premultiplied scattered light, transmittance)
vec4 skyClouds(vec3 wd, vec3 Ldir, vec3 Lcol, vec3 ambC) {
    if (wd.y < 0.03) return vec4(0.0, 0.0, 0.0, 1.0);
    float t = CLOUD_H / wd.y;
    vec2 q = wd.xz * t * 0.0018 + vec2(frameTimeCounter * 0.004, frameTimeCounter * 0.0015);
    float thr = mix(0.60, 0.38, CLOUD_COVERAGE) - rainStrength * 0.1;

    float detail = vnoise(q * 6.0 + 3.7) * 0.10;
    float d = smoothstep(thr, thr + 0.15, fbm3(q) - detail + 0.05);
    if (d < 0.003) return vec4(0.0, 0.0, 0.0, 1.0);

    vec2 ls = Ldir.xz / max(Ldir.y, 0.25) * 0.10;
    float dL = smoothstep(thr, thr + 0.15, fbm3(q + ls) - detail + 0.05);

    float sunTerm = max(exp(-dL * 3.0), 0.22 * exp(-dL * 0.6));
    float cosA = dot(wd, Ldir);
    float ph = mix(hgPhase(cosA, 0.6), hgPhase(cosA, -0.2), 0.3) * 1.6 + 0.35;

    vec3 grey = vec3(dot(ambC, vec3(0.333)));
    vec3 amb = mix(ambC, grey, 0.7) * (0.65 + 0.35 * (1.0 - dL));
    vec3 col = Lcol * sunTerm * ph * 0.8 + amb * 1.1;

    float alpha = (1.0 - exp(-d * 4.0)) * smoothstep(0.03, 0.22, wd.y);
    return vec4(col * alpha, 1.0 - alpha);
}
#endif

vec3 skyFull(vec3 dirV) {
    vec3 wd = mat3(gbufferModelViewInverse) * dirV;
    float night = skyNightFactor();
    vec3 sky = skyBase(dirV) + skyStars(wd, night) + skyAurora(wd, night);
#ifdef CLOUDS
    vec3 sunW = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    vec3 Ldir = skySunHeight() > -0.05 ? sunW : -sunW;
    vec3 ambC = skyBase(normalize(upPosition)) * 0.9 + vec3(0.01, 0.012, 0.02);
    vec4 cl = skyClouds(wd, Ldir, skyLightColor(), ambC);
    sky = sky * cl.a + cl.rgb;
#endif
    return sky;
}
