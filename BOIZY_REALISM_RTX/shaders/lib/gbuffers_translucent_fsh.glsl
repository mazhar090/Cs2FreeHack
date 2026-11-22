#ifndef GB_TRANSLUCENT_FSH
#define GB_TRANSLUCENT_FSH
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
uniform sampler2D normals;
uniform sampler2D specular;

void main(){
    vec4 tex = texture(gtexture, texcoord);
    if (tex.a < 0.01) discard;
    vec4 color = tex * glcolor;
    color.rgb = pow(color.rgb, vec3(2.2));

    vec3 wNormal = normalize(mat3(gbufferModelViewInverse) * normal);

    vec4 specT = texture(specular, texcoord);
#ifndef SPECULAR_MAPS
    specT = vec4(0.0);
#endif

    float matID = abs(entityID - 10001.0) < 0.5 ? 1.0 : 0.5;

    gl_FragData[0] = vec4(color.rgb, color.a);
    gl_FragData[1] = vec4(lmcoord, encodeNormal(wNormal));
    gl_FragData[2] = vec4(specT.r, specT.g, specT.b, specT.a);
    gl_FragData[3] = vec4(0.0, 0.0, 0.0, matID);
}
#endif
