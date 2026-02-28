# Godot Gauntlet: 10-Challenge Series

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Format:** Challenge series (not a tutorial)
**Prerequisites:** Modules 01–07 completed; Modules 08–13 helpful but not required

---

## What This Is

The 13 modules gave you a solid foundation: scenes, scripting, shaders, animation, physics, procedural generation, UI, multiplayer, and shipping. You have built 3D worlds. That is real knowledge.

Four pillars are still missing — and they are the ones that separate competent Godot developers from people who can build genuinely unusual things:

- **2D Systems Depth** — CanvasLight2D with normal maps, Skeleton2D with IK, TileMap physics layers. 2D in Godot is not a subset of 3D — it has its own rendering pipeline, its own animation rigs, and its own lighting engine. Most of the roadmap skipped it.
- **Post-Processing Pipeline** — SubViewport compositing, screen-space shader chains, multi-pass rendering. Module 06 taught you to write shaders. This teaches you to build the pipeline that applies them to the whole frame.
- **Advanced AI** — Behavior trees in GDScript, vision cones, hearing radii, blackboard state, squad broadcasts. Module 07 introduced enemy patterns. This formalizes them into a reusable architecture.
- **GPU Simulation** — GPUParticles3D GLSL process shader overrides, image ping-pong cellular automata. Module 08 used CPUParticles. This moves simulation work onto the GPU where it belongs.

A fifth pillar — **@tool editor scripts** — rounds out the arc: Godot lets you run GDScript during editing, turning Godot itself into a procedural content tool.

The pattern alternates:
- **Quick Fire (2–4 hrs)** — one new pillar, small visible output, enough to know the API
- **Weekend Build (6–10 hrs)** — mini-game, two or three systems working together

Every Quick Fire introduces a pillar. Every Weekend Build that follows deepens it. Challenge 10 combines three or more pillars in a game you ship.

---

## Prerequisites

Before starting:

- **Completed Modules 01–07.** The gauntlet assumes you are comfortable with scenes, GDScript, signals, physics, shaders, and basic enemy AI.
- **Modules 08–13** add procedural generation, multiplayer, and shipping workflows. They are referenced in stretch goals and Challenge 10. Complete them if you can, but you can start the gauntlet after Module 07.
- **Godot 4.3 or later.** Some APIs (`@export_tool_button`, `CompositorEffect`) require 4.3+. All core challenges work on 4.1+.

---

## The Challenges

| # | Title | Scope | Genre | New Tech Pillar |
|---|-------|-------|-------|-----------------|
| 01 | Lantern Depths | Quick Fire | 2D exploration | CanvasLight2D + normal maps |
| 02 | Bone Doll | Weekend Build | 2D action platformer | Skeleton2D + AnimationTree 2D + TileMap physics |
| 03 | Lens Lab | Quick Fire | VFX sandbox | SubViewport + screen-space shader pipeline |
| 04 | Signal Lost | Weekend Build | Retro horror | Full post-processing stack |
| 05 | Guard Brain | Quick Fire | AI demo | Hand-rolled behavior tree |
| 06 | Shadow Protocol | Weekend Build | Stealth game | Vision cone + hearing + squad AI |
| 07 | Spark Field | Quick Fire | Particle sim | GPUParticles3D GLSL process shader |
| 08 | God's Eye | Weekend Build | Emergent sim | Image ping-pong cellular automaton |
| 09 | World Brush | Quick Fire | Editor tool | @tool + Engine.is_editor_hint() |
| 10 | The Whole Package | Weekend Build | Your choice | Synthesis: 3+ pillars + ship to itch.io |

---

## Challenge 01: Lantern Depths 🔥 Quick Fire

**Genre:** 2D exploration — new territory

### The Build

A dark dungeon room. The player's lantern follows the mouse cursor, casting a warm pool of light and casting hard shadows from polygon occluders on the walls. Nearby sprites have subtle depth because their normal maps respond to the light direction. No gameplay loop — the goal is understanding how Godot's 2D lighting engine works before you build anything real with it.

### New Tech

- `CanvasLight2D` — a 2D point light; set `texture` to a `GradientTexture2D` for a soft falloff
- `CanvasLight2D.shadow_enabled = true` — enables shadow casting from occluders
- `LightOccluder2D` — node that blocks CanvasLight2D; requires an `OccluderPolygon2D` resource
- `OccluderPolygon2D.polygon` — an array of `Vector2` points defining the occluder shape
- `CanvasLight2D.range_layer_min` / `range_layer_max` — which CanvasItem layers this light affects
- `CanvasLight2D.item_cull_mask` and `CanvasItem.light_mask` — control which lights affect which sprites
- `CanvasTexture` resource — assign a normal map to its `normal_texture` slot, then use this as the sprite's texture to get normal-mapped 2D lighting

### Connects To

Module 06 introduced the concept of normal maps in 3D shaders. Godot's 2D lighting system uses the same math — surface normals dot-producted against light direction — but applied to flat sprites via `CanvasTexture`. No prior challenge required.

### Key APIs

`CanvasLight2D`, `LightOccluder2D`, `OccluderPolygon2D`, `CanvasTexture`, `get_global_mouse_position()`, `CanvasLight2D.shadow_enabled`, `CanvasLight2D.energy`, `CanvasLight2D.color`

### Starter Pattern

```gdscript
# lantern.gd — attach to a CanvasLight2D node
extends CanvasLight2D

func _process(_delta: float) -> void:
    global_position = get_global_mouse_position()
```

```gdscript
# room_setup.gd — add occluder polygons in code
extends Node2D

func _ready() -> void:
    # A wall segment as a LightOccluder2D
    var occ := LightOccluder2D.new()
    var poly := OccluderPolygon2D.new()
    poly.polygon = PackedVector2Array([
        Vector2(100, 100),
        Vector2(200, 100),
        Vector2(200, 120),
        Vector2(100, 120),
    ])
    occ.occluder = poly
    add_child(occ)
```

The key insight: **CanvasLight2D is a 2D render pass, not a 3D light.** Godot composites lit and unlit layers separately, which is why `item_cull_mask` matters — it lets you have some sprites (background props) that are lit and others (UI) that are not.

### Stretch Goals

- Add a second, cooler-colored light source (a torch bracket fixed on the wall) with a different `color` and `energy`
- Generate the occluder polygons procedurally from a tilemap's collision shapes
- Animate the lantern light's `energy` with `sin(Time.get_ticks_msec() * 0.003)` for a flicker effect

### What This Unlocks

Once you understand `CanvasLight2D`, `LightOccluder2D`, and normal-mapped sprites, you have the complete 2D lighting pipeline. Atmospheric horror games, noir detectives, underground exploration — all of this runs on the same three nodes. Challenge 02 puts this lighting system into a complete platformer.

---

## Challenge 02: Bone Doll 🏗️ Weekend Build

**Genre:** 2D action platformer — cutout character animation

**Builds on:** Challenge 01

### The Build

A side-scrolling platformer with a cutout-animated character: separate body-part sprites controlled by a `Skeleton2D` rig. The character punches and kicks using animations blended by an `AnimationTree` with a `BlendSpace2D` — direction keys tilt the blend space to pick the right directional attack. The level is built in Godot's TileMap editor with physics collision layers properly configured so the character can stand on platforms, walk through triggers, and collide with walls.

### New Tech

**Skeleton2D and IK:**
- `Skeleton2D` — root of a 2D bone hierarchy; child `Bone2D` nodes define the rig
- `Bone2D.rest` — the default `Transform2D` for the bone (set this first, animations offset from it)
- `SkeletonModification2DCCDIK` — cyclic coordinate descent IK; chain of bones tracks a target position (great for arms reaching toward the mouse)
- `Polygon2D.skeleton` — bind a `Polygon2D` to a `Skeleton2D` and set `uv` weights per vertex for skinned deformation (optional — simpler rigs just parent sprites to bones directly)

**AnimationTree with BlendSpace2D:**
- `AnimationTree` with `AnimationNodeStateMachine` at the root — same as Module 10, but the combat state uses `AnimationNodeBlendSpace2D` instead of a single clip
- `BlendSpace2D` maps a 2D parameter (`blend_position`) to a blend of animations — e.g. `punch_up`, `punch_forward`, `punch_down` interpolated based on aim angle
- Set `blend_position` from GDScript: `anim_tree.set("parameters/combat/blend_position", aim_vector)`

**TileMap physics layers (Godot 4):**
- `TileSet` resource has named physics layers; each tile can belong to zero or more layers
- Player `CharacterBody2D` collides against layer 0 (solid ground), but passes through layer 1 (one-way platforms by setting `one_way_collision = true` on the tile's physics shape)
- `TileMap.get_cells_terrain_connect_area()` — query which tile is at a world position

### Connects To

Module 10's `AnimationTree` + `AnimationNodeStateMachine` work is directly extended here — the state machine still exists, but combat states use `BlendSpace2D` for directional variety. Challenge 01's lighting drops in unchanged.

### Key APIs

`Skeleton2D`, `Bone2D`, `SkeletonModification2DCCDIK`, `AnimationNodeBlendSpace2D`, `AnimationTree.set()`, `TileSet`, `TileMap`, `CharacterBody2D.move_and_slide()`

### Starter Pattern

```gdscript
# character.gd
extends CharacterBody2D

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var skeleton: Skeleton2D = $Skeleton2D

const SPEED := 200.0
const JUMP_VEL := -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

    var dir := Input.get_axis("ui_left", "ui_right")
    velocity.x = dir * SPEED

    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VEL

    move_and_slide()

    # Update blend tree locomotion parameter
    anim_tree.set("parameters/locomotion/blend_position", velocity.x / SPEED)

    # Update combat aim direction
    var aim := (get_global_mouse_position() - global_position).normalized()
    anim_tree.set("parameters/combat/blend_position", aim)
```

### Stretch Goals

- Add `SkeletonModification2DCCDIK` so the character's arm tracks the mouse cursor in real time, even while playing locomotion animations
- Use a `RemoteTransform2D` to attach the lantern light from Challenge 01 to the character's hand bone
- Add a secondary TileMap layer for decorative props that have no physics, showing how layer separation works

### What This Unlocks

`Skeleton2D` + `AnimationTree` + `BlendSpace2D` is how professional 2D games handle complex character animation without combinatorial clip explosion. The TileMap physics layer system is the correct way to handle one-way platforms, triggers, and damage zones in any 2D Godot game.

---

## Challenge 03: Lens Lab 🔥 Quick Fire

**Genre:** VFX sandbox — post-processing introduction

### The Build

A scene with moving 3D objects (or a 2D game scene) that renders into a `SubViewport`. A fullscreen `ColorRect` samples the viewport texture through a `ShaderMaterial` and applies a screen-space effect. Press spacebar to cycle through three effects: pixelate, blur, and chromatic aberration. The goal is not the effects — it is learning the SubViewport → ViewportTexture → ShaderMaterial pipeline that all screen-space post-processing in Godot uses.

### New Tech

- `SubViewport` node — an offscreen render target; set `size` to match the window
- `SubViewportContainer` — optional wrapper that auto-sizes the SubViewport to its rect
- `SubViewport.get_texture()` — returns a `ViewportTexture` you can assign to a material's `texture` uniform
- `ColorRect` with `ShaderMaterial` — a fullscreen quad; the shader reads the viewport texture and outputs the processed result
- `uniform sampler2D screen_texture : hint_screen_texture` — in Godot 4 canvas_item shaders, this built-in uniform gives access to the screen render
- `set_shader_parameter(name, value)` — pass values from GDScript to shader uniforms at runtime

The pipeline:
```
Game scene → SubViewport (renders here) → ViewportTexture
  → ColorRect ShaderMaterial samples it → screen output
```

### Connects To

Module 06's `ShaderMaterial` and uniform sending (`set_shader_parameter`) are used directly. This challenge introduces the SubViewport layer that Module 06 never needed.

### Key APIs

`SubViewport`, `SubViewport.get_texture()`, `ViewportTexture`, `ColorRect`, `ShaderMaterial`, `set_shader_parameter()`, `canvas_item` shader type, `sampler2D` uniform

### The Three Shaders

```glsl
// pixelate.gdshader
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float block_size : hint_range(1.0, 32.0) = 4.0;

void fragment() {
    vec2 res = vec2(textureSize(screen_tex, 0));
    vec2 blocks = res / block_size;
    vec2 quantized = floor(UV * blocks) / blocks;
    COLOR = texture(screen_tex, quantized);
}
```

```glsl
// chromatic.gdshader
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 0.02) = 0.006;

void fragment() {
    vec2 offset = (UV - 0.5) * strength;
    float r = texture(screen_tex, UV - offset).r;
    float g = texture(screen_tex, UV).g;
    float b = texture(screen_tex, UV + offset).b;
    COLOR = vec4(r, g, b, 1.0);
}
```

```glsl
// blur.gdshader
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float radius : hint_range(0.0, 8.0) = 2.0;

void fragment() {
    vec2 texel = 1.0 / vec2(textureSize(screen_tex, 0));
    vec4 col = vec4(0.0);
    float total = 0.0;
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            col += texture(screen_tex, UV + vec2(x, y) * texel * radius);
            total += 1.0;
        }
    }
    COLOR = col / total;
}
```

### Stretch Goals

- Animate `strength` or `radius` over time using `set_shader_parameter` in `_process()` for a pulsing lens effect
- Add a fourth effect: vignette (darken screen edges) with a `uv_center` + `dot()` falloff
- Try a ping-pong pass: apply horizontal blur to a second SubViewport, then vertical blur on top of that — the basis for a real separable Gaussian bloom

### What This Unlocks

The SubViewport → ColorRect → ShaderMaterial pipeline is the foundation for every screen-space effect in Godot. Bloom, CRT distortion, heat shimmer, depth of field — they all start here. Challenge 04 stacks multiple passes of this pipeline into a full horror post-processing stack.

---

## Challenge 04: Signal Lost 🏗️ Weekend Build

**Genre:** Retro psychological horror — 2.5D

**Builds on:** Challenge 03, Module 06

### The Build

A short first-person horror corridor — the player walks down a hallway while the world degrades visually: CRT grain overlays the screen, a vignette pulses with the player's "heartbeat," a signal distortion shader warps geometry edges, and `WorldEnvironment` fog density is animated in code to thicken as the player descends. The visuals are the game. The mechanic is simple: reach the end.

### New Tech

**Multi-pass SubViewport chain:**
- Scene renders into SubViewport A → `ColorRect A` with CRT shader renders into SubViewport B → `ColorRect B` with distortion shader draws to screen
- Each pass adds one effect without the shaders needing to know about each other

**Animated WorldEnvironment fog:**
- `WorldEnvironment.environment.fog_density` is a plain float — animate it in `_process()` based on player Z position
- `Environment.fog_light_color`, `fog_aerial_perspective` — tweak for eerie effect

**CompositorEffect (Godot 4.3+):**
- A `CompositorEffect` subclass with `_render_callback()` gives direct access to the render buffers via `RenderSceneBuffersRD`
- Use it for screen-space distortion that warps rendered geometry (not a post-process quad — the geometry itself appears stretched)
- Fallback for 4.1/4.2: apply distortion as a third SubViewport pass instead

**Animated shader parameters:**
- Call `material.set_shader_parameter("time", elapsed)` in `_process()` for time-driven noise in the CRT shader
- `set_shader_parameter("vignette_strength", pulse)` where `pulse = 0.3 + 0.1 * sin(Time.get_ticks_msec() * 0.002)`

### Connects To

Challenge 03's SubViewport pipeline — extend it from one pass to a two-pass chain. Module 06's `ShaderMaterial` and `set_shader_parameter`. Module 04's `CharacterBody3D` player movement for the first-person walk.

### Key APIs

`WorldEnvironment`, `Environment.fog_density`, `SubViewport`, `CompositorEffect`, `RenderSceneBuffersRD`, `set_shader_parameter()`, `Time.get_ticks_msec()`

### Starter Pattern

```gdscript
# post_process.gd — manages the shader parameter animation loop
extends Node

@export var crt_material: ShaderMaterial
@export var distort_material: ShaderMaterial
@export var world_env: WorldEnvironment

var elapsed := 0.0

func _process(delta: float) -> void:
    elapsed += delta

    # CRT grain drifts over time
    crt_material.set_shader_parameter("time", elapsed)

    # Vignette heartbeat
    var pulse := 0.3 + 0.1 * sin(elapsed * 2.1)
    crt_material.set_shader_parameter("vignette_strength", pulse)

    # Fog thickens as player descends (Z < 0 = deeper)
    var player_depth := -get_tree().get_first_node_in_group("player").global_position.z
    world_env.environment.fog_density = clampf(player_depth * 0.01, 0.0, 0.08)
```

### Stretch Goals

- Add dithered shadow edges: a `spatial` shader on wall meshes that samples a blue noise texture in `fragment()` and clips pixels based on shadow proximity
- Procedurally flicker a `SpotLight3D` by randomizing its `energy` in `_process()` using `randf()` with a low-pass filter
- Add audio: `AudioStreamPlayer` with a low-frequency rumble, pitched down via `pitch_scale` as `fog_density` increases

### What This Unlocks

Multi-pass rendering, animated environment parameters, and `CompositorEffect` together cover the full range of Godot's post-processing capabilities. Any stylized or atmospheric game — horror, sci-fi, dreamlike — uses a subset of what this challenge builds.

---

## Challenge 05: Guard Brain 🔥 Quick Fire

**Genre:** AI demo — behavior tree introduction

### The Build

A single guard NPC on a flat plane. It patrols a route, notices the player (placeholder: player just moves freely), switches to chase, then enters a search state if it loses sight. The states are driven by a hand-rolled behavior tree written in GDScript — not a plugin, not a state machine enum. A debug overlay renders the name of the currently running leaf node so you can watch the tree execute in real time.

### New Tech

The core behavior tree pattern in ~60 lines of GDScript:

```gdscript
# behavior_tree.gd — minimal BT framework
class_name BehaviorNode

enum Status { SUCCESS, FAILURE, RUNNING }

func tick(blackboard: Dictionary) -> Status:
    return Status.FAILURE  # override in subclasses
```

```gdscript
# bt_sequence.gd — all children must succeed
class_name BTSequence extends BehaviorNode

var children: Array[BehaviorNode] = []

func tick(bb: Dictionary) -> Status:
    for child in children:
        var result := child.tick(bb)
        if result != Status.SUCCESS:
            return result  # FAILURE or RUNNING short-circuits
    return Status.SUCCESS
```

```gdscript
# bt_selector.gd — first child to succeed wins
class_name BTSelector extends BehaviorNode

var children: Array[BehaviorNode] = []

func tick(bb: Dictionary) -> Status:
    for child in children:
        var result := child.tick(bb)
        if result != Status.FAILURE:
            return result
    return Status.FAILURE
```

```gdscript
# bt_leaf.gd — wraps a Callable for leaf actions/conditions
class_name BTLeaf extends BehaviorNode

var label: String
var fn: Callable

func tick(bb: Dictionary) -> Status:
    bb["_active_node"] = label
    return fn.call(bb)
```

The **Blackboard** is a `Dictionary` passed by reference through every tick — guards store `player_pos`, `last_seen_pos`, `alert_level`, `patrol_index` here.

### Connects To

Module 07's enemy patterns (patrol waypoints, awareness radius) are re-implemented here using the behavior tree. The BT does not replace the underlying movement logic — it replaces the chain of `if/elif` that chose which behavior to run.

### Key APIs

`Callable`, `Dictionary` (as blackboard), `CharacterBody3D.move_and_slide()`, `NavigationAgent3D`, `draw_line()` / `draw_string()` in `_draw()` for the debug overlay

### Starter Pattern — Guard Tree

```gdscript
# guard.gd
extends CharacterBody3D

var bb := {
    "self": self,
    "player_pos": Vector3.ZERO,
    "alert_level": 0.0,
    "patrol_index": 0,
    "_active_node": "",
}

var tree: BTSelector

func _ready() -> void:
    # Build: (Patrol) Selector → [Chase Sequence, Patrol Sequence]
    var chase_seq := BTSequence.new()
    chase_seq.children = [
        BTLeaf.new().setup("CanSeePlayer", _can_see_player),
        BTLeaf.new().setup("ChasePlayer", _chase_player),
    ]
    var patrol_seq := BTSequence.new()
    patrol_seq.children = [
        BTLeaf.new().setup("MoveToWaypoint", _patrol),
    ]
    tree = BTSelector.new()
    tree.children = [chase_seq, patrol_seq]

func _physics_process(_delta: float) -> void:
    bb["player_pos"] = get_tree().get_first_node_in_group("player").global_position
    tree.tick(bb)
    queue_redraw()  # trigger debug overlay repaint
```

### Stretch Goals

- Add a `BTSearch` leaf that navigates to `last_seen_pos` then transitions back to patrol on a timer
- Visualize the full tree structure as a 2D debug UI, not just the active node name
- Add a `BTDecorator` base class — a node with one child that can invert, repeat, or limit retries

### What This Unlocks

A behavior tree separates **what to do** (leaf functions) from **when to do it** (the tree structure). Once you have this pattern, adding a new guard behavior means adding a leaf and inserting it into the tree — no existing code changes. Challenge 06 builds a full stealth game on top of this foundation.

---

## Challenge 06: Shadow Protocol 🏗️ Weekend Build

**Genre:** Top-down 2D stealth game

**Builds on:** Challenge 05, Module 07, Module 05

### The Build

A top-down stealth level with three guard types: a patrol guard following a fixed route, a static guard watching a cone, and a roaming guard moving semi-randomly. Each has a vision cone and a hearing radius. The player must cross the level without triggering any guard's alert to full. If a guard reaches full alert, it broadcasts to all others via a signal bus autoload. Guards in high-alert state call backup — a fourth guard spawns and sweeps the alert zone.

### New Tech

**Vision cone via raycasts:**
- Cast multiple rays in a fan from the guard's facing direction using `PhysicsDirectSpaceState2D.intersect_ray()`
- Rays that reach the player (unobstructed by walls) increment `alert_level` based on distance and angular position in the cone
- Visualize the cone by drawing filled triangles between the ray hit points in `_draw()`

**Hearing radius:**
- `Area2D` child of the guard with a `CollisionShape2D` circle; `body_entered` signal connects to a `_heard_something` method
- Player `CharacterBody2D` emits a `made_noise(intensity)` signal when sprinting or landing; the guard's `Area2D` receives it if the player is inside the radius
- Crouching reduces the player's noise radius (`Area2D.scale`)

**Alert escalation and squad broadcast:**
- Three alert levels: `UNAWARE → SUSPICIOUS → ALERTED`
- An autoload `SignalBus` with `signal guard_alerted(position: Vector2)` — guards connect to it on `_ready()`; any guard reaching `ALERTED` emits it, all others shift one level toward `SUSPICIOUS`

### Connects To

Challenge 05's behavior tree drives each guard — the tree gains new leaves: `CanHearPlayer`, `InvestigateNoise`, `BroadcastAlert`. Module 07's enemy movement patterns apply. Module 05's signals and autoload pattern is exactly the squad broadcast mechanism.

### Key APIs

`PhysicsDirectSpaceState2D`, `PhysicsRayQueryParameters2D`, `get_world_2d().direct_space_state`, `Area2D`, `body_entered` signal, `CharacterBody2D.velocity.length()`, `queue_redraw()`, `_draw()`, autoload singleton

### Starter Pattern — Vision Ray

```gdscript
# guard_vision.gd
extends Node2D

@export var cone_angle := 45.0  # degrees either side of facing
@export var ray_count := 12
@export var view_distance := 200.0

func get_visible_bodies() -> Array:
    var space := get_world_2d().direct_space_state
    var visible := []
    var half := deg_to_rad(cone_angle)
    var facing := get_parent().rotation  # guard's facing angle

    for i in ray_count:
        var t := float(i) / (ray_count - 1)
        var angle := facing + lerp(-half, half, t)
        var dir := Vector2.from_angle(angle) * view_distance
        var query := PhysicsRayQueryParameters2D.create(
            global_position,
            global_position + dir,
        )
        query.exclude = [get_parent().get_rid()]
        var hit := space.intersect_ray(query)
        if hit and hit.collider.is_in_group("player"):
            visible.append(hit.collider)
    return visible
```

### Stretch Goals

- Add a `SEARCH` state: alerted guard moves to `last_seen_pos`, waits 3 seconds, then returns to patrol
- Noise visualization: briefly render a circle at the noise emission point that fades over 1 second
- A second floor with a staircase — guards on the same floor hear each other; guards on different floors do not

### What This Unlocks

Vision cones backed by raycasts, hearing radii via `Area2D`, and a signal-bus squad system are the three components of production-quality stealth AI. Every guard-based stealth game — from Metal Gear-style top-down to Splinter Cell-style 3D — runs on these primitives. The behavior tree from Challenge 05 makes it extensible.

---

## Challenge 07: Spark Field 🔥 Quick Fire

**Genre:** Particle simulation — GPU process shader introduction

### The Build

Click anywhere to spawn a burst of 500 particles. They orbit the click point, trail secondary particles, and fade with a color gradient. The behavior is clearly different from anything CPUParticles3D could produce at this count: the GPU drives every particle's position, velocity, and color each frame via a custom GLSL process shader. The goal is understanding how to write a `particles` shader and override the built-in `VELOCITY`, `COLOR`, and `TRANSFORM` variables.

### New Tech

- `GPUParticles3D` (or `GPUParticles2D`) with `process_material` set to a `ShaderMaterial`
- Shader type: `shader_type particles;` — a special type that runs once per particle per emission step
- Built-in write targets: `VELOCITY`, `COLOR`, `TRANSFORM`, `ACTIVE`, `CUSTOM`
- Built-in read inputs: `TIME`, `DELTA`, `INDEX`, `LIFETIME`, `RESTART` (true on first frame of a particle's life)
- `TRANSFORM[3].xyz` — the particle's current world position as the 4th column of the transform matrix
- `SubEmitter` — a second `GPUParticles3D` attached as a sub-emitter; particles from it spawn wherever the parent particle is — used for trails

### Connects To

Module 06's GLSL syntax. Module 08's `GPUParticles3D` basic usage. The `particles` shader type is the same GLSL dialect as `spatial` and `canvas_item` — same uniform declaration, same math functions, different built-in variables.

### Key APIs

`GPUParticles3D`, `GPUParticles3D.process_material`, `ShaderMaterial`, `GPUParticles3D.sub_emitter`, `shader_type particles`, `VELOCITY`, `COLOR`, `TRANSFORM`, `RESTART`, `TIME`, `INDEX`

### Starter Pattern

```glsl
// orbit_particles.gdshader
shader_type particles;

uniform vec3 orbit_center = vec3(0.0);
uniform float orbit_speed : hint_range(0.5, 10.0) = 3.0;
uniform float orbit_radius : hint_range(0.1, 5.0) = 1.5;

void start() {
    // On first frame of particle life: scatter into a ring
    float angle = float(INDEX) / float(NUMBER_OF_PARTICLES) * TAU;
    TRANSFORM[3].xyz = orbit_center + vec3(
        cos(angle) * orbit_radius,
        sin(float(INDEX) * 0.4) * 0.3,  // slight vertical scatter
        sin(angle) * orbit_radius
    );
    VELOCITY = vec3(0.0);
}

void process() {
    // Compute tangent to orbit circle for continuous orbiting
    vec3 to_center = orbit_center - TRANSFORM[3].xyz;
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 tangent = normalize(cross(to_center, up));
    VELOCITY = tangent * orbit_speed;

    // Fade out by lifetime
    float life_ratio = (LIFETIME - AGE) / LIFETIME;
    COLOR = vec4(1.0, 0.6, 0.2, life_ratio);
}
```

### Stretch Goals

- Use `RESTART` to randomize each particle's starting orbit radius on spawn, creating a volumetric cloud effect
- Add a `CUSTOM.x` channel to store each particle's initial angle, then use it to maintain a perfect synchronized orbit
- Port from `GPUParticles3D` to `GPUParticles2D` — the shader built-ins are nearly identical but the coordinate system is 2D

### What This Unlocks

`shader_type particles` moves simulation logic onto the GPU, which is where it belongs. CPUParticles maxes out at a few hundred particles with complex behavior. GPUParticles with a custom process shader handles tens of thousands. Challenge 08 extends this idea to a full grid-based simulation using image ping-pong.

---

## Challenge 08: God's Eye 🏗️ Weekend Build

**Genre:** Emergent colony simulation

**Builds on:** Challenge 07, Module 08

### The Build

A slime mold / ant colony simulation. Agents (represented as colored pixels) wander a grid, deposit pheromone trails, and steer toward strong gradients. The pheromone grid decays and diffuses each tick. Place food sources; watch agents discover them and form efficient highways through emergent behavior — no global coordination, no pathfinding. The simulation runs on the CPU via Godot's `Image` API; a stretch goal ports the grid step to a compute shader for 10× throughput.

### New Tech

**Image ping-pong:**
- Maintain two `Image` objects: `current` and `next`
- Each tick: read from `current` (`image.get_pixel(x, y)`), compute new state, write to `next` (`image.set_pixel(x, y, color)`)
- Swap references: `var tmp = current; current = next; next = tmp`
- Upload to GPU: `texture.update(current)` where `texture` is an `ImageTexture`

**Image API:**
- `Image.create(width, height, false, Image.FORMAT_RGBA8)` — create a blank image in a specific format
- `image.get_pixel(x, y)` → `Color` — read a pixel
- `image.set_pixel(x, y, color)` — write a pixel
- `ImageTexture.create_from_image(image)` — create a GPU texture from an `Image`
- `ImageTexture.update(image)` — re-upload changed pixel data without recreating the texture

**Simulation encoding:**
- Encode pheromone intensity in the `r` channel; agent presence in `g`; food in `b`
- A `Color(pheromone, 0.0, 0.0, 1.0)` pixel is a trail cell; `Color(0.0, 1.0, 0.0, 1.0)` is an agent

### Connects To

Module 08's `FastNoiseLite` procedural generation — use noise to place initial food sources and obstacles. Challenge 07's GPU particle concepts — this challenge is a CPU analog of the same per-element simulation model, preparing you for the compute shader stretch goal.

### Key APIs

`Image`, `Image.create()`, `image.get_pixel()`, `image.set_pixel()`, `ImageTexture`, `ImageTexture.create_from_image()`, `ImageTexture.update()`, `TextureRect` (to display the simulation)

### Starter Pattern

```gdscript
# simulation.gd
extends TextureRect

const SIM_W := 256
const SIM_H := 256
const DECAY := 0.98
const DIFFUSE := 0.1

var current: Image
var next: Image
var tex: ImageTexture

func _ready() -> void:
    current = Image.create(SIM_W, SIM_H, false, Image.FORMAT_RGBA8)
    next = Image.create(SIM_W, SIM_H, false, Image.FORMAT_RGBA8)
    tex = ImageTexture.create_from_image(current)
    texture = tex

func _process(_delta: float) -> void:
    _step_simulation()
    tex.update(current)

func _step_simulation() -> void:
    for y in SIM_H:
        for x in SIM_W:
            var col := current.get_pixel(x, y)

            # Diffuse: average with neighbors
            var neighbors := Color()
            for dx in [-1, 0, 1]:
                for dy in [-1, 0, 1]:
                    if dx == 0 and dy == 0:
                        continue
                    neighbors += current.get_pixel(
                        wrapi(x + dx, 0, SIM_W),
                        wrapi(y + dy, 0, SIM_H)
                    )
            var diffused := col.r * (1.0 - DIFFUSE) + (neighbors.r / 8.0) * DIFFUSE

            next.set_pixel(x, y, Color(diffused * DECAY, col.g, col.b, 1.0))

    var tmp := current
    current = next
    next = tmp
```

### Stretch Goals

- Port the grid diffusion step to a compute shader using `RenderingDevice.compute_list_dispatch()` — same logic, runs 10× faster on large grids (512×512+)
- Add multiple pheromone channels: `r` = food trail, `g` = nest trail — agents follow different channels depending on state
- Use `FastNoiseLite` to generate initial terrain obstacles and food cluster positions (connects to Module 08)

### What This Unlocks

Image ping-pong on the CPU is the foundation for any grid-based simulation in Godot: fluid dynamics, cellular automata, heat diffusion, territory maps. The `ImageTexture.update()` pattern means you can display arbitrary per-pixel data on any mesh or UI element. The compute shader stretch goal is the gateway to GPU simulation at full scale.

---

## Challenge 09: World Brush 🔥 Quick Fire

**Genre:** Editor tool — @tool scripts introduction

### The Build

A `ForestScatter` node. In the Godot editor, add it to a scene, adjust its exported properties (`density`, `radius`, `scene_to_scatter`, `seed`) in the inspector, and child scene instances (trees, rocks, whatever) automatically populate as you type. No Play button required. The placement runs at edit time via `@tool`. Zero runtime overhead — the instances are just regular child nodes baked into the scene.

### New Tech

- `@tool` annotation at the top of a GDScript file — makes the entire script run in the editor, not just at runtime
- `Engine.is_editor_hint()` — returns `true` when running inside the editor; use to guard expensive operations that should only run in-editor
- `@export_tool_button("Regenerate", "regenerate")` (Godot 4.3+) — adds a button in the inspector that calls the named method; perfect for "regenerate" triggers
- `_get_configuration_warnings()` — return an array of strings shown as warnings on the node in the editor when properties are misconfigured
- `set_notify_transform(true)` + `_notification(NOTIFICATION_TRANSFORM_CHANGED)` — detect when the node moves in the editor and auto-update child placement
- Editor-time `_ready()` runs when the node enters the scene tree in the editor; editor-time `_process()` runs every editor frame

### Connects To

Module 08's `MultiMeshInstance3D` scatter patterns — World Brush is the editor-time authoring tool that produces the input scenes those patterns consume. Module 13's project organization (assets/scenes structure) — `ForestScatter` respects those conventions.

### Key APIs

`@tool`, `Engine.is_editor_hint()`, `@export_tool_button`, `_get_configuration_warnings()`, `PackedScene.instantiate()`, `Node.add_child()`, `Node.set_owner()` (required for editor-instantiated nodes to serialize into the scene file)

### Starter Pattern

```gdscript
@tool
extends Node3D
class_name ForestScatter

@export var scene_to_scatter: PackedScene:
    set(v):
        scene_to_scatter = v
        if Engine.is_editor_hint():
            regenerate()

@export_range(1, 200) var count := 30:
    set(v):
        count = v
        if Engine.is_editor_hint():
            regenerate()

@export var radius := 10.0:
    set(v):
        radius = v
        if Engine.is_editor_hint():
            regenerate()

@export var seed_value := 0:
    set(v):
        seed_value = v
        if Engine.is_editor_hint():
            regenerate()

@export_tool_button("Regenerate") var _regen_btn := regenerate

func regenerate() -> void:
    if not scene_to_scatter:
        return
    # Clear old children
    for child in get_children():
        child.queue_free()

    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value

    for i in count:
        var instance := scene_to_scatter.instantiate()
        add_child(instance)
        # CRITICAL: set_owner makes the node save with the scene
        instance.owner = get_tree().edited_scene_root
        var angle := rng.randf() * TAU
        var dist := rng.randf() * radius
        instance.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
        instance.rotation.y = rng.randf() * TAU
        instance.scale = Vector3.ONE * rng.randf_range(0.8, 1.2)

func _get_configuration_warnings() -> PackedStringArray:
    if not scene_to_scatter:
        return ["scene_to_scatter must be set before regenerating."]
    return []
```

The key insight: **`set_owner` is mandatory.** Without it, editor-instantiated nodes exist in memory but do not serialize into the `.tscn` file. The scene will appear populated while open but be empty when reloaded.

### Stretch Goals

- Add a `terrain_node` export that snaps scattered instances to the terrain's surface using `PhysicsDirectSpaceState3D.intersect_ray()` — fully editor-time, no runtime cost
- Add a `_clear` export button that removes all children without regenerating
- Extend to support multiple `PackedScene` assets in an array with per-asset probability weights

### What This Unlocks

`@tool` scripts turn Godot into a procedural content pipeline. World Brush is one example — others include road/river spline tools, dungeon assemblers, rule-tile painters. Every hour spent building editor tools returns many hours of level design time saved. Once you are comfortable with `Engine.is_editor_hint()` and `set_owner`, you can build any editor workflow you need.

---

## Challenge 10: The Whole Package 🏗️ Weekend Build

**Genre:** Your choice — one complete shippable game

**Builds on:** Every prior challenge

### The Build

Make one complete, shippable game. Not a prototype. Not a tech demo. A game with a title screen, a game loop, an end condition, and something a stranger could download and play for ten minutes without you explaining it.

The constraint: **your game must incorporate at least three of the five pillars introduced in this gauntlet.**

Suggested combinations by genre:

| Genre | Pillars to combine |
|---|---|
| Atmospheric 2D platformer | 2D Systems (C02) + Post-Processing (C03/04) + @tool scatter (C09) |
| Top-down stealth | Advanced AI (C06) + 2D Systems (C01) + Post-Processing (C04 CRT) |
| Colony / god game | GPU Simulation (C08) + @tool map authoring (C09) + Post-Processing (C03) |
| Atmospheric horror | Post-Processing (C04) + Advanced AI (C05) + GPU Particles (C07) |

### The Shippable Checklist

Scope accordingly. The same discipline as Module 13, now with five new technical pillars in play.

**Required to call it shipped:**
- [ ] Title screen with Play button; music or ambient audio
- [ ] Game over / win condition the player can reach unaided
- [ ] Restart without relaunching the editor or executable
- [ ] Sound effects on at least three gameplay actions
- [ ] Stable 60fps on typical hardware (profile `_process` load; move heavy work to threads if needed)
- [ ] Settings persisted with `ConfigFile` — at minimum: audio volume, fullscreen toggle
- [ ] Export builds for macOS + Windows (see Module 13 export workflow)
- [ ] Uploaded to itch.io with a cover image, description, and genre tags

**Common scope traps:**
- Image ping-pong simulation + complex game loop = frame budget competition. Cap simulation ticks per frame with a `max_steps_per_frame` constant; accept occasional stutter over frame drops.
- Behavior tree + SubViewport pipeline = both want `_process` time. Profile early; the BT should tick at 20Hz, not 60Hz.
- "Just one more pillar" is how this weekend becomes a three-month project. Lock pillars before Friday.

### Architecture Advice

As systems from multiple pillars multiply, a **global context autoload** prevents dependency tangles.

```gdscript
# GameContext.gd — autoload singleton
extends Node

signal state_changed(new_state: String)

var state := "title"
var elapsed := 0.0

# References to major subsystems — set by each subsystem's _ready()
var behavior_bus: Node       # SignalBus from C06
var simulation: Node         # God's Eye sim from C08
var post_process: Node       # SubViewport chain from C03/04

func change_state(new_state: String) -> void:
    state = new_state
    state_changed.emit(new_state)

func _process(delta: float) -> void:
    if state == "playing":
        elapsed += delta
```

Each subsystem registers itself on `_ready()` and reads other subsystems via `GameContext`. No spaghetti of `get_node("../../SomeSystem")` across your scene tree.

### What This Unlocks

You have now built something with five layers of technical depth — 2D lighting, post-processing, advanced AI, GPU simulation, and editor tooling — integrated into a single shippable artifact. That combination is rare. Most developers specialize in one or two of these areas.

More importantly, you have experienced how they interact at integration time. Knowing the pitfalls before you hit them in a production project is the actual value of this gauntlet.

---

## After the Gauntlet

### Game Jams

**Godot Wild Jam** runs monthly and is Godot-exclusive — the community is fluent in the same APIs you now know. **GMTK Game Jam** is the highest-prestige annual jam; Godot entries routinely finish in the top tier. Both are good first targets. Find upcoming jams at [itch.io/jams](https://itch.io/jams).

**GodotCon** is the annual community conference (usually Berlin or online). Talks cover rendering internals, GDExtension, and editor tooling — exactly the territory this gauntlet introduced.

### Advanced Rendering Topics Not in the Gauntlet

**GDExtension.** When GDScript is too slow for a hot path — dense physics, large simulation grids, custom rendering — GDExtension lets you write C++ or Rust that plugs into the Godot API as a first-class module. The `RenderingServer` and `RenderingDevice` low-level APIs become accessible without source modifications.

**RenderingDevice compute shaders.** The stretch goal in Challenge 08 scratches the surface. `RenderingDevice.compute_list_dispatch()` gives you full compute shader access: arbitrary buffer read/write, atomic operations, shared memory, workgroup synchronization. This is how AAA-style fluid sims, GPU pathfinding, and neural network inference run in Godot.

**Vulkan / Forward+ vs. Mobile vs. Compatibility renderers.** `SubViewport`, `CompositorEffect`, and custom process shaders all behave slightly differently across Godot's three renderer backends. Forward+ (Vulkan) supports everything. Compatibility (OpenGL) does not support `CompositorEffect`. Know which renderer your target platforms require before relying on advanced pipeline features.

**Signed distance fields.** SDF-based rendering unlocks infinite-resolution fonts, soft shadows, and smooth boolean shape operations entirely in shader code. The `spatial` shader fragment function is the right place to implement these.

### Resources

| Resource | What You Get |
|---|---|
| [Godot Docs: CanvasLight2D](https://docs.godotengine.org/en/stable/classes/class_canvaslight2d.html) | Full 2D lighting API reference |
| [Godot Docs: GPUParticles3D](https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html) | Particle shader built-in variables |
| [Godot Docs: @tool](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html) | Official guide to editor-time scripting |
| [Godot Docs: RenderingDevice](https://docs.godotengine.org/en/stable/classes/class_renderingdevice.html) | Low-level Vulkan API wrapper |
| [The Book of Shaders](https://thebookofshaders.com) | Visual, interactive GLSL fundamentals |
| [Behavior Trees for AI (Game Programming Patterns)](https://gameprogrammingpatterns.com) | Formal treatment of BT architecture |
| [Godot Wild Jam](https://godotwildjam.com) | Monthly Godot-only jam |
| [Slime Mold Simulation](https://sagejenson.com/physarum) | The algorithm behind Challenge 08 |

---

## Key Takeaways

- **Each Quick Fire challenge is a concept spike, not a game.** Getting comfortable with `CanvasLight2D` or `@tool` is different from integrating it into a shipped title. The Quick Fires build comfort. The Weekend Builds build capability.

- **2D in Godot is not simplified 3D.** It has its own rendering pipeline, its own animation systems, and its own lighting engine. Developers who know only 3D Godot are missing half the platform.

- **The SubViewport pipeline is the only post-processing model.** Every screen-space effect — blur, distortion, CRT, bloom — uses the same SubViewport → ColorRect → ShaderMaterial chain. Once you understand it in Challenge 03, you build on it forever.

- **Behavior trees are an organizational pattern, not an AI algorithm.** The tree controls *when* behaviors run. The actual movement, sensing, and state logic are plain GDScript functions. Separating these concerns is why BTs scale to complex multi-guard scenarios without becoming spaghetti.

- **GPU simulation changes what is possible.** A 512×512 cellular automaton at 60fps is impossible on the CPU. On the GPU it is trivial. Understanding where to put compute — CPU for logic, GPU for mass-parallel data — is a professional-level distinction.

- **@tool scripts make Godot a content pipeline.** The editor is not a constraint — it is a programmable tool. Procedural placement, rule-based tile painters, and automated LOD generation can all live in `@tool` scripts that never touch the runtime.

- **You now have a complete technical palette.** 2D lighting, skeleton rigs, post-processing pipelines, behavior trees, GPU particles, image simulation, and editor tooling — combined with everything from the 13-module roadmap. The constraints on what you can build are creative, not technical.

Back to the [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md).
