#ifndef SHADING_GLSL
#define SHADING_GLSL
#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/sky.glsl"
#include "/lib/water.glsl"
#include "/lib/rt.glsl"

uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2DShadow shadowtex1HW;
uniform sampler2D shadowcolor0;

// colored, PCF-filtered shadow lookup (normal-offset bias + distortion)
vec3 shadowColorAt(vec3 pPos, vec3 wNormal, float dither, int softness){
    vec3 offPos = pPos + wNormal * (0.03 + length(pPos) * 0.0007);
    vec4 sp = shadowProjection * (shadowModelView * vec4(offPos, 1.0));
    sp.xyz /= sp.w;
    if (max(abs(sp.x), max(abs(sp.y), abs(sp.z))) > 1.0) return vec3(1.0);
    vec2 duv = distortClip(sp.xy);
    vec3 sc = vec3(duv * 0.5 + 0.5, sp.z * 0.5 + 0.5);
    sc.z -= 0.0012;
    float sh;
    if (softness == 0){
        sh = texture(shadowtex1HW, sc).x;
    } else if (softness < 3){
        float rad = (0.6 + 0.4 * float(softness)) / float(textureSize(shadowtex1HW, 0).x) * 2.0;
        sh = 0.0;
        for (int dx = -1; dx <= 1; dx++){
            for (int dy = -1; dy <= 1; dy++){
                sh += texture(shadowtex1HW, vec3(sc.xy + vec2(float(dx), float(dy)) * rad, sc.z)).x;
            }
        }
        sh /= 9.0;
    } else {
        float rad = 3.0 / float(textureSize(shadowtex1HW, 0).x) * 2.0;
        sh = 0.0;
        for (int dx = -2; dx <= 2; dx++){
            for (int dy = -2; dy <= 2; dy++){
                sh += texture(shadowtex1HW, vec3(sc.xy + vec2(float(dx), float(dy)) * rad, sc.z)).x;
            }
        }
        sh /= 25.0;
    }
    vec3 res = vec3(sh);
    // colored shadows through translucent blockers (stained glass / water)
    if (texture(shadowtex0, sc.xy).x < sc.z - 0.0002){
        vec4 sc0 = texture(shadowcolor0, sc.xy);
        res *= mix(vec3(1.0), sc0.rgb, clamp(sc0.a, 0.0, 1.0) * 0.85);
    }
    return res;
}

// cheap single-tap shadow (for volumetric light marching)
float shadowSimple(vec3 pPos, float dither){
    vec4 sp = shadowProjection * (shadowModelView * vec4(pPos, 1.0));
    sp.xyz /= sp.w;
    if (max(abs(sp.x), max(abs(sp.y), abs(sp.z))) > 1.0) return 1.0;
    vec2 duv = distortClip(sp.xy);
    return texture(shadowtex1HW, vec3(duv * 0.5 + 0.5, sp.z * 0.5 + 0.5 - 0.001)).x;
}

#ifdef CONTACT_SHADOWS
float contactShadow(vec3 vpos, vec3 vnorm){
    vec3 ldir = normalize(shadowLightPosition);
    float occ = 0.0;
    for (int i = 1; i <= 6; i++){
        vec3 sp = vpos + vnorm * 0.03 + ldir * (float(i) * 0.08);
        vec2 suv = screenUV(sp);
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) continue;
        float sd = texture(depthtex0, suv).x;
        vec3 spos = getViewPos(suv, sd);
        if (spos.z > sp.z + 0.02){ occ = 1.0 - float(i - 1) / 6.0; break; }
    }
    return 1.0 - occ * 0.9;
}
#endif

#ifdef SSAO
float ssao(vec2 uv, vec3 vpos, vec3 vnorm, float dither){
    vec3 t = normalize(vnorm);
    vec3 u = abs(t.z) < 0.99 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 bt = normalize(cross(u, t));
    vec3 tn = cross(t, bt);
    mat3 tbn = mat3(tn, bt, t);
    float occ = 0.0;
    for (int i = 0; i < 12; i++){
        float ang = hash12(vec2(float(i), dither * 57.0)) * 6.28318;
        float rad = sqrt(hash12(vec2(float(i) * 3.7, dither * 91.0)));
        float hgt = 0.3 + 0.7 * hash12(vec2(float(i) * 1.3, dither * 13.0));
        vec3 sdir = tbn * vec3(cos(ang) * rad, sin(ang) * rad, hgt);
        vec3 samplePos = vpos + sdir * 0.35;
        vec2 suv = screenUV(samplePos);
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0){ occ += 0.25; continue; }
        float sd = texture(depthtex0, suv).x;
        vec3 spos = getViewPos(suv, sd);
        if (spos.z > samplePos.z + 0.02 && samplePos.z - spos.z < 0.6) occ += 1.0;
    }
    return clamp(1.0 - occ / 12.0 * 0.85, 0.0, 1.0);
}
#endif

// ================= main deferred lighting =================
vec3 doLighting(vec3 albedo, vec3 wNormal, vec2 lm, vec4 spec,
                vec3 pPos, vec3 vDir, float matID, float dither, vec2 uv){
    vec3 skyAmb = getSkyAmbient();
    vec3 sunCol = getSunColor();
    vec3 blockCol = vec3(1.0, 0.55, 0.25);
#ifndef WARM_BLOCKLIGHT
    blockCol = vec3(1.0);
#endif
    float blockL = pow(clamp(lm.x, 0.0, 1.0), 3.0) * 2.0 + MIN_LIGHT * 0.06;

    // hand: simple stable lighting (own projection, avoids reprojection artifacts)
    if (matID > 0.7 && matID < 0.8){
        return albedo * (skyAmb * 1.4 * (0.3 + 0.7 * lm.y) + blockCol * blockL);
    }
    // water pixels are re-shaded in composite2 — cheap placeholder only
    if (matID > 0.9 && matID < 1.1){
        return albedo * (skyAmb * (0.4 + 0.6 * lm.y) + blockCol * blockL);
    }

    vec3 vNormal = normalize(mat3(gbufferModelView) * wNormal);
    vec3 vPos = (gbufferModelView * vec4(pPos, 1.0)).xyz;
    vec3 sDirW = sunDirWorld();
    float NdotL = dot(wNormal, sDirW);

    vec3 shadowCol = shadowColorAt(pPos, wNormal, dither, SHADOW_SOFTNESS);

    float cs = 1.0;
#ifdef CONTACT_SHADOWS
    if (NdotL > 0.0) cs = contactShadow(vPos, vNormal);
#endif

    float cl = cloudShadowFactor(pPos + cameraPosition);

    float ao = 1.0;
#ifdef SSAO
    if (matID < 0.2 || matID > 0.8) ao = ssao(uv, vPos, vNormal, dither);
#endif

    // rain puddles darken albedo
    float pud = puddleMask(pPos + cameraPosition, wNormal);
    vec3 alb = albedo * (1.0 - 0.3 * pud);

    vec3 sunLight = sunCol * shadowCol * clamp(NdotL, 0.0, 1.0) * cs * cl;
    vec3 ambient = skyAmb * (lm.y * lm.y) * ao;

#ifdef RT_GI
    ambient += traceGI(vPos, vNormal, dither) * ao;
#endif

    vec3 color = alb * (sunLight + ambient + blockCol * blockL);

    // emission (labPBR specular alpha) + subtle pseudo-emission from blocklight
    float emis = (1.0 - step(0.999, spec.a)) * spec.a * 8.0;
    emis += pow(clamp(lm.x, 0.0, 1.0), 6.0) * 1.2;
    color += alb * emis;

    // subsurface scattering for foliage (shadow-map based thickness)
#ifdef SSS
    float sss = spec.b;
    if (sss > 0.05){
        vec3 deepPos = pPos - sDirW * (0.12 + 0.7 * sss);
        float t = dot(shadowColorAt(deepPos, wNormal, dither, 0), vec3(0.333));
        color += alb * sunCol * t * sss * 0.8 * (1.0 - clamp(NdotL, 0.0, 1.0)) * cl;
    }
#endif

    // underwater caustics on terrain (camera submerged)
#ifdef WATER_CAUSTICS
    if (isEyeInWater == 1){
        color *= 1.0 + caustic((pPos + cameraPosition).xz * 0.7,
                               frameTimeCounter * 0.6 * WAVE_SPEED) * 1.5 * clamp(lm.y, 0.0, 1.0);
    }
#endif

    // sun specular
    float smoothness = spec.r;
#ifdef WET_SURFACES
    smoothness = max(smoothness, rainStrength * 0.55 * smoothstep(0.75, 0.95, lm.y));
#endif
    if (smoothness > 0.05 && NdotL > 0.0){
        vec3 rayDirW = normalize(mat3(gbufferModelViewInverse) * vDir);
        vec3 h = normalize(sDirW - rayDirW);
        float NdotH = clamp(dot(wNormal, h), 0.0, 1.0);
        float ex = 4.0 + 250.0 * pow(smoothness, 3.0);
        float s = pow(NdotH, ex) * (0.2 + 0.8 * smoothness);
        vec3 F0 = spec.g > 0.9 ? alb : vec3(clamp(spec.g, 0.02, 0.9));
        color += sunCol * shadowCol * cs * s * F0 * clamp(NdotL, 0.0, 1.0);
    }
    return color;
}

#endif
