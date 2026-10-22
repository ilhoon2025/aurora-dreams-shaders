#version 120
#include "/lib/settings.glsl"

const int shadowMapResolution = SHADOW_RES;
const float shadowDistance = SHADOW_DIST;

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 c = texture2D(texture, texcoord) * glcolor;
    if (c.a < 0.1) discard;
    gl_FragData[0] = c;
}
