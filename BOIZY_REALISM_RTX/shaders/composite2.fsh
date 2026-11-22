#version 150 compatibility
#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"
#include "/lib/water.glsl"

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

/* DRAWBUFFERS:0 */

void main(){
    vec3 color = texture(colortex0, texcoord).rgb;
    float depth = texture(depthtex0, texcoord).x;
    float depth1 = texture(depthtex1, texcoord).x;
    float matID = texture(colortex3, texcoord).a;
    float dither = ign(gl_FragCoord.xy);

    if (depth < 1.0){
        vec3 vPos = getViewPos(texcoord, depth);
        vec3 vDir = normalize(vPos);
        vec3 pPos = getPlayerPos(texcoord, depth);
        vec3 wPos = pPos + cameraPosition;
        float dist = length(vPos);

        bool isWaterPx = matID > 0.9 && matID < 1.1;
        bool isGlassPx = matID > 0.4 && matID < 0.6;

#ifdef WATER_WAVES
        if (isWaterPx){
            // ---------- animated wave normals ----------
            vec3 wN = waterNormal(wPos, frameTimeCounter * WAVE_SPEED);
            if (isEyeInWater == 1) wN = -wN;
            vec3 vN = normalize(mat3(gbufferModelView) * wN);

            // ---------- screen-space reflections ----------
            vec3 rDir = reflect(vDir, vN);
            vec3 reflCol = vec3(0.0);
            float reflMask = 0.0;
#ifdef SSR
            vec2 hit = ssrMarch(vPos, rDir, dither);
            if (hit.x > 0.0){
                reflCol = texture(colortex0, hit).rgb;
                reflMask = ssrFade(hit);
            }
#endif
            if (reflMask < 0.99){
                vec3 rW = normalize(mat3(gbufferModelViewInverse) * rDir);
                reflCol = mix(reflCol, skyReflection(rW), 1.0 - reflMask);
            }
            float fres = 0.02 + 0.98 * pow(1.0 - clamp(dot(-vDir, vN), 0.0, 1.0), 5.0);

            // ---------- refraction + absorption ----------
            float dw = clamp(linZ(depth1) - linZ(depth), 0.0, 8.0);
            vec3 refr = color;
#ifdef WATER_REFRACTION
            vec2 ruv = texcoord + wN.xz * 0.02 * clamp(dw, 0.0, 3.0);
            if (ruv.x > 0.0 && ruv.x < 1.0 && ruv.y > 0.0 && ruv.y < 1.0){
                if (texture(depthtex0, ruv).x > depth - 0.00001) refr = texture(colortex0, ruv).rgb;
            }
#endif
            vec3 absorb = exp(-vec3(0.42, 0.12, 0.075) * dw * WATER_ABSORPTION);
            vec3 waterBase = vec3(0.035, 0.16, 0.20);
            refr = refr * absorb + waterBase * (1.0 - absorb) * 0.5;

#ifdef WATER_CAUSTICS
            if (isEyeInWater == 0){
                refr *= 1.0 + caustic(wPos.xz * 0.6, frameTimeCounter * 0.6 * WAVE_SPEED) * 1.4;
            }
#endif

            color = mix(refr, reflCol, fres);

            // ---------- sun glitter ----------
            vec3 sW = sunDirWorld();
            vec3 h = normalize(sW - normalize(mat3(gbufferModelViewInverse) * vDir));
            float glit = pow(clamp(dot(wN, h), 0.0, 1.0), 220.0) * 3.0;
            color += getSunColor() * glit * smoothstep(0.0, 0.15, sW.y);

            // ---------- shoreline foam ----------
#ifdef WATER_FOAM
            float shore = 1.0 - clamp(dw * 1.2, 0.0, 1.0);
            float fn = fbm2(wPos.xz * 2.0 + frameTimeCounter * WAVE_SPEED * vec2(1.0, -0.6));
            float foam = clamp(shore * 0.75 + (fn - 0.45) * 0.6, 0.0, 1.0) * clamp(shore * 1.5, 0.0, 1.0);
            color = mix(color, getSkyAmbient() * 2.0 + getSunColor() * 0.25, foam * 0.75);
#endif
        }
        else
#endif
        if (isGlassPx){
            // ---------- realistic reflective glass ----------
            vec4 spec = texture(colortex2, texcoord);
            float smoothness = max(spec.r, 0.75);
            vec3 wN = decodeNormal(texture(colortex1, texcoord).zw);
            vec3 vN = normalize(mat3(gbufferModelView) * wN);
            vec3 rDir = reflect(vDir, vN);
            vec3 refl = skyReflection(normalize(mat3(gbufferModelViewInverse) * rDir));
#ifdef SSR
            vec2 hit = ssrMarch(vPos, rDir, dither);
            if (hit.x > 0.0) refl = mix(refl, texture(colortex0, hit).rgb, ssrFade(hit));
#endif
            float cosT = clamp(dot(-vDir, vN), 0.0, 1.0);
            vec3 F0 = spec.g > 0.9 ? texture(colortex6, texcoord).rgb : vec3(clamp(spec.g, 0.04, 0.9));
            vec3 fres = F0 + (1.0 - F0) * pow(1.0 - cosT, 5.0);
            color += refl * fres * smoothness * REFLECTION_STRENGTH;
        }
        else if (matID < 0.15 && depth1 >= depth - 0.00001){
            // ---------- opaque surface reflections: metals, smooth materials, puddles ----------
            vec4 spec = texture(colortex2, texcoord);
            vec3 wN = decodeNormal(texture(colortex1, texcoord).zw);
            float smoothness = spec.r;
#ifdef WET_SURFACES
            smoothness = max(smoothness, rainStrength * 0.55 * smoothstep(0.75, 0.95, texture(colortex1, texcoord).y));
#endif
            smoothness = max(smoothness, puddleMask(wPos, wN) * 0.95);
            if (smoothness > 0.45){
                vec3 vN = normalize(mat3(gbufferModelView) * wN);
                vec3 rDir = reflect(vDir, vN);
#ifdef ROUGH_REFLECTIONS
                rDir = normalize(rDir + vec3(dither - 0.5, fract(dither * 7.3) - 0.5, fract(dither * 3.1) - 0.5)
                                 * (1.0 - smoothness) * 0.4);
#endif
                vec3 refl = skyReflection(normalize(mat3(gbufferModelViewInverse) * rDir));
#ifdef SSR
                vec2 hit = ssrMarch(vPos, rDir, dither);
                if (hit.x > 0.0) refl = mix(refl, texture(colortex0, hit).rgb, ssrFade(hit));
#endif
                float cosT = clamp(dot(-vDir, vN), 0.0, 1.0);
                vec3 F0 = spec.g > 0.9 ? texture(colortex6, texcoord).rgb : vec3(clamp(spec.g, 0.02, 0.9));
                vec3 fres = F0 + (1.0 - F0) * pow(1.0 - cosT, 5.0);
                color = mix(color, refl, fres * smoothness * REFLECTION_STRENGTH);
            }
        }

        // ---------- camera underwater / lava absorption ----------
        if (isEyeInWater == 1){
            vec3 absorbW = exp(-vec3(0.35, 0.09, 0.06) * dist * 0.25 * WATER_ABSORPTION);
            color *= absorbW;
            color = mix(color, vec3(0.010, 0.055, 0.075), 1.0 - exp(-dist * 0.045));
        } else if (isEyeInWater == 2){
            color = mix(color, vec3(1.0, 0.25, 0.03), 1.0 - exp(-dist * 0.8));
        }
    }
    gl_FragData[0] = vec4(color, 1.0);
}
