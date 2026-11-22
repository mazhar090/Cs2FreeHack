#version 150 compatibility
#include "/lib/settings.glsl"
varying vec2 lmcoord;
varying vec4 glcolor;
uniform sampler2D lightmap;
void main(){
    vec4 color = glcolor;
    color.rgb = pow(color.rgb, vec3(2.2)) * (pow(texture(lightmap, lmcoord).rgb, vec3(2.2)) * 3.0 + 0.05);
    gl_FragData[0] = color;
}
