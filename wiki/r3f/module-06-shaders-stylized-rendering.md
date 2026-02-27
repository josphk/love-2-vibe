# Module 6: Shaders & Stylized Rendering

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 8–12 hours
**Prerequisites:** [Module 5: Game Architecture & State](module-05-game-architecture-state.md)

---

## Overview

You're about to learn the most creatively powerful skill in game development: writing shaders. Shaders are tiny programs that run on the GPU, executing millions of times per frame — once for every vertex, once for every pixel. They control how everything looks. Every material you've used so far — `meshStandardMaterial`, `meshPhysicalMaterial`, all of them — is just a shader someone else wrote. Now you write your own.

This module is the heart of the artistic track. Built-in materials are fine for prototyping, but they all look the same. The moment you want a cel-shaded cartoon look, a holographic shimmer, a watercolor painting come to life, or literally any visual style that doesn't scream "default PBR," you need custom shaders. There's no way around it, and there's no reason to avoid it. GLSL is simpler than you think — it's mostly math, and most of that math is just `mix`, `smoothstep`, and `sin`.

You'll start with the GPU pipeline mental model, write your first shader from scratch, build up a toolkit of GLSL functions and noise, then apply everything to three complete stylized material effects: toon shading, watercolor, and holographic. You'll also get a preview of TSL (Three Shading Language), which lets you write shader logic in TypeScript instead of GLSL strings.

By the end, you'll have a character showcase with three swappable material modes, each with complete, copy-pasteable GLSL. You'll never look at a stylized game and think "how did they do that?" again. You'll know exactly how.

---

## 1. Why Custom Shaders

### What Built-In Materials Can't Do

Three.js ships with solid materials. `meshStandardMaterial` handles PBR. `meshPhysicalMaterial` handles glass, clearcoat, sheen. But they all converge on the same "realistic" look. They can't do:

- **Cel-shading / toon shading** — quantized light bands, hard edges, cartoon style
- **Watercolor / painterly effects** — noise-distorted edges, paper texture, soft bleeds
- **Holographic / sci-fi** — fresnel glow, scanlines, chromatic aberration
- **Dissolve effects** — noise-driven reveal/hide transitions
- **Force fields** — animated transparency with pulsing noise
- **Custom procedural textures** — marble, wood grain, stripes, computed entirely on the GPU
- **Screen-space effects** — outlines, blur, color grading in post-processing
- **Anything that moves uniquely per vertex** — wind on grass, waves on water, mesh distortion

### When to Reach for Custom Shaders vs Drei Helpers

Drei has some shortcut materials: `MeshDistortMaterial`, `MeshWobbleMaterial`, `MeshTransmissionMaterial`. Use them when they match your needs — they're battle-tested and performant. But the moment you need something they don't offer, or you need to combine effects, or you need precise control, you're writing GLSL.

The decision tree:
1. Does a built-in Three.js material do what I need? Use it.
2. Does a drei material do what I need? Use it.
3. Neither? Write a custom shader. That's what this module is for.

### The Creative Freedom of GPU Programming

A fragment shader runs once per pixel. On a 1920x1080 screen, that's ~2 million executions per frame. At 60fps, that's ~124 million per second. The GPU handles this effortlessly because it runs all those invocations in parallel. This parallelism is what makes shaders fast — and what makes them different from CPU code. You don't loop over pixels. You write the logic for one pixel, and the GPU runs it on all of them simultaneously.

---

## 2. The GPU Pipeline

### The Mental Model

Every frame, your 3D mesh goes through a pipeline on the GPU. You only need to understand three stages:

```
Vertices (mesh data)
       │
       ▼
┌──────────────┐
│ VERTEX SHADER │ ← You write this. Runs once per vertex.
│              │   Transforms positions from 3D world space
│              │   to 2D screen space.
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  RASTERIZER  │ ← GPU handles this. Converts triangles to
│              │   pixels. Interpolates data between vertices.
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ FRAGMENT SHADER  │ ← You write this. Runs once per pixel.
│                  │   Decides the final color of each pixel.
└──────────────────┘
       │
       ▼
   Screen pixels
```

### What Each Stage Does

**Vertex shader** — Receives raw vertex data (position, normal, UV coordinates). Its primary job: multiply the position by the model-view-projection matrix to get the screen-space position. It can also deform the mesh (waves, wind, explosions) and pass data to the fragment shader.

**Rasterizer** — Takes the transformed triangles from the vertex shader and figures out which pixels on screen each triangle covers. It interpolates any data you pass between vertices (like colors, UVs, normals) so the fragment shader gets a smooth, per-pixel value. You don't write this stage.

**Fragment shader** — Receives the interpolated data for each pixel and outputs a color (`vec4` — red, green, blue, alpha). This is where all the visual magic happens: lighting calculations, textures, noise, color effects.

### Attributes, Uniforms, Varyings

These are the three ways data flows through the pipeline:

| Type | Flows From | To | What It Is | Example |
|------|------------|-----|------------|---------|
| **Attribute** | CPU | Vertex shader only | Per-vertex data | `position`, `normal`, `uv` |
| **Uniform** | CPU | Both shaders | Constant for the whole draw call | `time`, `color`, `texture`, `matrix` |
| **Varying** | Vertex shader | Fragment shader | Interpolated per-pixel data | Passed UV, computed lighting |

Think of it this way:
- **Attributes** are different for every vertex (each vertex has its own position).
- **Uniforms** are the same for every vertex and every pixel in a single draw call (time doesn't change mid-frame).
- **Varyings** are the bridge — the vertex shader computes a value per vertex, the rasterizer interpolates it, and the fragment shader receives a smooth per-pixel value.

---

## 3. ShaderMaterial in R3F

### Writing Inline GLSL

In R3F, you use `<shaderMaterial>` and pass `vertexShader` and `fragmentShader` as string props containing GLSL code:

```tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

function CustomShaderMesh() {
  const materialRef = useRef<THREE.ShaderMaterial>(null)

  useFrame(({ clock }) => {
    if (!materialRef.current) return
    materialRef.current.uniforms.uTime.value = clock.getElapsedTime()
  })

  return (
    <mesh>
      <sphereGeometry args={[1, 32, 32]} />
      <shaderMaterial
        ref={materialRef}
        vertexShader={`
          varying vec2 vUv;
          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `}
        fragmentShader={`
          uniform float uTime;
          varying vec2 vUv;
          void main() {
            vec3 color = vec3(vUv, sin(uTime) * 0.5 + 0.5);
            gl_FragColor = vec4(color, 1.0);
          }
        `}
        uniforms={{
          uTime: { value: 0 },
        }}
      />
    </mesh>
  )
}
```

### Key Props of shaderMaterial

| Prop | Type | What It Does |
|------|------|--------------|
| `vertexShader` | `string` | GLSL code for the vertex shader |
| `fragmentShader` | `string` | GLSL code for the fragment shader |
| `uniforms` | `object` | Key-value pairs of uniform data (`{ name: { value: ... } }`) |
| `transparent` | `boolean` | Enable alpha blending (needed if your shader outputs alpha < 1) |
| `side` | `THREE.Side` | `THREE.FrontSide`, `THREE.BackSide`, or `THREE.DoubleSide` |
| `depthWrite` | `boolean` | Whether to write to the depth buffer |
| `blending` | `THREE.Blending` | Blend mode (`AdditiveBlending`, `NormalBlending`, etc.) |

### Built-In Uniforms Three.js Provides

When you use `shaderMaterial`, Three.js automatically injects these uniforms — you don't need to declare them:

| Uniform | Type | What It Is |
|---------|------|-----------|
| `projectionMatrix` | `mat4` | Camera projection (perspective/ortho) |
| `modelViewMatrix` | `mat4` | Combined model + view transform |
| `modelMatrix` | `mat4` | Object's world transform |
| `viewMatrix` | `mat4` | Camera's view transform |
| `normalMatrix` | `mat3` | Correct transform for normals |
| `cameraPosition` | `vec3` | World-space camera position |

### Built-In Attributes Three.js Provides

These are available in the vertex shader from the geometry:

| Attribute | Type | What It Is |
|-----------|------|-----------|
| `position` | `vec3` | Vertex position in local space |
| `normal` | `vec3` | Vertex normal |
| `uv` | `vec2` | Texture coordinates |

---

## 4. Your First Custom Shader

### Step by Step: Position-Based Coloring

Let's build a shader that colors a mesh based on its position in space. No textures, no lights — pure math to color.

**Vertex shader** — pass position and UV data to the fragment shader:

```glsl
// Declare a varying to send data to the fragment shader
varying vec2 vUv;
varying vec3 vPosition;

void main() {
  // Pass UV coordinates through
  vUv = uv;

  // Pass the local-space position to the fragment shader
  vPosition = position;

  // Standard transform: local space → clip space
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
```

**Fragment shader** — use the position to compute color:

```glsl
varying vec2 vUv;
varying vec3 vPosition;

void main() {
  // Remap position from [-1,1] to [0,1] range for color
  vec3 color = vPosition * 0.5 + 0.5;

  // Output the final color (RGBA)
  gl_FragColor = vec4(color, 1.0);
}
```

**The complete R3F component:**

```tsx
function PositionColorMesh() {
  return (
    <mesh>
      <boxGeometry args={[2, 2, 2]} />
      <shaderMaterial
        vertexShader={`
          varying vec2 vUv;
          varying vec3 vPosition;

          void main() {
            vUv = uv;
            vPosition = position;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `}
        fragmentShader={`
          varying vec2 vUv;
          varying vec3 vPosition;

          void main() {
            vec3 color = vPosition * 0.5 + 0.5;
            gl_FragColor = vec4(color, 1.0);
          }
        `}
      />
    </mesh>
  )
}
```

### What's Happening

1. The geometry provides `position`, `normal`, and `uv` attributes for each vertex.
2. The vertex shader transforms each vertex to screen space via `projectionMatrix * modelViewMatrix * vec4(position, 1.0)`. This line is the standard boilerplate — you'll write it in every vertex shader.
3. The vertex shader also passes `vPosition` and `vUv` as varyings.
4. The rasterizer interpolates `vPosition` and `vUv` across each triangle's pixels.
5. The fragment shader maps the interpolated position to an RGB color. `vPosition * 0.5 + 0.5` remaps from [-1,1] to [0,1] because color channels must be in [0,1] range.
6. `gl_FragColor` is the final output — a `vec4(r, g, b, a)`.

Each face of the box will be a different color because each face's vertices have different positions. Corners blend smoothly because the rasterizer interpolates.

---

## 5. Uniforms: Connecting CPU to GPU

### The Pattern

Uniforms are how you send data from your React component to your shader every frame. The pattern is always the same:

1. Declare the uniform in your GLSL code
2. Initialize it in the `uniforms` prop
3. Update it in `useFrame`

```tsx
function AnimatedShader() {
  const materialRef = useRef<THREE.ShaderMaterial>(null)

  useFrame(({ clock, pointer }) => {
    if (!materialRef.current) return
    materialRef.current.uniforms.uTime.value = clock.getElapsedTime()
    materialRef.current.uniforms.uMouse.value.set(pointer.x, pointer.y)
  })

  return (
    <mesh>
      <planeGeometry args={[4, 4]} />
      <shaderMaterial
        ref={materialRef}
        uniforms={{
          uTime: { value: 0 },
          uMouse: { value: new THREE.Vector2(0, 0) },
          uResolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
          uColor: { value: new THREE.Color('#ff6600') },
        }}
        vertexShader={`
          varying vec2 vUv;
          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `}
        fragmentShader={`
          uniform float uTime;
          uniform vec2 uMouse;
          uniform vec2 uResolution;
          uniform vec3 uColor;
          varying vec2 vUv;

          void main() {
            // Pulsing color based on time
            float pulse = sin(uTime * 2.0) * 0.5 + 0.5;
            vec3 color = mix(uColor, vec3(1.0), pulse * 0.3);

            // Mouse influence
            float mouseDist = distance(vUv, uMouse * 0.5 + 0.5);
            color += vec3(0.2) * smoothstep(0.3, 0.0, mouseDist);

            gl_FragColor = vec4(color, 1.0);
          }
        `}
      />
    </mesh>
  )
}
```

### Uniform Types Cheat Sheet

| GLSL Type | JS Type | Example |
|-----------|---------|---------|
| `float` | `number` | `{ value: 0.0 }` |
| `int` | `number` | `{ value: 1 }` |
| `vec2` | `THREE.Vector2` | `{ value: new THREE.Vector2(0, 0) }` |
| `vec3` | `THREE.Vector3` or `THREE.Color` | `{ value: new THREE.Color('#ff0000') }` |
| `vec4` | `THREE.Vector4` | `{ value: new THREE.Vector4(0, 0, 0, 1) }` |
| `mat4` | `THREE.Matrix4` | `{ value: new THREE.Matrix4() }` |
| `sampler2D` | `THREE.Texture` | `{ value: texture }` |
| `bool` | `number` (0 or 1) | `{ value: 0 }` |

### Texture Uniforms

Loading and passing textures as uniforms:

```tsx
import { useTexture } from '@react-three/drei'

function TexturedShader() {
  const materialRef = useRef<THREE.ShaderMaterial>(null)
  const paperTexture = useTexture('/textures/paper.jpg')

  return (
    <mesh>
      <planeGeometry args={[4, 4]} />
      <shaderMaterial
        ref={materialRef}
        uniforms={{
          uTexture: { value: paperTexture },
        }}
        vertexShader={`
          varying vec2 vUv;
          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `}
        fragmentShader={`
          uniform sampler2D uTexture;
          varying vec2 vUv;
          void main() {
            vec4 texColor = texture2D(uTexture, vUv);
            gl_FragColor = texColor;
          }
        `}
      />
    </mesh>
  )
}
```

---

## 6. Common GLSL Functions

This is your cheat sheet. Bookmark this section. You'll come back to it constantly.

### Interpolation & Clamping

| Function | Signature | What It Does |
|----------|-----------|--------------|
| `mix(a, b, t)` | `float/vec → same` | Linear interpolation. Returns `a * (1-t) + b * t`. The most-used function in all of shader programming. |
| `step(edge, x)` | `float → float` | Hard cutoff. Returns `0.0` if `x < edge`, `1.0` otherwise. |
| `smoothstep(lo, hi, x)` | `float → float` | Smooth transition from 0 to 1 between `lo` and `hi`. S-curve, no sharp edges. |
| `clamp(x, min, max)` | `float/vec → same` | Constrains `x` between `min` and `max`. |

```glsl
// mix: blend between two colors
vec3 color = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), 0.5); // purple

// step: hard threshold — everything below 0.5 is black, above is white
float mask = step(0.5, vUv.x);

// smoothstep: soft threshold — gradual transition from 0.3 to 0.7
float gradient = smoothstep(0.3, 0.7, vUv.x);

// clamp: keep value in range
float safe = clamp(brightness, 0.0, 1.0);
```

### Repeating & Wrapping

| Function | Signature | What It Does |
|----------|-----------|--------------|
| `fract(x)` | `float/vec → same` | Returns the fractional part. `fract(2.7) = 0.7`. Creates repeating patterns. |
| `mod(x, y)` | `float/vec → same` | Modulo. `mod(5.0, 3.0) = 2.0`. Like `fract` but with custom period. |
| `floor(x)` | `float/vec → same` | Round down. `floor(2.7) = 2.0`. |
| `ceil(x)` | `float/vec → same` | Round up. `ceil(2.3) = 3.0`. |
| `abs(x)` | `float/vec → same` | Absolute value. `abs(-3.0) = 3.0`. |

```glsl
// fract: create repeating stripes
float stripes = step(0.5, fract(vUv.x * 10.0));

// mod: tile UV space into a 4x4 grid
vec2 tiled = mod(vUv * 4.0, 1.0);
```

### Trigonometry

| Function | Signature | What It Does |
|----------|-----------|--------------|
| `sin(x)` | `float → float` | Sine wave. Returns [-1, 1]. The backbone of animation. |
| `cos(x)` | `float → float` | Cosine wave. Same as sin, shifted by π/2. |
| `atan(y, x)` | `float, float → float` | Angle from origin. Returns [-π, π]. |

```glsl
// sin: pulsing glow over time
float glow = sin(uTime * 3.0) * 0.5 + 0.5; // Remapped to [0, 1]

// sin + cos: circular motion
vec2 offset = vec2(cos(uTime), sin(uTime)) * 0.5;
```

### Vector Operations

| Function | Signature | What It Does |
|----------|-----------|--------------|
| `dot(a, b)` | `vec → float` | Dot product. Measures alignment. `1.0` = parallel, `0.0` = perpendicular, `-1.0` = opposite. |
| `normalize(v)` | `vec → vec` | Returns unit vector (length 1) in same direction. |
| `length(v)` | `vec → float` | Returns vector magnitude. |
| `distance(a, b)` | `vec, vec → float` | Distance between two points. Same as `length(a - b)`. |
| `reflect(I, N)` | `vec, vec → vec` | Reflects incident vector `I` around normal `N`. Used in specular lighting. |
| `cross(a, b)` | `vec3, vec3 → vec3` | Cross product. Returns a vector perpendicular to both inputs. |

```glsl
// dot: basic diffuse lighting
vec3 lightDir = normalize(vec3(1.0, 1.0, 0.5));
float diffuse = max(dot(vNormal, lightDir), 0.0);

// distance: radial gradient from center
float d = distance(vUv, vec2(0.5));
float circle = smoothstep(0.3, 0.28, d); // Soft circle

// normalize: safe direction computation
vec3 dir = normalize(targetPos - currentPos);
```

### Utility

| Function | Signature | What It Does |
|----------|-----------|--------------|
| `min(a, b)` | `float/vec → same` | Returns the smaller value. |
| `max(a, b)` | `float/vec → same` | Returns the larger value. |
| `pow(x, y)` | `float → float` | Power. `pow(x, 2.0)` = x squared. Used to sharpen/soften gradients. |
| `sqrt(x)` | `float → float` | Square root. |
| `sign(x)` | `float → float` | Returns -1.0, 0.0, or 1.0. |

```glsl
// pow: sharpen a gradient for tighter highlights
float sharp = pow(gradient, 4.0);

// max: ensure lighting never goes negative
float light = max(dot(normal, lightDir), 0.0);
```

---

## 7. Noise Functions

### Why Noise Matters

Noise is the foundation of procedural everything. Without noise, procedural textures look mechanical — perfect grids, perfect circles, perfect gradients. Noise adds organic variation. It's how you get clouds, terrain, fire, water, marble, wood grain, and every "natural-looking" procedural effect.

### Types of Noise

| Type | Look | Use Case |
|------|------|----------|
| **Value noise** | Blocky, simple | Cheap, good for rough variations |
| **Perlin noise** | Smooth, gradient-based | Classic procedural textures |
| **Simplex noise** | Smooth, less grid artifacts | Better than Perlin, lower cost |
| **Worley noise** | Cellular, Voronoi-like | Cells, cracks, caustics, scales |

### A Simple Noise Implementation

GLSL doesn't ship with noise functions. You need to include one. Here's a clean 2D simplex-style noise you can drop into any shader:

```glsl
// Simple hash-based 2D noise
vec2 hash22(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)),
           dot(p, vec2(269.5, 183.3)));
  return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise2D(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);

  // Smooth interpolation curve
  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(
    mix(dot(hash22(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
        dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
    mix(dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
        dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
    u.y
  );
}
```

### FBM: Fractal Brownian Motion

Layer multiple octaves of noise at different frequencies for richer detail:

```glsl
float fbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  float frequency = 1.0;

  for (int i = 0; i < 6; i++) {
    value += amplitude * noise2D(p * frequency);
    frequency *= 2.0;
    amplitude *= 0.5;
  }

  return value;
}
```

### Simple Worley (Cellular) Noise

```glsl
float worley(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);

  float minDist = 1.0;

  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 neighbor = vec2(float(x), float(y));
      vec2 point = hash22(i + neighbor) * 0.5 + 0.5; // Random point in cell
      float d = length(neighbor + point - f);
      minDist = min(minDist, d);
    }
  }

  return minDist;
}
```

### Using Noise in Practice

```glsl
// Animated noise cloud
float n = fbm(vUv * 5.0 + uTime * 0.3);
vec3 color = mix(vec3(0.1, 0.1, 0.3), vec3(1.0, 0.8, 0.5), n);

// Distort UVs for a watery effect
vec2 distortedUv = vUv + vec2(noise2D(vUv * 8.0 + uTime), noise2D(vUv * 8.0 + 100.0 + uTime)) * 0.02;

// Worley for cracked/cellular pattern
float cells = worley(vUv * 6.0);
vec3 cellColor = vec3(smoothstep(0.0, 0.1, cells)); // Dark borders, bright centers
```

---

## 8. Cel-Shading / Toon Shading

### The Core Idea

Realistic lighting is a smooth gradient from light to shadow. Cel-shading quantizes that gradient into discrete bands — like a cartoon. The steps:

1. Compute the standard diffuse dot product (`dot(normal, lightDirection)`)
2. Instead of using it directly, snap it to discrete levels using `floor` or `step`
3. Add a rim light (fresnel) for the glowing edge effect common in anime/cartoon styles

### The Complete Toon Shader

```glsl
// ===== VERTEX SHADER =====
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vUv;

void main() {
  vUv = uv;

  // Transform normal to world space
  vNormal = normalize(normalMatrix * normal);

  // Compute view direction (camera to vertex) in world space
  vec4 worldPos = modelMatrix * vec4(position, 1.0);
  vViewDir = normalize(cameraPosition - worldPos.xyz);

  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
```

```glsl
// ===== FRAGMENT SHADER =====
uniform vec3 uColor;
uniform vec3 uLightDir;
uniform float uBands;
uniform float uRimPower;
uniform float uRimIntensity;

varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vUv;

void main() {
  vec3 normal = normalize(vNormal);
  vec3 lightDir = normalize(uLightDir);
  vec3 viewDir = normalize(vViewDir);

  // --- Diffuse: quantized into bands ---
  float NdotL = dot(normal, lightDir);
  float diffuse = max(NdotL, 0.0);

  // Quantize: snap to discrete bands
  // e.g., 4 bands → values of 0.0, 0.33, 0.66, 1.0
  diffuse = floor(diffuse * uBands) / uBands;

  // Add a small ambient floor so the dark side isn't pure black
  diffuse = max(diffuse, 0.15);

  // --- Rim light (fresnel) ---
  float rimDot = 1.0 - max(dot(viewDir, normal), 0.0);
  float rim = pow(rimDot, uRimPower) * uRimIntensity;

  // --- Combine ---
  vec3 color = uColor * diffuse + vec3(rim);

  gl_FragColor = vec4(color, 1.0);
}
```

### The R3F Component

```tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

const TOON_VERT = `
  varying vec3 vNormal;
  varying vec3 vViewDir;
  varying vec2 vUv;

  void main() {
    vUv = uv;
    vNormal = normalize(normalMatrix * normal);
    vec4 worldPos = modelMatrix * vec4(position, 1.0);
    vViewDir = normalize(cameraPosition - worldPos.xyz);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`

const TOON_FRAG = `
  uniform vec3 uColor;
  uniform vec3 uLightDir;
  uniform float uBands;
  uniform float uRimPower;
  uniform float uRimIntensity;

  varying vec3 vNormal;
  varying vec3 vViewDir;
  varying vec2 vUv;

  void main() {
    vec3 normal = normalize(vNormal);
    vec3 lightDir = normalize(uLightDir);
    vec3 viewDir = normalize(vViewDir);

    float NdotL = dot(normal, lightDir);
    float diffuse = max(NdotL, 0.0);
    diffuse = floor(diffuse * uBands) / uBands;
    diffuse = max(diffuse, 0.15);

    float rimDot = 1.0 - max(dot(viewDir, normal), 0.0);
    float rim = pow(rimDot, uRimPower) * uRimIntensity;

    vec3 color = uColor * diffuse + vec3(rim);
    gl_FragColor = vec4(color, 1.0);
  }
`

function ToonMesh() {
  const materialRef = useRef<THREE.ShaderMaterial>(null)

  return (
    <mesh>
      <torusKnotGeometry args={[1, 0.4, 128, 32]} />
      <shaderMaterial
        ref={materialRef}
        vertexShader={TOON_VERT}
        fragmentShader={TOON_FRAG}
        uniforms={{
          uColor: { value: new THREE.Color('#e74c3c') },
          uLightDir: { value: new THREE.Vector3(1, 1, 0.5).normalize() },
          uBands: { value: 4.0 },
          uRimPower: { value: 3.0 },
          uRimIntensity: { value: 0.6 },
        }}
      />
    </mesh>
  )
}
```

### Adjusting the Look

- **More bands** (6–8): smoother, closer to realistic lighting
- **Fewer bands** (2–3): harsh, graphic novel style
- **Higher rim power**: thinner rim line
- **Lower rim power**: wider, more diffuse glow
- **Rim intensity**: how bright the edge highlight is

---

## 9. Outline Rendering

### Method 1: Inverted Hull (The Classic)

The inverted hull method is the standard real-time outline technique used in countless games (Borderlands, Guilty Gear, Zelda). The idea:

1. Render the mesh a second time
2. Scale it slightly outward along its normals
3. Cull front faces (only draw back faces)
4. Color it black (or whatever outline color you want)

The slightly larger back-face-only mesh peeks out around the edges of the original mesh, creating an outline.

```tsx
function OutlineMesh({ children }: { children: React.ReactNode }) {
  return (
    <group>
      {/* The original mesh */}
      {children}

      {/* The outline pass: a slightly larger version, back-faces only, black */}
      <mesh scale={1.0}>
        <torusKnotGeometry args={[1, 0.4, 128, 32]} />
        <shaderMaterial
          vertexShader={`
            uniform float uOutlineWidth;

            void main() {
              // Push vertices outward along their normal
              vec3 outlinePos = position + normal * uOutlineWidth;
              gl_Position = projectionMatrix * modelViewMatrix * vec4(outlinePos, 1.0);
            }
          `}
          fragmentShader={`
            uniform vec3 uOutlineColor;

            void main() {
              gl_FragColor = vec4(uOutlineColor, 1.0);
            }
          `}
          uniforms={{
            uOutlineWidth: { value: 0.03 },
            uOutlineColor: { value: new THREE.Color('#000000') },
          }}
          side={THREE.BackSide}
        />
      </mesh>
    </group>
  )
}
```

A cleaner approach — combine the outline into a reusable component:

```tsx
function OutlinePass({
  geometry,
  width = 0.03,
  color = '#000000',
}: {
  geometry: React.ReactNode
  width?: number
  color?: string
}) {
  return (
    <mesh>
      {geometry}
      <shaderMaterial
        vertexShader={`
          uniform float uOutlineWidth;
          void main() {
            vec3 pos = position + normal * uOutlineWidth;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
          }
        `}
        fragmentShader={`
          uniform vec3 uOutlineColor;
          void main() {
            gl_FragColor = vec4(uOutlineColor, 1.0);
          }
        `}
        uniforms={{
          uOutlineWidth: { value: width },
          uOutlineColor: { value: new THREE.Color(color) },
        }}
        side={THREE.BackSide}
      />
    </mesh>
  )
}
```

### Method 2: Post-Processing Edge Detection

Use a screen-space edge detection pass (Sobel filter, Roberts cross) on the depth or normal buffer to find edges. This produces consistent-width outlines regardless of mesh scale and works on the entire scene at once.

```tsx
import { EffectComposer, ShaderPass } from '@react-three/postprocessing'
// Or use the drei <Outline> effect:
import { Outline } from '@react-three/postprocessing'

// drei/postprocessing provides a ready-made outline effect
// This is the easier path if you don't need custom control
```

### Pros and Cons

| Aspect | Inverted Hull | Post-Processing |
|--------|--------------|-----------------|
| **Setup** | Per-mesh, simple GLSL | Scene-wide, needs post-processing pipeline |
| **Performance** | Extra draw call per outlined mesh | One extra full-screen pass |
| **Outline width** | Varies with distance/mesh scale | Consistent screen-space width |
| **Inner edges** | Cannot detect | Can detect (creases, silhouettes) |
| **Customization** | Full per-mesh control over width/color | Uniform across all outlined objects |
| **Best for** | Stylized per-object outlines | Consistent scene-wide outlines |

For the mini-project, we'll use the inverted hull method — it's simpler, more educational, and gives you per-object control.

---

## 10. Procedural Textures

### No Texture Files Needed

Every pattern below is computed purely from math in the fragment shader. No images, no loading, infinite resolution at any zoom level.

### Stripes

```glsl
// Horizontal stripes
float stripes = step(0.5, fract(vUv.y * 10.0));
vec3 color = mix(vec3(0.2, 0.2, 0.8), vec3(0.8, 0.8, 1.0), stripes);
```

### Checkerboard

```glsl
// Classic checkerboard
float checker = mod(floor(vUv.x * 8.0) + floor(vUv.y * 8.0), 2.0);
vec3 color = mix(vec3(0.1), vec3(0.9), checker);
```

### Dots / Polka Dots

```glsl
// Polka dots
vec2 grid = fract(vUv * 8.0) - 0.5;
float dot = smoothstep(0.25, 0.23, length(grid));
vec3 color = mix(vec3(0.9, 0.85, 0.8), vec3(0.8, 0.2, 0.3), dot);
```

### Radial Gradient

```glsl
// Radial gradient from center
float dist = distance(vUv, vec2(0.5));
vec3 color = mix(vec3(1.0, 0.8, 0.2), vec3(0.1, 0.0, 0.3), dist);
```

### Wood Grain

```glsl
// Simplified wood grain
float ring = sin((length(vUv - 0.5) + noise2D(vUv * 2.0) * 0.1) * 40.0);
ring = ring * 0.5 + 0.5;
vec3 lightWood = vec3(0.76, 0.6, 0.42);
vec3 darkWood = vec3(0.52, 0.37, 0.26);
vec3 color = mix(darkWood, lightWood, ring);
```

### Marble

```glsl
// Marble with veins
float turbulence = fbm(vUv * 5.0);
float veins = sin(vUv.x * 10.0 + turbulence * 6.0) * 0.5 + 0.5;
veins = pow(veins, 0.6); // Sharpen the veins
vec3 color = mix(vec3(0.2, 0.2, 0.22), vec3(0.95, 0.93, 0.9), veins);
```

### Combining Patterns

The power of procedural textures is composition. Mix noise with any pattern to break up the regularity:

```glsl
// Noisy stripes — more organic
float n = noise2D(vUv * 20.0) * 0.05;
float stripes = smoothstep(0.45, 0.55, fract(vUv.y * 10.0 + n));
```

---

## 11. TSL: Three Shading Language

### What TSL Is

TSL (Three Shading Language) is Three.js's node-based shader system that lets you write shader logic in JavaScript/TypeScript instead of GLSL strings. It compiles to GLSL (for WebGL) or WGSL (for WebGPU) behind the scenes. It's the future of shader authoring in Three.js, but it's closely tied to the `WebGPURenderer` pipeline.

### Why TSL Exists

1. **No more string-based GLSL.** GLSL in template literals has zero IDE support — no autocomplete, no type checking, no syntax highlighting (unless you install extra tooling). TSL is real TypeScript.
2. **Cross-backend.** TSL compiles to both GLSL and WGSL, so shaders work with both WebGL and WebGPU renderers without rewriting.
3. **Composable.** TSL nodes are functions you compose — combine, mix, reuse. No copy-pasting shader string chunks.

### Basic TSL Concepts

TSL works with **nodes** — small composable units that represent shader operations. You build a material by composing these nodes:

```tsx
import {
  uniform,
  uv,
  sin,
  time,
  mix,
  vec3,
  color,
  normalLocal,
  dot,
  normalize,
  float,
  floor,
  max as tslMax,
  MeshBasicNodeMaterial,
} from 'three/tsl'

// Create a toon shading material using TSL
const toonMaterial = new MeshBasicNodeMaterial()

// Define uniforms
const baseColor = uniform(color('#e74c3c'))
const lightDir = uniform(vec3(1, 1, 0.5)).normalize()
const bands = uniform(float(4))

// Compute diffuse lighting
const NdotL = dot(normalLocal, lightDir)
const diffuse = tslMax(NdotL, 0.0)
const quantized = floor(diffuse.mul(bands)).div(bands)
const lit = tslMax(quantized, 0.15)

// Apply to material
toonMaterial.colorNode = baseColor.mul(lit)
```

### GLSL vs TSL Side by Side

**GLSL version — stripes:**

```glsl
varying vec2 vUv;

void main() {
  float stripes = step(0.5, fract(vUv.y * 10.0));
  vec3 color = mix(vec3(0.2, 0.2, 0.8), vec3(0.8, 0.8, 1.0), stripes);
  gl_FragColor = vec4(color, 1.0);
}
```

**TSL version — stripes:**

```tsx
import { uv, fract, step, mix, vec3, MeshBasicNodeMaterial } from 'three/tsl'

const stripeMaterial = new MeshBasicNodeMaterial()

const stripes = step(0.5, fract(uv().y.mul(10.0)))
const colorA = vec3(0.2, 0.2, 0.8)
const colorB = vec3(0.8, 0.8, 1.0)

stripeMaterial.colorNode = mix(colorA, colorB, stripes)
```

**GLSL version — animated pulse:**

```glsl
uniform float uTime;
varying vec2 vUv;

void main() {
  float pulse = sin(uTime * 3.0) * 0.5 + 0.5;
  vec3 color = mix(vec3(0.1, 0.0, 0.3), vec3(1.0, 0.5, 0.0), pulse);
  gl_FragColor = vec4(color, 1.0);
}
```

**TSL version — animated pulse:**

```tsx
import { time, sin, mix, vec3, MeshBasicNodeMaterial } from 'three/tsl'

const pulseMaterial = new MeshBasicNodeMaterial()

const pulse = sin(time.mul(3.0)).mul(0.5).add(0.5)
const dark = vec3(0.1, 0.0, 0.3)
const bright = vec3(1.0, 0.5, 0.0)

pulseMaterial.colorNode = mix(dark, bright, pulse)
```

### Current Status and When to Use TSL

TSL is production-ready in Three.js r170+ and is the recommended path when using `WebGPURenderer`. Key considerations:

- **Use TSL when:** you're building with `WebGPURenderer`, you want cross-backend shaders, or you want type-safe composable shader logic.
- **Use GLSL when:** you're on `WebGLRenderer` (still the default in R3F), you're porting Shadertoy code, or you want maximum community resources and examples.
- **R3F integration:** TSL materials can be used in R3F by creating them imperatively and passing them to the `material` prop of a `<mesh>`. The `drei` ecosystem primarily uses GLSL-based approaches as of now.

```tsx
// Using a TSL material in R3F
import { useMemo } from 'react'
import { MeshBasicNodeMaterial } from 'three/webgpu'
import { uv, sin, time, vec3, mix } from 'three/tsl'

function TSLMesh() {
  const material = useMemo(() => {
    const mat = new MeshBasicNodeMaterial()
    const pulse = sin(time.mul(2.0)).mul(0.5).add(0.5)
    mat.colorNode = mix(vec3(0.0, 0.3, 0.8), vec3(1.0, 0.6, 0.0), pulse)
    return mat
  }, [])

  return (
    <mesh material={material}>
      <sphereGeometry args={[1, 32, 32]} />
    </mesh>
  )
}
```

For this module's mini-project, we'll use GLSL since it works with the standard R3F `WebGLRenderer` setup. But be aware that TSL is where Three.js is heading.

---

## 12. Drei Shader Helpers

### `shaderMaterial` — Reusable Custom Materials

Drei's `shaderMaterial` helper creates a reusable material class from GLSL code. Instead of repeating `<shaderMaterial>` with inline strings everywhere, you define the material once and reuse it like a built-in material:

```tsx
import { shaderMaterial } from '@react-three/drei'
import { extend } from '@react-three/fiber'
import * as THREE from 'three'

// Define the material OUTSIDE your component (runs once)
const PulseMaterial = shaderMaterial(
  // Uniforms with defaults
  {
    uTime: 0,
    uColor: new THREE.Color('#ff6600'),
    uIntensity: 1.0,
  },
  // Vertex shader
  `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  // Fragment shader
  `
    uniform float uTime;
    uniform vec3 uColor;
    uniform float uIntensity;
    varying vec2 vUv;

    void main() {
      float pulse = sin(uTime * 3.0) * 0.5 + 0.5;
      vec3 color = uColor * (0.5 + pulse * uIntensity);
      gl_FragColor = vec4(color, 1.0);
    }
  `
)

// Register as a JSX element
extend({ PulseMaterial })

// Declare the type for TypeScript
declare module '@react-three/fiber' {
  interface ThreeElements {
    pulseMaterial: JSX.IntrinsicElements['shaderMaterial'] & {
      uTime?: number
      uColor?: THREE.Color
      uIntensity?: number
    }
  }
}

// Now use it like a built-in material
function PulsingMesh() {
  const materialRef = useRef<typeof PulseMaterial & THREE.ShaderMaterial>(null)

  useFrame(({ clock }) => {
    if (!materialRef.current) return
    materialRef.current.uTime = clock.getElapsedTime()
  })

  return (
    <mesh>
      <sphereGeometry args={[1, 32, 32]} />
      <pulseMaterial ref={materialRef} uColor={new THREE.Color('#e74c3c')} />
    </mesh>
  )
}
```

The key advantage: uniforms become direct props. No more `material.uniforms.uTime.value = ...` — just `material.uTime = ...`. Cleaner API, less boilerplate.

### `MeshDistortMaterial`

Distorts a mesh's geometry using simplex noise. Great for organic, blobby shapes.

```tsx
import { MeshDistortMaterial } from '@react-three/drei'

<mesh>
  <sphereGeometry args={[1, 64, 64]} />
  <MeshDistortMaterial
    color="#8844ee"
    distort={0.4}    // Distortion amount (0-1)
    speed={2}        // Animation speed
    roughness={0.2}
  />
</mesh>
```

### `MeshWobbleMaterial`

Wobbles the mesh vertices with a sine wave. Simpler than distort, good for jelly/wobbly effects.

```tsx
import { MeshWobbleMaterial } from '@react-three/drei'

<mesh>
  <boxGeometry args={[2, 2, 2]} />
  <MeshWobbleMaterial
    color="#44cc88"
    factor={1}      // Wobble amplitude
    speed={2}       // Wobble speed
    roughness={0.3}
  />
</mesh>
```

### `MeshTransmissionMaterial`

Advanced glass/transmission material with physically accurate refraction. Much easier than writing your own transmission shader.

```tsx
import { MeshTransmissionMaterial } from '@react-three/drei'

<mesh>
  <sphereGeometry args={[1, 64, 64]} />
  <MeshTransmissionMaterial
    backside
    thickness={0.5}
    chromaticAberration={0.5}
    anisotropy={0.3}
    distortion={0.2}
    distortionScale={0.3}
    temporalDistortion={0.1}
  />
</mesh>
```

### When to Use Drei Materials vs Custom Shaders

| Scenario | Use |
|----------|-----|
| You need a quick wobbly/distorted effect | `MeshDistortMaterial` / `MeshWobbleMaterial` |
| You need glass/refraction | `MeshTransmissionMaterial` |
| You want a reusable custom material with clean API | `shaderMaterial` helper |
| You need full control over the shader pipeline | Raw `<shaderMaterial>` with inline GLSL |

---

## Code Walkthrough: Character Showcase with 3 Material Modes

This is the mini-project. You'll build a scene with a shape (torus knot — it shows off lighting and shading beautifully) and three swappable material modes: **Toon**, **Watercolor**, and **Holographic**. Keyboard or button toggle switches between them.

### Project Structure

```
shader-showcase/
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   ├── index.css
│   ├── shaders/
│   │   ├── toon.ts          # Toon shader GLSL strings
│   │   ├── watercolor.ts    # Watercolor shader GLSL strings
│   │   └── holographic.ts   # Holographic shader GLSL strings
│   └── components/
│       ├── Showcase.tsx      # Main showcase with mode toggle
│       ├── ToonMaterial.tsx
│       ├── WatercolorMaterial.tsx
│       ├── HolographicMaterial.tsx
│       └── OutlinePass.tsx
├── public/
│   └── textures/
│       └── paper.jpg        # Optional paper texture for watercolor
```

### Step 1: Shared Noise (Used by Watercolor and Holographic)

```ts
// src/shaders/noise.ts
export const NOISE_GLSL = `
vec2 hash22(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)),
           dot(p, vec2(269.5, 183.3)));
  return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise2D(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(
    mix(dot(hash22(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
        dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
    mix(dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
        dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
    u.y
  );
}

float fbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  float frequency = 1.0;
  for (int i = 0; i < 5; i++) {
    value += amplitude * noise2D(p * frequency);
    frequency *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}
`
```

### Step 2: Toon Shader

```ts
// src/shaders/toon.ts
export const TOON_VERT = `
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vUv;
varying vec3 vWorldPos;

void main() {
  vUv = uv;
  vNormal = normalize(normalMatrix * normal);

  vec4 worldPos = modelMatrix * vec4(position, 1.0);
  vWorldPos = worldPos.xyz;
  vViewDir = normalize(cameraPosition - worldPos.xyz);

  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`

export const TOON_FRAG = `
uniform vec3 uColor;
uniform vec3 uLightDir;
uniform float uBands;
uniform float uRimPower;
uniform float uRimIntensity;
uniform vec3 uShadowColor;
uniform vec3 uHighlightColor;

varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vUv;
varying vec3 vWorldPos;

void main() {
  vec3 normal = normalize(vNormal);
  vec3 lightDir = normalize(uLightDir);
  vec3 viewDir = normalize(vViewDir);

  // Diffuse: quantized into bands
  float NdotL = dot(normal, lightDir);
  float diffuse = max(NdotL, 0.0);
  diffuse = floor(diffuse * uBands + 0.5) / uBands;

  // Color: blend between shadow and lit color
  vec3 shadedColor = mix(uShadowColor * uColor, uColor, diffuse);

  // Specular band (hard highlight)
  vec3 halfDir = normalize(lightDir + viewDir);
  float specular = dot(normal, halfDir);
  specular = step(0.92, specular); // Hard specular cutoff
  shadedColor = mix(shadedColor, uHighlightColor, specular * 0.5);

  // Rim light (fresnel)
  float rimDot = 1.0 - max(dot(viewDir, normal), 0.0);
  float rim = pow(rimDot, uRimPower) * uRimIntensity;
  shadedColor += vec3(rim) * uColor;

  gl_FragColor = vec4(shadedColor, 1.0);
}
`
```

### Step 3: Watercolor Shader

```ts
// src/shaders/watercolor.ts
import { NOISE_GLSL } from './noise'

export const WATERCOLOR_VERT = `
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vUv;
varying vec3 vWorldPos;

void main() {
  vUv = uv;
  vNormal = normalize(normalMatrix * normal);

  vec4 worldPos = modelMatrix * vec4(position, 1.0);
  vWorldPos = worldPos.xyz;
  vViewDir = normalize(cameraPosition - worldPos.xyz);

  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`

export const WATERCOLOR_FRAG = `
uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
uniform float uEdgeDistortion;
uniform float uPaperStrength;
uniform vec3 uPaperTint;

varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vUv;
varying vec3 vWorldPos;

${NOISE_GLSL}

void main() {
  vec3 normal = normalize(vNormal);
  vec3 lightDir = normalize(uLightDir);

  // --- Distorted UVs for that wobbly watercolor feel ---
  float distortX = noise2D(vUv * 8.0 + uTime * 0.15) * uEdgeDistortion;
  float distortY = noise2D(vUv * 8.0 + vec2(100.0) + uTime * 0.15) * uEdgeDistortion;
  vec2 distortedUv = vUv + vec2(distortX, distortY);

  // --- Soft diffuse lighting with quantization ---
  float NdotL = dot(normal, lightDir);
  float diffuse = max(NdotL, 0.0);

  // Soft bands — smoother than toon, fewer harsh edges
  diffuse = smoothstep(0.0, 0.05, diffuse) * 0.3 +
            smoothstep(0.3, 0.35, diffuse) * 0.3 +
            smoothstep(0.6, 0.65, diffuse) * 0.4;
  diffuse = max(diffuse, 0.2);

  // --- Base color with noise variation (pigment density) ---
  float pigment = fbm(distortedUv * 6.0);
  vec3 baseColor = uColor * (0.8 + pigment * 0.4);

  // --- Paper texture simulation ---
  float paper = noise2D(vUv * 30.0);
  paper = paper * 0.5 + 0.5;
  paper = pow(paper, 0.8);

  // --- Soft edges: fade near silhouette edges ---
  float edgeFade = dot(normalize(vViewDir), normal);
  edgeFade = smoothstep(0.0, 0.4, edgeFade);

  // Add noise to the edge for irregular watercolor bleed
  float edgeNoise = noise2D(vUv * 15.0 + uTime * 0.1);
  edgeFade = edgeFade + edgeNoise * 0.1;
  edgeFade = clamp(edgeFade, 0.0, 1.0);

  // --- Combine everything ---
  vec3 litColor = baseColor * diffuse;

  // Mix in paper texture
  vec3 withPaper = mix(litColor, litColor * uPaperTint, (1.0 - paper) * uPaperStrength);

  // Apply edge fade
  vec3 finalColor = mix(uPaperTint * 0.9, withPaper, edgeFade);

  // Slight warm/cool variation (watercolor bleeds)
  float warmCool = noise2D(distortedUv * 3.0 + vec2(uTime * 0.05));
  finalColor += vec3(warmCool * 0.05, warmCool * 0.02, -warmCool * 0.03);

  gl_FragColor = vec4(finalColor, 1.0);
}
`
```

### Step 4: Holographic Shader

```ts
// src/shaders/holographic.ts
import { NOISE_GLSL } from './noise'

export const HOLO_VERT = `
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vUv;
varying vec3 vWorldPos;
varying vec3 vLocalPos;

void main() {
  vUv = uv;
  vNormal = normalize(normalMatrix * normal);
  vLocalPos = position;

  vec4 worldPos = modelMatrix * vec4(position, 1.0);
  vWorldPos = worldPos.xyz;
  vViewDir = normalize(cameraPosition - worldPos.xyz);

  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`

export const HOLO_FRAG = `
uniform float uTime;
uniform vec3 uBaseColor;
uniform float uFresnelPower;
uniform float uFresnelIntensity;
uniform float uScanlineSpeed;
uniform float uScanlineDensity;
uniform float uScanlineIntensity;
uniform float uAberrationStrength;
uniform float uAlpha;
uniform float uFlickerSpeed;

varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vUv;
varying vec3 vWorldPos;
varying vec3 vLocalPos;

${NOISE_GLSL}

void main() {
  vec3 normal = normalize(vNormal);
  vec3 viewDir = normalize(vViewDir);

  // --- Fresnel (edge glow) ---
  float fresnel = 1.0 - max(dot(viewDir, normal), 0.0);
  fresnel = pow(fresnel, uFresnelPower) * uFresnelIntensity;

  // --- Scanlines ---
  float scanY = vLocalPos.y * uScanlineDensity + uTime * uScanlineSpeed;
  float scanline = sin(scanY) * 0.5 + 0.5;
  scanline = pow(scanline, 2.0) * uScanlineIntensity;

  // --- Chromatic aberration ---
  // Shift the "color channels" based on view angle
  float aberration = fresnel * uAberrationStrength;
  vec3 colorR = uBaseColor + vec3(aberration, -aberration * 0.5, -aberration);
  vec3 colorG = uBaseColor + vec3(-aberration * 0.5, aberration, -aberration * 0.5);
  vec3 colorB = uBaseColor + vec3(-aberration, -aberration * 0.5, aberration);

  // Combine the shifted channels using view-dependent weights
  float angle = dot(viewDir, normal);
  vec3 chromatic = mix(colorR, colorG, smoothstep(0.0, 0.5, angle));
  chromatic = mix(chromatic, colorB, smoothstep(0.3, 0.8, angle));

  // --- Noise shimmer ---
  float shimmer = noise2D(vUv * 15.0 + uTime * 2.0);
  shimmer = shimmer * 0.5 + 0.5;

  // --- Flicker ---
  float flicker = sin(uTime * uFlickerSpeed) * 0.05 + 0.95;

  // --- Combine ---
  vec3 color = chromatic;
  color += vec3(fresnel * 0.5, fresnel * 0.7, fresnel * 1.0); // Blue-ish fresnel glow
  color += scanline * vec3(0.1, 0.3, 0.5); // Scanline tint
  color += shimmer * 0.08; // Subtle sparkle
  color *= flicker;

  // Alpha: more transparent in center, opaque at edges (fresnel)
  float alpha = uAlpha * (0.3 + fresnel * 0.7 + scanline * 0.2);

  gl_FragColor = vec4(color, alpha);
}
`
```

### Step 5: Outline Pass Component

```tsx
// src/components/OutlinePass.tsx
import * as THREE from 'three'

interface OutlinePassProps {
  width?: number
  color?: string
}

export function OutlinePass({ width = 0.03, color = '#000000' }: OutlinePassProps) {
  return (
    <shaderMaterial
      vertexShader={`
        uniform float uOutlineWidth;

        void main() {
          vec3 pos = position + normal * uOutlineWidth;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
        }
      `}
      fragmentShader={`
        uniform vec3 uOutlineColor;

        void main() {
          gl_FragColor = vec4(uOutlineColor, 1.0);
        }
      `}
      uniforms={{
        uOutlineWidth: { value: width },
        uOutlineColor: { value: new THREE.Color(color) },
      }}
      side={THREE.BackSide}
    />
  )
}
```

### Step 6: Material Components

```tsx
// src/components/ToonMaterial.tsx
import { useRef } from 'react'
import * as THREE from 'three'
import { TOON_VERT, TOON_FRAG } from '../shaders/toon'

export function ToonMaterial() {
  const ref = useRef<THREE.ShaderMaterial>(null)

  return (
    <shaderMaterial
      ref={ref}
      vertexShader={TOON_VERT}
      fragmentShader={TOON_FRAG}
      uniforms={{
        uColor: { value: new THREE.Color('#e74c3c') },
        uLightDir: { value: new THREE.Vector3(1, 1, 0.5).normalize() },
        uBands: { value: 4.0 },
        uRimPower: { value: 3.0 },
        uRimIntensity: { value: 0.5 },
        uShadowColor: { value: new THREE.Color('#2c1810') },
        uHighlightColor: { value: new THREE.Color('#ffffff') },
      }}
    />
  )
}
```

```tsx
// src/components/WatercolorMaterial.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'
import { WATERCOLOR_VERT, WATERCOLOR_FRAG } from '../shaders/watercolor'

export function WatercolorMaterial() {
  const ref = useRef<THREE.ShaderMaterial>(null)

  useFrame(({ clock }) => {
    if (!ref.current) return
    ref.current.uniforms.uTime.value = clock.getElapsedTime()
  })

  return (
    <shaderMaterial
      ref={ref}
      vertexShader={WATERCOLOR_VERT}
      fragmentShader={WATERCOLOR_FRAG}
      uniforms={{
        uTime: { value: 0 },
        uColor: { value: new THREE.Color('#3498db') },
        uLightDir: { value: new THREE.Vector3(1, 1, 0.5).normalize() },
        uEdgeDistortion: { value: 0.03 },
        uPaperStrength: { value: 0.4 },
        uPaperTint: { value: new THREE.Color('#f5f0e8') },
      }}
    />
  )
}
```

```tsx
// src/components/HolographicMaterial.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'
import { HOLO_VERT, HOLO_FRAG } from '../shaders/holographic'

export function HolographicMaterial() {
  const ref = useRef<THREE.ShaderMaterial>(null)

  useFrame(({ clock }) => {
    if (!ref.current) return
    ref.current.uniforms.uTime.value = clock.getElapsedTime()
  })

  return (
    <shaderMaterial
      ref={ref}
      vertexShader={HOLO_VERT}
      fragmentShader={HOLO_FRAG}
      uniforms={{
        uTime: { value: 0 },
        uBaseColor: { value: new THREE.Color('#00aaff') },
        uFresnelPower: { value: 2.5 },
        uFresnelIntensity: { value: 1.2 },
        uScanlineSpeed: { value: 2.0 },
        uScanlineDensity: { value: 30.0 },
        uScanlineIntensity: { value: 0.4 },
        uAberrationStrength: { value: 0.3 },
        uAlpha: { value: 0.85 },
        uFlickerSpeed: { value: 15.0 },
      }}
      transparent
      side={THREE.DoubleSide}
      depthWrite={false}
      blending={THREE.AdditiveBlending}
    />
  )
}
```

### Step 7: The Showcase Component

```tsx
// src/components/Showcase.tsx
import { useState, useEffect, useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { Html } from '@react-three/drei'
import * as THREE from 'three'
import { ToonMaterial } from './ToonMaterial'
import { WatercolorMaterial } from './WatercolorMaterial'
import { HolographicMaterial } from './HolographicMaterial'
import { OutlinePass } from './OutlinePass'

type MaterialMode = 'toon' | 'watercolor' | 'holographic'

const MODE_LABELS: Record<MaterialMode, string> = {
  toon: 'Toon / Cel-Shaded',
  watercolor: 'Watercolor',
  holographic: 'Holographic',
}

const MODE_ORDER: MaterialMode[] = ['toon', 'watercolor', 'holographic']

export function Showcase() {
  const [mode, setMode] = useState<MaterialMode>('toon')
  const meshRef = useRef<THREE.Mesh>(null)

  // Keyboard toggle: 1, 2, 3 or left/right arrows
  useEffect(() => {
    function handleKey(e: KeyboardEvent) {
      if (e.key === '1') setMode('toon')
      if (e.key === '2') setMode('watercolor')
      if (e.key === '3') setMode('holographic')
      if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
        setMode((prev) => {
          const idx = MODE_ORDER.indexOf(prev)
          const next = e.key === 'ArrowRight'
            ? (idx + 1) % MODE_ORDER.length
            : (idx - 1 + MODE_ORDER.length) % MODE_ORDER.length
          return MODE_ORDER[next]
        })
      }
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [])

  // Slow rotation
  useFrame((_, delta) => {
    if (!meshRef.current) return
    meshRef.current.rotation.y += delta * 0.3
  })

  return (
    <group>
      {/* Main mesh with swappable material */}
      <mesh ref={meshRef}>
        <torusKnotGeometry args={[1, 0.4, 256, 64]} />
        {mode === 'toon' && <ToonMaterial />}
        {mode === 'watercolor' && <WatercolorMaterial />}
        {mode === 'holographic' && <HolographicMaterial />}
      </mesh>

      {/* Outline — only for toon mode */}
      {mode === 'toon' && (
        <mesh rotation={meshRef.current?.rotation.toArray().slice(0, 3) as [number, number, number] || [0, 0, 0]}>
          <torusKnotGeometry args={[1, 0.4, 256, 64]} />
          <OutlinePass width={0.025} color="#1a0a05" />
        </mesh>
      )}

      {/* UI overlay */}
      <Html position={[0, -2.5, 0]} center>
        <div style={{
          display: 'flex',
          gap: '8px',
          background: 'rgba(0, 0, 0, 0.7)',
          padding: '12px 20px',
          borderRadius: '8px',
          fontFamily: 'system-ui, sans-serif',
          userSelect: 'none',
        }}>
          {MODE_ORDER.map((m, i) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              style={{
                padding: '8px 16px',
                background: mode === m ? '#ffffff' : 'rgba(255,255,255,0.15)',
                color: mode === m ? '#000000' : '#ffffff',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer',
                fontSize: '13px',
                fontWeight: mode === m ? 700 : 400,
              }}
            >
              {i + 1}. {MODE_LABELS[m]}
            </button>
          ))}
        </div>
      </Html>
    </group>
  )
}
```

### Step 8: Fixing the Outline Rotation Sync

The outline mesh needs to rotate in sync with the main mesh. The cleanest approach is to share a parent group:

```tsx
// Improved version — parent group handles rotation
export function Showcase() {
  const [mode, setMode] = useState<MaterialMode>('toon')
  const groupRef = useRef<THREE.Group>(null)

  useEffect(() => {
    function handleKey(e: KeyboardEvent) {
      if (e.key === '1') setMode('toon')
      if (e.key === '2') setMode('watercolor')
      if (e.key === '3') setMode('holographic')
      if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
        setMode((prev) => {
          const idx = MODE_ORDER.indexOf(prev)
          const next = e.key === 'ArrowRight'
            ? (idx + 1) % MODE_ORDER.length
            : (idx - 1 + MODE_ORDER.length) % MODE_ORDER.length
          return MODE_ORDER[next]
        })
      }
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [])

  useFrame((_, delta) => {
    if (!groupRef.current) return
    groupRef.current.rotation.y += delta * 0.3
  })

  const geometry = <torusKnotGeometry args={[1, 0.4, 256, 64]} />

  return (
    <group>
      <group ref={groupRef}>
        {/* Main mesh */}
        <mesh>
          {geometry}
          {mode === 'toon' && <ToonMaterial />}
          {mode === 'watercolor' && <WatercolorMaterial />}
          {mode === 'holographic' && <HolographicMaterial />}
        </mesh>

        {/* Outline — toon mode only */}
        {mode === 'toon' && (
          <mesh>
            {geometry}
            <OutlinePass width={0.025} color="#1a0a05" />
          </mesh>
        )}
      </group>

      {/* UI */}
      <Html position={[0, -2.5, 0]} center>
        <div style={{
          display: 'flex',
          gap: '8px',
          background: 'rgba(0, 0, 0, 0.7)',
          padding: '12px 20px',
          borderRadius: '8px',
          fontFamily: 'system-ui, sans-serif',
          userSelect: 'none',
        }}>
          {MODE_ORDER.map((m, i) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              style={{
                padding: '8px 16px',
                background: mode === m ? '#ffffff' : 'rgba(255,255,255,0.15)',
                color: mode === m ? '#000000' : '#ffffff',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer',
                fontSize: '13px',
                fontWeight: mode === m ? 700 : 400,
              }}
            >
              {i + 1}. {MODE_LABELS[m]}
            </button>
          ))}
        </div>
      </Html>
    </group>
  )
}
```

### Step 9: App and Entry Point

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { OrbitControls, Environment } from '@react-three/drei'
import { Showcase } from './components/Showcase'

export default function App() {
  return (
    <Canvas
      camera={{ position: [0, 1, 4], fov: 50 }}
      gl={{ antialias: true }}
    >
      <color attach="background" args={['#1a1a2e']} />

      {/* Ambient fill for the non-shader-lit modes */}
      <ambientLight intensity={0.3} />
      <directionalLight position={[3, 5, 2]} intensity={1.5} />

      <Showcase />

      <OrbitControls
        enableDamping
        dampingFactor={0.05}
        minDistance={2}
        maxDistance={10}
      />
    </Canvas>
  )
}
```

```css
/* src/index.css */
html,
body,
#root {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: #1a1a2e;
}
```

```tsx
// src/main.tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

### Running It

```bash
npm create vite@latest shader-showcase -- --template react-ts
cd shader-showcase
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three
npm run dev
```

Press **1**, **2**, **3** or use the arrow keys to switch between Toon, Watercolor, and Holographic modes. Click and drag to orbit. Each mode demonstrates a fundamentally different shader approach — quantized lighting, noise-distorted painting, and fresnel-driven sci-fi.

---

## Common Pitfalls

### 1. Forgetting Precision in Fragment Shader

Some devices (especially mobile) require an explicit precision declaration in the fragment shader. Three.js usually injects this for you when using `shaderMaterial`, but if you ever see a blank screen on mobile, this is likely why.

```glsl
// WRONG — may fail on mobile GPUs that need explicit precision
varying vec2 vUv;
void main() {
  gl_FragColor = vec4(vUv, 0.0, 1.0);
}

// RIGHT — explicit precision (or rely on Three.js to inject it, which it does for shaderMaterial)
precision highp float;
varying vec2 vUv;
void main() {
  gl_FragColor = vec4(vUv, 0.0, 1.0);
}
```

In practice, Three.js prepends precision for `<shaderMaterial>`, so this mostly matters if you're compiling shaders manually. But know it exists.

### 2. Uniform Names Not Matching Between JS and GLSL

The uniform name in your GLSL code must exactly match the key in your `uniforms` object. Mismatches fail silently — no error, the uniform just stays at its default (usually 0).

```tsx
// WRONG — JS says "time", GLSL says "uTime"
uniforms={{ time: { value: 0 } }}
// In GLSL: uniform float uTime; ← never receives the value!

// RIGHT — names must match exactly
uniforms={{ uTime: { value: 0 } }}
// In GLSL: uniform float uTime; ← works
```

### 3. Not Updating Uniforms in useFrame

You define `uTime` as a uniform, but it stays at 0 forever because you forgot to update it in `useFrame`. The shader compiles, the mesh renders, but nothing animates.

```tsx
// WRONG — uniform is set once and never updated
<shaderMaterial
  uniforms={{ uTime: { value: 0 } }}
  fragmentShader={`
    uniform float uTime;
    // ...sin(uTime)... ← always 0
  `}
/>

// RIGHT — update in useFrame every frame
const ref = useRef<THREE.ShaderMaterial>(null)

useFrame(({ clock }) => {
  if (!ref.current) return
  ref.current.uniforms.uTime.value = clock.getElapsedTime()
})

<shaderMaterial ref={ref} uniforms={{ uTime: { value: 0 } }} /* ... */ />
```

### 4. Using ShaderMaterial When drei's shaderMaterial Would Be Cleaner

If you're reusing the same custom shader in multiple places, raw `<shaderMaterial>` with repeated uniform objects is messy. Use drei's `shaderMaterial` helper to create a typed, reusable material with prop-based uniforms.

```tsx
// WRONG — copy-pasting the same shader strings and uniforms everywhere
<mesh>
  <shaderMaterial vertexShader={VERT} fragmentShader={FRAG} uniforms={{ uTime: { value: 0 }, uColor: { value: new THREE.Color('red') } }} />
</mesh>
<mesh>
  <shaderMaterial vertexShader={VERT} fragmentShader={FRAG} uniforms={{ uTime: { value: 0 }, uColor: { value: new THREE.Color('blue') } }} />
</mesh>

// RIGHT — define once with shaderMaterial, use as a JSX element
const MyMaterial = shaderMaterial({ uTime: 0, uColor: new THREE.Color('red') }, VERT, FRAG)
extend({ MyMaterial })

// Now reuse cleanly:
<mesh><myMaterial uColor={new THREE.Color('red')} /></mesh>
<mesh><myMaterial uColor={new THREE.Color('blue')} /></mesh>
```

### 5. Normal Calculation Errors in the Vertex Shader

If your lighting looks wrong — inverted, stuck to the camera, or just broken — you're probably transforming normals incorrectly. Normals must be transformed by the `normalMatrix`, not the `modelViewMatrix`.

```glsl
// WRONG — normals scaled/skewed by model transforms
vNormal = (modelViewMatrix * vec4(normal, 0.0)).xyz;

// WRONG — forgetting to transform at all
vNormal = normal; // Only works if the mesh has no rotation or non-uniform scale

// RIGHT — use normalMatrix (handles rotation + non-uniform scale correctly)
vNormal = normalize(normalMatrix * normal);
```

### 6. Color Space Issues (Linear vs sRGB)

Three.js renders in linear color space internally and converts to sRGB for display. Your shader outputs are in linear space. If your colors look washed out or too dark, you might be double-converting or not accounting for the color space.

```glsl
// WRONG — manually gamma-correcting when Three.js already does it
gl_FragColor = vec4(pow(color, vec3(1.0/2.2)), 1.0); // Double gamma = washed out

// RIGHT — output linear color, let Three.js handle the conversion
gl_FragColor = vec4(color, 1.0);
```

If colors from `uniform vec3 uColor` (set via `new THREE.Color('#ff0000')`) look wrong, it's because `THREE.Color` stores sRGB values but the shader expects linear. Three.js handles this automatically for built-in materials but not for custom shaders. You may need:

```tsx
// Convert color to linear space before passing to shader
const color = new THREE.Color('#ff0000').convertSRGBToLinear()
```

---

## Exercises

### Exercise 1: Pulsing Glow Shader

**Time:** 30–40 minutes

Build a shader where the emissive intensity pulses over time using a sine wave. The mesh should smoothly glow brighter and dimmer.

Requirements:
- Use `sin(uTime * speed) * 0.5 + 0.5` to create a 0-to-1 pulse
- Apply the pulse to the output color's brightness
- Add a `uGlowColor` uniform separate from the base color
- The glow should be additive — `baseColor + glowColor * pulse`

Hints:
- Start with `meshBasicMaterial`-style output (no lighting needed)
- Use `mix` between a dim version and a bright version of the color
- Try `pow(pulse, 2.0)` for a sharper pulse that spends more time dim

**Stretch goal:** Make the glow pulse from the center of the mesh outward using `distance(vUv, vec2(0.5))` as an offset to the sine wave.

### Exercise 2: Dissolve Effect

**Time:** 45–60 minutes

Create a dissolve shader that reveals or hides the mesh using a noise threshold. The effect should look like the mesh is burning away from random points.

Requirements:
- Generate noise from UV coordinates using the noise function from Section 7
- Compare the noise value to a `uDissolveThreshold` uniform (0.0 = fully visible, 1.0 = fully dissolved)
- Use `discard` in the fragment shader to skip pixels where noise < threshold
- Add a glowing edge at the dissolve boundary

The core logic:

```glsl
float n = noise2D(vUv * 8.0);
float edge = smoothstep(uThreshold - 0.05, uThreshold, n);

if (n < uThreshold) discard;

// Glowing edge
vec3 edgeGlow = vec3(1.0, 0.3, 0.0) * (1.0 - edge) * 3.0;
vec3 finalColor = baseColor + edgeGlow;
```

Hints:
- Animate `uDissolveThreshold` from 0 to 1 over time in `useFrame`
- Use `fbm` instead of raw noise for more organic dissolve patterns
- The `discard` keyword completely skips the pixel — it won't be drawn at all

**Stretch goal:** Add a second noise layer for the edge glow color, so the burning edge shifts between orange and blue.

### Exercise 3: Force Field Shader

**Time:** 45–60 minutes

Build a transparent force field effect with fresnel glow, animated noise patterns, and a hexagonal grid overlay.

Requirements:
- Fresnel for edge glow (bright at glancing angles, transparent when facing camera)
- Animated noise for the energy pattern
- Semi-transparent (use `transparent: true` and output alpha < 1)
- Additive blending for the glow

```glsl
// Hexagonal grid pattern
float hexGrid(vec2 p) {
  vec2 r = vec2(1.0, 1.732);
  vec2 h = r * 0.5;
  vec2 a = mod(p, r) - h;
  vec2 b = mod(p - h, r) - h;
  return min(dot(a, a), dot(b, b));
}
```

Hints:
- Start with the holographic shader as a base and modify it
- Use `blending: THREE.AdditiveBlending` and `depthWrite: false`
- The hex grid function returns distance to the nearest hex edge — use `step` or `smoothstep` to create lines

**Stretch goal:** Add an "impact" point — a uniform `vec3 uImpactPoint` where the force field brightens and ripples outward over time.

### Exercise 4: Port a GLSL Shader to TSL

**Time:** 30–45 minutes

Take the pulsing glow shader (Exercise 1) or the stripe procedural texture from Section 10, and rewrite it using TSL nodes.

Requirements:
- Create a `MeshBasicNodeMaterial`
- Use TSL functions (`sin`, `time`, `mix`, `uv`, `vec3`) to replicate the same visual
- Compare the GLSL version and TSL version side by side

Hints:
- Import TSL functions from `three/tsl`
- `time` in TSL auto-updates — no `useFrame` needed for time-based uniforms
- TSL uses method chaining: `sin(time.mul(3.0)).mul(0.5).add(0.5)`

**Note:** TSL works best with `WebGPURenderer`. If you're on the standard R3F `WebGLRenderer`, the imports may differ. Check the Three.js docs for your version.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [The Book of Shaders](https://thebookofshaders.com) | Interactive Tutorial | The best introduction to fragment shaders. Work through chapters 1–10. |
| [Shadertoy](https://www.shadertoy.com) | Community / Tool | Thousands of shader examples. Search for any effect and study the code. |
| [Three.js ShaderMaterial Docs](https://threejs.org/docs/#api/en/materials/ShaderMaterial) | Official Docs | Reference for all ShaderMaterial properties and built-in uniforms/attributes. |
| [Three.js TSL Docs](https://threejs.org/docs/pages/TSL.html) | Official Docs | The official TSL guide — node types, composition patterns, examples. |
| ["An Introduction to Shader Art Coding" by kishimisu](https://www.youtube.com/watch?v=f4s1h2YETNY) | YouTube | Excellent visual walkthrough of shader fundamentals. 20 minutes well spent. |
| [Inigo Quilez — Articles](https://iquilezles.org/articles/) | Blog | Deep dives on noise, SDF, raymarching, and every technique used in Shadertoy. The reference site for shader math. |
| [drei shaderMaterial source](https://github.com/pmndrs/drei/blob/master/src/core/shaderMaterial.tsx) | Code | Read how drei's `shaderMaterial` helper works under the hood. Short and educational. |

---

## Key Takeaways

1. **The GPU pipeline is vertex shader, rasterizer, fragment shader.** The vertex shader positions vertices on screen. The rasterizer fills in the pixels between them. The fragment shader colors each pixel. Attributes flow in, uniforms are constant, varyings bridge vertex to fragment.

2. **Uniforms connect your React code to the GPU.** Define them in GLSL, initialize them in the `uniforms` prop, update them in `useFrame`. Names must match exactly. Mismatches fail silently.

3. **Six GLSL functions cover 90% of shader effects:** `mix` for blending, `smoothstep` for soft transitions, `step` for hard cutoffs, `fract` for repetition, `dot` for lighting, and `sin` for animation. Master these and you can build almost anything.

4. **Noise is the foundation of organic effects.** Without noise, everything looks mechanical. With noise, you get watercolor bleeds, dissolve patterns, force field shimmer, terrain, clouds — anything natural.

5. **Cel-shading is just quantized lighting.** Compute `dot(normal, lightDir)`, snap it to bands with `floor`, add fresnel rim light. That's it. The simplicity is what makes it elegant.

6. **TSL is the future, GLSL is the present.** TSL gives you type-safe, composable, cross-backend shader authoring in TypeScript. GLSL gives you maximum community resources and works everywhere today. Know both, choose per-project.

7. **drei's `shaderMaterial` helper turns custom shaders into reusable JSX elements.** Define the material once, extend it, use it like `<myMaterial uColor={...} />`. Much cleaner than raw `<shaderMaterial>` when you reuse a shader.

---

## What's Next?

You now have the power to make anything look however you want. Every visual style is within reach. But shaders are just one axis of game visuals — the other is the world itself.

**[Module 7: Environmental Storytelling & Level Design](module-07-environmental-storytelling-level-design.md)** takes your shader skills and applies them to building complete game environments — terrain, skyboxes, fog, particles, lighting design, and the art of making a space feel alive. You'll build a complete stylized environment that combines everything from this module with spatial design.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)