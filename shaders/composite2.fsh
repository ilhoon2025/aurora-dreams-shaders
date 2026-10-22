#version 120
// Bloom, horizontal pass (bright-pass + gaussian) -> colortex3
uniform sampler2D colortex0;
uniform float viewWidth;

varying vec2 texcoord;

vec3 bright(vec2 uv) {
    vec3 s = texture2D(colortex0, uv).rgb;
    float l = dot(s, vec3(0.333));
    return s * clamp((l - 1.0) / 1.6, 0.0, 1.0) + s * 0.05;
}

void main() {
    float px = 1.0 / viewWidth;
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = exp(-float(i * i) / 18.0);
        sum += bright(texcoord + vec2(float(i) * px * 3.0, 0.0)) * w;
        wsum += w;
    }
/* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(sum / wsum, 1.0);
}
