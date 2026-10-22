#version 120
// Pass 8: bloom composite, ACES tonemap, colour grade -> sRGB (LDR)
#include "/lib/settings.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;

varying vec2 texcoord;

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main() {
    vec2 c = texcoord - 0.5;
    float ca = dot(c, c) * 0.005;
    vec3 color;
    color.r = texture2D(colortex0, texcoord - c * ca).r;
    color.g = texture2D(colortex0, texcoord).g;
    color.b = texture2D(colortex0, texcoord + c * ca).b;

    vec3 bloom = texture2D(colortex3, texcoord).rgb * 0.5 + texture2D(colortex4, texcoord).rgb * 0.9;
    color += bloom * BLOOM_STRENGTH * 0.45;
    color *= EXPOSURE;

    color = aces(color);

    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color *= mix(vec3(0.93, 0.99, 1.09), vec3(1.08, 1.0, 0.92), smoothstep(0.15, 0.85, lum));
    color = mix(vec3(lum), color, SATURATION);
    vec3 curved = color * color * (3.0 - 2.0 * color);
    color = mix(color, curved, 0.35 * CONTRAST);

    color = pow(clamp(color, 0.0, 1.0), vec3(1.0 / 2.2));
/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);
}
