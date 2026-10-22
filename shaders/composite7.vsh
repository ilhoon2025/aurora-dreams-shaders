#version 120
#include "/lib/daylight.glsl"

varying vec2 texcoord;
varying vec3 lightCol;
varying vec3 ambCol;
varying vec3 gndCol;

void main() {
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0.st;
    computeLight(lightCol, ambCol, gndCol);
}
