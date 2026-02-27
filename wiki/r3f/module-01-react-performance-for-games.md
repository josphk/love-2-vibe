# Module 1: React Performance for Games

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 0: Setup & First Game Loop](module-00-setup-first-scene.md)

---

## Overview

React was designed to build UIs: forms, lists, modals — things that update a few times per second at most. Games need to update every single frame, 60 times per second minimum. These two worlds collide violently when you try to use `useState` to track a bullet's position or a particle's velocity. Every `setState` call triggers React's reconciliation — virtual DOM diffing, component re-rendering, potential child re-renders — and at 60fps, that machinery buries your frame budget.

This module teaches you the patterns that make React and Three.js coexist at game-speed. The core idea is simple: use React for what it's good at (declarative scene setup, component composition, lifecycle management) and bypass it entirely for what it's bad at (per-frame mutation of thousands of objects). You'll learn to treat `useFrame` as your real game loop, refs as your bridge to raw Three.js objects, and `InstancedMesh` as your secret weapon for rendering thousands of objects in a single draw call.

By the end, you'll build a particle fountain — first the wrong way (watching your fps crater to single digits), then the right way (500+ particles at a locked 60fps). The difference is not subtle. It's the difference between a game and a slideshow.

---

## 1. The Problem: React Wasn't Built for Games

Every time you call `setState`, React does the following:

1. Marks the component as dirty
2. Re-executes the entire component function
3. Generates a new virtual DOM tree
4. Diffs the new tree against the previous tree
5. Batches and applies the minimal set of real DOM (or Three.js) changes

For a button click, this takes a few milliseconds. Invisible. For a position update happening 60 times per second across 500 objects, this is catastrophic.

Here's the math. At 60fps, you have **16.67ms** per frame to do everything — physics, input, rendering. React's reconciliation for a moderately complex component tree can easily take 5–15ms. If you're updating positions via `useState` for even a handful of objects, you're already over budget.

```tsx
// This looks innocent. It is not.
import { useState } from "react";
import { useFrame } from "@react-three/fiber";

function BadMovingBox() {
  const [x, setX] = useState(0);

  // This triggers a full React re-render 60 times per second
  useFrame((_, delta) => {
    setX((prev) => prev + delta);
  });

  return (
    <mesh position={[x, 0, 0]}>
      <boxGeometry />
      <meshStandardMaterial color="red" />
    </mesh>
  );
}
```

One box? You might not notice. Ten boxes? Slight jank. One hundred boxes each calling `setState` every frame? Your tab freezes.

The problem compounds because React re-renders propagate downward. If a parent component re-renders, every child re-renders too (unless explicitly memoized). In a game scene with nested groups and meshes, one `setState` at the top can cascade through the entire scene graph.

```tsx
// Benchmark: useState vs useRef for 100 moving objects
// Run this and watch your fps counter

function BadBenchmark() {
  const [positions, setPositions] = useState<[number, number, number][]>(
    Array.from({ length: 100 }, () => [0, 0, 0])
  );

  useFrame((_, delta) => {
    // Re-creating the entire array every frame
    // Triggers re-render of this component + all 100 children
    setPositions((prev) =>
      prev.map(([x, y, z]) => [
        x + Math.sin(Date.now() * 0.001) * delta,
        y,
        z,
      ])
    );
  });

  return (
    <group>
      {positions.map((pos, i) => (
        <mesh key={i} position={pos}>
          <sphereGeometry args={[0.1, 8, 8]} />
          <meshStandardMaterial color="orange" />
        </mesh>
      ))}
    </group>
  );
}
// Result: ~8-15 fps depending on hardware
```

The takeaway: React's render cycle is your enemy in a game loop. Everything in this module is about avoiding it.

---

## 2. The Golden Rule: Mutate, Don't Re-render

In normal React, direct mutation is a sin. In R3F game code, it's the only way to survive. The rule is simple:

**Use `useRef` for anything that changes every frame. Use `useState` only for things that change rarely (scene setup, game phase, UI state).**

Here's the same moving box, done correctly:

```tsx
import { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

function GoodMovingBox() {
  const meshRef = useRef<THREE.Mesh>(null!);

  // No setState. No re-render. Just direct mutation.
  useFrame((_, delta) => {
    meshRef.current.position.x += delta;
  });

  // This JSX runs ONCE on mount. Never again.
  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardMaterial color="green" />
    </mesh>
  );
}
```

The component function executes once. The JSX mounts the mesh once. After that, `useFrame` directly mutates the Three.js object's properties every frame — completely outside React's awareness. React never knows the position changed. React never re-renders. The mesh just moves.

Here's the 100-object benchmark done correctly:

```tsx
function GoodBenchmark() {
  const meshRefs = useRef<(THREE.Mesh | null)[]>([]);

  useFrame(() => {
    const time = Date.now() * 0.001;
    for (let i = 0; i < meshRefs.current.length; i++) {
      const mesh = meshRefs.current[i];
      if (mesh) {
        mesh.position.x = Math.sin(time + i * 0.1) * 2;
        mesh.position.y = Math.cos(time + i * 0.13) * 2;
      }
    }
  });

  return (
    <group>
      {Array.from({ length: 100 }, (_, i) => (
        <mesh key={i} ref={(el) => (meshRefs.current[i] = el)}>
          <sphereGeometry args={[0.1, 8, 8]} />
          <meshStandardMaterial color="lime" />
        </mesh>
      ))}
    </group>
  );
}
// Result: solid 60fps
```

Same visual result. The difference: the `useState` version re-runs 100 component functions and diffs 100 virtual nodes every frame. The `useRef` version runs a single `for` loop that pokes numbers into existing Three.js objects. It's not even close.

**When to use `useState` vs `useRef`:**

| Data | Use | Why |
|------|-----|-----|
| Position, rotation, scale | `useRef` + mutation | Changes every frame |
| Velocity, acceleration | `useRef` | Changes every frame |
| Health, score | `useRef` or Zustand | Changes often, read in useFrame |
| Current weapon, game phase | `useState` or Zustand | Changes rarely, affects UI/scene structure |
| Is paused, menu open | `useState` | Changes rarely, affects React tree |

---

## 3. useFrame Deep Dive

`useFrame` is the heartbeat of your R3F game. It's a callback that runs every frame, after React's work is done, inside the Three.js render loop. It is not a React re-render. It runs in an animation frame callback managed by R3F's internal loop.

### The Callback Signature

```tsx
useFrame((state, delta, xrFrame?) => {
  // state: the entire R3F root state
  // delta: seconds since last frame (typically ~0.016 at 60fps)
  // xrFrame: XR frame data (ignore unless doing VR/AR)
});
```

The `state` object gives you access to everything:

```tsx
useFrame((state) => {
  state.clock;           // THREE.Clock instance
  state.clock.elapsedTime; // total seconds since scene started
  state.camera;          // the active camera
  state.gl;              // the WebGLRenderer
  state.scene;           // the root THREE.Scene
  state.mouse;           // normalized mouse coordinates (-1 to 1)
  state.pointer;         // same as mouse (R3F v8+)
  state.size;            // { width, height } of the canvas
  state.viewport;        // { width, height } in Three.js units at z=0
  state.raycaster;       // the built-in raycaster
  state.get;             // getter for current state snapshot
  state.invalidate;      // request a new frame (if frameloop="demand")
});
```

### Delta Time Is Non-Negotiable

Always multiply movement by `delta`. Without it, your game runs at different speeds on different hardware.

```tsx
// WRONG: speed depends on frame rate
useFrame(() => {
  meshRef.current.position.x += 0.01;
});

// RIGHT: speed is consistent regardless of frame rate
useFrame((_, delta) => {
  meshRef.current.position.x += 5 * delta; // 5 units per second
});
```

At 60fps, `delta` is ~0.0167. At 30fps, `delta` is ~0.0333. The object moves the same distance per second either way.

### The Priority System

By default, all `useFrame` callbacks run at priority 0, before R3F renders the scene. You can control execution order with the priority parameter:

```tsx
// Runs first (lowest number = earliest)
useFrame(() => {
  // Update physics
}, -100);

// Runs at default priority
useFrame(() => {
  // Update game logic
}, 0);

// Runs later
useFrame(() => {
  // Update camera to follow player
}, 10);

// Runs last
useFrame(() => {
  // HUD / post-processing
}, 100);
```

**Critical caveat:** When you use a non-zero priority, R3F stops automatically rendering the scene. You become responsible for calling `state.gl.render(state.scene, state.camera)` yourself in one of your callbacks. This is an advanced pattern — stick with priority 0 until you need explicit control over render order.

```tsx
// If you use priorities, you must render manually
useFrame((state) => {
  state.gl.render(state.scene, state.camera);
}, 1); // priority > 0 means "I'll handle rendering"
```

### Reading State Without Subscribing

You often need to read game state inside `useFrame` without causing re-renders. The pattern is to use a store's `getState()` method:

```tsx
import { useGameStore } from "./store";

function Player() {
  const meshRef = useRef<THREE.Mesh>(null!);

  useFrame((_, delta) => {
    // Read directly from store — no subscription, no re-render
    const { speed, direction } = useGameStore.getState();
    meshRef.current.position.x += direction.x * speed * delta;
    meshRef.current.position.z += direction.z * speed * delta;
  });

  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardMaterial />
    </mesh>
  );
}
```

---

## 4. Refs and Direct Object Access

Refs are the bridge between React's declarative world and Three.js's imperative world. Every `<mesh>`, `<group>`, `<pointLight>`, and other R3F element can take a `ref` that gives you the underlying Three.js object.

### Basic Ref Patterns

```tsx
import { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

function SpinningBox() {
  const meshRef = useRef<THREE.Mesh>(null!);

  useFrame((_, delta) => {
    const mesh = meshRef.current;

    // Position: THREE.Vector3
    mesh.position.x = Math.sin(Date.now() * 0.001);
    mesh.position.set(1, 2, 3); // set all at once

    // Rotation: THREE.Euler (in radians)
    mesh.rotation.y += delta * 2;
    mesh.rotation.set(0, Math.PI, 0);

    // Scale: THREE.Vector3
    mesh.scale.setScalar(1.5); // uniform scale
    mesh.scale.set(1, 2, 1);  // non-uniform

    // Visibility (cheap toggle — no mount/unmount)
    mesh.visible = false;
  });

  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardMaterial color="blue" />
    </mesh>
  );
}
```

### The `null!` TypeScript Pattern

In TypeScript, `useRef<THREE.Mesh>(null!)` tells the compiler: "This ref starts as null, but trust me, it will be assigned by the time I use it." The `!` is the non-null assertion. Without it, you'd need to null-check `meshRef.current` on every access inside `useFrame`.

```tsx
// Without null assertion — tedious
const meshRef = useRef<THREE.Mesh>(null);
useFrame(() => {
  if (meshRef.current) {  // must check every time
    meshRef.current.position.x += 0.1;
  }
});

// With null assertion — clean
const meshRef = useRef<THREE.Mesh>(null!);
useFrame(() => {
  meshRef.current.position.x += 0.1; // safe after mount
});
```

This is safe because `useFrame` only runs after the component has mounted and the ref has been assigned.

### Groups and Hierarchical Access

```tsx
function Ship() {
  const groupRef = useRef<THREE.Group>(null!);
  const thrusterRef = useRef<THREE.Mesh>(null!);

  useFrame((_, delta) => {
    // Move the whole group (ship + all children)
    groupRef.current.position.z -= 10 * delta;

    // Animate a child independently
    thrusterRef.current.scale.x = 0.8 + Math.random() * 0.4;
  });

  return (
    <group ref={groupRef}>
      <mesh>  {/* Ship body */}
        <coneGeometry args={[0.5, 2, 8]} />
        <meshStandardMaterial color="gray" />
      </mesh>
      <mesh ref={thrusterRef} position={[0, -1.2, 0]}>  {/* Thruster */}
        <sphereGeometry args={[0.3, 8, 8]} />
        <meshStandardMaterial color="orange" emissive="orange" />
      </mesh>
    </group>
  );
}
```

### Accessing Material Properties

```tsx
function PulsingOrb() {
  const matRef = useRef<THREE.MeshStandardMaterial>(null!);

  useFrame((state) => {
    const t = state.clock.elapsedTime;
    matRef.current.emissiveIntensity = Math.sin(t * 3) * 0.5 + 0.5;
    matRef.current.opacity = 0.5 + Math.sin(t * 2) * 0.3;
  });

  return (
    <mesh>
      <sphereGeometry args={[1, 32, 32]} />
      <meshStandardMaterial
        ref={matRef}
        color="cyan"
        emissive="cyan"
        transparent
      />
    </mesh>
  );
}
```

---

## 5. InstancedMesh for Mass Objects

This is the single most important performance technique for games in R3F. If you're rendering more than ~50 copies of the same geometry, you need `InstancedMesh`.

### Why Individual Meshes Don't Scale

Each `<mesh>` in your scene is a separate draw call to the GPU. The GPU is fast at processing triangles but slow at switching between objects. 500 meshes with 100 triangles each means 500 draw calls for 50,000 triangles. The GPU could handle 50,000 triangles in a single call easily — the bottleneck is the 500 state changes.

```
500 individual meshes:  500 draw calls → ~15fps
1 InstancedMesh:          1 draw call → ~60fps
Same visual result. Same triangle count.
```

### The InstancedMesh Pattern

`InstancedMesh` renders N copies of the same geometry and material in a single draw call. Each instance gets its own 4x4 transformation matrix (position + rotation + scale).

```tsx
import { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

const PARTICLE_COUNT = 500;

function Particles() {
  const meshRef = useRef<THREE.InstancedMesh>(null!);

  // The dummy Object3D — used to build transformation matrices
  const dummy = useMemo(() => new THREE.Object3D(), []);

  useFrame((state) => {
    const time = state.clock.elapsedTime;

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      // Set position on the dummy
      dummy.position.set(
        Math.sin(time + i * 0.1) * 5,
        Math.cos(time + i * 0.13) * 5,
        Math.sin(time + i * 0.07) * 5
      );

      // Optionally set rotation/scale
      dummy.rotation.set(time + i, time + i * 0.5, 0);
      dummy.scale.setScalar(0.5 + Math.sin(time + i) * 0.3);

      // Compute the matrix from position/rotation/scale
      dummy.updateMatrix();

      // Write the matrix into the instance buffer
      meshRef.current.setMatrixAt(i, dummy.matrix);
    }

    // CRITICAL: tell Three.js the instance buffer has changed
    meshRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, PARTICLE_COUNT]}>
      <sphereGeometry args={[0.1, 8, 6]} />
      <meshStandardMaterial color="hotpink" />
    </instancedMesh>
  );
}
```

### The Dummy Object3D Pattern Explained

You can't set position/rotation/scale directly on instance entries. Instead, you:

1. Set position/rotation/scale on a temporary `Object3D`
2. Call `updateMatrix()` to compute the 4x4 transformation matrix
3. Copy that matrix into the instance buffer with `setMatrixAt(index, matrix)`

The dummy is created once with `useMemo` and reused every frame. It's just a scratchpad for matrix math.

### Instance Colors

Each instance can also have its own color:

```tsx
function ColoredParticles() {
  const meshRef = useRef<THREE.InstancedMesh>(null!);
  const dummy = useMemo(() => new THREE.Object3D(), []);
  const color = useMemo(() => new THREE.Color(), []);

  useFrame((state) => {
    const time = state.clock.elapsedTime;

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      dummy.position.set(
        Math.sin(time + i * 0.1) * 5,
        (i / PARTICLE_COUNT) * 10 - 5,
        Math.cos(time + i * 0.1) * 5
      );
      dummy.updateMatrix();
      meshRef.current.setMatrixAt(i, dummy.matrix);

      // Set per-instance color
      color.setHSL((i / PARTICLE_COUNT + time * 0.1) % 1, 0.8, 0.5);
      meshRef.current.setColorAt(i, color);
    }

    meshRef.current.instanceMatrix.needsUpdate = true;
    if (meshRef.current.instanceColor) {
      meshRef.current.instanceColor.needsUpdate = true;
    }
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, PARTICLE_COUNT]}>
      <sphereGeometry args={[0.1, 8, 6]} />
      <meshStandardMaterial />
    </instancedMesh>
  );
}
```

### The `args` Prop

The `args` for `instancedMesh` are `[geometry, material, count]`. When using JSX children for geometry and material, pass `undefined` for the first two:

```tsx
<instancedMesh args={[undefined, undefined, 1000]}>
  <boxGeometry args={[0.5, 0.5, 0.5]} />
  <meshStandardMaterial />
</instancedMesh>
```

---

## 6. React.memo and Component Boundaries

Even when you're using refs for per-frame updates, React re-renders can still hurt you if a parent component's state changes cause unnecessary child re-renders. The key is component architecture.

### Split Static vs Dynamic

```tsx
// BAD: HUD state changes re-render the entire scene
function Game() {
  const [score, setScore] = useState(0);

  return (
    <Canvas>
      {/* Every score change re-renders ALL of this */}
      <ambientLight />
      <Environment />  {/* expensive! */}
      <Level />        {/* lots of static meshes */}
      <Player />
      <Enemies />
      <ScoreDisplay score={score} />
    </Canvas>
  );
}

// GOOD: isolate the re-rendering parts
function Game() {
  return (
    <Canvas>
      <StaticScene />
      <DynamicScene />
    </Canvas>
  );
}

const StaticScene = React.memo(function StaticScene() {
  return (
    <>
      <ambientLight />
      <Environment />
      <Level />
    </>
  );
});

function DynamicScene() {
  // Score state is isolated here
  const [score, setScore] = useState(0);

  return (
    <>
      <Player onScore={() => setScore((s) => s + 1)} />
      <Enemies />
      <ScoreDisplay score={score} />
    </>
  );
}
```

### React.memo for Expensive Components

```tsx
import React from "react";

// This component only re-renders when its props actually change
const ExpensiveLevel = React.memo(function ExpensiveLevel({
  levelId,
}: {
  levelId: number;
}) {
  // Imagine this builds a complex level with hundreds of meshes
  return (
    <group>
      {/* ... lots of static geometry ... */}
    </group>
  );
});

// This component re-renders often (has dynamic state)
function GameScene() {
  const [health, setHealth] = useState(100);

  return (
    <>
      {/* levelId doesn't change, so ExpensiveLevel won't re-render */}
      <ExpensiveLevel levelId={1} />
      <Player health={health} />
      <HUD health={health} />
    </>
  );
}
```

### The Wrapper Component Pattern

When you need to read reactive state but mutate via refs, use a thin wrapper:

```tsx
// This component re-renders when speed changes — but it's tiny
function PlayerController({ speed }: { speed: number }) {
  const meshRef = useRef<THREE.Mesh>(null!);
  // Store speed in a ref so useFrame always has the latest value
  const speedRef = useRef(speed);
  speedRef.current = speed;

  useFrame((_, delta) => {
    // Read from ref, not from props (avoids stale closure)
    meshRef.current.position.x += speedRef.current * delta;
  });

  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardMaterial />
    </mesh>
  );
}
```

---

## 7. Zustand Without Re-renders

Zustand is the de facto state manager for R3F games. But the default `useStore(selector)` hook subscribes the component to changes — meaning it re-renders when the selected state changes. In game code, you often want to read state without subscribing.

### Three Patterns for Reading Zustand State

```tsx
import { create } from "zustand";
import { subscribeWithSelector } from "zustand/middleware";

interface GameState {
  playerPos: THREE.Vector3;
  score: number;
  speed: number;
  isPaused: boolean;
  increaseScore: () => void;
  setSpeed: (s: number) => void;
}

const useGameStore = create<GameState>()(
  subscribeWithSelector((set) => ({
    playerPos: new THREE.Vector3(),
    score: 0,
    speed: 5,
    isPaused: false,
    increaseScore: () => set((s) => ({ score: s.score + 1 })),
    setSpeed: (speed) => set({ speed }),
  }))
);
```

**Pattern 1: Subscribing (causes re-renders)**

```tsx
// Use this for UI/HUD components that SHOULD re-render
function ScoreHUD() {
  const score = useGameStore((s) => s.score); // re-renders on score change
  return <text>{score}</text>;
}
```

**Pattern 2: `getState()` in useFrame (no re-renders)**

```tsx
// Use this for game logic that runs every frame
function Enemy() {
  const meshRef = useRef<THREE.Mesh>(null!);

  useFrame((_, delta) => {
    const { playerPos, speed } = useGameStore.getState();
    // Chase the player — reads state directly, no subscription
    meshRef.current.position.lerp(playerPos, speed * delta * 0.1);
  });

  return (
    <mesh ref={meshRef}>
      <sphereGeometry args={[0.5]} />
      <meshStandardMaterial color="red" />
    </mesh>
  );
}
```

**Pattern 3: `subscribe` for side effects (no re-renders)**

```tsx
// Use this when you need to react to specific state changes
// without re-rendering the component
function SoundManager() {
  useEffect(() => {
    const unsub = useGameStore.subscribe(
      (s) => s.score,
      (score, prevScore) => {
        if (score > prevScore) {
          playSound("point");
        }
      }
    );
    return unsub;
  }, []);

  return null; // renders nothing
}
```

### Transient Updates Pattern

For values that change every frame (like player position), use a transient approach — write directly to a Zustand state vector without triggering React:

```tsx
// In your player's useFrame:
useFrame((_, delta) => {
  const mesh = meshRef.current;
  mesh.position.x += input.x * speed * delta;
  mesh.position.z += input.z * speed * delta;

  // Update the store's vector directly — no setState, no re-render
  useGameStore.getState().playerPos.copy(mesh.position);
});
```

Other components reading `playerPos` via `getState()` in their own `useFrame` will see the updated value. No React re-render anywhere in the chain.

---

## 8. Measuring Performance

You can't optimize what you can't measure. Here are the tools you'll use.

### r3f-perf (Recommended)

The easiest drop-in performance overlay for R3F:

```bash
npm install r3f-perf
```

```tsx
import { Perf } from "r3f-perf";

function Game() {
  return (
    <Canvas>
      <Perf position="top-left" />
      {/* your scene */}
    </Canvas>
  );
}
```

This shows FPS, frame time (ms), GPU time, memory usage, draw call count, and triangle count — all in a compact overlay.

### renderer.info for Draw Calls

Three.js tracks render stats internally:

```tsx
function DrawCallMonitor() {
  useFrame((state) => {
    const info = state.gl.info;
    // Log every 60 frames (once per second at 60fps)
    if (Math.floor(state.clock.elapsedTime * 60) % 60 === 0) {
      console.log("Draw calls:", info.render.calls);
      console.log("Triangles:", info.render.triangles);
      console.log("Geometries:", info.memory.geometries);
      console.log("Textures:", info.memory.textures);
    }
  });

  return null;
}
```

### Chrome DevTools Performance Tab

1. Open DevTools (F12)
2. Go to the **Performance** tab
3. Click Record, interact with your game for 2–3 seconds, click Stop
4. Look for:
   - **Long frames** (yellow bars taller than the 16ms line)
   - **Scripting** time (JavaScript execution — includes React reconciliation)
   - **Rendering** time (GPU paint/composite)
   - **GC events** (garbage collection pauses — often from allocating objects in useFrame)

### React DevTools Profiler

1. Install the React DevTools browser extension
2. Open it and go to the **Profiler** tab
3. Click Record, interact with your game, click Stop
4. Look for components that re-render every frame — those are your optimization targets
5. Components that render once and never again are correctly using the ref pattern

### Stats.js (Lightweight Alternative)

```bash
npm install stats.js
```

```tsx
import { useEffect } from "react";
import { useFrame, useThree } from "@react-three/fiber";
import Stats from "stats.js";

function StatsPanel() {
  const { gl } = useThree();
  const stats = useMemo(() => new Stats(), []);

  useEffect(() => {
    stats.showPanel(0); // 0=fps, 1=ms, 2=mb
    document.body.appendChild(stats.dom);
    return () => {
      document.body.removeChild(stats.dom);
    };
  }, [stats]);

  useFrame(() => {
    stats.update();
  });

  return null;
}
```

---

## 9. Object Pooling

In games, objects come and go constantly: particles spawn, bullets fire, enemies die, effects appear. The naive approach — mount a React component when something spawns, unmount it when it dies — is expensive. React has to reconcile the tree on every mount/unmount. JavaScript also has to allocate and garbage-collect the associated objects.

Object pooling pre-allocates a fixed number of objects and recycles them. Instead of creating a new particle, you grab an inactive one from the pool, configure it, and mark it active. Instead of destroying it, you mark it inactive and it becomes available for reuse.

### The Pool Pattern

```tsx
interface Particle {
  active: boolean;
  position: THREE.Vector3;
  velocity: THREE.Vector3;
  life: number;
  maxLife: number;
}

const POOL_SIZE = 500;

function useParticlePool() {
  const pool = useRef<Particle[]>(
    Array.from({ length: POOL_SIZE }, () => ({
      active: false,
      position: new THREE.Vector3(),
      velocity: new THREE.Vector3(),
      life: 0,
      maxLife: 0,
    }))
  );

  const spawn = useCallback((pos: THREE.Vector3, vel: THREE.Vector3, maxLife: number) => {
    // Find the first inactive particle
    const particle = pool.current.find((p) => !p.active);
    if (!particle) return; // pool exhausted

    particle.active = true;
    particle.position.copy(pos);
    particle.velocity.copy(vel);
    particle.life = 0;
    particle.maxLife = maxLife;
  }, []);

  return { pool, spawn };
}
```

### Visibility Toggle vs Mount/Unmount

```tsx
// BAD: mounting/unmounting React components
function Bullets() {
  const [bullets, setBullets] = useState<BulletData[]>([]);

  const fire = () => {
    setBullets((prev) => [...prev, newBullet()]); // allocation + re-render
  };

  return (
    <>
      {bullets.map((b) => (
        <Bullet key={b.id} data={b} /> // each one is a React component
      ))}
    </>
  );
}

// GOOD: pre-allocated pool with visibility toggle
function Bullets() {
  const meshRef = useRef<THREE.InstancedMesh>(null!);
  const poolRef = useRef<BulletData[]>(
    Array.from({ length: 100 }, () => ({
      active: false,
      position: new THREE.Vector3(),
      velocity: new THREE.Vector3(),
    }))
  );
  const dummy = useMemo(() => new THREE.Object3D(), []);

  useFrame((_, delta) => {
    const pool = poolRef.current;
    for (let i = 0; i < pool.length; i++) {
      const bullet = pool[i];
      if (bullet.active) {
        bullet.position.add(bullet.velocity.clone().multiplyScalar(delta));
        // Deactivate if out of bounds
        if (bullet.position.length() > 50) {
          bullet.active = false;
        }
      }

      // Set transform — inactive bullets get scaled to 0 (invisible)
      dummy.position.copy(bullet.position);
      dummy.scale.setScalar(bullet.active ? 1 : 0);
      dummy.updateMatrix();
      meshRef.current.setMatrixAt(i, dummy.matrix);
    }
    meshRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, 100]}>
      <sphereGeometry args={[0.1, 6, 6]} />
      <meshStandardMaterial color="yellow" emissive="yellow" />
    </instancedMesh>
  );
}
```

Key insight: scaling an instance to 0 makes it invisible and effectively free to render. No React mount/unmount. No allocation. No garbage collection.

---

## 10. Disposal and Memory

Three.js objects — geometries, materials, textures — allocate GPU memory. Unlike JavaScript objects, they aren't garbage-collected automatically. If you create a texture and lose the reference, the GPU memory stays allocated. This is a memory leak.

### The Disposal Rule

When a Three.js object is no longer needed, call `.dispose()` on it:

```tsx
geometry.dispose();      // free vertex buffer GPU memory
material.dispose();      // free shader program GPU memory
texture.dispose();       // free texture GPU memory
renderTarget.dispose();  // free framebuffer GPU memory
```

### useEffect Cleanup

In R3F components, use `useEffect` cleanup to dispose of manually created resources:

```tsx
function DynamicTexture() {
  const matRef = useRef<THREE.MeshStandardMaterial>(null!);

  useEffect(() => {
    const texture = new THREE.TextureLoader().load("/sprite.png");
    matRef.current.map = texture;
    matRef.current.needsUpdate = true;

    return () => {
      texture.dispose(); // Clean up on unmount
    };
  }, []);

  return (
    <mesh>
      <planeGeometry />
      <meshStandardMaterial ref={matRef} />
    </mesh>
  );
}
```

### R3F's Automatic Disposal

R3F automatically disposes of geometries and materials attached to components when they unmount. This works for JSX-declared resources:

```tsx
// These are auto-disposed when the component unmounts
<mesh>
  <boxGeometry />              {/* auto-disposed */}
  <meshStandardMaterial />     {/* auto-disposed */}
</mesh>
```

You can opt out of auto-disposal with the `dispose` prop:

```tsx
// Do NOT auto-dispose — I'm sharing this geometry between components
<mesh dispose={null}>
  <sharedGeometry />
  <meshStandardMaterial />
</mesh>
```

### Detecting Memory Leaks

Watch `renderer.info.memory` over time:

```tsx
function MemoryMonitor() {
  const prevRef = useRef({ geometries: 0, textures: 0 });

  useFrame((state) => {
    const mem = state.gl.info.memory;
    if (
      mem.geometries !== prevRef.current.geometries ||
      mem.textures !== prevRef.current.textures
    ) {
      console.log(
        `Memory: ${mem.geometries} geometries, ${mem.textures} textures`
      );
      prevRef.current = { geometries: mem.geometries, textures: mem.textures };
    }
  });

  return null;
}
```

If the geometry or texture count keeps climbing as you play, you have a leak. Track down what's being created but not disposed.

### Common Disposal Mistakes

```tsx
// WRONG: creating a new material every render
function BadComponent() {
  return (
    <mesh>
      <boxGeometry />
      <meshStandardMaterial map={new THREE.TextureLoader().load("/tex.png")} />
      {/* New texture created on every render! Previous one leaks! */}
    </mesh>
  );
}

// RIGHT: load once, clean up on unmount
function GoodComponent() {
  const texture = useMemo(() => new THREE.TextureLoader().load("/tex.png"), []);

  useEffect(() => {
    return () => texture.dispose();
  }, [texture]);

  return (
    <mesh>
      <boxGeometry />
      <meshStandardMaterial map={texture} />
    </mesh>
  );
}
```

---

## Code Walkthrough: Particle Fountain

Now let's build the module's mini-project — a particle fountain — twice. First the wrong way, then the right way.

### Step 1: The Bad Version (useState)

This version manages each particle's state in React. Watch the fps counter.

```tsx
import { useState, useCallback } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { Perf } from "r3f-perf";

interface ParticleState {
  id: number;
  x: number;
  y: number;
  z: number;
  vx: number;
  vy: number;
  vz: number;
  life: number;
}

const PARTICLE_COUNT = 500;
const GRAVITY = -9.8;

function createParticle(id: number): ParticleState {
  const angle = Math.random() * Math.PI * 2;
  const speed = 2 + Math.random() * 3;
  return {
    id,
    x: 0,
    y: 0,
    z: 0,
    vx: Math.cos(angle) * speed * 0.3,
    vy: 5 + Math.random() * 5,
    vz: Math.sin(angle) * speed * 0.3,
    life: 1,
  };
}

function BadParticle({ state }: { state: ParticleState }) {
  return (
    <mesh position={[state.x, state.y, state.z]}>
      <sphereGeometry args={[0.05, 6, 6]} />
      <meshStandardMaterial
        color="orange"
        transparent
        opacity={state.life}
      />
    </mesh>
  );
}

function BadParticleFountain() {
  const [particles, setParticles] = useState<ParticleState[]>(() =>
    Array.from({ length: PARTICLE_COUNT }, (_, i) => createParticle(i))
  );

  // Every frame: re-create the entire array, trigger a full re-render,
  // re-render 500 child components, diff 500 virtual DOM nodes
  useFrame((_, delta) => {
    setParticles((prev) =>
      prev.map((p) => {
        let { x, y, z, vx, vy, vz, life, id } = p;
        vy += GRAVITY * delta;
        x += vx * delta;
        y += vy * delta;
        z += vz * delta;
        life -= delta * 0.5;

        if (life <= 0 || y < -1) {
          return createParticle(id);
        }
        return { ...p, x, y, z, vx, vy, vz, life };
      })
    );
  });

  return (
    <group>
      {particles.map((p) => (
        <BadParticle key={p.id} state={p} />
      ))}
    </group>
  );
}

// Result: ~3-8 fps
// 500 components re-rendering every frame
// 500 draw calls (one per mesh)
// Massive GC spikes from array/object allocation

export function BadDemo() {
  return (
    <Canvas camera={{ position: [0, 5, 10], fov: 60 }}>
      <Perf position="top-left" />
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      <BadParticleFountain />
    </Canvas>
  );
}
```

What's wrong here:
- **500 setState-driven re-renders per frame** — each creates a new array with 500 new objects
- **500 React components** each re-evaluating their JSX
- **500 separate meshes** = 500 draw calls
- **Constant GC pressure** from spread operators and `map` creating new objects every frame

### Step 2: The Good Version (InstancedMesh + Refs)

Same visual result. Completely different architecture.

```tsx
import { useRef, useMemo } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { Perf } from "r3f-perf";
import * as THREE from "three";

const PARTICLE_COUNT = 500;
const GRAVITY = -9.8;

interface Particle {
  position: THREE.Vector3;
  velocity: THREE.Vector3;
  life: number;
  maxLife: number;
}

function resetParticle(p: Particle) {
  const angle = Math.random() * Math.PI * 2;
  const speed = 2 + Math.random() * 3;
  p.position.set(0, 0, 0);
  p.velocity.set(
    Math.cos(angle) * speed * 0.3,
    5 + Math.random() * 5,
    Math.sin(angle) * speed * 0.3
  );
  p.life = 0;
  p.maxLife = 1 + Math.random() * 2;
}

function GoodParticleFountain() {
  const meshRef = useRef<THREE.InstancedMesh>(null!);
  const dummy = useMemo(() => new THREE.Object3D(), []);
  const color = useMemo(() => new THREE.Color(), []);

  // Pre-allocate all particle data ONCE
  const particles = useRef<Particle[]>(
    Array.from({ length: PARTICLE_COUNT }, () => {
      const p: Particle = {
        position: new THREE.Vector3(),
        velocity: new THREE.Vector3(),
        life: 0,
        maxLife: 0,
      };
      resetParticle(p);
      // Stagger initial lifetimes so they don't all spawn at once
      p.life = Math.random() * p.maxLife;
      return p;
    })
  );

  useFrame((_, delta) => {
    const pool = particles.current;

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      const p = pool[i];

      // Apply gravity
      p.velocity.y += GRAVITY * delta;

      // Integrate position
      p.position.x += p.velocity.x * delta;
      p.position.y += p.velocity.y * delta;
      p.position.z += p.velocity.z * delta;

      // Age the particle
      p.life += delta;

      // Reset if expired or below ground
      if (p.life >= p.maxLife || p.position.y < -1) {
        resetParticle(p);
      }

      // Compute normalized age (0 = newborn, 1 = expired)
      const age = p.life / p.maxLife;

      // Set instance transform
      dummy.position.copy(p.position);
      dummy.scale.setScalar(1 - age * 0.8); // shrink as they age
      dummy.updateMatrix();
      meshRef.current.setMatrixAt(i, dummy.matrix);

      // Color: orange → red → dark as it ages
      color.setHSL(0.08 - age * 0.08, 1, 0.5 - age * 0.4);
      meshRef.current.setColorAt(i, color);
    }

    meshRef.current.instanceMatrix.needsUpdate = true;
    if (meshRef.current.instanceColor) {
      meshRef.current.instanceColor.needsUpdate = true;
    }
  });

  return (
    <instancedMesh
      ref={meshRef}
      args={[undefined, undefined, PARTICLE_COUNT]}
      frustumCulled={false}
    >
      <sphereGeometry args={[0.05, 6, 6]} />
      <meshStandardMaterial vertexColors toneMapped={false} />
    </instancedMesh>
  );
}

// Result: solid 60fps
// 1 component, 0 re-renders
// 1 draw call for all 500 particles
// 0 allocations per frame

export function GoodDemo() {
  return (
    <Canvas camera={{ position: [0, 5, 10], fov: 60 }}>
      <Perf position="top-left" />
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      <GoodParticleFountain />
    </Canvas>
  );
}
```

### Why It's 100x Faster

| Metric | Bad Version | Good Version |
|--------|-------------|--------------|
| Components rendering per frame | 501 | 0 |
| Draw calls | 500 | 1 |
| Objects allocated per frame | ~2000 | 0 |
| GC pauses | Frequent | None |
| FPS | 3–8 | 60 |

The good version:
- Renders the React component **once** on mount, then never again
- Uses a single `InstancedMesh` — **one draw call** for all 500 particles
- Mutates pre-allocated `Vector3` objects in place — **zero allocations per frame**
- Updates instance matrices directly in a tight `for` loop — no React overhead

---

## API Quick Reference

| Function/Hook | Description | Example |
|---------------|-------------|---------|
| `useFrame(cb, priority?)` | Run callback every frame; priority controls execution order | `useFrame((state, delta) => { ... })` |
| `useRef<T>(null!)` | Create ref to a Three.js object, skip null checks | `const ref = useRef<THREE.Mesh>(null!)` |
| `useThree()` | Access R3F state outside useFrame (triggers re-render on change) | `const { gl, camera, scene } = useThree()` |
| `useThree((s) => s.camera)` | Subscribe to specific part of R3F state | `const camera = useThree((s) => s.camera)` |
| `<instancedMesh args={[g, m, count]}>` | Render `count` instances in one draw call | `<instancedMesh args={[undefined, undefined, 500]}>` |
| `mesh.setMatrixAt(i, matrix)` | Set the transform matrix for instance `i` | `meshRef.current.setMatrixAt(i, dummy.matrix)` |
| `mesh.setColorAt(i, color)` | Set the color for instance `i` | `meshRef.current.setColorAt(i, color)` |
| `instanceMatrix.needsUpdate` | Flag instance buffer as changed (required after `setMatrixAt`) | `meshRef.current.instanceMatrix.needsUpdate = true` |
| `React.memo(Component)` | Prevent re-renders when props haven't changed | `const Level = React.memo(function Level() { ... })` |
| `useGameStore.getState()` | Read Zustand state without subscribing (no re-render) | `const { speed } = useStore.getState()` |
| `store.subscribe(selector, cb)` | React to state changes without re-rendering | `store.subscribe((s) => s.score, (score) => { ... })` |
| `object.dispose()` | Free GPU memory for geometry/material/texture | `texture.dispose(); geometry.dispose()` |

---

## Common Pitfalls

### 1. Using useState for per-frame game state

```tsx
// WRONG: triggers re-render 60 times per second
function Player() {
  const [pos, setPos] = useState({ x: 0, y: 0, z: 0 });
  useFrame((_, delta) => {
    setPos((p) => ({ ...p, x: p.x + delta }));
  });
  return <mesh position={[pos.x, pos.y, pos.z]} />;
}

// RIGHT: mutate the ref directly, zero re-renders
function Player() {
  const ref = useRef<THREE.Mesh>(null!);
  useFrame((_, delta) => {
    ref.current.position.x += delta;
  });
  return <mesh ref={ref} />;
}
```

### 2. Creating new Three.js objects inside useFrame

```tsx
// WRONG: allocates a new Vector3 every frame → GC spikes
useFrame(() => {
  const target = new THREE.Vector3(5, 0, 0);
  meshRef.current.position.lerp(target, 0.1);
});

// RIGHT: allocate once, reuse forever
const target = useMemo(() => new THREE.Vector3(5, 0, 0), []);
useFrame(() => {
  meshRef.current.position.lerp(target, 0.1);
});
```

### 3. Not using InstancedMesh for repeated geometry

```tsx
// WRONG: 200 draw calls, 200 React components
function Stars() {
  return (
    <>
      {Array.from({ length: 200 }, (_, i) => (
        <mesh key={i} position={[Math.random() * 50 - 25, Math.random() * 50, Math.random() * 50 - 25]}>
          <sphereGeometry args={[0.05, 4, 4]} />
          <meshBasicMaterial color="white" />
        </mesh>
      ))}
    </>
  );
}

// RIGHT: 1 draw call, 1 React component
function Stars() {
  const meshRef = useRef<THREE.InstancedMesh>(null!);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  useEffect(() => {
    for (let i = 0; i < 200; i++) {
      dummy.position.set(
        Math.random() * 50 - 25,
        Math.random() * 50,
        Math.random() * 50 - 25
      );
      dummy.updateMatrix();
      meshRef.current.setMatrixAt(i, dummy.matrix);
    }
    meshRef.current.instanceMatrix.needsUpdate = true;
  }, [dummy]);

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, 200]}>
      <sphereGeometry args={[0.05, 4, 4]} />
      <meshBasicMaterial color="white" />
    </instancedMesh>
  );
}
```

### 4. Subscribing to entire Zustand store in a render component

```tsx
// WRONG: re-renders on ANY state change (position, score, phase, etc.)
function Enemy() {
  const state = useGameStore();
  // ...
}

// RIGHT: subscribe to only what you need, or use getState() in useFrame
function Enemy() {
  const ref = useRef<THREE.Mesh>(null!);
  useFrame(() => {
    const { playerPos } = useGameStore.getState();
    ref.current.lookAt(playerPos);
  });
  return <mesh ref={ref} />;
}
```

### 5. Forgetting to dispose textures/geometries on unmount

```tsx
// WRONG: texture leaks GPU memory on unmount
function Decal() {
  const texture = useMemo(
    () => new THREE.TextureLoader().load("/decal.png"),
    []
  );
  return (
    <mesh>
      <planeGeometry />
      <meshBasicMaterial map={texture} />
    </mesh>
  );
}

// RIGHT: dispose in useEffect cleanup
function Decal() {
  const texture = useMemo(
    () => new THREE.TextureLoader().load("/decal.png"),
    []
  );

  useEffect(() => {
    return () => texture.dispose();
  }, [texture]);

  return (
    <mesh>
      <planeGeometry />
      <meshBasicMaterial map={texture} />
    </mesh>
  );
}
```

### 6. Using React children for thousands of objects instead of InstancedMesh

```tsx
// WRONG: 2000 React components, 2000 draw calls
function Forest() {
  const trees = useMemo(() =>
    Array.from({ length: 2000 }, () => ({
      x: Math.random() * 100 - 50,
      z: Math.random() * 100 - 50,
      scale: 0.5 + Math.random() * 1.5,
    })),
    []
  );

  return (
    <>
      {trees.map((t, i) => (
        <mesh key={i} position={[t.x, 0, t.z]} scale={t.scale}>
          <coneGeometry args={[1, 3, 6]} />
          <meshStandardMaterial color="green" />
        </mesh>
      ))}
    </>
  );
}

// RIGHT: 1 component, 1 draw call
function Forest() {
  const meshRef = useRef<THREE.InstancedMesh>(null!);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  useEffect(() => {
    for (let i = 0; i < 2000; i++) {
      dummy.position.set(
        Math.random() * 100 - 50,
        0,
        Math.random() * 100 - 50
      );
      dummy.scale.setScalar(0.5 + Math.random() * 1.5);
      dummy.updateMatrix();
      meshRef.current.setMatrixAt(i, dummy.matrix);
    }
    meshRef.current.instanceMatrix.needsUpdate = true;
  }, [dummy]);

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, 2000]}>
      <coneGeometry args={[1, 3, 6]} />
      <meshStandardMaterial color="green" />
    </instancedMesh>
  );
}
```

---

## Exercises

### Exercise 1: Build the Bad Version

Create a particle system using `useState` to manage 100 particles. Each particle should:
- Spawn at the origin with a random upward velocity
- Be affected by gravity
- Reset when it falls below `y = -1`
- Be rendered as a small sphere

Use `r3f-perf` or the browser's fps counter to measure your frame rate. Note the fps — you should see it drop below 30fps even with just 100 particles. Try increasing to 200, 300, 500. Record at what count your system becomes unusable.

**Goal:** Feel the pain. Understand viscerally why useState + individual meshes doesn't scale.

### Exercise 2: Convert to InstancedMesh

Rewrite the particle fountain using:
- `useRef<THREE.InstancedMesh>` instead of individual mesh components
- A pre-allocated array of particle data objects (position, velocity, life) stored in a `useRef`
- The dummy `Object3D` pattern for setting instance matrices
- `useFrame` for all updates — zero `setState` calls

Target: 500 particles at 60fps. Verify with `r3f-perf` that you have exactly 1 draw call for the particles.

**Goal:** Internalize the InstancedMesh + ref + useFrame pattern. This is the pattern you'll use for every mass-object system in your games.

### Exercise 3: Add Object Pooling

Modify your particle fountain so particles are pooled:
- All 500 particles are pre-allocated at initialization
- When a particle "dies" (life expired or fell below ground), it doesn't get destroyed — it gets recycled
- The `resetParticle` function sets new random velocity and resets position to origin
- No new objects are ever created after initialization
- Verify in Chrome DevTools Performance tab that there are no GC (garbage collection) spikes during steady-state operation

**Goal:** Understand the pool pattern and why zero-allocation game loops matter.

### Exercise 4 (Stretch): Velocity-Based Color Gradient

Extend the particle fountain with per-instance colors based on velocity:
- Fast particles glow bright white/yellow
- Slow particles fade to deep red/orange
- Use `meshRef.current.setColorAt(i, color)` and set `instanceColor.needsUpdate = true`
- Calculate speed as `velocity.length()` and map it to a color range using `THREE.Color.setHSL()`
- The visual effect: a fountain that's bright at the base (high velocity) and dims at the apex (velocity approaches zero before falling)

**Goal:** Practice per-instance color manipulation and reinforce the `setColorAt` / `needsUpdate` API.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [R3F Performance Pitfalls](https://docs.pmnd.rs/react-three-fiber/advanced/pitfalls) | Docs | Official list of performance mistakes and fixes |
| [Three.js How to Dispose of Objects](https://threejs.org/docs/#manual/en/introduction/How-to-dispose-of-objects) | Docs | Authoritative guide to Three.js memory management |
| [InstancedMesh Three.js Docs](https://threejs.org/docs/#api/en/objects/InstancedMesh) | API Reference | Full API for InstancedMesh including setMatrixAt, setColorAt |
| [Zustand GitHub](https://github.com/pmndrs/zustand) | Library | Zustand docs, especially the `subscribeWithSelector` middleware |
| [r3f-perf](https://github.com/utsuboco/r3f-perf) | Tool | Performance monitoring overlay built for R3F |
| [React DevTools Profiler](https://react.dev/learn/react-developer-tools) | Tool | Find which components re-render and how often |
| [Why React Re-Renders](https://www.joshwcomeau.com/react/why-react-re-renders/) | Article | Deep explanation of React's re-render triggers — know your enemy |
| [Three.js Fundamentals: Optimize Lots of Objects](https://threejs.org/manual/#en/optimize-lots-of-objects) | Tutorial | Merge geometry, instancing, and other strategies from the Three.js manual |

---

## Key Takeaways

1. **React's render cycle is your frame budget enemy.** Every `setState` triggers reconciliation. At 60fps, that's unacceptable for per-frame game state. Reserve `useState` for things that change rarely — game phase, UI toggles, initial setup.

2. **"Imperative island inside declarative React."** This is the mental model. React sets up the scene declaratively. `useFrame` runs your imperative game loop inside that scene. Refs are the bridge between the two worlds.

3. **useFrame is your game loop.** It runs every frame, outside React's render cycle. All per-frame logic — physics, movement, animation, visual updates — belongs here. Always multiply by `delta` for frame-rate independence.

4. **Refs are the bridge.** `useRef<THREE.Mesh>(null!)` gives you direct access to Three.js objects. Mutate `.position`, `.rotation`, `.scale`, and `.material` properties directly. React never knows, and that's the point.

5. **InstancedMesh is your #1 performance tool.** Any time you have more than ~50 copies of the same geometry, use `InstancedMesh`. It collapses hundreds or thousands of draw calls into one. The dummy `Object3D` + `setMatrixAt` pattern will become second nature.

6. **Pre-allocate, pool, recycle.** Never create or destroy objects per frame. Pre-allocate arrays of data, toggle `.visible` or scale to zero instead of mounting/unmounting, and reuse objects from a pool. Your steady-state game loop should allocate zero bytes.

7. **Dispose manually.** Three.js geometries, materials, and textures leak GPU memory unless explicitly disposed. Use `useEffect` cleanup for manually created resources. R3F auto-disposes JSX-declared resources on unmount, but anything you `new` yourself is your responsibility.

8. **Measure, don't guess.** Use `r3f-perf` for a quick overlay, `renderer.info` for draw call counts, Chrome DevTools Performance tab for frame analysis, and React DevTools Profiler to find components that re-render when they shouldn't.

---

## What's Next?

You now know how to keep React out of your game loop's way. In **Module 2: Physics with Rapier**, you'll add a real physics engine that runs at fixed timesteps, handles collision detection, and integrates cleanly with the ref-based mutation patterns you learned here. The particle fountain you built? In Module 2, those particles will bounce off surfaces and interact with rigid bodies.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)