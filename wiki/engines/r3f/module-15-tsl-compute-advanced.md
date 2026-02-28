# Module 15: TSL Compute — Advanced Patterns

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 10–14 hours
**Prerequisites:** [Module 12: WebGPU & The Cutting Edge](module-12-webgpu-cutting-edge.md), [Module 14: TSL Materials & Textures](module-14-tsl-materials-textures.md)

---

## Overview

In Module 12 you built your first GPU compute pipeline: a 100k+ particle system where every invocation mapped to one particle, each thread did its work independently, and you dispatched the whole thing with a single `gl.computeAsync()` call. That was the minimum viable compute shader — one dispatch, no coordination between threads, no multi-pass structure. It was enough to demonstrate the concept and produce something visually impressive. But real GPU simulations are fundamentally different.

Smoothed Particle Hydrodynamics (SPH) — the algorithm behind most GPU fluid simulations — cannot be implemented in a single dispatch where each thread works alone. To compute the pressure on particle A, you need to know the density of all of A's neighbors. To find those neighbors efficiently, you need a spatial data structure. Building that data structure requires threads to coordinate through atomic counters, prefix sums, and scatter operations. The result is a pipeline of five or more chained dispatches, each doing one piece of the work, with explicit synchronization between them. This module teaches you how to build that.

You'll cover shared workgroup memory for fast intra-workgroup communication, atomic operations for lock-free coordination between threads, the ping-pong buffer pattern for simulations that need double-buffering, and the full multi-dispatch pipeline pattern. The centerpiece is a 50k+ particle SPH fluid simulation: water that sloshes, compresses under pressure, and flows around obstacles. The physics are real — the math comes from the SPH literature, translated into TSL node functions. By the end, you'll have the compute programming patterns that power every serious GPU-driven simulation, ready to adapt for particle physics, cloth, smoke, or anything else that needs tens of thousands of interacting elements running at 60 fps.

---

## 1. Compute Architecture Review

### The Dispatch Model

You covered the basics in Module 12, but a quick review grounds everything that follows. When you call `.compute(N)` on a TSL compute function, Three.js translates that into a WebGPU dispatch. Internally, WebGPU launches workgroups of threads. Each workgroup contains a fixed number of invocations (threads) — 64 by default in Three.js's TSL compute system.

```
compute(50_000)
  └─ dispatch ceil(50000 / 64) = 782 workgroups
       └─ Workgroup 0: invocations 0–63
       └─ Workgroup 1: invocations 64–127
       └─ Workgroup 2: invocations 128–191
       ...
       └─ Workgroup 781: invocations 49984–49999 (plus 44 idle threads)
```

Each invocation knows three identifiers:
- **`instanceIndex`** — Global index across all workgroups. For particle systems, this is the particle index.
- **`localIndex`** — Index within the current workgroup (0–63 for default size). Used to coordinate shared memory access.
- **`workgroupIndex`** — Index of the workgroup itself. Rarely needed directly.

For most particle work, you only care about `instanceIndex`. But for the advanced patterns in this module — shared memory, parallel reduction, sorting — you need all three.

### Choosing Workgroup Sizes

The default workgroup size of 64 works well for most tasks. When should you change it?

- **Use 128 or 256** when your kernel is doing heavy math per thread and you want more threads to hide memory latency. Larger workgroups keep more warps/wavefronts in flight.
- **Use 32** when your kernel uses a lot of registers per thread (register pressure) or when you need the workgroup size to match warp size exactly for NVIDIA targets.
- **Stay at 64** for general particle systems. It's a good compromise across NVIDIA (32-thread warps run two per workgroup), AMD (64-thread wavefronts fill one workgroup exactly), and Apple Silicon (32-thread SIMD groups run two per workgroup).

You set a custom workgroup size by passing an options object to `.compute()`:

```tsx
// Default: workgroup size 64
const kernel = Fn(() => { /* ... */ })().compute(PARTICLE_COUNT)

// Custom workgroup size 128
const kernelLarge = Fn(() => { /* ... */ })().compute(PARTICLE_COUNT, 128)
```

### Memory Hierarchy

Understanding what's fast and what's slow prevents the most common compute performance mistakes:

| Memory Type | Latency | Bandwidth | Capacity | Scope |
|-------------|---------|-----------|----------|-------|
| Registers | ~1 cycle | Effectively infinite | ~64 KB per workgroup | Per thread |
| Shared (workgroup) memory | ~20 cycles | Very high | 16–32 KB per workgroup | Workgroup |
| L1 Cache | ~30 cycles | High | 32–128 KB per CU | Workgroup (automatic) |
| L2 Cache | ~200 cycles | Moderate | 2–32 MB | GPU-wide (automatic) |
| Global memory (VRAM) | ~300+ cycles | High bandwidth | GPU VRAM | GPU-wide |
| Host memory (CPU RAM) | ~3000 cycles | Low (over PCIe) | System RAM | CPU → GPU copies |

The rule: keep data in registers when possible, use shared memory for data shared within a workgroup, and minimize global memory accesses by reusing cached data. Your SPH kernel will live or die by how efficiently it accesses global memory.

### Debug Compute: Visualizing Dispatch Layout

Before building complex pipelines, a simple debug kernel that writes dispatch metadata to a buffer is invaluable for sanity-checking your layout:

```tsx
import { Fn, instanceIndex, uint, storage, workgroupIndex, localIndex } from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'

const COUNT = 256 // Small number for debugging

// Layout buffer: 3 uints per element [globalID, workgroupID, localID]
const layoutArray = new Uint32Array(COUNT * 3)
const layoutAttr = new StorageBufferAttribute(layoutArray, 3)
const layoutBuffer = storage(layoutAttr, 'uvec3', COUNT)

const debugDispatch = Fn(() => {
  const i = instanceIndex
  const slot = layoutBuffer.element(i)

  // Write global ID to x, workgroup ID to y, local ID to z
  slot.x.assign(i)                           // global invocation index
  slot.y.assign(workgroupIndex)              // which workgroup
  slot.z.assign(localIndex)                  // thread within workgroup
})().compute(COUNT)

// After dispatch, read back and inspect:
// layoutArray[0..2] = [0, 0, 0]   (first thread of first workgroup)
// layoutArray[3..5] = [1, 0, 1]   (second thread of first workgroup)
// ...
// layoutArray[64*3..] = [64, 1, 0] (first thread of second workgroup)
```

This confirms that `instanceIndex` runs from 0 to COUNT-1, `workgroupIndex` increments every 64 threads, and `localIndex` wraps 0–63 within each workgroup. Print out a few values to confirm before building anything that depends on these guarantees.

---

## 2. Shared Workgroup Memory

### What Shared Memory Is

Shared workgroup memory is a small, extremely fast on-chip SRAM that is shared by all threads in a workgroup. It is not shared between workgroups — each workgroup gets its own private block. Think of it as a scratchpad: load data from slow global memory once, work on it in fast shared memory, then write results back to global memory once.

The speed difference is significant. Global memory access (your storage buffers) is 300+ cycle latency. Shared memory is ~20 cycles — 15× faster. For algorithms that access the same data multiple times, this matters enormously.

### Declaring Shared Memory in TSL

Use `workgroupArray(type, size)` to declare shared memory:

```tsx
import { Fn, workgroupArray, instanceIndex, localIndex, workgroupIndex, workgroupBarrier } from 'three/tsl'

const computeWithShared = Fn(() => {
  // Shared array of 64 floats — one per thread in the workgroup
  const sharedData = workgroupArray('float', 64)

  // Each thread writes its global value to shared memory at its local index
  sharedData.element(localIndex).assign(myGlobalBuffer.element(instanceIndex))

  // CRITICAL: Wait for ALL threads to finish writing before reading
  workgroupBarrier()

  // Now thread 0 can read data written by thread 32
  const neighborValue = sharedData.element(localIndex.add(1).modInt(64))

  // ... process and write result to global buffer
})().compute(COUNT)
```

The `workgroupArray('float', 64)` declaration reserves 64 × 4 = 256 bytes of shared memory per workgroup. The size is a compile-time constant — you can't make it dynamic.

### workgroupBarrier() — The Synchronization Primitive

`workgroupBarrier()` is a synchronization barrier. When a thread hits it, it waits until **all** threads in the workgroup have also reached the barrier. Only then do all threads proceed past it.

Without `workgroupBarrier()`, you have a data race. Thread 0 might try to read data that thread 32 hasn't written yet. The result is undefined behavior — sometimes correct, sometimes garbage, sometimes a GPU device loss. Always barrier between writes and reads to shared memory.

```tsx
// WRONG: Reading shared data before other threads have written it
sharedData.element(localIndex).assign(globalBuffer.element(instanceIndex))
const neighbor = sharedData.element(localIndex.bitXor(1))  // RACE CONDITION
result.assign(neighbor)

// RIGHT: Barrier after all writes, before any reads
sharedData.element(localIndex).assign(globalBuffer.element(instanceIndex))
workgroupBarrier()  // All 64 threads finish their write before anyone reads
const neighbor = sharedData.element(localIndex.bitXor(1))  // Safe
result.assign(neighbor)
```

### The Tile-Based Access Pattern

The canonical use of shared memory is tiling: load a chunk of global data into shared memory once, then have all threads in the workgroup access it multiple times. This amortizes the global memory latency.

Example: smoothing particle density by averaging with neighbors. Without shared memory, each thread does N global memory reads. With shared memory, the workgroup loads once and shares the data:

```tsx
import {
  Fn, workgroupArray, workgroupBarrier, instanceIndex, localIndex,
  storage, float, clamp, uint
} from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'

const PARTICLE_COUNT = 50_000
const WORKGROUP_SIZE = 64
const RADIUS = 2 // Average over ±2 neighbors

const densityAttr = new StorageBufferAttribute(new Float32Array(PARTICLE_COUNT), 1)
const densityBuffer = storage(densityAttr, 'float', PARTICLE_COUNT)
const smoothedAttr = new StorageBufferAttribute(new Float32Array(PARTICLE_COUNT), 1)
const smoothedBuffer = storage(smoothedAttr, 'float', PARTICLE_COUNT)

const smoothDensity = Fn(() => {
  const i = instanceIndex

  // Each workgroup loads 64 densities into shared memory
  const tile = workgroupArray('float', 64)
  tile.element(localIndex).assign(densityBuffer.element(i))

  // Wait for all threads to finish loading
  workgroupBarrier()

  // Accumulate neighbors from shared memory (fast) instead of global memory (slow)
  const sum = float(0).toVar()
  const count = float(0).toVar()

  // Loop over ±RADIUS neighbors within the tile
  // (In production, you'd handle workgroup boundary cases too)
  for (let offset = -RADIUS; offset <= RADIUS; offset++) {
    const localNeighbor = localIndex.add(offset)
    const validLocal = localNeighbor.greaterThanEqual(uint(0)).and(
      localNeighbor.lessThan(uint(WORKGROUP_SIZE))
    )
    // Only accumulate if the neighbor is within this tile
    If(validLocal, () => {
      sum.addAssign(tile.element(localNeighbor))
      count.addAssign(float(1))
    })
  }

  smoothedBuffer.element(i).assign(sum.div(count))
})().compute(PARTICLE_COUNT)
```

### Shared Memory Bank Conflicts

GPU shared memory is divided into 32 banks (on most GPUs). When multiple threads in a warp access the same bank simultaneously, the accesses serialize — this is a bank conflict and it kills performance.

The rule: threads should access different banks. Since addresses modulo 32 determine the bank, strides that are multiples of 32 cause maximum conflicts.

```tsx
// FAST: Thread i accesses element i — consecutive, different banks
tile.element(localIndex).assign(...)

// SLOW: Thread i accesses element i*32 — all threads hit bank 0
tile.element(localIndex.mul(32)).assign(...)

// FAST AGAIN: Pad the array size by 1 to break stride conflicts
// If your algorithm naturally produces stride-32 access, declare:
const tile = workgroupArray('float', 65)  // 64 active + 1 padding
```

For SPH neighbor data, consecutive access patterns are natural (particles sort by cell index), so bank conflicts are rarely an issue. Just keep them in mind if your shared memory performance looks unexpectedly poor.

### Parallel Prefix Sum Within a Workgroup

The prefix sum (scan) is the core building block for sorting and spatial hashing. It converts an array like `[3, 1, 7, 2]` into `[0, 3, 4, 11]` — each element becomes the sum of all preceding elements. This is essential for computing cell offsets in your SPH grid.

The work-efficient parallel prefix sum uses a two-phase approach: reduce up the tree, then sweep down. Here's the workgroup-local version (handles 64 elements, one per thread):

```tsx
import {
  Fn, workgroupArray, workgroupBarrier, instanceIndex, localIndex, uint, int
} from 'three/tsl'

// Parallel prefix sum — result for thread i is sum of input[0..i-1]
// This version handles exactly one workgroup (64 threads, 64 elements)
const prefixSumKernel = Fn(([inputBuffer, outputBuffer]) => {
  const tile = workgroupArray('uint', 64)

  // Load into shared memory
  tile.element(localIndex).assign(inputBuffer.element(instanceIndex))
  workgroupBarrier()

  // Up-sweep (reduce) phase — build partial sums up the tree
  // After stride=1: tile[1]+=tile[0], tile[3]+=tile[2], tile[5]+=tile[4]...
  // After stride=2: tile[3]+=tile[1], tile[7]+=tile[5]...
  // After stride=32: tile[63]+=tile[31] (total sum at position 63)
  for (let stride = 1; stride < 64; stride *= 2) {
    const strideU = uint(stride)
    const idx = localIndex.mul(2).add(1).mul(strideU).sub(1)
    const validIdx = idx.lessThan(uint(64))
    workgroupBarrier()
    If(validIdx, () => {
      tile.element(idx).addAssign(tile.element(idx.sub(strideU)))
    })
  }

  // Clear the last element (exclusive scan)
  If(localIndex.equal(uint(63)), () => {
    tile.element(uint(63)).assign(uint(0))
  })
  workgroupBarrier()

  // Down-sweep phase — propagate sums back down the tree
  for (let stride = 32; stride >= 1; stride /= 2) {
    const strideU = uint(stride)
    const idx = localIndex.mul(2).add(1).mul(strideU).sub(1)
    const validIdx = idx.lessThan(uint(64))
    workgroupBarrier()
    If(validIdx, () => {
      const left = idx.sub(strideU)
      const temp = tile.element(left)
      tile.element(left).assign(tile.element(idx))
      tile.element(idx).addAssign(temp)
    })
  }

  workgroupBarrier()
  outputBuffer.element(instanceIndex).assign(tile.element(localIndex))
})
```

For datasets larger than 64 elements, you chain prefix sums: compute per-workgroup prefix sums, prefix-sum the workgroup totals, then add the workgroup offsets back to each element. This multi-pass approach is exactly what the SPH spatial grid uses for cell offsets.

---

## 3. Atomic Operations

### What Atomics Guarantee

When multiple threads write to the same memory location without coordination, you get a race condition — the final value depends on which thread wins, and it's unpredictable. Atomic operations solve this by guaranteeing that the read-modify-write cycle is indivisible: no other thread can interrupt between reading the value, modifying it, and writing it back.

The full set available in TSL:

| TSL Atomic | WGSL Equivalent | What It Does |
|------------|----------------|--------------|
| `atomicAdd(ptr, val)` | `atomicAdd` | Add val, return old value |
| `atomicSub(ptr, val)` | `atomicSub` | Subtract val, return old value |
| `atomicMin(ptr, val)` | `atomicMin` | Keep minimum, return old value |
| `atomicMax(ptr, val)` | `atomicMax` | Keep maximum, return old value |
| `atomicAnd(ptr, val)` | `atomicAnd` | Bitwise AND, return old value |
| `atomicOr(ptr, val)` | `atomicOr` | Bitwise OR, return old value |
| `atomicXor(ptr, val)` | `atomicXor` | Bitwise XOR, return old value |
| `atomicExchange(ptr, val)` | `atomicExchange` | Set to val, return old value |
| `atomicCompareExchange(ptr, cmp, val)` | `atomicCompareExchange` | CAS operation |

Atomics work on `uint` and `int` types only — not `float`. For floating-point accumulation, use either integer representation (fixed-point) or a reduction pattern (see Section 6).

### Particle Counter: Counting Per-Cell

The most common use of atomics in SPH is counting how many particles are in each grid cell. Every particle thread reads its grid cell index and atomically increments that cell's counter. Thousands of threads may target the same cell — atomics ensure the count is correct:

```tsx
import {
  Fn, instanceIndex, atomicAdd, storage, uint, vec3, float, floor, clamp
} from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'

const PARTICLE_COUNT = 50_000
const GRID_W = 50, GRID_H = 25, GRID_D = 50
const GRID_CELLS = GRID_W * GRID_H * GRID_D  // 62,500 cells
const CELL_SIZE = 0.4  // Must be >= SPH smoothing radius h

// Positions buffer (written by integration pass)
const posAttr = new StorageBufferAttribute(new Float32Array(PARTICLE_COUNT * 3), 3)
const posBuffer = storage(posAttr, 'vec3', PARTICLE_COUNT)

// Cell counts — how many particles in each cell (uint for atomics)
const cellCountAttr = new StorageBufferAttribute(new Uint32Array(GRID_CELLS), 1)
const cellCountBuffer = storage(cellCountAttr, 'uint', GRID_CELLS)

// Helper: 3D grid position → flat cell index
function gridHash(gx: any, gy: any, gz: any) {
  // Clamp to grid bounds first
  const cx = clamp(gx, uint(0), uint(GRID_W - 1))
  const cy = clamp(gy, uint(0), uint(GRID_H - 1))
  const cz = clamp(gz, uint(0), uint(GRID_D - 1))
  return cx.add(cy.mul(uint(GRID_W))).add(cz.mul(uint(GRID_W * GRID_H)))
}

// Pass 1: Count particles per cell
const countPass = Fn(() => {
  const i = instanceIndex
  const pos = posBuffer.element(i)

  // Map world position to grid cell indices
  // Grid origin at (0, 0, 0), cell size CELL_SIZE
  const gx = floor(pos.x.div(float(CELL_SIZE))).toUint()
  const gy = floor(pos.y.div(float(CELL_SIZE))).toUint()
  const gz = floor(pos.z.div(float(CELL_SIZE))).toUint()

  const cellIdx = gridHash(gx, gy, gz)

  // Atomically increment the cell counter
  // Multiple particles in the same cell are safe — atomicAdd serializes them
  atomicAdd(cellCountBuffer.element(cellIdx), uint(1))
})().compute(PARTICLE_COUNT)
```

After this dispatch, `cellCountBuffer` contains the exact count for each cell. Now you have the raw material for building a prefix sum that converts counts into offsets — the second step of the spatial grid.

### Resetting Atomic Counters Between Frames

Every frame, before the count pass, you must reset all cell counts to zero. This is a separate dispatch that clears the buffer:

```tsx
const resetCounts = Fn(() => {
  // Each thread clears one cell
  cellCountBuffer.element(instanceIndex).assign(uint(0))
})().compute(GRID_CELLS)
```

Forgetting to reset is one of the most common SPH bugs. Counts accumulate across frames and your grid becomes meaningless. This reset dispatch takes a fraction of a millisecond and must run first in the pipeline every frame.

### Minimizing Atomic Contention

Atomics serialize threads that target the same address. If all particles are clustered in one area (at initialization, or after gravity collapses them), many threads hit the same few cells, and atomic throughput drops. Strategies to minimize contention:

1. **Ensure good spatial distribution**: Don't start all particles at the same position.
2. **Keep cell sizes reasonable**: Smaller cells mean more cells and less contention per cell.
3. **Use shared memory atomics for intra-workgroup counting**: `atomicAdd` to shared memory is faster than global memory atomics. Use a two-phase approach: accumulate within a workgroup in shared memory, then one thread per workgroup does a single global atomic.

For the SPH simulation in this module, global atomics are fast enough at 50k particles. You'd need 500k+ particles before the contention overhead becomes the dominant cost.

---

## 4. Multi-Buffer Ping-Pong

### Why You Can't Read and Write the Same Buffer

Imagine every thread reads its current position, adds velocity, and writes the new position — all to the same buffer. Thread 0 reads position 0 and writes a new position. Thread 1 might read the new value written by thread 0 before doing its own computation, or it might read the old value. Which one depends on scheduling, which is GPU-hardware-dependent and non-deterministic. The simulation would produce different results every run. This is a race condition.

The solution is double buffering: maintain two copies of the data. Read from buffer A, write to buffer B. At the end of the frame, swap which buffer is "current" and which is "next." This eliminates all read-write hazards because reads and writes go to separate physical locations.

### Implementing Ping-Pong in TSL

```tsx
import {
  Fn, instanceIndex, storage, vec3, float, If
} from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'
import { useRef } from 'react'

const COUNT = 50_000

// Two position buffers — identical structure
function makeBuffer(count: number, components: number) {
  const arr = new Float32Array(count * components)
  const attr = new StorageBufferAttribute(arr, components)
  return { attr, buffer: storage(attr, components === 3 ? 'vec3' : 'float', count) }
}

// pos0 and pos1 alternate between "current" and "next" roles
const pos0 = makeBuffer(COUNT, 3)
const pos1 = makeBuffer(COUNT, 3)
const vel0 = makeBuffer(COUNT, 3)
const vel1 = makeBuffer(COUNT, 3)

// The swap flag (ping-pong index): 0 means "read from 0, write to 1"
//                                  1 means "read from 1, write to 0"
let pingPong = 0

// Build two kernel variants: one for each direction
function makeIntegrateKernel(readPos: any, writePos: any, readVel: any, writeVel: any) {
  return Fn(() => {
    const i = instanceIndex
    const pos = readPos.element(i)
    const vel = readVel.element(i)

    // Simple Euler integration (SPH uses proper forces, but structure is the same)
    const newVel = vel.add(vec3(0, float(-9.8).mul(0.016), 0)) // gravity
    const newPos = pos.add(newVel.mul(float(0.016)))

    writePos.element(i).assign(newPos)
    writeVel.element(i).assign(newVel)
  })().compute(COUNT)
}

// Pre-build both directions of the ping-pong
const kernel0to1 = makeIntegrateKernel(pos0.buffer, pos1.buffer, vel0.buffer, vel1.buffer)
const kernel1to0 = makeIntegrateKernel(pos1.buffer, pos0.buffer, vel1.buffer, vel0.buffer)

// In useFrame:
// gl.computeAsync(pingPong === 0 ? kernel0to1 : kernel1to0)
// pingPong = 1 - pingPong  // swap

// The "current" position for rendering:
// const renderBuffer = pingPong === 0 ? pos0.buffer : pos1.buffer
```

The rendering buffer follows the same swap — whatever was just written to is what you render from. The CPU never uploads any particle data; it just toggles the `pingPong` index.

### Game of Life: Full Ping-Pong Example

Conway's Game of Life on the GPU is the cleanest demo of ping-pong. Each cell's next state depends on its neighbors' current state — you can't update in-place:

```tsx
import { Fn, instanceIndex, storage, uint, If } from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'
import { useFrame } from '@react-three/fiber'
import { useRef, useMemo } from 'react'
import { Points, PointsMaterial } from 'three'
import { MeshBasicNodeMaterial } from 'three/webgpu'
import { storageObject } from 'three/tsl'

const W = 256, H = 256
const CELL_COUNT = W * H

function makeCell(count: number) {
  const arr = new Uint32Array(count)
  // Seed with random cells
  for (let i = 0; i < count; i++) arr[i] = Math.random() < 0.3 ? 1 : 0
  const attr = new StorageBufferAttribute(arr, 1)
  return { attr, buf: storage(attr, 'uint', count) }
}

function neighborIndex(ix: any, iy: any) {
  // Wrap around edges (toroidal topology)
  const wx = ix.add(uint(W)).modInt(uint(W))
  const wy = iy.add(uint(H)).modInt(uint(H))
  return wy.mul(uint(W)).add(wx)
}

function makeStepKernel(readBuf: any, writeBuf: any) {
  return Fn(() => {
    const i = instanceIndex
    const ix = i.modInt(uint(W))
    const iy = i.div(uint(W))

    // Count live neighbors (8-connected)
    const n = uint(0).toVar()
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0) continue
        const ni = neighborIndex(ix.add(int(dx)), iy.add(int(dy)))
        n.addAssign(readBuf.element(ni))
      }
    }

    const alive = readBuf.element(i)
    // B3/S23 rules: born if 3 neighbors, survives if 2 or 3
    const born = alive.equal(uint(0)).and(n.equal(uint(3)))
    const survives = alive.equal(uint(1)).and(n.greaterThanEqual(uint(2))).and(n.lessThanEqual(uint(3)))
    writeBuf.element(i).assign(born.or(survives).toUint())
  })().compute(CELL_COUNT)
}

export function GameOfLife() {
  const a = useMemo(() => makeCell(CELL_COUNT), [])
  const b = useMemo(() => makeCell(CELL_COUNT), [])
  const kernelAtoB = useMemo(() => makeStepKernel(a.buf, b.buf), [a, b])
  const kernelBtoA = useMemo(() => makeStepKernel(b.buf, a.buf), [a, b])
  const ping = useRef(0)

  useFrame(({ gl }) => {
    gl.computeAsync(ping.current === 0 ? kernelAtoB : kernelBtoA)
    ping.current = 1 - ping.current
  })

  // Render current buffer as a grid of points...
  return null // (rendering code omitted for brevity — use Points with instancedBuffer)
}
```

Triple buffering follows the same pattern with three buffers cycling through current → previous → oldest → (reused as next). This is useful when a simulation needs both the current and immediately previous state simultaneously (e.g., velocity Verlet integration).

---

## 5. Multi-Dispatch Pipelines

### Implicit Synchronization Between Dispatches

WebGPU guarantees that compute dispatches submitted to the same queue execute in submission order. When you call `gl.computeAsync(passA)` followed by `gl.computeAsync(passB)`, passB cannot begin until passA has completed. This is your synchronization primitive for multi-pass pipelines — no explicit barriers needed between dispatches.

Within a single dispatch, threads within the same workgroup can synchronize with `workgroupBarrier()`. But threads in different workgroups — even in the same dispatch — cannot synchronize. This is the fundamental reason you need multiple dispatches for SPH: density computation requires all particles to have updated grid positions before any particle reads its neighbors' densities. That global synchronization point only exists at the dispatch boundary.

### The SPH Multi-Dispatch Pipeline

Every frame, the SPH simulation runs these dispatches in order:

```
Frame start
    │
    ▼
[Dispatch 0] Reset grid cell counts to zero (N_CELLS threads)
    │
    ▼
[Dispatch 1] Count particles per cell (N_PARTICLES threads, atomicAdd)
    │
    ▼
[Dispatch 2] Prefix sum: cell counts → cell offsets (N_CELLS threads)
    │
    ▼
[Dispatch 3] Scatter: write particle indices into sorted order (N_PARTICLES threads, atomicAdd)
    │
    ▼
[Dispatch 4] Compute density for each particle (N_PARTICLES threads, neighbor search)
    │
    ▼
[Dispatch 5] Compute pressure + viscosity forces (N_PARTICLES threads, neighbor search)
    │
    ▼
[Dispatch 6] Integrate velocity and position (N_PARTICLES threads)
    │
    ▼
[Render] Draw particles from position buffer
```

Each dispatch is a complete synchronization point. Dispatch 4 cannot start until all 50,000 particles have been scattered into sorted order by Dispatch 3. This ordering is what makes neighbor lookup correct.

### Two-Pass Density and Force Example

Here's the structural pattern for the critical density-then-forces pipeline, simplified to show the multi-dispatch architecture:

```tsx
import { Fn, instanceIndex, atomicAdd, storage, vec3, float, uint, If } from 'three/tsl'
import { useFrame } from '@react-three/fiber'

// Buffers shared between passes
// posBuffer, velBuffer: particle state
// densityBuffer: written by pass 1, read by pass 2
// forceBuffer: written by pass 2, read by integration pass
// cellCount, cellOffset, sortedIdx: grid data

// Pass A: Compute density for each particle
// Reads: posBuffer, cellOffset, cellCount, sortedIdx (all from scatter pass)
// Writes: densityBuffer
const densityPass = Fn(() => {
  const i = instanceIndex
  const pos = posBuffer.element(i)

  // Find the grid cell for this particle
  const gx = floor(pos.x.div(float(CELL_SIZE))).toUint()
  const gy = floor(pos.y.div(float(CELL_SIZE))).toUint()
  const gz = floor(pos.z.div(float(CELL_SIZE))).toUint()

  // Sum contributions from particles in the 27 neighboring cells (3×3×3)
  const density = float(0).toVar()
  for (let dz = -1; dz <= 1; dz++) {
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        const nx = gx.add(int(dx))
        const ny = gy.add(int(dy))
        const nz = gz.add(int(dz))
        const inBounds = nx.greaterThanEqual(uint(0)).and(nx.lessThan(uint(GRID_W)))
          .and(ny.greaterThanEqual(uint(0))).and(ny.lessThan(uint(GRID_H)))
          .and(nz.greaterThanEqual(uint(0))).and(nz.lessThan(uint(GRID_D)))

        If(inBounds, () => {
          const cellIdx = nx.add(ny.mul(uint(GRID_W))).add(nz.mul(uint(GRID_W * GRID_H)))
          const start = cellOffsetBuffer.element(cellIdx)
          const count = cellCountBuffer.element(cellIdx)

          // Iterate over all particles in this neighbor cell
          Loop({ start, count: start.add(count) }, ({ i: j }) => {
            const jIdx = sortedIdxBuffer.element(j)
            const jPos = posBuffer.element(jIdx)
            const r = pos.sub(jPos)
            const rLen = length(r)

            // SPH poly6 kernel: W_poly6(r, h) = (315/64πh⁹)(h²-r²)³ for r ≤ h
            If(rLen.lessThanEqual(float(SPH_H)), () => {
              const h2 = float(SPH_H * SPH_H)
              const diff = h2.sub(rLen.mul(rLen))
              const w = diff.mul(diff).mul(diff).mul(float(POLY6_FACTOR))
              density.addAssign(float(PARTICLE_MASS).mul(w))
            })
          })
        })
      }
    }
  }

  densityBuffer.element(i).assign(density)
})().compute(PARTICLE_COUNT)

// Pass B: Compute pressure forces — reads density written by Pass A
// This dispatch cannot run until ALL densities are computed
const forcePass = Fn(() => {
  const i = instanceIndex
  const pos = posBuffer.element(i)
  const densityI = densityBuffer.element(i)  // Reading data from Pass A

  // Pressure from equation of state: P = k(ρ - ρ₀)
  const pressureI = float(PRESSURE_K).mul(densityI.sub(float(REST_DENSITY)))

  const force = vec3(0, 0, 0).toVar()

  // ... neighbor loop identical to density pass, but computing pressure + viscosity forces
  // Uses densityBuffer.element(jIdx) — safe because Pass A completed before Pass B dispatched

  forceBuffer.element(i).assign(force)
})().compute(PARTICLE_COUNT)

// Integration pass: reads forceBuffer written by forcePass
const integratePass = Fn(() => {
  const i = instanceIndex
  const vel = velBuffer.element(i)
  const pos = posBuffer.element(i)
  const force = forceBuffer.element(i)
  const density = densityBuffer.element(i)

  const accel = force.div(density.max(float(0.001)))  // F = ma → a = F/m (m = ρ for SPH)
  const newVel = vel.add(accel.mul(float(DT)))
  const newPos = pos.add(newVel.mul(float(DT)))

  velBuffer.element(i).assign(newVel)
  posBuffer.element(i).assign(newPos)
})().compute(PARTICLE_COUNT)

// In useFrame — dispatches execute in order, each waiting for the previous:
useFrame(({ gl }) => {
  gl.computeAsync(resetPass)
  gl.computeAsync(countPass)
  gl.computeAsync(prefixSumPass)
  gl.computeAsync(scatterPass)
  gl.computeAsync(densityPass)
  gl.computeAsync(forcePass)
  gl.computeAsync(integratePass)
})
```

The ordering guarantee is everything. `densityPass` can safely read positions that `scatterPass` wrote because `scatterPass` completed first. `forcePass` can safely read densities because `densityPass` completed first. Sequential dispatch = global synchronization.

---

## 6. Parallel Reduction

### The Problem: Computing a Global Aggregate

You want the sum, min, max, or average of N values on the GPU. The naive approach — one thread reads all N values and computes the aggregate — wastes 99.99% of the GPU and is no faster than doing it on the CPU. The atomic approach — every thread does `atomicAdd` to a shared counter — serializes all N threads at one memory address and is even worse.

The correct approach is tree reduction: split the work hierarchically, halving the active threads each round until one value remains.

### Tree Reduction Within a Workgroup

For N ≤ 64 values (one workgroup), the algorithm:

```
Input: [a₀, a₁, a₂, a₃, a₄, a₅, a₆, a₇]  (8 values, 8 threads)

Step 1 (stride=4): Thread 0 reads a₀+a₄, Thread 1 reads a₁+a₅, etc.
Shared: [a₀+a₄, a₁+a₅, a₂+a₆, a₃+a₇, -, -, -, -]

Step 2 (stride=2): Thread 0 reads (a₀+a₄)+(a₂+a₆), Thread 1 reads (a₁+a₅)+(a₃+a₇)
Shared: [(a₀+a₄+a₂+a₆), (a₁+a₅+a₃+a₇), -, -, -, -, -, -]

Step 3 (stride=1): Thread 0 reads the total sum
Shared: [total, -, -, -, -, -, -, -]
```

log₂(N) steps, each of which runs N/2 threads in parallel. Total work: O(N), total time: O(log N). This is optimal.

### Cross-Workgroup Reduction

For N > 64, you need multiple workgroups. Each workgroup reduces its 64-element tile to a single value and writes it to a secondary buffer. Then a second dispatch reduces that secondary buffer:

```tsx
import { Fn, workgroupArray, workgroupBarrier, instanceIndex, localIndex, workgroupIndex, uint, float } from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'

const PARTICLE_COUNT = 50_000
const WORKGROUP_SIZE = 64
const NUM_WORKGROUPS = Math.ceil(PARTICLE_COUNT / WORKGROUP_SIZE)

// Input: per-particle values (e.g., positions for center-of-mass)
// Output: per-workgroup partial sums
const partialSumAttr = new StorageBufferAttribute(new Float32Array(NUM_WORKGROUPS * 3), 3)
const partialSumBuffer = storage(partialSumAttr, 'vec3', NUM_WORKGROUPS)

// Final result: single vec3 (center of mass)
const resultAttr = new StorageBufferAttribute(new Float32Array(3), 3)
const resultBuffer = storage(resultAttr, 'vec3', 1)

// Pass 1: Each workgroup computes the sum of its 64 particles
const reducePass1 = Fn(() => {
  const tile = workgroupArray('vec3', 64)
  const i = instanceIndex

  // Load or zero-pad if out of range
  If(i.lessThan(uint(PARTICLE_COUNT)), () => {
    tile.element(localIndex).assign(posBuffer.element(i))
  }).Else(() => {
    tile.element(localIndex).assign(vec3(0, 0, 0))
  })

  workgroupBarrier()

  // Tree reduction: stride from 32 down to 1
  for (let stride = 32; stride >= 1; stride >>= 1) {
    const active = localIndex.lessThan(uint(stride))
    workgroupBarrier()
    If(active, () => {
      tile.element(localIndex).addAssign(tile.element(localIndex.add(uint(stride))))
    })
  }

  // Thread 0 of each workgroup writes the partial sum
  If(localIndex.equal(uint(0)), () => {
    partialSumBuffer.element(workgroupIndex).assign(tile.element(uint(0)))
  })
})().compute(Math.ceil(PARTICLE_COUNT / WORKGROUP_SIZE) * WORKGROUP_SIZE) // round up to full workgroup

// Pass 2: Reduce the partial sums (NUM_WORKGROUPS values → 1)
// For 782 workgroups, this fits in 13 workgroups of 64
const reducePass2 = Fn(() => {
  const tile = workgroupArray('vec3', 64)
  const i = instanceIndex

  If(i.lessThan(uint(NUM_WORKGROUPS)), () => {
    tile.element(localIndex).assign(partialSumBuffer.element(i))
  }).Else(() => {
    tile.element(localIndex).assign(vec3(0, 0, 0))
  })

  workgroupBarrier()

  for (let stride = 32; stride >= 1; stride >>= 1) {
    workgroupBarrier()
    If(localIndex.lessThan(uint(stride)), () => {
      tile.element(localIndex).addAssign(tile.element(localIndex.add(uint(stride))))
    })
  }

  // Only workgroup 0, thread 0 writes the final result
  If(workgroupIndex.equal(uint(0)).and(localIndex.equal(uint(0))), () => {
    // Divide by particle count to get average position (center of mass)
    resultBuffer.element(uint(0)).assign(
      tile.element(uint(0)).div(float(PARTICLE_COUNT))
    )
  })
})().compute(Math.ceil(NUM_WORKGROUPS / WORKGROUP_SIZE) * WORKGROUP_SIZE)

// Usage in frame:
// gl.computeAsync(reducePass1)   // 782 partial sums
// gl.computeAsync(reducePass2)   // single result
```

For most game purposes (average position, total energy, maximum velocity), two passes handle any practical particle count. If you need more, add more passes — it's still O(log N) dispatches.

---

## 7. GPU Sorting

### Why Sorting Matters for SPH

The neighbor search in SPH iterates over particles in the 27 cells surrounding the target particle. If particles are stored in random order, neighboring particles in space are scattered all over your buffers, and every read is a random-access cache miss. This is disastrous for performance.

If you sort particles by their grid cell index, particles that are spatially adjacent are also adjacent in memory. The 27-cell neighbor loop becomes sequential reads from a contiguous region of the buffer. Cache miss rate drops dramatically — this can improve SPH performance by 3–5× compared to unsorted storage.

### Bitonic Sort: The Simplest Parallel Sort

Bitonic sort is a comparison-based sorting network. It works by repeatedly performing compare-and-swap operations on pairs of elements. The algorithm has two nice properties for GPU implementation: every comparison-and-swap is independent of every other one in the same step, and the access pattern is regular and deterministic.

How it works mathematically: a bitonic sequence is one that first monotonically increases, then monotonically decreases (or vice versa). Bitonic sort works by repeatedly merging small bitonic sequences into larger ones, until the entire array is sorted.

For an array of N elements, bitonic sort requires O(log²N) steps. Each step is a compare-and-swap pass, implemented as one compute dispatch. For 50,000 particles (rounded to the next power of 2: 65,536), that's log₂(65536) = 16 major passes, each with up to 16 sub-passes = 136 dispatches per sort.

At first this sounds like a lot. But each dispatch is tiny — the GPU executes all 65,536 compare-and-swaps in parallel. The total time is usually < 1ms for 50k elements.

```tsx
import { Fn, instanceIndex, uint, storage, If } from 'three/tsl'
import { StorageBufferAttribute } from 'three/webgpu'

// Sort 'keys' by value — in SPH, keys are cell indices, values are particle indices
// After sort, particles are ordered by cell: all particles in cell 0, then cell 1, etc.
const N_PADDED = 65536  // Must be power of 2; pad with MAX_UINT for out-of-range

const keysAttr = new StorageBufferAttribute(new Uint32Array(N_PADDED).fill(0xFFFFFFFF), 1)
const keysBuffer = storage(keysAttr, 'uint', N_PADDED)
const valsAttr = new StorageBufferAttribute(new Uint32Array(N_PADDED).fill(0xFFFFFFFF), 1)
const valsBuffer = storage(valsAttr, 'uint', N_PADDED)

// One bitonic sort step: given (k, j), compare and swap pairs
// k = size of the current bitonic sequence being merged
// j = current comparison stride
function makeBitonicStep(k: number, j: number) {
  return Fn(() => {
    const i = instanceIndex
    // Compute the index of the element to compare with
    const l = i.bitXor(uint(j))

    If(l.greaterThan(i), () => {
      const iKey = keysBuffer.element(i)
      const lKey = keysBuffer.element(l)

      // Determine the sort direction: ascending if (i & k) == 0, descending otherwise
      const ascending = i.bitAnd(uint(k)).equal(uint(0))

      // Swap if out of order for the current direction
      const shouldSwap = ascending.and(iKey.greaterThan(lKey))
        .or(ascending.not().and(iKey.lessThan(lKey)))

      If(shouldSwap, () => {
        // Swap keys
        keysBuffer.element(i).assign(lKey)
        keysBuffer.element(l).assign(iKey)
        // Swap values in parallel (keep key-value pairs together)
        const iVal = valsBuffer.element(i)
        const lVal = valsBuffer.element(l)
        valsBuffer.element(i).assign(lVal)
        valsBuffer.element(l).assign(iVal)
      })
    })
  })().compute(N_PADDED)
}

// Pre-build all bitonic sort step kernels
// log²(N) steps total
const bitonicKernels: ReturnType<typeof makeBitonicStep>[] = []
for (let k = 2; k <= N_PADDED; k *= 2) {
  for (let j = k >> 1; j >= 1; j >>= 1) {
    bitonicKernels.push(makeBitonicStep(k, j))
  }
}

// In useFrame, after filling keys/values from count + scatter:
// bitonicKernels.forEach(kernel => gl.computeAsync(kernel))
// This dispatches all 136 sort passes; WebGPU executes them in order.
```

The practical concern: pre-building all 136 kernels at init time avoids runtime compilation stalls. Do it once in `useMemo`, never in `useFrame`.

### When to Sort on GPU vs CPU

| Dataset Size | Recommendation |
|-------------|----------------|
| < 1,000 | Sort on CPU — less overhead |
| 1,000–10,000 | Either; GPU wins if data already on GPU |
| 10,000–100,000 | GPU wins clearly (bitonic sort) |
| > 100,000 | GPU (bitonic) or GPU radix sort |

For 50k SPH particles, GPU bitonic sort is clearly the right choice. The sort completes in 0.5–2ms and the cache locality improvement pays for itself many times over in the neighbor search.

---

## 8. Spatial Data Structures

### Grid Hashing

The spatial hash grid is the most practical neighbor data structure for SPH at game-relevant particle counts. The idea: divide space into a regular grid of cells. Each cell has side length equal to the SPH smoothing radius `h`. To find a particle's neighbors, you only need to check the 27 cells in the 3×3×3 cube centered on the particle's cell.

The grid maps a 3D cell coordinate `(ix, iy, iz)` to a flat buffer index:

```
cellIndex = ix + iy * GRID_W + iz * GRID_W * GRID_H
```

This is only valid for a bounded simulation domain. For unbounded domains, use a hash function instead:

```tsx
// Hash for unbounded domain — maps any (ix, iy, iz) to [0, HASH_SIZE)
function spatialHash(ix: any, iy: any, iz: any) {
  // Large primes to minimize collisions
  const p1 = uint(73856093)
  const p2 = uint(19349663)
  const p3 = uint(83492791)
  return ix.mul(p1).bitXor(iy.mul(p2)).bitXor(iz.mul(p3)).modInt(uint(HASH_TABLE_SIZE))
}
```

For the bounded water-box simulation in this module, the flat index is simpler and collision-free.

### The Three-Dispatch Grid Build

Building the grid from scratch each frame requires three dispatches:

**Dispatch 1: Count** — atomicAdd to cellCount for each particle's cell.

**Dispatch 2: Prefix sum** — convert counts to exclusive offsets. After this, `cellOffset[c]` is the index in the sorted array where cell c's particles begin.

**Dispatch 3: Scatter** — each particle reads its cell's offset, atomicAdds to get its unique slot, and writes its own index to that slot.

```tsx
// After Dispatch 3, you have:
// sortedIdx[cellOffset[c] ... cellOffset[c] + cellCount[c] - 1]
//   = indices of all particles in cell c, in some order

// Neighbor search for particle i:
// 1. Find cell (cx, cy, cz)
// 2. For each of the 27 neighbor cells:
//    a. start = cellOffset[neighborCell]
//    b. count = cellCount[neighborCell]
//    c. For j in start..start+count: process particle sortedIdx[j]
```

The scatter dispatch uses the same atomicAdd trick as the count dispatch, but now it's writing indices rather than incrementing:

```tsx
// Scatter pass: each particle finds its sorted position and writes its index
const scatterPass = Fn(() => {
  const i = instanceIndex
  const pos = posBuffer.element(i)

  const gx = floor(pos.x.div(float(CELL_SIZE))).toUint()
  const gy = floor(pos.y.div(float(CELL_SIZE))).toUint()
  const gz = floor(pos.z.div(float(CELL_SIZE))).toUint()
  const cellIdx = gx.add(gy.mul(uint(GRID_W))).add(gz.mul(uint(GRID_W * GRID_H)))

  // atomicAdd returns the old value — that's this particle's unique slot in the sorted array
  // We use a separate scatter counter buffer (reset to cellOffset at start of each frame)
  const slot = atomicAdd(scatterCountBuffer.element(cellIdx), uint(1))
  const writeIdx = cellOffsetBuffer.element(cellIdx).add(slot)
  sortedIdxBuffer.element(writeIdx).assign(i)
})().compute(PARTICLE_COUNT)
```

After this, `sortedIdxBuffer` contains particle indices ordered by grid cell. The density and force passes iterate over this sorted array for fast, cache-friendly neighbor access.

---

## 9. Indirect Dispatch

### Letting the GPU Decide Workload Size

In a fixed-size simulation, you always dispatch for N particles. But many simulations have variable-length workloads: only active particles need processing, only non-empty cells need neighbor searches, only visible tiles need rendering. Dispatching for the maximum possible count wastes GPU time on no-op threads.

Indirect dispatch solves this: instead of specifying the workgroup count as a CPU-side constant, you write it into a GPU buffer from a compute pass, then dispatch using that buffer as the argument source.

### The Indirect Buffer Format

An indirect dispatch buffer contains three `uint32` values: `(workgroupCountX, workgroupCountY, workgroupCountZ)`. For 1D compute (which all our simulations are), Y and Z are both 1:

```tsx
import { StorageBufferAttribute } from 'three/webgpu'

// Indirect buffer: [workgroupCountX, workgroupCountY, workgroupCountZ]
const indirectArray = new Uint32Array([0, 1, 1])  // Start with 0 workgroups
const indirectAttr = new StorageBufferAttribute(indirectArray, 3)
```

### Writing Indirect Args from a Compute Pass

A first compute pass determines the active count and writes the indirect args:

```tsx
import { Fn, atomicAdd, storage, uint, instanceIndex, If } from 'three/tsl'

// Active particle count buffer (single uint, reset to 0 each frame)
const activeCountAttr = new StorageBufferAttribute(new Uint32Array(1), 1)
const activeCountBuffer = storage(activeCountAttr, 'uint', 1)

// Indirect args buffer
const indirectBuffer = storage(indirectAttr, 'uvec3', 1)

// Pass 1: count active particles
const countActivePass = Fn(() => {
  const i = instanceIndex
  const life = lifeBuffer.element(i)

  If(life.greaterThan(float(0)), () => {
    atomicAdd(activeCountBuffer.element(uint(0)), uint(1))
  })
})().compute(PARTICLE_COUNT)

// Pass 2: convert active count to workgroup count and write to indirect buffer
const writeIndirectPass = Fn(() => {
  // Only one thread needs to do this
  If(instanceIndex.equal(uint(0)), () => {
    const activeCount = activeCountBuffer.element(uint(0))
    // ceil(activeCount / 64) workgroups
    const workgroups = activeCount.add(uint(63)).div(uint(64))
    indirectBuffer.element(uint(0)).x.assign(workgroups)
    indirectBuffer.element(uint(0)).y.assign(uint(1))
    indirectBuffer.element(uint(0)).z.assign(uint(1))
  })
})().compute(1)

// Pass 3: process only active particles (GPU decides workgroup count)
// gl.computeAsyncIndirect(processActivePass, indirectAttr)
```

The `computeAsyncIndirect` API (or its Three.js wrapper equivalent) reads the workgroup count from the buffer rather than a JavaScript constant. The CPU submits the command without knowing how many particles are active — the GPU knows.

Indirect dispatch is most valuable when your active count varies significantly frame-to-frame — particle systems with death and respawn, simulations with pruning, or GPU-side LOD systems that process fewer tiles at distance.

---

## 10. Code Walkthrough: GPU Fluid Simulation

The mini-project is a full SPH fluid simulation: 50,000 water particles in a bounded box, simulating density, pressure, and viscosity. Particles respond to gravity, bounce off walls, and are color-mapped by velocity magnitude.

### SPH Physics Background

SPH approximates continuous fluid properties by summing contributions from nearby particles. Each particle has a position, velocity, density, and pressure. The key equations:

**Density** at particle i:
```
ρᵢ = Σⱼ mⱼ · W_poly6(|rᵢ - rⱼ|, h)
```
where `W_poly6(r, h) = (315 / 64πh⁹)(h² - r²)³` for r ≤ h

**Pressure** from equation of state (Tait equation, more stable than ideal gas):
```
Pᵢ = k(ρᵢ/ρ₀ - 1)
```

**Pressure force** on particle i:
```
Fᵢ_pressure = -Σⱼ mⱼ (Pᵢ + Pⱼ)/(2ρⱼ) · ∇W_spiky(|rᵢ - rⱼ|, h)
```
where `∇W_spiky(r, h) = -45/πh⁶ (h - r)² r̂` for r ≤ h

**Viscosity force**:
```
Fᵢ_viscosity = μ Σⱼ mⱼ (vⱼ - vᵢ)/ρⱼ · ∇²W_visc(|rᵢ - rⱼ|, h)
```
where `∇²W_visc(r, h) = 45/πh⁶ (h - r)` for r ≤ h

The implementation below translates these equations directly into TSL compute nodes.

### Full SPH Implementation

```tsx
// FluidSimulation.tsx
import { useRef, useMemo, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { useControls } from 'leva'
import { StorageBufferAttribute, MeshBasicNodeMaterial } from 'three/webgpu'
import {
  Fn, instanceIndex, localIndex, workgroupIndex, workgroupBarrier, workgroupArray,
  storage, storageObject, uniform, vec3, vec4, float, uint, int,
  floor, clamp, length, normalize, mix, pow, abs, max, min,
  atomicAdd, If, Loop,
  positionGeometry
} from 'three/tsl'
import { Points, BufferGeometry, Float32BufferAttribute, Color } from 'three'

// ── Constants ─────────────────────────────────────────────────────────────────

const PARTICLE_COUNT = 50_000
const SPH_H         = 0.4          // smoothing radius
const SPH_H2        = SPH_H * SPH_H
const PARTICLE_MASS = 0.02
const REST_DENSITY  = 1000.0       // kg/m³ (water)
const PRESSURE_K    = 200.0        // stiffness constant
const VISCOSITY     = 0.1          // dynamic viscosity
const DT            = 0.008        // timestep in seconds
const CELL_SIZE     = SPH_H        // cell size = smoothing radius (important!)

// Simulation domain
const DOMAIN = { x: 8, y: 6, z: 8 }
const GRID_W = Math.floor(DOMAIN.x / CELL_SIZE)  // 20
const GRID_H = Math.floor(DOMAIN.y / CELL_SIZE)  // 15
const GRID_D = Math.floor(DOMAIN.z / CELL_SIZE)  // 20
const GRID_CELLS = GRID_W * GRID_H * GRID_D       // 6000

// SPH kernel normalization constants
const POLY6_FACTOR   = 315.0 / (64.0 * Math.PI * Math.pow(SPH_H, 9))
const SPIKY_GRAD     = -45.0 / (Math.PI * Math.pow(SPH_H, 6))
const VISC_LAP       = 45.0  / (Math.PI * Math.pow(SPH_H, 6))

// ── Buffer creation helpers ───────────────────────────────────────────────────

function makeVec3Buffer(count: number, init?: (i: number, arr: Float32Array) => void) {
  const arr = new Float32Array(count * 3)
  if (init) for (let i = 0; i < count; i++) init(i, arr)
  const attr = new StorageBufferAttribute(arr, 3)
  return { attr, buf: storage(attr, 'vec3', count) }
}

function makeFloatBuffer(count: number, fill = 0) {
  const attr = new StorageBufferAttribute(new Float32Array(count).fill(fill), 1)
  return { attr, buf: storage(attr, 'float', count) }
}

function makeUintBuffer(count: number, fill = 0) {
  const attr = new StorageBufferAttribute(new Uint32Array(count).fill(fill), 1)
  return { attr, buf: storage(attr, 'uint', count) }
}

// ── Buffer initialization ─────────────────────────────────────────────────────

function initParticles() {
  // Start particles in a dam-break configuration: left half of the domain
  const pos = makeVec3Buffer(PARTICLE_COUNT, (i, arr) => {
    // 3D grid arrangement in left portion of domain
    const cols = 25, rows = 40, depth = 50
    const ix = i % cols
    const iy = Math.floor(i / cols) % rows
    const iz = Math.floor(i / (cols * rows)) % depth
    arr[i * 3 + 0] = ix * 0.15 + 0.2           // x: 0.2 to 3.9
    arr[i * 3 + 1] = iy * 0.15 + 0.2           // y: 0.2 to 6.2
    arr[i * 3 + 2] = iz * 0.15 + 0.2           // z: 0.2 to 7.7
  })

  const vel  = makeVec3Buffer(PARTICLE_COUNT)   // zero initial velocity
  const dens = makeFloatBuffer(PARTICLE_COUNT, REST_DENSITY)
  const pres = makeFloatBuffer(PARTICLE_COUNT)
  const forc = makeVec3Buffer(PARTICLE_COUNT)
  const colr = makeVec3Buffer(PARTICLE_COUNT, (i, arr) => {
    arr[i * 3] = 0.1; arr[i * 3 + 1] = 0.4; arr[i * 3 + 2] = 0.9  // ocean blue
  })

  return { pos, vel, dens, pres, forc, colr }
}

// ── Main component ────────────────────────────────────────────────────────────

export function FluidSimulation() {
  const { gravity, viscosity, pressureK, restDensity, renderMode } = useControls('SPH Fluid', {
    gravity:     { value: 9.8,    min: 0,    max: 20,   step: 0.1 },
    viscosity:   { value: 0.1,    min: 0,    max: 1.0,  step: 0.01 },
    pressureK:   { value: 200,    min: 10,   max: 1000, step: 10 },
    restDensity: { value: 1000,   min: 100,  max: 2000, step: 10 },
    renderMode:  { options: ['velocity', 'density', 'water'] },
  })

  // Uniforms for leva controls (update without recreating kernels)
  const uGravity     = useMemo(() => uniform(gravity), [])
  const uViscosity   = useMemo(() => uniform(viscosity), [])
  const uPressureK   = useMemo(() => uniform(pressureK), [])
  const uRestDensity = useMemo(() => uniform(restDensity), [])

  // Update uniforms when leva values change
  useEffect(() => { uGravity.value     = gravity     }, [gravity])
  useEffect(() => { uViscosity.value   = viscosity   }, [viscosity])
  useEffect(() => { uPressureK.value   = pressureK   }, [pressureK])
  useEffect(() => { uRestDensity.value = restDensity }, [restDensity])

  // Initialize all buffers once
  const bufs = useMemo(() => {
    const particles = initParticles()

    // Grid buffers
    const cellCount    = makeUintBuffer(GRID_CELLS)
    const cellOffset   = makeUintBuffer(GRID_CELLS)
    const scatterCount = makeUintBuffer(GRID_CELLS) // temp counter for scatter pass
    const sortedIdx    = makeUintBuffer(PARTICLE_COUNT)

    return { ...particles, cellCount, cellOffset, scatterCount, sortedIdx }
  }, [])

  // Helper: clamp (gx,gy,gz) to grid and compute flat index
  const gridIdx = (gx: any, gy: any, gz: any) => {
    const cx = clamp(gx, uint(0), uint(GRID_W - 1))
    const cy = clamp(gy, uint(0), uint(GRID_H - 1))
    const cz = clamp(gz, uint(0), uint(GRID_D - 1))
    return cx.add(cy.mul(uint(GRID_W))).add(cz.mul(uint(GRID_W * GRID_H)))
  }

  // Helper: world position → grid cell indices
  const posToGrid = (pos: any) => ({
    gx: clamp(floor(pos.x.div(float(CELL_SIZE))).toUint(), uint(0), uint(GRID_W - 1)),
    gy: clamp(floor(pos.y.div(float(CELL_SIZE))).toUint(), uint(0), uint(GRID_H - 1)),
    gz: clamp(floor(pos.z.div(float(CELL_SIZE))).toUint(), uint(0), uint(GRID_D - 1)),
  })

  // ── SPH neighbor summation macro ──────────────────────────────────────────
  // Used in both density pass and force pass — iterate 27 neighbor cells
  function forEachNeighbor(pos: any, callback: (jIdx: any, jPos: any, r: any, rLen: any) => void) {
    const { gx, gy, gz } = posToGrid(pos)

    for (let dz = -1; dz <= 1; dz++) {
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const nx = gx.add(int(dx))
          const ny = gy.add(int(dy))
          const nz = gz.add(int(dz))
          const inBounds = nx.greaterThanEqual(int(0)).and(nx.lessThan(int(GRID_W)))
            .and(ny.greaterThanEqual(int(0))).and(ny.lessThan(int(GRID_H)))
            .and(nz.greaterThanEqual(int(0))).and(nz.lessThan(int(GRID_D)))

          If(inBounds, () => {
            const cellIdx = gridIdx(nx.toUint(), ny.toUint(), nz.toUint())
            const start   = bufs.cellOffset.buf.element(cellIdx)
            const count   = bufs.cellCount.buf.element(cellIdx)
            const end     = start.add(count)

            Loop({ start, end }, ({ i: slot }) => {
              const jIdx = bufs.sortedIdx.buf.element(slot)
              const jPos = bufs.pos.buf.element(jIdx)
              const r    = pos.sub(jPos)
              const rLen = length(r)

              If(rLen.lessThan(float(SPH_H)).and(rLen.greaterThan(float(0.0001))), () => {
                callback(jIdx, jPos, r, rLen)
              })
            })
          })
        }
      }
    }
  }

  // ── Compute kernels (built once in useMemo) ────────────────────────────────
  const kernels = useMemo(() => {
    // 0. Reset grid cell counts
    const resetCounts = Fn(() => {
      bufs.cellCount.buf.element(instanceIndex).assign(uint(0))
      bufs.scatterCount.buf.element(instanceIndex).assign(uint(0))
    })().compute(GRID_CELLS)

    // 1. Count particles per cell
    const countPass = Fn(() => {
      const i   = instanceIndex
      const pos = bufs.pos.buf.element(i)
      const { gx, gy, gz } = posToGrid(pos)
      const cellIdx = gridIdx(gx, gy, gz)
      atomicAdd(bufs.cellCount.buf.element(cellIdx), uint(1))
    })().compute(PARTICLE_COUNT)

    // 2. Exclusive prefix sum on cellCount → cellOffset
    // For 6000 cells, this fits in a simple multi-pass approach:
    // Pass A: per-workgroup prefix sums (94 workgroups of 64)
    // Pass B: accumulate workgroup totals
    // (Using simple sequential prefix sum for correctness; optimize with parallel scan later)
    const prefixSumPass = Fn(() => {
      // Thread 0 does the entire prefix sum sequentially (only for demo correctness)
      // In production, use the parallel workgroup scan from Section 2
      If(instanceIndex.equal(uint(0)), () => {
        let running = uint(0).toVar()
        Loop({ start: uint(0), end: uint(GRID_CELLS) }, ({ i }) => {
          bufs.cellOffset.buf.element(i).assign(running)
          running.addAssign(bufs.cellCount.buf.element(i))
          // Also reset scatterCount to cellOffset for scatter pass
          bufs.scatterCount.buf.element(i).assign(bufs.cellOffset.buf.element(i))
        })
      })
    })().compute(1)

    // 3. Scatter particles into sorted order
    const scatterPass = Fn(() => {
      const i   = instanceIndex
      const pos = bufs.pos.buf.element(i)
      const { gx, gy, gz } = posToGrid(pos)
      const cellIdx = gridIdx(gx, gy, gz)
      // atomicAdd returns the slot before increment — that's this particle's sorted position
      const slot = atomicAdd(bufs.scatterCount.buf.element(cellIdx), uint(1))
      const writeIdx = bufs.cellOffset.buf.element(cellIdx).add(slot)
      bufs.sortedIdx.buf.element(writeIdx).assign(i)
    })().compute(PARTICLE_COUNT)

    // 4. Compute SPH density
    const densityPass = Fn(() => {
      const i   = instanceIndex
      const pos = bufs.pos.buf.element(i)
      const density = float(0).toVar()

      forEachNeighbor(pos, (jIdx, jPos, r, rLen) => {
        // W_poly6 kernel
        const h2 = float(SPH_H2)
        const diff = h2.sub(rLen.mul(rLen))
        const w = diff.mul(diff).mul(diff).mul(float(POLY6_FACTOR))
        density.addAssign(float(PARTICLE_MASS).mul(w))
      })

      // Clamp to avoid division by zero
      bufs.dens.buf.element(i).assign(max(density, float(REST_DENSITY * 0.5)))
    })().compute(PARTICLE_COUNT)

    // 5. Compute pressure + viscosity forces
    const forcePass = Fn(() => {
      const i       = instanceIndex
      const pos     = bufs.pos.buf.element(i)
      const vel     = bufs.vel.buf.element(i)
      const densI   = bufs.dens.buf.element(i)
      const pressI  = uPressureK.mul(densI.div(float(REST_DENSITY)).sub(float(1.0)))

      const force = vec3(0, float(-uGravity).mul(densI), 0).toVar()  // gravity

      forEachNeighbor(pos, (jIdx, jPos, r, rLen) => {
        const densJ  = bufs.dens.buf.element(jIdx)
        const velJ   = bufs.vel.buf.element(jIdx)
        const pressJ = uPressureK.mul(densJ.div(float(REST_DENSITY)).sub(float(1.0)))

        // Pressure force: -∇W_spiky
        const h_r    = float(SPH_H).sub(rLen)
        const spikyG = float(SPIKY_GRAD).mul(h_r).mul(h_r)
        const rHat   = normalize(r)
        const pFactor = float(PARTICLE_MASS).mul(pressI.add(pressJ)).div(float(2.0).mul(densJ))
        force.subAssign(rHat.mul(pFactor).mul(spikyG))

        // Viscosity force: μ∇²W_visc
        const viscLap = float(VISC_LAP).mul(h_r)
        const velDiff = velJ.sub(vel)
        force.addAssign(velDiff.mul(float(PARTICLE_MASS)).div(densJ).mul(viscLap).mul(uViscosity))
      })

      bufs.forc.buf.element(i).assign(force)
    })().compute(PARTICLE_COUNT)

    // 6. Integrate velocity and position
    const integratePass = Fn(() => {
      const i   = instanceIndex
      const pos = bufs.pos.buf.element(i)
      const vel = bufs.vel.buf.element(i)
      const f   = bufs.forc.buf.element(i)
      const rho = bufs.dens.buf.element(i)

      const accel  = f.div(rho)
      const newVel = vel.add(accel.mul(float(DT)))
      const newPos = pos.add(newVel.mul(float(DT)))

      // Boundary conditions: elastic bounce off domain walls
      const damping = float(0.3)

      // X walls
      const hitXLo = newPos.x.lessThan(float(0.1))
      const hitXHi = newPos.x.greaterThan(float(DOMAIN.x - 0.1))
      const velX   = If(hitXLo.or(hitXHi), newVel.x.negate().mul(damping), newVel.x)
      const posX   = clamp(newPos.x, float(0.1), float(DOMAIN.x - 0.1))

      // Y walls
      const hitYLo = newPos.y.lessThan(float(0.1))
      const hitYHi = newPos.y.greaterThan(float(DOMAIN.y - 0.1))
      const velY   = If(hitYLo.or(hitYHi), newVel.y.negate().mul(damping), newVel.y)
      const posY   = clamp(newPos.y, float(0.1), float(DOMAIN.y - 0.1))

      // Z walls
      const hitZLo = newPos.z.lessThan(float(0.1))
      const hitZHi = newPos.z.greaterThan(float(DOMAIN.z - 0.1))
      const velZ   = If(hitZLo.or(hitZHi), newVel.z.negate().mul(damping), newVel.z)
      const posZ   = clamp(newPos.z, float(0.1), float(DOMAIN.z - 0.1))

      bufs.vel.buf.element(i).assign(vec3(velX, velY, velZ))
      bufs.pos.buf.element(i).assign(vec3(posX, posY, posZ))

      // Update color based on velocity magnitude (fast = warm, slow = cool)
      const speed = length(vec3(velX, velY, velZ))
      const t     = clamp(speed.div(float(5.0)), float(0.0), float(1.0))
      const cool  = vec3(0.05, 0.2, 0.8)   // blue (slow water)
      const warm  = vec3(1.0,  0.4, 0.05)  // orange (fast water)
      bufs.colr.buf.element(i).assign(mix(cool, warm, t))
    })().compute(PARTICLE_COUNT)

    return { resetCounts, countPass, prefixSumPass, scatterPass, densityPass, forcePass, integratePass }
  }, [bufs, uGravity, uViscosity, uPressureK, uRestDensity])

  // ── Render geometry: use storageObject to drive Points vertex positions ────
  const geometry = useMemo(() => {
    const geo = new BufferGeometry()
    // Dummy positions — actual positions come from storage buffer in vertex shader
    geo.setAttribute('position', new Float32BufferAttribute(new Float32Array(PARTICLE_COUNT * 3), 3))
    geo.drawRange = { start: 0, count: PARTICLE_COUNT }
    return geo
  }, [])

  const material = useMemo(() => {
    const mat = new MeshBasicNodeMaterial()
    mat.transparent = true

    // Drive vertex position from storage buffer
    mat.positionNode = bufs.pos.buf.element(instanceIndex)

    // Drive color from storage buffer
    mat.colorNode = bufs.colr.buf.element(instanceIndex).toVec4().add(vec4(0, 0, 0, 0.8))

    return mat
  }, [bufs])

  // ── Frame loop: run all SPH passes in order ────────────────────────────────
  const frameCount = useRef(0)

  useFrame(({ gl }) => {
    const k = kernels

    // Step the simulation (can run multiple substeps per frame for stability)
    const SUBSTEPS = 2
    for (let s = 0; s < SUBSTEPS; s++) {
      gl.computeAsync(k.resetCounts)
      gl.computeAsync(k.countPass)
      gl.computeAsync(k.prefixSumPass)
      gl.computeAsync(k.scatterPass)
      gl.computeAsync(k.densityPass)
      gl.computeAsync(k.forcePass)
      gl.computeAsync(k.integratePass)
    }

    frameCount.current++
  })

  return (
    <points geometry={geometry}>
      <primitive object={material} />
    </points>
  )
}

// ── Scene wrapper ─────────────────────────────────────────────────────────────

export default function FluidScene() {
  return (
    <>
      <ambientLight intensity={0.3} />
      <directionalLight position={[5, 10, 5]} intensity={1.0} />

      <FluidSimulation />

      {/* Domain boundary visualization */}
      <mesh position={[4, 3, 4]}>
        <boxGeometry args={[8, 6, 8]} />
        <meshBasicMaterial color="#ffffff" wireframe opacity={0.1} transparent />
      </mesh>
    </>
  )
}
```

### Performance Notes

At 50k particles with SUBSTEPS=2, this simulation runs 14 compute dispatches per frame. On a mid-range GPU (RTX 3060, M2 Pro), expect 40–60 fps. The bottleneck is almost certainly the density and force passes — each particle checks up to 27 cells × ~20 particles/cell = ~540 neighbor lookups. That's 27 billion floating-point operations per second at 50k particles × 60 fps. If you need more particles, the bitonic sort from Section 7 reduces the random-access pattern in neighbor lookups and can push performance another 30–40%.

---

## 11. Performance Profiling

### The CPU vs GPU Timing Problem

`performance.now()` measures when you submitted the command to the GPU, not when the GPU finished executing it. The GPU is a deeply pipelined, asynchronous processor — it may start executing your dispatch milliseconds after you called `computeAsync`, and finish executing it while you're already recording the next frame's commands.

This means naive timing like this is almost useless:

```tsx
// WRONG: This measures CPU time to record the command, not GPU execution time
const t0 = performance.now()
gl.computeAsync(densityPass)
const elapsed = performance.now() - t0  // Will show 0.01ms regardless of GPU cost
```

### Timestamp Queries

WebGPU provides timestamp queries: the GPU writes a high-resolution timestamp into a buffer at specific points during execution. By reading the difference between two timestamps, you get true GPU execution time.

```tsx
import { WebGPURenderer } from 'three/webgpu'

// Check if timestamp queries are available (requires device feature)
async function setupTimestamps(renderer: WebGPURenderer) {
  const device = renderer.backend.device as GPUDevice
  if (!device.features.has('timestamp-query')) {
    console.warn('Timestamp queries not supported on this device')
    return null
  }

  // Create a query set for 16 timestamps (start/end for 8 passes)
  const querySet = device.createQuerySet({
    type: 'timestamp',
    count: 16,
  })

  // Buffer to resolve timestamp data into
  const resolveBuffer = device.createBuffer({
    size: 16 * 8,  // 16 timestamps × 8 bytes each (uint64)
    usage: GPUBufferUsage.QUERY_RESOLVE | GPUBufferUsage.COPY_SRC,
  })

  // CPU-readable staging buffer
  const readbackBuffer = device.createBuffer({
    size: 16 * 8,
    usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ,
  })

  return { querySet, resolveBuffer, readbackBuffer }
}

// Read back timing data (async — do this every few seconds, not every frame)
async function readTimings(
  device: GPUDevice,
  resolveBuffer: GPUBuffer,
  readbackBuffer: GPUBuffer,
  queryCount: number
) {
  const commandEncoder = device.createCommandEncoder()
  commandEncoder.copyBufferToBuffer(resolveBuffer, 0, readbackBuffer, 0, queryCount * 8)
  device.queue.submit([commandEncoder.finish()])

  await readbackBuffer.mapAsync(GPUMapMode.READ)
  const timestamps = new BigInt64Array(readbackBuffer.getMappedRange())

  const timings: number[] = []
  for (let i = 0; i < queryCount; i += 2) {
    // Convert nanoseconds to milliseconds
    const ms = Number(timestamps[i + 1] - timestamps[i]) / 1_000_000
    timings.push(ms)
  }

  readbackBuffer.unmap()
  return timings
}
```

### Practical Profiling Workflow

For day-to-day profiling without timestamp query infrastructure, use a practical tiered approach:

```tsx
// 1. Measure total GPU frame time with Chrome DevTools
//    Open DevTools → Performance → Record → look for GPU process activity

// 2. Isolate passes by commenting them out and comparing frame time
//    (crude but effective for identifying the dominant cost)

// 3. For production profiling, use WebGPU timestamp queries as above

// 4. Monitor frame time in-app with a rolling average
const frameTimes = useRef<number[]>([])
const lastTime = useRef(performance.now())

useFrame(() => {
  const now = performance.now()
  frameTimes.current.push(now - lastTime.current)
  if (frameTimes.current.length > 60) frameTimes.current.shift()
  lastTime.current = now

  const avg = frameTimes.current.reduce((a, b) => a + b) / frameTimes.current.length
  // Display avg in a <Stats> component or leva panel
})
```

### Occupancy and Memory Bandwidth

Two key concepts for understanding why a kernel is slow:

**Occupancy**: The ratio of active warps to maximum warps on a compute unit. Low occupancy means the GPU is underutilized. Causes: too much shared memory per workgroup (limits how many workgroups fit), too many registers per thread, or a workload that doesn't divide evenly into the workgroup size.

**Memory bandwidth**: How many bytes per second your kernel reads and writes. For the SPH density kernel at 50k particles with ~500 neighbors each: `50000 × 500 × (3 floats position + 1 float density) × 4 bytes ≈ 400 MB per dispatch`. At 400 GB/s GPU memory bandwidth, that's 1ms theoretically — a realistic estimate if your kernel is memory-bound with good spatial locality.

**Compute-bound vs memory-bound**: If adding more arithmetic to your kernel doesn't slow it down, you're memory-bound (memory access is the bottleneck). If reducing memory access doesn't speed it up, you're compute-bound. SPH density is typically memory-bound, which is why sorting particles by cell dramatically improves it.

---

## 12. Pitfalls

### Pitfall 1: Reading and Writing the Same Buffer in One Dispatch

```tsx
// WRONG: Race condition — some threads read the new value written by other threads
const updatePos = Fn(() => {
  const i   = instanceIndex
  const pos = posBuffer.element(i)           // Might read value written by thread i-1
  const vel = velBuffer.element(i)
  posBuffer.element(i).assign(pos.add(vel))  // Writes new value
})().compute(PARTICLE_COUNT)

// RIGHT: Use ping-pong buffers — read from A, write to B
const updatePos = Fn(() => {
  const i = instanceIndex
  const pos = posBufferA.element(i)          // Always reads old state
  const vel = velBufferA.element(i)
  posBufferB.element(i).assign(pos.add(vel)) // Always writes new state
})().compute(PARTICLE_COUNT)
// Then swap A and B references before next frame
```

The symptom of this bug is simulation that "works" most of the time but produces subtle jitter or divergence that depends on GPU thread scheduling. It will look different on different GPUs and may pass your initial tests before failing in production.

### Pitfall 2: Forgetting workgroupBarrier() After Shared Memory Writes

```tsx
// WRONG: Thread 0 reads tile[32] which may not have been written by thread 32 yet
const compute = Fn(() => {
  const tile = workgroupArray('float', 64)
  tile.element(localIndex).assign(globalBuffer.element(instanceIndex))
  // Missing: workgroupBarrier()
  const neighbor = tile.element(localIndex.bitXor(uint(1)))  // DATA RACE
  resultBuffer.element(instanceIndex).assign(neighbor)
})()

// RIGHT: Always barrier between writes and reads of shared memory
const compute = Fn(() => {
  const tile = workgroupArray('float', 64)
  tile.element(localIndex).assign(globalBuffer.element(instanceIndex))
  workgroupBarrier()  // All 64 threads finish writing before any reads
  const neighbor = tile.element(localIndex.bitXor(uint(1)))  // Safe
  resultBuffer.element(instanceIndex).assign(neighbor)
})()
```

This bug is insidious because it often produces mostly-correct results — thread scheduling on some GPUs happens to be sequential enough that the race rarely fires. But on different hardware or with different driver versions, it breaks catastrophically.

### Pitfall 3: Atomic Contention Destroying Performance

```tsx
// WRONG: All N threads atomicAdd to a single counter
// This serializes N threads — effective throughput is 1 operation at a time
const countAll = Fn(() => {
  If(isActive(instanceIndex), () => {
    atomicAdd(globalCountBuffer.element(uint(0)), uint(1))  // All threads fight over this
  })
})().compute(PARTICLE_COUNT)

// RIGHT: Two-phase reduction — workgroup atomics first, then single global atomic
const countAll = Fn(() => {
  const localCount = workgroupArray('uint', 1)

  // Phase 1: Each workgroup accumulates locally (fast)
  If(localIndex.equal(uint(0)), () => {
    localCount.element(uint(0)).assign(uint(0))
  })
  workgroupBarrier()

  If(isActive(instanceIndex), () => {
    atomicAdd(localCount.element(uint(0)), uint(1))
  })
  workgroupBarrier()

  // Phase 2: One thread per workgroup does the global atomic (few threads, little contention)
  If(localIndex.equal(uint(0)), () => {
    atomicAdd(globalCountBuffer.element(uint(0)), localCount.element(uint(0)))
  })
})().compute(PARTICLE_COUNT)
```

### Pitfall 4: Workgroup Size Not Dividing Data Size Evenly

```tsx
// WRONG: Dispatching exactly particle count with a reduction kernel
// If PARTICLE_COUNT is not a multiple of 64, the last workgroup has idle threads
// and shared-memory reduction reads uninitialized data in the padding slots
const reduce = Fn(() => {
  const tile = workgroupArray('float', 64)
  tile.element(localIndex).assign(dataBuffer.element(instanceIndex))  // Out-of-bounds!
  workgroupBarrier()
  // ... reduction code reads uninitialized tile entries
})().compute(PARTICLE_COUNT)

// RIGHT: Round up to next workgroup boundary and guard out-of-bounds threads
const PADDED_COUNT = Math.ceil(PARTICLE_COUNT / 64) * 64
const reduce = Fn(() => {
  const tile = workgroupArray('float', 64)

  // Guard: out-of-range threads write zero (neutral element for addition)
  If(instanceIndex.lessThan(uint(PARTICLE_COUNT)), () => {
    tile.element(localIndex).assign(dataBuffer.element(instanceIndex))
  }).Else(() => {
    tile.element(localIndex).assign(float(0))
  })

  workgroupBarrier()
  // ... reduction code is now correct for all tiles
})().compute(PADDED_COUNT)
```

### Pitfall 5: Forgetting to Reset Atomic Counters Between Frames

```tsx
// WRONG: cell counts accumulate across frames, spatial grid is garbage after frame 1
useFrame(({ gl }) => {
  // Missing reset pass!
  gl.computeAsync(countPass)     // cellCounts accumulate on top of last frame's values
  gl.computeAsync(prefixSumPass)
  gl.computeAsync(scatterPass)
})

// RIGHT: Always reset before accumulating
useFrame(({ gl }) => {
  gl.computeAsync(resetCountsPass)  // Zero out cellCount buffer
  gl.computeAsync(countPass)
  gl.computeAsync(prefixSumPass)
  gl.computeAsync(scatterPass)
})
```

The symptom is a simulation that looks correct for frame 0, then immediately explodes or collapses as particle counts grow unboundedly in subsequent frames.

### Pitfall 6: Buffer Size Not Accounting for Alignment

WebGPU requires storage buffer bindings to be aligned to 16 bytes. If you create a buffer of N floats (4 bytes each), and N is not a multiple of 4, the GPU may read uninitialized memory in the last element.

```tsx
// WRONG: 50001 elements × 4 bytes = 200004 bytes — not 16-byte aligned
const attr = new StorageBufferAttribute(new Float32Array(50001), 1)

// RIGHT: Pad to the next 16-byte-aligned count
function alignedCount(count: number, componentSize: number) {
  const bytesPerElement = componentSize * 4
  const remainder = (count * bytesPerElement) % 16
  if (remainder === 0) return count
  return count + Math.ceil((16 - remainder) / bytesPerElement)
}

const paddedCount = alignedCount(50001, 1)  // → 50004
const attr = new StorageBufferAttribute(new Float32Array(paddedCount), 1)
```

Three.js's `StorageBufferAttribute` usually handles this internally, but when you're computing derived buffer sizes (like `PARTICLE_COUNT × NEIGHBORS_PER_PARTICLE`), the math can produce misaligned sizes. Guard against this for any buffer where the size is computed rather than a literal constant.

---

## 13. Exercises

### Exercise 1: GPU Boids (Flocking Simulation)
**Estimated time:** 3–4 hours
**Difficulty:** Beginner

Implement a classic boids simulation with separation, alignment, and cohesion behaviors. Each boid should respond to its neighbors within a perception radius.

**Requirements:**
- 10,000+ boids in 3D space
- Neighbor search using the spatial grid from Section 8 (or brute-force with a smaller count)
- Separation: steer away from nearby boids
- Alignment: match average velocity of neighbors
- Cohesion: steer toward center of mass of neighbors
- Leva sliders for: separation radius, cohesion radius, max speed, weights for each behavior
- Render as instanced elongated pyramids (showing orientation), or as colored points

**Hints:**
- Start with brute-force neighbor search (O(n²)) before adding the grid. With 10k boids it's fast enough for prototyping.
- Velocity Verlet integration gives smoother results than Euler: `v += a*dt; p += v*dt`
- Clamp boid speed after applying forces: `vel = normalize(vel) * min(length(vel), maxSpeed)`

**Stretch goals:**
- Add obstacle avoidance (boids repel from a sphere or box collider)
- Make boids follow a moving target (camera position)
- Add predator/prey dynamics (one "shark" boid chases the others)

---

### Exercise 2: Cloth Simulation with Constraint Solving
**Estimated time:** 4–5 hours
**Difficulty:** Intermediate

Implement a GPU cloth simulation using position-based dynamics (PBD). A grid of particles connected by distance constraints — correct constraint violations iteratively rather than computing explicit forces.

**Requirements:**
- 128×128 cloth grid (16,384 particles)
- Structural constraints (horizontal, vertical) and shear constraints (diagonal)
- Multiple PBD iterations per frame (4–8) for stability
- Fixed corner particles (pinned in place)
- Gravity and damping
- Render as a triangle mesh using index buffer pointing into storage buffer positions

**Hints:**
- PBD constraints: for each structural edge `(i, j)` with rest length `L`, if `|pᵢ - pⱼ| ≠ L`, move both particles toward the midpoint proportionally.
- Separate dispatches for horizontal and vertical constraint passes (avoid race conditions — only update positions where threads don't conflict).
- "Checkerboard" constraint solving: split constraints into two sets that don't share vertices, process each set in one dispatch.

**Stretch goals:**
- Add wind force (perlin noise in XZ plane, varies over time)
- Sphere collision (particles pushed outside sphere radius)
- Tearing (constraints break when stretched beyond a threshold)

---

### Exercise 3: SPH Foam and Bubble Generation
**Estimated time:** 5–6 hours
**Difficulty:** Advanced

Extend the SPH fluid simulation with a secondary particle system for foam and bubbles. These are not SPH particles — they're lighter particles emitted from areas of high velocity divergence (where fluid splashes) and rendered differently.

**Requirements:**
- Extend the base SPH simulation from Section 10
- Add a fixed-size pool of foam particles (50,000 additional particles)
- Emit foam at positions where SPH velocity exceeds a threshold
- Foam particles are affected by gravity and buoyancy but not SPH forces
- Foam particles have a lifetime (they pop after 2–4 seconds)
- Implement a ring buffer for foam emission using atomicAdd with modulo
- Render foam as smaller, brighter, more transparent points
- Leva controls: emission rate, foam lifetime, buoyancy

**Hints:**
- Foam emission: in the integration pass, if `length(vel) > threshold`, atomicAdd to a global counter. Use `counter % FOAM_POOL_SIZE` as the ring buffer index to write a new foam particle. This overwrites old foam when the pool is full.
- Foam buoyancy: a simple upward force proportional to `restDensity - foamDensity`
- Foam rendering: use a second `<Points>` object drawing from the foam position buffer

**Stretch goals:**
- Foam-to-spray: foam particles above the water surface become airborne spray
- Screen-space surface rendering: render the SPH fluid as a smooth surface rather than points using screen-space ray-marching
- Vorticity confinement: add a small force that enhances rotational motion for more turbulent-looking fluid

---

### Exercise 4: GPU Particle Galaxy
**Estimated time:** 6–8 hours
**Difficulty:** Advanced / Expert

Build a galaxy simulation with 500,000 particles, using a Barnes-Hut tree approximation (implemented as a uniform grid for simplicity) for gravitational forces. This stretches every technique in this module.

**Requirements:**
- 500,000 star particles
- Disk galaxy initial conditions (particles initialized with spiral arm structure, orbital velocities)
- Gravitational force computation using a grid-based approximation: each cell contributes as a point mass at its center of mass
- Multi-dispatch pipeline: grid build → center-of-mass reduction per cell → force computation → integration
- Stars colored by velocity: fast stars are blue-white (young/hot), slow stars are red-orange (old/cool)
- Instanced rendering with additive blending for the glow effect
- Stats overlay: average kinetic energy, frame time, particles per second

**Hints:**
- Galaxy initialization: position = (r cos(θ + r/scale), small random y, r sin(θ + r/scale)) where r is radial distance and θ includes a spiral winding. Velocity = orbital velocity tangential to r.
- Grid-based gravity: divide space into a 64×64×64 grid. Each cell's mass = sum of star masses in it. Each cell's center-of-mass = weighted average position. Force computation: each star sums gravitational attraction from all 125,000 grid cells (still O(N × M_cells) but M_cells is fixed, not proportional to N).
- Softening factor: `F = G * M / (r² + ε²)` where ε prevents singularity at r=0
- Additive blending: `<Points material={mat} />` with `material.blending = THREE.AdditiveBlending`

**Stretch goals:**
- Barnes-Hut tree (quadtree or octree) for true O(N log N) gravity — requires dynamic data structure building on GPU
- Black hole: add a massive point mass at the center with 10,000× star mass
- Galaxy collision: spawn two galaxies on a collision course and watch them merge

---

## API Quick Reference

### Compute Dispatch

| API | Description |
|-----|-------------|
| `Fn(() => { ... })().compute(N)` | Create compute kernel for N invocations (default workgroup size 64) |
| `Fn(() => { ... })().compute(N, 128)` | Custom workgroup size |
| `gl.computeAsync(kernel)` | Submit compute kernel; dispatches execute in submission order |
| `instanceIndex` | Global invocation index (0 to N-1) |
| `localIndex` | Index within workgroup (0 to workgroupSize-1) |
| `workgroupIndex` | Index of this workgroup |

### Shared Memory

| API | Description |
|-----|-------------|
| `workgroupArray('float', 64)` | Declare 64-element float shared array |
| `workgroupArray('vec3', 64)` | Declare 64-element vec3 shared array |
| `workgroupArray('uint', 64)` | Declare 64-element uint shared array |
| `workgroupBarrier()` | Wait for all threads in workgroup to reach this point |
| `tile.element(localIndex)` | Access shared array element |

### Atomic Operations

| API | Supported Types | Description |
|-----|----------------|-------------|
| `atomicAdd(ptr, val)` | uint, int | Add val atomically, return old value |
| `atomicSub(ptr, val)` | uint, int | Subtract val atomically |
| `atomicMin(ptr, val)` | uint, int | Keep minimum value atomically |
| `atomicMax(ptr, val)` | uint, int | Keep maximum value atomically |
| `atomicAnd(ptr, val)` | uint, int | Bitwise AND atomically |
| `atomicOr(ptr, val)` | uint, int | Bitwise OR atomically |
| `atomicExchange(ptr, val)` | uint, int | Set value, return old value |
| `atomicCompareExchange(ptr, cmp, val)` | uint, int | CAS: set to val if current == cmp |

### Storage Buffers

| API | Description |
|-----|-------------|
| `new StorageBufferAttribute(array, components)` | Create GPU buffer from typed array |
| `storage(attr, 'vec3', count)` | Create TSL storage node from buffer attribute |
| `buf.element(index)` | Access buffer element by index (returns a writable node) |
| `buf.element(i).assign(val)` | Write to buffer element |
| `buf.element(i).addAssign(val)` | Add to buffer element in place |
| `renderer.getArrayBufferAsync(attr)` | Read buffer data back to CPU (async, expensive) |

### Indirect Dispatch

| API | Description |
|-----|-------------|
| `new StorageBufferAttribute(new Uint32Array([0, 1, 1]), 3)` | Create indirect args buffer |
| `gl.computeAsyncIndirect(kernel, indirectAttr)` | Dispatch with GPU-determined workgroup count |
| Indirect buffer format | `[workgroupCountX, workgroupCountY, workgroupCountZ]` as Uint32 |

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [WebGPU Compute Shaders — web.dev](https://developer.chrome.com/docs/web-platform/webgpu/compute-shaders) | Article | Official compute shader intro with clear dispatch model diagrams |
| [GPU Gems 3: Chapter 29 — Real-Time Rigid Body Simulation](https://developer.nvidia.com/gpugems/gpugems3/part-v-physics-simulation/chapter-29-real-time-rigid-body-simulation-gpus) | Book chapter | GPU physics pipeline patterns that directly apply to SPH |
| [SPH Fluids in Computer Graphics (Ihmsen et al.)](https://cg.informatik.uni-freiburg.de/publications/2014_EGstar_SPH.pdf) | Survey paper | Comprehensive SPH survey; density/force equations used directly in this module |
| [Bitonic Sort — Wikipedia](https://en.wikipedia.org/wiki/Bitonic_sort) | Article | Clear diagrams of the compare-and-swap network structure |
| [GPU Pro 360 Guide to Compute](https://www.routledge.com/GPU-Pro-360-Guide-to-Compute/Engel/p/book/9780815366270) | Book | Advanced compute patterns: parallel prefix, radix sort, spatial hashing |
| [Parallel Prefix Sum (Scan) with CUDA — NVIDIA](https://developer.nvidia.com/gpugems/gpugems3/part-vi-gpu-computing/chapter-39-parallel-prefix-sum-scan-cuda) | Article | The canonical parallel scan explanation; translates directly to WGSL |
| [Three.js WebGPU Examples — GitHub](https://github.com/mrdoob/three.js/tree/dev/examples) | Code | Source for `webgpu_compute_particles`, `webgpu_compute_geometry` — real working patterns |
| [WGSL Spec — W3C](https://www.w3.org/TR/WGSL/) | Specification | Reference for the shader language TSL compiles to; useful when debugging generated WGSL |
| [Müller, Charypar, Gross (2003) — Original SPH for Games paper](https://matthias-research.github.io/pages/publications/sph-fluids.pdf) | Paper | The foundational SPH-for-games paper; kernel functions are exact matches for this module's implementation |

---

## Key Takeaways

1. **Multi-dispatch is the core architectural pattern.** Any computation where threads need to read results written by other threads requires separate dispatches. Within a dispatch, threads are unordered relative to each other (except within the same workgroup, via `workgroupBarrier()`). Between dispatches, you get a global synchronization point for free.

2. **Shared workgroup memory is your fastest tool.** The ~15× speed advantage over global memory makes it worthwhile for any algorithm that accesses the same global data multiple times per thread. The tile-based pattern — load once to shared memory, process in shared memory, write back once — is the canonical GPU optimization pattern.

3. **Atomics are correct but expensive at scale.** They're essential for lock-free counting and scatter operations, but heavy contention (many threads fighting for the same address) serializes execution. Always measure whether atomic overhead is your bottleneck, and consider two-phase reduction (shared memory atomics followed by one global atomic per workgroup) when it is.

4. **Ping-pong buffers are not optional for stateful simulations.** Reading and writing the same buffer in one dispatch is a race condition that produces non-deterministic results. The double-buffer overhead (2× memory, twice the buffer objects) is trivial compared to the correctness it guarantees.

5. **Spatial data structures are the difference between O(n²) and O(n) neighbor search.** Without a grid, SPH at 50k particles requires checking 50k neighbors per particle — 2.5 billion comparisons per frame. With a grid, you check ~500 neighbors — a 100,000× reduction. This is why SPH is viable on the GPU and not on the CPU: the grid build is also parallelizable, whereas CPU-side KD-trees are inherently sequential.

6. **Sort your particles for cache performance.** After building the spatial grid, sorting particles by cell index means that neighboring particles in space are also neighboring in your storage buffer. Locality of reference drops cache miss rates from 80%+ to near zero for the neighbor loop — empirically, this 3–5× speedup is often the difference between 30fps and 90fps at 50k particles.

7. **Profile with GPU timestamps, not `performance.now()`.** JavaScript timing measures command submission, which has almost no correlation with GPU execution time. If your profiling tool doesn't show GPU-side timing, you don't know where your bottleneck actually is. Chrome DevTools Performance tab with GPU process visible, and WebGPU timestamp queries for fine-grained per-pass timing, are your actual profiling tools.

---

## What's Next?

You now have the compute programming foundation to build any GPU-driven simulation that appears in real game engines: fluid dynamics, cloth, rigid body physics, particle LOD systems, GPU-driven culling, and more.

[Module 16: TSL Ecosystem & Real-World Patterns](module-16-tsl-ecosystem-patterns.md) pulls everything together into production context. You'll see how TSL integrates with the rest of the R3F ecosystem — drei materials, post-processing passes, TypeScript's type system, instancing — and work through a retrofit project that converts three existing GLSL shaders to TSL, then extends them with compute-driven particles and a TSL post-processing effect. After that, you'll have a complete, integrated mental model of the TSL/WebGPU stack from first principles to shipping.

---

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
