# Module 5: Noise — Perlin, Simplex, Cellular, FBM

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** Module 4 (Patterns, Tiling & Transformations)

---

## Overview

Everything you have built so far is clean, geometric, and mathematical. Real things are not. Mountains are not sine waves. Fire is not a gradient. Clouds are not circles. To make anything look natural, you need **noise** — controlled randomness that is smooth, continuous, and coherent.

Noise in shader programming is not `random()`. A random value per pixel gives you television static — useless for anything visual. Shader noise is *structured* randomness: random values at grid points, smoothly interpolated between them, producing hills and valleys that vary in a natural-looking way. This is what Ken Perlin invented in 1983 (for the movie *Tron*), and it remains the foundation of procedural generation in every game engine, film pipeline, and VFX tool in existence.

This module covers four types of noise, each with a distinct visual character:

1. **Value noise** — Random values at grid points, smoothly interpolated. Simple and fast.
2. **Gradient (Perlin) noise** — Random gradients at grid points. Smoother and less grid-aligned than value noise.
3. **Simplex noise** — A modern improvement on Perlin. Fewer directional artifacts, faster in higher dimensions.
4. **Cellular (Voronoi/Worley) noise** — Distance to nearest random feature points. Produces cell-like organic patterns.

Then the real power tool: **fractal Brownian Motion (fBM)**, which layers multiple octaves of noise at increasing frequency and decreasing amplitude to create rich, natural-looking terrain, clouds, and textures. And finally, **domain warping** — using noise to distort the input to *more* noise — which creates the swirling, organic patterns that define a whole genre of shader art.

---

## 1. Why Not Just Use `random()`?

Let us see what plain randomness looks like:

```glsl
// Pure random noise — TV static
float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    float n = random(uv * 500.0);
    fragColor = vec4(vec3(n), 1.0);
}
```

This gives you grainy static — every pixel is independent, with no relationship to its neighbors. It is useless for terrain, clouds, or any natural phenomenon because natural things have **spatial coherence**: a mountain peak does not have a valley next to it at the pixel level. Things that are close together tend to have similar values.

Noise functions solve this by guaranteeing smoothness: nearby points in space produce similar (but not identical) values. The result looks like rolling hills seen from above — random but gentle.

---

## 2. Value Noise: The Simplest Noise

Value noise assigns random values to grid points and smoothly interpolates between them.

### Implementation

```glsl
// Hash function: pseudo-random float from a 2D coordinate
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Value noise
float valueNoise(vec2 p) {
    vec2 i = floor(p);  // Integer part (grid cell)
    vec2 f = fract(p);  // Fractional part (position within cell)

    // Random values at the four corners of the cell
    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    // Smooth interpolation (cubic Hermite curve)
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Bilinear interpolation with smooth curve
    return mix(mix(a, b, u.x),
               mix(c, d, u.x), u.y);
}
```

### How It Works

```
Grid with random values at corners:

  0.7 ──────── 0.3
   │              │
   │   ●          │    ● = point being evaluated
   │   f=(0.3,0.4)│    Interpolates between all 4 corners
   │              │    using smooth curve
  0.1 ──────── 0.9
```

1. `floor(p)` identifies which grid cell you are in.
2. `fract(p)` gives your position within that cell (0 to 1 in each axis).
3. `hash()` generates a pseudo-random value at each corner.
4. The smoothstep-like curve `f * f * (3.0 - 2.0 * f)` smooths the interpolation so there are no sharp edges at cell boundaries.
5. Two nested `mix()` calls perform bilinear interpolation.

### The Smoothing Curve

The line `vec2 u = f * f * (3.0 - 2.0 * f);` is crucial. Without it, you get linear interpolation, which produces visible grid lines at cell boundaries. The cubic Hermite curve has zero derivative at 0 and 1, so the transition between cells is seamless.

```
Linear interpolation:      Smooth interpolation:
      ╱                          ╭─╮
     ╱                          ╱   ╲
    ╱                          ╱     ╲
   ╱                          ╱       ╲
  ╱                          ╱         ╲
Visible grid seams!          No visible seams
```

An even smoother option is the quintic curve: `f * f * f * (f * (f * 6.0 - 15.0) + 10.0)`. This is what Perlin used in his "improved" noise (2002). It has zero first *and* second derivatives at the boundaries.

### Using It

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    float n = valueNoise(uv * 10.0);  // 10x10 grid of noise

    fragColor = vec4(vec3(n), 1.0);
}
```

The `* 10.0` controls the scale (frequency) of the noise. Larger values = more detailed, higher-frequency noise. Smaller values = smoother, lower-frequency noise.

---

## 3. Gradient (Perlin) Noise

Gradient noise is what most people mean when they say "Perlin noise." Instead of random *values* at grid points, it uses random *gradients* (direction vectors). This produces smoother results with less visible grid alignment.

### Implementation

```glsl
vec2 hashGrad(vec2 p) {
    // Random gradient (unit vector) at grid point
    float angle = hash(p) * 6.28318;
    return vec2(cos(angle), sin(angle));
}

float gradientNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Gradients at four corners
    vec2 g00 = hashGrad(i + vec2(0.0, 0.0));
    vec2 g10 = hashGrad(i + vec2(1.0, 0.0));
    vec2 g01 = hashGrad(i + vec2(0.0, 1.0));
    vec2 g11 = hashGrad(i + vec2(1.0, 1.0));

    // Vectors from corners to the point
    vec2 d00 = f - vec2(0.0, 0.0);
    vec2 d10 = f - vec2(1.0, 0.0);
    vec2 d01 = f - vec2(0.0, 1.0);
    vec2 d11 = f - vec2(1.0, 1.0);

    // Dot products (projection of displacement onto gradient)
    float v00 = dot(g00, d00);
    float v10 = dot(g10, d10);
    float v01 = dot(g01, d01);
    float v11 = dot(g11, d11);

    // Smooth interpolation
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);  // Quintic curve

    return mix(mix(v00, v10, u.x),
               mix(v01, v11, u.x), u.y);
}
```

### How It Differs from Value Noise

```
Value noise:                 Gradient noise:
Random VALUES at corners     Random DIRECTIONS at corners
  0.7 ──── 0.3                ↗ ──── ↙
   │          │                │        │
   │          │                │        │
  0.1 ──── 0.9                ↘ ──── ↗

Result: Blobby lumps           Result: Smoother, more organic
Visibly grid-aligned           Less grid bias
```

The dot product between the gradient and the displacement creates natural-looking variation that does not align with the grid axes. This is why gradient noise looks more organic than value noise.

### Range

Value noise outputs 0 to 1. Gradient noise outputs approximately -0.7 to 0.7 (the exact range depends on implementation). To use it as a color:

```glsl
float n = gradientNoise(uv * 10.0);
n = n * 0.5 + 0.5;  // Remap to 0–1
```

---

## 4. Simplex Noise

Simplex noise (also by Ken Perlin, 2001) is an improvement over gradient noise. It uses a **simplex grid** (triangles in 2D, tetrahedra in 3D) instead of a square grid, which reduces directional artifacts and is computationally cheaper in higher dimensions.

### Why Simplex?

```
Square grid (Perlin):       Simplex grid:
┌──┬──┬──┐                  ╱╲╱╲╱╲
├──┼──┼──┤                  ╲╱╲╱╲╱
├──┼──┼──┤                  ╱╲╱╲╱╲
└──┴──┴──┘

4 corners per cell          3 corners per cell (2D)
4 gradients to evaluate     3 gradients to evaluate
Visible axis alignment      Less directional bias
```

In 2D, simplex noise evaluates 3 points per sample (triangle corners) versus 4 for Perlin (square corners). In 3D, it is 4 versus 8. In 4D, it is 5 versus 16. The savings grow dramatically with dimension count.

### Implementation

A full simplex noise implementation is around 30 lines. Here is a compact, widely-used 2D version:

```glsl
// Simplex 2D noise (compact version)
vec3 permute(vec3 x) { return mod(((x * 34.0) + 1.0) * x, 289.0); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                       -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}
```

You do not need to understand every line. Copy this function and use it:

```glsl
float n = snoise(uv * 5.0);           // Range: approximately -1 to 1
float n01 = snoise(uv * 5.0) * 0.5 + 0.5;  // Remapped to 0–1
```

### When to Use Which Noise

| Noise Type | Visual Character | Performance | When to Use |
|---|---|---|---|
| Value | Blobby, grid-aligned | Fast | Quick prototyping, when quality does not matter |
| Gradient (Perlin) | Smooth, organic | Medium | General purpose, most tutorials use this |
| Simplex | Smooth, less directional | Best (especially 3D+) | Production use, higher dimensions |

In practice, for 2D ShaderToy shaders, the visual difference between Perlin and simplex is subtle. Use whichever implementation you have handy.

---

## 5. Cellular (Voronoi / Worley) Noise

Cellular noise produces a completely different look — cell-like structures that resemble biological tissue, cracked earth, or stained glass.

### The Algorithm

1. Scatter random feature points across a grid.
2. For each pixel, find the distance to the nearest feature point.
3. That distance is the noise value.

```
    ●               ●
         ╲      ╱
          ╲    ╱         ●
   ●       ╲  ╱
            ╳ ← this pixel
           ╱  ╲
          ╱    ╲
  ●      ╱      ╲
                   ●
                          ●

Distance to NEAREST ● = the noise value
```

### Implementation

```glsl
float voronoi(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float minDist = 1.0;

    // Check current cell and all 8 neighbors
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));

            // Random position within the neighboring cell
            vec2 point = vec2(
                hash(i + neighbor),
                hash(i + neighbor + vec2(31.0, 17.0))
            );

            // Distance from the pixel to this feature point
            float d = length(f - neighbor - point);
            minDist = min(minDist, d);
        }
    }

    return minDist;
}
```

### Variations

Different distance metrics produce different looks:

```glsl
// Euclidean distance (round cells)
float d = length(f - neighbor - point);

// Manhattan distance (diamond cells)
vec2 diff = abs(f - neighbor - point);
float d = diff.x + diff.y;

// Chebyshev distance (square cells)
vec2 diff = abs(f - neighbor - point);
float d = max(diff.x, diff.y);
```

### Second-Nearest Distance

The difference between the nearest and second-nearest distances creates the cell edges:

```glsl
float voronoiEdges(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float d1 = 1.0;  // Nearest
    float d2 = 1.0;  // Second nearest

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = vec2(
                hash(i + neighbor),
                hash(i + neighbor + vec2(31.0, 17.0))
            );
            float d = length(f - neighbor - point);

            if (d < d1) {
                d2 = d1;
                d1 = d;
            } else if (d < d2) {
                d2 = d;
            }
        }
    }

    return d2 - d1;  // Edge detection: small near boundaries, large in cell centers
}
```

### Animated Voronoi

Animate the feature points by adding time:

```glsl
vec2 point = vec2(
    hash(i + neighbor),
    hash(i + neighbor + vec2(31.0, 17.0))
);
// Animate feature points
point = 0.5 + 0.5 * sin(iTime + point * 6.28);
```

Now the cells pulse and morph organically — like a living tissue under a microscope.

---

## 6. Fractal Brownian Motion (fBM)

A single octave of noise looks like gentle rolling hills. Real terrain has detail at every scale — broad valleys, medium ridges, small rocks, tiny pebbles. **fBM** creates this multi-scale detail by layering noise at increasing frequencies.

### The Principle

Layer multiple octaves of noise, each with:
- **Double the frequency** (more detail per unit of space)
- **Half the amplitude** (less influence on the final shape)

```
Octave 1 (f=1, a=1):     Octave 2 (f=2, a=0.5):    Sum:
  ╭────╮                    ╭╮  ╭╮                   ╭─╮──╮
 ╱      ╲                  ╱  ╲╱  ╲                 ╱   ╲  ╲
╱        ╲                ╱        ╲               ╱     ╲  ╲
           ╲╱           ╱╲          ╲╱           ╱╲       ╲╱
                        (fine detail)            (combined!)
```

### Implementation

```glsl
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 6; i++) {
        value += amplitude * snoise(p * frequency);
        frequency *= 2.0;    // Lacunarity: frequency multiplier
        amplitude *= 0.5;    // Gain: amplitude multiplier
    }

    return value;
}
```

### Parameters

- **Octaves** (loop count): More octaves = more detail, but more expensive. 4–8 is typical.
- **Lacunarity** (frequency multiplier): Usually 2.0. Higher values skip frequency bands, creating a coarser look.
- **Gain** (amplitude multiplier): Usually 0.5. Higher values make fine details more prominent. Lower values make the large-scale features dominate.

```glsl
// Default: natural terrain look
fbm with lacunarity=2.0, gain=0.5

// Rocky, detailed terrain
fbm with lacunarity=2.0, gain=0.6   // More weight on fine detail

// Smooth, billowy clouds
fbm with lacunarity=2.0, gain=0.4   // Less fine detail

// Unusual: skip frequencies
fbm with lacunarity=3.0, gain=0.5   // Different character
```

### fBM Visual Character by Octave Count

```
1 octave:  Gentle rolling hills
2 octaves: Hills with ridges
4 octaves: Realistic terrain
6 octaves: Highly detailed landscape
8 octaves: Extreme detail (usually overkill for visual use)
```

### Using fBM

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Terrain-like heightmap
    float height = fbm(uv * 3.0);
    height = height * 0.5 + 0.5;  // Remap from ~(-1,1) to (0,1)

    // Color based on height
    vec3 color;
    if (height < 0.4) {
        color = vec3(0.1, 0.3, 0.6);  // Water (deep)
    } else if (height < 0.45) {
        color = vec3(0.7, 0.7, 0.5);  // Sand
    } else if (height < 0.7) {
        color = vec3(0.2, 0.5, 0.1);  // Grass
    } else if (height < 0.85) {
        color = vec3(0.4, 0.3, 0.2);  // Rock
    } else {
        color = vec3(0.9, 0.9, 0.95); // Snow
    }

    fragColor = vec4(color, 1.0);
}
```

---

## 7. Domain Warping with Noise

Domain warping (introduced conceptually in Module 4) reaches its full potential when combined with noise. Instead of `sin()`-based distortion, you use noise to warp coordinates — creating organic, flowing, unpredictable distortions.

### Basic Domain Warping

```glsl
float warpedFBM(vec2 p) {
    // Use noise to offset the input coordinates
    vec2 offset = vec2(
        fbm(p + vec2(0.0, 0.0)),
        fbm(p + vec2(5.2, 1.3))
    );

    return fbm(p + offset * 2.0);
}
```

The `+ vec2(5.2, 1.3)` ensures the X and Y warping use different noise values (otherwise both axes would be distorted identically, creating an unnatural look).

### Double Warp (Inigo Quilez Style)

Feed the warped result through another layer of warping:

```glsl
float doubleWarp(vec2 p) {
    // First warp
    vec2 q = vec2(
        fbm(p + vec2(0.0, 0.0)),
        fbm(p + vec2(5.2, 1.3))
    );

    // Second warp — feed q into another fbm
    vec2 r = vec2(
        fbm(p + 4.0 * q + vec2(1.7, 9.2) + 0.15 * iTime),
        fbm(p + 4.0 * q + vec2(8.3, 2.8) + 0.126 * iTime)
    );

    return fbm(p + 4.0 * r);
}
```

This creates swirling, fluid, organic patterns that look like paint mixing in water or alien biological growths. The `iTime` offsets in the second warp layer create slow, hypnotic animation.

### Coloring Domain-Warped Noise

```glsl
#define TAU 6.28318530718

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0) * t + vec3(0.0, 0.1, 0.2)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv *= 2.0;

    // Double domain warp
    vec2 q = vec2(
        fbm(uv),
        fbm(uv + vec2(5.2, 1.3))
    );

    vec2 r = vec2(
        fbm(uv + 4.0 * q + vec2(1.7, 9.2) + iTime * 0.15),
        fbm(uv + 4.0 * q + vec2(8.3, 2.8) + iTime * 0.126)
    );

    float f = fbm(uv + 4.0 * r);

    // Use both the warp vectors and final value for coloring
    vec3 color = palette(f + length(q) * 0.5);

    // Darken based on warp intensity
    color *= mix(vec3(0.2, 0.1, 0.3), vec3(1.0), f * f);

    fragColor = vec4(color, 1.0);
}
```

This is the technique behind Inigo Quilez's famous "warping" article and many of the most visually striking abstract shaders on ShaderToy.

---

## 8. Noise Applications

### Terrain

```glsl
float terrain(vec2 p) {
    float height = fbm(p * 2.0);
    // Sharpen ridges
    height = abs(height);  // Creates sharp creases
    return height;
}
```

The `abs()` trick on noise creates ridge-like features — the valleys become sharp creases. This is called **ridged noise** and it makes convincing mountain ranges.

### Turbulence

```glsl
float turbulence(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 6; i++) {
        value += amplitude * abs(snoise(p * frequency));  // abs!
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}
```

Turbulence is fBM with `abs()` applied to each octave. It creates billowy, cloud-like patterns with sharp crease lines.

### Fire

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    uv.y = 1.0 - uv.y;  // Flip Y so fire rises from bottom

    // Stretch vertically for flame shape
    float n = fbm(vec2(uv.x * 3.0, uv.y * 2.0 - iTime * 2.0));

    // Fade out toward top
    float fade = 1.0 - uv.y;
    n *= fade;

    // Fire colors
    vec3 color = vec3(0.0);
    color += vec3(1.5, 0.5, 0.0) * smoothstep(0.1, 0.5, n);  // Orange
    color += vec3(1.5, 1.0, 0.0) * smoothstep(0.3, 0.8, n);  // Yellow core
    color += vec3(0.5, 0.0, 0.0) * smoothstep(0.0, 0.3, n);  // Red edges

    fragColor = vec4(color, 1.0);
}
```

### Clouds

```glsl
float clouds(vec2 p) {
    float n = fbm(p + iTime * vec2(0.1, 0.05));
    n = smoothstep(0.3, 0.7, n * 0.5 + 0.5);  // Threshold to create distinct clouds
    return n;
}
```

### Water / Waves

```glsl
float water(vec2 p) {
    float t = iTime * 0.5;
    // Two overlapping noise layers at different angles
    float n1 = snoise(p * 3.0 + vec2(t, t * 0.7));
    float n2 = snoise(p * 5.0 + vec2(-t * 0.5, t * 0.3));
    return (n1 + n2 * 0.5) / 1.5;
}
```

### Marble / Wood Grain

```glsl
// Marble: noise used to perturb a regular stripe pattern
float marble(vec2 p) {
    float n = fbm(p * 2.0);
    return sin(p.x * 10.0 + n * 8.0) * 0.5 + 0.5;
}

// Wood grain: noise perturbs concentric circles
float woodGrain(vec2 p) {
    float n = fbm(p * 0.5);
    float grain = sin(length(p) * 20.0 + n * 10.0) * 0.5 + 0.5;
    return grain;
}
```

---

## Code Walkthrough: Animated Terrain with Atmosphere

```glsl
// --- Noise functions (copy from earlier sections) ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 6; i++) {
        v += a * valueNoise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// --- Main shader ---
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Sky ---
    vec3 skyColor = mix(
        vec3(0.9, 0.6, 0.3),  // Horizon (warm)
        vec3(0.2, 0.3, 0.7),  // Zenith (blue)
        pow(uv.y, 0.8)
    );

    // Sun
    vec2 sunPos = vec2(0.7, 0.85);
    float sunDist = length(uv - sunPos);
    float sun = 0.01 / (sunDist * sunDist + 0.01);
    skyColor += vec3(1.0, 0.8, 0.4) * sun * 0.3;

    // Clouds
    float cloudNoise = fbm(vec2(uv.x * 3.0 + iTime * 0.02, uv.y * 1.5));
    float clouds = smoothstep(0.4, 0.7, cloudNoise);
    clouds *= smoothstep(0.5, 0.8, uv.y);  // Only in upper sky
    skyColor = mix(skyColor, vec3(1.0, 0.95, 0.9), clouds * 0.7);

    // --- Terrain ---
    // The terrain is a 1D noise function sampled at uv.x
    float terrainHeight = fbm(vec2(uv.x * 4.0 + iTime * 0.01, 0.0)) * 0.3 + 0.15;

    // Layer 2: distant mountains (smaller, higher)
    float mtHeight = fbm(vec2(uv.x * 2.0 + 100.0, 0.0)) * 0.2 + 0.35;

    vec3 color = skyColor;

    // Distant mountains
    if (uv.y < mtHeight) {
        float fog = smoothstep(0.0, 0.4, mtHeight - uv.y);
        vec3 mtColor = mix(vec3(0.5, 0.5, 0.6), vec3(0.3, 0.3, 0.5), fog);
        color = mtColor;
    }

    // Foreground terrain
    if (uv.y < terrainHeight) {
        float depth = smoothstep(0.0, 0.3, terrainHeight - uv.y);
        vec3 groundColor = mix(
            vec3(0.2, 0.4, 0.1),  // Grass
            vec3(0.1, 0.2, 0.05), // Dark ground
            depth
        );
        color = groundColor;
    }

    // --- Atmospheric fog ---
    // Apply fog to distant mountains
    float fogAmount = smoothstep(0.15, 0.5, uv.y) * 0.3;
    color = mix(color, vec3(0.7, 0.7, 0.8), fogAmount * step(uv.y, mtHeight));

    fragColor = vec4(color, 1.0);
}
```

### What This Demonstrates

- **fBM for terrain** — multiple octaves create natural-looking mountain silhouettes
- **fBM for clouds** — the same noise function at different scales creates cloud cover
- **Layered composition** — sky, distant mountains, foreground terrain composited back-to-front
- **Atmospheric effects** — fog blending, sun glow, warm/cool color gradients
- **Slow animation** — multiplying `iTime` by small values (0.01, 0.02) creates imperceptible drift

---

## GLSL Quick Reference

Functions and concepts introduced in this module:

| Function/Concept | Description | Example |
|---|---|---|
| `hash(p)` | Pseudo-random float from vec2 | `fract(sin(dot(p, ...)) * 43758.5)` |
| `valueNoise(p)` | Random values at grid, interpolated | Blobby, grid-aligned |
| `gradientNoise(p)` | Random gradients at grid, interpolated | Smooth, organic |
| `snoise(p)` | Simplex noise (compact implementation) | Smooth, no grid bias |
| `voronoi(p)` | Distance to nearest feature point | Cell-like patterns |
| `fbm(p)` | Layered noise octaves | Terrain, clouds, fire |
| Lacunarity | Frequency multiplier per octave | Usually 2.0 |
| Gain | Amplitude multiplier per octave | Usually 0.5 |
| Domain warping | `fbm(p + fbm(p))` | Swirling organic distortion |
| Ridged noise | `abs(noise(p))` | Sharp crease lines |
| Turbulence | fBM with `abs()` per octave | Billowy, cloud-like |
| Voronoi edges | `d2 - d1` (second - nearest distance) | Cell boundaries |
| Marble | `sin(x * freq + noise * amp)` | Veined stone texture |

---

## Common Pitfalls

### 1. Noise Range Assumptions

Different noise types have different ranges. Always know your noise's range and remap if needed.

```glsl
// Value noise: 0 to 1 (no remapping needed for color)
// Gradient/Perlin noise: ~-0.7 to 0.7 (remap to 0–1)
// Simplex noise: ~-1 to 1 (remap to 0–1)
// fBM: varies based on gain (can exceed ±1)
```

### 2. Too Few Octaves Looks Boring, Too Many Is Invisible

After about 6 octaves, additional detail is below pixel resolution for typical screen sizes. Adding more just wastes GPU cycles.

```glsl
// Usually 4-6 octaves is the sweet spot for visual quality vs. performance
for (int i = 0; i < 6; i++) { ... }
```

### 3. Hash Function Quality

The `fract(sin(dot(...)))` hash works on most GPUs but can produce visible patterns on some mobile or AMD hardware. If you see banding or repetition, try different magic numbers or a different hash:

```glsl
// Alternative hash (integer-based, more robust):
float hash(vec2 p) {
    uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673u, 3812015801u);
    uint n = (q.x ^ q.y) * 1597334673u;
    return float(n) * (1.0 / float(0xffffffffu));
}
```

### 4. Noise Looks Static Without Time

Adding `iTime` to the noise input creates animation. But adding it directly shifts the entire pattern, which can look like it is sliding:

```glsl
// Sliding pattern:
float n = fbm(uv + iTime);

// Better: animate specific octaves or use a separate time dimension:
float n = fbm(vec2(uv.x, uv.y + iTime * 0.1));
```

For domain warping, adding time to the warp offsets (not the base coordinates) creates organic churning without sliding.

### 5. Domain Warp Amplitude

Too much warping creates visual soup. Start subtle and increase:

```glsl
// TOO MUCH — unreadable mess:
result = fbm(p + 10.0 * vec2(fbm(p), fbm(p + 100.0)));

// GOOD — organic but still structured:
result = fbm(p + 2.0 * vec2(fbm(p), fbm(p + 100.0)));
```

---

## Exercises

### Exercise 1: Noise Comparison

**Time:** 30–40 minutes

Create a shader that displays four noise types side by side (split screen into quadrants):

1. **Top-left:** Value noise
2. **Top-right:** Gradient (Perlin) noise
3. **Bottom-left:** fBM (6 octaves) using value or gradient noise
4. **Bottom-right:** Voronoi (cellular) noise

Use the same scale for all four so you can compare their visual character. Animate all with `iTime`. Add a thin separator line between quadrants.

**Concepts practiced:** Multiple noise implementations, visual comparison, layout

---

### Exercise 2: Procedural Landscape

**Time:** 45–60 minutes

Create a landscape scene using noise:

1. Use fBM for a mountain silhouette (sample noise at `uv.x` values, use as height)
2. Add a second, higher mountain range in the background with less detail
3. Create clouds with thresholded fBM in the upper sky
4. Color the sky with a gradient (warm at horizon, cool at zenith)
5. Add atmospheric fog between layers using `mix()`
6. Slowly animate everything with `iTime`

**Stretch:** Add water at the bottom with a reflected, inverted terrain silhouette. Animate the water surface with a second noise layer.

**Concepts practiced:** fBM, terrain generation, layered composition, atmospheric effects

---

### Exercise 3: Domain-Warped Art

**Time:** 45–60 minutes

Create an abstract art piece using domain warping:

1. Implement `fbm(p + fbm(p))` — single-layer domain warp
2. Color it with a cosine palette (Module 3)
3. Add a second warp layer: `fbm(p + 4.0 * q + time)` where `q` is the first warp
4. Use the intermediate warp vectors (`q`, `r`) to vary the color as well
5. Experiment with different warp amplitudes (the `4.0` multiplier)

The goal is to create something that looks like swirling paint, fluid dynamics, or alien biology. Share it on ShaderToy.

**Concepts practiced:** Domain warping, fBM, cosine palette, animation, artistic expression

---

## Key Takeaways

1. **Noise is structured randomness.** Not TV static — smooth, continuous variation that looks natural. Every type (value, gradient, simplex, cellular) generates this coherent randomness differently, producing distinct visual characters.

2. **fBM is noise at multiple scales.** Layer octaves with increasing frequency and decreasing amplitude. The loop is simple: `value += amplitude * noise(p * frequency); frequency *= 2.0; amplitude *= 0.5;`. More octaves = more detail.

3. **Domain warping creates organic complexity.** `fbm(p + fbm(p))` distorts the noise field with itself, creating swirling, unpredictable, natural-looking patterns. Double warping (`fbm(p + fbm(p + fbm(p)))`) is even more dramatic.

4. **Voronoi noise is for cell-like structures.** Biological tissue, cracked earth, stained glass, reptile skin. The distance to the nearest feature point creates the basic pattern; the difference between nearest and second-nearest creates edges.

5. **Noise parameters control character.** Octaves control detail level. Lacunarity (frequency multiplier) controls how spaced the detail bands are. Gain (amplitude multiplier) controls how much influence fine detail has. Changing these from the defaults (2.0 and 0.5) dramatically alters the look.

6. **Noise is a building block, not a final product.** Use noise as input to other functions: thresholding for clouds, color mapping for terrain, domain warping for fluid dynamics, perturbation for marble textures. The noise itself is just data — how you interpret it determines the visual result.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Book of Shaders, Ch. 11–12 (Noise, Cellular)](https://thebookofshaders.com/11/) | Interactive tutorial | Interactive implementations of value noise, gradient noise, and Voronoi with live-editable code. The best way to build intuition. |
| [Inigo Quilez: Domain Warping](https://iquilezles.org/articles/warp/) | Article | The definitive reference for domain warping with stunning examples. Shows single, double, and triple warping with source code. |
| [Inigo Quilez: Value Noise Derivatives](https://iquilezles.org/articles/morenoise/) | Article | Advanced: using noise derivatives for terrain normals and lighting. Not essential now, but powerful when you reach Modules 7 and 10. |
| [Stefan Gustavson: Simplex Noise Demystified (PDF)](https://weber.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf) | Paper | The clearest explanation of simplex noise's math. Read if you want to understand *why* simplex works, not just copy the code. |
| [Red Blob Games: Noise](https://www.redblobgames.com/articles/noise/introduction.html) | Interactive article | Excellent interactive exploration of noise concepts with visual explanations. Not GLSL-specific but the concepts translate directly. |

---

## What's Next?

You now have the organic brush — noise in all its forms. Combined with SDFs (Module 2), palettes (Module 3), and tiling (Module 4), you can create virtually any 2D procedural pattern.

In [Module 6: Textures & Image Processing](module-06-textures-image-processing.md), the outside world enters your shaders. You will learn to sample images, apply convolution kernels (blur, edge detection, sharpen), distort textures with UV manipulation, and create effects like chromatic aberration. This is the bridge from pure procedural art to practical game graphics and the gateway to post-processing (Module 9).

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
