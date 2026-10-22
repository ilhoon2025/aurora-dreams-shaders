#version 120
#include "/lib/settings.glsl"
#include "/lib/sky.glsl"

uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;

varying vec4 starData;

void main() {
    if (starData.a > 0.5) discard; // procedural stars replace vanilla ones

    vec4 p = gbufferProjectionInverse * vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
    vec3 dir = normalize(p.xyz / p.w);

/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(skyFull(dir), 1.0);
}
