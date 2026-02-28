# Module 8: The Vertex Shader

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** Module 1 (Coordinates, Uniforms & Math Toolbox)

---

## Overview

Until now, you have lived entirely in the fragment shader — the per-pixel stage of the rendering pipeline. The vertex shader is the stage *before* that: a per-vertex program that determines where geometry ends up on screen. If the fragment shader is the painter who decides the color of each pixel, the vertex shader is the architect who positions the walls and floors.

Understanding vertex shaders is essential if you want to:
- **Animate geometry** — ocean waves, wind-blown grass, flag ripples, mesh deformation
- **Implement 3D rendering** — the Model-View-Projection (MVP) matrix chain that transforms 3D coordinates into screen coordinates
- **Create visual effects** — vertex displacement for terrain, particle systems, screen-space distortion
- **Work in game engines** — every engine shader has both a vertex and fragment stage

ShaderToy abstracts the vertex shader away (it renders a single full-screen quad), so this module steps outside ShaderToy into environments where you control both stages. The concepts you learn here apply universally across OpenGL, WebGL, Godot, Unity, Unreal, and any other GPU-based renderer.

---

## 1. What the Vertex Shader Does

The vertex shader runs **once per vertex** (not per pixel). Each invocation receives one vertex's data — position, color, texture coordinate, normal — and must output at least one thing: the vertex's final position in **clip space**.

```
Input:                          Vertex Shader:           Output:
┌──────────────┐               ┌──────────────┐        ┌──────────────┐
│ Position     │──────────────▶│              │──────▶│ gl_Position  │
│ (model space)│               │  Transform   │        │ (clip space) │
│              │               │  Animate     │        │              │
│ Normal       │──────────────▶│  Pass data   │──────▶│ Varyings     │
│ UV coords   │──────────────▶│  to fragment │──────▶│ (interpolated│
│ Color        │──────────────▶│              │──────▶│  per pixel)  │
└──────────────┘               └──────────────┘        └──────────────┘
```

### The Minimum Vertex Shader

```glsl
#version 330 core

layout(location = 0) in vec3 aPosition;  // Vertex position (from mesh data)
layout(location = 1) in vec2 aTexCoord;  // Texture coordinate

out vec2 vTexCoord;  // Passed to fragment shader

uniform mat4 uMVP;  // Model-View-Projection matrix

void main() {
    gl_Position = uMVP * vec4(aPosition, 1.0);
    vTexCoord = aTexCoord;
}
```

### Key Concepts

- **`in` attributes** — Per-vertex data from the mesh buffer. Position, normal, UV, color.
- **`uniform`** — Values constant across all vertices (set by the CPU). Matrices, time, light positions.
- **`out` varyings** — Values sent to the fragment shader. They are **interpolated** across the triangle during rasterization.
- **`gl_Position`** — The mandatory output. A `vec4` in clip space that tells the GPU where to draw this vertex on screen.

---

## 2. Coordinate Spaces and the MVP Transform

Understanding the MVP (Model-View-Projection) matrix chain is the core of 3D vertex shaders. It transforms a vertex through four coordinate spaces:

### The Spaces

```
Model Space          World Space          View Space           Clip Space
(local to object)    (scene coordinates)  (camera-relative)    (GPU coordinates)

    ▲ y                  ▲ y                  ▲ y                Frustum
    │                    │                    │                  ╱╲
    │  ╭─╮              │     ╭─╮           │  ╭─╮            ╱  ╲
    └──╰─╯── x          └─────╰─╯── x       └──╰─╯── x      ╱    ╲
   Object centered      Placed in scene      Camera at origin ╲    ╱
   at its own origin    at some position     looking down -z   ╲  ╱
                                                                ╲╱

    ──── Model ────▶  ──── View ────▶  ──── Projection ────▶
       Matrix            Matrix              Matrix
```

**Model space:** The object's local coordinates. A cube centered at origin, a character standing at (0,0,0). This is how 3D artists build their meshes.

**World space:** Where the object sits in the scene. The Model matrix positions, rotates, and scales the object from its local space into the shared world.

**View space (camera space):** The world transformed so the camera is at the origin, looking down the negative Z axis. The View matrix is the inverse of the camera's world transform.

**Clip space:** The final space where the GPU clips and rasterizes. The Projection matrix applies perspective (far things smaller) or orthographic (no perspective) projection.

### The MVP Chain

```glsl
gl_Position = Projection * View * Model * vec4(position, 1.0);
// Or combined into a single matrix:
gl_Position = MVP * vec4(position, 1.0);
```

Matrices multiply right-to-left. The vertex position is first transformed by Model (local → world), then View (world → camera), then Projection (camera → clip).

### Why It Matters

In most game engines, you do not construct these matrices in the shader — the engine provides them as uniforms. But understanding what they do is essential for:
- Debugging visual issues ("why is my object upside down?" — a matrix sign error)
- Vertex displacement in world space vs. local space
- Custom projection effects (screen shake, split-screen, portals)

---

## 3. Building Matrices

### Translation

```glsl
mat4 translate(vec3 offset) {
    return mat4(
        1.0, 0.0, 0.0, 0.0,   // Column 0
        0.0, 1.0, 0.0, 0.0,   // Column 1
        0.0, 0.0, 1.0, 0.0,   // Column 2
        offset.x, offset.y, offset.z, 1.0  // Column 3
    );
}
```

### Rotation (around Y axis)

```glsl
mat4 rotateY(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat4(
        c,   0.0, s,   0.0,
        0.0, 1.0, 0.0, 0.0,
        -s,  0.0, c,   0.0,
        0.0, 0.0, 0.0, 1.0
    );
}
```

### Scale

```glsl
mat4 scale(vec3 s) {
    return mat4(
        s.x, 0.0, 0.0, 0.0,
        0.0, s.y, 0.0, 0.0,
        0.0, 0.0, s.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}
```

### Perspective Projection

```glsl
mat4 perspective(float fov, float aspect, float near, float far) {
    float f = 1.0 / tan(fov * 0.5);
    return mat4(
        f / aspect, 0.0, 0.0,                          0.0,
        0.0,        f,   0.0,                          0.0,
        0.0,        0.0, (far + near) / (near - far), -1.0,
        0.0,        0.0, 2.0*far*near / (near - far),  0.0
    );
}
```

**Note:** GLSL uses **column-major** matrix layout, which means the data is stored column by column. The `mat4(c0, c1, c2, c3)` constructor takes four column vectors. This trips up programmers coming from row-major languages.

---

## 4. Varyings: Vertex-to-Fragment Communication

Values output from the vertex shader are automatically **interpolated** across the triangle during rasterization. The fragment shader receives the smoothly blended value.

```glsl
// Vertex shader
out vec3 vColor;
out vec2 vUV;
out vec3 vWorldPosition;

void main() {
    vColor = aColor;
    vUV = aTexCoord;
    vWorldPosition = (uModel * vec4(aPosition, 1.0)).xyz;
    gl_Position = uMVP * vec4(aPosition, 1.0);
}

// Fragment shader
in vec3 vColor;
in vec2 vUV;
in vec3 vWorldPosition;

void main() {
    // vColor, vUV, vWorldPosition are smoothly interpolated
    // across the triangle from the three vertex values
    fragColor = vec4(vColor, 1.0);
}
```

### What Gets Interpolated

```
Vertex A: vColor = RED     Vertex B: vColor = GREEN
    ●───────────────────────────●
    │  interpolated gradient:   │
    │  RED → YELLOW → GREEN     │
    ●───────────────────────────●
Vertex C: vColor = RED     Vertex D: vColor = GREEN
```

The interpolation is **barycentric** — based on the pixel's position relative to the triangle's vertices. This is how smooth gradients, UV coordinates, and normals are transmitted from a handful of vertices to millions of pixels.

### Common Varyings

| Varying | Purpose |
|---|---|
| `vec2 vUV` | Texture coordinates for sampling |
| `vec3 vNormal` | Surface normal for lighting |
| `vec3 vWorldPos` | World position for lighting/fog |
| `vec3 vColor` | Per-vertex color |
| `float vDisplacement` | How much the vertex was moved (for coloring) |

---

## 5. Vertex Displacement

Vertex displacement is the creative heart of vertex shaders. You modify the vertex position before passing it to `gl_Position`, creating animated geometry.

### Ocean Waves

```glsl
uniform float uTime;

void main() {
    vec3 pos = aPosition;

    // Sum of two sine waves at different angles
    float wave1 = sin(pos.x * 4.0 + uTime * 2.0) * 0.08;
    float wave2 = sin(pos.z * 3.0 + uTime * 1.5) * 0.06;
    float wave3 = sin((pos.x + pos.z) * 2.5 + uTime * 1.8) * 0.04;

    pos.y += wave1 + wave2 + wave3;

    // Pass displacement to fragment for coloring
    vDisplacement = wave1 + wave2 + wave3;
    vUV = aTexCoord;

    gl_Position = uMVP * vec4(pos, 1.0);
}
```

The fragment shader can use `vDisplacement` to color wave crests white (foam) and troughs dark blue:

```glsl
// Fragment shader
in float vDisplacement;

void main() {
    // Map displacement to ocean colors
    vec3 deep = vec3(0.0, 0.1, 0.3);
    vec3 shallow = vec3(0.1, 0.4, 0.6);
    vec3 foam = vec3(0.8, 0.9, 1.0);

    float t = vDisplacement * 5.0 + 0.5;  // Remap
    vec3 color = mix(deep, shallow, clamp(t, 0.0, 1.0));
    color = mix(color, foam, smoothstep(0.7, 1.0, t));

    fragColor = vec4(color, 1.0);
}
```

### Wind-Blown Grass

Grass sways at the tips but stays planted at the roots. Use the vertex's Y coordinate (height) as a mask:

```glsl
void main() {
    vec3 pos = aPosition;

    // Only move upper vertices (tips of grass blades)
    float swayMask = smoothstep(0.0, 1.0, aPosition.y);  // 0 at base, 1 at tip

    // Wind sway
    float sway = sin(aPosition.x * 3.0 + uTime * 2.0) * 0.15;
    sway += sin(aPosition.x * 7.0 + uTime * 3.5) * 0.05;  // Higher frequency detail

    pos.x += sway * swayMask;

    gl_Position = uMVP * vec4(pos, 1.0);
}
```

### Explosion / Expand Along Normal

Push vertices outward along their normals for an inflation or explosion effect:

```glsl
void main() {
    vec3 pos = aPosition;

    float expand = sin(uTime) * 0.5 + 0.5;  // 0 to 1 over time
    pos += aNormal * expand * 0.3;

    vNormal = aNormal;
    gl_Position = uMVP * vec4(pos, 1.0);
}
```

### Terrain from Height Map

Displace a flat grid of vertices using a texture as a height map:

```glsl
uniform sampler2D uHeightMap;

void main() {
    vec3 pos = aPosition;

    // Sample the height map at this vertex's UV
    float height = texture(uHeightMap, aTexCoord).r;

    // Displace vertically
    pos.y += height * 2.0;  // Scale the height

    vUV = aTexCoord;
    vHeight = height;
    gl_Position = uMVP * vec4(pos, 1.0);
}
```

---

## 6. Recalculating Normals After Displacement

When you displace vertices, the original normals are wrong — the surface has changed shape. You need updated normals for correct lighting.

### Finite Difference Approach

Sample the displacement at neighboring positions and compute the cross product:

```glsl
// For a height-map displaced plane:
float eps = 0.01;
float hL = getHeight(aTexCoord + vec2(-eps, 0.0));
float hR = getHeight(aTexCoord + vec2( eps, 0.0));
float hD = getHeight(aTexCoord + vec2(0.0, -eps));
float hU = getHeight(aTexCoord + vec2(0.0,  eps));

vec3 normal = normalize(vec3(hL - hR, 2.0 * eps, hD - hU));
```

### Analytical Derivatives

For sine-wave displacement, you can compute the exact derivative:

```glsl
// Displacement: y = A * sin(x * freq + time)
// Derivative:   dy/dx = A * freq * cos(x * freq + time)

float dy_dx = 0.08 * 4.0 * cos(pos.x * 4.0 + uTime * 2.0);
float dy_dz = 0.06 * 3.0 * cos(pos.z * 3.0 + uTime * 1.5);

vec3 normal = normalize(vec3(-dy_dx, 1.0, -dy_dz));
```

Analytical normals are more accurate and cheaper than finite differences, but only work when you have the displacement formula.

---

## 7. Vertex Shader in Different Environments

ShaderToy does not expose the vertex shader. Here is how to access it in other environments:

### Raw WebGL / OpenGL

Both vertex and fragment shaders are separate GLSL source strings compiled and linked into a shader program:

```glsl
// Vertex shader (separate file or string)
#version 300 es
in vec3 aPosition;
in vec2 aTexCoord;
out vec2 vUV;
uniform mat4 uMVP;
void main() {
    vUV = aTexCoord;
    gl_Position = uMVP * vec4(aPosition, 1.0);
}

// Fragment shader (separate file or string)
#version 300 es
precision highp float;
in vec2 vUV;
out vec4 fragColor;
void main() {
    fragColor = vec4(vUV, 0.5, 1.0);
}
```

### Three.js / React Three Fiber

```javascript
const material = new THREE.ShaderMaterial({
    vertexShader: `
        varying vec2 vUv;
        uniform float uTime;

        void main() {
            vUv = uv;
            vec3 pos = position;
            pos.y += sin(pos.x * 4.0 + uTime) * 0.3;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
        }
    `,
    fragmentShader: `
        varying vec2 vUv;

        void main() {
            gl_FragColor = vec4(vUv, 0.5, 1.0);
        }
    `,
    uniforms: {
        uTime: { value: 0.0 }
    }
});
```

Three.js provides `projectionMatrix`, `modelViewMatrix`, `position`, `normal`, `uv` as built-in attributes and uniforms.

### Godot

```gdscript
shader_type spatial;

void vertex() {
    VERTEX.y += sin(VERTEX.x * 4.0 + TIME * 2.0) * 0.3;
}

void fragment() {
    ALBEDO = vec3(UV, 0.5);
}
```

Godot's shading language is GLSL-like but uses `VERTEX`, `NORMAL`, `UV`, `TIME` as built-in names. The `vertex()` function modifies vertices; `fragment()` determines color.

### Love2D

Love2D's shader system focuses on fragment shaders for 2D sprite rendering. Vertex shaders are available but less commonly used:

```lua
shader = love.graphics.newShader([[
    extern float time;

    vec4 position(mat4 transform_projection, vec4 vertex_position) {
        vertex_position.y += sin(vertex_position.x * 0.1 + time) * 10.0;
        return transform_projection * vertex_position;
    }

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        return Texel(tex, texture_coords) * color;
    }
]])
```

### VertexShaderArt.com

For pure vertex shader experimentation without fragment shader concerns, [vertexshaderart.com](https://vertexshaderart.com) lets you write vertex shaders that position thousands of points in space using only `vertexId`, `time`, and other uniforms. It is an excellent playground for vertex displacement.

---

## 8. Practical Effects

### Screen Shake

Offset the final clip-space position by a small amount:

```glsl
void main() {
    gl_Position = uMVP * vec4(aPosition, 1.0);

    // Shake: offset screen position
    float shakeAmount = uShakeIntensity;  // Set by CPU (0 = no shake)
    float shakeX = sin(uTime * 50.0) * shakeAmount;
    float shakeY = cos(uTime * 63.0) * shakeAmount;
    gl_Position.xy += vec2(shakeX, shakeY);
}
```

### Billboarding

Force a quad to always face the camera (for particles, labels, sprites in 3D):

```glsl
void main() {
    // Extract camera right and up vectors from the view matrix
    vec3 right = vec3(uView[0][0], uView[1][0], uView[2][0]);
    vec3 up    = vec3(uView[0][1], uView[1][1], uView[2][1]);

    // Position the vertex relative to the billboard center
    vec3 worldPos = uBillboardCenter
                  + right * aPosition.x * uSize
                  + up    * aPosition.y * uSize;

    gl_Position = uProjection * uView * vec4(worldPos, 1.0);
}
```

### Mesh Morphing

Blend between two positions (e.g., two animation poses):

```glsl
void main() {
    vec3 pos = mix(aPositionA, aPositionB, uMorphFactor);
    gl_Position = uMVP * vec4(pos, 1.0);
}
```

### Outline via Vertex Extrusion

Draw a slightly enlarged version of the mesh in a solid color behind the original for an outline effect:

```glsl
// Outline pass: push vertices outward along normals
void main() {
    vec3 pos = aPosition + aNormal * uOutlineWidth;
    gl_Position = uMVP * vec4(pos, 1.0);
}
// Fragment: output solid outline color
```

---

## Code Walkthrough: Animated Wave Plane

A complete vertex + fragment shader pair for an animated ocean surface.

### Vertex Shader

```glsl
#version 330 core

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec2 aTexCoord;

out vec2 vUV;
out float vHeight;
out vec3 vNormal;

uniform mat4 uMVP;
uniform mat4 uModel;
uniform float uTime;

void main() {
    vec3 pos = aPosition;

    // Multi-wave displacement
    float h = 0.0;
    h += sin(pos.x * 3.0 + uTime * 2.0) * 0.1;
    h += sin(pos.z * 4.0 + uTime * 1.5) * 0.07;
    h += sin((pos.x + pos.z) * 2.0 + uTime * 1.8) * 0.05;
    h += sin(pos.x * 8.0 + pos.z * 6.0 + uTime * 3.0) * 0.02;

    pos.y += h;

    // Compute normal analytically
    float dx = 0.0;
    dx += cos(pos.x * 3.0 + uTime * 2.0) * 0.1 * 3.0;
    dx += cos((pos.x + pos.z) * 2.0 + uTime * 1.8) * 0.05 * 2.0;
    dx += cos(pos.x * 8.0 + pos.z * 6.0 + uTime * 3.0) * 0.02 * 8.0;

    float dz = 0.0;
    dz += cos(pos.z * 4.0 + uTime * 1.5) * 0.07 * 4.0;
    dz += cos((pos.x + pos.z) * 2.0 + uTime * 1.8) * 0.05 * 2.0;
    dz += cos(pos.x * 8.0 + pos.z * 6.0 + uTime * 3.0) * 0.02 * 6.0;

    vNormal = normalize(vec3(-dx, 1.0, -dz));
    vHeight = h;
    vUV = aTexCoord;

    gl_Position = uMVP * vec4(pos, 1.0);
}
```

### Fragment Shader

```glsl
#version 330 core

in vec2 vUV;
in float vHeight;
in vec3 vNormal;

out vec4 fragColor;

uniform float uTime;

void main() {
    // Ocean colors based on height
    vec3 deep    = vec3(0.0, 0.05, 0.2);
    vec3 shallow = vec3(0.0, 0.3, 0.5);
    vec3 foam    = vec3(0.8, 0.9, 1.0);

    float t = vHeight * 4.0 + 0.5;
    vec3 color = mix(deep, shallow, clamp(t, 0.0, 1.0));
    color = mix(color, foam, smoothstep(0.8, 1.0, t));

    // Simple directional light
    vec3 lightDir = normalize(vec3(0.5, 0.8, 0.3));
    float diff = max(dot(vNormal, lightDir), 0.0);
    color *= 0.3 + 0.7 * diff;

    // Specular
    vec3 viewDir = vec3(0.0, 1.0, 0.0);
    vec3 halfDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(vNormal, halfDir), 0.0), 64.0);
    color += vec3(1.0) * spec * 0.5;

    fragColor = vec4(color, 1.0);
}
```

### What This Demonstrates

- **Multi-wave displacement** — four sine waves at different frequencies and angles create realistic ocean motion
- **Analytical normals** — computed from the derivatives of the displacement function
- **Height-to-color mapping** — using the displacement value to drive ocean color (deep → shallow → foam)
- **Diffuse + specular lighting** — applied in the fragment shader using interpolated normals
- **Vertex-to-fragment data flow** — height, UV, and normal passed as varyings

---

## GLSL Quick Reference

| Function/Concept | Description | Example |
|---|---|---|
| `gl_Position` | Mandatory vertex output (clip space) | `gl_Position = MVP * vec4(pos, 1.0)` |
| `in` attribute | Per-vertex data from mesh | `in vec3 aPosition` |
| `out` varying | Data sent to fragment shader | `out vec2 vUV` |
| `uniform` | Constant per-draw data from CPU | `uniform mat4 uMVP` |
| Model matrix | Local space → world space | Position, rotate, scale object |
| View matrix | World space → camera space | Inverse of camera transform |
| Projection matrix | Camera space → clip space | Perspective or orthographic |
| `mat4 * vec4` | Matrix-vector multiplication | Applies transform |
| Displacement | Modify `aPosition` before MVP | `pos.y += sin(pos.x + time)` |
| Normal recalc | Gradient of displacement | Finite diff or analytical derivative |
| Billboard | Face camera by using view matrix vectors | Particles, sprites |
| Screen shake | Offset `gl_Position.xy` | `pos.xy += shake * sin(time)` |

---

## Common Pitfalls

### 1. Column-Major vs. Row-Major

GLSL matrices are column-major. The constructor `mat4(c0, c1, c2, c3)` takes columns, not rows:

```glsl
// This is a TRANSLATION matrix (translation is in column 3):
mat4 t = mat4(
    1, 0, 0, 0,   // Column 0
    0, 1, 0, 0,   // Column 1
    0, 0, 1, 0,   // Column 2
    tx, ty, tz, 1  // Column 3 (translation)
);
```

If your translation appears in the wrong place, you probably swapped rows and columns.

### 2. Forgetting w=1 for Positions

```glsl
// WRONG — w=0 makes this a direction, not a position:
gl_Position = uMVP * vec4(aPosition, 0.0);

// RIGHT — w=1 for positions (affected by translation):
gl_Position = uMVP * vec4(aPosition, 1.0);

// w=0 is correct for DIRECTIONS (normals, light dirs):
vec3 worldNormal = (uModel * vec4(aNormal, 0.0)).xyz;
```

### 3. Normals After Non-Uniform Scale

If the model matrix includes non-uniform scaling, normals are distorted. Use the inverse transpose:

```glsl
// WRONG — normals skew with non-uniform scale:
vec3 worldNormal = (uModel * vec4(aNormal, 0.0)).xyz;

// RIGHT — use inverse transpose:
vec3 worldNormal = (transpose(inverse(uModel)) * vec4(aNormal, 0.0)).xyz;
// Or pass the normal matrix as a separate uniform (cheaper)
```

### 4. Displacement in Wrong Space

Displacement should usually happen in model/local space (before the MVP transform). Displacing in clip space gives very different results:

```glsl
// RIGHT — displace in local space, then transform:
vec3 pos = aPosition;
pos.y += sin(pos.x + uTime);
gl_Position = uMVP * vec4(pos, 1.0);

// DIFFERENT — displace in clip space (screen-space effect):
gl_Position = uMVP * vec4(aPosition, 1.0);
gl_Position.x += sin(uTime) * 0.1;  // Moves on screen, not in world
```

---

## Exercises

### Exercise 1: Wave Mesh

**Time:** 30–45 minutes

In any environment that supports vertex shaders (Three.js, Godot, raw WebGL):

1. Create a subdivided plane (grid of triangles)
2. In the vertex shader, displace the Y position using `sin(x * freq + time)`
3. Add a second wave with different frequency and direction
4. Pass the displacement amount as a varying to the fragment shader
5. Color the surface based on height: low = blue, mid = green, high = white

**Concepts practiced:** Vertex displacement, varyings, height-based coloring

---

### Exercise 2: Flag Simulation

**Time:** 30–45 minutes

Create a rectangular mesh that simulates a waving flag:

1. One edge of the flag is fixed (the pole side — displacement = 0 at `x = 0`)
2. The other edge waves freely (displacement increases with distance from pole)
3. Use `smoothstep(0.0, 1.0, aPosition.x)` as a flexibility mask
4. Layer 2–3 sine waves at different frequencies for natural cloth motion
5. Color the flag with stripes or a pattern (fragment shader)

**Concepts practiced:** Masked displacement, multiple waves, natural motion

---

### Exercise 3: Terrain Viewer

**Time:** 45–60 minutes

Create a terrain visualizer:

1. Generate a flat grid of vertices
2. In the vertex shader, sample a height map texture to displace Y
3. Compute normals using finite differences in the vertex shader
4. In the fragment shader, apply height-based coloring (water/sand/grass/rock/snow)
5. Add a directional light using the computed normals

**Stretch:** Add a time-based offset to the height map UV for a "flying over terrain" effect.

**Concepts practiced:** Height map displacement, normal computation, lighting, terrain coloring

---

## Key Takeaways

1. **The vertex shader positions geometry.** It runs once per vertex and must output `gl_Position` in clip space. This is where 3D-to-2D projection, animation, and deformation happen.

2. **MVP transforms go from local to screen.** Model (local → world) × View (world → camera) × Projection (camera → clip). Understanding this chain is fundamental to all 3D rendering.

3. **Varyings are interpolated across triangles.** Any value output from the vertex shader arrives at the fragment shader smoothly blended between the triangle's three vertices. This is how UVs, normals, and colors travel from vertices to pixels.

4. **Vertex displacement creates animated geometry.** Add sine waves for ocean, mask by vertex height for wind-blown grass, sample a height map for terrain. The technique is always: modify position, then pass info to the fragment shader for coloring.

5. **Normals must be recalculated after displacement.** Use analytical derivatives (exact, fast) for math-based displacement, or finite differences (general, slightly more expensive) for texture-based displacement.

6. **GLSL matrices are column-major.** This is the most common source of confusion when building matrices by hand. Translation goes in column 3, not row 3.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [LearnOpenGL: Coordinate Systems](https://learnopengl.com/Getting-started/Coordinate-Systems) | Tutorial | The clearest explanation of the MVP pipeline with diagrams. Essential reading. |
| [LearnOpenGL: Shaders](https://learnopengl.com/Getting-started/Shaders) | Tutorial | Vertex/fragment shader communication, attributes, uniforms, and varyings explained with working code. |
| [Ronja: Vertex Displacement](https://www.ronja-tutorials.com/post/015-wobble-displacement/) | Tutorial | Practical vertex displacement techniques with visual results. Unity/HLSL but translates directly. |
| [VertexShaderArt.com](https://vertexshaderart.com) | Playground | Pure vertex shader experimentation. Position thousands of points using only math — great for building vertex intuition. |

---

## What's Next?

You now understand both stages of the GPU pipeline: the vertex shader positions geometry, and the fragment shader colors pixels. The next logical steps:

- **[Module 9: Post-Processing Effects](module-09-post-processing.md)** — Apply full-screen effects to rendered scenes using the techniques from Module 6.
- **[Module 10: Raymarching & 3D SDF Scenes](module-10-raymarching-3d-sdf.md)** — Build 3D worlds entirely in the fragment shader (bypassing the vertex shader's geometry pipeline).
- **[Module 12: Porting to Engines](module-12-porting-to-engines.md)** — Use vertex + fragment shaders in Godot, Love2D, or Three.js.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
