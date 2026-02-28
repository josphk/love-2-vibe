# Module 4: Patterns, Tiling & Transformations

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** Module 3 (Color, Gradients & Blending)

---

## Overview

Everything you have built so far — shapes, colors, gradients — lives in a single coordinate space. One circle at the center. One gradient across the screen. To create rich, complex visuals from simple elements, you need **repetition** and **transformation**: the ability to tile a single shape into an infinite grid, rotate the space, warp it, and create patterns that look complex but are defined by a few lines of math.

This module introduces the three core techniques:

**Tiling** with `fract()` and `floor()`. Take your UV space and fold it into a repeating grid. Draw a circle in one tile, and it appears in every tile. Use `floor()` to know *which* tile you are in, so you can vary each copy — offset, rotate, colorize — while defining the shape only once.

**Transformations** with rotation matrices, scaling, and mirroring. A 2×2 matrix can rotate the entire coordinate space before your SDF evaluates. Apply it before tiling and the grid rotates. Apply it inside each tile and individual elements spin. Stack transformations for complex motion.

**Domain manipulation** in polar and warped coordinates. Convert to polar space for radial patterns and kaleidoscopes. Warp the coordinates with `sin()` or noise before evaluating your pattern. The pattern function stays simple — the coordinate system does the creative work.

These techniques are how a 10-line shader creates a full-screen animated wallpaper. They are how procedural textures work in every game engine. And they are the foundation for noise (Module 5) and everything after.

---

## 1. `fract()` and `floor()`: The Tiling Duo

You met `fract()` in Module 1 as a sawtooth wave. Its real purpose is **domain repetition** — turning one copy of something into infinitely many copies.

### The Basic Grid

```glsl
vec2 uv = fragCoord / iResolution.xy;  // 0 to 1
uv *= 5.0;                              // 0 to 5

vec2 cellUV = fract(uv);  // Local coordinates within each cell: 0 to 1
vec2 cellID = floor(uv);  // Which cell: (0,0), (1,0), ..., (4,4)
```

```
Original UV (0 to 5):             After fract():
┌─┬─┬─┬─┬─┐                     ┌─────┐
│0│1│2│3│4│  ← floor() IDs       │     │ Each cell gets
├─┼─┼─┼─┼─┤                     │ 0→1 │ its own 0 to 1
│5│6│7│8│9│                      │     │ coordinate space
├─┼─┼─┼─┼─┤                     └─────┘
│ │ │ │ │ │                      (all cells identical)
└─┴─┴─┴─┴─┘
```

### Drawing in Tiled Space

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    uv *= 5.0;  // 5x5 grid

    vec2 cellUV = fract(uv) - 0.5;  // Center each cell: -0.5 to 0.5
    vec2 cellID = floor(uv);

    // Draw a circle in each cell
    float d = length(cellUV) - 0.3;
    float fill = smoothstep(0.01, 0.0, d);

    fragColor = vec4(vec3(fill), 1.0);
}
```

The `-0.5` after `fract()` centers each cell's origin. Without it, the circle would be at each cell's corner. This is a pattern you will use every time.

### Per-Cell Variation with `floor()`

`floor()` gives you the cell index — a unique identifier for each tile. Use it to make each cell different:

```glsl
vec2 cellID = floor(uv);

// Pseudo-random value per cell
float rand = fract(sin(dot(cellID, vec2(12.9898, 78.233))) * 43758.5453);

// Random radius per cell
float radius = 0.1 + rand * 0.2;

// Random color per cell
vec3 color = palette(rand, ...);

// Offset per cell (stagger positions)
vec2 offset = vec2(rand - 0.5, fract(rand * 7.0) - 0.5) * 0.2;
float d = length(cellUV - offset) - radius;
```

The `fract(sin(dot(...)))` hash function is the classic cheap pseudo-random number generator in shaders. It takes a vec2 (the cell ID) and returns a seemingly random float between 0 and 1. It is not cryptographically random, but it looks random enough for visual purposes.

### Checkerboard Pattern

The simplest `floor()`-based pattern:

```glsl
vec2 cellID = floor(uv * 8.0);
float checker = mod(cellID.x + cellID.y, 2.0);
fragColor = vec4(vec3(checker), 1.0);
```

`mod(cellID.x + cellID.y, 2.0)` alternates between 0 and 1 for adjacent cells — the cells where `x + y` is even versus odd.

---

## 2. Brick Offset and Staggered Grids

A plain grid looks mechanical. Real patterns — bricks, honeycombs, woven fabric — stagger alternating rows.

### Basic Brick Offset

```glsl
vec2 uv = fragCoord / iResolution.xy;
uv *= vec2(8.0, 4.0);  // Wide tiles

// Offset every other row by half a tile
float row = floor(uv.y);
uv.x += mod(row, 2.0) * 0.5;

vec2 cellUV = fract(uv) - 0.5;
vec2 cellID = floor(uv);

// Draw rounded rectangle (brick)
float d = sdBox(cellUV, vec2(0.4, 0.35));
float fill = smoothstep(0.01, 0.0, d);

// Mortar lines (the gaps)
vec3 color = mix(vec3(0.3, 0.3, 0.3), vec3(0.7, 0.3, 0.2), fill);
```

The key line is `uv.x += mod(row, 2.0) * 0.5;` — it shifts every even-numbered row half a tile to the right, creating the classic brick pattern.

### Stagger Variants

```glsl
// Offset by 1/3 for a different pattern
uv.x += mod(row, 3.0) / 3.0;

// Offset based on a formula (organic look)
uv.x += sin(row * 0.7) * 0.5;

// Vertical stagger (columns instead of rows)
float col = floor(uv.x);
uv.y += mod(col, 2.0) * 0.5;
```

---

## 3. Rotation Matrices

Rotation in 2D is a 2×2 matrix multiplication. The matrix:

```glsl
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}
```

Rotates a point counter-clockwise by angle `a` (in radians) around the origin.

### Rotating the Entire Pattern

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

// Rotate the whole space 45 degrees
uv = rot(0.7854) * uv;  // 0.7854 = π/4 = 45°

// Now draw normally — everything is rotated
float d = sdBox(uv, vec2(0.2));
```

### Rotating Over Time

```glsl
uv = rot(iTime) * uv;  // Continuous rotation
```

### Rotating Individual Tiles

Apply rotation inside the tile (after `fract`), not before:

```glsl
vec2 uv = fragCoord / iResolution.xy * 5.0;
vec2 cellUV = fract(uv) - 0.5;
vec2 cellID = floor(uv);

// Each tile rotates based on its ID and time
float angle = iTime + cellID.x * 0.5 + cellID.y * 0.7;
cellUV = rot(angle) * cellUV;

float d = sdBox(cellUV, vec2(0.15));
float fill = smoothstep(0.01, 0.0, d);
```

Each cell spins independently because the rotation angle depends on `cellID`.

### Scaling

Scale by dividing coordinates (makes things bigger) or multiplying (makes things smaller):

```glsl
// Scale uniformly
uv /= scale;

// Scale non-uniformly
uv /= vec2(scaleX, scaleY);
```

Remember to correct the SDF distance when scaling (multiply by the scale factor).

### Combined Transform Order

Transformations apply in **reverse order** of how you write them:

```glsl
// This: translate, then rotate
uv -= offset;         // Written first
uv = rot(angle) * uv; // Written second
// Actual effect: rotates first, then translates

// To translate THEN rotate:
uv = rot(angle) * uv; // Rotate around origin
uv -= offset;         // Then move
```

The order matters significantly. Rotating then translating spins around the origin then moves. Translating then rotating moves then spins around the *new* origin.

---

## 4. Polar Tiling and Kaleidoscopes

Module 1 introduced polar coordinates. Now we tile in polar space to create radial patterns.

### Basic Polar Tiling

Divide the angle into equal sectors:

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
float angle = atan(uv.y, uv.x);  // -π to π
float radius = length(uv);

// Divide into 6 sectors
float sectors = 6.0;
float sectorAngle = TAU / sectors;

// Tile the angle
angle = mod(angle, sectorAngle) - sectorAngle * 0.5;

// Convert back to Cartesian for SDF evaluation
vec2 polarUV = vec2(cos(angle), sin(angle)) * radius;
```

Now whatever you draw in `polarUV` repeats 6 times around the center.

### Kaleidoscope

A kaleidoscope mirrors alternating sectors instead of just repeating them:

```glsl
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
float angle = atan(uv.y, uv.x);
float radius = length(uv);

float sectors = 6.0;
float sectorAngle = TAU / sectors;

// Fold into one sector
angle = mod(angle, sectorAngle);

// Mirror every other sector
angle = abs(angle - sectorAngle * 0.5);

// Back to Cartesian
vec2 kUV = vec2(cos(angle), sin(angle)) * radius;
```

The `abs()` creates the mirror. Even sectors are normal, odd sectors are flipped — just like a real kaleidoscope.

### Kaleidoscope with a Pattern

```glsl
#define TAU 6.28318530718

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TAU * (c * t + d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    // Kaleidoscope: 8-fold symmetry
    float sectors = 8.0;
    float sa = TAU / sectors;
    angle = mod(angle, sa);
    angle = abs(angle - sa * 0.5);

    // Reconstruct UV
    vec2 kUV = vec2(cos(angle), sin(angle)) * radius;

    // Draw a pattern in the sector
    float pattern = sin(kUV.x * 20.0 + iTime) * sin(kUV.y * 20.0 - iTime * 0.7);
    pattern = pattern * 0.5 + 0.5;

    vec3 color = palette(pattern + iTime * 0.1,
        vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.33, 0.67));

    fragColor = vec4(color, 1.0);
}
```

---

## 5. Hexagonal Grids

Hex grids cannot be done with simple `fract()` because hexagons do not tile on a rectangular grid. But the technique is surprisingly elegant.

### The Hex Grid Idea

A hex grid is two offset rectangular grids. You compute the nearest hex center by checking both grids and picking the closer one:

```glsl
vec2 hexGrid(vec2 uv, out vec2 cellID) {
    // Two candidate grids
    vec2 a = mod(uv, vec2(1.0, sqrt(3.0))) - vec2(0.5, sqrt(3.0) * 0.5);
    vec2 b = mod(uv + vec2(0.5, sqrt(3.0) * 0.5), vec2(1.0, sqrt(3.0)))
           - vec2(0.5, sqrt(3.0) * 0.5);

    // Pick the closer center
    vec2 cellA = uv - a;
    vec2 cellB = uv - b;

    if (length(a) < length(b)) {
        cellID = cellA;
        return a;
    } else {
        cellID = cellB;
        return b;
    }
}
```

### Simplified Hex Approach

A simpler (approximate) approach uses the hex SDF:

```glsl
// Hex distance (approximate)
float hexDist(vec2 p) {
    p = abs(p);
    return max(dot(p, vec2(1.0, 1.732) * 0.5), p.x);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Scale
    uv *= 5.0;

    // Two offset grids
    vec2 gridA = uv;
    vec2 gridB = uv + vec2(0.5, 0.866);

    vec2 cellA = fract(gridA) - 0.5;
    vec2 cellB = fract(gridB) - 0.5;

    // Pick the nearest hex center
    float dA = hexDist(cellA);
    float dB = hexDist(cellB);

    float d;
    vec2 cellUV;
    vec2 cellID;

    if (dA < dB) {
        d = dA;
        cellUV = cellA;
        cellID = floor(gridA);
    } else {
        d = dB;
        cellUV = cellB;
        cellID = floor(gridB);
    }

    // Color by cell
    float rand = fract(sin(dot(cellID, vec2(12.9898, 78.233))) * 43758.5453);
    vec3 color = vec3(rand, fract(rand * 7.0), fract(rand * 13.0));

    // Hex outline
    float edge = smoothstep(0.45, 0.44, d);
    color *= edge;

    fragColor = vec4(color, 1.0);
}
```

Hex grids are complex enough that most shader programmers copy a known implementation and adapt it. Do not feel you need to derive this from scratch.

---

## 6. Domain Warping

Domain warping means distorting the coordinate space *before* evaluating your pattern. The pattern function itself does not change — the space it lives in bends and flows.

### Simple Sine Warp

```glsl
vec2 uv = fragCoord / iResolution.xy;

// Warp: shift x based on y, and vice versa
uv.x += sin(uv.y * 10.0 + iTime) * 0.05;
uv.y += sin(uv.x * 10.0 + iTime * 0.7) * 0.05;

// Now evaluate any pattern with the warped UV
float pattern = sin(uv.x * 20.0) * 0.5 + 0.5;
```

The `* 0.05` controls the warp amplitude (how much distortion). The `* 10.0` controls the warp frequency (how wavy the distortion is). The `iTime` animates the warp.

### Warping a Grid

```glsl
vec2 uv = fragCoord / iResolution.xy * 5.0;

// Warp before tiling
uv.x += sin(uv.y * 2.0 + iTime) * 0.3;

// Now tile
vec2 cellUV = fract(uv) - 0.5;
float d = length(cellUV) - 0.2;
float fill = smoothstep(0.01, 0.0, d);
```

The grid itself bends. Circles that should be in a straight line now follow a wave. This is far more interesting than a regular grid, and the code difference is one line.

### Warping with Noise (Preview)

Module 5 covers noise in detail, but here is a preview of the most powerful domain warp — feeding noise into coordinates:

```glsl
// Conceptual (noise function defined in Module 5):
uv += vec2(noise(uv * 3.0 + iTime), noise(uv * 3.0 + 100.0 + iTime * 0.7)) * 0.2;
```

Noise-based domain warping produces organic, fluid distortions. It is the technique behind swirling smoke, undulating water, and alien terrain.

### Feedback Warping

Feed the result of one warp into another for increasingly complex distortions:

```glsl
// Single warp
vec2 warp1 = vec2(sin(uv.y * 5.0), cos(uv.x * 5.0)) * 0.1;
uv += warp1;

// Double warp (feed warped UV into another warp)
vec2 warp2 = vec2(sin(uv.y * 8.0 + iTime), cos(uv.x * 8.0 + iTime)) * 0.05;
uv += warp2;
```

Each layer of warping adds more organic complexity.

---

## 7. Symmetry Operations

Symmetry transforms reduce the space you need to define while creating visually complex results.

### Bilateral (Mirror) Symmetry

```glsl
uv.x = abs(uv.x);  // Left-right mirror
// Now whatever you draw on the right appears on the left too
```

### Four-Fold Symmetry

```glsl
uv = abs(uv);  // Mirror both axes — four copies
```

### Rotational Symmetry (N-Fold)

```glsl
float angle = atan(uv.y, uv.x);
float radius = length(uv);

float n = 5.0;  // 5-fold symmetry
angle = mod(angle + PI / n, TAU / n) - PI / n;

uv = vec2(cos(angle), sin(angle)) * radius;
```

This folds the entire coordinate space into one sector of the N-gon, then evaluates. Whatever you draw in that sector repeats N times with rotational symmetry.

### Reflection + Rotation (Dihedral Symmetry)

Combine rotational symmetry with a mirror:

```glsl
float n = 6.0;
float sectorAngle = TAU / n;
float angle = atan(uv.y, uv.x);
float radius = length(uv);

angle = mod(angle, sectorAngle);           // Rotational repeat
angle = abs(angle - sectorAngle * 0.5);    // Mirror within sector

uv = vec2(cos(angle), sin(angle)) * radius;
```

This creates the symmetry of a snowflake or a mandala.

---

## 8. Putting It All Together: Composite Patterns

Complex patterns come from combining the techniques in this module. Here are recipe patterns.

### Animated Spinning Tiles

```glsl
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv *= 6.0;

    vec2 cellID = floor(uv);
    vec2 cellUV = fract(uv) - 0.5;

    // Each tile rotates at a different speed
    float speed = sin(cellID.x * 1.3 + cellID.y * 2.7) * 2.0;
    cellUV = rot(iTime * speed) * cellUV;

    // Rounded square
    float d = sdBox(cellUV, vec2(0.2)) - 0.05;
    float fill = smoothstep(0.01, 0.0, d);

    // Color from palette based on cell
    float rand = fract(sin(dot(cellID, vec2(12.9898, 78.233))) * 43758.5453);
    vec3 color = 0.5 + 0.5 * cos(6.28 * (rand + vec3(0.0, 0.33, 0.67)));
    color *= fill;

    fragColor = vec4(color, 1.0);
}
```

### Moiré Pattern

Overlapping patterns with slightly different frequencies create moiré interference:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Two ring patterns with slightly different centers
    float r1 = sin(length(uv - vec2(0.1, 0.0)) * 40.0) * 0.5 + 0.5;
    float r2 = sin(length(uv + vec2(0.1, 0.0)) * 40.0) * 0.5 + 0.5;

    // Multiply them — moiré emerges at the interference
    float pattern = r1 * r2;

    fragColor = vec4(vec3(pattern), 1.0);
}
```

### Truchet Tiles

Truchet tiles randomly orient a simple element (like a quarter-circle) in each cell to create winding paths:

```glsl
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv *= 8.0;

    vec2 cellID = floor(uv);
    vec2 cellUV = fract(uv);

    // Random flip per cell
    float rand = fract(sin(dot(cellID, vec2(12.9898, 78.233))) * 43758.5453);
    if (rand > 0.5) {
        cellUV.x = 1.0 - cellUV.x;  // Flip horizontally
    }

    // Quarter circles at two opposite corners
    float d1 = abs(sdCircle(cellUV - vec2(0.0, 0.0), 0.5)) - 0.05;
    float d2 = abs(sdCircle(cellUV - vec2(1.0, 1.0), 0.5)) - 0.05;
    float d = min(d1, d2);

    float line = smoothstep(0.02, 0.0, d);

    fragColor = vec4(vec3(line), 1.0);
}
```

Truchet tiling creates the illusion of continuous, winding paths from disconnected cells — a beautiful emergent pattern.

---

## Code Walkthrough: Animated Mandala

Let us build a mandala — a radially symmetric, animated pattern combining tiling, rotation, and polar coordinates.

```glsl
#define PI  3.14159265359
#define TAU 6.28318530718

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0) * t + vec3(0.0, 0.33, 0.67)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // --- Polar coordinates ---
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    // --- 12-fold dihedral symmetry ---
    float n = 12.0;
    float sector = TAU / n;
    angle = mod(angle, sector);
    angle = abs(angle - sector * 0.5);

    // Reconstruct symmetric UV
    vec2 symUV = vec2(cos(angle), sin(angle)) * radius;

    // --- Ring layers ---
    vec3 color = vec3(0.02);

    // Layer 1: Inner ring of diamonds
    {
        vec2 p = symUV;
        p.x -= 0.12;  // Offset from center
        p = rot(iTime * 0.5) * p;
        float d = sdBox(p, vec2(0.03, 0.05)) - 0.005;
        float glow = 0.003 / max(abs(d), 0.001);
        color += palette(radius * 3.0 + iTime * 0.3) * glow;
    }

    // Layer 2: Middle ring of circles
    {
        float d = abs(length(symUV - vec2(0.25, 0.0)) - 0.03) - 0.008;
        float glow = 0.002 / max(abs(d), 0.001);
        color += palette(radius * 5.0 - iTime * 0.2) * glow;
    }

    // Layer 3: Outer ring of rotating squares
    {
        vec2 p = symUV;
        p.x -= 0.38;
        p = rot(-iTime * 0.3 + radius * 5.0) * p;
        float d = sdBox(p, vec2(0.02)) - 0.005;
        float glow = 0.003 / max(abs(d), 0.001);
        color += palette(angle * 2.0 + iTime * 0.5) * glow;
    }

    // --- Concentric guide rings ---
    float ring1 = abs(radius - 0.12) - 0.001;
    float ring2 = abs(radius - 0.25) - 0.001;
    float ring3 = abs(radius - 0.38) - 0.001;
    float rings = min(ring1, min(ring2, ring3));
    float ringGlow = 0.001 / max(abs(rings), 0.0005);
    color += vec3(0.3, 0.3, 0.5) * ringGlow;

    // --- Vignette ---
    color *= 1.0 - radius * 0.8;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
```

### What This Demonstrates

- **Polar coordinate conversion** — `atan`/`length` for radial layout
- **Dihedral symmetry** — `mod` for rotation, `abs` for mirror
- **Multiple layers at different radii** — each layer offsets `symUV.x` to place shapes at a specific distance from center
- **Per-layer rotation** — different `iTime` multipliers create complex relative motion
- **Glow rendering** — inverse-distance glow for each element
- **Cosine palette** — color varies by radius, angle, and time
- **Layered additive composition** — each layer adds its contribution to a black background

---

## GLSL Quick Reference

Functions and concepts introduced in this module:

| Function/Concept | Description | Example |
|---|---|---|
| `fract(uv * n)` | Tile UV into n×n grid | `fract(uv * 5.0) - 0.5` |
| `floor(uv * n)` | Get tile index (which cell) | `floor(uv * 5.0)` |
| `rot(angle)` | 2×2 rotation matrix | `uv = rot(iTime) * uv` |
| Brick offset | Stagger every other row | `uv.x += mod(row, 2.0) * 0.5` |
| Polar tiling | Divide angle into N sectors | `mod(angle, TAU/N)` |
| Kaleidoscope | Mirror within polar sector | `abs(angle - sectorAngle*0.5)` |
| Domain warp | Distort UV before pattern | `uv.x += sin(uv.y * 10.0) * 0.05` |
| `abs(uv)` | Mirror symmetry | Bilateral or four-fold |
| N-fold symmetry | Rotational + mirror | `mod` angle, `abs` within sector |
| Truchet tiles | Random orientation per cell | Flip based on `rand > 0.5` |
| Hash function | Per-cell randomness | `fract(sin(dot(id, ...)) * 43758.5)` |
| `mod(p, spacing)` | SDF repetition (infinite tiling) | `mod(p + s*0.5, s) - s*0.5` |

---

## Common Pitfalls

### 1. Forgetting to Center Cells After `fract()`

```glsl
// WRONG — shape at corner of each cell (visually confusing):
vec2 cellUV = fract(uv * 5.0);
float d = length(cellUV) - 0.3;  // Circle at (0,0) corner

// RIGHT — shape at center of each cell:
vec2 cellUV = fract(uv * 5.0) - 0.5;
float d = length(cellUV) - 0.3;  // Circle at cell center
```

### 2. SDF Artifacts at Tile Boundaries

When shapes in one cell extend past the cell boundary, they get clipped. You see this as shapes being cut off at cell edges.

```glsl
// Problem: circle radius 0.4 in a cell that's 0.5 wide
float d = length(cellUV) - 0.4;  // Extends beyond the -0.5 to 0.5 range

// Fix 1: Keep shapes smaller than half the cell size
float d = length(cellUV) - 0.3;

// Fix 2: Check neighboring cells (more expensive but correct)
// For each pixel, check the SDF in the current cell AND all 8 neighbors
float dMin = 1e10;
for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
        vec2 neighbor = vec2(float(dx), float(dy));
        vec2 neighborUV = cellUV - neighbor;
        float d = length(neighborUV) - 0.4;
        dMin = min(dMin, d);
    }
}
```

### 3. Rotation Distorting the Grid

Applying rotation before `fract` rotates the tiling grid itself. Applying rotation after `fract` rotates content within each cell. Make sure you know which you want:

```glsl
// Rotate the grid:
uv = rot(angle) * uv;
vec2 cellUV = fract(uv * 5.0) - 0.5;

// Rotate within each cell:
vec2 cellUV = fract(uv * 5.0) - 0.5;
cellUV = rot(angle) * cellUV;
```

### 4. Hash Function Producing Visible Patterns

The classic `fract(sin(dot(...)))` hash has known weaknesses — some GPU implementations of `sin()` produce visible banding or correlated patterns at certain scales.

```glsl
// If you see patterns, try different magic numbers:
float rand = fract(sin(dot(id, vec2(127.1, 311.7))) * 43758.5453123);

// Or use a different hash entirely:
float rand = fract(sin(id.x * 12.9898 + id.y * 78.233) * 43758.5453);
```

### 5. Polar Coordinate Seam at ±π

`atan(y, x)` has a discontinuity: it jumps from `π` to `-π` (or vice versa) at the negative X axis. When using `fract` or `mod` on the angle, this can create a visible seam.

```glsl
// Potential seam at the left side of the screen:
float t = fract(angle / TAU);  // Jump at angle = ±π

// Fix: offset the seam to a less visible location
float t = fract((angle + PI) / TAU);  // Seam at angle = 0 (right side)
```

---

## Exercises

### Exercise 1: Pattern Zoo

**Time:** 30–45 minutes

Create a shader that displays four different tiling patterns in a 2×2 layout:

1. **Top-left:** Regular grid of circles with per-cell random sizes
2. **Top-right:** Brick-offset pattern with rounded rectangles
3. **Bottom-left:** Checkerboard with alternating colors from a cosine palette
4. **Bottom-right:** Truchet tiles creating winding paths

Use `step()` on `fragCoord` to divide the screen into quadrants. Animate at least two of the patterns with `iTime`.

**Concepts practiced:** fract/floor tiling, brick offset, per-cell randomness, Truchet, layout composition

---

### Exercise 2: Kaleidoscope Machine

**Time:** 30–45 minutes

Build an interactive kaleidoscope:

1. Start with 6-fold dihedral symmetry (rotational + mirror)
2. Draw an interesting base pattern in the fundamental sector (use SDFs, sine waves, or both)
3. Use mouse X to control the number of symmetry sectors (map to range 3–12)
4. Use mouse Y to control the rotation speed
5. Animate the base pattern with `iTime`
6. Color with a cosine palette

**Stretch:** Add domain warping inside the sector — `sin()` distortion on the coordinates before drawing the pattern. This makes the kaleidoscope look organic instead of geometric.

**Concepts practiced:** Polar coordinates, N-fold symmetry, mirror symmetry, mouse interaction, palette coloring

---

### Exercise 3: Warped Grid

**Time:** 45–60 minutes

Create a grid of shapes that is deformed by domain warping:

1. Start with a regular 8×8 grid of small circles (using `fract`/`floor`)
2. Apply a sine-based domain warp to the UV *before* tiling: `uv.x += sin(uv.y * 3.0 + iTime) * 0.3`
3. Also warp Y: `uv.y += cos(uv.x * 3.0 + iTime * 0.7) * 0.3`
4. Color each circle based on its cell ID using a cosine palette
5. Vary the circle radius based on the cell's distance from the center of the screen

**Stretch:** Rotate each cell's shape based on the warp direction at that point. Compute the warp gradient (`dWarp/dUV`) and use `atan2` of the gradient as the rotation angle. This makes shapes "point along" the flow.

**Concepts practiced:** Domain warping, tiling, per-cell variation, palette coloring, combining techniques

---

## Key Takeaways

1. **`fract()` tiles, `floor()` identifies.** `fract(uv * n)` creates n×n repeating cells. `floor(uv * n)` tells you which cell you are in. Together, they are the foundation of all grid-based patterns. Always subtract 0.5 from `fract` to center each cell.

2. **Rotation is a 2×2 matrix multiply.** `mat2(c,-s,s,c) * uv` rotates by angle `a`. Apply it before tiling to rotate the grid. Apply it after tiling to rotate within cells. Mix with `iTime` for animation.

3. **Polar tiling creates radial symmetry.** `mod(angle, TAU/N)` creates N-fold rotational repeats. Adding `abs(angle - halfSector)` creates mirror (dihedral) symmetry. Together, they make kaleidoscopes and mandalas.

4. **Domain warping is a single-line upgrade.** Adding `uv.x += sin(uv.y * freq) * amp` before any pattern creates organic, flowing distortion. The pattern function does not change — only the space does. This is the most powerful aesthetic technique per line of code.

5. **Per-cell variation uses a hash function.** `fract(sin(dot(cellID, magic)) * 43758.5)` gives each cell a pseudo-random value. Use it for random sizes, colors, rotations, and offsets. This is what makes tiled patterns look natural instead of mechanical.

6. **Composition creates complexity.** A mandala is just: polar symmetry + tiling at different radii + rotation per layer + palette coloring + glow rendering. Each piece is simple. The composition is what makes it look complex.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Book of Shaders, Ch. 9 (Patterns)](https://thebookofshaders.com/09/) | Interactive tutorial | Interactive examples of `fract` tiling, offset grids, and Truchet patterns. The interactive editors make it easy to experiment. |
| [Book of Shaders, Ch. 8 (2D Matrices)](https://thebookofshaders.com/08/) | Interactive tutorial | Rotation, scaling, and translation in shader space with live-editable examples. |
| [Inigo Quilez: Useful Little Functions](https://iquilezles.org/articles/functions/) | Reference | A toolkit of shaping functions: gain, impulse, parabola, cubic pulse. Useful for modifying patterns and creating smooth transitions. |
| [Hexagonal Grids from Red Blob Games](https://www.redblobgames.com/grids/hexagons/) | Article | The definitive reference for hex grid math. Not GLSL-specific but the coordinate systems translate directly. |
| [Truchet Tiles (Wikipedia)](https://en.wikipedia.org/wiki/Truchet_tiles) | Reference | Mathematical background on Truchet tiling with visual examples. Useful for understanding why simple random flips create coherent patterns. |

---

## What's Next?

You can now tile, rotate, mirror, and warp patterns. Everything so far has been deterministic — clean geometric shapes in mathematical precision. The next module adds organic chaos.

In [Module 5: Noise — Perlin, Simplex, Cellular, FBM](module-05-noise.md), you will learn to generate procedural noise: random-looking but coherent patterns that mimic natural phenomena like terrain, clouds, fire, and water. Combined with the domain warping from this module, noise opens up an entire world of organic, fluid, living shader art.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
