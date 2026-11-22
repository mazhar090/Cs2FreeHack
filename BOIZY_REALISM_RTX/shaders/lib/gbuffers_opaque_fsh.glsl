#ifndef GB_OPAQUE_FSH
#define GB_OPAQUE_FSH
#include "/lib/settings.glsl"
#include "/lib/util.glsl"

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec4 tangent;
varying vec3 viewPos;
varying float entityID;
varying vec2 midUV;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;

#ifdef ENTITIES
uniform vec4 entityColor;
#endif

void main(){
    vec2 uv = texcoord;
    vec3 wNormal = normalize(mat3(gbufferModelViewInverse) * normal);
    vec3 wTangent = normalize(mat3(gbufferModelViewInverse) * tangent.xyz);
    vec3 wBitan = cross(wNormal, wTangent) * tangent.w;

    // ---------- parallax occlusion mapping (labPBR height in normal alpha) ----------
#if defined NORMAL_MAPS && defined POM && defined TERRAIN
    vec3 wv = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    vec3 tView = normalize(vec3(dot(cameraPosition - wv, wTangent),
                                dot(cameraPosition - wv, wBitan),
                                dot(cameraPosition - wv, wNormal)));
    vec2 tile = abs(texcoord - midUV) * 2.0;
    vec2 duv = tView.xy / max(tView.z, 0.05) * POM_DEPTH * tile / 16.0;
    float layerH = 1.0;
    for (int i = 0; i < 16; i++){
        layerH -= 0.0625;
        uv += duv;
        if (texture(normals, uv).a >= layerH) break;
    }
#endif

    vec4 tex = texture(gtexture, uv);
    if (tex.a < 0.1) discard;
    vec4 color = tex * glcolor;
#ifdef ENTITIES
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
#endif
    color.rgb = pow(color.rgb, vec3(2.2)); // sRGB -> linear (HDR pipeline)

    // ---------- normal mapping ----------
#ifdef NORMAL_MAPS
    vec3 nm = texture(normals, uv).xyz * 2.0 - 1.0;
    float nz = sqrt(clamp(1.0 - dot(nm.xy, nm.xy), 0.0, 1.0));
    wNormal = normalize(mat3(wTangent, wBitan, wNormal) * normalize(vec3(nm.xy, nz)));
#endif

    // ---------- labPBR specular ----------
    vec4 specT = texture(specular, uv);
#ifndef SPECULAR_MAPS
    specT = vec4(0.0);
#endif
    float sss = specT.b;
#ifdef SSS
    if (abs(entityID - 10002.0) < 0.5 || abs(entityID - 10003.0) < 0.5) sss = max(sss, 0.65);
#endif

    float id = 0.0;
#ifdef HAND
    id = 0.75;
#endif
#ifdef ENTITIES
    if (color.a < 0.95) id = 0.85; // translucent entities (slime etc.)
#endif

    gl_FragData[0] = vec4(color.rgb, 1.0);                 // linear albedo
    gl_FragData[1] = vec4(lmcoord, encodeNormal(wNormal)); // lightmap + normal
    gl_FragData[2] = vec4(specT.r, specT.g, sss, specT.a); // smoothness, f0, sss, emissive
    gl_FragData[3] = vec4(0.0, 0.0, 0.0, id);              // material ID
}
#endif
