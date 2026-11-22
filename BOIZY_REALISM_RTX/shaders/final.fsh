#version 150 compatibility
#include "/lib/settings.glsl"
#include "/lib/util.glsl"

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform float centerDepthSmooth;

void main(){
    vec2 uv = texcoord;
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    float depth = texture(depthtex0, uv).x;

    // ---------- rain droplets on the screen ----------
#ifdef RAIN_DROPLETS
    if (rainStrength > 0.01 && isEyeInWater == 0){
        vec2 dp = uv * vec2(viewWidth / viewHeight, 1.0) * 22.0;
        vec2 cell = floor(dp);
        float r = hash12(cell + vec2(floor(frameTimeCounter * 1.5), floor(frameTimeCounter * 0.6)));
        if (r > 0.55){
            vec2 f = fract(dp);
            vec2 o = (vec2(hash12(cell + 1.7), hash12(cell + 9.3)) - 0.5) * 0.7;
            float drop = smoothstep(0.30, 0.02, length(f - 0.5 - o));
            uv += drop * (f - 0.5 - o) * 0.012 * rainStrength;
        }
    }
#endif

    vec3 color = texture(colortex0, uv).rgb;

    // ---------- depth of field ----------
#ifdef DOF
    float focal = linZ(centerDepthSmooth);
    float z = linZ(depth);
    if (z > 0.1){
        float rpx = clamp(pow(abs(z - focal) * 0.08, 0.6) * DOF_STRENGTH, 0.0, 1.0) * 20.0;
        if (rpx > 0.5){
            vec3 blur = vec3(0.0);
            for (int i = 0; i < 12; i++){
                float a = (float(i) + 0.5) / 12.0 * 6.28318;
                float rr = sqrt(fract(float(i) * 0.618));
                blur += texture(colortex0, uv + vec2(cos(a), sin(a)) * rr * rpx * px).rgb;
            }
            color = mix(color, blur / 12.0, 0.85);
        }
    }
#endif

    // ---------- motion blur ----------
#ifdef MOTION_BLUR
    if (depth < 1.0){
        vec3 pPos = getPlayerPos(uv, depth);
        vec4 pv = gbufferPreviousProjection * gbufferPreviousModelView
                * vec4(pPos + cameraPosition - previousCameraPosition, 1.0);
        vec2 puv = (pv.xy / pv.w) * 0.5 + 0.5;
        vec2 vel = puv - texcoord;
        if (length(vel) > px.x && length(vel) < 0.2){
            vel *= MOTION_BLUR_STRENGTH * 0.4;
            vec3 blur = vec3(0.0);
            for (int i = 0; i < 5; i++){
                blur += texture(colortex5, texcoord - vel * float(i) / 4.0).rgb;
            }
            color = blur / 5.0;
        }
    }
#endif

    // ---------- bloom (mipmapped HDR buffer) ----------
#ifdef BLOOM
    vec3 bloom = textureLod(colortex0, uv, 2.0).rgb * 0.32
               + textureLod(colortex0, uv, 3.0).rgb * 0.30
               + textureLod(colortex0, uv, 4.0).rgb * 0.22
               + textureLod(colortex0, uv, 5.0).rgb * 0.16;
    color += bloom * BLOOM_STRENGTH * 0.10;
#endif

    // ---------- exposure ----------
#ifdef AUTO_EXPOSURE
    color *= texture(colortex4, vec2(0.5)).a;
#else
    color *= EXPOSURE;
#endif

    // ---------- chromatic aberration ----------
#ifdef CHROMATIC_ABERRATION
    {
        vec2 cc = uv - 0.5;
        float caS = dot(cc, cc) * 0.02;
        if (caS > 0.00001){
            color = vec3(texture(colortex0, uv + cc * caS).r, color.g, texture(colortex0, uv - cc * caS).b);
        }
    }
#endif

    // ---------- sharpening ----------
    color += (color - textureLod(colortex0, uv, 2.0).rgb) * SHARPENING * 0.5;

    // ---------- HDR tone mapping ----------
#if TONEMAP == 0
    color = clamp((color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14), 0.0, 1.0);
#else
    color = max(color, 0.0);
    color = (color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06);
    color = clamp(color, 0.0, 1.0);
#endif
    color = pow(color, vec3(1.0 / 2.2)); // linear -> sRGB

    // ---------- filmic color grading ----------
    float l = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(l), color, SATURATION);
    color = (color - 0.5) * CONTRAST + 0.5;

    // ---------- vignette ----------
#ifdef VIGNETTE
    color *= mix(1.0, smoothstep(0.95, 0.35, length(uv - 0.5)), 0.5);
#endif

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
