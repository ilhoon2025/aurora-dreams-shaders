#version 120
// Bloom composite, ACES tonemap, colour grade, vignette, film grain
#include "/lib/settings.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform float frameTimeCounter;

varying vec2 texcoord;

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

float ign(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

void main() {
    vec2 c = texcoord - 0.5;
    float ca = dot(c, c) * 0.006;
    vec3 color;
    color.r = texture2D(colortex0, texcoord - c * ca).r;
    color.g = texture2D(colortex0, texcoord).g;
    color.b = texture2D(colortex0, texcoord + c * ca).b;

    color += texture2D(colortex3, texcoord).rgb * BLOOM_STRENGTH * 0.55;
    color *= EXPOSURE;

    color = aces(color);

    // colour grade: cool shadows, warm highlights, vibrance
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color *= mix(vec3(0.94, 0.99, 1.08), vec3(1.07, 1.0, 0.93), smoothstep(0.15, 0.85, lum));
    color = mix(vec3(lum), color, SATURATION);
    color = color * color * (3.0 - 2.0 * color) * 0.35 + color * 0.65; // gentle S-curve

    color = pow(color, vec3(1.0 / 2.2));

    float vig = 1.0 - dot(c, c) * VIGNETTE * 2.2;
    color *= clamp(vig, 0.0, 1.0);

    color += (ign(gl_FragCoord.xy + fract(frameTimeCounter) * 100.0) - 0.5) / 255.0 * 1.5;

    gl_FragColor = vec4(color, 1.0);
}
