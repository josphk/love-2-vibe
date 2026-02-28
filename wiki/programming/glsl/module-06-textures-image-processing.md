# Module 6: Textures & Image Processing

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** Module 5 (Noise)

---

## Overview

Everything until now has been procedural — generated from pure math. No external data, no images, no assets. That changes in this module. **Textures** are how the outside world enters your shaders: photographs, sprite sheets, rendered scenes, audio visualizations, or even the output of other shader passes.

Sampling a texture is simple — `texture(iChannel0, uv)` returns the color at a given UV coordinate. But what you *do* with that sample opens up an entire field: image processing. Blur an image by averaging neighbors. Detect edges with a Sobel filter. Distort it with UV manipulation for water refraction effects. Split the RGB channels apart for chromatic aberration. These techniques are the building blocks of post-processing (Module 9) and the visual style of countless games.

This module also bridges the gap between ShaderToy experimentation and real-world shader applications. When you write a post-processing shader in Godot, Love2D, or Unity, you are sampling the rendered scene as a texture and transforming it. Everything in this module transfers directly.

---

## 1. Textures: The Basics

A texture is a 2D grid of color values (pixels / texels) stored on the GPU. You sample it using UV coordinates:

```glsl
vec4 color = texture(iChannel0, uv);
```

### ShaderToy Setup

In ShaderToy, you bind textures to **channels** (iChannel0 through iChannel3):

1. Click on "iChannel0" below the editor
2. Select a texture from the gallery (or upload your own)
3. The texture is now available as `iChannel0` in your shader

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec4 texColor = texture(iChannel0, uv);
    fragColor = texColor;
}
```

This displays the texture at full screen, stretched to fit.

### UV Coordinates for Textures

Texture UVs follow the same 0–1 convention:

```
(0, 1) ─────── (1, 1)
  │               │
  │   Texture     │
  │               │
(0, 0) ─────── (1, 0)
```

- `(0, 0)` = bottom-left of the texture
- `(1, 1)` = top-right
- `(0.5, 0.5)` = center

### Wrapping Modes

What happens when UV coordinates go outside the 0–1 range?

```glsl
// UV = 1.5 — what color do we get?
// Depends on the wrapping mode:
```

| Mode | Behavior | Effect |
|---|---|---|
| **Repeat** | UVs wrap around (like `fract()`) | Tiled texture |
| **Clamp** | UVs are clamped to 0–1 | Edge pixels stretch to infinity |
| **Mirror** | UVs bounce back | Mirrored tiling |

In ShaderToy, you set wrapping in the channel settings (click the gear icon on the channel). In engines, it is a texture property.

### Filtering Modes

How the GPU interpolates between texels:

- **Linear** (bilinear): Smooth blending between pixels. Good for most cases.
- **Nearest** (point): No interpolation, picks the closest texel. Creates a pixelated look. Good for pixel art.

```
Linear filtering:           Nearest filtering:
Smooth gradients            Hard pixel edges
between texels              (retro/pixel art look)
```

In ShaderToy, set filtering in the channel settings. In engines, it is a sampler or texture property.

---

## 2. Texture Manipulation

### Tinting

Multiply the texture color by a tint:

```glsl
vec4 tex = texture(iChannel0, uv);
vec3 tinted = tex.rgb * vec3(1.0, 0.8, 0.6);  // Warm tint
fragColor = vec4(tinted, tex.a);
```

### Grayscale

Convert to luminance:

```glsl
vec4 tex = texture(iChannel0, uv);
float gray = dot(tex.rgb, vec3(0.2126, 0.7152, 0.0722));
fragColor = vec4(vec3(gray), 1.0);
```

### Brightness and Contrast

```glsl
vec4 tex = texture(iChannel0, uv);
vec3 color = tex.rgb;

// Brightness: add/subtract
color += 0.1;  // Brighter

// Contrast: scale around midpoint
color = (color - 0.5) * 1.5 + 0.5;  // More contrast

fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
```

### Hue Shift

Rotate the hue using a matrix:

```glsl
vec3 hueShift(vec3 color, float shift) {
    // Approximate hue rotation
    float angle = shift * 6.28318;
    float s = sin(angle), c = cos(angle);
    vec3 weights = vec3(0.2126, 0.7152, 0.0722);
    float lum = dot(color, weights);
    vec3 gray = vec3(lum);
    vec3 diff = color - gray;
    return gray + diff * c + cross(diff, vec3(0.577, 0.577, 0.577)) * s;
}
```

### Inversion, Posterization, Threshold

```glsl
// Invert
vec3 inverted = 1.0 - tex.rgb;

// Posterize (reduce to N levels per channel)
float levels = 4.0;
vec3 posterized = floor(tex.rgb * levels) / levels;

// Threshold (black and white)
float lum = dot(tex.rgb, vec3(0.2126, 0.7152, 0.0722));
float bw = step(0.5, lum);
```

---

## 3. UV Distortion

Modifying UV coordinates before sampling creates warping and distortion effects. This is the same domain warping from Module 4, but applied to texture sampling.

### Wavy Distortion (Underwater Effect)

```glsl
vec2 uv = fragCoord / iResolution.xy;

// Horizontal wave
uv.x += sin(uv.y * 15.0 + iTime * 3.0) * 0.01;
// Vertical wave
uv.y += cos(uv.x * 15.0 + iTime * 2.5) * 0.01;

vec4 color = texture(iChannel0, uv);
fragColor = color;
```

The `* 0.01` controls the distortion amplitude. Keep it small for subtle effects. The `* 15.0` controls the wave frequency. Higher = tighter waves.

### Swirl

```glsl
vec2 uv = fragCoord / iResolution.xy;
vec2 center = vec2(0.5);
vec2 delta = uv - center;
float dist = length(delta);
float angle = atan(delta.y, delta.x);

// Add rotation based on distance from center
float swirl = 3.0;  // Swirl intensity
angle += dist * swirl;

uv = center + vec2(cos(angle), sin(angle)) * dist;
vec4 color = texture(iChannel0, uv);
```

### Barrel Distortion (Fisheye / CRT)

```glsl
vec2 uv = fragCoord / iResolution.xy;
uv = uv * 2.0 - 1.0;  // Center: -1 to 1

float dist = length(uv);
float strength = 0.3;  // Distortion amount
uv *= 1.0 + dist * dist * strength;

uv = uv * 0.5 + 0.5;  // Back to 0–1
vec4 color = texture(iChannel0, uv);
fragColor = color;
```

### Pixelation

Quantize UVs to create a mosaic effect:

```glsl
float pixelSize = 64.0;  // Number of "pixels" across
vec2 uv = floor(fragCoord / iResolution.xy * pixelSize) / pixelSize;
vec4 color = texture(iChannel0, uv);
```

### Noise-Based Distortion

Use noise from Module 5 for organic warping:

```glsl
vec2 uv = fragCoord / iResolution.xy;
float n1 = snoise(uv * 10.0 + iTime);
float n2 = snoise(uv * 10.0 + vec2(100.0) + iTime * 0.7);
uv += vec2(n1, n2) * 0.02;
vec4 color = texture(iChannel0, uv);
```

---

## 4. Convolution Kernels

A convolution kernel is a small grid of weights. For each pixel, you sample the neighborhood, multiply each sample by its weight, and sum the results. This is the mathematical foundation of blur, sharpen, edge detection, and emboss.

### How Convolution Works

```
Kernel (3×3):              Neighborhood samples:
┌────┬────┬────┐          ┌────┬────┬────┐
│ w1 │ w2 │ w3 │          │ s1 │ s2 │ s3 │
├────┼────┼────┤          ├────┼────┼────┤
│ w4 │ w5 │ w6 │    ×     │ s4 │ s5 │ s6 │
├────┼────┼────┤          ├────┼────┼────┤
│ w7 │ w8 │ w9 │          │ s7 │ s8 │ s9 │
└────┴────┴────┘          └────┴────┴────┘

Result = w1×s1 + w2×s2 + ... + w9×s9
```

### The Texel Size

To sample neighboring pixels, you need to know the UV size of one pixel:

```glsl
vec2 texel = 1.0 / iResolution.xy;  // Size of one pixel in UV space
// or for a texture channel:
vec2 texel = 1.0 / iChannelResolution[0].xy;
```

Now `uv + vec2(texel.x, 0.0)` is one pixel to the right.

### Box Blur (Average)

The simplest blur: average all neighbors equally.

```glsl
vec3 boxBlur(sampler2D tex, vec2 uv, vec2 texel) {
    vec3 color = vec3(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y)) * texel;
            color += texture(tex, uv + offset).rgb;
        }
    }

    return color / 9.0;  // Average of 9 samples
}
```

### Gaussian Blur (Weighted Average)

A Gaussian blur weights the center more heavily, producing a smoother result:

```glsl
vec3 gaussianBlur3x3(sampler2D tex, vec2 uv, vec2 texel) {
    // Gaussian 3×3 kernel:
    //  1  2  1
    //  2  4  2   ÷ 16
    //  1  2  1

    vec3 color = vec3(0.0);

    color += texture(tex, uv + vec2(-1, -1) * texel).rgb * 1.0;
    color += texture(tex, uv + vec2( 0, -1) * texel).rgb * 2.0;
    color += texture(tex, uv + vec2( 1, -1) * texel).rgb * 1.0;

    color += texture(tex, uv + vec2(-1,  0) * texel).rgb * 2.0;
    color += texture(tex, uv + vec2( 0,  0) * texel).rgb * 4.0;
    color += texture(tex, uv + vec2( 1,  0) * texel).rgb * 2.0;

    color += texture(tex, uv + vec2(-1,  1) * texel).rgb * 1.0;
    color += texture(tex, uv + vec2( 0,  1) * texel).rgb * 2.0;
    color += texture(tex, uv + vec2( 1,  1) * texel).rgb * 1.0;

    return color / 16.0;
}
```

### Larger Blurs

A 3×3 kernel produces a very subtle blur. For a stronger blur, either:

1. **Use a larger kernel** (5×5, 7×7, etc.) — expensive but simple
2. **Apply multiple passes** — blur the blurred result multiple times (use ShaderToy's Buffer A → Buffer B chain)
3. **Separable blur** — blur horizontally first, then vertically. A 9×9 2D blur needs 81 samples. A separable version needs only 9+9=18 samples.

```glsl
// Separable Gaussian blur (horizontal pass)
vec3 blurH(sampler2D tex, vec2 uv, vec2 texel) {
    float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    vec3 color = texture(tex, uv).rgb * weights[0];

    for (int i = 1; i < 5; i++) {
        vec2 off = vec2(float(i) * texel.x, 0.0);
        color += texture(tex, uv + off).rgb * weights[i];
        color += texture(tex, uv - off).rgb * weights[i];
    }

    return color;
}

// Vertical pass: same weights, but offset in Y
vec3 blurV(sampler2D tex, vec2 uv, vec2 texel) {
    float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    vec3 color = texture(tex, uv).rgb * weights[0];

    for (int i = 1; i < 5; i++) {
        vec2 off = vec2(0.0, float(i) * texel.y);
        color += texture(tex, uv + off).rgb * weights[i];
        color += texture(tex, uv - off).rgb * weights[i];
    }

    return color;
}
```

---

## 5. Edge Detection

Edge detection finds boundaries in an image — where pixel values change sharply. The Sobel operator is the classic technique.

### Sobel Edge Detection

The Sobel operator uses two 3×3 kernels — one for horizontal edges, one for vertical:

```
Horizontal (Gx):    Vertical (Gy):
-1  0  1            -1  -2  -1
-2  0  2             0   0   0
-1  0  1             1   2   1
```

```glsl
vec2 sobel(sampler2D tex, vec2 uv, vec2 texel) {
    // Sample 3×3 neighborhood luminance
    float tl = dot(texture(tex, uv + vec2(-1, -1) * texel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float t  = dot(texture(tex, uv + vec2( 0, -1) * texel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float tr = dot(texture(tex, uv + vec2( 1, -1) * texel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float l  = dot(texture(tex, uv + vec2(-1,  0) * texel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float r  = dot(texture(tex, uv + vec2( 1,  0) * texel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float bl = dot(texture(tex, uv + vec2(-1,  1) * texel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float b  = dot(texture(tex, uv + vec2( 0,  1) * texel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float br = dot(texture(tex, uv + vec2( 1,  1) * texel).rgb, vec3(0.2126, 0.7152, 0.0722));

    float gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
    float gy = -tl - 2.0*t - tr + bl + 2.0*b + br;

    return vec2(gx, gy);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;

    vec2 edge = sobel(iChannel0, uv, texel);
    float edgeStrength = length(edge);

    fragColor = vec4(vec3(edgeStrength), 1.0);
}
```

### Outline Effect

Overlay edges on the original image:

```glsl
vec3 original = texture(iChannel0, uv).rgb;
float edges = length(sobel(iChannel0, uv, texel));
edges = smoothstep(0.1, 0.3, edges);
vec3 color = mix(original, vec3(0.0), edges);  // Dark edges on top
```

### Emboss

Emboss highlights edges with a directional light effect:

```glsl
// Emboss kernel:
// -2  -1   0
// -1   1   1
//  0   1   2

float emboss(sampler2D tex, vec2 uv, vec2 texel) {
    float result = 0.0;
    result += texture(tex, uv + vec2(-1, -1) * texel).r * -2.0;
    result += texture(tex, uv + vec2( 0, -1) * texel).r * -1.0;
    result += texture(tex, uv + vec2(-1,  0) * texel).r * -1.0;
    result += texture(tex, uv).r * 1.0;
    result += texture(tex, uv + vec2( 1,  0) * texel).r * 1.0;
    result += texture(tex, uv + vec2( 0,  1) * texel).r * 1.0;
    result += texture(tex, uv + vec2( 1,  1) * texel).r * 2.0;
    return result * 0.5 + 0.5;  // Shift to 0–1 range
}
```

### Sharpen

Sharpening amplifies the center pixel and subtracts neighbors:

```glsl
// Sharpen kernel:
//  0  -1   0
// -1   5  -1
//  0  -1   0

vec3 sharpen(sampler2D tex, vec2 uv, vec2 texel) {
    vec3 color = vec3(0.0);
    color += texture(tex, uv + vec2( 0, -1) * texel).rgb * -1.0;
    color += texture(tex, uv + vec2(-1,  0) * texel).rgb * -1.0;
    color += texture(tex, uv).rgb * 5.0;
    color += texture(tex, uv + vec2( 1,  0) * texel).rgb * -1.0;
    color += texture(tex, uv + vec2( 0,  1) * texel).rgb * -1.0;
    return color;
}
```

---

## 6. Chromatic Aberration

Chromatic aberration simulates the color fringing caused by imperfect lenses. Each color channel (R, G, B) is sampled at a slightly different UV offset.

### Basic Implementation

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 center = vec2(0.5);

    // Direction from center to this pixel
    vec2 dir = uv - center;

    // Offset amount (stronger at edges)
    float amount = 0.005;

    // Sample each channel at a different offset
    float r = texture(iChannel0, uv + dir * amount).r;
    float g = texture(iChannel0, uv).g;  // Green stays centered
    float b = texture(iChannel0, uv - dir * amount).b;

    fragColor = vec4(r, g, b, 1.0);
}
```

The `dir` vector points away from the center, so the offset is radial — stronger at the edges, zero at the center. This mimics real lens aberration.

### Enhanced Version

```glsl
// More controlled: scale offset by distance from center
float dist = length(uv - center);
float amount = dist * dist * 0.03;  // Quadratic falloff

// Three-sample version with more separation
float r = texture(iChannel0, uv + dir * amount * 1.0).r;
float g = texture(iChannel0, uv).g;
float b = texture(iChannel0, uv - dir * amount * 1.0).b;
```

For higher quality, use more samples along the dispersion direction and weight them:

```glsl
// Multi-sample chromatic aberration (smoother)
vec3 color = vec3(0.0);
int samples = 8;
for (int i = 0; i < samples; i++) {
    float t = float(i) / float(samples - 1);  // 0 to 1
    vec2 offset = dir * amount * (t - 0.5) * 2.0;
    vec3 s = texture(iChannel0, uv + offset).rgb;
    // Weight by channel: red at positive offset, blue at negative
    color.r += s.r * (1.0 - t);
    color.g += s.g * (1.0 - abs(t - 0.5) * 2.0);
    color.b += s.b * t;
}
color /= float(samples) * 0.5;
```

---

## 7. Vignette

A vignette darkens the edges of the image, drawing focus to the center. It is one of the most common post-processing effects.

```glsl
float vignette(vec2 uv) {
    uv = uv * 2.0 - 1.0;  // Center: -1 to 1
    float d = length(uv);
    return 1.0 - smoothstep(0.5, 1.5, d);
}
```

### Customizable Vignette

```glsl
float vignette(vec2 uv, float radius, float softness) {
    uv = uv * 2.0 - 1.0;
    float d = length(uv);
    return 1.0 - smoothstep(radius, radius + softness, d);
}

// Usage:
vec3 color = texture(iChannel0, uv).rgb;
color *= vignette(uv, 0.5, 1.0);
```

---

## 8. Multi-Pass Rendering in ShaderToy

ShaderToy supports multiple render passes via **Buffers** (Buffer A, B, C, D). Each buffer is a fragment shader that renders to a texture, which can be read by other buffers or the final Image pass.

### How It Works

```
Buffer A (renders to texture)
    ↓
Buffer B (reads Buffer A, renders to texture)
    ↓
Image (reads Buffer B, outputs to screen)
```

### Setting Up

1. Click the "+" tab next to "Image" to add a buffer (Buffer A)
2. Write a shader in Buffer A
3. In the Image pass, click "iChannel0" and select "Buffer A"
4. Now `texture(iChannel0, uv)` in the Image pass reads Buffer A's output

### Why Multi-Pass Matters

Many effects require reading the result of a previous computation:
- **Separable blur**: horizontal blur in Buffer A, vertical blur of Buffer A in Image
- **Bloom**: extract bright pixels in Buffer A, blur them in Buffer B, composite in Image
- **Feedback effects**: Buffer A reads its own previous frame for trails and motion blur
- **Ping-pong**: Buffer A reads Buffer B, Buffer B reads Buffer A, creating iterative simulations

### Buffer Feedback (Reading Previous Frame)

In Buffer A, bind iChannel0 to "Buffer A" itself. Now `texture(iChannel0, uv)` reads the *previous frame's* output. This enables:

```glsl
// Buffer A: simple trail effect
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Read previous frame (slightly faded)
    vec3 prev = texture(iChannel0, uv).rgb * 0.98;

    // Draw something new on top
    vec2 center = vec2(0.5 + 0.3 * cos(iTime), 0.5 + 0.3 * sin(iTime));
    float d = length(uv - center) - 0.02;
    float dot = smoothstep(0.01, 0.0, d);

    vec3 color = max(prev, vec3(dot));

    fragColor = vec4(color, 1.0);
}
```

This creates a moving dot that leaves fading trails — the foundation of many motion graphics effects.

---

## Code Walkthrough: Retro VHS Effect

Let us combine multiple techniques into a complete VHS/retro tape effect.

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;

    // --- Tracking distortion (horizontal shifts) ---
    float trackingNoise = sin(uv.y * 100.0 + iTime * 5.0)
                        * sin(uv.y * 30.0 - iTime * 3.0)
                        * 0.002;
    // Occasional big glitch
    float glitch = step(0.99, sin(iTime * 2.0 + uv.y * 3.0))
                 * sin(iTime * 50.0) * 0.05;
    uv.x += trackingNoise + glitch;

    // --- Chromatic aberration ---
    vec2 dir = uv - 0.5;
    float caAmount = 0.003 + abs(glitch) * 0.02;
    float r = texture(iChannel0, uv + dir * caAmount).r;
    float g = texture(iChannel0, uv).g;
    float b = texture(iChannel0, uv - dir * caAmount).b;
    vec3 color = vec3(r, g, b);

    // --- Scanlines ---
    float scanline = sin(fragCoord.y * 3.14159) * 0.04;
    color -= scanline;

    // --- Noise grain ---
    float grain = (fract(sin(dot(fragCoord + iTime * 1000.0,
                    vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.08;
    color += grain;

    // --- Color bleed (slight horizontal blur) ---
    color.r = mix(color.r, texture(iChannel0, uv + vec2(texel.x * 2.0, 0.0)).r, 0.15);
    color.b = mix(color.b, texture(iChannel0, uv - vec2(texel.x * 2.0, 0.0)).b, 0.15);

    // --- Vignette ---
    float vig = 1.0 - length((uv - 0.5) * vec2(1.1, 1.0)) * 1.2;
    vig = clamp(vig, 0.0, 1.0);
    color *= vig;

    // --- Slight desaturation (VHS tapes lose color) ---
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(lum), color, 0.8);

    // --- Warm tint ---
    color *= vec3(1.05, 0.98, 0.9);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
```

### What This Demonstrates

- **Tracking distortion** — small horizontal UV offsets based on sine waves simulate magnetic tape wobble
- **Glitch effect** — occasional large offset for dramatic distortion
- **Chromatic aberration** — RGB channel splitting, intensified during glitches
- **Scanlines** — darkened every other row using `sin(fragCoord.y)`
- **Film grain** — per-pixel, per-frame noise
- **Color bleed** — horizontal channel smearing (VHS tapes had limited color bandwidth)
- **Vignette** — darkened edges
- **Desaturation** — reducing color vibrancy
- **Warm tint** — multiply blend with warm color

Each effect is 2–3 lines. The combination creates a convincing retro aesthetic.

---

## GLSL Quick Reference

Functions and concepts introduced in this module:

| Function/Concept | Description | Example |
|---|---|---|
| `texture(sampler, uv)` | Sample a texture at UV coordinate | `texture(iChannel0, uv)` |
| Texel size | UV size of one pixel | `1.0 / iResolution.xy` |
| Repeat/Clamp/Mirror | Texture wrapping at UV boundaries | Set in channel/sampler settings |
| Linear/Nearest | Texture filtering mode | Smooth vs. pixelated |
| Box blur | Average neighbors equally | 3×3 neighborhood / 9 |
| Gaussian blur | Weighted average (center-heavy) | `1 2 1 / 2 4 2 / 1 2 1 ÷ 16` |
| Separable blur | H-pass then V-pass (efficient) | `9+9 = 18` vs `9×9 = 81` samples |
| Sobel operator | Edge detection (gradient) | Horizontal + vertical kernels |
| Sharpen kernel | Center × 5, neighbors × −1 | Amplifies detail |
| Emboss | Directional edge highlight | Simulates carved surface |
| Chromatic aberration | Per-channel UV offset | `R += offset`, `B -= offset` |
| Vignette | Darken edges | `1.0 - smoothstep(r, r+s, dist)` |
| UV distortion | Modify UVs before sampling | `uv.x += sin(uv.y * f) * a` |
| Barrel distortion | Radial UV warp (CRT/fisheye) | `uv *= 1.0 + d² * k` |
| Multi-pass | Buffer A → Buffer B → Image | Separable blur, bloom, feedback |
| Buffer feedback | Buffer reads its own prev frame | Trails, motion blur, automata |

---

## Common Pitfalls

### 1. Forgetting Texel Size

Sampling neighbors at a fixed offset (like `uv + vec2(0.001, 0.0)`) is resolution-dependent. Always compute the texel size:

```glsl
// WRONG — breaks at different resolutions:
vec3 neighbor = texture(tex, uv + vec2(0.001, 0.0)).rgb;

// RIGHT — always exactly one pixel offset:
vec2 texel = 1.0 / iResolution.xy;
vec3 neighbor = texture(tex, uv + vec2(texel.x, 0.0)).rgb;
```

### 2. Sampling Out of Bounds

UV distortion can push coordinates outside 0–1. Depending on wrapping mode, this either tiles or stretches edges. Guard against it:

```glsl
vec2 distortedUV = uv + someOffset;
distortedUV = clamp(distortedUV, 0.0, 1.0);  // Prevent sampling outside
```

### 3. Kernel Weights Not Summing to 1

If your convolution kernel weights do not sum to 1.0, the image gets brighter or darker:

```glsl
// WRONG — weights sum to 9, image 9× brighter:
for (int y = -1; y <= 1; y++)
    for (int x = -1; x <= 1; x++)
        color += texture(tex, uv + vec2(x,y) * texel).rgb;
// Forgot to divide by 9!

// RIGHT:
color /= 9.0;
```

### 4. Blur Performance

A naive large-kernel blur is very expensive. A 15×15 kernel requires 225 texture samples per pixel. Use separable passes:

```
2D 15×15: 225 samples per pixel
Separable 15: 15 + 15 = 30 samples per pixel (7.5× faster)
```

### 5. Buffer Feedback Without Decay

If you read the previous frame without fading it, the buffer accumulates forever and fills with white:

```glsl
// WRONG — accumulates to infinity:
color = max(prev, newStuff);

// RIGHT — fade the previous frame:
color = max(prev * 0.98, newStuff);
```

---

## Exercises

### Exercise 1: Image Filter Gallery

**Time:** 30–45 minutes

Bind an image to iChannel0. Create a shader that splits the screen into sections (3×2 grid) showing the image with different filters:

1. Original (no filter)
2. Grayscale
3. Gaussian blur (3×3)
4. Sobel edge detection
5. Posterization (4 levels)
6. Chromatic aberration

Add thin separator lines between sections.

**Concepts practiced:** Texture sampling, convolution kernels, color manipulation, layout

---

### Exercise 2: Underwater Scene

**Time:** 30–45 minutes

Apply an underwater distortion effect to a texture:

1. Bind an image to iChannel0
2. Apply sine-wave UV distortion (horizontal and vertical at different frequencies)
3. Add a blue-green tint (multiply blend)
4. Add a subtle Gaussian blur for haziness
5. Apply a vignette with a soft blue-tinted edge
6. Add caustic-like patterns on top (use `sin()` interference patterns from Module 4)
7. Animate everything with `iTime`

**Concepts practiced:** UV distortion, tinting, blur, vignette, pattern overlay, animation

---

### Exercise 3: Multi-Pass Bloom

**Time:** 45–60 minutes

Implement a basic bloom effect using ShaderToy's multi-pass system:

1. **Buffer A:** Create a scene with bright SDF elements (glowing circles, shapes). Output the scene.
2. **Buffer B:** Read Buffer A. Extract only the bright parts (threshold). Apply a horizontal blur.
3. **Image:** Read both Buffer A (original) and Buffer B (blurred brights). Add them together.

**Stretch:** Add a second blur pass (vertical) for a proper separable Gaussian. Use multiple radius scales for a multi-resolution bloom that looks more realistic.

**Concepts practiced:** Multi-pass rendering, brightness extraction, separable blur, compositing

---

## Key Takeaways

1. **`texture(channel, uv)` is your window to the outside world.** It samples a color from an image, video, or buffer at the given UV coordinate. Everything in image processing starts here.

2. **Convolution kernels transform images mathematically.** A 3×3 grid of weights applied to pixel neighborhoods can blur, sharpen, detect edges, or emboss. The kernel weights determine the effect. Always normalize weights to sum to 1.0 (for blur/sharpen) or handle the range shift (for edge detection/emboss).

3. **UV distortion warps space, not pixels.** Modify the UV coordinates before sampling to create waves, swirls, barrel distortion, or noise-based organic warping. The texture call does not change — only the coordinates fed into it.

4. **Chromatic aberration splits RGB channels.** Sample each color channel at a slightly different UV, with offset radiating from the center. Subtle amounts add cinematic polish; large amounts create glitch effects.

5. **Multi-pass rendering enables complex effects.** Bloom, separable blur, feedback trails, and iterative simulations all require rendering to an intermediate texture and reading it back. ShaderToy's Buffer system makes this accessible without engine boilerplate.

6. **These techniques are the foundation of post-processing.** Every post-processing effect in every game engine is a combination of the techniques in this module: texture sampling, convolution, UV distortion, color manipulation, and multi-pass compositing.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [LearnOpenGL: Textures](https://learnopengl.com/Getting-started/Textures) | Tutorial | The clearest explanation of texture sampling, filtering, wrapping, and mipmaps. Essential fundamentals. |
| [LearnOpenGL: Framebuffers](https://learnopengl.com/Advanced-OpenGL/Framebuffers) | Tutorial | Render-to-texture explained. Critical for understanding multi-pass rendering and post-processing. |
| [Book of Shaders, Ch. 10 (Generative Designs)](https://thebookofshaders.com/10/) | Interactive tutorial | Generative design with randomness and textures. Bridges procedural and image-based techniques. |
| [Image Kernels Explained Visually](https://setosa.io/ev/image-kernels/) | Interactive tool | Beautiful interactive visualization of convolution kernels. Drag the kernel weights and see the effect live. |
| [ShaderToy Unofficial: Multipass](https://shadertoyunofficial.wordpress.com/2016/02/25/multipass/) | Tutorial | Explains ShaderToy's buffer system with practical examples. Essential for multi-pass effects. |

---

## What's Next?

You have completed the linear core path (Modules 0–6). Congratulations — you can now create procedural shapes, color them with mathematical palettes, tile and transform them into patterns, add organic noise, and process real images. That is a complete 2D shader toolkit.

From here, the roadmap branches. Choose based on your interest:

- **[Module 7: 2D Lighting & Shadows](module-07-2d-lighting-shadows.md)** — Add light and shadow to your SDF scenes. Point lights, normal maps, specular highlights, shadow marching. *(Requires Modules 2 and 5)*
- **[Module 8: The Vertex Shader](module-08-vertex-shader.md)** — Move geometry: MVP matrices, displacement, waves, wind. *(Requires Module 1)*
- **[Module 9: Post-Processing Effects](module-09-post-processing.md)** — Bloom, blur, CRT effects, film grain, color grading applied to entire scenes. *(Requires this module)*
- **[Module 10: Raymarching & 3D SDF Scenes](module-10-raymarching-3d-sdf.md)** — Build entire 3D worlds in a single fragment shader. *(Requires Module 2, benefits from 5 and 7)*
- **[Module 11: Animation, Motion & Interactive](module-11-animation-motion-interactive.md)** — Easing functions, sequencing, audio reactivity, buffer feedback. *(Requires Module 4)*
- **[Module 12: Porting to Engines](module-12-porting-to-engines.md)** — Take your shaders into Godot, Love2D, or React Three Fiber. *(Whenever ready)*

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
