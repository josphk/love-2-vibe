# Module 3: Cameras, Input & Character Control

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** [Module 2: 3D Assets & World Building](module-02-assets-world-building.md)

---

## Overview

Your 3D world exists, but right now you're a disembodied ghost floating in the void, looking at it from a fixed camera angle. That changes here. This module is about giving the player a body, eyes, and the ability to move. Cameras, input, and character control are the holy trinity of "the game actually feels like a game."

You'll build three different camera systems — orbit, first-person, and third-person — and understand when each one is the right choice. You'll wire up keyboard and gamepad input using a clean declarative pattern. You'll load a character model, animate it with idle/walk/run blending, and get it moving through a 3D environment with a smooth follow camera. This is the module where your project stops being a tech demo and starts feeling interactive.

The mini-project ties it all together: a walking character in a 3D environment with animated movement, a third-person camera that follows smoothly, keyboard and gamepad support, and an orbit camera fallback for development. By the end you'll have a reusable character controller pattern you can drop into any future project.

---

## 1. Camera Fundamentals

### The Camera Is Just a Scene Graph Object

This is the mental model that unlocks everything else in this module. A camera in Three.js isn't magical. It's an `Object3D` — the same base class as meshes, groups, and lights. It has a position, a rotation, and a parent in the scene graph. You can attach it to a group, move that group, and the camera moves with it. You can make it a child of a character model, and it follows the character automatically. Everything you learned about nesting and local coordinate spaces in Module 0 applies directly to cameras.

### PerspectiveCamera

This is what you'll use 95% of the time. It simulates how human eyes see the world — things farther away appear smaller.

```tsx
import { PerspectiveCamera } from '@react-three/drei'

<PerspectiveCamera
  makeDefault           // Makes this the active camera for the scene
  position={[0, 5, 10]}
  fov={60}              // Field of view in degrees (vertical)
  near={0.1}            // Nearest visible distance
  far={1000}            // Farthest visible distance
/>
```

Key props and what they actually mean:

| Prop | Type | Effect |
|------|------|--------|
| `fov` | `number` | Field of view in degrees. 60–75 is natural. Lower = telephoto zoom. Higher = fisheye. |
| `aspect` | `number` | Width/height ratio. R3F sets this automatically — don't touch it. |
| `near` | `number` | Objects closer than this are invisible. Keep it as large as possible (0.1, not 0.001). |
| `far` | `number` | Objects farther than this are invisible. Keep it as small as possible. |
| `makeDefault` | `boolean` | Drei prop — tells R3F "this is the camera to render from." |

The `near` and `far` values define the **frustum** — the pyramid-shaped region of space the camera can see. Everything outside the frustum is clipped (invisible). Setting `near` too small or `far` too large causes **z-fighting** — flickering artifacts where two surfaces are at nearly the same depth and the GPU can't decide which is in front. Default values of `near={0.1}` and `far={1000}` work for most games.

### OrthographicCamera

No perspective distortion. Objects stay the same size regardless of distance. Used for 2D games, strategy games, UI overlays, and isometric views.

```tsx
import { OrthographicCamera } from '@react-three/drei'

<OrthographicCamera
  makeDefault
  position={[10, 10, 10]}
  zoom={50}
  near={0.1}
  far={1000}
/>
```

With an orthographic camera, `zoom` controls how much of the scene is visible. Higher zoom = closer view. There's no `fov` because there's no perspective.

### R3F's Default Camera

If you don't create a camera explicitly, R3F creates a default `PerspectiveCamera` at `[0, 0, 5]` looking at the origin. You can configure it via the Canvas prop:

```tsx
<Canvas camera={{ position: [0, 5, 10], fov: 60, near: 0.1, far: 1000 }}>
```

This is fine for prototyping. Once you need to move the camera dynamically, switch to a `<PerspectiveCamera>` component with `makeDefault` so you have a ref to it.

### Getting a Camera Ref

```tsx
import { useRef } from 'react'
import { useThree } from '@react-three/fiber'
import type { PerspectiveCamera as PerspectiveCameraType } from 'three'

// Option 1: From useThree (gets whatever camera is active)
function CameraLogger() {
  const { camera } = useThree()
  console.log(camera.position)
  return null
}

// Option 2: Direct ref on a drei camera component
function MyCamera() {
  const cameraRef = useRef<PerspectiveCameraType>(null)
  return <PerspectiveCamera ref={cameraRef} makeDefault position={[0, 5, 10]} />
}
```

---

## 2. OrbitControls

### The Swiss Army Knife Camera

`OrbitControls` from drei is the camera you'll use during development on every single project, and it's the right production camera for strategy games, model viewers, editors, and any scenario where the player orbits around a focal point.

```tsx
import { OrbitControls } from '@react-three/drei'

<OrbitControls
  target={[0, 1, 0]}           // The point the camera orbits around
  enableDamping                  // Smooth deceleration after releasing
  dampingFactor={0.05}           // How quickly damping settles (lower = smoother)
  minDistance={2}                // Closest zoom
  maxDistance={50}               // Farthest zoom
  minPolarAngle={0}              // Minimum vertical angle (0 = directly above)
  maxPolarAngle={Math.PI / 2}   // Maximum vertical angle (PI/2 = horizon)
  autoRotate                     // Slowly auto-rotates when idle
  autoRotateSpeed={0.5}          // Rotation speed
  enablePan={false}              // Disable right-click pan
/>
```

### Props Reference

| Prop | Type | Default | What It Does |
|------|------|---------|--------------|
| `target` | `[x, y, z]` | `[0,0,0]` | Orbit center point |
| `enableDamping` | `boolean` | `false` | Smooth inertia on release |
| `dampingFactor` | `number` | `0.05` | Damping strength |
| `minDistance` | `number` | `0` | Minimum zoom distance |
| `maxDistance` | `number` | `Infinity` | Maximum zoom distance |
| `minPolarAngle` | `number` | `0` | Min vertical rotation (radians) |
| `maxPolarAngle` | `number` | `Math.PI` | Max vertical rotation (radians) |
| `minAzimuthAngle` | `number` | `-Infinity` | Min horizontal rotation |
| `maxAzimuthAngle` | `number` | `Infinity` | Max horizontal rotation |
| `enablePan` | `boolean` | `true` | Allow right-click panning |
| `enableZoom` | `boolean` | `true` | Allow scroll zooming |
| `enableRotate` | `boolean` | `true` | Allow left-click rotation |
| `autoRotate` | `boolean` | `false` | Auto-rotate when idle |
| `autoRotateSpeed` | `number` | `2` | Auto-rotation speed |

### Dynamically Updating the Target

If you want OrbitControls to follow a moving object (like a selected character), update the target in `useFrame`:

```tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'
import type { OrbitControls as OrbitControlsType } from 'three-stdlib'

function FollowOrbitControls({ targetPosition }: { targetPosition: [number, number, number] }) {
  const controlsRef = useRef<OrbitControlsType>(null)

  useFrame(() => {
    if (!controlsRef.current) return
    controlsRef.current.target.set(...targetPosition)
    controlsRef.current.update()
  })

  return <OrbitControls ref={controlsRef} enableDamping />
}
```

### When to Switch Away from OrbitControls

OrbitControls is great until it isn't. Switch to a custom camera when:
- You need a first-person or third-person view that follows a character
- The player shouldn't be able to clip through walls
- You need camera shake, cutscenes, or cinematic transitions
- The orbit metaphor doesn't match your game (platformers, shooters, etc.)

Think of OrbitControls as your development camera. Keep it around as a debug fallback — disable it in production or toggle it with a key.

---

## 3. First-Person Camera (PointerLockControls)

### Mouse Capture and Look-Around

First-person cameras need to capture the mouse cursor so the player can look around without the cursor hitting the edge of the screen. This uses the browser's Pointer Lock API — the cursor disappears, and mouse movement events report relative deltas instead of absolute positions.

```tsx
import { PointerLockControls } from '@react-three/drei'

function FPSScene() {
  return (
    <>
      <PointerLockControls />
      {/* Scene content */}
    </>
  )
}
```

When you click the Canvas, the cursor locks. Press Escape to release it. That's it — drei handles the API for you.

### PointerLockControls Props

| Prop | Type | Default | What It Does |
|------|------|---------|--------------|
| `selector` | `string` | `undefined` | CSS selector for the element that triggers lock on click |
| `onChange` | `function` | — | Fires when the camera rotates |
| `onLock` | `function` | — | Fires when pointer locks |
| `onUnlock` | `function` | — | Fires when pointer unlocks |

### Sensitivity

`PointerLockControls` from drei doesn't expose a sensitivity prop directly. You need to access the underlying controls to adjust it:

```tsx
import { useRef, useEffect } from 'react'
import { PointerLockControls as PointerLockControlsImpl } from 'three-stdlib'
import { PointerLockControls } from '@react-three/drei'

function FPSCamera({ sensitivity = 0.002 }) {
  const controlsRef = useRef<PointerLockControlsImpl>(null)

  useEffect(() => {
    if (!controlsRef.current) return
    // The pointerSpeed property controls mouse sensitivity
    controlsRef.current.pointerSpeed = sensitivity
  }, [sensitivity])

  return <PointerLockControls ref={controlsRef} />
}
```

### Combining with WASD Movement

PointerLockControls handles looking. Movement is on you. The camera has a direction it's facing — you extract forward and right vectors from it and move based on input:

```tsx
import { useRef } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import * as THREE from 'three'

function FPSMovement({ speed = 5 }: { speed?: number }) {
  const { camera } = useThree()
  const keysRef = useRef<Set<string>>(new Set())

  // Track key state
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => keysRef.current.add(e.code)
    const onKeyUp = (e: KeyboardEvent) => keysRef.current.delete(e.code)
    window.addEventListener('keydown', onKeyDown)
    window.addEventListener('keyup', onKeyUp)
    return () => {
      window.removeEventListener('keydown', onKeyDown)
      window.removeEventListener('keyup', onKeyUp)
    }
  }, [])

  useFrame((_, delta) => {
    const keys = keysRef.current
    const direction = new THREE.Vector3()

    // Get forward/right vectors from camera
    const forward = new THREE.Vector3()
    camera.getWorldDirection(forward)
    forward.y = 0         // Project onto horizontal plane
    forward.normalize()

    const right = new THREE.Vector3()
    right.crossVectors(forward, camera.up).normalize()

    // Build direction from keys
    if (keys.has('KeyW')) direction.add(forward)
    if (keys.has('KeyS')) direction.sub(forward)
    if (keys.has('KeyD')) direction.add(right)
    if (keys.has('KeyA')) direction.sub(right)

    // Normalize so diagonal movement isn't faster
    if (direction.length() > 0) {
      direction.normalize()
    }

    // Apply movement
    camera.position.addScaledVector(direction, speed * delta)
  })

  return null
}
```

### The Pointer Lock API — What's Actually Happening

Under the hood, `PointerLockControls` calls `canvas.requestPointerLock()`. This is a browser API that:
1. Hides the cursor
2. Fires `mousemove` events with `movementX` and `movementY` (relative deltas, not absolute positions)
3. Constrains the "virtual" cursor to the element (no edge escaping)
4. Requires a user gesture (click) to activate — you can't lock the pointer on page load
5. Can be exited by the user pressing Escape at any time

Important: some browsers show a permission prompt the first time. Your game should handle the case where the user declines or exits pointer lock.

---

## 4. Third-Person Camera

### The Follow Camera Pattern

A third-person camera sits behind and above the player, following their movement. It's the most common camera in 3D action games, and getting it right is the difference between "this feels amazing" and "I'm going to throw up."

The core idea: every frame, calculate where the camera *should* be (behind the player at an offset), and **lerp** toward that position instead of snapping to it. The lerp creates smooth, floaty follow behavior.

### Building a Follow Camera from Scratch

```tsx
import { useRef } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import * as THREE from 'three'

interface FollowCameraProps {
  target: React.RefObject<THREE.Object3D | null>
  offset?: [number, number, number]    // Camera offset from target
  smoothSpeed?: number                  // How quickly camera catches up (0–1 range per frame)
  lookAtOffset?: [number, number, number] // Where to look relative to target
}

function FollowCamera({
  target,
  offset = [0, 4, 8],
  smoothSpeed = 5,
  lookAtOffset = [0, 1.5, 0],
}: FollowCameraProps) {
  const { camera } = useThree()
  const desiredPosition = useRef(new THREE.Vector3())
  const lookAtTarget = useRef(new THREE.Vector3())

  useFrame((_, delta) => {
    if (!target.current) return

    // Get target's world position
    const targetWorldPos = new THREE.Vector3()
    target.current.getWorldPosition(targetWorldPos)

    // Calculate desired camera position (behind and above the target)
    // If target is rotated, the offset follows the rotation
    const offsetVec = new THREE.Vector3(...offset)
    offsetVec.applyQuaternion(target.current.quaternion)
    desiredPosition.current.copy(targetWorldPos).add(offsetVec)

    // Lerp camera position toward desired position
    camera.position.lerp(desiredPosition.current, 1 - Math.exp(-smoothSpeed * delta))

    // Look at the target (slightly above center mass)
    lookAtTarget.current.copy(targetWorldPos).add(new THREE.Vector3(...lookAtOffset))
    camera.lookAt(lookAtTarget.current)
  })

  return null
}
```

### Understanding lerp and slerp

**lerp** (linear interpolation) smoothly moves a value from A to B.

```tsx
// THREE.Vector3.lerp(target, alpha)
// alpha = 0 means "stay where I am"
// alpha = 1 means "snap to target"
// alpha = 0.1 means "move 10% toward target each call"
camera.position.lerp(desiredPosition, alpha)
```

But there's a problem: if you pass a fixed alpha like `0.1`, the smoothing is frame-rate dependent. At 60fps you lerp 60 times a second; at 30fps only 30 times. The camera will feel different on different machines.

**The fix: exponential smoothing with delta.**

```tsx
// Frame-rate independent smoothing
const alpha = 1 - Math.exp(-smoothSpeed * delta)
camera.position.lerp(desiredPosition, alpha)
```

`1 - Math.exp(-speed * delta)` gives you a frame-rate independent alpha. `smoothSpeed` of 5 feels snappy, 2 feels floaty, 10 feels nearly instant.

**slerp** (spherical linear interpolation) does the same thing but for rotations (quaternions). Use it when you need to smoothly rotate the camera:

```tsx
camera.quaternion.slerp(targetQuaternion, 1 - Math.exp(-smoothSpeed * delta))
```

### Camera Collision — Preventing Wall Clipping

Without collision, your follow camera will happily pass through walls, showing the player the inside of the level geometry. Fixing this requires a raycast from the target to the desired camera position:

```tsx
import * as THREE from 'three'

function useCollisionCamera(
  target: React.RefObject<THREE.Object3D | null>,
  offset: THREE.Vector3,
  scene: THREE.Scene,
): THREE.Vector3 {
  const raycaster = useRef(new THREE.Raycaster())
  const safePosition = useRef(new THREE.Vector3())

  function getSafePosition(): THREE.Vector3 {
    if (!target.current) return safePosition.current

    const targetPos = new THREE.Vector3()
    target.current.getWorldPosition(targetPos)

    const desiredPos = targetPos.clone().add(offset)
    const direction = desiredPos.clone().sub(targetPos).normalize()
    const maxDistance = offset.length()

    // Cast a ray from the target toward where the camera wants to be
    raycaster.current.set(targetPos, direction)
    raycaster.current.far = maxDistance

    const intersections = raycaster.current.intersectObjects(scene.children, true)

    if (intersections.length > 0) {
      // Something is between the target and the camera
      // Place camera just in front of the wall
      const wallDistance = intersections[0].distance
      safePosition.current.copy(targetPos).addScaledVector(direction, wallDistance - 0.5)
    } else {
      // No obstruction — use desired position
      safePosition.current.copy(desiredPos)
    }

    return safePosition.current
  }

  return getSafePosition()
}
```

The idea: cast a ray from the player to where the camera wants to be. If the ray hits a wall, pull the camera forward to just in front of the wall. The `- 0.5` buffer prevents the camera from sitting right on the wall surface.

For production games, you'll want to add:
- Multiple rays (a cone of rays) to handle camera near corners
- A minimum camera distance so it doesn't clip inside the player model
- Smooth transition when entering/leaving collision to avoid popping

---

## 5. KeyboardControls from drei

### Declarative Input Mapping

Raw `addEventListener('keydown')` works, but drei gives you a cleaner pattern with `KeyboardControls`. You define a keymap, wrap your scene, and read input state from anywhere with a hook.

```tsx
import { KeyboardControls } from '@react-three/drei'

// Define your key mappings outside the component (or in a constants file)
const keyMap = [
  { name: 'forward', keys: ['KeyW', 'ArrowUp'] },
  { name: 'backward', keys: ['KeyS', 'ArrowDown'] },
  { name: 'left', keys: ['KeyA', 'ArrowLeft'] },
  { name: 'right', keys: ['KeyD', 'ArrowRight'] },
  { name: 'jump', keys: ['Space'] },
  { name: 'sprint', keys: ['ShiftLeft', 'ShiftRight'] },
]

// Wrap your Canvas (KeyboardControls goes OUTSIDE Canvas)
function App() {
  return (
    <KeyboardControls map={keyMap}>
      <Canvas>
        <Player />
        {/* ... */}
      </Canvas>
    </KeyboardControls>
  )
}
```

### Reading Input with useKeyboardControls

Inside any component within the `<KeyboardControls>` wrapper, you can read input state:

```tsx
import { useKeyboardControls } from '@react-three/drei'

function Player() {
  // Method 1: Subscribe to all keys (returns current state)
  const [sub, getKeys] = useKeyboardControls()

  useFrame((_, delta) => {
    const { forward, backward, left, right, jump, sprint } = getKeys()

    if (forward) {
      // Move forward
    }
    if (jump) {
      // Jump
    }
  })

  return <mesh>{/* ... */}</mesh>
}
```

Two ways to consume input:

```tsx
// Method 1: getKeys() — poll current state in useFrame (most common for movement)
const [sub, getKeys] = useKeyboardControls()
useFrame(() => {
  const { forward, jump } = getKeys()
})

// Method 2: sub() — subscribe to changes (good for discrete actions like "jump pressed")
const [sub] = useKeyboardControls()
useEffect(() => {
  return sub(
    (state) => state.jump,
    (pressed) => {
      if (pressed) console.log('Jump pressed!')
    }
  )
}, [sub])
```

### TypeScript Enum Pattern

For type safety, define your controls as an enum:

```tsx
enum Controls {
  forward = 'forward',
  backward = 'backward',
  left = 'left',
  right = 'right',
  jump = 'jump',
  sprint = 'sprint',
}

const keyMap = [
  { name: Controls.forward, keys: ['KeyW', 'ArrowUp'] },
  { name: Controls.backward, keys: ['KeyS', 'ArrowDown'] },
  { name: Controls.left, keys: ['KeyA', 'ArrowLeft'] },
  { name: Controls.right, keys: ['KeyD', 'ArrowRight'] },
  { name: Controls.jump, keys: ['Space'] },
  { name: Controls.sprint, keys: ['ShiftLeft', 'ShiftRight'] },
]

// Now the hook is typed:
const [sub, getKeys] = useKeyboardControls<Controls>()
```

### Handling Multiple Keys Simultaneously

`getKeys()` returns a snapshot of all keys at that instant. Multiple keys can be true at once — this is how you handle diagonal movement and sprinting while moving:

```tsx
useFrame((_, delta) => {
  const { forward, backward, left, right, sprint } = getKeys()

  const moveSpeed = sprint ? 10 : 5
  const direction = new THREE.Vector3()

  if (forward) direction.z -= 1
  if (backward) direction.z += 1
  if (left) direction.x -= 1
  if (right) direction.x += 1

  // Normalize to prevent faster diagonal movement
  if (direction.length() > 0) {
    direction.normalize().multiplyScalar(moveSpeed * delta)
  }

  playerRef.current!.position.add(direction)
})
```

---

## 6. Movement Patterns

### Direction Vectors from Input

Every movement system boils down to the same core loop:
1. Read input and produce a **direction vector**
2. Normalize it
3. Scale by speed and delta time
4. Apply to position (or velocity, if using physics)

```tsx
function buildDirectionVector(
  forward: boolean,
  backward: boolean,
  left: boolean,
  right: boolean,
  cameraYRotation: number
): THREE.Vector3 {
  const direction = new THREE.Vector3()

  // Raw input direction (in local space)
  if (forward) direction.z -= 1
  if (backward) direction.z += 1
  if (left) direction.x -= 1
  if (right) direction.x += 1

  if (direction.length() === 0) return direction

  // Normalize so diagonal isn't faster
  direction.normalize()

  // Rotate direction to match camera facing
  direction.applyAxisAngle(new THREE.Vector3(0, 1, 0), cameraYRotation)

  return direction
}
```

### Why Normalizing Diagonal Movement Matters

If forward is `(0, 0, -1)` and right is `(1, 0, 0)`, pressing both gives you `(1, 0, -1)`. The length of that vector is `sqrt(2)` which is approximately 1.414 — meaning you move 41% faster diagonally. Players will notice, speedrunners will exploit it, and your game will feel inconsistent.

```tsx
// Without normalization: diagonal = ~1.414 speed
const direction = new THREE.Vector3(1, 0, -1)
// direction.length() === 1.4142...

// With normalization: diagonal = 1.0 speed
direction.normalize()
// direction.length() === 1.0
// direction === approximately (0.707, 0, -0.707)
```

Always normalize before applying speed.

### Applying Movement with Delta Time

```tsx
useFrame((_, delta) => {
  const { forward, backward, left, right, sprint } = getKeys()

  const speed = sprint ? 10 : 5
  const direction = buildDirectionVector(
    forward, backward, left, right, camera.rotation.y
  )

  // Frame-rate independent movement
  playerRef.current!.position.addScaledVector(direction, speed * delta)
})
```

### Direct Position vs Physics-Based Movement

**Direct position setting** (what we've done above):
- You calculate where the character should be and set it directly
- Simple. Predictable. No momentum, no bouncing, no sliding.
- Characters walk through walls unless you add your own collision checks
- Good for: top-down games, strategy games, simple prototypes

**Physics-based movement** (covered in depth in the physics module):
- You apply forces or velocities to a physics body
- The physics engine handles collision, gravity, friction, slopes
- More realistic but harder to control — characters can feel floaty or slippery
- Good for: platformers, action games, anything with real physics

```tsx
// Direct position (this module)
playerRef.current!.position.addScaledVector(direction, speed * delta)

// Physics-based velocity (physics module)
rigidBodyRef.current!.setLinvel({
  x: direction.x * speed,
  y: rigidBodyRef.current!.linvel().y, // Preserve gravity velocity
  z: direction.z * speed,
})
```

### Grounding with Raycasts

If you're doing direct position movement (no physics engine), you need to handle ground detection yourself. Cast a ray downward from the character to find the ground:

```tsx
const raycaster = new THREE.Raycaster()
const downDirection = new THREE.Vector3(0, -1, 0)

function snapToGround(
  playerPos: THREE.Vector3,
  scene: THREE.Scene,
  playerHeight: number
) {
  raycaster.set(
    new THREE.Vector3(playerPos.x, playerPos.y + 2, playerPos.z),
    downDirection
  )
  raycaster.far = 10

  const hits = raycaster.intersectObjects(scene.children, true)

  if (hits.length > 0) {
    playerPos.y = hits[0].point.y + playerHeight / 2
  }
}
```

This casts a ray from slightly above the player straight down. If it hits ground geometry, snap the player's Y position to the hit point plus half their height. It's crude but effective for flat and gently sloped terrain.

---

## 7. ecctrl Character Controller

### What ecctrl Provides

`ecctrl` (short for "Eggshell Character Controller") is a physics-based character controller built on top of rapier and R3F. It gives you a production-ready character controller with:

- Capsule collider for the character body
- Ground detection and slope handling
- Jump with configurable height and air control
- Sprint support
- Built-in third-person camera with collision
- Smooth rotation to face movement direction
- Integration with KeyboardControls

It's the "just give me a working character controller" package. Use it when you don't want to build all the physics plumbing yourself.

### Installation

```bash
npm install ecctrl @react-three/rapier
```

### Basic Setup

```tsx
import { Canvas } from '@react-three/fiber'
import { KeyboardControls } from '@react-three/drei'
import { Physics } from '@react-three/rapier'
import Ecctrl, { EcctrlAnimation } from 'ecctrl'

const keyMap = [
  { name: 'forward', keys: ['KeyW', 'ArrowUp'] },
  { name: 'backward', keys: ['KeyS', 'ArrowDown'] },
  { name: 'leftward', keys: ['KeyA', 'ArrowLeft'] },
  { name: 'rightward', keys: ['KeyD', 'ArrowRight'] },
  { name: 'jump', keys: ['Space'] },
  { name: 'run', keys: ['ShiftLeft'] },
]

function App() {
  return (
    <KeyboardControls map={keyMap}>
      <Canvas shadows>
        <Physics>
          <Ecctrl>
            {/* Your character model goes here */}
            <mesh>
              <capsuleGeometry args={[0.3, 0.7]} />
              <meshStandardMaterial color="blue" />
            </mesh>
          </Ecctrl>

          {/* Ground */}
          <RigidBody type="fixed">
            <mesh rotation={[-Math.PI / 2, 0, 0]}>
              <planeGeometry args={[100, 100]} />
              <meshStandardMaterial color="green" />
            </mesh>
          </RigidBody>
        </Physics>
      </Canvas>
    </KeyboardControls>
  )
}
```

### Configuration Options

ecctrl accepts many props for tuning the feel:

```tsx
<Ecctrl
  camInitDis={-15}           // Initial camera distance
  camMaxDis={-20}            // Maximum camera distance
  camMinDis={-5}             // Minimum camera distance
  camInitDir={{ x: 0, y: 0 }} // Initial camera direction
  maxVelLimit={5}            // Max movement speed
  jumpVel={4}                // Jump velocity
  sprintMult={2}             // Sprint speed multiplier
  turnVelMultiplier={0.5}    // Turn speed
  turnSpeed={15}             // Character turn speed
  capsuleHalfHeight={0.35}   // Half-height of capsule collider
  capsuleRadius={0.3}        // Radius of capsule collider
  floatHeight={0.3}          // Floating height above ground
  autoBalance                // Auto-balance the character
  animated                   // Enable animation support
>
  <CharacterModel />
</Ecctrl>
```

### Integrating with Your Own Camera

If you don't want ecctrl's built-in camera and prefer your own follow camera or orbit controls, you can disable ecctrl's camera and handle it yourself:

```tsx
<Ecctrl
  camCollision={false}  // Disable camera collision
  // Access the character's rigid body via ref
>
  <CharacterModel />
</Ecctrl>

{/* Your own camera system */}
<FollowCamera target={characterRef} />
```

ecctrl is a great starting point. Many developers use it as-is for game jams, then build a custom controller when they need behavior ecctrl doesn't support. Don't feel locked in — understanding the fundamentals in this module means you can always build your own.

---

## 8. Character Animation

### Loading Animated GLTF Models

Character animations usually come as GLTF/GLB files with embedded animation clips. Mixamo (mixamo.com) is the go-to source for free character models and animations. Download a character, apply animations (idle, walk, run), and export as GLB.

Load it with `useGLTF` and extract animations with `useAnimations`:

```tsx
import { useRef } from 'react'
import { useGLTF, useAnimations } from '@react-three/drei'
import type { Group } from 'three'

function Character() {
  const groupRef = useRef<Group>(null)
  const { scene, animations } = useGLTF('/models/character.glb')
  const { actions } = useAnimations(animations, groupRef)

  return (
    <group ref={groupRef}>
      <primitive object={scene} />
    </group>
  )
}

useGLTF.preload('/models/character.glb')
```

### The useAnimations Hook

`useAnimations` returns an object with:

| Property | Type | Description |
|----------|------|-------------|
| `actions` | `Record<string, AnimationAction>` | Named animation actions from the GLTF |
| `mixer` | `AnimationMixer` | The underlying Three.js animation mixer |
| `names` | `string[]` | Array of animation clip names |
| `ref` | `RefObject` | Ref to pass to the animated group |

To play an animation:

```tsx
useEffect(() => {
  if (actions['Idle']) {
    actions['Idle'].reset().fadeIn(0.5).play()
  }
}, [actions])
```

### Playing, Stopping, and Crossfading

The key to good character animation is smooth transitions between clips. You don't just stop "Idle" and start "Walk" — you crossfade between them:

```tsx
import { useEffect, useRef } from 'react'
import { useAnimations } from '@react-three/drei'
import type { AnimationAction } from 'three'

function useCharacterAnimation(
  actions: Record<string, AnimationAction | null>,
  currentAction: string
) {
  const previousAction = useRef<string>('')

  useEffect(() => {
    const current = actions[currentAction]
    const previous = actions[previousAction.current]

    if (!current) return

    if (previous && previous !== current) {
      // Crossfade from previous to current
      previous.fadeOut(0.3)
    }

    current.reset().fadeIn(0.3).play()
    previousAction.current = currentAction

    return () => {
      current.fadeOut(0.3)
    }
  }, [currentAction, actions])
}
```

### Blending Animations Based on Movement State

The common pattern: determine the character's current state based on velocity, then play the matching animation.

```tsx
import { useState } from 'react'
import { useFrame } from '@react-three/fiber'
import { useKeyboardControls } from '@react-three/drei'

type MovementState = 'idle' | 'walk' | 'run'

function useMovementState(): MovementState {
  const [state, setState] = useState<MovementState>('idle')
  const [, getKeys] = useKeyboardControls()

  useFrame(() => {
    const { forward, backward, left, right, sprint } = getKeys()
    const isMoving = forward || backward || left || right

    const newState: MovementState = !isMoving
      ? 'idle'
      : sprint
        ? 'run'
        : 'walk'

    // Only trigger state change when it actually changes
    // (setState with same value doesn't re-render, but be explicit)
    setState((prev) => (prev !== newState ? newState : prev))
  })

  return state
}

// In your Character component:
function AnimatedCharacter() {
  const groupRef = useRef<Group>(null)
  const { scene, animations } = useGLTF('/models/character.glb')
  const { actions } = useAnimations(animations, groupRef)
  const movementState = useMovementState()

  // Map movement state to animation name
  const animationMap: Record<MovementState, string> = {
    idle: 'Idle',
    walk: 'Walk',
    run: 'Run',
  }

  useCharacterAnimation(actions, animationMap[movementState])

  return (
    <group ref={groupRef}>
      <primitive object={scene} />
    </group>
  )
}
```

### Animation Speed Matching

If your walk animation doesn't match your movement speed, the character's feet will slide. Scale the animation's `timeScale` to match:

```tsx
useFrame(() => {
  const walkAction = actions['Walk']
  if (walkAction && walkAction.isRunning()) {
    // Adjust animation speed to match actual movement speed
    const actualSpeed = velocity.length()
    const animationBaseSpeed = 3.0  // The speed the animation was designed for
    walkAction.timeScale = actualSpeed / animationBaseSpeed
  }
})
```

---

## 9. Gamepad Support

### The Gamepad API

The browser has a built-in Gamepad API. No library needed. You poll gamepad state each frame — it's not event-based like keyboard input.

```tsx
function getGamepad(): Gamepad | null {
  const gamepads = navigator.getGamepads()
  // Find the first connected gamepad
  for (const gp of gamepads) {
    if (gp && gp.connected) return gp
  }
  return null
}
```

### Standard Gamepad Layout

Most modern controllers follow the "standard" mapping:

| Index | Button |
|-------|--------|
| `buttons[0]` | A / Cross |
| `buttons[1]` | B / Circle |
| `buttons[2]` | X / Square |
| `buttons[3]` | Y / Triangle |
| `buttons[4]` | Left Bumper |
| `buttons[5]` | Right Bumper |
| `buttons[6]` | Left Trigger |
| `buttons[7]` | Right Trigger |
| `buttons[8]` | Select / Back |
| `buttons[9]` | Start |
| `buttons[10]` | Left Stick Click |
| `buttons[11]` | Right Stick Click |
| `buttons[12]` | D-pad Up |
| `buttons[13]` | D-pad Down |
| `buttons[14]` | D-pad Left |
| `buttons[15]` | D-pad Right |

| Index | Axis |
|-------|------|
| `axes[0]` | Left Stick X (-1 left, +1 right) |
| `axes[1]` | Left Stick Y (-1 up, +1 down) |
| `axes[2]` | Right Stick X |
| `axes[3]` | Right Stick Y |

### Polling in useFrame

```tsx
import { useFrame } from '@react-three/fiber'

function useGamepadInput() {
  const gamepadState = useRef({
    leftStick: { x: 0, y: 0 },
    rightStick: { x: 0, y: 0 },
    jump: false,
    sprint: false,
  })

  useFrame(() => {
    const gp = getGamepad()
    if (!gp) return

    const deadZone = 0.15

    const applyDeadZone = (value: number): number =>
      Math.abs(value) < deadZone ? 0 : value

    gamepadState.current = {
      leftStick: {
        x: applyDeadZone(gp.axes[0]),
        y: applyDeadZone(gp.axes[1]),
      },
      rightStick: {
        x: applyDeadZone(gp.axes[2]),
        y: applyDeadZone(gp.axes[3]),
      },
      jump: gp.buttons[0].pressed,       // A button
      sprint: gp.buttons[10].pressed,     // Left stick click
    }
  })

  return gamepadState
}
```

### Dead Zones

Analog sticks are never perfectly centered. Even when you're not touching them, they report tiny values like `0.003` or `-0.02`. Without a dead zone, your character will slowly drift. A dead zone of `0.15` is a safe starting point — test with your actual controller and adjust.

```tsx
// Simple dead zone: snap to zero below threshold
function applyDeadZone(value: number, threshold = 0.15): number {
  return Math.abs(value) < threshold ? 0 : value
}

// Better dead zone: remap the remaining range so you still get full 0-1 output
function applyDeadZoneSmooth(value: number, threshold = 0.15): number {
  const abs = Math.abs(value)
  if (abs < threshold) return 0
  const sign = Math.sign(value)
  return sign * ((abs - threshold) / (1 - threshold))
}
```

The smooth version prevents a sudden jump in value right at the dead zone boundary. When the stick leaves the dead zone, output starts at 0 instead of 0.15.

### Supporting Both Keyboard and Gamepad

Merge both input sources into a single direction vector:

```tsx
function useCombinedInput() {
  const [, getKeys] = useKeyboardControls()
  const gamepadState = useGamepadInput()

  function getMovementDirection(): THREE.Vector3 {
    const keys = getKeys()
    const gp = gamepadState.current
    const direction = new THREE.Vector3()

    // Keyboard input (binary: 0 or 1)
    if (keys.forward) direction.z -= 1
    if (keys.backward) direction.z += 1
    if (keys.left) direction.x -= 1
    if (keys.right) direction.x += 1

    // Gamepad input (analog: -1 to 1) — add to keyboard direction
    direction.x += gp.leftStick.x
    direction.z += gp.leftStick.y  // Note: stick Y axis is inverted vs our convention

    // Clamp so combined input doesn't exceed magnitude 1
    if (direction.length() > 1) {
      direction.normalize()
    }

    return direction
  }

  function getJump(): boolean {
    return getKeys().jump || gamepadState.current.jump
  }

  function getSprint(): boolean {
    return getKeys().sprint || gamepadState.current.sprint
  }

  return { getMovementDirection, getJump, getSprint }
}
```

The beauty of this approach: whichever input device the player uses just works. No mode switching, no "press any button to set input type" screens.

### Gamepad Connection Events

You can listen for gamepads connecting and disconnecting:

```tsx
useEffect(() => {
  const onConnect = (e: GamepadEvent) => {
    console.log(`Gamepad connected: ${e.gamepad.id}`)
  }
  const onDisconnect = (e: GamepadEvent) => {
    console.log(`Gamepad disconnected: ${e.gamepad.id}`)
  }

  window.addEventListener('gamepadconnected', onConnect)
  window.addEventListener('gamepaddisconnected', onDisconnect)

  return () => {
    window.removeEventListener('gamepadconnected', onConnect)
    window.removeEventListener('gamepaddisconnected', onDisconnect)
  }
}, [])
```

---

## 10. Camera Shake and Effects

### Camera Shake as Game Feel

Camera shake is one of the cheapest, most effective ways to add "juice" to your game. An explosion feels like an explosion when the screen shakes. A heavy landing feels heavy. A boss stomp feels threatening. Without shake, these events feel flat.

The principle: apply a small random offset to the camera's position and/or rotation each frame, decaying over time.

### Trauma-Based Shake

The best camera shake implementations use a **trauma** system. Instead of turning shake on/off, you add "trauma" and let it decay naturally:

```tsx
import { useRef } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import * as THREE from 'three'

function useCameraShake() {
  const { camera } = useThree()
  const trauma = useRef(0)
  const originalPosition = useRef(new THREE.Vector3())
  const initialized = useRef(false)

  function addTrauma(amount: number) {
    trauma.current = Math.min(1, trauma.current + amount)
  }

  useFrame((_, delta) => {
    if (!initialized.current) {
      originalPosition.current.copy(camera.position)
      initialized.current = true
    }

    if (trauma.current <= 0) return

    // Shake intensity is trauma squared (feels more natural)
    const shake = trauma.current * trauma.current
    const maxOffset = 0.3
    const maxAngle = 0.05

    // Apply random offset
    camera.position.x = originalPosition.current.x + (Math.random() * 2 - 1) * maxOffset * shake
    camera.position.y = originalPosition.current.y + (Math.random() * 2 - 1) * maxOffset * shake
    camera.rotation.z = (Math.random() * 2 - 1) * maxAngle * shake

    // Decay trauma
    trauma.current = Math.max(0, trauma.current - delta * 1.5)
  })

  return { addTrauma }
}
```

Usage:

```tsx
function Explosion({ position }: { position: [number, number, number] }) {
  const { addTrauma } = useCameraShake()

  useEffect(() => {
    addTrauma(0.6) // Big shake for an explosion
  }, [])

  return <ExplosionEffect position={position} />
}
```

Trauma values:
- `0.1–0.2` — Subtle. Footstep, small impact.
- `0.3–0.5` — Medium. Landing, gunshot, hit taken.
- `0.6–0.8` — Strong. Explosion, boss attack.
- `1.0` — Maximum. Screen-filling event.

### drei's CameraShake

drei also provides a built-in `CameraShake` component if you don't need the trauma system:

```tsx
import { CameraShake } from '@react-three/drei'

<CameraShake
  maxYaw={0.05}        // Max rotation on Y axis
  maxPitch={0.05}      // Max rotation on X axis
  maxRoll={0.05}       // Max rotation on Z axis
  yawFrequency={1}     // Oscillation frequency
  pitchFrequency={1}
  rollFrequency={1}
  intensity={0.5}      // Overall intensity (0-1)
  decayRate={0.65}     // How quickly it calms down
/>
```

### Dolly Zoom (Vertigo Effect)

The dolly zoom simultaneously moves the camera forward while increasing FOV (or vice versa). The subject stays the same size in frame, but the background dramatically expands or contracts. Hitchcock made it famous. It's great for dramatic moments.

```tsx
function useDollyZoom() {
  const { camera } = useThree()

  function dollyZoom(
    targetFov: number,
    duration: number
  ) {
    const perspCam = camera as THREE.PerspectiveCamera
    const startFov = perspCam.fov
    const startPos = camera.position.clone()

    // Calculate how much to move to keep subject the same size
    const fovScale = Math.tan((targetFov * Math.PI) / 360) /
                     Math.tan((startFov * Math.PI) / 360)

    const targetZ = startPos.z / fovScale
    let elapsed = 0

    // Return a function to call in useFrame
    return (delta: number): boolean => {
      elapsed += delta
      const t = Math.min(elapsed / duration, 1)
      const eased = t * t * (3 - 2 * t) // Smoothstep easing

      perspCam.fov = THREE.MathUtils.lerp(startFov, targetFov, eased)
      perspCam.position.z = THREE.MathUtils.lerp(startPos.z, targetZ, eased)
      perspCam.updateProjectionMatrix()

      return t >= 1 // Returns true when complete
    }
  }

  return { dollyZoom }
}
```

### Screen Transitions

For level transitions, cutscenes, or teleportation, fade the screen to black (or white) using an HTML overlay. Don't try to do this in 3D — use a CSS overlay on top of the Canvas:

```tsx
import { useState } from 'react'

function ScreenTransition({
  active,
  color = 'black',
  duration = 0.5,
}: {
  active: boolean
  color?: string
  duration?: number
}) {
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: color,
        opacity: active ? 1 : 0,
        transition: `opacity ${duration}s ease-in-out`,
        pointerEvents: 'none',
        zIndex: 1000,
      }}
    />
  )
}
```

For more complex transitions (wipes, circles, dissolves), use a shader material on a fullscreen quad rendered as a post-processing effect. That's a Module 5+ topic.

---

## Code Walkthrough: Building the Walking Character

This is the complete mini-project. You'll build a walking character with animated movement, a third-person follow camera, keyboard input, and an orbit camera fallback.

### Step 1: Project Setup

```bash
npm create vite@latest walking-character -- --template react-ts
cd walking-character
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three
```

### Step 2: Get a Character Model

Go to [Mixamo](https://www.mixamo.com/):
1. Pick any character (the Y Bot works great)
2. Download it with these animations: **Idle**, **Walking**, **Running**
3. Export each as FBX, then convert to GLB (use `gltf-transform` or the Blender GLTF exporter)
4. Place the file at `public/models/character.glb`

Alternatively, use a Kenney character from [kenney.nl/assets](https://kenney.nl/assets) — they're CC0 licensed and game-ready.

For this walkthrough, we'll assume the file has animation clips named `'Idle'`, `'Walk'`, and `'Run'`.

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

### Step 4: Key Map Constants

```tsx
// src/constants.ts
export enum Controls {
  forward = 'forward',
  backward = 'backward',
  left = 'left',
  right = 'right',
  jump = 'jump',
  sprint = 'sprint',
}

export const KEY_MAP = [
  { name: Controls.forward, keys: ['KeyW', 'ArrowUp'] },
  { name: Controls.backward, keys: ['KeyS', 'ArrowDown'] },
  { name: Controls.left, keys: ['KeyA', 'ArrowLeft'] },
  { name: Controls.right, keys: ['KeyD', 'ArrowRight'] },
  { name: Controls.jump, keys: ['Space'] },
  { name: Controls.sprint, keys: ['ShiftLeft', 'ShiftRight'] },
]
```

### Step 5: The Character Model Component

```tsx
// src/components/CharacterModel.tsx
import { useRef, useEffect, useState } from 'react'
import { useFrame } from '@react-three/fiber'
import { useGLTF, useAnimations, useKeyboardControls } from '@react-three/drei'
import * as THREE from 'three'
import type { Group } from 'three'
import { Controls } from '../constants'

type MovementState = 'idle' | 'walk' | 'run'

interface CharacterModelProps {
  /** Parent ref that this component will move */
  groupRef: React.RefObject<THREE.Group | null>
  speed?: number
  sprintMultiplier?: number
}

export function CharacterModel({
  groupRef,
  speed = 4,
  sprintMultiplier = 2,
}: CharacterModelProps) {
  const innerRef = useRef<Group>(null)
  const { scene, animations } = useGLTF('/models/character.glb')
  const { actions } = useAnimations(animations, innerRef)
  const [, getKeys] = useKeyboardControls<Controls>()

  // Movement state for animation
  const [movementState, setMovementState] = useState<MovementState>('idle')
  const previousAction = useRef<string>('Idle')

  // Rotation smoothing
  const targetRotation = useRef(0)

  // Clone the scene so multiple instances don't share state
  const clonedScene = useMemo(() => scene.clone(), [scene])

  // Handle animation transitions
  useEffect(() => {
    const animationMap: Record<MovementState, string> = {
      idle: 'Idle',
      walk: 'Walk',
      run: 'Run',
    }

    const nextActionName = animationMap[movementState]
    const nextAction = actions[nextActionName]
    const prevAction = actions[previousAction.current]

    if (!nextAction) return

    if (prevAction && prevAction !== nextAction) {
      prevAction.fadeOut(0.3)
    }

    nextAction.reset().fadeIn(0.3).play()
    previousAction.current = nextActionName
  }, [movementState, actions])

  useFrame((state, delta) => {
    if (!groupRef.current) return

    const { forward, backward, left, right, sprint } = getKeys()
    const isMoving = forward || backward || left || right

    // Update movement state
    const newState: MovementState = !isMoving
      ? 'idle'
      : sprint
        ? 'run'
        : 'walk'
    setMovementState((prev) => (prev !== newState ? newState : prev))

    if (!isMoving) return

    // Build direction vector
    const direction = new THREE.Vector3()
    if (forward) direction.z -= 1
    if (backward) direction.z += 1
    if (left) direction.x -= 1
    if (right) direction.x += 1
    direction.normalize()

    // Calculate camera-relative direction
    const cameraDirection = new THREE.Vector3()
    state.camera.getWorldDirection(cameraDirection)
    cameraDirection.y = 0
    cameraDirection.normalize()

    const cameraRight = new THREE.Vector3()
    cameraRight.crossVectors(cameraDirection, new THREE.Vector3(0, 1, 0)).normalize()

    const worldDirection = new THREE.Vector3()
    worldDirection.addScaledVector(cameraRight, direction.x)
    worldDirection.addScaledVector(cameraDirection, -direction.z)
    worldDirection.normalize()

    // Move the character
    const currentSpeed = sprint ? speed * sprintMultiplier : speed
    groupRef.current.position.addScaledVector(worldDirection, currentSpeed * delta)

    // Rotate character to face movement direction
    targetRotation.current = Math.atan2(worldDirection.x, worldDirection.z)
    const currentY = groupRef.current.rotation.y

    // Smooth rotation using lerp on the angle
    // Handle wrapping around PI/-PI
    let angleDiff = targetRotation.current - currentY
    if (angleDiff > Math.PI) angleDiff -= Math.PI * 2
    if (angleDiff < -Math.PI) angleDiff += Math.PI * 2

    groupRef.current.rotation.y += angleDiff * Math.min(1, 10 * delta)
  })

  return (
    <group ref={innerRef}>
      <primitive object={clonedScene} scale={0.01} />
    </group>
  )
}

useGLTF.preload('/models/character.glb')
```

### Step 6: The Follow Camera Component

```tsx
// src/components/FollowCamera.tsx
import { useRef } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import * as THREE from 'three'

interface FollowCameraProps {
  target: React.RefObject<THREE.Group | null>
  offset?: [number, number, number]
  lookAtHeight?: number
  smoothSpeed?: number
}

export function FollowCamera({
  target,
  offset = [0, 5, 10],
  lookAtHeight = 1.5,
  smoothSpeed = 4,
}: FollowCameraProps) {
  const { camera } = useThree()
  const desiredPosition = useRef(new THREE.Vector3())
  const currentLookAt = useRef(new THREE.Vector3())

  useFrame((_, delta) => {
    if (!target.current) return

    const targetPos = new THREE.Vector3()
    target.current.getWorldPosition(targetPos)

    // Desired camera position: offset relative to world
    // (not relative to character rotation — that feels too aggressive)
    desiredPosition.current.set(
      targetPos.x + offset[0],
      targetPos.y + offset[1],
      targetPos.z + offset[2]
    )

    // Smooth follow with frame-rate independent lerp
    const alpha = 1 - Math.exp(-smoothSpeed * delta)
    camera.position.lerp(desiredPosition.current, alpha)

    // Look at target's chest height
    const lookAtTarget = new THREE.Vector3(
      targetPos.x,
      targetPos.y + lookAtHeight,
      targetPos.z
    )
    currentLookAt.current.lerp(lookAtTarget, alpha)
    camera.lookAt(currentLookAt.current)
  })

  return null
}
```

### Step 7: Ground and Environment

```tsx
// src/components/Ground.tsx
import { useTexture } from '@react-three/drei'
import * as THREE from 'three'

export function Ground() {
  return (
    <mesh rotation={[-Math.PI / 2, 0, 0]} receiveShadow>
      <planeGeometry args={[200, 200]} />
      <meshStandardMaterial color="#3a7d44" roughness={0.9} />
    </mesh>
  )
}

// Some simple obstacles to walk around
export function Environment() {
  return (
    <group>
      {/* Trees (simple cylinders + spheres) */}
      {[
        [-5, 0, -8],
        [8, 0, -3],
        [-3, 0, 6],
        [10, 0, 10],
        [-12, 0, -2],
        [6, 0, -15],
      ].map(([x, y, z], i) => (
        <group key={i} position={[x, y, z]}>
          {/* Trunk */}
          <mesh position={[0, 1.5, 0]} castShadow>
            <cylinderGeometry args={[0.2, 0.3, 3, 8]} />
            <meshStandardMaterial color="#8B4513" roughness={0.9} />
          </mesh>
          {/* Canopy */}
          <mesh position={[0, 3.5, 0]} castShadow>
            <sphereGeometry args={[1.5, 8, 8]} />
            <meshStandardMaterial color="#228B22" roughness={0.8} />
          </mesh>
        </group>
      ))}

      {/* Rocks */}
      {[
        [3, 0.3, 5],
        [-7, 0.4, -5],
        [15, 0.5, 3],
      ].map(([x, y, z], i) => (
        <mesh key={`rock-${i}`} position={[x, y, z]} castShadow>
          <dodecahedronGeometry args={[y * 2, 0]} />
          <meshStandardMaterial color="#666" roughness={1} />
        </mesh>
      ))}
    </group>
  )
}
```

### Step 8: The Player Component (ties it all together)

```tsx
// src/components/Player.tsx
import { useRef } from 'react'
import type { Group } from 'three'
import { CharacterModel } from './CharacterModel'
import { FollowCamera } from './FollowCamera'

export function Player() {
  const groupRef = useRef<Group>(null)

  return (
    <>
      <group ref={groupRef} position={[0, 0, 0]}>
        <CharacterModel groupRef={groupRef} speed={4} sprintMultiplier={2} />
      </group>

      <FollowCamera
        target={groupRef}
        offset={[0, 5, 10]}
        lookAtHeight={1.5}
        smoothSpeed={4}
      />
    </>
  )
}
```

### Step 9: The App — Final Assembly

```tsx
// src/App.tsx
import { useState } from 'react'
import { Canvas } from '@react-three/fiber'
import { KeyboardControls, OrbitControls, Sky } from '@react-three/drei'
import { Player } from './components/Player'
import { Ground, Environment } from './components/Ground'
import { KEY_MAP } from './constants'

export default function App() {
  const [devCamera, setDevCamera] = useState(false)

  return (
    <>
      {/* Toggle dev camera with backtick key */}
      <div
        style={{
          position: 'fixed',
          top: 10,
          left: 10,
          zIndex: 100,
          color: 'white',
          fontFamily: 'monospace',
          fontSize: 12,
          opacity: 0.5,
        }}
      >
        Press ` to toggle orbit camera | WASD to move | Shift to sprint
      </div>

      <KeyboardControls map={KEY_MAP}>
        <Canvas
          shadows
          camera={{ position: [0, 5, 10], fov: 60 }}
          onKeyDown={(e) => {
            if (e.code === 'Backquote') setDevCamera((prev) => !prev)
          }}
        >
          {/* Lighting */}
          <ambientLight intensity={0.4} />
          <directionalLight
            position={[10, 15, 10]}
            intensity={1.5}
            castShadow
            shadow-mapSize-width={2048}
            shadow-mapSize-height={2048}
            shadow-camera-far={50}
            shadow-camera-left={-20}
            shadow-camera-right={20}
            shadow-camera-top={20}
            shadow-camera-bottom={-20}
          />

          {/* Sky */}
          <Sky sunPosition={[100, 50, 100]} />

          {/* World */}
          <Ground />
          <Environment />

          {/* Player with follow camera */}
          <Player />

          {/* Dev orbit camera override */}
          {devCamera && (
            <OrbitControls
              enableDamping
              dampingFactor={0.05}
              minDistance={3}
              maxDistance={50}
            />
          )}
        </Canvas>
      </KeyboardControls>
    </>
  )
}
```

### Step 10: Entry Point

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

You should see a green field with trees and rocks. Your character stands at the origin. Press W/A/S/D to move, Shift to sprint. The character model animates between idle, walk, and run. The camera smoothly follows from behind. Press backtick (`) to toggle free orbit camera for inspecting the scene.

If you don't have a character model yet, swap `<CharacterModel>` for a simple capsule mesh and focus on getting the movement and camera working first. The animation layer can come after.

---

## API Quick Reference

### Camera Components (drei)

| Component | Description | Example |
|-----------|-------------|---------|
| `<PerspectiveCamera>` | Standard perspective camera | `<PerspectiveCamera makeDefault fov={60} />` |
| `<OrthographicCamera>` | No-perspective camera | `<OrthographicCamera makeDefault zoom={50} />` |
| `<CameraShake>` | Adds procedural shake | `<CameraShake intensity={0.5} />` |

### Camera Controls (drei)

| Component | Description | Example |
|-----------|-------------|---------|
| `<OrbitControls>` | Orbit around a target | `<OrbitControls enableDamping target={[0,1,0]} />` |
| `<PointerLockControls>` | FPS mouselook | `<PointerLockControls />` |
| `<MapControls>` | Pan-focused (strategy games) | `<MapControls />` |
| `<FlyControls>` | Free-fly (editor/debug) | `<FlyControls movementSpeed={10} />` |

### Input (drei)

| Component/Hook | Description | Example |
|----------------|-------------|---------|
| `<KeyboardControls>` | Provider for keyboard input | `<KeyboardControls map={keyMap}>` |
| `useKeyboardControls()` | Read keyboard state | `const [sub, get] = useKeyboardControls()` |

### Animation (drei)

| Hook | Description | Example |
|------|-------------|---------|
| `useAnimations(clips, ref)` | Set up animation actions from GLTF clips | `const { actions } = useAnimations(anims, ref)` |
| `useGLTF(url)` | Load GLTF/GLB with animations | `const { scene, animations } = useGLTF(url)` |

### Three.js Math Utilities

| Function | Description | Example |
|----------|-------------|---------|
| `THREE.MathUtils.lerp(a, b, t)` | Linear interpolation (numbers) | `lerp(0, 10, 0.5) // 5` |
| `Vector3.lerp(target, alpha)` | Lerp a vector toward target | `pos.lerp(desired, 0.1)` |
| `Quaternion.slerp(target, alpha)` | Spherical lerp for rotations | `quat.slerp(targetQuat, 0.1)` |
| `Vector3.normalize()` | Scale vector to length 1 | `direction.normalize()` |
| `Vector3.addScaledVector(v, s)` | Add `v * s` to this vector | `pos.addScaledVector(dir, speed * dt)` |
| `Vector3.applyQuaternion(q)` | Rotate vector by quaternion | `offset.applyQuaternion(playerQuat)` |
| `camera.getWorldDirection(v)` | Get camera's forward vector | `camera.getWorldDirection(fwd)` |

### Gamepad API

| API | Description |
|-----|-------------|
| `navigator.getGamepads()` | Returns array of connected gamepads |
| `gamepad.axes[0..3]` | Analog stick values (-1 to 1) |
| `gamepad.buttons[n].pressed` | Whether button n is pressed |
| `gamepad.buttons[n].value` | Analog button value (triggers) |
| `'gamepadconnected'` event | Fires when gamepad connects |
| `'gamepaddisconnected'` event | Fires when gamepad disconnects |

---

## Common Pitfalls

### 1. Camera Jitter from Update Order

If you update the camera position before the physics/movement update, the camera follows one frame behind and jitters. The fix: make sure camera follow runs *after* movement.

```tsx
// WRONG — camera follows runs at default priority (0), same as movement
// Order is undefined — sometimes camera reads stale position
function FollowCamera({ target }) {
  useFrame(() => {
    camera.position.copy(target.current.position).add(offset)
  })
  return null
}

function Player() {
  useFrame((_, delta) => {
    meshRef.current.position.x += speed * delta
  })
  return <mesh ref={meshRef} />
}

// RIGHT — use useFrame's priority parameter to control execution order
// Lower numbers run first. Movement at 0, camera at 1.
function FollowCamera({ target }) {
  useFrame(() => {
    camera.position.copy(target.current.position).add(offset)
  }, 1)  // Priority 1: runs AFTER default (0)
  return null
}

function Player() {
  useFrame((_, delta) => {
    meshRef.current.position.x += speed * delta
  }, 0)  // Priority 0 (default): runs first
  return <mesh ref={meshRef} />
}
```

### 2. Not Normalizing Diagonal Movement

Pressing W+D simultaneously makes the character move forward AND right. The combined vector has length ~1.414, meaning the character moves 41% faster diagonally. Players will exploit this.

```tsx
// WRONG — diagonal movement is faster
const direction = new THREE.Vector3()
if (forward) direction.z -= 1
if (right) direction.x += 1
// direction.length() is ~1.414 when both are pressed!
playerRef.current!.position.addScaledVector(direction, speed * delta)

// RIGHT — normalize before applying speed
const direction = new THREE.Vector3()
if (forward) direction.z -= 1
if (right) direction.x += 1
if (direction.length() > 0) {
  direction.normalize()  // Now length is always exactly 1
}
playerRef.current!.position.addScaledVector(direction, speed * delta)
```

### 3. Forgetting to Lock Pointer for FPS Controls

`PointerLockControls` won't do anything until the user clicks to lock the pointer. If you just drop it in and expect mouselook to work immediately, nothing will happen. The user must click first.

```tsx
// WRONG — no indication to the user that they need to click
<Canvas>
  <PointerLockControls />
  <FPSMovement />
</Canvas>
// User loads page, moves mouse, nothing happens. Confused.

// RIGHT — show a clear prompt, handle the lock/unlock states
function FPSScene() {
  const [locked, setLocked] = useState(false)

  return (
    <>
      {!locked && (
        <div style={{
          position: 'fixed', inset: 0, display: 'flex',
          alignItems: 'center', justifyContent: 'center',
          background: 'rgba(0,0,0,0.7)', color: 'white',
          fontSize: 24, zIndex: 100, cursor: 'pointer',
        }}>
          Click to play
        </div>
      )}
      <Canvas>
        <PointerLockControls
          onLock={() => setLocked(true)}
          onUnlock={() => setLocked(false)}
        />
        {locked && <FPSMovement />}
      </Canvas>
    </>
  )
}
```

### 4. Animation Not Transitioning Smoothly

If you just `.stop()` one animation and `.play()` another, you get a hard pop between poses. Use `crossFadeTo` or the `fadeIn`/`fadeOut` pattern.

```tsx
// WRONG — hard cut between animations, looks terrible
useEffect(() => {
  if (movementState === 'walk') {
    actions['Idle']?.stop()
    actions['Walk']?.play()
  }
}, [movementState])

// RIGHT — crossfade for smooth blending
useEffect(() => {
  const next = actions[animationMap[movementState]]
  const prev = actions[previousAction.current]

  if (!next) return

  if (prev && prev !== next) {
    prev.fadeOut(0.3)
  }

  next.reset().fadeIn(0.3).play()
  previousAction.current = animationMap[movementState]
}, [movementState])
```

The `fadeIn` / `fadeOut` duration (0.3 seconds here) controls how long the blend takes. Shorter = snappier, longer = smoother. 0.2–0.4 is the sweet spot for most movement transitions.

### 5. Gamepad Dead Zone Too Small (Drift)

Analog sticks are never perfectly centered at rest. A dead zone of `0` will cause constant unwanted movement.

```tsx
// WRONG — no dead zone, character slowly drifts even when stick is untouched
const moveX = gamepad.axes[0]  // Might be 0.003 at rest

// WRONG — dead zone too small, still drifts on worn controllers
const deadZone = 0.02
const moveX = Math.abs(gamepad.axes[0]) > deadZone ? gamepad.axes[0] : 0

// RIGHT — reasonable dead zone with smooth remapping
const DEAD_ZONE = 0.15
function applyDeadZone(value: number): number {
  const abs = Math.abs(value)
  if (abs < DEAD_ZONE) return 0
  const sign = Math.sign(value)
  return sign * ((abs - DEAD_ZONE) / (1 - DEAD_ZONE))
}
const moveX = applyDeadZone(gamepad.axes[0])
```

---

## Exercises

### Exercise 1: First-Person Mouselook Camera with WASD

**Time:** 30–45 minutes

Build a first-person camera scene. Use `PointerLockControls` for mouselook and implement WASD movement relative to the camera direction. Create a simple room with colored walls so you can verify that movement feels correct.

Requirements:
- Pointer lock with a "Click to play" overlay
- WASD moves relative to where you're looking
- Movement is normalized (no faster diagonals)
- Movement is frame-rate independent (multiply by delta)
- Shift to sprint (2x speed)
- A simple enclosed environment to walk around in

Hints:
- Use `camera.getWorldDirection()` to get the forward vector
- Zero out the Y component of the forward vector so you don't fly up/down while looking up/down
- Use `crossVectors(forward, upVector)` to get the right vector

**Stretch goal:** Add a head bob effect — gently oscillate the camera's Y position with a sine wave while moving. Scale the bob intensity with movement speed.

### Exercise 2: Third-Person Camera Following a Moving Cube

**Time:** 30–45 minutes

Create a cube that moves with WASD input and a third-person camera that smoothly follows it. No character model needed — just a cube is fine. Focus on getting the camera feel right.

Requirements:
- Cube moves on a flat plane with WASD
- Camera follows from behind and above
- Camera uses lerp smoothing (not instant following)
- Cube rotates to face movement direction
- Adjust the `smoothSpeed` parameter and observe how it changes the feel

Hints:
- Start with `smoothSpeed = 3` and experiment up/down
- Use `Math.atan2(direction.x, direction.z)` to get the rotation angle from the movement direction
- Smooth the cube's rotation too, not just the camera

**Stretch goal:** Make the camera offset rotate with the character so it's always directly behind them, not just at a fixed world-space offset. Use `applyQuaternion` to rotate the offset by the character's rotation.

### Exercise 3: Gamepad Support

**Time:** 30–45 minutes

Add gamepad support to either Exercise 1 or Exercise 2. The left stick should control movement, the right stick should control camera rotation (for third-person) or look direction (for first-person).

Requirements:
- Poll gamepad state in `useFrame`
- Apply a dead zone of 0.15 with smooth remapping
- Left stick = movement
- Right stick = camera
- A button = jump (or any action)
- Both keyboard and gamepad work simultaneously

Hints:
- `navigator.getGamepads()` returns the current state — call it every frame
- Analog sticks give you -1 to +1 values, which you can use directly as direction input (already normalized within the circle)
- For the right stick camera, apply the X axis to the camera's horizontal orbit angle and the Y axis to the vertical angle

**Stretch goal:** Add gamepad rumble/vibration on landing or collision using `gamepad.vibrationActuator.playEffect()`.

### Exercise 4 (Stretch): Camera Collision with Raycast

**Time:** 45–60 minutes

Take the third-person camera from Exercise 2 and add wall collision. Place walls and obstacles in the scene. The camera should pull forward when it would clip through geometry.

Requirements:
- Cast a ray from the player to the desired camera position
- If the ray hits a wall, place the camera in front of the wall
- Add a small buffer (0.3–0.5 units) so the camera doesn't sit right on the wall
- Smooth the transition when entering/leaving collision (don't pop)

Hints:
- `THREE.Raycaster.set(origin, direction)` then `raycaster.intersectObjects()`
- Only test against static world geometry, not the player model itself
- Lerp the camera to the collision-adjusted position rather than snapping — this prevents jarring pops when the camera enters/exits collision zones

**Stretch goal:** Use multiple rays in a small cone pattern to handle corner cases where a single ray misses narrow geometry.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [drei Camera Controls docs](https://drei.docs.pmnd.rs/) | Official Docs | Full API reference for OrbitControls, PointerLockControls, and every other camera helper. |
| [Three.js Camera docs](https://threejs.org/docs/#api/en/cameras/PerspectiveCamera) | Official Docs | Understand the raw Camera API that R3F wraps. |
| [ecctrl GitHub](https://github.com/pmndrs/ecctrl) | Library | Complete character controller with demos. Read the README and study the examples. |
| [Mixamo](https://www.mixamo.com/) | Asset Source | Free character models and animations. Essential for prototyping animated characters. |
| [GDC: Math for Game Programmers: Juicing Your Cameras](https://www.youtube.com/watch?v=tu-Qe66AvtY) | Talk | The definitive talk on camera shake, trauma systems, and camera feel. |
| [The Art of Screenshake (Jan Willem Nijman)](https://www.youtube.com/watch?v=AJdEqssNZ-U) | Talk | Vlambeer's legendary talk on game feel — camera shake is a key ingredient. |
| [MDN Gamepad API](https://developer.mozilla.org/en-US/docs/Web/API/Gamepad_API) | Reference | Browser gamepad API documentation with examples. |
| [Three.js Journey: Camera chapter](https://threejs-journey.com/) | Course | Bruno Simon's detailed walkthrough of Three.js camera systems. |

---

## Key Takeaways

1. **A camera is just a scene graph object.** It has position, rotation, and a parent. You can attach it to groups, move it with refs in `useFrame`, and compose camera systems from the same patterns you use for any other 3D object.

2. **Use `useFrame` priority to control update order.** Movement runs at priority 0, camera follows at priority 1. This prevents the one-frame-behind jitter that plagues naively implemented follow cameras.

3. **Always use frame-rate independent smoothing.** `1 - Math.exp(-speed * delta)` as a lerp alpha gives consistent camera and movement feel across 30fps, 60fps, and 144fps. Never use a fixed alpha like `0.1`.

4. **Normalize your direction vectors.** Diagonal movement without normalization is 41% faster. Players will notice, speedrunners will abuse it, and your game will feel wrong.

5. **KeyboardControls + useKeyboardControls is the cleanest input pattern.** Declarative key mapping, polled with `getKeys()` in `useFrame` for movement, subscribed with `sub()` for discrete actions. Works for any keyboard-driven game.

6. **CrossFade animations, never hard-switch.** `fadeOut(0.3)` on the old clip + `fadeIn(0.3).play()` on the new clip gives smooth, professional-feeling transitions between idle, walk, and run.

7. **Support multiple input devices from the start.** Merge keyboard and gamepad into a single direction vector. Whichever device the player uses just works — no mode switching needed.

---

## What's Next?

You have a character that moves, animates, and has a camera following it. But the character walks through everything — walls, trees, rocks, the ground. It's a ghost.

**[Module 4: Physics with Rapier](module-04-physics-rapier.md)** introduces rigid bodies, colliders, forces, and the physics simulation loop. You'll give your character a real physical body, add gravity, make them collide with the world, and build interactive physics objects. Movement will go from "set position directly" to "apply forces and let physics handle the rest." This is where your game world starts feeling solid.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)