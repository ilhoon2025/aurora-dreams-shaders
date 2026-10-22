#version 120
#include "/lib/settings.glsl"
#include "/lib/wave.glsl"

uniform sampler2D texture;
uniform mat4 gbufferModelView;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec3 worldNormal;
varying vec3 worldPos;
varying float isWater;

void main() {
    vec4 tex = texture2D(texture, texcoord) * glcolor;

    vec4 outColor = tex;
    vec3 outNormal = normalize(normal);
    float flag = 0.0;

    if (isWater > 0.5) {
        flag = 1.0;
        float lum = dot(tex.rgb, vec3(0.333));
        // mostly clear: depth tint and reflections are added in composite1
        outColor = vec4(vec3(0.05, 0.40, 0.55) * (0.7 + lum * 0.6), 0.16);

        if (worldNormal.y > 0.5) {
            vec2 p = worldPos.xz;
            float e = 0.05;
            float h0 = waveH(p);
            float hx = (waveH(p + vec2(e, 0.0)) - h0) / e;
            float hz = (waveH(p + vec2(0.0, e)) - h0) / e;
            vec3 wn = normalize(vec3(-hx * 0.16 * WATER_WAVE, 1.0, -hz * 0.16 * WATER_WAVE));
            outNormal = normalize(mat3(gbufferModelView) * wn);
        }
    }

/* DRAWBUFFERS:012 */
    gl_FragData[0] = outColor;
    gl_FragData[1] = vec4(outNormal * 0.5 + 0.5, 1.0);   // alpha 1: overwrite instead of blending
    gl_FragData[2] = vec4(lmcoord, flag, 1.0);
}
