#version 120
// Pass 2: water reflections (SSR + sky + aurora), atmospheric fog, underwater look
#include "/lib/settings.glsl"
#include "/lib/sky.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 shadowLightPosition;
uniform float far;
uniform int isEyeInWater;

varying vec2 texcoord;
varying vec3 lightCol;
varying vec3 ambCol;
varying vec3 gndCol;

vec3 toView(vec2 uv, float d) {
    vec4 p = gbufferProjectionInverse * vec4(vec3(uv, d) * 2.0 - 1.0, 1.0);
    return p.xyz / p.w;
}

vec4 traceSSR(vec3 vpos, vec3 rd) {
    float stepL = 0.25;
    vec3 p = vpos;
    for (int i = 0; i < 32; i++) {
        p += rd * stepL;
        stepL *= 1.18;
        vec4 pp = gbufferProjection * vec4(p, 1.0);
        if (pp.w <= 0.0) break;
        vec2 uv = pp.xy / pp.w * 0.5 + 0.5;
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) break;
        float sd = texture2D(depthtex1, uv).r;
        if (sd >= 1.0) continue;
        float diff = toView(uv, sd).z - p.z;
        if (diff > 0.0 && diff < stepL * 1.5 + 0.1) {
            vec2 e = min(uv, 1.0 - uv);
            float fade = smoothstep(0.0, 0.12, min(e.x, e.y));
            return vec4(texture2D(colortex0, uv).rgb, fade);
        }
    }
    return vec4(0.0);
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;
    vec3 vpos = toView(texcoord, depth);
    vec3 viewDir = normalize(vpos);
    float dist = depth < 1.0 ? length(vpos) : far;

    if (depth < 1.0) {
        vec3 data2 = texture2D(colortex2, texcoord).rgb;
        if (data2.b > 0.9) {
            vec3 n = normalize(texture2D(colortex1, texcoord).xyz * 2.0 - 1.0);
            vec3 rd = reflect(viewDir, n);
            float cosT = clamp(dot(-viewDir, n), 0.0, 1.0);
            float fres = clamp(0.02 + 0.98 * pow(1.0 - cosT, 5.0), 0.0, 1.0);
            fres = mix(fres, 1.0, 0.04);

            vec3 refl = skyFull(rd) * smoothstep(0.25, 0.95, data2.g);
#ifdef SSR
            vec4 hit = traceSSR(vpos, rd);
            refl = mix(refl, hit.rgb, hit.a);
#endif
            vec3 L = normalize(shadowLightPosition);
            float glint = pow(max(dot(rd, L), 0.0), 600.0);
            refl += lightCol * glint * 6.0 * smoothstep(0.5, 0.95, data2.g);

            color = mix(color, refl, fres);
        }
    }

    if (isEyeInWater == 1) {
        float t = 1.0 - exp(-dist * 0.11);
        vec3 deep = (ambCol * vec3(0.05, 0.45, 0.75) + vec3(0.002, 0.012, 0.02)) * 0.8;
        color = mix(color * vec3(0.55, 0.85, 1.0), deep, t);
    } else if (depth < 1.0) {
        vec3 up = normalize(upPosition);
        vec3 hd = viewDir - up * dot(viewDir, up) * 0.85;
        vec3 fogCol = skyBase(normalize(hd));
        float edge = 1.0 - exp(-pow(dist / (far * 0.9), 4.0) * 2.5);
        float haze = (1.0 - exp(-dist * (0.0028 + rainStrength * 0.012))) * 0.55;
        color = mix(color, fogCol, clamp(edge + haze, 0.0, 1.0));
    }

/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);
}
