<p align="center"><img src="assets/logo.png" width="160" alt="Aurora Dreams"></p>

# Aurora Dreams

A dreamy, cinematic shader pack for Minecraft (Java Edition) built for **Iris** and **OptiFine**.

## Screenshots

![Ocean at sunset](assets/gallery/01-ocean-sunset.jpg)
![Sunrise god rays](assets/gallery/02-sunrise-godrays.jpg)
![Glowing ores](assets/gallery/03-cave-glowing-ores.jpg)
![Aurora night](assets/gallery/04-aurora-night.jpg)

## Features
- **Night-sky aurora borealis** with procedural stars, moon glow and twinkling
- Dynamic sky: deep-blue day gradient, rose/orange sunrise and sunset, rain overcast
- **Soft, distortion-mapped shadows** (sun and moonlight) with normal-offset bias
- **Screen-space ambient occlusion**
- **Water** with animated waves, Fresnel reflections, **screen-space reflections**, sky + aurora reflections and sun glints
- Waving grass, flowers, crops and leaves
- Warm flickering torchlight
- Atmospheric haze and distance fog tinted by the sky; underwater fog
- **Bloom**, ACES tonemapping, cool-shadow / warm-highlight grading, vignette, subtle chromatic aberration and grain
- Simple Nether and End looks
- Coloured light spreading: redstone torches tint their surroundings red, soul fire blue, ores glow and light the cave in their own colour
- Stained-glass coloured shadows, lens flare, wet surfaces in rain
- Presets: Performance / Balanced / Ultra, plus sliders for everything in the options screen

## Install
1. Install [Iris](https://irisshaders.dev) (recommended) or OptiFine.
2. Drop `AuroraDreams-<version>.zip` into your `shaderpacks` folder (do **not** unzip it).
3. In game: Options > Video Settings > Shader Packs > Aurora Dreams.

Tip: nights are best seen with clear weather and a clear view of the sky.

## Compatibility
- **Iris** (recommended): tested on Minecraft 26.3 with Iris 1.11.7 + Sodium 0.9.2.
- **OptiFine**: tested on Minecraft 26.2 with OptiFine HD U K2 pre5 (preview): all 26 shader programs compile and the pack renders. A visual check was done for terrain, shadows, sky and clouds only. There is no OptiFine build for 26.3 yet, so OptiFine on 26.3 is untested.
- Requires GLSL 1.20 and `#include` support. Water is flagged by block id `10002`, foliage by `10000`/`10001` in `block.properties`.

## Building the zip
```
python build.py
```

## License
MIT - see [LICENSE](LICENSE).
