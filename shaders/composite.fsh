#version 120
// Emitter pass 1/5: extract coloured light sources (torches, lanterns, lava, ores ...).
// colortex3 = (emitted radiance rgb, view distance of the pixel)
#include "/lib/settings.glsl"

/*
const int colortex0Format = RGB16F;
const int colortex3Format = RGBA16F;
const int colortex4Format = RGBA16F;
*/

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform float far;

varying vec2 texcoord;

void main() {
    float depth = texture2D(depthtex0, texcoord).r;
    vec3 E = vec3(0.0);
    float D = far;
#ifdef EMITTER_LIGHT
    if (depth < 1.0) {
        vec4 p = gbufferProjectionInverse * vec4(vec3(texcoord, depth) * 2.0 - 1.0, 1.0);
        D = length(p.xyz / p.w);
        float flag = texture2D(colortex2, texcoord).b;
        if (abs(flag - 0.65) < 0.05 || abs(flag - 0.8) < 0.05) {
            vec3 tex = texture2D(colortex0, texcoord).rgb;
            float maxc = max(tex.r, max(tex.g, tex.b));
            float chroma = maxc - min(tex.r, min(tex.g, tex.b));
            vec3 lin = pow(tex, vec3(2.2));
            if (flag < 0.7) {
                E = lin * smoothstep(0.6, 0.85, maxc) * 6.0;
            } else {
                float mask = max(smoothstep(0.10, 0.28, chroma), smoothstep(0.65, 0.88, maxc));
                E = mix(vec3(dot(lin, vec3(0.333))), lin, 1.5) * mask * 3.0;
            }
        }
    }
#endif
/* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(E, D);
}
