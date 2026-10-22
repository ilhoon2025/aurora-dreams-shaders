#version 120
// Bloom, vertical pass
uniform sampler2D colortex3;
uniform float viewHeight;

varying vec2 texcoord;

void main() {
    float px = 1.0 / viewHeight;
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = exp(-float(i * i) / 18.0);
        sum += texture2D(colortex3, texcoord + vec2(0.0, float(i) * px * 3.0)).rgb * w;
        wsum += w;
    }
/* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(sum / wsum, 1.0);
}
