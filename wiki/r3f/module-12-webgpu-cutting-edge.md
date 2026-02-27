# Module 12: WebGPU & The Cutting Edge

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 6–10 hours
**Prerequisites:** [Module 6: Shaders & Stylized Rendering](module-06-shaders-stylized-rendering.md)

---

## Overview

You're about to step off the WebGL cliff and into the future of GPU programming in the browser. WebGPU is not a minor upgrade. It's a complete replacement for WebGL — a modern API modeled after Vulkan, Metal, and DirectX 12 that gives you compute shaders, proper GPU-driven pipelines, and dramatically less driver overhead. Three.js has been building toward this for years, and in 2026, the tooling is finally mature enough to use in real projects.

This module goes deep. You got a taste of TSL (Three Shading Language) back in Module 6, where it was a preview — a curiosity alongside your GLSL work. Now TSL becomes your primary shader authoring tool. You'll compose node-based materials in TypeScript with full type safety, chain operations instead of concatenating strings, and write shaders that compile to both WGSL (WebGPU) and GLSL (WebGL) without changing a line of code. The string-based GLSL era is ending.

The real headline, though, is compute shaders. WebGL couldn't do general-purpose GPU computation. You could hack around it with transform feedback and render-to-texture tricks, but they were painful and limited. WebGPU gives you first-class compute — the same capability that powers machine learning training, fluid simulations, and million-particle physics in native engines. You'll use it to build a 100k+ particle simulation where the GPU handles everything: position updates, velocity integration, force accumulation, collision detection, lifetime management, and color mapping. The CPU doesn't touch a single particle. It just says "go" and the GPU does the rest.

By the end, you'll have a particle system that would be physically impossible to run on the CPU at the same scale, controlled by leva sliders, with a WebGL fallback for browsers that haven't caught up yet.

---

## 1. Why WebGPU

### What WebGPU Replaces

WebGL is a JavaScript binding over OpenGL ES, a standard designed in 2007 for mobile phones. It works, and it's powered every browser-based 3D experience you've ever seen, but it carries decades of baggage:

- **Single-threaded command submission.** Every draw call, state change, and buffer upload blocks the main thread until the driver processes it. The driver itself often re-validates state redundantly.
- **No compute shaders.** WebGL 2.0 added transform feedback, but it's a hack for general-purpose GPU work. You can't do arbitrary read/write to buffers.
- **Implicit state machine.** WebGL is stateful — you bind a texture, set a uniform, draw, unbind. The order matters, and bugs from mis-ordered state are invisible until pixels go wrong.
- **Driver overhead.** The OpenGL driver does enormous amounts of work behind the scenes: validating state, compiling shaders on first use, managing memory implicitly. This is why WebGL apps sometimes stutter on first load.

WebGPU fixes all of this:

| Feature | WebGL 2 | WebGPU |
|---------|---------|--------|
| API model | Stateful (bind/unbind) | Explicit command buffers |
| Compute shaders | No | Yes |
| Pipeline objects | Implicit | Pre-compiled, reusable |
| Shader language | GLSL ES | WGSL (or GLSL via compilation) |
| Command submission | Single-threaded | Can record commands off main thread |
| Buffer access | Limited (read-back is painful) | First-class read/write storage buffers |
| Validation | Per-draw (driver overhead) | At pipeline creation (zero per-draw cost) |
| Multi-draw | Limited | Indirect draw, GPU-driven rendering |

### Performance Benefits

The performance gains come from three places:

1. **Reduced CPU overhead.** WebGPU pre-validates everything when you create a pipeline. At draw time, there's almost nothing for the CPU to do. In WebGL, the driver re-validates state on every single draw call. For scenes with hundreds of draw calls, this difference is massive.

2. **Compute shaders.** Moving simulation logic to the GPU eliminates the CPU-GPU data transfer bottleneck. A CPU particle system uploads position data to the GPU every frame. A GPU particle system keeps data on the GPU permanently — the CPU never touches it.

3. **Better batching and indirect draw.** WebGPU supports GPU-driven rendering where the GPU itself decides what to draw and how many instances. No CPU-side culling or draw call management needed.

### Browser Support (2026)

As of early 2026, WebGPU is available in:

- **Chrome/Edge:** Stable since Chrome 113 (May 2023). Full support.
- **Firefox:** Stable support shipped in late 2025. Fully usable.
- **Safari:** WebGPU support landed in Safari 18.x. Works on macOS and recent iOS.
- **Mobile:** Android Chrome has full support. iOS Safari has support on A15+ chips.

The practical reality: most of your users can run WebGPU. But not all of them. You still need a WebGL fallback for older devices, corporate browsers locked to old versions, and some mobile configurations. The good news is that Three.js and TSL make this fallback nearly seamless — the same material code compiles to both backends.

### The Rendering Pipeline Differences

WebGL uses an immediate-mode model: you set state, call draw, set more state, call draw again. Each call goes straight to the driver.

WebGPU uses a command buffer model:

```
1. Create pipeline objects (once, at init)
   - Shader modules
   - Bind group layouts
   - Render/compute pipeline descriptors

2. Each frame:
   - Create command encoder
   - Begin render pass
   - Set pipeline, bind groups, vertex buffers
   - Draw
   - End render pass
   - Submit command buffer to GPU queue
```

You don't need to manage this yourself — Three.js's `WebGPURenderer` handles it. But understanding the model helps you reason about performance: pipeline creation is expensive (do it once), command recording is cheap (do it every frame), and the GPU queue processes everything asynchronously.

---

## 2. Setting Up WebGPU in R3F

### The WebGPURenderer

Three.js ships `WebGPURenderer` as a drop-in replacement for `WebGLRenderer`. It handles the entire WebGPU initialization, pipeline management, and command recording. The critical difference from WebGL: initialization is **asynchronous**. The GPU adapter and device must be requested and awaited before rendering can begin.

### The Canvas gl Factory Pattern

R3F's `<Canvas>` component accepts a `gl` prop that can be a factory function. This is how you swap in `WebGPURenderer`:

```tsx
import { Canvas } from '@react-three/fiber'
import WebGPURenderer from 'three/webgpu'

export default function App() {
  return (
    <Canvas
      gl={(canvas) => {
        const renderer = new WebGPURenderer({
          canvas,
          antialias: true,
          forceWebGL: false,
        })
        return renderer
      }}
    >
      {/* Scene content */}
    </Canvas>
  )
}
```

### Async Initialization

Here's the catch: `WebGPURenderer` needs to call `.init()` before it can render anything. This is an async operation that requests the GPU adapter and device. R3F v9+ handles this automatically when you pass a `WebGPURenderer` instance — it detects the `.init()` method and awaits it before the first frame. But if you're on an older version, you need to handle it yourself:

```tsx
import { useState, useEffect } from 'react'
import { Canvas } from '@react-three/fiber'
import WebGPURenderer from 'three/webgpu'

function WebGPUCanvas({ children }: { children: React.ReactNode }) {
  const [ready, setReady] = useState(false)
  const [renderer, setRenderer] = useState<WebGPURenderer | null>(null)

  useEffect(() => {
    // Check if WebGPU is available
    if (!navigator.gpu) {
      console.warn('WebGPU not available, falling back to WebGL')
      setReady(true) // Will use default WebGL renderer
      return
    }

    const r = new WebGPURenderer({ antialias: true })
    r.init().then(() => {
      setRenderer(r)
      setReady(true)
    })
  }, [])

  if (!ready) return <div>Initializing GPU...</div>

  return (
    <Canvas
      gl={renderer ? (canvas) => {
        renderer.domElement = canvas
        return renderer
      } : undefined}
    >
      {children}
    </Canvas>
  )
}
```

### The Recommended Pattern (R3F v9+)

In practice, with R3F v9 and Three.js r170+, the simplest approach works:

```tsx
import { Canvas } from '@react-three/fiber'
import WebGPURenderer from 'three/webgpu'

export default function App() {
  return (
    <Canvas
      gl={(canvas) => {
        return new WebGPURenderer({
          canvas,
          antialias: true,
        })
      }}
    >
      <ambientLight intensity={0.5} />
      <directionalLight position={[5, 5, 5]} />
      <mesh>
        <boxGeometry />
        <meshStandardMaterial color="hotpink" />
      </mesh>
    </Canvas>
  )
}
```

R3F detects that the renderer has an async `.init()` and handles it. The first frame waits until initialization completes. No loading state required in simple cases.

### Fallback to WebGL

The robust pattern checks for WebGPU support and falls back gracefully:

```tsx
import { Canvas } from '@react-three/fiber'
import WebGPURenderer from 'three/webgpu'

function createRenderer(canvas: HTMLCanvasElement) {
  if (navigator.gpu) {
    return new WebGPURenderer({ canvas, antialias: true })
  }
  // Returning undefined tells R3F to use its default WebGLRenderer
  return undefined
}

export default function App() {
  return (
    <Canvas gl={(canvas) => createRenderer(canvas)}>
      {/* Same scene works with both renderers */}
    </Canvas>
  )
}
```

The beauty of this approach: TSL materials compile to both WGSL and GLSL. Your scene code doesn't change. The renderer is the only difference.

---

## 3. TSL Deep Dive

### The Mental Model Shift

In Module 6, you wrote shaders as GLSL strings inside template literals. That worked, but it had real problems:

- No TypeScript type checking inside strings
- No autocomplete or IDE support
- No composability — you copy-paste chunks of GLSL between shaders
- Errors show up as cryptic GPU compilation failures at runtime

TSL (Three Shading Language) replaces all of this with a functional, composable, TypeScript-native system. Instead of writing a string that says `vec3(1.0, 0.0, 0.0)`, you call a function: `vec3(1.0, 0.0, 0.0)`. Instead of writing `mix(a, b, t)` in GLSL, you write `mix(a, b, t)` in TypeScript — same name, but now your IDE knows the types, catches errors, and autocompletes.

The fundamental concept: **everything is a node**. A color is a node. A UV coordinate is a node. A math operation is a node. You compose nodes into a graph, and Three.js compiles that graph into the appropriate shader code for whichever backend you're running.

### Node Composition

TSL nodes are composable functions. Each node takes inputs and produces an output. You chain them together:

```tsx
import {
  color,
  mix,
  uv,
  sin,
  timerLocal,
  vec3,
  float,
} from 'three/tsl'

// A simple animated gradient
const time = timerLocal()                      // Auto-incrementing time value
const uvNode = uv()                            // UV coordinates (0-1)
const wave = sin(uvNode.x.mul(10.0).add(time)) // sin(uv.x * 10 + time)
const colorA = vec3(0.2, 0.5, 1.0)            // Blue
const colorB = vec3(1.0, 0.3, 0.1)            // Orange

// Mix between colors based on the wave
const finalColor = mix(colorA, colorB, wave.mul(0.5).add(0.5))
```

Notice the method chaining: `.mul()`, `.add()`, `.sub()`. Every TSL node has these arithmetic methods. They return new nodes, so you can keep chaining.

### Built-In TSL Functions

TSL mirrors GLSL's built-in functions, but as TypeScript imports:

**Math operations:**

| TSL Function | GLSL Equivalent | What It Does |
|--------------|----------------|--------------|
| `add(a, b)` or `a.add(b)` | `a + b` | Addition |
| `sub(a, b)` or `a.sub(b)` | `a - b` | Subtraction |
| `mul(a, b)` or `a.mul(b)` | `a * b` | Multiplication |
| `div(a, b)` or `a.div(b)` | `a / b` | Division |
| `mod(a, b)` | `mod(a, b)` | Modulo |
| `abs(a)` | `abs(a)` | Absolute value |
| `floor(a)` | `floor(a)` | Floor |
| `ceil(a)` | `ceil(a)` | Ceiling |
| `fract(a)` | `fract(a)` | Fractional part |
| `clamp(a, min, max)` | `clamp(a, min, max)` | Clamp to range |
| `min(a, b)` | `min(a, b)` | Minimum |
| `max(a, b)` | `max(a, b)` | Maximum |
| `pow(a, b)` | `pow(a, b)` | Power |
| `sqrt(a)` | `sqrt(a)` | Square root |

**Interpolation and shaping:**

| TSL Function | GLSL Equivalent | What It Does |
|--------------|----------------|--------------|
| `mix(a, b, t)` | `mix(a, b, t)` | Linear interpolation |
| `smoothstep(edge0, edge1, x)` | `smoothstep(edge0, edge1, x)` | Smooth hermite interpolation |
| `step(edge, x)` | `step(edge, x)` | 0 if x < edge, else 1 |

**Trigonometry:**

| TSL Function | GLSL Equivalent | What It Does |
|--------------|----------------|--------------|
| `sin(a)` | `sin(a)` | Sine |
| `cos(a)` | `cos(a)` | Cosine |
| `atan(a)` | `atan(a)` | Arctangent |

**Vector operations:**

| TSL Function | GLSL Equivalent | What It Does |
|--------------|----------------|--------------|
| `dot(a, b)` | `dot(a, b)` | Dot product |
| `cross(a, b)` | `cross(a, b)` | Cross product |
| `normalize(a)` | `normalize(a)` | Normalize to unit length |
| `length(a)` | `length(a)` | Vector length |
| `distance(a, b)` | `distance(a, b)` | Distance between vectors |
| `reflect(a, b)` | `reflect(a, b)` | Reflection |

**Time and inputs:**

| TSL Node | What It Provides |
|----------|-----------------|
| `timerLocal()` | Time in seconds since material creation (resets per material) |
| `timerGlobal()` | Time in seconds since renderer start (shared across all materials) |
| `uv()` | UV coordinates |
| `positionLocal` | Vertex position in local space |
| `positionWorld` | Vertex position in world space |
| `normalLocal` | Vertex normal in local space |
| `normalWorld` | Vertex normal in world space |
| `cameraPosition` | Camera position in world space |

### The Functional Composition Pattern

The power of TSL isn't any individual function — it's that every function returns a node you can feed into another function. You build shader logic the same way you build React component trees: small pieces composed into larger structures.

```tsx
import {
  uv, sin, cos, timerLocal, mix, vec3,
  smoothstep, length, sub, float,
} from 'three/tsl'

// Build a radial pulse effect, piece by piece
const time = timerLocal()
const center = vec3(0.5, 0.5, 0.0)
const uvPos = vec3(uv().x, uv().y, float(0.0))
const dist = length(sub(uvPos, center))

// Expanding ring
const ring = sin(dist.mul(20.0).sub(time.mul(3.0)))
const ringMask = smoothstep(float(-0.1), float(0.1), ring)

// Color: ring is bright cyan, background is dark blue
const bgColor = vec3(0.02, 0.02, 0.1)
const ringColor = vec3(0.0, 0.8, 1.0)
const finalColor = mix(bgColor, ringColor, ringMask)
```

Each variable is a node in the shader graph. Three.js traces the graph when you assign it to a material property and compiles the whole thing into optimized shader code.

---

## 4. TSL vs GLSL

### Side by Side: Animated Stripes

**GLSL version:**

```glsl
// vertex shader (standard passthrough)
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

// fragment shader
uniform float uTime;
varying vec2 vUv;
void main() {
  float stripe = step(0.5, fract(vUv.y * 10.0 + uTime));
  vec3 colorA = vec3(0.1, 0.1, 0.4);
  vec3 colorB = vec3(0.9, 0.3, 0.1);
  vec3 color = mix(colorA, colorB, stripe);
  gl_FragColor = vec4(color, 1.0);
}
```

**TSL version:**

```tsx
import { uv, step, fract, mix, vec3, float, timerLocal } from 'three/tsl'
import { MeshBasicNodeMaterial } from 'three/webgpu'

const time = timerLocal()
const stripe = step(float(0.5), fract(uv().y.mul(10.0).add(time)))
const colorA = vec3(0.1, 0.1, 0.4)
const colorB = vec3(0.9, 0.3, 0.1)
const finalColor = mix(colorA, colorB, stripe)

const material = new MeshBasicNodeMaterial()
material.colorNode = finalColor
```

Notice what's gone: no vertex shader boilerplate, no `varying` declarations, no `uniform` management, no `gl_FragColor`. TSL handles all the plumbing. You just describe the color computation.

### Side by Side: Fresnel Glow

**GLSL version:**

```glsl
// fragment shader
uniform float uTime;
varying vec3 vNormal;
varying vec3 vViewDir;

void main() {
  float fresnel = pow(1.0 - dot(normalize(vNormal), normalize(vViewDir)), 3.0);
  float pulse = sin(uTime * 2.0) * 0.3 + 0.7;
  vec3 glowColor = vec3(0.0, 0.5, 1.0) * fresnel * pulse;
  vec3 baseColor = vec3(0.05, 0.05, 0.1);
  gl_FragColor = vec4(baseColor + glowColor, 1.0);
}
```

**TSL version:**

```tsx
import {
  normalWorld, cameraPosition, positionWorld,
  normalize, sub, dot, pow, sin, timerLocal,
  vec3, float, mul, add,
} from 'three/tsl'
import { MeshBasicNodeMaterial } from 'three/webgpu'

const viewDir = normalize(sub(cameraPosition, positionWorld))
const fresnel = pow(
  sub(float(1.0), dot(normalize(normalWorld), viewDir)),
  float(3.0)
)
const pulse = sin(timerLocal().mul(2.0)).mul(0.3).add(0.7)
const glowColor = vec3(0.0, 0.5, 1.0).mul(fresnel).mul(pulse)
const baseColor = vec3(0.05, 0.05, 0.1)

const material = new MeshBasicNodeMaterial()
material.colorNode = add(baseColor, glowColor)
```

### When to Use Which

**Use TSL when:**
- You're targeting WebGPU (or want cross-backend compatibility)
- You want type safety and IDE autocomplete in your shaders
- You're composing multiple shader effects together
- You're building compute shaders (GLSL can't do this in WebGPU)

**Use GLSL when:**
- You're porting existing GLSL shaders from Shadertoy, tutorials, or other engines
- You need a specific GLSL feature that TSL doesn't wrap yet
- You're working with an older Three.js version or a WebGL-only project
- Community resources for a particular effect are in GLSL

### Migration Path

You don't have to convert everything at once. Three.js supports both in the same project. The practical migration:

1. Start new materials in TSL
2. Keep existing GLSL shaders working (they still compile under WebGPURenderer via GLSL-to-WGSL transpilation)
3. Convert GLSL to TSL when you need to modify an existing shader
4. Use TSL exclusively for compute shaders (there's no GLSL equivalent in WebGPU)

---

## 5. Node Materials

### MeshStandardNodeMaterial

Node materials are the TSL equivalents of Three.js's standard materials. They have the same base behavior (PBR lighting, shadow receiving, etc.) but expose node slots you can override:

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import { vec3, uv, sin, timerLocal, mix, float } from 'three/tsl'

function createAnimatedMaterial() {
  const material = new MeshStandardNodeMaterial()

  // Override the color output
  const time = timerLocal()
  const gradient = sin(uv().y.mul(5.0).add(time)).mul(0.5).add(0.5)
  material.colorNode = mix(
    vec3(0.1, 0.2, 0.8),  // Blue
    vec3(0.8, 0.2, 0.1),  // Red
    gradient
  )

  // Standard PBR properties still work
  material.roughness = 0.4
  material.metalness = 0.1

  return material
}
```

### Key Node Slots

Every node material exposes these override points:

| Node Slot | What It Controls | Default |
|-----------|-----------------|---------|
| `colorNode` | Base color (before lighting) | Solid color from `material.color` |
| `positionNode` | Vertex position in local space | `positionLocal` |
| `normalNode` | Surface normal | `normalLocal` |
| `outputNode` | Final output color (after lighting) | Computed PBR result |
| `opacityNode` | Alpha transparency | `material.opacity` |
| `emissiveNode` | Self-illumination | `material.emissive` |
| `roughnessNode` | Surface roughness | `material.roughness` |
| `metalnessNode` | Metallic factor | `material.metalness` |

### Customizing positionNode (Vertex Displacement)

Override `positionNode` to deform the mesh in the vertex shader:

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  positionLocal, normalLocal, sin, timerLocal,
  float, mul, add,
} from 'three/tsl'

const material = new MeshStandardNodeMaterial()

// Displace vertices along their normals using a sine wave
const time = timerLocal()
const displacement = sin(
  positionLocal.y.mul(5.0).add(time.mul(2.0))
).mul(0.2)

material.positionNode = add(
  positionLocal,
  mul(normalLocal, displacement)
)
```

This creates a wobbly pulsing effect — vertices push in and out along their normals in a wave pattern.

### Customizing normalNode

If you displace vertices, the normals become wrong (they still point in the original direction). For visual correctness, you should recompute normals. In simple cases, you can approximate:

```tsx
// Simple normal adjustment for Y-axis displacement
material.normalNode = normalize(
  add(normalLocal, vec3(0.0, displacement.mul(0.5), 0.0))
)
```

For production, compute the analytical derivative of your displacement function and adjust normals properly. But for stylized effects, the approximation is often good enough.

### Animating with timerLocal and timerGlobal

TSL provides two time nodes:

- **`timerLocal()`** — Seconds since this particular material was created. Each material has its own clock. Useful when you want materials to start their animation from zero independently.
- **`timerGlobal()`** — Seconds since the renderer started. Shared across all materials. Useful when you want everything to be in sync.

```tsx
const material = new MeshStandardNodeMaterial()

// Pulsing emissive glow synchronized across all objects
const globalTime = timerGlobal()
const pulse = sin(globalTime.mul(3.0)).mul(0.5).add(0.5)
material.emissiveNode = vec3(0.0, pulse, pulse.mul(0.5))
```

You don't need `useFrame` to update time. TSL time nodes auto-update every frame. One less thing to wire up.

### Using Node Materials in R3F

Since TSL materials are created imperatively, you use `useMemo` to create them once, then pass them to the `material` prop:

```tsx
import { useMemo } from 'react'
import { MeshStandardNodeMaterial } from 'three/webgpu'
import { vec3, uv, sin, timerLocal, mix } from 'three/tsl'

function AnimatedSphere() {
  const material = useMemo(() => {
    const mat = new MeshStandardNodeMaterial()
    const time = timerLocal()
    const wave = sin(uv().y.mul(8.0).add(time.mul(2.0))).mul(0.5).add(0.5)
    mat.colorNode = mix(vec3(0.0, 0.3, 1.0), vec3(1.0, 0.1, 0.3), wave)
    mat.roughness = 0.3
    return mat
  }, [])

  return (
    <mesh material={material}>
      <sphereGeometry args={[1, 64, 64]} />
    </mesh>
  )
}
```

---

## 6. Compute Shaders

### What Compute Shaders Are

Compute shaders are general-purpose programs that run on the GPU. Unlike vertex shaders (which process vertices) and fragment shaders (which process pixels), compute shaders process arbitrary data. They're not tied to the rendering pipeline at all — they just read data, crunch numbers, and write results.

This is the capability that makes GPU particle systems, physics simulations, and real-time fluid dynamics possible in the browser. Before WebGPU, you couldn't do this. Now you can.

### The Compute Model: Workgroups and Invocations

Compute shaders execute in a grid of **workgroups**, and each workgroup contains multiple **invocations** (individual threads). Think of it like this:

```
Dispatch(numGroupsX, numGroupsY, numGroupsZ)
  └── Workgroup [0,0,0] ─── 64 invocations
  └── Workgroup [1,0,0] ─── 64 invocations
  └── Workgroup [2,0,0] ─── 64 invocations
  ...
```

Each invocation knows:
- **Its global ID** — which particle/item in the total dataset it's responsible for
- **Its local ID** — its index within its workgroup
- **Its workgroup ID** — which workgroup it belongs to

For particle systems, the mapping is straightforward: one invocation per particle. If you have 100,000 particles with a workgroup size of 64, you dispatch `ceil(100000 / 64) = 1563` workgroups.

### Workgroup Size Considerations

The workgroup size (how many invocations per workgroup) affects performance:

- **64** is a safe default that works well across GPU architectures
- Must not exceed the device's `maxComputeInvocationsPerWorkgroup` limit (usually 256 or higher)
- Should be a multiple of the GPU's "warp" or "wavefront" size (32 for NVIDIA, 64 for AMD, 32 for Apple)
- Smaller workgroups waste GPU occupancy. Larger workgroups limit register usage.

For particle systems, 64 is the sweet spot. Don't overthink it unless you're profiling and need to squeeze out the last 5%.

### Compute in Three.js TSL

Three.js wraps the compute pipeline in TSL's functional style. You define a compute function using `Fn` and dispatch it:

```tsx
import { Fn, instanceIndex, storage, float, vec3 } from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'

// Create a storage buffer for particle positions (100k particles, 3 floats each)
const PARTICLE_COUNT = 100_000
const posArray = new Float32Array(PARTICLE_COUNT * 3)
const posAttribute = new StorageBufferAttribute(posArray, 3)
const posBuffer = storage(posAttribute, 'vec3', PARTICLE_COUNT)

// Define the compute shader
const computeParticles = Fn(() => {
  const index = instanceIndex  // Which particle am I?
  const pos = posBuffer.element(index)

  // Move particle upward
  pos.y.addAssign(float(0.01))
})().compute(PARTICLE_COUNT)
```

The `.compute(PARTICLE_COUNT)` call tells Three.js how many invocations to dispatch. It automatically calculates the number of workgroups based on a default workgroup size of 64.

### The Compute Pipeline

Each frame, you tell the renderer to execute your compute shader before rendering:

```tsx
import { useFrame } from '@react-three/fiber'

function ParticleSystem() {
  useFrame(({ gl }) => {
    // Run compute shader
    gl.computeAsync(computeParticles)
  })

  // ... render particles
}
```

The `computeAsync` method submits the compute work to the GPU queue. The GPU executes it before (or in parallel with) the render pass. No CPU involvement in the actual particle updates.

---

## 7. Storage Buffers

### GPU-Side Read/Write Data

Storage buffers are the data containers for compute shaders. Unlike uniforms (which are read-only and limited in size) and attributes (which are read-only in the shader), storage buffers can be **read and written** by compute shaders. This is what makes persistent GPU-side simulation possible.

### Creating StorageBufferAttribute

```tsx
import { StorageBufferAttribute } from 'three/webgpu'
import { storage } from 'three/tsl'

// Create a buffer for 100k vec3 values (positions)
const count = 100_000
const posArray = new Float32Array(count * 3)

// Initialize with random positions
for (let i = 0; i < count; i++) {
  posArray[i * 3 + 0] = (Math.random() - 0.5) * 20  // x
  posArray[i * 3 + 1] = Math.random() * 10           // y
  posArray[i * 3 + 2] = (Math.random() - 0.5) * 20  // z
}

// Create the storage buffer attribute
const posAttribute = new StorageBufferAttribute(posArray, 3)

// Wrap it as a TSL storage node
const posBuffer = storage(posAttribute, 'vec3', count)
```

The `StorageBufferAttribute` creates a GPU buffer initialized with the data from your Float32Array. After initialization, the data lives on the GPU. The CPU-side array is just for seeding initial values.

### Multiple Buffers for Complex Data

Real particle systems need more than positions. Create separate buffers for each data type:

```tsx
// Positions: vec3 (x, y, z)
const posArray = new Float32Array(count * 3)
const posAttribute = new StorageBufferAttribute(posArray, 3)
const posBuffer = storage(posAttribute, 'vec3', count)

// Velocities: vec3 (vx, vy, vz)
const velArray = new Float32Array(count * 3)
const velAttribute = new StorageBufferAttribute(velArray, 3)
const velBuffer = storage(velAttribute, 'vec3', count)

// Lifetimes: float (remaining life in seconds)
const lifeArray = new Float32Array(count)
const lifeAttribute = new StorageBufferAttribute(lifeArray, 1)
const lifeBuffer = storage(lifeAttribute, 'float', count)

// Colors: vec3 (r, g, b) — computed from velocity
const colorArray = new Float32Array(count * 3)
const colorAttribute = new StorageBufferAttribute(colorArray, 3)
const colorBuffer = storage(colorAttribute, 'vec3', count)
```

### Reading Back to CPU

Sometimes you need to read GPU data back to the CPU — for collision detection with game objects, for displaying debug info, or for saving state. This is expensive (it stalls the pipeline) so do it rarely:

```tsx
// Read back position data from GPU
async function readPositions(renderer: WebGPURenderer) {
  const data = await renderer.getArrayBufferAsync(posAttribute)
  const positions = new Float32Array(data)
  // Now you have CPU-side access to all particle positions
  return positions
}
```

The key word is **rarely**. Reading back data forces the GPU to finish all pending work and transfer data across the bus. It's a synchronization point that kills parallelism. For the particle system in this module, you'll never need to read back — everything stays on the GPU.

### Persistent Data Across Frames

Storage buffers persist between frames automatically. When your compute shader writes a particle's new position, that position is still there next frame when the compute shader reads it again. This is what makes simulation possible — each frame builds on the previous frame's state.

The lifecycle:

```
Frame 1: Compute reads positions → applies forces → writes new positions
Frame 1: Render reads positions → draws particles at new positions
Frame 2: Compute reads positions (from Frame 1) → applies forces → writes new positions
Frame 2: Render reads positions → draws particles at new positions
...
```

No CPU upload. No data transfer. The GPU owns the data permanently.

---

## 8. GPU Particle Systems

### The Architecture

A GPU particle system has two pipelines:

1. **Compute pipeline** — Runs every frame before rendering. Reads particle positions and velocities from storage buffers, applies forces, integrates motion, writes updated positions and velocities back.

2. **Render pipeline** — Reads particle positions from the same storage buffers (now updated) and renders them as points, billboards, or meshes.

The critical insight: **both pipelines share the same storage buffers**. The compute shader writes positions; the vertex shader reads them. Data never leaves the GPU.

```
┌─────────────────────────────────────────────┐
│                    GPU                       │
│                                              │
│  Storage Buffers: [positions] [velocities]   │
│       ▲                  │                   │
│       │    ┌─────────────┘                   │
│       │    │                                 │
│  ┌────┴────▼──────┐  ┌──────────────────┐   │
│  │ Compute Shader  │  │  Vertex Shader    │  │
│  │ (update physics)│  │  (read positions) │  │
│  └─────────────────┘  └──────────────────┘   │
│                            │                 │
│                       ┌────▼────────────┐    │
│                       │ Fragment Shader  │   │
│                       │ (color pixels)   │   │
│                       └─────────────────┘    │
└─────────────────────────────────────────────┘
                         │
                    Screen pixels
```

### Why Not CPU Particles?

Let's do the math. 100,000 particles, each with a position (3 floats) and velocity (3 floats). That's 600,000 floats = 2.4 MB of data.

**CPU approach:** Every frame, JavaScript loops over 100k particles, computes forces, updates positions, then uploads 2.4 MB to the GPU via `bufferSubData` or recreating the attribute. At 60fps, that's 144 MB/second of CPU-to-GPU transfer, plus the JavaScript loop overhead. You'll be lucky to hit 30fps.

**GPU approach:** Data never leaves the GPU. The compute shader processes all 100k particles in parallel. The GPU has thousands of cores running simultaneously. The entire update takes microseconds, not milliseconds. 60fps is effortless. You could push to 500k+ particles before the GPU starts to struggle.

### Rendering with Point Sprites

The simplest way to render particles is as points. Each particle is a single vertex rendered as a screen-space square:

```tsx
import { useMemo } from 'react'
import * as THREE from 'three'
import { StorageBufferAttribute } from 'three/webgpu'

function ParticleRenderer({
  posAttribute,
  colorAttribute,
  count,
}: {
  posAttribute: StorageBufferAttribute
  colorAttribute: StorageBufferAttribute
  count: number
}) {
  const geometry = useMemo(() => {
    const geo = new THREE.BufferGeometry()
    geo.setAttribute('position', posAttribute)
    geo.setAttribute('color', colorAttribute)
    geo.drawRange.count = count
    return geo
  }, [posAttribute, colorAttribute, count])

  return (
    <points geometry={geometry}>
      <pointsMaterial
        size={0.05}
        vertexColors
        transparent
        opacity={0.8}
        sizeAttenuation
        depthWrite={false}
        blending={THREE.AdditiveBlending}
      />
    </points>
  )
}
```

The `posAttribute` and `colorAttribute` are the same `StorageBufferAttribute` objects that the compute shader writes to. The vertex shader reads them directly — no copy, no transfer.

### Using Node Materials for Particle Rendering

For more control over how particles look, use a node material with `SpriteNodeMaterial` or a custom `PointsNodeMaterial`:

```tsx
import { PointsNodeMaterial } from 'three/webgpu'
import { storage, instanceIndex, attribute, vec4, float } from 'three/tsl'

const particleMaterial = new PointsNodeMaterial({
  transparent: true,
  depthWrite: false,
  blending: THREE.AdditiveBlending,
  sizeAttenuation: true,
})

// Set particle size
particleMaterial.size = 0.05

// Read color from storage buffer
particleMaterial.colorNode = storage(colorAttribute, 'vec3', count).element(instanceIndex)
```

---

## 9. Forces and Collision

### The Accumulate-Forces Pattern

Real physics engines accumulate all forces acting on a particle, then apply them all at once. Your compute shader should follow the same pattern:

```
For each particle:
  1. Start with zero acceleration
  2. Add gravity
  3. Add wind
  4. Add attractor force
  5. Apply acceleration to velocity (velocity += acceleration * dt)
  6. Apply velocity to position (position += velocity * dt)
  7. Check for collisions
  8. Handle lifetime
```

### Implementing Gravity

Gravity is the simplest force — a constant downward acceleration:

```tsx
import { Fn, instanceIndex, float, vec3, uniform } from 'three/tsl'

const gravity = uniform(vec3(0.0, -9.8, 0.0))
const deltaTime = uniform(float(0.016))

// Inside compute shader:
const computeForces = Fn(() => {
  const i = instanceIndex
  const vel = velBuffer.element(i)
  const pos = posBuffer.element(i)

  // Accumulate forces
  const acceleration = vec3(gravity)

  // Integrate velocity
  vel.addAssign(acceleration.mul(deltaTime))

  // Integrate position
  pos.addAssign(vel.mul(deltaTime))
})
```

### Implementing Wind

Wind is a constant horizontal force, but you can make it more interesting with noise or time-variance:

```tsx
const windForce = uniform(vec3(2.0, 0.0, 0.5))  // Push in +X and slight +Z

// Inside compute shader — add to acceleration:
const windVariation = sin(pos.x.mul(0.5).add(timerGlobal())).mul(0.3).add(1.0)
const wind = windForce.mul(windVariation)
acceleration.addAssign(wind)
```

### Implementing Attractors

An attractor pulls particles toward a point. The force is proportional to the inverse square of the distance (like gravity between masses), but clamped to avoid infinite force at zero distance:

```tsx
const attractorPos = uniform(vec3(0.0, 5.0, 0.0))    // Attractor position
const attractorStrength = uniform(float(50.0))         // Pull strength

// Inside compute shader:
const toAttractor = sub(attractorPos, pos)
const dist = max(length(toAttractor), float(0.5))  // Clamp minimum distance
const attractDir = normalize(toAttractor)
const attractForce = attractDir.mul(attractorStrength.div(dist.mul(dist)))
acceleration.addAssign(attractForce)
```

The `max(length, 0.5)` clamp prevents particles from experiencing infinite force when they're very close to the attractor. Without it, particles near the attractor would shoot off at ridiculous velocities.

### Floor Collision (Bounce)

Collision detection in a compute shader is straightforward for simple geometry. For a floor at y = 0:

```tsx
const bounceDamping = uniform(float(0.6))

// Inside compute shader, after position update:
// If particle is below the floor, bounce it
If(pos.y.lessThan(float(0.0)), () => {
  pos.y.assign(float(0.0))              // Push back to floor level
  vel.y.assign(vel.y.negate().mul(bounceDamping))  // Reverse and dampen Y velocity
  vel.x.mulAssign(float(0.95))          // Friction on X
  vel.z.mulAssign(float(0.95))          // Friction on Z
})
```

The `If` function in TSL generates a conditional branch in the shader. The bounce damping means each bounce loses energy — particles eventually come to rest on the floor. The X/Z friction prevents particles from sliding forever.

### Particle Lifetime and Respawning

Particles should eventually die and respawn. The lifetime buffer tracks remaining time:

```tsx
const maxLifetime = uniform(float(5.0))

// Inside compute shader:
const life = lifeBuffer.element(i)
life.subAssign(deltaTime)

// Respawn dead particles
If(life.lessThan(float(0.0)), () => {
  // Reset to emitter position with random velocity
  pos.assign(vec3(0.0, 0.0, 0.0))
  vel.assign(vec3(
    hash(i.add(timerGlobal().mul(1000.0))).sub(0.5).mul(10.0),
    hash(i.add(timerGlobal().mul(2000.0))).mul(15.0).add(5.0),
    hash(i.add(timerGlobal().mul(3000.0))).sub(0.5).mul(10.0),
  ))
  life.assign(maxLifetime.mul(hash(i.add(timerGlobal().mul(4000.0)))))
})
```

The `hash` function generates pseudo-random numbers in the shader. TSL provides `hash(value)` which produces a deterministic float in [0, 1] from any input. By adding time to the seed, you get different random values each time a particle respawns.

---

## 10. R3F v10 Alpha Features

### What's Changing

R3F v10 (currently in alpha/development as of early 2026) brings deeper WebGPU integration and new hooks that make working with node materials and compute shaders more ergonomic.

### Renderer Flexibility

R3F v10 treats the renderer as a first-class swappable concern. The `gl` factory pattern from Section 2 is now the standard approach, with better TypeScript types and automatic async handling:

```tsx
// R3F v10 pattern — renderer is fully typed
import { Canvas } from '@react-three/fiber'
import WebGPURenderer from 'three/webgpu'

<Canvas
  gl={(canvas) => new WebGPURenderer({ canvas, antialias: true })}
>
```

### useUniforms Hook

R3F v10 introduces `useUniforms` for creating reactive uniform values that bridge React state and TSL shaders without re-renders:

```tsx
import { useUniforms } from '@react-three/fiber'

function AnimatedMaterial() {
  const uniforms = useUniforms({
    color: new THREE.Color('#ff0000'),
    intensity: 1.0,
    mousePos: new THREE.Vector3(),
  })

  useFrame(({ pointer }) => {
    // Update uniforms directly — no re-render
    uniforms.mousePos.set(pointer.x * 10, pointer.y * 10, 0)
    uniforms.intensity = Math.sin(Date.now() * 0.001) * 0.5 + 1.0
  })

  // Use uniforms in TSL node material
  // ...
}
```

### useNodes Hook

The `useNodes` hook provides a pattern for creating and managing TSL node graphs within React's lifecycle:

```tsx
import { useNodes } from '@react-three/fiber'

function CustomShaderMesh() {
  const material = useNodes(() => {
    const mat = new MeshStandardNodeMaterial()
    const time = timerLocal()
    mat.colorNode = mix(vec3(1, 0, 0), vec3(0, 0, 1), sin(time))
    return mat
  }, [])

  return (
    <mesh material={material}>
      <sphereGeometry />
    </mesh>
  )
}
```

### Visibility Lifecycle Events

R3F v10 adds `onEnterView` and `onLeaveView` callbacks to meshes. These fire when an object enters or leaves the camera frustum, enabling efficient culling logic:

```tsx
<mesh
  onEnterView={() => { /* Start expensive simulation */ }}
  onLeaveView={() => { /* Pause simulation */ }}
>
  <sphereGeometry />
  <meshStandardMaterial />
</mesh>
```

For particle systems, this lets you pause compute shader dispatch when the particles aren't visible — a free performance win.

### Advanced Scheduler

The frame scheduler in v10 gives you finer control over update order:

```tsx
useFrame((state, delta) => {
  // Compute shader dispatch
}, -1)  // Negative priority: runs BEFORE default (0) priority

useFrame((state, delta) => {
  // Rendering-related updates
}, 1)   // Positive priority: runs AFTER default
```

This was already possible in earlier R3F versions, but v10 formalizes the priority system and adds named stages for clarity.

### A Note on Alpha APIs

R3F v10 features described here are based on the current alpha and may change before stable release. The core patterns — WebGPURenderer integration, TSL material usage, compute shader dispatch — are stable in the underlying Three.js layer. The R3F hooks are convenience wrappers that may shift in API surface. Check the R3F changelog when adopting v10 features.

---

## 11. Feature Detection and Fallback

### Checking for WebGPU

The check is simple: `navigator.gpu` exists if WebGPU is available.

```tsx
function isWebGPUAvailable(): boolean {
  return typeof navigator !== 'undefined' && !!navigator.gpu
}
```

But "available" doesn't mean "usable." The adapter request can still fail (e.g., if the GPU is blocklisted). A more robust check:

```tsx
async function isWebGPUUsable(): Promise<boolean> {
  if (!navigator.gpu) return false

  try {
    const adapter = await navigator.gpu.requestAdapter()
    if (!adapter) return false

    const device = await adapter.requestDevice()
    device.destroy() // Clean up — Three.js will create its own device
    return true
  } catch {
    return false
  }
}
```

### Graceful Degradation

The goal is that your app works everywhere — it's just better with WebGPU. The degradation ladder:

1. **WebGPU available:** Full compute shader particle system, TSL materials, maximum particle count
2. **WebGL 2 only:** Fall back to WebGLRenderer. TSL materials still compile (to GLSL). Particle system falls back to CPU-updated instanced points with a lower particle count.
3. **WebGL 1 only:** Same as WebGL 2 but with more feature restrictions. Rare in 2026.

### The Progressive Enhancement Pattern

```tsx
import { useState, useEffect, useMemo } from 'react'
import { Canvas } from '@react-three/fiber'
import WebGPURenderer from 'three/webgpu'

type GPUTier = 'webgpu' | 'webgl'

function useGPUTier(): GPUTier | null {
  const [tier, setTier] = useState<GPUTier | null>(null)

  useEffect(() => {
    if (navigator.gpu) {
      navigator.gpu.requestAdapter().then((adapter) => {
        setTier(adapter ? 'webgpu' : 'webgl')
      }).catch(() => setTier('webgl'))
    } else {
      setTier('webgl')
    }
  }, [])

  return tier
}

function App() {
  const gpuTier = useGPUTier()

  if (!gpuTier) return <div>Detecting GPU capabilities...</div>

  return (
    <Canvas
      gl={gpuTier === 'webgpu'
        ? (canvas) => new WebGPURenderer({ canvas, antialias: true })
        : undefined  // Default WebGLRenderer
      }
    >
      {gpuTier === 'webgpu' ? (
        <GPUParticleSystem count={100_000} />
      ) : (
        <CPUParticleSystem count={10_000} />
      )}
    </Canvas>
  )
}
```

The key insight: you have two implementations. The WebGPU version uses compute shaders and handles 100k+ particles. The WebGL fallback uses CPU-updated particles with 10x fewer particles. Both look good — the WebGPU version just looks *better*.

### Communicating GPU Tier to Users

Let users know what they're getting:

```tsx
function GPUBadge({ tier }: { tier: GPUTier }) {
  return (
    <div style={{
      position: 'fixed',
      bottom: 10,
      right: 10,
      padding: '4px 8px',
      background: tier === 'webgpu' ? '#00aa44' : '#aa8800',
      color: 'white',
      borderRadius: 4,
      fontSize: 12,
      fontFamily: 'monospace',
    }}>
      {tier === 'webgpu' ? 'WebGPU' : 'WebGL (reduced particles)'}
    </div>
  )
}
```

---

## Code Walkthrough: 100k+ GPU Particle Simulation

Let's build the complete mini-project. Every piece, from renderer setup to leva controls.

### Step 1: Project Setup

```bash
npm create vite@latest gpu-particles -- --template react-ts
cd gpu-particles
npm install three @react-three/fiber @react-three/drei leva
npm install -D @types/three
```

### Step 2: Global Styles

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
  background: #000;
}
```

### Step 3: Particle Buffers and Compute Shader

This is the core of the system. All particle logic lives in a single file that creates the storage buffers and defines the compute shader.

```tsx
// src/particles/particleCompute.ts
import {
  Fn,
  instanceIndex,
  storage,
  float,
  vec3,
  uniform,
  timerGlobal,
  If,
  hash,
  normalize,
  length,
  max,
  sub,
  sin,
  mix,
  clamp,
} from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'
import * as THREE from 'three'

export const PARTICLE_COUNT = 100_000

// --- Storage Buffers ---

// Positions
const posArray = new Float32Array(PARTICLE_COUNT * 3)
for (let i = 0; i < PARTICLE_COUNT; i++) {
  posArray[i * 3 + 0] = (Math.random() - 0.5) * 2  // x: tight initial spread
  posArray[i * 3 + 1] = Math.random() * 0.5         // y: near ground
  posArray[i * 3 + 2] = (Math.random() - 0.5) * 2  // z: tight initial spread
}
export const posAttribute = new StorageBufferAttribute(posArray, 3)
const posBuffer = storage(posAttribute, 'vec3', PARTICLE_COUNT)

// Velocities
const velArray = new Float32Array(PARTICLE_COUNT * 3)
for (let i = 0; i < PARTICLE_COUNT; i++) {
  velArray[i * 3 + 0] = (Math.random() - 0.5) * 10
  velArray[i * 3 + 1] = Math.random() * 15 + 5     // Strong upward initial burst
  velArray[i * 3 + 2] = (Math.random() - 0.5) * 10
}
export const velAttribute = new StorageBufferAttribute(velArray, 3)
const velBuffer = storage(velAttribute, 'vec3', PARTICLE_COUNT)

// Lifetimes
const lifeArray = new Float32Array(PARTICLE_COUNT)
for (let i = 0; i < PARTICLE_COUNT; i++) {
  lifeArray[i] = Math.random() * 5  // Random initial lifetime
}
export const lifeAttribute = new StorageBufferAttribute(lifeArray, 1)
const lifeBuffer = storage(lifeAttribute, 'float', PARTICLE_COUNT)

// Colors (computed from velocity in compute shader)
const colorArray = new Float32Array(PARTICLE_COUNT * 3)
export const colorAttribute = new StorageBufferAttribute(colorArray, 3)
const colorBuffer = storage(colorAttribute, 'vec3', PARTICLE_COUNT)

// --- Uniforms (controlled by leva) ---

export const uGravity = uniform(float(-9.8))
export const uWindX = uniform(float(2.0))
export const uWindZ = uniform(float(0.5))
export const uAttractorStrength = uniform(float(50.0))
export const uAttractorPos = uniform(new THREE.Vector3(0, 5, 0))
export const uMaxLifetime = uniform(float(5.0))
export const uBounceDamping = uniform(float(0.6))
export const uDeltaTime = uniform(float(0.016))
export const uEmitterSpread = uniform(float(8.0))
export const uInitialSpeed = uniform(float(12.0))

// --- Compute Shader ---

export const computeParticles = Fn(() => {
  const i = instanceIndex
  const pos = posBuffer.element(i)
  const vel = velBuffer.element(i)
  const life = lifeBuffer.element(i)
  const col = colorBuffer.element(i)
  const dt = uDeltaTime

  // --- Respawn dead particles ---
  const time = timerGlobal()
  const seed = float(i).add(time.mul(1000.0))

  If(life.lessThan(float(0.0)), () => {
    // Reset position at origin with spread
    pos.x.assign(hash(seed).sub(0.5).mul(uEmitterSpread))
    pos.y.assign(float(0.1))
    pos.z.assign(hash(seed.add(1.0)).sub(0.5).mul(uEmitterSpread))

    // Random upward velocity
    vel.x.assign(hash(seed.add(2.0)).sub(0.5).mul(uInitialSpeed))
    vel.y.assign(hash(seed.add(3.0)).mul(uInitialSpeed).add(float(5.0)))
    vel.z.assign(hash(seed.add(4.0)).sub(0.5).mul(uInitialSpeed))

    // Reset lifetime
    life.assign(uMaxLifetime.mul(hash(seed.add(5.0)).mul(0.8).add(0.2)))
  })

  // --- Accumulate forces ---

  // Gravity
  const accelX = float(0.0)
  const accelY = float(uGravity)
  const accelZ = float(0.0)

  // Wind (with spatial variation)
  const windVariation = sin(pos.x.mul(0.3).add(time.mul(0.7))).mul(0.4).add(1.0)
  const windX = uWindX.mul(windVariation)
  const windZ = uWindZ.mul(windVariation)

  // Attractor
  const toAttractor = sub(uAttractorPos, pos)
  const dist = max(length(toAttractor), float(0.5))
  const attractDir = normalize(toAttractor)
  const attractMag = uAttractorStrength.div(dist.mul(dist))

  // Sum forces
  const totalAccelX = accelX.add(windX).add(attractDir.x.mul(attractMag))
  const totalAccelY = accelY.add(attractDir.y.mul(attractMag))
  const totalAccelZ = accelZ.add(windZ).add(attractDir.z.mul(attractMag))

  // --- Integrate velocity ---
  vel.x.addAssign(totalAccelX.mul(dt))
  vel.y.addAssign(totalAccelY.mul(dt))
  vel.z.addAssign(totalAccelZ.mul(dt))

  // --- Integrate position ---
  pos.x.addAssign(vel.x.mul(dt))
  pos.y.addAssign(vel.y.mul(dt))
  pos.z.addAssign(vel.z.mul(dt))

  // --- Floor collision: bounce when y < 0 ---
  If(pos.y.lessThan(float(0.0)), () => {
    pos.y.assign(float(0.0))
    vel.y.assign(vel.y.negate().mul(uBounceDamping))
    vel.x.mulAssign(float(0.95))  // Friction
    vel.z.mulAssign(float(0.95))
  })

  // --- Decrement lifetime ---
  life.subAssign(dt)

  // --- Color from velocity magnitude ---
  // Slow = blue (0, 0.3, 1.0), Fast = red (1.0, 0.2, 0.0)
  const speed = length(vel)
  const speedNorm = clamp(speed.div(float(20.0)), float(0.0), float(1.0))

  const slowColor = vec3(0.0, 0.3, 1.0)
  const fastColor = vec3(1.0, 0.2, 0.0)
  const mappedColor = mix(slowColor, fastColor, speedNorm)

  // Fade out near end of life
  const lifeFade = clamp(life.div(float(0.5)), float(0.0), float(1.0))

  col.assign(mappedColor.mul(lifeFade))
})().compute(PARTICLE_COUNT)
```

That's the entire particle simulation. Let's break down the key decisions:

- **Separate buffers** for position, velocity, lifetime, and color. Each is a `StorageBufferAttribute` wrapped in a TSL `storage` node.
- **Uniforms** for all force parameters. These are controlled by leva sliders at runtime.
- **Force accumulation** pattern: gravity + wind + attractor, summed before integration.
- **Euler integration** (`vel += accel * dt`, `pos += vel * dt`). Simple and good enough for particles. Verlet or RK4 is overkill here.
- **Floor collision** at y = 0: reflect velocity, apply damping.
- **Lifetime** decrements by delta time. When it goes negative, the particle respawns.
- **Color mapping**: velocity magnitude mapped to a blue-to-red gradient. Fades to black near death.

### Step 4: Particle Renderer Component

```tsx
// src/particles/ParticleRenderer.tsx
import { useMemo } from 'react'
import * as THREE from 'three'
import {
  posAttribute,
  colorAttribute,
  PARTICLE_COUNT,
} from './particleCompute'

export function ParticleRenderer() {
  const geometry = useMemo(() => {
    const geo = new THREE.BufferGeometry()
    geo.setAttribute('position', posAttribute)
    geo.setAttribute('color', colorAttribute)
    geo.drawRange.count = PARTICLE_COUNT
    return geo
  }, [])

  return (
    <points geometry={geometry}>
      <pointsMaterial
        size={0.06}
        vertexColors
        transparent
        opacity={0.9}
        sizeAttenuation
        depthWrite={false}
        blending={THREE.AdditiveBlending}
      />
    </points>
  )
}
```

Additive blending makes overlapping particles glow brighter. `depthWrite={false}` prevents particles from occluding each other incorrectly — a standard trick for transparent particle rendering.

### Step 5: Compute Dispatcher Component

```tsx
// src/particles/ParticleSystem.tsx
import { useRef } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import {
  computeParticles,
  uDeltaTime,
  uGravity,
  uWindX,
  uWindZ,
  uAttractorStrength,
  uAttractorPos,
  uMaxLifetime,
  uBounceDamping,
  uEmitterSpread,
  uInitialSpeed,
} from './particleCompute'
import { ParticleRenderer } from './ParticleRenderer'
import { useControls } from 'leva'
import * as THREE from 'three'

export function ParticleSystem() {
  const { gl } = useThree()
  const mouseWorld = useRef(new THREE.Vector3(0, 5, 0))

  // Leva controls for all force parameters
  const {
    gravity,
    windX,
    windZ,
    attractorStrength,
    attractorFollow,
    maxLifetime,
    bounceDamping,
    emitterSpread,
    initialSpeed,
  } = useControls('Forces', {
    gravity: { value: -9.8, min: -30, max: 0, step: 0.1 },
    windX: { value: 2.0, min: -10, max: 10, step: 0.1 },
    windZ: { value: 0.5, min: -10, max: 10, step: 0.1 },
    attractorStrength: { value: 50, min: 0, max: 200, step: 1 },
    attractorFollow: { value: true, label: 'Attractor follows mouse' },
    maxLifetime: { value: 5, min: 1, max: 15, step: 0.5 },
    bounceDamping: { value: 0.6, min: 0, max: 1, step: 0.05 },
    emitterSpread: { value: 8, min: 1, max: 30, step: 1 },
    initialSpeed: { value: 12, min: 1, max: 30, step: 1 },
  })

  useFrame(({ pointer, camera, clock }, delta) => {
    // Clamp delta to prevent huge jumps on tab switch
    const dt = Math.min(delta, 0.05)

    // Update uniforms from leva
    uDeltaTime.value = dt
    uGravity.value = gravity
    uWindX.value = windX
    uWindZ.value = windZ
    uAttractorStrength.value = attractorStrength
    uMaxLifetime.value = maxLifetime
    uBounceDamping.value = bounceDamping
    uEmitterSpread.value = emitterSpread
    uInitialSpeed.value = initialSpeed

    // Project mouse to world space for attractor
    if (attractorFollow) {
      const vec = new THREE.Vector3(pointer.x, pointer.y, 0.5)
      vec.unproject(camera)
      const dir = vec.sub(camera.position).normalize()
      const dist = (5 - camera.position.y) / dir.y
      mouseWorld.current.copy(camera.position).add(dir.multiplyScalar(dist))
      mouseWorld.current.y = 5 // Keep attractor at y=5
      uAttractorPos.value.copy(mouseWorld.current)
    }

    // Dispatch compute shader
    gl.computeAsync(computeParticles)
  })

  return <ParticleRenderer />
}
```

The mouse-to-world projection places the attractor on a horizontal plane at y = 5. Moving your mouse around the screen drags the attractor through 3D space, pulling particles toward it.

### Step 6: Floor Grid

A simple visual reference so you can see the bouncing:

```tsx
// src/components/Floor.tsx
import { Grid } from '@react-three/drei'

export function Floor() {
  return (
    <Grid
      position={[0, 0, 0]}
      args={[50, 50]}
      cellSize={1}
      cellColor="#333333"
      sectionSize={5}
      sectionColor="#555555"
      fadeDistance={40}
      fadeStrength={1}
      infiniteGrid
    />
  )
}
```

### Step 7: Performance Stats

Show the performance difference:

```tsx
// src/components/PerfStats.tsx
import { useFrame } from '@react-three/fiber'
import { Html } from '@react-three/drei'
import { useRef, useState } from 'react'
import { PARTICLE_COUNT } from '../particles/particleCompute'

export function PerfStats() {
  const frames = useRef(0)
  const lastTime = useRef(performance.now())
  const [fps, setFps] = useState(60)
  const [drawCalls, setDrawCalls] = useState(0)

  useFrame(({ gl }) => {
    frames.current++
    const now = performance.now()
    const elapsed = now - lastTime.current

    if (elapsed >= 1000) {
      setFps(Math.round((frames.current * 1000) / elapsed))
      setDrawCalls(gl.info.render.calls)
      frames.current = 0
      lastTime.current = now
    }
  })

  return (
    <Html
      position={[0, 0, 0]}
      style={{
        position: 'fixed',
        top: 10,
        left: 10,
        color: '#00ff88',
        fontFamily: 'monospace',
        fontSize: 14,
        background: 'rgba(0,0,0,0.7)',
        padding: '8px 12px',
        borderRadius: 4,
        pointerEvents: 'none',
        whiteSpace: 'pre',
      }}
      center={false}
    >
      {`Particles: ${PARTICLE_COUNT.toLocaleString()}
FPS: ${fps}
Draw calls: ${drawCalls}
GPU: WebGPU (compute shaders)
CPU particle logic: NONE`}
    </Html>
  )
}
```

### Step 8: Main App with Fallback

```tsx
// src/App.tsx
import { useState, useEffect } from 'react'
import { Canvas } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'
import WebGPURenderer from 'three/webgpu'
import { ParticleSystem } from './particles/ParticleSystem'
import { Floor } from './components/Floor'
import { PerfStats } from './components/PerfStats'
import { Leva } from 'leva'

type GPUTier = 'webgpu' | 'webgl'

function useGPUTier(): GPUTier | null {
  const [tier, setTier] = useState<GPUTier | null>(null)

  useEffect(() => {
    if (navigator.gpu) {
      navigator.gpu.requestAdapter().then((adapter) => {
        setTier(adapter ? 'webgpu' : 'webgl')
      }).catch(() => setTier('webgl'))
    } else {
      setTier('webgl')
    }
  }, [])

  return tier
}

export default function App() {
  const gpuTier = useGPUTier()

  if (!gpuTier) {
    return (
      <div style={{
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100vh',
        fontFamily: 'monospace',
      }}>
        Detecting GPU capabilities...
      </div>
    )
  }

  if (gpuTier === 'webgl') {
    return (
      <div style={{
        color: '#ffaa00',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100vh',
        fontFamily: 'monospace',
        textAlign: 'center',
        padding: 40,
      }}>
        WebGPU is not available in your browser.
        <br />
        This demo requires compute shaders.
        <br />
        Try Chrome 113+, Firefox 125+, or Safari 18+.
      </div>
    )
  }

  return (
    <>
      <Leva collapsed />
      <Canvas
        camera={{ position: [0, 15, 25], fov: 50 }}
        gl={(canvas) =>
          new WebGPURenderer({ canvas, antialias: true })
        }
      >
        <color attach="background" args={['#050510']} />
        <ambientLight intensity={0.1} />

        <ParticleSystem />
        <Floor />
        <PerfStats />

        <OrbitControls
          enableDamping
          dampingFactor={0.05}
          minDistance={5}
          maxDistance={80}
        />
      </Canvas>
    </>
  )
}
```

### Step 9: Performance Comparison

Here's what you should see:

| Metric | GPU Particles (this project) | CPU Particles (equivalent) |
|--------|------------------------------|---------------------------|
| Particle count | 100,000 | ~5,000–10,000 max |
| FPS | 60 (stable) | 20–40 (struggling) |
| Draw calls | 1 | 1 |
| CPU time per frame | ~0.1 ms (just dispatching) | ~8–15 ms (JS loop + upload) |
| GPU time per frame | ~0.5 ms (compute + render) | ~0.3 ms (render only) |
| Data transfer/frame | 0 bytes | 2.4 MB |

The CPU version spends most of its frame budget on a JavaScript loop iterating over 100k particles and uploading position data. The GPU version offloads all of that to the GPU's massively parallel compute units. The CPU basically does nothing — it just says "run the compute shader" and "draw the particles."

### Run It

```bash
npm run dev
```

You should see a fountain of 100,000 particles erupting from the ground, arcing under gravity, bouncing off the floor, getting pulled toward your mouse cursor, and coloring themselves from blue (slow) to red (fast). The leva panel lets you tune every force in real time. FPS should be locked at 60.

---

## Common Pitfalls

### 1. Not Awaiting WebGPURenderer.init()

```tsx
// WRONG — renderer isn't ready, first frames are blank or crash
const renderer = new WebGPURenderer({ canvas })
// Immediately start rendering without init()

// RIGHT — use the gl factory pattern and let R3F handle async init
<Canvas
  gl={(canvas) => new WebGPURenderer({ canvas, antialias: true })}
>
```

R3F v9+ detects the async `.init()` method and calls it automatically. If you're manually managing the renderer, you must `await renderer.init()` before the first render call.

### 2. WebGPU Not Available (No Feature Detection)

```tsx
// WRONG — app crashes on browsers without WebGPU
import WebGPURenderer from 'three/webgpu'

<Canvas gl={(canvas) => new WebGPURenderer({ canvas })}>
  <ComputeParticles />  {/* Uses compute shaders that don't exist in WebGL */}
</Canvas>

// RIGHT — check availability, provide fallback
function App() {
  const gpuTier = useGPUTier()  // 'webgpu' | 'webgl' | null

  return (
    <Canvas
      gl={gpuTier === 'webgpu'
        ? (canvas) => new WebGPURenderer({ canvas, antialias: true })
        : undefined
      }
    >
      {gpuTier === 'webgpu' ? (
        <GPUParticles count={100_000} />
      ) : (
        <CPUParticles count={5_000} />
      )}
    </Canvas>
  )
}
```

### 3. Storage Buffer Size Mismatch

```tsx
// WRONG — compute shader writes 100k elements but buffer only has 50k
const posArray = new Float32Array(50_000 * 3)
const posAttribute = new StorageBufferAttribute(posArray, 3)
const posBuffer = storage(posAttribute, 'vec3', 50_000)

// But compute dispatches 100k invocations
const compute = Fn(() => {
  const pos = posBuffer.element(instanceIndex)
  pos.y.addAssign(float(0.01))
})().compute(100_000)  // Writing out of bounds!

// RIGHT — buffer size matches dispatch count
const PARTICLE_COUNT = 100_000
const posArray = new Float32Array(PARTICLE_COUNT * 3)
const posAttribute = new StorageBufferAttribute(posArray, 3)
const posBuffer = storage(posAttribute, 'vec3', PARTICLE_COUNT)

const compute = Fn(() => {
  const pos = posBuffer.element(instanceIndex)
  pos.y.addAssign(float(0.01))
})().compute(PARTICLE_COUNT)  // Matches buffer size
```

Writing past the end of a storage buffer is undefined behavior. On some GPUs it silently corrupts memory. On others it crashes the device. Always make sure your buffer size and dispatch count match.

### 4. Forgetting Workgroup Size Considerations

```tsx
// WRONG — unusual particle count with no consideration
const compute = Fn(() => { /* ... */ })().compute(99_999)
// 99999 / 64 = 1562.48 — last workgroup has partially empty invocations
// Some of those invocations may read garbage data

// RIGHT — either use a count that's a multiple of 64, or guard in the shader
const PARTICLE_COUNT = 100_000  // Not a multiple of 64, but that's OK if guarded

const compute = Fn(() => {
  const i = instanceIndex

  // Guard: skip invocations beyond our particle count
  If(i.greaterThanEqual(uint(PARTICLE_COUNT)), () => {
    return  // Early exit for padding invocations
  })

  // ... particle logic
})().compute(PARTICLE_COUNT)
```

Three.js pads the dispatch to the next workgroup boundary. Those extra invocations need to be harmless — either guard with an index check or make sure your buffers are sized to the padded count.

### 5. TSL Node Type Mismatches

```tsx
// WRONG — mixing vec3 and float without explicit conversion
const pos = posBuffer.element(i)  // vec3
const offset = float(1.0)         // float
pos.assign(offset)                 // Type mismatch! Can't assign float to vec3

// RIGHT — explicit type matching
pos.assign(vec3(offset, offset, offset))
// Or use the shorthand:
pos.assign(vec3(1.0, 1.0, 1.0))

// WRONG — adding vec3 + float directly
const result = pos.add(float(1.0))  // Ambiguous in some backends

// RIGHT — be explicit about broadcast
const result = pos.add(vec3(1.0, 1.0, 1.0))
```

TSL is typed, and the types must match. `vec3` operations need `vec3` operands. If you pass a `float` where a `vec3` is expected, you'll get a compilation error — but the error message might be cryptic since it comes from the WGSL/GLSL compiler, not TypeScript.

---

## Exercises

### Exercise 1: WebGPU Renderer with Automatic WebGL Fallback

**Time:** 20–30 minutes

Set up a Canvas that detects WebGPU availability and falls back to WebGL automatically. Display a badge showing which renderer is active.

Hints:
- Use `navigator.gpu` for the initial check
- Wrap the detection in a custom hook with `useState` and `useEffect`
- Pass `undefined` to the `gl` prop for default WebGL behavior
- Show a small overlay indicating "WebGPU" or "WebGL" mode

**Stretch goal:** Request the actual adapter and log its `name` and `features` to the console. Display the GPU name in the badge.

### Exercise 2: TSL Node Material with Animated Color

**Time:** 30–40 minutes

Create a `MeshStandardNodeMaterial` that cycles through colors over time using TSL nodes. Apply it to a sphere.

Requirements:
- Use `timerLocal()` for time
- Mix between at least 3 colors using `sin` waves at different frequencies
- Override `colorNode` with your composed color
- The color should shift smoothly and continuously

Hints:
- `sin(time.mul(speed)).mul(0.5).add(0.5)` gives you a 0-1 oscillator
- Use different speeds for R, G, B channels: `vec3(rOsc, gOsc, bOsc)`
- Wrap the material creation in `useMemo` to avoid recreating it every render

**Stretch goal:** Add vertex displacement using `positionNode` that makes the sphere pulse in sync with the color changes.

### Exercise 3: Simple Compute Shader (Circular Motion)

**Time:** 40–50 minutes

Write a compute shader that moves 10,000 particles in circles. Each particle orbits at a different radius and speed.

Requirements:
- Storage buffers for positions (vec3) and orbit parameters (radius, speed, angle — stored as vec3)
- Compute shader that updates angle by `speed * dt`, then computes `x = cos(angle) * radius`, `z = sin(angle) * radius`
- Render as colored points
- Initialize particles with random radii (2–15) and random speeds (0.5–3.0)

Hints:
- The orbit parameters buffer stores `(radius, speed, currentAngle)` per particle
- Only the angle changes each frame — radius and speed are constants
- Color by radius: inner particles red, outer particles blue

**Stretch goal:** Make the Y position bob up and down using `sin(angle * 2.0)` so particles trace helical paths.

### Exercise 4: Mouse-Following Attractor Force (Stretch)

**Time:** 60–90 minutes

Take the circular orbit system from Exercise 3 and add attractor physics. When you hold the mouse button, particles break out of their orbits and get pulled toward the mouse position. When you release, they gradually return to orbiting.

Requirements:
- Project mouse position to world space (use the plane-intersection technique from the walkthrough)
- Add an attractor force uniform
- Blend between orbit behavior and attractor behavior using a uniform `attractorActive` (0 or 1)
- Particles should smoothly transition between states
- Add velocity damping so particles don't fly off to infinity

Hints:
- When `attractorActive` is 0, run pure circular orbit logic
- When `attractorActive` is 1, apply attractor force and integrate velocity
- Use `mix(orbitPos, physicsPos, attractorActive)` for smooth blending
- Add leva controls for attractor strength and damping

---

## API Quick Reference

### WebGPU Setup

| API | What It Does |
|-----|-------------|
| `new WebGPURenderer({ canvas, antialias })` | Creates a WebGPU-backed renderer |
| `renderer.init()` | Async initialization (requests GPU adapter + device) |
| `renderer.computeAsync(computeNode)` | Dispatches a compute shader |
| `navigator.gpu` | WebGPU API entry point (check for existence) |
| `navigator.gpu.requestAdapter()` | Requests GPU adapter (async) |

### TSL Core

| Function | What It Does |
|----------|-------------|
| `vec3(x, y, z)` | Create a vec3 node |
| `float(x)` | Create a float node |
| `uniform(value)` | Create a uniform node (updatable from CPU) |
| `storage(attr, type, count)` | Wrap a StorageBufferAttribute as a TSL node |
| `Fn(() => { ... })` | Define a shader function |
| `.compute(count)` | Mark a function as a compute shader with N invocations |
| `instanceIndex` | Current invocation index in compute shader |
| `timerLocal()` / `timerGlobal()` | Auto-updating time nodes |
| `uv()` | UV coordinates |
| `positionLocal` / `positionWorld` | Vertex position nodes |
| `normalLocal` / `normalWorld` | Normal nodes |

### TSL Math

| Function | GLSL Equivalent |
|----------|----------------|
| `a.add(b)` | `a + b` |
| `a.sub(b)` | `a - b` |
| `a.mul(b)` | `a * b` |
| `a.div(b)` | `a / b` |
| `a.addAssign(b)` | `a += b` |
| `a.mulAssign(b)` | `a *= b` |
| `a.negate()` | `-a` |
| `mix(a, b, t)` | `mix(a, b, t)` |
| `smoothstep(e0, e1, x)` | `smoothstep(e0, e1, x)` |
| `clamp(x, min, max)` | `clamp(x, min, max)` |
| `length(v)` | `length(v)` |
| `normalize(v)` | `normalize(v)` |
| `dot(a, b)` | `dot(a, b)` |
| `cross(a, b)` | `cross(a, b)` |
| `hash(x)` | Pseudo-random float in [0, 1] |

### TSL Control Flow

| Function | What It Does |
|----------|-------------|
| `If(condition, () => { ... })` | Conditional branch |
| `Loop(count, ({ i }) => { ... })` | Loop N times |
| `a.lessThan(b)` | `a < b` |
| `a.greaterThan(b)` | `a > b` |
| `a.greaterThanEqual(b)` | `a >= b` |
| `a.equal(b)` | `a == b` |

### Node Material Slots

| Slot | What It Controls |
|------|-----------------|
| `colorNode` | Base color before lighting |
| `positionNode` | Vertex position (displacement) |
| `normalNode` | Surface normal |
| `outputNode` | Final color after lighting |
| `opacityNode` | Alpha |
| `emissiveNode` | Self-illumination |
| `roughnessNode` | PBR roughness |
| `metalnessNode` | PBR metalness |

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [Three.js TSL Documentation](https://threejs.org/docs/pages/TSL.html) | Official Docs | The authoritative TSL reference. Node types, composition patterns, examples. |
| [WebGPU Fundamentals](https://webgpufundamentals.org) | Tutorial | Deep explanation of the WebGPU API from scratch. Best conceptual resource. |
| [Three.js WebGPU Examples](https://threejs.org/examples/?q=webgpu) | Examples | Official examples showing compute, TSL materials, and GPU particles in action. |
| [WebGPU Specification](https://www.w3.org/TR/webgpu/) | Spec | The W3C spec. Dense but authoritative when you need exact behavior. |
| [WGSL Specification](https://www.w3.org/TR/WGSL/) | Spec | WebGPU Shading Language spec. Helpful when TSL generates unexpected WGSL. |
| [Compute Shader Introduction (Google)](https://developer.chrome.com/docs/web-platform/webgpu/compute) | Tutorial | Chrome team's guide to compute shaders. Good for understanding workgroups. |
| [R3F WebGPU Discussion](https://github.com/pmndrs/react-three-fiber/discussions) | Community | Track R3F's WebGPU integration progress and community patterns. |

---

## Key Takeaways

1. **WebGPU is a generational leap, not an incremental upgrade.** It replaces WebGL's stateful, single-threaded, render-only model with explicit command buffers, compute shaders, and GPU-driven pipelines. The performance gap is real and measurable.

2. **TSL replaces GLSL strings with typed, composable TypeScript.** Every shader operation is a function. Every function returns a node you can feed into another function. Your IDE catches type errors. Your shaders compose like React components. The string-based GLSL era is ending.

3. **Compute shaders unlock GPU-general-purpose computation.** Anything that can be expressed as "do this same thing to N items in parallel" belongs in a compute shader. Particles, physics, spatial queries, procedural generation — all of it.

4. **Storage buffers keep data on the GPU.** The moment data crosses the CPU-GPU bus, you lose. Storage buffers let compute shaders write data that render shaders read, with zero transfer. This is what makes 100k+ particle systems possible at 60fps.

5. **Always feature-detect and fall back gracefully.** Not every browser supports WebGPU. Not every GPU supports every feature. Check `navigator.gpu`, request an adapter, and have a WebGL fallback ready. Your app should work everywhere and shine where it can.

6. **The force accumulation pattern is universal.** Gravity, wind, attractors, drag — every force is a vec3 that gets added to an acceleration accumulator. Then you integrate: velocity += acceleration * dt, position += velocity * dt. This pattern works in compute shaders, CPU physics, and every physics engine ever written.

---

## What's Next?

You've reached the bleeding edge. You can set up a WebGPU renderer, author shaders in TSL, dispatch compute shaders, and build GPU-driven simulations that would be impossible on the CPU alone. This is the most technically advanced module in the roadmap.

**[Module 13: Build, Ship & What's Next](module-13-ship-whats-next.md)** brings it all together. You'll optimize your game for production, compress assets, configure Vite for deployment, and ship to the web. You'll also look at what's coming next: XR, AI integration, and where the React 3D ecosystem is heading. Time to put your game in front of players.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)