# Module 1: Coordinates, Uniforms & Math Toolbox

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** Module 0 (GPU Pipeline & First Fragment Shader)

---

## Overview

Module 0 got you writing a fragment shader and thinking in parallel. But if you tried to draw anything beyond a simple gradient, you probably ran into an immediate problem: the coordinate system is messy. Raw `fragCoord` values are in pixels, tied to your window resolution. A circle that looks perfect at 800×600 turns into an oval at 1920×1080. And the origin is at the bottom-left, which feels wrong if you are used to screen-space graphics.

This module fixes all of that. You will learn to normalize, center, and aspect-correct your coordinate system — three transformations that you will apply at the top of nearly every shader you ever write. Once your coordinates are clean, you can reason about where things are without worrying about pixel counts or resolution.

You will also get comfortable with ShaderToy's uniforms — the values the system feeds into your shader every frame — and build up a toolbox of GLSL math functions that you will reach for constantly. Functions like `sin`, `cos`, `fract`, `mod`, and `abs` are not just "math stuff." They are your brushes and chisels. A single `sin(uv.x * 20.0 + iTime)` creates an animated wave pattern. `fract(uv * 5.0)` tiles your entire UV space into a 5×5 grid. `abs(uv.x)` mirrors the left half of the screen onto the right. These are the atoms from which all shader effects are built.

By the end of this module, you will have a coordinate system you trust, a working relationship with time and mouse input, and enough math tools to start creating real patterns and animations. This is the foundation that every subsequent module builds on.

---

## 1. UV Coordinates: The Foundation

The most important two lines in shader programming are these:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    // ...
}
```

That single division transforms your pixel coordinates into **UV coordinates**: a normalized space where `(0.0, 0.0)` is the bottom-left corner and `(1.0, 1.0)` is the top-right corner, regardless of resolution.

### Why Normalize?

Without normalization, your shader is resolution-dependent:

```
fragCoord at 800×600:     fragCoord at 1920×1080:
(0, 0) to (800, 600)     (0, 0) to (1920, 1080)

UV after normalization:    UV after normalization:
(0, 0) to (1, 1)          (0, 0) to (1, 1)   ← Same!
```

A shape drawn at `uv = vec2(0.5, 0.5)` is always at the center. A line at `uv.x = 0.25` is always one-quarter from the left edge. Your shader works the same on a phone screen and a 4K monitor.

### The UV Space

```
(0, 1) ─────────────────── (1, 1)
  │                           │
  │     UV Space              │
  │     (resolution-          │
  │      independent)         │
  │                           │
  │         (0.5, 0.5)        │
  │            ●              │
  │          center           │
  │                           │
(0, 0) ─────────────────── (1, 0)
```

Note that Y still increases upward (bottom-left origin), matching OpenGL convention. If you need top-left origin (like CSS or Canvas), flip Y: `uv.y = 1.0 - uv.y;`.

---

## 2. Centering: Moving the Origin

For many effects — radial gradients, circular shapes, rotations — you want `(0, 0)` at the center of the screen, not the corner. There are two common approaches.

### Method 1: Subtract 0.5

```glsl
vec2 uv = fragCoord / iResolution.xy;  // 0 to 1
uv -= 0.5;                              // -0.5 to 0.5
```

Now the center of the screen is `(0, 0)`. The left edge is `x = -0.5`, the right edge is `x = 0.5`. Simple, but there is a problem: circles are still ovals if the window is not square.

### Method 2: Aspect-Correct Centering (The Standard)

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
```

This is the one you want to memorize. Let us break it down:

1. **`fragCoord - 0.5 * iResolution.xy`** — Shifts the origin to the center of the screen. `0.5 * iResolution.xy` is the pixel coordinate of the center, so subtracting it makes the center `(0, 0)`.

2. **`/ iResolution.y`** — Divides by height *only* (not `.xy`). This normalizes the vertical axis to range from `-0.5` to `0.5`, and the horizontal axis scales proportionally. On a 16:9 display, `uv.x` ranges from about `-0.89` to `0.89` while `uv.y` ranges from `-0.5` to `0.5`.

The key insight: by dividing both axes by the *same* value (`iResolution.y`), circles stay circular. A `length(uv)` of `0.3` is the same physical distance in both X and Y.

```
Centered, aspect-correct UV space (16:9 example):

(-0.89, 0.5) ──────────────────── (0.89, 0.5)
     │                                  │
     │        (0, 0) = center           │
     │           ●                      │
     │                                  │
(-0.89, -0.5) ──────────────────── (0.89, -0.5)
```

### Comparison: Circles in Both Systems

```glsl
// WITHOUT aspect correction — oval on non-square windows:
vec2 uv = fragCoord / iResolution.xy - 0.5;
float d = length(uv);  // Stretched horizontally on widescreen

// WITH aspect correction — always a perfect circle:
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
float d = length(uv);  // Same distance in both axes
```

### Which to Use?

| Situation | Method |
|---|---|
| Full-screen gradients, backgrounds | `fragCoord / iResolution.xy` (0–1 range) |
| Shapes, circles, rotations | `(fragCoord - 0.5 * iResolution.xy) / iResolution.y` (centered, aspect-correct) |
| Text-like layouts, UI elements | `fragCoord / iResolution.xy` (0–1 range, sometimes flipped Y) |

For the rest of this roadmap, unless stated otherwise, assume we are using the centered, aspect-corrected version.

---

## 3. ShaderToy Uniforms: Your Connection to the Outside World

A uniform is a value that stays constant across all pixels for a single frame, but can change between frames. The CPU (or in ShaderToy's case, the JavaScript wrapper) sends these values to the GPU before each frame renders.

ShaderToy provides these uniforms automatically — you do not declare them, just use them:

### The Essential Three

**`iResolution`** (`vec3`) — Viewport dimensions in pixels.

```glsl
iResolution.x   // Width (e.g., 1920.0)
iResolution.y   // Height (e.g., 1080.0)
iResolution.z   // Pixel aspect ratio (usually 1.0, rarely used)
```

Use `.xy` for UV normalization. The `.z` component exists for non-square-pixel displays (old TVs); you can ignore it.

**`iTime`** (`float`) — Seconds since the shader started running.

```glsl
iTime              // e.g., 12.453 (seconds)
sin(iTime)         // Oscillates -1 to 1, period ~6.28 seconds
fract(iTime)       // Sawtooth wave: 0 to 1 every second
fract(iTime * 0.5) // Sawtooth wave: 0 to 1 every 2 seconds
```

`iTime` is your animation clock. It starts at 0 when the shader loads and counts up continuously. Every animated shader uses it.

**`iMouse`** (`vec4`) — Mouse interaction.

```glsl
iMouse.xy   // Current position (in pixels) while mouse button is held down
iMouse.zw   // Position where the mouse button was last pressed (in pixels)
```

Important subtlety: `iMouse.xy` only updates while the mouse button is pressed. When the button is released, it retains the last pressed position. To normalize:

```glsl
vec2 mouse = iMouse.xy / iResolution.xy;  // 0 to 1 range
```

### Other Uniforms

| Uniform | Type | Description |
|---|---|---|
| `iTimeDelta` | `float` | Time since the previous frame (for framerate-independent animation) |
| `iFrame` | `int` | Current frame number (0, 1, 2, ...) |
| `iDate` | `vec4` | Current date: year, month, day, seconds since midnight |
| `iChannelN` | `sampler2D` | Texture inputs (0–3), used with `texture()` — covered in Module 6 |
| `iChannelResolution[N]` | `vec3` | Resolution of each texture channel |
| `iSampleRate` | `float` | Audio sample rate (when audio is bound to a channel) |

You will use `iTimeDelta` and `iFrame` later. For now, `iResolution`, `iTime`, and `iMouse` are all you need.

---

## 4. Time: Making Things Move

The simplest animation is plugging `iTime` into a math function:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Color channels oscillate over time
    float r = sin(iTime) * 0.5 + 0.5;         // Oscillates 0 to 1
    float g = sin(iTime + 2.094) * 0.5 + 0.5;  // Phase-shifted by 2π/3
    float b = sin(iTime + 4.189) * 0.5 + 0.5;  // Phase-shifted by 4π/3

    fragColor = vec4(r, g, b, 1.0);
}
```

This creates a screen that smoothly cycles through colors. The `* 0.5 + 0.5` pattern converts `sin`'s range from `[-1, 1]` to `[0, 1]` — you will use this pattern constantly.

### Controlling Speed

```glsl
sin(iTime)         // One full cycle every ~6.28 seconds (2π seconds)
sin(iTime * 2.0)   // Twice as fast
sin(iTime * 0.5)   // Half as fast
sin(iTime * PI)    // One cycle every 2 seconds (frequency = π, period = 2π/π = 2)
```

ShaderToy does not define `PI` by default. You will typically define your own:

```glsl
#define PI 3.14159265359
#define TAU 6.28318530718   // 2π — a full circle
```

### Combining Time with Position

The magic happens when you combine time with spatial coordinates:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // A moving wave pattern
    float wave = sin(uv.x * 10.0 + iTime);
    wave = wave * 0.5 + 0.5;  // Remap to 0–1

    fragColor = vec4(wave, wave, wave, 1.0);
}
```

`uv.x * 10.0` creates 10 wave cycles across the screen. Adding `iTime` scrolls them to the left. Subtracting `iTime` scrolls them to the right. Change `10.0` to `20.0` for more waves. Change `uv.x` to `uv.y` for vertical waves. Use `length(uv - 0.5)` instead of `uv.x` for radial waves.

### Time-Based Animation Patterns

```glsl
// Sawtooth: ramps from 0 to 1, then jumps back to 0
float saw = fract(iTime);

// Triangle wave: ramps up then down, 0 to 1 to 0
float tri = abs(fract(iTime) - 0.5) * 2.0;

// Square wave: alternates between 0 and 1
float square = step(0.5, fract(iTime));

// Smooth pulse: rises and falls smoothly
float pulse = smoothstep(0.0, 0.3, fract(iTime))
            - smoothstep(0.7, 1.0, fract(iTime));
```

These are the building blocks of all procedural animation. Memorize the sawtooth (`fract`), the triangle wave (`abs(fract - 0.5) * 2.0`), and the square wave (`step(0.5, fract)`). Everything else is a variation.

---

## 5. The Math Toolbox: Shaping Functions

These functions are not just math — they are the vocabulary of shader programming. Each one has a visual shape that you should be able to picture in your head.

### abs(x) — Mirror / V-Shape

```
  │    ╲   ╱
  │     ╲ ╱
  │      V
  └──────┼──────
        0.0
```

`abs(x)` folds negative values to positive. In UV space, `abs(uv.x)` mirrors the right half of the screen onto the left. This means you only need to define a pattern for one side and it appears on both.

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
uv.x = abs(uv.x);  // Now left and right are symmetric
// Draw a shape — it appears on both sides
```

### fract(x) — Sawtooth / Tiling

```
  1│ ╱╱╱╱
   │╱╱╱╱
  0└────────
   0  1  2  3
```

`fract(x)` returns the fractional part of `x`. It goes from 0 to 1, then resets to 0 and goes to 1 again, forever. This is how you tile. `fract(uv * 5.0)` creates a 5×5 grid where each cell has its own local UV from 0 to 1.

```glsl
vec2 tileUV = fract(uv * 5.0);   // Local coordinates within each tile
vec2 tileID = floor(uv * 5.0);   // Which tile am I in? (0,0), (1,0), ..., (4,4)
```

### mod(x, y) — Modular Arithmetic

`mod(x, y)` is `x - y * floor(x / y)`. It is similar to `fract` but with a configurable period:

```glsl
fract(x)    == mod(x, 1.0)   // Period of 1
mod(x, 2.0)                  // Period of 2 (sawtooth 0 to 2)
mod(x, PI)                   // Period of π
```

### sin(x) and cos(x) — Oscillation

```
sin:                 cos:
  1│   ╭╮               1│╮   ╭
   │  ╱  ╲               │ ╲ ╱
  0│─╱────╲─         0│──╲╱──
   │╱      ╲╱            │
 -1│                  -1│
   0   π   2π           0   π   2π
```

`sin` and `cos` oscillate between -1 and 1. They are the same function, phase-shifted by π/2 (a quarter cycle). Key relationships:

```glsl
sin(x) == cos(x - PI/2.0)
sin(x)^2 + cos(x)^2 == 1.0   // Always — this is the unit circle
```

Common patterns:

```glsl
sin(x) * 0.5 + 0.5           // Remap to 0–1 range
sin(x * frequency + phase)    // Control speed and offset
vec2(cos(angle), sin(angle))  // Point on a unit circle at 'angle'
```

### atan(y, x) — Angle

`atan(y, x)` returns the angle (in radians) from the origin to point `(x, y)`. Range: `-π` to `π`. This is essential for polar coordinates:

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
float angle = atan(uv.y, uv.x);   // Angle around the center
float radius = length(uv);         // Distance from center
// Now you have polar coordinates!
```

**Warning:** GLSL's `atan` has two forms. `atan(y, x)` is the two-argument version (like C's `atan2`) and handles all quadrants correctly. `atan(y_over_x)` is the one-argument version and only works for half the circle. Always use the two-argument form for polar coordinates.

### pow(x, n) — Contrast / Gamma

```
n=0.5:  n=1:    n=2:    n=3:
  1│╭     1│╱    1│   ╱  1│    ╱
   ││      │╱     │  ╱    │   ╱
   │╱      │╱     │ ╱     │  ╱
  0└──   0└──   0└──    0└──
   0  1   0  1   0  1    0  1
```

`pow(x, n)` raises `x` to the power `n`. For values between 0 and 1:
- `n < 1`: Pushes values toward 1 (brighter, more contrast at dark end)
- `n = 1`: No change
- `n > 1`: Pushes values toward 0 (darker, more contrast at bright end)

This is exactly how gamma correction works. It is also useful for shaping falloff curves:

```glsl
float falloff = 1.0 - length(uv);          // Linear falloff from center
float softFalloff = pow(falloff, 0.5);      // Softer (brighter near edges)
float hardFalloff = pow(falloff, 3.0);      // Sharper (darker near edges)
```

### clamp(x, lo, hi) — Range Restriction

```glsl
clamp(x, 0.0, 1.0)   // Forces x into the 0–1 range
// Equivalent to: min(max(x, 0.0), 1.0)
```

`clamp` is a safety net. Use it when you know a value *should* be in a range but math might push it outside. Also useful for creating plateaus:

```glsl
// A gradient that maxes out at 0.7 and floors at 0.3
float t = clamp(uv.x, 0.3, 0.7);
```

### sign(x) — Direction

Returns `-1.0`, `0.0`, or `1.0` depending on the sign of `x`. Useful for flipping directions conditionally without an `if` statement:

```glsl
vec2 dir = sign(uv);  // (-1,-1), (-1,1), (1,-1), or (1,1) depending on quadrant
```

---

## 6. Remapping: Converting Between Ranges

One of the most fundamental operations in shader programming is converting a value from one range to another. You do this so often that it becomes second nature.

### The 0–1 Remap Pattern

If you have a value in range `[a, b]` and want to map it to `[0, 1]`:

```glsl
float t = (value - a) / (b - a);
```

For example, `sin` outputs `[-1, 1]`. To remap to `[0, 1]`:

```glsl
float t = (sin(x) - (-1.0)) / (1.0 - (-1.0));
// Simplifies to:
float t = (sin(x) + 1.0) / 2.0;
// Or equivalently:
float t = sin(x) * 0.5 + 0.5;
```

### The General Remap

To map from `[inMin, inMax]` to `[outMin, outMax]`:

```glsl
float remap(float value, float inMin, float inMax, float outMin, float outMax) {
    float t = (value - inMin) / (inMax - inMin);  // Normalize to 0–1
    return outMin + t * (outMax - outMin);          // Scale to output range
}
```

This is so useful that many people define it as a helper function. You could also use `mix()`:

```glsl
float t = (value - inMin) / (inMax - inMin);
float result = mix(outMin, outMax, t);
```

### Common Remapping Scenarios

```glsl
// Distance (0 to ~1.4) → brightness (1 at center, 0 at edges)
float brightness = 1.0 - length(uv) * 2.0;

// Angle (-π to π) → UV (0 to 1) for polar mapping
float u = (angle + PI) / TAU;

// sin output (-1 to 1) → color channel (0 to 1)
float channel = sin(x) * 0.5 + 0.5;
```

---

## 7. Polar Coordinates

Polar coordinates are the shader programmer's secret weapon for radial patterns. Instead of describing a pixel by its `(x, y)` position, you describe it by its `(angle, radius)` from the center.

### Cartesian to Polar

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

float angle  = atan(uv.y, uv.x);  // -π to π (radians)
float radius = length(uv);         // 0 at center, increases outward
```

```
Cartesian:              Polar:
y                       angle = π/2 (top)
│  ● (0.3, 0.4)           │
│ ╱                     ───●─── angle = 0 (right)
│╱ angle                   │
└─────── x              angle = -π/2 (bottom)

                        radius = distance from center
```

### Polar Patterns

Once in polar coordinates, many complex-looking patterns become trivial:

```glsl
// Concentric rings
float rings = sin(radius * 30.0);

// Radial spokes (like a pie chart)
float spokes = sin(angle * 8.0);  // 8 spokes

// Spiral
float spiral = sin(radius * 20.0 - angle * 3.0);

// Starburst (rings modulated by angle)
float star = sin(radius * 20.0 + sin(angle * 6.0) * 2.0);
```

Add `iTime` to any of these for animation:

```glsl
// Expanding rings
float rings = sin(radius * 30.0 - iTime * 5.0);

// Spinning spokes
float spokes = sin(angle * 8.0 + iTime);

// Animated spiral
float spiral = sin(radius * 20.0 - angle * 3.0 + iTime * 2.0);
```

### Polar to Cartesian

Going the other direction (for constructing positions from angle and radius):

```glsl
float angle = iTime;        // Spin over time
float radius = 0.3;         // Fixed distance from center
vec2 point = vec2(cos(angle), sin(angle)) * radius;
// 'point' orbits the origin
```

This is how you make things orbit: `vec2(cos(t), sin(t)) * r` traces a circle of radius `r` as `t` increases.

---

## 8. The Mouse: Interactive Shaders

Mouse input turns static shaders into interactive ones. Here are practical patterns:

### Basic Mouse Position

```glsl
// Normalized mouse position (0 to 1)
vec2 mouse = iMouse.xy / iResolution.xy;

// Centered, aspect-corrected mouse position (matches centered UV)
vec2 mouse = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
```

### Light That Follows the Mouse

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 mouse = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;

    // Distance from this pixel to the mouse
    float d = length(uv - mouse);

    // Inverse-square falloff (like a real light)
    float brightness = 0.02 / (d * d);
    brightness = clamp(brightness, 0.0, 1.0);

    fragColor = vec4(vec3(brightness), 1.0);
}
```

### Mouse Click Detection

```glsl
// iMouse.z > 0.0 when the mouse button is currently pressed
bool mouseDown = iMouse.z > 0.0;

// Use this to toggle effects or trigger animations
float effect = step(0.0, iMouse.z);  // 1.0 when pressed, 0.0 when released
```

### Controlling Parameters with Mouse

```glsl
// Use mouse X to control a parameter (e.g., wave frequency)
float freq = mix(5.0, 50.0, iMouse.x / iResolution.x);
float wave = sin(uv.x * freq + iTime);

// Use mouse Y to control another parameter (e.g., amplitude)
float amp = iMouse.y / iResolution.y;
```

---

## 9. Combining Everything: Patterns from Math

Now that you have the tools, let us see how they combine. Every shader pattern is built from the same small set of operations applied to coordinates.

### Recipe: Concentric Circles

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
float d = length(uv);               // Distance from center
float rings = sin(d * 30.0) * 0.5 + 0.5;  // Sine wave based on distance
fragColor = vec4(vec3(rings), 1.0);
```

Adding `- iTime * 3.0` inside the `sin` makes them pulse outward.

### Recipe: Checkerboard

```glsl
vec2 uv = fragCoord / iResolution.xy;
vec2 grid = floor(uv * 8.0);            // 8x8 grid of tile indices
float checker = mod(grid.x + grid.y, 2.0);  // Alternates 0 and 1
fragColor = vec4(vec3(checker), 1.0);
```

### Recipe: Moving Stripes

```glsl
vec2 uv = fragCoord / iResolution.xy;
float stripes = sin(uv.x * 40.0 + iTime * 5.0) * 0.5 + 0.5;
stripes = step(0.5, stripes);  // Sharpen to hard stripes
fragColor = vec4(vec3(stripes), 1.0);
```

### Recipe: Radial Burst

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
float angle = atan(uv.y, uv.x);
float radius = length(uv);
float burst = sin(angle * 12.0 + radius * 20.0 - iTime * 3.0);
burst = burst * 0.5 + 0.5;
fragColor = vec4(vec3(burst), 1.0);
```

### Recipe: Symmetric Mirror Pattern

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
uv = abs(uv);  // Mirror both axes — four-fold symmetry
float pattern = sin(uv.x * 20.0 + iTime) * sin(uv.y * 20.0 + iTime * 0.7);
pattern = pattern * 0.5 + 0.5;
fragColor = vec4(vec3(pattern), 1.0);
```

The key insight: **every recipe is the same structure.** Set up coordinates → apply math functions → map the result to color. The only things that change are *which* math functions and *how* you combine them.

---

## Code Walkthrough: Animated Gradient with Mouse Control

Let us build a complete shader that ties together coordinates, time, mouse input, and the math toolbox.

### Goal

An animated radial gradient centered on the screen, with:
- Colors that cycle over time
- A pulse effect that radiates outward
- Mouse X controls the number of rings
- Mouse Y controls the speed

### Step 1: Set Up Coordinates

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Centered, aspect-corrected UV
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Distance from center
    float d = length(uv);
}
```

### Step 2: Add Mouse-Controlled Parameters

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float d = length(uv);

    // Mouse X controls ring count (5 to 40)
    float ringCount = mix(5.0, 40.0, iMouse.x / iResolution.x);

    // Mouse Y controls animation speed (0.5 to 5.0)
    float speed = mix(0.5, 5.0, iMouse.y / iResolution.y);
}
```

### Step 3: Create the Ring Pattern

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float d = length(uv);

    float ringCount = mix(5.0, 40.0, iMouse.x / iResolution.x);
    float speed = mix(0.5, 5.0, iMouse.y / iResolution.y);

    // Expanding rings
    float rings = sin(d * ringCount - iTime * speed) * 0.5 + 0.5;
}
```

### Step 4: Add Color That Cycles Over Time

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float d = length(uv);

    float ringCount = mix(5.0, 40.0, iMouse.x / iResolution.x);
    float speed = mix(0.5, 5.0, iMouse.y / iResolution.y);

    float rings = sin(d * ringCount - iTime * speed) * 0.5 + 0.5;

    // Color channels phase-shifted for rainbow cycling
    float r = rings * (sin(iTime * 0.5) * 0.5 + 0.5);
    float g = rings * (sin(iTime * 0.5 + 2.094) * 0.5 + 0.5);
    float b = rings * (sin(iTime * 0.5 + 4.189) * 0.5 + 0.5);

    fragColor = vec4(r, g, b, 1.0);
}
```

### Step 5: Add Vignette and Polish (Final Version)

```glsl
#define PI 3.14159265359

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // --- Coordinate setup ---
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float d = length(uv);  // Distance from center

    // --- Mouse-controlled parameters ---
    float ringCount = mix(5.0, 40.0, iMouse.x / iResolution.x);
    float speed = mix(0.5, 5.0, iMouse.y / iResolution.y);

    // --- Ring pattern ---
    float rings = sin(d * ringCount - iTime * speed) * 0.5 + 0.5;

    // --- Time-cycling color ---
    vec3 color;
    color.r = sin(iTime * 0.5) * 0.5 + 0.5;
    color.g = sin(iTime * 0.5 + 2.094) * 0.5 + 0.5;  // +2π/3
    color.b = sin(iTime * 0.5 + 4.189) * 0.5 + 0.5;   // +4π/3

    // Apply rings to color
    color *= rings;

    // --- Vignette (darken edges) ---
    float vignette = 1.0 - d * 1.2;
    vignette = clamp(vignette, 0.0, 1.0);
    vignette = pow(vignette, 0.8);  // Soften the falloff
    color *= vignette;

    // --- Output ---
    fragColor = vec4(color, 1.0);
}
```

### What This Demonstrates

- **Aspect-correct centering** — circles are always circular
- **`length()`** — radial distance as the basis for a pattern
- **`sin()` with time** — animated expanding rings
- **Phase-shifted `sin()` for color** — RGB channels offset by 2π/3 create a smooth hue cycle
- **Mouse parameters** — `mix()` maps mouse position to useful value ranges
- **Vignette** — `1.0 - d` fades to dark at edges; `pow()` shapes the curve
- **`clamp()`** — prevents negative brightness values

---

## GLSL Quick Reference

Functions and concepts introduced in this module:

| Function/Concept | Description | Example |
|---|---|---|
| UV normalization | `fragCoord / iResolution.xy` → 0–1 range | `vec2 uv = fragCoord / iResolution.xy;` |
| Centered UV | Origin at screen center, aspect-corrected | `vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;` |
| `iTime` | Elapsed time in seconds | `sin(iTime * 2.0)` |
| `iMouse` | Mouse position (xy=current, zw=click) | `iMouse.xy / iResolution.xy` |
| `sin(x)`, `cos(x)` | Oscillation (range -1 to 1) | `sin(uv.x * 10.0 + iTime)` |
| `atan(y, x)` | Angle to point (range -π to π) | `atan(uv.y, uv.x)` |
| `abs(x)` | Absolute value / mirror | `abs(uv.x)` for symmetry |
| `fract(x)` | Fractional part (sawtooth 0–1) | `fract(uv * 5.0)` for tiling |
| `floor(x)` | Round down (tile index) | `floor(uv * 5.0)` |
| `mod(x, y)` | Modulo / repeating range | `mod(x, 2.0)` |
| `pow(x, n)` | Power / gamma / contrast | `pow(color, vec3(2.2))` |
| `sign(x)` | Returns -1, 0, or 1 | `sign(uv.x)` |
| `clamp(x, lo, hi)` | Restrict to range | `clamp(brightness, 0.0, 1.0)` |
| Polar coords | `(angle, radius)` from center | `atan(uv.y, uv.x)`, `length(uv)` |
| Remap `sin` to 0–1 | `sin(x) * 0.5 + 0.5` | `sin(iTime) * 0.5 + 0.5` |

---

## Common Pitfalls

### 1. Forgetting Aspect Ratio Correction

The most common beginner mistake after Module 0. Circles look like ovals, squares look like rectangles.

```glsl
// WRONG — circle becomes oval on widescreen:
vec2 uv = fragCoord / iResolution.xy - 0.5;
float d = length(uv);

// RIGHT — divide both axes by the same value:
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
float d = length(uv);
```

### 2. Using `atan(y/x)` Instead of `atan(y, x)`

The one-argument `atan` only covers half the circle (-π/2 to π/2). The two-argument version handles all four quadrants.

```glsl
// WRONG — only works for right half of the screen:
float angle = atan(uv.y / uv.x);

// RIGHT — works for all quadrants:
float angle = atan(uv.y, uv.x);
```

### 3. The `sin` Range Trap

`sin` returns -1 to 1, not 0 to 1. Using it directly as a color produces negative values (which get clamped to 0, causing harsh cutoffs).

```glsl
// WRONG — harsh black bands where sin is negative:
float c = sin(uv.x * 10.0);
fragColor = vec4(c, c, c, 1.0);

// RIGHT — remap to 0–1:
float c = sin(uv.x * 10.0) * 0.5 + 0.5;
fragColor = vec4(c, c, c, 1.0);
```

### 4. Mouse Position When Not Clicking

`iMouse.xy` in ShaderToy only updates while the mouse button is pressed. Before any click, it is `(0, 0)`. Guard against this:

```glsl
// Guard: use center as default when mouse hasn't been clicked
vec2 mouse = iMouse.xy;
if (mouse == vec2(0.0)) {
    mouse = iResolution.xy * 0.5;  // Default to center
}
mouse = (mouse - 0.5 * iResolution.xy) / iResolution.y;
```

### 5. Confusing Radians and Degrees

All GLSL trig functions use **radians**, not degrees.

```glsl
// WRONG — 90 radians is not a right angle:
float angle = 90.0;
vec2 point = vec2(cos(angle), sin(angle));

// RIGHT — use radians:
float angle = PI / 2.0;  // 90 degrees in radians
vec2 point = vec2(cos(angle), sin(angle));

// Or convert:
float deg2rad = PI / 180.0;
float angle = 90.0 * deg2rad;
```

---

## Exercises

### Exercise 1: Wave Explorer

**Time:** 20–30 minutes

Write a shader that displays a wave pattern and lets you explore how math functions change it. Start with:

```glsl
float wave = sin(uv.x * 10.0) * 0.5 + 0.5;
```

Then modify it:
1. Change `sin` to `cos`, `abs(sin(...))`, `fract`, and `pow(sin(...) * 0.5 + 0.5, 3.0)`. Observe each shape.
2. Make the frequency change based on `uv.y` (so waves get tighter toward the top).
3. Add `iTime` to animate the waves scrolling.
4. Use the mouse X position to control frequency and mouse Y to control amplitude.

**Stretch:** Combine two wave functions — `sin(uv.x * 10.0) * sin(uv.y * 10.0)` — to create a 2D pattern. Add time. Multiply by a radial vignette (`1.0 - length(uv - 0.5)`).

**Concepts practiced:** sin, cos, fract, abs, pow, iTime, iMouse, function shapes

---

### Exercise 2: Polar Pattern Generator

**Time:** 30–45 minutes

Build a shader using polar coordinates that creates a radial pattern. Start from centered, aspect-corrected coordinates.

1. Compute `angle = atan(uv.y, uv.x)` and `radius = length(uv)`
2. Display the angle as a grayscale value: `(angle + PI) / TAU` (normalized to 0–1)
3. Create radial spokes: `sin(angle * 8.0) * 0.5 + 0.5` (8 spokes)
4. Create concentric rings: `sin(radius * 30.0) * 0.5 + 0.5`
5. Combine spokes and rings: multiply them together
6. Add `iTime` to create a spinning/pulsing animation

**Stretch:** Create a spiral by combining angle and radius inside the `sin`: `sin(radius * 20.0 - angle * 3.0 + iTime * 2.0)`. Vary the spiral parameters with the mouse.

**Concepts practiced:** atan, length, polar coordinates, sin with multiple inputs, combining patterns

---

### Exercise 3: Interactive Coordinate Playground

**Time:** 45–60 minutes

Create a shader that demonstrates different coordinate transformations, controlled by the mouse:

1. Start with a simple pattern (checkerboard or concentric circles).
2. Split the screen into quadrants (use `step` on `fragCoord`). In each quadrant, apply a different coordinate transformation to the UV before evaluating the pattern:
   - **Top-left:** Normal (no transform)
   - **Top-right:** `abs(uv)` (mirror)
   - **Bottom-left:** `fract(uv * 3.0)` (tile)
   - **Bottom-right:** Polar coordinates (`atan`/`length`)
3. Add thin lines at the quadrant borders (use `smoothstep` on the absolute distance to 0.5 in both axes).
4. Animate all four quadrants with `iTime`.

**Stretch:** Let the mouse position control a parameter in all four quadrants simultaneously — like the frequency of the base pattern.

**Concepts practiced:** Coordinate transformations, abs, fract, polar, step, smoothstep, layout composition

---

## Key Takeaways

1. **Normalize your coordinates.** `fragCoord / iResolution.xy` gives you resolution-independent UVs. `(fragCoord - 0.5 * iResolution.xy) / iResolution.y` gives you centered, aspect-corrected coordinates where circles stay circular. Memorize both.

2. **`iTime` is your animation clock.** Plug it into `sin`, `fract`, or any math function to create motion. Control speed by multiplying (`iTime * 2.0` for double speed). Control direction by sign (`+ iTime` vs `- iTime`).

3. **Every math function has a visual shape.** `sin` oscillates. `fract` creates sawtooth ramps (tiling). `abs` mirrors. `pow` adjusts contrast. `atan` gives you angles for polar patterns. Learn to picture these shapes in your head — they are the building blocks of every shader effect.

4. **Polar coordinates unlock radial patterns.** `atan(uv.y, uv.x)` for angle, `length(uv)` for radius. Rings, spokes, spirals, starbursts — all trivial in polar space.

5. **The remap pattern is fundamental.** Going from one range to another — especially `sin`'s `[-1, 1]` to `[0, 1]` via `* 0.5 + 0.5` — is something you will do constantly. Understand the general formula: `(value - inMin) / (inMax - inMin)`.

6. **Combine simple functions for complex results.** A single `sin` is boring. `sin(uv.x * 10.0) * sin(uv.y * 10.0)` creates a grid. Add `+ iTime` and it animates. Multiply by `1.0 - length(uv)` and it has a vignette. Layer simple operations for rich effects.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Book of Shaders, Ch. 5 (Shaping Functions)](https://thebookofshaders.com/05/) | Interactive tutorial | Interactive graphs of every key function — `step`, `smoothstep`, `sin`, `pow`, etc. Drag parameters and see the shape change in real time. Essential. |
| [Book of Shaders, Ch. 6 (Colors)](https://thebookofshaders.com/06/) | Interactive tutorial | Color mixing, HSB, and how coordinate-based math maps to color output. |
| [GLSL Built-in Functions (docs.gl)](https://docs.gl/sl4/abs) | Reference | Click through the sidebar for every GLSL function. Bookmark this for when you need the exact behavior of `mod` vs `fract`, or the argument order of `clamp`. |
| [Graphtoy](https://graphtoy.com/) | Tool | Inigo Quilez's online graphing calculator for GLSL functions. Type `sin(x*5.0)`, `fract(x)`, `smoothstep(0.3,0.7,x)` and see the curves live. Invaluable for building intuition. |
| [Desmos](https://www.desmos.com/calculator) | Tool | More powerful graphing calculator. Plot any function and drag parameters with sliders. Great for understanding how `pow`, `sin`, and combinations behave. |

---

## What's Next?

You now have clean, aspect-corrected coordinates, a working knowledge of uniforms, and a toolbox of math functions. You can create patterns, animate them, and respond to mouse input. That is a real toolkit.

In [Module 2: Shapes with Signed Distance Functions](module-02-shapes-sdf.md), you will learn the technique that transforms these abstract patterns into actual shapes — circles, rectangles, lines, and arbitrary geometry — all computed from a single mathematical function. SDFs are the foundation of 2D shader graphics and the gateway to raymarching in 3D. The distance-to-shape concept is one of the most powerful ideas in this entire roadmap.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
