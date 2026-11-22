#ifndef RT_GLSL
#define RT_GLSL
#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/sky.glsl"

uniform sampler2D depthtex1;
uniform sampler2D colortex1;
uniform sampler2D colortex6;

float ssrFade(vec2 uv){
    return (1.0 - smoothstep(0.5, 1.0, abs(uv.x * 2.0 - 1.0)))
         * (1.0 - smoothstep(0.5, 1.0, abs(uv.y * 2.0 - 1.0)));
}

// screen-space ray march against opaque geometry, binary refinement on hit
vec2 ssrMarch(vec3 vpos, vec3 rdir, float dither){
    vec3 cur = vpos;
    vec3 fwd = normalize(rdir);
    float stepLen = 0.25 + length(vpos) * 0.004;
    cur += fwd * stepLen * dither;
    for (int i = 0; i < SSR_SAMPLES; i++){
        vec2 suv = screenUV(cur);
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) return vec2(0.0);
        float d = texture(depthtex1, suv).x;
        if (d < 1.0){
            vec3 spos = getViewPos(suv, d);
            if (cur.z < spos.z - 0.02){
                vec3 lo = cur - fwd * stepLen, hi = cur;
                for (int j = 0; j < 4; j++){
                    vec3 mid = mix(lo, hi, 0.5);
                    vec2 muv = screenUV(mid);
                    float md = texture(depthtex1, muv).x;
                    vec3 ms = getViewPos(muv, md);
                    if (mid.z < ms.z - 0.02) hi = mid; else lo = mid;
                }
                vec2 fuv = screenUV(mix(lo, hi, 0.5));
                if (ssrFade(fuv) < 0.05) return vec2(0.0);
                return fuv;
            }
        }
        stepLen *= 1.3;
        cur += fwd * stepLen;
    }
    return vec2(0.0);
}

// screen-space global illumination approximation (1 bounce, 3 short rays)
vec3 traceGI(vec3 vPos, vec3 vNormal, float dither){
    vec3 gi = vec3(0.0);
    for (int i = 0; i < 3; i++){
        float h1 = hash12(vec2(dither * 137.0, float(i) * 3.1));
        float h2 = hash12(vec2(float(i) * 7.7, dither * 91.3));
        vec3 r = normalize(vNormal + normalize(vec3(h1 * 2.0 - 1.0, h2 * 2.0 - 1.0, h1 * h2)) * 1.2);
        vec3 cur = vPos + vNormal * 0.05 + r * 0.35;
        vec2 hituv = vec2(0.0);
        bool hit = false;
        for (int j = 0; j < 6; j++){
            vec2 suv = screenUV(cur);
            if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) break;
            float d = texture(depthtex1, suv).x;
            if (d < 1.0){
                vec3 sp = getViewPos(suv, d);
                if (cur.z < sp.z - 0.05){ hituv = suv; hit = true; break; }
            }
            cur += r * 0.5;
        }
        if (hit){
            vec3 halb = texture(colortex6, hituv).rgb;
            float skl = texture(colortex1, hituv).y;
            gi += halb * getSkyAmbient() * (skl * skl) * 0.7;
        }
    }
    return gi * GI_STRENGTH / 3.0;
}

#endif
