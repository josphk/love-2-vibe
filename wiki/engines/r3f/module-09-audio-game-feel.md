# Module 9: Audio & Game Feel

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 4--6 hours
**Prerequisites:** [Module 5: Game Architecture & State](module-05-game-architecture-state.md)

---

## Overview

You've built a game that works. The physics are correct. The collisions detect. The state updates properly. And it feels like a spreadsheet. Something is missing -- the invisible layer between "this thing works" and "this thing feels amazing." That layer is game feel, and it's the difference between a game people play once and a game people can't stop touching.

Game feel is micro-feedback. It's the camera flinching when you hit something. It's the 80ms pause that lets your brain register a heavy impact. It's the particle burst that makes a collision feel explosive instead of clinical. It's the spatial audio that tells you something is happening behind you before you see it. None of these change the mechanics. All of them change the experience.

This module covers the entire juice toolkit: Web Audio API fundamentals, spatial audio with drei and Howler.js, screen shake via the trauma model, hit stop / freeze frames, tweened animations with easing curves, particle feedback systems, and background music management. You'll learn each system individually, then combine them into a cascade that transforms a single game event from "ball hits wall" into a moment that feels powerful.

The mini-project ties everything together: you'll juice up a physics playground with a ball cannon firing at a target wall. On impact, you'll trigger camera shake, particle bursts, spatial audio, hit stop, and score animations -- all toggleable so you can see exactly how much each layer contributes. When you toggle everything on at once, you'll feel the difference in your gut. That's game feel.

---

## 1. What "Game Feel" Actually Is

### The Invisible Layer

Pick up any two platformers. Same mechanics: run, jump, land. One feels floaty and disconnected. The other feels tight and responsive. The difference isn't in the code that moves the character. It's in everything that happens *around* the movement -- the dust cloud when you land, the subtle camera lag, the landing thud, the half-frame of squash animation, the controller rumble.

Game feel is the 30% of development effort that creates 70% of the player's impression. It's the gap between "technically functional" and "I can't put this down." And the wild thing is, players can't articulate what's making the difference. They just say it "feels good" or "feels bad."

### The Juice Framework

"Juice" is the game dev shorthand for layered micro-feedback. The term comes from a legendary talk by Martin Jonasson and Petri Purho where they took a basic Breakout clone and progressively added effects until it felt incredible -- without changing a single line of gameplay logic.

The principle is simple: **one game event should trigger multiple feedback channels simultaneously.** When a ball hits a brick:

- **Visual:** The brick flashes white, then shatters into particles
- **Audio:** A satisfying impact sound plays, spatialized to the collision point
- **Camera:** A tiny shake proportional to the impact force
- **Time:** A 50ms hit stop that lets the brain register the moment
- **Animation:** The score text pops with a scale tween
- **Haptic:** Controller vibration (if available)

Each effect alone is barely noticeable. Together, they create a feeling of weight, power, and responsiveness that makes the game feel alive.

### Why It Works Psychologically

Your brain processes multisensory information faster and more convincingly than single-channel input. When you see a collision, hear the impact, and feel the screen shake -- all at the same time, all consistent with the physics -- your brain constructs a rich, believable event. Drop any one channel and the illusion weakens. Add them all and the game world feels "real," even when it's neon blocks bouncing off each other.

Hit stop works because your brain needs time to process important moments. A 60ms pause on a heavy hit gives the visual system time to register what happened, making the impact feel more significant. Without it, fast-paced action becomes an indistinguishable blur.

Screen shake works because your vestibular system associates vibration with force. Even though the screen is the thing shaking (not your body), the visual motion triggers a subconscious "that was powerful" response.

### The Implementation Pattern

Every juice system follows the same architecture:

1. **Event** -- something happens in the game (collision, pickup, death)
2. **Dispatch** -- the event system broadcasts it to all listeners
3. **Response** -- each juice system independently reacts
4. **Decay** -- the effect fades out over a short duration

This decoupled pattern means you can add, remove, or tune any juice layer without touching gameplay code. Your physics system doesn't know or care that the camera shakes on collision. The shake system just listens for collision events.

---

## 2. Web Audio API Basics

### AudioContext: The Foundation

Every sound you play in the browser goes through an `AudioContext`. It's the root node of the Web Audio graph -- a system of connected audio nodes that generate, process, and output sound.

```typescript
// Create an AudioContext (do this once, store it globally)
const audioContext = new AudioContext()
```

Here's the critical thing: **browsers block audio until a user gesture occurs.** This is a deliberate policy to prevent websites from autoplaying annoying sounds. Your AudioContext starts in a "suspended" state. You must resume it in response to a click, tap, or keypress.

```typescript
// Resume on first user interaction
function resumeAudio() {
  if (audioContext.state === 'suspended') {
    audioContext.resume()
  }
}

// Attach to your first click handler, or add a global listener
document.addEventListener('click', resumeAudio, { once: true })
document.addEventListener('keydown', resumeAudio, { once: true })
```

If you skip this step, you'll get zero audio and zero errors. The API silently does nothing. This is the single most common audio bug in web games.

### Loading and Playing Sounds

The Web Audio API doesn't have a simple "play sound" function. You load audio data into a buffer, create a source node, connect it to the output, and start it. Here's the pattern:

```typescript
async function loadSound(url: string): Promise<AudioBuffer> {
  const response = await fetch(url)
  const arrayBuffer = await response.arrayBuffer()
  return audioContext.decodeAudioData(arrayBuffer)
}

function playSound(buffer: AudioBuffer, volume: number = 1.0) {
  const source = audioContext.createBufferSource()
  const gainNode = audioContext.createGain()

  source.buffer = buffer
  gainNode.gain.value = volume

  source.connect(gainNode)
  gainNode.connect(audioContext.destination)

  source.start(0)
  return source
}
```

Key concepts:

- **AudioBuffer** -- decoded audio data sitting in memory, ready to play instantly
- **AudioBufferSourceNode** -- a one-shot player. Each time you play a sound, you create a new source. They're lightweight and designed to be disposable.
- **GainNode** -- controls volume. Value of 1.0 is full volume, 0 is silent. You can go above 1.0 to amplify, but you risk clipping.

### The Audio Node Graph

Web Audio works as a graph of connected nodes. Audio flows from source nodes through processing nodes to the destination (speakers):

```
BufferSource → GainNode → AudioContext.destination (speakers)
```

You can chain nodes to build complex audio pipelines:

```
BufferSource → GainNode → StereoPannerNode → AudioContext.destination
```

For games, the most common nodes are:

| Node | Purpose |
|------|---------|
| `AudioBufferSourceNode` | Plays a loaded audio buffer |
| `GainNode` | Volume control |
| `StereoPannerNode` | Left/right panning |
| `PannerNode` | Full 3D spatial positioning |
| `BiquadFilterNode` | EQ, lowpass, highpass filters |
| `DynamicsCompressorNode` | Prevents clipping on loud sounds |

### Preloading Audio

Never load audio on demand. Load everything during startup or level load, then play from cached buffers:

```typescript
// soundCache.ts
const audioContext = new AudioContext()
const bufferCache = new Map<string, AudioBuffer>()

export async function preloadSounds(urls: string[]) {
  const promises = urls.map(async (url) => {
    const buffer = await loadSound(url)
    bufferCache.set(url, buffer)
  })
  await Promise.all(promises)
}

export function playCached(url: string, volume = 1.0) {
  const buffer = bufferCache.get(url)
  if (!buffer) {
    console.warn(`Sound not preloaded: ${url}`)
    return
  }
  playSound(buffer, volume)
}
```

---

## 3. drei PositionalAudio

### 3D Sound in the Scene

drei provides `<PositionalAudio>` -- a component that places a sound source at a 3D position in your scene. As the camera moves closer to the source, the sound gets louder. Move away, it gets quieter. Move to one side, it pans to the appropriate ear. This is spatial audio, and it makes your 3D scenes dramatically more immersive.

```tsx
import { PositionalAudio } from '@react-three/drei'
import { useRef } from 'react'
import type { PositionalAudio as PositionalAudioType } from 'three'

function NoisyMachine() {
  const soundRef = useRef<PositionalAudioType>(null)

  return (
    <mesh position={[5, 0, 0]}>
      <boxGeometry args={[1, 2, 1]} />
      <meshStandardMaterial color="#886644" />
      <PositionalAudio
        ref={soundRef}
        url="/sounds/machine-hum.mp3"
        distance={10}     // Distance at which volume is halved
        loop              // Loop the sound
        autoplay          // Start playing when component mounts
      />
    </mesh>
  )
}
```

### How Spatial Audio Works

Under the hood, `<PositionalAudio>` uses Three.js's `AudioListener` (attached to the camera) and `PositionalAudio` object (a `PannerNode` positioned in 3D space). The browser's Web Audio API handles the math: it calculates distance, applies rolloff, and adjusts stereo panning based on the listener's position and orientation relative to the source.

### Key Props

| Prop | Type | What It Does |
|------|------|--------------|
| `url` | `string` | Path to the audio file |
| `distance` | `number` | Reference distance for volume falloff (default: 1) |
| `loop` | `boolean` | Whether to loop the sound |
| `autoplay` | `boolean` | Start playing on mount |

### Distance Rolloff Models

Three.js supports different rolloff models that control how sound fades with distance:

```tsx
function SpatialSound() {
  const soundRef = useRef<PositionalAudioType>(null)

  useEffect(() => {
    if (!soundRef.current) return
    const panner = soundRef.current.getOutput() as PannerNode
    panner.distanceModel = 'inverse'   // Default: 1/distance falloff
    panner.refDistance = 5             // Distance at which volume = 1
    panner.maxDistance = 100           // Maximum audible distance
    panner.rolloffFactor = 1          // How quickly sound fades
  }, [])

  return (
    <PositionalAudio
      ref={soundRef}
      url="/sounds/engine.mp3"
      loop
      autoplay
    />
  )
}
```

The three distance models:

| Model | Behavior | Best For |
|-------|----------|----------|
| `'inverse'` | Natural 1/distance falloff | Most game sounds |
| `'linear'` | Linear fade from refDistance to maxDistance | Predictable cutoff zones |
| `'exponential'` | Steeper falloff curve | Indoor/confined spaces |

### Triggering Spatial Sounds Programmatically

For one-shot sounds (impacts, pickups), you don't want autoplay. Trigger them from code:

```tsx
function ExplodingBarrel() {
  const soundRef = useRef<PositionalAudioType>(null)
  const [exploded, setExploded] = useState(false)

  const handleClick = () => {
    if (exploded) return
    setExploded(true)
    if (soundRef.current && !soundRef.current.isPlaying) {
      soundRef.current.play()
    }
  }

  return (
    <mesh onClick={handleClick}>
      <cylinderGeometry args={[0.4, 0.4, 1, 16]} />
      <meshStandardMaterial color={exploded ? '#333' : 'red'} />
      <PositionalAudio
        ref={soundRef}
        url="/sounds/explosion.mp3"
        distance={15}
      />
    </mesh>
  )
}
```

### The AudioListener Gotcha

R3F automatically attaches an `AudioListener` to the default camera. But if you swap cameras or create a custom one, you might lose spatial audio. Make sure the active camera has a listener:

```tsx
import { useThree } from '@react-three/fiber'
import { AudioListener } from 'three'
import { useEffect } from 'react'

function EnsureAudioListener() {
  const { camera } = useThree()

  useEffect(() => {
    const listener = new AudioListener()
    camera.add(listener)
    return () => {
      camera.remove(listener)
    }
  }, [camera])

  return null
}
```

---

## 4. Howler.js

### When drei Audio Isn't Enough

drei's `<PositionalAudio>` is great for sounds tied to specific 3D objects. But for UI sounds, background music, complex sound management (pooling, sprites, cross-fading), and non-spatial effects, you want a dedicated audio library. Howler.js is the standard.

```bash
npm install howler
npm install -D @types/howler
```

### Basic Usage

```typescript
import { Howl } from 'howler'

// Create a sound
const laserSound = new Howl({
  src: ['/sounds/laser.webm', '/sounds/laser.mp3'], // Fallback formats
  volume: 0.7,
})

// Play it
laserSound.play()
```

Howler handles AudioContext resumption, format detection, and buffering automatically. It's the "just works" option.

### Audio Sprites

An audio sprite packs multiple sounds into a single file. One HTTP request, multiple sounds. This is critical for web games where dozens of individual file requests would be slow.

```typescript
const sfx = new Howl({
  src: ['/sounds/sfx-sprite.webm', '/sounds/sfx-sprite.mp3'],
  sprite: {
    hit:    [0, 500],       // Start at 0ms, duration 500ms
    pickup: [600, 300],     // Start at 600ms, duration 300ms
    jump:   [1000, 400],    // Start at 1000ms, duration 400ms
    death:  [1500, 1200],   // Start at 1500ms, duration 1200ms
    click:  [2800, 150],    // Start at 2800ms, duration 150ms
  },
})

// Play specific sounds from the sprite
sfx.play('hit')
sfx.play('pickup')
sfx.play('jump')
```

### Building a Sound Manager

For any real game, you want a centralized sound manager that handles preloading, volume control, and sound instance management:

```typescript
// soundManager.ts
import { Howl, Howler } from 'howler'

interface SoundConfig {
  src: string[]
  volume?: number
  loop?: boolean
  sprite?: Record<string, [number, number]>
}

class SoundManager {
  private sounds = new Map<string, Howl>()
  private masterVolume = 1.0
  private sfxVolume = 1.0
  private musicVolume = 0.5

  register(name: string, config: SoundConfig) {
    const howl = new Howl({
      ...config,
      volume: config.volume ?? 1.0,
    })
    this.sounds.set(name, howl)
  }

  play(name: string, sprite?: string): number | undefined {
    const sound = this.sounds.get(name)
    if (!sound) {
      console.warn(`Sound not registered: ${name}`)
      return undefined
    }
    return sound.play(sprite)
  }

  stop(name: string) {
    this.sounds.get(name)?.stop()
  }

  setMasterVolume(vol: number) {
    this.masterVolume = vol
    Howler.volume(vol)
  }

  setSfxVolume(vol: number) {
    this.sfxVolume = vol
    // Update all non-music sounds
  }

  setMusicVolume(vol: number) {
    this.musicVolume = vol
    // Update music sounds
  }

  // Play with randomized pitch for variety
  playWithVariation(name: string, sprite?: string) {
    const sound = this.sounds.get(name)
    if (!sound) return
    const id = sound.play(sprite)
    if (id !== undefined) {
      // Random pitch between 0.9 and 1.1
      sound.rate(0.9 + Math.random() * 0.2, id)
    }
  }

  // Preload all registered sounds
  preloadAll(): Promise<void> {
    const promises = Array.from(this.sounds.values()).map((howl) => {
      return new Promise<void>((resolve) => {
        if (howl.state() === 'loaded') {
          resolve()
        } else {
          howl.once('load', () => resolve())
        }
      })
    })
    return Promise.all(promises).then(() => {})
  }
}

export const soundManager = new SoundManager()
```

### Using the Sound Manager with Zustand

Wire the sound manager into your game's event system:

```typescript
// gameStore.ts
import { create } from 'zustand'
import { soundManager } from './soundManager'

interface GameState {
  score: number
  onCollision: (force: number) => void
  onPickup: () => void
}

export const useGameStore = create<GameState>((set) => ({
  score: 0,

  onCollision: (force: number) => {
    // Play impact sound with intensity-based variation
    if (force > 5) {
      soundManager.play('impact-heavy')
    } else {
      soundManager.playWithVariation('impact-light')
    }
  },

  onPickup: () => {
    set((state) => ({ score: state.score + 1 }))
    soundManager.play('pickup')
  },
}))
```

### Howler vs drei: When to Use Which

| Scenario | Use This |
|----------|----------|
| Ambient sound tied to a 3D object (humming machine, waterfall) | drei `<PositionalAudio>` |
| Sound that follows an entity moving through the scene | drei `<PositionalAudio>` as child |
| UI click/hover sounds | Howler.js |
| Background music | Howler.js |
| Impact sounds triggered by physics events | Howler.js (or Positional if you need spatialization) |
| Complex sound management (sprites, pooling, cross-fading) | Howler.js |

---

## 5. Sound Design for Games

### Generating Retro Sound Effects

You don't need a sound studio. For prototype and retro-style games, use procedural sound generators:

- **SFXR / JSFXR** -- The classic. Generates 8-bit style effects with one click. Laser shots, explosions, pickups, jumps, powerups. [jsfxr.frozenfrog.com](https://sfxr.me/) runs in the browser.
- **Chiptone** -- More advanced procedural generator with visual envelope editing.
- **Bfxr** -- Fork of SFXR with more waveforms and filters.

For each game action, generate 3-5 variations and pick the best. Or use all of them and randomize at runtime for natural variety.

### Free Sound Libraries

When you need more realistic audio:

| Library | What | License |
|---------|------|---------|
| Freesound.org | Community-uploaded sounds, huge variety | Per-sound (CC0, CC-BY, etc.) |
| OpenGameArt.org | Game-specific audio packs | Various free licenses |
| Kenney.nl | Curated game asset packs including audio | CC0 |
| Mixkit.co | Curated free sound effects | Free license |
| Pixabay.com | Royalty-free music and SFX | Pixabay license |

### The Categories of Game Sounds

Every game has the same core sound categories. Think about each one when designing your audio landscape:

**UI Sounds** -- Button clicks, menu opens, tab switches, confirmation dings, error buzzes. These are non-diegetic (not part of the game world). Keep them short (50-200ms), consistent in style, and low in the mix.

**Ambient/Environment** -- Wind, rain, birds, crowd murmur, machinery hum. These run continuously and set the mood. Layer 2-3 ambient tracks for depth. Use looping audio with natural loop points.

**Impact/Collision** -- Hits, crashes, thuds, clanks. The workhorse of game feel. These need to be punchy, immediate, and satisfying. Vary pitch and volume slightly on each play to avoid "machine gun effect" (the same sample sounding robotic when repeated).

**Feedback/Action** -- Jumps, dashes, pickups, abilities. These confirm player actions. They should be instant (zero latency) and distinct from each other. The player should be able to close their eyes and know what action occurred just from the sound.

**Music** -- Background tracks that set emotional tone. Loop seamlessly. Crossfade between tracks on scene transitions. Keep volume lower than SFX so it doesn't mask gameplay audio.

### Sound Layering

A single game event should often trigger multiple sounds layered together. An explosion isn't one sound -- it's:

1. A low "boom" for bass impact
2. A mid-range crackle for debris
3. A high-frequency "sizzle" for fire
4. A reverb tail for space

Layering multiple short, distinct sounds creates richer, more convincing audio than trying to find one perfect sample.

```typescript
function playExplosion(intensity: number) {
  soundManager.play('explosion-bass')
  soundManager.play('explosion-crackle')
  if (intensity > 0.5) {
    soundManager.play('explosion-debris')
  }
  if (intensity > 0.8) {
    soundManager.play('explosion-fire')
  }
}
```

---

## 6. Screen Shake

### The Trauma Model

Screen shake is the most common juice effect, and the most commonly implemented badly. The naive approach -- random offsets every frame -- looks jittery and nauseating. The correct approach is the **trauma model**, popularized by Squirrel Eiserloh in his GDC talk "Math for Game Programmers: Juicing Your Cameras With Math."

The model has three parts:

1. **Trauma** -- a value from 0 to 1 that represents "how shaken" the camera is
2. **Shake** -- derived from trauma (usually `trauma^2` or `trauma^3` for a snappier feel) and used to calculate offsets
3. **Decay** -- trauma decreases over time, so the shake naturally dies down

When something impactful happens, you add trauma. The shake intensity is proportional to the current trauma level. As trauma decays, the shake smoothly fades out.

```typescript
// shakeStore.ts
import { create } from 'zustand'

interface ShakeState {
  trauma: number
  addTrauma: (amount: number) => void
  decay: (delta: number) => void
}

export const useShakeStore = create<ShakeState>((set) => ({
  trauma: 0,

  addTrauma: (amount: number) =>
    set((state) => ({
      trauma: Math.min(1, state.trauma + amount),
    })),

  decay: (delta: number) =>
    set((state) => ({
      trauma: Math.max(0, state.trauma - delta * 1.5), // Decay rate
    })),
}))
```

### Implementing Camera Shake in useFrame

The critical detail: **never modify the camera's position directly.** Apply shake as an *offset* that gets reset each frame. If you add random values to `camera.position` without resetting, the camera will drift permanently.

```tsx
// CameraShake.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { useShakeStore } from '../stores/shakeStore'
import * as THREE from 'three'

const MAX_OFFSET = 0.5       // Maximum position shake in units
const MAX_ANGLE = 0.05       // Maximum rotation shake in radians
const SHAKE_FREQUENCY = 15   // Noise sample rate

export function CameraShake() {
  // Store the camera's original (intended) position
  const basePosition = useRef(new THREE.Vector3())
  const baseRotation = useRef(new THREE.Euler())
  const initialized = useRef(false)

  useFrame(({ camera, clock }, delta) => {
    const { trauma, decay } = useShakeStore.getState()

    // Capture the base position once
    if (!initialized.current) {
      basePosition.current.copy(camera.position)
      baseRotation.current.copy(camera.rotation)
      initialized.current = true
    }

    // Decay trauma
    decay(delta)

    // Calculate shake intensity (quadratic for snappier feel)
    const shake = trauma * trauma

    if (shake > 0.001) {
      const time = clock.elapsedTime * SHAKE_FREQUENCY

      // Use sin/cos at different frequencies for pseudo-random motion
      const offsetX = MAX_OFFSET * shake * Math.sin(time * 1.0)
      const offsetY = MAX_OFFSET * shake * Math.cos(time * 1.3)
      const angleZ  = MAX_ANGLE * shake * Math.sin(time * 0.9)

      // Apply offset FROM the base position (never accumulate)
      camera.position.set(
        basePosition.current.x + offsetX,
        basePosition.current.y + offsetY,
        basePosition.current.z
      )
      camera.rotation.set(
        baseRotation.current.x,
        baseRotation.current.y,
        baseRotation.current.z + angleZ
      )
    } else {
      // No shake — snap back to base
      camera.position.copy(basePosition.current)
      camera.rotation.copy(baseRotation.current)
    }
  })

  return null
}
```

### Position Shake vs Rotation Shake

Position shake moves the camera left/right and up/down. Rotation shake tilts the camera. Combining both creates the most convincing effect, but they have different feels:

- **Position shake alone** -- feels like the ground is moving. Good for explosions, earthquakes.
- **Rotation shake alone** -- feels like the player's head is rocked. Good for punches, impacts.
- **Both together** -- feels like the whole world shuddered. Best for the biggest impacts.

### Triggering Shake

From anywhere in your code:

```typescript
// Small hit — subtle shake
useShakeStore.getState().addTrauma(0.2)

// Medium impact — noticeable
useShakeStore.getState().addTrauma(0.5)

// Massive explosion — full shake
useShakeStore.getState().addTrauma(1.0)
```

Because trauma is capped at 1.0, multiple rapid hits accumulate shake naturally. Two 0.3 hits in quick succession feel like one 0.6 hit. This is a property of the model, and it feels right.

### Tuning Parameters

| Parameter | Low Value | High Value | Default |
|-----------|-----------|------------|---------|
| Decay rate | 0.5 (slow fade) | 3.0 (snappy) | 1.5 |
| Max offset | 0.1 (subtle) | 1.0 (violent) | 0.5 |
| Max angle | 0.01 (barely) | 0.1 (dizzy) | 0.05 |
| Exponent | 2 (quadratic) | 3 (cubic, snappier) | 2 |
| Frequency | 5 (slow wobble) | 30 (fast jitter) | 15 |

Start subtle. You can always increase. Too much shake is far worse than too little -- it goes from "exciting" to "nauseating" fast. Test with someone who didn't build the game.

---

## 7. Hit Stop / Freeze Frames

### What Hit Stop Is

Hit stop (also called "freeze frames" or "hit pause") is a technique where you briefly pause the game for 50-150ms when a significant impact occurs. The ball hitting the wall doesn't just bounce -- everything freezes for a split second, then resumes.

It sounds weird on paper. In practice, it's one of the most powerful game feel techniques in existence. Fighting games have used it since Street Fighter II. Every time Ryu's fist connects, the game freezes for a few frames. It makes the hit feel devastating.

### Why It Works

Your visual system needs time to process fast events. At 60fps, a collision might only be visible for 1-2 frames before the objects bounce apart. That's 16-32ms. Your brain barely registers it. By pausing for 80ms, you give the player's visual cortex time to see the moment of contact, register the deformation, and feel the weight.

Hit stop also creates **contrast**. A game running at constant speed feels monotonous. Brief pauses create a rhythm: flow-IMPACT-flow-IMPACT. That rhythm is what makes combat feel punchy and satisfying.

### Implementation: Time Scale

The simplest implementation is a global time scale that you set to 0 during hit stop, then restore:

```typescript
// timeStore.ts
import { create } from 'zustand'

interface TimeState {
  timeScale: number
  hitstopTimer: number
  triggerHitstop: (duration: number) => void
  tick: (delta: number) => void
}

export const useTimeStore = create<TimeState>((set, get) => ({
  timeScale: 1.0,
  hitstopTimer: 0,

  triggerHitstop: (duration: number) => {
    set({
      timeScale: 0.0,
      hitstopTimer: duration,
    })
  },

  tick: (realDelta: number) => {
    const { hitstopTimer } = get()
    if (hitstopTimer > 0) {
      const newTimer = hitstopTimer - realDelta
      if (newTimer <= 0) {
        set({ hitstopTimer: 0, timeScale: 1.0 })
      } else {
        set({ hitstopTimer: newTimer })
      }
    }
  },
}))
```

### Using Time Scale in useFrame

All your game systems need to respect the time scale:

```tsx
// GameClock.tsx
import { useFrame } from '@react-three/fiber'
import { useTimeStore } from '../stores/timeStore'

export function GameClock() {
  useFrame((_, realDelta) => {
    // Tick the hitstop timer with real (unscaled) delta
    useTimeStore.getState().tick(realDelta)
  })

  return null
}
```

Then in every system that should freeze during hit stop:

```tsx
function PhysicsObject() {
  const meshRef = useRef<Mesh>(null)
  const velocity = useRef(new THREE.Vector3(0, 0, -5))

  useFrame((_, realDelta) => {
    if (!meshRef.current) return

    // Scale delta by timeScale — during hitstop this is 0
    const timeScale = useTimeStore.getState().timeScale
    const delta = realDelta * timeScale

    meshRef.current.position.add(
      velocity.current.clone().multiplyScalar(delta)
    )
  })

  return (
    <mesh ref={meshRef}>
      <sphereGeometry args={[0.5, 16, 16]} />
      <meshStandardMaterial color="red" />
    </mesh>
  )
}
```

### Triggering Hit Stop

```typescript
// On a heavy collision:
useTimeStore.getState().triggerHitstop(0.08) // 80ms freeze

// On a critical hit:
useTimeStore.getState().triggerHitstop(0.15) // 150ms freeze

// On a light hit:
useTimeStore.getState().triggerHitstop(0.04) // 40ms freeze (barely noticeable but adds weight)
```

### Selective Freeze

In some games, you want only certain objects to freeze while others keep moving. For example, freeze the enemy on hit but let the player's attack animation continue. You can implement this with per-entity time scales:

```typescript
// Instead of a global timeScale, tag entities
function EnemyMesh({ id }: { id: string }) {
  const meshRef = useRef<Mesh>(null)

  useFrame((_, realDelta) => {
    if (!meshRef.current) return

    const globalScale = useTimeStore.getState().timeScale
    const entityFrozen = useTimeStore.getState().frozenEntities.has(id)

    const delta = entityFrozen ? 0 : realDelta * globalScale

    // Update with adjusted delta
    meshRef.current.rotation.y += delta
  })

  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardMaterial color="green" />
    </mesh>
  )
}
```

### Slow Motion as a Variation

Hit stop at time scale 0 is a complete freeze. But you can also do **slow motion** by setting time scale to 0.1 or 0.2 instead of 0. This gives you a brief slow-mo effect that's less jarring than a full stop:

```typescript
triggerSlowMo: (duration: number, scale: number = 0.1) => {
  set({
    timeScale: scale,
    hitstopTimer: duration,
  })
}

// Usage: slow everything to 10% speed for 200ms
useTimeStore.getState().triggerSlowMo(0.2, 0.1)
```

---

## 8. Tweens and Easing

### What Tweening Is

Tweening (short for "in-betweening") is interpolating a value from A to B over a duration, typically with an easing function that controls the rate of change. Instead of snapping a score display from 5 to 6, you tween it: the number slides from 5 to 6 over 300ms with a satisfying overshoot.

Tweens are everywhere in juicy games: scale pops when you pick something up, color flashes on damage, position slides for UI elements, rotation flourishes for level-complete animations.

### Easing Functions

An easing function takes a normalized time `t` (0 to 1) and returns a modified value (also typically 0 to 1). The shape of this curve determines the character of the motion.

```typescript
// Common easing functions
const easing = {
  // Constant speed — boring but sometimes correct
  linear: (t: number) => t,

  // Smooth start + end (most common general-purpose ease)
  easeInOutCubic: (t: number) =>
    t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2,

  // Fast start, slow end (decelerating — feels "settling")
  easeOutCubic: (t: number) => 1 - Math.pow(1 - t, 3),

  // Slow start, fast end (accelerating — feels "launching")
  easeInCubic: (t: number) => t * t * t,

  // Overshoots then settles — great for scale pops
  easeOutBack: (t: number) => {
    const c1 = 1.70158
    const c3 = c1 + 1
    return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2)
  },

  // Springy oscillation — great for bouncy UI
  easeOutElastic: (t: number) => {
    if (t === 0 || t === 1) return t
    return Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * (2 * Math.PI) / 3) + 1
  },

  // Bounces at the end like a dropped ball
  easeOutBounce: (t: number) => {
    const n1 = 7.5625
    const d1 = 2.75
    if (t < 1 / d1) return n1 * t * t
    if (t < 2 / d1) return n1 * (t -= 1.5 / d1) * t + 0.75
    if (t < 2.5 / d1) return n1 * (t -= 2.25 / d1) * t + 0.9375
    return n1 * (t -= 2.625 / d1) * t + 0.984375
  },
}
```

### Roll-Your-Own Tween with useFrame

You don't need a library for simple tweens. A tween is just: track start time, calculate elapsed ratio, apply easing, interpolate value.

```tsx
// useTween.ts
import { useRef, useCallback } from 'react'
import { useFrame } from '@react-three/fiber'

interface TweenConfig {
  from: number
  to: number
  duration: number // seconds
  easing?: (t: number) => number
  onUpdate: (value: number) => void
  onComplete?: () => void
}

export function useTween() {
  const activeTweens = useRef<(TweenConfig & { startTime: number })[]>([])

  useFrame(({ clock }) => {
    const now = clock.elapsedTime
    const tweens = activeTweens.current

    for (let i = tweens.length - 1; i >= 0; i--) {
      const tween = tweens[i]
      const elapsed = now - tween.startTime
      const rawT = Math.min(elapsed / tween.duration, 1)
      const easedT = tween.easing ? tween.easing(rawT) : rawT

      const value = tween.from + (tween.to - tween.from) * easedT
      tween.onUpdate(value)

      if (rawT >= 1) {
        tween.onComplete?.()
        tweens.splice(i, 1)
      }
    }
  })

  const startTween = useCallback((config: TweenConfig) => {
    // Remove any existing tween with the same onUpdate reference
    activeTweens.current = activeTweens.current.filter(
      (t) => t.onUpdate !== config.onUpdate
    )
    activeTweens.current.push({
      ...config,
      startTime: 0, // Will be set on first frame
    })
  }, [])

  return { startTween }
}
```

### Common Tween Patterns

**Scale pop** -- When something appears or gets collected, scale it up quickly then back to normal:

```tsx
function ScorePopup({ value }: { value: number }) {
  const textRef = useRef<any>(null)
  const scaleRef = useRef(1)

  // Pop the scale when value changes
  useEffect(() => {
    scaleRef.current = 1.5 // Start big
  }, [value])

  useFrame((_, delta) => {
    // Lerp back to 1.0 — exponential decay feels great
    scaleRef.current += (1 - scaleRef.current) * delta * 10

    if (textRef.current) {
      const s = scaleRef.current
      textRef.current.scale.set(s, s, s)
    }
  })

  return (
    <Text ref={textRef} fontSize={0.5} color="white">
      Score: {value}
    </Text>
  )
}
```

**Color flash** -- Flash white on damage, then fade back:

```tsx
function DamageFlash() {
  const matRef = useRef<THREE.MeshStandardMaterial>(null)
  const flashRef = useRef(0) // 0 = no flash, 1 = full white

  // Call this when hit
  const flash = () => {
    flashRef.current = 1.0
  }

  useFrame((_, delta) => {
    if (!matRef.current) return

    // Decay flash
    flashRef.current = Math.max(0, flashRef.current - delta * 8)

    // Interpolate between base color and white
    matRef.current.emissive.setRGB(
      flashRef.current,
      flashRef.current,
      flashRef.current
    )
    matRef.current.emissiveIntensity = flashRef.current * 3
  })

  return (
    <mesh>
      <boxGeometry />
      <meshStandardMaterial ref={matRef} color="red" />
    </mesh>
  )
}
```

**Position slide** -- Smoothly move an object to a new position:

```tsx
function SlidingPanel() {
  const meshRef = useRef<Mesh>(null)
  const targetX = useRef(0)

  useFrame((_, delta) => {
    if (!meshRef.current) return
    // Lerp toward target — smooth and frame-rate independent
    meshRef.current.position.x +=
      (targetX.current - meshRef.current.position.x) * delta * 5
  })

  return (
    <mesh
      ref={meshRef}
      onClick={() => {
        targetX.current = targetX.current === 0 ? 3 : 0
      }}
    >
      <boxGeometry args={[1, 2, 0.1]} />
      <meshStandardMaterial color="steelblue" />
    </mesh>
  )
}
```

### Using GSAP (When You Need the Big Guns)

For complex, sequenced animations with timelines, GSAP is the industry standard:

```bash
npm install gsap
```

```tsx
import gsap from 'gsap'

function AnimatedBox() {
  const meshRef = useRef<Mesh>(null)

  const playHitAnimation = () => {
    if (!meshRef.current) return

    const tl = gsap.timeline()

    tl.to(meshRef.current.scale, {
      x: 1.5,
      y: 0.5,
      z: 1.5,
      duration: 0.05,
      ease: 'power2.out',
    })
    .to(meshRef.current.scale, {
      x: 0.8,
      y: 1.3,
      z: 0.8,
      duration: 0.08,
      ease: 'power2.out',
    })
    .to(meshRef.current.scale, {
      x: 1,
      y: 1,
      z: 1,
      duration: 0.3,
      ease: 'elastic.out(1, 0.3)',
    })
  }

  return (
    <mesh ref={meshRef} onClick={playHitAnimation}>
      <boxGeometry />
      <meshStandardMaterial color="tomato" />
    </mesh>
  )
}
```

GSAP works by directly mutating properties on the target objects. Since Three.js objects' `position`, `scale`, and `rotation` are plain mutable properties, GSAP drives them seamlessly without React re-renders.

---

## 9. Particles as Feedback

### Why Particles Matter

Particles are the visual exclamation mark of game feel. A collision without particles feels clinical. The same collision with 30 tiny fragments exploding outward feels powerful and real. Particles communicate force, energy, and consequence.

The key insight: game feel particles aren't decorative. They're **functional feedback**. They tell the player something happened, how intense it was, and where it happened. Every particle burst should be informational, not just pretty.

### A Reusable Particle Burst System

You want a particle system that you can trigger from anywhere -- on collision events, pickup events, or landing events. It needs to be pooled (don't create/destroy objects constantly) and performant (instanced rendering).

```tsx
// ParticleBurst.tsx
import { useRef, useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

interface Particle {
  position: THREE.Vector3
  velocity: THREE.Vector3
  life: number
  maxLife: number
  scale: number
}

const MAX_PARTICLES = 500
const TEMP_OBJECT = new THREE.Object3D()
const TEMP_COLOR = new THREE.Color()

export function ParticleBurstSystem() {
  const meshRef = useRef<THREE.InstancedMesh>(null)
  const particles = useRef<Particle[]>([])

  // Pre-allocate particle objects
  const particlePool = useMemo(() => {
    return Array.from({ length: MAX_PARTICLES }, () => ({
      position: new THREE.Vector3(),
      velocity: new THREE.Vector3(),
      life: 0,
      maxLife: 0,
      scale: 0,
    }))
  }, [])

  // Expose a burst function via a global event or store
  const burst = (
    origin: THREE.Vector3,
    count: number = 20,
    color: string = '#ffaa00',
    speed: number = 5,
    lifetime: number = 0.6
  ) => {
    let spawned = 0
    for (const particle of particlePool) {
      if (spawned >= count) break
      if (particle.life > 0) continue // Skip active particles

      particle.position.copy(origin)
      particle.velocity.set(
        (Math.random() - 0.5) * speed,
        Math.random() * speed * 0.8,
        (Math.random() - 0.5) * speed
      )
      particle.maxLife = lifetime * (0.5 + Math.random() * 0.5)
      particle.life = particle.maxLife
      particle.scale = 0.05 + Math.random() * 0.1

      spawned++
    }
  }

  // Store the burst function somewhere accessible
  // (e.g., on a Zustand store, or use a ref + context)
  useRef(burst) // This is just to keep the reference

  useFrame((_, delta) => {
    if (!meshRef.current) return

    let visibleCount = 0

    for (const particle of particlePool) {
      if (particle.life <= 0) continue

      // Update physics
      particle.life -= delta
      particle.velocity.y -= 9.8 * delta // Gravity
      particle.position.addScaledVector(particle.velocity, delta)

      // Calculate fade
      const lifeRatio = Math.max(0, particle.life / particle.maxLife)
      const currentScale = particle.scale * lifeRatio

      // Update instance transform
      TEMP_OBJECT.position.copy(particle.position)
      TEMP_OBJECT.scale.setScalar(currentScale)
      TEMP_OBJECT.updateMatrix()

      meshRef.current.setMatrixAt(visibleCount, TEMP_OBJECT.matrix)

      // Fade color toward dark
      TEMP_COLOR.setStyle('#ffaa00')
      TEMP_COLOR.lerp(new THREE.Color('#ff2200'), 1 - lifeRatio)
      meshRef.current.setColorAt(visibleCount, TEMP_COLOR)

      visibleCount++
    }

    // Hide remaining instances by scaling to 0
    TEMP_OBJECT.scale.setScalar(0)
    TEMP_OBJECT.updateMatrix()
    for (let i = visibleCount; i < MAX_PARTICLES; i++) {
      meshRef.current.setMatrixAt(i, TEMP_OBJECT.matrix)
    }

    meshRef.current.instanceMatrix.needsUpdate = true
    if (meshRef.current.instanceColor) {
      meshRef.current.instanceColor.needsUpdate = true
    }
    meshRef.current.count = visibleCount
  })

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, MAX_PARTICLES]}>
      <sphereGeometry args={[1, 6, 6]} />
      <meshStandardMaterial
        toneMapped={false}
        emissive="#ffaa00"
        emissiveIntensity={2}
      />
    </instancedMesh>
  )
}
```

### Wiring Particles to Events via Zustand

Make the burst function accessible from your game state:

```typescript
// juiceStore.ts
import { create } from 'zustand'
import * as THREE from 'three'

type BurstFn = (
  origin: THREE.Vector3,
  count?: number,
  color?: string,
  speed?: number,
  lifetime?: number
) => void

interface JuiceState {
  burstFn: BurstFn | null
  registerBurst: (fn: BurstFn) => void
  emitBurst: (
    origin: THREE.Vector3,
    count?: number,
    color?: string,
    speed?: number,
    lifetime?: number
  ) => void
}

export const useJuiceStore = create<JuiceState>((set, get) => ({
  burstFn: null,

  registerBurst: (fn) => set({ burstFn: fn }),

  emitBurst: (origin, count, color, speed, lifetime) => {
    get().burstFn?.(origin, count, color, speed, lifetime)
  },
}))
```

Then in your particle system component, register the burst function on mount:

```tsx
useEffect(() => {
  useJuiceStore.getState().registerBurst(burst)
}, [])
```

And trigger bursts from anywhere:

```typescript
// In a collision handler:
useJuiceStore.getState().emitBurst(
  collisionPoint,  // THREE.Vector3
  30,              // particle count
  '#ffcc00',       // color
  8,               // speed
  0.5              // lifetime
)
```

### Particle Patterns for Different Events

| Event | Count | Speed | Gravity | Lifetime | Visual |
|-------|-------|-------|---------|----------|--------|
| Hard collision | 20-40 | High | Strong | Short (0.3-0.5s) | Explosive outward burst |
| Pickup/collect | 10-15 | Low | None/negative | Medium (0.5-0.8s) | Sparkles floating upward |
| Landing/dust | 15-25 | Medium, mostly horizontal | Slight | Short (0.3-0.4s) | Radial puff at ground level |
| Trail | 1-3/frame | Very low | None | Very short (0.1-0.2s) | Lingering behind fast objects |
| Destruction | 30-50 | High | Strong | Long (0.8-1.5s) | Debris shower |

---

## 10. The Juice Cascade

### One Event, Multiple Systems

Here's where everything comes together. A single game event -- a ball hitting a wall -- triggers a cascade of juice effects that fire simultaneously:

```typescript
// collision handler
function onBallHitWall(point: THREE.Vector3, force: number) {
  const normalizedForce = Math.min(force / 20, 1.0) // Normalize 0-1

  // 1. Screen shake — proportional to force
  useShakeStore.getState().addTrauma(normalizedForce * 0.6)

  // 2. Hit stop — only for significant impacts
  if (normalizedForce > 0.3) {
    useTimeStore.getState().triggerHitstop(
      0.04 + normalizedForce * 0.1 // 40-140ms
    )
  }

  // 3. Particle burst — size proportional to force
  useJuiceStore.getState().emitBurst(
    point,
    Math.floor(10 + normalizedForce * 30), // 10-40 particles
    normalizedForce > 0.7 ? '#ff4400' : '#ffaa00', // Red for heavy hits
    3 + normalizedForce * 7, // Speed 3-10
    0.3 + normalizedForce * 0.4 // Lifetime 0.3-0.7
  )

  // 4. Sound — select by intensity
  if (normalizedForce > 0.6) {
    soundManager.playWithVariation('impact-heavy')
  } else {
    soundManager.playWithVariation('impact-light')
  }

  // 5. Score
  const points = Math.floor(normalizedForce * 100)
  useGameStore.getState().addScore(points)
}
```

### The Principle: Subtle Individually, Powerful Together

Here's the thing that's hard to grasp until you experience it: each juice effect, in isolation, is barely noticeable. A tiny camera shake? Meh. A brief pause? Weird. A few particles? Whatever. A quiet thud? Fine.

But when all five fire simultaneously? The ball hits the wall and the world reacts. The camera jolts, time hiccups, sparks fly, a satisfying thunk plays, and the score snaps upward. It feels *heavy*. It feels *real*. It feels *good*.

This is the juice cascade principle. The effects don't add linearly -- they multiply. Five subtle effects together create an experience that's greater than the sum of its parts.

### The Toggle Pattern: Prove It to Yourself

The best way to understand juice is to toggle it on and off. Build a UI that lets you enable/disable each juice layer individually:

```typescript
// juiceSettings.ts
import { create } from 'zustand'

interface JuiceSettings {
  shakeEnabled: boolean
  hitstopEnabled: boolean
  particlesEnabled: boolean
  soundEnabled: boolean
  tweensEnabled: boolean
  toggleShake: () => void
  toggleHitstop: () => void
  toggleParticles: () => void
  toggleSound: () => void
  toggleTweens: () => void
}

export const useJuiceSettings = create<JuiceSettings>((set) => ({
  shakeEnabled: true,
  hitstopEnabled: true,
  particlesEnabled: true,
  soundEnabled: true,
  tweensEnabled: true,
  toggleShake: () => set((s) => ({ shakeEnabled: !s.shakeEnabled })),
  toggleHitstop: () => set((s) => ({ hitstopEnabled: !s.hitstopEnabled })),
  toggleParticles: () => set((s) => ({ particlesEnabled: !s.particlesEnabled })),
  toggleSound: () => set((s) => ({ soundEnabled: !s.soundEnabled })),
  toggleTweens: () => set((s) => ({ tweensEnabled: !s.tweensEnabled })),
}))
```

Then guard each juice trigger:

```typescript
function onBallHitWall(point: THREE.Vector3, force: number) {
  const settings = useJuiceSettings.getState()
  const normalizedForce = Math.min(force / 20, 1.0)

  if (settings.shakeEnabled) {
    useShakeStore.getState().addTrauma(normalizedForce * 0.6)
  }

  if (settings.hitstopEnabled && normalizedForce > 0.3) {
    useTimeStore.getState().triggerHitstop(0.04 + normalizedForce * 0.1)
  }

  if (settings.particlesEnabled) {
    useJuiceStore.getState().emitBurst(point, Math.floor(10 + normalizedForce * 30))
  }

  if (settings.soundEnabled) {
    soundManager.playWithVariation(normalizedForce > 0.6 ? 'impact-heavy' : 'impact-light')
  }
}
```

Fire a ball with all juice off. Then toggle them on one by one. Watch the scene transform from a tech demo into a game.

---

## 11. Background Music and Ambiance

### Looping Background Tracks

Background music sets the emotional tone of your game. The implementation is straightforward with Howler.js, but there are details that separate "music that plays" from "music that feels right."

```typescript
// music.ts
import { Howl } from 'howler'

const tracks: Record<string, Howl> = {}

export function loadTrack(name: string, src: string[]) {
  tracks[name] = new Howl({
    src,
    loop: true,
    volume: 0,  // Start silent — we'll fade in
    html5: true, // Use HTML5 audio for long tracks (saves memory)
  })
}

export function playTrack(name: string, fadeDuration: number = 2.0) {
  const track = tracks[name]
  if (!track) return

  track.play()
  track.fade(0, 0.4, fadeDuration * 1000) // Fade in over N seconds
}

export function stopTrack(name: string, fadeDuration: number = 2.0) {
  const track = tracks[name]
  if (!track) return

  track.fade(track.volume(), 0, fadeDuration * 1000)
  track.once('fade', () => {
    track.stop()
  })
}
```

Note the `html5: true` option. For short sound effects, Howler decodes the entire file into an `AudioBuffer` in memory (Web Audio mode). This gives zero-latency playback but uses a lot of memory for long tracks. The `html5` flag streams the audio instead, using far less memory at the cost of slightly higher latency. Since background music doesn't need instant playback, streaming is the right choice.

### Crossfading Between Tracks

When the player enters a new area or the game state changes, you want to smoothly transition between music tracks, not just cut.

```typescript
let currentTrackName: string | null = null

export function crossfadeTo(
  newTrackName: string,
  fadeDuration: number = 2.0
) {
  if (currentTrackName === newTrackName) return

  // Fade out current track
  if (currentTrackName) {
    stopTrack(currentTrackName, fadeDuration)
  }

  // Fade in new track
  playTrack(newTrackName, fadeDuration)
  currentTrackName = newTrackName
}

// Usage:
// Player enters boss room:
crossfadeTo('boss-battle', 1.5)

// Player returns to hub:
crossfadeTo('hub-chill', 3.0)
```

### Ambient Sound Layers

Ambiance is different from music. It's the environmental audio that makes a space feel alive: wind, birds, distant traffic, machinery hum, rain. The key is layering multiple ambient tracks that run simultaneously.

```typescript
// ambience.ts
import { Howl } from 'howler'

interface AmbientLayer {
  howl: Howl
  baseVolume: number
}

const layers = new Map<string, AmbientLayer>()

export function addAmbientLayer(
  name: string,
  src: string[],
  volume: number = 0.3
) {
  const howl = new Howl({
    src,
    loop: true,
    volume: 0,
    html5: true,
  })
  layers.set(name, { howl, baseVolume: volume })
}

export function startAmbience() {
  layers.forEach(({ howl, baseVolume }) => {
    howl.play()
    howl.fade(0, baseVolume, 3000)
  })
}

export function stopAmbience() {
  layers.forEach(({ howl }) => {
    howl.fade(howl.volume(), 0, 2000)
    howl.once('fade', () => howl.stop())
  })
}

// Setup example:
addAmbientLayer('wind', ['/sounds/amb-wind.mp3'], 0.2)
addAmbientLayer('birds', ['/sounds/amb-birds.mp3'], 0.15)
addAmbientLayer('distant-traffic', ['/sounds/amb-traffic.mp3'], 0.1)
```

### Volume Management and User Preferences

Players need control over audio. Always provide at minimum a master volume and ideally separate SFX/music sliders. Persist preferences to localStorage:

```typescript
// audioSettings.ts
import { create } from 'zustand'
import { Howler } from 'howler'

interface AudioSettings {
  masterVolume: number
  musicVolume: number
  sfxVolume: number
  setMasterVolume: (vol: number) => void
  setMusicVolume: (vol: number) => void
  setSfxVolume: (vol: number) => void
  loadFromStorage: () => void
}

export const useAudioSettings = create<AudioSettings>((set, get) => ({
  masterVolume: 1.0,
  musicVolume: 0.5,
  sfxVolume: 0.8,

  setMasterVolume: (vol: number) => {
    Howler.volume(vol)
    set({ masterVolume: vol })
    localStorage.setItem('audio-master', String(vol))
  },

  setMusicVolume: (vol: number) => {
    set({ musicVolume: vol })
    localStorage.setItem('audio-music', String(vol))
    // Update active music tracks...
  },

  setSfxVolume: (vol: number) => {
    set({ sfxVolume: vol })
    localStorage.setItem('audio-sfx', String(vol))
  },

  loadFromStorage: () => {
    const master = parseFloat(localStorage.getItem('audio-master') ?? '1.0')
    const music = parseFloat(localStorage.getItem('audio-music') ?? '0.5')
    const sfx = parseFloat(localStorage.getItem('audio-sfx') ?? '0.8')
    Howler.volume(master)
    set({ masterVolume: master, musicVolume: music, sfxVolume: sfx })
  },
}))
```

### A Simple Volume Control UI

```tsx
// VolumeControls.tsx (overlay HTML, not inside Canvas)
import { useAudioSettings } from '../stores/audioSettings'

export function VolumeControls() {
  const { masterVolume, musicVolume, sfxVolume,
          setMasterVolume, setMusicVolume, setSfxVolume } = useAudioSettings()

  return (
    <div style={{
      position: 'absolute',
      top: 10,
      right: 10,
      background: 'rgba(0,0,0,0.7)',
      padding: '12px',
      borderRadius: '8px',
      color: 'white',
      fontFamily: 'monospace',
      fontSize: '12px',
    }}>
      <div>
        Master: {Math.round(masterVolume * 100)}%
        <input
          type="range"
          min={0}
          max={1}
          step={0.05}
          value={masterVolume}
          onChange={(e) => setMasterVolume(parseFloat(e.target.value))}
        />
      </div>
      <div>
        Music: {Math.round(musicVolume * 100)}%
        <input
          type="range"
          min={0}
          max={1}
          step={0.05}
          value={musicVolume}
          onChange={(e) => setMusicVolume(parseFloat(e.target.value))}
        />
      </div>
      <div>
        SFX: {Math.round(sfxVolume * 100)}%
        <input
          type="range"
          min={0}
          max={1}
          step={0.05}
          value={sfxVolume}
          onChange={(e) => setSfxVolume(parseFloat(e.target.value))}
        />
      </div>
    </div>
  )
}
```

---

## Code Walkthrough: The Juiced-Up Ball Cannon

Let's build the complete mini-project. A ball cannon fires at a target wall. On impact, every juice system triggers simultaneously. All effects are individually toggleable.

### Project Structure

```
juicy-cannon/
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   ├── index.css
│   ├── components/
│   │   ├── Scene.tsx
│   │   ├── Cannon.tsx
│   │   ├── Ball.tsx
│   │   ├── Wall.tsx
│   │   ├── CameraShake.tsx
│   │   ├── GameClock.tsx
│   │   ├── ParticleSystem.tsx
│   │   └── ScoreDisplay.tsx
│   ├── stores/
│   │   ├── gameStore.ts
│   │   ├── shakeStore.ts
│   │   ├── timeStore.ts
│   │   ├── juiceStore.ts
│   │   └── juiceSettings.ts
│   ├── audio/
│   │   └── soundManager.ts
│   └── ui/
│       ├── JuiceToggles.tsx
│       └── VolumeControls.tsx
├── public/
│   └── sounds/
│       ├── cannon-fire.mp3
│       ├── impact-heavy.mp3
│       ├── impact-light.mp3
│       └── ambient-music.mp3
```

### Step 1: Global Styles

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
}
```

### Step 2: Stores

The shake store:

```typescript
// src/stores/shakeStore.ts
import { create } from 'zustand'

interface ShakeState {
  trauma: number
  addTrauma: (amount: number) => void
  decay: (delta: number) => void
}

export const useShakeStore = create<ShakeState>((set) => ({
  trauma: 0,
  addTrauma: (amount) =>
    set((s) => ({ trauma: Math.min(1, s.trauma + amount) })),
  decay: (delta) =>
    set((s) => ({ trauma: Math.max(0, s.trauma - delta * 1.8) })),
}))
```

The time store:

```typescript
// src/stores/timeStore.ts
import { create } from 'zustand'

interface TimeState {
  timeScale: number
  hitstopTimer: number
  triggerHitstop: (duration: number) => void
  tick: (realDelta: number) => void
}

export const useTimeStore = create<TimeState>((set, get) => ({
  timeScale: 1.0,
  hitstopTimer: 0,

  triggerHitstop: (duration) =>
    set({ timeScale: 0.0, hitstopTimer: duration }),

  tick: (realDelta) => {
    const { hitstopTimer } = get()
    if (hitstopTimer > 0) {
      const remaining = hitstopTimer - realDelta
      if (remaining <= 0) {
        set({ hitstopTimer: 0, timeScale: 1.0 })
      } else {
        set({ hitstopTimer: remaining })
      }
    }
  },
}))
```

The juice store (particle burst registration):

```typescript
// src/stores/juiceStore.ts
import { create } from 'zustand'
import * as THREE from 'three'

type BurstFn = (
  origin: THREE.Vector3,
  count?: number,
  color?: string,
  speed?: number,
  lifetime?: number
) => void

interface JuiceState {
  burstFn: BurstFn | null
  registerBurst: (fn: BurstFn) => void
  emitBurst: (
    origin: THREE.Vector3,
    count?: number,
    color?: string,
    speed?: number,
    lifetime?: number
  ) => void
}

export const useJuiceStore = create<JuiceState>((set, get) => ({
  burstFn: null,
  registerBurst: (fn) => set({ burstFn: fn }),
  emitBurst: (origin, count, color, speed, lifetime) => {
    get().burstFn?.(origin, count, color, speed, lifetime)
  },
}))
```

The game store:

```typescript
// src/stores/gameStore.ts
import { create } from 'zustand'

interface GameState {
  score: number
  addScore: (points: number) => void
  resetScore: () => void
}

export const useGameStore = create<GameState>((set) => ({
  score: 0,
  addScore: (points) => set((s) => ({ score: s.score + points })),
  resetScore: () => set({ score: 0 }),
}))
```

The juice settings:

```typescript
// src/stores/juiceSettings.ts
import { create } from 'zustand'

interface JuiceSettings {
  shakeEnabled: boolean
  hitstopEnabled: boolean
  particlesEnabled: boolean
  soundEnabled: boolean
  tweensEnabled: boolean
  toggle: (key: keyof Omit<JuiceSettings, 'toggle'>) => void
}

export const useJuiceSettings = create<JuiceSettings>((set) => ({
  shakeEnabled: true,
  hitstopEnabled: true,
  particlesEnabled: true,
  soundEnabled: true,
  tweensEnabled: true,
  toggle: (key) => set((s) => ({ [key]: !s[key as keyof typeof s] })),
}))
```

### Step 3: Sound Manager

```typescript
// src/audio/soundManager.ts
import { Howl, Howler } from 'howler'

class SoundManager {
  private sounds = new Map<string, Howl>()

  register(name: string, src: string[], options: Partial<{
    volume: number
    loop: boolean
    html5: boolean
  }> = {}) {
    this.sounds.set(name, new Howl({
      src,
      volume: options.volume ?? 1.0,
      loop: options.loop ?? false,
      html5: options.html5 ?? false,
    }))
  }

  play(name: string): number | undefined {
    const sound = this.sounds.get(name)
    if (!sound) return undefined
    return sound.play()
  }

  playWithVariation(name: string) {
    const sound = this.sounds.get(name)
    if (!sound) return
    const id = sound.play()
    if (id !== undefined) {
      sound.rate(0.85 + Math.random() * 0.3, id)
    }
  }

  stop(name: string) {
    this.sounds.get(name)?.stop()
  }

  fade(name: string, from: number, to: number, duration: number) {
    this.sounds.get(name)?.fade(from, to, duration)
  }

  setMasterVolume(vol: number) {
    Howler.volume(vol)
  }
}

export const soundManager = new SoundManager()

// Register all game sounds
soundManager.register('cannon-fire', ['/sounds/cannon-fire.mp3'], { volume: 0.6 })
soundManager.register('impact-heavy', ['/sounds/impact-heavy.mp3'], { volume: 0.8 })
soundManager.register('impact-light', ['/sounds/impact-light.mp3'], { volume: 0.5 })
soundManager.register('ambient-music', ['/sounds/ambient-music.mp3'], {
  volume: 0.3,
  loop: true,
  html5: true,
})
```

### Step 4: Camera Shake Component

```tsx
// src/components/CameraShake.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { useShakeStore } from '../stores/shakeStore'
import * as THREE from 'three'

const MAX_OFFSET = 0.4
const MAX_ANGLE = 0.04
const FREQUENCY = 17

export function CameraShake() {
  const basePos = useRef(new THREE.Vector3())
  const baseRot = useRef(new THREE.Euler())
  const init = useRef(false)

  useFrame(({ camera, clock }, delta) => {
    const { trauma, decay } = useShakeStore.getState()

    if (!init.current) {
      basePos.current.copy(camera.position)
      baseRot.current.copy(camera.rotation)
      init.current = true
    }

    decay(delta)

    const shake = trauma * trauma
    if (shake > 0.001) {
      const t = clock.elapsedTime * FREQUENCY
      const ox = MAX_OFFSET * shake * Math.sin(t * 1.0)
      const oy = MAX_OFFSET * shake * Math.cos(t * 1.3)
      const az = MAX_ANGLE * shake * Math.sin(t * 0.9)

      camera.position.set(
        basePos.current.x + ox,
        basePos.current.y + oy,
        basePos.current.z
      )
      camera.rotation.set(
        baseRot.current.x,
        baseRot.current.y,
        baseRot.current.z + az
      )
    } else {
      camera.position.copy(basePos.current)
      camera.rotation.copy(baseRot.current)
    }
  })

  return null
}
```

### Step 5: Game Clock

```tsx
// src/components/GameClock.tsx
import { useFrame } from '@react-three/fiber'
import { useTimeStore } from '../stores/timeStore'

export function GameClock() {
  useFrame((_, realDelta) => {
    useTimeStore.getState().tick(realDelta)
  })
  return null
}
```

### Step 6: Particle System

```tsx
// src/components/ParticleSystem.tsx
import { useRef, useMemo, useEffect, useCallback } from 'react'
import { useFrame } from '@react-three/fiber'
import { useJuiceStore } from '../stores/juiceStore'
import * as THREE from 'three'

const MAX_PARTICLES = 300
const TEMP_OBJ = new THREE.Object3D()

interface Particle {
  position: THREE.Vector3
  velocity: THREE.Vector3
  life: number
  maxLife: number
  size: number
}

export function ParticleSystem() {
  const meshRef = useRef<THREE.InstancedMesh>(null)

  const particles = useMemo<Particle[]>(
    () =>
      Array.from({ length: MAX_PARTICLES }, () => ({
        position: new THREE.Vector3(),
        velocity: new THREE.Vector3(),
        life: 0,
        maxLife: 1,
        size: 0.05,
      })),
    []
  )

  const burst = useCallback(
    (
      origin: THREE.Vector3,
      count: number = 20,
      _color: string = '#ffaa00',
      speed: number = 5,
      lifetime: number = 0.6
    ) => {
      let spawned = 0
      for (const p of particles) {
        if (spawned >= count) break
        if (p.life > 0) continue

        p.position.copy(origin)
        p.velocity.set(
          (Math.random() - 0.5) * speed,
          Math.random() * speed * 0.7,
          (Math.random() - 0.5) * speed
        )
        p.maxLife = lifetime * (0.5 + Math.random() * 0.5)
        p.life = p.maxLife
        p.size = 0.03 + Math.random() * 0.08
        spawned++
      }
    },
    [particles]
  )

  useEffect(() => {
    useJuiceStore.getState().registerBurst(burst)
  }, [burst])

  useFrame((_, delta) => {
    if (!meshRef.current) return

    let count = 0
    for (const p of particles) {
      if (p.life <= 0) continue

      p.life -= delta
      p.velocity.y -= 9.8 * delta
      p.position.addScaledVector(p.velocity, delta)

      const ratio = Math.max(0, p.life / p.maxLife)
      const s = p.size * ratio

      TEMP_OBJ.position.copy(p.position)
      TEMP_OBJ.scale.setScalar(s)
      TEMP_OBJ.updateMatrix()
      meshRef.current.setMatrixAt(count, TEMP_OBJ.matrix)
      count++
    }

    // Zero out unused
    TEMP_OBJ.scale.setScalar(0)
    TEMP_OBJ.updateMatrix()
    for (let i = count; i < MAX_PARTICLES; i++) {
      meshRef.current.setMatrixAt(i, TEMP_OBJ.matrix)
    }

    meshRef.current.instanceMatrix.needsUpdate = true
    meshRef.current.count = count
  })

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, MAX_PARTICLES]}>
      <sphereGeometry args={[1, 6, 6]} />
      <meshStandardMaterial
        color="#ffcc00"
        emissive="#ff6600"
        emissiveIntensity={3}
        toneMapped={false}
      />
    </instancedMesh>
  )
}
```

### Step 7: The Wall

```tsx
// src/components/Wall.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Mesh } from 'three'

export function Wall() {
  const meshRef = useRef<Mesh>(null)
  const flashRef = useRef(0)

  // Expose a flash trigger
  useFrame((_, delta) => {
    if (!meshRef.current) return
    flashRef.current = Math.max(0, flashRef.current - delta * 6)
    const mat = meshRef.current.material as THREE.MeshStandardMaterial
    mat.emissiveIntensity = flashRef.current * 2
  })

  return (
    <mesh
      ref={meshRef}
      position={[0, 2.5, -10]}
      receiveShadow
    >
      <boxGeometry args={[8, 5, 0.5]} />
      <meshStandardMaterial
        color="#556677"
        roughness={0.8}
        emissive="#ffffff"
        emissiveIntensity={0}
      />
    </mesh>
  )
}
```

### Step 8: The Ball

```tsx
// src/components/Ball.tsx
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { useTimeStore } from '../stores/timeStore'
import { useShakeStore } from '../stores/shakeStore'
import { useJuiceStore } from '../stores/juiceStore'
import { useGameStore } from '../stores/gameStore'
import { useJuiceSettings } from '../stores/juiceSettings'
import { soundManager } from '../audio/soundManager'
import * as THREE from 'three'
import type { Mesh } from 'three'

interface BallProps {
  startPosition: THREE.Vector3
  velocity: THREE.Vector3
  onDestroy: () => void
}

export function Ball({ startPosition, velocity, onDestroy }: BallProps) {
  const meshRef = useRef<Mesh>(null)
  const vel = useRef(velocity.clone())
  const alive = useRef(true)

  useFrame((_, realDelta) => {
    if (!meshRef.current || !alive.current) return

    const timeScale = useTimeStore.getState().timeScale
    const delta = realDelta * timeScale

    // Move ball
    meshRef.current.position.addScaledVector(vel.current, delta)

    // Check wall collision (wall is at z = -10)
    if (meshRef.current.position.z <= -9.75) {
      alive.current = false
      const hitPoint = meshRef.current.position.clone()
      const force = vel.current.length()
      const normalized = Math.min(force / 15, 1)

      const settings = useJuiceSettings.getState()

      // Juice cascade!
      if (settings.shakeEnabled) {
        useShakeStore.getState().addTrauma(normalized * 0.5)
      }

      if (settings.hitstopEnabled && normalized > 0.2) {
        useTimeStore.getState().triggerHitstop(0.03 + normalized * 0.08)
      }

      if (settings.particlesEnabled) {
        useJuiceStore.getState().emitBurst(
          hitPoint,
          Math.floor(10 + normalized * 25),
          '#ffaa00',
          2 + normalized * 6,
          0.3 + normalized * 0.3
        )
      }

      if (settings.soundEnabled) {
        if (normalized > 0.5) {
          soundManager.playWithVariation('impact-heavy')
        } else {
          soundManager.playWithVariation('impact-light')
        }
      }

      useGameStore.getState().addScore(Math.floor(normalized * 100))

      onDestroy()
    }

    // Kill if too far
    if (meshRef.current.position.z < -15 ||
        meshRef.current.position.y < -5) {
      alive.current = false
      onDestroy()
    }
  })

  return (
    <mesh ref={meshRef} position={startPosition} castShadow>
      <sphereGeometry args={[0.3, 16, 16]} />
      <meshStandardMaterial color="#ff4444" roughness={0.3} metalness={0.6} />
    </mesh>
  )
}
```

### Step 9: The Cannon

```tsx
// src/components/Cannon.tsx
import { useState, useCallback } from 'react'
import { Ball } from './Ball'
import { useJuiceSettings } from '../stores/juiceSettings'
import { soundManager } from '../audio/soundManager'
import * as THREE from 'three'

let ballId = 0

interface ActiveBall {
  id: number
  position: THREE.Vector3
  velocity: THREE.Vector3
}

export function Cannon() {
  const [balls, setBalls] = useState<ActiveBall[]>([])

  const fire = useCallback(() => {
    const settings = useJuiceSettings.getState()

    if (settings.soundEnabled) {
      soundManager.play('cannon-fire')
    }

    const spread = 0.3
    const newBall: ActiveBall = {
      id: ballId++,
      position: new THREE.Vector3(
        (Math.random() - 0.5) * spread,
        2,
        5
      ),
      velocity: new THREE.Vector3(
        (Math.random() - 0.5) * 2,
        (Math.random() - 0.5) * 1,
        -12 - Math.random() * 5
      ),
    }

    setBalls((prev) => [...prev, newBall])
  }, [])

  const removeBall = useCallback((id: number) => {
    setBalls((prev) => prev.filter((b) => b.id !== id))
  }, [])

  return (
    <group>
      {/* Cannon body */}
      <mesh position={[0, 2, 5.5]} rotation={[0, 0, 0]}>
        <cylinderGeometry args={[0.4, 0.5, 2, 16]} />
        <meshStandardMaterial color="#333" metalness={0.8} roughness={0.3} />
      </mesh>

      {/* Fire button — click the cannon to fire */}
      <mesh
        position={[0, 1, 6.5]}
        onClick={fire}
        onPointerOver={() => { document.body.style.cursor = 'pointer' }}
        onPointerOut={() => { document.body.style.cursor = 'auto' }}
      >
        <boxGeometry args={[1.5, 0.5, 0.5]} />
        <meshStandardMaterial color="#cc2200" emissive="#cc2200" emissiveIntensity={0.3} />
      </mesh>

      {/* Active balls */}
      {balls.map((ball) => (
        <Ball
          key={ball.id}
          startPosition={ball.position}
          velocity={ball.velocity}
          onDestroy={() => removeBall(ball.id)}
        />
      ))}
    </group>
  )
}
```

### Step 10: Score Display with Tween

```tsx
// src/components/ScoreDisplay.tsx
import { useRef, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import { useGameStore } from '../stores/gameStore'
import { useJuiceSettings } from '../stores/juiceSettings'

export function ScoreDisplay() {
  const textRef = useRef<any>(null)
  const scaleRef = useRef(1)
  const prevScore = useRef(0)

  useFrame((_, delta) => {
    if (!textRef.current) return

    // Lerp scale back to 1.0
    scaleRef.current += (1 - scaleRef.current) * delta * 8
    const s = scaleRef.current
    textRef.current.scale.set(s, s, s)
  })

  // Watch for score changes
  useEffect(() => {
    const unsub = useGameStore.subscribe((state) => {
      if (state.score !== prevScore.current) {
        prevScore.current = state.score
        const settings = useJuiceSettings.getState()
        if (settings.tweensEnabled) {
          scaleRef.current = 1.6 // Pop!
        }
      }
    })
    return unsub
  }, [])

  const score = useGameStore((s) => s.score)

  return (
    <Text
      ref={textRef}
      position={[0, 6, -9]}
      fontSize={1.2}
      color="white"
      anchorX="center"
      anchorY="middle"
      outlineWidth={0.05}
      outlineColor="#000000"
    >
      {score}
    </Text>
  )
}
```

### Step 11: Scene Composition

```tsx
// src/components/Scene.tsx
import { Wall } from './Wall'
import { Cannon } from './Cannon'
import { CameraShake } from './CameraShake'
import { GameClock } from './GameClock'
import { ParticleSystem } from './ParticleSystem'
import { ScoreDisplay } from './ScoreDisplay'
import { PositionalAudio } from '@react-three/drei'
import { useRef, useEffect } from 'react'
import type { PositionalAudio as PosAudioType } from 'three'

export function Scene() {
  return (
    <group>
      {/* Lighting */}
      <ambientLight intensity={0.3} />
      <directionalLight
        position={[5, 10, 5]}
        intensity={1.5}
        castShadow
      />

      {/* Floor */}
      <mesh
        rotation={[-Math.PI / 2, 0, 0]}
        position={[0, 0, 0]}
        receiveShadow
      >
        <planeGeometry args={[30, 30]} />
        <meshStandardMaterial color="#223344" />
      </mesh>

      {/* Game objects */}
      <Wall />
      <Cannon />
      <ScoreDisplay />

      {/* Juice systems */}
      <CameraShake />
      <GameClock />
      <ParticleSystem />
    </group>
  )
}
```

### Step 12: Juice Toggles UI

```tsx
// src/ui/JuiceToggles.tsx
import { useJuiceSettings } from '../stores/juiceSettings'

const toggles: { key: keyof Omit<ReturnType<typeof useJuiceSettings.getState>, 'toggle'>; label: string }[] = [
  { key: 'shakeEnabled', label: 'Screen Shake' },
  { key: 'hitstopEnabled', label: 'Hit Stop' },
  { key: 'particlesEnabled', label: 'Particles' },
  { key: 'soundEnabled', label: 'Sound' },
  { key: 'tweensEnabled', label: 'Tweens' },
]

export function JuiceToggles() {
  const settings = useJuiceSettings()

  return (
    <div style={{
      position: 'absolute',
      top: 10,
      left: 10,
      background: 'rgba(0,0,0,0.75)',
      padding: '12px 16px',
      borderRadius: '8px',
      color: 'white',
      fontFamily: 'monospace',
      fontSize: '13px',
      lineHeight: '1.8',
      userSelect: 'none',
    }}>
      <div style={{ fontWeight: 'bold', marginBottom: '6px' }}>
        JUICE TOGGLES
      </div>
      {toggles.map(({ key, label }) => (
        <label key={key} style={{ display: 'block', cursor: 'pointer' }}>
          <input
            type="checkbox"
            checked={settings[key] as boolean}
            onChange={() => settings.toggle(key)}
            style={{ marginRight: '8px' }}
          />
          {label}
        </label>
      ))}
      <div style={{ marginTop: '8px', fontSize: '11px', opacity: 0.6 }}>
        Click the red button to fire
      </div>
    </div>
  )
}
```

### Step 13: App

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { Scene } from './components/Scene'
import { JuiceToggles } from './ui/JuiceToggles'
import { useEffect } from 'react'
import { soundManager } from './audio/soundManager'

export default function App() {
  // Start ambient music on first click
  useEffect(() => {
    const startMusic = () => {
      soundManager.play('ambient-music')
      document.removeEventListener('click', startMusic)
    }
    document.addEventListener('click', startMusic)
    return () => document.removeEventListener('click', startMusic)
  }, [])

  return (
    <>
      <Canvas
        camera={{ position: [0, 5, 12], fov: 55 }}
        shadows
        gl={{ antialias: true }}
      >
        <Scene />
      </Canvas>
      <JuiceToggles />
    </>
  )
}
```

### Step 14: Run It

```bash
npm run dev
```

Click the red button to fire balls at the wall. Watch the juice cascade in action: camera shakes, time freezes briefly on hard hits, particles explode from impact points, sounds play with spatial variation, and the score pops when it changes. Now start toggling the juice checkboxes off one by one. Notice how each layer you remove makes the scene feel flatter, more lifeless. Toggle them all off and fire a ball. Then toggle them all back on. That delta is game feel.

---

## Common Pitfalls

### 1. AudioContext Not Resumed

Browsers require a user gesture before audio can play. If you create an AudioContext and immediately try to play, nothing happens. No error. Just silence.

```typescript
// WRONG — AudioContext is suspended, play() silently fails
const ctx = new AudioContext()
const source = ctx.createBufferSource()
source.buffer = myBuffer
source.connect(ctx.destination)
source.start() // Nothing happens

// RIGHT — resume on user gesture, then play
document.addEventListener('click', () => {
  ctx.resume().then(() => {
    const source = ctx.createBufferSource()
    source.buffer = myBuffer
    source.connect(ctx.destination)
    source.start() // Now it works
  })
}, { once: true })
```

Howler.js handles this automatically on first interaction, which is one of many reasons to use it.

### 2. Screen Shake Applied Directly to Camera Position

If you add random offsets to `camera.position` each frame without resetting, the camera drifts randomly away from where it should be. After a few shakes, the camera is in a completely wrong position.

```tsx
// WRONG — camera drifts permanently
useFrame(({ camera }) => {
  const shake = getShake()
  camera.position.x += Math.random() * shake // Accumulates!
  camera.position.y += Math.random() * shake // Never resets!
})

// RIGHT — store base position, apply offset from it
useFrame(({ camera }) => {
  const shake = getShake()
  camera.position.x = basePosition.x + Math.sin(time) * shake
  camera.position.y = basePosition.y + Math.cos(time) * shake
})
```

Always store the camera's intended position and apply shake as an offset that gets recalculated every frame from the base.

### 3. Too Much Shake / Hit Stop

This is a design pitfall, not a code bug. Excessive screen shake causes motion sickness. Excessive hit stop makes the game feel sluggish. The instinct when building juice is to crank everything up because it feels cool. Then you hand it to a player and they hate it.

```typescript
// WRONG — too much trauma, too long hit stop
useShakeStore.getState().addTrauma(1.0)           // Full shake every hit
useTimeStore.getState().triggerHitstop(0.3)       // 300ms freeze? That's an eternity

// RIGHT — proportional and subtle
const normalizedForce = Math.min(force / 20, 1)
useShakeStore.getState().addTrauma(normalizedForce * 0.4)  // Max 40% trauma
useTimeStore.getState().triggerHitstop(0.03 + normalizedForce * 0.06)  // 30-90ms
```

Start at 50% of what you think looks good. Get outside feedback. Players who didn't build the game are far more sensitive to excessive effects.

### 4. Playing the Same Sound File Simultaneously

If you play the same `Audio` object while it's already playing, the browser either ignores the request or restarts the sound. This creates a "machine gun" artifact where rapid hits sound robotic instead of natural.

```typescript
// WRONG — single instance, replays reset the sound
const impactSound = new Audio('/sounds/impact.mp3')
function onHit() {
  impactSound.currentTime = 0
  impactSound.play() // Restarting = clicks and pops
}

// RIGHT — use Howler which handles instance pooling automatically
const impactSound = new Howl({
  src: ['/sounds/impact.mp3'],
  volume: 0.7,
})
function onHit() {
  impactSound.play() // Howler creates a new instance each time
}

// EVEN BETTER — randomize pitch for variety
function onHit() {
  const id = impactSound.play()
  if (id !== undefined) {
    impactSound.rate(0.85 + Math.random() * 0.3, id)
  }
}
```

### 5. Tween Not Frame-Rate Independent

If you hardcode tween step sizes instead of using delta time, your tweens will run at different speeds on different machines.

```tsx
// WRONG — fixed step, tied to frame rate
useFrame(() => {
  scaleRef.current += (1 - scaleRef.current) * 0.1 // At 30fps this is half as fast
})

// RIGHT — multiply by delta
useFrame((_, delta) => {
  scaleRef.current += (1 - scaleRef.current) * delta * 8 // Consistent across frame rates
})
```

The delta-based approach gives you consistent behavior whether the game runs at 30fps, 60fps, or 144fps.

---

## Exercises

### Exercise 1: Spatial Audio Walkthrough

**Time:** 30--40 minutes

Create a scene with three sound-emitting objects placed at different positions: a buzzing neon sign, a bubbling fountain, and a ticking clock. Use drei's `<PositionalAudio>` for each. Add OrbitControls so you can navigate around the scene.

As you orbit, sounds should pan between your left and right ears and get louder or quieter based on distance. Experiment with the `distance` prop to find values that feel natural -- the sound should be audible from a reasonable range but fall off convincingly.

Hints:
- Place objects at least 5 units apart so the spatial effect is obvious
- Use `distance={5}` as a starting point and adjust
- Add visual indicators (glowing meshes, animated objects) so you can see the sound sources
- Make sure to add `autoplay` and `loop` to your `<PositionalAudio>` components

**Stretch goal:** Add a toggle that switches between spatial and non-spatial versions of the same sounds, so you can hear the difference.

### Exercise 2: Trauma-Based Screen Shake

**Time:** 30--40 minutes

Implement the full trauma/shake model from Section 6. Create a scene with a large red button that, when clicked, adds 0.5 trauma. Display the current trauma value as a text element.

Requirements:
- Trauma should accumulate (two fast clicks = more shake than one)
- Trauma should cap at 1.0
- Shake intensity should use `trauma^2` (quadratic) for a snappier feel
- Trauma should decay at a constant rate (around 1.5 per second)
- Include both position shake and rotation shake
- Add a slider to control the decay rate in real time

Hints:
- Use Zustand for the trauma store
- The `useFrame` shake component should be a separate null-rendering component
- Store the camera's base position on first frame, apply offsets from it
- Use `Math.sin(time * frequency)` instead of `Math.random()` for smoother motion

**Stretch goal:** Add a second button that triggers a "mega shake" (trauma = 1.0) with slower decay, and a "micro shake" (trauma = 0.15) for comparison.

### Exercise 3: The Juice Toggle Demo

**Time:** 45--60 minutes

Build a simple scene: a ball drops from a height and bounces on the floor. Then add layers of juice, each individually toggleable via checkboxes:

- **Layer 0 (base):** Ball drops, bounces, no effects. This is the "spreadsheet" version.
- **Layer 1 (+sound):** Add an impact sound on each bounce, pitched by velocity.
- **Layer 2 (+particles):** Add a particle burst at the bounce point, sized by velocity.
- **Layer 3 (+shake):** Add camera shake on bounce, trauma proportional to velocity.
- **Layer 4 (+squash/stretch):** Scale the ball (squash on contact, stretch while falling).

Toggle all off, then toggle them on one at a time. Watch the scene transform.

Hints:
- Use a ref-based bounce simulation in `useFrame` (no physics engine needed)
- Velocity at impact = good proxy for intensity of all effects
- Squash/stretch: set `scale.y` to 0.5 and `scale.x` / `scale.z` to 1.3 on contact, then tween back

**Stretch goal:** Add a "randomize" button that spawns 10 balls from random heights with random colors, all bouncing and juicing simultaneously.

### Exercise 4 (Stretch): Event-Driven Particle Bursts

**Time:** 45--60 minutes

Build a reusable particle burst system that triggers from Zustand store events. The system should:

1. Accept burst requests via a Zustand action (position, count, color, speed, lifetime)
2. Use `InstancedMesh` for performance (no individual mesh per particle)
3. Support multiple simultaneous bursts (at least 3 active at once)
4. Apply gravity to particles
5. Fade particles out as they age (scale to 0)

Wire it up to a scene with clickable cubes. Clicking a cube should:
- Destroy the cube (remove from state)
- Emit a burst of particles in the cube's color at the cube's position
- Add 3 new cubes at random positions (the scene never empties)

Hints:
- Pre-allocate a particle pool (300-500 particles)
- Each particle: `{ position, velocity, life, maxLife, size }`
- In `useFrame`, iterate all particles, update alive ones, skip dead ones
- When `burst` is called, find dead particles in the pool and revive them
- Set `instancedMesh.count` to the number of active particles for efficiency

---

## API Quick Reference

### Audio

| API / Component | What It Does | Example |
|-----------------|-------------|---------|
| `new AudioContext()` | Creates Web Audio context | `const ctx = new AudioContext()` |
| `ctx.resume()` | Resumes suspended context (required after user gesture) | `ctx.resume()` |
| `ctx.decodeAudioData()` | Decodes audio file into buffer | `const buf = await ctx.decodeAudioData(data)` |
| `new Howl({ src })` | Creates a Howler sound | `new Howl({ src: ['/snd.mp3'] })` |
| `howl.play()` | Plays the sound (returns instance ID) | `const id = sound.play()` |
| `howl.rate(r, id)` | Sets playback rate/pitch | `sound.rate(1.2, id)` |
| `<PositionalAudio>` | drei 3D spatial audio | `<PositionalAudio url="/s.mp3" distance={10} />` |

### Juice Systems

| System | Key Concept | Trigger |
|--------|------------|---------|
| Screen Shake | Trauma (0-1), quadratic decay, offset from base | `addTrauma(0.5)` |
| Hit Stop | Time scale to 0 for N ms | `triggerHitstop(0.08)` |
| Particles | Instanced pool, burst on event, gravity + fade | `emitBurst(pos, 20)` |
| Tweens | Lerp with easing, delta-time based | `scaleRef.current = 1.5` then lerp back |
| Sound | Howler play with pitch variation | `playWithVariation('impact')` |

### Easing Functions

| Function | Character | Best For |
|----------|-----------|----------|
| `linear` | Constant speed | Rarely correct for game feel |
| `easeOutCubic` | Fast start, gentle stop | Most UI transitions |
| `easeOutBack` | Overshoots, then settles | Scale pops, button presses |
| `easeOutElastic` | Springy oscillation | Bouncy UI, playful feedback |
| `easeOutBounce` | Bounces at the end | Dropped objects, landing |
| `easeInOutCubic` | Smooth start and end | Camera movements, slides |

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| ["Juice it or lose it" - Martin Jonasson & Petri Purho](https://www.youtube.com/watch?v=Fy0aCDmgnxg) | Talk (15 min) | The original juice talk. Watch it before anything else. It'll change how you think about game development. |
| ["Math for Game Programmers: Juicing Your Cameras" - Squirrel Eiserloh](https://www.youtube.com/watch?v=tu-Qe66AvtY) | GDC Talk | The definitive screen shake talk. The trauma model comes from here. |
| [Game Feel by Steve Swink](https://www.game-feel.com/) | Book | The only full book dedicated to the topic. Dense, academic, worth it. |
| [Howler.js Documentation](https://howlerjs.com/) | Docs | Complete API reference for the audio library. |
| [Web Audio API - MDN](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) | Docs | When you need to go deeper than Howler abstracts. |
| [Easings.net](https://easings.net/) | Visual Reference | Interactive visualization of every common easing curve. Bookmark it. |
| [JSFXR](https://sfxr.me/) | Tool | Browser-based retro sound effect generator. Free, instant, fun. |

---

## Key Takeaways

1. **Game feel is the 30% that makes 70% of the impression.** Identical mechanics can feel completely different depending on the feedback layer. Juice doesn't change what happens -- it changes how it feels when it happens.

2. **One event should trigger multiple feedback channels.** Sound, particles, shake, time manipulation, and animation all firing together create an impact greater than any single effect. This is the juice cascade.

3. **The trauma model is the correct way to do screen shake.** Accumulate trauma from impacts, derive shake intensity as `trauma^2`, decay trauma over time. Apply shake as an offset from the camera's base position, never directly to `camera.position`.

4. **Hit stop works because your brain needs time.** Freezing the game for 50-100ms on big impacts lets the visual system register the moment. It transforms a blink-and-miss collision into a weighty, memorable impact.

5. **Always use delta time for tweens and animations.** Multiply all movement and interpolation by `delta` from `useFrame`. This makes your effects frame-rate independent and consistent across all hardware.

6. **Audio requires a user gesture to start.** Resume your AudioContext on the first click/keypress, or use Howler.js which handles this for you. No gesture, no sound, no error -- just silence.

7. **Start subtle, get outside feedback.** The builder always thinks the juice needs to be stronger. Playtesters will tell you if it's too much. Too much shake is nauseating. Too much hit stop is sluggish. Subtlety is usually the right call.

---

## What's Next?

Your game now feels alive. Collisions have weight, pickups have sparkle, and the camera reacts to everything. The feedback layer is in place.

Next, you need to handle the transition between game states -- menus, loading screens, level transitions, and scene management. **[Module 10: UI & Menus](module-10-ui-menus.md)** covers HTML overlay UI with React, in-world HUD elements, scene transitions with crossfades, and structuring a multi-screen game that doesn't become a tangled mess.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)