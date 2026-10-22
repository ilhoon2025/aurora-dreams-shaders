#version 120
// Nether: ember fog
uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform float far;

varying vec2 texcoord;

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;
    vec4 p = gbufferProjectionInverse * vec4(vec3(texcoord, depth) * 2.0 - 1.0, 1.0);
    float dist = depth < 1.0 ? length(p.xyz / p.w) : far;
    color = mix(color, vec3(0.30, 0.06, 0.03), 1.0 - exp(-dist * 0.012));
/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);
}
