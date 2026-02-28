# Module 9: Post-Processing Effects

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** Module 6 (Textures & Image Processing)

---

## Overview

Post-processing is the final transformation applied to a fully rendered frame before it reaches the screen. The game engine draws the scene to an off-screen texture (framebuffer), then a full-screen fragment shader reads that texture and transforms it. Bloom, blur, color grading, CRT scanlines, vignette, film grain — all post-processing.

You already know the individual techniques from Module 6: texture sampling, convolution kernels, UV distortion, chromatic aberration. This module teaches you to *combine* them into complete post-processing pipelines and to use multi-pass rendering for effects that require intermediate results (like bloom, which needs a separate blur pass).

Post-processing is where shader programming becomes directly applicable to game development. Every shipped game uses a post-processing stack. Understanding how it works lets you create custom visual styles, optimize performance, and debug visual artifacts.

---

## 1. The Post-Processing Pipeline

### How It Works

```
Normal rendering:
  Scene geometry → Vertex shader → Rasterization → Fragment shader → Screen

Post-processing:
  Scene geometry → Vertex shader → Rasterization → Fragment shader → TEXTURE
                                                                        ↓
  Full-screen quad → Simple vertex shader → Post-process fragment shader → Screen
```

The key difference: instead of rendering directly to the screen, you render to a **framebuffer** (an off-screen texture). Then a second shader reads that texture and transforms it.

### In ShaderToy

ShaderToy's multi-pass system maps directly to this:

- **Buffer A** = Your scene (renders to a texture)
- **Image pass** = Post-processing (reads Buffer A, outputs to screen)

```glsl
// Buffer A: render a scene
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    // ... draw your scene ...
    fragColor = vec4(sceneColor, 1.0);
}

// Image pass: apply post-processing to Buffer A
// (iChannel0 is bound to Buffer A)
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 scene = texture(iChannel0, uv).rgb;
    // ... apply effects to scene ...
    fragColor = vec4(processedColor, 1.0);
}
```

### In Game Engines

The engine handles the framebuffer setup. You just write the post-processing shader:

- **Godot:** Create a `CanvasLayer` with a `ColorRect` that has a shader material. The shader receives the screen via `SCREEN_TEXTURE`.
- **Love2D:** Use `love.graphics.newCanvas()` to render to a texture, then draw that canvas with a shader applied.
- **Three.js:** Use `EffectComposer` with custom shader passes.

---

## 2. Bloom

Bloom is the glow around bright objects — the hallmark of "next-gen" graphics in the 2000s, now a staple of every visual style. The algorithm is simple:

1. **Extract bright pixels** (threshold)
2. **Blur them** (Gaussian, multi-pass)
3. **Add them back** to the original image

### Step 1: Brightness Extraction

```glsl
vec3 scene = texture(iChannel0, uv).rgb;
float brightness = dot(scene, vec3(0.2126, 0.7152, 0.0722));
vec3 brightPixels = scene * smoothstep(0.7, 1.0, brightness);
```

`smoothstep(0.7, 1.0, brightness)` creates a soft threshold: pixels below 0.7 luminance are zero, pixels above 1.0 are fully extracted, pixels between get a smooth ramp.

### Step 2: Blur

Use a separable Gaussian blur (horizontal + vertical) from Module 6. For bloom, a large blur radius is essential — 9 to 15 samples per axis.

```glsl
// Buffer A: Extract bright pixels from iChannel0 (scene)
// Buffer B: Horizontal blur of Buffer A
// Buffer C: Vertical blur of Buffer B (or do both in one pass with fewer samples)
```

### Step 3: Composite

```glsl
// Image pass:
vec3 scene = texture(iChannel0, uv).rgb;  // Original scene
vec3 bloom = texture(iChannel1, uv).rgb;  // Blurred bright pixels

vec3 color = scene + bloom * bloomIntensity;
```

The `+` is additive blending — the bloom brightens the image without darkening anything. Adjust `bloomIntensity` (typically 0.5 to 2.0) to taste.

### Multi-Resolution Bloom

For more realistic bloom, blur at multiple resolutions and combine:

```glsl
// Sample at progressively larger offsets (approximating multi-scale blur)
vec3 bloom = vec3(0.0);
bloom += blur(tex, uv, texel * 1.0) * 0.5;
bloom += blur(tex, uv, texel * 2.0) * 0.3;
bloom += blur(tex, uv, texel * 4.0) * 0.15;
bloom += blur(tex, uv, texel * 8.0) * 0.05;
```

This simulates what a multi-pass downsample/upsample bloom pipeline does in production renderers.

### Complete ShaderToy Bloom

```glsl
// Buffer A: Scene with bright elements
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    vec3 color = vec3(0.02);

    // Bright SDF shapes
    float d1 = length(uv - vec2(0.2, 0.0)) - 0.1;
    float d2 = length(uv + vec2(0.2, 0.0)) - 0.08;

    color += vec3(1.0, 0.5, 0.2) * smoothstep(0.01, 0.0, d1) * 2.0;
    color += vec3(0.2, 0.5, 1.0) * smoothstep(0.01, 0.0, d2) * 2.0;

    // Values > 1.0 are intentionally "HDR" — they will bloom
    fragColor = vec4(color, 1.0);
}

// Image: Extract brights, blur, composite
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;

    vec3 scene = texture(iChannel0, uv).rgb;

    // Extract bright parts
    float lum = dot(scene, vec3(0.2126, 0.7152, 0.0722));
    vec3 bright = scene * smoothstep(0.8, 1.5, lum);

    // Simple blur (in production, this would be multi-pass)
    vec3 bloom = vec3(0.0);
    for (int y = -4; y <= 4; y++) {
        for (int x = -4; x <= 4; x++) {
            vec2 off = vec2(float(x), float(y)) * texel * 3.0;
            float w = exp(-float(x*x + y*y) * 0.05);
            vec3 s = texture(iChannel0, uv + off).rgb;
            float sl = dot(s, vec3(0.2126, 0.7152, 0.0722));
            bloom += s * smoothstep(0.8, 1.5, sl) * w;
        }
    }
    bloom /= 30.0;

    vec3 color = scene + bloom * 1.5;

    fragColor = vec4(color, 1.0);
}
```

---

## 3. Gaussian Blur (Production Quality)

### Separable Two-Pass Blur

The standard approach: blur horizontally in one pass, then blur that result vertically in a second pass. This reduces an N×N operation to N+N.

```glsl
// Pass 1 (Buffer A → Buffer B): Horizontal blur
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float texelX = 1.0 / iResolution.x;

    // 9-tap Gaussian weights
    float w[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

    vec3 color = texture(iChannel0, uv).rgb * w[0];
    for (int i = 1; i < 5; i++) {
        color += texture(iChannel0, uv + vec2(texelX * float(i), 0.0)).rgb * w[i];
        color += texture(iChannel0, uv - vec2(texelX * float(i), 0.0)).rgb * w[i];
    }

    fragColor = vec4(color, 1.0);
}

// Pass 2 (Image): Vertical blur of Buffer B's output
// Same code but with texelY offset instead of texelX
```

### Bilinear Filtering Optimization

Sample between texels and let the GPU's bilinear filtering do some of the work — one texture sample effectively averages two texels:

```glsl
// Instead of sampling at texel 1 and texel 2 with weights w1 and w2:
// Sample at the weighted midpoint: texel = (1*w1 + 2*w2)/(w1+w2)
// Use weight: w1 + w2
// This halves the number of texture reads!
```

This trick reduces a 9-tap blur to 5 texture reads.

---

## 4. CRT / Retro Effects

CRT effects are a stack of small techniques, each 2–5 lines, that combine into a convincing retro look.

### Scanlines

```glsl
// Darken every other row
float scanline = sin(fragCoord.y * 3.14159) * 0.08;
color -= scanline;

// More visible scanlines (sharper)
float scanline = pow(sin(fragCoord.y * 3.14159), 2.0) * 0.12;
color -= scanline;

// Phosphor dot pattern (simulates RGB subpixels)
float phosphor = sin(fragCoord.x * 3.14159 * 3.0) * 0.03;
color -= phosphor;
```

### Barrel Distortion (CRT Curvature)

```glsl
vec2 crtDistort(vec2 uv) {
    uv = uv * 2.0 - 1.0;  // Center
    float d = length(uv);
    float k = 0.15;  // Distortion strength
    uv *= 1.0 + d * d * k;
    uv = uv * 0.5 + 0.5;  // Back to 0–1
    return uv;
}
```

### Vignette (CRT Edge Darkening)

```glsl
float crtVignette(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    float vig = 1.0 - dot(uv * uv, uv * uv) * 0.5;
    return clamp(vig, 0.0, 1.0);
}
```

### Complete CRT Stack

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- CRT barrel distortion ---
    vec2 crtUV = uv * 2.0 - 1.0;
    float d = length(crtUV);
    crtUV *= 1.0 + d * d * 0.12;
    crtUV = crtUV * 0.5 + 0.5;

    // Out-of-bounds check (black border)
    if (crtUV.x < 0.0 || crtUV.x > 1.0 || crtUV.y < 0.0 || crtUV.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // --- Chromatic aberration ---
    vec2 dir = crtUV - 0.5;
    float ca = 0.003;
    float r = texture(iChannel0, crtUV + dir * ca).r;
    float g = texture(iChannel0, crtUV).g;
    float b = texture(iChannel0, crtUV - dir * ca).b;
    vec3 color = vec3(r, g, b);

    // --- Scanlines ---
    float scanline = pow(sin(fragCoord.y * 3.14159), 2.0) * 0.1;
    color -= scanline;

    // --- Phosphor dots ---
    float phosphor = (sin(fragCoord.x * 3.14159 * 3.0) * 0.5 + 0.5) * 0.05 + 0.95;
    color *= phosphor;

    // --- Vignette ---
    float vig = 1.0 - dot(crtUV * 2.0 - 1.0, crtUV * 2.0 - 1.0) * 0.4;
    color *= clamp(vig, 0.0, 1.0);

    // --- Slight flicker ---
    color *= 0.98 + 0.02 * sin(iTime * 60.0);

    // --- Warm color shift (CRT phosphors weren't pure white) ---
    color *= vec3(1.05, 1.0, 0.95);

    fragColor = vec4(color, 1.0);
}
```

---

## 5. Film Grain

Film grain adds subtle per-pixel, per-frame noise that gives a cinematic or photographic feel.

```glsl
float filmGrain(vec2 uv, float time) {
    // Hash function that changes every frame
    float noise = fract(sin(dot(uv + fract(time), vec2(12.9898, 78.233))) * 43758.5453);
    return noise;
}

// Usage:
float grain = filmGrain(uv, iTime) * 0.1;  // 10% intensity
color += grain - 0.05;  // Center around zero (adds AND subtracts)
```

### Colored Film Grain

```glsl
// Each channel gets slightly different noise
vec3 coloredGrain;
coloredGrain.r = filmGrain(uv, iTime + 0.0) * 0.08;
coloredGrain.g = filmGrain(uv, iTime + 100.0) * 0.08;
coloredGrain.b = filmGrain(uv, iTime + 200.0) * 0.08;
color += coloredGrain - 0.04;
```

---

## 6. Color Grading

Color grading transforms the entire frame's color palette for artistic effect. It is the shader equivalent of Lightroom presets.

### Contrast

```glsl
color = (color - 0.5) * contrast + 0.5;
```

### Brightness

```glsl
color += brightness;
```

### Saturation

```glsl
float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
color = mix(vec3(lum), color, saturation);
// saturation > 1.0: more vivid
// saturation < 1.0: toward grayscale
// saturation = 0.0: fully grayscale
```

### Color Temperature

```glsl
// Warm: boost red, reduce blue
// Cool: reduce red, boost blue
color.r *= 1.0 + temperature * 0.1;
color.b *= 1.0 - temperature * 0.1;
```

### Tone Mapping

HDR values (above 1.0) need to be mapped to the displayable 0–1 range:

```glsl
// Reinhard tone mapping
color = color / (color + 1.0);

// ACES filmic tone mapping (more cinematic)
vec3 acesToneMap(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}
color = acesToneMap(color);
```

### Gamma Correction

```glsl
// Linear → sRGB (standard gamma)
color = pow(color, vec3(1.0 / 2.2));
```

### Lift / Gamma / Gain (Professional Color Grading)

```glsl
// Lift: affects shadows (adds a color tint to dark areas)
// Gamma: affects midtones (adjusts the curve)
// Gain: affects highlights (multiplies bright areas)

vec3 liftGammaGain(vec3 color, vec3 lift, vec3 gamma, vec3 gain) {
    color = color * gain + lift;
    color = pow(max(color, 0.0), 1.0 / gamma);
    return color;
}

// Example: warm shadows, neutral mids, cool highlights
color = liftGammaGain(color,
    vec3(0.05, 0.02, 0.0),  // Warm lift (shadows)
    vec3(1.0, 1.0, 1.0),    // Neutral gamma (midtones)
    vec3(0.95, 0.95, 1.05)  // Cool gain (highlights)
);
```

### Complete Color Grading Pipeline

```glsl
vec3 colorGrade(vec3 color) {
    // 1. Exposure
    color *= 1.2;

    // 2. Tone mapping
    color = color / (color + 1.0);

    // 3. Contrast
    color = (color - 0.5) * 1.1 + 0.5;

    // 4. Saturation boost
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(lum), color, 1.2);

    // 5. Color temperature (warm)
    color *= vec3(1.03, 1.0, 0.97);

    // 6. Gamma
    color = pow(max(color, 0.0), vec3(1.0 / 2.2));

    return clamp(color, 0.0, 1.0);
}
```

---

## 7. Screen-Space Effects

### Motion Blur (Per-Pixel Velocity)

In production, motion blur samples along the per-pixel velocity vector. In a shader-only context, you can approximate it:

```glsl
// Radial motion blur from center
vec2 dir = uv - 0.5;
vec3 color = vec3(0.0);
int samples = 16;
for (int i = 0; i < samples; i++) {
    float t = float(i) / float(samples - 1);
    vec2 offset = dir * t * blurAmount;
    color += texture(iChannel0, uv - offset).rgb;
}
color /= float(samples);
```

### Depth of Field (Approximation)

Without actual depth data, fake it by blurring based on distance from a focus point:

```glsl
float focusPoint = 0.5;  // Y position of focus
float blurAmount = abs(uv.y - focusPoint) * 0.02;  // More blur = further from focus

vec3 color = vec3(0.0);
for (int i = 0; i < 16; i++) {
    float angle = float(i) * 6.28 / 16.0;
    vec2 offset = vec2(cos(angle), sin(angle)) * blurAmount;
    color += texture(iChannel0, uv + offset).rgb;
}
color /= 16.0;
```

### Heat Haze / Distortion

```glsl
// Animated UV distortion simulating heat shimmer
float distort = sin(uv.y * 30.0 + iTime * 5.0) * 0.003;
distort *= smoothstep(0.0, 0.3, uv.y);  // Only near the bottom (ground heat)
vec3 color = texture(iChannel0, uv + vec2(distort, 0.0)).rgb;
```

---

## 8. Building a Complete Post-Processing Stack

A production post-processing pipeline applies effects in a specific order. The order matters because each effect transforms the input for the next.

### Recommended Order

```
1. Scene Rendering → Framebuffer
2. Bloom extraction (bright pixels)
3. Bloom blur (multi-pass Gaussian)
4. Bloom composite (add blurred brights to scene)
5. Color grading (exposure, contrast, saturation, temperature)
6. Tone mapping (HDR → LDR)
7. Vignette
8. Film grain
9. Chromatic aberration
10. Gamma correction
11. Screen output
```

### Complete Post-Processing Shader

```glsl
vec3 postProcess(vec3 scene, vec3 bloom, vec2 uv, vec2 fragCoord) {
    vec3 color = scene;

    // --- Bloom ---
    color += bloom * 0.8;

    // --- Color grading ---
    // Exposure
    color *= 1.1;
    // Contrast
    color = (color - 0.5) * 1.1 + 0.5;
    // Saturation
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(lum), color, 1.15);
    // Temperature (warm)
    color *= vec3(1.02, 1.0, 0.98);

    // --- Tone mapping ---
    color = color / (color + 1.0);  // Reinhard

    // --- Vignette ---
    vec2 vigUV = uv * 2.0 - 1.0;
    float vig = 1.0 - dot(vigUV, vigUV) * 0.3;
    color *= clamp(vig, 0.0, 1.0);

    // --- Film grain ---
    float grain = fract(sin(dot(fragCoord + fract(iTime),
                  vec2(12.9898, 78.233))) * 43758.5453);
    color += (grain - 0.5) * 0.06;

    // --- Chromatic aberration ---
    // (Applied before this function, at the sampling stage)

    // --- Gamma ---
    color = pow(max(color, 0.0), vec3(1.0 / 2.2));

    return clamp(color, 0.0, 1.0);
}
```

---

## GLSL Quick Reference

| Function/Concept | Description | Example |
|---|---|---|
| Framebuffer | Off-screen render target | Scene → texture → post-process |
| Bloom | Bright pixel extraction + blur + add | `scene + blurredBrights * intensity` |
| Bright extraction | Threshold by luminance | `smoothstep(0.7, 1.0, lum)` |
| Separable blur | Horizontal then vertical | Two passes, N+N samples |
| Scanlines | Darken alternating rows | `sin(fragCoord.y * PI)` |
| Barrel distortion | CRT curvature | `uv *= 1.0 + d² * k` |
| Film grain | Per-pixel per-frame noise | `hash(fragCoord + time)` |
| Reinhard tone map | `c / (c + 1)` | Maps HDR to displayable range |
| ACES tone map | Filmic S-curve | More cinematic than Reinhard |
| Lift/Gamma/Gain | Shadow/mid/highlight coloring | Professional color grading |
| Saturation | `mix(grayscale, color, amount)` | `amount > 1` = more vivid |
| Vignette | Darken edges | `1 - dot(uv, uv) * k` |
| Motion blur | Sample along velocity vector | Average samples in motion dir |

---

## Common Pitfalls

### 1. Effect Order Matters

Applying tone mapping *before* bloom causes the bloom to be compressed. Applying grain *before* gamma makes it too harsh.

```glsl
// WRONG order:
color = toneMap(color);     // Compresses range
color += bloom;              // Bloom values are already compressed — weak
color = pow(color, 0.4545); // Grain would be amplified by gamma

// RIGHT order:
color += bloom;              // Bloom at full HDR intensity
color = toneMap(color);      // Compress range
color += grain;              // Grain in final space
color = pow(color, 0.4545); // Gamma last
```

### 2. Over-Saturated Bloom

If bloom colors are too saturated, they can create colored halos. Desaturate the bloom slightly:

```glsl
float bloomLum = dot(bloom, vec3(0.2126, 0.7152, 0.0722));
bloom = mix(vec3(bloomLum), bloom, 0.7);  // 30% desaturated
```

### 3. Film Grain Banding

If grain looks like it has visible steps or bands, your hash function is not high-quality enough. Ensure you use the `+ fract(time)` or `+ iFrame` to change the seed every frame:

```glsl
// Seed with frame-dependent value:
float noise = fract(sin(dot(fragCoord + vec2(iFrame), vec2(12.9898, 78.233))) * 43758.5453);
```

### 4. Double Gamma Correction

If your image looks washed out, you might be applying gamma correction when the output is already in sRGB. In ShaderToy, the output framebuffer is already sRGB, so applying `pow(color, 1/2.2)` may over-brighten.

---

## Exercises

### Exercise 1: Bloom Pipeline

**Time:** 45–60 minutes

Implement bloom using ShaderToy's multi-pass system:

1. **Buffer A:** Create a scene with bright and dark elements (SDF shapes with varying brightness, some values > 1.0)
2. **Buffer B:** Read Buffer A, extract bright pixels (luminance threshold), apply horizontal Gaussian blur
3. **Buffer C:** Read Buffer B, apply vertical Gaussian blur
4. **Image:** Read Buffer A (scene) and Buffer C (blurred brights), add them together

Experiment with threshold levels and blur radii.

**Concepts practiced:** Multi-pass rendering, brightness extraction, separable blur, compositing

---

### Exercise 2: Retro Console Effect

**Time:** 30–45 minutes

Create a post-processing shader that makes any image look like it is being displayed on a retro console:

1. Reduce color depth (posterize to 16 or 32 levels per channel)
2. Pixelate (quantize UVs to a grid, like a 256×224 display)
3. Add scanlines
4. Add a slight vignette
5. Optional: dithering (ordered or noise-based) to simulate limited color palettes

**Concepts practiced:** Posterization, pixelation, scanlines, vignette, dithering

---

### Exercise 3: Cinematic Color Grade

**Time:** 30–45 minutes

Create a color grading pipeline that transforms a scene:

1. Start with a colorful scene (bind an image to iChannel0 or create a procedural one)
2. Implement adjustable exposure, contrast, and saturation
3. Add color temperature control (warm/cool)
4. Implement Reinhard or ACES tone mapping
5. Add lift/gamma/gain for independent shadow/midtone/highlight coloring
6. Add gamma correction

Create at least 3 different "looks" by changing the parameters: action movie (high contrast, teal/orange), horror (desaturated, cool, dark), dream sequence (bright, warm, low contrast).

**Concepts practiced:** Exposure, contrast, saturation, temperature, tone mapping, lift/gamma/gain

---

## Key Takeaways

1. **Post-processing operates on the rendered frame as a texture.** The scene renders to a framebuffer, then a full-screen shader reads and transforms it. This is how all screen-wide effects work in games.

2. **Bloom = extract brights + blur + add.** The three-step recipe creates convincing glow around bright objects. Multi-resolution blur (or multiple passes at different radii) produces higher-quality results.

3. **Separable blur is the key optimization.** An N×N 2D blur becomes two N-sized 1D blurs (horizontal then vertical), reducing cost from O(N²) to O(2N). This makes large-radius blurs practical.

4. **CRT effects are a stack of small techniques.** Barrel distortion + scanlines + chromatic aberration + vignette + phosphor dots + flicker = convincing CRT. Each piece is 2–3 lines.

5. **Color grading transforms the final image's mood.** Exposure, contrast, saturation, temperature, and tone mapping — each is a simple mathematical operation. Combined, they define the visual identity of your game.

6. **Effect order matters.** Generally: bloom → color grading → tone mapping → vignette → grain → gamma. Reordering can cause visible artifacts or reduced quality.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [LearnOpenGL: Bloom](https://learnopengl.com/Advanced-Lighting/Bloom) | Tutorial | Complete bloom implementation with diagrams. Shows the extraction, blur, and compositing steps with code. |
| [LearnOpenGL: Framebuffers](https://learnopengl.com/Advanced-OpenGL/Framebuffers) | Tutorial | How render-to-texture works. Essential for understanding multi-pass rendering. |
| [Ronja: Postprocessing with Normals and Depth](https://www.ronja-tutorials.com/post/018-postprocessing-normal/) | Tutorial | Using scene depth and normals in post-processing for edge detection and fog. |
| [ShaderToy Unofficial: Multipass](https://shadertoyunofficial.wordpress.com/2016/02/25/multipass/) | Tutorial | Practical guide to ShaderToy's buffer system for multi-pass effects. |
| [John Hable: Filmic Tonemapping](http://filmicworlds.com/blog/filmic-tonemapping-operators/) | Blog | Deep dive into tone mapping operators used in AAA games. Explains why Reinhard, Hable, and ACES look different. |

---

## What's Next?

You now have a complete post-processing toolkit. Combined with the rendering techniques from earlier modules, you can create polished, professional-looking visual output.

- **[Module 10: Raymarching & 3D SDF Scenes](module-10-raymarching-3d-sdf.md)** — Build 3D worlds in a single fragment shader. Post-processing these scenes is where things get really cinematic.
- **[Module 11: Animation, Motion & Interactive](module-11-animation-motion-interactive.md)** — Easing, sequencing, audio reactivity, and buffer feedback for dynamic animations.
- **[Module 12: Porting to Engines](module-12-porting-to-engines.md)** — Take your post-processing shaders into Godot, Love2D, or React Three Fiber.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
