# Module 2: 3D Assets & World Building

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** [Module 1: React Performance for Games](module-01-react-performance-for-games.md)

---

## Overview

You can make cubes and spheres all day, but real games ship with real assets — characters, buildings, props, terrain. This module is where your scenes stop looking like a math demo and start looking like a world.

You'll learn the entire GLTF pipeline: finding free models, loading them into R3F, compressing them so they don't obliterate your load times, and tweaking their materials once they're in the scene. You'll learn PBR materials properly — not just "set color and move on" but understanding what baseColor, metalness, roughness, normal maps, and ambient occlusion actually do. You'll light scenes with intention, using three-point rigs, shadows, and environment maps to create mood instead of just visibility.

The mini-project is a stylized environment diorama — a small campsite scene composed from free assets with deliberate lighting, shadows, fog, and camera framing. It's the kind of thing you'd screenshot and put in a portfolio. More importantly, building it forces you through every step of the real-world asset pipeline: find model, download, compress, load, position, light, polish.

By the end of this module, you'll be able to build a complete 3D environment from scratch using free assets. That's the foundation every game needs.

---

## 1. The GLTF Format

### Why GLTF Won

GLTF (GL Transmission Format) is the JPEG of 3D. It's the standard. It's what Three.js loads fastest. It's what Blender exports cleanly. It's what every browser-based 3D engine has first-class support for. Use it unless you have a very specific reason not to.

GLTF was designed by the Khronos Group (same people behind OpenGL and Vulkan) specifically for runtime delivery — meaning it's optimized for loading fast and rendering immediately, not for editing in a DCC tool.

### What's Inside a GLTF File

A GLTF file is a scene graph containing:

| Component | What It Stores |
|-----------|---------------|
| **Meshes** | Vertex positions, normals, UVs, indices |
| **Materials** | PBR properties (baseColor, metalness, roughness, normal maps, etc.) |
| **Textures** | Image data (embedded or referenced as separate files) |
| **Animations** | Keyframe data for skeletal and morph target animations |
| **Scene graph** | Node hierarchy, transforms, parent-child relationships |
| **Extras** | Cameras, lights, custom properties from the authoring tool |

### Binary vs Text

GLTF comes in two flavors:

| Format | Extension | Description |
|--------|-----------|-------------|
| **GLTF Text** | `.gltf` + `.bin` + textures | JSON text file referencing external binary data and images. Good for debugging — you can read the JSON. |
| **GLTF Binary** | `.glb` | Single file, everything packed together. Smaller, faster to load, harder to inspect. **Use this for production.** |

Always export as `.glb` for your projects. The only time you'd want `.gltf` is when you need to inspect or hand-edit the JSON.

### GLTF vs FBX vs OBJ

| Feature | GLTF/GLB | FBX | OBJ |
|---------|---------|-----|-----|
| **Three.js support** | Native, fast, first-class | Needs separate loader, larger bundle | Supported but limited |
| **Materials** | Full PBR | Proprietary material model, lossy conversion | Basic only (MTL file) |
| **Animations** | Yes (skeletal + morph) | Yes | No |
| **File size** | Small (especially with Draco) | Large | Medium |
| **Scene graph** | Yes | Yes | No |
| **Open standard** | Yes (Khronos) | No (Autodesk) | Sort of (ancient, loosely defined) |
| **Verdict** | **Default choice** | Only if asset is FBX-only | Legacy, avoid |

If someone hands you an FBX or OBJ, convert it to GLB. Use Blender (import, then export as GLB) or the `gltf-transform` CLI.

---

## 2. Loading Models with useGLTF

### The Hook

drei's `useGLTF` hook handles loading, caching, and parsing GLTF files. It returns a structured object containing every mesh, material, and animation from the file.

```tsx
import { useGLTF } from '@react-three/drei'

function CampfireModel() {
  const { nodes, materials, scene } = useGLTF('/models/campfire.glb')

  return <primitive object={scene} />
}
```

The `scene` property is the entire Three.js scene graph from the file. Wrapping it in `<primitive>` dumps the whole thing into your R3F tree. This is the quickest way to get a model on screen, but not the most flexible.

### Accessing Nodes and Materials

The `nodes` object gives you named access to every mesh in the file. The `materials` object gives you every material. Names come from whatever the artist named things in Blender (or whatever DCC tool was used).

```tsx
function CampfireModel() {
  const { nodes, materials } = useGLTF('/models/campfire.glb')

  return (
    <group>
      <mesh
        geometry={(nodes.Logs as THREE.Mesh).geometry}
        material={materials.Wood}
        position={[0, 0, 0]}
      />
      <mesh
        geometry={(nodes.Flames as THREE.Mesh).geometry}
        material={materials.Fire}
        position={[0, 0.5, 0]}
      />
    </group>
  )
}
```

This approach gives you full control — you can reposition individual parts, swap materials, add click handlers to specific meshes.

### Suspense Boundaries

`useGLTF` suspends while loading. You **must** wrap components that use it in a `<Suspense>` boundary, or React will crash.

```tsx
import { Suspense } from 'react'
import { Canvas } from '@react-three/fiber'

function App() {
  return (
    <Canvas>
      <Suspense fallback={null}>
        <CampfireModel />
      </Suspense>
    </Canvas>
  )
}
```

The `fallback` can be `null` (show nothing while loading) or a loading indicator. For 3D, `null` is usually fine — the model just pops in when ready.

### Preloading

If you know a model will be needed, preload it before the component mounts. This kicks off the network request early so the model is ready when you need it.

```tsx
useGLTF.preload('/models/campfire.glb')
```

Call this at module scope (outside any component) in the file that uses the model.

### Where to Put Model Files

Put `.glb` files in the `public/` directory. Vite serves files from `public/` at the root path:

```
public/
  models/
    campfire.glb
    tent.glb
    tree.glb
```

Then reference them as `/models/campfire.glb` in your code. Don't put them in `src/` — Vite would try to bundle them, which is not what you want for binary assets.

---

## 3. gltfjsx: Auto-Generated Components

### Why This Is the Recommended Workflow

Manually accessing `nodes` and `materials` by string name is tedious and error-prone. `gltfjsx` solves this by analyzing a GLB file and generating a fully typed React component from it. The generated code gives you:

- Every mesh as a named JSX element
- Correct geometry and material references
- Proper TypeScript types
- The scene hierarchy preserved as nested JSX

### Running gltfjsx

```bash
npx gltfjsx public/models/campfire.glb --types --output src/components/Campfire.tsx
```

Key flags:

| Flag | What It Does |
|------|-------------|
| `--types` | Generate TypeScript types (always use this) |
| `--output <path>` | Write to a specific file instead of stdout |
| `--transform` | Optimize the GLB (compress with Draco, resize textures) during generation |
| `--shadows` | Add `castShadow` and `receiveShadow` to all meshes |
| `--instance` | Use instanced rendering for repeated geometries |

### What It Generates

For a campfire model, `gltfjsx` might produce something like:

```tsx
// Auto-generated by gltfjsx
import * as THREE from 'three'
import { useGLTF } from '@react-three/drei'
import { GLTF } from 'three-stdlib'

type GLTFResult = GLTF & {
  nodes: {
    Logs: THREE.Mesh
    Stones: THREE.Mesh
    Flames: THREE.Mesh
  }
  materials: {
    Wood: THREE.MeshStandardMaterial
    Rock: THREE.MeshStandardMaterial
    Fire: THREE.MeshStandardMaterial
  }
}

export function Campfire(props: JSX.IntrinsicElements['group']) {
  const { nodes, materials } = useGLTF('/models/campfire.glb') as GLTFResult
  return (
    <group {...props} dispose={null}>
      <mesh geometry={nodes.Logs.geometry} material={materials.Wood} />
      <mesh geometry={nodes.Stones.geometry} material={materials.Rock} />
      <mesh geometry={nodes.Flames.geometry} material={materials.Fire} />
    </group>
  )
}

useGLTF.preload('/models/campfire.glb')
```

### Customizing the Output

The generated file is **your code now**. Edit it freely:

- Add `castShadow` / `receiveShadow` to specific meshes
- Swap materials for custom ones
- Add animation hooks
- Add click handlers
- Wrap meshes in `<Float>` or other drei helpers
- Delete parts of the model you don't need

```tsx
export function Campfire(props: JSX.IntrinsicElements['group']) {
  const { nodes, materials } = useGLTF('/models/campfire.glb') as GLTFResult
  return (
    <group {...props} dispose={null}>
      <mesh
        geometry={nodes.Logs.geometry}
        material={materials.Wood}
        castShadow
        receiveShadow
      />
      <mesh
        geometry={nodes.Stones.geometry}
        material={materials.Rock}
        receiveShadow
      />
      {/* Make flames emissive and animated */}
      <mesh geometry={nodes.Flames.geometry}>
        <meshStandardMaterial
          color="#ff6600"
          emissive="#ff4400"
          emissiveIntensity={3}
          toneMapped={false}
        />
      </mesh>
    </group>
  )
}
```

The `--transform` flag is particularly useful. It runs the model through `gltf-transform` to apply Draco compression and downsize textures, outputting a new optimized `.glb` alongside your component. Use it unless you're managing optimization separately.

---

## 4. Draco and KTX2 Compression

### Why You Compress

Uncompressed 3D models are large. A character model with textures can easily be 20-50MB. In a web game, that's unacceptable. Compression is not optional — it's a requirement.

Two things need compressing: **geometry** (vertices, indices) and **textures** (images).

### Draco Compression (Geometry)

Draco is Google's mesh compression library. It compresses vertex data (positions, normals, UVs) by quantizing and entropy-coding it. Results are dramatic:

| Metric | Before Draco | After Draco |
|--------|-------------|-------------|
| Geometry size | 10 MB | 0.5-1 MB |
| Compression ratio | 1x | 10-20x |
| Load time | Slow | Fast |
| Decode cost | None | Small CPU spike on load |

To use Draco-compressed models in R3F, you need to tell `useGLTF` where to find the Draco decoder:

```tsx
import { useGLTF } from '@react-three/drei'

// Point to the Draco decoder WASM files
// drei bundles them — this just works
useGLTF.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.5.7/')

function MyModel() {
  const { scene } = useGLTF('/models/character.glb')
  return <primitive object={scene} />
}
```

Alternatively, copy the Draco decoder files into your `public/` directory and point there:

```tsx
useGLTF.setDecoderPath('/draco/')
```

### Compressing with gltf-transform CLI

`gltf-transform` is the Swiss Army knife for GLTF optimization. Install and use it:

```bash
npx gltf-transform draco input.glb output.glb
```

For a full optimization pass:

```bash
npx gltf-transform optimize input.glb output.glb --compress draco --texture-compress webp
```

### KTX2 / Basis Universal (Texture Compression)

Textures are usually the biggest part of a model's file size. KTX2 with Basis Universal encoding compresses textures so they can be loaded directly onto the GPU without decompression — saving both download time and GPU memory.

| Metric | PNG/JPEG | KTX2/Basis |
|--------|---------|------------|
| GPU memory | Full size (e.g. 16MB for 2K RGBA) | 4-6x smaller |
| Download size | Varies | 3-6x smaller than PNG |
| GPU upload | Decode then upload | Direct upload, no decode |

To use KTX2 textures in R3F:

```tsx
import { useGLTF } from '@react-three/drei'
import { KTX2Loader } from 'three-stdlib'

// Set up KTX2 loader with Basis transcoder
const ktx2Loader = new KTX2Loader()
ktx2Loader.setTranscoderPath('https://cdn.jsdelivr.net/gh/pmndrs/drei-assets/basis/')

function MyModel() {
  const { scene } = useGLTF('/models/scene.glb', true, true, (loader) => {
    loader.setKTX2Loader(ktx2Loader)
  })
  return <primitive object={scene} />
}
```

Compress textures to KTX2 with gltf-transform:

```bash
npx gltf-transform ktx2 input.glb output.glb --slots "baseColor,normal,emissive"
```

### Compression Decision Tree

1. **Always** apply Draco to geometry. No reason not to.
2. **Always** resize textures to the minimum resolution that looks good. 1024x1024 is plenty for most game assets. 2048x2048 for hero pieces.
3. **Use KTX2** when you have many textures or target mobile. The GPU memory savings matter.
4. **Use WebP/AVIF** as a simpler alternative to KTX2 if you just want smaller downloads without GPU-compressed textures.

---

## 5. PBR Materials Deep Dive

### What PBR Actually Means

PBR (Physically Based Rendering) means materials respond to light in a physically plausible way. A metal surface reflects light like actual metal. A rough surface scatters light like actual rough surfaces. This is why scenes with PBR materials look "correct" without manual tweaking — the math models reality.

Three.js's `MeshStandardMaterial` implements the metallic-roughness PBR model (same as GLTF, Unreal, Unity, Blender's Principled BSDF). Every surface is defined by a small set of texture maps.

### The Core PBR Maps

| Map | What It Controls | Range | Notes |
|-----|-----------------|-------|-------|
| **Base Color** (albedo) | Surface color without lighting | RGB | sRGB color space. This is what you think of as "the texture." |
| **Metalness** | Is it metal or non-metal? | 0-1 (grayscale) | 0 = dielectric (wood, plastic, skin). 1 = metal (gold, steel, aluminum). Usually 0 or 1, rarely in between. |
| **Roughness** | How rough is the surface? | 0-1 (grayscale) | 0 = perfect mirror. 1 = completely matte. Most real materials are 0.3-0.9. |
| **Normal** | Surface micro-detail | RGB (tangent-space) | Fakes small bumps and scratches without extra geometry. **Must be in linear color space.** |
| **Ambient Occlusion** (AO) | Crevice darkening | 0-1 (grayscale) | Pre-baked shadows in tight spaces. Adds depth without runtime cost. |
| **Emissive** | Self-illumination | RGB | Parts that glow (screens, lava, neon signs). Does not illuminate other objects. |

### How They Work Together

Think of it in layers:

1. **Base Color** sets the base appearance
2. **Metalness** decides if it reflects like metal (tinted reflections) or non-metal (white reflections)
3. **Roughness** decides if reflections are sharp (mirror) or blurry (matte)
4. **Normal Map** adds surface detail without geometry
5. **AO** darkens crevices and contact areas
6. **Emissive** adds glow on top of everything

### Applying Texture Maps in R3F

```tsx
import { useTexture } from '@react-three/drei'
import * as THREE from 'three'

function TexturedGround() {
  const [colorMap, normalMap, roughnessMap, aoMap] = useTexture([
    '/textures/ground_color.jpg',
    '/textures/ground_normal.jpg',
    '/textures/ground_roughness.jpg',
    '/textures/ground_ao.jpg',
  ])

  return (
    <mesh rotation={[-Math.PI / 2, 0, 0]} receiveShadow>
      <planeGeometry args={[20, 20]} />
      <meshStandardMaterial
        map={colorMap}
        normalMap={normalMap}
        roughnessMap={roughnessMap}
        aoMap={aoMap}
        normalScale={new THREE.Vector2(1, 1)}
      />
    </mesh>
  )
}
```

### Tweaking Materials After Loading

Models come with materials baked in, but you often want to adjust them at runtime. Access materials from the GLTF result and modify them:

```tsx
function TweakedModel() {
  const { nodes, materials } = useGLTF('/models/prop.glb') as GLTFResult

  // Modify material properties after loading
  useEffect(() => {
    const mat = materials.Wood as THREE.MeshStandardMaterial
    mat.roughness = 0.9
    mat.metalness = 0.0
    mat.envMapIntensity = 0.5
    mat.needsUpdate = true
  }, [materials])

  return <primitive object={nodes.Scene} />
}
```

Or override a material entirely in JSX:

```tsx
<mesh geometry={nodes.Crystal.geometry}>
  <meshPhysicalMaterial
    color="#88ccff"
    roughness={0.05}
    metalness={0}
    transmission={0.9}
    thickness={1.5}
    ior={1.5}
  />
</mesh>
```

---

## 6. Lighting Fundamentals

### Lighting Is Not Decoration — It's Design

Bad lighting makes great assets look terrible. Good lighting makes simple assets look stunning. Lighting is the single biggest factor in how your scene "feels." This section teaches you to light with intention.

### Three-Point Lighting

The three-point lighting rig is the foundation of all lighting setups — film, photography, games. Every complex lighting setup is a variation of this.

| Light | Role | Typical Intensity | Position |
|-------|------|------------------|----------|
| **Key Light** | Main illumination. Strongest light. Creates primary shadows. | 1.0-2.0 | Front-side, above (e.g. `[5, 8, 3]`) |
| **Fill Light** | Softens shadows from key. Usually weaker and more diffuse. | 0.3-0.5 | Opposite side from key, lower (e.g. `[-4, 3, 4]`) |
| **Rim/Back Light** | Separates subject from background. Creates edge highlight. | 0.5-1.0 | Behind and above subject (e.g. `[-3, 6, -5]`) |

```tsx
function ThreePointRig() {
  return (
    <group>
      {/* Key light — warm, strong, front-right */}
      <directionalLight
        position={[5, 8, 3]}
        intensity={1.5}
        color="#fff5e0"
        castShadow
        shadow-mapSize-width={2048}
        shadow-mapSize-height={2048}
      />

      {/* Fill light — cool, softer, front-left */}
      <directionalLight
        position={[-4, 3, 4]}
        intensity={0.4}
        color="#e0e8ff"
      />

      {/* Rim light — behind and above */}
      <directionalLight
        position={[-3, 6, -5]}
        intensity={0.8}
        color="#ffeedd"
      />

      {/* Ambient fill so nothing is pure black */}
      <ambientLight intensity={0.15} color="#404060" />
    </group>
  )
}
```

### Color Temperature

Warm light (yellowish, like sunset or firelight) and cool light (bluish, like shade or moonlight) create mood. Use them deliberately:

| Mood | Key Light Color | Fill/Ambient Color |
|------|----------------|-------------------|
| **Warm, cozy** | `#ffddaa` | `#886644` |
| **Cool, tense** | `#aaccff` | `#334466` |
| **Neutral daylight** | `#ffffff` | `#ccccdd` |
| **Golden hour** | `#ffaa55` | `#8866aa` |
| **Moonlight** | `#aabbdd` | `#222244` |

The key trick: key light and fill light should usually be **different temperatures**. Warm key + cool fill (or vice versa) creates visual richness. Same-temperature everything looks flat.

### Physically Correct Lighting

Three.js has a physically correct lighting mode where intensity values match real-world units (lumens for point lights, lux for directional lights). R3F enables this by default in recent versions.

In physically correct mode:
- `directionalLight intensity={1}` = 1 lux (dim)
- `pointLight intensity={100}` = 100 lumens (typical desk lamp)
- `pointLight intensity={800}` = 800 lumens (bright bulb)

The `decay` property controls how light falls off with distance. Set `decay={2}` for physically correct inverse-square falloff.

```tsx
<pointLight
  position={[0, 2, 0]}
  intensity={400}
  distance={20}
  decay={2}
  color="#ffaa44"
/>
```

---

## 7. Shadow Configuration

### Shadow Map Basics

Shadows in Three.js work by rendering the scene from the light's perspective into a depth texture (the shadow map), then using that texture to determine which pixels are in shadow during the main render.

This means shadows are expensive: each shadow-casting light does an extra render pass.

### Enabling Shadows — The Three-Step Checklist

1. `shadows` on `<Canvas>`
2. `castShadow` on the light
3. `castShadow` on objects that cast shadows, `receiveShadow` on objects that receive them

```tsx
<Canvas shadows>
  <directionalLight castShadow position={[5, 8, 3]} />
  <mesh castShadow>   {/* This object casts a shadow */}
    <boxGeometry />
    <meshStandardMaterial />
  </mesh>
  <mesh receiveShadow rotation={[-Math.PI / 2, 0, 0]}> {/* Ground receives shadow */}
    <planeGeometry args={[50, 50]} />
    <meshStandardMaterial />
  </mesh>
</Canvas>
```

### Shadow Map Types

| Type | Quality | Performance | Use Case |
|------|---------|-------------|----------|
| `THREE.BasicShadowMap` | Hard edges, aliased | Fastest | Stylized games, retro look |
| `THREE.PCFShadowMap` | Soft edges (default) | Medium | General purpose |
| `THREE.PCFSoftShadowMap` | Softer edges | Slower | When quality matters |
| `THREE.VSMShadowMap` | Very soft, can bleed | Medium | Specific artistic needs |

Set it on the Canvas:

```tsx
import * as THREE from 'three'

<Canvas shadows={{ type: THREE.PCFSoftShadowMap }}>
```

### Shadow Resolution

Higher resolution = sharper shadows = more GPU memory. The default is 512x512, which looks terrible. Use at least 1024, ideally 2048 for your main directional light.

```tsx
<directionalLight
  castShadow
  shadow-mapSize-width={2048}
  shadow-mapSize-height={2048}
/>
```

### Shadow Camera Frustum

For directional lights, the shadow camera is orthographic. You need to define how large an area it covers. Too large = blurry shadows. Too small = shadows cut off.

```tsx
<directionalLight
  castShadow
  shadow-mapSize-width={2048}
  shadow-mapSize-height={2048}
  shadow-camera-left={-10}
  shadow-camera-right={10}
  shadow-camera-top={10}
  shadow-camera-bottom={-10}
  shadow-camera-near={0.1}
  shadow-camera-far={50}
/>
```

The shadow camera frustum should be as tight as possible around the area you care about. If your scene is 10 units wide, don't set the shadow camera to 100 units wide — you're wasting 99% of your shadow map resolution.

### Shadow Bias

Shadow bias prevents "shadow acne" — a moire pattern caused by the shadow map's limited precision. Too much bias causes "peter panning" — shadows detach from their objects.

```tsx
<directionalLight
  castShadow
  shadow-bias={-0.0005}   // Negative values push shadow toward light
  shadow-normalBias={0.02} // Pushes along surface normal, usually better
/>
```

Start with `shadow-normalBias={0.02}` and adjust from there. It's more forgiving than `shadow-bias`.

### drei Shadow Helpers

**ContactShadows** — Fake ground-contact shadows. Not real shadow mapping. Rendered from below, fast, looks great for grounding objects.

```tsx
import { ContactShadows } from '@react-three/drei'

<ContactShadows
  position={[0, 0, 0]}
  opacity={0.5}
  scale={20}
  blur={2}
  far={4}
  color="#000000"
/>
```

**AccumulativeShadows** — Accumulates multiple soft shadow samples over time. Produces extremely soft, natural-looking shadows. More expensive but great for static scenes.

```tsx
import { AccumulativeShadows, RandomizedLight } from '@react-three/drei'

<AccumulativeShadows
  temporal
  frames={100}
  scale={20}
  position={[0, 0.01, 0]}
  opacity={0.8}
>
  <RandomizedLight
    amount={8}
    radius={4}
    ambient={0.5}
    position={[5, 8, 3]}
    bias={0.001}
  />
</AccumulativeShadows>
```

### Performance Rules for Shadows

1. **Limit shadow-casting lights.** One or two max. Each shadow-casting light adds a full render pass.
2. **Only `castShadow` on objects that need it.** Small props far from the camera don't need shadows.
3. **Use ContactShadows for grounding** instead of real shadows on small objects.
4. **Tight shadow camera frustum.** Cover only what the player sees.

---

## 8. Environment and Image-Based Lighting

### What IBL Does

Image-Based Lighting (IBL) uses an HDR image of a real or virtual environment to light your scene. Instead of placing individual lights, you wrap the entire scene in a spherical photo of, say, a sunset sky — and that photo provides ambient light, reflections, and color from every direction.

It's the fastest way to get a scene looking good. One line of code replaces hours of manual light placement.

### drei's Environment Component

```tsx
import { Environment } from '@react-three/drei'

// Use a built-in preset
<Environment preset="sunset" />
```

Available presets:

| Preset | Mood |
|--------|------|
| `apartment` | Warm interior |
| `city` | Urban, neutral |
| `dawn` | Soft pink/orange |
| `forest` | Green, dappled |
| `lobby` | Bright interior |
| `night` | Dark blue |
| `park` | Daylight, green |
| `studio` | Clean, neutral |
| `sunset` | Golden, warm |
| `warehouse` | Industrial, dim |

### Custom HDRIs

Presets are convenient but limited. For production, use HDRIs from [Polyhaven](https://polyhaven.com/hdris) — they're free, high quality, and CC0 licensed.

Download a `.hdr` or `.exr` file, put it in `public/`, and reference it:

```tsx
<Environment
  files="/hdri/meadow_2_1k.hdr"
  background                     // Also use as visible background
  backgroundBlurriness={0.05}    // Slight blur on background
/>
```

### Background vs Lighting Only

By default, `<Environment>` only provides lighting — no visible background. Add the `background` prop to make it visible:

```tsx
{/* Lighting only — background is whatever you set it to */}
<Environment preset="sunset" />

{/* Lighting AND visible background */}
<Environment preset="sunset" background />

{/* Lighting AND blurred background */}
<Environment preset="sunset" background backgroundBlurriness={0.5} />
```

### Environment Intensity

Control how strongly the environment map affects your scene:

```tsx
<Environment preset="sunset" environmentIntensity={0.8} />
```

Lower values make the environment lighting subtler, giving your direct lights more dominance. Higher values make the scene feel more "open" and evenly lit. Start at 1.0 and adjust based on your scene's mood.

### Combining Environment with Direct Lights

The most common setup: environment map for ambient fill + one or two directional lights for key shadows.

```tsx
{/* Environment handles ambient/fill/reflections */}
<Environment preset="sunset" />

{/* Directional light handles key light + shadows */}
<directionalLight
  position={[5, 8, 3]}
  intensity={1.5}
  castShadow
  shadow-mapSize-width={2048}
  shadow-mapSize-height={2048}
/>
```

This gives you the best of both worlds: rich ambient lighting from the environment and crisp, controllable shadows from the directional light.

---

## 9. Scene Composition Patterns

### Layering: Foreground, Midground, Background

Good scenes have depth. Arrange elements in three layers:

| Layer | Examples | Purpose |
|-------|----------|---------|
| **Foreground** | Grass, rocks, small props near camera | Frame the scene, create intimacy |
| **Midground** | Main subject (campsite, character, building) | Focus of attention |
| **Background** | Mountains, trees, sky, distant structures | Context, scale, atmosphere |

### Focal Points

Every scene needs something your eye goes to first. Create focal points with:

- **Contrast** — A bright object against a dark background
- **Color** — A warm-colored object in a cool scene
- **Scale** — The largest object draws attention
- **Light** — Direct a spotlight or the key light at the focal point
- **Isolation** — Space around an object makes it stand out

### Camera Framing

Where you put the camera matters as much as what's in the scene.

```tsx
<Canvas camera={{ position: [6, 4, 8], fov: 45 }}>
```

Rules of thumb:
- **Lower FOV** (35-50) flattens perspective, feels cinematic
- **Higher FOV** (60-80) exaggerates depth, feels more immersive/game-like
- **Camera slightly above** the scene (Y > 0) feels natural
- **Camera at ground level** feels dramatic

### Using drei Helpers for Composition

**Center** — Automatically centers a group of objects at the origin. Useful when loaded models have weird offsets.

```tsx
import { Center } from '@react-three/drei'

<Center>
  <CampfireModel />
</Center>
```

**Stage** — One-component scene setup: adds environment, ground, shadows, and lighting with sensible defaults.

```tsx
import { Stage } from '@react-three/drei'

<Stage
  intensity={0.5}
  environment="sunset"
  shadows={{ type: 'contact', opacity: 0.5, blur: 2 }}
  adjustCamera={false}
>
  <MyModel />
</Stage>
```

`Stage` is great for product shots and quick prototyping. For your game, you'll eventually replace it with a custom setup — but it's useful for testing how models look before you commit to a lighting rig.

### Fog for Depth

Fog fades distant objects into a color, creating atmospheric depth and hiding where the world ends.

```tsx
<Canvas>
  <fog attach="fog" args={['#e0d5c0', 10, 40]} />
  {/* args = [color, near, far] */}
</Canvas>
```

- `near` = distance where fog starts
- `far` = distance where fog fully obscures objects

Match the fog color to your background or sky for a natural look. Mismatched fog color is immediately obvious and looks wrong.

For exponential fog (denser at distance, more natural):

```tsx
<fogExp2 attach="fog" args={['#e0d5c0', 0.04]} />
{/* args = [color, density] */}
```

### Color Palette

Limit your scene to 3-5 main colors. Stylized scenes look better with intentional color choices than with random asset colors. After loading a model, you can override its materials to match your palette:

```tsx
<mesh geometry={nodes.Tent.geometry}>
  <meshStandardMaterial color="#cc7744" roughness={0.8} />
</mesh>
```

---

## 10. Free Asset Sources

### Where to Get Models

| Source | Type | License | Notes |
|--------|------|---------|-------|
| [Kenney](https://kenney.nl/) | Low-poly game assets | CC0 (public domain) | Best for: consistent style, game-ready, includes UI/audio too. Thousands of free packs. |
| [Poly Pizza](https://poly.pizza/) | Low-poly models | CC-BY (attribution) | Best for: individual props, search by keyword. Quick downloads. |
| [Quaternius](https://quaternius.com/) | Low-poly game packs | CC0 | Best for: themed packs (nature, medieval, sci-fi). Consistent style within packs. |
| [Sketchfab](https://sketchfab.com/) | All styles | Varies per model | Best for: high-quality hero pieces. Check license on each model. Download as GLTF. |
| [Mixamo](https://www.mixamo.com/) | Characters + animations | Free for use | Best for: rigged characters with animations. Export as FBX, convert to GLB. |

### Where to Get Textures

| Source | Type | License | Notes |
|--------|------|---------|-------|
| [Polyhaven](https://polyhaven.com/) | Textures, HDRIs, models | CC0 | Best all-around. PBR texture sets with all maps. Free HDRIs for environment lighting. |
| [ambientCG](https://ambientcg.com/) | PBR textures | CC0 | Huge library. Download at various resolutions. Great for ground, walls, surfaces. |

### When to Use What

- **Kenney or Quaternius** for consistent stylized look — assets from the same pack match each other
- **Poly Pizza** for filling in gaps — need one specific prop? Search here
- **Polyhaven** for textures and HDRIs — always your first stop for materials and environment maps
- **Sketchfab** for hero pieces — when you need something special and high-quality
- **ambientCG** for tiling textures — ground, walls, floors

### Practical Tip: Style Consistency

Don't mix hyperrealistic Sketchfab models with Kenney low-poly assets in the same scene. Pick one style and stick with it. The diorama project uses Kenney/Quaternius assets because they share a low-poly aesthetic and are guaranteed compatible.

---

## Code Walkthrough: Building the Campsite Diorama

Let's build a complete stylized campsite scene step by step. The final result: a small island-like clearing with a campfire, tent, trees, a ground plane, three-point lighting, environment map, contact shadows, and fog.

### Step 1: Project Setup and Assets

```bash
npm create vite@latest campsite-diorama -- --template react-ts
cd campsite-diorama
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three
```

Download free assets and place them in `public/models/`:

- **Campfire** — Kenney's [Nature Kit](https://kenney.nl/assets/nature-kit) or similar
- **Tent** — Kenney's [Survival Kit](https://kenney.nl/assets/survival-kit)
- **Trees** — Kenney's Nature Kit (includes multiple tree variants)

For this walkthrough, we'll assume you have `campfire.glb`, `tent.glb`, and `tree.glb` in `public/models/`. If you don't have exact matches, any low-poly props work — the patterns are identical.

### Step 2: Generate Components with gltfjsx

```bash
npx gltfjsx public/models/campfire.glb --types --output src/models/Campfire.tsx
npx gltfjsx public/models/tent.glb --types --output src/models/Tent.tsx
npx gltfjsx public/models/tree.glb --types --output src/models/Tree.tsx
```

### Step 3: Global Styles

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

### Step 4: Ground Plane

```tsx
// src/components/Ground.tsx
import * as THREE from 'three'
import { useTexture } from '@react-three/drei'

export function Ground() {
  // If you have Polyhaven textures, use them:
  // const [colorMap, normalMap, roughnessMap] = useTexture([
  //   '/textures/ground_color.jpg',
  //   '/textures/ground_normal.jpg',
  //   '/textures/ground_roughness.jpg',
  // ])

  return (
    <mesh
      rotation={[-Math.PI / 2, 0, 0]}
      position={[0, 0, 0]}
      receiveShadow
    >
      <circleGeometry args={[8, 64]} />
      <meshStandardMaterial
        color="#5a8a4a"
        roughness={0.9}
        metalness={0}
        // map={colorMap}
        // normalMap={normalMap}
        // roughnessMap={roughnessMap}
      />
    </mesh>
  )
}
```

A circle for the ground gives the diorama an island/pedestal feel. For a flat endless ground, use a large `planeGeometry` instead.

### Step 5: Lighting Rig

```tsx
// src/components/Lighting.tsx
import { Environment, ContactShadows } from '@react-three/drei'

export function Lighting() {
  return (
    <>
      {/* Key light — warm sunset, front-right, casts shadows */}
      <directionalLight
        position={[5, 8, 3]}
        intensity={1.5}
        color="#ffddaa"
        castShadow
        shadow-mapSize-width={2048}
        shadow-mapSize-height={2048}
        shadow-camera-left={-10}
        shadow-camera-right={10}
        shadow-camera-top={10}
        shadow-camera-bottom={-10}
        shadow-camera-near={0.1}
        shadow-camera-far={30}
        shadow-normalBias={0.02}
      />

      {/* Fill light — cool, softer, opposite side */}
      <directionalLight
        position={[-4, 3, 4]}
        intensity={0.4}
        color="#aabbdd"
      />

      {/* Rim light — behind, warm edge highlight */}
      <directionalLight
        position={[-3, 6, -5]}
        intensity={0.6}
        color="#ffccaa"
      />

      {/* Ambient base so shadows aren't pure black */}
      <ambientLight intensity={0.1} color="#404060" />

      {/* Campfire point light — warm glow */}
      <pointLight
        position={[0, 1, 0]}
        intensity={30}
        distance={12}
        decay={2}
        color="#ff8844"
      />

      {/* Environment map for reflections and ambient fill */}
      <Environment preset="sunset" environmentIntensity={0.4} />

      {/* Contact shadows for grounding objects */}
      <ContactShadows
        position={[0, 0.01, 0]}
        opacity={0.6}
        scale={20}
        blur={2}
        far={4}
        color="#2a1a0a"
      />
    </>
  )
}
```

### Step 6: Scene Composition

```tsx
// src/components/DioramaScene.tsx
import { Suspense } from 'react'
import { Float } from '@react-three/drei'
import { Ground } from './Ground'
import { Lighting } from './Lighting'
// Import your gltfjsx-generated components:
// import { Campfire } from '../models/Campfire'
// import { Tent } from '../models/Tent'
// import { Tree } from '../models/Tree'

// Placeholder components for the walkthrough
// Replace these with your actual gltfjsx-generated models

function CampfirePlaceholder() {
  return (
    <group position={[0, 0, 0]}>
      {/* Logs */}
      <mesh position={[0, 0.15, 0]} castShadow>
        <cylinderGeometry args={[0.05, 0.05, 0.6, 8]} />
        <meshStandardMaterial color="#6b3a2a" roughness={0.9} />
      </mesh>
      <mesh position={[0, 0.15, 0]} rotation={[0, Math.PI / 3, 0]} castShadow>
        <cylinderGeometry args={[0.05, 0.05, 0.6, 8]} />
        <meshStandardMaterial color="#5a2e1e" roughness={0.9} />
      </mesh>
      {/* Flames */}
      <mesh position={[0, 0.4, 0]}>
        <coneGeometry args={[0.15, 0.4, 8]} />
        <meshStandardMaterial
          color="#ff6600"
          emissive="#ff4400"
          emissiveIntensity={3}
          toneMapped={false}
        />
      </mesh>
    </group>
  )
}

function TentPlaceholder() {
  return (
    <mesh position={[0, 0.5, 0]} castShadow>
      <coneGeometry args={[0.8, 1, 4]} />
      <meshStandardMaterial color="#cc8844" roughness={0.8} />
    </mesh>
  )
}

function TreePlaceholder() {
  return (
    <group>
      {/* Trunk */}
      <mesh position={[0, 0.5, 0]} castShadow>
        <cylinderGeometry args={[0.08, 0.12, 1, 8]} />
        <meshStandardMaterial color="#6b3a2a" roughness={0.9} />
      </mesh>
      {/* Foliage */}
      <mesh position={[0, 1.3, 0]} castShadow>
        <coneGeometry args={[0.5, 1.2, 8]} />
        <meshStandardMaterial color="#3a7a3a" roughness={0.8} />
      </mesh>
    </group>
  )
}

// Tree positions scattered around the clearing
const TREE_POSITIONS: [number, number, number][] = [
  [-3, 0, -2],
  [-4, 0, 1],
  [-2.5, 0, 3],
  [3.5, 0, -1],
  [4, 0, 2],
  [2, 0, -4],
  [-1, 0, -4.5],
  [1.5, 0, 4],
]

// Random but deterministic scales for variety
const TREE_SCALES = [1.0, 0.8, 1.2, 0.9, 1.1, 0.7, 1.0, 0.85]
const TREE_ROTATIONS = [0, 0.5, 1.2, 2.1, 3.0, 4.2, 5.1, 0.8]

export function DioramaScene() {
  return (
    <Suspense fallback={null}>
      <Lighting />
      <Ground />

      {/* Campfire at center */}
      <CampfirePlaceholder />
      {/* Replace with: <Campfire position={[0, 0, 0]} /> */}

      {/* Tent offset from campfire */}
      <group position={[-2, 0, -1.5]} rotation={[0, Math.PI / 4, 0]}>
        <TentPlaceholder />
        {/* Replace with: <Tent /> */}
      </group>

      {/* Trees scattered around the clearing */}
      {TREE_POSITIONS.map((pos, i) => (
        <group
          key={i}
          position={pos}
          scale={TREE_SCALES[i]}
          rotation={[0, TREE_ROTATIONS[i], 0]}
        >
          <TreePlaceholder />
          {/* Replace with: <Tree /> */}
        </group>
      ))}

      {/* Small rocks for foreground detail */}
      {[[-0.8, 0, 0.5], [0.6, 0, -0.4], [1.2, 0, 0.8]].map(
        ([x, y, z], i) => (
          <mesh
            key={`rock-${i}`}
            position={[x, y + 0.06, z]}
            rotation={[Math.random(), Math.random(), 0]}
            scale={0.08 + i * 0.03}
            castShadow
          >
            <dodecahedronGeometry args={[1, 0]} />
            <meshStandardMaterial color="#777777" roughness={0.95} />
          </mesh>
        )
      )}

      {/* Floating fireflies / particles for atmosphere */}
      {Array.from({ length: 6 }, (_, i) => (
        <Float
          key={`fly-${i}`}
          speed={1.5 + i * 0.3}
          rotationIntensity={0}
          floatIntensity={0.5}
        >
          <mesh
            position={[
              (Math.sin(i * 2.3) * 3),
              1 + i * 0.3,
              (Math.cos(i * 1.7) * 3),
            ]}
          >
            <sphereGeometry args={[0.015, 8, 8]} />
            <meshStandardMaterial
              color="#ffee88"
              emissive="#ffee88"
              emissiveIntensity={5}
              toneMapped={false}
            />
          </mesh>
        </Float>
      ))}
    </Suspense>
  )
}
```

### Step 7: App with Canvas, Fog, and Controls

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'
import { DioramaScene } from './components/DioramaScene'

export default function App() {
  return (
    <Canvas
      shadows
      camera={{ position: [6, 4, 8], fov: 45 }}
      gl={{ antialias: true, toneMapping: 3 }} // ACESFilmicToneMapping
      dpr={[1, 2]}
    >
      {/* Fog for depth and atmosphere */}
      <fog attach="fog" args={['#2a1a3a', 12, 30]} />

      {/* Scene background color */}
      <color attach="background" args={['#1a1a2e']} />

      <DioramaScene />

      <OrbitControls
        enableDamping
        dampingFactor={0.05}
        minDistance={4}
        maxDistance={20}
        maxPolarAngle={Math.PI / 2.1}
        target={[0, 1, 0]}
      />
    </Canvas>
  )
}
```

### Step 8: Entry Point

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

### Run It

```bash
npm run dev
```

You should see a small campsite clearing with a campfire at center, tent to the side, trees ringing the clearing, warm lighting from the fire, a sunset-toned key light casting shadows, fog fading into the distance, and small floating fireflies for atmosphere. Drag to orbit, scroll to zoom.

To use real models: download assets from Kenney's Nature Kit or Survival Kit, run `gltfjsx` on each `.glb`, replace the placeholder components with the generated ones, and adjust positions/scales as needed.

---

## API Quick Reference

### Model Loading (drei)

| Function/Component | Description | Example |
|---------------------|-------------|---------|
| `useGLTF(url)` | Load a GLTF/GLB file, returns `{ nodes, materials, scene, animations }` | `const { nodes } = useGLTF('/model.glb')` |
| `useGLTF.preload(url)` | Start loading before component mounts | `useGLTF.preload('/model.glb')` |
| `useGLTF.setDecoderPath(path)` | Set Draco decoder location | `useGLTF.setDecoderPath('/draco/')` |
| `<primitive object={...}>` | Inject a Three.js object into the R3F tree | `<primitive object={scene} />` |
| `useTexture(urls)` | Load one or more textures | `const [color, normal] = useTexture([...])` |

### Lighting

| Component | Type | Key Props |
|-----------|------|-----------|
| `<ambientLight>` | Even fill | `intensity`, `color` |
| `<directionalLight>` | Parallel rays (sun) | `position`, `intensity`, `color`, `castShadow`, `shadow-*` |
| `<pointLight>` | Omnidirectional | `position`, `intensity`, `distance`, `decay`, `color` |
| `<spotLight>` | Cone | `position`, `angle`, `penumbra`, `intensity`, `castShadow` |
| `<hemisphereLight>` | Sky/ground gradient | `args={[skyColor, groundColor, intensity]}` |

### Shadows

| Prop | Applied To | Description |
|------|-----------|-------------|
| `shadows` | `<Canvas>` | Enable shadow maps globally |
| `castShadow` | Light or Mesh | Object casts shadows |
| `receiveShadow` | Mesh | Object receives shadows |
| `shadow-mapSize-width` | Light | Shadow map resolution (default 512) |
| `shadow-mapSize-height` | Light | Shadow map resolution (default 512) |
| `shadow-bias` | Light | Shadow depth bias (fix acne) |
| `shadow-normalBias` | Light | Normal-direction bias (fix acne, preferred) |
| `shadow-camera-*` | Directional Light | Orthographic frustum: `left`, `right`, `top`, `bottom`, `near`, `far` |

### Materials

| Material | Use Case | Key Props |
|----------|----------|-----------|
| `<meshStandardMaterial>` | General PBR | `color`, `roughness`, `metalness`, `map`, `normalMap`, `aoMap`, `emissive`, `emissiveIntensity`, `envMapIntensity` |
| `<meshPhysicalMaterial>` | Glass, clearcoat | All standard props + `transmission`, `ior`, `thickness`, `clearcoat`, `sheen` |
| `<meshBasicMaterial>` | Unlit / debug | `color`, `wireframe`, `opacity`, `transparent` |

### Environment & Atmosphere (drei)

| Component | Description | Key Props |
|-----------|-------------|-----------|
| `<Environment>` | HDR environment map for IBL | `preset`, `files`, `background`, `backgroundBlurriness`, `environmentIntensity` |
| `<ContactShadows>` | Ground contact shadow plane | `position`, `opacity`, `scale`, `blur`, `far`, `color` |
| `<AccumulativeShadows>` | Soft accumulated shadows | `temporal`, `frames`, `scale`, `opacity` |
| `<RandomizedLight>` | Jittered light for AccumulativeShadows | `amount`, `radius`, `ambient`, `position` |
| `<Stage>` | Quick scene setup (env + shadows + ground) | `intensity`, `environment`, `shadows`, `adjustCamera` |
| `<Center>` | Auto-center children at origin | `top`, `bottom`, `disableX`, `disableY`, `disableZ` |

### Fog

| Component | Description | Args |
|-----------|-------------|------|
| `<fog>` | Linear fog | `attach="fog" args={[color, near, far]}` |
| `<fogExp2>` | Exponential fog | `attach="fog" args={[color, density]}` |

### Compression Tools

| Tool | Command | Purpose |
|------|---------|---------|
| `gltfjsx` | `npx gltfjsx model.glb --types` | Generate typed React component from GLB |
| `gltf-transform draco` | `npx gltf-transform draco in.glb out.glb` | Draco-compress geometry |
| `gltf-transform ktx2` | `npx gltf-transform ktx2 in.glb out.glb` | Compress textures to KTX2 |
| `gltf-transform optimize` | `npx gltf-transform optimize in.glb out.glb` | Full optimization pass |

---

## Common Pitfalls

### 1. Loading the Same Model at Different Paths

`useGLTF` caches by URL. If you load `/models/tree.glb` in one component and `./models/tree.glb` in another, that's two separate network requests and two copies in memory. Same model, different string = no cache hit.

```tsx
// WRONG — different path strings, no cache sharing
function TreeA() {
  const { scene } = useGLTF('/models/tree.glb')
  return <primitive object={scene.clone()} />
}

function TreeB() {
  const { scene } = useGLTF('./models/tree.glb') // Different string!
  return <primitive object={scene.clone()} />
}

// RIGHT — same path everywhere, cache works correctly
const TREE_PATH = '/models/tree.glb'

function TreeA() {
  const { scene } = useGLTF(TREE_PATH)
  return <primitive object={scene.clone()} />
}

function TreeB() {
  const { scene } = useGLTF(TREE_PATH) // Cache hit
  return <primitive object={scene.clone()} />
}

useGLTF.preload(TREE_PATH)
```

Also note: if you render the same `scene` object in multiple places without `.clone()`, only the last one will be visible. Three.js objects can only have one parent. Clone or use `nodes/geometry` to share.

### 2. Missing Draco Decoder Setup

If your model was compressed with Draco and you don't configure the decoder, you get a cryptic error like `"THREE.GLTFLoader: No DRACOLoader instance provided."` Deep in the console. No obvious link to "you forgot a decoder."

```tsx
// WRONG — loading Draco-compressed model without decoder
function Model() {
  const { scene } = useGLTF('/models/character.glb') // Crashes if Draco-compressed
  return <primitive object={scene} />
}

// RIGHT — set decoder path before loading
useGLTF.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.5.7/')

function Model() {
  const { scene } = useGLTF('/models/character.glb') // Works
  return <primitive object={scene} />
}
```

Set the decoder path once, early in your app (e.g., in `main.tsx` or the top of your scene file). It only needs to be called once — it's global.

### 3. Forgetting Suspense Around useGLTF

`useGLTF` uses React's Suspense mechanism. Without a `<Suspense>` boundary, React throws an error and your entire app crashes.

```tsx
// WRONG — no Suspense boundary, React crashes
function App() {
  return (
    <Canvas>
      <MyModel />  {/* Uses useGLTF inside — will crash */}
    </Canvas>
  )
}

// RIGHT — wrap in Suspense
function App() {
  return (
    <Canvas>
      <Suspense fallback={null}>
        <MyModel />
      </Suspense>
    </Canvas>
  )
}
```

Pro tip: put one `<Suspense>` near the top of your Canvas children, wrapping everything that might load assets. You don't need one per model.

### 4. Texture Color Space Issues

Normal maps, roughness maps, metalness maps, and AO maps must be in **linear** color space. Base color (albedo) maps must be in **sRGB**. If you get this wrong, surfaces look washed out or overly contrasty.

```tsx
// WRONG — normal map interpreted as sRGB, lighting looks wrong
const normalMap = useTexture('/textures/normal.jpg')
// Three.js defaults some textures to sRGB

// RIGHT — explicitly set color space for non-color data
import * as THREE from 'three'

const normalMap = useTexture('/textures/normal.jpg')
normalMap.colorSpace = THREE.LinearSRGBColorSpace  // Not sRGB!

// For base color, Three.js usually gets this right automatically.
// But if colors look wrong, check:
const colorMap = useTexture('/textures/color.jpg')
colorMap.colorSpace = THREE.SRGBColorSpace  // Should be sRGB
```

When loading via `useGLTF`, the GLTF loader handles color spaces correctly based on the GLTF spec. This pitfall mainly hits you when loading textures manually with `useTexture`.

### 5. Shadow Acne from Wrong Bias Values

Shadow acne is a moire/striping pattern on shadow-receiving surfaces. It happens when the shadow map's depth precision causes surfaces to incorrectly shadow themselves.

```tsx
// WRONG — no bias, shadow acne everywhere
<directionalLight castShadow />

// WRONG — too much bias, shadows detach from objects ("peter panning")
<directionalLight castShadow shadow-bias={-0.05} />

// RIGHT — small normal bias, clean shadows
<directionalLight
  castShadow
  shadow-normalBias={0.02}
  shadow-mapSize-width={2048}
  shadow-mapSize-height={2048}
/>
```

Always start with `shadow-normalBias={0.02}`. If you still see acne, increase slightly. If shadows detach, decrease. Higher shadow map resolution also reduces acne.

### 6. Models Appearing Tiny or Huge

Different modeling tools use different unit conventions. Blender defaults to meters. Some tools use centimeters. Some artists model at arbitrary scales. A character might load as 0.01 units tall or 100 units tall.

```tsx
// WRONG — model is 100x too big, fills the screen
function Character() {
  const { scene } = useGLTF('/models/character.glb')
  return <primitive object={scene} />
}

// RIGHT — check scale, adjust as needed
function Character() {
  const { scene } = useGLTF('/models/character.glb')
  return <primitive object={scene} scale={0.01} />  // Scale down to fit
}
```

Convention: 1 Three.js unit = 1 meter. A character should be ~1.7 units tall. A tree ~3-5 units. A campfire ~0.5 units. If a model doesn't match, scale it on the `<primitive>` or the wrapping `<group>`.

Better long-term fix: normalize model scale in Blender or with `gltf-transform` before loading.

---

## Exercises

### Exercise 1: Load a Character Model with Proper Lighting

**Time:** 30–45 minutes

Download a free character model from Mixamo or Poly Pizza. Load it into an R3F scene with:

- Suspense boundary
- Three-point lighting rig (key, fill, rim)
- Ground plane that receives shadows
- The character casting shadows
- OrbitControls to inspect it

Hints:
- If using Mixamo, download as FBX and convert to GLB in Blender
- Run `gltfjsx` on the GLB to generate a typed component
- Characters from Mixamo are typically in centimeters — you'll need `scale={0.01}`
- Start with `shadow-normalBias={0.02}` on the directional light

**Stretch goal:** Add a `<pointLight>` at foot level to simulate bounce light from the ground.

### Exercise 2: Three-Point Lighting with Color Temperature Experiments

**Time:** 20–30 minutes

Build a scene with a single object (a sphere or loaded model) and a three-point lighting rig. Then experiment:

1. Warm key + cool fill (sunset mood)
2. Cool key + warm fill (moonlight with campfire)
3. Both warm (cozy interior)
4. Both cool (clinical/sci-fi)

For each setup, change only the `color` prop on your lights. Keep intensities the same. Notice how dramatically the mood shifts with just color changes.

Hints:
- Warm colors: `#ffddaa`, `#ffaa55`, `#ff8844`
- Cool colors: `#aabbdd`, `#8899cc`, `#6677aa`
- Add `<Environment preset="studio" environmentIntensity={0.2} />` for subtle reflections
- Use a roughness of 0.4-0.6 on the material so reflections are visible

**Stretch goal:** Build a simple UI (drei `<Html>` or regular DOM) with color pickers to adjust light colors in real time.

### Exercise 3: Multi-Model Scene with Environment and Fog

**Time:** 45–60 minutes

Build a complete scene with at least 3 different models from free sources:

1. Download 3 models from Kenney or Poly Pizza (e.g., a building, a vehicle, and a tree)
2. Load all three with `useGLTF` and a shared `<Suspense>` boundary
3. Set up a ground plane with a material
4. Add an `<Environment>` preset for ambient lighting
5. Add one `<directionalLight>` with shadows
6. Add `<ContactShadows>` for grounding
7. Add `<fog>` with a color that matches your environment
8. Frame the scene with intentional camera position and FOV

Hints:
- Put all model paths in a constants file and preload them all at module scope
- Use `<Center>` on individual models if their origins are offset
- Fog color should be close to your background/sky color
- Keep fog `near` past your closest object, `far` at the edge of your visible scene

**Stretch goal:** Export a custom model from Blender (even a simple one — a rock, a fence, a crate). Run it through `gltf-transform optimize` with Draco compression. Load it in your scene alongside the free assets. Compare the file size before and after compression.

### Exercise 4: Blender to R3F Pipeline (Stretch)

**Time:** 60–90 minutes

Walk through the complete asset pipeline end to end:

1. Create or download a model in Blender
2. Set up PBR materials in Blender (base color, roughness, metalness at minimum)
3. Export as GLB from Blender (File > Export > glTF 2.0, format Binary)
4. Optimize with `gltf-transform`: `npx gltf-transform optimize model.glb model-opt.glb --compress draco`
5. Generate a component: `npx gltfjsx model-opt.glb --types`
6. Load in R3F with proper lighting, shadows, and environment

Compare file sizes at each step. Check that materials transferred correctly. This is the pipeline you'll use for every custom asset in a real game.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [drei Documentation — Loaders](https://drei.docs.pmnd.rs/) | Official Docs | Reference for `useGLTF`, `useTexture`, `useKTX2`, and all loader helpers. |
| [gltfjsx Repository](https://github.com/pmndrs/gltfjsx) | Tool | Source, flags, examples. Bookmark this — you'll use it constantly. |
| [glTF Specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html) | Spec | Dense but authoritative. Skim the material model section. |
| [gltf-transform Documentation](https://gltf-transform.dev/) | Tool Docs | CLI and programmatic API for GLTF optimization. |
| [Polyhaven](https://polyhaven.com/) | Assets | Free HDRIs, textures, and models. CC0 license. Your first stop. |
| [Kenney Assets](https://kenney.nl/assets) | Assets | Thousands of free game assets. Consistent low-poly style. CC0. |
| [Three.js Materials Docs](https://threejs.org/docs/#api/en/materials/MeshStandardMaterial) | Reference | Every property on MeshStandardMaterial explained. |
| [Filament PBR Guide](https://google.github.io/filament/Materials.html) | Deep Dive | Google's guide to PBR material models. Best explanation of the math if you want to go deep. |

---

## Key Takeaways

1. **GLTF/GLB is the standard format for web 3D.** Don't use FBX or OBJ unless forced to. Everything in the Three.js ecosystem is built around GLTF.

2. **gltfjsx is your best friend for loading models.** Run it on every GLB to get a typed, customizable React component. Edit the generated code freely — it's yours.

3. **Compress everything.** Draco for geometry (10-20x smaller). KTX2/Basis for textures (4-6x GPU memory savings). Uncompressed models are a bug, not a feature.

4. **PBR materials work because they model reality.** Understand the five core maps (baseColor, metalness, roughness, normal, AO) and you can tweak any material to look right.

5. **Lighting creates mood, not just visibility.** Three-point rigs, color temperature, and environment maps are the tools. Warm key + cool fill is your default starting point.

6. **Shadows require three things:** `shadows` on Canvas, `castShadow` on lights, and `castShadow`/`receiveShadow` on meshes. Use `ContactShadows` from drei for cheap, good-looking ground contact shadows. Keep the shadow camera frustum tight.

7. **Environment maps are the fastest path to good-looking scenes.** One `<Environment preset="sunset" />` replaces hours of manual light placement. Combine with a single shadow-casting directional light for the best of both worlds.

8. **Scene composition is about layers and focal points.** Foreground/midground/background. Contrast draws the eye. Fog adds depth. Camera position and FOV shape the mood.

---

## What's Next?

You can now load assets, light them, and compose complete scenes. Your diorama looks good standing still. But games don't stand still.

**[Module 3: State Management for Games](module-03-state-management-for-games.md)** teaches you how to manage game state — health, inventory, score, game phases — without triggering expensive re-renders. You'll learn Zustand (the state manager built by the same team behind R3F), the subscribe-with-selector pattern for frame-rate-safe reads, and how to architect state so your game logic stays clean as complexity grows.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)