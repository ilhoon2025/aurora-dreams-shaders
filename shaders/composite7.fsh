#version 120
// Pass 3: screen-space god rays toward the sun / moon
#include "/lib/settings.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjection;
uniform vec3 shadowLightPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;

varying vec2 texcoord;
varying vec3 lightCol;
varying vec3 ambCol;
varying vec3 gndCol;

float ign(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
#ifdef GODRAYS
    vec4 sp = gbufferProjection * vec4(shadowLightPosition, 1.0);
    if (sp.w > 0.0 && isEyeInWater == 0) {
        vec2 suv = sp.xy / sp.w * 0.5 + 0.5;
        vec2 delta = suv - texcoord;
        const int N = 16;
        vec2 stepv = delta / float(N) * 0.95;
        vec2 uv = texcoord + stepv * ign(gl_FragCoord.xy);
        float acc = 0.0;
        float w = 1.0;
        float wsum = 0.0;
        for (int i = 0; i < N; i++) {
            uv += stepv;
            if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
                acc += step(1.0, texture2D(depthtex0, uv).r) * w;
            }
            wsum += w;
            w *= 0.94;
        }
        acc /= wsum;
        vec2 ad = delta * vec2(viewWidth / viewHeight, 1.0);
        float falloff = 1.0 / (1.0 + dot(ad, ad) * 6.0);
        color += lightCol * acc * falloff * 0.22 * GODRAYS_STRENGTH;
    }
#endif
#ifdef LENS_FLARE
    vec4 fp = gbufferProjection * vec4(shadowLightPosition, 1.0);
    if (fp.w > 0.0 && isEyeInWater == 0) {
        vec2 fuv = fp.xy / fp.w * 0.5 + 0.5;
        // how much of the light source is visible (not behind terrain)
        float vis = 0.0;
        vec2 vo = vec2(0.012, 0.012 * viewWidth / viewHeight);
        for (int i = 0; i < 5; i++) {
            vec2 o = (i == 0) ? vec2(0.0) : vec2(i == 1 || i == 3 ? 1.0 : -1.0, i < 3 ? 1.0 : -1.0) * vo;
            vec2 q = fuv + o;
            if (q.x > 0.0 && q.x < 1.0 && q.y > 0.0 && q.y < 1.0) vis += step(1.0, texture2D(depthtex0, q).r) * 0.2;
        }
        vec2 asp = vec2(viewWidth / viewHeight, 1.0);
        float edge = 1.0 - clamp(length((fuv - 0.5) * 1.6), 0.0, 1.0);
        vec2 toC = vec2(0.5) - fuv;
        vec3 flare = vec3(0.0);
        // ghosts along the line through the screen centre
        for (int k = 1; k <= 4; k++) {
            float fk = float(k);
            vec2 gp = fuv + toC * (0.55 * fk);
            float r = 0.025 + 0.018 * fk;
            float d = length((texcoord - gp) * asp);
            vec3 tint = mix(vec3(1.0, 0.6, 0.3), vec3(0.3, 0.6, 1.0), fk / 4.0);
            flare += tint * (smoothstep(r, r * 0.55, d) * 0.10 + smoothstep(r * 1.5, r * 0.5, d) * 0.04) / (0.6 + 0.3 * fk);
        }
        // anamorphic streak
        float dy = abs(texcoord.y - fuv.y) * 70.0;
        float dx = abs(texcoord.x - fuv.x) * 2.2;
        flare += vec3(0.35, 0.55, 1.0) * exp(-dy) * exp(-dx) * 0.45;
        color += flare * lightCol * vis * edge * 0.55;
    }
#endif
/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);
}
