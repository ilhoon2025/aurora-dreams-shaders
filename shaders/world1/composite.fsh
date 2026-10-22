#version 120
// The End: pale violet ambient lighting
#include "/lib/settings.glsl"

/*
const int colortex0Format = RGB16F;
const int colortex3Format = RGB16F;
const int colortex4Format = RGB16F;
*/

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
    float k = 0.7 + 0.3 * n.y;
    vec3 amb = vec3(0.62, 0.5, 1.0) * 0.5 * k;
    vec3 bl = vec3(1.0, 0.6, 0.3) * pow(d2.x, 3.2) * 2.4;
    gl_FragData[0] = vec4(albedo * (amb + bl), 1.0);
}
