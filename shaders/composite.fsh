#version 120
// Pass 1: deferred lighting (sun/moon shadows, sky ambient, torch light, SSAO)
#include "/lib/settings.glsl"

const int shadowMapResolution = SHADOW_RES;
const float shadowDistance = SHADOW_DIST;
const float sunPathRotation = -25.0;
/*
const int colortex0Format = RGB16F;
const int colortex3Format = RGB16F;
const int colortex4Format = RGB16F;
*/

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform vec3 upPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int heldItemId;
uniform int heldItemId2;

varying vec2 texcoord;
varying vec3 lightCol;
varying vec3 ambCol;
varying vec3 gndCol;

#include "/lib/shadow.glsl"

vec3 toView(vec2 uv, float d) {
    vec4 p = gbufferProjectionInverse * vec4(vec3(uv, d) * 2.0 - 1.0, 1.0);
    return p.xyz / p.w;
}

float ign(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

vec2 vogel(int i, int n, float rot) {
    float r = sqrt((float(i) + 0.5) / float(n));
    float th = float(i) * 2.399963 + rot;
    return r * vec2(cos(th), sin(th));
}

float getShadow(vec3 feet, vec3 worldN, float ndl) {
    vec3 off = worldN * (0.10 + 0.22 * (1.0 - ndl));
    vec4 sp = shadowProjection * (shadowModelView * vec4(feet + off, 1.0));
    float d = shadowDistortFactor(sp.xy);
    sp.xy /= d;
    sp.z *= 0.5;
    sp.xyz = sp.xyz * 0.5 + 0.5;
    if (sp.x < 0.0 || sp.x > 1.0 || sp.y < 0.0 || sp.y > 1.0) return 1.0;

    float bias = (0.0005 + 0.0016 * (1.0 - ndl)) * (0.5 + 2.0 * d * d) * (2048.0 / float(SHADOW_RES));
    float rot = ign(gl_FragCoord.xy) * 6.2831853;
    float rad = (2.2 / float(SHADOW_RES)) * (0.6 + d);
    float s = 0.0;
    for (int i = 0; i < 10; i++) {
        vec2 o = vogel(i, 10, rot) * rad;
        s += step(sp.z - bias, texture2D(shadowtex1, sp.xy + o).r);
    }
    return s / 10.0;
}

float ssao(vec3 vpos, vec3 n) {
    float rot = ign(gl_FragCoord.xy + 17.0) * 6.2831853;
    float r = clamp(0.5 * gbufferProjection[1][1] / max(-vpos.z, 0.5) * 0.5, 0.003, 0.05);
    vec2 asp = vec2(viewHeight / viewWidth, 1.0);
    float occ = 0.0;
    for (int i = 0; i < 6; i++) {
        float a = rot + float(i) * 2.39996;
        float rr = (float(i) + 1.0) / 6.0;
        vec2 suv = texcoord + vec2(cos(a), sin(a)) * r * rr * asp;
        float sd = texture2D(depthtex0, suv).r;
        if (sd >= 1.0) continue;
        vec3 dv = toView(suv, sd) - vpos;
        float len = length(dv);
        occ += max(dot(n, dv / len) - 0.12, 0.0) / (1.0 + len * len * 1.5);
    }
    return clamp(1.0 - occ / 6.0 * 2.4, 0.0, 1.0);
}


// colour of the light a held item gives off (ids come from item.properties)
vec3 heldColor(int id) {
    if (id == 10011) return vec3(0.12, 0.72, 1.00);  // soul torch / soul lantern
    if (id == 10013) return vec3(1.00, 0.10, 0.05);  // redstone torch
    if (id == 10014) return vec3(1.00, 0.78, 0.30);  // glowstone, shroomlight, ochre froglight
    if (id == 10015) return vec3(0.45, 0.92, 1.00);  // sea lantern, pearlescent froglight
    if (id == 10016) return vec3(0.35, 1.00, 0.45);  // verdant froglight
    if (id == 10017) return vec3(0.30, 1.00, 0.65);  // copper torch / lantern
    return vec3(1.00, 0.52, 0.20);                   // torch, lantern, unknown
}

vec3 handLight(vec3 vpos, vec3 n, int level, int id, vec3 handPos) {
    if (level < 1) return vec3(0.0);
    float r = float(level) * 0.95;
    vec3 d = handPos - vpos;
    float dist = length(d);
    float att = clamp(1.0 - dist / r, 0.0, 1.0);
    att *= att;
    float diff = clamp(dot(n, d / dist) * 0.75 + 0.25, 0.0, 1.0);
    float flick = 1.0 + 0.06 * sin(frameTimeCounter * 12.0) + 0.04 * sin(frameTimeCounter * 23.0 + 1.7);
    return heldColor(id) * att * diff * (float(level) / 15.0) * 3.4 * flick;
}

void main() {
    vec4 tex = texture2D(colortex0, texcoord);
    float depth = texture2D(depthtex0, texcoord).r;

/* DRAWBUFFERS:0 */
    if (depth >= 1.0) {
        gl_FragData[0] = tex; // sky already HDR linear
        return;
    }

    vec4 data2 = texture2D(colortex2, texcoord);
    float flag = data2.b;

    // emissive / unlit objects
    if (abs(flag - 0.5) < 0.1) {
        gl_FragData[0] = vec4(pow(tex.rgb, vec3(2.2)) * 2.0, 1.0);
        return;
    }

    vec3 albedo = pow(tex.rgb, vec3(2.2));
    bool foliage = abs(flag - 0.25) < 0.1;
    vec3 n = normalize(texture2D(colortex1, texcoord).xyz * 2.0 - 1.0);
    if (foliage) n = normalize(mix(n, normalize(upPosition), 0.55));
    vec2 lm = data2.xy;

    vec3 vpos = toView(texcoord, depth);
    vec3 feet = (gbufferModelViewInverse * vec4(vpos, 1.0)).xyz;
    vec3 L = normalize(shadowLightPosition);
    float ndl = max(dot(n, L), 0.0);
    if (foliage) ndl = clamp((dot(n, L) + 0.35) / 1.35, 0.0, 1.0);
    vec3 worldN = mat3(gbufferModelViewInverse) * n;

    float shadow = 1.0;
    if (ndl > 0.0) {
        shadow = getShadow(feet, worldN, ndl);
        float fade = smoothstep(SHADOW_DIST * 0.8, SHADOW_DIST, length(feet));
        shadow = mix(shadow, smoothstep(0.85, 1.0, lm.y), fade);
    }

    float ao = 1.0;
#ifdef SSAO
    ao = ssao(vpos, n);
#endif

    float skyL = pow(lm.y, 2.2);
    float hemi = dot(n, normalize(upPosition)) * 0.5 + 0.5;
    vec3 sky = mix(gndCol, ambCol, hemi) * skyL;

    float bl = pow(lm.x, 3.6);
    vec3 blockLight = vec3(1.0, 0.50, 0.20) * bl * 2.4 * (1.0 + 0.04 * sin(frameTimeCounter * 9.0 + lm.x * 20.0));
    blockLight *= 1.0 - 0.6 * skyL * smoothstep(0.0, 1.5, dot(ambCol, vec3(0.33)));

    vec3 direct = lightCol * ndl * shadow;
    if (foliage) {
        // light shining through leaves and grass blades
        float back = pow(clamp(dot(normalize(vpos), L), 0.0, 1.0), 4.0);
        direct += lightCol * shadow * back * 0.9 * vec3(0.75, 1.0, 0.35);
        albedo *= vec3(1.04, 1.07, 0.93);
    }
    vec3 hand = handLight(vpos, n, heldBlockLightValue, heldItemId, vec3(0.35, -0.30, -0.25))
              + handLight(vpos, n, heldBlockLightValue2, heldItemId2, vec3(-0.35, -0.30, -0.25));

    vec3 light = direct + (sky + blockLight + hand) * ao + vec3(0.012, 0.014, 0.02) * ao;
    vec3 color = albedo * light;

    // glowing blocks: torches, lanterns, lava ... (flag 0.65) and ore flecks in their own colour (flag 0.8)
    float maxc = max(tex.r, max(tex.g, tex.b));
    float chroma = maxc - min(tex.r, min(tex.g, tex.b));
    if (abs(flag - 0.65) < 0.05) {
        float mask = smoothstep(0.6, 0.85, maxc);
        float flick = 1.0 + 0.07 * sin(frameTimeCounter * 11.0 + feet.x * 3.0 + feet.z * 5.0);
        color += albedo * mask * 4.5 * flick;
    } else if (abs(flag - 0.8) < 0.05) {
        float mask = max(smoothstep(0.10, 0.28, chroma), smoothstep(0.65, 0.88, maxc));
        float pulse = 0.85 + 0.15 * sin(frameTimeCounter * 2.2 + feet.x * 1.7 + feet.y * 2.3 + feet.z * 1.3);
        vec3 vivid = mix(vec3(dot(albedo, vec3(0.333))), albedo, 1.5);
        color += max(vivid, 0.0) * mask * 3.2 * pulse;
    }

    gl_FragData[0] = vec4(color, 1.0);
}
