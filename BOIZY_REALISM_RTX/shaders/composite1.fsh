#version 150 compatibility
#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

varying vec2 texcoord;

// colortex1 is declared inside rt.glsl (via shading.glsl) — do not redeclare
uniform sampler2D colortex0;

/* DRAWBUFFERS:0 */

void main(){
    vec3 color = texture(colortex0, texcoord).rgb;
    float depth = texture(depthtex0, texcoord).x;
    float dither = ign(gl_FragCoord.xy);

    if (depth < 1.0){
        vec3 vPos = getViewPos(texcoord, depth);
        float dist = length(vPos);

        // ---------- volumetric light / god rays ----------
#ifdef VOLUMETRIC_LIGHT
        if (dist > 1.0){
            float lmY = pow(clamp(texture(colortex1, texcoord).y, 0.0, 1.0), 2.0);
            float volD = 0.025 + rainStrength * 0.06 + (isEyeInWater == 1 ? 0.05 : 0.0);
            float stepD = dist / float(VL_SAMPLES);
            float shaft = 0.0;
            for (int i = 0; i < VL_SAMPLES; i++){
                float t = stepD * (float(i) + dither);
                vec3 sp = vPos * (t / dist);
                vec3 pp = (gbufferModelViewInverse * vec4(sp, 1.0)).xyz;
                shaft += shadowSimple(pp, dither + float(i) * 0.37) * (1.0 - t / dist);
            }
            color += getSunColor() * shaft * lmY * volD * 2.2;
        }
#endif

        // ---------- atmospheric fog ----------
        vec3 dirW = normalize(mat3(gbufferModelViewInverse) * normalize(vPos));
        if (isEyeInWater == 0){
            color = applyFog(color, dist, dirW);
        }

        // ---------- thunderstorm lightning flash ----------
        float flick = ign(vec2(floor(frameTimeCounter * 20.0), 3.7));
        float flash = step(0.80, flick) * clamp(thunderStrength, 0.0, 1.0);
        color += vec3(0.35, 0.40, 0.50) * flash * 0.30;
    }
    gl_FragData[0] = vec4(color, 1.0);
}
