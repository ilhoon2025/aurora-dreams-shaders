#version 120
// Emitter pass 4: depth-aware blur (H, stage 2) spreading light colour across nearby surfaces
#include "/lib/settings.glsl"

uniform sampler2D colortex3;
uniform mat4 gbufferProjection;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

void main() {
    vec4 c = texture2D(colortex3, texcoord);
#ifdef EMITTER_LIGHT
    float D = c.a;
    float ppu = 0.5 * viewHeight * gbufferProjection[1][1] / max(D, 0.5); // pixels per block here
    float stride = clamp(0.45 * ppu, 1.0, 12.0);
    vec2 dir = vec2(1.0, 0.0) / vec2(viewWidth, viewHeight) * stride;
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        vec4 s = texture2D(colortex3, texcoord + dir * float(i));
        float g = exp(-float(i * i) / 22.0);
        sum += s.rgb * g * exp(-abs(s.a - D) * 0.9);
        wsum += g;
    }
    c = vec4(sum / wsum, D);
#endif
/* DRAWBUFFERS:4 */
    gl_FragData[0] = c;
}
