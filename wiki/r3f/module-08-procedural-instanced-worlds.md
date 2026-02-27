# Module 8: Procedural & Instanced Worlds

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 8–12 hours
**Prerequisites:** [Module 7: Post-Processing & VFX](module-07-post-processing-vfx.md)

---

## Overview

You're about to build a world that doesn't exist until the player walks into it. No hand-placed assets, no pre-baked terrain files, no level designers pulling overtime. Just algorithms, noise functions, and clever instancing — and the result will be an infinite landscape that stretches to the horizon, generates itself on demand, and runs at 60fps with thousands of trees and grass blades swaying in the wind.

This is one of the most satisfying modules in the entire roadmap. Everything you've learned so far — performance patterns, shaders, instancing, post-processing — converges here. You'll generate heightmap terrain from noise, color it by biome, scatter vegetation using Poisson disk sampling, animate grass with vertex shaders, and build a chunk manager that loads and unloads terrain tiles as the camera moves. It's the foundation for any open-world game, survival sim, or exploration experience.

The mini-project is an infinite procedural landscape. Endless terrain with biome coloring, instanced trees and grass with wind shaders, chunked loading and unloading, and fog to hide the seams. By the end you'll have something that looks like a real game world — and you'll understand exactly how every piece of it works.

---

## 1. Why Procedural

### Hand-Crafting Doesn't Scale

Imagine building a 10km x 10km game world by hand. Every hill, every valley, every tree placement — done manually in a 3D editor. For a AAA studio with 200 environment artists, sure. For you, building a game solo or with a small team? Absolutely not. You'd spend months on terrain alone and never ship anything.

Procedural generation solves this by trading artist time for CPU time. Instead of placing every vertex and every tree, you write algorithms that do it for you. The algorithms run in milliseconds. They can produce infinite variety. And when you want to tweak the world — make the mountains taller, add more forests, change the biome distribution — you change a parameter, not a thousand assets.

### What "Procedural" Actually Means

Procedural doesn't mean random. Random is noise. Procedural is *controlled* noise — patterns that look organic and natural but are fully deterministic. Give the same seed to a procedural generator and you get the exact same world every time. This is critical for multiplayer (everyone sees the same terrain) and for saving game state (you only need to store the seed, not the entire world).

### The Hall of Fame

These games all run on procedural generation:

- **Minecraft** — Block worlds generated from 3D noise. Arguably the most influential procedural system ever built. Every biome, cave, and mountain comes from layered noise functions.
- **No Man's Sky** — 18 quintillion planets, each generated from a seed. Terrain, flora, fauna, colors — all procedural.
- **Terraria** — 2D world generation with biomes, ore distribution, cave systems.
- **Valheim** — Procedural terrain with handcrafted boss arenas stitched in.
- **Deep Rock Galactic** — Procedural cave systems with voxel destruction.

The common thread: small teams building enormous worlds. That's the power of procedural generation.

### What You'll Build

Your infinite landscape will use:
- **Noise functions** to define the terrain heightmap
- **Rules** to assign biome colors based on height and slope
- **Scattering algorithms** to place vegetation
- **Vertex shaders** to animate wind
- **Chunked loading** to keep only nearby terrain in memory

Every one of these is a transferable skill. The same noise functions that make terrain also make clouds, water, fire, and cave systems. The same instancing patterns that render 10,000 grass blades render 10,000 bullets, particles, or enemies.

---

## 2. Noise Functions

### Why Not Math.random()

Call `Math.random()` for 100 adjacent pixels and you get static — like TV snow. There's no relationship between neighboring values. A pixel at position 50 has no idea what position 51 looks like.

Noise functions fix this. They produce **coherent randomness** — values that vary smoothly across space. Nearby inputs produce nearby outputs, creating organic-looking gradients, hills, and valleys. This is what makes noise useful for terrain: adjacent points on the heightmap have similar (but not identical) heights, producing smooth slopes instead of spiky chaos.

### The Big Three

**Perlin Noise** — Created by Ken Perlin in 1983 for the movie *Tron*. Produces smooth, organic-looking gradients. The classic. Has some directional artifacts aligned to grid axes, but these are rarely noticeable.

**Simplex Noise** — Also by Ken Perlin, designed as an improvement over classic Perlin. Fewer artifacts, cheaper to compute in higher dimensions, and has a nicer gradient distribution. This is what you should use.

**Value Noise** — The simplest: random values at grid points, interpolated between them. Cheap but blobby-looking. Good enough for some use cases but simplex is better for terrain.

### Frequency, Amplitude, and Octaves

A single layer of noise is boring. Real terrain has large-scale features (mountain ranges) with medium-scale detail (ridges) and small-scale roughness (rocks). You achieve this by layering noise at different frequencies — a technique called **Fractal Brownian Motion (FBM)** or simply **octaves**.

Each octave doubles the frequency (smaller features) and halves the amplitude (less influence):

```
Octave 1: frequency = 1,   amplitude = 1.0   (big hills)
Octave 2: frequency = 2,   amplitude = 0.5   (medium bumps)
Octave 3: frequency = 4,   amplitude = 0.25  (small roughness)
Octave 4: frequency = 8,   amplitude = 0.125 (fine detail)
```

The ratio between successive amplitudes is called **persistence** (or **gain**). A persistence of 0.5 means each octave has half the amplitude of the previous one. Lower persistence = smoother terrain. Higher persistence = rougher terrain.

The ratio between successive frequencies is called **lacunarity**. Typically 2.0 (frequency doubles each octave).

### The simplex-noise Package

```bash
npm install simplex-noise
```

```tsx
import { createNoise2D } from 'simplex-noise'

// Create a noise function (optionally seeded with alea for determinism)
const noise2D = createNoise2D()

// Returns values between -1 and 1
const value = noise2D(x * frequency, z * frequency)
```

For seeded deterministic generation:

```bash
npm install alea
```

```tsx
import { createNoise2D } from 'simplex-noise'
import alea from 'alea'

const prng = alea('my-world-seed')
const noise2D = createNoise2D(prng)
// Same seed = same world, every time
```

### FBM Implementation

This is the function you'll use for everything terrain-related:

```tsx
import { createNoise2D } from 'simplex-noise'

const noise2D = createNoise2D()

function fbm(
  x: number,
  z: number,
  octaves: number = 6,
  persistence: number = 0.5,
  lacunarity: number = 2.0,
  scale: number = 0.01
): number {
  let value = 0
  let amplitude = 1
  let frequency = scale
  let maxValue = 0 // For normalization

  for (let i = 0; i < octaves; i++) {
    value += noise2D(x * frequency, z * frequency) * amplitude
    maxValue += amplitude
    amplitude *= persistence
    frequency *= lacunarity
  }

  return value / maxValue // Normalize to roughly [-1, 1]
}
```

The `scale` parameter controls how zoomed in you are. Smaller scale = larger features. A scale of `0.01` means you need to travel 100 units before the noise pattern repeats one full cycle. For terrain, start with something in the `0.005`–`0.02` range and adjust by eye.

### Visualizing Noise

Before using noise for terrain, you should see it. Here's a quick debug component that renders a noise texture to a plane:

```tsx
import { useMemo } from 'react'
import { createNoise2D } from 'simplex-noise'
import * as THREE from 'three'

function NoisePreview({ size = 128 }: { size?: number }) {
  const texture = useMemo(() => {
    const noise2D = createNoise2D()
    const data = new Uint8Array(size * size * 4)

    for (let y = 0; y < size; y++) {
      for (let x = 0; x < size; x++) {
        const value = (noise2D(x * 0.05, y * 0.05) + 1) * 0.5 // Map to 0-1
        const idx = (y * size + x) * 4
        const byte = Math.floor(value * 255)
        data[idx] = byte     // R
        data[idx + 1] = byte // G
        data[idx + 2] = byte // B
        data[idx + 3] = 255  // A
      }
    }

    const tex = new THREE.DataTexture(data, size, size, THREE.RGBAFormat)
    tex.needsUpdate = true
    return tex
  }, [size])

  return (
    <mesh rotation={[-Math.PI / 2, 0, 0]}>
      <planeGeometry args={[10, 10]} />
      <meshBasicMaterial map={texture} />
    </mesh>
  )
}
```

---

## 3. Heightmap Terrain

### The Core Idea

A heightmap terrain is a flat grid of vertices where each vertex's Y position is set by a noise value. You start with a `PlaneGeometry`, which gives you an evenly-spaced grid of vertices, then you displace each vertex upward or downward based on the noise function evaluated at that vertex's X and Z coordinates.

### Creating the Geometry

```tsx
import { useMemo } from 'react'
import * as THREE from 'three'
import { createNoise2D } from 'simplex-noise'

const noise2D = createNoise2D()

function fbm(x: number, z: number): number {
  let value = 0
  let amplitude = 1
  let frequency = 0.008
  let maxValue = 0

  for (let i = 0; i < 6; i++) {
    value += noise2D(x * frequency, z * frequency) * amplitude
    maxValue += amplitude
    amplitude *= 0.5
    frequency *= 2.0
  }

  return value / maxValue
}

interface TerrainChunkProps {
  chunkX: number
  chunkZ: number
  chunkSize: number
  segments: number
}

function TerrainChunk({ chunkX, chunkZ, chunkSize, segments }: TerrainChunkProps) {
  const geometry = useMemo(() => {
    const geo = new THREE.PlaneGeometry(chunkSize, chunkSize, segments, segments)

    // PlaneGeometry is created in XY plane — rotate it to XZ
    geo.rotateX(-Math.PI / 2)

    const positions = geo.attributes.position
    const worldOffsetX = chunkX * chunkSize
    const worldOffsetZ = chunkZ * chunkSize

    for (let i = 0; i < positions.count; i++) {
      const localX = positions.getX(i)
      const localZ = positions.getZ(i)

      // World-space coordinates for noise sampling
      const worldX = localX + worldOffsetX
      const worldZ = localZ + worldOffsetZ

      // Displace vertex height
      const height = fbm(worldX, worldZ) * 30 // Amplitude of 30 units
      positions.setY(i, height)
    }

    // CRITICAL: recompute normals after displacement
    geo.computeVertexNormals()

    return geo
  }, [chunkX, chunkZ, chunkSize, segments])

  return (
    <mesh
      geometry={geometry}
      position={[chunkX * chunkSize, 0, chunkZ * chunkSize]}
    >
      <meshStandardMaterial color="#4a8f3f" flatShading />
    </mesh>
  )
}
```

### Why PlaneGeometry and Not a Custom BufferGeometry

You could build the vertex buffer from scratch, but `PlaneGeometry` gives you a properly indexed, UV-mapped grid with no effort. You're going to modify the vertices anyway — there's no reason to do the index math yourself. Take the free geometry and displace it.

### The Rotation Trick

`PlaneGeometry` is created in the XY plane (facing the camera). For terrain, you want it in the XZ plane (facing up). The cleanest way is to call `geo.rotateX(-Math.PI / 2)` before modifying vertices. This rotates the geometry data itself, so after rotation, the Y attribute is the one pointing up.

### Segment Count

The `segments` parameter controls terrain resolution. More segments = more vertices = smoother terrain but more expensive to generate and render.

| Segments | Vertices | Triangles | Use Case |
|----------|----------|-----------|----------|
| 32 | 1,089 | 2,048 | Low detail, far chunks |
| 64 | 4,225 | 8,192 | Medium detail |
| 128 | 16,641 | 32,768 | High detail, close chunks |
| 256 | 66,049 | 131,072 | Excessive for most cases |

For a 100x100 unit chunk, 64 segments gives you roughly 1.5-meter resolution between vertices. That's enough to look smooth at close range. Start there and adjust based on your performance budget.

### Recomputing Normals

After displacing vertices, the normals are still pointing straight up from the original flat plane. You **must** call `geo.computeVertexNormals()` to recalculate them based on the new vertex positions. Without this, lighting will look completely wrong — flat and uniform instead of showing slopes and hills.

```tsx
// After modifying all vertex positions:
geo.computeVertexNormals()
```

This is a single line but forgetting it is one of the most common terrain bugs. Your terrain will look like it has no depth, like a texture painted on a flat surface. If your terrain looks "flat" despite having obvious height variation, missing normals is the first thing to check.

---

## 4. Terrain Coloring

### Height-Based Biome Coloring

Real terrain has different appearances at different elevations: water at the bottom, sand along the shore, grass in the lowlands, rock on the mountains, snow at the peaks. You can replicate this by assigning vertex colors based on height.

### The Vertex Color Pattern

Three.js meshes can have a `color` attribute on their geometry that stores a per-vertex color. When you use `vertexColors: true` on the material, these colors are multiplied with the material's base color.

```tsx
function TerrainChunk({ chunkX, chunkZ, chunkSize, segments }: TerrainChunkProps) {
  const geometry = useMemo(() => {
    const geo = new THREE.PlaneGeometry(chunkSize, chunkSize, segments, segments)
    geo.rotateX(-Math.PI / 2)

    const positions = geo.attributes.position
    const worldOffsetX = chunkX * chunkSize
    const worldOffsetZ = chunkZ * chunkSize

    // Create color attribute
    const colors = new Float32Array(positions.count * 3)

    for (let i = 0; i < positions.count; i++) {
      const localX = positions.getX(i)
      const localZ = positions.getZ(i)
      const worldX = localX + worldOffsetX
      const worldZ = localZ + worldOffsetZ

      const height = fbm(worldX, worldZ) * 30
      positions.setY(i, height)

      // Assign biome color based on height
      const color = getBiomeColor(height)
      colors[i * 3] = color.r
      colors[i * 3 + 1] = color.g
      colors[i * 3 + 2] = color.b
    }

    geo.setAttribute('color', new THREE.BufferAttribute(colors, 3))
    geo.computeVertexNormals()

    return geo
  }, [chunkX, chunkZ, chunkSize, segments])

  return (
    <mesh
      geometry={geometry}
      position={[chunkX * chunkSize, 0, chunkZ * chunkSize]}
    >
      <meshStandardMaterial vertexColors />
    </mesh>
  )
}
```

### Biome Color Function

```tsx
const WATER_COLOR = new THREE.Color('#2a6fa8')
const SAND_COLOR = new THREE.Color('#c8b76e')
const GRASS_COLOR = new THREE.Color('#4a8f3f')
const FOREST_COLOR = new THREE.Color('#2d6b2e')
const ROCK_COLOR = new THREE.Color('#6b6b6b')
const SNOW_COLOR = new THREE.Color('#e8e8f0')

// Temporary color to avoid allocating in the loop
const tempColor = new THREE.Color()

function getBiomeColor(height: number): THREE.Color {
  if (height < -1) return tempColor.copy(WATER_COLOR)
  if (height < 1) return tempColor.copy(SAND_COLOR)
  if (height < 8) return tempColor.copy(GRASS_COLOR)
  if (height < 14) return tempColor.copy(FOREST_COLOR)
  if (height < 22) return tempColor.copy(ROCK_COLOR)
  return tempColor.copy(SNOW_COLOR)
}
```

### Smooth Transitions with Lerp

Hard biome boundaries look artificial. Real terrain transitions gradually. Use `THREE.Color.lerp` to blend between biome colors:

```tsx
function getBiomeColorSmooth(height: number): THREE.Color {
  if (height < -1) {
    return tempColor.copy(WATER_COLOR)
  } else if (height < 1) {
    const t = (height - (-1)) / 2 // 0 at h=-1, 1 at h=1
    return tempColor.copy(WATER_COLOR).lerp(SAND_COLOR, t)
  } else if (height < 3) {
    const t = (height - 1) / 2
    return tempColor.copy(SAND_COLOR).lerp(GRASS_COLOR, t)
  } else if (height < 10) {
    const t = (height - 3) / 7
    return tempColor.copy(GRASS_COLOR).lerp(FOREST_COLOR, t)
  } else if (height < 16) {
    const t = (height - 10) / 6
    return tempColor.copy(FOREST_COLOR).lerp(ROCK_COLOR, t)
  } else if (height < 24) {
    const t = (height - 16) / 8
    return tempColor.copy(ROCK_COLOR).lerp(SNOW_COLOR, t)
  } else {
    return tempColor.copy(SNOW_COLOR)
  }
}
```

### Slope-Based Variation

Steep slopes should show rock regardless of height. Grass doesn't grow on cliff faces. You can estimate slope from the vertex normal — a normal pointing straight up (y = 1) is flat ground, and normals with lower y values indicate steeper slopes.

```tsx
// After computing vertex normals, read them back for slope-based coloring
function getColorWithSlope(height: number, normalY: number): THREE.Color {
  const baseColor = getBiomeColorSmooth(height)

  // If slope is steep (normal.y < 0.7 means > ~45 degrees), blend toward rock
  if (normalY < 0.7 && height > 1) {
    const slopeFactor = 1 - (normalY - 0.3) / 0.4 // 0 at 0.7, 1 at 0.3
    const clampedFactor = Math.max(0, Math.min(1, slopeFactor))
    baseColor.lerp(ROCK_COLOR, clampedFactor * 0.8)
  }

  return baseColor
}
```

To use slope-based coloring, you need to compute normals first, then do a second pass over vertices to set colors. Alternatively, compute normals manually per-vertex during the height pass by sampling neighboring heights and computing the cross product.

### Vertex Colors vs Shader-Based Coloring

Vertex colors are simple and fast — the GPU interpolates them automatically between vertices. The downside is that your color resolution is limited to your vertex density. If your mesh has one vertex every 1.5 meters, biome boundaries will be blocky at that resolution.

For higher-quality coloring, you'd write a fragment shader that samples the noise function per-pixel and determines the biome color on the GPU. That's more complex but gives pixel-perfect biome boundaries regardless of mesh resolution. For this module, vertex colors are more than sufficient. You'll work with custom shaders more in advanced topics.

---

## 5. InstancedMesh Deep Dive

### Review: What InstancedMesh Does

`InstancedMesh` renders many copies of the same geometry and material in a single draw call. Instead of 1,000 separate meshes (1,000 draw calls), you get one mesh rendered 1,000 times with different transforms. This is the single most important performance tool for open-world rendering.

You first encountered `InstancedMesh` in Module 1. Now you're going to push it to its limits — thousands of instances per chunk, with per-instance color and dynamic counts.

### The Dummy Object3D Pattern

Each instance needs a 4x4 transformation matrix (position, rotation, scale). The standard pattern is to use a temporary `Object3D` as a calculator: set its position/rotation/scale, call `updateMatrix()`, then copy that matrix into the instance buffer.

```tsx
import { useRef, useMemo, useEffect } from 'react'
import * as THREE from 'three'

const dummy = new THREE.Object3D()

interface TreeInstancesProps {
  positions: Array<[number, number, number]>
  scales?: Array<number>
}

function TreeInstances({ positions, scales }: TreeInstancesProps) {
  const meshRef = useRef<THREE.InstancedMesh>(null)

  useEffect(() => {
    if (!meshRef.current) return

    for (let i = 0; i < positions.length; i++) {
      const [x, y, z] = positions[i]
      const scale = scales?.[i] ?? 1

      dummy.position.set(x, y, z)
      dummy.rotation.set(0, Math.random() * Math.PI * 2, 0) // Random Y rotation
      dummy.scale.setScalar(scale)
      dummy.updateMatrix()

      meshRef.current.setMatrixAt(i, dummy.matrix)
    }

    // CRITICAL: Tell Three.js the instance matrices have changed
    meshRef.current.instanceMatrix.needsUpdate = true
  }, [positions, scales])

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, positions.length]}>
      <coneGeometry args={[0.5, 2, 6]} />
      <meshStandardMaterial color="#2d6b2e" />
    </instancedMesh>
  )
}
```

### The args Triplet

The `args` for `<instancedMesh>` are `[geometry, material, count]`. When you provide geometry and material as children (the R3F way), pass `undefined` for the first two:

```tsx
<instancedMesh args={[undefined, undefined, 1000]}>
  <coneGeometry args={[0.5, 2, 6]} />
  <meshStandardMaterial color="green" />
</instancedMesh>
```

The `count` is the **maximum** number of instances. You can render fewer by setting `meshRef.current.count = actualCount`, but you can't exceed the initial count without recreating the mesh.

### Per-Instance Color

By default, all instances share the material's color. For variation — lighter trees, darker trees, slightly different greens — you need the `instanceColor` attribute:

```tsx
useEffect(() => {
  if (!meshRef.current) return

  const color = new THREE.Color()

  for (let i = 0; i < positions.length; i++) {
    const [x, y, z] = positions[i]

    // Set transform
    dummy.position.set(x, y, z)
    dummy.rotation.set(0, Math.random() * Math.PI * 2, 0)
    dummy.scale.setScalar(0.8 + Math.random() * 0.4)
    dummy.updateMatrix()
    meshRef.current.setMatrixAt(i, dummy.matrix)

    // Set per-instance color (slight green variation)
    const greenVariation = 0.3 + Math.random() * 0.3
    color.setRGB(0.1, greenVariation, 0.05)
    meshRef.current.setColorAt(i, color)
  }

  meshRef.current.instanceMatrix.needsUpdate = true
  if (meshRef.current.instanceColor) {
    meshRef.current.instanceColor.needsUpdate = true
  }
}, [positions])
```

### Dynamic Instance Count

You allocated space for `maxCount` instances, but you might not need all of them. Instead of recreating the mesh, just change the count:

```tsx
// Only render the first 500 instances
meshRef.current.count = 500
```

This is useful for LOD — reduce instance count for far-away chunks rather than disposing and recreating the entire `InstancedMesh`.

### Bounding Box and Frustum Culling

By default, Three.js frustum-culls the entire `InstancedMesh` as one object. If the bounding box is visible, all instances render. If it's not, none render. For large worlds, you should compute an accurate bounding box after setting all instance matrices:

```tsx
meshRef.current.computeBoundingBox()
meshRef.current.computeBoundingSphere()
```

If your instances span a huge area, the bounding box will always intersect the frustum and you'll never get culling benefits. The solution is to split instances per chunk — each chunk's `InstancedMesh` has a tight bounding box and can be culled independently.

---

## 6. Vegetation Scattering

### The Problem with Random Placement

If you scatter trees using `Math.random()` for X and Z coordinates, you get clumps and gaps. Some spots will have five trees on top of each other. Other areas will be suspiciously empty. Random isn't uniform.

### Poisson Disk Sampling

Poisson disk sampling generates points that are randomly distributed but with a minimum distance between them. No clumps, no overlaps, just a natural-looking spread — like how trees actually grow (they compete for light and water, so they don't crowd each other).

Here's a simple 2D Poisson disk sampler:

```tsx
function poissonDiskSampling(
  width: number,
  height: number,
  minDistance: number,
  maxAttempts: number = 30
): Array<[number, number]> {
  const cellSize = minDistance / Math.SQRT2
  const gridWidth = Math.ceil(width / cellSize)
  const gridHeight = Math.ceil(height / cellSize)
  const grid: (number | null)[] = new Array(gridWidth * gridHeight).fill(null)
  const points: Array<[number, number]> = []
  const active: number[] = []

  function gridIndex(x: number, y: number): number {
    const gx = Math.floor(x / cellSize)
    const gy = Math.floor(y / cellSize)
    return gy * gridWidth + gx
  }

  // Start with a random point
  const startX = Math.random() * width
  const startY = Math.random() * height
  points.push([startX, startY])
  grid[gridIndex(startX, startY)] = 0
  active.push(0)

  while (active.length > 0) {
    const activeIdx = Math.floor(Math.random() * active.length)
    const pointIdx = active[activeIdx]
    const [px, py] = points[pointIdx]
    let found = false

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const angle = Math.random() * Math.PI * 2
      const distance = minDistance + Math.random() * minDistance
      const nx = px + Math.cos(angle) * distance
      const ny = py + Math.sin(angle) * distance

      if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue

      const gx = Math.floor(nx / cellSize)
      const gy = Math.floor(ny / cellSize)
      let tooClose = false

      // Check neighboring grid cells
      for (let dy = -2; dy <= 2 && !tooClose; dy++) {
        for (let dx = -2; dx <= 2 && !tooClose; dx++) {
          const checkX = gx + dx
          const checkY = gy + dy
          if (checkX < 0 || checkX >= gridWidth || checkY < 0 || checkY >= gridHeight) continue
          const neighbor = grid[checkY * gridWidth + checkX]
          if (neighbor !== null) {
            const [ox, oy] = points[neighbor]
            const dist = Math.hypot(nx - ox, ny - oy)
            if (dist < minDistance) tooClose = true
          }
        }
      }

      if (!tooClose) {
        const newIdx = points.length
        points.push([nx, ny])
        grid[gridIndex(nx, ny)] = newIdx
        active.push(newIdx)
        found = true
        break
      }
    }

    if (!found) {
      active.splice(activeIdx, 1)
    }
  }

  return points
}
```

### Scatter Rules

Don't put trees in the ocean. Don't put trees on cliff faces. Vary grass density by altitude. These rules make your scattering look believable instead of like a random texture.

```tsx
interface ScatterConfig {
  minHeight: number       // Don't place below this (e.g., water level)
  maxHeight: number       // Don't place above this (e.g., snow line)
  maxSlope: number        // Maximum terrain slope (0-1, where 1 = vertical)
  density: number         // Minimum distance between instances
}

const TREE_CONFIG: ScatterConfig = {
  minHeight: 1.5,         // Above sand line
  maxHeight: 18,          // Below snow line
  maxSlope: 0.7,          // No trees on steep cliffs
  density: 4,             // 4 units minimum between trees
}

const GRASS_CONFIG: ScatterConfig = {
  minHeight: 0.5,
  maxHeight: 14,
  maxSlope: 0.8,
  density: 1.5,
}
```

### Combining Scattering with Terrain

The key insight: scatter points in 2D (XZ plane), then sample the terrain heightmap to get the correct Y position for each instance. This ensures trees sit on the terrain surface instead of floating or buried.

```tsx
function scatterOnTerrain(
  chunkX: number,
  chunkZ: number,
  chunkSize: number,
  config: ScatterConfig,
  heightFn: (x: number, z: number) => number,
  slopeFn: (x: number, z: number) => number
): Array<[number, number, number]> {
  // Generate 2D scatter points within the chunk
  const points2D = poissonDiskSampling(chunkSize, chunkSize, config.density)

  const worldOffsetX = chunkX * chunkSize - chunkSize / 2
  const worldOffsetZ = chunkZ * chunkSize - chunkSize / 2

  const positions: Array<[number, number, number]> = []

  for (const [localX, localZ] of points2D) {
    const worldX = localX + worldOffsetX
    const worldZ = localZ + worldOffsetZ

    const height = heightFn(worldX, worldZ)
    const slope = slopeFn(worldX, worldZ)

    // Apply scatter rules
    if (height < config.minHeight || height > config.maxHeight) continue
    if (slope > config.maxSlope) continue

    positions.push([worldX, height, worldZ])
  }

  return positions
}
```

### Estimating Slope from Noise

You can approximate slope by sampling the height at nearby points and computing the finite difference:

```tsx
function getSlope(x: number, z: number, epsilon: number = 0.5): number {
  const h = fbm(x, z) * 30
  const hx = fbm(x + epsilon, z) * 30
  const hz = fbm(x, z + epsilon) * 30

  const dx = (hx - h) / epsilon
  const dz = (hz - h) / epsilon

  // Slope magnitude (0 = flat, higher = steeper)
  return Math.sqrt(dx * dx + dz * dz)
}
```

A slope value of 0 is perfectly flat. Values above ~1.5 are quite steep. You can normalize or threshold this however suits your scatter rules.

---

## 7. Wind Animation

### The Goal

Static grass and trees look dead. Even subtle movement — a gentle sway, a ripple through a field — brings a scene to life. You'll achieve this with a vertex shader that displaces vertices over time.

### The Key Principles

1. **Only tips move, roots stay fixed.** A grass blade's base is planted in the ground. Displacement should scale with vertex height — zero at the bottom, maximum at the top.

2. **Spatial variation.** If every grass blade sways identically, it looks mechanical, like an animation loop. Use world position to offset the phase of the wave, so nearby blades are similar but not identical. This creates a ripple effect, like wind rolling across a field.

3. **Time-based.** Pass a `uTime` uniform that increments each frame. The wave function uses time to create continuous motion.

### Grass Wind Shader

You'll use `onBeforeCompile` to inject wind displacement into the standard material's vertex shader. This preserves lighting, shadows, and all material features while adding your custom displacement.

```tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

function useWindMaterial(color: string = '#4a8f3f') {
  const materialRef = useRef<THREE.MeshStandardMaterial>(null)
  const uniformsRef = useRef({ uTime: { value: 0 } })

  useFrame((_, delta) => {
    uniformsRef.current.uTime.value += delta
  })

  const onBeforeCompile = (shader: THREE.WebGLProgramParameters) => {
    shader.uniforms.uTime = uniformsRef.current.uTime

    // Inject uniform declaration
    shader.vertexShader = shader.vertexShader.replace(
      '#include <common>',
      /* glsl */ `
        #include <common>
        uniform float uTime;
      `
    )

    // Inject displacement after the vertex position is computed
    shader.vertexShader = shader.vertexShader.replace(
      '#include <begin_vertex>',
      /* glsl */ `
        #include <begin_vertex>

        // Get world position for spatial variation
        vec4 worldPos = modelMatrix * vec4(position, 1.0);

        // Height factor: 0 at base, 1 at top
        // Assumes grass/tree model has base at y=0, tip at max y
        float heightFactor = clamp(position.y / 2.0, 0.0, 1.0);
        heightFactor = heightFactor * heightFactor; // Quadratic — tips move more

        // Wind displacement
        float windStrength = 0.3;
        float windSpeed = 1.5;
        float windFrequency = 0.5;

        // Two overlapping sine waves for organic motion
        float wave1 = sin(worldPos.x * windFrequency + uTime * windSpeed) * 0.6;
        float wave2 = sin(worldPos.z * windFrequency * 0.7 + uTime * windSpeed * 1.3) * 0.4;
        float wind = (wave1 + wave2) * windStrength * heightFactor;

        transformed.x += wind;
        transformed.z += wind * 0.3; // Slight Z movement for depth
      `
    )
  }

  return { materialRef, onBeforeCompile, color }
}
```

### Using the Wind Material with InstancedMesh

```tsx
function GrassInstances({
  positions,
}: {
  positions: Array<[number, number, number]>
}) {
  const meshRef = useRef<THREE.InstancedMesh>(null)
  const { onBeforeCompile } = useWindMaterial()

  useEffect(() => {
    if (!meshRef.current) return

    const color = new THREE.Color()

    for (let i = 0; i < positions.length; i++) {
      const [x, y, z] = positions[i]

      dummy.position.set(x, y, z)
      dummy.rotation.set(0, Math.random() * Math.PI * 2, 0)
      dummy.scale.set(
        0.8 + Math.random() * 0.4,
        0.6 + Math.random() * 0.8,
        0.8 + Math.random() * 0.4
      )
      dummy.updateMatrix()
      meshRef.current.setMatrixAt(i, dummy.matrix)

      // Vary green tones
      color.setHSL(0.28 + Math.random() * 0.06, 0.6 + Math.random() * 0.2, 0.3 + Math.random() * 0.15)
      meshRef.current.setColorAt(i, color)
    }

    meshRef.current.instanceMatrix.needsUpdate = true
    if (meshRef.current.instanceColor) {
      meshRef.current.instanceColor.needsUpdate = true
    }
  }, [positions])

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, positions.length]}>
      <coneGeometry args={[0.15, 0.6, 4, 1]} />
      <meshStandardMaterial
        vertexColors
        onBeforeCompile={onBeforeCompile}
      />
    </instancedMesh>
  )
}
```

### Important: customProgramCacheKey

When you use `onBeforeCompile`, Three.js caches shaders by material type. If you modify the vertex shader, you need to tell Three.js this is a different program:

```tsx
<meshStandardMaterial
  vertexColors
  onBeforeCompile={onBeforeCompile}
  customProgramCacheKey={() => 'wind-material'}
/>
```

Without this, Three.js might reuse a cached non-wind shader for your material (or vice versa), producing flickering or incorrect visuals.

### Tree Wind — Subtler

Trees sway less than grass. Use a lower wind strength and larger frequency (bigger, slower waves):

```tsx
// In the tree wind shader variant:
float windStrength = 0.1;   // Much less than grass
float windSpeed = 0.8;      // Slower
float windFrequency = 0.2;  // Larger wavelength

float heightFactor = clamp(position.y / 4.0, 0.0, 1.0);
// Use sqrt for trees — the trunk barely moves, canopy sways
heightFactor = sqrt(heightFactor);
```

---

## 8. Chunked Loading

### Why Chunks

You can't generate infinite terrain all at once — you'd run out of memory. Instead, divide the world into tiles (chunks) and only keep the ones near the camera loaded. As the camera moves, generate new chunks ahead and dispose old ones behind.

### The Chunk Key Pattern

Identify each chunk by its grid coordinates. The camera's world position maps to a chunk coordinate by dividing by chunk size and flooring:

```tsx
function worldToChunk(worldX: number, worldZ: number, chunkSize: number): [number, number] {
  return [
    Math.floor(worldX / chunkSize),
    Math.floor(worldZ / chunkSize),
  ]
}

function chunkKey(cx: number, cz: number): string {
  return `${cx},${cz}`
}
```

### The Chunk Manager

The chunk manager is the brain of the system. Every frame (or every few frames — you don't need to check every single frame), it computes which chunks should be loaded based on the camera position, spawns missing chunks, and disposes chunks that are too far away.

```tsx
import { useRef, useState, useCallback } from 'react'
import { useFrame, useThree } from '@react-three/fiber'

const CHUNK_SIZE = 100
const VIEW_DISTANCE = 3    // Number of chunks in each direction
const DISPOSE_DISTANCE = 5 // Dispose chunks beyond this

interface ChunkData {
  cx: number
  cz: number
  key: string
}

function ChunkManager() {
  const { camera } = useThree()
  const [chunks, setChunks] = useState<Map<string, ChunkData>>(new Map())
  const lastChunkRef = useRef<string>('')

  useFrame(() => {
    const camX = camera.position.x
    const camZ = camera.position.z
    const [currentCX, currentCZ] = worldToChunk(camX, camZ, CHUNK_SIZE)
    const currentKey = chunkKey(currentCX, currentCZ)

    // Only update when camera enters a new chunk
    if (currentKey === lastChunkRef.current) return
    lastChunkRef.current = currentKey

    setChunks((prev) => {
      const next = new Map(prev)

      // Add chunks within view distance
      for (let dx = -VIEW_DISTANCE; dx <= VIEW_DISTANCE; dx++) {
        for (let dz = -VIEW_DISTANCE; dz <= VIEW_DISTANCE; dz++) {
          const cx = currentCX + dx
          const cz = currentCZ + dz
          const key = chunkKey(cx, cz)
          if (!next.has(key)) {
            next.set(key, { cx, cz, key })
          }
        }
      }

      // Remove chunks beyond dispose distance
      for (const [key, chunk] of next) {
        const dist = Math.max(
          Math.abs(chunk.cx - currentCX),
          Math.abs(chunk.cz - currentCZ)
        )
        if (dist > DISPOSE_DISTANCE) {
          next.delete(key)
        }
      }

      return next
    })
  })

  return (
    <>
      {Array.from(chunks.values()).map((chunk) => (
        <TerrainChunkComplete
          key={chunk.key}
          chunkX={chunk.cx}
          chunkZ={chunk.cz}
          chunkSize={CHUNK_SIZE}
        />
      ))}
    </>
  )
}
```

### React State vs Imperative Management

The approach above uses React state (`useState`) to manage chunks. When the map changes, React diffs the component list and mounts/unmounts chunk components. This is the simplest approach and works well for moderate chunk counts.

For extreme performance (hundreds of chunks, very fast camera movement), you might need imperative management — storing chunks in a ref, manually adding/removing meshes from the scene, and handling disposal yourself. The trade-off is complexity: you lose React's automatic cleanup and have to manage the Three.js scene graph directly.

Start with React state. Switch to imperative only if profiling reveals the state updates are a bottleneck. In most cases, the chunk generation itself is far more expensive than the React reconciliation.

### Throttling Updates

You don't need to check for new chunks every frame. The camera has to move an entire chunk width before anything changes. The `lastChunkRef` comparison above handles this efficiently — the expensive set operation only runs when the camera crosses a chunk boundary.

### Disposing Geometry

When a chunk unmounts, its geometry needs to be disposed. Otherwise you leak GPU memory. Use a cleanup effect:

```tsx
function TerrainChunkComplete({ chunkX, chunkZ, chunkSize }: {
  chunkX: number
  chunkZ: number
  chunkSize: number
}) {
  const geometry = useMemo(() => {
    // ... generate geometry ...
    return geo
  }, [chunkX, chunkZ, chunkSize])

  // Clean up on unmount
  useEffect(() => {
    return () => {
      geometry.dispose()
    }
  }, [geometry])

  return (
    <mesh geometry={geometry} position={[chunkX * chunkSize, 0, chunkZ * chunkSize]}>
      <meshStandardMaterial vertexColors />
    </mesh>
  )
}
```

### Seam Prevention

When two adjacent chunks have different resolutions or slightly different noise sampling patterns, you get visible seams — cracks or height mismatches at chunk boundaries. To prevent this:

1. **Use exact world coordinates for noise.** Don't use local chunk coordinates with an offset that might have floating-point errors. Compute `worldX` and `worldZ` precisely.

2. **Include border vertices.** Make chunks overlap by one vertex at the edges. Adjacent chunks will generate the same height for shared boundary vertices.

3. **Use fog.** This is the lazy-but-effective solution. Seams are only visible at a distance where fog hides them anyway.

---

## 9. Level of Detail (LOD)

### The Problem

A tree that's 5 meters away needs detailed geometry — hundreds or thousands of triangles. The same tree 500 meters away occupies a handful of pixels. Rendering the full-detail version is pure waste.

### Three.js LOD Object

Three.js has a built-in `LOD` class that swaps between detail levels based on camera distance:

```tsx
import { useRef, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

function LodTree({ position }: { position: [number, number, number] }) {
  const lodRef = useRef<THREE.LOD>(null)

  useFrame(({ camera }) => {
    // LOD needs to be updated every frame to check distances
    lodRef.current?.update(camera)
  })

  return (
    <lod ref={lodRef} position={position}>
      {/* Level 0: High detail (close) */}
      <mesh>
        <coneGeometry args={[0.5, 2, 8]} />
        <meshStandardMaterial color="#2d6b2e" />
      </mesh>

      {/* Level 1: Medium detail (mid-range) */}
      <mesh>
        <coneGeometry args={[0.5, 2, 4]} />
        <meshStandardMaterial color="#2d6b2e" />
      </mesh>
    </lod>
  )
}
```

However, LOD per tree doesn't scale well — you'd need thousands of LOD objects, each doing a distance check every frame. For instanced vegetation, you use a different strategy.

### Chunk-Level LOD

Instead of per-tree LOD, use LOD at the chunk level. Close chunks get high-detail terrain (128 segments) with full vegetation. Medium-distance chunks get lower-detail terrain (64 segments) and fewer instances. Distant chunks get minimal detail (32 segments) and no vegetation.

```tsx
function getChunkLod(
  chunkCX: number,
  chunkCZ: number,
  cameraCX: number,
  cameraCZ: number
): 'high' | 'medium' | 'low' {
  const dist = Math.max(
    Math.abs(chunkCX - cameraCX),
    Math.abs(chunkCZ - cameraCZ)
  )

  if (dist <= 1) return 'high'
  if (dist <= 3) return 'medium'
  return 'low'
}

const LOD_CONFIG = {
  high:   { segments: 128, treeCount: 1.0,  grassCount: 1.0 },
  medium: { segments: 64,  treeCount: 0.5,  grassCount: 0.2 },
  low:    { segments: 32,  treeCount: 0.1,  grassCount: 0.0 },
}
```

### Billboard Impostors

For very distant objects, even a low-poly mesh is overkill. Replace 3D geometry with a flat textured quad (billboard) that always faces the camera. A tree at 300 meters is indistinguishable from a cardboard cutout of a tree.

drei's `<Billboard>` component handles the always-facing-camera rotation:

```tsx
import { Billboard } from '@react-three/drei'

<Billboard position={[x, y, z]}>
  <mesh>
    <planeGeometry args={[1, 2]} />
    <meshBasicMaterial
      map={treeTexture}
      transparent
      alphaTest={0.5}
    />
  </mesh>
</Billboard>
```

For instanced billboards at scale, you'd use a custom shader that rotates each instance's quad to face the camera in the vertex shader — far more efficient than individual Billboard components.

### drei's Detailed Component

drei provides `<Detailed>`, which wraps Three.js LOD with a cleaner API:

```tsx
import { Detailed } from '@react-three/drei'

<Detailed distances={[0, 25, 50]}>
  <HighDetailTree />   {/* Shown when camera is 0-25 units away */}
  <MediumDetailTree /> {/* Shown when camera is 25-50 units away */}
  <LowDetailTree />   {/* Shown when camera is 50+ units away */}
</Detailed>
```

---

## 10. Fog and Draw Distance

### Why Fog Matters for Procedural Worlds

Fog isn't just an aesthetic choice — it's a critical performance tool. Without fog, players can see to the edge of your loaded world, which means:
1. You see chunks popping in and out as they load and unload
2. You see the hard edge where terrain stops
3. You need to render more chunks to fill the visible area

Fog hides all of these problems. It fades distant objects to a background color, so chunk loading happens invisibly in the fog.

### Linear Fog vs Exponential Fog

**Linear fog** fades linearly between a near and far distance. You get precise control over where fog starts and ends.

```tsx
<Canvas>
  <fog attach="fog" args={['#b0c4de', 100, 400]} />
  {/* args: [color, near, far] */}
  {/* ...scene contents... */}
</Canvas>
```

**Exponential fog** uses an exponential falloff curve. It's simpler (one density parameter instead of near/far), and often looks more natural — atmosphere doesn't have a hard "start of fog" point.

```tsx
<Canvas>
  <fogExp2 attach="fog" args={['#b0c4de', 0.005]} />
  {/* args: [color, density] */}
  {/* ...scene contents... */}
</Canvas>
```

### Matching Fog Color to Sky

If your fog color doesn't match the sky/background color, you get a visible band at the horizon. Set the Canvas clear color and the fog color to the same value:

```tsx
<Canvas
  gl={{ clearColor: '#b0c4de' }}
  onCreated={({ gl }) => {
    gl.setClearColor('#b0c4de')
  }}
>
  <fog attach="fog" args={['#b0c4de', 100, 400]} />
  {/* ... */}
</Canvas>
```

Or use the `<color>` element to set the scene background:

```tsx
<Canvas>
  <color attach="background" args={['#b0c4de']} />
  <fog attach="fog" args={['#b0c4de', 100, 400]} />
  {/* ... */}
</Canvas>
```

### Tuning Fog Distance to Chunk Distance

Your fog far distance should be less than or equal to your chunk dispose distance multiplied by chunk size. If chunks unload at 500 units and fog ends at 400, the player never sees chunks disappear. If fog ends at 600, they'll see terrain vanishing.

```
Fog far distance <= DISPOSE_DISTANCE * CHUNK_SIZE
```

For your infinite landscape with `CHUNK_SIZE = 100` and `DISPOSE_DISTANCE = 5`:

```tsx
// Max visible distance = 5 * 100 = 500 units
// Set fog to end before that
<fog attach="fog" args={['#b0c4de', 80, 400]} />
```

### Performance Benefit

Fog doesn't just hide seams — it lets you reduce draw distance. With dense fog, you can set the camera's far plane closer, and the GPU skips everything beyond it:

```tsx
<Canvas camera={{ position: [0, 30, 0], fov: 60, near: 0.1, far: 500 }}>
  <fogExp2 attach="fog" args={['#c8d8e8', 0.006]} />
  {/* ... */}
</Canvas>
```

Everything past 500 units is clipped by the camera and never rendered, regardless of how many chunks are loaded.

---

## 11. BatchedMesh

### When InstancedMesh Isn't Enough

`InstancedMesh` renders many copies of **the same geometry** in one draw call. What if you need different geometries — pine trees, oak trees, and birch trees — in one draw call? That's where `BatchedMesh` comes in.

### BatchedMesh Overview

`BatchedMesh` was added to Three.js to handle the case of **multiple different geometries and materials** in a single draw call. You pre-register geometries and materials, then add instances of any registered geometry.

```tsx
import * as THREE from 'three'

// Create a BatchedMesh
const batchedMesh = new THREE.BatchedMesh(
  1000,    // Max instance count
  50000,   // Max vertex count across all geometries
  100000   // Max index count across all geometries
)

// Register geometries
const pineGeoId = batchedMesh.addGeometry(pineGeometry)
const oakGeoId = batchedMesh.addGeometry(oakGeometry)
const birchGeoId = batchedMesh.addGeometry(birchGeometry)

// Add instances
const matrix = new THREE.Matrix4()
matrix.setPosition(10, 0, 5)
const instanceId = batchedMesh.addInstance(pineGeoId)
batchedMesh.setMatrixAt(instanceId, matrix)

matrix.setPosition(15, 0, 8)
const instanceId2 = batchedMesh.addInstance(oakGeoId)
batchedMesh.setMatrixAt(instanceId2, matrix)
```

### BatchedMesh vs InstancedMesh

| Feature | InstancedMesh | BatchedMesh |
|---------|---------------|-------------|
| Geometry | Single | Multiple |
| Material | Single | Single (with workarounds for multi-material) |
| Draw calls | 1 | 1 |
| Per-instance color | Yes (instanceColor) | Yes |
| API maturity | Stable, well-tested | Newer, still evolving |
| Ease of use | Simple | More complex setup |

### When to Use Which

- **All instances are the same shape** (grass blades, same tree model, bullets): `InstancedMesh`. Simpler, faster setup, well-supported.
- **Mixed shapes in one draw call** (different tree species, mixed vegetation): `BatchedMesh`. More complex but saves draw calls.
- **Few different shapes, many of each**: Consider multiple `InstancedMesh`es — one per shape. Three draw calls for 3 tree types is rarely a bottleneck compared to the complexity of BatchedMesh.

### Using BatchedMesh in R3F

R3F doesn't have declarative JSX support for `BatchedMesh` as of now, so you use it imperatively:

```tsx
import { useRef, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

function MixedVegetation({
  instances,
}: {
  instances: Array<{ type: 'pine' | 'oak' | 'birch'; position: [number, number, number] }>
}) {
  const meshRef = useRef<THREE.BatchedMesh>(null)

  useEffect(() => {
    if (!meshRef.current) return

    const batch = meshRef.current

    // Create geometries
    const pine = new THREE.ConeGeometry(0.4, 2.5, 6)
    const oak = new THREE.SphereGeometry(0.8, 6, 6)
    oak.translate(0, 1.5, 0)
    const birch = new THREE.CylinderGeometry(0.15, 0.2, 3, 5)

    const pineId = batch.addGeometry(pine)
    const oakId = batch.addGeometry(oak)
    const birchId = batch.addGeometry(birch)

    const geoMap = { pine: pineId, oak: oakId, birch: birchId }

    const matrix = new THREE.Matrix4()
    const color = new THREE.Color()

    for (const inst of instances) {
      const geoId = geoMap[inst.type]
      const instanceId = batch.addInstance(geoId)
      matrix.setPosition(...inst.position)
      batch.setMatrixAt(instanceId, matrix)

      // Vary color by type
      if (inst.type === 'pine') color.set('#1a5c1a')
      else if (inst.type === 'oak') color.set('#2d7a2d')
      else color.set('#c8b06e')
      batch.setColorAt(instanceId, color)
    }

    // Clean up geometries (they've been copied into the batch)
    pine.dispose()
    oak.dispose()
    birch.dispose()
  }, [instances])

  return (
    <primitive
      ref={meshRef}
      object={new THREE.BatchedMesh(
        instances.length,
        instances.length * 200, // Conservative vertex budget
        instances.length * 600  // Conservative index budget
      )}
    >
      <meshStandardMaterial vertexColors />
    </primitive>
  )
}
```

### Practical Advice

For most procedural world projects, multiple `InstancedMesh` components (one per vegetation type) is the right call. `BatchedMesh` is worth reaching for when you have many geometry variants and draw call count is a measured, proven bottleneck — not before.

---

## 12. Performance Budgeting

### Know Your Targets

Before you start profiling, know what "fast enough" means:

| Metric | Budget (60fps target) | Notes |
|--------|----------------------|-------|
| Frame time | < 16.6ms | 1000ms / 60fps |
| Draw calls | < 100 | GPU state changes are expensive |
| Triangles | < 2M per frame | Depends heavily on GPU |
| Texture memory | < 512MB | Depends on device |
| Instance matrix updates | < 50K per frame | CPU-side bottleneck |

These are rough guidelines for a mid-range desktop GPU. Mobile targets are much tighter.

### Where Bottlenecks Live

**CPU-side bottlenecks:**
- Generating terrain geometry (noise sampling, vertex manipulation)
- Computing instance matrices (the `dummy.updateMatrix()` loop)
- React reconciliation (too many state updates triggering re-renders)
- Poisson disk sampling (expensive for high densities)
- Garbage collection (allocating objects in hot loops)

**GPU-side bottlenecks:**
- Too many draw calls (each InstancedMesh is one draw call; keep count low)
- Too many triangles (reduce mesh resolution for distant chunks)
- Shader complexity (wind animation adds cost per vertex)
- Overdraw (grass blades overlapping at close range)
- Fill rate (high-resolution screens with complex fragment shaders)

### Profiling with r3f-perf

```bash
npm install r3f-perf
```

```tsx
import { Perf } from 'r3f-perf'

<Canvas>
  <Perf position="top-left" />
  {/* ...scene... */}
</Canvas>
```

r3f-perf shows you:
- **FPS** — frames per second
- **MS** — milliseconds per frame
- **GPU** — GPU render time
- **CPU** — JavaScript execution time
- **Draw calls** — number of WebGL draw calls
- **Triangles** — total triangle count
- **Memory** — texture and geometry memory

### Optimization Checklist

When your infinite landscape drops below 60fps, check these in order:

1. **Draw calls too high?** Merge InstancedMeshes. Use one per vegetation type per group of chunks, not one per chunk.

2. **Triangle count too high?** Reduce terrain segments for distant chunks. Lower grass density. Use LOD.

3. **CPU time too high?** Move terrain generation to a Web Worker. Cache generated chunks. Reduce Poisson disk sampling resolution.

4. **Instance matrix updates every frame?** Only update matrices when instances change, not every frame. Trees don't move — set matrices once.

5. **Garbage collection spikes?** Pre-allocate Vector3, Matrix4, Color objects outside of loops. Reuse the `dummy` Object3D.

### Web Workers for Terrain Generation

The heaviest CPU operation is generating terrain geometry — sampling noise thousands of times per chunk. Move this off the main thread:

```tsx
// terrain-worker.ts
self.onmessage = (event) => {
  const { chunkX, chunkZ, chunkSize, segments } = event.data

  // Generate vertex positions and colors here
  // (Import noise functions, run FBM, compute biome colors)

  const positions = new Float32Array(/* ... */)
  const colors = new Float32Array(/* ... */)
  const normals = new Float32Array(/* ... */)

  // Transfer the buffers (zero-copy)
  self.postMessage(
    { chunkX, chunkZ, positions, colors, normals },
    [positions.buffer, colors.buffer, normals.buffer]
  )
}
```

```tsx
// In your React component:
const worker = useMemo(() => new Worker(
  new URL('./terrain-worker.ts', import.meta.url),
  { type: 'module' }
), [])
```

Transfer buffers using the second argument to `postMessage` — this moves the ArrayBuffer to the worker (or back) without copying, making large terrain transfers essentially free.

---

## Code Walkthrough: Building the Infinite Landscape

Let's build the complete mini-project. This ties together everything from the module: noise terrain, biome coloring, instanced vegetation, wind shaders, chunked loading, and fog.

### Project Setup

```bash
npm create vite@latest infinite-landscape -- --template react-ts
cd infinite-landscape
npm install three @react-three/fiber @react-three/drei simplex-noise r3f-perf
npm install -D @types/three
```

### Project Structure

```
infinite-landscape/
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   ├── index.css
│   ├── components/
│   │   ├── ChunkManager.tsx
│   │   ├── TerrainChunk.tsx
│   │   ├── TreeInstances.tsx
│   │   ├── GrassInstances.tsx
│   │   └── FlyCamera.tsx
│   ├── lib/
│   │   ├── noise.ts
│   │   ├── scatter.ts
│   │   └── biome.ts
│   └── vite-env.d.ts
├── index.html
└── package.json
```

### Global Styles

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

### Noise Utilities

```tsx
// src/lib/noise.ts
import { createNoise2D } from 'simplex-noise'

const noise2D = createNoise2D()

export function fbm(
  x: number,
  z: number,
  octaves: number = 6,
  persistence: number = 0.5,
  lacunarity: number = 2.0,
  scale: number = 0.008
): number {
  let value = 0
  let amplitude = 1
  let frequency = scale
  let maxValue = 0

  for (let i = 0; i < octaves; i++) {
    value += noise2D(x * frequency, z * frequency) * amplitude
    maxValue += amplitude
    amplitude *= persistence
    frequency *= lacunarity
  }

  return value / maxValue
}

export function getHeight(worldX: number, worldZ: number): number {
  return fbm(worldX, worldZ) * 30
}

export function getSlope(worldX: number, worldZ: number): number {
  const epsilon = 0.5
  const h = getHeight(worldX, worldZ)
  const hx = getHeight(worldX + epsilon, worldZ)
  const hz = getHeight(worldX, worldZ + epsilon)
  const dx = (hx - h) / epsilon
  const dz = (hz - h) / epsilon
  return Math.sqrt(dx * dx + dz * dz)
}
```

### Biome Color Utilities

```tsx
// src/lib/biome.ts
import * as THREE from 'three'

const WATER  = new THREE.Color('#2a6fa8')
const SAND   = new THREE.Color('#c8b76e')
const GRASS  = new THREE.Color('#4a8f3f')
const FOREST = new THREE.Color('#2d6b2e')
const ROCK   = new THREE.Color('#6b6b6b')
const SNOW   = new THREE.Color('#e8e8f0')

const temp = new THREE.Color()

export function getBiomeColor(height: number, slope: number): THREE.Color {
  // Steep slopes default to rock
  if (slope > 2.0 && height > 1.5) {
    return temp.copy(ROCK)
  }

  if (height < -1) return temp.copy(WATER)

  if (height < 1) {
    const t = (height + 1) / 2
    return temp.copy(WATER).lerp(SAND, t)
  }

  if (height < 3) {
    const t = (height - 1) / 2
    return temp.copy(SAND).lerp(GRASS, t)
  }

  if (height < 10) {
    const t = (height - 3) / 7
    return temp.copy(GRASS).lerp(FOREST, t)
  }

  if (height < 16) {
    const t = (height - 10) / 6
    return temp.copy(FOREST).lerp(ROCK, t)
  }

  if (height < 24) {
    const t = (height - 16) / 8
    return temp.copy(ROCK).lerp(SNOW, t)
  }

  return temp.copy(SNOW)
}
```

### Scattering Utilities

```tsx
// src/lib/scatter.ts
import { getHeight, getSlope } from './noise'

export function poissonDiskSampling(
  width: number,
  height: number,
  minDistance: number,
  maxAttempts: number = 30
): Array<[number, number]> {
  const cellSize = minDistance / Math.SQRT2
  const gridW = Math.ceil(width / cellSize)
  const gridH = Math.ceil(height / cellSize)
  const grid: (number | null)[] = new Array(gridW * gridH).fill(null)
  const points: Array<[number, number]> = []
  const active: number[] = []

  const gIdx = (x: number, y: number) =>
    Math.floor(y / cellSize) * gridW + Math.floor(x / cellSize)

  const sx = Math.random() * width
  const sy = Math.random() * height
  points.push([sx, sy])
  grid[gIdx(sx, sy)] = 0
  active.push(0)

  while (active.length > 0) {
    const ai = Math.floor(Math.random() * active.length)
    const pi = active[ai]
    const [px, py] = points[pi]
    let found = false

    for (let a = 0; a < maxAttempts; a++) {
      const angle = Math.random() * Math.PI * 2
      const dist = minDistance + Math.random() * minDistance
      const nx = px + Math.cos(angle) * dist
      const ny = py + Math.sin(angle) * dist

      if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue

      const gx = Math.floor(nx / cellSize)
      const gy = Math.floor(ny / cellSize)
      let tooClose = false

      for (let dy = -2; dy <= 2 && !tooClose; dy++) {
        for (let dx = -2; dx <= 2 && !tooClose; dx++) {
          const cx = gx + dx
          const cy = gy + dy
          if (cx < 0 || cx >= gridW || cy < 0 || cy >= gridH) continue
          const neighbor = grid[cy * gridW + cx]
          if (neighbor !== null) {
            const [ox, oy] = points[neighbor]
            if (Math.hypot(nx - ox, ny - oy) < minDistance) tooClose = true
          }
        }
      }

      if (!tooClose) {
        const idx = points.length
        points.push([nx, ny])
        grid[gIdx(nx, ny)] = idx
        active.push(idx)
        found = true
        break
      }
    }

    if (!found) active.splice(ai, 1)
  }

  return points
}

export interface ScatterResult {
  positions: Array<[number, number, number]>
  scales: Array<number>
}

export function scatterTrees(
  chunkX: number,
  chunkZ: number,
  chunkSize: number
): ScatterResult {
  const points = poissonDiskSampling(chunkSize, chunkSize, 5)
  const halfSize = chunkSize / 2
  const positions: Array<[number, number, number]> = []
  const scales: Array<number> = []

  for (const [lx, lz] of points) {
    const wx = lx + chunkX * chunkSize - halfSize
    const wz = lz + chunkZ * chunkSize - halfSize

    const h = getHeight(wx, wz)
    const s = getSlope(wx, wz)

    // Trees: above water, below snow, not on steep slopes
    if (h < 1.5 || h > 18 || s > 1.5) continue

    positions.push([wx, h, wz])
    scales.push(0.8 + Math.random() * 0.6)
  }

  return { positions, scales }
}

export function scatterGrass(
  chunkX: number,
  chunkZ: number,
  chunkSize: number
): ScatterResult {
  const points = poissonDiskSampling(chunkSize, chunkSize, 1.8)
  const halfSize = chunkSize / 2
  const positions: Array<[number, number, number]> = []
  const scales: Array<number> = []

  for (const [lx, lz] of points) {
    const wx = lx + chunkX * chunkSize - halfSize
    const wz = lz + chunkZ * chunkSize - halfSize

    const h = getHeight(wx, wz)
    const s = getSlope(wx, wz)

    // Grass: above sand, below rock, moderate slopes only
    if (h < 0.5 || h > 14 || s > 2.0) continue

    positions.push([wx, h, wz])
    scales.push(0.5 + Math.random() * 0.8)
  }

  return { positions, scales }
}
```

### Terrain Chunk Component

```tsx
// src/components/TerrainChunk.tsx
import { useMemo, useEffect } from 'react'
import * as THREE from 'three'
import { getHeight, getSlope } from '../lib/noise'
import { getBiomeColor } from '../lib/biome'

interface TerrainChunkProps {
  chunkX: number
  chunkZ: number
  chunkSize: number
  segments?: number
}

export function TerrainChunk({
  chunkX,
  chunkZ,
  chunkSize,
  segments = 64,
}: TerrainChunkProps) {
  const geometry = useMemo(() => {
    const geo = new THREE.PlaneGeometry(chunkSize, chunkSize, segments, segments)
    geo.rotateX(-Math.PI / 2)

    const positions = geo.attributes.position
    const colors = new Float32Array(positions.count * 3)
    const worldOffsetX = chunkX * chunkSize
    const worldOffsetZ = chunkZ * chunkSize

    // First pass: set heights
    for (let i = 0; i < positions.count; i++) {
      const lx = positions.getX(i)
      const lz = positions.getZ(i)
      const wx = lx + worldOffsetX
      const wz = lz + worldOffsetZ
      const height = getHeight(wx, wz)
      positions.setY(i, height)
    }

    // Compute normals after height displacement
    geo.computeVertexNormals()

    // Second pass: set colors using height and slope
    const normals = geo.attributes.normal
    for (let i = 0; i < positions.count; i++) {
      const lx = positions.getX(i)
      const lz = positions.getZ(i)
      const wx = lx + worldOffsetX
      const wz = lz + worldOffsetZ

      const height = positions.getY(i)
      const slope = getSlope(wx, wz)

      const color = getBiomeColor(height, slope)
      colors[i * 3] = color.r
      colors[i * 3 + 1] = color.g
      colors[i * 3 + 2] = color.b
    }

    geo.setAttribute('color', new THREE.BufferAttribute(colors, 3))

    return geo
  }, [chunkX, chunkZ, chunkSize, segments])

  // Clean up on unmount
  useEffect(() => {
    return () => {
      geometry.dispose()
    }
  }, [geometry])

  return (
    <mesh
      geometry={geometry}
      position={[chunkX * chunkSize, 0, chunkZ * chunkSize]}
      receiveShadow
    >
      <meshStandardMaterial vertexColors flatShading={false} />
    </mesh>
  )
}
```

### Tree Instances Component

```tsx
// src/components/TreeInstances.tsx
import { useRef, useEffect } from 'react'
import * as THREE from 'three'
import type { ScatterResult } from '../lib/scatter'

const dummy = new THREE.Object3D()

interface TreeInstancesProps {
  scatter: ScatterResult
  chunkX: number
  chunkZ: number
  chunkSize: number
}

export function TreeInstances({ scatter, chunkX, chunkZ, chunkSize }: TreeInstancesProps) {
  const trunkRef = useRef<THREE.InstancedMesh>(null)
  const canopyRef = useRef<THREE.InstancedMesh>(null)
  const count = scatter.positions.length

  useEffect(() => {
    if (!trunkRef.current || !canopyRef.current || count === 0) return

    const color = new THREE.Color()

    for (let i = 0; i < count; i++) {
      const [x, y, z] = scatter.positions[i]
      const s = scatter.scales[i]

      // Trunk
      dummy.position.set(x, y + 0.8 * s, z)
      dummy.rotation.set(0, Math.random() * Math.PI * 2, 0)
      dummy.scale.set(s * 0.3, s * 0.8, s * 0.3)
      dummy.updateMatrix()
      trunkRef.current.setMatrixAt(i, dummy.matrix)

      color.setHSL(0.07, 0.4, 0.2 + Math.random() * 0.1)
      trunkRef.current.setColorAt(i, color)

      // Canopy
      dummy.position.set(x, y + 1.8 * s, z)
      dummy.scale.set(s, s * 1.2, s)
      dummy.updateMatrix()
      canopyRef.current.setMatrixAt(i, dummy.matrix)

      color.setHSL(0.28 + Math.random() * 0.06, 0.5 + Math.random() * 0.2, 0.2 + Math.random() * 0.1)
      canopyRef.current.setColorAt(i, color)
    }

    trunkRef.current.instanceMatrix.needsUpdate = true
    canopyRef.current.instanceMatrix.needsUpdate = true
    if (trunkRef.current.instanceColor) trunkRef.current.instanceColor.needsUpdate = true
    if (canopyRef.current.instanceColor) canopyRef.current.instanceColor.needsUpdate = true

    // Compute bounding for frustum culling
    trunkRef.current.computeBoundingSphere()
    canopyRef.current.computeBoundingSphere()
  }, [scatter, count])

  if (count === 0) return null

  return (
    <group>
      {/* Trunks */}
      <instancedMesh ref={trunkRef} args={[undefined, undefined, count]} castShadow>
        <cylinderGeometry args={[0.15, 0.25, 2, 5]} />
        <meshStandardMaterial vertexColors />
      </instancedMesh>

      {/* Canopies */}
      <instancedMesh ref={canopyRef} args={[undefined, undefined, count]} castShadow>
        <coneGeometry args={[1, 2.5, 7]} />
        <meshStandardMaterial vertexColors />
      </instancedMesh>
    </group>
  )
}
```

### Grass Instances Component (with Wind Shader)

```tsx
// src/components/GrassInstances.tsx
import { useRef, useEffect, useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'
import type { ScatterResult } from '../lib/scatter'

const dummy = new THREE.Object3D()

interface GrassInstancesProps {
  scatter: ScatterResult
}

export function GrassInstances({ scatter }: GrassInstancesProps) {
  const meshRef = useRef<THREE.InstancedMesh>(null)
  const count = scatter.positions.length
  const timeUniform = useMemo(() => ({ value: 0 }), [])

  useFrame((_, delta) => {
    timeUniform.value += delta
  })

  const onBeforeCompile = useMemo(
    () => (shader: THREE.WebGLProgramParameters) => {
      shader.uniforms.uTime = timeUniform

      shader.vertexShader = shader.vertexShader.replace(
        '#include <common>',
        /* glsl */ `
          #include <common>
          uniform float uTime;
        `
      )

      shader.vertexShader = shader.vertexShader.replace(
        '#include <begin_vertex>',
        /* glsl */ `
          #include <begin_vertex>

          // World position for spatial variation
          vec4 wPos = instanceMatrix * vec4(position, 1.0);
          wPos = modelMatrix * wPos;

          // Height factor: tips move, roots stay
          float hFactor = clamp(position.y / 0.6, 0.0, 1.0);
          hFactor *= hFactor;

          // Wind: two overlapping sine waves
          float windStr = 0.25;
          float w1 = sin(wPos.x * 0.5 + uTime * 1.5) * 0.6;
          float w2 = sin(wPos.z * 0.35 + uTime * 2.0) * 0.4;
          float wind = (w1 + w2) * windStr * hFactor;

          transformed.x += wind;
          transformed.z += wind * 0.4;
        `
      )
    },
    [timeUniform]
  )

  useEffect(() => {
    if (!meshRef.current || count === 0) return

    const color = new THREE.Color()

    for (let i = 0; i < count; i++) {
      const [x, y, z] = scatter.positions[i]
      const s = scatter.scales[i]

      dummy.position.set(x, y, z)
      dummy.rotation.set(
        (Math.random() - 0.5) * 0.2,
        Math.random() * Math.PI * 2,
        (Math.random() - 0.5) * 0.2
      )
      dummy.scale.set(s * 0.6, s, s * 0.6)
      dummy.updateMatrix()
      meshRef.current.setMatrixAt(i, dummy.matrix)

      color.setHSL(
        0.25 + Math.random() * 0.08,
        0.5 + Math.random() * 0.3,
        0.25 + Math.random() * 0.15
      )
      meshRef.current.setColorAt(i, color)
    }

    meshRef.current.instanceMatrix.needsUpdate = true
    if (meshRef.current.instanceColor) {
      meshRef.current.instanceColor.needsUpdate = true
    }
    meshRef.current.computeBoundingSphere()
  }, [scatter, count])

  if (count === 0) return null

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, count]}>
      <coneGeometry args={[0.08, 0.6, 3, 1]} />
      <meshStandardMaterial
        vertexColors
        side={THREE.DoubleSide}
        onBeforeCompile={onBeforeCompile}
        customProgramCacheKey={() => 'grass-wind'}
      />
    </instancedMesh>
  )
}
```

### Fly Camera

```tsx
// src/components/FlyCamera.tsx
import { useRef } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import * as THREE from 'three'

export function FlyCamera({ speed = 30, height = 25 }: { speed?: number; height?: number }) {
  const { camera } = useThree()
  const keys = useRef(new Set<string>())
  const direction = useRef(new THREE.Vector3(0, 0, -1))

  // Set initial camera position
  useRef(() => {
    camera.position.set(0, height, 0)
    camera.lookAt(0, height - 5, -50)
  }).current

  // Register key listeners once
  useRef(() => {
    const onDown = (e: KeyboardEvent) => keys.current.add(e.code)
    const onUp = (e: KeyboardEvent) => keys.current.delete(e.code)
    window.addEventListener('keydown', onDown)
    window.addEventListener('keyup', onUp)
    return () => {
      window.removeEventListener('keydown', onDown)
      window.removeEventListener('keyup', onUp)
    }
  })

  useFrame((_, delta) => {
    const k = keys.current
    const moveSpeed = speed * delta

    // Get camera forward direction (flatten to XZ plane)
    camera.getWorldDirection(direction.current)
    direction.current.y = 0
    direction.current.normalize()

    const right = new THREE.Vector3()
    right.crossVectors(direction.current, camera.up).normalize()

    if (k.has('KeyW') || k.has('ArrowUp'))    camera.position.addScaledVector(direction.current, moveSpeed)
    if (k.has('KeyS') || k.has('ArrowDown'))  camera.position.addScaledVector(direction.current, -moveSpeed)
    if (k.has('KeyA') || k.has('ArrowLeft'))  camera.position.addScaledVector(right, -moveSpeed)
    if (k.has('KeyD') || k.has('ArrowRight')) camera.position.addScaledVector(right, moveSpeed)
    if (k.has('Space'))    camera.position.y += moveSpeed
    if (k.has('ShiftLeft')) camera.position.y -= moveSpeed
  })

  return null
}
```

### Chunk Manager

```tsx
// src/components/ChunkManager.tsx
import { useRef, useState } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import { TerrainChunk } from './TerrainChunk'
import { TreeInstances } from './TreeInstances'
import { GrassInstances } from './GrassInstances'
import { scatterTrees, scatterGrass, ScatterResult } from '../lib/scatter'
import { useMemo } from 'react'

const CHUNK_SIZE = 100
const VIEW_DISTANCE = 3
const DISPOSE_DISTANCE = 5

interface ChunkData {
  cx: number
  cz: number
  key: string
}

function chunkKey(cx: number, cz: number): string {
  return `${cx},${cz}`
}

function ChunkContent({ cx, cz }: { cx: number; cz: number }) {
  const trees = useMemo(() => scatterTrees(cx, cz, CHUNK_SIZE), [cx, cz])
  const grass = useMemo(() => scatterGrass(cx, cz, CHUNK_SIZE), [cx, cz])

  return (
    <group>
      <TerrainChunk chunkX={cx} chunkZ={cz} chunkSize={CHUNK_SIZE} segments={64} />
      <TreeInstances scatter={trees} chunkX={cx} chunkZ={cz} chunkSize={CHUNK_SIZE} />
      <GrassInstances scatter={grass} />
    </group>
  )
}

export function ChunkManager() {
  const { camera } = useThree()
  const [chunks, setChunks] = useState<Map<string, ChunkData>>(new Map())
  const lastChunkKeyRef = useRef<string>('')

  useFrame(() => {
    const camCX = Math.floor(camera.position.x / CHUNK_SIZE)
    const camCZ = Math.floor(camera.position.z / CHUNK_SIZE)
    const key = chunkKey(camCX, camCZ)

    if (key === lastChunkKeyRef.current) return
    lastChunkKeyRef.current = key

    setChunks((prev) => {
      const next = new Map(prev)

      // Spawn chunks within view distance
      for (let dx = -VIEW_DISTANCE; dx <= VIEW_DISTANCE; dx++) {
        for (let dz = -VIEW_DISTANCE; dz <= VIEW_DISTANCE; dz++) {
          const cx = camCX + dx
          const cz = camCZ + dz
          const k = chunkKey(cx, cz)
          if (!next.has(k)) {
            next.set(k, { cx, cz, key: k })
          }
        }
      }

      // Dispose distant chunks
      for (const [k, chunk] of next) {
        const dist = Math.max(
          Math.abs(chunk.cx - camCX),
          Math.abs(chunk.cz - camCZ)
        )
        if (dist > DISPOSE_DISTANCE) {
          next.delete(k)
        }
      }

      return next
    })
  })

  return (
    <>
      {Array.from(chunks.values()).map((chunk) => (
        <ChunkContent key={chunk.key} cx={chunk.cx} cz={chunk.cz} />
      ))}
    </>
  )
}
```

### App Entry Point

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'
import { Perf } from 'r3f-perf'
import { ChunkManager } from './components/ChunkManager'

export default function App() {
  return (
    <Canvas
      camera={{ position: [0, 40, 80], fov: 60, near: 0.1, far: 500 }}
      gl={{ antialias: true }}
    >
      {/* Sky color and fog — matched */}
      <color attach="background" args={['#b0c4de']} />
      <fog attach="fog" args={['#b0c4de', 80, 420]} />

      {/* Lighting */}
      <ambientLight intensity={0.4} />
      <directionalLight
        position={[100, 80, 50]}
        intensity={1.2}
        castShadow
        shadow-mapSize-width={2048}
        shadow-mapSize-height={2048}
      />

      {/* The infinite world */}
      <ChunkManager />

      {/* Camera controls — use OrbitControls for exploration */}
      <OrbitControls
        enableDamping
        dampingFactor={0.05}
        maxPolarAngle={Math.PI / 2.1}
        minDistance={10}
        maxDistance={200}
      />

      {/* Performance monitor */}
      <Perf position="top-left" />
    </Canvas>
  )
}
```

### Main Entry (Untouched)

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

You should see rolling terrain with biome coloring — blue-gray water in low areas, sand along the shoreline, green grass and forests on the hills, gray rock on steep slopes, and white snow on the peaks. Trees are scattered across the landscape, grass sways in the wind, and fog fades everything into a soft blue-gray at the horizon. Use the OrbitControls to pan around and watch chunks load and unload seamlessly. The r3f-perf overlay shows your draw call count, triangle count, and frame time.

---

## Common Pitfalls

### 1. Generating Noise on Every Frame Instead of Once Per Chunk

```tsx
// WRONG — regenerates the entire terrain every frame
function TerrainChunk({ chunkX, chunkZ }: Props) {
  const geometry = new THREE.PlaneGeometry(100, 100, 64, 64)

  useFrame(() => {
    // This runs 60 times a second!
    const positions = geometry.attributes.position
    for (let i = 0; i < positions.count; i++) {
      const height = fbm(positions.getX(i), positions.getZ(i))
      positions.setY(i, height)
    }
    positions.needsUpdate = true
  })

  return <mesh geometry={geometry}>...</mesh>
}

// RIGHT — generate once in useMemo, only when chunk coordinates change
function TerrainChunk({ chunkX, chunkZ }: Props) {
  const geometry = useMemo(() => {
    const geo = new THREE.PlaneGeometry(100, 100, 64, 64)
    geo.rotateX(-Math.PI / 2)
    const positions = geo.attributes.position

    for (let i = 0; i < positions.count; i++) {
      const wx = positions.getX(i) + chunkX * 100
      const wz = positions.getZ(i) + chunkZ * 100
      positions.setY(i, fbm(wx, wz) * 30)
    }

    geo.computeVertexNormals()
    return geo
  }, [chunkX, chunkZ])

  return <mesh geometry={geometry}>...</mesh>
}
```

### 2. Not Disposing Old Chunk Geometry (Memory Leak)

```tsx
// WRONG — geometry created in useMemo but never disposed
function TerrainChunk({ chunkX, chunkZ }: Props) {
  const geometry = useMemo(() => {
    // Generates geometry... but when this component unmounts,
    // the geometry stays in GPU memory forever
    return generateTerrain(chunkX, chunkZ)
  }, [chunkX, chunkZ])

  return <mesh geometry={geometry}>...</mesh>
}

// RIGHT — dispose geometry on unmount
function TerrainChunk({ chunkX, chunkZ }: Props) {
  const geometry = useMemo(() => {
    return generateTerrain(chunkX, chunkZ)
  }, [chunkX, chunkZ])

  useEffect(() => {
    return () => {
      geometry.dispose() // Free GPU memory when chunk unloads
    }
  }, [geometry])

  return <mesh geometry={geometry}>...</mesh>
}
```

After 10 minutes of flying around without disposal, you'll have hundreds of orphaned geometries eating GPU memory. Eventually the tab will crash or the GPU will start swapping. Always dispose.

### 3. All Grass Swaying in Sync (Not Using World Position)

```tsx
// WRONG — every grass blade has the same wave phase
// In vertex shader:
float wind = sin(uTime * 2.0) * 0.3 * heightFactor;
transformed.x += wind;
// Every blade moves identically — looks like a single solid sheet

// RIGHT — use world position for phase variation
vec4 wPos = modelMatrix * instanceMatrix * vec4(position, 1.0);
float wind = sin(wPos.x * 0.5 + uTime * 1.5) * 0.3 * heightFactor;
transformed.x += wind;
// Adjacent blades are similar but not identical — looks like wind rippling
```

### 4. Instance Matrices Not Updated (Forgetting needsUpdate)

```tsx
// WRONG — matrices are set but Three.js doesn't know they changed
for (let i = 0; i < count; i++) {
  dummy.position.set(x, y, z)
  dummy.updateMatrix()
  meshRef.current.setMatrixAt(i, dummy.matrix)
}
// Instances all render at the origin because the GPU buffer wasn't flagged

// RIGHT — flag the buffer as needing upload to GPU
for (let i = 0; i < count; i++) {
  dummy.position.set(x, y, z)
  dummy.updateMatrix()
  meshRef.current.setMatrixAt(i, dummy.matrix)
}
meshRef.current.instanceMatrix.needsUpdate = true // THIS LINE
```

Same applies to `instanceColor` — if you use `setColorAt`, you need `meshRef.current.instanceColor.needsUpdate = true`.

### 5. Too Many Draw Calls from Separate InstancedMesh Per Chunk

```tsx
// WRONG — each chunk creates its own InstancedMesh for trees
// 49 chunks (7x7 grid) = 49 draw calls just for trees
// Plus 49 for grass, 49 for terrain = 147 draw calls
function ChunkContent({ cx, cz }) {
  return (
    <group>
      <TerrainChunk ... />
      <instancedMesh args={[undefined, undefined, 50]}>  {/* 50 trees per chunk */}
        ...
      </instancedMesh>
      <instancedMesh args={[undefined, undefined, 200]}> {/* 200 grass per chunk */}
        ...
      </instancedMesh>
    </group>
  )
}

// BETTER — pool instances across multiple chunks
// One InstancedMesh with 2000 trees shared across all visible chunks
// = 1 draw call for all trees
// This is more complex to manage but dramatically reduces draw calls
```

The "right" answer depends on your scale. For 20-30 chunks, per-chunk InstancedMesh is fine — 60-90 draw calls is within budget. For 100+ chunks, you need instance pooling or BatchedMesh.

### 6. Vertex Normals Wrong After Displacement

```tsx
// WRONG — displaced vertices but forgot to recompute normals
const geo = new THREE.PlaneGeometry(100, 100, 64, 64)
geo.rotateX(-Math.PI / 2)
const positions = geo.attributes.position
for (let i = 0; i < positions.count; i++) {
  positions.setY(i, fbm(x, z) * 30)
}
// Normals still point straight up — lighting shows no hills or valleys

// RIGHT — recompute normals after displacement
const geo = new THREE.PlaneGeometry(100, 100, 64, 64)
geo.rotateX(-Math.PI / 2)
const positions = geo.attributes.position
for (let i = 0; i < positions.count; i++) {
  positions.setY(i, fbm(x, z) * 30)
}
geo.computeVertexNormals() // NOW lighting shows the terrain shape correctly
```

---

## Exercises

### Exercise 1: Generate a Noise-Based Heightmap Terrain with Biome Coloring

**Time:** 45–60 minutes

Create a single terrain chunk with noise-based height displacement and vertex colors that change by height. Use FBM with at least 4 octaves.

Requirements:
- PlaneGeometry with 64+ segments
- Heights driven by FBM noise
- At least 4 biome zones (water, grass, rock, snow) with smooth transitions
- Properly recomputed vertex normals
- Flat water plane at sea level (optional but looks much better)

Hints:
- Start with a single chunk at the origin before worrying about multiple chunks
- Use `flatShading={false}` for smooth terrain, or `flatShading={true}` for a low-poly stylized look
- For a flat water plane, add a second mesh: a plain `<planeGeometry>` at Y=0 with a blue transparent material

**Stretch goal:** Add a secondary noise layer with different parameters to create "ridged" terrain — take the absolute value of the noise and invert it: `1 - Math.abs(noise2D(x, z))`. This creates sharp ridge lines like mountain ranges.

### Exercise 2: Scatter 1000+ Trees on the Terrain Using InstancedMesh

**Time:** 45–60 minutes

Using the terrain from Exercise 1, scatter at least 1000 tree instances on the surface. Each tree should sit at the correct terrain height.

Requirements:
- Poisson disk sampling for even distribution
- Trees only placed above water level
- No trees on very steep slopes
- Per-instance random Y rotation and slight scale variation
- Per-instance color variation (different shades of green)

Hints:
- Use a simple cone geometry for the canopy and a cylinder for the trunk (two InstancedMeshes)
- Keep the `dummy` Object3D outside the component to avoid GC pressure
- Remember `instanceMatrix.needsUpdate = true` and `instanceColor.needsUpdate = true`
- Compute bounding sphere after setting all matrices for proper frustum culling

**Stretch goal:** Add 2-3 tree "species" — different height/width ratios and color palettes. Either use separate InstancedMeshes or try BatchedMesh.

### Exercise 3: Add Wind Animation to Grass Instances via Vertex Shader

**Time:** 60–90 minutes

Scatter grass instances across the terrain and animate them with a vertex shader wind effect.

Requirements:
- Grass only appears in appropriate biomes (not in water, not on snow)
- Wind displacement scales with vertex height (roots fixed, tips sway)
- Spatial variation using world position (not all grass sways identically)
- Time-based animation via `uTime` uniform
- Use `onBeforeCompile` to inject into the standard material's vertex shader

Hints:
- Grass geometry can be a simple cone or a thin box (args: `[0.05, 0.5, 0.01]`)
- Use `DoubleSide` rendering so grass is visible from both directions
- Two overlapping sine waves with different frequencies create more organic motion
- Use `customProgramCacheKey` to avoid shader cache conflicts

**Stretch goal:** Add a gust system — periodically increase wind strength for a few seconds, creating visible waves rolling across the grass field. Pass a second uniform `uGustTime` that ramps up and down.

### Exercise 4 (Stretch): Implement Chunked Loading with Dynamic Generation/Disposal

**Time:** 90–120 minutes

Build a chunk manager that dynamically generates and disposes terrain chunks based on camera position.

Requirements:
- World divided into grid-based chunks
- Chunks generated when camera approaches
- Chunks disposed when camera moves away
- No visible popping or seams (use fog)
- Geometry properly disposed on unmount (no memory leaks)
- Performance overlay showing draw calls and memory

Hints:
- Use Chebyshev distance (max of dx, dz) not Euclidean for chunk distance — it gives you a square view area which matches the grid
- Threshold the update: only recalculate chunks when the camera enters a new chunk cell
- Start with a small view distance (2-3 chunks) and increase once it's working
- Use React DevTools to verify components unmount when chunks leave view range
- Watch the r3f-perf memory readout — if it only goes up, you're leaking geometry

**Stretch goal:** Add chunk-level LOD — close chunks get 128 segments and full vegetation, medium chunks get 64 segments and reduced vegetation, far chunks get 32 segments and no vegetation.

---

## API Quick Reference

### Noise

| Function / Package | Description | Example |
|-------------------|-------------|---------|
| `createNoise2D()` | Creates a 2D simplex noise function | `const noise = createNoise2D()` |
| `noise2D(x, z)` | Returns noise value in [-1, 1] | `noise2D(wx * 0.01, wz * 0.01)` |
| `alea(seed)` | Seeded PRNG for deterministic noise | `createNoise2D(alea('seed'))` |
| FBM | Layered noise with octaves | See implementation above |

### Terrain

| Pattern | Description | Key Methods |
|---------|-------------|-------------|
| PlaneGeometry displacement | Subdivided plane + vertex Y modification | `positions.setY(i, height)` |
| Vertex normals | Recompute after displacement | `geo.computeVertexNormals()` |
| Vertex colors | Per-vertex RGB attribute | `geo.setAttribute('color', new BufferAttribute(colors, 3))` |
| Geometry disposal | Free GPU memory on unmount | `geometry.dispose()` |

### Instancing

| API | Description | Critical Detail |
|-----|-------------|-----------------|
| `<instancedMesh args={[g, m, count]}>` | Instanced rendering | Pass `[undefined, undefined, count]` with JSX children |
| `setMatrixAt(i, matrix)` | Set instance transform | Use dummy Object3D pattern |
| `instanceMatrix.needsUpdate` | Flag buffer for GPU upload | **Must set to true after changes** |
| `setColorAt(i, color)` | Set per-instance color | Also requires `instanceColor.needsUpdate = true` |
| `mesh.count` | Dynamic instance count | Can reduce below max but not increase |

### Chunking

| Concept | Pattern | Notes |
|---------|---------|-------|
| Chunk key | `"${cx},${cz}"` | String key for Map lookups |
| World to chunk | `Math.floor(worldX / chunkSize)` | Grid coordinate conversion |
| View distance | Check once per chunk crossing | Use `lastChunkRef` to avoid per-frame work |
| Disposal | `useEffect` cleanup | Dispose geometry, textures, materials |

### Fog

| Component | Props | Description |
|-----------|-------|-------------|
| `<fog>` | `args={[color, near, far]}` | Linear fog |
| `<fogExp2>` | `args={[color, density]}` | Exponential fog |
| `<color attach="background">` | `args={[color]}` | Scene background color (match fog) |

### Performance

| Tool | Purpose | Install |
|------|---------|---------|
| r3f-perf | FPS, draw calls, memory, GPU time | `npm install r3f-perf` |
| `<Perf position="top-left" />` | Drop-in overlay inside Canvas | Import from `r3f-perf` |
| Web Workers | Offload terrain generation | Built-in, use `new Worker(...)` |

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [The Book of Shaders: Noise](https://thebookofshaders.com/11/) | Tutorial | Deep, visual explanation of noise functions with interactive examples |
| [Red Blob Games: Terrain Generation](https://www.redblobgames.com/maps/terrain-from-noise/) | Tutorial | Excellent interactive guide to noise-based terrain with code |
| [Three.js InstancedMesh Docs](https://threejs.org/docs/#api/en/objects/InstancedMesh) | Docs | Official API reference for InstancedMesh |
| [Three.js BatchedMesh Docs](https://threejs.org/docs/#api/en/objects/BatchedMesh) | Docs | Official API reference for BatchedMesh |
| [Sebastian Lague: Procedural Terrain](https://www.youtube.com/watch?v=MRNFcywkUSA) | Video | Outstanding video series on procedural terrain generation (Unity, but concepts transfer directly) |
| [Poisson Disk Sampling in Processing](https://sighack.com/post/poisson-disk-sampling-brute-force) | Tutorial | Visual explanation of the Bridson algorithm for point scattering |
| [drei Documentation](https://drei.docs.pmnd.rs/) | Docs | Reference for Detailed, Billboard, and other LOD-related helpers |

---

## Key Takeaways

1. **Noise functions are the foundation of procedural worlds.** Simplex noise with FBM (layered octaves) produces natural-looking terrain from a few parameters. Same seed = same world. Tweak frequency, amplitude, and octave count to control the shape of your landscape.

2. **InstancedMesh is your rendering workhorse.** One draw call for 10,000 trees. Use the dummy Object3D pattern to set transforms, set `needsUpdate = true` after modifying buffers, and compute bounding spheres for frustum culling.

3. **Scatter with rules, not pure randomness.** Poisson disk sampling gives even distribution. Height and slope filters make placement believable. Sample the terrain heightmap to position instances at the correct Y.

4. **Wind is a vertex shader trick.** Displace vertices using sine waves driven by time and world position. Scale displacement by vertex height so roots stay fixed. Two overlapping waves with different frequencies create organic-looking motion.

5. **Chunked loading makes infinity possible.** Divide the world into tiles, generate on demand, dispose when distant. Use fog to hide chunk boundaries. Only recalculate when the camera crosses a chunk border.

6. **Profile before optimizing.** Use r3f-perf to find the actual bottleneck — is it draw calls, triangle count, CPU-side generation, or memory? Optimize the bottleneck, not the thing you assume is slow.

---

## What's Next?

You've built a world that generates itself. Now you need things to live in it.

**[Module 9: ECS & State Management](module-09-ecs-state-management.md)** introduces the Entity-Component-System pattern for managing game objects at scale — enemies, items, NPCs, and all the dynamic entities that populate your procedural world. You'll wire up Zustand for global game state, build an event bus for decoupled communication, and learn when to use React state vs game-engine-style ECS.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)