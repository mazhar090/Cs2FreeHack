#ifndef GB_TEXTURED_FSH
#define GB_TEXTURED_FSH
#include "/lib/settings.glsl"
#include "/lib/util.glsl"

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

void main(){
    vec4 color = texture(gtexture, texcoord) * glcolor;
    if (color.a < 0.01) discard;
    color.rgb = pow(color.rgb, vec3(2.2));
#ifndef FULLBRIGHT
    color.rgb *= pow(texture(lightmap, lmcoord).rgb, vec3(2.2)) * 1.4 + 0.02;
#else
    color.rgb *= 2.0;
#endif
#ifdef WEATHER
    color.rgb *= vec3(0.85, 0.88, 0.94);
    color.a *= 0.6;
#endif
    gl_FragData[0] = color;
}
#endif
