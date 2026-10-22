#version 120
#include "/lib/settings.glsl"
#include "/lib/wave.glsl"
#include "/lib/shadow.glsl"

attribute vec4 mc_Entity;
attribute vec2 mc_midTexCoord;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    texcoord = gl_MultiTexCoord0.st;
    glcolor = gl_Color;

    vec4 pos = shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
#ifdef WAVING
    float isTop = float(texcoord.t < mc_midTexCoord.t);
    pos.xyz += foliageWave(pos.xyz + cameraPosition, mc_Entity.x, isTop);
#endif
    gl_Position = gl_ProjectionMatrix * (shadowModelView * pos);
    gl_Position.xy = distortShadow(gl_Position.xy);
    gl_Position.z *= 0.5;
}
