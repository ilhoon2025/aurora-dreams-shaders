// Shadow-map space warp: more resolution near the player.
vec2 distortShadow(vec2 p) {
    float d = length(p) * 0.85 + 0.15;
    return p / d;
}

float shadowDistortFactor(vec2 p) {
    return length(p) * 0.85 + 0.15;
}
