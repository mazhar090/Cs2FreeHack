#ifndef GBUFFERS_VSH
#define GBUFFERS_VSH
#include "/lib/settings.glsl"
#include "/lib/util.glsl"

in vec4 mc_Entity;
in vec4 at_tangent;
in vec4 mc_midTexCoord;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec4 tangent;
varying vec3 viewPos;
varying float entityID;
varying vec2 midUV;

void main(){
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
    tangent = vec4(normalize(gl_NormalMatrix * at_tangent.xyz), at_tangent.w);
    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    entityID = mc_Entity.x;
    midUV = mc_midTexCoord.xy;
}
#endif
