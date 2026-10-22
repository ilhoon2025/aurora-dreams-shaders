// Time-of-day lighting colours. Requires uniforms declared below.
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float rainStrength;

float sunHeight() {
    return dot(normalize(sunPosition), normalize(upPosition));
}

void computeLight(out vec3 lightCol, out vec3 ambCol, out vec3 gndCol) {
    float sh = sunHeight();

    float warm = pow(1.0 - smoothstep(0.0, 0.5, sh), 1.6);
    vec3 sunC = mix(vec3(1.0, 0.92, 0.80), vec3(1.0, 0.40, 0.12), warm);
    float sunI = smoothstep(-0.03, 0.12, sh) * 2.8;
    vec3 moonC = vec3(0.40, 0.55, 1.0) * 0.42 * smoothstep(-0.03, 0.12, -sh);
    lightCol = (sunC * sunI + moonC) * mix(1.0, 0.18, rainStrength);

    float day = smoothstep(-0.12, 0.22, sh);
    vec3 ambD = pow(vec3(0.58, 0.74, 1.0), vec3(2.2)) * 1.25;
    vec3 ambN = pow(vec3(0.22, 0.32, 0.62), vec3(2.2)) * 0.5;
    float sunset = 1.0 - smoothstep(0.0, 0.35, abs(sh));
    ambCol = mix(ambN, ambD, day);
    ambCol = mix(ambCol, pow(vec3(1.0, 0.62, 0.66), vec3(2.2)) * 0.9, sunset * 0.5);
    ambCol *= mix(1.0, 0.55, rainStrength);
    gndCol = ambCol * vec3(0.50, 0.46, 0.42);
}
