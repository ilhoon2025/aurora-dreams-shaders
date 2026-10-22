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
        const int N = 28;
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
            w *= 0.965;
        }
        acc /= wsum;
        vec2 ad = delta * vec2(viewWidth / viewHeight, 1.0);
        float falloff = 1.0 / (1.0 + dot(ad, ad) * 6.0);
        color += lightCol * acc * falloff * 0.22 * GODRAYS_STRENGTH;
    }
#endif
/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);
}
