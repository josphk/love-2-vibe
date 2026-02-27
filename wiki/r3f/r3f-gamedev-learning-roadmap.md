# React Three Fiber Game Dev Learning Roadmap

**For:** Web developers who want to build 3D games in the browser · Vibe-coding with Claude Code · ADHD-friendly

---

## How This Roadmap Works

This is not a "watch 40 hours of tutorials" roadmap. This is a build-first, read-second, vibe-code-everything approach to learning 3D game development with React Three Fiber.

**The philosophy:**

1. **Every module has a mini-project.** You learn by building, not by reading. The reading supports the building.
2. **Vibe-code aggressively.** Use Claude Code to scaffold, debug, and iterate. The goal is understanding, not typing. When you hit a wall, describe what you want and let Claude write the first pass. Then read it, break it, fix it.
3. **Modules 0-5 are linear.** Do them in order. They build your foundation: project setup, performance intuition, assets, controls, physics, architecture. Skip nothing.
4. **After Module 5, go non-linear.** Pick what excites you. The dependency graph below shows what unlocks what.

**Dependency graph:**

```
0 → 1 → 2 → 3 → 4 → 5 (linear foundation — do these in order)
                        ↓
         6 → 7 → 8 (artistic core — benefits from sequence but not required)
         9, 10, 11 (independent — pick any after Module 5)
         12 (cutting edge — builds on Modules 6-8)
         13 (capstone — do whenever you're ready to ship)
```

After Module 5, you have a complete game-capable foundation. Modules 6-8 form the "artistic core" and benefit from being done in sequence (shaders feed into post-processing, which feeds into procedural worlds), but you can jump to Module 9, 10, or 11 if you want game feel, UI, or multiplayer first. Module 12 assumes shader knowledge from 6-8. Module 13 is your shipping capstone — do it whenever you have something worth deploying.

**All code is TypeScript/TSX.** No plain JS. TypeScript catches entire categories of bugs that would otherwise waste your debugging time, and R3F's types are excellent.

**Time estimates are generous.** They include reading, building, breaking things, and staring at the screen wondering why your normals are flipped. If you finish faster, great. If you need longer, that's fine too.

---

## Module 0: Setup & First Game Loop (Day 1)

> **Deep dive:** [Full study guide](module-00-setup-first-scene.md)

**Goal:** Get a Vite + React Three Fiber project running with an interactive 3D scene that updates every frame.

**Do this:**

1. Scaffold a project with `npm create vite@latest my-r3f-game -- --template react-ts`
2. Install dependencies: `npm install three @react-three/fiber @react-three/drei`
3. Replace the default app with a `<Canvas>` containing a rotating box
4. Use `useFrame` to spin the box every frame — this is your game loop
5. Add click interaction: clicking a mesh changes its color or scale
6. **Mini-project:** Build a solar system toy — a sun with orbiting planets, each spinning on its axis, clickable to display info

**Read:**

- R3F Getting Started: https://r3f.docs.pmnd.rs/getting-started/introduction
- React Three Fiber API: https://r3f.docs.pmnd.rs/api/canvas

**Key concepts:**

- Vite project scaffolding and dev server
- `<Canvas>` component as the Three.js scene root
- `useFrame` — your per-frame update loop (the heart of R3F games)
- `useThree` — access to camera, renderer, scene, viewport
- Mesh basics: geometry + material = visible object
- Pointer events on meshes: `onClick`, `onPointerOver`, `onPointerOut`

**Time:** 3–5 hours

---

## Module 1: React Performance for Games (Day 2–3)

> **Deep dive:** [Full study guide](module-01-react-performance-for-games.md)

**Goal:** Understand why React re-renders destroy frame rates and learn the ref-mutation pattern that makes R3F games possible.

**Do this:**

1. Build a "bad" particle system using `useState` — watch it chug at 100+ particles
2. Rebuild it using `useRef` and direct mutation in `useFrame` — watch it handle 500+ easily
3. Profile both versions with React DevTools and `r3f-perf`
4. Convert particles to `InstancedMesh` for massive throughput
5. **Mini-project:** Particle fountain — 500+ particles spawning, falling with gravity, recycling. Include a toggle to switch between the useState version (broken) and the useRef version (smooth) so you viscerally feel the difference

**Read:**

- R3F Performance Pitfalls: https://r3f.docs.pmnd.rs/advanced/pitfalls
- React Three Fiber scaling: https://r3f.docs.pmnd.rs/advanced/scaling-performance
- r3f-perf: https://github.com/utsuboco/r3f-perf

**Key concepts:**

- React reconciler overhead: why setState triggers re-render, and why re-renders at 60fps = death
- `useRef` for mutable game state that bypasses React's render cycle
- The `useFrame` mutation pattern: read refs, mutate transforms, never setState
- `InstancedMesh` for rendering thousands of identical objects in one draw call
- R3F performance pitfalls: unnecessary re-renders, inline objects, missing keys

**Time:** 4–6 hours

---

## Module 2: 3D Assets & World Building

> **Deep dive:** [Full study guide](module-02-assets-world-building.md)

**Goal:** Load GLTF models, set up materials and lighting, and compose a complete 3D scene.

**Do this:**

1. Download free GLTF models from Kenney or Poly Pizza
2. Use `useGLTF` with Draco compression to load them efficiently
3. Set up a three-point lighting rig: ambient + directional + fill
4. Add `Environment` from drei for image-based lighting
5. Experiment with `ContactShadows`, `Stage`, and `AccumulativeShadows`
6. **Mini-project:** Build a stylized environment diorama — a small scene (campsite, room, island) composed from free assets with intentional lighting that sets a mood

**Read:**

- drei documentation: https://drei.docs.pmnd.rs/
- Kenney free assets: https://kenney.nl
- Poly Pizza: https://poly.pizza
- gltfjsx (auto-generates R3F components from GLTF): https://github.com/pmndrs/gltfjsx

**Key concepts:**

- GLTF as the "JPEG of 3D" — the standard format for web 3D
- `useGLTF` and `useGLTF.preload` for async model loading
- Draco compression: smaller files, faster loads
- PBR materials: roughness, metalness, normal maps, emissive
- Lighting rigs: ambient, directional, point, spot, hemisphere
- Drei helpers: `Environment`, `Stage`, `ContactShadows`, `Sky`, `Stars`

**Time:** 5–8 hours

---

## Module 3: Cameras, Input & Character Control

> **Deep dive:** [Full study guide](module-03-cameras-input-character.md)

**Goal:** Implement third-person and first-person camera systems, handle keyboard/gamepad input, and get a character moving through a 3D world.

**Do this:**

1. Set up `OrbitControls` for free camera exploration
2. Switch to `PointerLockControls` for first-person mouselook
3. Use `KeyboardControls` from drei for WASD movement
4. Integrate `ecctrl` (Eric's character controller) for a full third-person setup
5. Add gamepad support via the Gamepad API
6. **Mini-project:** Walking character in a 3D environment — load a character model, animate it with idle/walk/run, follow camera, keyboard + gamepad input

**Read:**

- drei controls: https://drei.docs.pmnd.rs/controls/orbit-controls
- ecctrl character controller: https://github.com/pmndrs/ecctrl
- KeyboardControls: https://drei.docs.pmnd.rs/controls/keyboard-controls
- Mixamo for character animations: https://www.mixamo.com

**Key concepts:**

- `OrbitControls` for development and strategy-style cameras
- `PointerLockControls` for FPS-style mouselook
- `KeyboardControls` from drei: declarative input mapping
- `ecctrl` character controller: physics-based movement with camera follow
- Gamepad API: polling-based input for controllers
- Camera smoothing: lerp, slerp, damping

**Time:** 5–8 hours

---

## Module 4: Physics with Rapier

> **Deep dive:** [Full study guide](module-04-physics-rapier.md)

**Goal:** Add physics simulation with @react-three/rapier — rigid bodies, colliders, sensors, joints, and raycasting.

**Do this:**

1. Install `@react-three/rapier` and wrap your scene in `<Physics>`
2. Add `RigidBody` components: dynamic (falls), static (floor), kinematicPosition (scripted)
3. Experiment with collider shapes: cuboid, ball, trimesh, convexHull
4. Build triggers with sensor colliders and `onIntersectionEnter`
5. Connect objects with joints: fixed, revolute, prismatic, spherical
6. Implement raycasting for ground detection and line-of-sight
7. **Mini-project:** Rube Goldberg physics puzzle — chain reaction of dominoes, ramps, balls, seesaws, and triggers. Toggle physics debug wireframes to see colliders.

**Read:**

- React Three Rapier docs: https://github.com/pmndrs/react-three-rapier
- Rapier.rs documentation: https://rapier.rs/docs/

**Key concepts:**

- `RigidBody` types: dynamic, static, kinematicPosition, kinematicVelocity
- Collider shapes: automatic from mesh, or explicit (cuboid, ball, capsule, trimesh, convexHull)
- Sensors and triggers: `sensor` prop, `onIntersectionEnter/Exit`
- Joints: connecting bodies with constraints (revolute, prismatic, fixed, spherical)
- Raycasting: `rapier.castRay` for ground checks, aiming, line-of-sight
- `<Debug />` component for visualizing collider wireframes

**Time:** 5–8 hours

---

## Module 5: Game Architecture & State

> **Deep dive:** [Full study guide](module-05-game-architecture-state.md)

**Goal:** Structure a real game with Zustand state management, scene transitions, and optionally ECS patterns.

**Do this:**

1. Create a Zustand store for game state: score, health, game phase, settings
2. Use `subscribeWithSelector` to react to specific state changes without re-rendering
3. Build scene management: title screen, gameplay, pause overlay, game over
4. Implement a fixed timestep game loop for deterministic updates
5. Explore ECS with miniplex or bitECS for entity management
6. **Mini-project:** A structured game (simple arena shooter or platformer) with title screen, gameplay with HUD, pause menu, game over screen, score tracking — all wired through Zustand

**Read:**

- Zustand: https://docs.pmnd.rs/zustand/getting-started/introduction
- miniplex ECS: https://github.com/hmans/miniplex
- bitECS: https://github.com/NateTheGreatt/bitECS
- Game Programming Patterns (free online): https://gameprogrammingpatterns.com/

**Key concepts:**

- Zustand stores: simple, un-opinionated state outside React's render cycle
- `subscribeWithSelector`: subscribe to slices of state for performant updates
- Scene management: conditional rendering vs. mount/unmount vs. visibility
- ECS (Entity Component System): entities are IDs, components are data, systems are logic
- Fixed timestep: deterministic updates decoupled from frame rate
- Game clock: delta time, elapsed time, pause/resume

**Time:** 6–10 hours

---

## Module 6: Shaders & Stylized Rendering

> **Deep dive:** [Full study guide](module-06-shaders-stylized-rendering.md)

**Goal:** Write custom shaders in GLSL, explore Three.js TSL, and build stylized rendering effects like cel-shading and outlines.

**Do this:**

1. Start with `ShaderMaterial`: write a minimal vertex + fragment shader
2. Pass uniforms (time, color, mouse position) and watch them animate
3. Build a cel-shader: quantize lighting into discrete bands
4. Add outline rendering via inverted-hull or post-processing
5. Explore TSL (Three Shading Language) as a TypeScript-native alternative to GLSL
6. Create procedural textures: noise, stripes, dots, gradients — all in shader code
7. **Mini-project:** Character showcase with 3 swappable material modes: toon/cel-shaded, watercolor (noise-distorted edges + paper texture), and holographic (fresnel + scanlines + chromatic aberration)

**Read:**

- The Book of Shaders: https://thebookofshaders.com
- Shadertoy: https://www.shadertoy.com
- Three.js ShaderMaterial: https://threejs.org/docs/#api/en/materials/ShaderMaterial
- Three.js TSL Docs: https://threejs.org/docs/pages/TSL.html

**Key concepts:**

- `ShaderMaterial` and `RawShaderMaterial`: custom GPU programs in R3F
- Uniforms: passing CPU data (time, resolution, mouse) to shaders
- Vertex shaders: transform positions, pass varyings
- Fragment shaders: compute per-pixel color
- TSL (Three Shading Language): node-based shader authoring in TypeScript
- Cel-shading: quantized diffuse lighting, rim lighting
- Outline passes: inverted hull method, edge detection
- Procedural textures: noise, patterns, UV manipulation

**Time:** 8–12 hours

---

## Module 7: Post-Processing & VFX

> **Deep dive:** [Full study guide](module-07-post-processing-vfx.md)

**Goal:** Master the post-processing pipeline with EffectComposer, build visual presets, and create particle-based VFX.

**Do this:**

1. Install `@react-three/postprocessing` and set up `EffectComposer`
2. Stack effects: bloom, vignette, chromatic aberration, noise
3. Add color grading with LUT textures and tone mapping
4. Build a custom effect by extending the Effect class
5. Create particle systems: sparks, fire, smoke, magic trails
6. **Mini-project:** Mood board scene — a single 3D environment with 4 switchable visual presets: cyberpunk (bloom + chromatic aberration + scanlines), pastoral (warm grading + soft vignette + god rays), horror (desaturation + film grain + fog), retro (pixelation + dithering + CRT warp)

**Read:**

- @react-three/postprocessing: https://github.com/pmndrs/react-postprocessing
- pmndrs postprocessing (underlying lib): https://github.com/pmndrs/postprocessing
- drei particle helpers: https://drei.docs.pmnd.rs/

**Key concepts:**

- `EffectComposer`: the post-processing pipeline manager
- Effect stacking order: effects apply sequentially, order matters
- Bloom: emissive threshold, intensity, radius
- Color grading: LUT textures, tone mapping, white balance
- Custom effects: extending `Effect` with custom GLSL fragments
- Particle systems: instanced geometry, shader-driven animation, pooling
- Trails and ribbons: `Trail` from drei, custom trail geometry

**Time:** 8–12 hours

---

## Module 8: Procedural & Instanced Worlds

> **Deep dive:** [Full study guide](module-08-procedural-instanced-worlds.md)

**Goal:** Generate terrain with noise functions, scatter thousands of instances efficiently, and build an infinite scrolling world.

**Do this:**

1. Generate a heightmap from Simplex noise and apply it to a plane geometry
2. Color the terrain based on height: water, sand, grass, rock, snow
3. Scatter trees and grass with `InstancedMesh` using Poisson disk sampling
4. Add wind animation via vertex shaders on the grass instances
5. Implement chunked loading: generate/dispose terrain chunks as the camera moves
6. Add LOD (Level of Detail) for distant objects
7. **Mini-project:** Infinite procedural landscape — endless terrain with biome coloring, instanced trees and grass with wind shaders, chunked loading/unloading, fog for draw distance

**Read:**

- Simplex noise: https://github.com/jwagner/simplex-noise
- Three.js InstancedMesh: https://threejs.org/docs/#api/en/objects/InstancedMesh
- Three.js BatchedMesh: https://threejs.org/docs/#api/en/objects/BatchedMesh

**Key concepts:**

- Simplex/Perlin noise: coherent randomness for natural-looking terrain
- Heightmap generation: noise → vertex displacement on a subdivided plane
- `InstancedMesh`: one draw call for thousands of identical meshes with per-instance transforms
- `BatchedMesh`: similar to instanced but supports different geometries
- LOD (Level of Detail): swap geometry complexity based on camera distance
- Chunked loading: generate world in tiles, load/unload based on camera position
- Poisson disk sampling: even distribution for natural-looking object placement

**Time:** 8–12 hours

---

## Module 9: Audio & Game Feel

> **Deep dive:** [Full study guide](module-09-audio-game-feel.md)

**Goal:** Add spatial audio, screen shake, hit stop, tweens, and all the "juice" that makes games feel alive.

**Do this:**

1. Set up the Web Audio API context and play sounds on interaction
2. Add spatial/positional audio with drei's `PositionalAudio`
3. Implement screen shake: randomize camera offset on impact, decay over time
4. Add hit stop (freeze frames): pause the game clock for 50-100ms on big hits
5. Layer juice: combine particles + sound + shake + flash for a single event
6. Use tweens for smooth transitions: scale bounces, color flashes, UI slides
7. **Mini-project:** Juice up a physics playground — take your Rube Goldberg from Module 4 (or build a simple breakout/shooting gallery) and add spatial audio for collisions, camera shake on impacts, hit stop on big events, particle bursts, and satisfying tweened animations

**Read:**

- drei audio: https://drei.docs.pmnd.rs/abstractions/positional-audio
- Howler.js: https://howlerjs.com
- SFXR (generate retro sound effects): https://sfxr.me
- "Juice it or lose it" talk: https://www.youtube.com/watch?v=Fy0aCDmgnxg

**Key concepts:**

- Web Audio API: AudioContext, spatial panning, gain nodes
- `PositionalAudio` from drei: 3D-positioned sound sources
- Howler.js: cross-browser audio library with sprite support
- Screen shake: camera offset with exponential decay
- Hit stop / freeze frames: brief time scale pause for impact emphasis
- Tweens: eased interpolation for scale, position, color, opacity
- Juice philosophy: layering multiple small effects to create satisfying feedback

**Time:** 4–6 hours

---

## Module 10: UI & Menus

> **Deep dive:** [Full study guide](module-10-ui-menus.md)

**Goal:** Build game UI with HTML overlays and in-world 3D elements — menus, HUDs, loading screens, and health bars.

**Do this:**

1. Use drei's `Html` component to place HTML elements in 3D space
2. Build a HUD with a standard React overlay (absolute-positioned div over the canvas)
3. Use `tunnel-rat` to render React portals from inside R3F to outside the Canvas
4. Create `Billboard` text and sprites for in-world labels
5. Build a loading screen with `Suspense` and drei's `useProgress`
6. **Mini-project:** Complete game UI kit — main menu (start, settings, credits), in-game HUD (health, score, minimap), pause menu overlay, in-world floating health bars over enemies, loading screen with progress bar

**Read:**

- drei Html: https://drei.docs.pmnd.rs/misc/html
- drei Billboard: https://drei.docs.pmnd.rs/abstractions/billboard
- tunnel-rat: https://github.com/pmndrs/tunnel-rat
- drei useProgress: https://drei.docs.pmnd.rs/loaders/use-progress

**Key concepts:**

- `Html` from drei: DOM elements positioned in 3D space, occludable by geometry
- `Billboard`: sprites/text that always face the camera
- HTML/CSS overlay: standard React UI rendered on top of the Canvas
- `tunnel-rat`: bidirectional portals between R3F and React DOM
- `Suspense` + `useProgress`: loading states for async assets
- Health bars: world-space `Html` or shader-based billboard quads
- Responsive design: adapting UI to screen size and aspect ratio

**Time:** 4–6 hours

---

## Module 11: Multiplayer & Networking

> **Deep dive:** [Full study guide](module-11-multiplayer-networking.md)

**Goal:** Add real-time multiplayer with WebSockets, handle state synchronization, and build a shared 3D space.

**Do this:**

1. Set up a WebSocket server (Node.js) that broadcasts player positions
2. Connect R3F clients and render other players' positions
3. Implement client-side prediction: move locally, reconcile with server
4. Add interpolation to smooth other players' movement
5. Explore Colyseus for room-based multiplayer with schema sync
6. Try PartyKit for serverless multiplayer
7. **Mini-project:** Multiplayer arena — 2-4 players moving in a shared 3D space, seeing each other in real time, with basic interaction (tag, collect items, or simple combat)

**Read:**

- Colyseus: https://colyseus.io
- PartyKit: https://partykit.io
- WebSocket API: https://developer.mozilla.org/en-US/docs/Web/API/WebSocket
- Gabriel Gambetta's networking articles: https://www.gabrielgambetta.com/client-server-game-architecture.html

**Key concepts:**

- WebSocket basics: persistent bidirectional connection
- Authoritative server: server owns game state, clients are renderers
- Client-side prediction: act immediately, reconcile with server later
- Entity interpolation: smooth rendering of remote entity positions
- Colyseus: room-based multiplayer framework with automatic state sync
- PartyKit: serverless WebSocket rooms on Cloudflare
- Bandwidth optimization: delta compression, update frequency, relevancy filtering

**Time:** 8–12 hours

---

## Module 12: WebGPU & The Cutting Edge

> **Deep dive:** [Full study guide](module-12-webgpu-cutting-edge.md)

**Goal:** Explore WebGPU rendering, deep-dive into TSL node materials, and harness compute shaders for massive simulations.

**Do this:**

1. Switch to `WebGPURenderer` in your R3F setup (Three.js r169+)
2. Build a TSL node material: combine noise, lighting, and animation nodes
3. Write a compute shader that updates particle positions on the GPU
4. Use storage buffers to read/write particle data without CPU round-trips
5. Profile WebGPU vs WebGL rendering performance
6. **Mini-project:** 100k+ GPU particle simulation — particles driven entirely by compute shaders, with forces (gravity, wind, attractors), collision with a surface, and color based on velocity. Zero CPU particle logic.

**Read:**

- Three.js TSL Docs: https://threejs.org/docs/pages/TSL.html
- WebGPU Fundamentals: https://webgpufundamentals.org
- Three.js WebGPU examples: https://threejs.org/examples/?q=webgpu

**Key concepts:**

- `WebGPURenderer`: Three.js's next-gen renderer, replacing WebGL
- TSL (Three Shading Language): node-based materials that compile to WGSL or GLSL
- Compute shaders: general-purpose GPU computation (not just rendering)
- Storage buffers: GPU-side read/write data for compute pipelines
- GPU particle systems: update + render entirely on GPU
- R3F compatibility: current state of R3F + WebGPU integration
- Feature detection: graceful fallback when WebGPU is unavailable

**Time:** 6–10 hours

---

## Module 13: Build, Ship & What's Next

> **Deep dive:** [Full study guide](module-13-ship-whats-next.md)

**Goal:** Optimize, compress, deploy, and get your game in front of players. Then look at what's next.

**Do this:**

1. Configure Vite for production: tree-shaking, code splitting, chunk optimization
2. Compress assets: Draco for meshes, KTX2/Basis for textures
3. Audit bundle size: `npx vite-bundle-visualizer`
4. Deploy to Vercel or Netlify with proper caching headers
5. Package as a PWA with offline support
6. Explore WebXR basics: VR/AR in the browser with R3F
7. **Mini-project:** Take your best project from any module, polish it (loading screen, responsive UI, compressed assets, error boundaries), and ship it live to Vercel or itch.io. Share the link.

**Read:**

- Vite build docs: https://vite.dev/guide/build
- Draco compression: https://google.github.io/draco/
- KTX2 textures: https://github.com/KhronosGroup/KTX-Software
- @react-three/xr: https://github.com/pmndrs/xr
- Vercel deployment: https://vercel.com/docs
- itch.io HTML5 games: https://itch.io/docs/creators/html5

**Key concepts:**

- Vite production build: minification, tree-shaking, chunk splitting
- Draco mesh compression: 90%+ size reduction for geometry
- KTX2/Basis texture compression: GPU-native compressed textures
- Bundle analysis: identifying bloat, lazy loading heavy modules
- Deployment: Vercel, Netlify, Cloudflare Pages, itch.io
- PWA manifest: installable web app with offline support
- WebXR intro: `@react-three/xr` for VR/AR experiences
- Future paths: native apps (Electron/Tauri), mobile (React Native), advanced AI integration

**Time:** 4–8 hours

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| R3F Docs | https://r3f.docs.pmnd.rs/ | Official React Three Fiber documentation |
| Three.js Docs | https://threejs.org/docs/ | The underlying engine — you'll reference this constantly |
| Drei | https://drei.docs.pmnd.rs/ | Hundreds of R3F helpers — check here before building from scratch |
| React Three Rapier | https://github.com/pmndrs/react-three-rapier | Physics engine bindings for R3F |
| Three.js TSL Docs | https://threejs.org/docs/pages/TSL.html | Node-based shading language reference |
| Poimandres GitHub | https://github.com/pmndrs | The team behind R3F, Drei, Zustand, and more |
| Kenney Assets | https://kenney.nl | Free CC0 game assets — models, textures, audio |
| Poly Pizza | https://poly.pizza | Free low-poly 3D models with attribution |
| Sketchfab (free) | https://sketchfab.com/features/free-3d-models | High-quality free 3D models |
| Mixamo | https://www.mixamo.com | Free character animations — rigging and motion capture |
| r3f-perf | https://github.com/utsuboco/r3f-perf | Performance monitor overlay for R3F |
| SFXR | https://sfxr.me | Generate retro sound effects in seconds |
| Shadertoy | https://www.shadertoy.com | Shader examples and inspiration — endless rabbit hole |
| The Book of Shaders | https://thebookofshaders.com | Best introduction to fragment shaders on the web |

---

## ADHD-Friendly Tips

- **Set a timer.** 90 minutes per session, then walk away. Your brain needs offline processing time for 3D math to click.
- **Build the mini-project first, read second.** Vibe-code the project with Claude, get it running, *then* read the docs to understand what happened. Understanding sticks better when you have working code to reference.
- **One module at a time.** Do not open Module 6 while you're in Module 3. The shiny new thing will still be there.
- **Keep a "cool ideas" file.** When inspiration strikes mid-module, write it down and get back to what you were doing. The file becomes your motivation for later modules.
- **Break on success, not failure.** Finished a mini-project? Take a break while you feel good. Don't push into the next module on fumes.
- **Use the debug overlay.** `r3f-perf` and physics debug wireframes are your sanity checks. If something looks wrong, make the invisible visible.
- **Commit constantly.** After every working state, `git commit`. Nothing kills motivation like losing an hour of progress to a bad refactor.
- **It's OK to skip ahead.** The dependency graph exists for a reason. If Module 5 is boring you and you really want shaders, jump to Module 6. Come back later. Motion beats perfection.
- **Pair with Claude Code.** Describe what you want in plain English. Let Claude scaffold it. Read the output. Modify it. Break it. Fix it. This is the fastest loop for learning.
- **Celebrate the small wins.** A spinning cube is a win. A bouncing ball is a win. Your first shader that does *anything* is a massive win. Games are visual — enjoy what you see on screen.
