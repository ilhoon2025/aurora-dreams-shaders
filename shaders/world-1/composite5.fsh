#version 120
// Nether: no sun, warm ember ambient lighting
#include "/lib/settings.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;

varying vec2 texcoord;

void main() {
    vec4 tex = texture2D(colortex0, texcoord);
    float depth = texture2D(depthtex0, texcoord).r;
/* DRAWBUFFERS:0 */
    if (depth >= 1.0) { gl_FragData[0] = tex; return; }

    vec4 d2 = texture2D(colortex2, texcoord);
    vec3 albedo = pow(tex.rgb, vec3(2.2));
    if (abs(d2.b - 0.5) < 0.1) { gl_FragData[0] = vec4(albedo * 2.0, 1.0); return; }

    vec3 n = normalize(texture2D(colortex1, texcoord).xyz * 2.0 - 1.0);
    float k = 0.75 + 0.25 * n.y;
    vec3 amb = vec3(1.0, 0.42, 0.28) * 0.55 * k;
    vec3 bl = vec3(1.0, 0.55, 0.22) * pow(d2.x, 3.2) * 2.6;
    gl_FragData[0] = vec4(albedo * (amb + bl), 1.0);
}
