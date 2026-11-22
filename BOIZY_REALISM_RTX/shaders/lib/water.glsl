#ifndef WATER_GLSL
#define WATER_GLSL
#include "/lib/util.glsl"

float waveHeight(vec2 p, float t){
    float h = 0.0;
    h += sin(dot(p, vec2(0.6, 0.8)) * 0.8 + t * 1.4) * 0.5;
    h += sin(dot(p, vec2(-0.9, 0.4)) * 1.3 + t * 1.1) * 0.30;
    h += vnoise2(p * 1.2 + t * vec2(0.5, 0.3)) * 0.60;
    h += vnoise2(p * 2.7 - t * vec2(0.4, 0.6)) * 0.25;
    h += sin(dot(p, vec2(0.2, -1.1)) * 2.1 + t * 2.0) * 0.12;
    return h * 0.25;
}

vec3 waterNormal(vec3 wPos, float t){
    vec2 p = wPos.xz;
    float e = 0.08;
    float h0 = waveHeight(p, t);
    float hx = waveHeight(p + vec2(e, 0.0), t);
    float hz = waveHeight(p + vec2(0.0, e), t);
    return normalize(vec3((h0 - hx) * 1.2, 0.15, (h0 - hz) * 1.2));
}

// classic animated caustics pattern
float caustic(vec2 p, float t){
    vec2 i = p;
    float c = 1.0;
    float inten = 0.005;
    for (int n = 0; n < 3; n++){
        float tt = t * (1.0 - 3.5 / float(n + 1));
        i = p + vec2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
        c += 1.0 / length(vec2(p.x / (sin(i.x + tt) / inten), p.y / (cos(i.y + tt) / inten)));
    }
    c /= 3.0;
    c = 1.17 - pow(c, 1.4);
    return clamp(pow(abs(c), 8.0), 0.0, 2.0);
}

float puddleMask(vec3 wPos, vec3 wNormal){
#ifdef PUDDLES
    if (wetness < 0.02 || wNormal.y < 0.75) return 0.0;
    float n = fbm2(wPos.xz * 0.5);
    float m = smoothstep(0.62 - 0.2 * wetness, 0.78 - 0.1 * wetness, n);
    return m * wetness * smoothstep(0.75, 0.95, wNormal.y);
#else
    return 0.0;
#endif
}

#endif
