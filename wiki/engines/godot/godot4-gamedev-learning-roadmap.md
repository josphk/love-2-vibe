# Godot 4 Game Dev Learning Roadmap

**For:** Programmers who want to build 3D games with Godot · Vibe-coding with Claude Code · ADHD-friendly

---

## How This Roadmap Works

This is not a "watch 40 hours of tutorials" roadmap. This is a build-first, read-second, vibe-code-everything approach to learning 3D game development with Godot 4.

**The philosophy:**

1. **Every module has a mini-project.** You learn by building, not by reading. The reading supports the building.
2. **Vibe-code aggressively.** Use Claude Code to scaffold, debug, and iterate. The goal is understanding, not typing. When you hit a wall, describe what you want and let Claude write the first pass. Then read it, break it, fix it.
3. **Modules 0-5 are linear.** Do them in order. They build your foundation: editor setup, GDScript, scene composition, assets, physics, architecture. Skip nothing.
4. **After Module 5, go non-linear.** Pick what excites you. The dependency graph below shows what unlocks what.

**Dependency graph:**

```
0 → 1 → 2 → 3 → 4 → 5 (linear foundation — do these in order)
                        ↓
         6 → 7 → 8 (artistic core — benefits from sequence but not required)
         9, 10, 11 (independent — pick any after Module 5)
         12 (independent after Module 5)
         13 (capstone — do whenever you're ready to ship)
```

After Module 5, you have a complete game-capable foundation (GDScript, scenes, assets, physics, architecture). Modules 6-8 form the "artistic core" and benefit from being done in sequence (shaders feed into post-processing, which feeds into procedural worlds), but you can jump to Module 9, 10, or 11 if you want game feel, animation, or UI first. Module 12 is multiplayer — independent after Module 5. Module 13 is your shipping capstone — do it whenever you have something worth deploying.

**All code is GDScript with static typing.** No C#. GDScript is purpose-built for Godot, its types are excellent, and the Godot community's documentation, examples, and community help all assume GDScript first.

**Time estimates are generous.** They include reading, building, breaking things, and staring at the scene tree wondering why your node disappeared. If you finish faster, great. If you need longer, that's fine too.

---

## Module 0: Setup & First Scene (Day 1)

> **Deep dive:** [Full study guide](module-00-setup-first-scene.md)

**Goal:** Get Godot 4 installed, navigate the editor, create your first 3D scene with a mesh, a light, and a script that updates every frame.

**Do this:**

1. Download Godot 4.3+ from godotengine.org — it's a single executable, no installer required
2. Create a new project and explore the editor: viewport, scene tree, inspector, file system dock
3. Add a MeshInstance3D with a SphereMesh, a DirectionalLight3D, and a Camera3D
4. Attach a GDScript to the sphere — use `_process(delta)` to rotate it every frame. This is your game loop.
5. Add click interaction: clicking the sphere changes its color or scale
6. **Mini-project:** Solar system toy — a glowing sun with orbiting planets, each spinning on its axis, clickable to display info via Label3D

**Read:**

- Godot docs — Your first 3D game: https://docs.godotengine.org/en/stable/getting_started/first_3d_game/index.html
- GDScript basics: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html

**Key concepts:**

- Godot editor layout: viewport, scene tree, inspector, file system dock
- Nodes and scenes — the fundamental building blocks of everything in Godot
- `_process(delta)` — your per-frame update loop (the heart of Godot games)
- `_ready()` — initialization called once when a node enters the scene tree
- `@export` variables — exposing properties to the inspector for easy tweaking
- MeshInstance3D + geometry resource + material = a visible 3D object

**Time:** 3–5 hours

---

## Module 1: GDScript & the Engine Lifecycle (Day 2–3)

> **Deep dive:** [Full study guide](module-01-gdscript-engine-lifecycle.md)

**Goal:** Internalize GDScript syntax, the node lifecycle, and the critical difference between `_process` and `_physics_process`.

**Do this:**

1. Work through GDScript types: `var`, static typing, `@export`, `@onready`, enums, `match`
2. Build a lifecycle demo: print from `_init`, `_enter_tree`, `_ready`, `_process`, `_physics_process`, `_exit_tree` — see the exact order
3. Build two identical balls — one updated in `_process(delta)`, one in `_physics_process(delta)`. Visualize the difference when you change the physics tick rate.
4. Set up the Input Map in Project Settings — define named actions, never hardcode keys
5. **Mini-project:** Simple character controller using `_physics_process` for movement and `_process` for visual effects (trail particles, rotation smoothing)

**Read:**

- GDScript reference: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
- Idle and physics processing: https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html

**Key concepts:**

- GDScript syntax for JS/Python devs: static typing, `@export`, `@onready`, enums, `match`
- Node lifecycle order: `_init` → `_enter_tree` → `_ready` → `_process`/`_physics_process` → `_exit_tree`
- `_process(delta)` vs `_physics_process(delta)`: render-coupled (variable) vs fixed-step (deterministic)
- Input handling: `_input(event)` vs `_unhandled_input(event)` vs `Input.is_action_pressed()`
- InputMap: the named actions system in Project Settings — decouple logic from physical keys
- GDScript built-in types: `Array`, `Dictionary`, `PackedScene`, `StringName`, `NodePath`

**Time:** 4–6 hours

---

## Module 2: Scene Composition & the Node Tree

> **Deep dive:** [Full study guide](module-02-scene-composition-nodes.md)

**Goal:** Master Godot's core architectural pattern — scenes as reusable building blocks, node composition, instancing, and the scene tree.

**Do this:**

1. Create a reusable "torch" scene: MeshInstance3D + OmniLight3D + GPUParticles3D, saved as its own `.tscn`
2. Instance it multiple times in a room scene — each instance is independent
3. Use `PackedScene.instantiate()` to spawn scenes from code at runtime
4. Use groups to broadcast messages to all matching nodes ("all torches turn off")
5. Create a base enemy scene, then use scene inheritance to create a variant enemy with different stats and mesh
6. **Mini-project:** Modular dungeon builder — reusable room scenes with doors, torches, and props assembled at runtime into a navigable dungeon

**Read:**

- Nodes and scenes: https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html
- Instancing: https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html

**Key concepts:**

- Scenes as prefabs: every `.tscn` is a self-contained, reusable node tree
- `PackedScene` and `instantiate()`: spawning scenes at runtime from code
- Node hierarchy and access: `get_node()`, `$NodeName`, `%UniqueName`
- Groups: `add_to_group()`, `get_tree().get_nodes_in_group()` — broadcast without tight coupling
- `class_name` for custom typed nodes: enables type hints and autocompletion
- Scene inheritance: extending a base scene for variants without duplication

**Time:** 5–8 hours

---

## Module 3: 3D Assets & World Building

> **Deep dive:** [Full study guide](module-03-assets-world-building.md)

**Goal:** Import GLTF models, set up materials and lighting, and build a complete 3D environment with Godot's material and environment systems.

**Do this:**

1. Download free GLTF/GLB models from Kenney or Poly Pizza
2. Import them — explore the import dock, material overrides, and animation import settings
3. Set up a three-point lighting rig: DirectionalLight3D (key) + OmniLight3D (fill) + SpotLight3D (rim)
4. Add a WorldEnvironment node with sky, ambient light, fog, and tonemap
5. Prototype level geometry with CSG nodes: CSGBox3D, CSGCylinder3D, CSGCombiner3D
6. **Mini-project:** Stylized environment diorama — composed from free assets, intentional three-point lighting, a scripted day-night cycle via code animating the DirectionalLight3D and sky color

**Read:**

- Importing 3D scenes: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html
- 3D lights and shadows: https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html
- Environment and post-processing: https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html

**Key concepts:**

- GLTF/GLB import pipeline: reimport settings, material overrides, animation import
- `StandardMaterial3D`: albedo, roughness, metallic, emission, normal maps — the PBR material
- Lighting: `DirectionalLight3D`, `OmniLight3D`, `SpotLight3D` — shadows, energy, attenuation
- `WorldEnvironment` + `Environment` resource: sky, ambient, fog, tonemap, glow
- CSG nodes for rapid level prototyping before committing to final assets
- `MeshLibrary` + `GridMap` for tile-based 3D environment building

**Time:** 5–8 hours

---

## Module 4: Physics & CharacterBody3D

> **Deep dive:** [Full study guide](module-04-physics-characterbody3d.md)

**Goal:** Build physics-driven gameplay with Godot's built-in physics — rigid bodies, character bodies, collision shapes, areas, raycasts, and joints.

**Do this:**

1. Add `CollisionShape3D` to everything — understand box, sphere, capsule, convex hull, trimesh
2. Build a floor with `StaticBody3D`, then drop `RigidBody3D` objects onto it — watch gravity and collisions work
3. Build a `CharacterBody3D` with `move_and_slide()` — WASD movement, jumping, gravity
4. Add `Area3D` triggers that fire signals on `body_entered` / `body_exited`
5. Use `RayCast3D` for ground detection and line-of-sight checks
6. Connect objects with `HingeJoint3D` and `PinJoint3D`
7. **Mini-project:** Rube Goldberg physics puzzle — dominoes, ramps, balls, seesaws, Area3D triggers. A `CharacterBody3D` walks around and kicks the first domino to start the chain.

**Read:**

- Physics introduction: https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html
- Using CharacterBody: https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html

**Key concepts:**

- `CollisionShape3D` types: box, sphere, capsule, convex hull, trimesh — choose wisely for performance
- `RigidBody3D`: dynamic physics simulation with mass, friction, bounce
- `CharacterBody3D`: `move_and_slide()`, `is_on_floor()`, `velocity` — the standard character approach
- `StaticBody3D`: immovable collision geometry for floors, walls, platforms
- `Area3D`: sensors and triggers with `body_entered` / `body_exited` signals
- `RayCast3D`: ground detection, line-of-sight, aiming systems
- Collision layers and masks: fine-grained control over what collides with what
- Joints: `HingeJoint3D`, `PinJoint3D`, `SliderJoint3D` for connected physics objects

**Time:** 5–8 hours

---

## Module 5: Signals, Resources & Game Architecture

> **Deep dive:** [Full study guide](module-05-signals-resources-architecture.md)

**Goal:** Structure a real game with signals for decoupled communication, custom Resources for data, autoloads for global state, and scene transitions.

**Do this:**

1. Declare custom signals with parameters — connect them in code and via the editor's node connections UI
2. Build a signal bus autoload for game-wide events that any scene can emit or listen to
3. Create custom `Resource` subclasses for weapon stats, enemy configs, level data — editable in the inspector
4. Set up autoloads for a game manager and audio manager
5. Build scene transitions with `get_tree().change_scene_to_packed()`
6. Implement save/load with `ConfigFile` and `Resource` serialization
7. **Mini-project:** Arena game with title screen, gameplay, pause menu, and game over screens — wave spawner, health and score tracking, save system — all wired through signals and autoloads

**Read:**

- Signals: https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- Resources: https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html
- Autoloads (singletons): https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
- Saving games: https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

**Key concepts:**

- Signals: `signal` declaration, `emit()`, `connect()` — Godot's primary decoupling mechanism
- Custom `Resource` subclasses: `class_name` + `extends Resource` for typed data containers
- Autoloads (singletons): global scripts that persist across scene changes — your game manager, audio manager, event bus
- Scene transitions: `change_scene_to_packed()` with optional loading screen
- Game manager pattern: autoload owning game phase, score, settings
- Pausing: `get_tree().paused = true` + `process_mode` per node for pause-immune UI
- Save/load: `ConfigFile`, `FileAccess`, JSON, or `ResourceSaver`/`ResourceLoader`

**Time:** 6–10 hours

---

## Module 6: Shaders & Stylized Rendering

> **Deep dive:** [Full study guide](module-06-shaders-stylized-rendering.md)

**Goal:** Write custom shaders in Godot's shading language and use the visual shader editor to build cel-shading, outlines, dissolve effects, and procedural textures.

**Do this:**

1. Start with a minimal spatial shader: `vertex()` and `fragment()` functions, basic color output
2. Pass uniforms from GDScript — time, color, noise textures — and watch them animate live
3. Build a cel-shader: quantized lighting with `smoothstep` + rim lighting
4. Add outline rendering via the inverted-hull method using `next_pass`
5. Create a dissolve effect with noise + `alpha scissor` + edge glow emission
6. Build one shader entirely in the visual shader editor (node-based)
7. **Mini-project:** Character showcase with 3 swappable shader modes: toon/cel-shaded, holographic (fresnel + scanlines), dissolve (noise-driven reveal with edge glow)

**Read:**

- Shading language reference: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html
- Spatial shader reference: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- Visual shaders: https://docs.godotengine.org/en/stable/tutorials/shaders/visual_shaders.html
- The Book of Shaders: https://thebookofshaders.com
- Godot Shaders community: https://godotshaders.com

**Key concepts:**

- Godot shading language: `shader_type`, `render_mode`, built-in variables like `NORMAL`, `UV`, `TIME`
- `shader_type spatial`: `vertex()`, `fragment()`, `light()` functions for 3D surface shaders
- Uniforms with hint annotations: `uniform sampler2D hint_default_white`
- Visual shader editor: node-based alternative — great for exploring without GLSL syntax
- Cel-shading: quantized diffuse + rim lighting using `dot` and `step`/`smoothstep`
- Dissolve: noise texture + `alpha scissor` + edge emission for a clean reveal effect
- `ShaderMaterial` vs `StandardMaterial3D`: when to go custom; `next_pass` for multi-pass effects

**Time:** 8–12 hours

---

## Module 7: Post-Processing & VFX

> **Deep dive:** [Full study guide](module-07-post-processing-vfx.md)

**Goal:** Master Godot's built-in post-processing, compositor effects, and GPUParticles3D for visual effects.

**Do this:**

1. Set up `WorldEnvironment` with an `Environment` resource — tweak glow, SSAO, SSR, and fog
2. Create `GPUParticles3D`: sparks, fire, smoke, magic trails with `ParticleProcessMaterial`
3. Build custom particle shaders for advanced per-particle behavior
4. Use `SubViewport` for pixelation and outline effects
5. Explore compositor effects (Godot 4.3+) for custom post-processing passes
6. Add volumetric fog with `VolumetricFog` settings and `FogVolume` nodes
7. **Mini-project:** Mood board scene — one 3D environment with 4 switchable Environment presets: cyberpunk (bloom + high contrast), pastoral (warm tonemap + volumetric fog), horror (desaturation + film grain), retro (pixelation via SubViewport + color reduction)

**Read:**

- Environment and post-processing: https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html
- GPU particles: https://docs.godotengine.org/en/stable/tutorials/3d/particles/index.html
- Volumetric fog: https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html
- Compositor: https://docs.godotengine.org/en/stable/tutorials/rendering/compositor.html

**Key concepts:**

- `Environment` resource: tonemap, glow/bloom, SSAO, SSR, SDFGI, fog — the rendering quality knobs
- `GPUParticles3D` + `ParticleProcessMaterial`: gravity, velocity, `color_ramp`, `scale_curve`
- Particle shaders: custom GLSL-style GPU particle behavior for things `ParticleProcessMaterial` can't do
- Compositor effects (4.3+): custom render passes inserted into the rendering pipeline
- `SubViewport` tricks: pixelation, outline post-effects, split-screen, minimap
- `VolumetricFog` + `FogVolume` nodes: localized and global volumetric fog
- `CPUParticles3D` as a fallback when GPU particles are unavailable

**Time:** 8–12 hours

---

## Module 8: Procedural & Instanced Worlds

> **Deep dive:** [Full study guide](module-08-procedural-instanced-worlds.md)

**Goal:** Generate terrain with noise, scatter thousands of instances with MultiMeshInstance3D, and build a chunked infinite world.

**Do this:**

1. Generate a heightmap from `FastNoiseLite` and apply it to an `ArrayMesh` via `SurfaceTool`
2. Color terrain by height: water, sand, grass, rock, snow — blend using height thresholds
3. Scatter trees and grass with `MultiMeshInstance3D` using Poisson disk sampling
4. Add wind animation via vertex shaders on grass instances
5. Implement chunk loading: generate and dispose terrain chunks as the camera moves
6. Add LOD with `visibility_range_begin` / `visibility_range_end` on nodes
7. **Mini-project:** Infinite procedural landscape — heightmap terrain with biome coloring, MultiMesh trees and grass with wind shaders, chunk loading/unloading, fog for draw distance

**Read:**

- ArrayMesh: https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/arraymesh.html
- SurfaceTool: https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/surfacetool.html
- Using MultiMeshInstance3D: https://docs.godotengine.org/en/stable/tutorials/3d/using_multi_mesh_instance.html

**Key concepts:**

- `FastNoiseLite`: Godot's built-in noise generator — simplex, Perlin, cellular, value
- `SurfaceTool` + `ArrayMesh`: building procedural meshes from code, vertex by vertex
- `MultiMeshInstance3D`: one draw call for thousands of identical meshes — critical for forests and grass
- `MultiMesh` resource: per-instance transforms, colors, and custom data
- Chunk loading: generate world in tiles, load/unload based on camera position
- LOD: `visibility_range_begin` / `visibility_range_end` on `GeometryInstance3D` nodes
- Poisson disk sampling: even, natural-looking distribution for object placement

**Time:** 8–12 hours

---

## Module 9: Audio & Game Feel

> **Deep dive:** [Full study guide](module-09-audio-game-feel.md)

**Goal:** Add spatial audio, screen shake, hit stop, tweens, and all the "juice" that makes games feel alive.

**Do this:**

1. Set up `AudioStreamPlayer` and `AudioStreamPlayer3D` for 2D and spatial 3D sound
2. Configure the Audio Bus Layout: master, SFX, and music buses with effects (reverb, compressor)
3. Implement camera shake via the trauma model with exponential decay
4. Add hit stop with `Engine.time_scale` manipulation and a Timer to restore it
5. Use `create_tween()` for scale bounces, color flashes, and UI slide animations
6. Layer juice: combine particles + sound + shake + flash for a single event (e.g. an enemy dying)
7. **Mini-project:** Juice up a physics playground — take your Rube Goldberg from Module 4 and add spatial audio, camera shake, hit stop, particle bursts, and satisfying tween animations

**Read:**

- Audio streams: https://docs.godotengine.org/en/stable/tutorials/audio/audio_streams.html
- Audio buses: https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html
- Tween class: https://docs.godotengine.org/en/stable/classes/class_tween.html
- "Juice it or lose it" talk: https://www.youtube.com/watch?v=Fy0aCDmgnxg

**Key concepts:**

- `AudioStreamPlayer` / `AudioStreamPlayer3D`: 2D and spatially positioned sound
- Audio Bus Layout: buses as routing channels, effects chain per bus (reverb, EQ, compressor)
- `AudioStreamRandomizer`: pitch and volume variation to avoid repetitive sound
- Camera shake: trauma model — accumulate trauma on impact, decay exponentially, apply as noise offset
- Hit stop: `Engine.time_scale = 0.05` + `Timer` to restore — freeze-frame on big impacts
- `Tween`: `create_tween()`, `tween_property()`, easing curves, chaining multiple tweens
- Juice philosophy: layering multiple small effects creates feedback that feels satisfying

**Time:** 4–6 hours

---

## Module 10: Animation — AnimationPlayer & AnimationTree

> **Deep dive:** [Full study guide](module-10-animation-player-tree.md)

**Goal:** Master Godot's animation system — keyframing any property with AnimationPlayer, blending and state machines with AnimationTree, importing Mixamo animations.

**Do this:**

1. Use `AnimationPlayer` to keyframe transforms, colors, visibility, and shader uniforms
2. Add method call tracks to trigger GDScript functions at specific frames (footstep sounds, particle bursts)
3. Import a Mixamo character with idle, walk, run, and jump animations
4. Wire an `AnimationTree` with `AnimationNodeStateMachine` for state transitions
5. Set up `BlendSpace2D` for directional movement blending (strafe left/right/forward/back)
6. Enable root motion for animation-driven character movement
7. **Mini-project:** Third-person character with a full state machine — idle, walk, run, jump, fall, land, attack. Mixamo character, AnimationTree state machine, root motion, method call tracks for footstep sounds.

**Read:**

- AnimationPlayer: https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html
- AnimationTree: https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- Retargeting 3D skeletons: https://docs.godotengine.org/en/stable/tutorials/animation/retargeting_3d_skeletons.html
- Mixamo: https://www.mixamo.com

**Key concepts:**

- `AnimationPlayer`: keyframe ANY property on ANY node — transforms, materials, visibility, uniforms
- Track types: property, method_call, audio, Bezier, blend_shape
- `AnimationTree`: compose multiple animations — state machines, blend trees, transitions
- `AnimationNodeStateMachine`: states, transitions, auto-advance, `travel()` from code
- `BlendSpace1D` / `BlendSpace2D`: directional animation blending based on input vectors
- Root motion: animation-driven movement extracted from the root bone — cleaner than script-driven
- Importing Mixamo: retargeting, animation libraries, dealing with the Y-forward skeleton

**Time:** 6–10 hours

---

## Module 11: UI & Menus

> **Deep dive:** [Full study guide](module-11-ui-menus.md)

**Goal:** Build game UI with Godot's Control node system — menus, HUDs, loading screens, health bars, and responsive layouts.

**Do this:**

1. Build a main menu with `Button`, `Label`, and `VBoxContainer`
2. Style it with a `Theme` resource: custom fonts, colors, and `StyleBox` variants per state
3. Add a `CanvasLayer` HUD that overlays the 3D scene, unaffected by the 3D camera
4. Build a pause menu that sets `get_tree().paused = true` and layers over gameplay
5. Create a minimap using `SubViewport` with a top-down `Camera3D`
6. Implement a loading screen with `ResourceLoader.load_threaded_request()`
7. **Mini-project:** Complete game UI kit — main menu (start, settings, credits), in-game HUD (health bar, score, minimap), pause menu overlay, loading screen with progress bar

**Read:**

- UI system: https://docs.godotengine.org/en/stable/tutorials/ui/index.html
- Size and anchors: https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html
- Theme editor: https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_theme_editor.html
- Background loading: https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

**Key concepts:**

- Control nodes: `Button`, `Label`, `TextureRect`, `ProgressBar`, `RichTextLabel`
- Containers and anchors: `HBoxContainer`, `VBoxContainer`, `MarginContainer`, `CenterContainer` — responsive layout
- `Theme` resource: global UI styling with fonts, colors, and `StyleBox` per control type and state
- `CanvasLayer`: HUD overlay that renders on top of the 3D scene, ignores camera transform
- Focus and navigation: keyboard and gamepad UI with `focus_neighbor_*` for accessible menus
- `SubViewport` for minimap: top-down camera rendered to a `ViewportTexture` displayed in a `TextureRect`
- `ResourceLoader` threaded loading: load scenes in the background with `load_threaded_get_status()`

**Time:** 5–8 hours

---

## Module 12: Multiplayer & Networking

> **Deep dive:** [Full study guide](module-12-multiplayer-networking.md)

**Goal:** Add multiplayer using Godot's built-in networking — ENet, RPCs, MultiplayerSpawner, MultiplayerSynchronizer, and authority.

**Do this:**

1. Set up an `ENetMultiplayerPeer` server and client — connect them on localhost first
2. Use `@rpc` to call functions across peers: authority-only and any-peer variants
3. Add `MultiplayerSpawner` for automatic scene spawning across all connected peers
4. Use `MultiplayerSynchronizer` for automatic property replication with configurable sync intervals
5. Implement authority: understand who owns which objects with `set_multiplayer_authority()`
6. Try `WebSocketMultiplayerPeer` for browser compatibility
7. **Mini-project:** Multiplayer arena — 2-4 players in a shared 3D space, seeing each other in real time, with basic interaction (tag, collect items, or simple combat)

**Read:**

- High-level multiplayer: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- MultiplayerSpawner: https://docs.godotengine.org/en/stable/classes/class_multiplayerspawner.html
- MultiplayerSynchronizer: https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html
- Gabriel Gambetta's networking articles: https://www.gabrielgambetta.com/client-server-game-architecture.html

**Key concepts:**

- High-level multiplayer API: `multiplayer` property, peer IDs, `is_server()`, authority
- `ENetMultiplayerPeer`: creating server (`create_server`) and client (`create_client`) — reliable UDP
- `@rpc` annotation: call modes (`authority`, `any_peer`), transfer modes (`reliable`, `unreliable`, `unreliable_ordered`)
- `MultiplayerSpawner`: automatic scene spawning across all peers — configure spawnable scenes
- `MultiplayerSynchronizer`: automatic property replication with configurable replication interval
- Authority: `set_multiplayer_authority()` — who has the right to drive a given node
- Server-authoritative vs client-authoritative patterns — and why server-authoritative is safer

**Time:** 8–12 hours

---

## Module 13: Build, Ship & What's Next

> **Deep dive:** [Full study guide](module-13-ship-whats-next.md)

**Goal:** Export your game to desktop and web, optimize performance, deploy to itch.io, and survey what's next.

**Do this:**

1. Configure export presets in Project > Export for Windows, macOS, Linux, and Web (HTML5)
2. Download export templates for your specific Godot version via the Export dialog
3. Export for desktop — test the executable on your platform
4. Export for Web (HTML5) — understand SharedArrayBuffer requirements and what doesn't work in browser
5. Profile with the built-in profiler and the Monitors tab in the Debugger
6. Optimize: reduce draw calls with batching, enable occlusion culling, use LOD, compress textures
7. Deploy to itch.io — configure the HTML5 embed settings
8. **Mini-project:** Take your best project from any module, polish it (loading screen, UI, compressed textures, export settings), export for desktop and web, and deploy to itch.io. Share the link.

**Read:**

- Exporting projects: https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html
- Exporting for web: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Performance: https://docs.godotengine.org/en/stable/tutorials/performance/index.html
- GDExtension: https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html

**Key concepts:**

- Export presets: per-platform settings, icons, splash screens, feature flags
- Export templates: downloading the correct templates for your Godot version — required to build
- Web export: SharedArrayBuffer requirements, COOP/COEP headers, what WebGL/WebGPU Godot supports
- Performance profiler: built-in profiler, Monitors tab, the debug draw overlays (FPS, draw calls, physics)
- Optimization: draw call batching, occlusion culling, LOD, texture compression (VRAM formats)
- itch.io deployment: HTML5 embed settings, viewport sizing, SharedArrayBuffer workarounds
- Future paths: GDExtension (C/C++/Rust for performance-critical code), mobile (Android/iOS), console, XR

**Time:** 4–8 hours

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| Godot Docs | https://docs.godotengine.org/en/stable/ | Official documentation — your primary reference |
| GDScript Reference | https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html | Language reference for GDScript |
| Godot Asset Library | https://godotengine.org/asset-library/asset | In-editor and web-browsable community assets |
| GDQuest | https://www.gdquest.com/ | Best structured Godot learning content |
| Kenney Assets | https://kenney.nl | Free CC0 game assets — models, textures, audio |
| Poly Pizza | https://poly.pizza | Free low-poly 3D models with attribution |
| Mixamo | https://www.mixamo.com | Free character animations and auto-rigging |
| Godot Shaders | https://godotshaders.com | Community shader repository — copy, learn, remix |
| SFXR | https://sfxr.me | Generate retro sound effects in seconds |
| The Book of Shaders | https://thebookofshaders.com | Best intro to fragment shaders — concepts transfer directly |
| Game Programming Patterns | https://gameprogrammingpatterns.com/ | Free online book on game architecture |
| KidsCanCode Godot Recipes | https://kidscancode.org/godot_recipes/4.x/ | Practical how-to guides for Godot 4 |
| Godot Forum | https://forum.godotengine.org/ | Community help and discussion |

---

## ADHD-Friendly Tips

- **Set a timer.** 90 minutes per session, then walk away. Your brain needs offline processing time for 3D math and node trees to click.
- **Build the mini-project first, read second.** Vibe-code the project with Claude, get it running, *then* read the docs to understand what happened. Understanding sticks better when you have working code to reference.
- **One module at a time.** Do not open Module 6 while you're in Module 3. The shiny new thing will still be there.
- **Keep a "cool ideas" file.** When inspiration strikes mid-module, write it down and get back to what you were doing. The file becomes your motivation for later modules.
- **Break on success, not failure.** Finished a mini-project? Take a break while you feel good. Don't push into the next module on fumes.
- **Use the built-in debugger.** Enable visible collision shapes, the FPS counter, the profiler, and the Monitors tab. If something looks wrong, make the invisible visible.
- **Commit constantly.** After every working state, `git commit`. Nothing kills motivation like losing an hour of progress to a bad refactor. Version-control your entire Godot project folder.
- **It's OK to skip ahead.** The dependency graph exists for a reason. If Module 5 is boring you and you really want shaders, jump to Module 6. Come back later. Motion beats perfection.
- **Pair with Claude Code.** Describe what you want in plain English. Let Claude scaffold the GDScript. Read the output. Modify it. Break it. Fix it. This is the fastest learning loop.
- **Celebrate the small wins.** A spinning mesh is a win. A bouncing rigid body is a win. Your first shader that does *anything* is a massive win. Godot's editor gives instant visual feedback — enjoy what you see on screen.
