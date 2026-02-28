# Module 16: TSL Ecosystem & Real-World Patterns

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 6–10 hours
**Prerequisites:** [Module 14: TSL Materials & Textures](module-14-tsl-materials-textures.md), [Module 15: TSL Compute — Advanced Patterns](module-15-tsl-compute-advanced.md)

---

## Overview

You've covered a lot of ground. Module 6 introduced you to shaders from scratch — GLSL strings, `ShaderMaterial`, uniforms, the vertex/fragment pipeline. Module 12 pivoted to WebGPU and TSL as your primary authoring tool, replacing GLSL strings with composable TypeScript nodes that compile to both WGSL and GLSL. Modules 14 and 15 went deep: TSL materials with texture sampling, PBR overrides, procedural noise, and GPU compute with storage buffers and dispatch patterns.

This module is about making TSL work in the real world. Writing TSL in isolation is one thing; integrating it with the libraries you already use — drei, post-processing, instancing systems, TypeScript's type system — is another. You'll hit friction points that the documentation glosses over: which drei materials accept TSL node overrides and which silently ignore them, how to write post-processing effects that interoperate with TSL `outputNode`, how to get autocomplete working with `three/tsl` imports, and how to debug the WGSL that TSL generates.

The centerpiece is a Retrofit Project: three objects that originally use GLSL `ShaderMaterial` (an energy shield, a terrain material, a holographic display), converted to TSL, then extended with compute-driven particles and a TSL post-processing pass. You'll see the before/after side by side for each shader, understand why the TSL version is easier to maintain, and have a complete scene that demonstrates every integration pattern covered in this module. By the end, TSL won't feel like a new tool — it'll feel like the only reasonable way to write shaders for the web.

---

## 1. TSL + Drei

Drei's material helpers are time-savers, but they have an important caveat: many of them are wrappers around specific `Three.js` material subclasses, and whether TSL node overrides work depends on whether the underlying material is a `NodeMaterial` subclass. As of Three.js r170+, the node material system is mature, and most drei materials can be extended — but you need to know the pattern.

### MeshStandardNodeMaterial as a Drop-In

The cleanest path: use `MeshStandardNodeMaterial` directly instead of `meshStandardMaterial`, then add TSL overrides. This gives you the full PBR pipeline with arbitrary node overrides.

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import { color, mix, texture, uv, time, sin, float, normalLocal, dot, max } from 'three/tsl'
import { useTexture } from '@react-three/drei'

function EnhancedRockMaterial() {
  const albedoMap = useTexture('/textures/rock-albedo.jpg')
  const normalMap = useTexture('/textures/rock-normal.jpg')
  const roughnessMap = useTexture('/textures/rock-roughness.jpg')

  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial()

    // Standard PBR inputs
    m.colorNode = texture(albedoMap, uv())

    // Procedural moss overlay based on up-facing normals
    const worldUp = vec3(0, 1, 0)
    const upFacing = max(dot(normalLocal, worldUp), float(0))
    const mossColor = color('#2d4a1e')
    const mossMask = smoothstep(float(0.6), float(0.9), upFacing)

    // Pulse the moss to show it's "alive"
    const pulse = sin(time.mul(0.5)).mul(0.1).add(0.9)
    m.colorNode = mix(texture(albedoMap, uv()), mossColor.mul(pulse), mossMask)

    // Moss areas are wetter (smoother)
    m.roughnessNode = mix(texture(roughnessMap, uv()), float(0.2), mossMask)
    m.normalNode = texture(normalMap, uv())
    m.metalnessNode = float(0)

    return m
  }, [albedoMap, normalMap, roughnessMap])

  return (
    <mesh>
      <sphereGeometry args={[1, 64, 64]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

### MeshPhysicalNodeMaterial with TSL Overrides

Physical materials add clearcoat, transmission, and iridescence. All of these have node-overrideable counterparts in `MeshPhysicalNodeMaterial`. Here's an enhanced glass material with procedural refraction distortion — something that would require a custom shader in WebGL but is just a few node composites here.

```tsx
import {
  MeshPhysicalNodeMaterial,
} from 'three/webgpu'
import {
  color, float, uv, time, sin, cos, vec2, texture, normalLocal,
  vec3, mix, smoothstep, screenUV, viewportSharedTexture, Fn
} from 'three/tsl'
import { useTexture } from '@react-three/drei'

function EnhancedGlassMaterial() {
  const matcapMap = useTexture('/textures/glass-matcap.png')

  const mat = useMemo(() => {
    const m = new MeshPhysicalNodeMaterial({
      transmission: 1.0,
      thickness: 0.5,
      roughness: 0.05,
      ior: 1.5,
    })

    // Animated distortion offset applied to refraction UVs
    // This creates a "warping" effect as if the glass is rippling
    const distortionStrength = float(0.02)
    const wave1 = sin(uv().x.mul(8).add(time)).mul(distortionStrength)
    const wave2 = cos(uv().y.mul(6).add(time.mul(0.7))).mul(distortionStrength)
    const distortedUV = uv().add(vec2(wave1, wave2))

    // Sample the background through distorted UVs for faked refraction
    const refractedBg = viewportSharedTexture(screenUV.add(vec2(wave1, wave2)))

    // Fresnel: show refraction on flat faces, tint on glancing angles
    const fresnel = float(1).sub(
      normalLocal.dot(vec3(0, 0, 1)).abs()
    ).pow(float(2))
    const tintColor = color('#a0c8ff')

    m.colorNode = mix(refractedBg, tintColor, fresnel.mul(0.4))

    // Iridescent clearcoat: color shifts based on view angle
    m.clearcoatNode = float(1)
    m.clearcoatRoughnessNode = float(0.05)

    return m
  }, [matcapMap])

  return (
    <mesh>
      <sphereGeometry args={[1, 64, 64]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

### Converting drei's shaderMaterial to nodesMaterial

Drei's `shaderMaterial` helper creates a `ShaderMaterial` subclass with typed props. To convert it to TSL, use `nodesMaterial` instead — a similar helper that creates a `NodeMaterial` subclass with TSL node inputs.

```tsx
// BEFORE: drei shaderMaterial (GLSL strings)
import { shaderMaterial } from '@react-three/drei'

const GlowMaterial = shaderMaterial(
  { uTime: 0, uColor: new Color('#ff6600') },
  /* glsl */ `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  /* glsl */ `
    varying vec2 vUv;
    uniform float uTime;
    uniform vec3 uColor;
    void main() {
      float glow = sin(vUv.x * 10.0 + uTime) * 0.5 + 0.5;
      gl_FragColor = vec4(uColor * glow, 1.0);
    }
  `
)

// AFTER: TSL node material (type-safe, composable)
import { MeshStandardNodeMaterial } from 'three/webgpu'
import { color, uv, time, sin, float, uniform, vec4 } from 'three/tsl'

function GlowMaterialTSL({ baseColor = '#ff6600' }: { baseColor?: string }) {
  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial()

    // Uniforms become typed uniform() nodes — reactive to prop changes
    const uColor = uniform(new Color(baseColor))
    const glow = sin(uv().x.mul(10).add(time)).mul(0.5).add(0.5)

    m.colorNode = uColor.mul(glow)
    m.emissiveNode = uColor.mul(glow).mul(float(2)) // Self-illuminating glow

    // Store the uniform so we can update it from props
    ;(m as any).__uColor = uColor

    return m
  }, []) // Note: recreate if baseColor changes structurally; or use useEffect to update

  // Update the color uniform when prop changes without recreating material
  useEffect(() => {
    const m = mat as any
    if (m.__uColor) {
      m.__uColor.value.set(baseColor)
    }
  }, [baseColor, mat])

  return <primitive object={mat} />
}
```

### Extending MeshReflectorMaterial

`MeshReflectorMaterial` from drei uses its own reflection pass. As of Three.js r170+, you can stack TSL overrides on top — but only via `onBeforeCompile` for WebGL or by using `MeshStandardNodeMaterial` with a manual reflection texture.

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  texture, uv, time, sin, vec2, screenUV, viewportSharedTexture,
  mix, color, float, normalLocal, vec3, dot, abs, smoothstep
} from 'three/tsl'

// Build a floor material that simulates reflections via screen-space sampling
// This is a TSL-native alternative to MeshReflectorMaterial
function TSLReflectorMaterial({ roughness = 0.1 }) {
  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial()

    // Animated ripple distortion for wet floor effect
    const rippleFreq = float(20)
    const rippleSpeed = float(1.5)
    const rippleAmp = float(0.003)

    const ripple = sin(
      uv().x.mul(rippleFreq).add(time.mul(rippleSpeed))
    ).mul(rippleAmp)

    const distortedScreen = screenUV.add(vec2(ripple, ripple.mul(0.5)))
    const reflectionSample = viewportSharedTexture(distortedScreen)

    // Fresnel: more reflective at glancing angles
    const fresnel = float(1).sub(
      abs(dot(normalLocal, vec3(0, 1, 0)))
    ).pow(float(3))

    const floorColor = color('#1a1a1a')
    m.colorNode = mix(floorColor, reflectionSample, fresnel.mul(0.8))
    m.roughnessNode = float(roughness)
    m.metalnessNode = float(0)

    return m
  }, [roughness])

  return (
    <mesh rotation={[-Math.PI / 2, 0, 0]}>
      <planeGeometry args={[20, 20, 1, 1]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

The key insight: for serious TSL work, prefer `MeshStandardNodeMaterial` or `MeshPhysicalNodeMaterial` from `three/webgpu` over drei's wrappers. Drei's wrappers are convenient for their specific features but add an integration layer that can fight against node overrides. When you need both (e.g., the actual reflection render pass from `MeshReflectorMaterial`), use drei for the pass configuration and then read the resulting render target texture as a TSL `texture()` node.

---

## 2. TSL + Post-Processing

Post-processing effects in `@react-three/postprocessing` work by extending the `Effect` class from the `postprocessing` library. That class ultimately generates a GLSL fragment shader. This creates a layering problem: TSL generates WGSL/GLSL at the node graph level, but the `Effect` class expects raw GLSL strings.

There are two integration strategies:

1. **Write effects using raw GLSL strings in the Effect class** (traditional), and use TSL only for material nodes. Simple, no friction.
2. **Write effects entirely as TSL nodes** via Three.js's `FullScreenQuad` + `NodeMaterial` pattern and plug them into the render pipeline manually.

For most games, Strategy 1 is the right call — TSL is for material nodes, GLSL strings are fine for post-processing. Strategy 2 is for when you want a single authored language across your entire pipeline.

### Custom Effect with TSL-Generated Heat Distortion

This example uses Strategy 2 — a TSL node graph that drives a screen-space heat distortion effect, wrapped in a custom Effect class.

```tsx
import { Effect } from 'postprocessing'
import { Uniform, Vector2 } from 'three'

// Strategy 1: Traditional Effect class with GLSL fragment
// Use this for straightforward post-processing effects
class HeatDistortionEffect extends Effect {
  constructor({ strength = 0.02, speed = 1.5 } = {}) {
    super(
      'HeatDistortionEffect',
      /* glsl */ `
        uniform float uTime;
        uniform float uStrength;
        uniform vec2 uResolution;

        // Simple noise for heat shimmer
        float hash(vec2 p) {
          return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
        }

        float noise(vec2 p) {
          vec2 i = floor(p);
          vec2 f = fract(p);
          f = f * f * (3.0 - 2.0 * f);
          return mix(
            mix(hash(i), hash(i + vec2(1,0)), f.x),
            mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x),
            f.y
          );
        }

        void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
          // Heat rises, so distort upward based on height
          float heightFactor = uv.y;
          float timeOffset = uTime * 0.8;

          // Sample noise at two scales for detail
          float n1 = noise(vec2(uv.x * 8.0, uv.y * 3.0 - timeOffset));
          float n2 = noise(vec2(uv.x * 15.0, uv.y * 5.0 - timeOffset * 1.3));
          float heatNoise = mix(n1, n2, 0.5) - 0.5;

          // Distortion fades near the bottom (heat rises from a hot surface)
          vec2 distortion = vec2(heatNoise * uStrength * heightFactor, 0.0);

          outputColor = texture2D(inputBuffer, uv + distortion);
        }
      `,
      {
        uniforms: new Map([
          ['uTime', new Uniform(0)],
          ['uStrength', new Uniform(strength)],
          ['uResolution', new Uniform(new Vector2(1, 1))],
        ]),
      }
    )
    this.speed = speed
  }

  update(_renderer: any, _inputBuffer: any, deltaTime: number) {
    this.uniforms.get('uTime')!.value += deltaTime * this.speed
  }
}

// React wrapper
import { forwardRef, useMemo } from 'react'
import { wrapEffect } from '@react-three/postprocessing'

const HeatDistortion = wrapEffect(HeatDistortionEffect)

// Usage in a scene with hot surfaces
function HotScene() {
  return (
    <>
      <Canvas>
        <EffectComposer>
          <Bloom intensity={0.5} luminanceThreshold={0.8} />
          {/* Heat distortion goes after bloom so bloom itself shimmers */}
          <HeatDistortion strength={0.015} speed={1.2} />
        </EffectComposer>
      </Canvas>
    </>
  )
}
```

### Node-Based Color Grading Pipeline

TSL is excellent for color grading because you can compose the pipeline from typed, named operations rather than raw GLSL.

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  screenUV, viewportSharedTexture, vec3, float, dot, mix,
  clamp, pow, Fn, vec4
} from 'three/tsl'

// A reusable TSL function for color grading
// Can be used in any TSL material's outputNode
const colorGrade = Fn(([inputColor]: [any]) => {
  // Exposure
  const exposed = inputColor.mul(float(1.2))

  // Contrast (S-curve)
  const contrasted = exposed.sub(0.5).mul(1.3).add(0.5)

  // Saturation via luminance
  const luma = dot(contrasted, vec3(0.2126, 0.7152, 0.0722))
  const saturated = mix(vec3(luma, luma, luma), contrasted, float(1.3))

  // Split-tone: push shadows cool, highlights warm
  const shadowTone = vec3(0.9, 0.95, 1.1)  // Blue-ish shadows
  const highlightTone = vec3(1.1, 1.0, 0.9) // Warm highlights
  const luminance = clamp(luma, float(0), float(1))
  const toned = mix(
    saturated.mul(shadowTone),
    saturated.mul(highlightTone),
    luminance
  )

  // Gamma correction (output color space)
  return pow(clamp(toned, float(0), float(1)), vec3(1.0 / 2.2))
})

// Vignette node — can be composited over any scene output
const vignette = Fn(() => {
  const uv = screenUV
  const center = uv.sub(0.5)
  const dist = center.dot(center)
  const vignetteStrength = smoothstep(float(0.3), float(0.8), dist)
  return float(1).sub(vignetteStrength.mul(0.7))
})

// Film grain that's animated every frame
const filmGrain = Fn(([frameTime]: [any]) => {
  const grainUV = screenUV.mul(vec2(1920, 1080)).floor()
  const rand = fract(
    sin(grainUV.x.mul(127.1).add(grainUV.y.mul(311.7)).add(frameTime.mul(74.2))).mul(43758.5)
  )
  return rand.sub(0.5).mul(0.04) // Subtle grain, ±2% intensity
})
```

### Integrating Custom TSL Effects with EffectComposer

For TSL-authored screen effects that need to live inside the `EffectComposer` pipeline, create a `FullScreenQuad` effect that reads from the render target:

```tsx
import { EffectComposer, Bloom, Vignette } from '@react-three/postprocessing'
import { BlendFunction } from 'postprocessing'

// Combine: TSL materials for objects, standard GLSL effects for post-processing
// This is the pragmatic pattern — best of both worlds
function SceneWithPostProcessing() {
  return (
    <>
      <Canvas gl={(canvas) => new WebGPURenderer({ canvas, antialias: true })}>
        <Suspense>
          {/* Objects use TSL materials */}
          <EnergyShield />
          <TerrainObject />
          <HolographicDisplay />

          {/* Post-processing uses the EffectComposer */}
          <EffectComposer>
            <Bloom
              intensity={1.5}
              luminanceThreshold={0.6}
              luminanceSmoothing={0.9}
              radius={0.4}
            />
            <Vignette
              offset={0.3}
              darkness={0.6}
              blendFunction={BlendFunction.NORMAL}
            />
            {/* Custom heat distortion using GLSL Effect */}
            <HeatDistortion strength={0.01} speed={0.8} />
          </EffectComposer>
        </Suspense>
      </Canvas>
    </>
  )
}
```

---

## 3. TSL + InstancedMesh

Instancing is where TSL really earns its place over GLSL. With `ShaderMaterial` and instancing, passing per-instance data requires `InstancedBufferAttribute`, reading it in the vertex shader via `attribute`, and being careful about attribute indexing. With TSL, per-instance data is readable with typed node accessors and the graph handles the attribute wiring automatically.

### Per-Instance Node Overrides

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  instanceIndex, storage, StorageBufferAttribute,
  float, vec3, vec4, color, time, sin, cos, Fn,
  positionLocal, normalLocal, mix, smoothstep, abs
} from 'three/tsl'
import { useMemo, useRef } from 'react'
import { InstancedMesh, DynamicDrawUsage } from 'three'

const CRYSTAL_COUNT = 10_000

function CrystalField() {
  const meshRef = useRef<InstancedMesh>(null!)

  const { material, positionBuffer, colorBuffer } = useMemo(() => {
    // Storage buffers for per-instance data (GPU-readable by TSL)
    const positions = new Float32Array(CRYSTAL_COUNT * 4) // vec4: xyz pos + phase
    const colors = new Float32Array(CRYSTAL_COUNT * 4)    // vec4: rgb color + intensity

    // Scatter crystals across a plane
    for (let i = 0; i < CRYSTAL_COUNT; i++) {
      const x = (Math.random() - 0.5) * 100
      const z = (Math.random() - 0.5) * 100
      const phase = Math.random() * Math.PI * 2 // Random phase for animation

      positions[i * 4 + 0] = x
      positions[i * 4 + 1] = 0
      positions[i * 4 + 2] = z
      positions[i * 4 + 3] = phase // Stored in w channel

      // Procedural color: blues, purples, teals
      const hue = Math.random()
      const r = hue < 0.33 ? 0.3 : hue < 0.67 ? 0.6 : 0.1
      const g = hue < 0.33 ? 0.5 : hue < 0.67 ? 0.2 : 0.8
      const b = 0.9 + Math.random() * 0.1
      const intensity = 0.5 + Math.random() * 0.5

      colors[i * 4 + 0] = r
      colors[i * 4 + 1] = g
      colors[i * 4 + 2] = b
      colors[i * 4 + 3] = intensity
    }

    const positionBuffer = new StorageBufferAttribute(positions, 4)
    const colorBuffer = new StorageBufferAttribute(colors, 4)

    const m = new MeshStandardNodeMaterial()

    // Read per-instance data using instanceIndex
    const instancePos = storage(positionBuffer, 'vec4', CRYSTAL_COUNT).element(instanceIndex)
    const instanceColor = storage(colorBuffer, 'vec4', CRYSTAL_COUNT).element(instanceIndex)

    // Phase stored in the w component of position
    const phase = instancePos.w

    // Floating animation: vertical oscillation with per-instance phase offset
    const floatHeight = sin(time.mul(1.5).add(phase)).mul(0.3)
    const floatOffset = vec3(0, floatHeight, 0)

    // Apply offset to local position (moves the crystal up/down)
    m.positionNode = positionLocal.add(floatOffset)

    // Procedural color from per-instance buffer + emission pulse
    const baseColor = instanceColor.xyz
    const intensity = instanceColor.w
    const emissionPulse = sin(time.mul(2).add(phase)).mul(0.5).add(0.5)

    m.colorNode = baseColor
    m.emissiveNode = baseColor.mul(intensity).mul(emissionPulse)
    m.roughnessNode = float(0.1)
    m.metalnessNode = float(0.8)

    return { material: m, positionBuffer, colorBuffer }
  }, [])

  // Set initial instance transforms (positions)
  useEffect(() => {
    const mesh = meshRef.current
    const dummy = new Object3D()
    const posData = positionBuffer.array as Float32Array

    for (let i = 0; i < CRYSTAL_COUNT; i++) {
      dummy.position.set(
        posData[i * 4 + 0],
        posData[i * 4 + 1],
        posData[i * 4 + 2]
      )
      // Random scale and rotation per crystal
      const scale = 0.2 + Math.random() * 0.6
      dummy.scale.set(scale, scale * (1.5 + Math.random()), scale)
      dummy.rotation.y = Math.random() * Math.PI * 2
      dummy.updateMatrix()
      mesh.setMatrixAt(i, dummy.matrix)
    }
    mesh.instanceMatrix.needsUpdate = true
  }, [positionBuffer])

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, CRYSTAL_COUNT]}>
      <coneGeometry args={[0.3, 1.5, 6]} />
      <primitive object={material} />
    </instancedMesh>
  )
}
```

### Compute-Driven Instancing

When the animation is complex enough that JavaScript can't keep up, move instance updates to a compute shader. See Module 15 for the full compute pattern — here's the key integration point:

```tsx
import { wgslFn, instanceIndex, storage, StorageBufferAttribute } from 'three/tsl'
import { computeShader } from 'three/webgpu'

// Compute shader updates crystal Y positions every frame
const updateCrystals = wgslFn(`
  fn updateCrystals(
    positions: ptr<storage, array<vec4f>, read_write>,
    time: f32,
  ) -> void {
    let i = instanceIndex;
    let phase = (*positions)[i].w;
    // Floating motion
    (*positions)[i].y = sin(time * 1.5 + phase) * 0.3;
  }
`)

// In the render loop:
function useCrystalCompute(positionBuffer: StorageBufferAttribute) {
  const { gl } = useThree()

  const computeNode = useMemo(() => {
    const timeUniform = uniform(0, 'float')
    const storageNode = storage(positionBuffer, 'vec4', CRYSTAL_COUNT)
    const node = updateCrystals({ positions: storageNode, time: timeUniform })
      .compute(CRYSTAL_COUNT)
    ;(node as any).__time = timeUniform
    return node
  }, [positionBuffer])

  useFrame(({ clock }) => {
    ;(computeNode as any).__time.value = clock.getElapsedTime()
    gl.computeAsync(computeNode)
  })
}
```

---

## 4. Custom Fn() Composition

`Fn()` is TSL's mechanism for creating reusable shader functions. Unlike GLSL's raw function declarations, `Fn()` creates callable node objects that can be composed, parameterized, and passed around like values in TypeScript. This enables a proper library architecture.

### Building a Reusable TSL Utility Library

```tsx
// tsl-utils.ts — A reusable node library for your project
import {
  Fn, float, vec2, vec3, vec4, uv, time, sin, cos, floor, fract,
  dot, mix, smoothstep, clamp, pow, abs, length, normalize,
  ShaderNodeObject, Node
} from 'three/tsl'

// --- Noise Functions ---

// Classic 2D hash noise
export const hash2D = Fn(([p]: [ShaderNodeObject<Node>]) => {
  // dot(p, vec2(127.1, 311.7)) gives a unique float per integer cell
  return fract(sin(dot(p, vec2(127.1, 311.7))).mul(43758.5453))
})

// Smooth value noise — bilinear interpolation between hash values
export const valueNoise2D = Fn(([p]: [ShaderNodeObject<Node>]) => {
  const i = floor(p)
  const f = fract(p)
  // Hermite interpolation for smoother results than linear
  const u = f.mul(f).mul(float(3).sub(f.mul(2)))

  const a = hash2D(i)
  const b = hash2D(i.add(vec2(1, 0)))
  const c = hash2D(i.add(vec2(0, 1)))
  const d = hash2D(i.add(vec2(1, 1)))

  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y)
})

// Fractal Brownian Motion — layers of noise at different frequencies
// octaves: number of layers (more = more detail, more expensive)
export const fbm = Fn(([p, octaves]: [ShaderNodeObject<Node>, ShaderNodeObject<Node>]) => {
  // Note: TSL Loop() doesn't support dynamic bounds cleanly,
  // so manually unroll for a fixed octave count
  let value = float(0)
  let amplitude = float(0.5)
  let frequency = float(1)
  let currentP = p

  // 5 octaves hardcoded — sufficient for most use cases
  for (let i = 0; i < 5; i++) {
    value = value.add(valueNoise2D(currentP.mul(frequency)).mul(amplitude))
    amplitude = amplitude.mul(0.5)
    frequency = frequency.mul(2)
    currentP = currentP.mul(vec2(1.7, 1.3)) // Slightly skew to avoid axis-aligned artifacts
  }

  return value
})

// --- Pattern Generators ---

// Checkerboard pattern
export const checkerboard = Fn(([p, scale]: [ShaderNodeObject<Node>, ShaderNodeObject<Node>]) => {
  const scaled = p.mul(scale)
  const checker = floor(scaled.x).add(floor(scaled.y))
  return fract(checker.mul(0.5)).mul(2) // Returns 0 or 1
})

// Animated scanlines
export const scanlines = Fn(([p, count, speed]: [
  ShaderNodeObject<Node>,
  ShaderNodeObject<Node>,
  ShaderNodeObject<Node>
]) => {
  const line = fract(p.y.mul(count).add(time.mul(speed)))
  return smoothstep(float(0), float(0.05), line).mul(
    smoothstep(float(0.1), float(0.05), line)
  )
})

// Fresnel rim effect
export const fresnel = Fn(([normal, viewDir, power]: [
  ShaderNodeObject<Node>,
  ShaderNodeObject<Node>,
  ShaderNodeObject<Node>
]) => {
  const ndotv = clamp(dot(normalize(normal), normalize(viewDir)), float(0), float(1))
  return pow(float(1).sub(ndotv), power)
})

// --- Lighting Helpers ---

// Cel-shade a lighting value into N discrete bands
export const celShade = Fn(([lightValue, bands]: [
  ShaderNodeObject<Node>,
  ShaderNodeObject<Node>
]) => {
  return floor(lightValue.mul(bands)).div(bands)
})

// Pulsing emission — for energy/sci-fi effects
export const pulse = Fn(([baseColor, speed, intensity]: [
  ShaderNodeObject<Node>,
  ShaderNodeObject<Node>,
  ShaderNodeObject<Node>
]) => {
  const p = sin(time.mul(speed)).mul(0.5).add(0.5)
  return baseColor.mul(p.mul(intensity))
})
```

### Composing a Complex Material from Building Blocks

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import { normalLocal, positionLocal, uv, vec3, color, float } from 'three/tsl'
import { fresnel, fbm, pulse, celShade, scanlines } from './tsl-utils'

function HolographicCrystal() {
  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial({
      transparent: true,
    })

    // Compose the final color from multiple utility nodes
    const fresnelMask = fresnel(normalLocal, vec3(0, 0, 1), float(3))
    const noisePattern = fbm(uv().mul(5), float(5))
    const scanlinesPattern = scanlines(uv(), float(40), float(0.3))
    const emissionPulse = pulse(color('#00ffcc'), float(2), float(3))

    // Layer them: base transparency, rim glow, scanlines, noise variation
    const baseAlpha = fresnelMask.mul(0.7).add(0.1)
    const baseColor = color('#004488')

    m.colorNode = baseColor.add(emissionPulse.mul(scanlinesPattern))
    m.emissiveNode = emissionPulse.mul(fresnelMask).mul(noisePattern)
    m.opacityNode = baseAlpha.mul(noisePattern.mul(0.3).add(0.7))
    m.roughnessNode = float(0)
    m.metalnessNode = float(0.5)

    return m
  }, [])

  return (
    <mesh>
      <octahedronGeometry args={[1, 2]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

The key advantage of `Fn()` composition: each utility function is tested in isolation, documented with types, and reusable across materials. Compare this to GLSL utility functions that are copy-pasted between shader strings with no type checking.

---

## 5. Under the Hood: Generated WGSL

Understanding what TSL compiles to helps you write better TSL. The compiler performs several optimizations: common subexpression elimination (a node used multiple times is computed once), dead code elimination (unused branches are stripped), and constant folding (operations on literal values are pre-computed).

### Inspecting Generated Shader Code

Three.js exposes the generated shader source through the material's node builder:

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import { useThree, useFrame } from '@react-three/fiber'
import { useEffect, useRef } from 'react'

function ShaderInspector({ material }: { material: MeshStandardNodeMaterial }) {
  const { gl } = useThree()
  const logged = useRef(false)

  useFrame(() => {
    // The renderer must process the material before we can read the shader
    // Check after the first frame
    if (!logged.current) {
      logged.current = true

      try {
        // Access the internal node builder for this renderer
        const nodeFrame = (gl as any).info?.programs?.get(material)
        if (nodeFrame) {
          console.group('Generated WGSL / GLSL')
          console.log('Fragment:', nodeFrame.fragmentShader)
          console.log('Vertex:', nodeFrame.vertexShader)
          console.groupEnd()
        }

        // Alternative: use the material's cache key to correlate with DevTools
        console.log('Material cache key:', material.customProgramCacheKey())
      } catch (e) {
        console.warn('Could not inspect shader:', e)
      }
    }
  })

  return null
}
```

### TSL → WGSL Translation Examples

Here are three concrete examples showing TSL input and the WGSL that Three.js generates. Knowing this helps you reason about performance and avoid surprises.

**Example 1: Simple color with time animation**

```tsx
// TSL input
m.colorNode = color('#ff6600').mul(sin(time).mul(0.5).add(0.5))
```

```wgsl
// Generated WGSL (simplified)
@fragment
fn main(input: FragmentInput) -> FragmentOutput {
  var output: FragmentOutput;
  // color('#ff6600') becomes a constant
  let node_color = vec3f(1.0, 0.4, 0.0);
  // time comes from a uniform
  let node_sin = sin(uniforms.time);
  // Arithmetic nodes become direct expressions
  let node_mul_0 = node_sin * 0.5;
  let node_add = node_mul_0 + 0.5;
  let node_result = node_color * node_add;

  output.color = vec4f(node_result, 1.0);
  return output;
}
```

**Example 2: Conditional logic with If() / select()**

```tsx
// TSL input — select() for branchless conditional
import { select } from 'three/tsl'
const mask = uv().x.greaterThan(float(0.5))
m.colorNode = select(mask, color('#ff0000'), color('#0000ff'))
```

```wgsl
// Generated WGSL — uses select() intrinsic (branchless on GPU)
let node_uv = input.uv;
let node_gt = node_uv.x > 0.5;
// select() maps directly to WGSL select() — no branch!
let node_color = select(vec3f(0.0, 0.0, 1.0), vec3f(1.0, 0.0, 0.0), node_gt);
```

```tsx
// TSL input — If() for branching (more expensive, generates actual branch)
import { If } from 'three/tsl'
const finalColor = vec3(0).toVar()
If(uv().x.greaterThan(float(0.5)), () => {
  finalColor.assign(color('#ff0000'))
}).Else(() => {
  finalColor.assign(color('#0000ff'))
})
m.colorNode = finalColor
```

```wgsl
// Generated WGSL — actual branch (avoid in hot paths)
var node_final = vec3f(0.0);
if (node_uv.x > 0.5) {
  node_final = vec3f(1.0, 0.0, 0.0);
} else {
  node_final = vec3f(0.0, 0.0, 1.0);
}
```

**Example 3: Common subexpression elimination**

```tsx
// TSL input — fresnel used in both color and opacity
const fresnelValue = float(1).sub(dot(normalLocal, vec3(0, 0, 1)).abs()).pow(float(3))
m.colorNode = color('#00aaff').mul(fresnelValue)
m.opacityNode = fresnelValue.mul(0.8)
```

```wgsl
// Generated WGSL — fresnel computed ONCE, reused in both outputs
// (TSL's compiler performs CSE automatically)
let node_dot = abs(dot(input.normalLocal, vec3f(0.0, 0.0, 1.0)));
let node_sub = 1.0 - node_dot;
let node_fresnel = pow(node_sub, 3.0); // Computed once!

let node_color = vec3f(0.0, 0.667, 1.0) * node_fresnel;
let node_opacity = node_fresnel * 0.8;
```

This is the CSE win: you don't pay for node reuse. Reference the same node object from multiple places in the graph and the compiler deduplicates the computation.

---

## 6. GLSL → TSL Migration Cookbook

Each recipe shows the GLSL pattern and its TSL equivalent. All TSL imports come from `three/tsl`.

### Recipe 1: Uniform Declarations

```glsl
// GLSL
uniform float uTime;
uniform vec3 uColor;
uniform sampler2D uTexture;
```

```tsx
// TSL — uniforms are typed nodes, values update via .value
import { uniform } from 'three/tsl'
import { Color, Texture } from 'three'

const uTime = uniform(0, 'float')           // float uniform
const uColor = uniform(new Color('#ff6600')) // vec3 (Color maps to vec3)
const uTexture = texture(myTexture, uv())   // sampler2D accessed via texture()

// Update at runtime:
uTime.value = clock.getElapsedTime()
uColor.value.set('#00ff00')
```

### Recipe 2: Varyings and Attribute Access

```glsl
// GLSL — explicit varying declaration and UV access
varying vec2 vUv;
void main() { vUv = uv; }
// Fragment: use vUv
```

```tsx
// TSL — built-in nodes, no explicit varyings needed
import { uv, positionLocal, positionWorld, normalLocal, normalWorld } from 'three/tsl'

m.colorNode = texture(map, uv())         // UV access
m.positionNode = positionLocal.add(...)  // Vertex position
// normalLocal, normalWorld available in fragment automatically
```

### Recipe 3: Texture Sampling

```glsl
// GLSL
vec4 color = texture2D(uMap, vUv);
// Or in WebGL2:
vec4 color = texture(uMap, vUv);
```

```tsx
// TSL
import { texture, uv } from 'three/tsl'
const color = texture(myTexture, uv())
// With explicit UV offset:
const shifted = texture(myTexture, uv().add(vec2(0.1, 0)))
```

### Recipe 4: mix / smoothstep / clamp

```glsl
// GLSL
float result = mix(a, b, t);
float smooth = smoothstep(0.2, 0.8, x);
float clamped = clamp(val, 0.0, 1.0);
```

```tsx
// TSL — same names, method-chaining style
import { mix, smoothstep, clamp } from 'three/tsl'

const result = mix(a, b, t)
const smooth = smoothstep(float(0.2), float(0.8), x)
const clamped = clamp(val, float(0), float(1))

// Method-chaining alternative (often cleaner):
const chained = val.clamp(0, 1).smoothstep(0.2, 0.8)
```

### Recipe 5: Trigonometry

```glsl
// GLSL
float s = sin(uTime * 2.0);
float c = cos(angle);
vec2 polar = vec2(cos(theta), sin(theta)) * radius;
```

```tsx
// TSL — identical function names
import { sin, cos } from 'three/tsl'

const s = sin(uTime.mul(2))
const c = cos(angle)
const polar = vec2(cos(theta), sin(theta)).mul(radius)
```

### Recipe 6: Matrix Transforms

```glsl
// GLSL
mat3 tbn = mat3(tangent, bitangent, normal);
vec3 worldNormal = normalize(normalMatrix * normal);
```

```tsx
// TSL
import { mat3, normalMatrix, normalLocal, normalize } from 'three/tsl'

// normalMatrix is a built-in node
const worldNormal = normalize(normalMatrix.mul(normalLocal))
// For custom TBN: use tangentLocal, bitangentLocal, normalLocal
```

### Recipe 7: Conditionals

```glsl
// GLSL
if (x > 0.5) {
  color = vec3(1.0, 0.0, 0.0);
} else {
  color = vec3(0.0, 0.0, 1.0);
}
// Ternary style (branchless — prefer this):
vec3 color = x > 0.5 ? vec3(1,0,0) : vec3(0,0,1);
```

```tsx
// TSL — If() for branching, select() for branchless (prefer select)
import { If, select } from 'three/tsl'

// Branchless (GPU-friendly):
const color = select(x.greaterThan(float(0.5)), vec3(1, 0, 0), vec3(0, 0, 1))

// Branching (needed for complex logic with side effects):
const color2 = vec3(0).toVar()
If(x.greaterThan(float(0.5)), () => {
  color2.assign(vec3(1, 0, 0))
}).Else(() => {
  color2.assign(vec3(0, 0, 1))
})
```

### Recipe 8: For Loops

```glsl
// GLSL
float sum = 0.0;
for (int i = 0; i < 8; i++) {
  sum += texture2D(shadowMaps[i], uv).r;
}
```

```tsx
// TSL — Loop() for GPU loops
import { Loop, float } from 'three/tsl'

const sum = float(0).toVar()
Loop(8, ({ i }) => {
  // i is a TSL int node — use it in TSL expressions
  sum.addAssign(texture(shadowMaps[i], uv()).r)
})
```

### Recipe 9: Preprocessor Constants

```glsl
// GLSL
#define PI 3.14159265
#define NUM_LIGHTS 4
const float ROUGHNESS = 0.3;
```

```tsx
// TSL — const is a JS/TS const, literal values inline or as named nodes
import { float, int } from 'three/tsl'

const PI = float(Math.PI)       // Named for reuse
const NUM_LIGHTS = int(4)       // Integer constant
const ROUGHNESS = float(0.3)    // Or just use the literal inline
```

### Recipe 10: Fragment Coordinates

```glsl
// GLSL
vec2 fragCoord = gl_FragCoord.xy;
vec2 normalizedCoord = fragCoord / uResolution;
```

```tsx
// TSL
import { screenUV, screenSize } from 'three/tsl'

// screenUV is already normalized [0,1] — equivalent to gl_FragCoord.xy / resolution
const normalizedCoord = screenUV

// If you need raw pixel coords:
const fragCoord = screenUV.mul(screenSize)
```

### Recipe 11: Instance ID

```glsl
// GLSL (WebGL 2)
int instanceId = gl_InstanceID;
float phase = float(instanceId) * 0.1;
```

```tsx
// TSL
import { instanceIndex } from 'three/tsl'

// instanceIndex is already a float-compatible int node
const phase = instanceIndex.toFloat().mul(0.1)
```

### Recipe 12: Custom Functions

```glsl
// GLSL
float myFunc(float x, float y) {
  return x * x + y;
}
```

```tsx
// TSL
import { Fn, float } from 'three/tsl'

const myFunc = Fn(([x, y]: [any, any]) => {
  return x.mul(x).add(y)
})

// Call it:
const result = myFunc(someX, someY)
```

### Common Migration Gotchas

- **Operator overloading doesn't exist in TSL.** `a * b` where `a` and `b` are nodes won't work — use `a.mul(b)` or `mul(a, b)`.
- **`vec3(1.0)` in GLSL broadcasts — `vec3(1)` in TSL does too** but the arg must be a number literal or a single-channel node. `vec3(myFloat)` works.
- **TSL nodes are lazy.** The node graph isn't evaluated until the renderer processes the material. You can't `console.log` a node's value — it has no value at JS time.
- **`.toVar()` is required for mutation.** If you need to assign to a node variable conditionally (inside `If()`), call `.toVar()` first to create a mutable shader variable.
- **`normalWorld` vs `normalLocal`**: GLSL's `gl_NormalMatrix * normal` maps to TSL's `normalWorld`. `normal` attribute alone maps to `normalLocal`.

---

## 7. TypeScript Integration

TSL's TypeScript integration is functional but still maturing. The type system correctly models node types, but some patterns require casts or `@ts-ignore` that will become unnecessary as the types improve.

### Proper Imports from three/tsl

```tsx
// Always import TSL functions from 'three/tsl' — NOT from 'three'
// Wrong:
import { sin } from 'three'          // This is Three.js's math util, not a node
// Right:
import { sin } from 'three/tsl'      // This returns a ShaderNodeObject<MathNode>

// Material classes come from 'three/webgpu'
import { MeshStandardNodeMaterial } from 'three/webgpu'
// NOT from 'three' (WebGLRenderer version)
import { MeshStandardMaterial } from 'three'  // This doesn't support nodeColorNode etc.
```

### Creating Typed TSL Utility Functions

```tsx
import {
  Fn, float, vec2, vec3, ShaderNodeObject, Node, FloatNode, Vec3Node
} from 'three/tsl'

// Fully typed utility function
// Input: a vec3 color and a float intensity
// Output: the color multiplied by intensity with gamma correction applied
function makeEmission(
  color: ShaderNodeObject<Node>,
  intensity: ShaderNodeObject<FloatNode>
): ShaderNodeObject<Node> {
  const gammaCorrected = pow(color.clamp(0, 1), vec3(1.0 / 2.2))
  return gammaCorrected.mul(intensity)
}

// Factory function pattern — returns a configured node ready for use
function createRimLight(options: {
  rimColor?: string
  rimPower?: number
  rimIntensity?: number
}) {
  const {
    rimColor = '#ffffff',
    rimPower = 3,
    rimIntensity = 1.5,
  } = options

  // These local consts are TSL nodes, not JS values
  const colorNode = color(rimColor)
  const powerNode = float(rimPower)
  const intensityNode = float(rimIntensity)

  return Fn(() => {
    const rim = float(1).sub(
      dot(normalLocal, vec3(0, 0, 1)).abs()
    ).pow(powerNode)
    return colorNode.mul(rim).mul(intensityNode)
  })()
}

// Higher-order node: takes a node and returns a transformed version
function withPulse(
  node: ShaderNodeObject<Node>,
  speed: number = 2,
  range: [number, number] = [0.5, 1.5]
): ShaderNodeObject<Node> {
  const [low, high] = range
  const pulseFactor = sin(time.mul(speed))
    .mul((high - low) / 2)
    .add((high + low) / 2)
  return node.mul(pulseFactor)
}
```

### Dealing with @ts-ignore

Some TSL patterns lag behind the type definitions:

```tsx
// Common pattern: property access on material that TS doesn't know about yet
const mat = new MeshStandardNodeMaterial()
// TypeScript knows about these:
mat.colorNode = someNode
mat.roughnessNode = float(0.3)

// TypeScript may not know about newer node properties — cast as needed
;(mat as any).clearcoatNode = float(1)
;(mat as any).transmissionNode = float(0.95)

// For storage buffers, the types are loose
// @ts-ignore — StorageBufferAttribute constructor types are not precise yet
const buffer = new StorageBufferAttribute(data, 4)
```

The practical rule: use `as any` sparingly and only when you're certain the property exists (verify in Three.js source or examples). Keep a comment explaining what version introduced the missing type so you can remove the cast later.

---

## 8. Debugging & Profiling TSL

Debugging shader code is always harder than debugging JavaScript — errors often manifest as silent visual artifacts or complete render failures with cryptic messages. TSL adds a layer of indirection that makes some bugs harder to locate. These tools and techniques help.

### Chrome DevTools GPU Inspection

```tsx
// In development, enable verbose GPU logging
// Add to your renderer setup:
const renderer = new WebGPURenderer({
  canvas,
  antialias: true,
  // In dev mode, request a device with error validation
  // (automatic in Chrome, but you can force it)
})

// Enable Three.js's built-in error checking in dev
renderer.debug.checkShaderErrors = true  // WebGL
// For WebGPU, Chrome's default validation catches most errors

// React component to log shader compilation errors
function ShaderErrorBoundary({ material }: { material: any }) {
  const { gl } = useThree()

  useEffect(() => {
    // Listen for WebGPU device error events
    const device = (gl as any).backend?.device
    if (device) {
      device.addEventListener('uncapturederror', (e: any) => {
        console.error('WebGPU Error:', e.error.message)
        // The error message often includes the WGSL line that failed
        // Use this to trace back to your TSL node graph
      })
    }
  }, [gl])

  return null
}
```

### Debug Utility Component

```tsx
import { useThree, useFrame } from '@react-three/fiber'
import { useState, useRef } from 'react'

interface TSLDebugInfo {
  vertexShader?: string
  fragmentShader?: string
  cacheKey?: string
  compileTime?: number
  drawCalls?: number
  triangles?: number
}

function TSLDebugPanel({ material }: { material: any }) {
  const { gl } = useThree()
  const [info, setInfo] = useState<TSLDebugInfo>({})
  const frameCount = useRef(0)

  useFrame(() => {
    frameCount.current++

    // Sample every 60 frames to avoid performance impact
    if (frameCount.current % 60 !== 0) return

    const renderer = gl as any
    const rendererInfo = renderer.info

    const newInfo: TSLDebugInfo = {
      cacheKey: material.customProgramCacheKey?.(),
      drawCalls: rendererInfo?.render?.calls,
      triangles: rendererInfo?.render?.triangles,
    }

    // Try to access generated shader source
    try {
      const nodeBuilder = renderer.backend?.nodes?.nodeFrame
      if (nodeBuilder && material.__shaderSource) {
        newInfo.vertexShader = material.__shaderSource.vertex?.slice(0, 200) + '...'
        newInfo.fragmentShader = material.__shaderSource.fragment?.slice(0, 200) + '...'
      }
    } catch (e) {
      // Shader source access varies by Three.js version
    }

    setInfo(newInfo)
  })

  if (process.env.NODE_ENV !== 'development') return null

  return (
    <div style={{
      position: 'fixed', top: 10, right: 10,
      background: 'rgba(0,0,0,0.8)', color: '#0f0',
      padding: 12, fontSize: 11, fontFamily: 'monospace',
      maxWidth: 300, zIndex: 9999
    }}>
      <div><strong>TSL Debug</strong></div>
      <div>Cache key: {info.cacheKey?.slice(0, 20)}...</div>
      <div>Draw calls: {info.drawCalls}</div>
      <div>Triangles: {info.triangles?.toLocaleString()}</div>
      {info.fragmentShader && (
        <details>
          <summary>Fragment (first 200 chars)</summary>
          <pre style={{ fontSize: 9 }}>{info.fragmentShader}</pre>
        </details>
      )}
    </div>
  )
}
```

### Using Spector.js for WebGPU Frame Capture

Spector.js (browser extension) captures entire GPU frames and lets you inspect every draw call, shader, and buffer:

1. Install the Spector.js Chrome extension
2. Open DevTools → Spector.js tab
3. Click "Capture frame"
4. Inspect draw calls — for TSL materials, look for the `NodeMaterial` programs
5. Click a draw call to see the bound shader source (you'll see the generated WGSL/GLSL)
6. The "Uniforms" tab shows current uniform values per draw call

For WebGPU specifically, Chrome's built-in `chrome://gpu` page shows device capabilities and any WebGPU validation errors that weren't caught in your error handler.

### Performance Profiling

```tsx
// Quick profiling utility: measure GPU time for a TSL material
// Works in Chrome with the timestamp query extension
function useGPUTimer(label: string) {
  const { gl } = useThree()
  const timerRef = useRef<any>(null)

  useFrame(() => {
    const renderer = gl as any
    // WebGPU timestamp queries are available in Chrome with --enable-dawn-features=allow_unsafe_apis
    // For practical profiling, use r3f-perf instead:
    // npm install r3f-perf
    // <Perf /> from 'r3f-perf' shows GPU timing, draw calls, and memory
  })
}
```

### Identifying Expensive TSL Nodes

Performance problems in TSL shaders usually come from:

1. **Too many texture samples.** Each `texture()` call is a GPU memory fetch. Consolidate: sample once and reuse the result.
2. **Expensive math in the fragment shader.** `pow()`, `sqrt()`, `sin()` in the fragment shader (per-pixel) are expensive. Move to vertex shader where possible via `varying`.
3. **Dynamic branching (`If()`)** causing GPU thread divergence. Prefer `select()` for branchless math.
4. **Overdraw.** Transparent materials drawn on top of each other multiply the fragment shader cost. Sort transparent objects back-to-front.

```tsx
// Wrong: sampling the texture 3 times for different channels
m.colorNode = texture(map, uv()).rgb
m.roughnessNode = texture(map, uv()).r    // Second sample — wasteful!
m.metalnessNode = texture(map, uv()).g    // Third sample — wasteful!

// Right: sample once, destructure
const mapSample = texture(map, uv())
m.colorNode = mapSample.rgb
m.roughnessNode = mapSample.r             // Reuses cached sample
m.metalnessNode = mapSample.g             // Reuses cached sample
```

---

## Code Walkthrough

### Mini-Project: The Retrofit

This project takes three objects that originally use GLSL `ShaderMaterial` and converts them to TSL. We'll see the GLSL "before" and the TSL "after" for each, then add compute-driven particles and a custom post-processing effect.

#### Object 1: Energy Shield

**Before (GLSL):**

```glsl
// Vertex shader
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPosition;

void main() {
  vUv = uv;
  vNormal = normalize(normalMatrix * normal);
  vPosition = (modelViewMatrix * vec4(position, 1.0)).xyz;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
```

```glsl
// Fragment shader
uniform float uTime;
uniform vec3 uColor;
uniform float uStrength;

varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPosition;

float noise(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5);
}

void main() {
  // Fresnel rim
  vec3 viewDir = normalize(-vPosition);
  float fresnel = pow(1.0 - dot(vNormal, viewDir), 3.0);

  // Animated noise pattern
  vec2 noiseUv = vUv * 5.0 + vec2(uTime * 0.3, uTime * 0.2);
  float n = noise(noiseUv) * 0.5 + noise(noiseUv * 2.0) * 0.25;

  // Hex grid pattern
  float hexX = vUv.x * 8.0;
  float hexY = vUv.y * 4.0;
  float hex = abs(sin(hexX + uTime) + sin(hexY));

  float combined = fresnel * (0.6 + n * 0.4) + hex * 0.1;

  gl_FragColor = vec4(uColor * combined * uStrength, combined * 0.8);
}
```

**After (TSL):**

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  color, float, uv, time, sin, cos, pow, fract, dot, vec2, vec3,
  normalLocal, normalWorld, positionViewDirection, mix, abs, mul, add
} from 'three/tsl'
import { hash2D, valueNoise2D } from './tsl-utils'

function EnergyShield() {
  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial({ transparent: true, side: DoubleSide })

    const shieldColor = color('#00aaff')
    const strength = float(2.5)

    // Fresnel rim — normalLocal and positionViewDirection are built-in
    const fresnel = pow(
      float(1).sub(dot(normalLocal, positionViewDirection).abs()),
      float(3)
    )

    // Animated noise — reusing our utility library
    const animatedUV = uv().mul(5).add(vec2(time.mul(0.3), time.mul(0.2)))
    const noiseVal = valueNoise2D(animatedUV).mul(0.5)
      .add(valueNoise2D(animatedUV.mul(2)).mul(0.25))

    // Hex grid approximation using sin patterns
    const hexX = uv().x.mul(8)
    const hexY = uv().y.mul(4)
    const hexPattern = sin(hexX.add(time)).add(sin(hexY)).abs()

    // Combine
    const combined = fresnel.mul(float(0.6).add(noiseVal.mul(0.4)))
      .add(hexPattern.mul(0.1))

    m.colorNode = shieldColor.mul(combined).mul(strength)
    m.emissiveNode = shieldColor.mul(fresnel).mul(strength)
    m.opacityNode = combined.mul(0.8)
    m.roughnessNode = float(0)
    m.metalnessNode = float(0.3)

    return m
  }, [])

  return (
    <mesh>
      <sphereGeometry args={[2, 64, 64]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

#### Object 2: Terrain Material

**Before (GLSL):**

```glsl
// Vertex shader — triplanar UVs
varying vec3 vWorldPos;
varying vec3 vNormal;
varying float vHeight;

void main() {
  vec4 worldPos = modelMatrix * vec4(position, 1.0);
  vWorldPos = worldPos.xyz;
  vNormal = normalize(mat3(modelMatrix) * normal);
  vHeight = position.y;
  gl_Position = projectionMatrix * viewMatrix * worldPos;
}
```

```glsl
// Fragment shader — height-based coloring with triplanar
uniform sampler2D uGrassAlbedo;
uniform sampler2D uRockAlbedo;
uniform sampler2D uSnowAlbedo;
uniform float uTime;

varying vec3 vWorldPos;
varying vec3 vNormal;
varying float vHeight;

vec3 triplanar(sampler2D map, vec3 pos, vec3 normal, float scale) {
  vec3 blendWeights = abs(normal);
  blendWeights = pow(blendWeights, vec3(8.0));
  blendWeights /= blendWeights.x + blendWeights.y + blendWeights.z;

  vec3 xSample = texture2D(map, pos.yz * scale).rgb;
  vec3 ySample = texture2D(map, pos.xz * scale).rgb;
  vec3 zSample = texture2D(map, pos.xy * scale).rgb;

  return xSample * blendWeights.x + ySample * blendWeights.y + zSample * blendWeights.z;
}

void main() {
  float normalizedHeight = (vHeight + 5.0) / 15.0;

  vec3 grass = triplanar(uGrassAlbedo, vWorldPos, vNormal, 0.5);
  vec3 rock = triplanar(uRockAlbedo, vWorldPos, vNormal, 0.3);
  vec3 snow = vec3(0.95, 0.97, 1.0);

  // Height-based blending
  vec3 terrainColor = grass;
  terrainColor = mix(terrainColor, rock, smoothstep(0.4, 0.6, normalizedHeight));
  terrainColor = mix(terrainColor, snow, smoothstep(0.8, 1.0, normalizedHeight));

  // Slope-based rock overlay (steep slopes = rock regardless of height)
  float slope = 1.0 - abs(dot(vNormal, vec3(0.0, 1.0, 0.0)));
  terrainColor = mix(terrainColor, rock, smoothstep(0.4, 0.7, slope));

  gl_FragColor = vec4(terrainColor, 1.0);
}
```

**After (TSL):**

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  texture, uv, positionWorld, normalWorld, normalLocal, float, vec3,
  abs, pow, dot, mix, smoothstep, add, div, Fn, vec2
} from 'three/tsl'
import { useTexture } from '@react-three/drei'

// Reusable triplanar sampling node function
const triplanarSample = Fn(([map, worldPos, normal, scale]: [any, any, any, any]) => {
  // Blend weights based on normal direction (steep = favors side UVs)
  const weights = abs(normal).pow(vec3(8))
  const weightSum = weights.x.add(weights.y).add(weights.z)
  const blendWeights = weights.div(weightSum)

  const scaledPos = worldPos.mul(scale)

  // Sample from three axes
  const xSample = texture(map, vec2(scaledPos.y, scaledPos.z)).rgb
  const ySample = texture(map, vec2(scaledPos.x, scaledPos.z)).rgb
  const zSample = texture(map, vec2(scaledPos.x, scaledPos.y)).rgb

  return xSample.mul(blendWeights.x)
    .add(ySample.mul(blendWeights.y))
    .add(zSample.mul(blendWeights.z))
})

function TerrainMaterial() {
  const [grassMap, rockMap] = useTexture([
    '/textures/grass-albedo.jpg',
    '/textures/rock-albedo.jpg',
  ])

  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial()

    // Height from world Y position, normalized to [0, 1]
    const normalizedHeight = positionWorld.y.add(5).div(15).clamp(0, 1)

    // Triplanar samples for each zone
    const grassColor = triplanarSample(grassMap, positionWorld, normalWorld, float(0.5))
    const rockColor = triplanarSample(rockMap, positionWorld, normalWorld, float(0.3))
    const snowColor = vec3(0.95, 0.97, 1.0)

    // Height-based blending
    let terrainColor = grassColor
    terrainColor = mix(terrainColor, rockColor, smoothstep(float(0.4), float(0.6), normalizedHeight))
    terrainColor = mix(terrainColor, snowColor, smoothstep(float(0.8), float(1.0), normalizedHeight))

    // Slope-based rock (steep slopes show rock regardless of height)
    const upFacing = abs(dot(normalWorld, vec3(0, 1, 0)))
    const slope = float(1).sub(upFacing)
    terrainColor = mix(terrainColor, rockColor, smoothstep(float(0.4), float(0.7), slope))

    m.colorNode = terrainColor
    m.roughnessNode = float(0.85)
    m.metalnessNode = float(0)

    return m
  }, [grassMap, rockMap])

  return (
    <mesh>
      <planeGeometry args={[20, 20, 64, 64]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

#### Object 3: Holographic Display

**Before (GLSL):**

```glsl
// Fragment shader — scanlines + glitch + chromatic aberration
uniform float uTime;
uniform sampler2D uContent;

varying vec2 vUv;

float random(vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  // Scanlines
  float scanline = sin(vUv.y * 200.0 + uTime * 5.0) * 0.04;

  // Glitch: occasional horizontal displacement
  float glitchTime = floor(uTime * 10.0);
  float glitch = random(vec2(glitchTime, vUv.y * 10.0));
  float glitchStrength = step(0.95, glitch) * 0.04;

  // Chromatic aberration with glitch offset
  vec2 uvR = vUv + vec2(glitchStrength + 0.002, 0.0);
  vec2 uvG = vUv + vec2(glitchStrength, 0.0);
  vec2 uvB = vUv - vec2(glitchStrength + 0.002, 0.0);

  vec3 color;
  color.r = texture2D(uContent, uvR).r;
  color.g = texture2D(uContent, uvG).g;
  color.b = texture2D(uContent, uvB).b;

  // Color matrix: push to cyan-green
  color = color * vec3(0.6, 1.0, 0.8);

  // Fade edges
  float fade = smoothstep(0.0, 0.1, vUv.x) * smoothstep(1.0, 0.9, vUv.x)
             * smoothstep(0.0, 0.05, vUv.y) * smoothstep(1.0, 0.95, vUv.y);

  gl_FragColor = vec4(color * (1.0 + scanline), fade * 0.9);
}
```

**After (TSL):**

```tsx
import { MeshStandardNodeMaterial } from 'three/webgpu'
import {
  texture, uv, time, sin, floor, fract, dot, vec2, vec3,
  smoothstep, step, float, color, mix, clamp
} from 'three/tsl'
import { useTexture } from '@react-three/drei'
import { hash2D } from './tsl-utils'

function HolographicDisplay() {
  const contentMap = useTexture('/textures/holo-content.png')

  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial({ transparent: true, side: DoubleSide })

    // Animated scanlines
    const scanline = sin(uv().y.mul(200).add(time.mul(5))).mul(0.04)

    // Glitch displacement: random but time-stepped (not every frame)
    const glitchTime = floor(time.mul(10))
    const glitchSeed = vec2(glitchTime, uv().y.mul(10))
    const glitchNoise = hash2D(glitchSeed)
    const glitchStrength = step(float(0.95), glitchNoise).mul(0.04)

    // Chromatic aberration: separate R, G, B channels by glitch offset
    const uvR = uv().add(vec2(glitchStrength.add(0.002), 0))
    const uvG = uv().add(vec2(glitchStrength, 0))
    const uvB = uv().sub(vec2(glitchStrength.add(0.002), 0))

    const r = texture(contentMap, uvR).r
    const g = texture(contentMap, uvG).g
    const b = texture(contentMap, uvB).b

    // Recombine channels with holographic color tint
    const holoTint = vec3(0.6, 1.0, 0.8)
    const combinedColor = vec3(r, g, b).mul(holoTint)

    // Edge fade (billboard vignette)
    const fadeX = smoothstep(float(0), float(0.1), uv().x)
      .mul(smoothstep(float(1), float(0.9), uv().x))
    const fadeY = smoothstep(float(0), float(0.05), uv().y)
      .mul(smoothstep(float(1), float(0.95), uv().y))
    const fade = fadeX.mul(fadeY)

    m.colorNode = combinedColor.mul(float(1).add(scanline))
    m.emissiveNode = combinedColor.mul(float(0.5))
    m.opacityNode = fade.mul(0.9)
    m.roughnessNode = float(0)
    m.metalnessNode = float(0)

    return m
  }, [contentMap])

  return (
    <mesh>
      <planeGeometry args={[3, 2, 1, 1]} />
      <primitive object={mat} />
    </mesh>
  )
}
```

#### The Complete Retrofit Scene

```tsx
import { Canvas, useFrame } from '@react-three/fiber'
import { Suspense, useMemo, useEffect, useRef } from 'react'
import { EffectComposer, Bloom } from '@react-three/postprocessing'
import { WebGPURenderer } from 'three/webgpu'
import { OrbitControls, Environment } from '@react-three/drei'

// Compact compute-driven particle system for the scene atmosphere
function AtmosphericParticles() {
  const COUNT = 5000
  const meshRef = useRef<any>(null!)

  const mat = useMemo(() => {
    const m = new MeshStandardNodeMaterial()
    const floatAnim = sin(
      time.mul(2).add(instanceIndex.toFloat().mul(0.1))
    ).mul(0.5)
    m.positionNode = positionLocal.add(vec3(0, floatAnim, 0))
    m.colorNode = color('#00aaff')
    m.emissiveNode = color('#00aaff').mul(float(2))
    m.roughnessNode = float(0)
    return m
  }, [])

  useEffect(() => {
    const mesh = meshRef.current
    const dummy = new Object3D()
    for (let i = 0; i < COUNT; i++) {
      dummy.position.set(
        (Math.random() - 0.5) * 20,
        Math.random() * 10,
        (Math.random() - 0.5) * 20
      )
      const s = 0.02 + Math.random() * 0.05
      dummy.scale.setScalar(s)
      dummy.updateMatrix()
      mesh.setMatrixAt(i, dummy.matrix)
    }
    mesh.instanceMatrix.needsUpdate = true
  }, [])

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, COUNT]}>
      <sphereGeometry args={[1, 4, 4]} />
      <primitive object={mat} />
    </instancedMesh>
  )
}

// The complete scene combining all three retrofitted objects
export function RetrofitScene() {
  return (
    <Canvas
      gl={(canvas) => {
        const renderer = new WebGPURenderer({ canvas, antialias: true })
        renderer.toneMapping = ACESFilmicToneMapping
        renderer.toneMappingExposure = 1.2
        return renderer
      }}
      camera={{ position: [0, 3, 8], fov: 60 }}
    >
      <Suspense fallback={null}>
        <Environment preset="night" />

        {/* Three retrofitted objects */}
        <group position={[-4, 2, 0]}>
          <EnergyShield />
        </group>

        <group position={[0, 0, 0]} scale={[2, 2, 2]}>
          <TerrainMaterial />
        </group>

        <group position={[4, 2, 0]}>
          <HolographicDisplay />
        </group>

        {/* Compute-driven ambient particles */}
        <AtmosphericParticles />

        {/* Crystal field from Section 3 */}
        <CrystalField />

        <OrbitControls />

        {/* Post-processing: bloom to make emissives glow */}
        <EffectComposer>
          <Bloom intensity={2} luminanceThreshold={0.5} radius={0.6} />
          <HeatDistortion strength={0.005} speed={0.5} />
        </EffectComposer>
      </Suspense>
    </Canvas>
  )
}
```

---

## Pitfalls

### 1. Importing from the Wrong Package

```tsx
// WRONG: These look like they should work but produce subtle bugs or type errors
import { sin, color, vec3 } from 'three'                    // Three.js math, NOT TSL nodes
import { MeshStandardNodeMaterial } from 'three'            // WebGL version, no node support
import { MeshStandardNodeMaterial } from 'three/examples/jsm/...' // Old import path, outdated

// RIGHT: Always use these exact import paths
import { sin, color, vec3, float, uv, time } from 'three/tsl'
import { MeshStandardNodeMaterial, WebGPURenderer } from 'three/webgpu'
```

The symptom of the wrong import: `sin(time)` returns a `number`, not a `ShaderNodeObject`. Operations on it won't compose into the node graph, and the material will silently render incorrectly (often solid black or white).

### 2. Drei Materials That Don't Support Node Overrides

```tsx
// WRONG: Some drei materials use their own rendering passes, not NodeMaterial
import { MeshReflectorMaterial, MeshTransmissionMaterial } from '@react-three/drei'

// These materials DO work with TSL in newer drei versions (check drei changelog):
<MeshTransmissionMaterial
  // These props control TSL node overrides when running Three.js r170+
  // But older versions silently ignore them
/>

// RIGHT: For full TSL control, use the base node material directly
import { MeshPhysicalNodeMaterial } from 'three/webgpu'

function SafeGlassMaterial() {
  const mat = useMemo(() => {
    const m = new MeshPhysicalNodeMaterial()
    // All TSL overrides work reliably here
    m.transmission = 1
    m.thickness = 0.5
    m.colorNode = mix(color('#88aaff'), refractedBg, fresnel)
    return m
  }, [])

  return <primitive object={mat} />
}
```

### 3. Creating New Nodes Every Frame

```tsx
// WRONG: This creates new TSL node objects every frame,
// forcing shader recompilation constantly (massive performance hit)
useFrame(({ clock }) => {
  meshRef.current.material.colorNode = color('#ff0000').mul(
    sin(float(clock.getElapsedTime()))  // NEW nodes every frame!
  )
})

// RIGHT: Create nodes once, update uniform values
const timeUniform = useMemo(() => uniform(0, 'float'), [])
const mat = useMemo(() => {
  const m = new MeshStandardNodeMaterial()
  m.colorNode = color('#ff0000').mul(sin(timeUniform))  // Built once
  return m
}, [timeUniform])

useFrame(({ clock }) => {
  timeUniform.value = clock.getElapsedTime()  // Just update the value
})
```

### 4. Post-Processing outputNode Conflicts

```tsx
// WRONG: Setting outputNode on a material when using EffectComposer
// outputNode replaces the entire fragment output, bypassing post-processing
const mat = new MeshStandardNodeMaterial()
mat.outputNode = myCustomOutput  // This can break tone mapping and EffectComposer

// RIGHT: Use specific node slots (colorNode, emissiveNode) instead of outputNode
// outputNode is for advanced cases where you need full control of the output stage
// Only use it if you know exactly what you're overriding
mat.colorNode = myCustomColor       // Safe: overrides PBR color input
mat.emissiveNode = myCustomEmit     // Safe: overrides emissive input
// Leave outputNode unset — Three.js handles tone mapping and output encoding
```

### 5. WGSL Generation Differences Between Browsers

```tsx
// Firefox's WebGPU implementation (via wgpu) is slightly stricter
// about integer type conversions than Chrome's Dawn backend
// This causes silent failures or validation errors on Firefox only

// WRONG (works in Chrome, fails in Firefox):
const index = instanceIndex           // uint32 in WGSL
const floatVal = index.mul(0.1)      // Implicitly cast? Not in strict WGSL

// RIGHT: Explicit type conversion
const index = instanceIndex.toFloat()  // Explicitly convert to f32
const floatVal = index.mul(0.1)        // Now safe across all backends

// Similarly, always use float() for decimal literals in integer contexts:
const count = int(10)                  // Explicit integer
const countF = count.toFloat()         // Explicit float conversion
```

---

## Exercises

### Exercise 1: GLSL to TSL Converter (2–3 hours)

**Goal:** Take a Shadertoy shader you admire and convert it to TSL using the cookbook in Section 6.

**Requirements:**
- Choose any Shadertoy shader that uses: uniforms, noise, conditionals, and texture sampling
- Convert it to a `MeshStandardNodeMaterial` using TSL
- The material should be parameterized (at least 3 `uniform()` nodes exposed as React props)
- Display it on a sphere in an R3F scene with orbit controls

**Hints:**
- Start by identifying every `uniform` declaration and map them to `uniform()` nodes
- Replace `gl_FragCoord` with `screenUV`
- Replace `iTime` with `time`
- The most common Shadertoy trick — `hash()` for noise — translates directly using `Fn()`

**Stretch goal:** Create a React UI (with leva) that lets you adjust the material parameters in real time and see the result. Add a button that logs the material's `customProgramCacheKey()` and the generated fragment shader source.

### Exercise 2: Instanced Crystal Garden (3–4 hours)

**Goal:** Build the 10,000-crystal scene from Section 3 with additional features.

**Requirements:**
- 10,000 instanced crystals with per-instance procedural color from a storage buffer
- A compute shader that updates each crystal's Y position for floating animation (see Module 15 for compute setup)
- Crystals should react to a "disturbance" point: when the user clicks on the terrain, nearby crystals ripple outward from the click point
- The disturbance should use a `uniform()` for the click position and time, no JS-side per-crystal updates

**Hints:**
- Store crystal base positions in a storage buffer alongside their phase offsets
- The ripple effect: compute distance from each crystal base position to the disturbance point, use `smoothstep` on the distance to create a radial wave
- `useFrame` can update the disturbance time uniform; `onClick` on the terrain plane updates the position uniform

**Stretch goal:** Add LOD: crystals far from the camera use a simple `coneGeometry(0, 4)` while nearby ones use `coneGeometry(6, 6)`. Implement this with `BatchedMesh` instead of `InstancedMesh`.

### Exercise 3: TSL Utility Library (3–5 hours)

**Goal:** Build a reusable, fully typed TSL utility library for your project.

**Requirements:**
- Minimum 8 utility functions as `Fn()` exports, covering:
  - At least 2 noise functions (e.g., value noise, FBM)
  - At least 2 pattern generators (e.g., checkerboard, hexagonal grid)
  - At least 2 lighting helpers (e.g., cel-shade, rim light)
  - At least 2 animation helpers (e.g., pulse, bounce easing)
- Every function must have TypeScript types on its parameters and return value
- Write a demo scene that composes 3 different materials using only functions from your library (no inline TSL math)
- Each material should look visually distinct

**Hints:**
- Look at GLSL shader libraries (lygia, glsl-noise) for inspiration on what functions to include
- `ShaderNodeObject<Node>` is the general type for most parameters — specialize with `FloatNode`, `Vec3Node` when you can
- The factory function pattern (a function that returns a configured node) is more flexible than a plain `Fn()` when you need TypeScript generics

**Stretch goal:** Publish your utility library as an npm package with proper TypeScript declarations. Write a README with usage examples for each function.

### Exercise 4: Full Retrofit + Profiling (4–6 hours)

**Goal:** Extend the Retrofit project from the Code Walkthrough into a complete profiled scene comparison.

**Requirements:**
- Implement the full Retrofit scene (3 GLSL objects + 3 TSL versions)
- Add a toggle button that swaps between GLSL `ShaderMaterial` and TSL `MeshStandardNodeMaterial` versions of each object
- Integrate `r3f-perf` and record:
  - FPS, draw calls, and triangle count for both versions
  - GPU frame time (if available via the performance API)
- Add the `AtmosphericParticles` compute-driven system and the `HeatDistortion` post-processing effect
- Display a side-by-side comparison panel showing the performance metrics for each version

**Hints:**
- Use Zustand to store which version (GLSL vs TSL) is active, to avoid re-creating materials on every toggle
- `r3f-perf`'s `usePerf()` hook gives you frame-level metrics — store them in a ref to display before/after
- The cold start difference (first frame is always slow due to shader compilation) is expected — measure steady-state performance after 2 seconds

**Stretch goal:** Write a blog post (or README) documenting your findings. Did TSL perform better or worse than raw GLSL? Where was the overhead? What surprised you?

---

## API Quick Reference

### Drei + TSL Integration

| Drei Material | TSL Node Override Support | Notes |
|---|---|---|
| `MeshStandardNodeMaterial` | Full | Use this as your primary material |
| `MeshPhysicalNodeMaterial` | Full | Add clearcoat, transmission, iridescence |
| `shaderMaterial` (drei) | Not directly | Convert to `MeshStandardNodeMaterial` |
| `MeshReflectorMaterial` | Partial | Wrap reflection texture as `texture()` node |
| `MeshTransmissionMaterial` | Partial (v1.9+) | Check drei changelog for node support |
| `SpotLight`, `PointLight` | N/A | Light nodes (from drei) work with TSL scenes |

### Post-Processing + TSL

| Pattern | API | Notes |
|---|---|---|
| Custom GLSL effect | `class MyEffect extends Effect` | Standard — works alongside TSL materials |
| Wrap effect for R3F | `wrapEffect(MyEffect)` from `@react-three/postprocessing` | Exposes as React component |
| Read scene buffer | `inputBuffer` texture in Effect GLSL | Available in Effect's `mainImage` |
| Screen UV | `screenUV` (TSL) / `vUv` (Effect GLSL) | Different coordinate systems |
| Scene texture in TSL | `viewportSharedTexture(screenUV)` | For screen-space sampling in materials |
| outputNode | `material.outputNode` | Use sparingly — overrides all output encoding |

### GLSL → TSL Cheat Sheet

| GLSL | TSL | Notes |
|---|---|---|
| `uniform float x` | `uniform(0, 'float')` | Update via `.value` |
| `vUv` | `uv()` | Auto-interpolated built-in |
| `texture2D(map, uv)` | `texture(map, uv())` | |
| `gl_FragCoord.xy` | `screenUV.mul(screenSize)` | `screenUV` is already normalized |
| `gl_InstanceID` | `instanceIndex` | Convert to float with `.toFloat()` |
| `a * b` | `a.mul(b)` or `mul(a, b)` | No operator overloading |
| `mix(a, b, t)` | `mix(a, b, t)` | Same name |
| `if/else` | `If().Else()` or `select()` | Prefer `select()` for performance |
| `for (int i=0; i<N; i++)` | `Loop(N, ({i}) => {...})` | TSL managed loop |
| Custom function | `Fn(([a, b]) => {...})` | Returns callable node |
| `.toVar()` | Mutable local variable | Required before `.assign()` |
| `normalMatrix * normal` | `normalWorld` | Built-in |
| `modelViewPosition` | `positionView` | Built-in |

### Debug Tools

| Tool | Use Case | Notes |
|---|---|---|
| `r3f-perf` | Real-time FPS, GPU, draw calls | `npm i r3f-perf` — add `<Perf />` to scene |
| Spector.js | Frame capture, shader inspection | Chrome extension — shows generated WGSL |
| `chrome://gpu` | WebGPU capability check | See enabled features and validation errors |
| `renderer.debug.checkShaderErrors` | WebGL shader compile errors | Set to `true` in development |
| `material.customProgramCacheKey()` | Identify material variant | Stable key for a given node configuration |
| Chrome DevTools → Performance | GPU frame timing | See "GPU" track in performance recordings |
| `.toVar()` | Mutable shader variables | Enables `If()` / `Loop()` mutation |
| `wgslFn()` | Raw WGSL in TSL | Escape hatch for unsupported patterns |

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Three.js TSL Docs](https://threejs.org/docs/pages/TSL.html) | Official Docs | The definitive node API reference — read this alongside your code |
| [Three.js TSL Examples](https://threejs.org/examples/?q=tsl) | Interactive Examples | Hundreds of live TSL examples with source — best learning resource |
| [Three.js WebGPU Source](https://github.com/mrdoob/three.js/tree/dev/src/nodes) | Source Code | Read the node source to understand what properties are available |
| [WGSL Spec](https://www.w3.org/TR/WGSL/) | Spec | When generated WGSL errors are cryptic, the spec clarifies |
| [WebGPU Fundamentals](https://webgpufundamentals.org) | Tutorial Series | Best conceptual explanation of the WebGPU pipeline |
| [The Book of Shaders](https://thebookofshaders.com) | Interactive Book | GLSL-first, but the math and patterns translate directly to TSL |
| [pmndrs/postprocessing](https://github.com/pmndrs/postprocessing) | Source Code | Effect class internals — essential for custom effects |
| [Spector.js](https://github.com/BabylonJS/Spector.js) | Tool | GPU frame inspector — the most powerful debugging tool for shader work |
| [lygia shader library](https://lygia.xyz) | Shader Library | Comprehensive GLSL utilities — great migration targets for TSL `Fn()` |
| [r3f-perf](https://github.com/utsuboco/r3f-perf) | Tool | Real-time performance overlay for R3F — always have this running in dev |

---

## Key Takeaways

1. **TSL and drei coexist cleanly when you pick the right entry point.** Use `MeshStandardNodeMaterial` and `MeshPhysicalNodeMaterial` from `three/webgpu` as your base materials — they support full TSL node overrides. Drei material helpers are convenient but may lag behind node support; when in doubt, use the base node material directly.

2. **Post-processing is still best written in GLSL via the Effect class.** The `@react-three/postprocessing` ecosystem is battle-tested with GLSL. Writing effects as TSL nodes that feed into a custom render pass is possible but adds complexity. Use TSL for material nodes, GLSL for post-processing effects, and don't fight the layering.

3. **Per-instance TSL reads are the future of InstancedMesh.** Reading per-instance data from storage buffers via `instanceIndex` and `storage()` is dramatically cleaner than the WebGL `InstancedBufferAttribute` pattern. The TSL graph handles the attribute wiring and the compiler optimizes the access patterns.

4. **`Fn()` composition enables a proper shader library architecture.** Unlike GLSL functions that live in concatenated strings, `Fn()` creates first-class TypeScript values that can be typed, tested in isolation, parameterized with factory functions, and composed into arbitrarily complex materials. Build your library once, use it everywhere.

5. **The TSL compiler is smarter than you think.** Common subexpression elimination means you should reference the same node object in multiple places without fear — the compiler computes it once. Prefer `select()` over `If()` for branchless conditionals. Don't create new node objects in `useFrame` — create nodes once, update `uniform()` values.

6. **Migration from GLSL is mechanical, not creative.** Every GLSL pattern has a direct TSL equivalent. The migration cookbook covers 90% of cases. The 10% that remain — complex `#pragma` annotations, texture arrays, custom extensions — are handled by `wgslFn()` as an escape hatch. You don't need to rewrite your entire GLSL library at once; migrate shader by shader as you touch them.

7. **TypeScript types for TSL are functional but imperfect.** Import everything from `three/tsl` and `three/webgpu`. Use `as any` when the types lag behind the actual API (especially for newer material properties). Keep casts in one place (your material factories) so they're easy to remove as the types improve. The investment in TSL's type safety — autocomplete, refactoring, compile-time checks on node composition — pays back immediately when you're building complex multi-file shader libraries.

---

## What's Next?

This is the final module in the TSL track, and you've now covered the complete arc: from GLSL strings in Module 6, through the WebGPU paradigm shift in Module 12, deep material and texture work in Module 14, advanced compute patterns in Module 15, and now the full ecosystem integration here in Module 16.

Where you go from here depends on what you're building:

- **If you're shipping a game:** Return to the [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md) and work through Module 13 (Build, Ship & What's Next). Your TSL materials are already production-ready — now it's time to compress assets, audit bundle size, and deploy.

- **If you want to go deeper on GPU programming:** The natural next step is reading the [WebGPU spec](https://www.w3.org/TR/webgpu/) and [WGSL spec](https://www.w3.org/TR/WGSL/) directly. Understanding the GPU pipeline at this level lets you optimize TSL output, write `wgslFn()` escapes precisely, and reason about exactly what the compiler produces.

- **If post-processing is your focus:** The [pmndrs/postprocessing library source](https://github.com/pmndrs/postprocessing) is worth reading in full. The built-in effects are excellent starting points for learning how complex screen-space effects are structured, and the Effect class architecture supports arbitrarily sophisticated compositions.

- **If procedural content is your next goal:** TSL Fn() library patterns from this module pair directly with the procedural world generation techniques from Module 8. The combination of compute-driven terrain generation, TSL materials with triplanar mapping, and instanced vegetation with per-instance node overrides is a powerful stack for open-world games.

The skills you've built across the TSL track — node composition, GLSL migration, TypeScript integration, GPU debugging — are transferable far beyond Three.js. The mental model of composable, typed, GPU-targeted functions is the direction the entire real-time graphics industry is moving, from USD/MaterialX in film, to shader graphs in game engines, to TSL on the web.

---

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
