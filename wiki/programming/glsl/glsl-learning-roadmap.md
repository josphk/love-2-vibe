# GLSL / Shader Programming Learning Roadmap

**For:** Game developer who wants to understand shaders from the ground up · ShaderToy as playground · Framework-agnostic · Reads > watches · ADHD-friendly

---

## How This Roadmap Works

This roadmap teaches you to **think in parallel**. Shader programming is unlike anything you've written before — you don't loop over pixels, you write the logic for *one* pixel, and the GPU runs it on all of them simultaneously. It's math made visual, and it's the most creatively rewarding skill in game development.

The core path (Modules 0-6) is linear — each builds on the last. After that, modules branch based on interest. You don't need to learn raymarching to do post-processing, and you don't need vertex shaders to do 2D lighting. Follow the dependency graph and jump to whatever excites you.

ShaderToy is your primary playground. Everything through Module 6 can be done entirely in a browser tab. No engine, no build system, no asset pipeline. Just you and math.

Each module below is a summary. Click the "Deep dive" link on any module to open the full study guide with detailed explanations, code walkthroughs, and additional exercises.

**Dependency graph:**
```
0 → 1 → 2 → 3 → 4 → 5 → 6 (linear core)
                              ↓
           7 (2D lighting — after 2+5)
           8 (vertex shaders — after 1)
           9 (post-processing — after 6)
          10 (raymarching — after 2, benefits from 5+7)
          11 (animation/interactive — after 4)
          12 (porting to engines — whenever ready)
```

---

## Module 0: The GPU Pipeline & Your First Fragment Shader

> **Deep dive:** [Full study guide](module-00-gpu-pipeline-first-shader.md)

**Goal:** Understand what a GPU does, write a fragment shader that outputs a color.

Before you write a single line of GLSL, you need a mental model of what's actually happening. A GPU is not a faster CPU — it's a fundamentally different machine. A CPU is a brilliant chess player solving one problem at a time with great sophistication. A GPU is a stadium full of people who can all do simple arithmetic simultaneously. Shader programming is writing the instruction card that every person in the stadium follows at once.

The rendering pipeline goes: **vertices in → vertex shader → rasterization → fragment shader → pixels out.** You're going to start at the end — the fragment shader — because that's where all the visual magic happens and you get instant visual feedback. A fragment shader runs once per pixel on screen. It receives a coordinate and must output a color. That's the entire contract.

Open ShaderToy (https://www.shadertoy.com/new) and you'll see a default shader. Replace it with:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
```

Red screen. You just told every pixel on the screen to be red. Change the numbers. Mix them. Break it. Fix it. You're programming a GPU.

**Key concepts:**
- **Fragment shader:** A program that runs per-pixel and outputs a color (vec4: red, green, blue, alpha)
- **The GPU pipeline:** Vertex data → vertex shader → rasterization → fragment shader → framebuffer
- **Parallelism:** Every pixel runs your code independently and simultaneously — no shared state, no reading from neighboring pixels (unless you use textures)
- **GLSL types:** `float`, `vec2`, `vec3`, `vec4`, `mat2`, `mat3`, `mat4` — vectors and matrices are first-class citizens, not library imports
- **Swizzling:** `color.rgb`, `pos.xy`, `v.xyzw` — you can rearrange vector components freely

**Read:**
- The Book of Shaders, Chapter 1-3: https://thebookofshaders.com/01/ — the gentlest introduction to fragment shaders that exists
- LearnOpenGL, "Hello Triangle" (the pipeline explanation, not the C++ code): https://learnopengl.com/Getting-started/Hello-Triangle
- "A Journey Into Shaders" by Maxime Heckel: https://blog.maximeheckel.com/posts/the-study-of-shaders-with-react-three-fiber/ — despite the R3F title, the first half is a pure GLSL mental model explainer

**Exercise:** In ShaderToy, write a fragment shader that colors the left half of the screen blue and the right half red. Hint: `fragCoord.x` gives you the pixel's horizontal position, and `iResolution.x` gives you the screen width. You'll need an `if` statement (or better, `step()`).

**Time:** 2-3 hours

---

## Module 1: Coordinates, Uniforms & Math Toolbox

> **Deep dive:** [Full study guide](module-01-coordinates-uniforms-math.md)

**Goal:** Master UV coordinates, time/mouse uniforms, essential GLSL functions.

Raw pixel coordinates (`fragCoord`) are messy — they change with screen resolution. The first thing every shader programmer learns is to **normalize** them into UV coordinates: values from 0.0 to 1.0 (or -1.0 to 1.0 if centered). This is the foundation of everything. Every pattern, every shape, every effect you'll build starts with `vec2 uv = fragCoord / iResolution.xy;`.

Uniforms are values the CPU sends to the GPU each frame. ShaderToy gives you several for free: `iTime` (seconds since start), `iMouse` (mouse position), `iResolution` (screen size). These are your connection to the outside world — without them, every frame would look identical.

**The GLSL math toolbox** is small but powerful. You'll use these functions constantly, and understanding them deeply is what separates someone who copies shader code from someone who writes it:

- **`mix(a, b, t)`** — linear interpolation. The single most important function. Blend between any two values.
- **`step(edge, x)`** — hard cutoff. Returns 0.0 if x < edge, 1.0 otherwise. Sharp borders.
- **`smoothstep(lo, hi, x)`** — soft cutoff. Smooth transition between lo and hi. Soft borders.
- **`clamp(x, min, max)`** — constrain a value to a range.
- **`mod(x, y)` and `fract(x)`** — modulo and fractional part. The basis of all repeating patterns.
- **`sin()`, `cos()`, `atan()`** — trigonometry drives oscillation, rotation, circular shapes.
- **`length()`, `distance()`, `dot()`, `normalize()`** — vector operations. Distance from center is `length(uv - 0.5)`.
- **`abs()`, `sign()`, `min()`, `max()`** — utility everywhere.

Think of `mix` as your paintbrush, `step`/`smoothstep` as your stencil, and `sin`/`fract` as your pattern generators. The rest is combining them.

**Read:**
- The Book of Shaders, Chapter 5 (Shaping Functions): https://thebookofshaders.com/05/ — interactive graphs of every key function
- The Book of Shaders, Chapter 6 (Colors): https://thebookofshaders.com/06/
- GLSL Built-in Functions quick reference: https://docs.gl/sl4/abs (click through the sidebar for each function)

**Exercise:** Create an animated gradient that shifts hue over time. Start with `uv.x` controlling one color channel and `sin(iTime)` modulating another. Then add a radial gradient from the center using `length()`. Make the mouse position (`iMouse.xy / iResolution.xy`) control something — the center point, the speed, the color balance.

**Time:** 3-5 hours

---

## Module 2: Shapes with Signed Distance Functions

> **Deep dive:** [Full study guide](module-02-shapes-sdf.md)

**Goal:** Draw circles, rectangles, lines using SDFs; combine, outline, glow.

Here's the fundamental idea: instead of "drawing" a shape, you compute the **distance** from the current pixel to the nearest edge of the shape. If the distance is negative, you're inside. If positive, you're outside. If zero, you're on the edge. This is a signed distance function (SDF), and it's the single most powerful technique in shader-based graphics.

A circle SDF is just `length(uv - center) - radius`. That's it. Every pixel computes its distance to the circle's edge. From that one number, you can create: a filled circle (`step(0.0, -d)`), an outlined circle (`smoothstep(0.0, 0.01, abs(d))`), a glowing circle (`1.0 / d` for cheap glow), a circle with soft edges, a moving circle, a pulsing circle. One distance function, infinite visual variations.

Rectangle SDFs, line segment SDFs, rounded rectangles, triangles — Inigo Quilez has catalogued dozens. The real power comes from **combining** them:
- **Union:** `min(d1, d2)` — merge two shapes
- **Intersection:** `max(d1, d2)` — keep only the overlap
- **Subtraction:** `max(d1, -d2)` — cut one shape from another
- **Smooth union:** `smin(d1, d2, k)` — blend shapes together like clay

These boolean operations on SDFs let you build complex 2D (and later 3D) geometry entirely in math. No meshes, no sprites, no asset pipeline. Just functions.

**Read:**
- Inigo Quilez, "2D distance functions": https://iquilezles.org/articles/distfunctions2d/ — the definitive reference for 2D SDF shapes
- The Book of Shaders, Chapter 7 (Shapes): https://thebookofshaders.com/07/
- Inigo Quilez, "Smooth minimum": https://iquilezles.org/articles/smin/ — the smooth blending operation

**Exercise:** Build a face on ShaderToy using only SDFs. A circle for the head, two smaller circles for eyes, an arc or line for the mouth. Use `smoothstep` on the SDF to get anti-aliased edges. Then animate it — make the eyes blink using `step(fract(iTime), 0.9)` to toggle eye height, or make the mouth curve change with `sin(iTime)`.

**Time:** 4-6 hours

---

## Module 3: Color, Gradients & Blending

> **Deep dive:** [Full study guide](module-03-color-gradients-blending.md)

**Goal:** Color spaces, procedural palettes (Inigo Quilez), gradient types, blending.

Color in shaders isn't just `vec3(r, g, b)`. Understanding how color works — and how to generate it procedurally — is the difference between shaders that look like programmer art and shaders that look like art.

**RGB is a terrible space for creating palettes.** You want smooth, natural-looking color transitions? Work in HSB/HSV instead, where you can sweep the hue channel while keeping brightness and saturation constant. The conversion to/from RGB is a handful of lines (The Book of Shaders provides the functions). But the real unlock is **Inigo Quilez's cosine palette formula:**

```glsl
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}
```

Four vec3 parameters generate an infinite range of smooth, beautiful color ramps. Feed it `length(uv)` for radial palettes, `uv.x` for horizontal gradients, `iTime + length(uv)` for animated psychedelic patterns. Quilez's article includes a visual palette editor where you can tune the four parameters and see the result live.

**Blending** is how you composite layers. `mix()` is linear blending, but Photoshop-style blend modes (multiply, screen, overlay, soft light) are all simple math on two color values. Multiply is `a * b`. Screen is `1.0 - (1.0 - a) * (1.0 - b)`. Overlay is a branch on luminance. Knowing these lets you layer effects the way a digital artist layers in Photoshop, but in real-time and per-pixel.

**Read:**
- The Book of Shaders, Chapter 6 (Colors): https://thebookofshaders.com/06/ — HSB, color mixing, and interactive examples
- Inigo Quilez, "Palettes": https://iquilezles.org/articles/palettes/ — the cosine palette formula with interactive editor
- "Blending Modes in GLSL" — Romain Music's reference: https://mouaif.wordpress.com/2009/01/05/photoshop-math-with-glsl-shaders/ — every Photoshop blend mode as a GLSL one-liner

**Exercise:** Create a shader that generates a full-screen animated pattern (use `sin()` waves or SDF shapes from Module 2) and colors it entirely with Quilez cosine palettes. No hardcoded colors — everything derived from the palette function. Make the palette itself animate over time. Try at least 3 different `(a, b, c, d)` parameter sets.

**Time:** 3-4 hours

---

## Module 4: Patterns, Tiling & Transformations

> **Deep dive:** [Full study guide](module-04-patterns-tiling-transformations.md)

**Goal:** `fract()` tiling, rotation matrices, polar coordinates, domain transforms.

`fract(uv * 5.0)` tiles UV space into a 5x5 grid. Each tile gets its own local coordinate from 0.0 to 1.0. Draw a circle in one tile, you get 25 circles. This is the principle behind every repeating pattern in shader art: **domain repetition.** You don't draw 25 circles — you draw one circle in repeated space.

`floor(uv * 5.0)` gives you the **tile index** — which copy you're in. Combine `fract` and `floor` to make each tile slightly different: offset the shape, vary the color, alternate every other row. Checkerboards, brick patterns, hex grids — all built from `fract` and `floor`.

**Rotation** in 2D is a 2x2 matrix multiply: `mat2(cos(a), -sin(a), sin(a), cos(a)) * uv`. Apply it before tiling and the whole grid rotates. Apply it inside the tile and each cell rotates independently. Apply `iTime` as the angle and everything spins.

**Polar coordinates** (`atan(uv.y, uv.x)` for angle, `length(uv)` for radius) unlock radial patterns: spirals, starbursts, kaleidoscopes, clock faces. Tile in polar space with `fract(angle / TAU * N)` for N-fold symmetry.

**Domain warping** is the advanced move: distort the UV coordinates *before* evaluating your pattern. Feed noise into UV (Module 5 does this deeply), or offset tiles by `sin(row_index)` for a staggered brick layout. The pattern doesn't change — the space it lives in changes.

**Read:**
- The Book of Shaders, Chapter 9 (Patterns): https://thebookofshaders.com/09/ — fract tiling with interactive examples
- The Book of Shaders, Chapter 8 (2D Matrices): https://thebookofshaders.com/08/ — rotation, scaling, translation in shader space
- Inigo Quilez, "Useful Little Functions": https://iquilezles.org/articles/functions/ — a toolkit of shaping functions for modifying patterns

**Exercise:** Build an animated tile pattern on ShaderToy. Start with a basic `fract` grid of circles. Then: (1) alternate every other row using `floor`, (2) rotate each tile based on its index and time, (3) convert to polar coordinates and create a kaleidoscope with 6-fold symmetry, (4) apply a color palette from Module 3. The result should be a single shader that creates a complex, animated, colorful pattern from simple building blocks.

**Time:** 4-6 hours

---

## Module 5: Noise — Perlin, Simplex, Cellular, FBM

> **Deep dive:** [Full study guide](module-05-noise.md)

**Goal:** Procedural noise types, fractal layering, domain warping.

Noise is the organic brush of shader programming. Without it, everything looks geometric and synthetic. With it, you get terrain, clouds, fire, water, marble, wood grain, alien landscapes — anything that needs to look natural without being authored.

**Value noise** is the simplest: random values at grid points, smoothly interpolated between them. **Perlin noise** (technically gradient noise) is the classic — random gradients at grid points produce smoother, less grid-aligned results. **Simplex noise** is Perlin's successor, faster and less prone to directional artifacts. **Cellular noise** (Voronoi/Worley) computes the distance to the nearest random feature point, producing cell-like organic patterns — think reptile skin, cracked earth, or stained glass.

The real power comes from **fractal Brownian Motion (fBM):** layer multiple octaves of noise at increasing frequency and decreasing amplitude. One octave of Perlin noise looks like rolling hills. Six octaves of fBM look like a mountain range. The formula is simple — a loop that accumulates `noise(p * frequency) * amplitude` while doubling frequency and halving amplitude each iteration. The parameters (octaves, lacunarity, gain) control the character of the result.

**Domain warping** takes fBM further: use one noise function to distort the input coordinates of *another* noise function. `fbm(p + fbm(p + fbm(p)))` creates swirling, organic patterns that look like fluid dynamics or alien growths. Inigo Quilez's article on domain warping is essential reading — it opened up an entire genre of shader art.

**Read:**
- The Book of Shaders, Chapters 11-12 (Noise, Cellular Noise): https://thebookofshaders.com/11/ — interactive noise implementations
- Inigo Quilez, "Value Noise Derivatives": https://iquilezles.org/articles/morenoise/ — understanding noise analytically
- Inigo Quilez, "Domain Warping": https://iquilezles.org/articles/warp/ — the domain warping technique with stunning examples
- Stefan Gustavson, "Simplex Noise Demystified" (PDF): https://weber.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf — the definitive explanation of simplex noise

**Exercise:** Build a series of shaders (or one with toggle states): (1) basic value noise, (2) Perlin noise, (3) cellular/Voronoi noise, (4) fBM with 6 octaves over Perlin noise, (5) domain-warped fBM (`fbm(p + fbm(p))`). Animate each with `iTime` as an offset. Color the domain-warped version with a cosine palette from Module 3. You should end up with something that looks like liquid fire or alien marble.

**Time:** 5-8 hours

---

## Module 6: Textures & Image Processing

> **Deep dive:** [Full study guide](module-06-textures-image-processing.md)

**Goal:** Sampling, wrapping, convolution kernels, UV distortion, chromatic aberration.

So far, everything has been procedural — generated from math alone. Textures are where the outside world enters. `texture(iChannel0, uv)` samples an image at a UV coordinate and returns its color. ShaderToy lets you bind images, videos, audio, and even other shader passes to channels. This is where shaders start looking like image processing, not just pattern generation.

**Wrapping modes** control what happens at texture edges. Repeat tiles the image. Clamp sticks to the edge pixel. Mirror reflects. These are set on the texture, not in your code, but understanding them matters when you design UV transforms.

**Convolution kernels** are the foundation of image processing. A kernel is a small grid of weights. For each pixel, you sample its neighbors, multiply by the weights, and sum. A blur kernel averages neighbors. An edge-detection kernel (Sobel) subtracts neighbors to find sharp changes. A sharpen kernel amplifies the center and subtracts neighbors. All of Photoshop's filters are convolution kernels.

**UV distortion** means modifying the UV coordinates before sampling: `texture(tex, uv + noise(uv))` warps the image with noise. `texture(tex, uv + vec2(sin(uv.y * 10.0 + iTime) * 0.02, 0.0))` creates a wavy water refraction. **Chromatic aberration** samples each RGB channel at slightly different UV offsets, creating the color-fringing effect of cheap lenses — a staple of stylized games and retro aesthetics.

This module is also the bridge to post-processing (Module 9). Once you can sample a texture and transform it, you can apply any of these effects to a full rendered scene, not just a static image.

**Read:**
- The Book of Shaders, Chapter 10 (Generative Designs): https://thebookofshaders.com/10/ — using randomness and generative approaches with textures
- LearnOpenGL, "Textures": https://learnopengl.com/Getting-started/Textures — the clearest explanation of texture sampling, filtering, and wrapping
- LearnOpenGL, "Framebuffers": https://learnopengl.com/Advanced-OpenGL/Framebuffers — render-to-texture concept, critical for post-processing

**Exercise:** In ShaderToy, bind an image to iChannel0. Then build each effect in sequence: (1) sample and display the image normally, (2) add UV distortion with `sin()` to create a wavy underwater look, (3) implement a 3x3 Gaussian blur kernel, (4) implement Sobel edge detection and overlay the edges on the original image, (5) add chromatic aberration by offsetting R, G, B channel UVs. Combine them into a final composite that looks like a retro VHS tape.

**Time:** 4-6 hours

---

## Module 7: 2D Lighting & Shadows

> **Deep dive:** [Full study guide](module-07-2d-lighting-shadows.md)

**Goal:** Point lights, diffuse/specular, normal maps, shadow approximation.

**Prerequisites:** Modules 2 (SDFs) and 5 (Noise)

Lighting in 2D shaders is a cheat — and a beautiful one. Real-time 2D games don't have actual geometry to cast shadows on, so you fake it. But the "faking" produces results that look stunning and run incredibly fast because the entire lighting computation is a handful of dot products per pixel.

**Point lights** are the simplest: compute the direction and distance from the pixel to the light source. Attenuation (falloff) is usually `1.0 / (distance * distance)` or a smoother custom curve. Multiply the attenuation by the light color and you have a glowing point light. Add multiple lights by summing their contributions. In a dark scene with two or three colored point lights, this alone looks atmospheric.

**Diffuse lighting** uses the dot product between the surface normal and the light direction. In 2D, if your surface is "flat," the normal is `vec3(0, 0, 1)` everywhere and diffuse is uniform. The trick is **normal maps**: textures where RGB encodes the surface normal direction. A flat cobblestone texture paired with its normal map suddenly has the appearance of depth as lights move across it. Normal maps turn flat 2D art into something that reacts to light.

**Specular highlights** simulate shininess. Compute the reflection of the light direction around the normal, then dot it with the view direction and raise to a power (the Phong model). Higher power = tighter, shinier highlight. Even in 2D, a specular highlight on a button or gem makes it feel tangible.

**Shadow approximation** in 2D SDF scenes is elegant: march from the pixel toward the light in small steps, checking the SDF at each step. If the SDF goes negative (you're inside a shape), the point is in shadow. This is called ray marching for shadows and it's a simplified version of what Module 10 covers in full 3D.

**Read:**
- LearnOpenGL, "Basic Lighting": https://learnopengl.com/Lighting/Basic-Lighting — Phong model explained clearly, applicable to 2D with flat normals
- LearnOpenGL, "Lighting Maps": https://learnopengl.com/Lighting/Lighting-maps — normal maps, diffuse maps, specular maps
- Ronja's Tutorials, "2D SDF Shadows": https://www.ronja-tutorials.com/post/037-2d-sdf-shadows/ — 2D shadow technique using SDFs

**Exercise:** Build a 2D scene with 3-4 SDF shapes (Module 2) on a dark background. Add two colored point lights that follow the mouse and a time-based orbit. Implement diffuse shading using a procedural normal (derive normals from SDF gradient: sample the SDF at small offsets in x and y, the gradient approximates the normal). Add a specular highlight on at least one shape. Bonus: implement soft shadows by marching from each pixel toward the light.

**Time:** 5-7 hours

---

## Module 8: The Vertex Shader

> **Deep dive:** [Full study guide](module-08-vertex-shader.md)

**Goal:** MVP matrices, vertex displacement, wind/wave animation, varyings.

**Prerequisites:** Module 1 (Coordinates & Math)

You've been living in the fragment shader — the per-pixel stage. Now you step backward in the pipeline to the **vertex shader**, which runs once per vertex and controls *where* geometry appears on screen. This is where 3D transforms happen, where meshes deform, and where effects like wind-blown grass and ocean waves live.

The vertex shader's core job is transforming vertex positions from **model space** (local coordinates) through **world space** (scene coordinates) and **view space** (camera-relative) to **clip space** (what the GPU rasterizes). This chain of matrix multiplications — model, view, projection (MVP) — is the foundation of all 3D rendering. Even if you only care about 2D, understanding MVP helps you reason about coordinate spaces in any engine.

**Vertex displacement** is the creative application: modify the vertex position *before* the MVP transform. Add `sin(position.x * 10.0 + time) * 0.1` to the Y component and a flat plane becomes ocean waves. Multiply displacement by a vertex color or attribute and only certain parts of the mesh move — grass tips sway while roots stay planted.

**Varyings** are how the vertex shader communicates with the fragment shader. Any value you output from the vertex shader gets *interpolated* across the triangle during rasterization and arrives at the fragment shader as a smooth gradient. This is how UV coordinates, normals, and world positions travel from vertices to pixels. Understanding varyings is essential for effects that need both vertex-level and pixel-level logic.

Note: ShaderToy doesn't expose a vertex shader (it renders a single full-screen quad). For this module, use a local GLSL setup, an engine, or a tool like **glslCanvas** / **glsl-sandbox** / **Shadertoy-like** environments that support custom geometry. Alternatively, use the vertex shader editors on https://vertexshaderart.com for pure vertex experimentation.

**Read:**
- LearnOpenGL, "Coordinate Systems": https://learnopengl.com/Getting-started/Coordinate-Systems — the MVP pipeline explained with diagrams
- LearnOpenGL, "Shaders": https://learnopengl.com/Getting-started/Shaders — vertex/fragment shader communication and varyings
- Ronja's Tutorials, "Vertex Displacement": https://www.ronja-tutorials.com/post/015-wobble-displacement/ — practical displacement techniques

**Exercise:** In any environment that supports vertex shaders (even a minimal Three.js/R3F setup or Godot), create a subdivided plane and write a vertex shader that displaces it into ocean waves: `y = amplitude * sin(x * frequency + time) + amplitude2 * cos(z * frequency2 + time * 0.7)`. Pass the displacement amount as a varying to the fragment shader and use it to color the surface — deeper troughs are darker blue, wave crests are white foam. Add a second wave layer with different frequency for realistic interference.

**Time:** 4-6 hours

---

## Module 9: Post-Processing Effects

> **Deep dive:** [Full study guide](module-09-post-processing.md)

**Goal:** Render-to-texture, bloom, blur, CRT/retro, film grain, color grading.

**Prerequisites:** Module 6 (Textures & Image Processing)

Post-processing is applying shader effects to the *entire rendered frame* as a final pass. The scene renders to an off-screen texture (framebuffer), then a full-screen quad displays that texture through a fragment shader that transforms it. Bloom, blur, color grading, CRT scanlines, vignette, film grain — all post-processing.

**Bloom** is the glow around bright objects. The algorithm: (1) extract bright pixels from the scene (threshold), (2) blur them heavily (Gaussian blur, usually multi-pass for performance), (3) add the blurred result back onto the original scene. That's it. Bloom is just "blur the bright parts and layer them on top." The quality comes from the blur — a separable two-pass Gaussian (horizontal then vertical) is standard.

**Gaussian blur** itself deserves understanding. A single-pass 2D blur with a large kernel is expensive. A separable blur does the same work in two passes — blur horizontally, then blur that result vertically. A 15x15 kernel that would need 225 samples per pixel becomes two passes of 15 samples each (30 total). This optimization is why multi-pass rendering matters.

**CRT/retro effects** are a stack of small techniques: scanlines (darken every other row with `mod(fragCoord.y, 2.0)`), chromatic aberration (Module 6), vignette (darken edges using `length(uv - 0.5)`), barrel distortion (warp UVs outward from center), and phosphor dot simulation. Layered together, they convincingly fake a CRT monitor.

**Film grain** is noise (Module 5) added to the final image, animated per frame. Use a hash function of `fragCoord + iTime` for per-pixel per-frame noise, blend it subtly with `mix()`.

**Color grading** transforms the final image's colors: adjust contrast (remap with `smoothstep`), shift color temperature (tint shadows blue, highlights warm), desaturate (dot product with luminance weights). Professional color grading uses LUTs (look-up textures), but shader math gets you 80% of the way there.

**Read:**
- LearnOpenGL, "Bloom": https://learnopengl.com/Advanced-Lighting/Bloom — complete bloom implementation walkthrough
- LearnOpenGL, "Framebuffers": https://learnopengl.com/Advanced-OpenGL/Framebuffers — render-to-texture fundamentals
- Ronja's Tutorials, "Postprocessing with Normals and Depth": https://www.ronja-tutorials.com/post/018-postprocessing-normal/ — using scene data in post-processing

**Exercise:** In ShaderToy, use a multi-pass setup (Buffer A renders a scene, Image reads from Buffer A). In Buffer A, create an animated SDF scene with bright glowing elements. In the Image pass, implement: (1) bloom by extracting bright pixels and blurring, (2) vignette, (3) chromatic aberration, (4) film grain, (5) CRT scanlines. Make each effect toggleable by commenting/uncommenting. The goal is a complete retro-styled post-processing pipeline.

**Time:** 5-8 hours

---

## Module 10: Raymarching & 3D SDF Scenes

> **Deep dive:** [Full study guide](module-10-raymarching-3d-sdf.md)

**Goal:** Build 3D scenes in a single fragment shader with lighting and shadows.

**Prerequisites:** Module 2 (SDFs). Benefits from Module 5 (Noise) and Module 7 (2D Lighting).

This is the mountain peak of fragment shader programming. Raymarching lets you render fully lit 3D scenes — spheres, boxes, organic shapes, entire landscapes — in a single fragment shader with zero geometry. No meshes, no vertices, no engine. Just math.

The idea is deceptively simple: for each pixel, cast a ray from the camera into the scene. March along the ray in steps, evaluating a 3D SDF at each point. The SDF tells you the distance to the nearest surface. If the distance is very small, you've hit something — shade it. If it's large, take a step of that size (the "sphere tracing" optimization: you can safely step by the SDF value because nothing is closer than that). If you've marched too far without hitting anything, the pixel is background.

**3D SDFs** are natural extensions of 2D ones. A sphere is `length(p) - radius`. A box uses `max(abs(p) - size)`. Inigo Quilez's 3D SDF catalogue provides dozens of primitives. The same boolean operations from Module 2 work here — `min` for union, `max` for intersection, `smin` for smooth blending. You can build organic, impossible shapes that would be nightmarish to model as meshes.

**Lighting** reuses Module 7 concepts in 3D. The surface normal at a hit point is the gradient of the SDF (sample at small offsets in x, y, z). With a normal and a light direction, you compute diffuse and specular exactly as before. **Soft shadows** come from marching a secondary ray toward the light and tracking how close it passes to other surfaces — if the closest approach was small but nonzero, the point is in penumbra.

This is the technique behind most top-rated ShaderToy creations. It's computationally intensive but produces results that look like they require an entire rendering engine.

**Read:**
- Inigo Quilez, "3D distance functions": https://iquilezles.org/articles/distfunctions/ — the 3D SDF bible
- Inigo Quilez, "Raymarching Primitives": https://iquilezles.org/articles/raymarchingdf/ — sphere tracing algorithm explained
- Inigo Quilez, "Soft Shadows in Raymarched Scenes": https://iquilezles.org/articles/rmshadows/ — penumbra technique
- Jamie Wong, "Ray Marching and Signed Distance Functions": https://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/ — excellent illustrated walkthrough

**Exercise:** Build a raymarched scene on ShaderToy with: (1) a ground plane and at least 3 SDF primitives (sphere, box, torus), (2) smooth-blended union between at least two shapes, (3) a single directional light with diffuse and specular shading, (4) surface normals computed from the SDF gradient, (5) hard shadows via secondary ray march. Bonus: add soft shadows, ambient occlusion (march the normal direction and check SDF falloff), or fog (blend with distance).

**Time:** 6-10 hours

---

## Module 11: Animation, Motion & Interactive Shaders

> **Deep dive:** [Full study guide](module-11-animation-motion-interactive.md)

**Goal:** Time-based animation, easing, audio reactivity, buffer feedback.

**Prerequisites:** Module 4 (Patterns & Transformations)

Static shaders are impressive. Animated shaders are mesmerizing. This module is about making things *move* with intention — not just slapping `iTime` into random `sin()` calls and hoping for the best, but understanding how to choreograph shader animation with the same rigor a motion designer brings to After Effects.

**Easing functions** are the backbone of polished animation. Linear motion (`t`) looks robotic. Ease-in (`t * t`) accelerates naturally. Ease-out (`1.0 - (1.0 - t) * (1.0 - t)`) decelerates. Ease-in-out combines both. Bounce, elastic, back — all are simple math functions that transform a linear 0-to-1 progress value into a curved one. Apply them to any animated parameter: position, scale, color, opacity. The difference between amateur and professional motion is almost always easing.

**Sequencing** means triggering different animations at different times. `fract(iTime / duration)` gives you a looping 0-to-1 progress value. `floor(iTime / duration)` gives you the current "beat" number. Combine with `step()` or `smoothstep()` to sequence events: shape A appears from 0-1s, morphs to shape B from 1-2s, explodes into particles from 2-3s, loops.

**Audio reactivity** in ShaderToy uses `iChannel0` bound to audio or a microphone. The audio data comes as a texture where the x-axis is frequency and the y-axis is waveform. Sample the bass frequencies to drive scale, mids for color, highs for distortion. Audio-reactive shaders are a gateway to VJ-style live visuals.

**Buffer feedback** uses multi-pass rendering where a buffer reads its *own previous frame*. Buffer A renders to a texture, and on the next frame, Buffer A samples that texture as input. This creates feedback loops: trails, motion blur, reaction-diffusion patterns, cellular automata. Conway's Game of Life is a single-pass buffer feedback shader.

**Read:**
- Easings.net: https://easings.net — visual reference for every standard easing curve, with math formulas
- The Book of Shaders, Chapter 10 (Generative Designs): https://thebookofshaders.com/10/ — randomness and motion principles
- Inigo Quilez, "Painting with Math": https://iquilezles.org/articles/palettes/ — using time-driven palettes for animation

**Exercise:** Create a ShaderToy multi-pass shader: Buffer A implements a simple particle system or cellular automaton using buffer feedback (sample previous frame, apply rules, write new state). The Image pass reads Buffer A and renders it with full visual treatment — cosine palettes, bloom glow, animated background. Add audio reactivity if you have a mic: bind audio to iChannel1 and let bass frequencies pulse the scale or brightness.

**Time:** 5-7 hours

---

## Module 12: Porting to Engines

> **Deep dive:** [Full study guide](module-12-porting-to-engines.md)

**Goal:** Translate GLSL to Godot shading language, Love2D shaders, R3F ShaderMaterial.

**Prerequisites:** Any modules — port whatever you've built so far.

ShaderToy is a playground. Engines are where shaders ship. The good news: everything you've learned is transferable. The concepts — UV coordinates, SDFs, noise, lighting models, post-processing — are universal. The syntax changes, the uniform names change, and each engine has its own opinions about the pipeline. But a `smoothstep` is a `smoothstep` everywhere.

**Godot** uses its own shading language (similar to GLSL, but simplified). Fragment shaders write to `ALBEDO`, `EMISSION`, `ROUGHNESS` instead of a raw `fragColor`. Uniforms are declared with `uniform` keyword and editable in the inspector. Godot provides built-in access to `TIME`, `UV`, `SCREEN_UV`, `SCREEN_TEXTURE`, and light callback functions. Canvas item shaders (2D) and spatial shaders (3D) have different built-ins but the same core language. See the [Godot Shaders & Stylized Rendering module](../../engines/godot/module-06-shaders-stylized-rendering.md) for engine-specific deep dives.

**Love2D** uses GLSL directly via `love.graphics.newShader()`. You write a GLSL fragment shader as a string, and Love2D provides `extern` uniforms for time, textures, and custom values. The main differences from ShaderToy: the entry point is `vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)`, the texture is passed as an argument rather than a channel, and you send uniforms with `shader:send()`. See the [Love2D Learning Roadmap](../../engines/love2d/love2d-learning-roadmap.md) for the full framework context.

**React Three Fiber (R3F)** uses `ShaderMaterial` with raw GLSL vertex/fragment strings, or `shaderMaterial` from drei for a declarative API. Uniforms are passed as props and update reactively. Three.js provides `#include` chunks for common functions (lighting, normal maps, fog). TSL (Three Shading Language) is the newer path — write shader logic in TypeScript with `Fn`, `uv()`, `time`, `mix`, `sin` etc., compiled to GLSL/WGSL behind the scenes. See the [R3F Shaders & Stylized Rendering module](../../engines/r3f/module-06-shaders-stylized-rendering.md) for the full R3F shader workflow.

**Porting checklist — ShaderToy to any engine:**
1. Replace `iResolution`, `iTime`, `iMouse` with engine equivalents
2. Replace `fragCoord / iResolution.xy` with the engine's built-in UV
3. Replace `texture(iChannelN, uv)` with the engine's texture sampling
4. Replace `fragColor = vec4(...)` with the engine's output variable
5. Move noise functions and utility code into includes/libraries (engines don't have them built in)
6. Adapt multi-pass shaders to the engine's render-to-texture system

**Read:**
- Godot Shader Language reference: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html
- Love2D Shader documentation: https://love2d.org/wiki/love.graphics.newShader
- Three.js ShaderMaterial docs: https://threejs.org/docs/#api/en/materials/ShaderMaterial
- "From ShaderToy to Three.js" by Maxime Heckel: https://blog.maximeheckel.com/posts/the-study-of-shaders-with-react-three-fiber/

**Exercise:** Pick your favorite shader from Modules 2-6. Port it to at least two of the three engines above. Document every change you had to make in a comment block at the top of each ported shader. The exercise isn't the visual result (you already have that) — it's building the translation muscle memory so that future shaders flow naturally into your engine of choice.

**Time:** 4-6 hours per engine

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| The Book of Shaders | https://thebookofshaders.com | The starting point. Interactive, text-first, beautifully designed. Chapters 1-12 cover Modules 0-5 of this roadmap. |
| ShaderToy | https://www.shadertoy.com | Your playground. Browse top-rated shaders, fork them, break them, learn from them. |
| Inigo Quilez Articles | https://iquilezles.org/articles/ | The GLSL reference library. SDFs, noise, palettes, raymarching — IQ wrote the definitive article on all of it. |
| LearnOpenGL | https://learnopengl.com | Best explanation of the GPU pipeline, textures, lighting, and framebuffers. Ignore the C++ setup code, read the concepts. |
| Ronja's Tutorials | https://www.ronja-tutorials.com | Shader tutorials written as text with diagrams. Unity-flavored but the HLSL translates directly to GLSL. |
| docs.gl | https://docs.gl | GLSL function reference. Bookmark `docs.gl/sl4/` for the function index. |
| Shadertoy Unofficial Wiki | https://shadertoyunofficial.wordpress.com | Tips, tricks, and explanations for ShaderToy-specific features and multi-pass setups. |
| Easings.net | https://easings.net | Visual easing function reference with formulas. |
| GPU Gems (NVIDIA) | https://developer.nvidia.com/gpugems/gpugems/contributors | Free online. Dense but authoritative chapters on noise, lighting, post-processing. |

---

## ADHD-Friendly Tips

- **ShaderToy is instant dopamine.** Change a number, see the result. There's no compile step, no build system, no waiting. If motivation is low, just open ShaderToy and type `sin(iTime)` into something. You'll end up tinkering for 30 minutes.
- **Fork, don't start from scratch.** Browse top ShaderToy creations, fork one, and start changing numbers. See what each line does by breaking it. Reverse-engineering a working shader teaches faster than building from nothing.
- **One function per session.** Don't try to learn `smoothstep`, `fract`, noise, and SDFs in one sitting. Pick one function. Understand it visually. Use it in three different ways. Stop. Come back tomorrow for the next one.
- **Make it weird.** Shader programming rewards experimentation. Multiply where you should add. Use `sin` where you should use `step`. Feed UV coordinates into color channels. The "mistakes" are often more interesting than the plan. Follow the happy accidents.
- **Screenshot your progress.** Shader work is inherently visual. Save screenshots of things that look cool, even if they're unfinished or accidental. Build a gallery. On low-motivation days, scroll through it to remember that you made those.
- **Pair with music.** Shader coding is deeply meditative once you're in flow. Put on an album, set a timer for the album length, and tinker. When the music stops, you stop. No guilt.
- **The Book of Shaders is your anchor.** If you're overwhelmed by ShaderToy's complexity, go back to The Book of Shaders. It's paced for humans. Each chapter is a single concept with interactive editors right on the page.
