#ifndef SKY_GLSL
#define SKY_GLSL
#include "/lib/util.glsl"

uniform vec3 fogColor;

vec3 sunDirWorld(){ return normalize(mat3(gbufferModelViewInverse) * shadowLightPosition); }
float sunHeight(){ return dot(normalize(sunPosition), normalize(upPosition)); }
float dayFactor(){ return smoothstep(-0.06, 0.18, sunHeight()); }

vec3 getSunColor(){
    float sh = sunHeight();
    float day = smoothstep(-0.04, 0.16, sh);
    float glow = exp(-abs(sh) * 5.0);
    vec3 dayC = vec3(1.0, 0.97, 0.90) * 2.6;
    vec3 setC = vec3(1.6, 0.50, 0.18) * 2.2;
    vec3 nightC = vec3(0.25, 0.33, 0.55) * 0.10;
    vec3 c = mix(nightC, dayC, day);
    c = mix(c, setC, glow * 0.85);
    c *= 1.0 - rainStrength * 0.65;
    return c;
}

vec3 getSkyAmbient(){
    float day = dayFactor();
    vec3 a = mix(vec3(0.010, 0.014, 0.026), vec3(0.22, 0.34, 0.60), day);
    a = mix(a, vec3(0.075, 0.085, 0.10), rainStrength * 0.85);
    return a;
}

vec3 skyBase(vec3 dir){
    float day = dayFactor();
    float sh = sunHeight();
    float glow = exp(-abs(sh) * 5.0);
    vec3 zen = mix(vec3(0.006, 0.009, 0.024), vec3(0.05, 0.14, 0.50), day);
    vec3 hor = mix(vec3(0.008, 0.010, 0.022), vec3(0.28, 0.44, 0.72), day);
    hor = mix(hor, vec3(0.40, 0.15, 0.06), glow * 0.8);
    zen = mix(zen, vec3(0.085, 0.095, 0.115), rainStrength * 0.85);
    hor = mix(hor, vec3(0.10, 0.11, 0.13), rainStrength * 0.85);
    float t = pow(clamp(dir.y, 0.0, 1.0), 0.5);
    vec3 sky = mix(hor, zen, t);
    if (dir.y < 0.0) sky = mix(hor, hor * 0.35, clamp(-dir.y * 3.0, 0.0, 1.0));
    vec3 sd = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    float g = max(dot(dir, sd), 0.0);
    sky += getSunColor() * 0.025 * pow(g, 4.0);
    sky += getSunColor() * 0.010 * pow(g, 32.0);
    return sky;
}

vec3 stars(vec3 dir, float nightF){
    vec3 p = dir * 250.0;
    vec3 id = floor(p);
    float h = hash13(id);
    vec3 f = fract(p) - 0.5;
    float star = smoothstep(0.25, 0.05, length(f)) * step(0.9965, h);
    star *= 0.6 + 0.4 * sin(frameTimeCounter * 3.0 + h * 40.0);
    return vec3(star) * nightF * (1.0 - rainStrength);
}

vec3 sunMoon(vec3 dir){
    vec3 c = vec3(0.0);
    vec3 sd = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 md = normalize(mat3(gbufferModelViewInverse) * moonPosition);
    float s = smoothstep(0.9995, 0.99985, dot(dir, sd));
    c += getSunColor() * s * 4.0;
    float m = smoothstep(0.99955, 0.99985, dot(dir, md));
    m *= 0.7 + 0.3 * vnoise2(dir.xz * 400.0 + 7.0);
    c += vec3(0.85, 0.90, 1.0) * m * 0.6;
    return c * (1.0 - rainStrength * 0.92);
}

// ---------- clouds ----------
float cloudDensity(vec3 p){
    p.xz += frameTimeCounter * vec2(8.0, 3.0);
    vec3 q = vec3(p.x, p.y * 3.0, p.z) * 0.004;
    float d = fbm3(q);
    float th = 1.0 - 0.45 * CLOUD_DENSITY;
    float c = smoothstep(th, th + 0.22, d);
    float h = clamp((p.y - 128.0) / 128.0, 0.0, 1.0);
    c *= smoothstep(0.0, 0.15, h) * (1.0 - smoothstep(0.7, 1.0, h));
    return c;
}

vec4 clouds2D(vec3 dir, vec3 camW){
    if (dir.y < 0.03) return vec4(0.0);
    float t = (200.0 - camW.y) / dir.y;
    if (t < 0.0) return vec4(0.0);
    vec3 p = camW + dir * t;
    float d = cloudDensity(p);
    if (d < 0.01) return vec4(0.0);
    float vis = 1.0 - 0.8 * cloudDensity(p + sunDirWorld() * 60.0);
    vec3 bright = getSunColor() * 0.6 + getSkyAmbient() * 2.0;
    vec3 dark = getSkyAmbient() * 0.55 + vec3(0.008);
    vec3 cCol = mix(dark, bright, vis);
    return vec4(cCol, d * 0.85 * smoothstep(0.03, 0.15, dir.y));
}

vec4 cloudsVol(vec3 dir, vec3 camW){
    if (dir.y < 0.02) return vec4(0.0);
    float t0 = (128.0 - camW.y) / dir.y;
    float t1 = (256.0 - camW.y) / dir.y;
    t0 = max(t0, 0.0);
    if (t1 <= t0) return vec4(0.0);
    float stepLen = (t1 - t0) / float(CLOUD_QUALITY);
    float dither = ign(gl_FragCoord.xy);
    vec3 sld = sunDirWorld();
    vec3 bright = getSunColor() * 0.55 + getSkyAmbient() * 2.0;
    vec3 dark = getSkyAmbient() * 0.50 + vec3(0.008);
    vec3 scat = vec3(0.0);
    float trans = 1.0;
    for (int i = 0; i < CLOUD_QUALITY; i++){
        vec3 p = camW + dir * (t0 + stepLen * (float(i) + dither));
        float d = cloudDensity(p);
        if (d > 0.01){
            float vis = exp(-max(0.0, cloudDensity(p + sld * 90.0)) * 2.2 - 0.15);
            vec3 cCol = mix(dark, bright, vis);
            float a = 1.0 - exp(-d * stepLen * 0.012);
            scat += cCol * a * trans;
            trans *= 1.0 - a;
            if (trans < 0.05) break;
        }
    }
    return vec4(scat, (1.0 - trans) * smoothstep(0.02, 0.10, dir.y));
}

vec3 aurora(vec3 dir){
#ifdef AURORA
    if (dir.y < 0.05) return vec3(0.0);
    float u = atan(dir.x, dir.z);
    float band = fbm2(vec2(u * 2.5 + frameTimeCounter * 0.02, dir.y * 6.0));
    float base = 0.15 + 0.25 * fbm2(vec2(u * 1.5 - frameTimeCounter * 0.015, 4.7));
    float i1 = smoothstep(base, base + 0.08, dir.y) * (1.0 - smoothstep(base + 0.2, base + 0.5, dir.y));
    float flick = 0.6 + 0.4 * sin(frameTimeCounter * 0.7 + u * 6.0);
    vec3 c = mix(vec3(0.05, 0.9, 0.35), vec3(0.15, 0.35, 0.9), band);
    return c * i1 * flick * 0.35;
#else
    return vec3(0.0);
#endif
}

float cloudShadowFactor(vec3 wPos){
#ifdef CLOUD_SHADOWS
    vec3 sld = sunDirWorld();
    float d = cloudDensity(wPos + sld * 150.0) * 0.7 + cloudDensity(wPos + sld * 300.0) * 0.5;
    return clamp(1.0 - d, 0.15, 1.0);
#else
    return 1.0;
#endif
}

// full sky for sky pixels
vec3 skyRender(vec3 dir, vec2 uv){
    if (length(sunPosition) < 0.5) return vec3(fogColor);
    vec3 sky = skyBase(dir);
    float nightF = 1.0 - dayFactor();
    sky += stars(dir, nightF) * (1.0 - rainStrength);
    sky += sunMoon(dir);
#ifdef VOLUMETRIC_CLOUDS
#if CLOUD_QUALITY <= 8
    vec4 cl = clouds2D(dir, cameraPosition);
#else
    vec4 cl = cloudsVol(dir, cameraPosition);
#endif
    sky = mix(sky, cl.rgb, clamp(cl.a, 0.0, 1.0));
#endif
    sky += aurora(dir) * nightF * (1.0 - rainStrength);
    if (rainStrength > 0.01){
        float streak = smoothstep(0.75, 0.95, vnoise2(vec2(uv.x * 160.0, uv.y * 24.0 - frameTimeCounter * 12.0)));
        sky += vec3(0.20, 0.24, 0.28) * streak * rainStrength * 0.30;
    }
    return sky;
}

// cheap sky for reflections / fog
vec3 skyReflection(vec3 dir){
    vec3 sky = skyBase(dir);
#ifdef VOLUMETRIC_CLOUDS
    vec4 cl = clouds2D(dir, cameraPosition);
    sky = mix(sky, cl.rgb, clamp(cl.a, 0.0, 1.0) * 0.9);
#endif
    return sky;
}

vec3 applyFog(vec3 col, float dist, vec3 dirW){
    vec3 hdir = normalize(vec3(dirW.x, 0.02, dirW.z));
    vec3 fogCol = skyBase(hdir);
    float f = 1.0 - exp(-pow(dist * 0.0012 * (1.0 + rainStrength * 2.5), 1.4));
    return mix(col, fogCol, clamp(f, 0.0, 1.0));
}

#endif
