#version 120
#include "/lib/settings.glsl"

attribute vec4 mc_Entity;
attribute vec2 mc_midTexCoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;

void main() {
    texcoord = gl_MultiTexCoord0.st;
    lmcoord = clamp(((gl_TextureMatrix[1] * gl_MultiTexCoord1).st - 0.03125) * 1.0667, 0.0, 1.0);
    glcolor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);

    vec4 pos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

#ifdef WAVING
    float amp = 0.0;
    if (mc_Entity.x == 10000.0) {
        amp = 0.045;
    } else if (mc_Entity.x == 10001.0 && texcoord.t < mc_midTexCoord.t) {
        amp = 0.085;
    }
    if (amp > 0.0) {
        amp *= 1.0 + rainStrength * 1.5;
        vec3 wp = pos.xyz + cameraPosition;
        float t = frameTimeCounter;
        pos.x += (sin(t * 1.7 + wp.x * 0.9 + wp.z * 0.6) + 0.4 * sin(t * 3.1 + wp.z * 1.7 + wp.y * 0.8)) * amp;
        pos.z += (cos(t * 1.4 + wp.z * 0.8 + wp.x * 0.5) + 0.4 * cos(t * 2.7 + wp.x * 1.6 + wp.y * 0.7)) * amp;
        if (mc_Entity.x == 10000.0) pos.y += sin(t * 2.0 + wp.x * 1.1 + wp.z * 1.3) * amp * 0.5;
    }
#endif

    gl_Position = gl_ProjectionMatrix * (gbufferModelView * pos);
}
