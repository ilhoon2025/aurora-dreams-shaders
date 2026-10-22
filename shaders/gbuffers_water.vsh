#version 120

attribute vec4 mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec3 worldNormal;
varying vec3 worldPos;
varying float isWater;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    lmcoord = clamp(((gl_TextureMatrix[1] * gl_MultiTexCoord1).st - 0.03125) * 1.0667, 0.0, 1.0);
    glcolor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
    worldNormal = mat3(gbufferModelViewInverse) * normal;
    isWater = float(mc_Entity.x == 10002.0);

    vec4 pos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
    worldPos = pos.xyz + cameraPosition;
    gl_Position = gl_ProjectionMatrix * (gbufferModelView * pos);
}
