#version 150 compatibility
#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

/* DRAWBUFFERS:06 */

void main(){
    vec4 c0 = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).x;
    vec3 color = c0.rgb;
    float dither = ign(gl_FragCoord.xy);
    vec3 dirW = normalize(mat3(gbufferModelViewInverse) * normalize(getViewPos(texcoord, 1.0)));
    vec3 albedoOut = vec3(0.0);

    if (depth >= 1.0){
        // ---------- procedural sky (atmosphere, clouds, sun, moon, stars, aurora) ----------
        color = skyRender(dirW, texcoord);
    } else {
        float depth1 = texture(depthtex1, texcoord).x;
        float matID = texture(colortex3, texcoord).a;
        bool transFront = depth < depth1 - 0.00001;

        if (transFront && depth1 >= 1.0){
            // translucent geometry (glass, water edge, particles) against open sky
            vec3 skyBG = skyRender(dirW, texcoord);
            float a = clamp(c0.a, 0.0, 1.0);
            color = skyBG * (1.0 - a) + c0.rgb * 1.6;
            albedoOut = c0.rgb;
        } else if (transFront && matID < 0.35){
            // forward-lit particles / weather - already shaded
            albedoOut = c0.rgb;
        } else {
            // ---------- full deferred lighting ----------
            vec3 albedo = c0.rgb;
            vec2 lm = texture(colortex1, texcoord).xy;
            vec4 spec = texture(colortex2, texcoord);
            vec3 wNormal = decodeNormal(texture(colortex1, texcoord).zw);
            vec3 pPos = getPlayerPos(texcoord, depth);
            vec3 vDir = normalize(getViewPos(texcoord, depth));
            color = doLighting(albedo, wNormal, lm, spec, pPos, vDir, matID, dither, texcoord);
            albedoOut = albedo;
        }
    }
    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(albedoOut, 1.0);
}
