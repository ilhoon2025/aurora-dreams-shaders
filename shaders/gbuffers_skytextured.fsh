#version 120
// Sun and moon discs: written as linear HDR so bloom picks them up.

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 c = texture2D(texture, texcoord) * glcolor;
    c.rgb = pow(c.rgb, vec3(2.2)) * 3.2;

/* DRAWBUFFERS:0 */
    gl_FragData[0] = c;
}
