#version 120
// Emitter pass 3: depth-aware blur (V, stage 1) spreading light colour across nearby surfaces
#include "/lib/settings.glsl"

uniform sampler2D colortex4;
uniform mat4 gbufferProjection;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

void main() {
    vec4 c = texture2D(colortex4, texcoord);
#ifdef EMITTER_LIGHT
    float D = c.a;
    float ppu = 0.5 * viewHeight * gbufferProjection[1][1] / max(D, 0.5); // pixels per block here
    float stride = clamp(0.1 * ppu, 1.0, 3.0);
    vec2 dir = vec2(0.0, 1.0) / vec2(viewWidth, viewHeight) * stride;
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -4; i <= 4; i++) {
        vec4 s = texture2D(colortex4, texcoord + dir * float(i));
        float g = exp(-float(i * i) / 9.0);
        sum += s.rgb * g * exp(-abs(s.a - D) * 0.9);
        wsum += g;
    }
    c = vec4(sum / wsum, D);
#endif
/* DRAWBUFFERS:3 */
    gl_FragData[0] = c;
}
