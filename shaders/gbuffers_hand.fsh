#version 120
// Held torches / lanterns / glowstone glow like placed ones.

uniform sampler2D texture;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;

void main() {
    vec4 c = texture2D(texture, texcoord) * glcolor;
    if (c.a < 0.02) discard;
    float flag = (heldBlockLightValue + heldBlockLightValue2 > 0) ? 0.65 : 0.0;

/* DRAWBUFFERS:012 */
    gl_FragData[0] = c;
    gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5, 1.0);
    gl_FragData[2] = vec4(lmcoord, flag, 1.0);
}
