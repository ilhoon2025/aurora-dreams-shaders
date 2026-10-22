#version 120

uniform sampler2D texture;
uniform vec4 entityColor;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;

void main() {
    vec4 c = texture2D(texture, texcoord) * glcolor;
    if (c.a < 0.02) discard;
    c.rgb = mix(c.rgb, entityColor.rgb, entityColor.a);

/* DRAWBUFFERS:012 */
    gl_FragData[0] = c;
    gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5, 1.0);
    gl_FragData[2] = vec4(lmcoord, 0.0, 1.0);
}
