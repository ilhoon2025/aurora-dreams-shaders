#version 120
// Block outline, debug lines

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;

void main() {
/* DRAWBUFFERS:012 */
    gl_FragData[0] = glcolor;
    gl_FragData[1] = vec4(0.5, 0.5, 1.0, 1.0);
    gl_FragData[2] = vec4(0.0, 0.0, 0.5, 1.0);
}
