#version 150 compatibility
#include "/lib/settings.glsl"
#include "/lib/util.glsl"

varying vec2 texcoord;
varying vec4 glcolor;

void main(){
    gl_Position = ftransform();
    gl_Position.xy = distortClip(gl_Position.xy);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
}
