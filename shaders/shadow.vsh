#version 120
#include "/lib/shadow.glsl"

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    texcoord = gl_MultiTexCoord0.st;
    glcolor = gl_Color;
    gl_Position = ftransform();
    gl_Position.xy = distortShadow(gl_Position.xy);
    gl_Position.z *= 0.5;
}
