# Module 2: Shapes with Signed Distance Functions

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** Module 1 (Coordinates, Uniforms & Math Toolbox)

---

## Overview

In normal programming, you draw a circle by calling `drawCircle(x, y, radius)`. The graphics API handles everything behind the scenes. In shader programming, there is no `drawCircle` function. You are a single pixel asking a single question: *"Am I inside the circle?"*

The elegant answer to that question is a **Signed Distance Function (SDF)**. An SDF takes a point in space and returns the shortest distance from that point to the nearest edge of a shape. If the distance is negative, you are inside the shape. If positive, you are outside. If zero, you are exactly on the edge.

This might sound like a complicated way to draw shapes. It is — until you realize what it gives you for free. From a single distance value, you can create:

- A filled shape (`step(0.0, -d)`)
- An outlined shape (`smoothstep(0.0, 0.02, abs(d))`)
- A glowing shape (`0.01 / abs(d)`)
- A soft-edged shape (`smoothstep(0.02, 0.0, d)`)
- A shadow (`smoothstep(-0.1, 0.0, d)`)
- An animated shape (change the SDF parameters over time)

One function. Infinite visual variations. And then the real power: you can *combine* SDFs. Take the `min` of two shapes and they merge. Take the `max` and you get their intersection. Subtract one from another. Blend them smoothly. Build complex geometry from simple primitives, entirely in math.

SDFs are the central technique of this roadmap. They are how you draw in 2D shaders, and they are the foundation of raymarching (Module 10), where you will build entire 3D scenes from SDFs. Master them here and everything that follows will make more sense.

---

## 1. What Is a Signed Distance Function?

An SDF is a function that takes a point `p` and returns a signed scalar:

```
d = SDF(p)

d < 0  →  point is INSIDE the shape
d = 0  →  point is ON the edge (the boundary)
d > 0  →  point is OUTSIDE the shape
```

The magnitude `|d|` tells you *how far* you are from the nearest edge. A point with `d = 0.1` is 0.1 units outside the boundary. A point with `d = -0.05` is 0.05 units inside.

```
             d = 0.3  (outside)
                ●
           ╭─────────╮
           │  d = 0   │  ← boundary (the shape edge)
           │    ●     │
           │ d = -0.2 │  (inside)
           ╰─────────╯
```

### Why "Signed"?

The sign is what makes SDFs powerful. A regular (unsigned) distance function only tells you how far you are from the edge — it cannot distinguish inside from outside. The sign gives you that information, which means you can fill shapes, create borders, and do boolean operations.

### The SDF Workflow in a Shader

Every SDF-based shader follows this pattern:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // 1. Set up coordinates (centered, aspect-corrected)
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // 2. Compute the SDF (distance from this pixel to the shape)
    float d = sdCircle(uv, 0.3);  // Some SDF function

    // 3. Use the distance to determine the color
    vec3 color = vec3(step(0.0, -d));  // Filled: white inside, black outside

    fragColor = vec4(color, 1.0);
}
```

Step 2 is where the shape is defined. Step 3 is where you decide *how* to visualize the distance. The beauty is that you can change step 3 without touching step 2 — the same SDF can produce entirely different visual styles.

---

## 2. The Circle SDF

The simplest and most important SDF. A circle is defined by a center and a radius. The distance from a point `p` to the circle's edge is:

```
distance to center - radius
```

If you are closer to the center than the radius, you are inside (negative distance). If farther, you are outside (positive).

```glsl
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}
```

That is the entire function. `length(p)` computes the distance from `p` to the origin. Subtracting `r` shifts the zero-crossing to the circle's edge.

```
         length(p) = 0.5
              ●  ← d = 0.5 - 0.3 = 0.2 (outside)
         ╭────╮
         │    │   radius = 0.3
         │  ● │ ← d = 0.0 - 0.3 = -0.3 (inside, at center)
         ╰────╯
              ● ← d = 0.3 - 0.3 = 0.0 (exactly on edge)
```

### Using It

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    float d = sdCircle(uv, 0.3);

    // Filled circle: white inside, black outside
    float fill = step(0.0, -d);  // 1.0 inside, 0.0 outside

    fragColor = vec4(vec3(fill), 1.0);
}
```

### Moving the Circle

To move the circle's center, subtract the desired position from `p` before computing the SDF:

```glsl
vec2 center = vec2(0.2, -0.1);
float d = sdCircle(uv - center, 0.3);
```

This works because subtracting the center from `uv` moves the coordinate system so that the shape is at the origin from the SDF's perspective.

### Animating the Circle

```glsl
// Orbiting circle
vec2 center = vec2(cos(iTime), sin(iTime)) * 0.2;
float d = sdCircle(uv - center, 0.1);

// Pulsing radius
float radius = 0.2 + sin(iTime * 3.0) * 0.05;
float d = sdCircle(uv, radius);
```

---

## 3. The Rectangle SDF

A rectangle (axis-aligned box) centered at the origin with half-dimensions `b` (half-width, half-height):

```glsl
float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}
```

This is more complex than the circle, so let us break it down.

### How It Works

The `abs(p)` exploits the rectangle's symmetry — a rectangle is the same in all four quadrants, so we fold everything into the positive quadrant and compute the distance there.

`abs(p) - b` gives us the displacement from the rectangle's edge in each axis. If this value is negative in both components, we are inside. If positive in at least one component, we are outside.

```
Case 1: Outside (corner region)     Case 2: Outside (edge region)
  Both d.x > 0 and d.y > 0           d.x > 0 but d.y < 0
  Distance = length(d)                Distance = d.x only

    ● (outside, corner)                      ● (outside, edge)
     ╲                                       │
  ┌───╲──┐                              ┌────┤──┐
  │     ╲ │                              │    │  │
  │      ╲│                              │    │  │
  └───────┘                              └───────┘

Case 3: Inside
  Both d.x < 0 and d.y < 0
  Distance = max(d.x, d.y)  (the "least negative" = closest edge)

  ┌──────────┐
  │    ●     │  d.x = -0.2, d.y = -0.1
  │          │  distance = max(-0.2, -0.1) = -0.1
  └──────────┘
```

### Using It

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Rectangle: 0.4 wide, 0.2 tall (half-dimensions)
    float d = sdBox(uv, vec2(0.2, 0.1));

    float fill = step(0.0, -d);
    fragColor = vec4(vec3(fill), 1.0);
}
```

### Rounded Rectangle

Add rounding by subtracting a radius from the box dimensions and then subtracting the same radius from the SDF result:

```glsl
float sdRoundedBox(vec2 p, vec2 b, float r) {
    return sdBox(p, b - r) - r;
}
```

This shrinks the box inward by `r` on each side, then expands the distance field outward by `r` — which rounds the corners. `r = 0.05` gives subtle rounding. `r = min(b.x, b.y)` turns the rectangle into a capsule shape.

---

## 4. The Line Segment SDF

A line from point `a` to point `b`:

```glsl
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}
```

### How It Works

The idea is to find the closest point on the line segment to `p`, then return the distance to that closest point.

`dot(pa, ba) / dot(ba, ba)` projects `p` onto the line through `a` and `b`, giving a parameter `h` where `h = 0` is at `a` and `h = 1` is at `b`. The `clamp` keeps `h` within the segment (not extending past the endpoints).

`pa - ba * h` is the vector from the closest point on the segment to `p`. `length()` gives the distance.

Note this is an *unsigned* distance — a line segment has no "inside." To use it like other SDFs, subtract a thickness:

```glsl
// A line with thickness
float d = sdSegment(uv, vec2(-0.3, -0.1), vec2(0.3, 0.1)) - 0.01;
```

---

## 5. More Primitives

Here are several more useful SDF primitives. You do not need to memorize the math — just know they exist and what they produce.

### Equilateral Triangle

```glsl
float sdTriangle(vec2 p, float r) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if (p.x + k * p.y > 0.0) {
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    }
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}
```

### Ring (Annulus)

A ring is just a circle SDF with `abs()` applied before subtracting the ring thickness:

```glsl
float sdRing(vec2 p, float outerR, float thickness) {
    return abs(length(p) - outerR) - thickness;
}
```

This is an important pattern: `abs(sdf) - thickness` turns any SDF into a hollow outline (a "shell" of constant thickness around the original boundary).

### Arc (Partial Ring)

For an arc spanning a certain angle:

```glsl
float sdArc(vec2 p, float angle, float ra, float rb) {
    vec2 sca = vec2(sin(angle), cos(angle));
    p.x = abs(p.x);
    float k = (sca.y * p.x > sca.x * p.y) ? dot(p, sca) : length(p);
    return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}
```

### Regular Polygon

An N-sided regular polygon:

```glsl
float sdPolygon(vec2 p, float r, int n) {
    float a = atan(p.y, p.x);
    float s = 6.28318 / float(n);
    float d = cos(floor(0.5 + a / s) * s - a) * length(p);
    return d - r;
}
```

### Where to Find More

Inigo Quilez maintains the definitive catalogue of 2D SDF primitives at [iquilezles.org/articles/distfunctions2d](https://iquilezles.org/articles/distfunctions2d/). Bookmark this page. Every shape you could want — stars, hearts, crosses, bezier curves, parabolas — has a compact SDF implementation there.

---

## 6. Visualizing SDFs: From Distance to Color

The SDF gives you a number. How you turn that number into a color determines the visual style. Here are the most important techniques.

### Hard Fill

```glsl
float fill = step(0.0, -d);  // 1.0 inside, 0.0 outside
```

Binary inside/outside. Sharp edges, no anti-aliasing. Sometimes that is what you want (pixel art, hard-edged graphics). Usually you want something softer.

### Anti-Aliased Fill

```glsl
float fill = smoothstep(0.005, 0.0, d);  // Smooth transition over ~5 pixels
```

`smoothstep` creates a soft transition at the boundary. The width of the transition (`0.005` in this case) controls the anti-aliasing. Wider = softer edges. Narrower = sharper.

For resolution-independent anti-aliasing, compute the transition width based on screen-space pixel size:

```glsl
float px = fwidth(d);  // Rate of change of d across the pixel
float fill = smoothstep(px, -px, d);
```

`fwidth()` (or `dFdx`/`dFdy`) tells you how fast the value changes across the screen. This gives you exactly-one-pixel anti-aliasing at any zoom level.

### Outline

```glsl
float outline = smoothstep(0.02, 0.01, abs(d));  // Ring at the boundary
```

`abs(d)` makes the distance unsigned — now both inside and outside are positive, and the zero-crossing (the edge) is the minimum. `smoothstep` creates a narrow bright band around `abs(d) = 0` — the edge.

Varying the `smoothstep` range gives you different outline widths:

```glsl
// Thin outline
float thin = smoothstep(0.01, 0.005, abs(d));

// Thick outline
float thick = smoothstep(0.04, 0.02, abs(d));

// Outline only outside (like a border)
float border = smoothstep(0.02, 0.01, d) - smoothstep(0.0, -0.01, d);
```

### Glow

```glsl
float glow = 0.01 / abs(d);  // Bright at edge, falls off with distance
glow = clamp(glow, 0.0, 1.0);  // Prevent values > 1
```

This creates a radiant glow around the shape boundary. The `0.01` controls the glow intensity/size — smaller values give a tighter glow. The inverse-distance falloff creates a natural light-like effect.

### Onion Rings

```glsl
// Multiple concentric outlines
float rings = abs(mod(d, 0.05) - 0.025);
float viz = smoothstep(0.005, 0.0, rings);
```

`mod` repeats the distance field at regular intervals, creating concentric copies of the shape boundary. This works with any SDF — circles become concentric rings, rectangles become nested rectangles, any shape becomes an "onion" of itself.

### Distance Field Visualization

For debugging and learning, visualize the raw distance field:

```glsl
// Gradient visualization: blue inside, red outside
vec3 color = (d < 0.0) ? vec3(0.2, 0.4, 0.8) : vec3(0.9, 0.3, 0.2);

// Overlay contour lines
color *= 1.0 - smoothstep(0.0, 0.01, abs(fract(d * 20.0) - 0.5));

// Highlight the boundary
color = mix(color, vec3(1.0), smoothstep(0.01, 0.0, abs(d)));
```

This technique — visualizing the raw SDF with color coding and contour lines — is invaluable when you are building complex SDFs and need to see what the distance field looks like.

---

## 7. Boolean Operations: Combining Shapes

This is where SDFs become truly powerful. You can combine any two SDFs using simple min/max operations.

### Union: Merging Shapes

```glsl
float d = min(d1, d2);
```

Takes the minimum distance of two SDFs. The result contains both shapes — wherever you are inside *either* shape, the minimum is negative.

```
  ┌──┐         ┌──┐        ┌──┬──┐
  │  │    +    │  │   =    │  │  │   (min)
  └──┘         └──┘        └──┴──┘
  shape1      shape2        union
```

### Intersection: Overlap Only

```glsl
float d = max(d1, d2);
```

Takes the maximum. The result is only the region inside *both* shapes — both distances must be negative, and `max` of two negatives is the "less negative" one.

```
  ┌───┐           ┌───┐
  │   ├───┐       │ ┌─┤       ┌─┐
  │   │   │  →    │ │X│  =    │X│    (max)
  │   ├───┘       │ └─┤       └─┘
  └───┘           └───┘     overlap only
```

### Subtraction: Cutting Away

```glsl
float d = max(d1, -d2);
```

Negating `d2` flips its inside/outside. Then `max` keeps only the region inside `d1` *and outside* `d2` — effectively cutting `d2` out of `d1`.

```
  ┌───────┐        ╭──╮      ┌───┐
  │       │   -    │  │  =   │   ╰──╮
  │       │        │  │      │      │
  │       │        ╰──╯      │   ╭──╯
  └───────┘                  └───┘
  shape1         shape2     subtraction
```

### Practical Example: A Pac-Man

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Head: circle
    float head = sdCircle(uv, 0.3);

    // Mouth: a triangle-like region
    // Use a rotated half-plane to cut out a wedge
    float mouthAngle = 0.4;  // Mouth opening angle
    vec2 mouthDir = vec2(cos(mouthAngle), sin(mouthAngle));
    float mouth = dot(uv, vec2(1.0, 0.0));  // Right-facing plane
    float mouthTop = dot(uv, vec2(mouthDir.x, mouthDir.y));
    float mouthBot = dot(uv, vec2(mouthDir.x, -mouthDir.y));
    float wedge = max(-mouthTop, mouthBot);

    // Subtract the wedge from the circle
    float d = max(head, wedge);

    // Eye
    float eye = sdCircle(uv - vec2(0.05, 0.15), 0.03);

    // Combine: pac-man body minus the eye
    d = max(d, eye);  // Cut out the eye

    // Render
    float fill = smoothstep(0.005, 0.0, d);
    vec3 color = fill * vec3(1.0, 0.85, 0.0);  // Yellow

    fragColor = vec4(color, 1.0);
}
```

---

## 8. Smooth Boolean Operations

Hard `min` and `max` produce sharp creases where shapes meet. **Smooth operations** blend the transition, creating organic, clay-like joins.

### Smooth Union (smin)

```glsl
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
```

The parameter `k` controls the blending radius. `k = 0.0` is identical to `min`. Larger `k` means a wider, smoother blend.

```
Hard union (min):            Smooth union (smin, k=0.1):
  ╭─╮╭─╮                        ╭─────╮
  │  ││  │                      │       │
  │  ││  │                      │       │
  ╰─╯╰─╯                        ╰─────╯
Two shapes touching            Shapes melt together
```

### Smooth Subtraction and Intersection

```glsl
// Smooth subtraction
float smax(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(a, b, h) + k * h * (1.0 - h);
}

// Smooth subtraction: smax(d1, -d2, k)
// Smooth intersection: smax(d1, d2, k)
```

### Practical Example: Melting Blobs

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Two orbiting circles
    vec2 p1 = vec2(cos(iTime), sin(iTime)) * 0.15;
    vec2 p2 = vec2(cos(iTime * 1.3 + 2.0), sin(iTime * 1.3 + 2.0)) * 0.15;

    float d1 = sdCircle(uv - p1, 0.12);
    float d2 = sdCircle(uv - p2, 0.12);

    // Smooth union — they melt together when close
    float d = smin(d1, d2, 0.1);

    float fill = smoothstep(0.005, 0.0, d);
    vec3 color = fill * vec3(0.3, 0.7, 1.0);

    fragColor = vec4(color, 1.0);
}
```

The `smin` makes the circles "attract" each other as they pass close — creating a liquid, organic effect. This is one of the most visually satisfying things you can do with SDFs.

---

## 9. Transforming SDFs

You do not need separate SDFs for every position, size, and orientation. Apply transformations to the input point `p` before evaluating the SDF.

### Translation (Moving)

```glsl
float d = sdCircle(p - offset, radius);
```

Subtracting the offset moves the shape. This is the same as all coordinate transforms in shaders: you move the *space*, not the shape.

### Scaling

```glsl
float d = sdCircle(p / scale, radius) * scale;
```

Divide `p` by the scale factor, then multiply the result. The multiplication corrects the distance — without it, the distances would be wrong for further operations.

### Rotation

```glsl
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Rotate the space, then evaluate
vec2 rp = rot(angle) * p;
float d = sdBox(rp, vec2(0.2, 0.1));
```

### Symmetry (Mirroring)

```glsl
// Mirror across the Y axis — draw once, get both sides
vec2 mp = vec2(abs(p.x), p.y);
float d = sdCircle(mp - vec2(0.2, 0.1), 0.05);
// Produces circles at both (0.2, 0.1) and (-0.2, 0.1)
```

### Repetition (Infinite Tiling)

```glsl
// Tile the SDF across a grid
vec2 spacing = vec2(0.3);
vec2 rp = mod(p + spacing * 0.5, spacing) - spacing * 0.5;
float d = sdCircle(rp, 0.1);
// Infinite grid of circles!
```

`mod` wraps the coordinate space, so the SDF evaluates in a repeating tile. The `+ spacing * 0.5` and `- spacing * 0.5` center the tile around the origin. This is the same `fract`/`mod` tiling from Module 1, but applied to SDF input.

---

## 10. Building a Complete Scene

Let us combine everything into a single shader that builds a scene with multiple shapes, boolean operations, and styled rendering.

### Scene: Sunset with Mountains

```glsl
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // --- Sky gradient ---
    vec3 skyTop    = vec3(0.1, 0.1, 0.4);
    vec3 skyBottom = vec3(0.9, 0.4, 0.1);
    vec3 color = mix(skyBottom, skyTop, uv.y + 0.5);

    // --- Sun ---
    vec2 sunPos = vec2(0.0, 0.05);
    float sun = sdCircle(uv - sunPos, 0.15);
    vec3 sunColor = vec3(1.0, 0.8, 0.3);

    // Soft glow around the sun
    float sunGlow = 0.03 / max(abs(sun), 0.001);
    sunGlow = clamp(sunGlow, 0.0, 1.0);
    color += sunGlow * sunColor * 0.5;

    // Sun fill
    float sunFill = smoothstep(0.005, 0.0, sun);
    color = mix(color, sunColor, sunFill);

    // --- Mountains ---
    // Build from overlapping circles at the bottom
    float m1 = sdCircle(uv - vec2(-0.4, -0.6), 0.45);
    float m2 = sdCircle(uv - vec2(0.1, -0.55), 0.40);
    float m3 = sdCircle(uv - vec2(0.5, -0.65), 0.50);
    float m4 = sdCircle(uv - vec2(-0.1, -0.7), 0.55);

    // Smooth-merge all mountains
    float mountains = smin(m1, m2, 0.1);
    mountains = smin(mountains, m3, 0.1);
    mountains = smin(mountains, m4, 0.1);

    // Mountain colors
    vec3 mountainColor = vec3(0.05, 0.05, 0.15);
    float mountainFill = smoothstep(0.005, 0.0, mountains);
    color = mix(color, mountainColor, mountainFill);

    // --- Ground ---
    float ground = uv.y + 0.35;  // Horizontal line
    vec3 groundColor = vec3(0.02, 0.02, 0.05);
    float groundFill = smoothstep(0.005, 0.0, ground);
    color = mix(color, groundColor, groundFill);

    // --- Stars (only in upper sky) ---
    // Simple pseudo-random dots
    vec2 starUV = floor(uv * 60.0);
    float starRand = fract(sin(dot(starUV, vec2(12.9898, 78.233))) * 43758.5453);
    float star = step(0.98, starRand) * step(0.0, uv.y);  // Only above horizon
    star *= smoothstep(-0.1, 0.3, uv.y);  // Fade near horizon
    color += star * vec3(0.8, 0.8, 1.0);

    fragColor = vec4(color, 1.0);
}
```

### What This Demonstrates

- **Multiple SDF primitives** — circles for sun and mountain peaks
- **`smin`** for smooth mountain merging
- **Layered composition** — sky gradient, then sun glow, then sun fill, then mountains, then ground, then stars. Each layer uses `mix()` to blend based on its SDF.
- **Glow effect** — `0.03 / abs(d)` for a natural glow around the sun
- **Pseudo-random function** — `fract(sin(dot(...)))` for star placement (a classic trick covered more in Module 5)
- **The distance field as a tool** — we never "draw" anything. We compute distances and convert them to blending factors.

---

## Code Walkthrough: Animated SDF Face

Let us build a complete face using SDFs, with blinking eyes and a smiling mouth.

### Step 1: Head

```glsl
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Head
    float head = sdCircle(uv, 0.35);
    float fill = smoothstep(0.005, 0.0, head);
    vec3 color = fill * vec3(1.0, 0.85, 0.4);  // Skin color

    fragColor = vec4(color, 1.0);
}
```

### Step 2: Eyes

```glsl
    // Left eye
    float eyeL = sdCircle(uv - vec2(-0.12, 0.08), 0.05);
    // Right eye
    float eyeR = sdCircle(uv - vec2(0.12, 0.08), 0.05);
    // Combine eyes
    float eyes = min(eyeL, eyeR);

    // Eyes are dark — subtract from color
    float eyeFill = smoothstep(0.005, 0.0, eyes);
    color = mix(color, vec3(0.1, 0.1, 0.2), eyeFill);
```

### Step 3: Blinking

```glsl
    // Blink: flatten the eye vertically every few seconds
    float blinkCycle = fract(iTime * 0.3);  // Cycle every ~3.3 seconds
    float blink = 1.0 - step(0.9, blinkCycle);  // Open most of the time

    // Scale eye height based on blink
    vec2 eyeScale = vec2(1.0, blink * 1.0 + 0.01);  // Nearly zero when blinking

    float eyeL = sdCircle((uv - vec2(-0.12, 0.08)) / eyeScale, 0.05) * min(eyeScale.x, eyeScale.y);
    float eyeR = sdCircle((uv - vec2(0.12, 0.08)) / eyeScale, 0.05) * min(eyeScale.x, eyeScale.y);
```

### Step 4: Mouth (Full Shader)

```glsl
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // --- Background ---
    vec3 color = vec3(0.2, 0.3, 0.5);

    // --- Head ---
    float head = sdCircle(uv, 0.35);
    float headFill = smoothstep(0.005, 0.0, head);
    vec3 skinColor = vec3(1.0, 0.85, 0.4);
    color = mix(color, skinColor, headFill);

    // --- Eyes with blink ---
    float blinkCycle = fract(iTime * 0.3);
    float blink = smoothstep(0.9, 0.92, blinkCycle)
                - smoothstep(0.95, 0.97, blinkCycle);
    blink = 1.0 - blink;  // 1.0 = open, 0.0 = closed

    vec2 eyeScale = vec2(1.0, max(blink, 0.05));
    float eyeScaleFactor = min(eyeScale.x, eyeScale.y);

    float eyeL = sdCircle((uv - vec2(-0.12, 0.08)) / eyeScale, 0.05) * eyeScaleFactor;
    float eyeR = sdCircle((uv - vec2( 0.12, 0.08)) / eyeScale, 0.05) * eyeScaleFactor;
    float eyes = min(eyeL, eyeR);

    float eyeFill = smoothstep(0.005, 0.0, eyes);
    color = mix(color, vec3(0.1, 0.1, 0.2), eyeFill);

    // --- Pupils ---
    float pupilL = sdCircle(uv - vec2(-0.12, 0.08), 0.02);
    float pupilR = sdCircle(uv - vec2( 0.12, 0.08), 0.02);
    float pupils = min(pupilL, pupilR);
    float pupilFill = smoothstep(0.005, 0.0, pupils);
    // Only show pupils when eyes are open enough
    pupilFill *= step(0.3, blink);
    color = mix(color, vec3(1.0), pupilFill);

    // --- Mouth ---
    // Smile: subtract a smaller circle from a larger one, shifted down
    float smileAmount = sin(iTime) * 0.02;  // Subtle expression change
    float mouthOuter = sdCircle(uv - vec2(0.0, -0.05 + smileAmount), 0.18);
    float mouthInner = sdCircle(uv - vec2(0.0, 0.02 + smileAmount), 0.18);

    // The mouth is the region inside mouthOuter but outside mouthInner
    float mouth = max(mouthOuter, -mouthInner);
    // Only keep the lower part
    mouth = max(mouth, -(uv.y + 0.05 - smileAmount));

    float mouthFill = smoothstep(0.005, 0.0, mouth);
    color = mix(color, vec3(0.8, 0.2, 0.2), mouthFill);

    // --- Head outline ---
    float headOutline = smoothstep(0.015, 0.005, abs(head));
    color = mix(color, vec3(0.3, 0.2, 0.1), headOutline);

    fragColor = vec4(color, 1.0);
}
```

### What This Demonstrates

- **Scene composition** — each element is a separate SDF, composed with `min`, `max`, and `mix`
- **Subtraction for complex shapes** — the mouth is carved from two overlapping circles
- **Scale-based animation** — eye blinking by squishing the Y scale
- **Layered rendering** — background → head → eyes → pupils → mouth → outline, each using `mix()` with an SDF-derived alpha
- **Time-based expression** — subtle mouth movement with `sin(iTime)`

---

## GLSL Quick Reference

Functions and concepts introduced in this module:

| Function/Concept | Description | Example |
|---|---|---|
| `sdCircle(p, r)` | Circle SDF: `length(p) - r` | `sdCircle(uv, 0.3)` |
| `sdBox(p, b)` | Rectangle SDF (half-dimensions `b`) | `sdBox(uv, vec2(0.2, 0.1))` |
| `sdSegment(p, a, b)` | Line segment SDF | `sdSegment(uv, start, end) - 0.01` |
| `min(d1, d2)` | Union (merge shapes) | `min(circle, box)` |
| `max(d1, d2)` | Intersection (overlap only) | `max(circle, box)` |
| `max(d1, -d2)` | Subtraction (cut d2 from d1) | `max(head, -mouth)` |
| `smin(d1, d2, k)` | Smooth union (organic blend) | `smin(blob1, blob2, 0.1)` |
| `step(0.0, -d)` | Hard fill (inside = 1, outside = 0) | Binary rendering |
| `smoothstep(e, 0.0, d)` | Anti-aliased fill | `smoothstep(0.005, 0.0, d)` |
| `abs(d) - thickness` | Shell/outline from any SDF | `abs(circle) - 0.01` |
| `0.01 / abs(d)` | Glow effect | Bright at edges, fades with distance |
| `mod(d, s) - s*0.5` | Onion rings / concentric repeats | Repeating contour lines |
| Translation | `sdf(p - offset, ...)` | Move shapes by offsetting p |
| Rotation | `sdf(rot(a) * p, ...)` | Rotate with 2×2 matrix |
| Repetition | `sdf(mod(p, s) - s*0.5, ...)` | Infinite tiling |

---

## Common Pitfalls

### 1. Forgetting to Correct Distance After Scaling

When you scale the input point, the distances are wrong unless you multiply the result by the scale factor.

```glsl
// WRONG — distances are stretched, boolean ops break:
float d = sdCircle(p / 2.0, 0.3);

// RIGHT — multiply result by scale:
float d = sdCircle(p / 2.0, 0.3) * 2.0;
```

For non-uniform scaling (different X and Y), use the minimum scale factor: `* min(scale.x, scale.y)`. Non-uniform scaling distorts the SDF and is only an approximation.

### 2. Subtraction Order Matters

`max(d1, -d2)` cuts `d2` from `d1`. `max(d2, -d1)` cuts `d1` from `d2`. These are different operations.

```glsl
// Cut a hole in the box (box with circular hole):
float d = max(box, -circle);

// Cut the box from the circle (crescent shape):
float d = max(circle, -box);
```

### 3. Smooth Union with k = 0 Is Just min

If you are using `smin` and the shapes are not blending, check that `k > 0`. With `k = 0.0`, `smin` is identical to `min`. Start with `k = 0.1` and adjust.

### 4. Anti-Aliasing Width

Hardcoding `smoothstep(0.01, 0.0, d)` works at one resolution but looks wrong at others. The transition width should depend on pixel size.

```glsl
// Resolution-dependent (fragile):
float fill = smoothstep(0.01, 0.0, d);

// Resolution-independent (robust):
float px = fwidth(d);
float fill = smoothstep(px, -px, d);
```

### 5. Layering Order

When compositing multiple shapes with `mix()`, order matters. Later `mix()` calls overwrite earlier ones. Paint from back to front:

```glsl
// Background → large shapes → details → outlines
color = mix(color, bodyColor, bodyFill);      // First: body
color = mix(color, eyeColor, eyeFill);        // Then: eyes (on top of body)
color = mix(color, pupilColor, pupilFill);    // Then: pupils (on top of eyes)
color = mix(color, outlineColor, outlineFill); // Finally: outlines (on top of everything)
```

---

## Exercises

### Exercise 1: SDF Sampler Platter

**Time:** 30–40 minutes

Create a shader that displays four shapes in a 2×2 grid:

1. **Top-left:** Circle with anti-aliased fill
2. **Top-right:** Rounded rectangle with outline only (no fill)
3. **Bottom-left:** Equilateral triangle with glow effect
4. **Bottom-right:** A ring (annulus) with onion-ring contour lines

For each shape, use `uv` offset to position it in its quadrant. Use different colors for each shape. Add `iTime` to rotate the triangle and pulse the ring.

**Concepts practiced:** Multiple SDF primitives, outline vs fill vs glow rendering, layout composition

---

### Exercise 2: Melting Metaballs

**Time:** 30–45 minutes

Create 3–5 circles that orbit around the center at different speeds and radii. Use `smin` (smooth union) to blend them together, creating a liquid/metaball effect.

1. Start with 3 circles using `cos(iTime * speed)` and `sin(iTime * speed)` for positions.
2. Chain `smin` calls: `smin(smin(d1, d2, k), d3, k)`
3. Experiment with different `k` values (0.05 tight, 0.2 blobby)
4. Add color that varies based on the final distance value
5. Try the glow visualization (`0.01 / abs(d)`) for a neon look

**Stretch:** Add `iMouse` to position one of the blobs, so you can interact with the metaball simulation.

**Concepts practiced:** smin, animated SDFs, multiple shapes, glow rendering

---

### Exercise 3: Build a Face (from the Roadmap)

**Time:** 45–60 minutes

Build a face using only SDFs. Requirements:

1. A circle for the head with an outline
2. Two eyes using circles (bonus: use scale to make them ellipses)
3. Pupils that follow the mouse position (hint: compute direction from eye center to mouse, offset pupils in that direction, clamp the offset to stay within the eye)
4. A mouth using subtracted/intersected circles
5. At least one animated element (blinking, expression change, color)

**Stretch:** Add rosy cheeks using a subtle glow from two circles on the cheeks. Add a hat using rectangle and triangle SDFs.

**Concepts practiced:** Scene composition, boolean operations, layered rendering, animation, mouse interaction

---

## Key Takeaways

1. **An SDF returns the signed distance to a shape's edge.** Negative = inside, positive = outside, zero = boundary. From one number, you can create fills, outlines, glows, and shadows. The distance is the data; the visualization is a separate choice.

2. **Circle SDF is `length(p) - r`.** The simplest and most important SDF. Every other SDF builds on the same concept: compute the shortest distance to the shape's boundary.

3. **Boolean operations are min/max.** `min(d1, d2)` merges shapes (union). `max(d1, d2)` intersects them. `max(d1, -d2)` subtracts `d2` from `d1`. `smin` blends shapes smoothly. These four operations let you build complex geometry from simple primitives.

4. **Transform the point, not the shape.** Move a shape by subtracting an offset from `p`. Rotate by multiplying `p` with a rotation matrix. Tile infinitely with `mod()`. The SDF function itself never changes — you change what you feed into it.

5. **Anti-aliased rendering uses `smoothstep`.** `smoothstep(px, -px, d)` with `px = fwidth(d)` gives you resolution-independent anti-aliasing. This is better than `step` for almost all visual purposes.

6. **SDFs compose.** The real power is combining simple primitives into complex scenes. A face is circles + booleans. A landscape is smooth-blended circles. Any 2D shape you can imagine can be built from SDF primitives and boolean operations.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Inigo Quilez: 2D Distance Functions](https://iquilezles.org/articles/distfunctions2d/) | Reference | The definitive catalog of 2D SDF primitives. Bookmark this — you will reference it constantly. Every shape has interactive diagrams and minimal code. |
| [Book of Shaders, Ch. 7 (Shapes)](https://thebookofshaders.com/07/) | Interactive tutorial | Interactive examples of drawing shapes with distance fields. Complements the IQ reference with more guided exploration. |
| [Inigo Quilez: Smooth Minimum](https://iquilezles.org/articles/smin/) | Article | Detailed explanation of smooth boolean operations with visualizations and multiple formulations (polynomial, exponential, power). |
| [Inigo Quilez: Useful Little Functions](https://iquilezles.org/articles/functions/) | Reference | A toolkit of shaping functions that are useful for modifying SDFs — gain, impulse, parabola, cubic pulse. Building blocks for advanced SDF manipulation. |
| [SDF Tutorial by Jamie Wong](https://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/) | Blog post | Excellent illustrated walkthrough of SDFs and raymarching. Starts with 2D intuition before extending to 3D. Clear explanations with interactive demos. |

---

## What's Next?

You can now draw shapes, combine them, animate them, and render them with various styles. You have the geometry toolkit. What you are missing is the *color* toolkit.

In [Module 3: Color, Gradients & Blending](module-03-color-gradients-blending.md), you will learn to move beyond hardcoded `vec3(1.0, 0.0, 0.0)` and generate beautiful, smooth color palettes procedurally. The Inigo Quilez cosine palette formula alone is worth the price of admission — four parameters generate infinite color schemes. You will also learn HSB color space, Photoshop-style blend modes, and how to create multi-stop gradients. Combined with the SDF shapes from this module, you will be able to create visually rich scenes from pure math.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
