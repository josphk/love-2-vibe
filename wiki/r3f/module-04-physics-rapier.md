# Module 4: Physics with Rapier

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 5-8 hours
**Prerequisites:** [Module 3: Cameras, Input & Character Control](module-03-cameras-input-character.md)

---

## Overview

You're about to give your 3D world something it's been missing: consequences. Objects that fall, collide, bounce, topple, and chain-react. Without physics, your objects are ghosts floating in a void. With physics, a ball rolling off a table hits the floor, a stack of boxes collapses when you slam something into it, and a domino taps the next one in line until the whole row is down.

This module covers physics simulation using Rapier, a Rust-based physics engine compiled to WebAssembly, via `@react-three/rapier` -- the React bindings that make it feel as natural as the rest of your R3F scene. You'll learn rigid body types, collider shapes, forces, collision events, sensors, joints, raycasting, and performance tuning. Every concept builds toward the mini-project: a Rube Goldberg machine where dominoes fall, a ball rolls down a ramp, a seesaw launches, and a sensor trigger declares victory.

Collision detection is one of the hardest problems in game development. Doing it yourself means solving continuous swept volumes, manifold generation, contact point resolution, and numerical stability -- all at 60fps. Don't do it yourself. That's what physics engines are for. Rapier handles all of this, and `@react-three/rapier` lets you declare it in JSX. You set up the bodies, define the shapes, and the engine does the math.

By the end of this module, you'll have physics intuition: when to use dynamic vs kinematic bodies, which collider shape fits your use case, how to apply forces without things exploding, and how to keep the simulation performant. You'll also have a Rube Goldberg machine that's deeply satisfying to watch.

---

## 1. Why Rapier

### The Problem Physics Engines Solve

Collision detection is deceptively hard. Detecting whether two boxes overlap is straightforward. Detecting whether two arbitrary meshes with thousands of triangles overlap, at what exact point, along what contact normal, and resolving the collision so objects don't pass through each other or jitter -- that's a research-grade problem. And you need to solve it for every pair of objects, every frame, in under 16 milliseconds.

Physics engines give you:
- **Broad-phase collision detection** -- quickly ruling out pairs of objects that can't possibly be touching
- **Narrow-phase collision detection** -- precise contact point and normal computation for nearby pairs
- **Constraint solving** -- resolving overlaps, applying friction, stacking objects stably
- **Continuous collision detection** -- preventing fast-moving objects from tunneling through thin walls
- **Joints and motors** -- connecting bodies with hinges, sliders, ropes, and motorized constraints

### Rapier vs Cannon vs Ammo

Three physics engines have significant mindshare in the JavaScript/WebGL ecosystem:

| Engine | Language | Binding | Strengths | Weaknesses |
|--------|----------|---------|-----------|------------|
| **Rapier** | Rust -> WASM | `@react-three/rapier` | Fastest, deterministic, active development, excellent API | Newer, smaller community than Cannon |
| **Cannon** | JavaScript | `@react-three/cannon` | Mature, well-documented, pure JS | Slower, original author stopped maintaining, no WASM |
| **Ammo** | C++ -> WASM | `enable3d`, manual | Port of Bullet Physics, battle-tested in AAA games | Terrible JavaScript API, no React bindings, painful to use |

**Rapier wins.** Here's why:

- **Speed.** Rapier is written in Rust and compiled to WASM. It runs 2-5x faster than Cannon for equivalent scenes. When you have 200 physics bodies, this matters.
- **Determinism.** Given the same inputs, Rapier produces the exact same outputs every time, on every platform. This is critical for replays, netcode, and debugging.
- **Active development.** Rapier is actively maintained with regular releases. Cannon-es (the maintained Cannon fork) gets sporadic updates.
- **React bindings.** `@react-three/rapier` is built and maintained by the Poimandres collective -- the same people behind R3F and drei. It's a first-class citizen in the ecosystem.

### @react-three/rapier

`@react-three/rapier` is the declarative React wrapper around Rapier. Instead of imperatively creating bodies and colliders, you wrap your meshes in `<RigidBody>` components and the library handles synchronization between the physics world and your Three.js scene.

```tsx
// Without @react-three/rapier (imperative, painful):
const world = new RAPIER.World({ x: 0, y: -9.81, z: 0 })
const bodyDesc = RAPIER.RigidBodyDesc.dynamic().setTranslation(0, 5, 0)
const body = world.createRigidBody(bodyDesc)
const colliderDesc = RAPIER.ColliderDesc.cuboid(0.5, 0.5, 0.5)
world.createCollider(colliderDesc, body)
// Then manually sync position to your mesh every frame...

// With @react-three/rapier (declarative, nice):
<RigidBody position={[0, 5, 0]}>
  <mesh>
    <boxGeometry />
    <meshStandardMaterial />
  </mesh>
</RigidBody>
```

The library synchronizes physics body positions to your mesh transforms every frame. You declare intent, it handles the plumbing.

---

## 2. Setup

### Installation

```bash
npm install @react-three/rapier
```

That's it. Rapier's WASM binary is bundled with the package -- no separate downloads, no CDN scripts, no build config.

### Wrapping Your Scene in Physics

Every physics-enabled scene needs a `<Physics>` provider. It initializes the Rapier world and runs the simulation.

```tsx
import { Canvas } from '@react-three/fiber'
import { Physics } from '@react-three/rapier'

export default function App() {
  return (
    <Canvas camera={{ position: [0, 5, 10], fov: 60 }}>
      <ambientLight intensity={0.5} />
      <directionalLight position={[5, 10, 5]} intensity={1} />

      <Physics>
        {/* All physics bodies go inside here */}
      </Physics>
    </Canvas>
  )
}
```

`<Physics>` must be inside `<Canvas>`. Everything that participates in the physics simulation must be a descendant of `<Physics>`.

### Gravity

By default, gravity is `[0, -9.81, 0]` -- standard Earth gravity in meters per second squared, pulling downward on the Y axis. You can change it:

```tsx
// Moon gravity
<Physics gravity={[0, -1.62, 0]}>

// Zero gravity (space)
<Physics gravity={[0, 0, 0]}>

// Sideways gravity (weird, but legal)
<Physics gravity={[5, 0, 0]}>
```

### Debug Mode

The single most useful feature during development. `debug` renders wireframe outlines of all collider shapes, so you can see exactly what the physics engine thinks your objects look like.

```tsx
<Physics debug>
  {/* Your physics bodies */}
</Physics>
```

The debug wireframes are color-coded:
- **Green** -- active dynamic bodies
- **Blue** -- sleeping dynamic bodies
- **Gray/dark** -- static bodies
- **Translucent** -- sensor colliders

Turn this on immediately. Leave it on until your physics feel right. Then toggle it off.

### Timestep Configuration

The physics engine steps forward in fixed increments, independent of your rendering frame rate. This is important for determinism and stability.

```tsx
// Default: fixed timestep at 60Hz (1/60 second per step)
<Physics timeStep={1 / 60}>

// Higher frequency for more precision (more expensive)
<Physics timeStep={1 / 120}>

// Variable timestep (matches frame rate -- less stable, not recommended for most games)
<Physics timeStep="vary">
```

Stick with the default `1/60` unless you have a specific reason to change it. If your game runs at 144fps, the physics still steps at 60Hz and interpolates between steps for smooth rendering.

---

## 3. RigidBody Types

### The Four Types

Every physics body has a type that determines how it interacts with the simulation. This is the most fundamental decision you make for each object.

#### Dynamic -- Affected by Everything

Dynamic bodies are fully simulated. Gravity pulls them down, forces push them around, collisions bounce them off other objects. This is your default for anything that should "feel physical."

```tsx
import { RigidBody } from '@react-three/rapier'

function FallingBox() {
  return (
    <RigidBody type="dynamic" position={[0, 5, 0]}>
      <mesh>
        <boxGeometry />
        <meshStandardMaterial color="orange" />
      </mesh>
    </RigidBody>
  )
}
```

Drop this in a scene with a ground plane and it falls, hits the ground, and bounces. Dynamic is the default type -- you can omit `type="dynamic"`.

Use dynamic for: **crates, balls, ragdolls, debris, dominoes, anything that should react to physics.**

#### Fixed -- Immovable

Fixed bodies don't move. Ever. Forces, gravity, collisions -- nothing affects them. Other objects collide against them, but they don't budge.

```tsx
function Ground() {
  return (
    <RigidBody type="fixed">
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0, 0]}>
        <planeGeometry args={[50, 50]} />
        <meshStandardMaterial color="#556644" />
      </mesh>
    </RigidBody>
  )
}
```

Use fixed for: **ground, walls, platforms, ramps, environmental obstacles -- anything that shouldn't move.**

#### KinematicPosition -- Scripted Movement by Position

Kinematic position bodies are controlled by you. You set their position directly each frame, and the physics engine computes the velocity needed to move them there. They affect dynamic bodies (pushing them around), but dynamic bodies don't affect them back.

```tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { RigidBody } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'

function MovingPlatform() {
  const bodyRef = useRef<RapierRigidBody>(null)

  useFrame((state) => {
    if (!bodyRef.current) return

    const t = state.clock.elapsedTime
    bodyRef.current.setNextKinematicTranslation({
      x: Math.sin(t) * 3,
      y: 0.5,
      z: 0,
    })
  })

  return (
    <RigidBody ref={bodyRef} type="kinematicPosition">
      <mesh>
        <boxGeometry args={[3, 0.3, 2]} />
        <meshStandardMaterial color="#4488cc" />
      </mesh>
    </RigidBody>
  )
}
```

The key method is `setNextKinematicTranslation`. You tell it where you want the body to be next frame, and Rapier figures out the physics-correct way to get it there, properly pushing any dynamic bodies in its path.

Use kinematic position for: **moving platforms, elevators, doors, scripted obstacles -- anything with a predictable path.**

#### KinematicVelocity -- Scripted Movement by Velocity

Like kinematic position, but instead of setting a target position, you set a velocity. The engine moves the body at that velocity. This is useful when you want constant-speed movement without computing positions yourself.

```tsx
function ConveyorBelt() {
  const bodyRef = useRef<RapierRigidBody>(null)

  useFrame(() => {
    if (!bodyRef.current) return
    bodyRef.current.setNextKinematicRotation({
      x: 0,
      y: 0,
      z: 0,
      w: 1,
    })
    bodyRef.current.setLinvel({ x: 2, y: 0, z: 0 }, true)
  })

  return (
    <RigidBody ref={bodyRef} type="kinematicVelocity">
      <mesh>
        <boxGeometry args={[6, 0.2, 2]} />
        <meshStandardMaterial color="#888888" />
      </mesh>
    </RigidBody>
  )
}
```

Use kinematic velocity for: **conveyor belts, fans, constant-push zones -- anything defined by a velocity rather than a destination.**

### Quick Reference

| Type | Affected by gravity? | Affected by forces? | Moves other bodies? | You control it? |
|------|---------------------|--------------------|--------------------|----------------|
| `dynamic` | Yes | Yes | Yes | No (physics drives it) |
| `fixed` | No | No | Yes (immovable wall) | No |
| `kinematicPosition` | No | No | Yes | Yes (set position) |
| `kinematicVelocity` | No | No | Yes | Yes (set velocity) |

---

## 4. Collider Shapes

### Auto-Colliders

The simplest approach: let `@react-three/rapier` generate colliders automatically from your mesh geometry. By default, `<RigidBody>` creates a `cuboid` (box) collider that matches the bounding box of its children.

```tsx
// Auto-collider: cuboid wrapping the sphere mesh
<RigidBody>
  <mesh>
    <sphereGeometry args={[1, 32, 32]} />
    <meshStandardMaterial color="red" />
  </mesh>
</RigidBody>
```

You can change the auto-collider shape with the `colliders` prop:

```tsx
// Auto-generate a ball collider instead
<RigidBody colliders="ball">
  <mesh>
    <sphereGeometry args={[1, 32, 32]} />
    <meshStandardMaterial color="red" />
  </mesh>
</RigidBody>

// Auto-generate a hull collider
<RigidBody colliders="hull">
  <mesh>
    <torusGeometry args={[1, 0.3, 16, 48]} />
    <meshStandardMaterial color="gold" />
  </mesh>
</RigidBody>

// Disable auto-colliders (you'll add explicit ones)
<RigidBody colliders={false}>
  {/* ... */}
</RigidBody>
```

Auto-collider options: `"cuboid"` (default), `"ball"`, `"hull"`, `"trimesh"`, `false`.

### Explicit Collider Shapes

For precise control, disable auto-colliders and add explicit `<CuboidCollider>`, `<BallCollider>`, etc. as children:

```tsx
import { RigidBody, CuboidCollider, BallCollider } from '@react-three/rapier'
```

#### Cuboid (Box)

```tsx
// args = [halfWidth, halfHeight, halfDepth]
// A cuboid with args={[1, 0.5, 1]} is 2 units wide, 1 unit tall, 2 units deep
<RigidBody colliders={false}>
  <CuboidCollider args={[1, 0.5, 1]} position={[0, 0, 0]} />
  <mesh>
    <boxGeometry args={[2, 1, 2]} />
    <meshStandardMaterial color="orange" />
  </mesh>
</RigidBody>
```

**Important:** Cuboid args are **half-extents**, not full dimensions. A `<boxGeometry args={[2, 1, 2]}>` needs a `<CuboidCollider args={[1, 0.5, 1]}>`. This trips up everyone the first time.

#### Ball (Sphere)

```tsx
// args = [radius]
<RigidBody colliders={false}>
  <BallCollider args={[0.5]} />
  <mesh>
    <sphereGeometry args={[0.5, 32, 32]} />
    <meshStandardMaterial color="blue" />
  </mesh>
</RigidBody>
```

#### Capsule

```tsx
import { CapsuleCollider } from '@react-three/rapier'

// args = [halfHeight, radius]
// Total height = 2 * halfHeight + 2 * radius
<RigidBody colliders={false}>
  <CapsuleCollider args={[0.5, 0.3]} />
  <mesh>
    <capsuleGeometry args={[0.3, 1, 16, 32]} />
    <meshStandardMaterial color="green" />
  </mesh>
</RigidBody>
```

Capsules are the go-to shape for characters. They slide smoothly along surfaces and don't snag on edges like boxes do.

#### TrimeshCollider (Triangle Mesh)

```tsx
import { TrimeshCollider } from '@react-three/rapier'

// Matches exact triangle geometry -- STATIC BODIES ONLY
<RigidBody type="fixed" colliders="trimesh">
  <mesh>
    <torusKnotGeometry args={[1, 0.3, 128, 32]} />
    <meshStandardMaterial color="purple" />
  </mesh>
</RigidBody>
```

Trimesh creates a collider from every triangle in your mesh. Pixel-perfect collision. But it comes with a hard constraint: **trimesh colliders only work on fixed (static) bodies.** The physics engine can't compute stable dynamic collision response for arbitrary triangle soups. If you need a complex shape on a dynamic body, use convex hull.

#### ConvexHull

```tsx
// Wraps the mesh in the tightest convex shape that contains all vertices
<RigidBody colliders="hull">
  <mesh>
    <torusGeometry args={[1, 0.3, 16, 48]} />
    <meshStandardMaterial color="gold" />
  </mesh>
</RigidBody>
```

A convex hull is like shrink-wrapping your object. It doesn't capture concavities (holes, indentations), but it works on dynamic bodies and is much cheaper than trimesh.

#### Heightfield

```tsx
import { HeightfieldCollider } from '@react-three/rapier'

// For terrain -- a grid of height values
// args = [rows, cols, heightData, scale]
<RigidBody type="fixed" colliders={false}>
  <HeightfieldCollider
    args={[
      10,                    // number of rows
      10,                    // number of columns
      new Float32Array(121), // height values (rows+1)*(cols+1)
      { x: 20, y: 1, z: 20 } // scale
    ]}
  />
</RigidBody>
```

Heightfields are optimized for terrain. They use far less memory than a trimesh of the same resolution.

### Performance Characteristics

| Shape | Speed | Dynamic? | Accuracy |
|-------|-------|----------|----------|
| Cuboid | Fastest | Yes | Box approximation |
| Ball | Fastest | Yes | Sphere approximation |
| Capsule | Very fast | Yes | Great for characters |
| ConvexHull | Fast | Yes | Tight convex wrap |
| Trimesh | Moderate | **Static only** | Pixel-perfect |
| Heightfield | Fast | **Static only** | Good for terrain |

### When to Use Trimesh vs ConvexHull

**Use trimesh** when you have a static environment piece with concavities that matter for gameplay -- a tunnel, a cave, a hollowed-out building, level geometry with overhangs. The collider matches the mesh exactly.

**Use convex hull** when you have a dynamic object with a non-primitive shape -- a chair, a barrel, a weapon pickup. The hull approximation is close enough, and it actually works with the physics simulation.

**Compound colliders** are the middle ground. If your dynamic object is complex (like an L-shaped piece), compose it from multiple primitive colliders:

```tsx
<RigidBody colliders={false}>
  {/* L-shape from two cuboids */}
  <CuboidCollider args={[1, 0.25, 0.25]} position={[0, 0, 0]} />
  <CuboidCollider args={[0.25, 1, 0.25]} position={[-0.75, 1.25, 0]} />
  <mesh>{/* Your L-shaped visual mesh */}</mesh>
</RigidBody>
```

---

## 5. Forces, Impulses, and Velocity

### The Physics API via Refs

To push, pull, spin, or launch physics bodies, you need a ref to the `RigidBody`. This gives you access to the Rapier rigid body API.

```tsx
import { useRef } from 'react'
import { RigidBody } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'

function LaunchableBox() {
  const bodyRef = useRef<RapierRigidBody>(null)

  const launch = () => {
    if (!bodyRef.current) return
    bodyRef.current.applyImpulse({ x: 0, y: 10, z: 0 }, true)
  }

  return (
    <RigidBody ref={bodyRef} position={[0, 1, 0]}>
      <mesh onClick={launch}>
        <boxGeometry />
        <meshStandardMaterial color="tomato" />
      </mesh>
    </RigidBody>
  )
}
```

### Forces vs Impulses

This distinction matters. Get it wrong and your objects either barely move or rocket into space.

**Force** -- applied continuously over time. Like a rocket engine. The effect accumulates frame by frame. The longer you apply it, the faster the object goes.

```tsx
// Apply a continuous upward force (call every frame for effect)
bodyRef.current.addForce({ x: 0, y: 50, z: 0 }, true)
```

**Impulse** -- applied instantly, once. Like hitting something with a bat. Immediately changes velocity. Apply it once, not every frame.

```tsx
// Apply a one-time upward impulse (call once on an event)
bodyRef.current.applyImpulse({ x: 0, y: 10, z: 0 }, true)
```

**Torque** -- rotational force (continuous).

```tsx
bodyRef.current.addTorque({ x: 0, y: 5, z: 0 }, true)
```

**Torque impulse** -- rotational impulse (instantaneous).

```tsx
bodyRef.current.applyTorqueImpulse({ x: 0, y: 2, z: 0 }, true)
```

The second argument (`true`) wakes the body up if it's sleeping (more on sleeping in section 10).

### Setting Velocity Directly

Sometimes you want to bypass forces entirely and just set the velocity. This is common for character movement where you want precise, responsive control.

```tsx
// Set linear velocity (movement)
bodyRef.current.setLinvel({ x: 5, y: 0, z: 0 }, true)

// Set angular velocity (rotation)
bodyRef.current.setAngvel({ x: 0, y: 3, z: 0 }, true)

// Read current velocity
const vel = bodyRef.current.linvel() // { x, y, z }
const angVel = bodyRef.current.angvel() // { x, y, z }
```

### Reading Position and Rotation

```tsx
// Get current position
const pos = bodyRef.current.translation() // { x, y, z }

// Get current rotation (as quaternion)
const rot = bodyRef.current.rotation() // { x, y, z, w }
```

### The useRapier Hook

For direct access to the physics world itself:

```tsx
import { useRapier } from '@react-three/rapier'

function PhysicsController() {
  const { world, rapier } = useRapier()

  // world is the Rapier physics world instance
  // rapier is the Rapier module (for creating descriptors, etc.)

  const resetAll = () => {
    // Access world-level APIs
    world.gravity = { x: 0, y: -20, z: 0 }
  }

  return null
}
```

### Common Force Magnitudes

Getting force values right is trial and error, but here are starting points assuming objects with mass ~1:

| Action | Method | Typical Value |
|--------|--------|---------------|
| Gentle push | `applyImpulse` | `{ y: 2 }` |
| Strong launch | `applyImpulse` | `{ y: 10 }` |
| Continuous hover | `addForce` (per frame) | `{ y: 15 }` |
| Character jump | `applyImpulse` | `{ y: 5-8 }` |
| Explosion | `applyImpulse` (radial) | `{ y: 20-50 }` |

These all depend on mass. Heavier objects need bigger values. Rapier auto-calculates mass from collider volume and density (default density: 1.0).

### Adjusting Mass and Physical Properties

```tsx
<RigidBody
  mass={5}               // Override auto-calculated mass
  linearDamping={0.5}    // Air resistance (slows linear movement)
  angularDamping={0.3}   // Rotational damping (slows spinning)
  restitution={0.7}      // Bounciness (0 = no bounce, 1 = perfect bounce)
  friction={0.5}         // Surface friction
>
```

You can also set restitution and friction on individual colliders:

```tsx
<CuboidCollider args={[1, 0.5, 1]} restitution={1} friction={0} />
```

---

## 6. Collision Events

### Responding to Collisions

Physics without collision callbacks is just watching things fall. In a game, you need to know *when* objects hit each other so you can play sounds, deal damage, trigger effects, or update game state.

### The Four Collision Events

```tsx
<RigidBody
  onCollisionEnter={(event) => {
    // Fires when this body starts touching another body
    console.log('Hit something!', event.other.rigidBodyObject)
  }}
  onCollisionExit={(event) => {
    // Fires when this body stops touching another body
    console.log('No longer touching', event.other.rigidBodyObject)
  }}
  onIntersectionEnter={(event) => {
    // Fires when this body enters a sensor (see section 7)
    console.log('Entered sensor zone', event.other.rigidBodyObject)
  }}
  onIntersectionExit={(event) => {
    // Fires when this body exits a sensor
    console.log('Left sensor zone', event.other.rigidBodyObject)
  }}
>
```

**Collision** events fire for solid-body contacts (objects that physically bounce off each other). **Intersection** events fire for sensor overlaps (pass-through volumes). Don't mix them up -- this is a common source of "my events aren't firing" confusion.

### The Collision Event Object

The event passed to your callback contains useful data:

```tsx
onCollisionEnter={(event) => {
  // The "other" body involved in the collision
  const otherBody = event.other.rigidBody         // Rapier RigidBody
  const otherObject = event.other.rigidBodyObject  // Three.js Object3D (the mesh/group)
  const otherCollider = event.other.collider       // The specific collider that was hit

  // The manifold contains contact information
  const manifold = event.manifold
  const flipped = event.flipped

  // Contact normal and point (if available from manifold)
  if (manifold) {
    const normal = manifold.normal()               // Contact normal direction
  }

  // Check the other object's name or userData for identification
  if (otherObject?.name === 'ground') {
    console.log('Landed on ground!')
  }
}}
```

### Naming Bodies for Identification

You can use the `name` prop on `<RigidBody>` to tag objects, then check the name in collision callbacks:

```tsx
<RigidBody name="player" onCollisionEnter={handlePlayerCollision}>
  {/* player mesh */}
</RigidBody>

<RigidBody name="spike-trap">
  {/* spike mesh */}
</RigidBody>

function handlePlayerCollision(event: CollisionPayload) {
  const otherName = event.other.rigidBodyObject?.name
  if (otherName === 'spike-trap') {
    console.log('Player hit spikes! Ouch!')
  }
}
```

### Collision Groups (Filtering)

Not every object should collide with every other object. A player's bullet shouldn't collide with the player who fired it. UI trigger volumes shouldn't block enemy movement.

Collision groups use a bitmask system with two parts: **membership** (what groups this body belongs to) and **filter** (what groups this body collides with).

```tsx
import { RigidBody, interactionGroups } from '@react-three/rapier'

// interactionGroups(membership, filter)
// Groups are numbered 0-15

// Player is in group 0, collides with groups 1 and 2
<RigidBody collisionGroups={interactionGroups([0], [1, 2])}>
  {/* player */}
</RigidBody>

// Enemy is in group 1, collides with groups 0 and 2
<RigidBody collisionGroups={interactionGroups([1], [0, 2])}>
  {/* enemy */}
</RigidBody>

// Player bullet is in group 2, collides with group 1 only (not group 0 = player)
<RigidBody collisionGroups={interactionGroups([2], [1])}>
  {/* bullet */}
</RigidBody>
```

This prevents the bullet from hitting the player who fired it, while still letting it hit enemies and letting the player collide with enemies directly.

You can also set `solverGroups` (which groups generate contact forces) separately from `collisionGroups` (which groups generate events). This lets you detect overlaps without physical response.

---

## 7. Sensors and Triggers

### What Sensors Are

A sensor is a collider that detects overlap but doesn't create a physical collision response. Objects pass right through it. Think of it as an invisible tripwire.

```tsx
<RigidBody type="fixed" sensor>
  <CuboidCollider args={[2, 2, 2]} />
  {/* No visible mesh needed -- it's invisible */}
</RigidBody>
```

Or apply `sensor` to a specific collider within a body:

```tsx
<RigidBody type="fixed" colliders={false}>
  {/* Solid collider for the physical wall */}
  <CuboidCollider args={[2, 3, 0.2]} position={[0, 3, 0]} />
  {/* Sensor collider for the detection zone in front of the wall */}
  <CuboidCollider args={[3, 3, 1]} position={[0, 3, 1]} sensor />
</RigidBody>
```

### Sensor Events

Sensors fire **intersection** events, not **collision** events. This is the distinction:

- `onCollisionEnter` / `onCollisionExit` -- for solid-body contacts
- `onIntersectionEnter` / `onIntersectionExit` -- for sensor overlaps

```tsx
function TriggerZone() {
  const [triggered, setTriggered] = useState(false)

  return (
    <>
      <RigidBody
        type="fixed"
        sensor
        name="finish-line"
        onIntersectionEnter={(event) => {
          const name = event.other.rigidBodyObject?.name
          if (name === 'player-ball') {
            setTriggered(true)
            console.log('Player reached the finish!')
          }
        }}
        onIntersectionExit={() => {
          setTriggered(false)
        }}
      >
        <CuboidCollider args={[3, 3, 0.5]} />
      </RigidBody>

      {/* Optional: visible indicator */}
      <mesh position={[0, 3, 0]}>
        <boxGeometry args={[6, 6, 1]} />
        <meshStandardMaterial
          color={triggered ? '#00ff88' : '#ff4444'}
          transparent
          opacity={0.3}
        />
      </mesh>
    </>
  )
}
```

### Common Sensor Use Cases

| Use Case | Setup | Event |
|----------|-------|-------|
| **Trigger zone** (cutscene, door open) | Fixed sensor cuboid | `onIntersectionEnter` |
| **Pickup item** (coin, health pack) | Fixed sensor ball | `onIntersectionEnter` -> remove item |
| **Checkpoint** | Fixed sensor cuboid | `onIntersectionEnter` -> save position |
| **Kill volume** (pit, lava) | Fixed sensor cuboid below map | `onIntersectionEnter` -> respawn player |
| **Proximity detection** (aggro range) | Fixed sensor ball on enemy | `onIntersectionEnter` -> start chasing |

### Sensor vs Collision: A Mental Model

Think of it this way:
- **Collision** = solid wall. You bump into it and bounce off. You know you hit it.
- **Sensor** = laser tripwire. You walk through it unimpeded. But something knows you crossed it.

If you attach `onCollisionEnter` to a sensor body, it won't fire. You must use `onIntersectionEnter`. If you attach `onIntersectionEnter` to a solid body, it won't fire unless another sensor is involved. Match the event type to the body type.

---

## 8. Joints

### Connecting Bodies Together

Joints constrain how two rigid bodies move relative to each other. A door is a body jointed to a frame by a hinge. A piston is a body jointed to a cylinder by a slider. A wrecking ball is a body jointed to a crane by a rope.

`@react-three/rapier` provides joint components that you place inside your Physics context.

### Refs for Joint Bodies

All joints need refs to the two bodies being connected:

```tsx
const bodyA = useRef<RapierRigidBody>(null)
const bodyB = useRef<RapierRigidBody>(null)
```

### useFixedJoint

Locks two bodies together rigidly. They move as one. Use this to attach objects that shouldn't separate but need to be separate physics bodies (e.g., for different collision properties).

```tsx
import { useFixedJoint } from '@react-three/rapier'

function GluedBoxes() {
  const bodyA = useRef<RapierRigidBody>(null)
  const bodyB = useRef<RapierRigidBody>(null)

  useFixedJoint(bodyA, bodyB, [
    // Anchor point on body A (local space)
    [1, 0, 0],
    // Orientation on body A (quaternion)
    [0, 0, 0, 1],
    // Anchor point on body B (local space)
    [-1, 0, 0],
    // Orientation on body B (quaternion)
    [0, 0, 0, 1],
  ])

  return (
    <>
      <RigidBody ref={bodyA} position={[-1, 5, 0]}>
        <mesh>
          <boxGeometry />
          <meshStandardMaterial color="red" />
        </mesh>
      </RigidBody>
      <RigidBody ref={bodyB} position={[1, 5, 0]}>
        <mesh>
          <boxGeometry />
          <meshStandardMaterial color="blue" />
        </mesh>
      </RigidBody>
    </>
  )
}
```

### useRevoluteJoint (Hinge)

Allows rotation around a single axis. Doors, seesaws, wheels, flippers.

```tsx
import { useRevoluteJoint } from '@react-three/rapier'

function Seesaw() {
  const pivot = useRef<RapierRigidBody>(null)
  const plank = useRef<RapierRigidBody>(null)

  useRevoluteJoint(pivot, plank, [
    // Anchor on pivot body (local space)
    [0, 0.5, 0],
    // Anchor on plank body (local space)
    [0, 0, 0],
    // Axis of rotation (Z-axis = tilts left-right)
    [0, 0, 1],
  ])

  return (
    <>
      {/* The fixed pivot point */}
      <RigidBody ref={pivot} type="fixed" position={[0, 1, 0]}>
        <mesh>
          <cylinderGeometry args={[0.3, 0.3, 1, 16]} />
          <meshStandardMaterial color="#666666" />
        </mesh>
      </RigidBody>

      {/* The plank that tilts */}
      <RigidBody ref={plank} position={[0, 1.5, 0]}>
        <mesh>
          <boxGeometry args={[6, 0.2, 1.5]} />
          <meshStandardMaterial color="#aa8844" />
        </mesh>
      </RigidBody>
    </>
  )
}
```

### usePrismaticJoint (Slider)

Allows movement along a single axis. Sliding doors, pistons, elevators.

```tsx
import { usePrismaticJoint } from '@react-three/rapier'

function SlidingDoor() {
  const frame = useRef<RapierRigidBody>(null)
  const door = useRef<RapierRigidBody>(null)

  usePrismaticJoint(frame, door, [
    // Anchor on frame
    [0, 0, 0],
    // Anchor on door
    [0, 0, 0],
    // Slide axis (X-axis = left-right)
    [1, 0, 0],
    // Limits: [min, max] distance along axis
    // Negative = left of anchor, positive = right
  ])

  return (
    <>
      <RigidBody ref={frame} type="fixed" position={[0, 2, 0]}>
        <mesh>
          <boxGeometry args={[4, 0.2, 0.2]} />
          <meshStandardMaterial color="#444444" />
        </mesh>
      </RigidBody>
      <RigidBody ref={door} position={[0, 1, 0]}>
        <mesh>
          <boxGeometry args={[1.8, 2, 0.15]} />
          <meshStandardMaterial color="#886644" />
        </mesh>
      </RigidBody>
    </>
  )
}
```

### useSphericalJoint (Ball-and-Socket)

Allows rotation around all three axes. Ragdoll shoulders, chain links, wrecking balls.

```tsx
import { useSphericalJoint } from '@react-three/rapier'

function PendulumBall() {
  const anchor = useRef<RapierRigidBody>(null)
  const ball = useRef<RapierRigidBody>(null)

  useSphericalJoint(anchor, ball, [
    // Anchor on the fixed point
    [0, 0, 0],
    // Anchor on the ball (connect at the "top" of the chain)
    [0, 3, 0],
  ])

  return (
    <>
      <RigidBody ref={anchor} type="fixed" position={[0, 6, 0]}>
        <mesh>
          <sphereGeometry args={[0.2, 16, 16]} />
          <meshStandardMaterial color="gray" />
        </mesh>
      </RigidBody>
      <RigidBody ref={ball} position={[2, 3, 0]}>
        <mesh>
          <sphereGeometry args={[0.5, 32, 32]} />
          <meshStandardMaterial color="crimson" metalness={0.8} roughness={0.2} />
        </mesh>
      </RigidBody>
    </>
  )
}
```

### useRopeJoint

Constrains maximum distance between two bodies. They can get closer, but not farther apart than the specified length. Like an invisible rope.

```tsx
import { useRopeJoint } from '@react-three/rapier'

function TetheredBall() {
  const anchor = useRef<RapierRigidBody>(null)
  const ball = useRef<RapierRigidBody>(null)

  useRopeJoint(anchor, ball, [
    // Anchor on body A
    [0, 0, 0],
    // Anchor on body B
    [0, 0, 0],
    // Max rope length
    4,
  ])

  return (
    <>
      <RigidBody ref={anchor} type="fixed" position={[0, 8, 0]}>
        <mesh>
          <sphereGeometry args={[0.15, 16, 16]} />
          <meshStandardMaterial color="gray" />
        </mesh>
      </RigidBody>
      <RigidBody ref={ball} position={[3, 8, 0]}>
        <mesh>
          <sphereGeometry args={[0.4, 32, 32]} />
          <meshStandardMaterial color="dodgerblue" />
        </mesh>
      </RigidBody>
    </>
  )
}
```

### Motor-Driven Joints

Revolute and prismatic joints can have motors. The joint hook returns a ref you can use to configure the motor at runtime:

```tsx
function MotorizedHinge() {
  const frameRef = useRef<RapierRigidBody>(null)
  const armRef = useRef<RapierRigidBody>(null)

  const joint = useRevoluteJoint(frameRef, armRef, [
    [0, 0, 0],
    [-2, 0, 0],
    [0, 0, 1],
  ])

  useEffect(() => {
    if (!joint.current) return
    // Configure motor: target velocity, max force factor
    joint.current.configureMotorVelocity(5.0, 2.0)
  }, [joint])

  return (
    <>
      <RigidBody ref={frameRef} type="fixed" position={[0, 3, 0]}>
        <mesh>
          <boxGeometry args={[0.3, 0.3, 0.3]} />
          <meshStandardMaterial color="#555" />
        </mesh>
      </RigidBody>
      <RigidBody ref={armRef} position={[2, 3, 0]}>
        <mesh>
          <boxGeometry args={[4, 0.3, 0.5]} />
          <meshStandardMaterial color="#cc8833" />
        </mesh>
      </RigidBody>
    </>
  )
}
```

Motor methods on joints:
- `configureMotorVelocity(targetVel, factor)` -- spin at a target velocity
- `configureMotorPosition(targetAngle, stiffness, damping)` -- rotate to a target angle (like a servo)

---

## 9. Raycasting

### What Raycasting Is

A raycast shoots an invisible line from a point in a direction and tells you what it hits. This is the physics engine's version of "can I see that from here?" or "is there ground below me?"

### Ground Detection (Is the Character on the Floor?)

The most common use case. Before allowing a jump, cast a ray straight down from the character's position. If it hits something close, the character is grounded.

```tsx
import { useRapier } from '@react-three/rapier'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

function CharacterWithGroundCheck() {
  const bodyRef = useRef<RapierRigidBody>(null)
  const { world } = useRapier()
  const isGrounded = useRef(false)

  useFrame(() => {
    if (!bodyRef.current) return

    const origin = bodyRef.current.translation()
    const direction = { x: 0, y: -1, z: 0 }
    const maxDistance = 1.2 // Slightly more than character half-height

    const ray = new (world as any).constructor.Ray(origin, direction)
    const hit = world.castRay(
      ray,
      maxDistance,
      true,                // solid: test against solid colliders
      undefined,           // filter flags
      undefined,           // filter groups
      undefined,           // filter exclude collider
      bodyRef.current      // exclude this body from results
    )

    isGrounded.current = hit !== null && hit.timeOfImpact < maxDistance
  })

  // Use isGrounded.current to gate jump logic
  // ...
}
```

### Rapier Ray API

The lower-level way, using the `useRapier` hook for direct world access:

```tsx
import { useRapier } from '@react-three/rapier'

function RaycastExample() {
  const { world, rapier } = useRapier()

  const castRay = () => {
    const rayOrigin = { x: 0, y: 5, z: 0 }
    const rayDirection = { x: 0, y: -1, z: 0 }
    const maxToi = 50  // Maximum "time of impact" (distance along ray)

    const ray = new rapier.Ray(rayOrigin, rayDirection)

    // Basic raycast: returns distance to hit
    const hit = world.castRay(ray, maxToi, true)
    if (hit) {
      const hitPoint = {
        x: rayOrigin.x + rayDirection.x * hit.timeOfImpact,
        y: rayOrigin.y + rayDirection.y * hit.timeOfImpact,
        z: rayOrigin.z + rayDirection.z * hit.timeOfImpact,
      }
      console.log('Hit at distance:', hit.timeOfImpact)
      console.log('Hit point:', hitPoint)
      console.log('Hit collider:', hit.collider)
    }

    // Raycast with normal: also returns the surface normal at the hit point
    const hitWithNormal = world.castRayAndGetNormal(ray, maxToi, true)
    if (hitWithNormal) {
      console.log('Hit normal:', hitWithNormal.normal) // { x, y, z }
    }
  }

  return null
}
```

### Line-of-Sight Check

Can enemy A see the player? Cast a ray from A toward the player. If it hits the player before hitting any walls, line of sight is clear.

```tsx
function checkLineOfSight(
  world: any,
  rapier: any,
  from: { x: number; y: number; z: number },
  to: { x: number; y: number; z: number },
  excludeBody?: any
): boolean {
  const dx = to.x - from.x
  const dy = to.y - from.y
  const dz = to.z - from.z
  const distance = Math.sqrt(dx * dx + dy * dy + dz * dz)

  const direction = {
    x: dx / distance,
    y: dy / distance,
    z: dz / distance,
  }

  const ray = new rapier.Ray(from, direction)
  const hit = world.castRay(ray, distance, true)

  // If no hit, or hit is at approximately the target distance, line of sight is clear
  if (!hit) return true
  return hit.timeOfImpact >= distance - 0.1
}
```

### Aiming and Projectile Hit Testing

Cast a ray from the camera through the crosshair to find what the player is aiming at:

```tsx
import { useThree } from '@react-three/fiber'

function AimRaycast() {
  const { camera } = useThree()
  const { world, rapier } = useRapier()

  const getAimTarget = () => {
    // Ray from camera forward
    const origin = camera.position
    const direction = new THREE.Vector3(0, 0, -1)
      .applyQuaternion(camera.quaternion)

    const ray = new rapier.Ray(
      { x: origin.x, y: origin.y, z: origin.z },
      { x: direction.x, y: direction.y, z: direction.z }
    )

    const hit = world.castRayAndGetNormal(ray, 100, true)
    if (hit) {
      const point = {
        x: origin.x + direction.x * hit.timeOfImpact,
        y: origin.y + direction.y * hit.timeOfImpact,
        z: origin.z + direction.z * hit.timeOfImpact,
      }
      return { point, normal: hit.normal, collider: hit.collider }
    }
    return null
  }

  return null
}
```

### Filtering Ray Results

You can filter raycasts by collision group to ignore certain categories of objects:

```tsx
import { interactionGroups } from '@react-three/rapier'

// Only hit objects in group 1 (e.g., environment), ignore group 2 (e.g., triggers)
const filterGroups = interactionGroups([0], [1])

const hit = world.castRay(ray, maxToi, true, undefined, filterGroups)
```

This is essential for ground checks that shouldn't detect trigger volumes, or aim raycasts that should ignore the player's own body.

---

## 10. Physics Performance

### Fixed vs Variable Timestep

**Fixed timestep** (default: `1/60`) steps the simulation at a constant rate regardless of render frame rate. If your game renders at 144fps, the physics still ticks at 60Hz, with interpolation smoothing the visual positions between ticks. This gives you:
- Deterministic simulation (same input = same output)
- Stable stacking and constraint solving
- Consistent gameplay across hardware

**Variable timestep** (`timeStep="vary"`) steps the simulation once per frame using the actual frame delta. This can lead to:
- Different behavior at different frame rates
- Unstable stacking at low frame rates
- Objects tunneling through walls during frame spikes

**Use fixed timestep.** The only reason to use variable is if you're building something non-game (a casual visualization) where determinism doesn't matter and you want simplicity.

### Collision Group Filtering

Every collision check costs CPU time. The broad phase does a good job of pruning obviously-distant pairs, but collision groups let you eliminate categories of checks entirely.

If your game has 50 enemies and 200 bullets, that's potentially 10,000 enemy-bullet pair checks per frame. If bullets are in group 2 and enemies are in group 1, and you set the filters correctly, bullets only check against enemies and not against each other, cutting the work dramatically.

```tsx
// Bullets don't collide with other bullets
<RigidBody collisionGroups={interactionGroups([2], [0, 1])}>
  {/* bullet */}
</RigidBody>
```

### Sleeping Bodies

When a dynamic body comes to rest (velocity drops below a threshold), Rapier puts it to **sleep**. Sleeping bodies consume zero CPU until something disturbs them. A stack of 100 boxes that has settled costs almost nothing.

Don't fight the sleep system. It's one of the biggest performance wins in the engine. However, be aware:
- Applying a force or impulse wakes a body (the `true` second argument in API calls)
- Moving a nearby kinematic body can wake adjacent sleeping bodies
- You can manually control sleeping: `bodyRef.current.sleep()` and `bodyRef.current.wakeUp()`

```tsx
// Check if a body is sleeping
const isSleeping = bodyRef.current.isSleeping()
```

### Reducing Collider Complexity

| Optimization | Impact |
|-------------|--------|
| Use primitives (cuboid, ball, capsule) instead of hull/trimesh | Significant -- primitive checks are mathematical, not geometric |
| Decompose complex shapes into a few primitives | Better than one convex hull for most cases |
| Use convex hull instead of trimesh for static scenery when possible | Trimesh is slowest collision check |
| Reduce triangle count on trimesh colliders | Fewer triangles = faster narrow phase |
| Use heightfield for terrain instead of trimesh | Heightfield is highly optimized |

### Disabling Physics on Distant Objects

If your world is large, objects far from the player don't need active physics. You can conditionally render physics bodies:

```tsx
function DistanceCulledBody({ position, playerPosition }: Props) {
  const distance = Math.hypot(
    position[0] - playerPosition[0],
    position[2] - playerPosition[2]
  )

  const isNearby = distance < 50

  if (!isNearby) {
    // Render just the visual, no physics
    return (
      <mesh position={position}>
        <boxGeometry />
        <meshStandardMaterial color="gray" />
      </mesh>
    )
  }

  return (
    <RigidBody position={position}>
      <mesh>
        <boxGeometry />
        <meshStandardMaterial color="gray" />
      </mesh>
    </RigidBody>
  )
}
```

Be careful with this approach -- mounting and unmounting RigidBody components resets their state (velocity, sleep status, etc.). It works best for objects that should be static until the player gets close.

### Performance Checklist

1. Use fixed timestep (default is fine)
2. Set collision groups so unrelated categories don't check against each other
3. Use primitive colliders whenever possible
4. Let sleeping do its job -- don't wake bodies unnecessarily
5. Use `debug` mode to verify your colliders match your visuals -- oversized colliders waste performance
6. Profile with the browser DevTools if physics is your bottleneck (look for WASM time in the flame chart)

---

## 11. Debug Visualization

### The debug Prop

The simplest and most important debugging tool for physics. Add `debug` to your `<Physics>` component:

```tsx
<Physics debug>
  {/* All your rigid bodies and colliders */}
</Physics>
```

This renders semi-transparent wireframe overlays on every collider in the scene. You instantly see:
- Whether your colliders match your visual meshes
- Whether auto-colliders are the shape you expect
- Whether sensor volumes are positioned correctly
- Which bodies are active (green), sleeping (blue), or static (dark)

### Common Mismatches to Watch For

**Collider larger than mesh.** If your cuboid auto-collider wraps a sphere, the "sphere" will collide with things at its corners -- places where there's nothing visible. Objects will bounce off invisible geometry.

**Collider offset from mesh.** If you set `position` on the mesh inside a `<RigidBody>` but not on the collider (or vice versa), the visual and physical shapes won't overlap. The object will appear to float above surfaces or clip through them.

**Scale not propagating.** If you scale a parent `<group>` containing a `<RigidBody>`, the collider might not scale with it. Always set scale on the `<RigidBody>` itself or use explicit collider dimensions.

### Toggling Debug at Runtime

Build a debug toggle into your game so you can flip physics visualization on and off with a keypress:

```tsx
import { useState, useEffect } from 'react'
import { Physics } from '@react-three/rapier'

function PhysicsScene() {
  const [debugPhysics, setDebugPhysics] = useState(false)

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'F1') {
        e.preventDefault()
        setDebugPhysics((prev) => !prev)
      }
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [])

  return (
    <Physics debug={debugPhysics}>
      {/* scene contents */}
    </Physics>
  )
}
```

Now F1 toggles physics wireframes. This is the kind of development tool you'll use in every project, so build the habit now.

### Visualizing Raycasts

Rapier doesn't provide built-in ray visualization, but you can draw debug lines using Three.js:

```tsx
import { Line } from '@react-three/drei'

function DebugRay({ origin, direction, length, color = 'yellow' }: {
  origin: [number, number, number]
  direction: [number, number, number]
  length: number
  color?: string
}) {
  const end: [number, number, number] = [
    origin[0] + direction[0] * length,
    origin[1] + direction[1] * length,
    origin[2] + direction[2] * length,
  ]

  return (
    <Line
      points={[origin, end]}
      color={color}
      lineWidth={2}
    />
  )
}
```

Render these conditionally when debug mode is active. Seeing raycasts in 3D is invaluable for debugging ground checks, aim lines, and line-of-sight systems.

---

## Code Walkthrough: Building the Rube Goldberg Machine

Time to put it all together. You'll build a chain reaction machine: dominoes topple into a ball, the ball rolls down a ramp, the ball lands on a seesaw, the seesaw launches another ball, and the launched ball enters a sensor zone that displays "SUCCESS!"

### Project Setup

```bash
npm create vite@latest rube-goldberg -- --template react-ts
cd rube-goldberg
npm install three @react-three/fiber @react-three/drei @react-three/rapier
npm install -D @types/three
```

### Project Structure

```
rube-goldberg/
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   ├── index.css
│   └── components/
│       ├── Ground.tsx
│       ├── Dominoes.tsx
│       ├── Ramp.tsx
│       ├── Seesaw.tsx
│       ├── TriggerZone.tsx
│       └── RubeGoldbergScene.tsx
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
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
  background: #1a1a2e;
}
```

### The Ground

A simple static floor that everything rests on.

```tsx
// src/components/Ground.tsx
import { RigidBody } from '@react-three/rapier'

export function Ground() {
  return (
    <RigidBody type="fixed" name="ground" friction={0.8} restitution={0.2}>
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0, 0]} receiveShadow>
        <planeGeometry args={[60, 60]} />
        <meshStandardMaterial color="#3a5a40" />
      </mesh>
    </RigidBody>
  )
}
```

### The Dominoes

A row of thin boxes spaced just right so each one knocks over the next. The first domino gets a nudge to start the chain.

```tsx
// src/components/Dominoes.tsx
import { useRef, useEffect } from 'react'
import { RigidBody } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'

const DOMINO_COUNT = 12
const DOMINO_SPACING = 0.7
const DOMINO_WIDTH = 0.15
const DOMINO_HEIGHT = 1.0
const DOMINO_DEPTH = 0.5

interface DominoesProps {
  startX: number
  startZ: number
  shouldStart: boolean
}

function SingleDomino({
  position,
  index,
  shouldPush,
}: {
  position: [number, number, number]
  index: number
  shouldPush: boolean
}) {
  const bodyRef = useRef<RapierRigidBody>(null)
  const hasPushed = useRef(false)

  useEffect(() => {
    if (shouldPush && index === 0 && !hasPushed.current && bodyRef.current) {
      // Small delay so physics has time to initialize
      const timer = setTimeout(() => {
        if (bodyRef.current) {
          bodyRef.current.applyImpulse({ x: 0.3, y: 0, z: 0 }, true)
          hasPushed.current = true
        }
      }, 500)
      return () => clearTimeout(timer)
    }
  }, [shouldPush, index])

  return (
    <RigidBody
      ref={bodyRef}
      position={position}
      name={`domino-${index}`}
      friction={0.6}
      restitution={0.1}
      mass={0.5}
    >
      <mesh castShadow>
        <boxGeometry args={[DOMINO_WIDTH, DOMINO_HEIGHT, DOMINO_DEPTH]} />
        <meshStandardMaterial color="#e8d5b7" roughness={0.4} />
      </mesh>
    </RigidBody>
  )
}

export function Dominoes({ startX, startZ, shouldStart }: DominoesProps) {
  const dominoes = Array.from({ length: DOMINO_COUNT }, (_, i) => ({
    position: [
      startX + i * DOMINO_SPACING,
      DOMINO_HEIGHT / 2,
      startZ,
    ] as [number, number, number],
    index: i,
  }))

  return (
    <group>
      {dominoes.map(({ position, index }) => (
        <SingleDomino
          key={index}
          position={position}
          index={index}
          shouldPush={shouldStart}
        />
      ))}
    </group>
  )
}
```

### The Ramp

An angled static body at the end of the domino row. The last domino knocks a ball, which rolls down the ramp.

```tsx
// src/components/Ramp.tsx
import { RigidBody } from '@react-three/rapier'

interface RampProps {
  position: [number, number, number]
  rotation?: [number, number, number]
  size?: [number, number, number]
}

export function Ramp({
  position,
  rotation = [0, 0, -0.25],
  size = [4, 0.15, 1.5],
}: RampProps) {
  return (
    <RigidBody type="fixed" position={position} rotation={rotation} friction={0.3}>
      <mesh castShadow receiveShadow>
        <boxGeometry args={size} />
        <meshStandardMaterial color="#8b7355" roughness={0.6} />
      </mesh>
    </RigidBody>
  )
}

interface RollingBallProps {
  position: [number, number, number]
}

export function RollingBall({ position }: RollingBallProps) {
  return (
    <RigidBody
      position={position}
      colliders="ball"
      name="rolling-ball"
      restitution={0.5}
      friction={0.4}
      mass={1.5}
    >
      <mesh castShadow>
        <sphereGeometry args={[0.3, 32, 32]} />
        <meshStandardMaterial color="#cc3333" metalness={0.3} roughness={0.4} />
      </mesh>
    </RigidBody>
  )
}
```

### The Seesaw

A plank jointed to a fixed pivot with a revolute joint. When the ball lands on one end, the other end launches a second ball upward.

```tsx
// src/components/Seesaw.tsx
import { useRef } from 'react'
import { RigidBody, useRevoluteJoint } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'

interface SeesawProps {
  position: [number, number, number]
}

export function Seesaw({ position }: SeesawProps) {
  const pivotRef = useRef<RapierRigidBody>(null)
  const plankRef = useRef<RapierRigidBody>(null)

  useRevoluteJoint(pivotRef, plankRef, [
    // Anchor on the pivot (top of the cylinder)
    [0, 0.4, 0],
    // Anchor on the plank (center)
    [0, 0, 0],
    // Rotation axis (Z-axis for left-right tilt)
    [0, 0, 1],
  ])

  return (
    <group>
      {/* Fixed pivot / fulcrum */}
      <RigidBody
        ref={pivotRef}
        type="fixed"
        position={[position[0], position[1], position[2]]}
      >
        <mesh castShadow>
          <cylinderGeometry args={[0.15, 0.35, 0.8, 8]} />
          <meshStandardMaterial color="#666666" roughness={0.3} metalness={0.6} />
        </mesh>
      </RigidBody>

      {/* The plank that tilts */}
      <RigidBody
        ref={plankRef}
        position={[position[0], position[1] + 0.5, position[2]]}
        name="seesaw-plank"
        mass={2}
        friction={0.6}
      >
        <mesh castShadow>
          <boxGeometry args={[5, 0.15, 1.2]} />
          <meshStandardMaterial color="#aa8844" roughness={0.5} />
        </mesh>
      </RigidBody>

      {/* Ball sitting on the far end of the seesaw, waiting to be launched */}
      <RigidBody
        position={[position[0] - 2.2, position[1] + 1.2, position[2]]}
        colliders="ball"
        name="launch-ball"
        restitution={0.6}
        friction={0.3}
        mass={0.8}
      >
        <mesh castShadow>
          <sphereGeometry args={[0.35, 32, 32]} />
          <meshStandardMaterial color="#4488ff" metalness={0.4} roughness={0.3} />
        </mesh>
      </RigidBody>
    </group>
  )
}
```

### The Trigger Zone

A sensor volume that detects when the launched ball reaches the end zone and displays a "SUCCESS!" message.

```tsx
// src/components/TriggerZone.tsx
import { useState } from 'react'
import { RigidBody, CuboidCollider } from '@react-three/rapier'
import { Text } from '@react-three/drei'

interface TriggerZoneProps {
  position: [number, number, number]
  size?: [number, number, number]
}

export function TriggerZone({
  position,
  size = [2, 3, 2],
}: TriggerZoneProps) {
  const [triggered, setTriggered] = useState(false)

  return (
    <group position={position}>
      {/* The invisible sensor volume */}
      <RigidBody
        type="fixed"
        sensor
        name="victory-zone"
        colliders={false}
        onIntersectionEnter={(event) => {
          const name = event.other.rigidBodyObject?.name
          // Accept any ball entering the zone
          if (name === 'launch-ball' || name === 'rolling-ball') {
            setTriggered(true)
          }
        }}
      >
        <CuboidCollider
          args={[size[0] / 2, size[1] / 2, size[2] / 2]}
        />
      </RigidBody>

      {/* Visible zone indicator (transparent box) */}
      <mesh>
        <boxGeometry args={size} />
        <meshStandardMaterial
          color={triggered ? '#00ff88' : '#ff6644'}
          transparent
          opacity={triggered ? 0.4 : 0.15}
          wireframe={!triggered}
        />
      </mesh>

      {/* Victory text */}
      {triggered && (
        <Text
          position={[0, size[1] / 2 + 1, 0]}
          fontSize={0.8}
          color="#00ff88"
          anchorX="center"
          anchorY="bottom"
          outlineWidth={0.04}
          outlineColor="#003311"
        >
          SUCCESS!
        </Text>
      )}

      {/* Zone label */}
      {!triggered && (
        <Text
          position={[0, size[1] / 2 + 0.5, 0]}
          fontSize={0.3}
          color="#ff6644"
          anchorX="center"
          anchorY="bottom"
        >
          TARGET ZONE
        </Text>
      )}
    </group>
  )
}
```

### The Complete Scene

Wire it all together with the debug toggle and reset functionality.

```tsx
// src/components/RubeGoldbergScene.tsx
import { useState, useEffect, useCallback } from 'react'
import { Physics } from '@react-three/rapier'
import { OrbitControls } from '@react-three/drei'
import { Ground } from './Ground'
import { Dominoes } from './Dominoes'
import { Ramp, RollingBall } from './Ramp'
import { Seesaw } from './Seesaw'
import { TriggerZone } from './TriggerZone'

export function RubeGoldbergScene() {
  const [debugPhysics, setDebugPhysics] = useState(false)
  const [sceneKey, setSceneKey] = useState(0)
  const [started, setStarted] = useState(false)

  const resetScene = useCallback(() => {
    setStarted(false)
    setSceneKey((prev) => prev + 1)
  }, [])

  const startChain = useCallback(() => {
    setStarted(true)
  }, [])

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      switch (e.key) {
        case 'F1':
          e.preventDefault()
          setDebugPhysics((prev) => !prev)
          break
        case 'r':
        case 'R':
          resetScene()
          break
        case ' ':
          e.preventDefault()
          startChain()
          break
      }
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [resetScene, startChain])

  return (
    <>
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

      {/* Camera controls */}
      <OrbitControls
        enableDamping
        dampingFactor={0.05}
        minDistance={3}
        maxDistance={40}
        target={[4, 2, 0]}
      />

      {/*
        key={sceneKey} forces a full remount of the Physics component
        and everything inside it. This is the simplest way to "reset"
        the physics scene -- just destroy and recreate everything.
      */}
      <Physics debug={debugPhysics} key={sceneKey}>
        {/* The ground */}
        <Ground />

        {/* Row of dominoes starting at x=-2 */}
        <Dominoes startX={-2} startZ={0} shouldStart={started} />

        {/* Ball sitting at the end of the domino row */}
        <RollingBall position={[6.5, 0.35, 0]} />

        {/* Ramp angled downward, after the dominoes */}
        <Ramp position={[8.5, 0.8, 0]} rotation={[0, 0, -0.3]} />

        {/* A second ramp section to keep the ball rolling */}
        <Ramp
          position={[11, 0.15, 0]}
          rotation={[0, 0, -0.08]}
          size={[3, 0.15, 1.5]}
        />

        {/* Seesaw at the bottom of the ramp */}
        <Seesaw position={[14, 0.4, 0]} />

        {/* Target zone for the launched ball */}
        <TriggerZone position={[10, 3, 0]} size={[2.5, 3, 2.5]} />
      </Physics>
    </>
  )
}
```

### The App

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { RubeGoldbergScene } from './components/RubeGoldbergScene'

export default function App() {
  return (
    <>
      <Canvas
        shadows
        camera={{ position: [5, 8, 15], fov: 50 }}
        gl={{ antialias: true }}
      >
        <color attach="background" args={['#1a1a2e']} />
        <fog attach="fog" args={['#1a1a2e', 25, 50]} />
        <RubeGoldbergScene />
      </Canvas>

      {/* HUD overlay */}
      <div
        style={{
          position: 'absolute',
          top: 16,
          left: 16,
          color: '#ffffff',
          fontFamily: 'monospace',
          fontSize: '14px',
          pointerEvents: 'none',
          userSelect: 'none',
          lineHeight: 1.8,
        }}
      >
        <div>[SPACE] Start chain reaction</div>
        <div>[R] Reset scene</div>
        <div>[F1] Toggle physics debug</div>
        <div>Drag to orbit / Scroll to zoom</div>
      </div>
    </>
  )
}
```

### Entry Point

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

Press SPACE to push the first domino. Watch the chain reaction unfold: dominoes topple one by one, the last one hits the ball, the ball rolls down the ramp, lands on the seesaw, and the other end launches a blue ball toward the target zone. When it enters the sensor, "SUCCESS!" appears in green. Press R to reset and try again. Press F1 to see the physics debug wireframes.

### Tuning Tips

The positions, masses, and forces above are starting points. Physics tuning is an iterative process. Here's what to adjust if things don't work:

- **Dominoes don't chain-fall:** Reduce `DOMINO_SPACING` or increase the initial impulse
- **Ball doesn't reach the seesaw:** Adjust ramp angle (more negative Z rotation = steeper) or add another ramp segment
- **Seesaw doesn't launch hard enough:** Increase the rolling ball's mass or lower the launch ball's mass
- **Ball flies past the target zone:** Adjust the target zone position or size, or reduce seesaw plank mass
- **Everything jitters:** Increase friction, add damping, or check that colliders aren't overlapping at spawn

---

## API Quick Reference

### @react-three/rapier Core

| Component/Hook | Description | Example |
|----------------|-------------|---------|
| `<Physics>` | Root provider, creates Rapier world | `<Physics gravity={[0, -9.81, 0]} debug>` |
| `<RigidBody>` | Physics body wrapper | `<RigidBody type="dynamic" mass={2}>` |
| `<CuboidCollider>` | Box collider (half-extents) | `<CuboidCollider args={[1, 0.5, 1]} />` |
| `<BallCollider>` | Sphere collider | `<BallCollider args={[0.5]} />` |
| `<CapsuleCollider>` | Capsule collider | `<CapsuleCollider args={[0.5, 0.3]} />` |
| `<HeightfieldCollider>` | Terrain collider | `<HeightfieldCollider args={[...]} />` |
| `useRapier()` | Access physics world and rapier module | `const { world, rapier } = useRapier()` |
| `useFixedJoint()` | Rigid connection between bodies | `useFixedJoint(bodyA, bodyB, [...])` |
| `useRevoluteJoint()` | Hinge joint | `useRevoluteJoint(bodyA, bodyB, [...])` |
| `usePrismaticJoint()` | Slider joint | `usePrismaticJoint(bodyA, bodyB, [...])` |
| `useSphericalJoint()` | Ball-and-socket joint | `useSphericalJoint(bodyA, bodyB, [...])` |
| `useRopeJoint()` | Max-distance constraint | `useRopeJoint(bodyA, bodyB, [...])` |
| `interactionGroups()` | Create collision group bitmask | `interactionGroups([0], [1, 2])` |

### RigidBody Props

| Prop | Type | Description |
|------|------|-------------|
| `type` | `'dynamic' \| 'fixed' \| 'kinematicPosition' \| 'kinematicVelocity'` | Body type (default: dynamic) |
| `position` | `[x, y, z]` | Initial position |
| `rotation` | `[x, y, z]` | Initial rotation (Euler angles) |
| `colliders` | `'cuboid' \| 'ball' \| 'hull' \| 'trimesh' \| false` | Auto-collider shape |
| `sensor` | `boolean` | Make all colliders sensors |
| `mass` | `number` | Override auto-calculated mass |
| `friction` | `number` | Surface friction (0-1+) |
| `restitution` | `number` | Bounciness (0-1) |
| `linearDamping` | `number` | Movement damping |
| `angularDamping` | `number` | Rotation damping |
| `name` | `string` | Name for identification in events |
| `collisionGroups` | `number` | Collision group bitmask |
| `onCollisionEnter` | `(event) => void` | Solid contact start |
| `onCollisionExit` | `(event) => void` | Solid contact end |
| `onIntersectionEnter` | `(event) => void` | Sensor overlap start |
| `onIntersectionExit` | `(event) => void` | Sensor overlap end |

### RigidBody Ref API (RapierRigidBody)

| Method | Description |
|--------|-------------|
| `applyImpulse({ x, y, z }, wake)` | One-time velocity change |
| `applyTorqueImpulse({ x, y, z }, wake)` | One-time angular velocity change |
| `addForce({ x, y, z }, wake)` | Continuous force (apply every frame) |
| `addTorque({ x, y, z }, wake)` | Continuous torque |
| `setLinvel({ x, y, z }, wake)` | Set linear velocity directly |
| `setAngvel({ x, y, z }, wake)` | Set angular velocity directly |
| `linvel()` | Get current linear velocity |
| `angvel()` | Get current angular velocity |
| `translation()` | Get current position |
| `rotation()` | Get current rotation (quaternion) |
| `setNextKinematicTranslation({ x, y, z })` | Set next position for kinematic body |
| `setNextKinematicRotation({ x, y, z, w })` | Set next rotation for kinematic body |
| `sleep()` | Force body to sleep |
| `wakeUp()` | Force body to wake |
| `isSleeping()` | Check if body is sleeping |

### Rapier World Raycasting

| Method | Description |
|--------|-------------|
| `world.castRay(ray, maxToi, solid, flags?, groups?, exclude?)` | Cast ray, returns `{ timeOfImpact, collider }` |
| `world.castRayAndGetNormal(ray, maxToi, solid, flags?, groups?, exclude?)` | Cast ray, also returns hit normal |
| `new rapier.Ray(origin, direction)` | Create a ray for casting |

---

## Common Pitfalls

### 1. Using Trimesh Collider for Dynamic Bodies

Trimesh colliders (exact triangle-mesh shape) only work on fixed (static) bodies. If you use them on dynamic bodies, the simulation becomes unstable -- objects will jitter, tunnel through surfaces, or explode. Rapier technically allows it in some configurations, but the results are unreliable.

```tsx
// WRONG -- trimesh on a dynamic body = unstable physics, objects fly apart
<RigidBody type="dynamic" colliders="trimesh">
  <mesh>
    <torusGeometry args={[1, 0.3, 16, 48]} />
    <meshStandardMaterial color="gold" />
  </mesh>
</RigidBody>

// RIGHT -- use convex hull for dynamic bodies with complex shapes
<RigidBody type="dynamic" colliders="hull">
  <mesh>
    <torusGeometry args={[1, 0.3, 16, 48]} />
    <meshStandardMaterial color="gold" />
  </mesh>
</RigidBody>
```

If you need more precision than a single convex hull, use compound colliders (multiple primitives) to approximate the shape.

### 2. Forgetting the Physics Wrapper

If you put `<RigidBody>` components outside a `<Physics>` provider, nothing crashes -- but nothing works either. Objects sit motionless. No gravity, no collisions, no events. It fails silently.

```tsx
// WRONG -- RigidBody outside Physics provider = objects don't move, no errors
<Canvas>
  <RigidBody>
    <mesh>
      <boxGeometry />
      <meshStandardMaterial />
    </mesh>
  </RigidBody>
</Canvas>

// RIGHT -- wrap everything in Physics
<Canvas>
  <Physics>
    <RigidBody>
      <mesh>
        <boxGeometry />
        <meshStandardMaterial />
      </mesh>
    </RigidBody>
  </Physics>
</Canvas>
```

If objects aren't falling or colliding, the first thing to check is whether `<Physics>` wraps your scene.

### 3. Setting Position Directly on Kinematic Bodies

Kinematic bodies must use `setNextKinematicTranslation` to move. If you set the position via JSX props or direct mutation of the Three.js object, the physics engine doesn't know the body moved. It won't push other objects out of the way or generate proper collision events.

```tsx
// WRONG -- directly setting position bypasses physics
useFrame((state) => {
  if (!meshRef.current) return
  meshRef.current.position.x = Math.sin(state.clock.elapsedTime) * 3
})

// ALSO WRONG -- setting position on the RigidBody's Three.js object
useFrame((state) => {
  if (!bodyRef.current) return
  const obj = bodyRef.current as any
  obj.translation = { x: Math.sin(state.clock.elapsedTime) * 3, y: 0, z: 0 }
})

// RIGHT -- use the kinematic API so physics knows about the movement
useFrame((state) => {
  if (!bodyRef.current) return
  bodyRef.current.setNextKinematicTranslation({
    x: Math.sin(state.clock.elapsedTime) * 3,
    y: 0.5,
    z: 0,
  })
})
```

### 4. Wrong Event Type for Sensors vs Solid Bodies

`onCollisionEnter` is for solid-body contacts. `onIntersectionEnter` is for sensor overlaps. If you use the wrong one, your callback never fires and you'll spend an hour wondering why.

```tsx
// WRONG -- using onCollisionEnter on a sensor body (events never fire)
<RigidBody type="fixed" sensor onCollisionEnter={() => {
  console.log('This never prints')
}}>
  <CuboidCollider args={[2, 2, 2]} />
</RigidBody>

// RIGHT -- sensors fire intersection events, not collision events
<RigidBody type="fixed" sensor onIntersectionEnter={() => {
  console.log('Something entered the sensor zone!')
}}>
  <CuboidCollider args={[2, 2, 2]} />
</RigidBody>
```

Quick rule: if it has `sensor` on it, use `onIntersectionEnter`/`onIntersectionExit`. If it doesn't, use `onCollisionEnter`/`onCollisionExit`.

### 5. Physics Bodies Teleporting on React Re-render

When React re-renders a component containing a `<RigidBody>`, if the position comes from state, the body teleports to that position. This breaks physics continuity -- stacked objects explode, moving objects snap to new locations, simulation becomes chaotic.

```tsx
// WRONG -- position from state causes teleporting on re-render
function BadPhysicsBox() {
  const [pos, setPos] = useState([0, 5, 0])

  // Any state change in this component or a parent re-renders this,
  // which resets the RigidBody position to [0, 5, 0]
  return (
    <RigidBody position={pos as [number, number, number]}>
      <mesh>
        <boxGeometry />
        <meshStandardMaterial />
      </mesh>
    </RigidBody>
  )
}

// RIGHT -- set initial position once, let physics drive position after that
function GoodPhysicsBox() {
  const bodyRef = useRef<RapierRigidBody>(null)

  // Read position from the body ref when you need it
  // Don't store physics positions in React state
  return (
    <RigidBody ref={bodyRef} position={[0, 5, 0]}>
      <mesh>
        <boxGeometry />
        <meshStandardMaterial />
      </mesh>
    </RigidBody>
  )
}
```

The `position` prop on `<RigidBody>` is an *initial* position. After the component mounts, the physics engine owns that body's position. If you need to read the position, use `bodyRef.current.translation()`. If you need to move it, use forces, impulses, or kinematic methods.

### 6. Scale on Parent Group Not Propagating to Colliders

If you scale a `<group>` that contains a `<RigidBody>`, the visual mesh scales but the collider might not match. The physics shape stays at its original size, creating an invisible mismatch.

```tsx
// WRONG -- scaling the parent group doesn't scale the collider
<group scale={2}>
  <RigidBody>
    <mesh>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial />
    </mesh>
  </RigidBody>
</group>
// Visual: 2x2x2 box. Collider: 1x1x1 box. Objects clip through the edges.

// RIGHT -- scale on the RigidBody or use explicit collider dimensions
<RigidBody colliders={false}>
  <CuboidCollider args={[1, 1, 1]} /> {/* Half-extents for a 2x2x2 box */}
  <mesh scale={2}>
    <boxGeometry args={[1, 1, 1]} />
    <meshStandardMaterial />
  </mesh>
</RigidBody>
```

When in doubt, turn on `debug` mode and visually confirm that the collider wireframes match your meshes. If they don't line up, objects will behave strangely and you'll waste time chasing phantom bugs.

---

## Exercises

### Exercise 1: Box Stack Demolition

**Time:** 30-40 minutes

Build a pyramid stack of boxes (3-4 layers) on the ground. Create a "launcher" -- click a button or press a key to fire a sphere at the stack with a strong impulse. Watch the boxes scatter.

Requirements:
- Stack at least 10 boxes in a pyramid pattern
- Sphere fires from a fixed position toward the stack
- Use `applyImpulse` on the sphere, not `setLinvel`
- Boxes should have appropriate mass and friction to stack stably before being hit

Hints:
- Stack boxes with small gaps to avoid initial overlap (overlap = explosion)
- A sphere mass of 3-5 and impulse of `{ x: -15, y: 2, z: 0 }` is a reasonable starting point
- Use `restitution={0.1}` on boxes so they don't bounce like rubber

**Stretch goal:** Add a score counter that increments for each box that falls below y=0 (use `onCollisionEnter` with the ground or a sensor plane below the map).

### Exercise 2: Pinball Machine

**Time:** 60-90 minutes

Build a simple top-down pinball machine with two flippers controlled by left/right arrow keys.

Requirements:
- Tilted play field (static body, slight angle so the ball rolls toward the bottom)
- Two flippers at the bottom, each attached to a fixed pivot with a revolute joint
- Flippers activate with left/right arrow keys using `configureMotorVelocity` or `applyTorqueImpulse`
- Walls around the play field (static cuboid colliders)
- At least 3 bumpers (static bodies with high restitution) that the ball bounces off
- A sensor at the bottom that detects when the ball is lost

Hints:
- The play field should be rotated slightly on X to simulate a tilted table, or use a custom gravity direction
- Flipper motors: `configureMotorVelocity(30, 5)` to swing up, `configureMotorVelocity(-15, 3)` to return
- Set flipper joint limits so they don't rotate past a reasonable range
- Use `BallCollider` for the pinball with `restitution={0.8}` for bouncy behavior

**Stretch goal:** Add a score system with sensor zones behind bumpers. Display the score using drei's `<Text>` component anchored above the play field.

### Exercise 3: Jump Character with Ground Check

**Time:** 40-60 minutes

Build a capsule-shaped character that moves with WASD and jumps with SPACE. Use raycasting to check if the character is on the ground before allowing a jump.

Requirements:
- Character is a dynamic `<RigidBody>` with a `<CapsuleCollider>`
- WASD movement using `setLinvel` (preserve Y velocity for gravity)
- SPACE to jump: cast a ray downward from the character's position, only allow jump if the ray hits ground within a short distance
- A simple platform level with a few static bodies at different heights
- Character should not be able to double-jump (no jumping while in the air)

Hints:
- For WASD, read velocity with `linvel()`, modify X and Z, keep Y, then `setLinvel`
- Ground ray: origin = character translation, direction = `{ x: 0, y: -1, z: 0 }`, max distance = character half-height + small epsilon (like 1.1)
- Lock rotation so the capsule doesn't tip over: `enabledRotations={[false, false, false]}` on the `<RigidBody>`
- Jump impulse: `applyImpulse({ x: 0, y: 5, z: 0 }, true)`

**Stretch goal:** Add a moving platform (kinematic position body) that the character can ride on. The ground check raycast should detect the platform as valid ground.

### Exercise 4 (Stretch): Conveyor Belt

**Time:** 45-60 minutes

Build a conveyor belt that moves objects placed on it in a specific direction. Use `kinematicVelocity` bodies.

Requirements:
- A kinematic velocity body that looks like a belt (long, flat box)
- The belt has a constant linear velocity in one direction
- Objects placed on the belt slide along in the belt's direction due to friction
- At least 3 boxes spawning at intervals on one end, riding the belt to the other end
- A sensor at the end of the belt that removes boxes (unmounts them)

Hints:
- The kinematic velocity body itself doesn't visually move, but its surface velocity affects objects resting on it through friction
- For proper conveyor behavior you may need to set the surface velocity using Rapier's collider API or use a series of thin kinematic bodies
- Alternatively, apply a small continuous force to objects that overlap a sensor zone along the belt
- Spawn boxes using a timer in `useFrame` with a ref counter

**Stretch goal:** Build a sorting system with two conveyor belts going different directions and a sensor-activated diverter (kinematic body that pops up to redirect boxes to the second belt based on their color/name).

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [@react-three/rapier Docs](https://github.com/pmndrs/react-three-rapier) | Official Docs | The README is the primary documentation. Read the entire thing -- it covers every feature. |
| [Rapier Official Docs](https://rapier.rs/docs/) | Engine Docs | Understand the underlying engine. The JavaScript/WASM section explains the API that @react-three/rapier wraps. |
| [Rapier Testbed](https://rapier.rs/demos2d/) | Interactive Demo | Play with 2D and 3D physics demos in the browser. Great for building intuition about joints, forces, and collider shapes. |
| [Poimandres Discord](https://discord.gg/poimandres) | Community | The #rapier channel has active help. Search before asking -- most common questions are already answered. |
| [Three.js Journey R3F Physics](https://threejs-journey.com/) | Course | Bruno Simon's course has dedicated R3F + Rapier chapters with video walkthroughs. |
| [Game Physics Engine Development (Millington)](https://www.routledge.com/Game-Physics-Engine-Development/Millington/p/book/9780123819765) | Book | If you want to understand what's happening inside the engine -- not required, but deepens your intuition enormously. |

---

## Key Takeaways

1. **Rapier is the right physics engine for R3F games.** It's fast (Rust-compiled WASM), deterministic, actively maintained, and has first-class React bindings via `@react-three/rapier`. Use it unless you have a specific reason not to.

2. **Understand the four rigid body types.** Dynamic bodies are simulated by physics. Fixed bodies are immovable walls and floors. Kinematic position bodies follow scripted paths. Kinematic velocity bodies move at set velocities. Pick the right type and your scene behaves predictably.

3. **Collider shape choice is a performance and correctness decision.** Use primitives (cuboid, ball, capsule) for speed. Use convex hull for complex dynamic shapes. Use trimesh only for static scenery. Use compound colliders (multiple primitives) when a single shape doesn't fit.

4. **Forces are continuous, impulses are instantaneous.** Apply forces every frame for sustained effects (jet engines, magnets). Apply impulses once for discrete events (jumps, explosions, hits). Getting this wrong makes objects either barely twitch or rocket to infinity.

5. **Sensors detect, they don't deflect.** Sensors are pass-through volumes that fire intersection events. Use them for trigger zones, pickups, checkpoints, and kill volumes. Match the event type to the body type: `onIntersectionEnter` for sensors, `onCollisionEnter` for solid bodies.

6. **The debug wireframes are not optional during development.** Turn on `debug` mode immediately. Leave it on until your physics feel right. The number one source of confusing physics behavior is a mismatch between what you see (the mesh) and what the engine simulates (the collider).

---

## What's Next?

You now have a full physics toolkit: bodies, colliders, forces, events, sensors, joints, and raycasting. Your objects have weight, momentum, and consequences.

**[Module 5: 3D Models, Animation & Assets](module-05-models-animation-assets.md)** teaches you to load GLTF models, play skeletal animations, manage asset loading with Suspense, and integrate animated models with the physics system you just learned. Your Rube Goldberg machine used primitive shapes -- now you'll replace them with real 3D art.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)