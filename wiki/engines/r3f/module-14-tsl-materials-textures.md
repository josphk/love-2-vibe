# Module 14: TSL Materials & Textures

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 8–12 hours
**Prerequisites:** [Module 6: Shaders & Stylized Rendering](module-06-shaders-stylized-rendering.md), [Module 12: WebGPU & The Cutting Edge](module-12-webgpu-cutting-edge.md)

---

## Overview

In Module 6 you wrote shaders as raw GLSL strings — vertex and fragment programs stitched together with template literals, uniforms passed as plain objects, and the constant risk of a typo that only surfaces as a black mesh at runtime. At the end of that module you got a preview of TSL (Three Shading Language): a way to compose shaders as TypeScript expressions instead of strings. In Module 12 you used TSL seriously for the first time, building node materials for your compute particle system.

This module takes TSL all the way. You'll stop treating it as a novelty and start treating it as your primary material authoring tool. That means learning the full node material slot system — every PBR parameter you can override, from `colorNode` to `iridescenceNode` — understanding how the lighting pipeline composes your overrides, and mastering the library of built-in nodes for noise, math, screen-space operations, and transforms. You'll work without a single texture image file. Everything — marble veins, wood grain, water caustics, fire, holograms, force fields — will be computed entirely on the GPU from noise functions and math.

The payoff is significant. Procedural materials are infinitely scalable (they look perfect at any zoom level), instantly tweakable (change a `uniform()` and the material updates live), trivially animatable (pass `time` into any noise function), and ship with zero texture asset overhead. By the end you'll have six production-quality procedural materials and a deep intuition for how to build any material from first principles — which is the skill that separates shader artists from people who just copy-paste from Shadertoy.

---

## 1. Node Material Architecture

### The Material Slot System

Three.js node materials work by letting you override specific slots in the PBR lighting pipeline. Instead of writing a monolithic fragment shader, you plug node expressions into named slots, and the lighting system handles compositing. This is the same mental model as a Blender Shader Editor node graph — you're wiring values into the lighting equation rather than computing it yourself.

Here are all the slots you'll work with:

| Slot | Type | What It Controls |
|------|------|-----------------|
| `colorNode` | `vec3` / `vec4` | Base diffuse color (albedo) |
| `emissiveNode` | `vec3` | Emissive light contribution (unlit glow) |
| `roughnessNode` | `float` | PBR roughness (0 = mirror, 1 = matte) |
| `metalnessNode` | `float` | PBR metalness (0 = dielectric, 1 = metal) |
| `normalNode` | `vec3` | Surface normal in view space (for normal mapping) |
| `positionNode` | `vec3` | Vertex position override (vertex displacement) |
| `opacityNode` | `float` | Transparency (0 = invisible, 1 = opaque) |
| `alphaTestNode` | `float` | Clip pixels below threshold (cutout transparency) |
| `outputNode` | `vec4` | Full override — bypasses ALL lighting, raw output |
| `aoNode` | `float` | Ambient occlusion contribution |
| `sheenNode` | `vec3` | Fabric sheen color |
| `sheenRoughnessNode` | `float` | Fabric sheen roughness |
| `clearcoatNode` | `float` | Clearcoat layer intensity |
| `clearcoatRoughnessNode` | `float` | Clearcoat roughness |
| `iorNode` | `float` | Index of refraction (glass, water) |
| `transmissionNode` | `float` | Physically-based transparency with refraction |
| `thicknessNode` | `float` | Volume thickness for transmission |
| `iridescenceNode` | `float` | Thin-film iridescence intensity |
| `iridescenceIORNode` | `float` | Thin-film IOR |
| `iridescenceThicknessNode` | `float` | Thin-film thickness |
| `envNode` | `texture` | Override the environment map |

### MeshStandardNodeMaterial vs MeshPhysicalNodeMaterial vs MeshBasicNodeMaterial

Pick the base material that matches the slots you need:

- **`MeshBasicNodeMaterial`** — No lighting at all. Use `colorNode` or `outputNode` to set color directly. Good for debug visualizations, UI quads, skyboxes, and any material where you want to bypass the lighting equation entirely. The cheapest option.

- **`MeshStandardNodeMaterial`** — Full PBR lighting with `colorNode`, `roughnessNode`, `metalnessNode`, `emissiveNode`, `normalNode`. This is your default for game materials. Compiles to both WebGL and WebGPU.

- **`MeshPhysicalNodeMaterial`** — Extends Standard with clearcoat, sheen, transmission, iridescence, and IOR. Use this for glass, fabric, soap bubbles, gemstones, and any material needing sub-surface-level optical accuracy. Slightly more expensive to render.

### How the Lighting Pipeline Composes Your Slots

When you override `colorNode`, you're not replacing the whole shader — you're plugging your expression into the albedo input of the PBR BRDF. The lighting system still:

1. Samples all lights in the scene (directional, point, spot)
2. Computes diffuse and specular contributions using your roughness/metalness
3. Adds your emissive contribution on top
4. Applies environment/IBL using your normal
5. Multiplies everything by your color

This is the crucial insight: **`colorNode` is multiplied by lighting, `emissiveNode` is added to it, and `outputNode` bypasses all of it**. If you want your material to respond to lights (which you usually do), use `colorNode`. If you want an unlit glow, use `emissiveNode`. If you're doing a completely custom lighting model, use `outputNode`.

### A Complete Example: Five Slots on One Material

```tsx
import { useMemo } from 'react'
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  uniform, uv, vec3, float, sin, cos, mix, smoothstep,
  mx_noise_float, positionWorld, normalWorld, time
} from 'three/tsl'

export function ElaborateMaterial() {
  const mat = useMemo(() => {
    const material = new MeshStandardNodeMaterial()

    // 1. colorNode — animated noise-based color
    const noiseVal = mx_noise_float(positionWorld.mul(2.0).add(time))
    const color1 = vec3(0.1, 0.4, 0.9)  // blue
    const color2 = vec3(0.9, 0.2, 0.1)  // red
    material.colorNode = mix(color1, color2, noiseVal)

    // 2. roughnessNode — rougher at the poles, smooth at equator
    // positionWorld.y maps from -1 to 1 for a unit sphere
    const roughness = smoothstep(float(-0.5), float(0.5), positionWorld.y).oneMinus()
    material.roughnessNode = roughness

    // 3. metalnessNode — metallic at the top
    material.metalnessNode = smoothstep(float(0.3), float(0.8), positionWorld.y)

    // 4. emissiveNode — pulsing glow based on surface normal facing camera
    // normalWorld.z is roughly 1 when facing camera (in world-space approximation)
    const rimFactor = normalWorld.dot(vec3(0, 0, 1)).abs()
    const pulse = sin(time.mul(3.0)).mul(0.5).add(0.5)
    material.emissiveNode = vec3(0.2, 0.5, 1.0).mul(rimFactor).mul(pulse)

    // 5. normalNode — procedural bump from noise derivatives
    const bumpScale = uniform(0.15)
    const bumpNoise = mx_noise_float(positionWorld.mul(8.0))
    // Approximate bump by perturbing normal with noise gradient
    // We'll do this properly in Section 7; for now a simple approach:
    const perturbedNormal = normalWorld.add(
      vec3(bumpNoise, bumpNoise, float(0)).normalize().mul(bumpScale)
    ).normalize()
    material.normalNode = perturbedNormal

    return material
  }, [])

  return (
    <mesh>
      <sphereGeometry args={[1, 64, 64]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

The key thing to notice: you never touched a vertex shader or a fragment shader. You expressed slot values as node expressions, and Three.js compiled them into the correct shader slots. The resulting material gets PBR lighting, shadows, reflections — everything a standard material gets — but with your custom logic driving the inputs.

---

## 2. Texture Sampling Nodes

### Loading and Sampling Textures

Even in a module about procedural materials, you'll need to know how to combine them with textures. The `texture()` node samples a texture at given UV coordinates:

```tsx
import { useTexture } from '@react-three/drei'
import { MeshStandardNodeMaterial } from 'three/webgpu'
import { texture, uv } from 'three/tsl'
import { useMemo } from 'react'

export function TexturedMaterial() {
  // Load texture the normal drei way
  const colorMap = useTexture('/textures/rock_color.jpg')

  const mat = useMemo(() => {
    const material = new MeshStandardNodeMaterial()
    // texture() wraps a Three.js Texture in a node
    material.colorNode = texture(colorMap, uv())
    return material
  }, [colorMap])

  return (
    <mesh>
      <boxGeometry />
      <primitive object={mat} />
    </mesh>
  )
}
```

### UV Manipulation

The `uv()` node returns the mesh's default UV coordinates, but you can transform them arbitrarily before sampling:

```tsx
import { uv, vec2, float, sin, cos, mat2, time } from 'three/tsl'

// Tiling: repeat the texture 4x4
const tiledUV = uv().mul(vec2(4, 4))

// Offset scrolling: scroll UVs over time
const scrollUV = uv().add(vec2(time.mul(0.1), float(0)))

// Rotation about center: rotate UVs by an angle
function rotateUV(uvNode: any, angle: any) {
  // Translate to center, rotate, translate back
  const centered = uvNode.sub(vec2(0.5, 0.5))
  const s = sin(angle)
  const c = cos(angle)
  // Manual 2x2 matrix rotation
  const rotX = centered.x.mul(c).sub(centered.y.mul(s))
  const rotY = centered.x.mul(s).add(centered.y.mul(c))
  return vec2(rotX, rotY).add(vec2(0.5, 0.5))
}

// Usage
const rotatedUV = rotateUV(uv(), time.mul(0.5))
```

### Triplanar Mapping

Triplanar projection avoids UV stretching on complex geometry like terrain — it projects the texture from all three world-space axes and blends based on surface normal:

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  texture, positionWorld, normalWorld, abs, pow, max, float, vec3, vec4
} from 'three/tsl'
import { useMemo } from 'react'
import { useTexture } from '@react-three/drei'

export function TriplanarMaterial() {
  const colorMap = useTexture('/textures/rock_color.jpg')

  const mat = useMemo(() => {
    const material = new MeshStandardNodeMaterial()

    // Scale factor for the projection
    const scale = float(0.5)

    // Sample the texture from three axes using world-space position
    const px = positionWorld.yz.mul(scale) // Project from X axis
    const py = positionWorld.xz.mul(scale) // Project from Y axis
    const pz = positionWorld.xy.mul(scale) // Project from Z axis

    const colorX = texture(colorMap, px)
    const colorY = texture(colorMap, py)
    const colorZ = texture(colorMap, pz)

    // Blend weights from world-space normal magnitude per axis
    // Higher sharpness exponent = harder transitions
    const sharpness = float(4.0)
    const absNormal = abs(normalWorld)
    const weights = pow(absNormal, vec3(sharpness, sharpness, sharpness))

    // Normalize weights so they sum to 1
    const totalWeight = weights.x.add(weights.y).add(weights.z)
    const wx = weights.x.div(totalWeight)
    const wy = weights.y.div(totalWeight)
    const wz = weights.z.div(totalWeight)

    // Blend the three samples
    const blended = colorX.mul(wx).add(colorY.mul(wy)).add(colorZ.mul(wz))
    material.colorNode = blended

    return material
  }, [colorMap])

  return (
    <mesh>
      {/* Triplanar looks great on terrain/irregular geometry */}
      <torusKnotGeometry args={[1, 0.3, 128, 16]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

Triplanar mapping is the standard approach for terrain materials in games. The texture tiles seamlessly in all directions with no UV seams, regardless of how complex the underlying geometry is.

---

## 3. Built-in Noise Functions

TSL ships with the MaterialX noise library — a curated set of noise functions that cover the most common use cases in material authoring. These compile to both WGSL and GLSL with identical visual output.

### The Core Noise Functions

```tsx
import {
  mx_noise_float,      // Classic Perlin-style noise, returns float
  mx_noise_vec3,       // Noise returning vec3 (independent per channel)
  mx_fractal_noise_float,  // Multi-octave fractal (fBm) noise
  mx_fractal_noise_vec3,   // Multi-octave fractal returning vec3
  mx_worley_noise_float,   // Voronoi/cellular noise, returns float
  mx_worley_noise_vec2,    // Voronoi returning vec2 (F1, F2 distances)
} from 'three/tsl'
```

### mx_noise_float — Standard Noise

The workhorse for most procedural materials. Smooth, continuous, natural-looking:

```tsx
import { positionWorld, time, mx_noise_float, float, vec3 } from 'three/tsl'

// Basic noise at object's world position
const n1 = mx_noise_float(positionWorld)

// Scale the input to control frequency (higher = smaller features)
const n2 = mx_noise_float(positionWorld.mul(5.0))

// Animate by adding time to one axis
const n3 = mx_noise_float(positionWorld.mul(3.0).add(vec3(time, float(0), float(0))))

// Stack multiple frequencies manually for fBm-like result
const fbm = mx_noise_float(positionWorld.mul(1.0))
  .add(mx_noise_float(positionWorld.mul(2.0)).mul(0.5))
  .add(mx_noise_float(positionWorld.mul(4.0)).mul(0.25))
```

### mx_fractal_noise_float — Multi-Octave Fractal Noise

Handles the octave stacking automatically with configurable parameters:

```tsx
import { positionWorld, mx_fractal_noise_float, float } from 'three/tsl'

// Parameters: position, octaves, lacunarity, diminish, offset
const fractalNoise = mx_fractal_noise_float(
  positionWorld.mul(2.0),  // position input
  float(4),                // octaves: how many layers of detail
  float(2.0),              // lacunarity: frequency multiplier per octave (usually 2.0)
  float(0.5),              // diminish: amplitude multiplier per octave (persistence, usually 0.5)
  float(0.0)               // offset: bias added to each octave
)
```

- **Octaves:** More octaves = more detail, more GPU cost. 4-6 is typical.
- **Lacunarity:** How much the frequency increases each octave. 2.0 doubles the frequency each time.
- **Diminish (persistence):** How much the amplitude decreases each octave. 0.5 halves it each time. Lower values produce smoother results; higher values give rougher, more chaotic surfaces.

### mx_worley_noise_float — Voronoi/Cellular Noise

Produces cell patterns — great for biological textures, cracked earth, scales, or the base for fire and plasma:

```tsx
import { positionWorld, mx_worley_noise_float, mx_worley_noise_vec2, float } from 'three/tsl'

// Returns distance to nearest cell center (F1)
const worleyF1 = mx_worley_noise_float(positionWorld.mul(4.0))

// Returns vec2(F1, F2) — both nearest and second-nearest distances
// F2 - F1 gives you the cell borders
const worleyBoth = mx_worley_noise_vec2(positionWorld.mul(4.0))
// Cell border mask: thin where |F2-F1| is small
const borderMask = worleyBoth.y.sub(worleyBoth.x)
```

### Visual Comparison

What each noise type looks like on a sphere (described, since this is text):

- **`mx_noise_float`** — Smooth organic blobs, like clouds or smoke. Good for: marble base, water variation, smoke.
- **`mx_fractal_noise_float`** (4 octaves) — Fine-grained turbulence with large-scale variation. Good for: terrain, rock, fire turbulence, detailed marble.
- **`mx_worley_noise_float`** (F1) — Dark cell interiors fading to bright borders. Good for: skin cells, soap bubbles, cracked ground.
- **`mx_worley_noise_vec2`** (F2-F1) — Thin bright borders between cells. Good for: cell walls, circuit boards, scale borders.

---

## 4. Procedural Patterns

### Gradient Mapping

Mapping a scalar noise value to a multi-stop color gradient is the foundation of most procedural color effects. TSL's `mx_gradient_color` is available, but it's often cleaner to use `mix()` chains:

```tsx
import { mix, smoothstep, float, vec3 } from 'three/tsl'

// Map a 0-1 float to a 3-stop gradient
function gradientMap(t: any, color0: any, color1: any, color2: any) {
  // First half: color0 to color1
  const firstHalf = mix(color0, color1, smoothstep(float(0.0), float(0.5), t))
  // Second half: color1 to color2
  const secondHalf = mix(color1, color2, smoothstep(float(0.5), float(1.0), t))
  // Blend the two halves
  return mix(firstHalf, secondHalf, smoothstep(float(0.4), float(0.6), t))
}

// Example: fire color ramp
const fireGradient = (t: any) => gradientMap(
  t,
  vec3(0.0, 0.0, 0.0),  // black (cool)
  vec3(1.0, 0.3, 0.0),  // orange (hot)
  vec3(1.0, 1.0, 0.5)   // yellow-white (hottest)
)
```

### Domain Warping

Domain warping feeds noise back into itself to create swirling, organic distortion. It's one of the most powerful pattern techniques:

```tsx
import {
  positionWorld, mx_noise_float, mx_noise_vec3, mix, float, vec3
} from 'three/tsl'

// Basic domain warp: use noise to distort the input coordinates
function domainWarp(pos: any, warpStrength: number) {
  // Sample noise to get a displacement vector
  const displacement = mx_noise_vec3(pos.mul(1.5))
  // Warp the position by the displacement
  const warpedPos = pos.add(displacement.mul(warpStrength))
  // Sample the actual noise at the warped position
  return mx_noise_float(warpedPos.mul(2.0))
}

// Two-pass domain warp (Inigo Quilez technique) — much more organic
function doubleWarp(pos: any) {
  // First warp pass
  const q = mx_noise_vec3(pos)
  // Second warp pass uses result of first
  const r = mx_noise_vec3(pos.add(q.mul(4.0)))
  // Final noise at double-warped position
  return mx_noise_float(pos.add(r.mul(4.0)))
}
```

Domain warping is what gives fire its swirling turbulence, water its caustic patterns, and clouds their billowing shapes. A flat noise field becomes dramatically more interesting after one or two warp passes.

### Brick Pattern

A manually constructed brick pattern with adjustable mortar width:

```tsx
import { uv, floor, fract, smoothstep, float, step, vec2, mix, vec3 } from 'three/tsl'

function brickPattern(uvNode: any, columns: number, rows: number, mortarWidth: number) {
  // Scale UVs to desired brick count
  const scaled = uvNode.mul(vec2(columns, rows))

  // Offset every other row by half a brick
  const rowIndex = floor(scaled.y)
  const offsetX = rowIndex.mod(2.0).mul(0.5) // 0 or 0.5

  // Local UV within this brick (0-1 range)
  const brickUV = vec2(fract(scaled.x.add(offsetX)), fract(scaled.y))

  // Mortar mask: 1 in mortar, 0 in brick
  const mortar = float(mortarWidth)
  const mortarX = smoothstep(float(0.0), mortar, brickUV.x)
    .oneMinus()
    .add(smoothstep(float(1.0).sub(mortar), float(1.0), brickUV.x))
  const mortarY = smoothstep(float(0.0), mortar, brickUV.y)
    .oneMinus()
    .add(smoothstep(float(1.0).sub(mortar), float(1.0), brickUV.y))

  return mortarX.max(mortarY) // 1 = mortar, 0 = brick
}

// Usage in a material
// const mask = brickPattern(uv(), 8, 4, 0.05)
// material.colorNode = mix(brickColor, mortarColor, mask)
```

---

## 5. Screen-Space Operations

### Screen-Space Nodes

TSL provides nodes for accessing the framebuffer's screen-space coordinates, depth, and size:

```tsx
import {
  screenUV,      // Normalized 0-1 screen coordinates (origin = bottom-left in WebGL)
  screenSize,    // vec2(width, height) in pixels
  viewportUV,    // Same as screenUV in most setups
} from 'three/tsl'
```

### Depth Buffer Access

Reading the scene depth buffer enables soft particles, intersection glow, and contact effects:

```tsx
import {
  screenUV, depth, viewZToOrthographicDepth, perspectiveDepthToViewZ,
  cameraNear, cameraFar, float
} from 'three/tsl'

// Read the depth at the current fragment's screen position
// This gives you the depth of whatever was rendered BEFORE this transparent object
const sceneDepth = depth  // Built-in node: scene depth at this fragment

// Linearize depth for useful calculations
// Raw depth is non-linear (more precision near the camera)
function linearizeDepth(rawDepth: any, near: any, far: any) {
  // Convert from NDC depth to view-space Z
  const viewZ = perspectiveDepthToViewZ(rawDepth, near, far)
  // Convert to 0-1 range
  return viewZToOrthographicDepth(viewZ, near, far)
}
```

### Soft Particle Intersection Glow

This is a classic effect: a transparent particle fades where it intersects with opaque geometry, preventing hard clipping edges:

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  depth, positionView, cameraNear, cameraFar,
  perspectiveDepthToViewZ, smoothstep, float, vec3
} from 'three/tsl'
import { useMemo } from 'react'

export function SoftIntersectionMaterial() {
  const mat = useMemo(() => {
    const material = new MeshStandardNodeMaterial()
    material.transparent = true
    material.depthWrite = false

    // Get scene depth at this pixel's screen position
    const sceneDepthRaw = depth

    // Convert scene depth to linear view-space Z
    const sceneViewZ = perspectiveDepthToViewZ(sceneDepthRaw, cameraNear, cameraFar).abs()

    // This fragment's view-space Z (how far from camera this particle is)
    const fragViewZ = positionView.z.abs()

    // Depth difference: how close is this fragment to the geometry behind it?
    const depthDiff = sceneViewZ.sub(fragViewZ)

    // Fade in over a soft range (0.0 to 0.5 world units)
    const softFade = smoothstep(float(0.0), float(0.5), depthDiff)

    // Apply as opacity
    material.colorNode = vec3(0.2, 0.6, 1.0)
    material.opacityNode = softFade.mul(0.7)

    return material
  }, [])

  return (
    <mesh>
      <planeGeometry args={[2, 2]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

Soft particles are essential for fire, smoke, water splashes, and any transparent VFX that intersects with the world. Without them, particles look like they're cutting through geometry.

---

## 6. Matrix & Transform Nodes

### Available Transform Matrices

TSL exposes the standard graphics transform matrices as nodes:

```tsx
import {
  modelWorldMatrix,       // Object → World space (M)
  modelViewMatrix,        // Object → View space (MV)
  normalMatrix,           // Normal transform (inverse transpose of MV, 3x3)
  cameraProjectionMatrix, // View → Clip space (P)
  cameraViewMatrix,       // World → View space (V)
  modelNormalMatrix,      // Same as normalMatrix
} from 'three/tsl'
```

### Space Transformations

Understanding which space you're in matters for consistent effects:

```tsx
import {
  positionLocal,   // Object space: mesh coordinates before any transform
  positionWorld,   // World space: after model matrix
  positionView,    // View/camera space: world pos relative to camera
  normalLocal,     // Object-space normal
  normalWorld,     // World-space normal
  normalView,      // View-space normal
} from 'three/tsl'
```

### World-Space Patterns

World-space operations create effects that are consistent regardless of object orientation — like stripes that align with the world Y axis rather than the mesh UV:

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import { positionWorld, sin, smoothstep, float, mix, vec3 } from 'three/tsl'
import { useMemo } from 'react'

export function WorldSpaceStripeMaterial() {
  const mat = useMemo(() => {
    const material = new MeshStandardNodeMaterial()

    // Horizontal stripes aligned to world Y — independent of mesh rotation
    const stripeFreq = float(3.0)
    const stripeSharpness = float(20.0)

    // sin(y * freq) oscillates between -1 and 1
    const wave = sin(positionWorld.y.mul(stripeFreq))
    // Map to 0-1 with smoothstep for controllable edge sharpness
    const stripe = smoothstep(
      float(-0.1).div(stripeSharpness),
      float(0.1).div(stripeSharpness),
      wave
    )

    material.colorNode = mix(
      vec3(0.05, 0.05, 0.1),  // dark stripe
      vec3(0.4, 0.8, 1.0),    // light stripe
      stripe
    )

    return material
  }, [])

  return (
    <mesh rotation={[0.3, 0.5, 0.1]}>
      {/* Notice: rotating the mesh doesn't affect the stripe direction */}
      <sphereGeometry args={[1, 32, 32]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

---

## 7. Derivatives & Normal Mapping

### Generating Normals from a Height Function

If you have a procedural height field (noise function), you can derive surface normals analytically using partial derivatives. This is how you get bump mapping with zero texture assets.

The principle: the normal is perpendicular to the surface. For a height function `h(x, y)`, the surface tangent vectors are `(1, 0, dh/dx)` and `(0, 1, dh/dy)`, and the normal is their cross product.

In TSL, you approximate these derivatives using the screen-space derivative nodes — they give you how a value changes between adjacent pixels:

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  positionWorld, mx_fractal_noise_float, vec3, float, cross, normalize,
  fwidth
} from 'three/tsl'
import { useMemo } from 'react'

export function ProceduralBumpMaterial() {
  const mat = useMemo(() => {
    const material = new MeshStandardNodeMaterial()

    const freq = float(6.0)
    const bumpStrength = float(0.3)

    // Sample height at the current position
    const pos = positionWorld.mul(freq)
    const h = mx_fractal_noise_float(pos, float(4), float(2.0), float(0.5), float(0.0))

    // Approximate the gradient of the height field using fwidth
    // fwidth(x) = abs(dFdx(x)) + abs(dFdy(x))
    // For a proper gradient we'd use separate dFdx/dFdy, but we approximate here
    const dh = fwidth(h)

    // Build a perturbed normal
    // dx and dy are approximations of the height gradient in screen space
    // We use a small epsilon offset to estimate the tangent directions
    const eps = float(0.01)
    const hX = mx_fractal_noise_float(pos.add(vec3(eps, float(0), float(0))), float(4), float(2.0), float(0.5), float(0.0))
    const hZ = mx_fractal_noise_float(pos.add(vec3(float(0), float(0), eps)), float(4), float(2.0), float(0.5), float(0.0))

    // Tangent vectors in world space
    const tangentX = vec3(eps, hX.sub(h).mul(bumpStrength), float(0))
    const tangentZ = vec3(float(0), hZ.sub(h).mul(bumpStrength), eps)

    // Normal = cross product of tangents
    const computedNormal = cross(tangentZ, tangentX).normalize()

    material.normalNode = computedNormal
    material.colorNode = vec3(0.6, 0.5, 0.4)  // stone-ish
    material.roughnessNode = float(0.8)

    return material
  }, [])

  return (
    <mesh>
      <sphereGeometry args={[1, 64, 64]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

The "sample at +epsilon" approach (finite differences) is reliable and straightforward. For performance-critical shaders, you can derive the gradient analytically if your noise function has a known derivative — but finite differences work well for most game materials.

---

## 8. Material Debugging

Debugging a broken TSL material is significantly easier than debugging GLSL strings — you get TypeScript errors, not black meshes — but you still need to visualize intermediate values to understand what's happening.

### Visualization Modes

```tsx
import { MeshBasicNodeMaterial } from 'three/webgpu'
import {
  normalWorld, uv, positionWorld, depth, vec3, float,
  perspectiveDepthToViewZ, cameraNear, cameraFar
} from 'three/tsl'

// 1. Visualize world normals: maps -1..1 to 0..1 RGB
const normalsVis = normalWorld.mul(0.5).add(0.5)

// 2. Visualize UV coordinates: U = red, V = green
const uvVis = vec3(uv().x, uv().y, float(0))

// 3. Visualize world position (useful for checking scale)
// Usually need to remap to visible range
const posVis = positionWorld.mul(0.5).add(0.5)

// 4. Visualize roughness as grayscale — use with colorNode on a copy of the mat
// const roughnessVis = float(roughnessValue)  // plug in your roughness expression
// material.colorNode = vec3(roughnessVis, roughnessVis, roughnessVis)

// 5. Visualize linearized depth
const rawDepth = depth
const linearDepth = perspectiveDepthToViewZ(rawDepth, cameraNear, cameraFar).abs().div(50.0)
const depthVis = vec3(linearDepth, linearDepth, linearDepth)
```

### Debug Toggle Component

A practical component that lets you cycle through visualization modes in development:

```tsx
import { useControls } from 'leva'
import { MeshBasicNodeMaterial, MeshStandardNodeMaterial } from 'three/webgpu'
import { normalWorld, uv, positionWorld, vec3, float } from 'three/tsl'
import { useMemo, useEffect } from 'react'

type DebugMode = 'none' | 'normals' | 'uv' | 'position'

interface DebugMaterialProps {
  baseMaterial: MeshStandardNodeMaterial
}

export function DebugMaterialWrapper({ baseMaterial }: DebugMaterialProps) {
  const { debugMode } = useControls('Material Debug', {
    debugMode: {
      value: 'none' as DebugMode,
      options: ['none', 'normals', 'uv', 'position'],
    }
  })

  const debugMat = useMemo(() => {
    if (debugMode === 'none') return null

    // Use MeshBasicNodeMaterial to bypass lighting for raw visualization
    const mat = new MeshBasicNodeMaterial()

    switch (debugMode) {
      case 'normals':
        mat.colorNode = normalWorld.mul(0.5).add(0.5)
        break
      case 'uv':
        mat.colorNode = vec3(uv().x, uv().y, float(0))
        break
      case 'position':
        mat.colorNode = positionWorld.mul(0.1).add(0.5).clamp(float(0), float(1))
        break
    }

    return mat
  }, [debugMode])

  return (
    <primitive object={debugMode === 'none' ? baseMaterial : (debugMat ?? baseMaterial)} />
  )
}
```

Using `MeshBasicNodeMaterial` for debug views is important — you want to see the raw node value without any lighting modification. If you use `colorNode` on a `MeshStandardNodeMaterial` for debug, the lighting will multiply your values and make everything harder to interpret.

---

## Code Walkthrough: Procedural Material Gallery

The mini-project is a gallery of six spheres, each with a completely procedural material. No texture files. All math, all GPU, all TSL.

```tsx
// ProceduralGallery.tsx
import { Canvas, useFrame } from '@react-three/fiber'
import { OrbitControls, Environment } from '@react-three/drei'
import { useControls, folder } from 'leva'
import { MeshStandardNodeMaterial, MeshPhysicalNodeMaterial } from 'three/webgpu'
import {
  uniform, uv, vec2, vec3, float, color,
  sin, cos, abs, floor, fract, clamp, mix, smoothstep, step,
  min, max, pow, sqrt, normalize, cross, dot,
  positionWorld, positionLocal, normalWorld,
  mx_noise_float, mx_noise_vec3, mx_fractal_noise_float,
  mx_worley_noise_float, mx_worley_noise_vec2,
  time
} from 'three/tsl'
import { useMemo, useRef } from 'react'
import type { Mesh } from 'three'

// ─────────────────────────────────────────────
// MATERIAL 1: Marble
// Technique: fractal noise + veins via abs() + color gradient
// ─────────────────────────────────────────────
function useMarbleMaterial() {
  const { veins, scale, color1, color2 } = useControls('Marble', {
    veins: { value: 8.0, min: 2, max: 20 },
    scale: { value: 1.5, min: 0.5, max: 5 },
    color1: '#e8e0d8',
    color2: '#2a1a0a',
  })

  return useMemo(() => {
    const mat = new MeshStandardNodeMaterial()

    const pos = positionWorld.mul(scale)

    // Fractal noise drives the vein position
    const fbm = mx_fractal_noise_float(pos, float(5), float(2.0), float(0.5), float(0.0))

    // Vein pattern: sin waves distorted by noise
    // The abs(sin(x * veins + noise)) creates thin bright streaks
    const veinCoord = pos.x.add(pos.y.mul(0.5)).add(fbm.mul(2.0))
    const veinRaw = sin(veinCoord.mul(veins)).abs()

    // Power curve sharpens the veins (makes them thinner/more defined)
    const veinMask = pow(veinRaw, float(2.0))

    // Color gradient: white marble with dark veins
    const c1 = vec3(color1)
    const c2 = vec3(color2)
    mat.colorNode = mix(c1, c2, veinMask)

    // Marble is smooth and slightly specular
    mat.roughnessNode = mix(float(0.1), float(0.4), veinMask)
    mat.metalnessNode = float(0.0)

    return mat
  }, [veins, scale, color1, color2])
}

// ─────────────────────────────────────────────
// MATERIAL 2: Wood
// Technique: cylindrical distance + rings + noise grain
// ─────────────────────────────────────────────
function useWoodMaterial() {
  const { ringFreq, grainStrength, scale } = useControls('Wood', {
    ringFreq: { value: 10, min: 3, max: 30 },
    grainStrength: { value: 0.8, min: 0, max: 2 },
    scale: { value: 1.0, min: 0.3, max: 3 },
  })

  return useMemo(() => {
    const mat = new MeshStandardNodeMaterial()

    const pos = positionWorld.mul(scale)

    // Cylindrical distance from the Y axis (tree growth rings)
    const radius = sqrt(pos.x.mul(pos.x).add(pos.z.mul(pos.z)))

    // Add noise to distort the rings naturally
    const grain = mx_noise_float(pos.mul(8.0)).mul(grainStrength)
    const distorted = radius.add(grain)

    // Rings: sin wave on the radius
    const ringValue = sin(distorted.mul(ringFreq)).mul(0.5).add(0.5)

    // Power-curve for more distinct ring separation
    const ring = pow(ringValue, float(1.5))

    // Wood color gradient: light sapwood to dark heartwood
    const sapwood = vec3(0.82, 0.66, 0.42)
    const heartwood = vec3(0.38, 0.22, 0.10)

    mat.colorNode = mix(heartwood, sapwood, ring)
    mat.roughnessNode = float(0.7)
    mat.metalnessNode = float(0.0)

    return mat
  }, [ringFreq, grainStrength, scale])
}

// ─────────────────────────────────────────────
// MATERIAL 3: Animated Water
// Technique: multi-layer animated noise + transparency + surface normals
// ─────────────────────────────────────────────
function useWaterMaterial() {
  const { speed, transparency, waveScale } = useControls('Water', {
    speed: { value: 0.5, min: 0, max: 2 },
    transparency: { value: 0.35, min: 0, max: 1 },
    waveScale: { value: 2.0, min: 0.5, max: 8 },
  })

  return useMemo(() => {
    const mat = new MeshStandardNodeMaterial()
    mat.transparent = true

    const pos = positionWorld.mul(waveScale)

    // Two layers of noise moving in different directions for interference pattern
    const t = time.mul(speed)
    const wave1 = mx_noise_float(pos.add(vec3(t, float(0), t.mul(0.7))))
    const wave2 = mx_noise_float(pos.mul(1.7).add(vec3(t.mul(-0.6), float(0), t.mul(0.4))))

    // Combine waves and remap to 0-1
    const combined = wave1.add(wave2).mul(0.5).add(0.5)

    // Deep water color: blends between dark deep and light shallow
    const deepColor = vec3(0.01, 0.05, 0.15)
    const shallowColor = vec3(0.05, 0.40, 0.65)
    mat.colorNode = mix(deepColor, shallowColor, combined)

    // Animated roughness: slightly rougher at wave peaks
    mat.roughnessNode = mix(float(0.05), float(0.25), combined)
    mat.metalnessNode = float(0.15)

    // Opacity variation: slightly transparent in troughs
    mat.opacityNode = mix(float(transparency), float(1.0), combined)

    // Procedural bump from noise gradient
    const eps = float(0.02)
    const hX = mx_noise_float(pos.add(vec3(eps, float(0), float(0))).add(vec3(t, float(0), t.mul(0.7))))
    const hZ = mx_noise_float(pos.add(vec3(float(0), float(0), eps)).add(vec3(t, float(0), t.mul(0.7))))

    const bumpScale = float(0.4)
    const tangentX = vec3(eps, hX.sub(wave1).mul(bumpScale), float(0))
    const tangentZ = vec3(float(0), hZ.sub(wave1).mul(bumpScale), eps)
    mat.normalNode = cross(tangentZ, tangentX).normalize()

    return mat
  }, [speed, transparency, waveScale])
}

// ─────────────────────────────────────────────
// MATERIAL 4: Fire
// Technique: domain-warped noise + color ramp + vertex displacement + emission
// ─────────────────────────────────────────────
function useFireMaterial() {
  const { speed, height, intensity } = useControls('Fire', {
    speed: { value: 1.5, min: 0.5, max: 4 },
    height: { value: 2.0, min: 0.5, max: 5 },
    intensity: { value: 3.0, min: 0.5, max: 8 },
  })

  return useMemo(() => {
    const mat = new MeshStandardNodeMaterial()
    mat.transparent = true
    mat.depthWrite = false

    const t = time.mul(speed)
    const pos = positionWorld

    // Fire rises from bottom (Y=0) to top (Y=height)
    // Remap Y so fire fades toward the tip
    const heightFade = clamp(
      float(1.0).sub(pos.y.div(height)),
      float(0), float(1)
    )
    const heightFadePow = pow(heightFade, float(0.5))

    // Domain warp for turbulence
    // First warp pass
    const warpFreq = float(1.5)
    const q = mx_noise_vec3(pos.mul(warpFreq).add(vec3(float(0), t.negate(), float(0))))
    // Second warp pass — uses first pass result
    const r = mx_noise_vec3(pos.mul(warpFreq).add(q.mul(4.0)).add(vec3(float(0), t.negate().mul(1.2), float(0))))
    // Final noise at double-warped position
    const fireNoise = mx_fractal_noise_float(
      pos.mul(2.0).add(r.mul(3.0)).add(vec3(float(0), t.negate(), float(0))),
      float(4), float(2.0), float(0.5), float(0.0)
    ).mul(heightFadePow)

    // Fire color gradient: black → red → orange → yellow → white
    const black = vec3(0.0, 0.0, 0.0)
    const red = vec3(0.8, 0.1, 0.0)
    const orange = vec3(1.0, 0.4, 0.0)
    const yellow = vec3(1.0, 0.9, 0.2)

    // Multi-stop gradient using smoothstep thresholds
    const t0 = float(0.2)
    const t1 = float(0.5)
    const t2 = float(0.8)

    const baseColor = mix(black, red, smoothstep(float(0), t0, fireNoise))
    const midColor = mix(baseColor, orange, smoothstep(t0, t1, fireNoise))
    const tipColor = mix(midColor, yellow, smoothstep(t1, t2, fireNoise))

    // No albedo color — fire is pure emission
    mat.colorNode = vec3(0, 0, 0)
    mat.emissiveNode = tipColor.mul(intensity)

    // Opacity follows fire intensity, fades at edges
    mat.opacityNode = clamp(fireNoise.mul(2.0), float(0), float(1))

    // Vertex displacement: make the flame surface irregular
    // Note: requires a mesh with enough vertices (high subdivisions)
    const dispNoise = mx_noise_float(positionLocal.mul(3.0).add(vec3(float(0), t.negate(), float(0))))
    const displacement = positionLocal.add(
      normalWorld.mul(dispNoise.mul(0.1).mul(heightFade))
    )
    mat.positionNode = displacement

    return mat
  }, [speed, height, intensity])
}

// ─────────────────────────────────────────────
// MATERIAL 5: Hologram
// Technique: fresnel rim + scanlines + glitch noise + additive transparency
// ─────────────────────────────────────────────
function useHologramMaterial() {
  const { scanlineFreq, glitchStrength, rimPower } = useControls('Hologram', {
    scanlineFreq: { value: 40, min: 10, max: 100 },
    glitchStrength: { value: 0.3, min: 0, max: 1 },
    rimPower: { value: 2.0, min: 0.5, max: 6 },
  })

  return useMemo(() => {
    const mat = new MeshStandardNodeMaterial()
    mat.transparent = true
    mat.depthWrite = false

    const t = time

    // Fresnel: stronger glow at silhouette edges
    // View direction dot normal: 0 at edges, 1 facing camera
    // We approximate view dir using normalWorld.z in world space
    const fresnelDot = abs(normalWorld.z)
    const fresnel = float(1.0).sub(fresnelDot).pow(rimPower)

    // Horizontal scanlines using world Y position
    const scanlineY = positionWorld.y.mul(scanlineFreq)
    const scanline = step(float(0.5), fract(scanlineY))

    // Animated glitch: random noise that jumps in time
    // Floor time to create discrete time steps for glitching
    const glitchTime = floor(t.mul(8.0)).div(8.0)
    const glitchNoise = mx_noise_float(
      vec3(positionWorld.y.mul(2.0), glitchTime, float(0))
    )
    const glitch = step(float(1.0).sub(glitchStrength), glitchNoise)

    // Horizontal offset from glitch (shifts UV-based effects)
    const glitchOffset = glitch.mul(mx_noise_float(vec3(glitchTime, float(0), float(0))).mul(0.1))

    // Combine: fresnel rim + scanlines + glitch interruption
    const hologramMask = fresnel.add(scanline.mul(0.3)).mul(glitch.oneMinus().add(0.5))

    // Teal hologram color
    const holoColor = vec3(0.0, 0.85, 1.0)

    mat.colorNode = vec3(0, 0, 0)
    mat.emissiveNode = holoColor.mul(hologramMask).mul(2.0)
    mat.opacityNode = clamp(hologramMask.mul(1.5), float(0), float(0.9))

    return mat
  }, [scanlineFreq, glitchStrength, rimPower])
}

// ─────────────────────────────────────────────
// MATERIAL 6: Force Field
// Technique: animated voronoi + depth intersection glow + transparency
// ─────────────────────────────────────────────
function useForcefieldMaterial() {
  const { pulseSpeed, cellScale, edgeBrightness } = useControls('Forcefield', {
    pulseSpeed: { value: 1.0, min: 0.2, max: 4 },
    cellScale: { value: 3.0, min: 1, max: 8 },
    edgeBrightness: { value: 5.0, min: 1, max: 10 },
  })

  return useMemo(() => {
    const mat = new MeshStandardNodeMaterial()
    mat.transparent = true
    mat.depthWrite = false
    mat.side = 2 // DoubleSide

    const t = time.mul(pulseSpeed)

    // Animated voronoi in world space
    const pos = positionWorld.mul(cellScale)
    const animPos = pos.add(vec3(t.mul(0.1), t.mul(0.15), float(0)))

    const worley = mx_worley_noise_vec2(animPos)
    const f1 = worley.x
    const f2 = worley.y

    // Cell borders: thin bright lines where F2 - F1 is small
    const border = smoothstep(float(0.0), float(0.15), f2.sub(f1))
    const borderGlow = border.oneMinus()

    // Pulsing: cells pulse with an offset based on their center
    const pulse = sin(t.add(f1.mul(6.28))).mul(0.5).add(0.5)

    // Combine border glow and pulse
    const intensity = borderGlow.mul(edgeBrightness).add(pulse.mul(0.3))

    // Electric blue-purple color
    const innerColor = vec3(0.1, 0.2, 0.8)
    const edgeColor = vec3(0.4, 0.8, 1.0)
    const forcefieldColor = mix(innerColor, edgeColor, borderGlow)

    // Fresnel for edge highlight
    const fresnel = float(1.0).sub(abs(normalWorld.z)).pow(float(1.5))

    mat.colorNode = vec3(0, 0, 0)
    mat.emissiveNode = forcefieldColor.mul(intensity.add(fresnel.mul(2.0)))
    mat.opacityNode = clamp(intensity.mul(0.6).add(fresnel.mul(0.4)), float(0.0), float(0.85))

    return mat
  }, [pulseSpeed, cellScale, edgeBrightness])
}

// ─────────────────────────────────────────────
// GALLERY SCENE
// ─────────────────────────────────────────────

interface GallerySphereProps {
  position: [number, number, number]
  material: MeshStandardNodeMaterial
  label: string
  subdivisions?: number
}

function GallerySphere({ position, material, subdivisions = 64 }: GallerySphereProps) {
  const meshRef = useRef<Mesh>(null)

  useFrame(({ clock }) => {
    if (meshRef.current) {
      // Gentle rotation so all sides are visible
      meshRef.current.rotation.y = clock.getElapsedTime() * 0.3
    }
  })

  return (
    <mesh ref={meshRef} position={position}>
      {/* High subdivisions needed for vertex displacement materials */}
      <sphereGeometry args={[0.8, subdivisions, subdivisions]} />
      <primitive object={material} />
    </mesh>
  )
}

export function ProceduralGallery() {
  const marbleMat = useMarbleMaterial()
  const woodMat = useWoodMaterial()
  const waterMat = useWaterMaterial()
  const fireMat = useFireMaterial()
  const hologramMat = useHologramMaterial()
  const forcefieldMat = useForcefieldMaterial()

  const materials = [
    { mat: marbleMat, pos: [-5, 0, 0] as [number, number, number], label: 'Marble' },
    { mat: woodMat, pos: [-3, 0, 0] as [number, number, number], label: 'Wood' },
    { mat: waterMat, pos: [-1, 0, 0] as [number, number, number], label: 'Water' },
    { mat: fireMat, pos: [1, 0, 0] as [number, number, number], label: 'Fire', subdivisions: 128 },
    { mat: hologramMat, pos: [3, 0, 0] as [number, number, number], label: 'Hologram' },
    { mat: forcefieldMat, pos: [5, 0, 0] as [number, number, number], label: 'Forcefield' },
  ]

  return (
    <Canvas camera={{ position: [0, 1, 8], fov: 50 }}>
      <color attach="background" args={['#050508']} />

      {/* Subtle lighting — emissive materials provide most of the interest */}
      <ambientLight intensity={0.3} />
      <directionalLight position={[5, 10, 5]} intensity={1.0} />
      <pointLight position={[-5, 3, 3]} intensity={0.5} color="#4466ff" />

      <Environment preset="city" />

      {materials.map(({ mat, pos, label, subdivisions }) => (
        <GallerySphere
          key={label}
          position={pos}
          material={mat}
          label={label}
          subdivisions={subdivisions}
        />
      ))}

      <OrbitControls makeDefault />
    </Canvas>
  )
}
```

This gallery is a living reference. The leva panels let you tweak every parameter while the scene runs. To extend it: add a 7th sphere with a new material idea, observe how changing parameters affects the look, and use the debug techniques from Section 8 to inspect what each noise node is producing.

---

## Pitfalls

### 1. Not Wrapping Material Creation in useMemo

**WRONG — creates a new material object every render:**
```tsx
function BadMaterial() {
  const { speed } = useControls({ speed: 1.0 })

  // This runs on EVERY render, creating a new material each time.
  // The old material leaks GPU memory. React re-renders → material spike.
  const mat = new MeshStandardNodeMaterial()
  mat.colorNode = vec3(1, 0, 0)

  return <primitive object={mat} />
}
```

**RIGHT — memoize, use uniform() for animatable values:**
```tsx
function GoodMaterial() {
  const { speed } = useControls({ speed: 1.0 })

  // useMemo ensures the material is created once and reused
  const { mat, speedUniform } = useMemo(() => {
    const speedUniform = uniform(1.0)  // uniform() creates an animatable handle
    const mat = new MeshStandardNodeMaterial()
    // Use the uniform reference inside the node graph
    mat.colorNode = vec3(sin(time.mul(speedUniform)), float(0.5), float(1.0))
    return { mat, speedUniform }
  }, [])

  // Update the uniform value every frame — no new material created
  useEffect(() => {
    speedUniform.value = speed
  }, [speed, speedUniform])

  return <primitive object={mat} />
}
```

### 2. Mutating Node Objects Instead of Using uniform()

**WRONG — you cannot mutate a node value after construction:**
```tsx
const mat = new MeshStandardNodeMaterial()
const myColor = vec3(1, 0, 0)
mat.colorNode = myColor

// This does NOT work. vec3() creates an immutable node constant.
// Changing .value on it will either error or have no effect.
useFrame(() => {
  (myColor as any).value = [Math.random(), 0, 0]  // WRONG
})
```

**RIGHT — use uniform() for any value you intend to change at runtime:**
```tsx
const colorUniform = uniform(new THREE.Color(1, 0, 0))
const mat = new MeshStandardNodeMaterial()
mat.colorNode = colorUniform  // uniform nodes ARE animatable

useFrame(() => {
  // uniform.value can be mutated — it's designed for this
  colorUniform.value.setRGB(Math.random(), 0, 0)
})
```

### 3. Texture Not Available at Material Construction Time

**WRONG — texture may be undefined when the material is created:**
```tsx
function TextureMaterial() {
  const colorMap = useTexture('/rock.jpg')

  // The memo runs when colorMap is first set to a placeholder,
  // then useTexture resolves and colorMap changes — but the memo
  // doesn't re-run because it captured the old placeholder.
  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial()
    m.colorNode = texture(colorMap, uv())  // colorMap might be wrong here
    return m
  }, [])  // BUG: colorMap is NOT in the dependency array

  return <primitive object={mat} />
}
```

**RIGHT — include the texture in the memo dependency array:**
```tsx
function TextureMaterial() {
  const colorMap = useTexture('/rock.jpg')

  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial()
    m.colorNode = texture(colorMap, uv())
    return m
  }, [colorMap])  // Recreate material when texture resolves

  return <primitive object={mat} />
}
```

### 4. Noise Frequency Mismatch

**WRONG — applying noise at a frequency that doesn't match object scale:**
```tsx
// Your sphere has radius 1. Noise input at frequency 1000 means
// each "grain" is 0.001 world units — way too fine to see.
// The sphere will look like solid grey (noise averages out to 0.5).
const n = mx_noise_float(positionWorld.mul(1000.0))
```

**RIGHT — match noise frequency to your object's scale:**
```tsx
// Rule of thumb: noise frequency 1-4 gives large features on a unit object.
// Frequency 8-16 gives fine detail. Frequency 30+ is very fine grain.
// Start at frequency 2.0 and adjust visually.
const n = mx_noise_float(positionWorld.mul(2.0))  // Large features on unit sphere

// For fractal noise, the base frequency controls the largest feature.
// Octaves add smaller details on top. Don't start with a high base frequency.
const fbm = mx_fractal_noise_float(
  positionWorld.mul(1.5),  // Base frequency: large-scale variation
  float(4),                 // 4 octaves of detail
  float(2.0), float(0.5), float(0.0)
)
```

### 5. Screen-Space Operations Not Accounting for Aspect Ratio

**WRONG — screenUV gives non-square coordinates on non-square viewports:**
```tsx
// screenUV.x goes from 0 to 1 regardless of window width.
// screenUV.y goes from 0 to 1 regardless of window height.
// A circle defined by distance from center will be oval on most screens.
const center = vec2(0.5, 0.5)
const dist = screenUV.sub(center).length()
const circle = step(float(0.3), dist).oneMinus()  // OVAL, not circle
```

**RIGHT — correct for aspect ratio using screenSize:**
```tsx
import { screenUV, screenSize, vec2, float } from 'three/tsl'

// Compute aspect ratio and correct the X coordinate
const aspect = screenSize.x.div(screenSize.y)
const correctedUV = vec2(
  screenUV.x.sub(0.5).mul(aspect).add(0.5),
  screenUV.y
)

const center = vec2(screenUV.x.mul(aspect).add(screenUV.x.sub(screenUV.x)), float(0.5))
// Simpler pattern: scale X by aspect before computing distance
const dist = vec2(
  screenUV.x.sub(0.5).mul(aspect),
  screenUV.y.sub(0.5)
).length()
const circle = step(float(0.3), dist).oneMinus()  // Correct circle
```

---

## Exercises

### Exercise 1 — Noise Explorer (2–3 hours)

**Goal:** Build an interactive grid that visualizes all four noise types side by side, with leva controls for every parameter.

**Requirements:**
- A 2×2 grid of flat planes, each showing one noise type: `mx_noise_float`, `mx_fractal_noise_float`, `mx_worley_noise_float`, and `mx_worley_noise_vec2` (F2-F1 border mode)
- Leva controls shared across all four: scale (frequency), animate (boolean)
- Fractal noise panel: separate octaves (1–8), lacunarity, persistence sliders
- Use `MeshBasicNodeMaterial` with `outputNode` for direct visualization (bypasses lighting)
- Color-map the noise through at least a 2-stop gradient (not just grayscale)

**Hint:** Use `positionWorld` as the noise input. For the flat planes, Y is always 0, so the noise patterns are readable as 2D slices. Scale the XZ position to control frequency.

**Stretch goal:** Add a 5th panel that shows domain-warped noise, with a "warp strength" slider. Let users see the warped vs. unwarped noise simultaneously.

---

### Exercise 2 — Animated Lava Lamp Material (3–4 hours)

**Goal:** Create a lava lamp material with rising blobs of color, applied to a tall cylinder.

**Requirements:**
- Blobs rise from bottom to top over time, driven by multi-octave animated noise
- At least 3 distinct color bands (cool base, warm mid, hot core)
- Blobs should look naturally rounded — use `smoothstep` to soften edges
- Apply to a `CylinderGeometry` that is tall and narrow (like an actual lava lamp)
- Leva controls: rise speed, blob size, color stops

**Hint:** The trick is to use `positionWorld.y.sub(time.mul(speed))` as one component of the noise input. This makes the pattern scroll upward. Then use the noise value to control which color band appears. Threshold the noise with `smoothstep` to create distinct blobs rather than a smooth wash.

**Stretch goal:** Add a second layer of smaller, faster bubbles. Add an emissive component so the lamp glows. Wrap the lamp in a thin transparent shell with `MeshPhysicalNodeMaterial` and `transmissionNode`.

---

### Exercise 3 — Triplanar Terrain Material (4–5 hours)

**Goal:** Build a terrain-ready material with triplanar projection and height-based biome blending.

**Requirements:**
- Load a heightmap (or generate one procedurally) and apply it to a `PlaneGeometry`
- Triplanar material with three textures: grass (Y-facing), rock (steep slopes), snow (high altitude)
- Blend between biomes based on: Y height (for snow), normal Y component (for rock vs grass)
- Procedural normal mapping on all three biomes using the finite-difference technique from Section 7
- No texture assets allowed for the normals — compute from the height function

**Hint:** Generate height with `mx_fractal_noise_float(position.xz, 4, 2.0, 0.5, 0.0)` to avoid needing a heightmap file. For biome blending, `smoothstep` is your friend: `smoothstep(0.6, 0.8, normalWorld.y)` blends between rock and grass based on slope steepness.

**Stretch goal:** Add a water plane at height 0. Use `transmissionNode` and `iorNode` on `MeshPhysicalNodeMaterial` for refractive water. Add animated caustics using domain-warped voronoi as an `emissiveNode` contribution near the water surface.

---

### Exercise 4 — Custom Lighting Model (5–7 hours)

**Goal:** Implement a non-PBR toon/cel shading model using `outputNode` to take full control of the lighting calculation, then recreate the gallery's fire material using the new lighting model.

**Requirements:**
- Use `MeshBasicNodeMaterial` with `outputNode` (bypass all PBR lighting)
- Implement a Lambertian diffuse model manually: `dot(normalWorld, lightDir)` clamped to 0-1
- Quantize the diffuse into 3 distinct bands using `floor(diffuse * 3.0) / 3.0`
- Add a rim light using fresnel: bright edge where normal is perpendicular to view
- Access Three.js directional light direction as a uniform (you'll need to pass it manually)
- Apply this custom toon shader to the fire material from the gallery: the fire should now render with cel-shaded bands

**Hint:** In `outputNode`, you have full control. You cannot use Three.js's light loop directly — you need to replicate the lighting math. Get the sun direction from a `uniform(new THREE.Vector3(...))` that you update each frame. The toon bands come from `floor()` applied to the diffuse factor.

**Stretch goal:** Implement Blinn-Phong specular as a fourth band (bright highlight). Add a fill light in the opposite direction from the sun. Create a UI toggle to switch between PBR and toon modes on all gallery materials simultaneously.

---

## API Quick Reference

### Material Types

| Class | Import | Use When |
|-------|--------|----------|
| `MeshBasicNodeMaterial` | `three/webgpu` | No lighting, debug vis, UI, skybox |
| `MeshStandardNodeMaterial` | `three/webgpu` | Most game materials, PBR |
| `MeshPhysicalNodeMaterial` | `three/webgpu` | Glass, fabric, iridescence, transmission |
| `MeshToonNodeMaterial` | `three/webgpu` | Built-in toon with configurable gradient |
| `SpriteNodeMaterial` | `three/webgpu` | Billboard sprites with node materials |
| `LineBasicNodeMaterial` | `three/webgpu` | Procedural wireframes, debug lines |

### Node Slot Reference

| Slot | Type | Default |
|------|------|---------|
| `colorNode` | `vec3/vec4` | White |
| `emissiveNode` | `vec3` | Black |
| `roughnessNode` | `float` | 1.0 |
| `metalnessNode` | `float` | 0.0 |
| `normalNode` | `vec3` | Mesh normal |
| `positionNode` | `vec3` | Mesh position |
| `opacityNode` | `float` | 1.0 |
| `outputNode` | `vec4` | (bypasses all lighting) |
| `transmissionNode` | `float` | 0.0 |
| `thicknessNode` | `float` | 0.0 |
| `iorNode` | `float` | 1.5 |
| `iridescenceNode` | `float` | 0.0 |
| `clearcoatNode` | `float` | 0.0 |
| `sheenNode` | `vec3` | Black |

### Texture Nodes

| Node | Returns | Usage |
|------|---------|-------|
| `texture(map, uvNode)` | `vec4` | Sample a texture at UV |
| `uv()` | `vec2` | Default mesh UV channel |
| `uv(1)` | `vec2` | Second UV channel |
| `screenUV` | `vec2` | Normalized screen position |
| `viewportUV` | `vec2` | Viewport-relative screen position |

### Noise Functions

| Function | Returns | Notes |
|----------|---------|-------|
| `mx_noise_float(pos)` | `float` | Standard noise, -1 to 1 |
| `mx_noise_vec3(pos)` | `vec3` | Independent noise per channel |
| `mx_fractal_noise_float(pos, octaves, lac, dim, offset)` | `float` | Multi-octave fBm |
| `mx_fractal_noise_vec3(pos, ...)` | `vec3` | Multi-octave fBm per channel |
| `mx_worley_noise_float(pos)` | `float` | Voronoi F1 distance |
| `mx_worley_noise_vec2(pos)` | `vec2` | Voronoi (F1, F2) distances |

### Math Utility Nodes

| Node | Returns | Notes |
|------|---------|-------|
| `mix(a, b, t)` | same as a | Linear interpolation |
| `smoothstep(lo, hi, x)` | `float` | Smooth 0-1 transition |
| `step(edge, x)` | `float` | Hard threshold (0 or 1) |
| `fract(x)` | same | Fractional part |
| `floor(x)` | same | Round down |
| `abs(x)` | same | Absolute value |
| `pow(x, n)` | same | Power/exponent |
| `clamp(x, lo, hi)` | same | Clamp to range |
| `sin(x)` / `cos(x)` | same | Trigonometry |
| `normalize(v)` | `vec3` | Normalize vector |
| `cross(a, b)` | `vec3` | Cross product |
| `dot(a, b)` | `float` | Dot product |
| `length(v)` | `float` | Vector magnitude |
| `uniform(value)` | varies | CPU-mutable value |

### Screen-Space Nodes

| Node | Type | Description |
|------|------|-------------|
| `screenUV` | `vec2` | Normalized 0-1 screen coordinates |
| `screenSize` | `vec2` | Viewport size in pixels |
| `depth` | `float` | Scene depth at this fragment |
| `viewportUV` | `vec2` | Same as screenUV in most setups |
| `cameraNear` | `float` | Camera near clip distance |
| `cameraFar` | `float` | Camera far clip distance |
| `perspectiveDepthToViewZ(d, near, far)` | `float` | Linearize perspective depth |

### Position and Normal Nodes

| Node | Space | Notes |
|------|-------|-------|
| `positionLocal` | Object | Before model transform |
| `positionWorld` | World | After model transform |
| `positionView` | Camera | Relative to camera |
| `normalLocal` | Object | Before transform |
| `normalWorld` | World | After transform (use for effects) |
| `normalView` | Camera | For view-dependent effects |
| `time` | — | Elapsed time in seconds |

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [Three.js TSL Documentation](https://threejs.org/docs/pages/TSL.html) | Official Docs | Authoritative reference for all nodes and syntax |
| [Three.js Node Material Examples](https://threejs.org/examples/?q=node) | Interactive Examples | 30+ examples showing real-world node material usage |
| [Inigo Quilez — Articles](https://iquilezles.org/articles/) | Technical Articles | The definitive source on procedural textures, domain warping, and SDF math |
| [Inigo Quilez — Shadertoy](https://www.shadertoy.com/user/iq) | Shader Examples | IQ's canonical procedural material implementations — translate these to TSL |
| [The Book of Shaders — Chapter 12-13](https://thebookofshaders.com/12/) | Interactive Tutorial | Cellular noise and fractal brownian motion, explained interactively |
| [MaterialX Specification](https://materialx.org/Specification.html) | Specification | TSL's noise functions come from MaterialX — useful when you need exact behavior |
| [GPU Gems 3 — Chapter 1](https://developer.nvidia.com/gpugems/gpugems3/part-i-geometry/chapter-1-generating-complex-procedural-terrains-using-gpu) | Book Chapter | Procedural terrain and noise on the GPU — the techniques still apply |
| [Catlike Coding — Rendering Tutorials](https://catlikecoding.com/unity/tutorials/rendering/) | Tutorial Series | Unity-based but the shader math is identical — excellent on normal mapping and PBR |
| [Three.js r3f-node-editor](https://github.com/three-stdlib/r3f-node-editor) | Tool | Visual node editor for TSL in R3F — great for exploring node graphs interactively |

---

## Key Takeaways

1. **Node materials are slot overrides, not full replacements.** When you set `colorNode`, you plug into the PBR lighting equation at the albedo stage. The lighting math still runs. Use `outputNode` only when you genuinely need to replace the entire lighting model.

2. **`uniform()` is the only way to make values animatable after material creation.** You cannot mutate a `vec3()` or `float()` node constant after building the graph. `uniform()` creates a special node whose `.value` property is mutable at runtime — always use it for anything that changes.

3. **`useMemo` is non-negotiable for node material creation.** Creating a material is expensive: it allocates GPU objects and compiles shaders. Doing it on every render will destroy performance and cause memory leaks. Recreate only when dependencies genuinely change.

4. **`positionWorld` is almost always the right noise input.** Using `positionLocal` (object space) means your procedural pattern rotates and scales with the object — usually not what you want. `positionWorld` keeps the pattern fixed in the world, producing consistent results regardless of object transforms.

5. **Domain warping transforms flat noise into organic forms.** A single noise sample looks like smooth blobs. Feed that noise back as an offset into the position, then sample again — the result swirls, turbulates, and looks genuinely organic. This single technique accounts for fire, smoke, clouds, water caustics, and most other complex natural patterns.

6. **Transparency materials need `depthWrite = false` and additive or premultiplied blending.** Emissive transparent materials (fire, holograms, force fields) should almost always have `depthWrite = false` to prevent them from occluding objects behind them incorrectly. Set `material.blending = AdditiveBlending` for glow effects that brighten what's behind them.

7. **Debug with `MeshBasicNodeMaterial` and `outputNode`.** When an effect looks wrong, plug intermediate values into `outputNode` on a `MeshBasicNodeMaterial`. The lack of lighting makes it easy to see exactly what a node is producing. Normals become RGB, floats become grayscale — this visual debugging catches problems in minutes that might take hours to find by reading numbers.

---

## What's Next?

You've mastered TSL's material and texture system — every PBR slot, noise functions, procedural patterns, screen-space operations, and material debugging. Now it's time to push the GPU further.

**[Module 15: TSL Compute — Advanced Patterns](module-15-tsl-compute-advanced.md)** takes the compute foundations from Module 12 and goes deep: shared workgroup memory, atomic operations, ping-pong buffers, parallel reduction, GPU sorting, spatial data structures, and indirect dispatch. You'll build a full GPU fluid simulation with 50k+ particles — the kind of system where every technique from this module (procedural materials, noise, screen-space operations) combines with compute to create something that would be impossible without both halves.

**[Module 16: TSL Ecosystem & Real-World Patterns](module-16-tsl-ecosystem-patterns.md)** brings it all together: integrating TSL with Drei helpers, post-processing, instanced meshes, and TypeScript's type system. You'll learn the GLSL → TSL migration cookbook, inspect generated WGSL, and build a complete retrofit project converting legacy GLSL shaders to TSL.

---

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
