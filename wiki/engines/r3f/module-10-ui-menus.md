# Module 10: UI & Menus

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 5: Game Architecture & State](module-05-game-architecture-state.md)

---

## Overview

You have two worlds and they don't talk to each other. The 3D Canvas is a WebGL context managed by React Three Fiber's reconciler. The HTML DOM is the regular React tree where `<div>` and `<button>` live. Your game UI needs to live in both — menus and HUDs in the DOM, floating health bars and labels in the 3D scene, loading screens that bridge the gap. This module is about bridging those two worlds cleanly.

The core tension is this: HTML is great for text, buttons, layout, and accessibility. WebGL is great for rendering things in 3D space. A health bar above an enemy's head needs to track a 3D position but render as crisp HTML (or as a billboard sprite). A pause menu needs to overlay the 3D scene but block pointer events. A loading screen needs to show while 3D assets stream in via Suspense. Every choice has tradeoffs, and you need to understand them so you pick the right tool for each case.

By the end of this module you'll have a complete game UI kit: a loading screen with a real progress bar, a main menu with navigation, an in-game HUD, floating in-world health bars, and a pause menu overlay. All of it wired to Zustand state, all of it performant, all of it structured so adding new UI doesn't break existing features.

---

## 1. The UI Challenge in 3D Games

### Two Rendering Systems, One Screen

Here's the fundamental problem. When you write an R3F game, you have two completely separate React trees:

1. **The DOM tree** — standard React. `<div>`, `<button>`, `<span>`. Managed by `react-dom`.
2. **The R3F tree** — inside `<Canvas>`. `<mesh>`, `<group>`, `<ambientLight>`. Managed by R3F's custom reconciler.

These trees don't share context. A component inside Canvas can't render a `<div>`. A component outside Canvas can't render a `<mesh>`. They're separate React roots connected only by the fact that `<Canvas>` is a DOM component that creates the bridge.

This matters because game UI naturally spans both worlds:

| UI Element | Where It Lives | Why |
|-----------|---------------|-----|
| Main menu | HTML DOM | Text, buttons, CSS transitions — HTML does this perfectly |
| HUD (health, score) | HTML DOM | Crisp text, easy layout, no 3D projection math |
| Loading screen | HTML DOM | Needs to cover the Canvas while assets load |
| Floating health bar | 3D scene (projected to DOM) | Tracks a world-space position, but renders as HTML |
| In-world label | 3D scene | Needs to exist at a 3D coordinate |
| Damage numbers | Either | Could be 3D Text or projected HTML |
| Minimap | HTML DOM (or second Canvas) | 2D rendering on top of the 3D scene |

### The Tradeoff Matrix

**HTML overlay** — Put a `<div>` on top of the Canvas with `position: absolute`. Standard React. Full CSS. Crisp text. Accessible. But it has no knowledge of 3D space — you have to project 3D coordinates to screen coordinates yourself if you want it to track something.

**drei `<Html>` component** — Renders HTML inside the R3F tree, automatically projected to a 3D position. Handles occlusion, distance scaling, and sprite behavior. But it creates a DOM element for each instance, which gets expensive at scale.

**drei `<Text>` / `<Billboard>`** — Pure 3D. Renders inside WebGL. No DOM overhead. Scales with the scene. But no CSS, no rich formatting, no buttons. Good for labels and simple text.

**Shader-based UI** — Quads with custom shaders for health bars, indicators, etc. Most performant option. Zero DOM overhead. But you're writing shaders for UI, which is a pain.

The right answer is almost always: **HTML overlay for menus and HUD, drei `<Html>` for a handful of in-world elements, `<Billboard>` or `<Text>` when you have many entities**. Mix and match based on the use case. There's no single tool that does everything well.

---

## 2. HTML Overlay Approach

### The Pattern

The simplest and most common way to build game UI is to render standard React components on top of the Canvas. The Canvas fills the viewport. The UI sits in a sibling `<div>` positioned absolutely on top. Pointer events pass through the UI layer to the Canvas except where you explicitly want interactive elements.

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { GameHUD } from './ui/GameHUD'
import { GameScene } from './scenes/GameScene'

export default function App() {
  return (
    <div style={{ width: '100vw', height: '100vh', position: 'relative' }}>
      {/* The 3D scene — fills the container */}
      <Canvas camera={{ position: [0, 5, 10], fov: 60 }}>
        <GameScene />
      </Canvas>

      {/* UI overlay — sits on top of Canvas */}
      <GameHUD />
    </div>
  )
}
```

### The CSS Foundation

The overlay div needs to cover the Canvas exactly, but not block pointer events by default. Only interactive elements (buttons, sliders) should capture clicks.

```css
/* src/styles/ui.css */
.game-ui-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none; /* Let clicks pass through to Canvas */
  z-index: 1;
}

.game-ui-overlay button,
.game-ui-overlay input,
.game-ui-overlay select,
.game-ui-overlay a,
.game-ui-overlay .interactive {
  pointer-events: auto; /* Re-enable on interactive elements */
}
```

```tsx
// src/ui/GameHUD.tsx
import './ui.css'

export function GameHUD() {
  return (
    <div className="game-ui-overlay">
      <div style={{ position: 'absolute', top: 16, left: 16 }}>
        <HealthBar />
        <ScoreDisplay />
      </div>
      <div style={{ position: 'absolute', top: 16, right: 16 }}>
        <MinimapPlaceholder />
      </div>
      <div style={{ position: 'absolute', bottom: 16, left: '50%', transform: 'translateX(-50%)' }}>
        <AbilityBar />
      </div>
    </div>
  )
}
```

### Why This Works Well

This approach gives you the full power of HTML and CSS for UI. You get flexbox, grid, transitions, animations, accessibility, text rendering, form elements — everything the web platform offers. The Canvas handles the 3D scene, and the DOM handles the UI. Clean separation.

The key rule: the overlay `<div>` has `pointer-events: none`, so mouse events pass through it to the Canvas. You selectively re-enable `pointer-events: auto` on buttons and other interactive elements. This way, clicking on empty space interacts with the 3D scene, but clicking on a button activates the button.

---

## 3. drei Html Component

### Anchoring HTML to 3D Positions

Sometimes you need HTML at a 3D position — a label floating above a character, a tooltip on an interactive object, a speech bubble. drei's `<Html>` component handles this. It renders an HTML element that follows a position in 3D space, automatically converting world coordinates to screen coordinates every frame.

```tsx
import { Html } from '@react-three/drei'

function LabeledCrate() {
  return (
    <group position={[3, 0, -2]}>
      <mesh>
        <boxGeometry />
        <meshStandardMaterial color="saddlebrown" />
      </mesh>

      {/* This HTML tracks the mesh's position in 3D space */}
      <Html position={[0, 1.2, 0]} center>
        <div style={{
          background: 'rgba(0, 0, 0, 0.75)',
          color: 'white',
          padding: '4px 8px',
          borderRadius: 4,
          fontSize: 12,
          whiteSpace: 'nowrap',
        }}>
          Supply Crate
        </div>
      </Html>
    </group>
  )
}
```

### Key Props

| Prop | Type | What It Does |
|------|------|--------------|
| `center` | `boolean` | Centers the HTML element on the anchor point |
| `distanceFactor` | `number` | Scales the element based on distance from camera. Set to e.g. `10` to make it shrink as it moves away. |
| `occlude` | `boolean \| Object3D[]` | Hides the element when occluded by 3D geometry |
| `transform` | `boolean` | Applies 3D CSS transforms (perspective-correct scaling/rotation) |
| `sprite` | `boolean` | Always faces the camera (billboarding) |
| `zIndexRange` | `[number, number]` | CSS z-index range for depth sorting between multiple Html elements |
| `portal` | `RefObject<HTMLElement>` | Renders the HTML into a custom DOM container |
| `style` | `CSSProperties` | Style applied to the wrapper div |
| `className` | `string` | CSS class on the wrapper div |

### Distance Scaling

Without `distanceFactor`, the HTML element stays the same pixel size regardless of camera distance. This is usually what you want for UI labels. But if you want the HTML to feel "attached" to the 3D world — getting smaller as the camera pulls back — set `distanceFactor`:

```tsx
<Html distanceFactor={10} center>
  <div style={{ fontSize: 16, color: 'white' }}>
    This shrinks with distance
  </div>
</Html>
```

The number is roughly the distance at which the element appears at its "native" CSS size.

### Occlusion

By default, `<Html>` elements render on top of everything — even if a wall is between the camera and the anchor point. To hide them when occluded:

```tsx
<Html occlude center>
  <div>I hide behind objects</div>
</Html>
```

When `occlude` is `true`, drei uses GPU readback to check visibility. This has a slight performance cost. For a handful of labels it's fine. For 50+ elements, consider alternatives.

### When NOT to Use Html

`<Html>` creates a real DOM element for each instance. Every frame, it recalculates the screen-space position. This is fine for 5-10 elements. It becomes a problem at 50+. If you need floating indicators on 100 enemies, use `<Billboard>` with `<Text>` instead (Section 4) or shader-based sprites.

---

## 4. Billboard and Text

### drei Billboard

A `<Billboard>` is a `<group>` that always faces the camera. It automatically rotates every frame to point toward the camera position. This is the classic "sprite" technique used in games since the 90s.

```tsx
import { Billboard, Text } from '@react-three/drei'

function EnemyLabel({ position, name }: { position: [number, number, number]; name: string }) {
  return (
    <Billboard position={position} follow lockX={false} lockY={false} lockZ={false}>
      <Text fontSize={0.3} color="white" anchorY="bottom">
        {name}
      </Text>
    </Billboard>
  )
}
```

| Prop | Type | What It Does |
|------|------|--------------|
| `follow` | `boolean` | Whether to follow the camera (default: `true`) |
| `lockX` | `boolean` | Lock rotation on the X axis |
| `lockY` | `boolean` | Lock rotation on the Y axis |
| `lockZ` | `boolean` | Lock rotation on the Z axis |

Locking an axis is useful when you want the billboard to face the camera horizontally but stay upright. `lockX={false} lockY={false}` is the most common setup — the sprite turns to face you but doesn't tilt.

### drei Text

`<Text>` renders text using Signed Distance Field (SDF) fonts, which produce crisp text at any size and distance. It's a pure WebGL solution — no DOM elements, no CSS.

```tsx
import { Text } from '@react-three/drei'

function DamageNumber({ position, amount }: { position: [number, number, number]; amount: number }) {
  return (
    <Text
      position={position}
      fontSize={0.5}
      color="red"
      anchorX="center"
      anchorY="middle"
      outlineWidth={0.03}
      outlineColor="black"
      font="/fonts/inter-bold.woff"  // Optional custom font
    >
      {`-${amount}`}
    </Text>
  )
}
```

Key `<Text>` props:

| Prop | Type | What It Does |
|------|------|--------------|
| `fontSize` | `number` | Size in world units |
| `color` | `string` | Text color |
| `anchorX` | `'left' \| 'center' \| 'right'` | Horizontal alignment |
| `anchorY` | `'top' \| 'middle' \| 'bottom'` | Vertical alignment |
| `maxWidth` | `number` | Word wrap width in world units |
| `outlineWidth` | `number` | Outline thickness (great for readability) |
| `outlineColor` | `string` | Outline color |
| `font` | `string` | URL to .woff or .ttf font file |
| `characters` | `string` | Pre-specified character set for SDF generation |

### When to Use Which

**Use `<Html>`** when you need rich HTML content — buttons, styled text, images, complex layouts. For a handful of UI elements anchored to 3D positions.

**Use `<Billboard>` + `<Text>`** when you need many labels in the 3D scene. 100 enemies with name plates? Billboard. Damage numbers spawning rapidly? Billboard. These live entirely in WebGL, so they're much cheaper than DOM elements.

**Use `<Text>` alone** (without Billboard) when the text should be part of the 3D world and not necessarily face the camera — signs, labels painted on walls, etc.

### Performance Consideration

`<Text>` uses troika-three-text under the hood. Font parsing and SDF generation happen on first render and can cause a brief delay. Pre-specify your `characters` prop if you know the character set (e.g., `characters="0123456789-+HP"` for health numbers) to speed up initial generation. Also, each unique `<Text>` instance is a separate draw call. For truly massive numbers of labels, consider `InstancedMesh` with a texture atlas.

---

## 5. tunnel-rat

### The Problem

Here's a frustrating limitation you'll hit the moment you try to build real game UI: components inside `<Canvas>` can't render to the DOM. They live in R3F's reconciler. Components outside `<Canvas>` can't access R3F hooks like `useFrame` or `useThree`. They live in `react-dom`'s reconciler.

So if you have a game component inside Canvas that knows the player's health, and you want to display that health in a DOM-based HUD outside Canvas — how do you connect them?

Option 1: lift state to a shared store (Zustand). This works great and is the primary approach for most game state. But sometimes you have a component deep inside the R3F tree that wants to render some DOM output without threading everything through a store.

Option 2: `tunnel-rat`. It creates a portal between the two React trees.

### What tunnel-rat Does

`tunnel-rat` is a tiny library (also from the Poimandres team) that creates a bidirectional tunnel. You push content into the tunnel from one React tree and render it from another.

```bash
npm install tunnel-rat
```

### Setup

```tsx
// src/tunnel.ts
import tunnel from 'tunnel-rat'

export const ui = tunnel()
```

That's it. `ui` now has two components: `ui.In` (where you push content) and `ui.Out` (where it renders).

### Usage

```tsx
// Inside Canvas — an R3F component that wants to render DOM content
function PlayerStatus() {
  const health = usePlayerHealth() // Some R3F-side hook or state

  return (
    <>
      {/* This mesh lives in the 3D scene */}
      <mesh position={[0, 0, 0]}>
        <sphereGeometry args={[0.5, 32, 32]} />
        <meshStandardMaterial color="blue" />
      </mesh>

      {/* This HTML will appear in the DOM, outside Canvas */}
      <ui.In>
        <div style={{ color: 'white', fontSize: 24 }}>
          HP: {health}
        </div>
      </ui.In>
    </>
  )
}
```

```tsx
// Outside Canvas — in the DOM tree
import { ui } from './tunnel'

export default function App() {
  return (
    <div style={{ width: '100vw', height: '100vh', position: 'relative' }}>
      <Canvas>
        <PlayerStatus />
      </Canvas>

      {/* Renders whatever was pushed into ui.In */}
      <div style={{ position: 'absolute', top: 16, left: 16, pointerEvents: 'none' }}>
        <ui.Out />
      </div>
    </div>
  )
}
```

### When to Use tunnel-rat vs Zustand

For most game UI, you don't need tunnel-rat. Zustand stores are accessible from both trees (Canvas and DOM). Your game state lives in Zustand, and both sides read from it.

tunnel-rat shines when:
- A component deep in the R3F tree needs to render some dynamic DOM content that's tightly coupled to that component's lifecycle
- You want the DOM output to mount/unmount with the R3F component
- You're building reusable components that need to "escape" the Canvas

For a typical game, the pattern is: **Zustand for state, HTML overlay for HUD, tunnel-rat for edge cases**. Don't reach for tunnel-rat first. Reach for it when the simpler patterns don't fit.

### Cleanup

tunnel-rat automatically cleans up when the source component unmounts. The `<ui.In>` content disappears from `<ui.Out>` when the component that rendered it is removed from the R3F tree. You don't need manual cleanup — but be aware that if you create multiple tunnel instances and forget to render `<Out>`, those DOM elements are just lost in the void.

---

## 6. Loading Screens

### The Problem

3D games load assets — models, textures, HDR environments, sounds. These take time. A blank screen while assets load is amateur hour. You need a loading screen.

React already has the primitive for this: `Suspense`. R3F integrates with Suspense natively. When a component inside `<Canvas>` loads an asset (via `useGLTF`, `useTexture`, etc.), it suspends. The nearest `<Suspense>` boundary catches it and shows the fallback.

### useProgress

drei's `useProgress` hook gives you loading progress information:

```tsx
import { useProgress } from '@react-three/drei'

function LoadingScreen() {
  const { progress, active, loaded, total } = useProgress()

  return (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#111',
      color: 'white',
      zIndex: 10,
    }}>
      <h2>Loading...</h2>
      <div style={{
        width: 300,
        height: 8,
        background: '#333',
        borderRadius: 4,
        overflow: 'hidden',
        marginTop: 16,
      }}>
        <div style={{
          width: `${progress}%`,
          height: '100%',
          background: '#4488ff',
          borderRadius: 4,
          transition: 'width 0.2s ease',
        }} />
      </div>
      <p style={{ marginTop: 8, fontSize: 14, opacity: 0.6 }}>
        {loaded} / {total} assets loaded
      </p>
    </div>
  )
}
```

| Property | Type | What It Is |
|----------|------|------------|
| `progress` | `number` | 0–100 percentage |
| `active` | `boolean` | `true` while assets are still loading |
| `loaded` | `number` | Number of items loaded |
| `total` | `number` | Total number of items to load |
| `item` | `string` | URL of the currently loading item |
| `errors` | `string[]` | Any failed load URLs |

### The Suspense Boundary Pattern

The placement of your `<Suspense>` boundary matters. Put it **inside** the Canvas to keep the Canvas mounted while assets load. Put the loading screen **outside** the Canvas so it overlays it.

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { Suspense } from 'react'
import { LoadingScreen } from './ui/LoadingScreen'
import { GameScene } from './scenes/GameScene'
import { useProgress } from '@react-three/drei'

function LoadingOverlay() {
  const { active, progress } = useProgress()

  if (!active) return null

  return <LoadingScreen progress={progress} />
}

export default function App() {
  return (
    <div style={{ width: '100vw', height: '100vh', position: 'relative' }}>
      <Canvas>
        <Suspense fallback={null}>
          <GameScene />
        </Suspense>
      </Canvas>

      {/* Loading overlay reads progress from drei */}
      <LoadingOverlay />
    </div>
  )
}
```

The `Suspense fallback={null}` inside Canvas means the 3D scene shows nothing while loading. The `<LoadingOverlay>` outside Canvas reads `useProgress` and shows the progress bar. When loading finishes, `active` becomes `false`, and the overlay disappears.

### Fade-Out Transition

An abrupt disappearance looks jarring. Add a fade-out:

```tsx
import { useState, useEffect } from 'react'
import { useProgress } from '@react-three/drei'

function LoadingOverlay() {
  const { active, progress } = useProgress()
  const [visible, setVisible] = useState(true)
  const [opacity, setOpacity] = useState(1)

  useEffect(() => {
    if (!active && progress === 100) {
      // Start fade out
      setOpacity(0)
      // Remove from DOM after transition
      const timer = setTimeout(() => setVisible(false), 600)
      return () => clearTimeout(timer)
    }
  }, [active, progress])

  if (!visible) return null

  return (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#111',
      color: 'white',
      zIndex: 10,
      opacity,
      transition: 'opacity 0.5s ease-out',
      pointerEvents: active ? 'auto' : 'none',
    }}>
      <h2 style={{ fontFamily: 'monospace', letterSpacing: 4 }}>LOADING</h2>
      <div style={{
        width: 300,
        height: 6,
        background: '#333',
        borderRadius: 3,
        overflow: 'hidden',
        marginTop: 16,
      }}>
        <div style={{
          width: `${progress}%`,
          height: '100%',
          background: '#4488ff',
          borderRadius: 3,
          transition: 'width 0.3s ease',
        }} />
      </div>
    </div>
  )
}
```

---

## 7. Main Menu

### Structure

A main menu is a full-screen overlay that covers the Canvas. It's pure HTML/CSS — no 3D rendering needed for the UI itself (though you might render a 3D scene in the background for visual flair).

The menu connects to your Zustand game state store to switch between scenes.

### The Game State Store

First, define the UI states your game can be in:

```tsx
// src/stores/gameStore.ts
import { create } from 'zustand'

type GameScreen = 'mainMenu' | 'playing' | 'paused' | 'settings' | 'credits' | 'gameOver'

interface GameState {
  screen: GameScreen
  health: number
  maxHealth: number
  score: number

  // Actions
  setScreen: (screen: GameScreen) => void
  startGame: () => void
  pauseGame: () => void
  resumeGame: () => void
  takeDamage: (amount: number) => void
  addScore: (points: number) => void
  resetGame: () => void
}

export const useGameStore = create<GameState>((set) => ({
  screen: 'mainMenu',
  health: 100,
  maxHealth: 100,
  score: 0,

  setScreen: (screen) => set({ screen }),

  startGame: () =>
    set({
      screen: 'playing',
      health: 100,
      score: 0,
    }),

  pauseGame: () => set({ screen: 'paused' }),
  resumeGame: () => set({ screen: 'playing' }),

  takeDamage: (amount) =>
    set((state) => {
      const newHealth = Math.max(0, state.health - amount)
      return {
        health: newHealth,
        screen: newHealth <= 0 ? 'gameOver' : state.screen,
      }
    }),

  addScore: (points) => set((state) => ({ score: state.score + points })),

  resetGame: () =>
    set({
      screen: 'mainMenu',
      health: 100,
      score: 0,
    }),
}))
```

### The Main Menu Component

```tsx
// src/ui/MainMenu.tsx
import { useGameStore } from '../stores/gameStore'

export function MainMenu() {
  const screen = useGameStore((s) => s.screen)
  const startGame = useGameStore((s) => s.startGame)
  const setScreen = useGameStore((s) => s.setScreen)

  if (screen !== 'mainMenu') return null

  return (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #0a0a2e 0%, #1a1a3e 50%, #0a0a2e 100%)',
      zIndex: 20,
    }}>
      <h1 style={{
        fontFamily: 'monospace',
        fontSize: 48,
        color: '#fff',
        letterSpacing: 8,
        marginBottom: 8,
        textShadow: '0 0 20px rgba(68, 136, 255, 0.5)',
      }}>
        ARENA
      </h1>
      <p style={{
        fontFamily: 'monospace',
        fontSize: 14,
        color: '#888',
        marginBottom: 48,
        letterSpacing: 2,
      }}>
        SURVIVE THE ONSLAUGHT
      </p>

      <MenuButton onClick={startGame}>START GAME</MenuButton>
      <MenuButton onClick={() => setScreen('settings')}>SETTINGS</MenuButton>
      <MenuButton onClick={() => setScreen('credits')}>CREDITS</MenuButton>
    </div>
  )
}

function MenuButton({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      style={{
        fontFamily: 'monospace',
        fontSize: 18,
        color: '#ccc',
        background: 'transparent',
        border: '1px solid #444',
        padding: '12px 48px',
        marginBottom: 12,
        cursor: 'pointer',
        letterSpacing: 4,
        transition: 'all 0.2s ease',
        minWidth: 260,
      }}
      onMouseOver={(e) => {
        e.currentTarget.style.borderColor = '#4488ff'
        e.currentTarget.style.color = '#fff'
        e.currentTarget.style.background = 'rgba(68, 136, 255, 0.1)'
      }}
      onMouseOut={(e) => {
        e.currentTarget.style.borderColor = '#444'
        e.currentTarget.style.color = '#ccc'
        e.currentTarget.style.background = 'transparent'
      }}
    >
      {children}
    </button>
  )
}
```

### Settings and Credits Screens

These are simple sub-screens that navigate back to the main menu:

```tsx
// src/ui/SettingsScreen.tsx
import { useGameStore } from '../stores/gameStore'

export function SettingsScreen() {
  const screen = useGameStore((s) => s.screen)
  const setScreen = useGameStore((s) => s.setScreen)

  if (screen !== 'settings') return null

  return (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#0a0a2e',
      color: 'white',
      zIndex: 20,
    }}>
      <h2 style={{ fontFamily: 'monospace', letterSpacing: 4, marginBottom: 32 }}>SETTINGS</h2>

      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}>
        <label style={{ fontFamily: 'monospace', fontSize: 14, width: 120 }}>VOLUME</label>
        <input
          type="range"
          min={0}
          max={100}
          defaultValue={80}
          style={{ width: 200 }}
        />
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 32 }}>
        <label style={{ fontFamily: 'monospace', fontSize: 14, width: 120 }}>DIFFICULTY</label>
        <select
          defaultValue="normal"
          style={{
            fontFamily: 'monospace',
            background: '#222',
            color: 'white',
            border: '1px solid #444',
            padding: '4px 8px',
          }}
        >
          <option value="easy">EASY</option>
          <option value="normal">NORMAL</option>
          <option value="hard">HARD</option>
        </select>
      </div>

      <button
        onClick={() => setScreen('mainMenu')}
        style={{
          fontFamily: 'monospace',
          fontSize: 14,
          color: '#ccc',
          background: 'transparent',
          border: '1px solid #444',
          padding: '8px 32px',
          cursor: 'pointer',
          letterSpacing: 2,
        }}
      >
        BACK
      </button>
    </div>
  )
}
```

### Animated Background

Want the main menu to have a 3D background? Keep the Canvas rendering behind the menu overlay. The menu's `background` becomes semi-transparent:

```tsx
// Change the menu background to see through to the Canvas:
background: 'rgba(10, 10, 46, 0.85)',
```

Now your spinning 3D scene shows through behind the menu. This is a common pattern — the game world is technically always there, just obscured by the menu overlay.

---

## 8. HUD (Heads-Up Display)

### What Goes in a HUD

The HUD shows the player's moment-to-moment game state. Common elements:

- Health bar
- Score / kill counter
- Minimap
- Ammo count
- Ability cooldowns
- Compass / waypoint indicators
- FPS counter (debug)

All of these are HTML overlay elements. They don't need to exist in 3D space. They're positioned relative to the screen corners using `position: absolute`.

### Health Bar

```tsx
// src/ui/HealthBar.tsx
import { useGameStore } from '../stores/gameStore'

export function HealthBar() {
  const health = useGameStore((s) => s.health)
  const maxHealth = useGameStore((s) => s.maxHealth)
  const percent = (health / maxHealth) * 100

  // Color shifts from green to yellow to red as health decreases
  const barColor =
    percent > 60 ? '#44cc44' :
    percent > 30 ? '#cccc44' :
    '#cc4444'

  return (
    <div style={{ marginBottom: 8 }}>
      <div style={{
        fontFamily: 'monospace',
        fontSize: 11,
        color: '#aaa',
        marginBottom: 2,
        letterSpacing: 1,
      }}>
        HP {health} / {maxHealth}
      </div>
      <div style={{
        width: 200,
        height: 12,
        background: '#222',
        borderRadius: 2,
        overflow: 'hidden',
        border: '1px solid #444',
      }}>
        <div style={{
          width: `${percent}%`,
          height: '100%',
          background: barColor,
          transition: 'width 0.3s ease, background-color 0.3s ease',
          borderRadius: 2,
        }} />
      </div>
    </div>
  )
}
```

### Score Display

```tsx
// src/ui/ScoreDisplay.tsx
import { useGameStore } from '../stores/gameStore'

export function ScoreDisplay() {
  const score = useGameStore((s) => s.score)

  return (
    <div style={{
      fontFamily: 'monospace',
      fontSize: 20,
      color: '#fff',
      letterSpacing: 2,
    }}>
      {score.toString().padStart(8, '0')}
    </div>
  )
}
```

### Minimap Placeholder

A real minimap is complex (covered in the exercises). For now, a placeholder:

```tsx
// src/ui/Minimap.tsx
export function Minimap() {
  return (
    <div style={{
      width: 150,
      height: 150,
      background: 'rgba(0, 0, 0, 0.6)',
      border: '1px solid #444',
      borderRadius: 4,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}>
      <div style={{
        width: 6,
        height: 6,
        background: '#4488ff',
        borderRadius: '50%',
      }} />
    </div>
  )
}
```

### Assembling the HUD

```tsx
// src/ui/GameHUD.tsx
import { useGameStore } from '../stores/gameStore'
import { HealthBar } from './HealthBar'
import { ScoreDisplay } from './ScoreDisplay'
import { Minimap } from './Minimap'

export function GameHUD() {
  const screen = useGameStore((s) => s.screen)

  // Only show HUD during gameplay
  if (screen !== 'playing' && screen !== 'paused') return null

  return (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      pointerEvents: 'none',
      zIndex: 5,
    }}>
      {/* Top-left: health and score */}
      <div style={{ position: 'absolute', top: 16, left: 16 }}>
        <HealthBar />
        <ScoreDisplay />
      </div>

      {/* Top-right: minimap */}
      <div style={{ position: 'absolute', top: 16, right: 16 }}>
        <Minimap />
      </div>
    </div>
  )
}
```

### Performance: Don't Re-render Every Frame

The HUD uses Zustand selectors (`useGameStore((s) => s.health)`). Zustand only re-renders the component when the selected value changes. If health doesn't change this frame, the `HealthBar` component doesn't re-render. This is why Zustand selectors matter — without them, the entire HUD would re-render on every state change.

Compare this to React Context, where any change to the context re-renders every consumer. With Zustand, changing the score doesn't re-render the health bar. Changing health doesn't re-render the score. Each piece updates independently.

For values that change very frequently (like a timer ticking every frame), consider using a ref and updating the DOM directly:

```tsx
function FrameTimer() {
  const spanRef = useRef<HTMLSpanElement>(null)

  // This hook lives in the R3F tree, not the DOM tree
  // You'd use tunnel-rat or update via Zustand
  useEffect(() => {
    let frame: number
    const update = () => {
      if (spanRef.current) {
        spanRef.current.textContent = performance.now().toFixed(0)
      }
      frame = requestAnimationFrame(update)
    }
    frame = requestAnimationFrame(update)
    return () => cancelAnimationFrame(frame)
  }, [])

  return <span ref={spanRef} style={{ fontFamily: 'monospace', color: '#888' }} />
}
```

This bypasses React's render cycle entirely for high-frequency DOM updates.

---

## 9. In-World Health Bars

### The Pattern

Enemies need health bars floating above their heads. These bars exist in the 3D scene — they track the enemy's world-space position and always face the camera.

You have two options:

1. **`<Html>` component** — Each enemy gets a small HTML element positioned in 3D space. Crisp rendering, easy to style. Works great for 5–20 enemies.
2. **`<Billboard>` with a colored plane** — Pure 3D. A quad that always faces the camera with its width proportional to health. Works for hundreds of enemies.

### Option 1: Html-based Health Bars

```tsx
// src/components/EnemyHealthBar.tsx
import { Html } from '@react-three/drei'

interface EnemyHealthBarProps {
  health: number
  maxHealth: number
  visible?: boolean
}

export function EnemyHealthBar({ health, maxHealth, visible = true }: EnemyHealthBarProps) {
  if (!visible || health >= maxHealth) return null

  const percent = (health / maxHealth) * 100

  return (
    <Html center position={[0, 1.8, 0]} distanceFactor={8} sprite>
      <div style={{
        width: 60,
        height: 6,
        background: '#333',
        borderRadius: 3,
        overflow: 'hidden',
        border: '1px solid #555',
      }}>
        <div style={{
          width: `${percent}%`,
          height: '100%',
          background: percent > 50 ? '#44cc44' : percent > 25 ? '#cccc44' : '#cc4444',
          transition: 'width 0.2s ease',
        }} />
      </div>
    </Html>
  )
}
```

Usage on an enemy:

```tsx
function Enemy({ id }: { id: string }) {
  const meshRef = useRef<Mesh>(null)
  const health = useEnemyHealth(id) // Read from Zustand/ECS
  const maxHealth = 100

  useFrame((_, delta) => {
    if (!meshRef.current) return
    // Enemy movement logic...
  })

  return (
    <group>
      <mesh ref={meshRef}>
        <boxGeometry args={[1, 1.5, 1]} />
        <meshStandardMaterial color="red" />
      </mesh>
      <EnemyHealthBar health={health} maxHealth={maxHealth} />
    </group>
  )
}
```

### Option 2: Billboard-based Health Bars (for Scale)

When you have 50+ enemies, each `<Html>` element adds a real DOM node that gets repositioned every frame. This doesn't scale. Use a pure 3D approach instead:

```tsx
// src/components/WorldHealthBar.tsx
import { useRef, useMemo } from 'react'
import { Billboard } from '@react-three/drei'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

interface WorldHealthBarProps {
  health: number
  maxHealth: number
  width?: number
  yOffset?: number
}

export function WorldHealthBar({
  health,
  maxHealth,
  width = 1.2,
  yOffset = 1.8,
}: WorldHealthBarProps) {
  const fillRef = useRef<THREE.Mesh>(null)
  const percent = health / maxHealth

  // Only re-render this component when health actually changes
  const barColor = useMemo(() => {
    if (percent > 0.6) return '#44cc44'
    if (percent > 0.3) return '#cccc44'
    return '#cc4444'
  }, [percent])

  useFrame(() => {
    if (!fillRef.current) return
    fillRef.current.scale.x = Math.max(0, percent)
    fillRef.current.position.x = -(width * (1 - percent)) / 2
  })

  if (health >= maxHealth) return null

  return (
    <Billboard position={[0, yOffset, 0]}>
      {/* Background bar */}
      <mesh>
        <planeGeometry args={[width, 0.08]} />
        <meshBasicMaterial color="#333" transparent opacity={0.8} />
      </mesh>

      {/* Fill bar */}
      <mesh ref={fillRef} position={[0, 0, 0.001]}>
        <planeGeometry args={[width, 0.06]} />
        <meshBasicMaterial color={barColor} />
      </mesh>
    </Billboard>
  )
}
```

This creates zero DOM elements. It's pure WebGL — two planes on a billboard. The fill bar's scale and position are updated via ref mutation, so there are no React re-renders during health changes.

### Reading Health from a Store

If your enemies are tracked in a Zustand store (as set up in Module 5), you can read individual enemy health with a selector:

```tsx
// src/stores/enemyStore.ts
import { create } from 'zustand'

interface Enemy {
  id: string
  position: [number, number, number]
  health: number
  maxHealth: number
}

interface EnemyStore {
  enemies: Map<string, Enemy>
  damageEnemy: (id: string, amount: number) => void
  removeEnemy: (id: string) => void
}

export const useEnemyStore = create<EnemyStore>((set) => ({
  enemies: new Map(),

  damageEnemy: (id, amount) =>
    set((state) => {
      const enemies = new Map(state.enemies)
      const enemy = enemies.get(id)
      if (enemy) {
        enemies.set(id, {
          ...enemy,
          health: Math.max(0, enemy.health - amount),
        })
      }
      return { enemies }
    }),

  removeEnemy: (id) =>
    set((state) => {
      const enemies = new Map(state.enemies)
      enemies.delete(id)
      return { enemies }
    }),
}))

// Selector hook for a single enemy's health
export function useEnemyHealth(id: string): number {
  return useEnemyStore((s) => s.enemies.get(id)?.health ?? 0)
}
```

### Performance at Scale

Here's the scaling reality:

| Enemies | Approach | Performance |
|---------|----------|-------------|
| 1–20 | `<Html>` | Fine. DOM is fast at this scale. |
| 20–100 | `<Billboard>` with planes | Good. Pure WebGL, minimal overhead. |
| 100–1000 | `InstancedMesh` health bars | Best. One draw call for all bars. |

For the instanced approach (100+ enemies), you'd create an `InstancedMesh` with one instance per enemy, and update each instance's matrix and color per frame. This is an advanced optimization covered in Module 8.

---

## 10. Pause Menu

### The Overlay Pattern

The pause menu is an overlay — a semi-transparent darkening layer with menu options centered on screen. It appears instantly when the player presses Escape.

```tsx
// src/ui/PauseMenu.tsx
import { useGameStore } from '../stores/gameStore'

export function PauseMenu() {
  const screen = useGameStore((s) => s.screen)
  const resumeGame = useGameStore((s) => s.resumeGame)
  const resetGame = useGameStore((s) => s.resetGame)
  const setScreen = useGameStore((s) => s.setScreen)

  if (screen !== 'paused') return null

  return (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'rgba(0, 0, 0, 0.7)',
      backdropFilter: 'blur(4px)',
      zIndex: 15,
    }}>
      <h2 style={{
        fontFamily: 'monospace',
        fontSize: 32,
        color: '#fff',
        letterSpacing: 6,
        marginBottom: 40,
      }}>
        PAUSED
      </h2>

      <PauseButton onClick={resumeGame}>RESUME</PauseButton>
      <PauseButton onClick={() => setScreen('settings')}>SETTINGS</PauseButton>
      <PauseButton onClick={resetGame}>QUIT TO MENU</PauseButton>
    </div>
  )
}

function PauseButton({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      style={{
        fontFamily: 'monospace',
        fontSize: 16,
        color: '#ccc',
        background: 'rgba(255, 255, 255, 0.05)',
        border: '1px solid #555',
        padding: '10px 40px',
        marginBottom: 10,
        cursor: 'pointer',
        letterSpacing: 3,
        minWidth: 240,
        transition: 'all 0.15s ease',
      }}
      onMouseOver={(e) => {
        e.currentTarget.style.borderColor = '#4488ff'
        e.currentTarget.style.color = '#fff'
        e.currentTarget.style.background = 'rgba(68, 136, 255, 0.15)'
      }}
      onMouseOut={(e) => {
        e.currentTarget.style.borderColor = '#555'
        e.currentTarget.style.color = '#ccc'
        e.currentTarget.style.background = 'rgba(255, 255, 255, 0.05)'
      }}
    >
      {children}
    </button>
  )
}
```

### Listening for Escape Key

Wire up the Escape key to toggle pause:

```tsx
// src/hooks/usePauseOnEscape.ts
import { useEffect } from 'react'
import { useGameStore } from '../stores/gameStore'

export function usePauseOnEscape() {
  const screen = useGameStore((s) => s.screen)
  const pauseGame = useGameStore((s) => s.pauseGame)
  const resumeGame = useGameStore((s) => s.resumeGame)

  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        if (screen === 'playing') pauseGame()
        else if (screen === 'paused') resumeGame()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [screen, pauseGame, resumeGame])
}
```

### Pausing the Game Clock

When the game is paused, you need to stop the game simulation. The simplest pattern: check the game state in `useFrame` and skip updates.

```tsx
// In any game component that uses useFrame:
useFrame((state, delta) => {
  const screen = useGameStore.getState().screen
  if (screen !== 'playing') return // Skip all updates when not playing

  // Normal game logic here...
  meshRef.current!.position.x += velocity * delta
})
```

Note the use of `useGameStore.getState()` instead of a hook selector. Inside `useFrame`, you don't want to subscribe to React state changes — you want to read the current value imperatively. `getState()` is synchronous, causes no re-render, and is exactly what you need in a game loop.

### Pausing Physics

If you're using Rapier (from Module 4), pause the physics world:

```tsx
import { useRapier } from '@react-three/rapier'

function PhysicsPauser() {
  const { world } = useRapier()
  const screen = useGameStore((s) => s.screen)

  useEffect(() => {
    if (screen === 'paused') {
      // Rapier doesn't have a built-in pause — set timestep to 0
      world.timestep = 0
    } else if (screen === 'playing') {
      world.timestep = 1 / 60
    }
  }, [screen, world])

  return null
}
```

Alternatively, wrap your physics world in a component that conditionally sets `paused`:

```tsx
<Physics paused={screen !== 'playing'}>
  {/* Game objects */}
</Physics>
```

The `paused` prop on `<Physics>` from `@react-three/rapier` stops the simulation while keeping all bodies in place. When you unpause, everything resumes from where it was.

### The Blur / Darken Effect

The `backdrop-filter: blur(4px)` in the pause menu CSS blurs the 3D scene behind it. This gives a natural visual cue that the game is paused. Combined with the semi-transparent black overlay (`rgba(0, 0, 0, 0.7)`), it creates a clean separation between the game world and the menu.

Browser support for `backdrop-filter` is excellent in modern browsers. If you need to support older browsers, fall back to a solid dark overlay instead.

---

## 11. Responsive Design

### The Problem

Your game UI looks perfect on your 1920x1080 monitor. Then you open it on a phone or a 4K display and everything breaks. Text is tiny, health bars overflow, the minimap covers half the screen or is invisible.

### Using useThree for Canvas-Relative Sizing

Inside the R3F tree, `useThree().size` gives you the Canvas dimensions in pixels:

```tsx
import { useThree } from '@react-three/fiber'

function ResponsiveText() {
  const { size } = useThree()

  // Scale text based on viewport width
  const fontSize = Math.max(0.3, size.width / 3000)

  return (
    <Text fontSize={fontSize} color="white" anchorX="center" anchorY="middle">
      Responsive Label
    </Text>
  )
}
```

For in-world `<Html>` elements, `distanceFactor` handles most sizing concerns. But if you need the HTML element itself to scale with viewport:

```tsx
function ResponsiveHtml() {
  const { size } = useThree()
  const scale = Math.min(1, size.width / 1200)

  return (
    <Html center style={{ transform: `scale(${scale})` }}>
      <div style={{ fontSize: 14, color: 'white' }}>Scaled Label</div>
    </Html>
  )
}
```

### Media Queries for HTML Overlay

Your DOM-based UI (menus, HUD) should use standard CSS responsive techniques:

```css
/* Base styles — designed for 1280px+ */
.hud-health-bar {
  width: 200px;
  height: 12px;
}

.hud-minimap {
  width: 150px;
  height: 150px;
}

.hud-score {
  font-size: 20px;
}

/* Smaller screens */
@media (max-width: 768px) {
  .hud-health-bar {
    width: 120px;
    height: 8px;
  }

  .hud-minimap {
    width: 100px;
    height: 100px;
  }

  .hud-score {
    font-size: 14px;
  }
}

/* Very small screens — hide non-essential UI */
@media (max-width: 480px) {
  .hud-minimap {
    display: none;
  }
}
```

### Viewport Units

CSS viewport units (`vw`, `vh`, `vmin`, `vmax`) are useful for game UI that should scale proportionally with the screen:

```tsx
<div style={{
  width: '15vmin',   // 15% of the smaller viewport dimension
  height: '15vmin',
  position: 'absolute',
  top: '2vh',
  right: '2vw',
}}>
  <Minimap />
</div>
```

`vmin` is particularly handy — it uses the smaller of width or height, so your UI elements stay proportional regardless of aspect ratio.

### Handling Device Pixel Ratio

High-DPI displays (Retina, 4K) render more pixels per CSS pixel. The Canvas handles this with the `dpr` prop:

```tsx
<Canvas dpr={[1, 2]}>
  {/* Scene content */}
</Canvas>
```

`dpr={[1, 2]}` means: use 1x on low-DPI screens, up to 2x on high-DPI. This prevents your game from rendering at 4x resolution on a 4K display (which would destroy performance).

Your HTML overlay automatically benefits from the display's DPI — text and CSS renders crisply at native resolution. No extra work needed.

### Fullscreen Toggle

Many games offer a fullscreen mode. Use the browser's Fullscreen API:

```tsx
function FullscreenButton() {
  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen()
    } else {
      document.exitFullscreen()
    }
  }

  return (
    <button onClick={toggleFullscreen} className="interactive" style={{
      position: 'absolute',
      bottom: 16,
      right: 16,
      fontFamily: 'monospace',
      fontSize: 12,
      color: '#888',
      background: 'rgba(0,0,0,0.5)',
      border: '1px solid #444',
      padding: '4px 8px',
      cursor: 'pointer',
    }}>
      FULLSCREEN
    </button>
  )
}
```

---

## Code Walkthrough: Building the Complete UI Kit

This walkthrough builds every piece of UI a game needs, all wired together. We'll build on top of the Zustand store defined in Section 7.

### Project Structure

```
src/
├── App.tsx
├── main.tsx
├── index.css
├── stores/
│   ├── gameStore.ts
│   └── enemyStore.ts
├── ui/
│   ├── LoadingScreen.tsx
│   ├── MainMenu.tsx
│   ├── GameHUD.tsx
│   ├── HealthBar.tsx
│   ├── ScoreDisplay.tsx
│   ├── Minimap.tsx
│   ├── PauseMenu.tsx
│   └── SettingsScreen.tsx
├── components/
│   ├── GameScene.tsx
│   ├── Enemy.tsx
│   └── EnemyHealthBar.tsx
├── hooks/
│   └── usePauseOnEscape.ts
└── tunnel.ts
```

### Step 1: The Game Store

```tsx
// src/stores/gameStore.ts
import { create } from 'zustand'

type GameScreen = 'mainMenu' | 'playing' | 'paused' | 'settings' | 'credits' | 'gameOver'

interface GameState {
  screen: GameScreen
  health: number
  maxHealth: number
  score: number

  setScreen: (screen: GameScreen) => void
  startGame: () => void
  pauseGame: () => void
  resumeGame: () => void
  takeDamage: (amount: number) => void
  addScore: (points: number) => void
  resetGame: () => void
}

export const useGameStore = create<GameState>((set) => ({
  screen: 'mainMenu',
  health: 100,
  maxHealth: 100,
  score: 0,

  setScreen: (screen) => set({ screen }),

  startGame: () =>
    set({
      screen: 'playing',
      health: 100,
      score: 0,
    }),

  pauseGame: () => set({ screen: 'paused' }),
  resumeGame: () => set({ screen: 'playing' }),

  takeDamage: (amount) =>
    set((state) => {
      const newHealth = Math.max(0, state.health - amount)
      return {
        health: newHealth,
        screen: newHealth <= 0 ? 'gameOver' : state.screen,
      }
    }),

  addScore: (points) =>
    set((state) => ({ score: state.score + points })),

  resetGame: () =>
    set({ screen: 'mainMenu', health: 100, score: 0 }),
}))
```

### Step 2: Loading Screen with useProgress

```tsx
// src/ui/LoadingScreen.tsx
import { useState, useEffect } from 'react'
import { useProgress } from '@react-three/drei'

export function LoadingScreen() {
  const { active, progress, loaded, total } = useProgress()
  const [show, setShow] = useState(true)
  const [fadeOut, setFadeOut] = useState(false)

  useEffect(() => {
    if (!active && progress === 100) {
      setFadeOut(true)
      const timer = setTimeout(() => setShow(false), 800)
      return () => clearTimeout(timer)
    }
  }, [active, progress])

  if (!show) return null

  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#0a0a0a',
        color: '#fff',
        zIndex: 50,
        opacity: fadeOut ? 0 : 1,
        transition: 'opacity 0.6s ease-out',
        pointerEvents: active ? 'auto' : 'none',
      }}
    >
      <div
        style={{
          fontFamily: 'monospace',
          fontSize: 14,
          letterSpacing: 6,
          color: '#666',
          marginBottom: 24,
        }}
      >
        LOADING
      </div>

      {/* Progress bar track */}
      <div
        style={{
          width: 320,
          height: 4,
          background: '#222',
          borderRadius: 2,
          overflow: 'hidden',
        }}
      >
        {/* Progress bar fill */}
        <div
          style={{
            width: `${progress}%`,
            height: '100%',
            background: '#4488ff',
            borderRadius: 2,
            transition: 'width 0.3s ease',
          }}
        />
      </div>

      <div
        style={{
          fontFamily: 'monospace',
          fontSize: 11,
          color: '#444',
          marginTop: 12,
        }}
      >
        {Math.round(progress)}% — {loaded}/{total}
      </div>
    </div>
  )
}
```

### Step 3: Main Menu

```tsx
// src/ui/MainMenu.tsx
import { useGameStore } from '../stores/gameStore'

export function MainMenu() {
  const screen = useGameStore((s) => s.screen)
  const startGame = useGameStore((s) => s.startGame)
  const setScreen = useGameStore((s) => s.setScreen)

  if (screen !== 'mainMenu') return null

  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(180deg, #0a0a2e 0%, #1a0a2e 100%)',
        zIndex: 20,
      }}
    >
      <h1
        style={{
          fontFamily: 'monospace',
          fontSize: 'clamp(32px, 6vw, 64px)',
          color: '#fff',
          letterSpacing: 12,
          marginBottom: 8,
          textShadow: '0 0 30px rgba(68, 136, 255, 0.4)',
        }}
      >
        ARENA
      </h1>
      <p
        style={{
          fontFamily: 'monospace',
          fontSize: 'clamp(10px, 1.5vw, 14px)',
          color: '#666',
          letterSpacing: 4,
          marginBottom: 48,
        }}
      >
        SURVIVE THE ONSLAUGHT
      </p>

      <MenuButton onClick={startGame}>START GAME</MenuButton>
      <MenuButton onClick={() => setScreen('settings')}>SETTINGS</MenuButton>
      <MenuButton onClick={() => setScreen('credits')}>CREDITS</MenuButton>
    </div>
  )
}

function MenuButton({
  onClick,
  children,
}: {
  onClick: () => void
  children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      style={{
        fontFamily: 'monospace',
        fontSize: 'clamp(12px, 1.8vw, 18px)',
        color: '#aaa',
        background: 'transparent',
        border: '1px solid #333',
        padding: '12px 48px',
        marginBottom: 10,
        cursor: 'pointer',
        letterSpacing: 4,
        minWidth: 260,
        transition: 'all 0.2s ease',
      }}
      onMouseOver={(e) => {
        e.currentTarget.style.borderColor = '#4488ff'
        e.currentTarget.style.color = '#fff'
        e.currentTarget.style.background = 'rgba(68, 136, 255, 0.08)'
      }}
      onMouseOut={(e) => {
        e.currentTarget.style.borderColor = '#333'
        e.currentTarget.style.color = '#aaa'
        e.currentTarget.style.background = 'transparent'
      }}
    >
      {children}
    </button>
  )
}
```

### Step 4: In-Game HUD

```tsx
// src/ui/GameHUD.tsx
import { useGameStore } from '../stores/gameStore'

export function GameHUD() {
  const screen = useGameStore((s) => s.screen)

  if (screen !== 'playing' && screen !== 'paused') return null

  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        pointerEvents: 'none',
        zIndex: 5,
      }}
    >
      {/* Top-left: health + score */}
      <div style={{ position: 'absolute', top: '2vh', left: '2vw' }}>
        <HudHealthBar />
        <HudScore />
      </div>

      {/* Top-right: minimap */}
      <div style={{ position: 'absolute', top: '2vh', right: '2vw' }}>
        <HudMinimap />
      </div>
    </div>
  )
}

function HudHealthBar() {
  const health = useGameStore((s) => s.health)
  const maxHealth = useGameStore((s) => s.maxHealth)
  const percent = (health / maxHealth) * 100

  const color =
    percent > 60 ? '#44cc44' : percent > 30 ? '#cccc44' : '#cc4444'

  return (
    <div style={{ marginBottom: 8 }}>
      <div
        style={{
          fontFamily: 'monospace',
          fontSize: 'clamp(9px, 1.2vw, 11px)',
          color: '#888',
          marginBottom: 2,
          letterSpacing: 1,
        }}
      >
        HP {health} / {maxHealth}
      </div>
      <div
        style={{
          width: 'clamp(120px, 15vw, 220px)',
          height: 'clamp(8px, 1vw, 12px)',
          background: '#1a1a1a',
          borderRadius: 2,
          overflow: 'hidden',
          border: '1px solid #333',
        }}
      >
        <div
          style={{
            width: `${percent}%`,
            height: '100%',
            background: color,
            borderRadius: 2,
            transition: 'width 0.3s ease, background-color 0.5s ease',
          }}
        />
      </div>
    </div>
  )
}

function HudScore() {
  const score = useGameStore((s) => s.score)

  return (
    <div
      style={{
        fontFamily: 'monospace',
        fontSize: 'clamp(14px, 2vw, 22px)',
        color: '#fff',
        letterSpacing: 2,
        marginTop: 4,
      }}
    >
      {score.toString().padStart(8, '0')}
    </div>
  )
}

function HudMinimap() {
  return (
    <div
      style={{
        width: 'clamp(80px, 12vmin, 150px)',
        height: 'clamp(80px, 12vmin, 150px)',
        background: 'rgba(0, 0, 0, 0.5)',
        border: '1px solid #333',
        borderRadius: 4,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {/* Player dot */}
      <div
        style={{
          width: 6,
          height: 6,
          background: '#4488ff',
          borderRadius: '50%',
          boxShadow: '0 0 6px rgba(68, 136, 255, 0.6)',
        }}
      />
    </div>
  )
}
```

### Step 5: Pause Menu Overlay

```tsx
// src/ui/PauseMenu.tsx
import { useGameStore } from '../stores/gameStore'

export function PauseMenu() {
  const screen = useGameStore((s) => s.screen)
  const resumeGame = useGameStore((s) => s.resumeGame)
  const resetGame = useGameStore((s) => s.resetGame)

  if (screen !== 'paused') return null

  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'rgba(0, 0, 0, 0.7)',
        backdropFilter: 'blur(4px)',
        WebkitBackdropFilter: 'blur(4px)',
        zIndex: 15,
      }}
    >
      <h2
        style={{
          fontFamily: 'monospace',
          fontSize: 28,
          color: '#fff',
          letterSpacing: 8,
          marginBottom: 40,
        }}
      >
        PAUSED
      </h2>

      <PauseButton onClick={resumeGame}>RESUME</PauseButton>
      <PauseButton onClick={resetGame}>QUIT TO MENU</PauseButton>
    </div>
  )
}

function PauseButton({
  onClick,
  children,
}: {
  onClick: () => void
  children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      style={{
        fontFamily: 'monospace',
        fontSize: 16,
        color: '#aaa',
        background: 'rgba(255, 255, 255, 0.04)',
        border: '1px solid #444',
        padding: '10px 40px',
        marginBottom: 10,
        cursor: 'pointer',
        letterSpacing: 3,
        minWidth: 220,
        transition: 'all 0.15s ease',
      }}
      onMouseOver={(e) => {
        e.currentTarget.style.borderColor = '#4488ff'
        e.currentTarget.style.color = '#fff'
      }}
      onMouseOut={(e) => {
        e.currentTarget.style.borderColor = '#444'
        e.currentTarget.style.color = '#aaa'
      }}
    >
      {children}
    </button>
  )
}
```

### Step 6: In-World Health Bars over Enemies

```tsx
// src/components/Enemy.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { Html } from '@react-three/drei'
import type { Group } from 'three'
import { useGameStore } from '../stores/gameStore'

interface EnemyProps {
  id: string
  startPosition: [number, number, number]
  health: number
  maxHealth: number
}

export function Enemy({ id, startPosition, health, maxHealth }: EnemyProps) {
  const groupRef = useRef<Group>(null)
  const percent = (health / maxHealth) * 100

  useFrame((_, delta) => {
    const screen = useGameStore.getState().screen
    if (screen !== 'playing') return

    if (!groupRef.current) return
    // Simple patrol: bob up and down
    groupRef.current.position.y =
      startPosition[1] + Math.sin(Date.now() * 0.002) * 0.3
  })

  const barColor =
    percent > 50 ? '#44cc44' : percent > 25 ? '#cccc44' : '#cc4444'

  return (
    <group ref={groupRef} position={startPosition}>
      {/* Enemy body */}
      <mesh>
        <boxGeometry args={[0.8, 1.2, 0.8]} />
        <meshStandardMaterial color="#cc3333" roughness={0.6} />
      </mesh>

      {/* Floating health bar — only show when damaged */}
      {health < maxHealth && (
        <Html center position={[0, 1.4, 0]} sprite distanceFactor={10}>
          <div
            style={{
              width: 50,
              height: 5,
              background: '#222',
              borderRadius: 2,
              overflow: 'hidden',
            }}
          >
            <div
              style={{
                width: `${percent}%`,
                height: '100%',
                background: barColor,
                transition: 'width 0.2s ease',
              }}
            />
          </div>
        </Html>
      )}
    </group>
  )
}
```

### Step 7: The Zustand Store Drives Everything

```tsx
// src/ui/GameOverScreen.tsx
import { useGameStore } from '../stores/gameStore'

export function GameOverScreen() {
  const screen = useGameStore((s) => s.screen)
  const score = useGameStore((s) => s.score)
  const resetGame = useGameStore((s) => s.resetGame)

  if (screen !== 'gameOver') return null

  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'rgba(20, 0, 0, 0.85)',
        zIndex: 20,
      }}
    >
      <h2
        style={{
          fontFamily: 'monospace',
          fontSize: 36,
          color: '#cc4444',
          letterSpacing: 8,
          marginBottom: 16,
        }}
      >
        GAME OVER
      </h2>
      <p
        style={{
          fontFamily: 'monospace',
          fontSize: 18,
          color: '#888',
          marginBottom: 40,
        }}
      >
        SCORE: {score.toString().padStart(8, '0')}
      </p>
      <button
        onClick={resetGame}
        style={{
          fontFamily: 'monospace',
          fontSize: 16,
          color: '#ccc',
          background: 'transparent',
          border: '1px solid #444',
          padding: '10px 40px',
          cursor: 'pointer',
          letterSpacing: 3,
        }}
      >
        RETURN TO MENU
      </button>
    </div>
  )
}
```

### Step 8: Wiring It All Together

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { Suspense } from 'react'
import { OrbitControls, Environment } from '@react-three/drei'
import { useGameStore } from './stores/gameStore'
import { LoadingScreen } from './ui/LoadingScreen'
import { MainMenu } from './ui/MainMenu'
import { GameHUD } from './ui/GameHUD'
import { PauseMenu } from './ui/PauseMenu'
import { GameOverScreen } from './ui/GameOverScreen'
import { Enemy } from './components/Enemy'
import { usePauseOnEscape } from './hooks/usePauseOnEscape'

function GameScene() {
  return (
    <>
      <ambientLight intensity={0.4} />
      <directionalLight position={[5, 8, 5]} intensity={1} castShadow />
      <Environment preset="sunset" />

      {/* Ground */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.5, 0]} receiveShadow>
        <planeGeometry args={[20, 20]} />
        <meshStandardMaterial color="#2a2a2a" />
      </mesh>

      {/* Some enemies with health bars */}
      <Enemy id="e1" startPosition={[-3, 0.6, -2]} health={75} maxHealth={100} />
      <Enemy id="e2" startPosition={[2, 0.6, -4]} health={30} maxHealth={100} />
      <Enemy id="e3" startPosition={[0, 0.6, -6]} health={100} maxHealth={100} />

      <OrbitControls enableDamping dampingFactor={0.05} />
    </>
  )
}

function UILayer() {
  usePauseOnEscape()

  return (
    <>
      <LoadingScreen />
      <MainMenu />
      <GameHUD />
      <PauseMenu />
      <GameOverScreen />
    </>
  )
}

export default function App() {
  return (
    <div style={{ width: '100vw', height: '100vh', position: 'relative' }}>
      <Canvas
        camera={{ position: [0, 5, 10], fov: 55 }}
        shadows
        dpr={[1, 2]}
      >
        <Suspense fallback={null}>
          <GameScene />
        </Suspense>
      </Canvas>

      {/* All UI overlays */}
      <UILayer />
    </div>
  )
}
```

### Step 9: Escape Key Handler

```tsx
// src/hooks/usePauseOnEscape.ts
import { useEffect } from 'react'
import { useGameStore } from '../stores/gameStore'

export function usePauseOnEscape() {
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key !== 'Escape') return

      const { screen, pauseGame, resumeGame } = useGameStore.getState()

      if (screen === 'playing') pauseGame()
      else if (screen === 'paused') resumeGame()
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])
}
```

Notice that the `useEffect` dependency array is empty. We read from the store with `getState()` inside the event handler, not via a selector. This means the event listener is attached once and never recreated. It always reads the latest state at the moment the key is pressed.

---

## Common Pitfalls

### 1. pointer-events on Overlay Blocking Canvas Interaction

```tsx
// WRONG — overlay captures all clicks, Canvas is unresponsive
function GameHUD() {
  return (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      // No pointer-events setting — defaults to 'auto'
      // This div eats every click
    }}>
      <button>Pause</button>
    </div>
  )
}

// RIGHT — overlay passes clicks through, only buttons capture
function GameHUD() {
  return (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      pointerEvents: 'none', // Clicks pass through to Canvas
    }}>
      <button style={{ pointerEvents: 'auto' }}>Pause</button>
    </div>
  )
}
```

This is the single most common UI bug in R3F games. Your overlay div intercepts every click, and the Canvas underneath becomes unresponsive. You click on the 3D scene and nothing happens. Set `pointer-events: none` on the overlay container, then `pointer-events: auto` on each interactive element.

### 2. Html Component Re-rendering Every Frame

```tsx
// WRONG — creating a new style object every render, causing Html to update
function FloatingLabel({ position }: { position: [number, number, number] }) {
  return (
    <Html position={position} center>
      <div style={{ color: 'white', background: 'rgba(0,0,0,0.5)', padding: 4 }}>
        Enemy
      </div>
    </Html>
  )
}

// If the parent re-renders every frame (from useFrame), this creates
// garbage on every frame. The Html component recalculates screen
// position, and React diffs the children.

// RIGHT — memoize the component and use stable references
import { memo, useMemo } from 'react'

const FloatingLabel = memo(function FloatingLabel() {
  const labelStyle = useMemo(() => ({
    color: 'white',
    background: 'rgba(0,0,0,0.5)',
    padding: 4,
  }), [])

  return (
    <Html position={[0, 1.5, 0]} center>
      <div style={labelStyle}>Enemy</div>
    </Html>
  )
})
```

When `<Html>` is a child of a component that re-renders frequently (e.g., one using `useFrame` that triggers state changes), the HTML recalculates its screen projection. Memoize the component with `React.memo` and keep inline objects stable with `useMemo`.

### 3. Loading Screen Never Disappearing

```tsx
// WRONG — Suspense boundary wraps the entire app, loading screen
// checks useProgress but the Canvas itself never finishes "loading"
function App() {
  return (
    <Suspense fallback={<LoadingScreen />}>
      <Canvas>
        <GameScene /> {/* Contains useGLTF, useTexture, etc. */}
      </Canvas>
    </Suspense>
  )
}

// The Suspense fallback replaces the ENTIRE Canvas while loading.
// useProgress can't report progress because drei's loaders
// aren't mounting yet. You get a loading screen that never resolves.

// RIGHT — Suspense inside Canvas, loading overlay outside
function App() {
  return (
    <div style={{ position: 'relative', width: '100vw', height: '100vh' }}>
      <Canvas>
        <Suspense fallback={null}>
          <GameScene />
        </Suspense>
      </Canvas>

      {/* Reads drei's useProgress from outside Canvas — this works! */}
      <LoadingOverlay />
    </div>
  )
}
```

The key insight: put `<Suspense>` **inside** the Canvas so the Canvas element stays mounted. Put the loading screen **outside** the Canvas as an overlay. `useProgress` works from either tree — it reads from drei's global loading manager.

### 4. UI Elements Not Scaling with Screen Size

```tsx
// WRONG — fixed pixel sizes that look wrong on different screens
<div style={{ width: 200, fontSize: 16, padding: 20 }}>
  Health: 100/100
</div>

// RIGHT — responsive units that scale with the viewport
<div style={{
  width: 'clamp(120px, 15vw, 250px)',
  fontSize: 'clamp(11px, 1.4vw, 16px)',
  padding: 'clamp(8px, 1.5vw, 20px)',
}}>
  Health: 100/100
</div>
```

`clamp(min, preferred, max)` is your best friend for game UI. It sets a preferred size that scales with the viewport but won't go below a minimum or above a maximum. Your HUD stays readable on phones and doesn't become comically large on ultrawide monitors.

### 5. tunnel-rat Portal Not Cleaning Up on Unmount

```tsx
// WRONG — creating a new tunnel instance inside a component
function MyR3FComponent() {
  const myTunnel = tunnel() // New tunnel on every render!

  return (
    <myTunnel.In>
      <div>This creates orphaned DOM nodes</div>
    </myTunnel.In>
  )
}

// RIGHT — create the tunnel once at module scope
// src/tunnel.ts
import tunnel from 'tunnel-rat'
export const ui = tunnel()

// Then use it in components:
import { ui } from '../tunnel'

function MyR3FComponent() {
  return (
    <ui.In>
      <div>This cleans up properly</div>
    </ui.In>
  )
}
```

Tunnel instances must be created once at module scope, not inside components. If you create a tunnel inside a component, every re-render creates a new tunnel instance. The old one's content is orphaned — it stays in the DOM but is no longer connected to any `<Out>`. The new tunnel's content appears but duplicates the old one.

---

## Exercises

### Exercise 1: Build a Loading Screen with Progress Bar and Fade-Out

**Time:** 30–40 minutes

Build a loading screen that:
- Shows while 3D assets are loading (use `useProgress` from drei)
- Displays a progress bar that fills from 0% to 100%
- Shows the current percentage as text
- Fades out smoothly over 500ms when loading completes
- Is removed from the DOM after the fade completes

Hints:
- Use `useState` to track whether the screen is visible
- Use a `useEffect` that watches `active` and `progress` from `useProgress`
- Use CSS `transition: opacity 0.5s ease-out` for the fade
- Use `setTimeout` to remove from DOM after the transition ends
- To test it, add some heavy assets to your scene (large GLTFs, high-res textures via `useTexture`)

**Stretch goal:** Add a spinning indicator or animated dots to the loading text. Display the name of the currently loading file using `useProgress().item`.

### Exercise 2: Create a Main Menu with Start/Settings Buttons Wired to Zustand

**Time:** 40–50 minutes

Build a complete main menu system:
- Full-screen menu with game title, START, SETTINGS, and CREDITS buttons
- Clicking START transitions to the `'playing'` state and hides the menu
- Clicking SETTINGS shows a settings panel (volume slider, difficulty select)
- A BACK button on settings returns to the main menu
- All screen transitions driven by a `screen` property in a Zustand store

Hints:
- Define a `GameScreen` type union: `'mainMenu' | 'playing' | 'paused' | 'settings' | 'credits'`
- Each UI screen checks `if (screen !== 'myScreen') return null`
- Use `clamp()` for font sizes so the menu works on different screen sizes
- Style hover states with `onMouseOver` / `onMouseOut` to avoid a CSS file

**Stretch goal:** Add CSS transitions when switching between screens. Use `opacity` and `transform: translateY` to slide screens in and out.

### Exercise 3: Add Floating Labels to Objects Using drei Html

**Time:** 20–30 minutes

Create a scene with several objects, each with a floating label:
- Use `<Html>` from drei to render a styled label above each object
- Labels should be centered with `center` prop
- Labels should shrink with distance using `distanceFactor`
- Labels should hide when occluded by other objects using `occlude`
- Clicking an object should toggle extra info in the label (e.g., description text)

Hints:
- Nest `<Html>` inside the object's `<group>` or `<mesh>` so it inherits position
- Use `position={[0, yOffset, 0]}` on the Html to float it above the mesh
- Memoize label content to avoid unnecessary re-renders
- `distanceFactor={8}` is a good starting value

**Stretch goal:** Compare performance of `<Html>` labels vs `<Billboard>` + `<Text>` labels. Create 50 objects with labels using each approach and check the frame rate with `r3f-perf`.

### Exercise 4: Build a Minimap Using a Second Canvas or Render Target

**Time:** 60–90 minutes (stretch)

Build a real minimap that shows a top-down view of the game world:

**Option A: Second Canvas**
- Render a second, smaller `<Canvas>` in the HTML overlay
- Use an orthographic camera looking straight down
- Share game state via Zustand so both canvases show the same entity positions
- Style it as a small rectangle in the corner

**Option B: Render Target**
- Create a `WebGLRenderTarget` in the main Canvas
- Render the scene from a top-down camera to the render target
- Display the render target as a texture on a plane (or pass it to an HTML `<img>` via `toDataURL`)

Hints for Option A:
- Two `<Canvas>` components are totally valid — they're just two WebGL contexts
- The minimap Canvas can use `frameloop="demand"` and manually invalidate to save performance
- Use `<OrthographicCamera makeDefault>` in the minimap Canvas
- Simplified materials (flat colors, no lighting) make the minimap read better

Hints for Option B:
- `useFBO` from drei creates a render target
- Use `useFrame` to render the scene from the minimap camera to the FBO
- `gl.render(scene, minimapCamera)` then restore the main camera

This is a genuinely hard exercise. Option A is simpler. Option B is more performant. Either one teaches you something valuable about rendering architecture.

---

## API Quick Reference

### HTML Overlay Pattern

| Concept | Implementation | Notes |
|---------|---------------|-------|
| Overlay container | `position: absolute; pointer-events: none` | Covers Canvas, passes clicks through |
| Interactive elements | `pointer-events: auto` on buttons/inputs | Re-enables click capture |
| Screen switching | Zustand `screen` state + conditional rendering | Each screen checks its own state |
| Responsive sizing | `clamp()`, `vw`, `vh`, `vmin` | Scale with viewport |

### drei UI Components

| Component | Import | What It Does |
|-----------|--------|-------------|
| `<Html>` | `@react-three/drei` | DOM element at a 3D position |
| `<Billboard>` | `@react-three/drei` | Group that always faces camera |
| `<Text>` | `@react-three/drei` | SDF text in WebGL (troika) |
| `useProgress` | `@react-three/drei` | Loading progress hook |

### Html Props

| Prop | Type | Default | Effect |
|------|------|---------|--------|
| `center` | `boolean` | `false` | Centers on anchor point |
| `distanceFactor` | `number` | — | Scales with camera distance |
| `occlude` | `boolean \| Object3D[]` | `false` | Hides behind geometry |
| `transform` | `boolean` | `false` | 3D CSS transforms |
| `sprite` | `boolean` | `false` | Always faces camera |
| `portal` | `RefObject<HTMLElement>` | — | Custom render target |
| `zIndexRange` | `[number, number]` | `[16777271, 0]` | Depth sorting range |

### useProgress Return Values

| Property | Type | Description |
|----------|------|-------------|
| `progress` | `number` | 0–100 percentage |
| `active` | `boolean` | True while loading |
| `loaded` | `number` | Items loaded |
| `total` | `number` | Total items |
| `item` | `string` | Current item URL |
| `errors` | `string[]` | Failed URLs |

### tunnel-rat

| API | Usage | Notes |
|-----|-------|-------|
| `tunnel()` | Create at module scope | One instance per tunnel |
| `<t.In>` | Wrap content inside R3F | Pushes to the tunnel |
| `<t.Out />` | Place in DOM tree | Renders tunnel content |

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [drei Html docs](https://drei.docs.pmnd.rs/misc/html) | Official Docs | All Html component props and examples |
| [drei Billboard docs](https://drei.docs.pmnd.rs/abstractions/billboard) | Official Docs | Billboard and Text component API |
| [tunnel-rat GitHub](https://github.com/pmndrs/tunnel-rat) | Library | The portal solution for R3F-to-DOM rendering |
| [drei useProgress docs](https://drei.docs.pmnd.rs/loaders/use-progress) | Official Docs | Loading progress tracking API |
| [CSS clamp() on MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/clamp) | Reference | Responsive sizing without media queries |
| [Zustand docs](https://zustand.docs.pmnd.rs/) | Official Docs | State management driving all UI transitions |

---

## Key Takeaways

1. **Two worlds, one screen.** Your game has an HTML DOM and a WebGL Canvas. UI lives in both. HTML overlay for menus and HUDs (crisp text, CSS layout, accessibility). drei `<Html>` for a handful of 3D-anchored elements. `<Billboard>` + `<Text>` when you need scale.

2. **`pointer-events: none` is the bridge.** The HTML overlay covers the entire Canvas but passes clicks through. Only interactive elements (buttons, inputs) re-enable pointer events. Forget this and your 3D scene becomes unresponsive.

3. **Zustand drives screen transitions.** A single `screen` state in your store determines which UI is visible. Each screen component checks `if (screen !== 'mine') return null`. Clean, predictable, no prop drilling.

4. **Loading screens live outside the Canvas.** Put `<Suspense>` inside the Canvas. Put the loading overlay outside. `useProgress` works from either tree. The Canvas stays mounted while assets load — you just show a progress bar on top.

5. **`<Html>` is convenient but doesn't scale.** It's perfect for 5–20 floating labels. At 50+, switch to `<Billboard>` with `<Text>` or shader-based sprites. Every `<Html>` instance is a real DOM node being repositioned every frame.

6. **tunnel-rat is the escape hatch, not the default.** Most of the time, Zustand handles communication between the R3F tree and the DOM tree. Use tunnel-rat when a component deep in the R3F tree needs to render DOM content that's tightly coupled to its lifecycle.

7. **Responsive UI is not optional.** Use `clamp()`, viewport units, and media queries. Your game will be played on phones, laptops, and ultrawide monitors. Design for all of them from the start, not as an afterthought.

---

## What's Next?

Your game now has a complete UI layer. Players can navigate menus, see their health and score, pause the action, and watch a loading screen while assets stream in. The 3D scene and the HTML DOM are working together.

Next up is connecting your game to other players. **[Module 11: Multiplayer & Networking](module-11-multiplayer-networking.md)** covers WebSocket communication, state synchronization, client-side prediction, and building a shared 3D space where multiple players interact in real time. It's where your single-player prototype becomes a social experience.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)