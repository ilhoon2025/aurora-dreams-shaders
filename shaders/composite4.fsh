#version 120
// Bloom blur (composite4)
uniform sampler2D colortex3;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

vec3 tap(vec2 uv) {
    vec3 s = texture2D(colortex3, uv).rgb;

    return s;
}

void main() {
    vec2 px = vec2(0.0, 1.0) / vec2(viewWidth, viewHeight) * 3.0;
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -7; i <= 7; i++) {
        float w = exp(-float(i * i) / 22.0);
        sum += tap(texcoord + px * float(i)) * w;
        wsum += w;
    }
/* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(sum / wsum, 1.0);
}
