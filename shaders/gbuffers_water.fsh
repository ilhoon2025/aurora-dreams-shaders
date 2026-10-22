#version 120
#include "/lib/settings.glsl"

uniform sampler2D texture;
uniform mat4 gbufferModelView;
uniform float frameTimeCounter;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec3 worldNormal;
varying vec3 worldPos;
varying float isWater;

float waveH(vec2 p) {
    float t = frameTimeCounter;
    float h = 0.0;
    h += sin(p.x * 1.1 + t * 1.3 + sin(p.y * 0.7 + t * 0.4)) * 0.50;
    h += sin((p.x + p.y) * 1.9 - t * 1.9) * 0.25;
    h += sin(p.y * 3.1 + t * 2.3 + p.x * 0.5) * 0.12;
    h += sin((p.x - p.y * 1.3) * 5.3 + t * 3.1) * 0.05;
    return h * 0.17 * WATER_WAVE;
}

void main() {
    vec4 tex = texture2D(texture, texcoord) * glcolor;

    vec4 outColor = tex;
    vec3 outNormal = normalize(normal);
    float flag = 0.0;

    if (isWater > 0.5) {
        flag = 1.0;
        float lum = dot(tex.rgb, vec3(0.333));
        vec3 base = vec3(0.03, 0.26, 0.36);
        outColor = vec4(mix(base, tex.rgb * vec3(0.45, 0.9, 1.0), 0.3) * (0.8 + lum * 0.4), 0.64);

        if (worldNormal.y > 0.5) {
            vec2 p = worldPos.xz;
            float e = 0.04;
            float h0 = waveH(p);
            float hx = (waveH(p + vec2(e, 0.0)) - h0) / e;
            float hz = (waveH(p + vec2(0.0, e)) - h0) / e;
            vec3 wn = normalize(vec3(-hx, 1.0, -hz));
            outNormal = normalize(mat3(gbufferModelView) * wn);
        }
    }

/* DRAWBUFFERS:012 */
    gl_FragData[0] = outColor;
    gl_FragData[1] = vec4(outNormal * 0.5 + 0.5, 1.0);   // alpha 1: overwrite instead of blending
    gl_FragData[2] = vec4(lmcoord, flag, 1.0);
}
