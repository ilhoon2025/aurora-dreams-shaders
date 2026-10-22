#version 120

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    lmcoord = clamp(((gl_TextureMatrix[1] * gl_MultiTexCoord1).st - 0.03125) * 1.0667, 0.0, 1.0);
    glcolor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
