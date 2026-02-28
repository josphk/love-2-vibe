# Module 3: Color, Gradients & Blending

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 3–4 hours
**Prerequisites:** Module 2 (Shapes with SDFs)

---

## Overview

So far, your shaders have used hardcoded colors — `vec3(1.0, 0.0, 0.0)` for red, `vec3(0.3, 0.7, 1.0)` for a nice blue. That works, but it is like painting with only the primary colors straight from the tube. Professional shader art uses procedural color generation: mathematical functions that produce smooth, harmonious color palettes from a handful of parameters.

This module teaches you three things. First, **color spaces** — particularly HSB/HSV, where you can sweep the hue dial while keeping brightness and saturation constant, producing rainbow gradients that look natural instead of garish. Second, **Inigo Quilez's cosine palette formula**, which is arguably the single most useful function in shader art. Four vec3 parameters generate an infinite variety of beautiful, smooth color ramps. Feed it distance, angle, time — anything — and get gorgeous color. Third, **blending modes** — the same operations Photoshop uses to composite layers, implemented as simple per-pixel math.

By the end of this module, you will never hardcode a color again. Every color in your shaders will be derived from the palette function, from HSB mixing, or from mathematical relationships. Your shaders will go from "technically interesting" to "visually beautiful."

---

## 1. RGB Color: What You Already Know (and Its Limits)

You have been using RGB since Module 0:

```glsl
vec3 color = vec3(1.0, 0.5, 0.2);  // R=1.0, G=0.5, B=0.2 → warm orange
```

RGB is intuitive for specific named colors. You know red is `(1,0,0)`, green is `(0,1,0)`, yellow is `(1,1,0)`. But RGB falls apart when you try to do things like:

- "Make this color lighter" → Which channels do you increase? By how much?
- "Shift the hue slightly" → You need to change all three channels in a coordinated way.
- "Create a rainbow gradient" → A linear RGB gradient from red to green passes through ugly muddy brown.
- "Pick a color that is 'the same brightness' as this other color" → Brightness in RGB is not a single channel.

```glsl
// RGB rainbow attempt — muddy transitions:
vec3 c1 = vec3(1.0, 0.0, 0.0);  // Red
vec3 c2 = vec3(0.0, 1.0, 0.0);  // Green
vec3 c3 = vec3(0.0, 0.0, 1.0);  // Blue
// mix(c1, c2, 0.5) = vec3(0.5, 0.5, 0.0) — dark yellow, not a bright hue
```

The problem: RGB mixes along straight lines through the color cube, and those straight lines pass through the desaturated interior. You need a color space where "hue" is a separate dimension you can walk along independently.

---

## 2. HSB / HSV: Hue, Saturation, Brightness

HSB (also called HSV — Hue, Saturation, Value) separates color into three intuitive channels:

- **Hue (H):** The "color" — where you are on the rainbow. 0.0 = red, 0.33 = green, 0.67 = blue, 1.0 = red again (it wraps).
- **Saturation (S):** How vivid the color is. 1.0 = pure color. 0.0 = gray.
- **Brightness / Value (B/V):** How light or dark. 1.0 = full brightness. 0.0 = black.

```
Hue wheel (S=1, B=1):

          0.167 (yellow)
              ●
         ╱         ╲
   0.0 ●               ● 0.333 (green)
  (red)  ╲           ╱
          ●─────────●
     0.833           0.5 (cyan)
    (magenta)    ●
               0.667 (blue)
```

### HSB to RGB Conversion

GLSL does not have a built-in HSB type. You convert to RGB for output. Here is the standard conversion function:

```glsl
vec3 hsb2rgb(vec3 hsb) {
    vec3 rgb = clamp(
        abs(mod(hsb.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
        0.0, 1.0
    );
    return hsb.z * mix(vec3(1.0), rgb, hsb.y);
}
```

This looks like magic, but it is computing a piecewise linear approximation of the hue wheel. You do not need to understand every piece — just copy it and use it.

### Usage

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Hue varies across X, full saturation and brightness
    vec3 color = hsb2rgb(vec3(uv.x, 1.0, 1.0));

    fragColor = vec4(color, 1.0);
}
```

This creates a full rainbow gradient across the screen — smooth, vivid, no muddy transitions.

### Practical HSB Patterns

```glsl
// Rainbow wheel (polar hue)
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
float angle = atan(uv.y, uv.x);
float hue = (angle + 3.14159) / 6.28318;  // Normalize angle to 0–1
vec3 color = hsb2rgb(vec3(hue, 1.0, 1.0));

// Animated hue shift
vec3 color = hsb2rgb(vec3(fract(uv.x + iTime * 0.1), 1.0, 1.0));

// Distance-based hue with constant brightness
float d = length(uv);
vec3 color = hsb2rgb(vec3(d * 2.0 + iTime * 0.2, 0.8, 0.9));
```

### When to Use HSB

HSB is excellent for:
- Rainbow effects (sweep H, keep S and B constant)
- "Shifting" an existing color's hue without changing its brightness
- Color pickers and UI
- Any time you need to think about "hue" as a separate concept

HSB is less ideal for smooth multi-stop gradients and artistic palettes — that is where the cosine palette shines.

---

## 3. The Cosine Palette: Your Most Powerful Tool

Inigo Quilez's cosine palette formula is the single most useful color function in shader art. It generates smooth, beautiful color ramps from four parameters:

```glsl
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}
```

That is it. Five lines including the function signature. But this formula can produce virtually any color scheme.

### How It Works

The function evaluates a cosine curve independently for each RGB channel. The parameters control:

- **`a`** — The "center" or "bias" of the color. Determines the average brightness and tint.
- **`b`** — The "amplitude" of the oscillation. How much each channel varies.
- **`c`** — The "frequency" of the oscillation. How many color cycles per unit of `t`.
- **`d`** — The "phase offset" of each channel. Shifts the oscillation for each RGB channel independently — this is what creates different hues.

```
For one channel (e.g., Red):

  a + b ─ ─ ─ ╭─╮─ ─ ─ ─ ─ ╭─╮─ ─    ← peak
              ╱   ╲         ╱   ╲
  a ─ ─ ─ ─╱── ── ╲── ── ╱── ── ╲─    ← center
           ╱        ╲   ╱        ╲
  a - b ─ ╯─ ─ ─ ─ ─╰─╯─ ─ ─ ─ ─╰    ← trough
           0    0.5    1    1.5    2
                     t →

Each channel (R, G, B) gets its own phase offset (d),
so they peak at different values of t → different hues!
```

### Classic Parameter Sets

Here are some well-known palette configurations. Try each one in ShaderToy:

```glsl
// Rainbow (classic)
palette(t, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.33, 0.67));

// Sunset (warm orange to deep purple)
palette(t, vec3(0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5),
           vec3(1.0, 1.0, 1.0), vec3(0.0, 0.10, 0.20));

// Ocean (deep blue to teal to white)
palette(t, vec3(0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5),
           vec3(1.0, 1.0, 1.0), vec3(0.30, 0.20, 0.20));

// Fire (black to red to yellow to white)
palette(t, vec3(0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5),
           vec3(1.0, 0.7, 0.4), vec3(0.0, 0.15, 0.20));

// Neon (electric colors)
palette(t, vec3(0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5),
           vec3(2.0, 1.0, 0.0), vec3(0.5, 0.20, 0.25));

// Grayscale (for testing — just a sine wave)
palette(t, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0));
```

### Feeding the Palette

The magic of the cosine palette is what you feed into `t`:

```glsl
// Distance from center → radial palette
float t = length(uv);

// Angle → hue wheel
float t = (atan(uv.y, uv.x) + PI) / TAU;

// Time → animated color cycling
float t = iTime * 0.2;

// Distance + time → animated radial palette
float t = length(uv) - iTime * 0.3;

// SDF distance → color based on proximity to shape
float t = sdCircle(uv, 0.3);

// Anything!
float t = sin(uv.x * 10.0) * 0.5 + 0.5;
```

### Using the Palette in a Shader

```glsl
#define PI  3.14159265359
#define TAU 6.28318530718

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TAU * (c * t + d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    float d = length(uv);  // Distance from center
    float t = d - iTime * 0.3;  // Animate outward

    // Sunset palette
    vec3 color = palette(t,
        vec3(0.5, 0.5, 0.5),
        vec3(0.5, 0.5, 0.5),
        vec3(1.0, 1.0, 1.0),
        vec3(0.0, 0.10, 0.20)
    );

    fragColor = vec4(color, 1.0);
}
```

### Interactive Palette Explorer

Visit [iquilezles.org/articles/palettes](https://iquilezles.org/articles/palettes/) for an interactive editor where you can adjust the four parameters in real time and see the resulting palette. This is invaluable for designing your own color schemes.

---

## 4. Gradient Types

A gradient maps a spatial value (position, distance, angle) to a color progression. Here are the fundamental gradient types.

### Linear Gradient

```glsl
// Horizontal
float t = uv.x;

// Vertical
float t = uv.y;

// Diagonal (45 degrees)
float t = (uv.x + uv.y) * 0.5;

// Any angle
float angle = 0.7;  // radians
float t = dot(uv, vec2(cos(angle), sin(angle)));
```

### Radial Gradient

```glsl
float t = length(uv);  // Distance from center
// Optionally remap: t = clamp(t / 0.5, 0.0, 1.0) for a specific radius
```

### Angular Gradient (Conic)

```glsl
float t = (atan(uv.y, uv.x) + PI) / TAU;  // 0 to 1, wrapping around
```

### Diamond Gradient

```glsl
float t = abs(uv.x) + abs(uv.y);  // Manhattan distance from center
```

### Multi-Stop Gradients

Photoshop-style gradients with multiple color stops:

```glsl
vec3 gradient(float t) {
    // 3-stop gradient: blue → white → orange
    vec3 c1 = vec3(0.1, 0.3, 0.8);   // Blue at t=0
    vec3 c2 = vec3(1.0, 1.0, 1.0);   // White at t=0.5
    vec3 c3 = vec3(0.9, 0.5, 0.1);   // Orange at t=1

    if (t < 0.5) {
        return mix(c1, c2, t * 2.0);       // Blue to white
    } else {
        return mix(c2, c3, (t - 0.5) * 2.0); // White to orange
    }
}
```

The `smoothstep` version (branchless):

```glsl
vec3 gradient(float t) {
    vec3 c1 = vec3(0.1, 0.3, 0.8);
    vec3 c2 = vec3(1.0, 1.0, 1.0);
    vec3 c3 = vec3(0.9, 0.5, 0.1);

    vec3 color = mix(c1, c2, smoothstep(0.0, 0.5, t));
    color = mix(color, c3, smoothstep(0.5, 1.0, t));
    return color;
}
```

### Repeating Gradients

```glsl
// Repeating linear gradient (like CSS repeating-linear-gradient)
float t = fract(uv.x * 5.0);  // 5 repetitions across the screen

// Repeating with mirroring (ping-pong)
float t = abs(fract(uv.x * 5.0) - 0.5) * 2.0;  // Triangle wave
```

---

## 5. Blending Modes

Photoshop's layer blend modes are just simple per-pixel math. Knowing the formulas lets you composite layers in real-time shaders.

### Setup

In each blend mode, `base` is the bottom layer and `blend` is the top layer being applied:

```glsl
vec3 base  = /* bottom layer color */;
vec3 blend = /* top layer color */;
vec3 result = /* blend mode formula */;
```

### Normal (Opacity)

```glsl
// Standard alpha blending
vec3 result = mix(base, blend, alpha);
```

### Multiply

```glsl
vec3 result = base * blend;
```

Darkens. Black stays black, white is transparent. Use it for shadows, overlays on dark backgrounds, and tinting. This is the most useful blend mode.

```
Multiply: result = base × blend
White (1.0) × anything = anything  (white is "transparent")
Black (0.0) × anything = 0.0      (black always wins)
0.5 × 0.8 = 0.4                   (darkening)
```

### Screen

```glsl
vec3 result = 1.0 - (1.0 - base) * (1.0 - blend);
```

The opposite of multiply — lightens. Black is transparent, white always wins. Use it for glows, light effects, and brightening.

### Overlay

```glsl
vec3 overlay(vec3 base, vec3 blend) {
    return mix(
        2.0 * base * blend,                      // Dark regions: multiply
        1.0 - 2.0 * (1.0 - base) * (1.0 - blend), // Light regions: screen
        step(0.5, base)
    );
}
```

Overlay combines multiply and screen. Dark base values get darker (multiply), light base values get lighter (screen). It increases contrast while preserving highlights and shadows. Very useful for adding texture detail to a base color.

### Soft Light

```glsl
vec3 softLight(vec3 base, vec3 blend) {
    return mix(
        2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
        sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend),
        step(0.5, blend)
    );
}
```

A gentler version of overlay. Good for subtle tinting and color adjustments.

### Additive

```glsl
vec3 result = base + blend;
// Usually clamped:
vec3 result = min(base + blend, 1.0);
```

Pure light addition. Use it for fire, explosions, glowing effects — anything that emits light. Multiple additive layers get brighter and eventually white.

### Difference

```glsl
vec3 result = abs(base - blend);
```

Creates high-contrast psychedelic effects. Identical colors cancel to black. Opposite colors become bright.

### Practical Blending Example

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Base: gradient background
    vec3 base = mix(vec3(0.1, 0.2, 0.4), vec3(0.4, 0.2, 0.1), uv.y + 0.5);

    // Blend layer: radial glow
    float d = length(uv);
    vec3 glow = vec3(1.0, 0.6, 0.2) * (0.03 / (d * d + 0.01));
    glow = clamp(glow, 0.0, 1.0);

    // Screen blend: the glow adds light on top of the gradient
    vec3 color = 1.0 - (1.0 - base) * (1.0 - glow);

    fragColor = vec4(color, 1.0);
}
```

---

## 6. Color Manipulation Techniques

### Brightness / Luminance

The perceived brightness of a color is not the average of R, G, B. Human eyes are most sensitive to green, then red, then blue. The standard luminance weights:

```glsl
float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}
```

### Desaturation

Blend toward the grayscale luminance value:

```glsl
vec3 desaturate(vec3 color, float amount) {
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    return mix(color, vec3(lum), amount);
}
// amount = 0.0: fully saturated (original)
// amount = 1.0: fully desaturated (grayscale)
```

### Contrast

Remap values to push them away from or toward 0.5:

```glsl
vec3 adjustContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}
// contrast > 1.0: more contrast
// contrast < 1.0: less contrast
// contrast = 1.0: no change
```

### Color Temperature (Warm/Cool)

Shift toward warm (orange) or cool (blue):

```glsl
vec3 adjustTemperature(vec3 color, float temp) {
    // temp > 0: warmer, temp < 0: cooler
    color.r += temp * 0.1;
    color.b -= temp * 0.1;
    return clamp(color, 0.0, 1.0);
}
```

### Tinting

Apply a color tint using multiply blend:

```glsl
vec3 tint = vec3(1.0, 0.9, 0.7);  // Warm tint
vec3 tinted = color * tint;
```

### Inverting

```glsl
vec3 inverted = 1.0 - color;
```

### Posterize (Reduce Color Levels)

```glsl
vec3 posterize(vec3 color, float levels) {
    return floor(color * levels) / levels;
}
// posterize(color, 4.0): reduces each channel to 4 levels
```

---

## 7. SDFs + Color: Putting It Together

The real payoff comes from combining SDFs (Module 2) with procedural color (this module). Here are the key patterns.

### Distance-Based Coloring

Use the SDF distance as input to the palette function:

```glsl
float d = sdCircle(uv, 0.3);
vec3 color = palette(d * 3.0 + iTime, a, b, c, d_params);
```

The distance creates naturally radiating color bands around the shape.

### Multiple SDFs, One Palette

```glsl
float d1 = sdCircle(uv - vec2(-0.2, 0.0), 0.15);
float d2 = sdBox(uv - vec2(0.2, 0.0), vec2(0.1));
float d = min(d1, d2);

// Color the combined shape with palette
vec3 color = palette(d * 5.0 + iTime * 0.5, ...);

// Mask to only show inside the shapes
float mask = smoothstep(0.01, 0.0, d);
color *= mask;
```

### Glowing Shapes with Palette Colors

```glsl
float d = sdCircle(uv, 0.2);
float glow = 0.02 / abs(d);
vec3 color = palette(d * 10.0 + iTime, ...) * glow;
color = clamp(color, 0.0, 1.0);
```

### Per-Shape Coloring

Give each shape its own color from the palette by using the shape index:

```glsl
// Tiled shapes — each tile gets a different color
vec2 id = floor(uv * 5.0);
vec2 localUV = fract(uv * 5.0) - 0.5;

float d = sdCircle(localUV, 0.3);
float shapeID = id.x + id.y * 5.0;  // Unique per tile
vec3 color = palette(shapeID * 0.1 + iTime * 0.2, ...);

float fill = smoothstep(0.01, 0.0, d);
color *= fill;
```

---

## Code Walkthrough: Animated Palette Art

Let us build a complete shader that creates a visually rich piece using cosine palettes and SDFs.

### The Final Shader

```glsl
#define PI  3.14159265359
#define TAU 6.28318530718

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TAU * (c * t + d));
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // --- Coordinate setup ---
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 uv0 = uv;  // Save the original for later

    vec3 finalColor = vec3(0.0);

    // --- Iterative pattern (fractal-like) ---
    for (int i = 0; i < 4; i++) {
        // Tile and center each iteration
        uv = fract(uv * 1.5) - 0.5;

        // SDF: distance from center of each tile
        float d = length(uv);

        // Animate with time and iteration depth
        float t = length(uv0)      // Global distance for color coherence
                + float(i) * 0.4    // Each iteration offsets the palette
                - iTime * 0.3;      // Animate over time

        // Cosine palette (electric neon)
        vec3 color = palette(t,
            vec3(0.5, 0.5, 0.5),
            vec3(0.5, 0.5, 0.5),
            vec3(1.0, 1.0, 1.0),
            vec3(0.263, 0.416, 0.557)
        );

        // Create glowing ring pattern
        d = sin(d * 8.0 + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2);

        // Accumulate with palette color
        finalColor += color * d;
    }

    fragColor = vec4(finalColor, 1.0);
}
```

### What Each Section Does

1. **`uv = fract(uv * 1.5) - 0.5`** — Each iteration tiles the space more finely, creating a fractal-like recursion. The `- 0.5` centers each tile.

2. **`length(uv0) + float(i) * 0.4 - iTime * 0.3`** — The palette input combines global position (for spatial coherence), iteration depth (for color variety), and time (for animation).

3. **`sin(d * 8.0 + iTime) / 8.0`** — Converts the smooth distance field into concentric rings. The `/ 8.0` keeps the amplitude small.

4. **`pow(0.01 / d, 1.2)`** — The inverse-distance creates glow. The `pow` sharpens it slightly.

5. **`finalColor += color * d`** — Additive blending across iterations. Each layer adds its contribution, creating bright spots where rings from different iterations overlap.

This pattern — iterative tiling + cosine palette + SDF glow + additive blending — is behind many of the beautiful abstract shaders you see on ShaderToy.

---

## GLSL Quick Reference

Functions and concepts introduced in this module:

| Function/Concept | Description | Example |
|---|---|---|
| `hsb2rgb(vec3 hsb)` | Convert HSB to RGB color | `hsb2rgb(vec3(hue, 1.0, 1.0))` |
| Cosine palette | `a + b * cos(TAU * (c*t + d))` | `palette(length(uv), a, b, c, d)` |
| `a` parameter | Palette center/bias | `vec3(0.5)` for medium brightness |
| `b` parameter | Palette amplitude | `vec3(0.5)` for full swing |
| `c` parameter | Palette frequency | `vec3(1.0)` for one cycle |
| `d` parameter | Palette phase offset | `vec3(0.0, 0.33, 0.67)` for rainbow |
| `mix(a, b, t)` | Linear blend (gradient) | `mix(blue, red, uv.x)` |
| Multiply blend | `base * blend` | Darkens, useful for shadows |
| Screen blend | `1-(1-base)*(1-blend)` | Lightens, useful for glows |
| Additive blend | `base + blend` | Pure light addition |
| Luminance | `dot(c, vec3(.2126,.7152,.0722))` | Perceptual brightness |
| Desaturation | `mix(color, vec3(lum), amount)` | Toward grayscale |
| Contrast | `(color - 0.5) * k + 0.5` | `k > 1` = more contrast |
| Posterize | `floor(color * n) / n` | Reduce to n color levels |
| Linear gradient | `t = uv.x` (or `.y`, diagonal) | `mix(c1, c2, uv.x)` |
| Radial gradient | `t = length(uv)` | Distance from center |
| Angular gradient | `t = (atan(y,x)+PI)/TAU` | Angle around center |

---

## Common Pitfalls

### 1. Palette Colors Outside 0–1

The cosine palette formula can produce values below 0 or above 1 depending on the parameters. Always clamp:

```glsl
vec3 color = palette(t, a, b, c, d);
color = clamp(color, 0.0, 1.0);
// Or: color = max(color, 0.0); if you want to allow HDR brights
```

Alternatively, choose `a` and `b` so that `a - b >= 0` and `a + b <= 1` for each channel.

### 2. Muddy RGB Interpolation

Linear interpolation in RGB between two vivid colors often passes through gray:

```glsl
// MUDDY — red to cyan through gray:
vec3 color = mix(vec3(1, 0, 0), vec3(0, 1, 1), t);
// At t=0.5: vec3(0.5, 0.5, 0.5) — gray!

// BETTER — interpolate in HSB space:
vec3 hsb1 = vec3(0.0, 1.0, 1.0);   // Red in HSB
vec3 hsb2 = vec3(0.5, 1.0, 1.0);   // Cyan in HSB
vec3 color = hsb2rgb(mix(hsb1, hsb2, t));  // Smooth hue transition
```

Or just use a cosine palette, which avoids the problem entirely.

### 3. Forgetting Additive Blending Clamp

Additive blending (`color += glow`) accumulates and can blow out to white:

```glsl
// Without clamp — everything washes out to white:
for (...) {
    color += glow * palette_color;
}
// color could be vec3(5.0, 3.0, 7.0)

// With clamp — or just let the hardware clamp at output:
fragColor = vec4(color, 1.0);  // Values > 1.0 are clamped to 1.0 at output
// This is often fine — blown-out centers look like bright light
```

### 4. Linear vs. sRGB Color Space

Your monitor displays sRGB, but shader math is linear. If your colors look washed out or too dark, you may need gamma correction:

```glsl
// Approximate gamma correction at output:
color = pow(color, vec3(1.0 / 2.2));  // Linear → sRGB
```

In ShaderToy, this usually is not necessary (the pipeline handles it). In engines, check whether the framebuffer is sRGB.

### 5. Black Background Bias

When building layered effects with additive blending, the result always starts bright against black. If you want a colored background:

```glsl
// Start with a background color, not black:
vec3 color = vec3(0.05, 0.05, 0.1);  // Dark blue, not pure black

// Then add effects on top:
color += glow_effect;
```

---

## Exercises

### Exercise 1: Palette Explorer

**Time:** 20–30 minutes

Create a shader that displays the cosine palette as a gradient bar across the screen, with the four parameters controllable:

1. Display `palette(uv.x, a, b, c, d)` as a horizontal gradient across the full screen width
2. Start with the rainbow parameters: `a=vec3(0.5)`, `b=vec3(0.5)`, `c=vec3(1.0)`, `d=vec3(0.0, 0.33, 0.67)`
3. Try at least 5 different parameter sets from the list in this module
4. Animate the palette over time by adding `iTime * 0.1` to `t`
5. Feed `length(uv)` instead of `uv.x` for a radial version

**Stretch:** Split the screen into 4 horizontal strips, each showing a different palette. This becomes a visual reference card.

**Concepts practiced:** Cosine palette, parameter tuning, spatial/temporal input

---

### Exercise 2: SDF + Palette Artwork

**Time:** 30–45 minutes

Create a visually rich piece that combines SDFs from Module 2 with cosine palette colors:

1. Create 3–5 SDF shapes (circles, boxes, or combined shapes)
2. Use the SDF distance as the palette `t` value — each shape radiates color outward
3. Combine shapes with `min` (union) so the color field blends naturally
4. Add a glow effect (`0.01 / abs(d)`) colored by the palette
5. Animate with `iTime` in both the shape positions and the palette offset

**Stretch:** Use `smin` (smooth union) and observe how the smooth blending affects the color field differently than hard `min`.

**Concepts practiced:** SDF + palette integration, glow, animation, scene composition

---

### Exercise 3: Blend Mode Gallery

**Time:** 30–45 minutes

Create a shader that demonstrates blend modes visually:

1. Create a base layer — a radial gradient or a pattern using `sin()` waves
2. Create a blend layer — a different pattern, maybe animated SDF shapes
3. Split the screen into sections (use `floor(uv.x * 4.0)` for 4 columns)
4. In each section, apply a different blend mode: multiply, screen, overlay, additive
5. Label each section by using a distinct background tint so you can tell them apart

**Stretch:** Let the mouse X position slide between blend modes using `mix()` — interpolating from multiply to screen to overlay continuously.

**Concepts practiced:** Blend mode formulas, visual comparison, layer composition

---

## Key Takeaways

1. **RGB is for final output, HSB is for color thinking.** When you need to sweep through hues, adjust saturation independently, or keep brightness constant while changing color, convert to HSB, manipulate there, then convert back.

2. **The cosine palette is your go-to for beautiful color.** `a + b * cos(TAU * (c * t + d))` generates infinite smooth color ramps from four vec3 parameters. Feed it distance, angle, time, or any scalar value. Learn a few good parameter sets and you will never need to hardcode colors again.

3. **Gradients are just mappings from space to color.** Linear, radial, angular, diamond — they all work the same way: compute a scalar `t` from position, then use `t` to look up a color (via `mix`, `smoothstep`, or `palette`).

4. **Blend modes are per-pixel math.** Multiply (`a * b`) darkens. Screen (`1-(1-a)*(1-b)`) lightens. Additive (`a + b`) adds light. Knowing even these three opens up rich layer composition.

5. **SDF distance is perfect palette input.** Using the distance field as your palette parameter creates naturally radiating color that follows the shape's geometry. This is the bridge between the shape toolkit (Module 2) and the color toolkit (this module).

6. **Iterative patterns with additive color create visual richness.** A simple loop that tiles, computes an SDF, applies a palette, and adds the result to a running total can produce stunningly complex visuals from just a few lines of code.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Inigo Quilez: Palettes](https://iquilezles.org/articles/palettes/) | Interactive article | The definitive source for the cosine palette formula. Includes an interactive editor where you can tweak all four parameters and see the palette in real time. |
| [Book of Shaders, Ch. 6 (Colors)](https://thebookofshaders.com/06/) | Interactive tutorial | HSB color space, color mixing, and interactive experiments. Great for building color intuition. |
| [Photoshop Blend Modes in GLSL](https://mouaif.wordpress.com/2009/01/05/photoshop-math-with-glsl-shaders/) | Reference | Every Photoshop blend mode as a GLSL one-liner. Bookmark this for when you need a specific blend mode formula. |
| [Cosine Gradient Generator](http://dev.thi.ng/gradients/) | Tool | Interactive tool for designing cosine palettes with visual feedback. Export parameters directly. |
| [ColorBrewer](https://colorbrewer2.org/) | Tool | Research-backed color schemes for data visualization. The color palettes are designed for perceptual uniformity — useful for scientific or information-focused shaders. |

---

## What's Next?

You now have shapes (Module 2) and color (this module). The next step is to make them repeat.

In [Module 4: Patterns, Tiling & Transformations](module-04-patterns-tiling-transformations.md), you will learn to use `fract()` and `floor()` to tile your UV space into grids, apply rotation matrices to spin shapes, work in polar coordinates for radial patterns, and warp the coordinate space itself to create organic variations. This is where individual shapes become infinite patterns — wallpaper, kaleidoscopes, brick layouts, hex grids — all from the same small set of coordinate transformations.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
