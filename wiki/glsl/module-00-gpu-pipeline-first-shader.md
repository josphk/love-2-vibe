# Module 0: The GPU Pipeline & Your First Fragment Shader

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** None

---

## Overview

Welcome to the beginning of everything. Before you can make swirling fractals, raymarched landscapes, or that satisfying CRT screen effect you saw on Twitter, you need to understand what a GPU actually *does* and why shader code looks so alien compared to the JavaScript or Python you might be used to. The good news: the core mental model is surprisingly simple, and by the end of this module you will have written real shader code that runs on your actual GPU.

This module starts from absolute zero. We will cover what makes a GPU different from a CPU (spoiler: it is not about being "faster"), walk through the rendering pipeline that transforms geometry into the pixels on your screen, and then zoom in on the **fragment shader** — the tiny per-pixel program that is the heart of everything we will do in this roadmap. You will learn the basic GLSL data types, write your first ShaderToy shader, and start building the intuition for thinking in parallel.

If you have ever written a `for` loop that visits every pixel in an image, you already understand the *what* of fragment shaders. The *how* is where things get interesting — because the GPU does not use a for loop at all. It runs your code on every single pixel simultaneously. That constraint (no loops over pixels, no peeking at your neighbors, no shared mutable state) is what makes shader programming feel like a different discipline. But it is also what makes it blazingly fast and, frankly, a lot of fun once it clicks.

---

## 1. The GPU vs. the CPU: The Stadium Analogy

You have heard that GPUs are "parallel processors," but what does that actually mean in practice?

**The CPU is a brilliant chess grandmaster.** It can solve incredibly complex, branching problems. It handles if-else chains, pointer chasing, recursion, and unpredictable control flow with ease. It is *smart*, but it is one person (or a small handful of people, with modern multi-core CPUs — maybe 8 to 16 grandmasters). When you write normal code, you are writing instructions for this grandmaster.

**The GPU is a stadium full of 50,000 people who can each do basic arithmetic.** None of them are chess grandmasters. They cannot solve complex branching problems efficiently. But if you hand every person in the stadium the *same* worksheet — "multiply these two numbers, add this, take the square root" — they all finish at roughly the same time. Fifty thousand simple math problems, solved simultaneously.

This is the key insight: **a GPU trades sophistication for parallelism**. Your fragment shader is that worksheet. Every "person in the stadium" gets the same shader code, but each one is working on a *different pixel*. Person in seat 1 computes the color for pixel (0, 0). Person in seat 2 computes the color for pixel (1, 0). And so on, for every pixel on screen.

```
CPU approach (pseudocode):
  for x = 0 to 1919:
    for y = 0 to 1079:
      color = computeColor(x, y)   // Sequential: ~2 million iterations
      setPixel(x, y, color)

GPU approach (conceptual):
  // All pixels at once, in parallel:
  each pixel (x, y) runs: color = computeColor(x, y)
  // No loop. No iteration. Just... all of them. At the same time.
```

### What This Means for You

The parallel model imposes strict rules on how you write shader code:

- **No shared state.** Pixel (100, 50) cannot read what pixel (101, 50) computed. There is no global variable you can write to and read from another invocation. Each pixel is on its own.
- **No reading neighbors directly.** You cannot say "what color did the pixel to my left get?" (You *can* read from textures, which we will cover later — but that is reading *input* data, not another pixel's *output*.)
- **Same code, different data.** Every pixel runs the exact same shader program. The only thing that varies is the input: the pixel's coordinates, the current time, the mouse position, etc.
- **No recursion, limited branching.** GPUs handle `if` statements, but they are most efficient when most pixels take the same branch. Deeply nested or wildly divergent branching hurts performance.

If this sounds limiting, you are right — it is. But those limits are exactly what allow the GPU to process millions of pixels in the time a CPU could handle a few thousand. Learning to think within these constraints is a big part of what makes shader programming a unique skill.

---

## 2. The Rendering Pipeline

Before your shader code runs, data flows through a pipeline. Understanding this pipeline helps you see where fragment shaders fit and why they receive the inputs they do.

Here is the simplified version (we will focus on the stages that matter for learning):

```
┌─────────────┐
│  Vertices   │  Raw geometry data: triangle corners as (x, y, z) coordinates
│  (input)    │  plus attributes like color, texture coordinates, normals
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Vertex    │  Runs once per vertex. Transforms positions
│   Shader    │  (e.g., applying camera perspective, animation).
│             │  Output: final screen-space position of each vertex.
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Rasteriza-  │  The GPU figures out which pixels each triangle covers.
│   tion      │  For each covered pixel, it interpolates vertex attributes
│             │  (color, UV coords, etc.) smoothly across the surface.
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Fragment   │  ★ THIS IS WHERE WE LIVE ★
│   Shader    │  Runs once per pixel (fragment). Receives interpolated
│             │  data. Outputs a single color: vec4(R, G, B, A).
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Pixels     │  Final colors are written to the framebuffer.
│  (output)   │  After blending, depth testing, etc. → your screen.
└─────────────┘
```

### Stages Explained

**Vertices (Input):** Everything you see on screen is made of triangles (yes, even circles — they are just triangles with enough subdivisions to look round). Each triangle corner is a *vertex* with a position and optional extra data.

**Vertex Shader:** A small program that runs once per vertex. Its primary job is to transform 3D world positions into 2D screen positions (projection). If you have ever seen a 3D object rotating on screen, the vertex shader is doing that rotation math. We will not write vertex shaders for a while — ShaderToy handles this for us by drawing a single full-screen quad.

**Rasterization:** This is the hardware stage (you do not program it) where the GPU figures out which pixels fall inside each triangle. For a full-screen quad, the answer is "all of them." The rasterizer also *interpolates* — if one vertex is red and another is blue, pixels between them get a smooth blend. This happens automatically.

**Fragment Shader:** Here we are. This program runs once for every pixel (technically every *fragment*, but the distinction rarely matters at this level). It receives inputs — its pixel coordinate, the current time, textures, whatever you pass in — and outputs exactly one thing: a color, as a `vec4(red, green, blue, alpha)`. This is where all the magic in ShaderToy happens.

**Output:** The colors go to a framebuffer, which is just a big array of pixel colors that gets displayed on your monitor.

### Why We Start With the Fragment Shader

In a full OpenGL or Vulkan application, you would need to set up vertex buffers, configure the pipeline, write both vertex and fragment shaders, and manage a lot of boilerplate before seeing a single pixel. ShaderToy abstracts all of that away. It gives you a full-screen quad (two triangles covering every pixel) and lets you *just* write the fragment shader. This is why ShaderToy is such a powerful learning tool — you skip straight to the fun part.

---

## 3. The Fragment Shader: Your Per-Pixel Program

Let us get concrete. Here is the simplest possible ShaderToy shader:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Output a solid red color for every pixel
    fragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
```

That is it. Every pixel on screen becomes red. Let us break down every piece.

### The Function Signature

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
//   ^^^^^^^^^ ShaderToy's entry point (like main() in C)
//              ^^^ "out" means we WRITE to this parameter
//                  ^^^^ a 4-component vector (R, G, B, A)
//                       ^^^^^^^^^ the name — we assign the final color to this
//                                  ^^ "in" means we READ from this parameter
//                                      ^^^^ a 2-component vector (x, y)
//                                           ^^^^^^^^ the pixel's screen coordinate
```

**`mainImage`** is ShaderToy's convention. In raw OpenGL/Vulkan GLSL, the entry point is `void main()` and you write to a special output variable. ShaderToy wraps this for convenience.

**`out vec4 fragColor`** — This is where you put your answer. "What color should this pixel be?" You must write to `fragColor` before the function ends, or you get undefined behavior (usually black, sometimes garbage).

**`in vec2 fragCoord`** — The pixel coordinate this particular invocation is responsible for. If your window is 1920x1080, then `fragCoord` ranges from `(0.5, 0.5)` at the bottom-left to `(1919.5, 1079.5)` at the top-right. Yes, the `.5` is intentional — the coordinate refers to the *center* of the pixel.

### The Color Output

```glsl
fragColor = vec4(1.0, 0.0, 0.0, 1.0);
//               ^^^  ^^^  ^^^  ^^^
//               Red  Grn  Blu  Alpha
//               (each component ranges from 0.0 to 1.0)
```

Colors in GLSL are floating-point values from 0.0 to 1.0, not integers from 0 to 255 like you might be used to. To convert from 0–255 to GLSL range, divide by 255.0:

```glsl
// CSS: rgb(66, 135, 245) — a nice blue
// GLSL: divide each by 255.0
vec3 myBlue = vec3(66.0/255.0, 135.0/255.0, 245.0/255.0);
// Result: approximately vec3(0.259, 0.529, 0.961)
```

The fourth component, **alpha**, controls transparency. For most ShaderToy shaders, set it to `1.0` (fully opaque) and forget about it.

---

## 4. ShaderToy: Your Playground

Head to [https://www.shadertoy.com/new](https://www.shadertoy.com/new) to create a new shader. Here is what you will see:

### The Interface

- **Code editor (center/bottom):** Where your GLSL code lives. The default new shader shows a gradient — we will replace it.
- **Preview (top):** A live preview of your shader output, updating as you type.
- **Compile button / Alt+Enter:** Recompiles your shader. If there are errors, they show below the editor.
- **iTime, iResolution, iMouse:** These are *uniforms* — global read-only values that ShaderToy provides to your shader automatically.

### ShaderToy's Built-in Uniforms

ShaderToy provides several useful inputs. For now, focus on these three:

| Uniform | Type | What It Contains |
|---|---|---|
| `iResolution` | `vec3` | Viewport size in pixels. `.x` = width, `.y` = height, `.z` = pixel aspect ratio (usually 1.0) |
| `iTime` | `float` | Seconds since the shader started running |
| `iMouse` | `vec4` | Mouse position. `.xy` = current pos when clicked, `.zw` = click position |

You do not need to declare these — ShaderToy injects them automatically. Just use them in your code:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalize coordinates to 0.0–1.0 range
    vec2 uv = fragCoord / iResolution.xy;

    // Use normalized x as red, y as green
    fragColor = vec4(uv.x, uv.y, 0.0, 1.0);
}
```

This gives you a gradient: black at bottom-left, red at bottom-right, green at top-left, yellow at top-right. Try it. Change values. Break things. That is how you learn.

### A Note on Errors

GLSL compiler errors are notoriously cryptic. A few survival tips:

- **The line number is usually close but not always exact.** ShaderToy adds wrapper code, so line numbers may be off by a few.
- **Missing semicolons** produce wildly misleading error messages. If an error makes no sense, check for missing semicolons first.
- **`float` vs `int` matters.** Writing `1` instead of `1.0` can cause type errors. Always use the decimal point for floats.

---

## 5. GLSL Types: Vectors and Matrices

GLSL is a C-like language, but it has first-class support for the types that GPU programming needs most: vectors and matrices. These are not library types or structs you import — they are *built into the language*.

### Scalar Types

```glsl
float f = 3.14;    // 32-bit floating point (this is your bread and butter)
int   i = 42;      // 32-bit signed integer
uint  u = 7u;      // 32-bit unsigned integer (note the 'u' suffix)
bool  b = true;    // Boolean
```

**Important:** GLSL does not do implicit type conversion the way C does. You cannot write `float f = 1;` — you must write `float f = 1.0;`. This trips up beginners constantly.

### Vector Types

```glsl
vec2  v2 = vec2(1.0, 2.0);          // 2 floats (position, UV coordinates)
vec3  v3 = vec3(1.0, 2.0, 3.0);     // 3 floats (color RGB, 3D position)
vec4  v4 = vec4(1.0, 2.0, 3.0, 4.0); // 4 floats (color RGBA, homogeneous coords)

ivec2 iv = ivec2(1, 2);             // 2 ints
bvec3 bv = bvec3(true, false, true); // 3 bools
```

### Constructing Vectors

GLSL is flexible about how you build vectors:

```glsl
// All equivalent ways to make a vec4:
vec4 a = vec4(1.0, 2.0, 3.0, 4.0);   // Four separate floats
vec4 b = vec4(vec2(1.0, 2.0), 3.0, 4.0); // A vec2 + two floats
vec4 c = vec4(vec3(1.0, 2.0, 3.0), 4.0); // A vec3 + one float
vec4 d = vec4(1.0);                    // All four components = 1.0

// This also works for building smaller vectors:
vec3 color = vec3(0.5);               // vec3(0.5, 0.5, 0.5) — medium gray
```

The `vec4(1.0)` shorthand (broadcasting a single value to all components) is extremely common and worth memorizing.

### Matrix Types

```glsl
mat2 m2;  // 2x2 matrix (4 floats)
mat3 m3;  // 3x3 matrix (9 floats)
mat4 m4;  // 4x4 matrix (16 floats)
```

We will not use matrices much in the first few modules, but know they exist. They are how transformations (rotation, scaling, projection) are represented. GLSL supports matrix-vector multiplication with the `*` operator, which is very convenient:

```glsl
mat2 rotation = mat2(cos(angle), -sin(angle),
                     sin(angle),  cos(angle));
vec2 rotated = rotation * originalPoint;  // Matrix * vector multiplication — built in!
```

### Arithmetic on Vectors

This is where GLSL shines compared to regular programming. All arithmetic operations work **component-wise** on vectors:

```glsl
vec3 a = vec3(1.0, 2.0, 3.0);
vec3 b = vec3(4.0, 5.0, 6.0);

vec3 c = a + b;    // vec3(5.0, 7.0, 9.0)
vec3 d = a * b;    // vec3(4.0, 10.0, 18.0)  — component-wise, NOT dot product
vec3 e = a * 2.0;  // vec3(2.0, 4.0, 6.0)    — scalar * vector
vec3 f = a / b;    // vec3(0.25, 0.4, 0.5)   — component-wise division
```

The fact that `a * b` is component-wise multiplication (not dot product) surprises people coming from linear algebra. For dot product, use the `dot()` function:

```glsl
float d = dot(a, b);   // 1*4 + 2*5 + 3*6 = 32.0
vec3  c = cross(a, b); // Cross product (only for vec3)
float l = length(a);   // sqrt(1^2 + 2^2 + 3^2) = 3.742
vec3  n = normalize(a); // a / length(a) — unit vector
```

---

## 6. Swizzling: Rearranging Vector Components

Swizzling is one of GLSL's most distinctive features, and once you get used to it, you will miss it in every other language.

Every vector's components can be accessed by name, and you can **rearrange, repeat, or select subsets** of components freely:

```glsl
vec4 color = vec4(1.0, 0.5, 0.2, 1.0);

// Access individual components:
float r = color.r;    // 1.0  (first component)
float g = color.g;    // 0.5  (second component)
float b = color.b;    // 0.2  (third component)
float a = color.a;    // 1.0  (fourth component)

// Grab a subset — creates a NEW vector:
vec3 rgb = color.rgb;   // vec3(1.0, 0.5, 0.2)
vec2 rg  = color.rg;    // vec2(1.0, 0.5)

// Rearrange components:
vec3 bgr = color.bgr;   // vec3(0.2, 0.5, 1.0) — reversed!
vec4 rrrr = color.rrrr; // vec4(1.0, 1.0, 1.0, 1.0) — repeat!

// Swizzle on the LEFT side of assignment (write to specific components):
color.rb = vec2(0.0, 0.8);  // Now color = vec4(0.0, 0.5, 0.8, 1.0)
```

### The Three Naming Conventions

GLSL provides three sets of component names. They are interchangeable aliases — pick whichever is most readable for your context:

| Set | Components | Typical Use |
|---|---|---|
| `xyzw` | `.x .y .z .w` | Positions and coordinates |
| `rgba` | `.r .g .b .a` | Colors |
| `stpq` | `.s .t .p .q` | Texture coordinates |

These are purely cosmetic. `color.r` and `color.x` access the exact same component. But **do not mix sets** in a single swizzle — `color.xg` is a compile error.

```glsl
vec4 v = vec4(1.0, 2.0, 3.0, 4.0);

v.x == v.r == v.s   // All refer to the first component (1.0)
v.xy == v.rg == v.st // All refer to the first two components

v.xg;  // ERROR: Cannot mix 'x' (position set) with 'g' (color set)
```

### Why Swizzling Matters

Swizzling is not just syntactic sugar — it compiles down to efficient GPU instructions for shuffling data between registers. It also makes shader code significantly more readable:

```glsl
// Without swizzling (verbose):
vec3 flipped;
flipped.x = original.z;
flipped.y = original.y;
flipped.z = original.x;

// With swizzling (clean):
vec3 flipped = original.zyx;
```

---

## 7. Parallelism: Thinking in Pixels

This is the conceptual shift that takes the longest to internalize, so let us spend some time on it.

In normal programming, if you want to draw a red circle on a white background, you might write:

```
// Pseudocode — CPU approach
create a white image
for each pixel (x, y) in the circle's area:
    if distance(x, y, center) < radius:
        setPixel(x, y, RED)
```

You iterate over pixels, check a condition, and set individual pixels. You have full control over which pixels you visit and in what order.

**In a fragment shader, you do not iterate over pixels.** You write a function that answers one question: *"Given that I am pixel (x, y), what color should I be?"*

```glsl
// GLSL — GPU approach
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 center = iResolution.xy * 0.5;  // Center of screen
    float radius = 100.0;

    // "Am I inside the circle?"
    float dist = distance(fragCoord, center);

    if (dist < radius) {
        fragColor = vec4(1.0, 0.0, 0.0, 1.0); // Red
    } else {
        fragColor = vec4(1.0, 1.0, 1.0, 1.0); // White
    }
}
```

Every pixel on the screen runs this exact code simultaneously. Each pixel independently asks "am I in the circle?" and colors itself accordingly. There is no loop. There is no "draw" command. There is just the question and the answer.

### The Rules of Parallel Pixel Land

1. **You only control YOUR pixel.** You write to `fragColor` and that is it. You cannot write to the pixel next door.
2. **You cannot read other pixels' outputs.** Pixel (100, 50) has no idea what pixel (101, 50) decided to output. (Textures let you read *input* data that was prepared beforehand, but never another pixel's current output.)
3. **Order does not exist.** There is no guarantee that pixel (0, 0) runs before pixel (1, 0). They might all run at exactly the same time, or in any arbitrary order. Your code must not depend on execution order.
4. **No persistent local state.** Each invocation starts fresh. There is no way to say "remember this value from the last time this pixel ran." (Multi-pass rendering, which ShaderToy supports, is the workaround for this — but that is a later module.)

### Mental Model: The Question Machine

Think of your fragment shader as a **pure function** in the mathematical sense:

```
f(pixel_coordinate, time, mouse, ...) → color
```

Same inputs always produce the same output. No side effects. No state. If you have experience with functional programming, this should feel familiar. If you do not, this is a great introduction to the concept.

---

## 8. Key GLSL Functions for Beginners

Before we get to the walkthrough, here is a handful of built-in GLSL functions you will use constantly. You do not need to memorize them all right now — just know they exist so you can reach for them later.

### Math Basics

```glsl
abs(x)          // Absolute value: abs(-3.0) = 3.0
sign(x)         // Returns -1.0, 0.0, or 1.0
floor(x)        // Round down: floor(3.7) = 3.0
ceil(x)         // Round up: ceil(3.2) = 4.0
fract(x)        // Fractional part: fract(3.7) = 0.7  (equivalent to x - floor(x))
mod(x, y)       // Modulo: mod(5.0, 3.0) = 2.0

min(a, b)       // Minimum of two values
max(a, b)       // Maximum of two values
clamp(x, lo, hi) // Clamp x to range [lo, hi]
```

### Interpolation and Steps

```glsl
mix(a, b, t)    // Linear interpolation: a*(1-t) + b*t
                // mix(0.0, 10.0, 0.3) = 3.0
                // Works on vectors too! mix(colorA, colorB, 0.5) blends colors

step(edge, x)   // Returns 0.0 if x < edge, 1.0 if x >= edge
                // Like a hard threshold / if-else in one function
                // step(0.5, 0.3) = 0.0
                // step(0.5, 0.7) = 1.0

smoothstep(lo, hi, x) // Smooth transition from 0.0 to 1.0 as x goes from lo to hi
                      // Like step() but with a smooth curve instead of a hard edge
```

### Why `step()` and `smoothstep()` Instead of `if`?

You will see experienced shader programmers avoid `if` statements and use `step()` or `mix()` instead. There are two reasons:

1. **GPU branching is expensive.** When some pixels take the `if` branch and others take the `else` branch, the GPU has to run *both* branches for the entire group and throw away the unused results. `step()` avoids branching entirely.
2. **Smooth transitions.** Hard `if/else` boundaries create jagged, aliased edges. `smoothstep()` gives you an anti-aliased transition for free.

```glsl
// Using if (works, but can be slower and creates hard edges):
if (uv.x > 0.5) {
    fragColor = vec4(1.0, 0.0, 0.0, 1.0);
} else {
    fragColor = vec4(0.0, 0.0, 1.0, 1.0);
}

// Using step (branchless, same hard edge):
float t = step(0.5, uv.x);
fragColor = vec4(t, 0.0, 1.0 - t, 1.0);

// Using smoothstep (branchless AND smooth transition):
float t = smoothstep(0.49, 0.51, uv.x);
fragColor = vec4(t, 0.0, 1.0 - t, 1.0);
```

### Geometry Functions

```glsl
length(v)            // Length of a vector: sqrt(v.x^2 + v.y^2 + ...)
distance(a, b)       // Distance between two points: length(a - b)
normalize(v)         // Unit vector: v / length(v)
dot(a, b)            // Dot product
```

All of these work on any vector size (`vec2`, `vec3`, `vec4`), and they are *heavily* optimized by the GPU hardware.

---

## 9. Understanding Color in GLSL

Since fragment shaders output colors, having a solid mental model for color is essential.

### RGB Color Space

In GLSL, colors are `vec3` (RGB) or `vec4` (RGBA) with each component ranging from 0.0 to 1.0:

```glsl
vec3 black   = vec3(0.0, 0.0, 0.0);  // No light
vec3 white   = vec3(1.0, 1.0, 1.0);  // Full light
vec3 red     = vec3(1.0, 0.0, 0.0);
vec3 green   = vec3(0.0, 1.0, 0.0);
vec3 blue    = vec3(0.0, 0.0, 1.0);
vec3 yellow  = vec3(1.0, 1.0, 0.0);  // Red + Green = Yellow (additive color!)
vec3 cyan    = vec3(0.0, 1.0, 1.0);  // Green + Blue
vec3 magenta = vec3(1.0, 0.0, 1.0);  // Red + Blue
vec3 gray50  = vec3(0.5);            // 50% gray (shorthand!)
```

### Additive Color

If you are used to mixing paint, GPU colors work the opposite way. Paint is *subtractive* (mixing all colors gives you mud/black). Light is *additive* (mixing all colors gives you white). This is why `vec3(1.0, 1.0, 0.0)` — full red plus full green — gives you bright yellow, not brownish green.

### Using Color as Data

Here is a mind-bending thing about shaders: colors are just vectors, and vectors are just numbers. You can do math on colors the same way you do math on positions:

```glsl
// Darken a color by 50%
vec3 dark = color * 0.5;

// Blend two colors
vec3 blended = mix(colorA, colorB, 0.5);

// Tint a grayscale value
float brightness = 0.7;
vec3 tinted = brightness * vec3(1.0, 0.8, 0.6);  // Warm tint

// "Multiply" blend mode (like Photoshop)
vec3 result = colorA * colorB;
```

This interchangeability between "colors" and "math" is one of the most powerful aspects of shader programming. A distance field is just a grayscale image. A normal map is just an image where RGB encodes XYZ directions. Everything is numbers.

---

## 10. Coordinate Systems and Normalization

Understanding coordinate systems is so important that the entire next module is dedicated to it. But you need the basics right now to make sense of your first shaders.

### Raw Pixel Coordinates (`fragCoord`)

`fragCoord` gives you the pixel position in the viewport:

```
(0.5, 1079.5)  <---------------->  (1919.5, 1079.5)
       |                                  |
       |        Your screen               |
       |        (1920 x 1080)             |
       |                                  |
(0.5, 0.5)  <---------------->  (1919.5, 0.5)
```

**Note:** The origin (0, 0) is at the **bottom-left**, not the top-left. This is the opposite of most 2D graphics APIs and will confuse you at least once. Y increases upward. The `.5` offset means coordinates refer to pixel centers.

### Normalizing to 0–1

Raw pixel coordinates are resolution-dependent. A shader that looks great at 800x600 will look totally different at 1920x1080. The fix: **normalize** by dividing by the resolution.

```glsl
// Normalize fragCoord to 0.0–1.0 range
vec2 uv = fragCoord / iResolution.xy;
// Now uv.x goes from 0.0 (left) to 1.0 (right)
// and uv.y goes from 0.0 (bottom) to 1.0 (top)
// regardless of window size
```

This pattern — `vec2 uv = fragCoord / iResolution.xy;` — is the most common first line in any ShaderToy shader. You will write it hundreds of times.

### Centering Coordinates

Often you want (0, 0) at the center of the screen, not the corner. There are several ways to do this, which Module 1 covers in depth. Here is a quick preview:

```glsl
// Centered: ranges from -0.5 to 0.5
vec2 uv = (fragCoord / iResolution.xy) - 0.5;

// Centered AND aspect-ratio corrected (circles stay circular):
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
```

---

## Code Walkthrough: Split-Screen Color Shader

Let us build a complete, working ShaderToy shader step by step. This shader will color the left half of the screen blue and the right half red, with a smooth gradient transition between them.

### Step 1: The Skeleton

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // We will build this up line by line
}
```

### Step 2: Normalize Coordinates

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Convert pixel coordinates (0 to ~1920) into
    // normalized coordinates (0.0 to 1.0)
    vec2 uv = fragCoord / iResolution.xy;
}
```

### Step 3: Determine Left vs. Right

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // uv.x < 0.5 means left half, uv.x >= 0.5 means right half
    // step(0.5, uv.x) returns:
    //   0.0 when uv.x < 0.5 (left side)
    //   1.0 when uv.x >= 0.5 (right side)
    float t = step(0.5, uv.x);
}
```

### Step 4: Mix Between Colors

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    float t = step(0.5, uv.x);

    // Define our two colors
    vec3 blue = vec3(0.1, 0.3, 0.9);
    vec3 red  = vec3(0.9, 0.2, 0.1);

    // mix() blends between blue (when t=0) and red (when t=1)
    vec3 color = mix(blue, red, t);

    // Output with full opacity
    fragColor = vec4(color, 1.0);
}
```

### Step 5: Add Smooth Transition (Final Version)

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // --- Normalize coordinates to 0.0–1.0 ---
    vec2 uv = fragCoord / iResolution.xy;

    // --- Create a smooth transition zone ---
    // smoothstep creates a gradual blend from 0.0 to 1.0
    // as uv.x travels from 0.45 to 0.55
    // (a 10% wide transition band centered at the midpoint)
    float t = smoothstep(0.45, 0.55, uv.x);

    // --- Define colors ---
    vec3 blue = vec3(0.1, 0.3, 0.9);  // Left side
    vec3 red  = vec3(0.9, 0.2, 0.1);  // Right side

    // --- Blend ---
    vec3 color = mix(blue, red, t);

    // --- Output ---
    fragColor = vec4(color, 1.0);
}
```

### What This Demonstrates

- **Coordinate normalization** — `fragCoord / iResolution.xy` makes everything resolution-independent
- **`step()` vs `smoothstep()`** — hard edge vs. smooth transition (try replacing `smoothstep` with `step` to see the difference)
- **`mix()` for color blending** — linearly interpolating between two `vec3` colors using a scalar
- **Building up a `vec4` from a `vec3`** — `vec4(color, 1.0)` appends the alpha channel
- **The shader-thinking pattern** — every pixel asks "where am I?" and chooses its color accordingly

Paste the final version into [ShaderToy](https://www.shadertoy.com/new) and experiment. Change the colors. Move the split point. Make the transition wider or narrower. Change `smoothstep(0.45, 0.55, ...)` to `smoothstep(0.0, 1.0, ...)` and see what a full-screen gradient looks like.

---

## GLSL Quick Reference

Functions and concepts introduced in this module:

| Function/Concept | Description | Example |
|---|---|---|
| `vec2`, `vec3`, `vec4` | Vector types (2, 3, 4 components) | `vec3 color = vec3(1.0, 0.0, 0.0);` |
| `float`, `int`, `bool` | Scalar types | `float t = 0.5;` |
| `mat2`, `mat3`, `mat4` | Matrix types | `mat2 rot = mat2(c, -s, s, c);` |
| Swizzling | Rearrange vector components | `v.xy`, `color.rgb`, `v.zyx` |
| `vec4(1.0)` | Broadcast scalar to all components | Creates `vec4(1.0, 1.0, 1.0, 1.0)` |
| `step(edge, x)` | 0.0 if `x < edge`, else 1.0 | `step(0.5, uv.x)` |
| `smoothstep(lo, hi, x)` | Smooth 0-to-1 transition from lo to hi | `smoothstep(0.45, 0.55, uv.x)` |
| `mix(a, b, t)` | Linear interpolation: `a*(1-t) + b*t` | `mix(blue, red, 0.5)` |
| `length(v)` | Vector length | `length(vec2(3.0, 4.0))` = 5.0 |
| `distance(a, b)` | Distance between two points | `distance(uv, center)` |
| `normalize(v)` | Unit vector in same direction | `normalize(vec2(3.0, 4.0))` |
| `dot(a, b)` | Dot product | `dot(normal, lightDir)` |
| `clamp(x, lo, hi)` | Restrict value to range | `clamp(color, 0.0, 1.0)` |
| `fract(x)` | Fractional part (`x - floor(x)`) | `fract(3.7)` = 0.7 |
| `mod(x, y)` | Modulo | `mod(5.0, 3.0)` = 2.0 |
| `abs(x)` | Absolute value | `abs(-3.0)` = 3.0 |
| `iResolution` | Viewport size (ShaderToy uniform) | `fragCoord / iResolution.xy` |
| `iTime` | Elapsed time in seconds (ShaderToy) | `sin(iTime)` |
| `iMouse` | Mouse position (ShaderToy uniform) | `iMouse.xy / iResolution.xy` |
| `fragCoord` | Pixel coordinate (ShaderToy input) | Bottom-left origin, `.5` centered |

---

## Common Pitfalls

### 1. Forgetting the Decimal Point on Floats

GLSL is strict about types. An integer literal where a float is expected will cause a compile error or subtle bugs.

```glsl
// WRONG — type mismatch: '1' is an int, not a float
vec3 color = vec3(1, 0, 0);
float half = 1 / 2;        // Integer division! Result is 0, not 0.5

// RIGHT — always use decimal points for floats
vec3 color = vec3(1.0, 0.0, 0.0);
float half = 1.0 / 2.0;    // Result is 0.5
```

### 2. Mixing Swizzle Sets

Each swizzle set (`xyzw`, `rgba`, `stpq`) must be used consistently within a single swizzle expression.

```glsl
vec4 v = vec4(1.0, 2.0, 3.0, 4.0);

// WRONG — mixing position ('x') and color ('g') sets
vec2 bad = v.xg;

// RIGHT — stick to one set
vec2 good = v.xy;   // Position set
vec2 also = v.rg;   // Color set (same result)
```

### 3. Assuming Top-Left Origin

Unlike most 2D graphics APIs (Canvas, SDL, screen coordinates), GLSL's `fragCoord` has its origin at the **bottom-left**. Y increases upward.

```glsl
// WRONG — if you expect top-left origin:
float t = fragCoord.y / iResolution.y;
// t = 0.0 at bottom, 1.0 at top (opposite of what you might expect)

// RIGHT — if you need top-left origin, flip Y:
float t = 1.0 - (fragCoord.y / iResolution.y);
// Now t = 0.0 at top, 1.0 at bottom
```

### 4. Colors Outside 0–1 Range

GLSL does not clamp your color output automatically (values outside 0–1 get clamped at the final output stage, but intermediate math can produce unexpected results).

```glsl
// WRONG — math can push values out of range unexpectedly
vec3 color = vec3(0.8) + vec3(0.5);  // vec3(1.3) — will be clamped to 1.0

// RIGHT — clamp when you know values might exceed range
vec3 color = clamp(vec3(0.8) + vec3(0.5), 0.0, 1.0);

// ALSO RIGHT — sometimes you WANT values > 1.0 for intermediate math
// Just be aware of it
```

### 5. Forgetting That `*` Is Component-Wise for Vectors

If you are expecting matrix multiplication or dot product behavior from the `*` operator on two vectors, you will get wrong results.

```glsl
vec3 a = vec3(1.0, 2.0, 3.0);
vec3 b = vec3(4.0, 5.0, 6.0);

// This is component-wise multiplication, NOT dot product
vec3 c = a * b;  // vec3(4.0, 10.0, 18.0)

// For dot product, use the dot() function
float d = dot(a, b);  // 1*4 + 2*5 + 3*6 = 32.0

// Matrix * vector IS matrix multiplication (correct behavior)
vec2 transformed = mat2(...) * someVec2;  // Actual matrix multiply
```

### 6. Missing Semicolons Producing Cryptic Errors

GLSL error messages for missing semicolons are often completely misleading — they will point to the *next* line and complain about something unrelated.

```glsl
// WRONG — missing semicolon on line 3
vec2 uv = fragCoord / iResolution.xy    // <- Missing semicolon HERE
float t = step(0.5, uv.x);             // Error points HERE, confusingly

// RIGHT
vec2 uv = fragCoord / iResolution.xy;   // <- Semicolon present
float t = step(0.5, uv.x);             // Compiles fine
```

**Survival tip:** When you get a baffling error, check the line *above* the reported line number for a missing semicolon.

---

## Exercises

### Exercise 1: Solid Color Picker

**Time:** 10–15 minutes

Write a ShaderToy shader that displays a single solid color of your choice. Start with something simple, then try to match a specific color. Pick a color from any website or application (use a color picker to get the RGB values), convert from 0–255 to 0.0–1.0, and display it.

**Stretch:** Display four quadrants, each a different solid color. Use `step()` on both `uv.x` and `uv.y` to determine which quadrant the current pixel is in.

*Hint for quadrants:*
```glsl
float isRight = step(0.5, uv.x);   // 0 = left, 1 = right
float isTop   = step(0.5, uv.y);   // 0 = bottom, 1 = top
// Combine these to pick one of four colors...
```

**Concepts practiced:** vec4 color output, coordinate normalization, step(), basic shader structure

---

### Exercise 2: Gradient Explorer

**Time:** 20–30 minutes

Create a shader that displays a smooth horizontal gradient from one color to another. Then modify it to:
1. Make the gradient vertical instead of horizontal
2. Make a diagonal gradient (hint: use `(uv.x + uv.y) / 2.0`)
3. Make a radial gradient from the center of the screen outward (hint: use `distance()` and the centered coordinate system)

**Stretch:** Animate the gradient by incorporating `iTime`. For example, make the gradient slowly shift position using `sin(iTime)`, or make the colors themselves cycle over time.

*Hint for radial gradient:*
```glsl
vec2 center = vec2(0.5, 0.5);
float d = distance(uv, center);
// d is now 0.0 at center, ~0.7 at corners
// Use it as your mix() parameter
```

**Concepts practiced:** mix(), distance(), sin(), iTime, coordinate manipulation, thinking spatially

---

### Exercise 3: Split Screen with `step()`

**Time:** 30–45 minutes

This is the exercise from the roadmap: write a shader that colors the left half of the screen blue and the right half red, using `fragCoord.x`, `iResolution.x`, and `step()`. Then extend it:

1. Start with the hard-edge version using `step()`
2. Replace `step()` with `smoothstep()` and experiment with different transition widths
3. Make the split point follow the mouse x-position (hint: use `iMouse.x / iResolution.x`)
4. Add a third color in the middle using two `smoothstep()` calls

**Stretch:** Make the split boundary a wavy line instead of straight. Use `sin()` on the y-coordinate to offset the split point:

```glsl
// Instead of splitting at exactly 0.5:
float splitPoint = 0.5 + 0.05 * sin(uv.y * 20.0);
float t = smoothstep(splitPoint - 0.01, splitPoint + 0.01, uv.x);
```

Add `iTime` to the `sin()` argument to animate the wave.

**Concepts practiced:** step(), smoothstep(), mix(), iMouse, iTime, sin(), combining multiple concepts

---

## Key Takeaways

1. **The GPU is a massively parallel processor.** It runs your fragment shader on thousands of pixels simultaneously. This is what makes it fast — and what constrains how you write code. No shared state, no reading neighbors, same code for every pixel.

2. **The rendering pipeline transforms vertices into pixels.** Vertex shader positions geometry, rasterization determines which pixels are covered, and the fragment shader decides the final color of each pixel. ShaderToy lets you skip straight to the fragment shader.

3. **A fragment shader is a pure function from coordinate to color.** It takes in a pixel position (`fragCoord`), optional uniforms (`iTime`, `iResolution`, `iMouse`), and outputs a single `vec4` color. Every pixel independently evaluates this function.

4. **GLSL has first-class vector and matrix types.** `vec2`, `vec3`, `vec4` are not library types — they are built into the language. Arithmetic operations work component-wise, and swizzling (`v.xy`, `color.rgb`, `v.zyx`) lets you flexibly rearrange components.

5. **`step()`, `smoothstep()`, and `mix()` replace if-else in many cases.** These functions are branchless (efficient on GPUs) and naturally produce smooth transitions. Getting comfortable with them is a core shader skill.

6. **Normalizing coordinates is always step one.** `vec2 uv = fragCoord / iResolution.xy` converts pixel coordinates to a 0–1 range, making your shader resolution-independent. This line will appear at the top of nearly every shader you write.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Book of Shaders, Ch. 1–3](https://thebookofshaders.com/01/) | Interactive tutorial | Beautiful, interactive introduction to the same concepts covered here, with live editable examples. Start here for reinforcement. |
| [LearnOpenGL: Hello Triangle](https://learnopengl.com/Getting-started/Hello-Triangle) | Tutorial | Shows the full OpenGL pipeline with vertex buffers and boilerplate. Helps you appreciate what ShaderToy abstracts away. Read for context, not to memorize. |
| [A Journey Into Shaders](https://blog.maximeheckel.com/posts/the-study-of-shaders-with-react-three-fiber/) by Maxime Heckel | Blog post | Excellent visual walkthrough of shader fundamentals using Three.js. Different framework, same GLSL concepts. Great supplementary perspective. |
| [ShaderToy](https://www.shadertoy.com/) | Playground | Browse other people's shaders. Click "Show code" on anything that catches your eye. You will not understand most of it yet — but you will see the patterns we cover here. |
| [GLSL Spec Quick Reference (OpenGL ES 3.0)](https://www.khronos.org/files/opengles3-quick-reference-card.pdf) | Reference card | Two-page PDF with every GLSL type, function, and qualifier. Print it out. Keep it next to your keyboard. |

---

## What's Next?

You have written your first fragment shader, and you understand the big picture: the GPU runs your code on every pixel simultaneously, your shader is a function from coordinate to color, and GLSL gives you powerful vector types with built-in math operations. That is a solid foundation.

In [Module 1: Coordinates, Uniforms & Math Toolbox](module-01-coordinates-uniforms-math.md), we will dig much deeper into coordinate systems — centering, aspect ratio correction, and remapping ranges. You will learn about all of ShaderToy's uniforms, get comfortable with the essential math functions (`sin`, `cos`, `fract`, `mod`, `abs`), and start combining them to create animated patterns. The coordinate work in Module 1 is foundational for everything that follows, so take the exercises here seriously before moving on.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
