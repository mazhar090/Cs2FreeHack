#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

/* ================= Iris/OptiFine pipeline constants =================
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA8;
const int colortex3Format = RGBA8;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA8;

const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = false;

const bool colortex0MipmapEnabled = true;

const int shadowMapResolution = 2048; // [1024 2048 4096 8192]
const float shadowDistance = 128.0; // [96.0 128.0 160.0 192.0 256.0]
const float shadowDistanceRenderMul = 1.0;
const bool shadowHardwareFiltering = true;
const float sunPathRotation = -40.0;
const float ambientOcclusionLevel = 0.7; // [0.0 0.4 0.7 1.0]
const float centerDepthSmoothHalflife = 1.5;
====================================================================== */

// ==================== USER OPTIONS ====================

// ---- Lighting
#define VOLUMETRIC_LIGHT
#define VL_SAMPLES 24 // [8 16 24 32 48 64]
#define RT_GI
#define GI_STRENGTH 1.0 // [0.5 1.0 1.5 2.0]
#define MIN_LIGHT 0.5 // [0.0 0.25 0.5 0.75 1.0]
#define WARM_BLOCKLIGHT
#define AUTO_EXPOSURE
#define EXPOSURE 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
#define SSAO

// ---- Ray tracing & reflections
#define SSR
#define SSR_SAMPLES 16 // [8 12 16 24 32]
#define ROUGH_REFLECTIONS
#define REFLECTION_STRENGTH 1.0 // [0.5 0.75 1.0 1.25 1.5]

// ---- Shadows
#define SHADOW_SOFTNESS 2 // [0 1 2 3]
#define CONTACT_SHADOWS
#define SSS

// ---- Water
#define WATER_WAVES
#define WAVE_SPEED 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define WATER_REFRACTION
#define WATER_CAUSTICS
#define WATER_ABSORPTION 1.0 // [0.5 1.0 2.0]
#define WATER_FOAM

// ---- Clouds & sky
#define VOLUMETRIC_CLOUDS
#define CLOUD_QUALITY 16 // [4 8 16 24 32 48]
#define CLOUD_DENSITY 1.0 // [0.5 0.75 1.0 1.25 1.5]
#define CLOUD_SHADOWS
#define AURORA

// ---- Weather
#define WET_SURFACES
#define PUDDLES
#define RAIN_DROPLETS

// ---- Materials & PBR
#define NORMAL_MAPS
#define SPECULAR_MAPS
#define POM
#define POM_DEPTH 0.08

// ---- Post processing
#define TAA
#define BLOOM
#define BLOOM_STRENGTH 0.5 // [0.25 0.5 1.0 1.5 2.0]
#define DOF
#define DOF_STRENGTH 0.5 // [0.5 1.0 2.0]
#define MOTION_BLUR
#define MOTION_BLUR_STRENGTH 0.5 // [0.25 0.5 1.0]
#define CHROMATIC_ABERRATION
#define VIGNETTE
#define SHARPENING 0.5 // [0.0 0.25 0.5 1.0]
#define TONEMAP 0 // [0 1]
#define SATURATION 1.0 // [0.5 0.75 1.0 1.25 1.5]
#define CONTRAST 1.0 // [0.75 0.9 1.0 1.1 1.25]

#endif
