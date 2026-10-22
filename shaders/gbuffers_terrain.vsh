#version 120
#include "/lib/settings.glsl"
#include "/lib/wave.glsl"

attribute vec4 mc_Entity;
attribute vec2 mc_midTexCoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;
varying float foliage;

void main() {
    texcoord = gl_MultiTexCoord0.st;
    lmcoord = clamp(((gl_TextureMatrix[1] * gl_MultiTexCoord1).st - 0.03125) * 1.0667, 0.0, 1.0);
    glcolor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
    foliage = (mc_Entity.x == 10000.0 || mc_Entity.x == 10001.0) ? 0.25 : 0.0;

    vec4 pos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

#ifdef WAVING
    float isTop = float(texcoord.t < mc_midTexCoord.t);
    pos.xyz += foliageWave(pos.xyz + cameraPosition, mc_Entity.x, isTop);
#endif

    gl_Position = gl_ProjectionMatrix * (gbufferModelView * pos);
}
