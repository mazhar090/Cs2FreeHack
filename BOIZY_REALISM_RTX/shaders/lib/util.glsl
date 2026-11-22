#ifndef UTIL_GLSL
#define UTIL_GLSL

// ---------- shared uniforms ----------
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;
uniform mat4 shadowModelView, shadowProjection;
uniform vec3 cameraPosition, previousCameraPosition;
uniform vec3 sunPosition, moonPosition, upPosition, shadowLightPosition;
uniform float frameTimeCounter, rainStrength, wetness, thunderStrength;
uniform float viewWidth, viewHeight, near, far;
uniform int frameCounter, isEyeInWater;

// ---------- noise ----------
float hash12(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p){
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}
float ign(vec2 c){ // interleaved gradient noise
    return 0.25 + 0.75 * fract(52.9829189 * fract(dot(c, vec2(0.06711056, 0.00583715))));
}
float vnoise2(vec2 p){
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float fbm2(vec2 p){
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++){ s += a * vnoise2(p); p *= 2.03; a *= 0.5; }
    return s;
}
float vnoise3(vec3 p){
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = hash13(i);
    float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
    float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
    float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
    float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
    float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
    float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
    float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
    return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
               mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}
float fbm3(vec3 p){
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 3; i++){ s += a * vnoise3(p); p *= 2.02; a *= 0.5; }
    return s;
}

// ---------- normal encoding (octahedral) ----------
vec2 encodeNormal(vec3 n){
    n /= abs(n.x) + abs(n.y) + abs(n.z);
    vec2 res = n.xy;
    if (n.z < 0.0) res = (1.0 - abs(res.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return res;
}
vec3 decodeNormal(vec2 e){
    vec3 n = vec3(e, 1.0 - abs(e.x) - abs(e.y));
    float t = max(-n.z, 0.0);
    n.xy -= vec2(n.x >= 0.0 ? t : -t, n.y >= 0.0 ? t : -t);
    return normalize(n);
}

// ---------- position helpers ----------
float linZ(float depth){
    return (2.0 * near * far) / (far + near - (depth * 2.0 - 1.0) * (far - near));
}
vec3 getViewPos(vec2 uv, float depth){
    vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 vp = gbufferProjectionInverse * ndc;
    return vp.xyz / vp.w;
}
vec3 getPlayerPos(vec2 uv, float depth){
    return (gbufferModelViewInverse * vec4(getViewPos(uv, depth), 1.0)).xyz;
}
vec2 screenUV(vec3 vpos){
    vec4 cp = gbufferProjection * vec4(vpos, 1.0);
    return (cp.xy / cp.w) * 0.5 + 0.5;
}

// ---------- shadow distortion ----------
#define SHADOW_DISTORTION 0.85
vec2 distortClip(vec2 p){
    float d = length(p);
    return p * (1.0 + SHADOW_DISTORTION * d * d) / (1.0 + SHADOW_DISTORTION);
}

#endif
