#version 150 compatibility
#include "/lib/settings.glsl"
#include "/lib/util.glsl"

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;

/* DRAWBUFFERS:045 */

void main(){
    vec3 color = texture(colortex0, texcoord).rgb;
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);

    // ---------- temporally smoothed auto exposure ----------
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722)) * 0.4;
    lum += dot(texture(colortex0, texcoord + vec2(0.33, 0.33)).rgb, vec3(0.2126, 0.7152, 0.0722)) * 0.15;
    lum += dot(texture(colortex0, texcoord + vec2(-0.33, 0.33)).rgb, vec3(0.2126, 0.7152, 0.0722)) * 0.15;
    lum += dot(texture(colortex0, texcoord + vec2(0.33, -0.33)).rgb, vec3(0.2126, 0.7152, 0.0722)) * 0.15;
    lum += dot(texture(colortex0, texcoord + vec2(-0.33, -0.33)).rgb, vec3(0.2126, 0.7152, 0.0722)) * 0.15;
    float prevExp = texture(colortex4, vec2(0.5)).a;
    if (frameCounter < 3) prevExp = 1.0;
    float targetExp = clamp(0.5 / (lum + 0.12), 0.30, 3.0);
    float expo = mix(prevExp, targetExp, 0.04);

    // ---------- temporal anti-aliasing ----------
#ifdef TAA
    float depth = texture(depthtex0, texcoord).x;
    if (depth < 1.0){
        vec3 pPos = getPlayerPos(texcoord, depth);
        vec4 pv = gbufferPreviousProjection * gbufferPreviousModelView
                * vec4(pPos + cameraPosition - previousCameraPosition, 1.0);
        vec2 puv = (pv.xy / pv.w) * 0.5 + 0.5;
        if (puv.x > 0.0 && puv.x < 1.0 && puv.y > 0.0 && puv.y < 1.0){
            vec3 prev = texture(colortex4, puv).rgb;
            vec3 minC = color;
            vec3 maxC = color;
            for (int dx = -1; dx <= 1; dx++){
                for (int dy = -1; dy <= 1; dy++){
                    vec3 s = texture(colortex0, texcoord + vec2(float(dx), float(dy)) * px).rgb;
                    minC = min(minC, s);
                    maxC = max(maxC, s);
                }
            }
            vec3 clampedPrev = clamp(prev, minC, maxC);
            float vel = length(puv - texcoord);
            float blendF = clamp(0.10 + vel * 2.0, 0.10, 0.40);
            color = mix(clampedPrev, color, blendF);
        }
    }
#endif
    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(color, expo);
    gl_FragData[2] = vec4(color, 1.0);
}
