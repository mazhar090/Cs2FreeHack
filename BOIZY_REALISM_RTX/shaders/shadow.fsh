#version 150 compatibility
#include "/lib/settings.glsl"

varying vec2 texcoord;
varying vec4 glcolor;

uniform sampler2D gtexture;

void main(){
    vec4 color = texture(gtexture, texcoord) * glcolor;
    if (color.a < 0.01) discard;
    gl_FragData[0] = color; // shadowcolor0 -> colored shadows
}
