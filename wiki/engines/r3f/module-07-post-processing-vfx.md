# Module 7: Post-Processing & VFX

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 8–12 hours
**Prerequisites:** [Module 6: Shaders & Stylized Rendering](module-06-shaders-stylized-rendering.md)

---

## Overview

You've learned how to write custom shaders that run on individual materials. Now you're going to learn the other side of the visual equation: effects that run on the *entire screen* after the scene has been rendered. Bloom that makes neon signs bleed light. Film grain that sells a horror vibe. Chromatic aberration that screams cyberpunk. Depth of field that guides the player's eye. These are post-processing effects, and they're responsible for at least half of the visual identity of any modern game.

This module covers the full post-processing pipeline in R3F using `@react-three/postprocessing`, from built-in effects like bloom and vignette to writing your own custom GLSL effects from scratch. You'll also build particle systems — the other half of game VFX — starting from naive approaches and working up to GPU-driven point particles that can handle tens of thousands of sparks, embers, and explosions without breaking a sweat.

The mini-project ties it all together: a mood board scene where a single 3D environment can be viewed through four completely different visual lenses — cyberpunk, pastoral, horror, and retro — each built from a different stack of post-processing effects. Swap between them with a keypress and watch the same geometry feel like four different games.

---

## 1. What Post-Processing Is

### The Core Concept

Here's the idea. Your scene renders normally — meshes, lights, materials, shadows — and the result is a texture. A flat 2D image sitting in a framebuffer. Post-processing takes that texture and runs additional shader passes on it *before* it reaches the screen. You're not changing the 3D scene at all. You're changing the photograph of the scene.

Think of it like Instagram filters, but with full GPU shader power. The scene renders to an off-screen texture, then a full-screen quad (two triangles covering the entire viewport) samples that texture and applies effects — blur, color shifts, distortion, whatever you want.

### Why This Is Different From Material-Level Effects

In Module 6, you wrote shaders that run per-object. A custom material on a mesh affects only that mesh. Post-processing runs on the *entire rendered frame*. It doesn't know about individual objects — it only sees pixels.

This distinction matters:
- **Material shaders** know about geometry, normals, UV coordinates, vertex positions
- **Post-processing shaders** know about screen-space pixel colors, depth buffer values, and screen coordinates
- Material effects are per-object. Post effects are per-frame.
- You can't make a single object bloom with a material shader alone. You need post-processing.

### The Ping-Pong Buffer Pattern

When you stack multiple effects, the output of one becomes the input of the next. The renderer uses two framebuffers — call them A and B — and alternates between them:

1. Render the scene to buffer A
2. Effect 1 reads from A, writes result to B
3. Effect 2 reads from B, writes result to A
4. Effect 3 reads from A, writes result to B
5. Final result goes to the screen

This is called "ping-pong" rendering. Each effect gets a clean input texture and writes to a clean output texture. The `EffectComposer` handles all of this automatically — you never manage buffers yourself. But understanding the pattern helps you reason about performance (each effect = one full-screen draw call) and effect ordering (each effect only sees the output of the previous one).

### What Data Is Available

Post-processing effects can access more than just the color buffer. The most important additional data source is the **depth buffer** — a texture where each pixel stores how far that point is from the camera. This enables effects like:
- **Depth of field** — blur pixels that are far from the focus distance
- **Fog** — fade pixels toward a color based on depth
- **God rays** — volumetric light scattering based on depth occlusion
- **SSAO** — darken crevices based on nearby depth discontinuities

Some effects also use the **normal buffer** (surface orientation per pixel) or **velocity buffer** (motion per pixel for motion blur). The postprocessing library manages these auxiliary buffers for you.

---

## 2. EffectComposer Setup

### Installing the Library

`@react-three/postprocessing` is the React wrapper around the `postprocessing` library by vanruesc. It's the standard solution for post-processing in R3F — faster than Three.js's built-in `EffectComposer` because it merges compatible effects into single shader passes.

```bash
npm install @react-three/postprocessing postprocessing
```

You need both packages. `@react-three/postprocessing` provides the React components. `postprocessing` provides the underlying effect implementations and types you'll need for custom effects.

### Basic Setup

Wrap your scene content with `<EffectComposer>`:

```tsx
import { Canvas } from '@react-three/fiber'
import { EffectComposer, Bloom, Vignette } from '@react-three/postprocessing'

export default function App() {
  return (
    <Canvas camera={{ position: [0, 2, 5] }}>
      {/* Your scene content — lights, meshes, everything */}
      <ambientLight intensity={0.5} />
      <directionalLight position={[5, 5, 5]} />
      <mesh>
        <boxGeometry />
        <meshStandardMaterial color="orange" />
      </mesh>

      {/* Post-processing effects — must be INSIDE Canvas */}
      <EffectComposer>
        <Bloom intensity={0.5} luminanceThreshold={0.9} />
        <Vignette darkness={0.5} offset={0.3} />
      </EffectComposer>
    </Canvas>
  )
}
```

The `<EffectComposer>` component intercepts the normal rendering pipeline. Instead of rendering directly to the screen, R3F renders to an off-screen texture, then `EffectComposer` applies the child effects in order and outputs the final result to the screen.

### Key EffectComposer Props

| Prop | Type | Default | What It Does |
|------|------|---------|--------------|
| `enabled` | `boolean` | `true` | Toggle all effects on/off without unmounting |
| `multisampling` | `number` | `8` | MSAA samples. Higher = smoother edges, more GPU cost. Set to `0` to disable |
| `stencilBuffer` | `boolean` | `false` | Enable stencil buffer for masking effects to specific regions |
| `depthBuffer` | `boolean` | `true` | Enable depth buffer access (needed for DoF, fog, god rays) |
| `autoClear` | `boolean` | `true` | Whether to clear the framebuffer between frames |

### Performance Cost Awareness

Every effect added to the composer has a cost. It's not huge for simple effects — a vignette is basically free — but it adds up:

- Each effect that can't be merged = one full-screen draw call
- Full-screen draw calls touch every pixel on screen. At 1920x1080, that's ~2 million pixels. At 4K, it's ~8 million.
- Effects that sample neighboring pixels (blur, chromatic aberration) are more expensive than per-pixel color transforms (brightness, contrast)
- Bloom is particularly expensive because it involves multiple blur passes at different resolutions

The `postprocessing` library is smart about merging effects. Simple per-pixel effects (brightness, contrast, vignette) get merged into a single shader pass. But effects with unique sampling patterns (bloom, DoF) must run as separate passes.

Rule of thumb: 3-4 effects is fine for most games. 6+ effects and you should be profiling on your target hardware. Mobile/low-end should stick to 1-2 lightweight effects.

### Conditionally Enabling Effects

You can toggle effects on and off without unmounting, which is cheaper than conditional rendering:

```tsx
<EffectComposer>
  <Bloom intensity={bloomEnabled ? 0.8 : 0} />
  <Vignette darkness={vignetteEnabled ? 0.5 : 0} />
</EffectComposer>
```

Or use conditional rendering if you want to completely remove the GPU cost:

```tsx
<EffectComposer>
  {bloomEnabled && <Bloom intensity={0.8} />}
  {vignetteEnabled && <Vignette darkness={0.5} />}
</EffectComposer>
```

The second approach fully removes the effect from the pipeline, but causes the shader to recompile when effects are added/removed. For real-time toggling (like a settings menu), set intensity to 0 instead.

---

## 3. Built-In Effects

### Bloom

Makes bright areas bleed light outward. The single most popular post-processing effect in games.

```tsx
import { Bloom } from '@react-three/postprocessing'

<Bloom
  intensity={1.0}              // Overall bloom strength
  luminanceThreshold={0.9}     // Brightness cutoff — only pixels brighter than this bloom
  luminanceSmoothing={0.025}   // Smoothness of the threshold transition
  mipmapBlur                   // Use mipmap-based blur (faster, smoother)
/>
```

**Before:** A neon sign is just a bright flat color.
**After:** The neon sign radiates light into the surrounding area, with soft falloff.

To make objects bloom, you need bright pixels. The easiest way: use emissive materials with `emissiveIntensity` greater than 1, and set `toneMapped={false}` on the material so the values aren't clamped:

```tsx
<meshStandardMaterial
  color="#00ffff"
  emissive="#00ffff"
  emissiveIntensity={3}
  toneMapped={false}
/>
```

### Vignette

Darkens the edges and corners of the screen. Subtle but powerful — it draws the eye to the center and adds a cinematic feel.

```tsx
import { Vignette } from '@react-three/postprocessing'

<Vignette
  darkness={0.5}    // How dark the edges get (0-1)
  offset={0.3}      // How far the darkening extends inward (0-1)
  eskil={false}     // Use Eskil's vignette technique (different falloff curve)
/>
```

**Before:** Flat, even exposure across the entire frame.
**After:** Edges subtly darken, creating a natural focus on the center.

### Chromatic Aberration

Splits the color channels slightly, creating colored fringes at the edges of the screen. Looks techy, slightly broken, very cyberpunk.

```tsx
import { ChromaticAberration } from '@react-three/postprocessing'
import { Vector2 } from 'three'

<ChromaticAberration
  offset={new Vector2(0.002, 0.002)}   // RGB channel offset amount
  radialModulation                       // Stronger at edges, none at center
  modulationOffset={0.5}                // How far from center the effect starts
/>
```

**Before:** Clean, sharp image with no color fringing.
**After:** Subtle rainbow fringes at object edges, especially toward screen edges.

### Noise

Adds film grain or static noise. Sells a horror, vintage, or analog video look.

```tsx
import { Noise } from '@react-three/postprocessing'
import { BlendFunction } from 'postprocessing'

<Noise
  opacity={0.3}                              // Noise visibility (0-1)
  blendFunction={BlendFunction.OVERLAY}      // How noise blends with the scene
/>
```

The `BlendFunction` controls how noise combines with the image. Common choices:
- `BlendFunction.OVERLAY` — enhances contrast along with noise
- `BlendFunction.SOFT_LIGHT` — subtle, filmic grain
- `BlendFunction.SCREEN` — brightens, like old CRT static

### Depth of Field

Blurs objects that aren't at the focus distance. Simulates a camera lens with a wide aperture. Great for drawing attention to a specific subject.

```tsx
import { DepthOfField } from '@react-three/postprocessing'

<DepthOfField
  focusDistance={0}       // Normalized focus distance (0 = near plane, 1 = far plane)
  focalLength={0.02}     // Camera focal length (affects blur amount)
  bokehScale={2}         // Size of the bokeh blur circles
  height={480}           // Render height for the blur pass (lower = cheaper + blurrier)
/>
```

**Before:** Everything is in sharp focus regardless of distance.
**After:** Objects at the focus distance are sharp; everything else softly blurs, with distant objects showing circular bokeh.

Depth of field is one of the more expensive effects. The `height` prop controls the resolution of the blur pass — lower values are cheaper but blurrier. For a game, `480` is usually fine.

### BrightnessContrast

Simple but useful. Adjusts the overall brightness and contrast of the frame.

```tsx
import { BrightnessContrast } from '@react-three/postprocessing'

<BrightnessContrast
  brightness={0.05}     // -1 to 1 (0 = no change)
  contrast={0.1}        // -1 to 1 (0 = no change)
/>
```

### HueSaturation

Shifts the hue and adjusts saturation of the entire frame. Desaturation is key for horror or bleak moods.

```tsx
import { HueSaturation } from '@react-three/postprocessing'

<HueSaturation
  hue={0}               // Hue shift in radians (-Math.PI to Math.PI)
  saturation={-0.3}     // Saturation adjustment (-1 = grayscale, 0 = no change)
/>
```

### Putting Them Together

Here's a quick stack that creates a moody, cinematic look:

```tsx
<EffectComposer>
  <Bloom intensity={0.3} luminanceThreshold={0.8} mipmapBlur />
  <BrightnessContrast brightness={-0.05} contrast={0.15} />
  <HueSaturation saturation={-0.15} />
  <Vignette darkness={0.4} offset={0.3} />
</EffectComposer>
```

Four effects, one line each. The scene goes from flat and evenly-lit to cinematic and moody. This is why post-processing is such a powerful tool — massive visual impact with minimal code.

---

## 4. Color Grading

### What Color Grading Does

Color grading is the process of shifting the overall color palette of your scene to achieve a specific mood. Hollywood movies do it obsessively — blue-orange for action films, teal-warm for indie dramas, desaturated cold tones for thrillers. You can do the exact same thing with post-processing.

### ToneMapping

Tone mapping converts HDR (high dynamic range) color values to the LDR (low dynamic range) that your monitor can display. Different tone mapping algorithms produce very different looks from the same scene.

R3F/Three.js applies tone mapping by default. You can change it on the Canvas:

```tsx
import { ACESFilmicToneMapping, CineonToneMapping, ReinhardToneMapping } from 'three'

<Canvas
  gl={{
    toneMapping: ACESFilmicToneMapping,  // Default — cinematic, good contrast
  }}
>
```

| ToneMapping Type | Visual Character |
|-----------------|------------------|
| `NoToneMapping` | Raw values, can look washed out or blown out |
| `LinearToneMapping` | Simple linear scale, flat |
| `ReinhardToneMapping` | Soft highlight rolloff, classic look |
| `CineonToneMapping` | Film-like, slightly desaturated highlights |
| `ACESFilmicToneMapping` | Cinematic, good contrast, slightly warm — the default and usually the best |
| `AgXToneMapping` | Modern alternative to ACES, better color preservation |

You can also control tone mapping per-effect using the `ToneMapping` effect:

```tsx
import { ToneMapping } from '@react-three/postprocessing'
import { ToneMappingMode } from 'postprocessing'

<EffectComposer>
  <ToneMapping mode={ToneMappingMode.ACES_FILMIC} />
</EffectComposer>
```

### BrightnessContrast + HueSaturation Stacking

For quick color grading without LUT textures, stack these two effects:

```tsx
{/* Warm, slightly desaturated — post-apocalyptic vibe */}
<BrightnessContrast brightness={-0.1} contrast={0.2} />
<HueSaturation hue={0.05} saturation={-0.2} />
```

```tsx
{/* Cool, high-contrast — sci-fi vibe */}
<BrightnessContrast brightness={0.0} contrast={0.3} />
<HueSaturation hue={-0.1} saturation={0.1} />
```

### LUT Textures for Cinematic Looks

A LUT (Look-Up Table) is a small texture — typically 256x16 or a 3D texture — that remaps every input color to an output color. Professional colorists create LUTs to achieve specific looks, and you can apply them as a post-processing effect.

```tsx
import { LUT3DEffect } from 'postprocessing'
import { useLoader } from '@react-three/fiber'
import { LookupTexture } from 'postprocessing'
import { useEffect, useState } from 'react'

function LUTEffect() {
  const [lut, setLut] = useState<any>(null)

  useEffect(() => {
    // Load a .cube or .png LUT file
    LookupTexture.from('/luts/cinematic-warm.png').then((result) => {
      setLut(result)
    })
  }, [])

  if (!lut) return null

  return (
    <EffectComposer>
      <primitive object={new LUT3DEffect(lut)} />
    </EffectComposer>
  )
}
```

### Where to Find LUT Textures

- **Free LUT packs** — Search "free LUT pack for games" or "free .cube LUT files." Many filmmakers share theirs.
- **Create your own** — Open a screenshot of your game in Photoshop or DaVinci Resolve, grade it how you want, and export the adjustment as a .cube file.
- **RocketStock, FilterGrade** — Free and paid LUT packs.
- **Unity/Unreal asset stores** — Many LUT packs are cross-engine compatible (the .cube format is universal).

The key insight: LUTs let you do complex, nonlinear color transformations in a single texture lookup. A warm cinematic grade that would take 10 lines of color math can be baked into one tiny texture.

### Manual Color Grading With Uniforms

If you want precise control without external LUT files, you can build a custom color grading effect:

```tsx
// Simple color grading using built-in effects
<EffectComposer>
  {/* Lift shadows, gamma mid-tones, gain highlights */}
  <BrightnessContrast brightness={-0.05} contrast={0.15} />
  <HueSaturation hue={0.02} saturation={-0.1} />

  {/* Tint the highlights warm and shadows cool */}
  {/* This requires a custom effect — we'll cover that in section 6 */}
</EffectComposer>
```

The built-in effects cover 80% of color grading needs. For the remaining 20% (split-toning, color curves, channel mixing), you'll write custom effects.

---

## 5. Bloom Deep Dive

### How Bloom Actually Works

Bloom is probably the effect you'll use most, so it's worth understanding the pipeline under the hood.

**Step 1: Brightness extraction.** The bloom effect reads the rendered scene and extracts only the pixels above a brightness threshold. Everything below the threshold becomes black. This creates a "bright spots only" image.

**Step 2: Blur.** The bright spots image is blurred — typically using a multi-pass Gaussian blur at progressively lower resolutions (mipmap levels). This creates the soft, spreading glow.

**Step 3: Blend.** The blurred bright spots are added back on top of the original scene. Bright areas now glow, and the glow extends into surrounding darker areas.

The mipmap approach (`mipmapBlur={true}`) is key to performance. Instead of blurring at full resolution (expensive), the image is downsampled to half size, quarter size, eighth size, etc. Each level is blurred cheaply, then all levels are combined. This gives you a wide, smooth glow for very little GPU cost.

### The Bloom Parameters

```tsx
<Bloom
  intensity={1.5}              // How strong the glow is. 0 = off, 1 = normal, 2+ = strong
  luminanceThreshold={0.9}     // Brightness cutoff. 0 = everything blooms, 1 = only pure white
  luminanceSmoothing={0.025}   // Transition width. 0 = hard cutoff, higher = gradual
  mipmapBlur                   // Use efficient mipmap blur (almost always want this on)
  radius={0.85}                // Blur radius when using mipmapBlur (0-1)
/>
```

**`luminanceThreshold`** is the most important parameter. Too low and everything glows — your entire scene looks like it's underwater. Too high and nothing glows at all. Start at `0.9` and adjust.

**`luminanceSmoothing`** controls the transition zone around the threshold. At `0`, there's a hard cutoff — pixels are either blooming at full strength or not at all. A small smoothing value (0.025 to 0.1) creates a natural falloff.

**`intensity`** scales the final bloom contribution. It's a multiplier on the blurred bright image before it's added to the scene. Values above 1.0 make the bloom very visible. Values around 0.3-0.5 give a subtle, cinematic feel.

### Making Things Glow: The Emissive + Bloom Pipeline

Bloom works on brightness. To make a specific object glow, you need to make it render brighter than the threshold. The recipe:

```tsx
{/* This material renders BRIGHT — it will trigger bloom */}
<meshStandardMaterial
  color="#ff00ff"
  emissive="#ff00ff"
  emissiveIntensity={4}
  toneMapped={false}        // CRITICAL — don't clamp the brightness
/>
```

`toneMapped={false}` is the key. Without it, Three.js tone maps the pixel values to the 0-1 range before the bloom effect sees them. With it disabled on a per-material basis, emissive values above 1.0 pass through to the bloom extraction step.

Here's a complete neon sign example:

```tsx
import { Canvas } from '@react-three/fiber'
import { EffectComposer, Bloom } from '@react-three/postprocessing'
import { Text } from '@react-three/drei'

function NeonSign() {
  return (
    <group>
      {/* Dark background wall */}
      <mesh position={[0, 0, -0.5]}>
        <planeGeometry args={[8, 4]} />
        <meshStandardMaterial color="#111111" />
      </mesh>

      {/* Glowing neon text */}
      <Text
        position={[0, 0, 0]}
        fontSize={1.2}
        font="/fonts/neon-font.woff"
        anchorX="center"
        anchorY="middle"
      >
        OPEN
        <meshStandardMaterial
          color="#ff2266"
          emissive="#ff2266"
          emissiveIntensity={4}
          toneMapped={false}
        />
      </Text>
    </group>
  )
}

export default function App() {
  return (
    <Canvas camera={{ position: [0, 0, 5] }}>
      <ambientLight intensity={0.1} />
      <NeonSign />
      <EffectComposer>
        <Bloom
          intensity={1.2}
          luminanceThreshold={0.8}
          luminanceSmoothing={0.05}
          mipmapBlur
          radius={0.8}
        />
      </EffectComposer>
    </Canvas>
  )
}
```

### Selective Bloom

Sometimes you want bloom on specific objects but not others. The `postprocessing` library supports this through selection:

```tsx
import { Selection, Select, EffectComposer, SelectiveBloom } from '@react-three/postprocessing'

function Scene() {
  return (
    <Selection>
      <EffectComposer>
        <SelectiveBloom
          intensity={1.5}
          luminanceThreshold={0.5}
          mipmapBlur
          lights={[]}  // Array of light refs to include (empty = all)
        />
      </EffectComposer>

      {/* This object will bloom */}
      <Select enabled>
        <mesh position={[-2, 0, 0]}>
          <sphereGeometry args={[0.5, 32, 32]} />
          <meshStandardMaterial
            emissive="#00ffff"
            emissiveIntensity={3}
            toneMapped={false}
          />
        </mesh>
      </Select>

      {/* This object will NOT bloom even if it's bright */}
      <mesh position={[2, 0, 0]}>
        <sphereGeometry args={[0.5, 32, 32]} />
        <meshStandardMaterial color="white" />
      </mesh>
    </Selection>
  )
}
```

Wrap your entire scene in `<Selection>`, wrap bloom targets in `<Select enabled>`, and use `<SelectiveBloom>` instead of `<Bloom>`. Objects outside `<Select>` won't bloom regardless of their brightness.

### Bloom Performance Tips

- Always use `mipmapBlur`. The alternative (Gaussian) is slower for equivalent visual quality.
- Keep `intensity` reasonable. Very high values don't cost more GPU, but they wash out your scene.
- The `radius` prop (0-1) controls how far the glow spreads. Higher radius = more mipmap levels sampled = slightly more cost.
- On mobile or low-end hardware, consider reducing the internal render resolution by setting `height` on the `EffectComposer`.

---

## 6. Custom Post-Processing Effects

### When Built-Ins Aren't Enough

The built-in effects cover common ground. But game-specific looks — scanlines, CRT warping, pixel sorting, heat haze, dream sequences — require custom effects. The `postprocessing` library provides an `Effect` base class you can extend with your own GLSL fragment shader.

### Anatomy of a Custom Effect

A custom effect is a class that extends `Effect` from the `postprocessing` package. It provides a GLSL fragment shader with a specific function signature.

```tsx
import { Effect } from 'postprocessing'
import { Uniform } from 'three'

// The GLSL fragment shader
const fragmentShader = /* glsl */ `
  uniform float intensity;

  void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
    // inputColor = the pixel color from the previous effect (or the scene)
    // uv = screen-space coordinates (0-1)
    // outputColor = what you write as the result

    // Example: simple desaturation
    float gray = dot(inputColor.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desaturated = mix(inputColor.rgb, vec3(gray), intensity);
    outputColor = vec4(desaturated, inputColor.a);
  }
`

export class DesaturationEffect extends Effect {
  constructor({ intensity = 0.5 } = {}) {
    super('DesaturationEffect', fragmentShader, {
      uniforms: new Map([
        ['intensity', new Uniform(intensity)],
      ]),
    })
  }

  // Update uniforms from outside
  set intensity(value: number) {
    this.uniforms.get('intensity')!.value = value
  }

  get intensity(): number {
    return this.uniforms.get('intensity')!.value
  }
}
```

### The mainImage Function Signature

Every custom effect must implement `mainImage`:

```glsl
void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `inputColor` | `vec4` | The pixel color coming in (RGBA, 0-1 range before tone mapping) |
| `uv` | `vec2` | Screen-space coordinates — `(0,0)` is bottom-left, `(1,1)` is top-right |
| `outputColor` | `vec4` | The pixel color going out — write your result here |

You also get access to built-in uniforms automatically:
- `resolution` — `vec2` with the render target size in pixels
- `time` — elapsed time in seconds (if you call `setChanged()` in update)

### Using a Custom Effect in R3F

To use your custom effect in the React pipeline, you create an instance and pass it via the `<primitive>` escape hatch, or better yet, wrap it in a React component using `forwardRef` and `useEffect`:

```tsx
import { forwardRef, useMemo } from 'react'
import { DesaturationEffect } from './DesaturationEffect'

type DesaturationProps = {
  intensity?: number
}

export const Desaturation = forwardRef<DesaturationEffect, DesaturationProps>(
  ({ intensity = 0.5 }, ref) => {
    const effect = useMemo(() => new DesaturationEffect({ intensity }), [])

    useEffect(() => {
      effect.intensity = intensity
    }, [effect, intensity])

    return <primitive ref={ref} object={effect} />
  }
)
```

Now use it like any other effect:

```tsx
<EffectComposer>
  <Bloom intensity={0.5} />
  <Desaturation intensity={0.7} />
</EffectComposer>
```

### Building a Scanline Effect From Scratch

Scanlines are horizontal lines that darken every other row of pixels. Classic CRT monitor look. Here's a complete implementation:

```tsx
// ScanlineEffect.ts
import { Effect } from 'postprocessing'
import { Uniform } from 'three'

const scanlineFragmentShader = /* glsl */ `
  uniform float count;
  uniform float intensity;
  uniform float scrollSpeed;
  uniform float time;

  void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
    // Calculate scanline pattern
    // Multiply UV.y by the count to get the desired number of lines
    float scanline = sin((uv.y + time * scrollSpeed) * count * 3.14159) * 0.5 + 0.5;

    // Raise to a power to make lines sharper
    scanline = pow(scanline, 1.5);

    // Mix between original color and darkened color
    float darken = 1.0 - (1.0 - scanline) * intensity;
    outputColor = vec4(inputColor.rgb * darken, inputColor.a);
  }
`

export class ScanlineEffect extends Effect {
  constructor({
    count = 800.0,
    intensity = 0.3,
    scrollSpeed = 0.0,
  } = {}) {
    super('ScanlineEffect', scanlineFragmentShader, {
      uniforms: new Map([
        ['count', new Uniform(count)],
        ['intensity', new Uniform(intensity)],
        ['scrollSpeed', new Uniform(scrollSpeed)],
        ['time', new Uniform(0)],
      ]),
    })
  }

  update(_renderer: any, _inputBuffer: any, deltaTime: number) {
    const timeUniform = this.uniforms.get('time')!
    timeUniform.value += deltaTime
  }
}
```

The `update` method runs every frame before the effect renders. It receives `deltaTime` (seconds since last frame). Use it to animate uniforms.

### Building a CRT Warp Effect

Barrel distortion that mimics a curved CRT screen. Pixels near the edges are pushed outward.

```tsx
// CRTWarpEffect.ts
import { Effect } from 'postprocessing'
import { Uniform } from 'three'

const crtWarpFragmentShader = /* glsl */ `
  uniform float warpX;
  uniform float warpY;

  void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
    // Center the UV coordinates (-0.5 to 0.5)
    vec2 centered = uv - 0.5;

    // Apply barrel distortion
    float r2 = dot(centered, centered);
    centered *= 1.0 + vec2(warpX, warpY) * r2;

    // Convert back to 0-1 range
    vec2 warped = centered + 0.5;

    // Black out pixels that fall outside the screen
    if (warped.x < 0.0 || warped.x > 1.0 || warped.y < 0.0 || warped.y > 1.0) {
      outputColor = vec4(0.0, 0.0, 0.0, 1.0);
      return;
    }

    // Sample the scene at the warped coordinates
    outputColor = texture2D(inputBuffer, warped);
  }
`

export class CRTWarpEffect extends Effect {
  constructor({ warpX = 0.03, warpY = 0.04 } = {}) {
    super('CRTWarpEffect', crtWarpFragmentShader, {
      uniforms: new Map([
        ['warpX', new Uniform(warpX)],
        ['warpY', new Uniform(warpY)],
      ]),
    })
  }
}
```

Notice the use of `texture2D(inputBuffer, warped)` — when you need to sample the input texture at a *different* UV coordinate than the current pixel (as in any distortion effect), you read from `inputBuffer` directly. This is different from `inputColor`, which is the color at the *current* pixel's UV.

### Passing Animated Uniforms

If you want to animate uniform values from React (e.g., lerping bloom intensity), use a ref to the effect:

```tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { ScanlineEffect } from './ScanlineEffect'

function AnimatedScanlines() {
  const effectRef = useRef<ScanlineEffect>(null)

  useFrame(() => {
    if (!effectRef.current) return
    // Pulse the scanline intensity
    const t = performance.now() * 0.001
    effectRef.current.uniforms.get('intensity')!.value =
      0.2 + Math.sin(t * 2) * 0.1
  })

  const effect = useMemo(() => new ScanlineEffect(), [])

  return <primitive ref={effectRef} object={effect} />
}
```

---

## 7. Effect Stacking and Order

### Order Matters

Effects in the `<EffectComposer>` are applied in the order you list them. Each effect reads the output of the previous effect. This means the visual result changes depending on order.

Consider these two orderings:

```tsx
{/* Order A: Bloom THEN ChromaticAberration */}
<EffectComposer>
  <Bloom intensity={1} />
  <ChromaticAberration offset={new Vector2(0.005, 0.005)} />
</EffectComposer>

{/* Order B: ChromaticAberration THEN Bloom */}
<EffectComposer>
  <ChromaticAberration offset={new Vector2(0.005, 0.005)} />
  <Bloom intensity={1} />
</EffectComposer>
```

**Order A:** The bloom glow gets chromatic aberration applied to it — the glow itself splits into RGB fringes. Looks techy and aggressive.

**Order B:** The chromatic aberration color fringes feed into bloom — the split colors themselves glow. Looks softer and more diffused.

Neither is "correct." It depends on the look you want. But you need to be aware that order is a creative choice, not arbitrary.

### General Ordering Guidelines

A sensible default order for most game looks:

1. **Scene modifications** (fog, depth of field) — these change the scene's spatial qualities
2. **Bloom** — extracts and blurs bright areas
3. **Color grading** (brightness/contrast, hue/saturation, LUT) — adjusts the overall palette
4. **Noise/grain** — adds texture to the final image
5. **Vignette** — darkens edges last so it's on top of everything
6. **Screen-space distortion** (chromatic aberration, CRT warp) — applied at the very end

```tsx
<EffectComposer>
  <DepthOfField focusDistance={0} focalLength={0.02} bokehScale={2} />
  <Bloom intensity={0.8} luminanceThreshold={0.85} mipmapBlur />
  <BrightnessContrast brightness={-0.05} contrast={0.1} />
  <HueSaturation saturation={-0.1} />
  <Noise opacity={0.15} blendFunction={BlendFunction.SOFT_LIGHT} />
  <Vignette darkness={0.4} offset={0.3} />
</EffectComposer>
```

### Effect Merging

The `postprocessing` library automatically merges compatible effects into single shader passes. Simple per-pixel effects (brightness, contrast, hue, saturation, vignette) can all be merged into one draw call. Complex effects (bloom, DoF, god rays) always need their own passes.

You don't need to do anything special to benefit from merging — it happens automatically. But it explains why adding a sixth simple color effect might not cost any extra GPU time, while adding a second blur effect absolutely will.

### Performance Profiling

Use the browser's built-in GPU profiling (Chrome DevTools > Performance, check "GPU" category) or the `<Stats>` component from drei:

```tsx
import { Stats } from '@react-three/drei'

<Canvas>
  <Stats />
  {/* ... */}
</Canvas>
```

Watch the frame time (ms per frame). Add effects one at a time and check the impact:
- < 16.6ms = 60fps (good)
- 16.6-33.3ms = 30-60fps (acceptable for some games)
- > 33.3ms = < 30fps (unacceptable — cut effects)

### Quality Settings Pattern

Build a quality settings system so players can choose their own performance/quality trade-off:

```tsx
type QualityLevel = 'low' | 'medium' | 'high'

function PostProcessing({ quality }: { quality: QualityLevel }) {
  return (
    <EffectComposer multisampling={quality === 'low' ? 0 : quality === 'medium' ? 4 : 8}>
      <Bloom
        intensity={0.8}
        luminanceThreshold={0.85}
        mipmapBlur
      />
      {quality !== 'low' && (
        <DepthOfField focusDistance={0} focalLength={0.02} bokehScale={2} />
      )}
      {quality === 'high' && (
        <ChromaticAberration offset={new Vector2(0.002, 0.002)} />
      )}
      <Vignette darkness={0.4} />
    </EffectComposer>
  )
}
```

Low quality gets just bloom and vignette (merged into one extra draw call). Medium adds depth of field (one more pass). High adds chromatic aberration (potentially merged with vignette). Scale your effect stack to your audience's hardware.

---

## 8. Particle Systems

### Why Particles Matter

Particles are the workhorse of game VFX. Fire, smoke, sparks, dust, rain, snow, explosions, magic spells, healing auras, hit impacts — all particles. A game without particles feels dead. A game with good particles feels alive.

### Three Approaches, Ranked

**Approach 1: Individual Meshes (Bad)**

```tsx
// DON'T DO THIS
// Each particle is a separate mesh = separate draw call = GPU chokes
{particles.map((p, i) => (
  <mesh key={i} position={p.position}>
    <sphereGeometry args={[0.05, 8, 8]} />
    <meshBasicMaterial color="orange" />
  </mesh>
))}
```

100 particles = 100 draw calls. 1000 particles = 1000 draw calls. Your GPU can do a few hundred draw calls per frame before it starts sweating. This approach caps you at maybe 200 particles before fps drops. Useless for real VFX.

**Approach 2: InstancedMesh (Good)**

```tsx
// Better — one draw call for ALL particles
import { useRef, useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import { InstancedMesh, Object3D, Color } from 'three'

const MAX_PARTICLES = 1000
const tempObject = new Object3D()
const tempColor = new Color()

function ParticleSystem() {
  const meshRef = useRef<InstancedMesh>(null)
  const particles = useMemo(() =>
    Array.from({ length: MAX_PARTICLES }, () => ({
      position: [Math.random() * 10 - 5, Math.random() * 10, Math.random() * 10 - 5],
      velocity: [0, -Math.random() * 2 - 0.5, 0],
      lifetime: Math.random() * 3,
      maxLifetime: Math.random() * 3 + 1,
      color: new Color().setHSL(Math.random() * 0.1 + 0.05, 1, 0.5),
    }))
  , [])

  useFrame((_, delta) => {
    if (!meshRef.current) return

    particles.forEach((p, i) => {
      // Update lifetime
      p.lifetime += delta
      if (p.lifetime > p.maxLifetime) {
        // Respawn
        p.lifetime = 0
        p.position = [Math.random() * 10 - 5, 0, Math.random() * 10 - 5]
        p.velocity = [0, Math.random() * 2 + 1, 0]
      }

      // Update position
      p.position[0] += p.velocity[0] * delta
      p.position[1] += p.velocity[1] * delta
      p.position[2] += p.velocity[2] * delta

      // Update instance matrix
      tempObject.position.set(p.position[0], p.position[1], p.position[2])
      const lifeFraction = p.lifetime / p.maxLifetime
      const scale = 1 - lifeFraction  // Shrink as they age
      tempObject.scale.setScalar(scale * 0.1)
      tempObject.updateMatrix()
      meshRef.current!.setMatrixAt(i, tempObject.matrix)

      // Update instance color
      meshRef.current!.setColorAt(i, p.color)
    })

    meshRef.current.instanceMatrix.needsUpdate = true
    if (meshRef.current.instanceColor) {
      meshRef.current.instanceColor.needsUpdate = true
    }
  })

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, MAX_PARTICLES]}>
      <sphereGeometry args={[1, 8, 8]} />
      <meshBasicMaterial />
    </instancedMesh>
  )
}
```

One draw call for all 1000 particles. The geometry and material are shared. Only the per-instance transform matrices differ. You can push this to ~5000-10000 particles before CPU-side matrix updates become the bottleneck.

**Approach 3: Shader-Driven Points (Best)**

The fastest approach. We'll cover this in the next section.

### The Particle Lifecycle

Every particle system follows the same lifecycle pattern:

1. **Spawn** — Create a particle with initial position, velocity, color, size, lifetime
2. **Update** — Each frame, advance position by velocity, apply forces (gravity, wind), decrement lifetime
3. **Die** — When lifetime reaches zero, the particle is "dead"
4. **Recycle** — Don't destroy dead particles — reset their properties and reuse them

The recycle step is critical. If you create new particles and destroy old ones, you're allocating and deallocating memory every frame. The garbage collector will eventually freeze your game for a frame or two. Instead, pre-allocate a fixed pool of particles and recycle them.

```tsx
// The particle pool pattern
interface Particle {
  position: [number, number, number]
  velocity: [number, number, number]
  life: number        // Current remaining lifetime
  maxLife: number     // Total lifetime (for computing age fraction)
  active: boolean     // Whether this particle is currently visible
}

function spawnParticle(pool: Particle[], origin: [number, number, number]) {
  // Find the first inactive particle and reuse it
  const particle = pool.find(p => !p.active)
  if (!particle) return  // Pool exhausted — no particle spawned

  particle.position = [...origin]
  particle.velocity = [
    (Math.random() - 0.5) * 2,
    Math.random() * 3 + 1,
    (Math.random() - 0.5) * 2,
  ]
  particle.life = 2.0
  particle.maxLife = 2.0
  particle.active = true
}
```

### Building a Basic Particle Emitter

Here's a complete, reusable particle emitter using InstancedMesh:

```tsx
// ParticleEmitter.tsx
import { useRef, useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import { InstancedMesh, Object3D, Color, Vector3 } from 'three'

interface ParticleEmitterProps {
  count?: number
  origin?: [number, number, number]
  spread?: number
  speed?: number
  lifetime?: number
  gravity?: number
  color?: string
  size?: number
}

interface Particle {
  pos: Vector3
  vel: Vector3
  life: number
  maxLife: number
}

const tempObject = new Object3D()

export function ParticleEmitter({
  count = 500,
  origin = [0, 0, 0],
  spread = 1,
  speed = 3,
  lifetime = 2,
  gravity = -2,
  color = '#ff6600',
  size = 0.05,
}: ParticleEmitterProps) {
  const meshRef = useRef<InstancedMesh>(null)

  const particles = useMemo<Particle[]>(() =>
    Array.from({ length: count }, () => ({
      pos: new Vector3(),
      vel: new Vector3(),
      life: 0,
      maxLife: 0,
    }))
  , [count])

  // Stagger initial spawn times so particles don't all appear at once
  useMemo(() => {
    particles.forEach((p) => {
      resetParticle(p, origin, spread, speed, lifetime)
      p.life = Math.random() * p.maxLife  // Randomize starting age
    })
  }, [])

  useFrame((_, delta) => {
    if (!meshRef.current) return

    particles.forEach((p, i) => {
      p.life -= delta

      if (p.life <= 0) {
        resetParticle(p, origin, spread, speed, lifetime)
      }

      // Apply gravity
      p.vel.y += gravity * delta

      // Update position
      p.pos.addScaledVector(p.vel, delta)

      // Calculate fade based on remaining life
      const lifeFraction = Math.max(p.life / p.maxLife, 0)

      // Update instance transform
      tempObject.position.copy(p.pos)
      tempObject.scale.setScalar(size * lifeFraction)
      tempObject.updateMatrix()
      meshRef.current!.setMatrixAt(i, tempObject.matrix)
    })

    meshRef.current.instanceMatrix.needsUpdate = true
  })

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, count]}>
      <sphereGeometry args={[1, 6, 6]} />
      <meshBasicMaterial color={color} toneMapped={false} />
    </instancedMesh>
  )
}

function resetParticle(
  p: Particle,
  origin: [number, number, number],
  spread: number,
  speed: number,
  lifetime: number
) {
  p.pos.set(
    origin[0] + (Math.random() - 0.5) * spread * 0.2,
    origin[1],
    origin[2] + (Math.random() - 0.5) * spread * 0.2,
  )
  p.vel.set(
    (Math.random() - 0.5) * spread,
    Math.random() * speed,
    (Math.random() - 0.5) * spread,
  )
  p.life = lifetime * (0.5 + Math.random() * 0.5)
  p.maxLife = p.life
}
```

Use it anywhere:

```tsx
<ParticleEmitter
  origin={[0, 0, 0]}
  count={300}
  speed={4}
  gravity={-3}
  color="#ff4400"
  lifetime={1.5}
/>
```

---

## 9. Shader-Driven Particles

### Why Shader Particles Are Faster

With InstancedMesh particles, the CPU calculates every particle's position, builds a matrix, and uploads it to the GPU every frame. At 10,000 particles, that's 10,000 matrix multiplications and a large buffer upload — the CPU becomes the bottleneck.

Shader-driven particles move the computation to the GPU. You store each particle's attributes (position, velocity, lifetime) in buffer attributes, and the vertex shader does the movement calculations. The CPU just increments a time uniform. This pushes the particle limit from ~10,000 to 100,000+ on decent hardware.

### Points Geometry Setup

Three.js's `Points` object renders each vertex as a screen-facing square (a "point sprite"). Combined with a custom `ShaderMaterial`, you get fully GPU-driven particles.

```tsx
// ShaderParticles.tsx
import { useRef, useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import { Points, ShaderMaterial, BufferAttribute, Color } from 'three'

const PARTICLE_COUNT = 10000

const vertexShader = /* glsl */ `
  attribute float aLifetime;
  attribute float aMaxLifetime;
  attribute vec3 aVelocity;
  attribute vec3 aStartPosition;

  uniform float uTime;
  uniform float uSize;

  varying float vLifeFraction;
  varying vec3 vColor;

  void main() {
    // Calculate how far through its life this particle is
    // Use mod to loop the particle's life
    float age = mod(uTime + aLifetime, aMaxLifetime);
    float lifeFraction = age / aMaxLifetime;
    vLifeFraction = lifeFraction;

    // Calculate position: start position + velocity * age + gravity
    vec3 pos = aStartPosition
             + aVelocity * age
             + vec3(0.0, -2.0 * age * age, 0.0);  // Gravity

    // Fade and shrink near end of life
    float sizeFade = 1.0 - lifeFraction;

    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
    gl_PointSize = uSize * sizeFade * (300.0 / -mvPosition.z);
    gl_Position = projectionMatrix * mvPosition;

    // Color gradient from hot to cool
    vColor = mix(vec3(1.0, 0.8, 0.2), vec3(1.0, 0.1, 0.0), lifeFraction);
  }
`

const fragmentShader = /* glsl */ `
  varying float vLifeFraction;
  varying vec3 vColor;

  void main() {
    // Soft circle shape
    float dist = length(gl_PointCoord - vec2(0.5));
    if (dist > 0.5) discard;

    // Soft edge
    float alpha = 1.0 - smoothstep(0.3, 0.5, dist);

    // Fade out near end of life
    alpha *= 1.0 - vLifeFraction;

    gl_FragColor = vec4(vColor, alpha);
  }
`

export function ShaderParticles({ origin = [0, 0, 0] }: { origin?: [number, number, number] }) {
  const pointsRef = useRef<Points>(null)
  const materialRef = useRef<ShaderMaterial>(null)

  const { positions, velocities, lifetimes, maxLifetimes } = useMemo(() => {
    const positions = new Float32Array(PARTICLE_COUNT * 3)
    const velocities = new Float32Array(PARTICLE_COUNT * 3)
    const lifetimes = new Float32Array(PARTICLE_COUNT)
    const maxLifetimes = new Float32Array(PARTICLE_COUNT)

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      const i3 = i * 3

      // Start positions — clustered at origin with slight randomness
      positions[i3]     = origin[0] + (Math.random() - 0.5) * 0.2
      positions[i3 + 1] = origin[1]
      positions[i3 + 2] = origin[2] + (Math.random() - 0.5) * 0.2

      // Random velocities — upward with spread
      velocities[i3]     = (Math.random() - 0.5) * 3
      velocities[i3 + 1] = Math.random() * 4 + 2
      velocities[i3 + 2] = (Math.random() - 0.5) * 3

      // Staggered lifetimes so particles are spread across the cycle
      lifetimes[i] = Math.random() * 3
      maxLifetimes[i] = 2.0 + Math.random() * 1.5
    }

    return { positions, velocities, lifetimes, maxLifetimes }
  }, [])

  useFrame((state) => {
    if (!materialRef.current) return
    materialRef.current.uniforms.uTime.value = state.clock.elapsedTime
  })

  return (
    <points ref={pointsRef}>
      <bufferGeometry>
        <bufferAttribute
          attach="attributes-position"
          args={[positions, 3]}
        />
        <bufferAttribute
          attach="attributes-aVelocity"
          args={[velocities, 3]}
        />
        <bufferAttribute
          attach="attributes-aLifetime"
          args={[lifetimes, 1]}
        />
        <bufferAttribute
          attach="attributes-aMaxLifetime"
          args={[maxLifetimes, 1]}
        />
      </bufferGeometry>
      <shaderMaterial
        ref={materialRef}
        vertexShader={vertexShader}
        fragmentShader={fragmentShader}
        uniforms={{
          uTime: { value: 0 },
          uSize: { value: 4 },
        }}
        transparent
        depthWrite={false}
        blending={2}  // AdditiveBlending
      />
    </points>
  )
}
```

The CPU work per frame: setting a single uniform (`uTime`). The GPU does all the per-particle math in parallel. 10,000 particles at near-zero CPU cost.

### Texture-Based Particles

By default, point sprites are squares. To render them as circles, smoke puffs, sparks, or any custom shape, you sample a texture in the fragment shader.

```glsl
uniform sampler2D uParticleTexture;

void main() {
  vec4 texColor = texture2D(uParticleTexture, gl_PointCoord);

  // gl_PointCoord gives you UV coordinates within the point sprite
  // (0,0) is top-left, (1,1) is bottom-right

  // Use the texture alpha to shape the particle
  if (texColor.a < 0.01) discard;

  gl_FragColor = vec4(vColor * texColor.rgb, texColor.a * vAlpha);
}
```

Common particle textures:
- **Soft circle** — a white circle with gaussian falloff to transparent. Universal.
- **Smoke** — wispy, irregular shape on transparent background. Rotate randomly.
- **Spark** — elongated bright streak. Align with velocity direction.
- **Star/cross** — four-pointed star shape. Good for magic effects.

You can create these in any image editor. Save as PNG with transparency. Keep them small (64x64 or 128x128) — they're rendered at point size, not texture resolution.

### Important: `depthWrite={false}`

When rendering transparent particles, always set `depthWrite={false}` on the material. If particles write to the depth buffer, particles behind other particles become invisible (they fail the depth test). With depth write disabled, particles blend properly with each other.

Also consider using additive blending (`blending={2}` or `blending={THREE.AdditiveBlending}`). Additive blending makes overlapping particles appear brighter — perfect for fire, sparks, and glowing effects. For smoke or dust, use normal alpha blending (`blending={THREE.NormalBlending}`).

---

## 10. Trails and Ribbons

### drei's Trail Component

`@react-three/drei` includes a `<Trail>` component that creates a ribbon trailing behind a moving object. Dead simple to use:

```tsx
import { Trail } from '@react-three/drei'
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Mesh } from 'three'

function MovingOrb() {
  const meshRef = useRef<Mesh>(null)

  useFrame((state) => {
    if (!meshRef.current) return
    const t = state.clock.elapsedTime
    meshRef.current.position.x = Math.sin(t) * 3
    meshRef.current.position.y = Math.cos(t * 1.3) * 2
    meshRef.current.position.z = Math.sin(t * 0.7) * 3
  })

  return (
    <Trail
      width={1.5}                            // Trail width
      length={8}                             // Number of trail segments
      color="#ff00ff"                         // Trail color
      attenuation={(t) => t * t}             // Width falloff: t=1 at head, t=0 at tail
    >
      <mesh ref={meshRef}>
        <sphereGeometry args={[0.2, 16, 16]} />
        <meshStandardMaterial
          color="#ff00ff"
          emissive="#ff00ff"
          emissiveIntensity={3}
          toneMapped={false}
        />
      </mesh>
    </Trail>
  )
}
```

Key `<Trail>` props:

| Prop | Type | Description |
|------|------|-------------|
| `width` | `number` | Maximum width of the trail |
| `length` | `number` | Number of segments (more = smoother but more geometry) |
| `color` | `string \| Color` | Trail color |
| `attenuation` | `(t: number) => number` | Width at each point. `t` goes from 1 (head) to 0 (tail) |
| `decay` | `number` | How fast the trail fades (default 1) |

### Custom Trail Geometry

For more control, build your own trail by storing a history of positions and constructing a ribbon mesh:

```tsx
// CustomTrail.tsx
import { useRef, useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import { BufferGeometry, Float32BufferAttribute, Mesh, Vector3 } from 'three'

const TRAIL_LENGTH = 50

export function CustomTrail({ target }: { target: React.RefObject<Mesh> }) {
  const meshRef = useRef<Mesh>(null)
  const positions = useMemo(
    () => Array.from({ length: TRAIL_LENGTH }, () => new Vector3()),
    []
  )
  const headIndex = useRef(0)

  useFrame((state) => {
    if (!target.current || !meshRef.current) return

    // Store current position in the ring buffer
    positions[headIndex.current].copy(target.current.position)
    headIndex.current = (headIndex.current + 1) % TRAIL_LENGTH

    // Build ribbon geometry from position history
    const geometry = meshRef.current.geometry as BufferGeometry
    const verts: number[] = []
    const up = new Vector3(0, 1, 0)

    for (let i = 0; i < TRAIL_LENGTH - 1; i++) {
      const idx = (headIndex.current + i) % TRAIL_LENGTH
      const nextIdx = (idx + 1) % TRAIL_LENGTH
      const current = positions[idx]
      const next = positions[nextIdx]

      // Direction along the trail
      const dir = new Vector3().subVectors(next, current).normalize()

      // Perpendicular vector (trail width direction)
      const perp = new Vector3().crossVectors(dir, up).normalize()

      // Width tapers toward the tail
      const t = i / TRAIL_LENGTH
      const width = t * 0.3

      // Two vertices per trail point (left and right edge)
      verts.push(
        current.x + perp.x * width, current.y + perp.y * width, current.z + perp.z * width,
        current.x - perp.x * width, current.y - perp.y * width, current.z - perp.z * width,
      )
    }

    geometry.setAttribute('position', new Float32BufferAttribute(verts, 3))
    geometry.computeVertexNormals()
  })

  return (
    <mesh ref={meshRef}>
      <bufferGeometry />
      <meshBasicMaterial color="#00ffff" side={2} transparent opacity={0.6} />
    </mesh>
  )
}
```

The ring buffer pattern (`headIndex` wrapping around) avoids array shifting. New positions overwrite the oldest ones, and the rendering loop reads them in order from oldest to newest.

### Use Cases

- **Projectile trails** — A bullet or arrow leaves a fading streak behind it
- **Movement traces** — Show the path a character has taken (strategy games)
- **Magic effects** — Wand tips, spell trajectories, enchantment circles
- **Racing games** — Tire marks, speed lines, drift smoke trails
- **UI feedback** — Mouse cursor trails, selection lasso paths

### Trail + Bloom = Magic

Trails look dramatically better with bloom. Make the trail material emissive and ensure bloom is active:

```tsx
<Trail width={1} length={10} color="#ff00ff" attenuation={(t) => t * t}>
  <mesh ref={orbRef}>
    <sphereGeometry args={[0.1, 16, 16]} />
    <meshBasicMaterial color="#ff00ff" toneMapped={false} />
  </mesh>
</Trail>

<EffectComposer>
  <Bloom intensity={1.5} luminanceThreshold={0.5} mipmapBlur />
</EffectComposer>
```

The trail itself will bloom because drei's Trail uses `MeshBasicMaterial` internally, which can be bright enough to trigger the bloom threshold. For even stronger glow, set the trail color to a very bright value.

---

## 11. God Rays and Volumetric Effects

### God Rays

God rays (also called crepuscular rays) simulate beams of light streaming through gaps in clouds or windows. The `postprocessing` library provides a `GodRays` effect that works by ray-marching from a light source.

```tsx
import { GodRays } from '@react-three/postprocessing'
import { useRef } from 'react'
import type { Mesh } from 'three'

function SunWithGodRays() {
  const sunRef = useRef<Mesh>(null)

  return (
    <>
      {/* The sun mesh — GodRays needs a reference to the light source mesh */}
      <mesh ref={sunRef} position={[0, 10, -20]}>
        <sphereGeometry args={[2, 32, 32]} />
        <meshBasicMaterial color="#ffddaa" />
      </mesh>

      <EffectComposer>
        {sunRef.current && (
          <GodRays
            sun={sunRef.current}       // Reference to the light source mesh
            samples={60}               // Ray samples — more = smoother but slower
            density={0.97}             // Ray density
            decay={0.96}               // How fast rays fade with distance
            weight={0.6}               // Ray intensity
            exposure={0.6}             // Overall brightness
            clampMax={1}               // Maximum brightness cap
            blur                       // Apply blur to smooth the rays
          />
        )}
        <Bloom intensity={0.3} luminanceThreshold={0.8} mipmapBlur />
      </EffectComposer>
    </>
  )
}
```

The `sun` prop takes a reference to a mesh — not a light. The effect treats this mesh as the source of the rays. Typically you use a bright sphere or disc positioned where your sun/light source is.

**Important:** The `sun` ref needs to be populated before `GodRays` renders. The conditional `{sunRef.current && ...}` pattern handles this, though in practice you might need a state trigger or a two-pass approach to ensure the ref is ready.

A cleaner pattern:

```tsx
function Scene() {
  const [sunMesh, setSunMesh] = useState<Mesh | null>(null)

  return (
    <>
      <mesh ref={setSunMesh} position={[0, 10, -20]}>
        <sphereGeometry args={[2, 32, 32]} />
        <meshBasicMaterial color="#ffddaa" />
      </mesh>

      <EffectComposer>
        {sunMesh && (
          <GodRays
            sun={sunMesh}
            samples={60}
            density={0.97}
            decay={0.96}
            weight={0.6}
            exposure={0.6}
            blur
          />
        )}
      </EffectComposer>
    </>
  )
}
```

Using `ref={setSunMesh}` with a state setter ensures a re-render when the ref is ready, which mounts the `GodRays` effect with a valid mesh reference.

### God Rays Performance

God rays are one of the most expensive post-processing effects. The `samples` parameter directly controls cost — 60 samples means 60 texture lookups per pixel. Tips:

- Start with `samples={30}` and increase only if quality is insufficient
- The `blur` flag adds a slight blur to hide low sample counts — almost always worth enabling
- `density` and `decay` interact: lower density + higher decay = shorter, less visible rays = cheaper
- Consider disabling god rays on low-quality settings

### Fog

Three.js has built-in fog support, applied at the scene level rather than as a post-processing effect. It fades objects toward a color based on distance from the camera.

```tsx
import { useThree } from '@react-three/fiber'
import { useEffect } from 'react'
import { Fog, FogExp2 } from 'three'

function LinearFog() {
  const { scene } = useThree()

  useEffect(() => {
    scene.fog = new Fog('#000000', 10, 50)
    // args: color, near distance, far distance
    // Objects closer than 10 units are fully visible
    // Objects beyond 50 units are fully fogged (invisible)
    return () => { scene.fog = null }
  }, [scene])

  return null
}

function ExponentialFog() {
  const { scene } = useThree()

  useEffect(() => {
    scene.fog = new FogExp2('#1a0a2e', 0.035)
    // args: color, density
    // Exponential falloff — never fully fogs, but gets very thick
    return () => { scene.fog = null }
  }, [scene])

  return null
}
```

**Linear fog** (`Fog`) has a hard near and far boundary. Objects between near and far gradually fade. Objects past far are fully hidden. Good for hiding the far clipping plane.

**Exponential fog** (`FogExp2`) uses an exponential curve. It's denser close to the camera and never fully obscures distant objects. More natural-looking. Better for atmospheric effects.

Alternatively, you can set fog directly on the Canvas:

```tsx
<Canvas>
  <fog attach="fog" args={['#000000', 10, 50]} />
  {/* ... */}
</Canvas>
```

### Fog + Post-Processing

Fog and post-processing work together naturally. Fog handles depth-based atmosphere in the 3D pipeline. Post-processing handles screen-space effects. A horror scene might combine:

- Exponential fog for distance haze
- Vignette for edge darkening
- Desaturation for bleakness
- Film grain for unease

```tsx
<Canvas>
  <fog attach="fog" args={['#0a0a0a', 5, 30]} />
  {/* ... scene content ... */}
  <EffectComposer>
    <HueSaturation saturation={-0.6} />
    <BrightnessContrast brightness={-0.15} contrast={0.1} />
    <Noise opacity={0.3} blendFunction={BlendFunction.OVERLAY} />
    <Vignette darkness={0.7} offset={0.2} />
  </EffectComposer>
</Canvas>
```

### Volumetric Lighting Concepts

True volumetric lighting (light scattering through a volume of air/fog) is expensive. The god rays effect is a 2D screen-space approximation. For real volumetric effects, you'd need:

- **Ray marching through a 3D volume** — stepping through space from the camera, accumulating light and density at each step
- **3D noise textures** — to make the fog non-uniform (patchy, cloud-like)
- **Shadow-aware scattering** — checking if each sample point is in shadow

This is advanced GPU programming and typically too expensive for real-time on the web. For R3F games, the combination of Three.js fog + god rays post-processing + bloom covers 90% of volumetric lighting needs.

---

## 12. VFX Composition

### The Juice Cascade

A single game event — an explosion, a power-up, a critical hit — should trigger multiple simultaneous VFX systems. This is what separates games that feel flat from games that feel incredible. Call it the "juice cascade."

Take an explosion:

| System | Effect | Duration |
|--------|--------|----------|
| Particles | Burst of orange/yellow sparks flying outward | 0.5-1.5s |
| Particles | Smoke cloud expanding and fading | 1-3s |
| Particles | Debris chunks arcing with gravity | 0.5-2s |
| Post-processing | Brief screen flash (white/orange) | 0.1s |
| Post-processing | Bloom spike (temporarily increase intensity) | 0.3s |
| Post-processing | Chromatic aberration pulse | 0.2s |
| Camera | Camera shake (random offset + rotation) | 0.3s |
| Audio | Explosion sound effect | 1s |
| Lighting | Flash point light at explosion position | 0.2s |

Nine systems, all triggered by one event. Each one is simple on its own. Together, they create an explosion that *feels* real.

### Implementing a Juice Cascade

The cleanest pattern is an event system. When an explosion happens, emit an event. Multiple systems listen and respond independently.

```tsx
// Simple event system using zustand
import { create } from 'zustand'

interface VFXEvent {
  type: 'explosion' | 'hit' | 'powerup'
  position: [number, number, number]
  timestamp: number
}

interface VFXStore {
  events: VFXEvent[]
  emit: (type: VFXEvent['type'], position: [number, number, number]) => void
  consume: (timestamp: number) => void
}

export const useVFXStore = create<VFXStore>((set) => ({
  events: [],
  emit: (type, position) =>
    set((state) => ({
      events: [...state.events, { type, position, timestamp: Date.now() }],
    })),
  consume: (timestamp) =>
    set((state) => ({
      events: state.events.filter((e) => e.timestamp !== timestamp),
    })),
}))
```

### Screen Flash Effect

A brief white/colored overlay that fades out. Implement as a custom post-processing effect:

```tsx
import { Effect } from 'postprocessing'
import { Uniform } from 'three'

const screenFlashShader = /* glsl */ `
  uniform float intensity;
  uniform vec3 flashColor;

  void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
    outputColor = vec4(mix(inputColor.rgb, flashColor, intensity), inputColor.a);
  }
`

export class ScreenFlashEffect extends Effect {
  constructor() {
    super('ScreenFlashEffect', screenFlashShader, {
      uniforms: new Map([
        ['intensity', new Uniform(0)],
        ['flashColor', new Uniform([1, 1, 1])],
      ]),
    })
  }

  flash(color: [number, number, number] = [1, 1, 1]) {
    this.uniforms.get('flashColor')!.value = color
    this.uniforms.get('intensity')!.value = 1.0
  }

  update(_renderer: any, _inputBuffer: any, deltaTime: number) {
    const intensity = this.uniforms.get('intensity')!
    if (intensity.value > 0) {
      intensity.value = Math.max(0, intensity.value - deltaTime * 5)
    }
  }
}
```

### Camera Shake

Camera shake sells impacts. The simplest approach: add random offsets to the camera position for a brief duration.

```tsx
import { useRef } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import { Vector3 } from 'three'

export function CameraShake() {
  const { camera } = useThree()
  const shakeRef = useRef({ intensity: 0, decay: 5 })
  const originalPos = useRef(new Vector3())

  // Call this to trigger a shake
  const shake = (intensity: number = 0.5) => {
    originalPos.current.copy(camera.position)
    shakeRef.current.intensity = intensity
  }

  useFrame((_, delta) => {
    const s = shakeRef.current
    if (s.intensity > 0.001) {
      camera.position.x = originalPos.current.x + (Math.random() - 0.5) * s.intensity
      camera.position.y = originalPos.current.y + (Math.random() - 0.5) * s.intensity
      camera.position.z = originalPos.current.z + (Math.random() - 0.5) * s.intensity * 0.5
      s.intensity *= Math.pow(0.1, delta)  // Exponential decay
    } else if (s.intensity > 0) {
      camera.position.copy(originalPos.current)
      s.intensity = 0
    }
  })

  return null
}
```

### Bloom Spike

Temporarily increase bloom intensity on impact. Use a ref to the bloom effect:

```tsx
function DynamicBloom() {
  const bloomRef = useRef<any>(null)
  const baseIntensity = 0.5
  const currentIntensity = useRef(baseIntensity)

  // Call this to spike bloom
  const spike = (amount: number = 2) => {
    currentIntensity.current = baseIntensity + amount
  }

  useFrame((_, delta) => {
    if (!bloomRef.current) return
    // Decay back to base intensity
    currentIntensity.current = Math.max(
      baseIntensity,
      currentIntensity.current - delta * 4,
    )
    bloomRef.current.intensity = currentIntensity.current
  })

  return <Bloom ref={bloomRef} intensity={baseIntensity} luminanceThreshold={0.8} mipmapBlur />
}
```

### Putting It All Together

The key insight: each VFX subsystem is independent and self-contained. The explosion emitter doesn't know about camera shake. The camera shake doesn't know about bloom spikes. They're all triggered by the same event but respond independently. This keeps the code modular and composable.

When you want a new VFX event type (say, "power-up"), you don't modify existing systems. You just define what each system does in response to a "powerup" event: blue particles instead of orange, positive bloom instead of aggressive, a chime sound instead of an explosion.

---

## Code Walkthrough: Mood Board Scene

Time to build the mini-project. One 3D scene, four completely different visual identities, switchable at the press of a key.

### Step 1: Project Setup

```bash
npm create vite@latest mood-board -- --template react-ts
cd mood-board
npm install three @react-three/fiber @react-three/drei @react-three/postprocessing postprocessing zustand
npm install -D @types/three
```

### Step 2: The Preset Store

```tsx
// src/stores/presetStore.ts
import { create } from 'zustand'

export type PresetName = 'cyberpunk' | 'pastoral' | 'horror' | 'retro'

const PRESET_ORDER: PresetName[] = ['cyberpunk', 'pastoral', 'horror', 'retro']

interface PresetStore {
  current: PresetName
  index: number
  next: () => void
  prev: () => void
  set: (preset: PresetName) => void
}

export const usePresetStore = create<PresetStore>((set) => ({
  current: 'cyberpunk',
  index: 0,
  next: () =>
    set((state) => {
      const nextIndex = (state.index + 1) % PRESET_ORDER.length
      return { current: PRESET_ORDER[nextIndex], index: nextIndex }
    }),
  prev: () =>
    set((state) => {
      const prevIndex = (state.index - 1 + PRESET_ORDER.length) % PRESET_ORDER.length
      return { current: PRESET_ORDER[prevIndex], index: prevIndex }
    }),
  set: (preset) =>
    set({ current: preset, index: PRESET_ORDER.indexOf(preset) }),
}))
```

### Step 3: Custom Effects

```tsx
// src/effects/ScanlineEffect.ts
import { Effect } from 'postprocessing'
import { Uniform } from 'three'

const scanlineShader = /* glsl */ `
  uniform float count;
  uniform float intensity;
  uniform float scroll;

  void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
    float scanline = sin((uv.y + scroll) * count * 3.14159) * 0.5 + 0.5;
    scanline = pow(scanline, 2.0);
    float darken = 1.0 - (1.0 - scanline) * intensity;
    outputColor = vec4(inputColor.rgb * darken, inputColor.a);
  }
`

export class ScanlineEffect extends Effect {
  constructor({ count = 800, intensity = 0.3 } = {}) {
    super('ScanlineEffect', scanlineShader, {
      uniforms: new Map([
        ['count', new Uniform(count)],
        ['intensity', new Uniform(intensity)],
        ['scroll', new Uniform(0)],
      ]),
    })
  }

  update(_renderer: any, _inputBuffer: any, deltaTime: number) {
    this.uniforms.get('scroll')!.value += deltaTime * 0.01
  }
}
```

```tsx
// src/effects/CRTEffect.ts
import { Effect } from 'postprocessing'
import { Uniform } from 'three'

const crtShader = /* glsl */ `
  uniform float warpX;
  uniform float warpY;

  void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
    vec2 centered = uv - 0.5;
    float r2 = dot(centered, centered);
    centered *= 1.0 + vec2(warpX, warpY) * r2;
    vec2 warped = centered + 0.5;

    if (warped.x < 0.0 || warped.x > 1.0 || warped.y < 0.0 || warped.y > 1.0) {
      outputColor = vec4(0.0, 0.0, 0.0, 1.0);
      return;
    }

    outputColor = texture2D(inputBuffer, warped);
  }
`

export class CRTEffect extends Effect {
  constructor({ warpX = 0.04, warpY = 0.05 } = {}) {
    super('CRTEffect', crtShader, {
      uniforms: new Map([
        ['warpX', new Uniform(warpX)],
        ['warpY', new Uniform(warpY)],
      ]),
    })
  }
}
```

```tsx
// src/effects/PixelationEffect.ts
import { Effect } from 'postprocessing'
import { Uniform } from 'three'

const pixelationShader = /* glsl */ `
  uniform float pixelSize;
  uniform vec2 resolution;

  void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
    vec2 pixelUV = floor(uv * resolution / pixelSize) * pixelSize / resolution;
    outputColor = texture2D(inputBuffer, pixelUV);

    // Optional: reduce color depth for extra retro feel
    outputColor.rgb = floor(outputColor.rgb * 8.0) / 8.0;
  }
`

export class PixelationEffect extends Effect {
  constructor({ pixelSize = 4.0 } = {}) {
    super('PixelationEffect', pixelationShader, {
      uniforms: new Map([
        ['pixelSize', new Uniform(pixelSize)],
        ['resolution', new Uniform([window.innerWidth, window.innerHeight])],
      ]),
    })
  }

  setSize(width: number, height: number) {
    this.uniforms.get('resolution')!.value = [width, height]
  }
}
```

### Step 4: The Base Scene

Build a simple 3D environment that works across all presets.

```tsx
// src/components/BaseScene.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { Float } from '@react-three/drei'
import type { Group, Mesh } from 'three'

export function BaseScene() {
  return (
    <group>
      {/* Ground plane */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -1, 0]} receiveShadow>
        <planeGeometry args={[40, 40]} />
        <meshStandardMaterial color="#333333" roughness={0.8} />
      </mesh>

      {/* Central pillar */}
      <mesh position={[0, 1.5, 0]} castShadow>
        <cylinderGeometry args={[0.4, 0.5, 5, 16]} />
        <meshStandardMaterial color="#555555" roughness={0.4} metalness={0.6} />
      </mesh>

      {/* Floating orb at the top */}
      <Float speed={2} floatIntensity={0.5} rotationIntensity={0.3}>
        <mesh position={[0, 5, 0]} castShadow>
          <sphereGeometry args={[0.6, 32, 32]} />
          <meshStandardMaterial
            color="#ffffff"
            emissive="#ffffff"
            emissiveIntensity={2}
            toneMapped={false}
          />
        </mesh>
      </Float>

      {/* Surrounding cubes */}
      <RotatingCubes />

      {/* Neon rings — visible in all presets but especially impactful in cyberpunk */}
      <NeonRing radius={3} height={0.5} color="#00ffff" />
      <NeonRing radius={4.5} height={1.5} color="#ff00ff" />
      <NeonRing radius={6} height={0.8} color="#ffff00" />

      {/* Background pillars for depth */}
      {Array.from({ length: 8 }).map((_, i) => {
        const angle = (i / 8) * Math.PI * 2
        const x = Math.cos(angle) * 12
        const z = Math.sin(angle) * 12
        return (
          <mesh key={i} position={[x, 2, z]} castShadow>
            <boxGeometry args={[1, 6, 1]} />
            <meshStandardMaterial color="#444444" roughness={0.6} metalness={0.3} />
          </mesh>
        )
      })}
    </group>
  )
}

function RotatingCubes() {
  const groupRef = useRef<Group>(null)

  useFrame((_, delta) => {
    if (!groupRef.current) return
    groupRef.current.rotation.y += delta * 0.15
  })

  return (
    <group ref={groupRef}>
      {Array.from({ length: 6 }).map((_, i) => {
        const angle = (i / 6) * Math.PI * 2
        const x = Math.cos(angle) * 5
        const z = Math.sin(angle) * 5
        return (
          <mesh key={i} position={[x, 0.5, z]} castShadow>
            <boxGeometry args={[0.8, 0.8, 0.8]} />
            <meshStandardMaterial
              color={`hsl(${(i / 6) * 360}, 70%, 50%)`}
              roughness={0.3}
              metalness={0.5}
            />
          </mesh>
        )
      })}
    </group>
  )
}

function NeonRing({ radius, height, color }: { radius: number; height: number; color: string }) {
  const meshRef = useRef<Mesh>(null)

  useFrame((state) => {
    if (!meshRef.current) return
    meshRef.current.rotation.x = Math.sin(state.clock.elapsedTime * 0.5) * 0.2
    meshRef.current.rotation.z = Math.cos(state.clock.elapsedTime * 0.3) * 0.15
  })

  return (
    <mesh ref={meshRef} position={[0, height, 0]}>
      <torusGeometry args={[radius, 0.03, 16, 64]} />
      <meshStandardMaterial
        color={color}
        emissive={color}
        emissiveIntensity={3}
        toneMapped={false}
      />
    </mesh>
  )
}
```

### Step 5: Preset Post-Processing Stacks

```tsx
// src/components/PostProcessingPresets.tsx
import { useMemo, useRef, useEffect } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import {
  EffectComposer,
  Bloom,
  Vignette,
  ChromaticAberration,
  Noise,
  DepthOfField,
  BrightnessContrast,
  HueSaturation,
  GodRays,
} from '@react-three/postprocessing'
import { BlendFunction } from 'postprocessing'
import { Vector2, Mesh, FogExp2 } from 'three'
import { usePresetStore, PresetName } from '../stores/presetStore'
import { ScanlineEffect } from '../effects/ScanlineEffect'
import { CRTEffect } from '../effects/CRTEffect'
import { PixelationEffect } from '../effects/PixelationEffect'

export function PostProcessingPresets() {
  const current = usePresetStore((s) => s.current)

  switch (current) {
    case 'cyberpunk':
      return <CyberpunkPreset />
    case 'pastoral':
      return <PastoralPreset />
    case 'horror':
      return <HorrorPreset />
    case 'retro':
      return <RetroPreset />
  }
}

function CyberpunkPreset() {
  const scanlines = useMemo(() => new ScanlineEffect({ count: 600, intensity: 0.15 }), [])

  return (
    <EffectComposer>
      <Bloom
        intensity={1.5}
        luminanceThreshold={0.6}
        luminanceSmoothing={0.05}
        mipmapBlur
        radius={0.8}
      />
      <ChromaticAberration
        offset={new Vector2(0.003, 0.003)}
        radialModulation
        modulationOffset={0.4}
      />
      <BrightnessContrast brightness={-0.05} contrast={0.2} />
      <HueSaturation hue={-0.1} saturation={0.2} />
      <primitive object={scanlines} />
      <Vignette darkness={0.4} offset={0.3} />
    </EffectComposer>
  )
}

function PastoralPreset() {
  const { scene } = useThree()

  useEffect(() => {
    scene.fog = new FogExp2('#e8d5b0', 0.015)
    return () => { scene.fog = null }
  }, [scene])

  return (
    <EffectComposer>
      <Bloom
        intensity={0.3}
        luminanceThreshold={0.85}
        luminanceSmoothing={0.1}
        mipmapBlur
      />
      <DepthOfField
        focusDistance={0.01}
        focalLength={0.03}
        bokehScale={3}
        height={480}
      />
      <BrightnessContrast brightness={0.08} contrast={-0.05} />
      <HueSaturation hue={0.05} saturation={-0.05} />
      <Vignette darkness={0.3} offset={0.5} />
    </EffectComposer>
  )
}

function HorrorPreset() {
  const { scene } = useThree()

  useEffect(() => {
    scene.fog = new FogExp2('#0a0a0a', 0.06)
    return () => { scene.fog = null }
  }, [scene])

  return (
    <EffectComposer>
      <HueSaturation saturation={-0.7} />
      <BrightnessContrast brightness={-0.2} contrast={0.15} />
      <Noise opacity={0.35} blendFunction={BlendFunction.OVERLAY} />
      <Bloom
        intensity={0.2}
        luminanceThreshold={0.95}
        mipmapBlur
      />
      <Vignette darkness={0.8} offset={0.15} />
    </EffectComposer>
  )
}

function RetroPreset() {
  const pixelation = useMemo(() => new PixelationEffect({ pixelSize: 4 }), [])
  const scanlines = useMemo(() => new ScanlineEffect({ count: 400, intensity: 0.2 }), [])
  const crt = useMemo(() => new CRTEffect({ warpX: 0.04, warpY: 0.05 }), [])

  return (
    <EffectComposer>
      <primitive object={pixelation} />
      <BrightnessContrast brightness={0.0} contrast={0.1} />
      <HueSaturation saturation={-0.3} />
      <Bloom
        intensity={0.4}
        luminanceThreshold={0.7}
        mipmapBlur
      />
      <primitive object={scanlines} />
      <Vignette darkness={0.5} offset={0.25} />
      <primitive object={crt} />
    </EffectComposer>
  )
}
```

### Step 6: Keyboard Controls and HUD

```tsx
// src/components/PresetHUD.tsx
import { useEffect } from 'react'
import { usePresetStore, PresetName } from '../stores/presetStore'

const PRESET_LABELS: Record<PresetName, string> = {
  cyberpunk: 'CYBERPUNK',
  pastoral: 'PASTORAL',
  horror: 'HORROR',
  retro: 'RETRO',
}

const PRESET_COLORS: Record<PresetName, string> = {
  cyberpunk: '#00ffff',
  pastoral: '#a8d08d',
  horror: '#cc0000',
  retro: '#ffcc00',
}

export function PresetHUD() {
  const current = usePresetStore((s) => s.current)
  const next = usePresetStore((s) => s.next)
  const prev = usePresetStore((s) => s.prev)

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight' || e.key === 'd') next()
      if (e.key === 'ArrowLeft' || e.key === 'a') prev()
      if (e.key === '1') usePresetStore.getState().set('cyberpunk')
      if (e.key === '2') usePresetStore.getState().set('pastoral')
      if (e.key === '3') usePresetStore.getState().set('horror')
      if (e.key === '4') usePresetStore.getState().set('retro')
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [next, prev])

  return (
    <div
      style={{
        position: 'absolute',
        bottom: '30px',
        left: '50%',
        transform: 'translateX(-50%)',
        display: 'flex',
        gap: '12px',
        alignItems: 'center',
        fontFamily: 'monospace',
        userSelect: 'none',
        zIndex: 10,
      }}
    >
      <button onClick={prev} style={buttonStyle}>&#9664;</button>

      <div
        style={{
          color: PRESET_COLORS[current],
          fontSize: '24px',
          fontWeight: 'bold',
          letterSpacing: '4px',
          textShadow: `0 0 10px ${PRESET_COLORS[current]}`,
          minWidth: '200px',
          textAlign: 'center',
        }}
      >
        {PRESET_LABELS[current]}
      </div>

      <button onClick={next} style={buttonStyle}>&#9654;</button>

      <div
        style={{
          position: 'absolute',
          bottom: '-24px',
          left: '50%',
          transform: 'translateX(-50%)',
          color: '#666',
          fontSize: '12px',
          whiteSpace: 'nowrap',
        }}
      >
        Arrow keys or 1-4 to switch
      </div>
    </div>
  )
}

const buttonStyle: React.CSSProperties = {
  background: 'rgba(255, 255, 255, 0.1)',
  border: '1px solid rgba(255, 255, 255, 0.3)',
  color: 'white',
  fontSize: '18px',
  padding: '8px 16px',
  cursor: 'pointer',
  borderRadius: '4px',
}
```

### Step 7: The App

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { OrbitControls, Stars } from '@react-three/drei'
import { BaseScene } from './components/BaseScene'
import { PostProcessingPresets } from './components/PostProcessingPresets'
import { PresetHUD } from './components/PresetHUD'

export default function App() {
  return (
    <>
      <Canvas
        camera={{ position: [8, 6, 12], fov: 50 }}
        gl={{ antialias: true }}
        shadows
      >
        <ambientLight intensity={0.15} />
        <directionalLight
          position={[10, 15, 10]}
          intensity={1}
          castShadow
          shadow-mapSize-width={2048}
          shadow-mapSize-height={2048}
        />
        <pointLight position={[0, 5, 0]} intensity={50} distance={20} decay={2} />

        <Stars radius={100} depth={50} count={3000} saturation={0} fade />
        <BaseScene />
        <PostProcessingPresets />

        <OrbitControls
          enableDamping
          dampingFactor={0.05}
          minDistance={5}
          maxDistance={30}
        />
      </Canvas>
      <PresetHUD />
    </>
  )
}
```

### Step 8: Global Styles

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

### Step 9: Smooth Transitions (Stretch Goal)

For smooth transitions between presets, you'd interpolate uniform values rather than swapping entire EffectComposer stacks. The approach:

```tsx
// src/hooks/useLerpedValue.ts
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { MathUtils } from 'three'

export function useLerpedValue(target: number, speed: number = 3): React.RefObject<number> {
  const current = useRef(target)
  const targetRef = useRef(target)
  targetRef.current = target

  useFrame((_, delta) => {
    current.current = MathUtils.lerp(current.current, targetRef.current, 1 - Math.exp(-speed * delta))
  })

  return current
}
```

Then instead of switching between completely different EffectComposer stacks, use a single stack where every parameter is a lerped value:

```tsx
function UnifiedPostProcessing() {
  const current = usePresetStore((s) => s.current)

  // Define target values per preset
  const bloomIntensity = useLerpedValue(
    current === 'cyberpunk' ? 1.5 : current === 'pastoral' ? 0.3 : current === 'horror' ? 0.2 : 0.4
  )
  const saturation = useLerpedValue(
    current === 'cyberpunk' ? 0.2 : current === 'pastoral' ? -0.05 : current === 'horror' ? -0.7 : -0.3
  )
  const vignetteDarkness = useLerpedValue(
    current === 'cyberpunk' ? 0.4 : current === 'pastoral' ? 0.3 : current === 'horror' ? 0.8 : 0.5
  )
  // ... more parameters

  // Apply lerped values to effects each frame via refs
  const bloomRef = useRef<any>(null)
  const hueSatRef = useRef<any>(null)
  const vignetteRef = useRef<any>(null)

  useFrame(() => {
    if (bloomRef.current) bloomRef.current.intensity = bloomIntensity.current
    if (hueSatRef.current) hueSatRef.current.saturation = saturation.current
    if (vignetteRef.current) vignetteRef.current.darkness = vignetteDarkness.current
  })

  return (
    <EffectComposer>
      <Bloom ref={bloomRef} luminanceThreshold={0.7} mipmapBlur />
      <HueSaturation ref={hueSatRef} />
      <Vignette ref={vignetteRef} offset={0.3} />
    </EffectComposer>
  )
}
```

This creates buttery-smooth transitions between presets — the scene morphs from cyberpunk to pastoral over a second or two, with every parameter sliding to its new value.

### Run It

```bash
npm run dev
```

You should see the scene with the cyberpunk preset active — high bloom on the neon rings, chromatic aberration fringes, scanlines scrolling subtly. Press the right arrow key or click the arrow button to cycle through pastoral (warm, soft, depth of field), horror (dark, grainy, heavy vignette, thick fog), and retro (pixelated, CRT-warped, scanlined).

---

## Common Pitfalls

### 1. Bloom Making Everything Glow

```tsx
// WRONG — luminanceThreshold too low, the entire scene blooms
<Bloom intensity={1.5} luminanceThreshold={0.1} mipmapBlur />
// Result: everything looks like it's underwater. No contrast.

// RIGHT — only bright emissive objects bloom
<Bloom intensity={1.5} luminanceThreshold={0.8} mipmapBlur />
// Also make sure your emissive materials actually exceed the threshold:
<meshStandardMaterial emissive="#ff00ff" emissiveIntensity={3} toneMapped={false} />
```

If you want *selective* glow on specific objects, don't lower the threshold. Instead, make those objects brighter using `emissiveIntensity` and `toneMapped={false}`.

### 2. Too Many Effects Tanking FPS

```tsx
// WRONG — kitchen sink approach, no performance budget
<EffectComposer>
  <Bloom intensity={1} mipmapBlur />
  <DepthOfField focusDistance={0} focalLength={0.02} bokehScale={3} />
  <GodRays sun={sunMesh} samples={100} />
  <ChromaticAberration offset={new Vector2(0.005, 0.005)} />
  <Noise opacity={0.3} />
  <Vignette darkness={0.5} />
  <BrightnessContrast brightness={0} contrast={0.1} />
  <HueSaturation saturation={0.1} />
</EffectComposer>
// Result: 20fps on a laptop. Unplayable.

// RIGHT — profile, prioritize, and offer quality settings
<EffectComposer multisampling={quality === 'low' ? 0 : 4}>
  <Bloom intensity={1} mipmapBlur />
  {quality !== 'low' && <DepthOfField focusDistance={0} focalLength={0.02} bokehScale={2} />}
  <Vignette darkness={0.5} />
</EffectComposer>
// Result: 60fps on most hardware. Still looks great.
```

Profile first. Add effects one at a time and check the frame time impact. Lightweight effects (vignette, brightness/contrast, hue/saturation) are nearly free because they merge. Heavy effects (bloom, DoF, god rays) cost a full pass each.

### 3. Depth of Field on Everything

```tsx
// WRONG — extremely shallow depth of field with nothing in focus
<DepthOfField
  focusDistance={0}
  focalLength={0.1}      // Way too aggressive
  bokehScale={10}         // Enormous bokeh
/>
// Result: everything is blurry. Players can't see what they're doing.

// RIGHT — subtle DoF that guides the eye without impairing gameplay
<DepthOfField
  focusDistance={0.01}    // Tune this to your target distance
  focalLength={0.02}     // Subtle blur
  bokehScale={2}         // Small bokeh circles
  height={480}
/>
// Result: foreground/background slightly soft, mid-ground sharp.
```

In games, DoF should be subtle. Reserve aggressive DoF for cinematic moments (cutscenes, menus, pausing the game to show an inventory). During gameplay, the player needs to see clearly.

### 4. Custom Effect Not Updating

```tsx
// WRONG — forgetting to update time uniform in the update method
export class MyAnimatedEffect extends Effect {
  constructor() {
    super('MyEffect', shader, {
      uniforms: new Map([['time', new Uniform(0)]]),
    })
  }
  // No update() method! Time stays at 0 forever.
}

// RIGHT — implement update() to advance time
export class MyAnimatedEffect extends Effect {
  constructor() {
    super('MyEffect', shader, {
      uniforms: new Map([['time', new Uniform(0)]]),
    })
  }

  update(_renderer: any, _inputBuffer: any, deltaTime: number) {
    this.uniforms.get('time')!.value += deltaTime
  }
}
```

The `update` method is called every frame before the effect renders. If your custom effect has any animated uniforms, you must update them here. Common bug: the effect renders fine on the first frame but never changes.

### 5. Particles Not Recycling

```tsx
// WRONG — creating new particles every frame, never cleaning up
const [particles, setParticles] = useState<Particle[]>([])

useFrame(() => {
  setParticles(prev => [
    ...prev,                                // Keep ALL old particles
    createNewParticle(),                     // Add a new one every frame
  ])
  // Result: array grows forever. 60 new particles per second.
  // After 10 seconds: 600 particles. After a minute: 3,600.
  // Memory usage climbs. FPS drops. Eventually crashes.
})

// RIGHT — fixed pool with recycling
const particles = useMemo(() =>
  Array.from({ length: MAX_PARTICLES }, () => createParticle()),
[])

useFrame((_, delta) => {
  particles.forEach(p => {
    p.life -= delta
    if (p.life <= 0) resetParticle(p)  // Recycle, don't create new
    updateParticle(p, delta)
  })
})
```

Pre-allocate your particle pool once. Recycle dead particles by resetting their properties. Never use `useState` or array spreading for particle state — it triggers re-renders and GC pressure every frame.

### 6. Effect Order Producing Unexpected Results

```tsx
// CONFUSING — CRT warp before bloom
// The warped edges create bright discontinuities that bloom catches
<EffectComposer>
  <primitive object={crtWarp} />
  <Bloom intensity={1} luminanceThreshold={0.5} />
</EffectComposer>
// Result: bright bloom artifacts along the CRT warp boundary

// INTENTIONAL — bloom before CRT warp
// The bloom glow gets warped along with the rest of the image
<EffectComposer>
  <Bloom intensity={1} luminanceThreshold={0.5} />
  <primitive object={crtWarp} />
</EffectComposer>
// Result: clean CRT effect with naturally warped glow
```

When debugging unexpected visuals, try reordering your effects. Comment out everything except one effect, verify it looks right, then add them back one at a time. The order in which effects appear in `<EffectComposer>` is the order they're applied.

---

## Exercises

### Exercise 1: Neon Sign With Bloom

**Time:** 30–45 minutes

Set up an `EffectComposer` with `Bloom` and `Vignette`. Build a dark scene with a neon sign that glows.

Requirements:
- Dark background wall (`meshStandardMaterial`, color near black)
- Text or simple shapes (torus, box outlines) with emissive materials
- Emissive intensity of at least 2, `toneMapped={false}`
- Bloom with `luminanceThreshold` tuned so only the neon glows, not the wall
- Subtle vignette for framing

Hints:
- Use drei's `<Text>` with a custom material child for neon text
- Try multiple colors — cyan, magenta, orange — for a neon bar feel
- Adjust `luminanceSmoothing` if the bloom cutoff looks too harsh
- Add a `<pointLight>` near each sign to cast colored light on the wall

**Stretch goal:** Add a flickering effect — randomly dip the emissive intensity for a fraction of a second using `useFrame` and `Math.random()`.

### Exercise 2: Custom Scanline Effect

**Time:** 45–60 minutes

Build a scanline post-processing effect completely from scratch following section 6.

Requirements:
- Extend the `Effect` class from `postprocessing`
- Write a GLSL fragment shader that darkens alternating horizontal lines
- Accept `count` (number of lines) and `intensity` (darkening amount) as uniforms
- Scrolling animation via the `update` method
- Wrap it in a React component and use it inside `<EffectComposer>`

Hints:
- Use `sin(uv.y * count * PI)` for the scanline pattern
- Multiply `inputColor.rgb` by the scanline pattern value
- Keep intensity low (0.15-0.3) — heavy scanlines are hard to look at
- The `update` method receives `deltaTime` — accumulate it for the scroll animation

**Stretch goal:** Add a `thickness` uniform that controls the duty cycle of the scanlines (thick dark bands vs thin dark lines). Use `step()` or `smoothstep()` instead of `sin()`.

### Exercise 3: Particle Spark Emitter

**Time:** 45–60 minutes

Create a particle emitter that spawns sparks from a point, arcing upward and falling with gravity.

Requirements:
- Use `InstancedMesh` with at least 300 particles
- Particles spawn at a point, fly upward with randomized velocity, and fall with gravity
- Particles shrink as they age
- Color gradient from bright yellow/white (young) to red/orange (old)
- Fixed particle pool with recycling — no array growth

Hints:
- Store particle data in a `useMemo` array, not state
- Use `Object3D` + `setMatrixAt` to update instance transforms
- Don't forget `instanceMatrix.needsUpdate = true` every frame
- Use `meshBasicMaterial` with `toneMapped={false}` for bright particles
- Stagger initial lifetimes so particles don't all spawn at once

**Stretch goal:** Add bloom to make the bright particles glow. Use `useFrame` to slowly rotate the emission direction, creating a sparkler effect.

### Exercise 4 (Stretch): Full CRT TV Effect

**Time:** 1.5–2 hours

Build a comprehensive CRT TV effect combining three custom post-processing effects.

Requirements:
- **Barrel distortion** — CRT screen curvature, pixels pushed outward from center
- **Scanlines** — horizontal darkening lines
- **Color bleeding** — slight horizontal offset between R, G, and B channels (similar to chromatic aberration but horizontal only)
- All three as custom `Effect` classes with their own GLSL shaders
- Stack them in the correct order inside `<EffectComposer>`
- Add a thin black border around the warped screen area

Hints:
- For barrel distortion: `centered *= 1.0 + warpAmount * dot(centered, centered)`
- For color bleeding: sample the R channel from a UV slightly to the left, G from center, B from slightly to the right
- Apply distortion last so it warps the scanlines and color bleeding too
- Add a subtle green tint (`hue` shift) for an old-school monitor look
- The black border comes naturally from the barrel distortion — pixels outside 0-1 UV range render black

**Stretch goal:** Add a "power on" animation — the screen starts as a single horizontal line in the center and expands vertically to fill the screen, with VHS-style noise during the transition.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [react-three/postprocessing docs](https://docs.pmnd.rs/react-postprocessing/introduction) | Official Docs | API reference for all built-in effects and EffectComposer configuration |
| [postprocessing library (vanruesc)](https://github.com/pmndrs/postprocessing) | Source Code | The underlying library. Read the Effect base class source to understand custom effects deeply |
| [The Book of Shaders](https://thebookofshaders.com/) | Tutorial | Essential GLSL knowledge for writing custom post-processing effects |
| [ShaderToy](https://shadertoy.com) | Examples | Thousands of full-screen shader effects you can study and adapt to postprocessing |
| [Three.js Journey — Post-Processing](https://threejs-journey.com/lessons/post-processing-with-r3f) | Course | Bruno Simon's lesson on R3F post-processing, with video walkthrough |
| [GDC: The Art of the Juice](https://www.youtube.com/watch?v=Fy0aCDmgnxg) | Talk | Classic game feel talk covering VFX composition, screen shake, and "juice" |

---

## Key Takeaways

1. **Post-processing effects operate on the rendered frame, not on individual objects.** The scene renders to a texture, then effects modify that texture before it reaches the screen. This is fundamentally different from material-level shaders.

2. **EffectComposer handles the ping-pong buffer pipeline for you.** Just list your effects as children. The library manages framebuffers, effect merging, and rendering order automatically.

3. **Bloom needs bright pixels.** Set `emissiveIntensity` above 1 and `toneMapped={false}` on materials you want to glow. Tune `luminanceThreshold` to prevent unwanted glow on the rest of the scene.

4. **Custom effects extend the `Effect` class with a `mainImage` GLSL function.** The pattern is straightforward: read `inputColor` at the current pixel, optionally sample `inputBuffer` at other coordinates, write to `outputColor`. Use the `update` method for animated uniforms.

5. **Particles should use a fixed pool with recycling, never growing arrays.** Pre-allocate `InstancedMesh` instances or GPU buffer attributes. Recycle dead particles by resetting their properties. For maximum performance, move particle logic to vertex shaders.

6. **VFX composition is where the magic happens.** A single game event should trigger particles + post-processing spikes + camera shake + audio simultaneously. Each system is simple alone; together, they create visceral game feel that players remember.

---

## What's Next

You can now control how your game *looks* at every level — from individual material shaders (Module 6) to full-screen post-processing and particle VFX (this module). The next challenge is making your game *sound* right and giving players the tools to tweak their experience.

**[Module 8: Procedural & Instanced Worlds](module-08-procedural-instanced-worlds.md)** covers spatial audio with Web Audio API, sound effect triggering tied to game events, music systems with crossfading, and building a proper settings menu with graphics quality presets, audio controls, and input rebinding.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)