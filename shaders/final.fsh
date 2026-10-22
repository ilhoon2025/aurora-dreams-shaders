#version 120
// FXAA, vignette, film grain
#include "/lib/settings.glsl"

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

varying vec2 texcoord;

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float ign(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

vec3 fxaa(vec2 uv, vec2 px) {
    vec3 rgbNW = texture2D(colortex0, uv + vec2(-1.0, -1.0) * px).rgb;
    vec3 rgbNE = texture2D(colortex0, uv + vec2(1.0, -1.0) * px).rgb;
    vec3 rgbSW = texture2D(colortex0, uv + vec2(-1.0, 1.0) * px).rgb;
    vec3 rgbSE = texture2D(colortex0, uv + vec2(1.0, 1.0) * px).rgb;
    vec3 rgbM = texture2D(colortex0, uv).rgb;
    float lNW = luma(rgbNW), lNE = luma(rgbNE), lSW = luma(rgbSW), lSE = luma(rgbSE), lM = luma(rgbM);
    float lMin = min(lM, min(min(lNW, lNE), min(lSW, lSE)));
    float lMax = max(lM, max(max(lNW, lNE), max(lSW, lSE)));

    vec2 dir;
    dir.x = -((lNW + lNE) - (lSW + lSE));
    dir.y = ((lNW + lSW) - (lNE + lSE));
    float dirReduce = max((lNW + lNE + lSW + lSE) * 0.25 * 0.125, 1.0 / 128.0);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = clamp(dir * rcpDirMin, -8.0, 8.0) * px;

    vec3 rgbA = 0.5 * (texture2D(colortex0, uv + dir * (1.0 / 3.0 - 0.5)).rgb +
                       texture2D(colortex0, uv + dir * (2.0 / 3.0 - 0.5)).rgb);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (texture2D(colortex0, uv + dir * -0.5).rgb +
                                     texture2D(colortex0, uv + dir * 0.5).rgb);
    float lB = luma(rgbB);
    return (lB < lMin || lB > lMax) ? rgbA : rgbB;
}

void main() {
    vec2 px = 1.0 / vec2(viewWidth, viewHeight);
#ifdef FXAA
    vec3 color = fxaa(texcoord, px);
#else
    vec3 color = texture2D(colortex0, texcoord).rgb;
#endif

    vec2 c = texcoord - 0.5;
    color *= clamp(1.0 - dot(c, c) * VIGNETTE * 2.2, 0.0, 1.0);
    color += (ign(gl_FragCoord.xy + fract(frameTimeCounter) * 100.0) - 0.5) / 255.0 * 1.5;

    gl_FragColor = vec4(color, 1.0);
}
