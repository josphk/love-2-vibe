# Module 0: Setup & First Game Loop

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** None (basic React/TypeScript knowledge assumed)

---

## Overview

You're about to build 3D stuff in the browser using React. Not vanilla Three.js with imperative spaghetti — actual declarative, component-based 3D scenes where a `<mesh>` is as natural as a `<div>`. React Three Fiber (R3F) is the bridge that makes this work, and by the end of this module you'll have a working solar system toy running at 60fps in your browser.

This module covers the absolute foundations: scaffolding a project, understanding how R3F's `<Canvas>` creates a WebGL context, placing objects in 3D space, lighting them, and — critically — running a game loop with `useFrame`. The game loop is where everything interesting happens. It's the heartbeat of every game, simulation, and interactive experience you'll ever build. Get comfortable with it here.

You'll also wire up click and hover interactions, use a handful of `drei` helpers to skip boilerplate, and walk away with a complete mini-project: a solar system where planets orbit a glowing sun, you can click to select them, and the camera is fully controllable. It's small, but it touches every concept you need to build on.

---

## 1. Setting Up the Project

### Scaffolding with Vite

Vite is the only sane choice for new React projects in 2025+. Create React App is dead. Next.js is overkill for a game. Vite gives you instant HMR, fast builds, and zero config pain.

```bash
npm create vite@latest solar-system-toy -- --template react-ts
cd solar-system-toy
```

### Installing R3F and Friends

You need three packages to get started:

```bash
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three
```

Here's what each one does:

| Package | Role |
|---------|------|
| `three` | The actual Three.js library — the 3D engine under the hood |
| `@react-three/fiber` | React reconciler for Three.js — lets you write Three.js as JSX |
| `@react-three/drei` | Helper library — hundreds of pre-built components so you don't reinvent wheels |
| `@types/three` | TypeScript types for Three.js |

### Project Structure

Delete the boilerplate Vite gives you and set up something clean:

```
solar-system-toy/
├── src/
│   ├── App.tsx            # Canvas + scene composition
│   ├── main.tsx           # Entry point (untouched)
│   ├── index.css          # Global styles (critical for Canvas sizing)
│   ├── components/
│   │   ├── Sun.tsx
│   │   ├── Planet.tsx
│   │   └── SolarSystem.tsx
│   └── vite-env.d.ts
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

### The CSS You Will Forget (And Then Waste 20 Minutes Debugging)

This is the single most common beginner problem. The Canvas renders into its parent container. If the parent has zero height, you see nothing. Put this in `index.css`:

```css
html,
body,
#root {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
}
```

That's it. Don't skip it. Don't "come back to it later." Do it now.

---

## 2. The Canvas Component

### What Canvas Actually Does

`<Canvas>` is the entry point for everything R3F. When you render it, here's what happens behind the scenes:

1. Creates a `<canvas>` DOM element
2. Initializes a WebGL2 rendering context
3. Sets up a Three.js `Scene`, `Camera`, and `WebGLRenderer`
4. Starts a render loop (requestAnimationFrame)
5. Creates a separate React reconciler — your R3F components live in a different React tree from your DOM components

That last point is important. Inside `<Canvas>`, you're not in DOM-land anymore. You can't render `<div>` or `<span>` inside it. Everything inside is Three.js objects expressed as JSX.

### Basic Canvas Setup

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'

export default function App() {
  return (
    <Canvas
      camera={{ position: [0, 5, 10], fov: 60 }}
      gl={{ antialias: true }}
    >
      {/* 3D content goes here */}
      <mesh>
        <boxGeometry />
        <meshStandardMaterial color="orange" />
      </mesh>
      <ambientLight intensity={0.5} />
    </Canvas>
  )
}
```

### Key Canvas Props

| Prop | Type | What It Does |
|------|------|--------------|
| `camera` | `object` | Sets default camera position, fov, near/far planes |
| `gl` | `object` | WebGL renderer options (antialias, toneMapping, etc.) |
| `shadows` | `boolean` | Enables shadow maps globally (off by default for perf) |
| `dpr` | `number \| [min, max]` | Device pixel ratio — use `[1, 2]` to cap on retina displays |
| `frameloop` | `'always' \| 'demand' \| 'never'` | Controls when the scene re-renders |

### Responsive Sizing

Canvas automatically fills its parent container and resizes on window resize. You don't need to manage this yourself — R3F handles it. Just make sure the parent has actual dimensions (see the CSS section above).

If you need the Canvas to only fill part of the screen, wrap it in a sized container:

```tsx
<div style={{ width: '800px', height: '600px' }}>
  <Canvas>
    {/* ... */}
  </Canvas>
</div>
```

---

## 3. Your First Mesh

### The Mesh Pattern

Every visible object in Three.js follows the same pattern: **mesh = geometry + material**. Geometry defines the shape (vertices, faces). Material defines the appearance (color, shininess, texture). The mesh combines them into a renderable object.

In R3F, this is expressed as nested JSX:

```tsx
<mesh position={[0, 0, 0]} rotation={[0, 0, 0]} scale={1}>
  <boxGeometry args={[1, 1, 1]} />
  <meshStandardMaterial color="hotpink" />
</mesh>
```

The `args` prop maps to constructor arguments. `boxGeometry args={[1, 1, 1]}` is equivalent to `new THREE.BoxGeometry(1, 1, 1)` — width, height, depth.

### Common Geometries

```tsx
{/* Box: args = [width, height, depth] */}
<boxGeometry args={[2, 1, 1]} />

{/* Sphere: args = [radius, widthSegments, heightSegments] */}
<sphereGeometry args={[1, 32, 32]} />

{/* Plane: args = [width, height] */}
<planeGeometry args={[10, 10]} />

{/* Cylinder: args = [radiusTop, radiusBottom, height, radialSegments] */}
<cylinderGeometry args={[0.5, 0.5, 2, 32]} />

{/* Torus: args = [radius, tubeRadius, radialSegments, tubularSegments] */}
<torusGeometry args={[1, 0.3, 16, 48]} />
```

### The Declarative 3D Paradigm

Here's the mental shift: you're not *building* a scene imperatively (create object, add to scene, position it, etc.). You're *describing* it. R3F diffs your JSX tree and updates the Three.js scene graph, just like React diffs the DOM.

This means conditional rendering works:

```tsx
{showPlanet && (
  <mesh position={[3, 0, 0]}>
    <sphereGeometry args={[0.5, 32, 32]} />
    <meshStandardMaterial color="blue" />
  </mesh>
)}
```

And so does mapping over arrays:

```tsx
{planets.map((planet) => (
  <mesh key={planet.id} position={planet.position}>
    <sphereGeometry args={[planet.radius, 32, 32]} />
    <meshStandardMaterial color={planet.color} />
  </mesh>
))}
```

---

## 4. The Three.js Coordinate System

### Right-Hand Rule, Y-Up

Three.js uses a right-handed coordinate system with Y pointing up:

```
        Y (up)
        |
        |
        |
        +------- X (right)
       /
      /
     Z (toward you)
```

To remember the right-hand rule: point your right hand's fingers along the positive X axis, curl them toward positive Y — your thumb points along positive Z (toward the camera).

### Position, Rotation, Scale

Every object in R3F accepts these transform props:

```tsx
<mesh
  position={[x, y, z]}    // Translation from origin
  rotation={[rx, ry, rz]} // Euler angles in radians
  scale={[sx, sy, sz]}    // Or a single number for uniform scale
>
```

Key facts:
- **Position** `[0, 0, 0]` is the center of the scene (or the center of the parent group)
- **Rotation** is in **radians**, not degrees. `Math.PI` = 180 degrees. `Math.PI / 2` = 90 degrees.
- **Scale** `1` = default size. `[2, 2, 2]` = double size. You can also just write `scale={2}`.

### Units

Three.js units are arbitrary, but the convention is to treat 1 unit as 1 meter. Physics engines, VR frameworks, and most community assets assume this. Stick with it unless you have a strong reason not to.

### Nesting and Local Space

When you nest objects, children are positioned relative to their parent. This is how you build complex hierarchies:

```tsx
{/* Parent group at x=5 */}
<group position={[5, 0, 0]}>
  {/* This child is at world position [7, 0, 0] */}
  <mesh position={[2, 0, 0]}>
    <sphereGeometry args={[0.5, 32, 32]} />
    <meshStandardMaterial color="red" />
  </mesh>
</group>
```

This nesting is how we'll make planets orbit the sun — rotate the parent group, and the child orbits around the parent's origin.

---

## 5. Colors and Materials

### Material Types

Three.js ships many materials. Here are the three you'll use 90% of the time:

**meshBasicMaterial** — Unlit. No shadows, no light response. Flat color. Use for UI elements, wireframes, debug visuals, or stylized art that doesn't need lighting.

```tsx
<meshBasicMaterial color="red" wireframe />
```

**meshStandardMaterial** — Physically-based (PBR). Responds to lights. Has roughness and metalness. This is your default choice for most things.

```tsx
<meshStandardMaterial
  color="#4488ff"
  roughness={0.5}    // 0 = mirror, 1 = matte
  metalness={0.2}    // 0 = plastic/wood, 1 = metal
/>
```

**meshPhysicalMaterial** — Extended PBR. Adds clearcoat, transmission (glass), sheen, iridescence. More expensive to render. Use only when you need the extra features.

```tsx
<meshPhysicalMaterial
  color="white"
  transmission={1}     // 1 = fully transparent glass
  roughness={0.1}
  thickness={0.5}      // Refraction depth
  ior={1.5}            // Index of refraction
/>
```

### Specifying Colors

R3F accepts colors in multiple formats:

```tsx
<meshStandardMaterial color="hotpink" />          {/* CSS color name */}
<meshStandardMaterial color="#ff6600" />           {/* Hex */}
<meshStandardMaterial color="rgb(255, 102, 0)" /> {/* RGB string */}
<meshStandardMaterial color={0xff6600} />          {/* Hex number */}
```

### Emissive Materials

For objects that "glow" (like our sun), use the `emissive` and `emissiveIntensity` props:

```tsx
<meshStandardMaterial
  color="#ffaa00"
  emissive="#ffaa00"
  emissiveIntensity={2}
/>
```

Emissive materials don't actually emit light in the scene — they just look bright. You still need a `<pointLight>` if you want them to illuminate other objects.

---

## 6. Lighting

### No Lights = Black Scene

If you use `meshStandardMaterial` or `meshPhysicalMaterial` and add zero lights, your scene will be pure black. This catches everyone exactly once. Now it won't catch you.

### Light Types

**ambientLight** — Even light everywhere. No shadows. Use it to fill in dark areas so they're not pitch black.

```tsx
<ambientLight intensity={0.3} color="#ffffff" />
```

**directionalLight** — Parallel rays from a direction (like the sun). Position sets the direction, not the origin.

```tsx
<directionalLight
  position={[5, 10, 5]}
  intensity={1}
  castShadow
/>
```

**pointLight** — Emits light in all directions from a point (like a light bulb). Has distance falloff.

```tsx
<pointLight
  position={[0, 0, 0]}
  intensity={100}      // Note: physically-correct intensity is high
  distance={50}        // Max range (0 = infinite)
  decay={2}            // Falloff rate
/>
```

**spotLight** — Cone of light from a point toward a target.

```tsx
<spotLight
  position={[0, 10, 0]}
  angle={Math.PI / 6}     // Cone angle
  penumbra={0.5}           // Edge softness (0-1)
  intensity={100}
  castShadow
/>
```

### Quick Shadow Setup

Shadows are off by default because they're expensive. To enable them:

1. Add `shadows` to `<Canvas>`
2. Add `castShadow` to lights
3. Add `castShadow` and `receiveShadow` to meshes

```tsx
<Canvas shadows>
  <directionalLight position={[5, 10, 5]} castShadow />
  <mesh castShadow>
    <boxGeometry />
    <meshStandardMaterial />
  </mesh>
  <mesh receiveShadow rotation={[-Math.PI / 2, 0, 0]} position={[0, -1, 0]}>
    <planeGeometry args={[20, 20]} />
    <meshStandardMaterial />
  </mesh>
</Canvas>
```

### Environment Maps (drei)

For fast, beautiful lighting without fiddling with individual lights, use drei's `<Environment>`:

```tsx
import { Environment } from '@react-three/drei'

<Environment preset="sunset" />
// Presets: apartment, city, dawn, forest, lobby, night, park, studio, sunset, warehouse
```

This wraps the scene in an HDR environment map that provides realistic reflections and ambient lighting.

---

## 7. The Game Loop: useFrame

### This Is the Most Important Section in This Module

`useFrame` is the game loop. It runs every frame — typically 60 times per second. Every animation, every physics update, every continuous interaction you'll ever build runs inside `useFrame`. Understand this hook deeply.

```tsx
import { useFrame } from '@react-three/fiber'

function SpinningBox() {
  useFrame((state, delta) => {
    // This runs every frame
    // delta = seconds since last frame (~0.016 at 60fps)
  })

  return (
    <mesh>
      <boxGeometry />
      <meshStandardMaterial color="orange" />
    </mesh>
  )
}
```

### The state Object

The first argument to `useFrame` gives you access to the entire R3F state:

| Property | Type | What It Is |
|----------|------|------------|
| `state.clock` | `THREE.Clock` | Elapsed time since scene start |
| `state.camera` | `THREE.Camera` | The active camera |
| `state.scene` | `THREE.Scene` | The scene graph root |
| `state.gl` | `THREE.WebGLRenderer` | The renderer |
| `state.pointer` | `{ x, y }` | Normalized mouse position (-1 to 1) |
| `state.size` | `{ width, height }` | Canvas size in pixels |

### Delta Time: Use It

The second argument, `delta`, is the time in seconds since the last frame. **Always multiply your movement/rotation by delta.** This makes your animation frame-rate independent — it'll look the same at 30fps, 60fps, or 144fps.

```tsx
useFrame((state, delta) => {
  // GOOD: Frame-rate independent
  meshRef.current!.rotation.y += 1.0 * delta

  // BAD: Tied to frame rate — faster on fast machines
  meshRef.current!.rotation.y += 0.01
})
```

### Refs, Not State — This Is Critical

Here's the rule you need to tattoo on your brain: **never use `useState` for values that change every frame.**

React state triggers re-renders. Re-renders are expensive. At 60fps, you'd be re-rendering your entire component tree 60 times a second. Your frame rate will tank.

Instead, use **refs** to access Three.js objects directly and mutate them:

```tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Mesh } from 'three'

function SpinningBox() {
  const meshRef = useRef<Mesh>(null)

  useFrame((state, delta) => {
    if (!meshRef.current) return
    meshRef.current.rotation.y += delta
    meshRef.current.rotation.x += delta * 0.5
  })

  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardMaterial color="orange" />
    </mesh>
  )
}
```

This is direct mutation of Three.js objects. No re-render. No virtual DOM diff. Just raw, fast updates at native speed.

### When useState IS Okay

Use React state for things that change infrequently in response to discrete events:
- Selecting an object (click)
- Toggling a mode on/off
- Changing a scene configuration

The rule of thumb: if it changes every frame, use a ref. If it changes in response to user action, state is fine.

---

## 8. Interaction: Click, Hover, Pointer Events

### Raycasting Under the Hood

When you click on a 3D scene, how does the browser know which object you clicked? **Raycasting**. R3F shoots an invisible ray from the camera through the mouse cursor and checks which objects it intersects. This happens automatically — you just attach event handlers.

### Pointer Events on Meshes

R3F meshes support pointer events just like DOM elements:

```tsx
function InteractiveBox() {
  const [hovered, setHovered] = useState(false)
  const [clicked, setClicked] = useState(false)

  return (
    <mesh
      onClick={() => setClicked(!clicked)}
      onPointerOver={() => setHovered(true)}
      onPointerOut={() => setHovered(false)}
      scale={clicked ? 1.5 : 1}
    >
      <boxGeometry />
      <meshStandardMaterial color={hovered ? 'hotpink' : 'orange'} />
    </mesh>
  )
}
```

### Available Events

| Event | When It Fires |
|-------|---------------|
| `onClick` | Mouse click (or tap) on the mesh |
| `onDoubleClick` | Double click on the mesh |
| `onPointerOver` | Mouse enters the mesh |
| `onPointerOut` | Mouse leaves the mesh |
| `onPointerDown` | Mouse button pressed on the mesh |
| `onPointerUp` | Mouse button released on the mesh |
| `onPointerMove` | Mouse moves while over the mesh |

### The Event Object

Every event handler receives a rich event object:

```tsx
onClick={(event) => {
  event.stopPropagation()  // Prevent event from reaching objects behind
  console.log(event.point)       // World-space intersection point
  console.log(event.distance)    // Distance from camera
  console.log(event.object)      // The Three.js object that was hit
  console.log(event.face)        // The face that was hit
  console.log(event.faceIndex)   // Index of the face
}}
```

### Cursor Changes

Change the cursor when hovering over interactive objects — it's a small touch that makes your scene feel polished:

```tsx
onPointerOver={() => {
  document.body.style.cursor = 'pointer'
  setHovered(true)
}}
onPointerOut={() => {
  document.body.style.cursor = 'auto'
  setHovered(false)
}}
```

---

## 9. Drei Helpers

### What Drei Gives You

`@react-three/drei` is a collection of hundreds of helper components. It exists so you don't have to write boilerplate. Here are the ones relevant to this module:

### OrbitControls

Click-and-drag camera controls. Rotate, zoom, pan. Essential for development and great for many game types.

```tsx
import { OrbitControls } from '@react-three/drei'

// Inside Canvas:
<OrbitControls
  enableDamping        // Smooth deceleration
  dampingFactor={0.05}
  minDistance={5}       // Minimum zoom
  maxDistance={50}      // Maximum zoom
  maxPolarAngle={Math.PI / 2}  // Don't let camera go below ground
/>
```

### Stars

Instant starfield background. Perfect for space scenes.

```tsx
import { Stars } from '@react-three/drei'

<Stars
  radius={100}    // Sphere radius
  depth={50}      // Depth of star volume
  count={5000}    // Number of stars
  factor={4}      // Size factor
  saturation={0}  // Color saturation (0 = white)
  fade            // Fade stars at edges
  speed={1}       // Twinkle speed
/>
```

### Text

3D text using SDF fonts. Much better than Three.js TextGeometry.

```tsx
import { Text } from '@react-three/drei'

<Text
  position={[0, 2, 0]}
  fontSize={0.5}
  color="white"
  anchorX="center"
  anchorY="middle"
>
  Hello World
</Text>
```

### Float

Makes an object gently bob up and down. Instant "living" feel.

```tsx
import { Float } from '@react-three/drei'

<Float
  speed={2}           // Animation speed
  rotationIntensity={0.5}  // Rotation wobble
  floatIntensity={1}       // Up/down intensity
>
  <mesh>
    <sphereGeometry />
    <meshStandardMaterial color="coral" />
  </mesh>
</Float>
```

### Html

Render HTML content anchored to a 3D position. Good for labels, tooltips, HUDs.

```tsx
import { Html } from '@react-three/drei'

<mesh position={[3, 0, 0]}>
  <sphereGeometry args={[0.5, 32, 32]} />
  <meshStandardMaterial color="blue" />
  <Html position={[0, 1, 0]} center>
    <div style={{ color: 'white', fontSize: '14px' }}>Earth</div>
  </Html>
</mesh>
```

---

## Code Walkthrough: Building the Solar System Toy

Let's build the complete project step by step. Every file, every line.

### Step 1: Project Setup

```bash
npm create vite@latest solar-system-toy -- --template react-ts
cd solar-system-toy
npm install three @react-three/fiber @react-three/drei
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

### Step 3: The Sun Component

```tsx
// src/components/Sun.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Mesh } from 'three'

export function Sun() {
  const meshRef = useRef<Mesh>(null)

  useFrame((_, delta) => {
    if (!meshRef.current) return
    meshRef.current.rotation.y += delta * 0.1
  })

  return (
    <group>
      {/* The point light sits at the center — this is what illuminates planets */}
      <pointLight intensity={800} distance={100} decay={2} color="#fff5e0" />

      {/* The visible sun sphere */}
      <mesh ref={meshRef}>
        <sphereGeometry args={[2, 64, 64]} />
        <meshStandardMaterial
          color="#ffcc00"
          emissive="#ff8800"
          emissiveIntensity={3}
          toneMapped={false}
        />
      </mesh>
    </group>
  )
}
```

`toneMapped={false}` lets the emissive material blow out past normal brightness — it makes the sun look properly radiant instead of clamped.

### Step 4: The Planet Component

```tsx
// src/components/Planet.tsx
import { useRef, useState } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import type { Group } from 'three'

interface PlanetProps {
  name: string
  color: string
  radius: number
  orbitRadius: number
  orbitSpeed: number
  startAngle?: number
}

export function Planet({
  name,
  color,
  radius,
  orbitRadius,
  orbitSpeed,
  startAngle = 0,
}: PlanetProps) {
  const groupRef = useRef<Group>(null)
  const angleRef = useRef(startAngle)
  const [selected, setSelected] = useState(false)
  const [hovered, setHovered] = useState(false)

  useFrame((_, delta) => {
    if (!groupRef.current) return

    // Update orbit angle
    angleRef.current += orbitSpeed * delta

    // Calculate position on circular orbit
    const x = Math.cos(angleRef.current) * orbitRadius
    const z = Math.sin(angleRef.current) * orbitRadius

    groupRef.current.position.x = x
    groupRef.current.position.z = z
  })

  return (
    <group ref={groupRef}>
      <mesh
        onClick={(e) => {
          e.stopPropagation()
          setSelected(!selected)
        }}
        onPointerOver={(e) => {
          e.stopPropagation()
          setHovered(true)
          document.body.style.cursor = 'pointer'
        }}
        onPointerOut={() => {
          setHovered(false)
          document.body.style.cursor = 'auto'
        }}
        scale={selected ? 1.4 : hovered ? 1.15 : 1}
      >
        <sphereGeometry args={[radius, 32, 32]} />
        <meshStandardMaterial
          color={color}
          roughness={0.7}
          metalness={0.1}
        />
      </mesh>

      {/* Planet name label — visible when selected */}
      {selected && (
        <Text
          position={[0, radius + 0.6, 0]}
          fontSize={0.4}
          color="white"
          anchorX="center"
          anchorY="bottom"
        >
          {name}
        </Text>
      )}
    </group>
  )
}
```

Notice the pattern: `angleRef` stores the continuously-updated orbit angle (changes every frame, so it's a ref). `selected` and `hovered` are React state because they change on discrete click/hover events.

### Step 5: The Solar System Scene

```tsx
// src/components/SolarSystem.tsx
import { Sun } from './Sun'
import { Planet } from './Planet'

const PLANETS = [
  {
    name: 'Mercury',
    color: '#b5b5b5',
    radius: 0.3,
    orbitRadius: 4,
    orbitSpeed: 1.6,
    startAngle: 0,
  },
  {
    name: 'Venus',
    color: '#e8cda0',
    radius: 0.5,
    orbitRadius: 6,
    orbitSpeed: 1.1,
    startAngle: Math.PI * 0.7,
  },
  {
    name: 'Earth',
    color: '#4488ff',
    radius: 0.55,
    orbitRadius: 8.5,
    orbitSpeed: 0.8,
    startAngle: Math.PI * 1.3,
  },
  {
    name: 'Mars',
    color: '#cc4422',
    radius: 0.4,
    orbitRadius: 11,
    orbitSpeed: 0.6,
    startAngle: Math.PI * 0.4,
  },
]

export function SolarSystem() {
  return (
    <group>
      <Sun />
      {PLANETS.map((planet) => (
        <Planet key={planet.name} {...planet} />
      ))}
    </group>
  )
}
```

### Step 6: The App with Canvas

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { Stars, OrbitControls } from '@react-three/drei'
import { SolarSystem } from './components/SolarSystem'

export default function App() {
  return (
    <Canvas
      camera={{ position: [0, 15, 20], fov: 50 }}
      gl={{ antialias: true }}
    >
      {/* Dim ambient so the dark side of planets isn't pure black */}
      <ambientLight intensity={0.08} />

      {/* Stars background */}
      <Stars
        radius={200}
        depth={60}
        count={4000}
        factor={5}
        saturation={0}
        fade
        speed={0.5}
      />

      {/* The solar system */}
      <SolarSystem />

      {/* Camera controls */}
      <OrbitControls
        enableDamping
        dampingFactor={0.05}
        minDistance={5}
        maxDistance={60}
      />
    </Canvas>
  )
}
```

### Step 7: Entry Point (Untouched)

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

You should see a glowing sun with four planets orbiting it against a starfield. Click any planet to select it and see its name. Drag to rotate the camera. Scroll to zoom.

---

## API Quick Reference

### Core R3F

| Function/Hook | Description | Example |
|---------------|-------------|---------|
| `<Canvas>` | Root component, creates WebGL context and render loop | `<Canvas camera={{ position: [0, 5, 10] }}>` |
| `useFrame(callback)` | Runs callback every frame; receives `(state, delta)` | `useFrame((_, d) => ref.current!.rotation.y += d)` |
| `useThree()` | Access R3F state outside useFrame (camera, gl, scene, size) | `const { camera, size } = useThree()` |
| `<mesh>` | Container for geometry + material | `<mesh position={[1, 0, 0]} ref={ref}>` |
| `<group>` | Empty transform node for grouping objects | `<group rotation={[0, angle, 0]}>` |

### Common Geometries

| Geometry | Constructor Args | Notes |
|----------|-----------------|-------|
| `<boxGeometry>` | `[width, height, depth]` | Default: 1x1x1 |
| `<sphereGeometry>` | `[radius, wSegs, hSegs]` | Use 32+ segments for smooth |
| `<planeGeometry>` | `[width, height]` | Faces +Z by default |
| `<cylinderGeometry>` | `[rTop, rBottom, height, segs]` | Set one radius to 0 for cone |
| `<torusGeometry>` | `[radius, tube, rSegs, tSegs]` | Donut shape |

### Materials

| Material | Use Case | Key Props |
|----------|----------|-----------|
| `<meshBasicMaterial>` | Unlit / wireframe / debug | `color`, `wireframe`, `opacity` |
| `<meshStandardMaterial>` | General purpose PBR | `color`, `roughness`, `metalness`, `emissive` |
| `<meshPhysicalMaterial>` | Glass, clearcoat, advanced | `transmission`, `ior`, `clearcoat`, `sheen` |

### Lights

| Light | Type | Key Props |
|-------|------|-----------|
| `<ambientLight>` | Even fill, no direction | `intensity`, `color` |
| `<directionalLight>` | Parallel rays (sun) | `position`, `intensity`, `castShadow` |
| `<pointLight>` | Omnidirectional (bulb) | `position`, `intensity`, `distance`, `decay` |
| `<spotLight>` | Cone (flashlight) | `position`, `angle`, `penumbra`, `castShadow` |

### Drei Helpers

| Component | What It Does | Example |
|-----------|-------------|---------|
| `<OrbitControls>` | Click-drag camera rotation, zoom, pan | `<OrbitControls enableDamping />` |
| `<Stars>` | Starfield particle background | `<Stars count={5000} fade />` |
| `<Text>` | SDF text rendering | `<Text fontSize={0.5}>Hello</Text>` |
| `<Float>` | Gentle bobbing animation | `<Float speed={2}><mesh>...</mesh></Float>` |
| `<Html>` | DOM content at 3D position | `<Html center><div>Label</div></Html>` |
| `<Environment>` | HDR environment map lighting | `<Environment preset="sunset" />` |

---

## Common Pitfalls

### 1. Using useState for Per-Frame Updates

This is the number one R3F performance killer. React state triggers re-renders. At 60fps, that's 60 re-renders per second, each running the full React reconciler.

```tsx
// WRONG — re-renders 60 times per second, murders performance
function SpinningBox() {
  const [rotation, setRotation] = useState(0)

  useFrame((_, delta) => {
    setRotation((prev) => prev + delta) // Triggers re-render every frame!
  })

  return (
    <mesh rotation={[0, rotation, 0]}>
      <boxGeometry />
      <meshStandardMaterial />
    </mesh>
  )
}

// RIGHT — direct mutation via ref, zero re-renders
function SpinningBox() {
  const meshRef = useRef<Mesh>(null)

  useFrame((_, delta) => {
    meshRef.current!.rotation.y += delta // Direct mutation, no re-render
  })

  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardMaterial />
    </mesh>
  )
}
```

### 2. Forgetting Refs for Three.js Object Access

If you need to read or write a Three.js object's properties in `useFrame`, you need a ref to it. Without a ref, you have no handle on the underlying Three.js object.

```tsx
// WRONG — no ref, no way to access the mesh in useFrame
function AnimatedBox() {
  useFrame(() => {
    // How do I rotate the box? I have no reference to it!
  })

  return (
    <mesh>
      <boxGeometry />
      <meshStandardMaterial />
    </mesh>
  )
}

// RIGHT — ref gives you direct access
function AnimatedBox() {
  const ref = useRef<Mesh>(null)

  useFrame((_, delta) => {
    ref.current!.rotation.y += delta
  })

  return (
    <mesh ref={ref}>
      <boxGeometry />
      <meshStandardMaterial />
    </mesh>
  )
}
```

### 3. No Lights in the Scene

`meshStandardMaterial` and `meshPhysicalMaterial` need light to be visible. Without lights, everything is black and you'll think your code is broken.

```tsx
// WRONG — standard material in a scene with no lights = black screen
<Canvas>
  <mesh>
    <boxGeometry />
    <meshStandardMaterial color="red" />
  </mesh>
</Canvas>

// RIGHT — add at least one light source
<Canvas>
  <ambientLight intensity={0.5} />
  <directionalLight position={[5, 5, 5]} intensity={1} />
  <mesh>
    <boxGeometry />
    <meshStandardMaterial color="red" />
  </mesh>
</Canvas>
```

### 4. Canvas Has Zero Height

The `<Canvas>` fills its parent. If the parent has no height, you see nothing. No error. No warning. Just a blank page.

```css
/* WRONG — root has no explicit height */
#root {
  /* nothing */
}

/* RIGHT — full viewport coverage */
html,
body,
#root {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
}
```

### 5. Importing from 'three' vs '@react-three/fiber'

Use `three` for types, constants, and utility classes. Use `@react-three/fiber` for hooks and the Canvas component. Don't mix them up.

```tsx
// WRONG — trying to import hooks from three
import { useFrame } from 'three' // This doesn't exist

// WRONG — trying to use Three.js classes imperatively inside JSX
import { Mesh, BoxGeometry } from 'three'
// Then trying to manually create and add to scene...

// RIGHT — types from three, hooks from fiber
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Mesh } from 'three'

function MyComponent() {
  const ref = useRef<Mesh>(null)
  useFrame(() => { /* ... */ })
  return <mesh ref={ref}>{/* ... */}</mesh>
}
```

---

## Exercises

### Exercise 1: Add a Moon Orbiting Earth

**Time:** 20–30 minutes

Create a `Moon` component that orbits around Earth. This requires nested transforms — the moon needs to orbit Earth's position, not the origin.

Hints:
- Make the moon a child of the planet's `<group>`
- Give it its own `useFrame` with its own angleRef
- Radius of ~0.15, orbit radius ~1.2 from the planet center
- Make it a gray color like `#aaaaaa`

**Stretch goal:** Add a tilt to the moon's orbit plane by rotating the parent group on the X axis.

### Exercise 2: Add a Comet with a Trail

**Time:** 30–40 minutes

Create a comet with an elliptical orbit and a glowing trail using drei's `<Trail>` component.

```tsx
import { Trail } from '@react-three/drei'

<Trail
  width={2}
  length={8}
  color="cyan"
  attenuation={(t) => t * t}  // Fade shape
>
  <mesh ref={cometRef}>
    <sphereGeometry args={[0.15, 16, 16]} />
    <meshBasicMaterial color="cyan" />
  </mesh>
</Trail>
```

For an elliptical orbit, use different radii for X and Z in your orbit calculation:

```tsx
const x = Math.cos(angle) * 18   // Wide
const z = Math.sin(angle) * 8    // Narrow
```

**Stretch goal:** Make the comet speed up near the sun and slow down far away (Kepler's second law — approximate it by scaling speed inversely with distance).

### Exercise 3: Orbit Paths and Planet Variety

**Time:** 20–30 minutes

Add visible orbit paths using drei's `<Line>` component, and give each planet a distinct visual identity.

```tsx
import { Line } from '@react-three/drei'

function OrbitPath({ radius }: { radius: number }) {
  const points = Array.from({ length: 129 }, (_, i) => {
    const angle = (i / 128) * Math.PI * 2
    return [Math.cos(angle) * radius, 0, Math.sin(angle) * radius] as const
  })

  return (
    <Line
      points={points}
      color="#ffffff"
      opacity={0.15}
      transparent
      lineWidth={0.5}
    />
  )
}
```

Give each planet different `roughness`, `metalness`, and consider adding rings to one planet (Saturn) using a `<torusGeometry>` or `<ringGeometry>` with a flat scale on Y.

**Stretch goal:** Add planet rotation (spin on its own axis) at different speeds, independent of orbital motion.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [R3F Documentation](https://r3f.docs.pmnd.rs/) | Official Docs | The authoritative source. API reference, examples, tutorials. |
| [Drei Documentation](https://drei.docs.pmnd.rs/) | Official Docs | Browse all available helpers — there are hundreds you'll use constantly. |
| [Three.js Fundamentals](https://threejs.org/manual/#en/fundamentals) | Tutorial | Understand what R3F abstracts over. Read the first 5 chapters. |
| [Bruno Simon's Three.js Journey](https://threejs-journey.com/) | Course | The gold standard Three.js course. Chapters on R3F included. |
| [Poimandres GitHub](https://github.com/pmndrs) | Code | The team behind R3F, drei, zustand, and more. Study their examples. |
| [R3F Examples](https://r3f.docs.pmnd.rs/getting-started/examples) | Examples | Dozens of working demos with source code. |

---

## Key Takeaways

1. **R3F lets you write Three.js as declarative React components.** `<mesh>`, `<boxGeometry>`, and `<meshStandardMaterial>` are JSX — not HTML, not DOM elements, but Three.js objects managed by a React reconciler.

2. **`useFrame` is your game loop.** It runs every frame. Use it for animation, physics, input processing — anything continuous. Always multiply movement by `delta` for frame-rate independence.

3. **Refs for per-frame updates, state for discrete events.** This is the most important performance rule in R3F. Mutate Three.js objects directly via refs. Reserve `useState` for things like selection, toggles, and mode changes.

4. **Nesting creates local coordinate spaces.** Child objects are positioned relative to their parent. Rotating a parent group rotates all its children around the parent's origin — this is how orbits work.

5. **Drei saves you hundreds of lines of boilerplate.** Before you write a custom solution for anything, check if drei already has it. It probably does.

6. **Three common setup traps to avoid:** no CSS height on the Canvas parent, no lights with PBR materials, and using `useState` in `useFrame`. Now you know. You'll never lose time to these.

---

## What's Next?

You have a working R3F project with animation, interaction, and camera controls. Now it's time to understand **why** certain patterns are fast and others are slow.

**[Module 1: React Performance for Games](module-01-react-performance-for-games.md)** teaches you the ref-mutation pattern in depth, introduces `InstancedMesh` for rendering thousands of objects in a single draw call, and shows you — viscerally — what happens when you use `useState` at 60fps. You'll build a particle fountain that either runs at 5fps or 60fps depending on which pattern you use.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
