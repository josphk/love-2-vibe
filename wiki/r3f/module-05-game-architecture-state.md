# Module 5: Game Architecture & State

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 6–10 hours
**Prerequisites:** [Module 4: Physics with Rapier](module-04-physics-rapier.md)

---

## Overview

Your codebase has hit a wall. You have physics, you have 3D rendering, you have input handling. But every new feature you add makes the whole thing worse. Adding a pause menu breaks your physics. Adding a score display causes performance drops. Adding a title screen means restructuring half your components. This isn't a skill problem — it's an architecture problem.

This module is about building a real game structure: state management that doesn't fight your render loop, scene transitions that don't destroy your objects, a game clock you can pause and slow down, and organizational patterns that scale from "weekend jam" to "actual shipped game." You'll learn Zustand (the state manager built by the same team that makes R3F), ECS patterns for when your entity count grows, and event systems for decoupling the gnarly spaghetti that games inevitably produce.

The mini-project is a structured arena game with all the screens a real game needs: title, gameplay with HUD, pause menu, game over. Enemies spawn, you dodge or shoot, health goes down, score goes up. It's not about the gameplay being complex — it's about the *plumbing* being clean. When you finish this module, adding a new feature should feel like plugging in a new module, not performing open-heart surgery on your codebase.

---

## 1. Why Architecture Matters Now

Up until now, you could get away with keeping everything in one file. A single component with some refs, a `useFrame`, maybe a few `useState` calls. That worked because the scope was small. But games grow. They grow fast. And they grow in ways you don't predict.

Here's what happens without architecture:

- You add a score counter. It lives in `useState` inside your game component. Now you need to display it in the HUD, which is a DOM overlay. You start prop-drilling or lifting state up and suddenly your entire component tree re-renders when the score changes.
- You add a pause menu. Now you need to stop the physics, stop the game clock, stop enemy spawning, but keep the scene rendered. You start threading `isPaused` through every component.
- You add a title screen. Now you need conditional rendering at the top level. But mounting and unmounting the game scene means losing all your physics state, entity positions, and loaded assets.
- You add sound effects. The sound system needs to know when an enemy dies, when the player gets hit, when the score reaches a milestone. You start passing callbacks everywhere.

Each of these features is individually simple. But without structure, they interact in exponentially complex ways. Five simple features create twenty-five potential interactions. Ten features create a hundred. This is the complexity bomb that kills hobby game projects.

The fix isn't "be more careful." The fix is architecture: predictable patterns for state, communication, and lifecycle that scale linearly instead of exponentially. That's what this module teaches.

---

## 2. Zustand: State Management for Games

### Why Zustand Over Redux or Context

You might be wondering why not Redux, or React Context, or Jotai, or any of the other state management solutions in the React ecosystem. Here's the short answer: Zustand was built by the same team that builds R3F (Poimandres), and it was designed with exactly this use case in mind.

The longer answer:

| Solution | Problem for Games |
|----------|------------------|
| `useState` / `useReducer` | Component-scoped. Can't access from `useFrame` without re-renders. Prop drilling nightmare. |
| React Context | Every consumer re-renders when *any* part of the context changes. No selector support out of the box. |
| Redux | Massive boilerplate. Actions, reducers, action creators. Overkill for game state that changes 60 times per second. |
| Zustand | Minimal API. Selectors prevent unnecessary re-renders. `getState()` for read-without-subscribe. Works perfectly inside `useFrame`. |

Zustand gives you a global store that any component can read from, with surgical control over which components re-render when which parts of state change. And critically, it lets you read state *without subscribing* — which is exactly what you need inside a game loop.

### Installing Zustand

```bash
npm install zustand
```

### Creating a Store

A Zustand store is just a function that returns your initial state and any actions to modify it:

```tsx
// src/stores/useGameStore.ts
import { create } from 'zustand'

interface GameState {
  // State
  gamePhase: 'menu' | 'playing' | 'paused' | 'gameOver'
  score: number
  health: number
  highScore: number

  // Actions
  startGame: () => void
  pauseGame: () => void
  resumeGame: () => void
  endGame: () => void
  addScore: (points: number) => void
  takeDamage: (amount: number) => void
  resetGame: () => void
}

export const useGameStore = create<GameState>((set, get) => ({
  // Initial state
  gamePhase: 'menu',
  score: 0,
  health: 100,
  highScore: 0,

  // Actions
  startGame: () => set({ gamePhase: 'playing', score: 0, health: 100 }),

  pauseGame: () => {
    if (get().gamePhase === 'playing') {
      set({ gamePhase: 'paused' })
    }
  },

  resumeGame: () => {
    if (get().gamePhase === 'paused') {
      set({ gamePhase: 'playing' })
    }
  },

  endGame: () => {
    const { score, highScore } = get()
    set({
      gamePhase: 'gameOver',
      highScore: Math.max(score, highScore),
    })
  },

  addScore: (points) => set((state) => ({ score: state.score + points })),

  takeDamage: (amount) => {
    const newHealth = Math.max(0, get().health - amount)
    set({ health: newHealth })
    if (newHealth <= 0) {
      get().endGame()
    }
  },

  resetGame: () => set({ gamePhase: 'menu', score: 0, health: 100 }),
}))
```

A few things to notice:

- `set` merges state shallowly — you only specify the fields you're changing.
- `get` reads the current state at call time — use it when an action depends on current values.
- Actions live alongside state in the same store. No separate action creators, no dispatch, no reducers.
- The `takeDamage` action checks if health reached zero and automatically triggers `endGame`. Logic stays in the store, not scattered across components.

### Reading State in Components

Use the store hook with a selector to subscribe to specific slices:

```tsx
function ScoreDisplay() {
  // Only re-renders when score changes
  const score = useGameStore((state) => state.score)
  return <div className="score">Score: {score}</div>
}

function HealthBar() {
  // Only re-renders when health changes
  const health = useGameStore((state) => state.health)
  return (
    <div className="health-bar">
      <div
        className="health-fill"
        style={{ width: `${health}%` }}
      />
    </div>
  )
}
```

Each component only subscribes to the slice it cares about. When the score changes, `HealthBar` does not re-render. When health changes, `ScoreDisplay` does not re-render. This is the selector pattern, and it's essential for performance.

### The Critical Pattern: getState() in useFrame

This is the single most important Zustand pattern for game development. Inside `useFrame`, you do not want to subscribe to state — that would cause a re-render every time that state changes. Instead, you read state imperatively with `getState()`:

```tsx
function EnemySpawner() {
  const spawnTimerRef = useRef(0)

  useFrame((_, delta) => {
    // Read state without subscribing — no re-renders!
    const { gamePhase } = useGameStore.getState()
    if (gamePhase !== 'playing') return

    spawnTimerRef.current += delta
    if (spawnTimerRef.current > 2) {
      spawnTimerRef.current = 0
      // Spawn an enemy...
    }
  })

  return null
}
```

`useGameStore.getState()` is a plain function call. It reads the current state synchronously. No hook. No subscription. No re-render. You can call it from anywhere — inside `useFrame`, inside event handlers, inside utility functions, even outside of React entirely.

This is why Zustand is perfect for games: it bridges the gap between React's declarative world and the imperative game loop.

### Multiple Stores vs One Big Store

You have two strategies:

**One big store** — All game state lives in a single store. Simple to reason about. Actions can easily reference other state. Good for small-to-medium games.

**Multiple specialized stores** — Separate stores for different concerns: `useGameStore` for phase/score, `usePlayerStore` for player state, `useSettingsStore` for audio/graphics settings. Good for larger games where you want clear boundaries.

```tsx
// Multiple stores approach
export const useGameStore = create<GameState>((set) => ({
  gamePhase: 'menu',
  score: 0,
  // ...
}))

export const usePlayerStore = create<PlayerState>((set) => ({
  health: 100,
  position: [0, 0, 0] as [number, number, number],
  inventory: [],
  // ...
}))

export const useSettingsStore = create<SettingsState>((set) => ({
  musicVolume: 0.7,
  sfxVolume: 1.0,
  showFps: false,
  // ...
}))
```

Start with one store. Split when you feel the pain of it growing too large. Premature separation is worse than a slightly-too-big single store.

---

## 3. subscribeWithSelector

### The Problem

By default, Zustand's `subscribe` method fires on *every* state change, regardless of which field changed. If you want to react to a *specific* state change — say, play a sound when health drops below 25 — you need more precision.

### Enabling subscribeWithSelector

```tsx
import { create } from 'zustand'
import { subscribeWithSelector } from 'zustand/middleware'

interface GameState {
  health: number
  score: number
  gamePhase: 'menu' | 'playing' | 'paused' | 'gameOver'
  takeDamage: (amount: number) => void
  addScore: (points: number) => void
}

export const useGameStore = create<GameState>()(
  subscribeWithSelector((set, get) => ({
    health: 100,
    score: 0,
    gamePhase: 'menu',
    takeDamage: (amount) => {
      const newHealth = Math.max(0, get().health - amount)
      set({ health: newHealth })
      if (newHealth <= 0) set({ gamePhase: 'gameOver' })
    },
    addScore: (points) => set((s) => ({ score: s.score + points })),
  }))
)
```

Notice the double parentheses on `create<GameState>()( ... )`. The first call is for the generic type, the second passes the middleware-wrapped state creator. TypeScript requires this pattern.

### Subscribing to Slices

Now you can subscribe to specific fields and react only when they change:

```tsx
// In a setup effect (like useEffect or a component mount)
useEffect(() => {
  // Subscribe to health changes only
  const unsubHealth = useGameStore.subscribe(
    (state) => state.health,
    (health, previousHealth) => {
      if (health < previousHealth) {
        // Health went down — play damage sound
        playSound('hit')
      }
      if (health <= 25 && previousHealth > 25) {
        // Just crossed the low-health threshold
        playSound('warning')
      }
    }
  )

  // Subscribe to score changes only
  const unsubScore = useGameStore.subscribe(
    (state) => state.score,
    (score, previousScore) => {
      if (score > 0 && score % 1000 === 0) {
        // Milestone! Every 1000 points
        playSound('milestone')
        spawnParticles('celebration')
      }
    }
  )

  return () => {
    unsubHealth()
    unsubScore()
  }
}, [])
```

The first argument is the selector (which slice to watch). The second is the listener (what to do when it changes). The listener receives both the new value and the previous value, which is incredibly useful for detecting transitions.

### Reacting to Phase Transitions

This pattern is perfect for game phase changes:

```tsx
useEffect(() => {
  const unsub = useGameStore.subscribe(
    (state) => state.gamePhase,
    (phase, previousPhase) => {
      if (phase === 'playing' && previousPhase === 'menu') {
        // Game just started
        playMusic('gameplay')
      }
      if (phase === 'gameOver') {
        stopMusic()
        playSound('gameOver')
      }
      if (phase === 'paused') {
        pauseMusic()
      }
      if (phase === 'playing' && previousPhase === 'paused') {
        resumeMusic()
      }
    }
  )
  return unsub
}, [])
```

This is how you wire up side effects (sound, particles, analytics, save-game triggers) without polluting your game logic. The store just changes state. Subscribers react to the changes they care about.

### The equalityFn Option

By default, Zustand uses `Object.is` for comparison. For object or array selectors, you might want shallow equality:

```tsx
import { shallow } from 'zustand/shallow'

const unsub = useGameStore.subscribe(
  (state) => ({ health: state.health, score: state.score }),
  (slice) => {
    updateHUD(slice)
  },
  { equalityFn: shallow }
)
```

---

## 4. Transient Updates

### The Problem with React Re-Renders in Games

You have a score display. Every time the score changes, React re-renders the HUD. That's fine — the HUD is a DOM element, it needs to update. But what about a health bar that's a 3D mesh inside the Canvas? If the health bar is a React component that subscribes to `health` state, it re-renders on every health change. If the health bar has children, they re-render too. In a complex scene, this cascade can be expensive.

The transient update pattern lets you update visual state *without* triggering React re-renders, by combining `useStore.subscribe` with `useRef`.

### The Pattern

```tsx
import { useRef, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Mesh } from 'three'
import { useGameStore } from '../stores/useGameStore'

function HealthBar3D() {
  const barRef = useRef<Mesh>(null)
  // Read initial value once to set up the ref
  const healthRef = useRef(useGameStore.getState().health)

  useEffect(() => {
    // Subscribe to health changes and store in ref — no re-render
    const unsub = useGameStore.subscribe(
      (state) => (healthRef.current = state.health)
    )
    return unsub
  }, [])

  useFrame(() => {
    if (!barRef.current) return
    // Use the ref value to update the mesh directly
    const healthPercent = healthRef.current / 100
    barRef.current.scale.x = healthPercent
    barRef.current.position.x = (healthPercent - 1) / 2
  })

  return (
    <group position={[-2, 2, 0]}>
      {/* Background bar */}
      <mesh position={[0, 0, -0.01]}>
        <planeGeometry args={[2, 0.2]} />
        <meshBasicMaterial color="#333333" />
      </mesh>
      {/* Health fill */}
      <mesh ref={barRef}>
        <planeGeometry args={[2, 0.2]} />
        <meshBasicMaterial color="#44ff44" />
      </mesh>
    </group>
  )
}
```

Here's what's happening:

1. `healthRef` stores the current health value.
2. `useEffect` subscribes to the store and pipes new values into `healthRef.current`. This is a plain assignment — no `setState`, no re-render.
3. `useFrame` reads `healthRef.current` every frame and updates the mesh's scale directly.

The component renders once when it mounts. After that, health updates flow through the ref and directly into Three.js mutations. React never knows the health changed. The mesh updates at 60fps with zero reconciliation overhead.

### When to Use Transient Updates

Use transient updates when:
- The visual representation is a 3D object inside the Canvas
- The value changes frequently (multiple times per second)
- The component has expensive children that would be affected by re-renders

Use normal React state when:
- The visual representation is DOM (HTML overlay)
- The value changes infrequently (button clicks, phase changes)
- Re-rendering is cheap (small component trees)

### Transient Updates with subscribeWithSelector

If you're already using `subscribeWithSelector`, you can combine both patterns:

```tsx
useEffect(() => {
  const unsub = useGameStore.subscribe(
    (state) => state.health,
    (health) => {
      healthRef.current = health
    }
  )
  return unsub
}, [])
```

Same idea, but now you only receive updates when the specific field you care about changes.

---

## 5. Scene Management

### Game Phases as Conditional Rendering

A game typically has several distinct phases: menu, playing, paused, game over. In React, the simplest way to handle this is conditional rendering based on the current phase:

```tsx
function Game() {
  const gamePhase = useGameStore((state) => state.gamePhase)

  return (
    <>
      <Canvas camera={{ position: [0, 10, 15], fov: 50 }}>
        {/* The 3D scene is always mounted — we control visibility */}
        <GameScene />
        <ambientLight intensity={0.3} />
        <directionalLight position={[5, 10, 5]} intensity={1} />
      </Canvas>

      {/* DOM overlays — conditionally rendered */}
      {gamePhase === 'menu' && <TitleScreen />}
      {gamePhase === 'playing' && <HUD />}
      {gamePhase === 'paused' && <PauseMenu />}
      {gamePhase === 'gameOver' && <GameOverScreen />}
    </>
  )
}
```

Notice the 3D scene stays mounted regardless of game phase. The DOM overlays (title screen, HUD, pause menu, game over) are what get conditionally rendered. This is intentional.

### Mount/Unmount vs Visibility

You have two strategies for scene content:

**Mount/Unmount** — Components are added to and removed from the React tree. Good for DOM overlays and lightweight 3D elements. Bad for heavy scenes because mounting triggers initialization (loading textures, creating physics bodies, etc.).

```tsx
{/* Mount/unmount — clean but expensive for heavy scenes */}
{gamePhase === 'playing' && <GameplayScene />}
```

**Visibility Toggle** — Components stay mounted but become invisible. Good for heavy 3D scenes because they stay initialized. Bad for DOM elements (invisible `<div>`s still take up layout space).

```tsx
{/* Visibility — scene stays alive, just hidden */}
<group visible={gamePhase === 'playing'}>
  <GameplayScene />
</group>
```

In practice, you'll usually combine both. Keep the 3D scene mounted and toggle visibility. Mount/unmount the DOM overlays.

### A Complete Scene Manager

```tsx
// src/components/SceneManager.tsx
import { useGameStore } from '../stores/useGameStore'
import { Arena } from './Arena'
import { Enemies } from './Enemies'
import { Player } from './Player'
import { Projectiles } from './Projectiles'

export function SceneManager() {
  const gamePhase = useGameStore((state) => state.gamePhase)
  const isActive = gamePhase === 'playing' || gamePhase === 'paused'

  return (
    <group>
      {/* Arena floor and walls — always visible once the game has been entered */}
      <group visible={isActive}>
        <Arena />
      </group>

      {/* Gameplay entities — only active during play */}
      {isActive && (
        <>
          <Player paused={gamePhase === 'paused'} />
          <Enemies paused={gamePhase === 'paused'} />
          <Projectiles paused={gamePhase === 'paused'} />
        </>
      )}

      {/* Title screen 3D content */}
      {gamePhase === 'menu' && <TitleScene />}
    </group>
  )
}
```

### Keeping Scene State Alive During Pause

When the player pauses, you don't want enemies to reset their positions or projectiles to disappear. The key is: *don't unmount gameplay components when pausing*. Instead, pass a `paused` prop (or read the game phase in `useFrame`) and skip updates:

```tsx
function Enemy({ position, paused }: { position: [number, number, number]; paused: boolean }) {
  const meshRef = useRef<Mesh>(null)

  useFrame((_, delta) => {
    if (paused || !meshRef.current) return
    // Enemy logic only runs when not paused
    meshRef.current.position.z += delta * 2
  })

  return (
    <mesh ref={meshRef} position={position}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="red" />
    </mesh>
  )
}
```

Or, more cleanly, read the phase from the store inside `useFrame`:

```tsx
function Enemy({ position }: { position: [number, number, number] }) {
  const meshRef = useRef<Mesh>(null)

  useFrame((_, delta) => {
    if (!meshRef.current) return
    const { gamePhase } = useGameStore.getState()
    if (gamePhase !== 'playing') return

    meshRef.current.position.z += delta * 2
  })

  return (
    <mesh ref={meshRef} position={position}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="red" />
    </mesh>
  )
}
```

This second approach is cleaner because the component doesn't need a `paused` prop. Every component that cares about pause state just reads from the store.

### Transition Animations

For polish, you can fade between phases using CSS transitions on the DOM overlays:

```tsx
// src/components/Overlay.tsx
import { ReactNode } from 'react'

interface OverlayProps {
  visible: boolean
  children: ReactNode
}

export function Overlay({ visible, children }: OverlayProps) {
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'rgba(0, 0, 0, 0.7)',
        opacity: visible ? 1 : 0,
        pointerEvents: visible ? 'all' : 'none',
        transition: 'opacity 0.3s ease',
        zIndex: 10,
      }}
    >
      {children}
    </div>
  )
}
```

Use `pointerEvents: 'none'` when the overlay is invisible so clicks pass through to the Canvas underneath.

---

## 6. The Game Clock

### Why You Need Your Own Clock

R3F gives you `state.clock` and `delta` in `useFrame`. These are fine for simple animations, but games need more control:

- **Pause**: R3F's clock keeps ticking when the game is paused. You need a clock that stops.
- **Slow motion**: Setting `delta` to `delta * 0.5` everywhere is error-prone. You want a central time scale.
- **Elapsed game time**: How long has this round been going? R3F's clock counts from scene creation, not from game start.

### Building a Game Clock Store

```tsx
// src/stores/useClockStore.ts
import { create } from 'zustand'

interface ClockState {
  elapsed: number        // Seconds since game started (affected by timeScale)
  timeScale: number      // 1.0 = normal, 0.5 = slow motion, 0 = paused
  isPaused: boolean

  pause: () => void
  resume: () => void
  setTimeScale: (scale: number) => void
  reset: () => void
  tick: (rawDelta: number) => void
}

export const useClockStore = create<ClockState>((set, get) => ({
  elapsed: 0,
  timeScale: 1.0,
  isPaused: false,

  pause: () => set({ isPaused: true }),
  resume: () => set({ isPaused: false }),
  setTimeScale: (scale) => set({ timeScale: Math.max(0, scale) }),
  reset: () => set({ elapsed: 0 }),

  tick: (rawDelta) => {
    const { isPaused, timeScale, elapsed } = get()
    if (isPaused) return

    const scaledDelta = rawDelta * timeScale
    set({ elapsed: elapsed + scaledDelta })
  },
}))
```

### The Clock Ticker Component

Create a component whose only job is to tick the game clock every frame:

```tsx
// src/systems/ClockTicker.tsx
import { useFrame } from '@react-three/fiber'
import { useClockStore } from '../stores/useClockStore'

export function ClockTicker() {
  useFrame((_, delta) => {
    useClockStore.getState().tick(delta)
  })
  return null
}
```

Place this inside your `<Canvas>`:

```tsx
<Canvas>
  <ClockTicker />
  <SceneManager />
  {/* ... */}
</Canvas>
```

### Using the Game Clock in Systems

Now every system that needs delta time reads from the game clock instead of using `useFrame`'s raw delta:

```tsx
function EnemySystem() {
  useFrame((_, rawDelta) => {
    const { isPaused, timeScale } = useClockStore.getState()
    if (isPaused) return

    const delta = rawDelta * timeScale

    // All enemy movement uses the scaled delta
    enemies.forEach((enemy) => {
      enemy.position.z += enemy.speed * delta
    })
  })

  return null
}
```

### Slow Motion

Now slow motion is trivial:

```tsx
function triggerSlowMotion(duration: number) {
  const clock = useClockStore.getState()
  clock.setTimeScale(0.2) // 20% speed

  setTimeout(() => {
    clock.setTimeScale(1.0) // Back to normal
  }, duration * 1000)
}
```

Want a bullet-time effect? Set `timeScale` to 0.1 when the player activates a special ability. Everything slows down — enemies, projectiles, particles — because everything reads from the same clock. The player can optionally ignore time scale for their own movement, making them feel fast while the world moves in slow motion.

### Wiring Clock to Game Phase

Connect the clock to your game store so pausing the game pauses the clock:

```tsx
// In your setup/initialization
useEffect(() => {
  const unsub = useGameStore.subscribe(
    (state) => state.gamePhase,
    (phase) => {
      if (phase === 'paused') {
        useClockStore.getState().pause()
      } else if (phase === 'playing') {
        useClockStore.getState().resume()
      } else if (phase === 'menu') {
        useClockStore.getState().reset()
      }
    }
  )
  return unsub
}, [])
```

---

## 7. Fixed Timestep

### The Problem with Variable Delta Time

Every frame, your `useFrame` callback receives `delta` — the time since the last frame. On a fast machine at 144fps, delta is ~0.007 seconds. On a slow machine at 30fps, delta is ~0.033 seconds. If you multiply movement by delta, things move at the same *speed* regardless of frame rate. But they don't produce the same *results*.

Why? Because physics integration is order-dependent. Consider a ball bouncing on a floor:

- At 144fps: ball moves in tiny increments, collision is detected early, bounce happens at almost exactly the right position.
- At 30fps: ball moves in large increments, might pass *through* the floor before collision is detected (tunneling), or bounce from a position well below the surface.

Variable delta time produces non-deterministic behavior. The game plays differently at different frame rates. This is unacceptable for anything with physics, AI state machines, or gameplay that needs to feel consistent.

### The Accumulator Pattern

The fix is the fixed timestep: run your game logic at a constant rate (say, 60 times per second, with a fixed delta of 1/60) regardless of the rendering frame rate. If the render rate is faster than the logic rate, some frames skip the logic update. If the render rate is slower, the logic runs multiple times per render frame to catch up.

```tsx
// src/systems/FixedTimestep.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { useClockStore } from '../stores/useClockStore'

const FIXED_DT = 1 / 60 // 60Hz logic rate
const MAX_SUBSTEPS = 5   // Safety cap to prevent spiral of death

interface FixedTimestepProps {
  onFixedUpdate: (fixedDelta: number) => void
}

export function FixedTimestep({ onFixedUpdate }: FixedTimestepProps) {
  const accumulatorRef = useRef(0)

  useFrame((_, rawDelta) => {
    const { isPaused, timeScale } = useClockStore.getState()
    if (isPaused) return

    const delta = rawDelta * timeScale

    // Clamp delta to prevent huge jumps (e.g., after tab was in background)
    const clampedDelta = Math.min(delta, FIXED_DT * MAX_SUBSTEPS)

    accumulatorRef.current += clampedDelta

    let steps = 0
    while (accumulatorRef.current >= FIXED_DT && steps < MAX_SUBSTEPS) {
      onFixedUpdate(FIXED_DT)
      accumulatorRef.current -= FIXED_DT
      steps++
    }
  })

  return null
}
```

### How the Accumulator Works

Let's trace through an example. Fixed step is 1/60 (~0.0167s):

1. **Frame 1** (delta = 0.018s): Accumulator goes from 0 to 0.018. That's >= 0.0167, so we run one fixed update. Accumulator becomes 0.018 - 0.0167 = 0.0013.
2. **Frame 2** (delta = 0.015s): Accumulator goes from 0.0013 to 0.0163. That's < 0.0167, so we skip the logic update. Just render.
3. **Frame 3** (delta = 0.016s): Accumulator goes from 0.0163 to 0.0323. That's >= 0.0167, so we run one fixed update. Accumulator becomes 0.0323 - 0.0167 = 0.0156.
4. **Frame 4** (delta = 0.033s — lag spike): Accumulator goes from 0.0156 to 0.0486. That's >= 0.0167, so we run one update (0.0486 - 0.0167 = 0.0319), then another (0.0319 - 0.0167 = 0.0152). Two fixed updates to catch up.

The result: game logic always runs at exactly 60Hz, regardless of render frame rate. Physics is deterministic. The game plays identically on fast and slow machines.

### The Spiral of Death

What if the machine is so slow that each frame takes longer than several fixed steps? The accumulator grows unboundedly, the logic runs more steps to catch up, each frame takes even longer, more steps accumulate... This is the "spiral of death."

The `MAX_SUBSTEPS` cap prevents this. If the accumulator has more time than `MAX_SUBSTEPS * FIXED_DT`, we cap it. The game will effectively slow down (run at less than real-time), but it won't freeze or crash.

### Using the Fixed Timestep

```tsx
function GameLoop() {
  const handleFixedUpdate = useCallback((fixedDelta: number) => {
    // All deterministic game logic goes here
    updateEnemyAI(fixedDelta)
    updatePhysics(fixedDelta)
    checkCollisions()
    updateSpawners(fixedDelta)
  }, [])

  return <FixedTimestep onFixedUpdate={handleFixedUpdate} />
}
```

### Separating Render from Logic

With a fixed timestep, you naturally separate two kinds of updates:

- **Fixed update** (deterministic, constant rate): physics, AI, game logic, collision detection.
- **Render update** (variable rate, every frame): visual interpolation, camera smoothing, particle effects, animations.

```tsx
function GameSystems() {
  const handleFixedUpdate = useCallback((fixedDelta: number) => {
    // Deterministic logic at fixed 60Hz
    updatePhysics(fixedDelta)
    updateAI(fixedDelta)
  }, [])

  useFrame((_, delta) => {
    // Visual-only updates at render rate
    updateParticles(delta)
    updateCameraSmooth(delta)
  })

  return <FixedTimestep onFixedUpdate={handleFixedUpdate} />
}
```

---

## 8. ECS: Entity Component System

### What ECS Is

Entity Component System is an architectural pattern used in almost every serious game engine. It replaces the object-oriented inheritance model (class `FlyingEnemy extends Enemy extends Entity`) with a composition model:

- **Entity**: Just an ID. A number. Nothing else. It's a label that says "this thing exists."
- **Component**: A bag of data attached to an entity. `Position { x, y, z }`, `Health { current, max }`, `Velocity { dx, dy, dz }`. No behavior.
- **System**: A function that operates on all entities that have a specific set of components. "For every entity with Position and Velocity, update Position by adding Velocity * delta."

The power is in the queries. Instead of a deep class hierarchy where you override methods, you have flat data and systems that process groups of entities by their component composition.

### Why Games Use ECS

**Flexible composition**: An entity can be anything. Give it `Position` + `Sprite` and it's a visual object. Add `Health` and it's a damageable object. Add `AI` and it becomes an enemy. Add `PlayerControlled` and it becomes the player. No inheritance gymnastics.

**Cache-friendly data layouts**: Components of the same type are stored contiguously in memory. When a system iterates over all `Position` components, it's reading sequential memory. This is fast. Object-oriented designs scatter data across the heap.

**Decoupled systems**: The rendering system doesn't know about the health system. The AI system doesn't know about the rendering system. They communicate through components on entities. Adding a new system doesn't require modifying existing code.

### When ECS Makes Sense vs When It's Overkill

ECS shines when:
- You have many entities with varied but overlapping capabilities (enemies, power-ups, projectiles, decorations — all with different component mixes)
- You need to add/remove capabilities dynamically (an enemy picks up a shield — add `Shield` component)
- You're processing hundreds or thousands of entities per frame
- Systems need to query across entity types (damage system needs all entities with `Health`, regardless of whether they're enemies, players, or destructible objects)

ECS is overkill when:
- You have fewer than ~20 entities
- Entity types are fixed and well-known (just a player, a few enemies, and some platforms)
- React component composition already handles your needs
- You're prototyping and just need things to work

Don't adopt ECS because it sounds cool. Adopt it when your game outgrows simple component-based React architecture.

### Mental Model: ECS vs OOP

```
OOP:
  class FlyingEnemy extends Enemy extends Entity
    - has position, velocity, health, AI, flying behavior
    - What if we want a non-flying enemy with the same AI?
    - What if we want a flying object that isn't an enemy?
    - Inheritance doesn't let you mix and match.

ECS:
  Entity 42:
    - Position { x: 5, y: 10, z: 0 }
    - Velocity { dx: 0, dy: 0, dz: -1 }
    - Health { current: 50, max: 50 }
    - AI { behavior: 'patrol' }
    - Flying { altitude: 10 }

  Want a non-flying enemy? Same thing without the Flying component.
  Want a flying non-enemy? Position + Velocity + Flying, no Health or AI.
  No new classes needed.
```

---

## 9. ECS with miniplex

### Why miniplex

`miniplex` is an ECS library specifically designed to work well with React and R3F. It uses plain JavaScript objects as entities (not typed arrays), which means your entities can hold React refs, Three.js objects, and any other JS value. It integrates with React's rendering model through a `<Entity>` pattern.

```bash
npm install miniplex @miniplex/react
```

### Creating a World

```tsx
// src/ecs/world.ts
import { World } from 'miniplex'

// Define your entity type
interface GameEntity {
  // Core components
  position?: { x: number; y: number; z: number }
  velocity?: { x: number; y: number; z: number }
  health?: { current: number; max: number }

  // Identity tags
  isEnemy?: true
  isProjectile?: true
  isPlayer?: true
  isPickup?: true

  // Visual
  color?: string
  size?: number

  // AI
  ai?: { behavior: 'chase' | 'patrol' | 'flee'; target?: GameEntity }

  // Three.js ref (for bridging ECS to rendering)
  sceneObject?: THREE.Object3D
}

export const world = new World<GameEntity>()
```

### Adding Entities

```tsx
// Spawn an enemy
const enemy = world.add({
  position: { x: 5, y: 0, z: -10 },
  velocity: { x: 0, y: 0, z: 1 },
  health: { current: 30, max: 30 },
  isEnemy: true,
  color: '#ff4444',
  size: 1,
  ai: { behavior: 'chase' },
})

// Spawn a projectile
const bullet = world.add({
  position: { x: 0, y: 1, z: 0 },
  velocity: { x: 0, y: 0, z: -20 },
  isProjectile: true,
  color: '#ffff00',
  size: 0.2,
})

// Remove an entity
world.remove(enemy)
```

### Querying Entities

Queries are how systems find the entities they care about:

```tsx
// All entities with position and velocity
const movingEntities = world.with('position', 'velocity')

// All enemies (entities with isEnemy AND position)
const enemies = world.with('isEnemy', 'position')

// All entities with health
const damageable = world.with('health')

// Entities with position but NOT isEnemy
const nonEnemies = world.with('position').without('isEnemy')
```

### Building Systems

A system is just a function that iterates over a query:

```tsx
// src/systems/movementSystem.ts
import { world } from '../ecs/world'

const movingEntities = world.with('position', 'velocity')

export function movementSystem(delta: number) {
  for (const entity of movingEntities) {
    entity.position.x += entity.velocity.x * delta
    entity.position.y += entity.velocity.y * delta
    entity.position.z += entity.velocity.z * delta
  }
}
```

```tsx
// src/systems/healthSystem.ts
import { world } from '../ecs/world'

const damageable = world.with('health')

export function healthSystem() {
  for (const entity of damageable) {
    if (entity.health.current <= 0) {
      world.remove(entity)
    }
  }
}
```

### The React Bridge: Rendering ECS Entities

Here's where miniplex's React integration shines. Use `@miniplex/react` to create a reactive component that renders entities:

```tsx
// src/ecs/react.ts
import { createReactAPI } from '@miniplex/react'
import { world } from './world'

export const ECS = createReactAPI(world)
```

Now use it in your R3F scene:

```tsx
// src/components/EnemyRenderer.tsx
import { ECS } from '../ecs/react'

const enemies = world.with('isEnemy', 'position', 'color', 'size')

export function EnemyRenderer() {
  return (
    <ECS.Entities in={enemies}>
      {(entity) => (
        <ECS.Entity entity={entity}>
          <mesh position={[entity.position.x, entity.position.y, entity.position.z]}>
            <boxGeometry args={[entity.size, entity.size, entity.size]} />
            <meshStandardMaterial color={entity.color} />
          </mesh>
        </ECS.Entity>
      )}
    </ECS.Entities>
  )
}
```

`<ECS.Entities>` reactively renders a component for each entity in the query. When entities are added or removed from the world, the components mount and unmount automatically. This is the bridge between ECS data and React rendering.

### Building an Enemy Spawner with ECS

```tsx
// src/systems/SpawnSystem.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { world } from '../ecs/world'
import { useGameStore } from '../stores/useGameStore'

export function SpawnSystem() {
  const timerRef = useRef(0)
  const spawnIntervalRef = useRef(2) // seconds between spawns

  useFrame((_, delta) => {
    const { gamePhase } = useGameStore.getState()
    if (gamePhase !== 'playing') return

    timerRef.current += delta

    if (timerRef.current >= spawnIntervalRef.current) {
      timerRef.current = 0

      // Spawn at random position on the edge of the arena
      const angle = Math.random() * Math.PI * 2
      const radius = 15
      const x = Math.cos(angle) * radius
      const z = Math.sin(angle) * radius

      world.add({
        position: { x, y: 0.5, z },
        velocity: { x: -x * 0.1, y: 0, z: -z * 0.1 }, // Move toward center
        health: { current: 30, max: 30 },
        isEnemy: true,
        color: '#ff4444',
        size: 1,
        ai: { behavior: 'chase' },
      })

      // Increase difficulty over time
      spawnIntervalRef.current = Math.max(0.5, spawnIntervalRef.current - 0.01)
    }
  })

  return null
}
```

### Syncing ECS Position to Three.js

For entities that move every frame, you need to sync their ECS position to the actual Three.js mesh. Use a ref on the mesh and update it in a system:

```tsx
// Bridge component that syncs ECS position to Three.js object
function ECSMesh({ entity }: { entity: GameEntity }) {
  const meshRef = useRef<Mesh>(null)

  useFrame(() => {
    if (!meshRef.current || !entity.position) return
    meshRef.current.position.set(
      entity.position.x,
      entity.position.y,
      entity.position.z
    )
  })

  return (
    <mesh ref={meshRef}>
      <boxGeometry args={[entity.size ?? 1, entity.size ?? 1, entity.size ?? 1]} />
      <meshStandardMaterial color={entity.color ?? '#ffffff'} />
    </mesh>
  )
}
```

---

## 10. ECS with bitECS

### When to Use bitECS

`bitECS` is a high-performance ECS library that uses typed arrays (ArrayBuffers) instead of JavaScript objects. This makes it significantly faster for large entity counts (thousands) because:

- Data is stored contiguously in memory
- No garbage collection pressure from object allocation
- SIMD-friendly data layouts
- Archetypal queries are extremely fast

The trade-off: components can only hold numeric data (no strings, no objects, no refs). This makes it harder to integrate with React and Three.js. Use bitECS when you have thousands of entities and performance matters more than ergonomics.

```bash
npm install bitecs
```

### Defining Components

In bitECS, components are defined as schemas of typed arrays:

```tsx
// src/ecs/bitecs-world.ts
import {
  createWorld,
  defineComponent,
  defineQuery,
  addEntity,
  addComponent,
  removeEntity,
  Types,
} from 'bitecs'

// Components are typed array schemas
const Position = defineComponent({
  x: Types.f32,
  y: Types.f32,
  z: Types.f32,
})

const Velocity = defineComponent({
  x: Types.f32,
  y: Types.f32,
  z: Types.f32,
})

const Health = defineComponent({
  current: Types.f32,
  max: Types.f32,
})

// Tags are components with no data
const Enemy = defineComponent()
const Projectile = defineComponent()
const Player = defineComponent()

// Create the world
const world = createWorld()
```

### Creating Entities

```tsx
// Create an entity (just returns a number ID)
const eid = addEntity(world)

// Add components and set their values
addComponent(world, Position, eid)
Position.x[eid] = 5
Position.y[eid] = 0
Position.z[eid] = -10

addComponent(world, Velocity, eid)
Velocity.x[eid] = 0
Velocity.y[eid] = 0
Velocity.z[eid] = 1

addComponent(world, Health, eid)
Health.current[eid] = 30
Health.max[eid] = 30

addComponent(world, Enemy, eid)
```

Notice the data access pattern: `Position.x[eid]`. This is an indexed lookup into a Float32Array. Every entity's X position is stored contiguously: `Position.x[0]`, `Position.x[1]`, `Position.x[2]`, etc. When a system iterates over all positions, it's reading sequential memory. This is called Structure of Arrays (SoA) and it's why bitECS is fast.

### Defining Queries

```tsx
// Query: all entities with Position and Velocity
const movingQuery = defineQuery([Position, Velocity])

// Query: all enemies
const enemyQuery = defineQuery([Enemy, Position, Health])

// Query: all projectiles
const projectileQuery = defineQuery([Projectile, Position, Velocity])
```

### Building Systems

```tsx
function movementSystem(world: ReturnType<typeof createWorld>, delta: number) {
  const entities = movingQuery(world)

  for (let i = 0; i < entities.length; i++) {
    const eid = entities[i]
    Position.x[eid] += Velocity.x[eid] * delta
    Position.y[eid] += Velocity.y[eid] * delta
    Position.z[eid] += Velocity.z[eid] * delta
  }

  return world
}

function healthSystem(world: ReturnType<typeof createWorld>) {
  const entities = enemyQuery(world)

  for (let i = 0; i < entities.length; i++) {
    const eid = entities[i]
    if (Health.current[eid] <= 0) {
      removeEntity(world, eid)
    }
  }

  return world
}
```

### The Archetype Query Pattern

bitECS uses archetypes under the hood. An archetype is a unique combination of components. All entities with the same set of components are stored together. This means queries are essentially free — they just return the list of entities in a matching archetype.

```tsx
// These queries are O(1) lookups, not O(n) scans
const withPosVel = defineQuery([Position, Velocity])
const withPosVelHealth = defineQuery([Position, Velocity, Health])

// Enter/exit queries detect when entities gain/lose components
const enterEnemyQuery = enterQuery(enemyQuery)
const exitEnemyQuery = exitQuery(enemyQuery)

function spawnEffectSystem(world: ReturnType<typeof createWorld>) {
  // Entities that just became enemies (just had Enemy component added)
  const entered = enterEnemyQuery(world)
  for (const eid of entered) {
    // Spawn particle effect at their position
    triggerSpawnEffect(Position.x[eid], Position.y[eid], Position.z[eid])
  }

  // Entities that just stopped being enemies (removed or Enemy component removed)
  const exited = exitEnemyQuery(world)
  for (const eid of exited) {
    triggerDeathEffect(Position.x[eid], Position.y[eid], Position.z[eid])
  }

  return world
}
```

### bitECS vs miniplex

| Feature | miniplex | bitECS |
|---------|----------|--------|
| Data model | JS objects | Typed arrays (SoA) |
| Component values | Any JS value (strings, objects, refs) | Numbers only (f32, i32, ui8, etc.) |
| React integration | First-class (`@miniplex/react`) | Manual — you build the bridge |
| Performance | Good (hundreds of entities) | Excellent (thousands of entities) |
| Ergonomics | High — feels like normal JS/React | Lower — indexed array access, numeric-only |
| Three.js bridge | Easy — store refs directly on entities | Manual — maintain a separate Map<eid, Object3D> |
| Best for | R3F games with <1000 entities | Performance-critical simulations, particle-heavy games |

For most R3F games, **start with miniplex**. Switch to bitECS if profiling shows entity processing is your bottleneck — which likely won't happen until you have thousands of active entities.

### Bridging bitECS to Three.js

Since bitECS entities can't hold object references, you need a separate lookup table:

```tsx
// Mapping from bitECS entity ID to Three.js Object3D
const entityMeshMap = new Map<number, THREE.Object3D>()

function RenderBridge() {
  useFrame(() => {
    const entities = movingQuery(world)
    for (let i = 0; i < entities.length; i++) {
      const eid = entities[i]
      const mesh = entityMeshMap.get(eid)
      if (mesh) {
        mesh.position.set(
          Position.x[eid],
          Position.y[eid],
          Position.z[eid]
        )
      }
    }
  })

  return null
}
```

---

## 11. Event Systems

### The Coupling Problem

Without events, your systems talk to each other directly:

```tsx
// In your damage system
function applyDamage(entity: GameEntity, amount: number) {
  entity.health.current -= amount

  // Now we need to:
  playSoundEffect('hit')          // Sound system
  spawnParticles(entity.position) // Particle system
  shakeCamera(0.3)                // Camera system
  updateHUD()                     // UI system
  checkAchievements()             // Achievement system

  if (entity.health.current <= 0) {
    playSoundEffect('death')
    spawnExplosion(entity.position)
    addScore(100)
    // ... even more systems to notify
  }
}
```

This function knows about *everything*. Add a new system? Modify this function. Remove a system? Modify this function. Every feature addition requires touching existing code. This is tight coupling, and it's how codebases become unmaintainable.

### Decoupling with Events

An event system lets you publish events without knowing who's listening:

```tsx
// Damage system just publishes what happened
function applyDamage(entity: GameEntity, amount: number) {
  entity.health.current -= amount
  events.emit('entity-damaged', { entity, amount })

  if (entity.health.current <= 0) {
    events.emit('entity-killed', { entity })
  }
}

// Other systems subscribe to what they care about
events.on('entity-damaged', ({ entity }) => {
  playSoundEffect('hit')
  spawnParticles(entity.position)
  shakeCamera(0.3)
})

events.on('entity-killed', ({ entity }) => {
  playSoundEffect('death')
  spawnExplosion(entity.position)
  addScore(100)
})
```

Now the damage system has *no idea* that sound, particles, or score exist. You can add a new system (say, screen recording highlights) by adding a new subscriber. You never modify the damage system again.

### A Simple Pub/Sub Implementation

You don't need a library. A typed event emitter is ~30 lines:

```tsx
// src/systems/events.ts
type EventMap = {
  'entity-damaged': { entityId: number; amount: number; position: [number, number, number] }
  'entity-killed': { entityId: number; position: [number, number, number]; points: number }
  'player-hit': { amount: number; newHealth: number }
  'score-changed': { score: number; delta: number }
  'phase-changed': { from: string; to: string }
  'projectile-fired': { position: [number, number, number]; direction: [number, number, number] }
  'pickup-collected': { type: 'health' | 'ammo' | 'score'; position: [number, number, number] }
}

type EventCallback<T> = (data: T) => void

class GameEvents {
  private listeners = new Map<string, Set<EventCallback<any>>>()

  on<K extends keyof EventMap>(event: K, callback: EventCallback<EventMap[K]>) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set())
    }
    this.listeners.get(event)!.add(callback)

    // Return unsubscribe function
    return () => {
      this.listeners.get(event)?.delete(callback)
    }
  }

  emit<K extends keyof EventMap>(event: K, data: EventMap[K]) {
    this.listeners.get(event)?.forEach((callback) => callback(data))
  }

  off<K extends keyof EventMap>(event: K, callback: EventCallback<EventMap[K]>) {
    this.listeners.get(event)?.delete(callback)
  }

  clear() {
    this.listeners.clear()
  }
}

export const gameEvents = new GameEvents()
```

Fully typed. Autocomplete on event names and data shapes. No library needed.

### Using mitt or eventemitter3

If you prefer a battle-tested library:

```bash
npm install mitt
# or
npm install eventemitter3
```

With mitt:

```tsx
import mitt from 'mitt'

type Events = {
  'entity-killed': { entityId: number; points: number }
  'player-hit': { amount: number }
}

export const gameEvents = mitt<Events>()

// Subscribe
gameEvents.on('entity-killed', ({ entityId, points }) => {
  console.log(`Entity ${entityId} killed for ${points} points`)
})

// Emit
gameEvents.emit('entity-killed', { entityId: 42, points: 100 })

// Unsubscribe all listeners for an event
gameEvents.off('entity-killed')
```

### Wiring Events to React Components

Use `useEffect` to subscribe and unsubscribe cleanly:

```tsx
function SoundSystem() {
  useEffect(() => {
    const unsubs = [
      gameEvents.on('entity-damaged', ({ position }) => {
        playSound('hit', { position, volume: 0.7 })
      }),
      gameEvents.on('entity-killed', ({ position }) => {
        playSound('explosion', { position, volume: 1.0 })
      }),
      gameEvents.on('pickup-collected', ({ type }) => {
        playSound(`pickup-${type}`, { volume: 0.5 })
      }),
    ]

    return () => unsubs.forEach((unsub) => unsub())
  }, [])

  return null
}
```

```tsx
function CameraShakeSystem() {
  const shakeRef = useRef(0)

  useEffect(() => {
    const unsub = gameEvents.on('entity-damaged', () => {
      shakeRef.current = 0.3 // shake intensity
    })
    return unsub
  }, [])

  useFrame((state, delta) => {
    if (shakeRef.current > 0) {
      shakeRef.current -= delta
      const intensity = shakeRef.current * 0.1
      state.camera.position.x += (Math.random() - 0.5) * intensity
      state.camera.position.y += (Math.random() - 0.5) * intensity
    }
  })

  return null
}
```

### Events vs Zustand subscribeWithSelector

Both let you react to changes. Use them for different things:

- **Zustand subscribe**: React to *state changes*. "When health changes from above 25 to below 25, play warning sound."
- **Events**: React to *things that happened*. "An entity was killed at position [5, 0, 3] for 100 points."

State changes are about values transitioning. Events are about discrete occurrences. Sometimes they overlap — use whichever feels more natural for the specific case.

---

## 12. Project Organization

### File Structure for a Real R3F Game

Once your game has stores, systems, ECS, events, multiple scenes, and a dozen components, you need a file structure that scales. Here's a proven layout:

```
src/
├── main.tsx                    # Entry point
├── App.tsx                     # Canvas + top-level layout
├── index.css                   # Global styles
│
├── stores/                     # Zustand stores
│   ├── useGameStore.ts         # Game phase, score, health
│   ├── useClockStore.ts        # Game clock, time scale
│   └── useSettingsStore.ts     # Audio volume, graphics options
│
├── systems/                    # Game systems (logic, no rendering)
│   ├── ClockTicker.tsx         # Ticks the game clock each frame
│   ├── FixedTimestep.tsx       # Fixed timestep accumulator
│   ├── SpawnSystem.tsx         # Enemy/pickup spawning
│   ├── CollisionSystem.tsx     # Collision detection + response
│   └── events.ts               # Event bus definition
│
├── ecs/                        # ECS setup (if using)
│   ├── world.ts                # World + component definitions
│   └── react.ts                # React bindings (miniplex)
│
├── components/                 # Reusable 3D components
│   ├── Player.tsx
│   ├── Enemy.tsx
│   ├── Projectile.tsx
│   ├── Arena.tsx
│   ├── Pickup.tsx
│   └── effects/
│       ├── Explosion.tsx
│       └── HitFlash.tsx
│
├── scenes/                     # Top-level scene compositions
│   ├── TitleScene.tsx          # 3D content for title screen
│   ├── GameplayScene.tsx       # The main game scene
│   └── SceneManager.tsx        # Conditional rendering of scenes
│
├── ui/                         # DOM overlays (HTML/CSS)
│   ├── TitleScreen.tsx         # Title menu buttons
│   ├── HUD.tsx                 # Score, health, ammo display
│   ├── PauseMenu.tsx           # Pause overlay
│   ├── GameOverScreen.tsx      # Game over + restart
│   └── Overlay.tsx             # Shared overlay wrapper
│
├── hooks/                      # Custom hooks
│   ├── useKeyboard.ts          # Keyboard input
│   └── useGameClock.ts         # Game clock access helpers
│
└── utils/                      # Pure utility functions
    ├── math.ts                 # Clamp, lerp, random range
    └── constants.ts            # Game balance numbers
```

### Key Principles

**stores/ — State lives here, not in components.** Components read from stores. Actions live on stores. If you need game state somewhere, import the store. No prop drilling.

**systems/ — Logic without rendering.** Systems are components that return `null`. They run `useFrame` callbacks, subscribe to events, manage spawning. They have no visual output. This separation makes it easy to add/remove game behavior without touching visuals.

**components/ — Visuals without logic.** Components render 3D objects. They might read state (via refs and `getState()`), but they don't own game logic. An `Enemy` component renders an enemy mesh and syncs its position. It doesn't decide when to spawn or what to do on death.

**scenes/ — Composition.** Scenes compose components and systems into complete game phases. `GameplayScene` puts together the arena, player, enemies, systems, and HUD.

**ui/ — DOM layer.** Everything here is normal React (divs, buttons, CSS). It sits on top of the Canvas as fixed-position overlays. Keep 3D and DOM cleanly separated.

### Barrel Exports

Use `index.ts` barrel files to keep imports clean:

```tsx
// src/components/index.ts
export { Player } from './Player'
export { Enemy } from './Enemy'
export { Projectile } from './Projectile'
export { Arena } from './Arena'
```

```tsx
// Importing from elsewhere
import { Player, Enemy, Arena } from '../components'
```

### Keeping Renders Lean

A common mistake is putting game logic inside rendering components. This makes components hard to test, hard to reuse, and easy to break.

```tsx
// WRONG — game logic mixed into the render component
function Enemy({ id }: { id: number }) {
  const meshRef = useRef<Mesh>(null)
  const healthRef = useRef(30)
  const aiStateRef = useRef<'idle' | 'chase' | 'attack'>('idle')

  useFrame((_, delta) => {
    // 50 lines of AI logic
    // 30 lines of movement
    // 20 lines of attack behavior
    // 10 lines of health checking
    // This component is now 150+ lines and does everything
  })

  return <mesh ref={meshRef}>{/* ... */}</mesh>
}

// RIGHT — component only renders, systems handle logic
function Enemy({ position, color, size }: EnemyProps) {
  const meshRef = useRef<Mesh>(null)

  useFrame(() => {
    // Only sync visual state
    if (!meshRef.current) return
    meshRef.current.position.set(position.x, position.y, position.z)
  })

  return (
    <mesh ref={meshRef}>
      <boxGeometry args={[size, size, size]} />
      <meshStandardMaterial color={color} />
    </mesh>
  )
}
```

The enemy's AI, movement, and health are handled by systems that process all enemies together. The `Enemy` component just renders.

---

## Code Walkthrough: Building the Structured Arena Game

Time to build a complete game with all the architecture patterns from this module. This is a top-down arena game where enemies spawn from the edges, the player dodges or shoots, and the game tracks score, health, and phase transitions.

### Step 1: Project Setup

```bash
npm create vite@latest arena-game -- --template react-ts
cd arena-game
npm install three @react-three/fiber @react-three/drei zustand
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
  background: #111;
  font-family: 'Segoe UI', system-ui, sans-serif;
}

* {
  box-sizing: border-box;
}
```

### Step 3: The Game Store

```tsx
// src/stores/useGameStore.ts
import { create } from 'zustand'
import { subscribeWithSelector } from 'zustand/middleware'

export type GamePhase = 'menu' | 'playing' | 'paused' | 'gameOver'

interface GameState {
  gamePhase: GamePhase
  score: number
  health: number
  maxHealth: number
  highScore: number
  enemiesKilled: number

  // Actions
  startGame: () => void
  pauseGame: () => void
  resumeGame: () => void
  endGame: () => void
  addScore: (points: number) => void
  takeDamage: (amount: number) => void
  killEnemy: () => void
}

export const useGameStore = create<GameState>()(
  subscribeWithSelector((set, get) => ({
    gamePhase: 'menu',
    score: 0,
    health: 100,
    maxHealth: 100,
    highScore: 0,
    enemiesKilled: 0,

    startGame: () =>
      set({
        gamePhase: 'playing',
        score: 0,
        health: 100,
        enemiesKilled: 0,
      }),

    pauseGame: () => {
      if (get().gamePhase === 'playing') {
        set({ gamePhase: 'paused' })
      }
    },

    resumeGame: () => {
      if (get().gamePhase === 'paused') {
        set({ gamePhase: 'playing' })
      }
    },

    endGame: () => {
      const { score, highScore } = get()
      set({
        gamePhase: 'gameOver',
        highScore: Math.max(score, highScore),
      })
    },

    addScore: (points) =>
      set((state) => ({ score: state.score + points })),

    takeDamage: (amount) => {
      const newHealth = Math.max(0, get().health - amount)
      set({ health: newHealth })
      if (newHealth <= 0) {
        get().endGame()
      }
    },

    killEnemy: () =>
      set((state) => ({
        enemiesKilled: state.enemiesKilled + 1,
      })),
  }))
)
```

### Step 4: The Game Clock Store

```tsx
// src/stores/useClockStore.ts
import { create } from 'zustand'

interface ClockState {
  elapsed: number
  timeScale: number
  isPaused: boolean

  pause: () => void
  resume: () => void
  setTimeScale: (scale: number) => void
  reset: () => void
  tick: (rawDelta: number) => number // Returns scaled delta
}

export const useClockStore = create<ClockState>((set, get) => ({
  elapsed: 0,
  timeScale: 1.0,
  isPaused: false,

  pause: () => set({ isPaused: true }),
  resume: () => set({ isPaused: false }),
  setTimeScale: (scale) => set({ timeScale: Math.max(0, scale) }),
  reset: () => set({ elapsed: 0, timeScale: 1.0, isPaused: false }),

  tick: (rawDelta) => {
    const { isPaused, timeScale, elapsed } = get()
    if (isPaused) return 0

    const scaledDelta = rawDelta * timeScale
    set({ elapsed: elapsed + scaledDelta })
    return scaledDelta
  },
}))
```

### Step 5: The Event System

```tsx
// src/systems/events.ts
type EventMap = {
  'enemy-killed': { position: [number, number, number]; points: number }
  'enemy-reached-center': { damage: number }
  'player-damaged': { amount: number; newHealth: number }
  'projectile-fired': { position: [number, number, number] }
  'game-started': undefined
  'game-paused': undefined
  'game-resumed': undefined
  'game-over': { finalScore: number }
}

type EventCallback<T> = T extends undefined ? () => void : (data: T) => void

class GameEvents {
  private listeners = new Map<string, Set<EventCallback<any>>>()

  on<K extends keyof EventMap>(event: K, callback: EventCallback<EventMap[K]>) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set())
    }
    this.listeners.get(event)!.add(callback)
    return () => {
      this.listeners.get(event)?.delete(callback)
    }
  }

  emit<K extends keyof EventMap>(
    event: K,
    ...args: EventMap[K] extends undefined ? [] : [EventMap[K]]
  ) {
    this.listeners.get(event)?.forEach((cb) => cb(args[0]))
  }

  clear() {
    this.listeners.clear()
  }
}

export const gameEvents = new GameEvents()
```

### Step 6: The Clock Ticker System

```tsx
// src/systems/ClockTicker.tsx
import { useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { useClockStore } from '../stores/useClockStore'
import { useGameStore } from '../stores/useGameStore'

export function ClockTicker() {
  // Wire game phase to clock
  useEffect(() => {
    const unsub = useGameStore.subscribe(
      (state) => state.gamePhase,
      (phase) => {
        const clock = useClockStore.getState()
        if (phase === 'paused') clock.pause()
        else if (phase === 'playing') clock.resume()
        else if (phase === 'menu') clock.reset()
      }
    )
    return unsub
  }, [])

  useFrame((_, rawDelta) => {
    useClockStore.getState().tick(rawDelta)
  })

  return null
}
```

### Step 7: Enemy Data and Spawner

```tsx
// src/systems/useEnemies.ts
import { useRef, useCallback } from 'react'
import { useFrame } from '@react-three/fiber'
import { useGameStore } from '../stores/useGameStore'
import { useClockStore } from '../stores/useClockStore'
import { gameEvents } from './events'

export interface EnemyData {
  id: number
  position: [number, number, number]
  velocity: [number, number, number]
  health: number
  speed: number
}

let nextEnemyId = 0

export function useEnemies() {
  const enemiesRef = useRef<EnemyData[]>([])
  const spawnTimerRef = useRef(0)
  const spawnInterval = useRef(2.0)

  const spawnEnemy = useCallback(() => {
    const angle = Math.random() * Math.PI * 2
    const radius = 18
    const x = Math.cos(angle) * radius
    const z = Math.sin(angle) * radius

    // Velocity points toward center with some randomness
    const speed = 2 + Math.random() * 2
    const dirX = -x / radius
    const dirZ = -z / radius

    const enemy: EnemyData = {
      id: nextEnemyId++,
      position: [x, 0.5, z],
      velocity: [dirX * speed, 0, dirZ * speed],
      health: 30,
      speed,
    }

    enemiesRef.current.push(enemy)
  }, [])

  const removeEnemy = useCallback((id: number) => {
    enemiesRef.current = enemiesRef.current.filter((e) => e.id !== id)
  }, [])

  const damageEnemy = useCallback((id: number, amount: number) => {
    const enemy = enemiesRef.current.find((e) => e.id === id)
    if (!enemy) return

    enemy.health -= amount
    if (enemy.health <= 0) {
      const pos: [number, number, number] = [...enemy.position]
      removeEnemy(id)
      useGameStore.getState().addScore(100)
      useGameStore.getState().killEnemy()
      gameEvents.emit('enemy-killed', { position: pos, points: 100 })
    }
  }, [removeEnemy])

  useFrame((_, rawDelta) => {
    const { gamePhase } = useGameStore.getState()
    if (gamePhase !== 'playing') return

    const { timeScale } = useClockStore.getState()
    const delta = rawDelta * timeScale

    // Spawn timer
    spawnTimerRef.current += delta
    if (spawnTimerRef.current >= spawnInterval.current) {
      spawnTimerRef.current = 0
      spawnEnemy()
      // Gradually increase spawn rate
      spawnInterval.current = Math.max(0.3, spawnInterval.current - 0.02)
    }

    // Update positions
    for (const enemy of enemiesRef.current) {
      enemy.position[0] += enemy.velocity[0] * delta
      enemy.position[1] += enemy.velocity[1] * delta
      enemy.position[2] += enemy.velocity[2] * delta

      // If enemy reaches center, damage player and remove
      const distFromCenter = Math.sqrt(
        enemy.position[0] ** 2 + enemy.position[2] ** 2
      )
      if (distFromCenter < 1.5) {
        const damage = 10
        useGameStore.getState().takeDamage(damage)
        gameEvents.emit('enemy-reached-center', { damage })
        removeEnemy(enemy.id)
      }
    }
  })

  return { enemiesRef, damageEnemy, spawnEnemy, removeEnemy }
}
```

### Step 8: Projectile System

```tsx
// src/systems/useProjectiles.ts
import { useRef, useCallback } from 'react'
import { useFrame } from '@react-three/fiber'
import { useGameStore } from '../stores/useGameStore'
import { useClockStore } from '../stores/useClockStore'
import type { EnemyData } from './useEnemies'

export interface ProjectileData {
  id: number
  position: [number, number, number]
  velocity: [number, number, number]
  lifetime: number
}

let nextProjectileId = 0

export function useProjectiles(
  enemiesRef: React.MutableRefObject<EnemyData[]>,
  damageEnemy: (id: number, amount: number) => void
) {
  const projectilesRef = useRef<ProjectileData[]>([])

  const fireProjectile = useCallback(
    (from: [number, number, number], direction: [number, number, number]) => {
      const speed = 25
      const proj: ProjectileData = {
        id: nextProjectileId++,
        position: [...from],
        velocity: [direction[0] * speed, direction[1] * speed, direction[2] * speed],
        lifetime: 2.0,
      }
      projectilesRef.current.push(proj)
    },
    []
  )

  useFrame((_, rawDelta) => {
    const { gamePhase } = useGameStore.getState()
    if (gamePhase !== 'playing') return

    const { timeScale } = useClockStore.getState()
    const delta = rawDelta * timeScale

    const toRemove: number[] = []

    for (const proj of projectilesRef.current) {
      // Move
      proj.position[0] += proj.velocity[0] * delta
      proj.position[1] += proj.velocity[1] * delta
      proj.position[2] += proj.velocity[2] * delta

      // Decrease lifetime
      proj.lifetime -= delta
      if (proj.lifetime <= 0) {
        toRemove.push(proj.id)
        continue
      }

      // Check collision with enemies
      for (const enemy of enemiesRef.current) {
        const dx = proj.position[0] - enemy.position[0]
        const dz = proj.position[2] - enemy.position[2]
        const dist = Math.sqrt(dx * dx + dz * dz)

        if (dist < 1.0) {
          damageEnemy(enemy.id, 30)
          toRemove.push(proj.id)
          break
        }
      }
    }

    // Remove expired/hit projectiles
    if (toRemove.length > 0) {
      projectilesRef.current = projectilesRef.current.filter(
        (p) => !toRemove.includes(p.id)
      )
    }
  })

  return { projectilesRef, fireProjectile }
}
```

### Step 9: The Player Component

```tsx
// src/components/Player.tsx
import { useRef, useEffect, useCallback } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import type { Mesh, Raycaster } from 'three'
import * as THREE from 'three'
import { useGameStore } from '../stores/useGameStore'
import { useClockStore } from '../stores/useClockStore'

interface PlayerProps {
  onFire: (from: [number, number, number], direction: [number, number, number]) => void
}

export function Player({ onFire }: PlayerProps) {
  const meshRef = useRef<Mesh>(null)
  const keysRef = useRef<Set<string>>(new Set())
  const fireTimerRef = useRef(0)
  const { camera, pointer } = useThree()
  const raycaster = useRef(new THREE.Raycaster())
  const groundPlane = useRef(new THREE.Plane(new THREE.Vector3(0, 1, 0), 0))

  // Keyboard input
  useEffect(() => {
    const handleDown = (e: KeyboardEvent) => {
      keysRef.current.add(e.key.toLowerCase())

      // Pause toggle
      if (e.key === 'Escape') {
        const { gamePhase, pauseGame, resumeGame } = useGameStore.getState()
        if (gamePhase === 'playing') pauseGame()
        else if (gamePhase === 'paused') resumeGame()
      }
    }
    const handleUp = (e: KeyboardEvent) => {
      keysRef.current.delete(e.key.toLowerCase())
    }

    window.addEventListener('keydown', handleDown)
    window.addEventListener('keyup', handleUp)
    return () => {
      window.removeEventListener('keydown', handleDown)
      window.removeEventListener('keyup', handleUp)
    }
  }, [])

  // Click to fire
  const handleClick = useCallback(() => {
    const { gamePhase } = useGameStore.getState()
    if (gamePhase !== 'playing' || !meshRef.current) return

    // Raycast from mouse to ground plane to get aim direction
    raycaster.current.setFromCamera(
      new THREE.Vector2(pointer.x, pointer.y),
      camera
    )
    const target = new THREE.Vector3()
    raycaster.current.ray.intersectPlane(groundPlane.current, target)

    if (target) {
      const pos = meshRef.current.position
      const dir = new THREE.Vector3(
        target.x - pos.x,
        0,
        target.z - pos.z
      ).normalize()

      onFire(
        [pos.x, pos.y, pos.z],
        [dir.x, dir.y, dir.z]
      )
    }
  }, [camera, pointer, onFire])

  useEffect(() => {
    window.addEventListener('click', handleClick)
    return () => window.removeEventListener('click', handleClick)
  }, [handleClick])

  useFrame((_, rawDelta) => {
    if (!meshRef.current) return
    const { gamePhase } = useGameStore.getState()
    if (gamePhase !== 'playing') return

    const { timeScale } = useClockStore.getState()
    const delta = rawDelta * timeScale

    // WASD movement
    const speed = 8
    const keys = keysRef.current
    const moveDir = new THREE.Vector3(0, 0, 0)

    if (keys.has('w') || keys.has('arrowup')) moveDir.z -= 1
    if (keys.has('s') || keys.has('arrowdown')) moveDir.z += 1
    if (keys.has('a') || keys.has('arrowleft')) moveDir.x -= 1
    if (keys.has('d') || keys.has('arrowright')) moveDir.x += 1

    if (moveDir.length() > 0) {
      moveDir.normalize()
      meshRef.current.position.x += moveDir.x * speed * delta
      meshRef.current.position.z += moveDir.z * speed * delta

      // Clamp to arena bounds
      const bound = 14
      meshRef.current.position.x = THREE.MathUtils.clamp(
        meshRef.current.position.x, -bound, bound
      )
      meshRef.current.position.z = THREE.MathUtils.clamp(
        meshRef.current.position.z, -bound, bound
      )
    }
  })

  return (
    <mesh ref={meshRef} position={[0, 0.5, 0]}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="#44aaff" emissive="#2266aa" emissiveIntensity={0.5} />
    </mesh>
  )
}
```

### Step 10: Enemy and Projectile Renderers

```tsx
// src/components/EnemyRenderer.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { InstancedMesh } from 'three'
import * as THREE from 'three'
import type { EnemyData } from '../systems/useEnemies'

interface EnemyRendererProps {
  enemiesRef: React.MutableRefObject<EnemyData[]>
}

const tempObject = new THREE.Object3D()
const MAX_ENEMIES = 200

export function EnemyRenderer({ enemiesRef }: EnemyRendererProps) {
  const meshRef = useRef<InstancedMesh>(null)

  useFrame(() => {
    if (!meshRef.current) return

    const enemies = enemiesRef.current

    for (let i = 0; i < MAX_ENEMIES; i++) {
      if (i < enemies.length) {
        tempObject.position.set(
          enemies[i].position[0],
          enemies[i].position[1],
          enemies[i].position[2]
        )
        tempObject.scale.setScalar(1)
      } else {
        // Hide unused instances
        tempObject.scale.setScalar(0)
      }
      tempObject.updateMatrix()
      meshRef.current.setMatrixAt(i, tempObject.matrix)
    }

    meshRef.current.instanceMatrix.needsUpdate = true
  })

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, MAX_ENEMIES]}>
      <boxGeometry args={[0.8, 0.8, 0.8]} />
      <meshStandardMaterial color="#ff4444" emissive="#aa0000" emissiveIntensity={0.3} />
    </instancedMesh>
  )
}
```

```tsx
// src/components/ProjectileRenderer.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { InstancedMesh } from 'three'
import * as THREE from 'three'
import type { ProjectileData } from '../systems/useProjectiles'

interface ProjectileRendererProps {
  projectilesRef: React.MutableRefObject<ProjectileData[]>
}

const tempObject = new THREE.Object3D()
const MAX_PROJECTILES = 100

export function ProjectileRenderer({ projectilesRef }: ProjectileRendererProps) {
  const meshRef = useRef<InstancedMesh>(null)

  useFrame(() => {
    if (!meshRef.current) return

    const projectiles = projectilesRef.current

    for (let i = 0; i < MAX_PROJECTILES; i++) {
      if (i < projectiles.length) {
        tempObject.position.set(
          projectiles[i].position[0],
          projectiles[i].position[1],
          projectiles[i].position[2]
        )
        tempObject.scale.setScalar(1)
      } else {
        tempObject.scale.setScalar(0)
      }
      tempObject.updateMatrix()
      meshRef.current.setMatrixAt(i, tempObject.matrix)
    }

    meshRef.current.instanceMatrix.needsUpdate = true
  })

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, MAX_PROJECTILES]}>
      <sphereGeometry args={[0.15, 8, 8]} />
      <meshBasicMaterial color="#ffff44" toneMapped={false} />
    </instancedMesh>
  )
}
```

### Step 11: The Arena

```tsx
// src/components/Arena.tsx
import { Grid } from '@react-three/drei'

export function Arena() {
  return (
    <group>
      {/* Ground plane */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.01, 0]} receiveShadow>
        <planeGeometry args={[32, 32]} />
        <meshStandardMaterial color="#1a1a2e" />
      </mesh>

      {/* Grid for visual reference */}
      <Grid
        position={[0, 0, 0]}
        args={[32, 32]}
        cellSize={1}
        cellThickness={0.5}
        cellColor="#2a2a4e"
        sectionSize={4}
        sectionThickness={1}
        sectionColor="#3a3a6e"
        fadeDistance={40}
        fadeStrength={1}
        infiniteGrid={false}
      />

      {/* Arena boundary markers — four corner pillars */}
      {[
        [-15, 0, -15],
        [15, 0, -15],
        [-15, 0, 15],
        [15, 0, 15],
      ].map((pos, i) => (
        <mesh key={i} position={pos as [number, number, number]}>
          <cylinderGeometry args={[0.3, 0.3, 3, 8]} />
          <meshStandardMaterial
            color="#6644aa"
            emissive="#4422aa"
            emissiveIntensity={0.5}
          />
        </mesh>
      ))}
    </group>
  )
}
```

### Step 12: DOM Overlays

```tsx
// src/ui/Overlay.tsx
import { ReactNode, CSSProperties } from 'react'

interface OverlayProps {
  children: ReactNode
  background?: string
  style?: CSSProperties
}

export function Overlay({
  children,
  background = 'rgba(0, 0, 0, 0.75)',
  style,
}: OverlayProps) {
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        background,
        zIndex: 10,
        color: 'white',
        ...style,
      }}
    >
      {children}
    </div>
  )
}
```

```tsx
// src/ui/TitleScreen.tsx
import { useGameStore } from '../stores/useGameStore'
import { Overlay } from './Overlay'

export function TitleScreen() {
  const startGame = useGameStore((s) => s.startGame)
  const highScore = useGameStore((s) => s.highScore)

  return (
    <Overlay>
      <h1 style={{ fontSize: '4rem', margin: '0 0 0.5rem 0', letterSpacing: '0.1em' }}>
        ARENA
      </h1>
      <p style={{ fontSize: '1.2rem', color: '#aaa', margin: '0 0 2rem 0' }}>
        Survive the swarm
      </p>

      <button
        onClick={startGame}
        style={{
          padding: '1rem 3rem',
          fontSize: '1.3rem',
          background: '#4444ff',
          color: 'white',
          border: 'none',
          borderRadius: '8px',
          cursor: 'pointer',
          letterSpacing: '0.05em',
          transition: 'background 0.2s',
        }}
        onMouseEnter={(e) => (e.currentTarget.style.background = '#5555ff')}
        onMouseLeave={(e) => (e.currentTarget.style.background = '#4444ff')}
      >
        START GAME
      </button>

      {highScore > 0 && (
        <p style={{ marginTop: '1.5rem', color: '#888' }}>
          High Score: {highScore}
        </p>
      )}

      <div style={{ marginTop: '3rem', color: '#666', fontSize: '0.9rem' }}>
        <p>WASD to move / Click to shoot / ESC to pause</p>
      </div>
    </Overlay>
  )
}
```

```tsx
// src/ui/HUD.tsx
import { useGameStore } from '../stores/useGameStore'

export function HUD() {
  const score = useGameStore((s) => s.score)
  const health = useGameStore((s) => s.health)
  const maxHealth = useGameStore((s) => s.maxHealth)

  const healthPercent = (health / maxHealth) * 100
  const healthColor =
    healthPercent > 60 ? '#44ff44' : healthPercent > 25 ? '#ffaa00' : '#ff4444'

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        padding: '1rem 2rem',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        zIndex: 5,
        pointerEvents: 'none',
      }}
    >
      {/* Score */}
      <div style={{ color: 'white', fontSize: '1.5rem', fontWeight: 'bold' }}>
        SCORE: {score}
      </div>

      {/* Health bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        <span style={{ color: '#aaa', fontSize: '0.9rem' }}>HP</span>
        <div
          style={{
            width: '200px',
            height: '20px',
            background: '#333',
            borderRadius: '10px',
            overflow: 'hidden',
          }}
        >
          <div
            style={{
              width: `${healthPercent}%`,
              height: '100%',
              background: healthColor,
              borderRadius: '10px',
              transition: 'width 0.2s, background 0.3s',
            }}
          />
        </div>
        <span style={{ color: '#aaa', fontSize: '0.9rem', minWidth: '3rem' }}>
          {health}
        </span>
      </div>
    </div>
  )
}
```

```tsx
// src/ui/PauseMenu.tsx
import { useGameStore } from '../stores/useGameStore'
import { Overlay } from './Overlay'

export function PauseMenu() {
  const resumeGame = useGameStore((s) => s.resumeGame)
  const resetGame = useGameStore((s) => s.resetGame)
  const score = useGameStore((s) => s.score)

  const buttonStyle = {
    padding: '0.75rem 2.5rem',
    fontSize: '1.1rem',
    background: 'transparent',
    color: 'white',
    border: '2px solid #555',
    borderRadius: '8px',
    cursor: 'pointer',
    width: '220px',
    transition: 'border-color 0.2s',
  }

  return (
    <Overlay>
      <h2 style={{ fontSize: '2.5rem', margin: '0 0 0.5rem 0' }}>PAUSED</h2>
      <p style={{ color: '#888', margin: '0 0 2rem 0' }}>Score: {score}</p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        <button
          onClick={resumeGame}
          style={{ ...buttonStyle, borderColor: '#4444ff' }}
          onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#6666ff')}
          onMouseLeave={(e) => (e.currentTarget.style.borderColor = '#4444ff')}
        >
          RESUME
        </button>
        <button
          onClick={resetGame}
          style={buttonStyle}
          onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#888')}
          onMouseLeave={(e) => (e.currentTarget.style.borderColor = '#555')}
        >
          QUIT TO MENU
        </button>
      </div>
    </Overlay>
  )
}
```

```tsx
// src/ui/GameOverScreen.tsx
import { useGameStore } from '../stores/useGameStore'
import { Overlay } from './Overlay'

export function GameOverScreen() {
  const score = useGameStore((s) => s.score)
  const highScore = useGameStore((s) => s.highScore)
  const enemiesKilled = useGameStore((s) => s.enemiesKilled)
  const startGame = useGameStore((s) => s.startGame)
  const resetGame = useGameStore((s) => s.resetGame)

  const isNewHighScore = score >= highScore && score > 0

  const buttonStyle = {
    padding: '0.75rem 2.5rem',
    fontSize: '1.1rem',
    background: 'transparent',
    color: 'white',
    border: '2px solid #555',
    borderRadius: '8px',
    cursor: 'pointer',
    width: '220px',
    transition: 'border-color 0.2s',
  }

  return (
    <Overlay background="rgba(20, 0, 0, 0.85)">
      <h2 style={{ fontSize: '2.5rem', margin: '0 0 0.5rem 0', color: '#ff4444' }}>
        GAME OVER
      </h2>

      {isNewHighScore && (
        <p style={{ color: '#ffaa00', fontSize: '1.2rem', margin: '0 0 1rem 0' }}>
          NEW HIGH SCORE!
        </p>
      )}

      <div style={{ color: '#aaa', fontSize: '1.1rem', margin: '0 0 2rem 0' }}>
        <p style={{ margin: '0.3rem 0' }}>Final Score: <strong style={{ color: 'white' }}>{score}</strong></p>
        <p style={{ margin: '0.3rem 0' }}>Enemies Killed: <strong style={{ color: 'white' }}>{enemiesKilled}</strong></p>
        <p style={{ margin: '0.3rem 0' }}>High Score: <strong style={{ color: 'white' }}>{highScore}</strong></p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        <button
          onClick={startGame}
          style={{ ...buttonStyle, borderColor: '#4444ff', background: '#4444ff' }}
          onMouseEnter={(e) => (e.currentTarget.style.background = '#5555ff')}
          onMouseLeave={(e) => (e.currentTarget.style.background = '#4444ff')}
        >
          PLAY AGAIN
        </button>
        <button
          onClick={resetGame}
          style={buttonStyle}
          onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#888')}
          onMouseLeave={(e) => (e.currentTarget.style.borderColor = '#555')}
        >
          MAIN MENU
        </button>
      </div>
    </Overlay>
  )
}
```

### Step 13: The Gameplay Scene

```tsx
// src/scenes/GameplayScene.tsx
import { Player } from '../components/Player'
import { EnemyRenderer } from '../components/EnemyRenderer'
import { ProjectileRenderer } from '../components/ProjectileRenderer'
import { Arena } from '../components/Arena'
import { useEnemies } from '../systems/useEnemies'
import { useProjectiles } from '../systems/useProjectiles'

export function GameplayScene() {
  const { enemiesRef, damageEnemy } = useEnemies()
  const { projectilesRef, fireProjectile } = useProjectiles(enemiesRef, damageEnemy)

  return (
    <group>
      <Arena />
      <Player onFire={fireProjectile} />
      <EnemyRenderer enemiesRef={enemiesRef} />
      <ProjectileRenderer projectilesRef={projectilesRef} />
    </group>
  )
}
```

### Step 14: The App

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { useGameStore } from './stores/useGameStore'
import { ClockTicker } from './systems/ClockTicker'
import { GameplayScene } from './scenes/GameplayScene'
import { TitleScreen } from './ui/TitleScreen'
import { HUD } from './ui/HUD'
import { PauseMenu } from './ui/PauseMenu'
import { GameOverScreen } from './ui/GameOverScreen'

export default function App() {
  const gamePhase = useGameStore((s) => s.gamePhase)
  const isPlaying = gamePhase === 'playing' || gamePhase === 'paused'

  return (
    <>
      <Canvas
        camera={{ position: [0, 20, 15], fov: 50 }}
        gl={{ antialias: true }}
      >
        <ambientLight intensity={0.3} />
        <directionalLight position={[10, 20, 10]} intensity={1} />
        <pointLight position={[0, 5, 0]} intensity={50} distance={30} decay={2} />

        <ClockTicker />

        {/* Game scene — mounted when playing or paused */}
        {isPlaying && <GameplayScene />}
      </Canvas>

      {/* DOM overlays */}
      {gamePhase === 'menu' && <TitleScreen />}
      {gamePhase === 'playing' && <HUD />}
      {gamePhase === 'paused' && (
        <>
          <HUD />
          <PauseMenu />
        </>
      )}
      {gamePhase === 'gameOver' && <GameOverScreen />}
    </>
  )
}
```

### Step 15: Entry Point

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

You should see a title screen with "ARENA" and a start button. Click start. WASD to move your blue cube. Click to shoot yellow projectiles at red enemies that spawn from the edges. Enemies that reach the center damage you. ESC to pause. When health hits zero, the game over screen shows your score and kill count.

The important thing isn't the gameplay. It's the architecture. Score, health, and game phase live in Zustand. The game clock pauses when the game pauses. Systems read state with `getState()` and never cause re-renders. DOM overlays are conditionally rendered based on phase. The 3D scene and DOM layers are cleanly separated. Adding a new feature (sound system, power-ups, difficulty scaling) means adding a new system — not modifying existing ones.

---

## Common Pitfalls

### 1. Subscribing to the Entire Store in a Rendering Component

When you use `useGameStore()` with no selector, the component re-renders on *any* state change. In a game where score updates 10 times per second, every component that subscribes to the full store re-renders 10 times per second.

```tsx
// WRONG — re-renders on ANY state change (score, health, phase, everything)
function ScoreDisplay() {
  const store = useGameStore()
  return <div>Score: {store.score}</div>
}

// RIGHT — re-renders ONLY when score changes
function ScoreDisplay() {
  const score = useGameStore((state) => state.score)
  return <div>Score: {score}</div>
}
```

### 2. Putting Game Phase in useState Instead of Zustand

If game phase lives in a component's local `useState`, you can't access it from `useFrame` without causing re-renders, and you can't access it from other components without prop drilling.

```tsx
// WRONG — phase is trapped in local state
function Game() {
  const [gamePhase, setGamePhase] = useState<'menu' | 'playing'>('menu')
  // Now how does the EnemySpawner know the phase?
  // Prop drill? Context? Both cause problems.
  return <EnemySpawner phase={gamePhase} />
}

// RIGHT — phase lives in Zustand, accessible everywhere
function EnemySpawner() {
  useFrame(() => {
    const { gamePhase } = useGameStore.getState()
    if (gamePhase !== 'playing') return
    // Spawn logic...
  })
  return null
}
```

### 3. Not Using getState() in useFrame

This is the Zustand equivalent of using `useState` in `useFrame`. If you use the hook selector inside a component that also has `useFrame`, every state change causes a re-render — and the re-render reconstructs the `useFrame` callback.

```tsx
// WRONG — subscribes to score, re-renders every time score changes
function ScoreParticles() {
  const score = useGameStore((s) => s.score) // Causes re-renders!

  useFrame(() => {
    // Use score to spawn particles...
    if (score > lastScore) spawnParticles()
  })

  return null
}

// RIGHT — read score imperatively in useFrame
function ScoreParticles() {
  const lastScoreRef = useRef(0)

  useFrame(() => {
    const { score } = useGameStore.getState() // No re-render
    if (score > lastScoreRef.current) {
      spawnParticles()
      lastScoreRef.current = score
    }
  })

  return null
}
```

### 4. Mounting/Unmounting Heavy Scenes Instead of Toggling Visibility

Mounting a scene means creating all its Three.js objects, loading textures, initializing physics bodies. Unmounting means destroying them. If you toggle between scenes frequently (play -> pause -> play), this is extremely wasteful.

```tsx
// WRONG — scene is destroyed and recreated every pause/unpause
{gamePhase === 'playing' && <GameplayScene />}
{gamePhase === 'paused' && <PauseOverlay />}
{/* GameplayScene unmounts during pause! All state lost, all objects recreated on resume */}

// RIGHT — scene stays mounted, just paused
{(gamePhase === 'playing' || gamePhase === 'paused') && <GameplayScene />}
{gamePhase === 'paused' && <PauseOverlay />}
{/* GameplayScene stays alive during pause */}
```

For scenes you transition between rarely (title -> gameplay), mount/unmount is fine. For scenes you switch between frequently (play <-> pause), keep them mounted.

### 5. Variable Timestep Causing Physics Jitter

If you use `delta` directly for physics updates, objects jitter at inconsistent frame rates. Especially noticeable with collision detection.

```tsx
// WRONG — variable timestep, jittery at inconsistent frame rates
useFrame((_, delta) => {
  // delta is 0.016 one frame, 0.032 the next (GC pause), 0.014 after...
  body.position.y -= gravity * delta * delta // Non-deterministic!
})

// RIGHT — fixed timestep accumulator for physics
const accumulator = useRef(0)
const FIXED_DT = 1 / 60

useFrame((_, delta) => {
  accumulator.current += Math.min(delta, 0.1)

  while (accumulator.current >= FIXED_DT) {
    // Physics always steps at exactly 1/60
    body.velocity.y -= gravity * FIXED_DT
    body.position.y += body.velocity.y * FIXED_DT
    accumulator.current -= FIXED_DT
  }
})
```

### 6. Over-Engineering with ECS When Simple Objects Would Suffice

ECS has a learning curve and adds indirection. If you have a player, ten enemies, and five projectiles, you don't need ECS. You need an array and a for loop.

```tsx
// OVERKILL for 15 entities
const world = new World<GameEntity>()
const enemies = world.with('isEnemy', 'position', 'health')
const ECS = createReactAPI(world)
// ... 50 lines of ECS boilerplate

// FINE for 15 entities
const enemies = useRef<Enemy[]>([])
useFrame((_, delta) => {
  for (const enemy of enemies.current) {
    enemy.position.z += enemy.speed * delta
  }
})
```

Adopt ECS when you have dozens of entity types with overlapping component sets, or when you're processing hundreds of entities and need the organizational structure. Don't adopt it because it sounds like the "right" way to make games.

---

## Exercises

### Exercise 1: Create a Zustand Store with Game State and Wire Up a Pause System

**Time:** 30–45 minutes

Build a Zustand store with:
- `gamePhase`: `'menu' | 'playing' | 'paused' | 'gameOver'`
- `score`: number
- `isPaused`: derived from gamePhase (or just check `gamePhase === 'paused'`)
- Actions: `startGame`, `pauseGame`, `resumeGame`

Then wire up ESC key to toggle pause. Create a `useFrame` component that only increments a counter when the game is playing (not paused). Display the counter in a DOM overlay. Verify that:
1. Pressing ESC pauses the counter.
2. Pressing ESC again resumes it.
3. The 3D scene stays rendered while paused.

Hints:
- Use `useEffect` with `window.addEventListener('keydown', ...)` for ESC handling.
- Use `getState()` inside the keydown handler to read current phase.
- Use `getState()` inside `useFrame` to check if paused.

**Stretch goal:** Add a `timeScale` to the store. When paused, set it to 0. When playing, set it to 1. Add a "slow motion" key (e.g., Tab) that sets it to 0.3. Multiply all your deltas by timeScale.

### Exercise 2: Build Scene Transitions with Conditional Rendering

**Time:** 45–60 minutes

Build three screens:
1. **Title screen** (DOM overlay): "My Game" title and "Start" button.
2. **Gameplay** (Canvas + HUD): A spinning cube and a score counter that auto-increments.
3. **Game over** (DOM overlay): Shows final score and "Play Again" button.

Wire them together:
- Title screen's "Start" button calls `startGame()`.
- After 10 seconds of gameplay, automatically call `endGame()`.
- Game over screen's "Play Again" calls `startGame()`.
- Score persists on the game over screen (it should show the final score, not reset to 0 until `startGame` is called).

Hints:
- Use a timer ref in `useFrame` to count to 10 seconds.
- The score should increment every second during gameplay (use another timer ref).
- Make sure the spinning cube doesn't spin during game over (check gamePhase).

**Stretch goal:** Add a fade transition between screens using CSS opacity transitions on the overlays.

### Exercise 3: Implement a Fixed Timestep Game Loop

**Time:** 30–45 minutes

Build a visualization of fixed vs variable timestep:

1. Create two spheres side by side.
2. One moves using variable delta (`useFrame`'s raw delta).
3. One moves using a fixed timestep accumulator (1/60 fixed dt).
4. Both should move at the "same" speed (configure them to match at 60fps).
5. Add a button that artificially simulates frame drops (sleep for 50ms per frame using a heavy computation in `useFrame`).

When the frame rate is stable, both spheres move identically. When frame drops happen, the variable-timestep sphere jitters while the fixed-timestep sphere moves smoothly.

Hints:
- Use `performance.now()` and a busy loop to simulate frame drops.
- Reset both spheres to the start position with a button click.
- Display the current FPS using `1 / delta` to show the impact.

**Stretch goal:** Add interpolation between the last two fixed-step positions to smooth out the fixed-timestep sphere's visual movement even further.

### Exercise 4 (Stretch): Convert a Simple Spawner to miniplex ECS

**Time:** 60–90 minutes

Take a simple spawner system (enemies spawn, move toward center, get removed on arrival) and convert it to use miniplex ECS:

1. Install `miniplex` and `@miniplex/react`.
2. Define entity types with `position`, `velocity`, `isEnemy`, `health` components.
3. Create a world and the React API.
4. Build a movement system that processes all entities with `position` and `velocity`.
5. Build a spawn system that adds entities to the world.
6. Build a cleanup system that removes entities too close to the center.
7. Use `<ECS.Entities>` to render them in the Canvas.

Compare the code before and after. Notice how the ECS version separates data (components) from logic (systems) from rendering (the React bridge). This separation doesn't pay off much at this scale, but imagine doing it with 20 entity types and 15 systems.

Hints:
- Start by defining your entity interface with all components as optional properties.
- Use `world.with('position', 'velocity')` to create a query for the movement system.
- The spawn system can be a `useFrame` component that calls `world.add()`.
- Use `world.remove(entity)` in the cleanup system.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [Zustand Documentation](https://zustand.docs.pmnd.rs/) | Official Docs | The complete API. Pay special attention to the middleware section and `subscribeWithSelector`. |
| [Zustand GitHub](https://github.com/pmndrs/zustand) | Code | Read the source — it's remarkably small. Understanding how it works makes you better at using it. |
| [miniplex Documentation](https://github.com/hmans/miniplex) | Official Docs | The R3F-friendly ECS. Excellent README with React integration examples. |
| [bitECS Documentation](https://github.com/NateTheGreatt/bitECS) | Official Docs | High-performance ECS with typed arrays. Read the benchmarks to understand when it matters. |
| [Fix Your Timestep!](https://gafferongames.com/post/fix_your_timestep/) | Article | The definitive article on fixed timestep. By Glenn Fiedler. Read it cover to cover. |
| [Game Programming Patterns](https://gameprogrammingpatterns.com/) | Book/Web | Free online. Chapters on Game Loop, Component, and Event Queue are directly relevant to this module. |
| [mitt](https://github.com/developit/mitt) | Library | Tiny event emitter. 200 bytes. Read the source — it's 50 lines. |

---

## Key Takeaways

1. **Zustand is your game's central nervous system.** It holds state, provides actions, and bridges React's declarative world with the imperative game loop through `getState()`. Never use `useState` for state that needs to be accessed from `useFrame` or from multiple unrelated components.

2. **`getState()` in `useFrame`, selectors in components.** This is the golden rule. Inside the game loop, read state imperatively. In React components, subscribe with selectors for surgical re-renders. Mixing these up is the most common Zustand performance mistake.

3. **Transient updates bypass React entirely.** When you need to update 3D objects based on state changes without re-rendering, use `subscribe` + `useRef` to pipe state changes directly into Three.js mutations. Zero reconciliation overhead.

4. **Your game clock is not R3F's clock.** Build a clock you can pause, resume, and scale. Slow motion, pause menus, and cutscenes all need clock control. Wire it to your game phase store so pausing the game pauses time automatically.

5. **Fixed timestep produces deterministic gameplay.** The accumulator pattern decouples your logic rate from your render rate. Physics, AI, and gameplay logic run at a constant frequency. The game feels the same at 30fps and 144fps.

6. **ECS is a tool, not a religion.** Use it when you have many entities with varied component compositions and systems that need to query across types. For simple games, arrays and objects are fine. miniplex for ergonomics, bitECS for raw performance.

7. **Events decouple your systems.** The damage system doesn't need to know about the sound system. Publish events describing what happened; let interested systems subscribe. Adding features becomes additive, not invasive.

---

## What's Next?

You now have the architectural bones of a real game: state management, scene flow, a pausable game clock, and patterns for scaling your codebase. But your player is a colored cube. Your enemies are colored cubes. Everything is colored cubes.

**[Module 6: 3D Models, Animation & Assets](module-06-models-animation-assets.md)** teaches you to load GLTF models, play skeletal animations, manage assets with Suspense boundaries, and swap out those cubes for actual characters. Your game is about to start looking like a game.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)