#version 120
// Clouds are shaded by the deferred lighting pass (sunset-tinted, moonlit at night).

uniform sampler2D texture;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;

void main() {
    vec4 c = texture2D(texture, texcoord);
    if (c.a < 0.02) discard;

/* DRAWBUFFERS:012 */
    gl_FragData[0] = vec4(vec3(0.97, 0.98, 1.0), c.a * glcolor.a * 0.82);
    gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5, 1.0);
    gl_FragData[2] = vec4(0.0, 1.0, 0.0, 1.0);
}
