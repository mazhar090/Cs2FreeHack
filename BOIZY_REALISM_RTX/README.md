# BOIZY REALISM RTX v1.0

**Ultra-realistic, heavy shader pack for Minecraft Java Edition 1.21.1**
Made for Iris Shaders + Sodium. © 2026 Mr op12 — All Rights Reserved.

> "RTX" is branding. All effects are implemented with real screen-space ray tracing (SSR),
> shadow-map ray marching and ray-marched volumetrics — the maximum the Iris/GLSL pipeline allows.
> No hardware DXR is used or claimed.

## How to install (60 seconds)

1. On this repo page: **Code (green button) → Download ZIP**
2. Extract the downloaded ZIP.
3. Inside you will find the folder **`BOIZY_REALISM_RTX/shaders/`**.
4. ZIP that folder: select `shaders` → right-click → *Send to → Compressed (zipped) folder*
   (or run the one-line command below). The final ZIP must contain the `shaders` folder at its root.
5. Put that ZIP into `.minecraft\shaderpacks\` (do not extract it).
6. Launch Minecraft 1.21.1 with **Iris + Sodium**, then:
   Options → Video Settings → Shader Packs → select **BOIZY REALISM RTX** → Apply.

PowerShell one-liner (run inside the extracted folder, creates the installable pack):

```powershell
Compress-Archive -Path BOIZY_REALISM_RTX\shaders -DestinationPath BOIZY_REALISM_RTX.zip
```

## The 5 presets

Open Shader Pack Settings → top **Profile** button:

| Preset | Shadows | SSR | GI | Volumetrics | Clouds | Target |
|---|---|---|---|---|---|---|
| LOW | 1024, hard | off | off | off | fast 2D | weak/old GPUs |
| MEDIUM | 2048, soft | 12 steps | off | 16 samples | 2D | laptops |
| HIGH | 2048, soft+PCF | 16 steps | on | 24 | 3D raymarch | default look |
| ULTRA | 4096, soft+PCF | 24 steps | on | 32 | 3D | gaming PCs |
| EXTREME | 8192, max | 32 steps | 1.5x | 48 | 3D max | cinematic |

## Features

SSR reflections (water/glass/metal/puddles) - screen-space GI - colored soft shadows -
contact shadows - SSS foliage - SSAO - volumetric light (god rays) - volumetric clouds with
cloud shadows - aurora - animated water waves - refraction - caustics - underwater absorption -
shoreline foam - wet surfaces + rain puddles - rain droplets - lightning flash - labPBR
(normal/specular/POM/emissive) - TAA - auto exposure - bloom - DOF - motion blur - chromatic
aberration - ACES/Filmic tonemaps - filmic grading - vignette - sharpening.

## Honest notes

- This pack has NOT been compiled in a live Minecraft/Iris session. If a shader error appears on
  first load, copy the error lines from `.minecraft/logs/latest.log` and report them for a fix.
- Requires Iris 1.21.1 builds. Vanilla rendering is replaced; use LOW preset on integrated GPUs.

## License

All rights reserved © 2026 Mr op12. See `BOIZY_REALISM_RTX/LICENSE.txt`.
No copying, re-uploading, editing, rebranding or selling without written permission.
