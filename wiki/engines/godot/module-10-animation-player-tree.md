# Module 10: Animation — AnimationPlayer & AnimationTree

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 6–10 hours
**Prerequisites:** [Module 5: Signals, Resources & Game Architecture](module-05-signals-resources-architecture.md)

---

## Overview

AnimationPlayer is one of Godot's most powerful tools — and most underestimated. It doesn't just animate characters. It keyframes ANY property on ANY node: transforms, colors, shader parameters, visibility, audio volume, even script variables. If a node has a property, AnimationPlayer can animate it. Screen transitions, UI effects, cutscenes, environmental changes — all doable with AnimationPlayer alone. Most developers treat it as a character animation tool. It's actually a general-purpose timeline system for anything that changes over time.

AnimationTree builds on top of AnimationPlayer for complex character animation. It provides state machines (idle → walk → run → jump), blend spaces (directional movement), and transitions — all visually editable in the editor. Combined with Mixamo for free character animations and Godot's retargeting system, you can have a fully animated character running in your scene in minutes. AnimationTree doesn't replace AnimationPlayer — it processes the animations that AnimationPlayer holds.

By the end of this module, you'll build a third-person character with a full animation state machine: idle, walk, run, jump, fall, land, and attack — with smooth blending, root motion, and animation callbacks for footstep sounds. You'll also learn when NOT to use AnimationPlayer, and how Tweens fill the gap for procedural, code-driven animations that don't need an artist-authored timeline.

---

## 1. AnimationPlayer Fundamentals

### The Node Setup

Add an `AnimationPlayer` node to your scene. It can go anywhere in the tree, but it's conventional to place it as a child of the node it primarily animates. Once added, a new panel appears at the bottom of the editor — the Animation panel. This is your timeline.

```
- CharacterBody3D          (or whatever your root is)
  - MeshInstance3D
  - AnimationPlayer        ← add here
```

Click the `AnimationPlayer` in the scene tree to select it. In the Animation panel at the bottom, click the **Animation** button (or the dropdown that says "—none—") and select **New Animation**. Name it something descriptive: `idle`, `walk`, `door_open`, `flash`, etc.

### Keyframing Properties

This is the key insight: **any property in the Inspector can be keyframed**. You see that small key icon next to each property in the Inspector? Click it and Godot asks you to confirm adding a track for that property to the current animation. A diamond appears on the timeline at the current playhead position. Move the playhead, change the property value, click the key icon again. You now have a two-keyframe animation.

Let's do a concrete example. Select a `MeshInstance3D` in your scene while `AnimationPlayer` is selected and your animation is active:

1. Move the playhead to frame 0 (position 0.0s)
2. Set Position to `(0, 0, 0)` in the Inspector
3. Click the key icon next to `position` — Godot adds a track
4. Move the playhead to frame 1.0s
5. Set Position to `(0, 2, 0)` in the Inspector
6. Click the key icon again

Press Play in the Animation panel. The mesh moves up 2 units over 1 second. That's the whole system. The complexity comes from what you do with it.

### What You Can Animate

**Node3D transforms:**
```
position          → moves in world space
rotation_degrees  → rotates (Inspector shows degrees, internally radians)
scale             → non-uniform scaling possible
```

**Material properties** — click the material in Inspector, expand it, key any property:
```
albedo_color       → color shifts, tinting effects
roughness          → surface changes
emission           → glowing up/down
emission_energy    → pulse effects
transparency/alpha → fade in/out (requires Transparency mode on material)
```

**Visibility:**
```
visible           → boolean toggle (creates a Discrete track, not interpolated)
modulate          → for Control and Sprite2D nodes (Color with alpha)
modulate:a        → just the alpha channel
```

**Shader uniforms** via `ShaderMaterial`:
```
# In the Animation panel, after adding a ShaderMaterial to a mesh:
# Track path: MeshInstance3D:mesh:surface_0:material:shader_parameter/my_param
```
Right-click a shader parameter in the Inspector when AnimationPlayer is focused, or use the track-add button in the Animation panel and navigate the property path.

**Audio** — AnimationPlayer has an audio track type that plays streams at specific points.

**Script variables** — any `@export` variable on a script can be keyframed. Animate integers, floats, Vector3s, bools — whatever your logic needs.

### The Animation Editor UI

Key controls in the Animation panel:

| Control | Purpose |
|---------|---------|
| Play button (▶) | Play animation from playhead |
| Stop (■) | Stop playback |
| Loop button (↻) | Toggle loop mode |
| Speed multiplier | Adjust playback speed (1x, 0.5x, 2x, etc.) |
| Length field | Total animation duration in seconds |
| Snap field | Keyframe snap resolution (0.1, 0.05, etc.) |
| Add track (+) | Manually add a new track by type |
| Zoom | Timeline zoom for fine editing |

**Keyframe interpolation** — right-click any keyframe diamond on the timeline to set the interpolation type:
- **Linear**: constant rate of change between keyframes
- **Cubic**: smooth ease using cubic Hermite spline
- **Nearest**: instant jump (good for boolean properties, sprite frame swaps)

**Loop modes** (the loop button dropdown):
- **No Loop**: plays once and stops
- **Loop**: repeats from the beginning
- **Ping-Pong**: plays forward then backward

### Playing Animations from Code

```gdscript
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    # Play by name
    anim.play("idle")

func _on_player_jumped() -> void:
    anim.play("jump")

func _on_player_landed() -> void:
    # Play with blend time — smoothly transitions from current animation
    anim.play("land", 0.2)

func open_door() -> void:
    anim.play("door_open")
    # Wait for the animation to finish before proceeding
    await anim.animation_finished
    print("Door is now fully open")
    # Now do something: enable a trigger area, play a sound, etc.

func reset_state() -> void:
    # Play backwards
    anim.play_backwards("door_open")

func pause_game() -> void:
    anim.pause()

func resume_game() -> void:
    anim.play()  # Resumes from current position

func skip_to_end() -> void:
    # Seek to a specific time
    anim.seek(anim.current_animation_length, true)  # true = update immediately
```

The `animation_finished` signal is essential for sequencing: open a door, THEN spawn an enemy, THEN unlock a chest. Chain them with `await`.

### Multiple Animations

An `AnimationPlayer` holds a library of animations. You can add as many animations as you want. In the Animation panel dropdown, each named animation appears. They're stored in an `AnimationLibrary` resource (more on this in section 4).

```gdscript
# List all animations
for anim_name in anim.get_animation_list():
    print(anim_name)

# Check current animation
print(anim.current_animation)

# Queue animations to play in sequence
anim.queue("attack_windup")
anim.queue("attack_swing")
anim.queue("attack_recovery")
# They play back-to-back automatically
```

---

## 2. Track Types Deep Dive

AnimationPlayer has six distinct track types. Choosing the right one matters for performance and correctness.

### Property Track

The most common track type. Keyframes any exported property on any node. When you click the key icon in the Inspector, Godot creates a Property track automatically.

The track path looks like: `NodePath:property_name`

Examples:
```
MeshInstance3D:position
MeshInstance3D:scale
DirectionalLight3D:light_energy
Camera3D:fov
Label:text          ← yes, you can animate text!
ColorRect:color
```

For nested properties (like a material on a mesh surface):
```
MeshInstance3D:mesh:surface_0:material:albedo_color
```

### Method Call Track

Calls a function at a specific time in the animation. This is how you sync game events to animation frames without polling. In the Animation panel, click the **+** button to add a track, choose **Call Method Track**, and point it to a node. Then right-click on the track timeline to add a call keyframe — you'll be prompted for the method name and any arguments.

```gdscript
# Character script — these functions are called by Method Call tracks in AnimationPlayer

func play_footstep() -> void:
    # Called by Method Call track at frames 0.3 and 0.7 of the walk cycle
    footstep_audio.stream = footstep_randomizer  # AudioStreamRandomizer
    footstep_audio.pitch_scale = randf_range(0.9, 1.1)
    footstep_audio.play()

func trigger_attack_hitbox() -> void:
    # Called at the exact frame the weapon makes contact
    # NOT at the start of the swing animation
    attack_area.monitoring = true

func end_attack_hitbox() -> void:
    # Called at the frame the weapon lifts away
    attack_area.monitoring = false

func spawn_impact_sparks(position: Vector3) -> void:
    # Method Call tracks can pass arguments too
    var sparks := spark_particles.instantiate()
    sparks.global_position = position
    get_parent().add_child(sparks)
    sparks.emitting = true
```

**Critical use cases for Method Call tracks:**
- Footstep sounds: trigger at exact foot-contact frames, not on a timer
- Damage application: sword hits at frame 0.6, not at frame 0.0 when the swing starts
- VFX: dust, sparks, blood — synced to impact frames
- Combo windows: set a flag that enables the next attack input
- Dialogue: trigger specific dialogue lines during a cutscene
- Screen shake: call a camera shake function at impact frames

### Audio Track

Plays an `AudioStream` resource at a specific point in the animation timeline. Add it via the **+** button → **Audio Track**, point it to an `AudioStreamPlayer` node. Drag an audio file onto the track to add a playback keyframe.

Audio tracks are better than Method Call tracks for music and ambient sounds because Godot handles the synchronization internally and can blend volume. For one-shot sounds with randomization (footsteps), Method Call tracks give you more control.

```gdscript
# Audio tracks in AnimationPlayer work well for:
# - Door creak sound timed to door rotation
# - Ambient sounds that start when entering a zone
# - Music changes in cutscenes
# - UI feedback sounds in menu animations
```

### Bezier Track

Like a Property track, but the interpolation is defined by Bezier curves rather than linear interpolation. Opens a Bezier curve editor when you click the track. Useful for fine-tuning easing — a camera zoom that slows near the target, a heartbeat pulse with organic rhythm.

```gdscript
# Bezier tracks shine for:
# - Camera FOV changes that need organic feel
# - Character expression blend shapes
# - Environmental effects (waterfall spray intensity)
# - Any animation where linear or cubic interpolation feels mechanical
```

To add: click **+** in Animation panel → **Bezier Track**. In the editor you'll see a curve editor instead of diamond keyframes. Click to add control points, drag handles for curve shape.

### Animation Track

Triggers other animations at a specific point. Useful for:
- Compositing sequences: a "combat_sequence" animation that chains attack, recoil, recovery
- One-shot sub-animations: a character's flag waves as part of a celebration animation
- Layered effects: run an idle animation while a separate "breathing" animation also plays

```gdscript
# Animation tracks reference other named animations by name.
# When the playhead hits the track keyframe, that animation starts playing.
# Great for hierarchical animation systems without writing state machine logic.
```

### Rotation Track (3D)

Specialized for bone/Node3D rotation. Uses quaternion interpolation internally for correct 3D rotation blending (avoids gimbal lock that you'd get with Euler angle property tracks). When you import skeletal animations, Godot automatically creates rotation tracks for bones.

---

## 3. Non-Character Uses of AnimationPlayer

This is the section most tutorials skip. AnimationPlayer is a general timeline system. Here are practical non-character examples.

### Door Opening

```gdscript
# DoorController.gd
extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var door_audio: AudioStreamPlayer3D = $DoorAudio
@onready var interaction_area: Area3D = $InteractionArea

var is_open: bool = false

func _ready() -> void:
    interaction_area.body_entered.connect(_on_player_entered)

func _on_player_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        toggle_door()

func toggle_door() -> void:
    if is_open:
        anim.play_backwards("door_open")
    else:
        anim.play("door_open")
    is_open = !is_open
    await anim.animation_finished
    print("Door toggled, now open: ", is_open)
```

The `door_open` animation contains:
- A Property track on `HingeMesh:rotation_degrees:y` from 0 to 90 over 0.8 seconds
- An Audio track that plays the creak sound at frame 0.0
- A Property track on `PointLight3D:light_energy` from 0.5 to 1.2 (the room brightens as the door opens, letting light in)
- A Method Call track at frame 0.8 that calls `_on_door_fully_open()` on the door controller

All of this in a single timeline. No coroutines, no `_process` polling for rotation.

### UI Menu Transitions

```gdscript
# MainMenu.gd
extends Control

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var buttons_container: VBoxContainer = $ButtonsContainer
@onready var logo: TextureRect = $Logo
@onready var settings_panel: Control = $SettingsPanel

func _ready() -> void:
    # Start with everything invisible, then play the appear animation
    anim.play("menu_appear")

func show_settings() -> void:
    anim.play("to_settings")
    await anim.animation_finished
    # Settings is now visible, buttons are hidden

func hide_settings() -> void:
    anim.play_backwards("to_settings")
    await anim.animation_finished

func start_game() -> void:
    anim.play("menu_disappear")
    await anim.animation_finished
    get_tree().change_scene_to_file("res://scenes/game.tscn")
```

The `menu_appear` animation contains:
- Logo: `position:y` slides from -100 to 0, `modulate:a` fades from 0 to 1
- Buttons: staggered `modulate:a` fades, each starting 0.1s later than the previous
- Background: `color` shifts from black to the menu background color

The `to_settings` animation:
- `ButtonsContainer:position:x` slides off to the left (negative x)
- `SettingsPanel:position:x` slides in from the right
- Both panels animate `modulate:a`

This is cleaner than writing tween code per-element and lets a designer tweak timing without touching code.

### Day-Night Cycle

```gdscript
# DayNightCycle.gd
extends Node

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sun: DirectionalLight3D = $Sun
@onready var environment: WorldEnvironment = $WorldEnvironment

@export var day_duration_seconds: float = 120.0

func _ready() -> void:
    # Set animation length to match day duration
    # The animation plays at real-time speed, looping
    anim.speed_scale = anim.current_animation_length / day_duration_seconds
    anim.play("day_night_cycle")

func get_time_of_day() -> float:
    # Returns 0.0 (midnight) to 1.0 (next midnight)
    return anim.current_animation_position / anim.current_animation_length
```

The `day_night_cycle` animation (looping, let's say 60 seconds at 1x):
- `Sun:rotation_degrees:x` from -90 to 270 (full circle)
- `Sun:light_energy` — peaks at noon, goes to 0 at night
- `Sun:light_color` — warm orange at sunrise/sunset, white at noon
- `WorldEnvironment:environment:ambient_light_color` — dark blue at night, light blue during day
- `WorldEnvironment:environment:sky_top_color` — full sky gradient
- A Method Call track at dawn and dusk to trigger bird/cricket ambient sounds

Changing the `speed_scale` makes days longer or shorter without touching the animation data.

### Cutscene System

```gdscript
# CutscenePlayer.gd
extends Node

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera3D = $CutsceneCamera
@onready var skip_label: Label = $UI/SkipLabel

var skippable: bool = true
var cutscene_ended: bool = false

func play_cutscene(cutscene_name: String) -> void:
    camera.make_current()
    skip_label.visible = skippable
    anim.play(cutscene_name)
    anim.animation_finished.connect(_on_cutscene_finished, CONNECT_ONE_SHOT)

func _input(event: InputEvent) -> void:
    if skippable and event.is_action_pressed("ui_cancel") and not cutscene_ended:
        skip_cutscene()

func skip_cutscene() -> void:
    anim.stop()
    _on_cutscene_finished(anim.current_animation)

func _on_cutscene_finished(_anim_name: String) -> void:
    cutscene_ended = true
    skip_label.visible = false
    # Return control to player camera
    $PlayerCamera.make_current()
    # Trigger whatever comes after the cutscene
    cutscene_complete.emit()

# Called by Method Call track in the animation
func show_dialogue(text: String) -> void:
    $UI/DialogueBox.show_text(text)

func trigger_music_change(track_name: String) -> void:
    MusicManager.transition_to(track_name)

signal cutscene_complete
```

### Screen Flash Effect

Common use: damage flash, screen hit reaction, level transition.

```gdscript
# ScreenEffects.gd — autoload singleton
extends CanvasLayer

@onready var flash_rect: ColorRect = $FlashRect
@onready var anim: AnimationPlayer = $AnimationPlayer

func flash_white() -> void:
    flash_rect.color = Color.WHITE
    anim.stop()
    anim.play("flash")

func flash_red() -> void:
    flash_rect.color = Color(1, 0, 0, 1)
    anim.stop()
    anim.play("flash")

func transition_to_black(duration: float = 0.5) -> void:
    anim.speed_scale = 0.5 / duration
    anim.play("fade_to_black")
    await anim.animation_finished
    anim.speed_scale = 1.0
```

The `flash` animation:
- `FlashRect:modulate:a` keyframes: 0.0s → 1.0, 0.1s → 0.0 (fast fade out)
- Duration: 0.2 seconds, no loop

The `fade_to_black` animation:
- `FlashRect:modulate:a` from 0.0 to 1.0 over 0.5s
- `FlashRect:color` is set before playing via code

---

## 4. Importing Skeletal Animations

### Getting Animations from Mixamo

Mixamo (mixamo.com) is Adobe's free animation library with thousands of motion-captured character animations. The workflow:

1. Go to [mixamo.com](https://mixamo.com) — requires a free Adobe account
2. **Upload your character** (or use one of their provided characters): Upload button accepts FBX, OBJ, or ZIP
3. Browse the animation library — search for "idle", "walking", "jump", etc.
4. Preview animations on your character in the viewport
5. Adjust parameters (speed, character arm space, etc.)
6. **Download**:
   - First animation: **Format: FBX**, **Skin: With Skin**, **Frames: 30fps**
   - All subsequent animations: **Format: FBX**, **Skin: Without Skin** (same skeleton, no duplicate mesh)

You'll end up with files like:
```
character.fbx          (T-pose, with mesh — use for the base character)
idle.fbx               (without skin)
walking.fbx            (without skin)
running.fbx            (without skin)
jumping.fbx            (without skin)
falling.fbx            (without skin)
landing.fbx            (without skin)
sword_attack.fbx       (without skin)
```

### Importing into Godot

Drop all FBX files into your Godot project's `res://` folder (or a subfolder like `res://character/animations/`). Godot handles FBX and GLTF natively — no plugins needed for Godot 4.

Select the base character FBX in the FileSystem dock. The **Import** dock on the right shows import options. Important settings:

| Setting | Value | Why |
|---------|-------|-----|
| Import Scene As | Node3D | Standard for 3D scenes |
| Root Type | CharacterBody3D | Or leave as Node3D and change later |
| Animation > Import | Enabled | Import embedded animations |
| Animation > Storage | Files (.res) | Saves animations as separate resources |
| Animation > FPS | 30 | Match Mixamo export FPS |
| Meshes > Light Baking | Disabled | Not needed for characters |

Click **Reimport** after changing settings. Godot generates a `.import` file and potentially a `.res` file for animations.

For animation-only FBX files (the "without skin" ones), Godot imports them as scenes containing just a skeleton with animations. You can then reference these animation libraries.

### Animation Libraries

Godot 4 organizes animations into `AnimationLibrary` resources. When you select an `AnimationPlayer`, the Animation panel shows a dropdown. Under the hood, animations are stored in libraries with names.

The default library has the name `""` (empty string). Imported files create a library named after the file:
```
""              → default library (manually created animations)
"idle"          → from idle.fbx import
"walking"       → from walking.fbx import
"sword_attack"  → from sword_attack.fbx import
```

To access them in code:
```gdscript
# Play animation from a specific library
anim.play("idle/mixamo.com")  # Mixamo names the animation "mixamo.com" internally

# Or rename during import: in Import dock, expand Animation > Animations,
# find the animation and rename it to something cleaner
anim.play("idle/idle")

# List all libraries
for lib_name in anim.get_animation_library_list():
    print("Library: ", lib_name)
    var lib := anim.get_animation_library(lib_name)
    for anim_name in lib.get_animation_list():
        print("  Animation: ", anim_name)
```

### Merging Animation Libraries

To consolidate animations into one AnimationPlayer:

```gdscript
# Editor script approach — or do this in the import dock
# In the AnimationPlayer's animation dock, you can drag animations
# between libraries using the Animation > Manage Animations menu.

# From code (useful for runtime loading):
func load_animation_library(path: String, lib_name: String) -> void:
    var scene := load(path)
    var instance := scene.instantiate()
    var source_anim_player: AnimationPlayer = find_child_animation_player(instance)
    if source_anim_player:
        var lib := source_anim_player.get_animation_library("")
        anim_player.add_animation_library(lib_name, lib)
    instance.free()
```

### Skeleton Retargeting

If your animations come from different skeletons (e.g., Mixamo uses a specific bone naming convention, but you have a custom character), Godot 4.0+ has a retargeting system.

In the Import dock for an animation FBX:
1. Expand **Skeleton > Retarget**
2. Set **Retarget Source** to point to your character's skeleton profile
3. Godot maps bones by name or by skeletal profile

The `SkeletonProfile` resource defines canonical bone names (Hips, Spine, Chest, Neck, Head, LeftUpperArm, etc.). Godot ships with a Humanoid profile. If your character uses Mixamo bone names and your target also uses Mixamo names, retargeting works automatically.

```gdscript
# Verify skeleton bone mapping
func check_skeleton_bones() -> void:
    var skeleton: Skeleton3D = $Armature/Skeleton3D
    for i in skeleton.get_bone_count():
        print("Bone %d: %s" % [i, skeleton.get_bone_name(i)])
```

---

## 5. AnimationTree: State Machines

`AnimationPlayer` stores animations. `AnimationTree` processes them — blending, transitioning, and selecting which animation plays based on game state. The most important AnimationTree node type is `AnimationNodeStateMachine`.

### Basic Setup

```
- CharacterBody3D
  - Armature
    - Skeleton3D
      - MeshInstance3D
  - AnimationPlayer     ← holds all animations
  - AnimationTree       ← processes them
```

**Step-by-step setup:**

1. Add `AnimationTree` node to the scene (sibling of `AnimationPlayer`)
2. In the Inspector, set **Anim Player** property to point to your `AnimationPlayer` node
3. Click **Tree Root** → choose **New AnimationNodeStateMachine**
4. Check **Active** in the Inspector (set to true) — the tree is now processing
5. Double-click the `AnimationTree` node to open the state machine editor (or click the popup icon next to Tree Root)

### Building the State Machine

In the state machine editor:
- **Right-click** → **Add Animation** to create a state that plays an animation
- **Select a state**, then choose which animation it plays from the dropdown at the top
- **Draw connections** between states: hover over the edge of a state until you see an arrow, then drag to another state
- **Click a transition arrow** to configure it in the Inspector:
  - **Switch Mode**: `Immediate` (cuts instantly), `Sync` (waits for same position in new anim), `AtEnd` (waits for current animation to finish)
  - **Advance Mode**: `Auto` (transitions when conditions met), `Enabled` (transitions when called from code), `Disabled`
  - **Xfade Time**: seconds to crossfade between animations (0.2 is a good default for most transitions)
  - **Xfade Curve**: easing curve for the crossfade

Add an **Entry** node (already there by default) and connect it to your default state. Connect an **End** node if you want a terminal state.

### State Machine from Code

```gdscript
extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree

# Get the playback controller — this is the object you call travel/start on
@onready var state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/playback"]

const GRAVITY: float = 9.8
const WALK_SPEED: float = 3.0
const RUN_SPEED: float = 7.0
const JUMP_VELOCITY: float = 5.0

func _physics_process(delta: float) -> void:
    # Apply gravity
    if not is_on_floor():
        velocity.y -= GRAVITY * delta

    # Handle jumping
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Handle movement input
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if direction:
        velocity.x = direction.x * RUN_SPEED
        velocity.z = direction.z * RUN_SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, RUN_SPEED)
        velocity.z = move_toward(velocity.z, 0, RUN_SPEED)

    move_and_slide()

    # Update animation state machine
    _update_animation_state()

func _update_animation_state() -> void:
    var horizontal_speed := Vector2(velocity.x, velocity.z).length()

    if is_on_floor():
        if horizontal_speed < 0.1:
            state_machine.travel("idle")
        elif horizontal_speed < 5.0:
            state_machine.travel("walk")
        else:
            state_machine.travel("run")
    else:
        if velocity.y > 0.5:
            state_machine.travel("jump")
        elif velocity.y < -0.5:
            state_machine.travel("fall")
        # At the apex of the jump, let the current state hold

func _on_landed() -> void:
    # Called when we detect landing (was_on_floor changed)
    state_machine.travel("land")

func get_current_state() -> String:
    return state_machine.get_current_node()
```

### travel() vs start()

```gdscript
# travel() — follows the defined transition path in the state machine.
# Respects xfade_time, switch_mode, and the connection between states.
# If there's no direct path, it finds the shortest path through intermediate states.
state_machine.travel("run")

# start() — jumps directly to a state, ignoring transitions.
# Instant, no crossfade. Use for hard cuts.
state_machine.start("idle")

# When to use start():
# - Respawning (snap to idle, no fade from death)
# - First frame initialization
# - When you need precise state control for debugging

# When to use travel():
# - All normal gameplay transitions
# - Anything the player will see
```

### Avoiding the Travel-Every-Frame Problem

```gdscript
# WRONG: Calling travel every frame resets the transition timer
func _physics_process(delta: float) -> void:
    state_machine.travel("idle")  # Don't do this if already in idle

# RIGHT: Check current state before traveling
func _update_animation_state() -> void:
    var target_state := _determine_target_state()
    if state_machine.get_current_node() != target_state:
        state_machine.travel(target_state)

func _determine_target_state() -> String:
    if not is_on_floor():
        return "jump" if velocity.y > 0 else "fall"
    if Vector2(velocity.x, velocity.z).length() < 0.1:
        return "idle"
    if Vector2(velocity.x, velocity.z).length() < 5.0:
        return "walk"
    return "run"
```

---

## 6. Blend Spaces

Blend spaces interpolate between multiple animations based on one or two parameters. Instead of discrete states (idle OR walk OR run), you get smooth continuous blending.

### BlendSpace1D — Speed-Based Blending

```
Parameters: blend_position (float, 0.0 to 1.0 typically)
Animations:
  0.0 → idle
  0.5 → walk
  1.0 → run
```

Setup in the state machine editor:
1. Instead of adding an **Animation** state, right-click → **Add BlendSpace1D**
2. Double-click the BlendSpace1D node to edit it
3. The editor shows a horizontal axis. Click the **+** button to add animation points
4. Place animations at specific positions on the axis

```gdscript
# In AnimationTree, blend spaces have parameters accessed by path
# If your BlendSpace1D state is named "movement":
const MOVEMENT_BLEND: String = "parameters/movement/blend_position"

const MAX_SPEED: float = 7.0

func _update_movement_blend() -> void:
    var horizontal_speed := Vector2(velocity.x, velocity.z).length()
    var blend_value := clampf(horizontal_speed / MAX_SPEED, 0.0, 1.0)
    anim_tree.set(MOVEMENT_BLEND, blend_value)

# The BlendSpace1D handles the interpolation:
# speed 0.0  → plays idle (position 0.0)
# speed 0.35 → blends 70% idle + 30% walk (position 0.35)
# speed 0.5  → plays walk (position 0.5)
# speed 0.75 → blends 50% walk + 50% run (position 0.75)
# speed 1.0  → plays run (position 1.0)
```

### BlendSpace2D — Directional Blending

For characters with directional movement animations (forward walk, backward walk, strafe left, strafe right), `BlendSpace2D` is the solution.

```
Parameters: blend_position (Vector2)
Animations placed at 2D positions:
  (0, 1)    → walk_forward
  (0, -1)   → walk_backward
  (-1, 0)   → strafe_left
  (1, 0)    → strafe_right
  (0, 0)    → idle (center)
  (-0.7, 0.7) → walk_forward_left (diagonal blend, optional)
```

```gdscript
# BlendSpace2D for directional movement
const MOVEMENT_BLEND_2D: String = "parameters/movement_2d/blend_position"

func _update_directional_blend() -> void:
    if velocity.length() < 0.1:
        # At rest — blend toward center
        var current := anim_tree.get(MOVEMENT_BLEND_2D) as Vector2
        anim_tree.set(MOVEMENT_BLEND_2D, current.lerp(Vector2.ZERO, 0.1))
        return

    # Convert world-space velocity to local character space
    # This makes the blend relative to which way the character is facing
    var local_velocity := global_transform.basis.inverse() * velocity
    local_velocity.y = 0.0  # Ignore vertical component

    # Normalize by max speed
    var blend := Vector2(local_velocity.x, -local_velocity.z) / MAX_SPEED
    blend = blend.clampf(-1.0, 1.0)  # Clamp to valid blend space range

    anim_tree.set(MOVEMENT_BLEND_2D, blend)
```

### BlendSpace2D Sync

For BlendSpace2D, you can enable **Sync** mode so all animations play from the same normalized position. This prevents snapping when the character changes direction — the foot phases stay synchronized.

In the BlendSpace2D editor, check **Sync** at the top. The animations will advance at the same rate relative to their own length.

### Combining Blend Spaces with State Machine

A typical setup uses both:

```
StateMachine
├── grounded (BlendSpace1D: idle/walk/run based on speed)
├── jump (single animation)
├── fall (single animation)
├── land (single animation)
├── attack (sub-StateMachine with combo system)
│   ├── attack_1
│   ├── attack_2
│   └── attack_3
└── [transitions between all of these]
```

```gdscript
# Accessing parameters for nested blend spaces and state machines
const GROUND_BLEND: String = "parameters/grounded/blend_position"
const ATTACK_PLAYBACK: String = "parameters/attack/playback"

func _physics_process(delta: float) -> void:
    # Update top-level state
    _update_animation_state()

    # Always update blend space parameters regardless of current state
    # (they'll be ready when we enter that state)
    var speed := Vector2(velocity.x, velocity.z).length()
    anim_tree.set(GROUND_BLEND, clampf(speed / MAX_SPEED, 0.0, 1.0))

func trigger_attack() -> void:
    state_machine.travel("attack")
    var attack_sm: AnimationNodeStateMachinePlayback = anim_tree[ATTACK_PLAYBACK]
    attack_sm.start("attack_1")
```

---

## 7. Root Motion

Root motion is animation-driven movement. Instead of code controlling where the character moves and the animation playing visually in place, the animation itself contains movement data that drives the character's position.

### Why Root Motion Exists

Without root motion, you have a problem: your walk cycle animation moves the feet at one speed, but your code moves the character at a different speed. The feet slide. The foot contacts don't line up with the actual movement.

With root motion, the animator bakes movement into the root bone of the skeleton. Godot reads that movement data and applies it to the `CharacterBody3D`. The character's actual position matches the animation's intended movement exactly.

### Enabling Root Motion

In the AnimationTree Inspector:
- **Root Motion Track**: set this to the NodePath of the root bone that contains motion, e.g., `Armature/Skeleton3D:Root`

The root bone is the top-level bone in the skeleton hierarchy. In Mixamo animations, it's often called `Hips` or `Root`. Not all animations have root motion baked in — you may need to enable it in the animation software (Blender, Maya) or find animations explicitly tagged as "root motion" versions.

```gdscript
extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/playback"]

const GRAVITY: float = 9.8

func _physics_process(delta: float) -> void:
    # Apply gravity manually — root motion doesn't handle vertical movement
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = 0.0

    # Get movement from animation root motion
    var root_motion_pos := anim_tree.get_root_motion_position()
    var root_motion_rot := anim_tree.get_root_motion_rotation()

    # The root motion position is in LOCAL space of the skeleton root
    # Convert to world space using the character's transform
    var world_motion := global_transform.basis * root_motion_pos

    # Set velocity from root motion (it's a delta position, convert to velocity)
    velocity.x = world_motion.x / delta
    velocity.z = world_motion.z / delta

    # Apply root motion rotation to the character body
    # This lets the animation turn the character
    var rotation_delta := Basis(root_motion_rot)
    global_transform.basis = global_transform.basis * rotation_delta

    move_and_slide()

func _update_animation_state() -> void:
    var current_speed := Vector2(velocity.x, velocity.z).length()
    if is_on_floor():
        if current_speed < 0.1:
            state_machine.travel("idle")
        else:
            state_machine.travel("walk")
    else:
        state_machine.travel("fall")
```

### Root Motion Rotation

```gdscript
# If your animations turn the character (like a turning-in-place animation),
# apply root motion rotation:
func _physics_process(delta: float) -> void:
    var root_rot := anim_tree.get_root_motion_rotation()
    # root_rot is a Quaternion representing the delta rotation this frame

    # Apply to the character's Y-axis rotation only
    var rot_delta := Basis(root_rot).get_euler()
    rotate_y(rot_delta.y)

    # Also get accumulated rotation for direction-aware movement
    var accumulated_rot := anim_tree.get_root_motion_rotation_accumulator()
    # This is the total rotation since last reset
```

### When to Use Root Motion

**Use root motion when:**
- Realistic character locomotion where foot slip is noticeable (third-person RPG)
- Cinematic cutscenes where character movement is authored
- Complex movement animations: rolling, climbing, dodging
- Turn-in-place animations
- Any animation where the character's path is authored by the animator

**Do NOT use root motion when:**
- Fast-paced arcade games (root motion adds input latency)
- Platform games with precise jumps (physics must be code-controlled)
- Characters that need immediate velocity changes
- Multiplayer games where you control velocity for sync purposes

```gdscript
# Toggle root motion based on game state
@export var use_root_motion: bool = true

func _physics_process(delta: float) -> void:
    if use_root_motion:
        _physics_with_root_motion(delta)
    else:
        _physics_without_root_motion(delta)

func _physics_with_root_motion(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= GRAVITY * delta

    var root_pos := anim_tree.get_root_motion_position()
    var world_pos := global_transform.basis * root_pos
    velocity.x = world_pos.x / delta
    velocity.z = world_pos.z / delta
    move_and_slide()

func _physics_without_root_motion(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= GRAVITY * delta

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * MAX_SPEED
    velocity.z = direction.z * MAX_SPEED
    move_and_slide()
```

---

## 8. Animation Callbacks and Events

Method Call tracks let animations drive game logic at precise frames. This is one of the most practical features in AnimationPlayer and one of the most commonly under-used.

### Adding Method Call Tracks

In the Animation panel:
1. Click the **+** (Add Track) button
2. Select **Call Method Track**
3. Choose the node whose method you want to call
4. Right-click on the track's timeline at the desired frame
5. Select **Add Call**
6. Enter the method name and any arguments

Arguments can be: int, float, String, Vector2, Vector3, Color, bool, NodePath.

### Footstep Sound System

```gdscript
# PlayerCharacter.gd
extends CharacterBody3D

@onready var footstep_left: AudioStreamPlayer3D = $FootstepLeft
@onready var footstep_right: AudioStreamPlayer3D = $FootstepRight
@onready var footstep_randomizer: AudioStreamRandomizer = preload("res://audio/footstep_randomizer.tres")

# Surface detection for different footstep sounds
@export var footstep_surfaces: Dictionary = {
    "grass": preload("res://audio/footsteps/grass_randomizer.tres"),
    "stone": preload("res://audio/footsteps/stone_randomizer.tres"),
    "wood": preload("res://audio/footsteps/wood_randomizer.tres"),
    "dirt": preload("res://audio/footsteps/dirt_randomizer.tres"),
}

var current_surface: String = "stone"

# Called by Method Call track at left foot contact frames (0.0s and 0.5s in walk cycle)
func footstep_left_contact() -> void:
    var stream := footstep_surfaces.get(current_surface, footstep_randomizer)
    footstep_left.stream = stream
    footstep_left.pitch_scale = randf_range(0.9, 1.1)
    footstep_left.volume_db = randf_range(-3.0, 0.0)
    footstep_left.play()

# Called by Method Call track at right foot contact frames (0.25s and 0.75s in walk cycle)
func footstep_right_contact() -> void:
    var stream := footstep_surfaces.get(current_surface, footstep_randomizer)
    footstep_right.stream = stream
    footstep_right.pitch_scale = randf_range(0.9, 1.1)
    footstep_right.volume_db = randf_range(-3.0, 0.0)
    footstep_right.play()

# Called by physics raycasting to detect current surface
func _detect_ground_surface() -> void:
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(
        global_position,
        global_position + Vector3.DOWN * 1.5
    )
    var result := space.intersect_ray(query)
    if result and result.collider.has_meta("surface_type"):
        current_surface = result.collider.get_meta("surface_type")
```

### Attack Damage Application

```gdscript
# Warrior.gd
extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var attack_area: Area3D = $AttackArea
@onready var hit_audio: AudioStreamPlayer3D = $HitAudio
@onready var swing_audio: AudioStreamPlayer3D = $SwingAudio
@onready var whoosh_audio: AudioStreamPlayer3D = $WhooshAudio

@export var attack_damage: float = 25.0
@export var attack_knockback: float = 5.0

var can_combo: bool = false
var combo_count: int = 0

func trigger_attack() -> void:
    if not is_on_floor():
        return
    combo_count = clamp(combo_count + 1, 1, 3)
    var attack_name := "attack_%d" % combo_count
    anim_player.play(attack_name, 0.1)

# === Methods called by Method Call tracks in attack animations ===

# Called at frame 0.0 of every attack animation (sword begins to swing)
func attack_begin_swing() -> void:
    whoosh_audio.play()
    attack_area.monitoring = false  # Hitbox not active yet

# Called at frame where sword reaches the hit zone
# attack_1: frame 0.35s, attack_2: frame 0.28s, attack_3: frame 0.42s
func attack_apply_damage() -> void:
    attack_area.monitoring = true
    var bodies := attack_area.get_overlapping_bodies()
    for body in bodies:
        if body == self:
            continue
        if body.is_in_group("enemy") or body.is_in_group("destructible"):
            if body.has_method("take_damage"):
                var knockback_dir := (body.global_position - global_position).normalized()
                body.take_damage(attack_damage, knockback_dir, attack_knockback)
                hit_audio.play()
    # Disable hitbox after applying damage (only hits once per swing)
    attack_area.monitoring = false

# Called at the frame when the player CAN press attack to continue the combo
func open_combo_window() -> void:
    can_combo = true

# Called at the end of the combo window
func close_combo_window() -> void:
    can_combo = false
    if combo_count >= 3:
        combo_count = 0  # Reset after full combo

# Called at the very end of the recovery animation
func attack_recovery_complete() -> void:
    combo_count = 0
    can_combo = false
    attack_area.monitoring = false

func _input(event: InputEvent) -> void:
    if event.is_action_just_pressed("attack"):
        if can_combo:
            trigger_attack()
        elif combo_count == 0:
            combo_count = 0
            trigger_attack()
```

### VFX and Environmental Callbacks

```gdscript
# These might live on different nodes, but all called via Method Call tracks

# Called when an explosion animation reaches the blast frame
func spawn_explosion_vfx() -> void:
    var explosion := explosion_scene.instantiate()
    explosion.global_position = global_position
    get_tree().current_scene.add_child(explosion)

# Called during a landing animation at the frame of impact
func spawn_landing_dust() -> void:
    if not is_on_floor():
        return
    var dust := dust_scene.instantiate()
    dust.global_position = Vector3(global_position.x, global_position.y - 0.1, global_position.z)
    get_parent().add_child(dust)
    dust.emitting = true

# Called at specific frames of an environmental animation (volcano eruption, etc.)
func trigger_screen_shake(intensity: float) -> void:
    ScreenEffects.shake(intensity, 0.3)

# Called during cutscene animation to advance dialogue
func show_dialogue_line(line_id: String) -> void:
    DialogueManager.show_line(line_id)
```

---

## 9. Procedural Animation with Tweens

Tweens are Godot's code-first animation system. They don't require an AnimationPlayer node or a timeline editor. For simple, reactive, one-shot animations triggered by game events, Tweens are faster to write and more flexible than AnimationPlayer.

### Tween Basics

```gdscript
# Create a tween (it's automatically freed when done, unless set to loop)
var tween := create_tween()

# Animate position.y from current value to target over 0.5 seconds
tween.tween_property(self, "position:y", target_y, 0.5)

# Chain another property animation after the first completes
tween.tween_property(self, "scale", Vector3.ONE * 1.2, 0.2)
tween.tween_property(self, "scale", Vector3.ONE, 0.2)

# Call a function after a delay
tween.tween_callback(some_function).set_delay(1.0)

# Parallel animations (run simultaneously instead of sequentially)
tween.set_parallel(true)
tween.tween_property(self, "position:y", 5.0, 1.0)
tween.tween_property(self, "modulate:a", 0.0, 1.0)

# Or use parallel() for a single step
tween.tween_property(self, "position:y", 5.0, 1.0)
tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
```

### Bobbing Collectible

```gdscript
# Collectible.gd
extends Area3D

@export var bob_height: float = 0.3
@export var bob_speed: float = 1.0
@export var spin_speed: float = 1.5

var base_y: float

func _ready() -> void:
    base_y = position.y

    # Bobbing tween — loops forever
    var bob_tween := create_tween().set_loops()
    bob_tween.tween_property(self, "position:y", base_y + bob_height, bob_speed)\
        .set_ease(Tween.EASE_IN_OUT)\
        .set_trans(Tween.TRANS_SINE)
    bob_tween.tween_property(self, "position:y", base_y, bob_speed)\
        .set_ease(Tween.EASE_IN_OUT)\
        .set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
    # Spin using process — simpler than a tween for constant rotation
    rotate_y(spin_speed * delta)

func collect() -> void:
    # Stop bobbing
    # Tweens created with create_tween() on this node stop when node is freed
    # Alternatively: kill all tweens
    # (No direct way to name/kill specific tweens — just free the node after)

    # Play collection animation
    var collect_tween := create_tween()
    collect_tween.set_parallel(true)
    collect_tween.tween_property(self, "position:y", position.y + 1.5, 0.4)\
        .set_ease(Tween.EASE_OUT)\
        .set_trans(Tween.TRANS_QUAD)
    collect_tween.tween_property(self, "scale", Vector3.ZERO, 0.3)\
        .set_ease(Tween.EASE_IN)\
        .set_trans(Tween.TRANS_BACK)\
        .set_delay(0.1)
    collect_tween.tween_property(self, "modulate:a", 0.0, 0.3)\
        .set_delay(0.1)

    # Free the node after animation
    await collect_tween.finished
    queue_free()
```

### Damage Reaction Effects

```gdscript
# On any enemy or player that takes damage

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO, knockback_force: float = 0.0) -> void:
    health -= amount

    # Flash white to indicate damage
    _play_hit_flash()

    # Knockback
    if knockback_force > 0.0:
        _play_knockback(knockback_dir, knockback_force)

    if health <= 0:
        _die()

func _play_hit_flash() -> void:
    # Override material to white, then fade back
    var mat := mesh_instance.material_overlay as StandardMaterial3D
    if not mat:
        mat = StandardMaterial3D.new()
        mat.albedo_color = Color.WHITE
        mat.emission_enabled = true
        mat.emission = Color.WHITE
        mat.emission_energy = 2.0
        mesh_instance.material_overlay = mat

    mat.albedo_color = Color.WHITE
    var tween := create_tween()
    tween.tween_property(mat, "albedo_color", Color.TRANSPARENT, 0.2)\
        .set_ease(Tween.EASE_OUT)
    tween.tween_callback(func(): mesh_instance.material_overlay = null)

func _play_knockback(direction: Vector3, force: float) -> void:
    var target_pos := global_position + direction * force
    # Only move horizontally for knockback
    target_pos.y = global_position.y

    var tween := create_tween()
    tween.tween_property(self, "global_position", target_pos, 0.15)\
        .set_ease(Tween.EASE_OUT)\
        .set_trans(Tween.TRANS_QUAD)

func _die() -> void:
    # Death animation via tween
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "scale:y", 0.0, 0.4)\
        .set_ease(Tween.EASE_IN)\
        .set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "modulate:a", 0.0, 0.5)
    await tween.finished
    queue_free()
```

### UI Animations with Tween

```gdscript
# HUD.gd
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_flash: ColorRect = $DamageFlash
@onready var score_label: Label = $ScoreLabel

func animate_health_change(old_value: float, new_value: float) -> void:
    # Smooth health bar transition
    var tween := create_tween()
    tween.tween_property(health_bar, "value", new_value, 0.3)\
        .set_ease(Tween.EASE_OUT)\
        .set_trans(Tween.TRANS_QUAD)

    # Flash if taking damage
    if new_value < old_value:
        flash_damage()

func flash_damage() -> void:
    damage_flash.modulate.a = 0.4
    var tween := create_tween()
    tween.tween_property(damage_flash, "modulate:a", 0.0, 0.3)\
        .set_ease(Tween.EASE_OUT)

func animate_score(old_score: int, new_score: int) -> void:
    # Count up animation
    var tween := create_tween()
    tween.tween_method(
        func(value: float): score_label.text = str(int(value)),
        float(old_score),
        float(new_score),
        0.5
    ).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

    # Scale pop on score increase
    score_label.scale = Vector3.ONE * 1.3
    tween.parallel().tween_property(score_label, "scale", Vector3.ONE, 0.3)\
        .set_ease(Tween.EASE_OUT)\
        .set_trans(Tween.TRANS_BACK)
```

### Tween vs AnimationPlayer Decision Guide

| Use Tween when... | Use AnimationPlayer when... |
|-------------------|-----------------------------|
| Animation is driven by runtime values | Animation is authored with specific timing |
| One-shot reaction (damage, pickup) | Reusable, looping animation (idle, walk) |
| Simple 1-3 property changes | Complex multi-track timeline |
| You need to interpolate to an unknown target | Target values are fixed |
| Quick to prototype | Designer needs to tweak timing visually |
| No node needed in scene | Fine-grained method call track timing |

They complement each other. An `AnimationPlayer` handles the character's walk cycle; a `Tween` handles the damage flash. Use both.

---

## 10. Advanced: IK, BoneAttachment, and Skeleton Manipulation

### BoneAttachment3D — Attaching Objects to Bones

`BoneAttachment3D` is a Node3D that follows a specific bone on a `Skeleton3D`. Use it to attach weapons, accessories, VFX, or any scene to a character's skeleton.

```gdscript
# Attach a sword to the character's right hand bone
func equip_weapon(weapon_scene: PackedScene) -> void:
    var skeleton: Skeleton3D = $Armature/Skeleton3D

    # Find or create the attachment point
    var attachment := BoneAttachment3D.new()
    attachment.bone_name = "RightHand"  # Must match bone name in the skeleton
    attachment.use_external_skeleton = false  # Using parent skeleton
    skeleton.add_child(attachment)

    # Instance the weapon and add it to the attachment
    var weapon := weapon_scene.instantiate()
    attachment.add_child(weapon)

    # Adjust weapon position relative to hand bone
    weapon.position = Vector3(0.05, 0.0, -0.1)
    weapon.rotation_degrees = Vector3(0, 0, -90)

# Alternative: pre-place BoneAttachment3D in the scene tree
# This is cleaner if you know the skeleton structure ahead of time:
```

Scene tree with pre-placed attachment:
```
- CharacterBody3D
  - Armature
    - Skeleton3D
      - BoneAttachment3D (bone_name = "RightHand")
        - WeaponSocket        ← empty Node3D, children added here at runtime
      - MeshInstance3D
  - AnimationPlayer
  - AnimationTree
```

```gdscript
@onready var weapon_socket: Node3D = $Armature/Skeleton3D/BoneAttachment3D/WeaponSocket

func equip_weapon(weapon_scene: PackedScene) -> void:
    # Clear any current weapon
    for child in weapon_socket.get_children():
        child.queue_free()

    var weapon := weapon_scene.instantiate()
    weapon_socket.add_child(weapon)
    weapon.position = Vector3.ZERO
    weapon.rotation = Vector3.ZERO
```

### SkeletonIK3D — Inverse Kinematics

`SkeletonIK3D` calculates bone rotations to reach a target position. The classic uses: feet planted on uneven ground, hands reaching for a door handle, head looking at a target.

```gdscript
# FootIK.gd — keep feet planted on uneven terrain
extends Node3D

@onready var skeleton: Skeleton3D = $"../Armature/Skeleton3D"
@onready var left_foot_ik: SkeletonIK3D = $"../LeftFootIK"
@onready var right_foot_ik: SkeletonIK3D = $"../RightFootIK"

# SkeletonIK3D setup (in Inspector):
# - root_bone: "LeftUpLeg" (or whatever your upper leg bone is named)
# - tip_bone: "LeftFoot"
# - target: NodePath to an empty Node3D that you move to the raycast hit position
# - interpolation: 1.0 (full IK)
# - min_distance: 0.01

@onready var left_foot_target: Node3D = $LeftFootTarget
@onready var right_foot_target: Node3D = $RightFootTarget

func _physics_process(delta: float) -> void:
    _update_foot_ik($LeftFootPosition.global_position, left_foot_target, left_foot_ik)
    _update_foot_ik($RightFootPosition.global_position, right_foot_target, right_foot_ik)

func _update_foot_ik(foot_pos: Vector3, target: Node3D, ik: SkeletonIK3D) -> void:
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(
        foot_pos + Vector3.UP * 0.5,  # Start above the foot
        foot_pos + Vector3.DOWN * 0.5  # Cast downward
    )
    query.exclude = [get_parent()]  # Don't hit self
    var result := space.intersect_ray(query)

    if result:
        # Move the IK target to the ground contact point
        var target_pos := result.position
        # Smoothly move target to prevent snapping
        target.global_position = target.global_position.lerp(target_pos, 20.0 * delta)
        ik.start()
    else:
        ik.stop()
```

### Direct Bone Manipulation

For procedural effects — breathing, cloth simulation, look-at — you can directly set bone poses:

```gdscript
# LookAt.gd — character head follows a target
extends Node3D

@onready var skeleton: Skeleton3D = $"../Armature/Skeleton3D"

@export var head_bone_name: String = "Head"
@export var look_strength: float = 0.5  # 0=no effect, 1=full follow

var head_bone_idx: int = -1
var target: Node3D

func _ready() -> void:
    head_bone_idx = skeleton.find_bone(head_bone_name)

func _process(delta: float) -> void:
    if head_bone_idx == -1 or not target:
        return

    # Get current head bone global transform
    var head_global := skeleton.get_bone_global_pose(head_bone_idx)
    var head_world_pos := skeleton.global_transform * head_global.origin

    # Direction from head to target
    var to_target := (target.global_position - head_world_pos).normalized()

    # Convert to local skeleton space for bone pose
    var local_dir := skeleton.global_transform.basis.inverse() * to_target

    # Create a rotation that looks at the target
    var look_basis := Basis.looking_at(local_dir, Vector3.UP)

    # Get current bone local pose
    var current_pose := skeleton.get_bone_pose(head_bone_idx)

    # Blend between current and look target
    var target_rot := current_pose.basis.slerp(look_basis, look_strength)
    current_pose.basis = target_rot

    # Apply
    skeleton.set_bone_pose(head_bone_idx, current_pose)
```

---

## 11. Code Walkthrough: Animated Third-Person Character

This is the complete mini-project: a third-person character with a full animation state machine.

### Scene Structure

```
PlayerScene (CharacterBody3D) [player.gd]
├── Armature
│   └── Skeleton3D
│       ├── BoneAttachment3D (bone = "RightHand")
│       │   └── WeaponSocket
│       └── MeshInstance3D
├── AnimationPlayer
├── AnimationTree
├── AttackArea (Area3D) — hitbox for melee
│   └── CollisionShape3D
├── FootstepLeft (AudioStreamPlayer3D)
├── FootstepRight (AudioStreamPlayer3D)
├── SwingAudio (AudioStreamPlayer3D)
├── LandAudio (AudioStreamPlayer3D)
├── CameraArm (SpringArm3D)
│   └── Camera3D
└── CollisionShape3D
```

### Animation Library Setup

In `AnimationPlayer`, create an animation library named `"character"` with these animations:
- `character/idle` (looping)
- `character/walk` (looping)
- `character/run` (looping)
- `character/jump` (single play)
- `character/fall` (looping)
- `character/land` (single play, short)
- `character/attack_1` (single play)
- `character/attack_2` (single play)
- `character/attack_3` (single play)

Or if importing from Mixamo FBX files, the library names match the filenames.

### AnimationTree Configuration

```
AnimationTree
├── anim_player: @AnimationPlayer
├── tree_root: AnimationNodeStateMachine
└── active: true

State Machine layout:
[Entry] → [grounded]
[grounded]  (BlendSpace1D: blend between idle/walk/run by speed)
[jump]      (plays jump animation once)
[fall]      (plays fall animation, looping)
[land]      (plays landing animation once, short)
[attack]    (sub-StateMachine for combo system)
    [attack_1] → [attack_2] → [attack_3] → [End]

Transitions:
grounded → jump:   Immediate, xfade=0.1, Advance=Enabled
grounded → attack: AtEnd (on complete step), xfade=0.15, Advance=Enabled
jump → fall:       Automatic when velocity.y < 0 (use condition or code)
fall → land:       Immediate, xfade=0.05
land → grounded:   AtEnd (when land finishes), xfade=0.2
attack → grounded: AtEnd, xfade=0.3
```

### Complete Player Script

```gdscript
# player.gd
extends CharacterBody3D

# Movement constants
const WALK_SPEED: float = 3.0
const RUN_SPEED: float = 7.0
const JUMP_VELOCITY: float = 5.5
const GRAVITY: float = 12.0
const TURN_SPEED: float = 10.0

# Attack constants
const ATTACK_DAMAGE: float = 20.0
const ATTACK_KNOCKBACK: float = 4.0

# Animation parameter paths
const PARAM_PLAYBACK: String = "parameters/playback"
const PARAM_GROUND_BLEND: String = "parameters/grounded/blend_position"

# Node references
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = anim_tree[PARAM_PLAYBACK]

@onready var camera_arm: SpringArm3D = $CameraArm
@onready var camera: Camera3D = $CameraArm/Camera3D

@onready var attack_area: Area3D = $AttackArea
@onready var footstep_left: AudioStreamPlayer3D = $FootstepLeft
@onready var footstep_right: AudioStreamPlayer3D = $FootstepRight
@onready var land_audio: AudioStreamPlayer3D = $LandAudio
@onready var swing_audio: AudioStreamPlayer3D = $SwingAudio

# State tracking
var was_on_floor: bool = true
var is_attacking: bool = false
var can_combo: bool = false
var combo_count: int = 0
var camera_angle: float = 0.0

# Footstep sounds per surface
var footstep_sounds: Dictionary = {}
var current_surface: String = "stone"

func _ready() -> void:
    # Initialize
    attack_area.monitoring = false
    anim_tree.active = true
    state_machine.start("grounded")
    was_on_floor = is_on_floor()

    # Capture mouse for camera control
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
    # Camera rotation
    if event is InputEventMouseMotion:
        camera_arm.rotation.y -= event.relative.x * 0.003
        camera_arm.rotation.x -= event.relative.y * 0.003
        camera_arm.rotation.x = clampf(camera_arm.rotation.x, -1.2, 0.4)
        camera_angle = camera_arm.rotation.y

    # Attack input
    if event.is_action_just_pressed("attack"):
        _try_attack()

    # Jump input
    if event.is_action_just_pressed("jump") and is_on_floor():
        _jump()

    # Escape to release mouse
    if event.is_action_just_pressed("ui_cancel"):
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_movement(delta)
    _handle_landing()
    _update_animations()
    move_and_slide()
    was_on_floor = is_on_floor()

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = maxf(velocity.y, -0.5)  # Small downward force to stay grounded

func _handle_movement(delta: float) -> void:
    if is_attacking:
        # Slow movement during attacks
        velocity.x = move_toward(velocity.x, 0, RUN_SPEED * 3 * delta)
        velocity.z = move_toward(velocity.z, 0, RUN_SPEED * 3 * delta)
        return

    # Get camera-relative movement direction
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

    if input_dir == Vector2.ZERO:
        velocity.x = move_toward(velocity.x, 0, RUN_SPEED * 2 * delta)
        velocity.z = move_toward(velocity.z, 0, RUN_SPEED * 2 * delta)
        return

    # Camera-relative direction
    var cam_basis := Basis.from_euler(Vector3(0, camera_angle, 0))
    var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    # Determine speed (sprint if held)
    var target_speed := RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED

    velocity.x = direction.x * target_speed
    velocity.z = direction.z * target_speed

    # Rotate character to face movement direction
    if direction.length() > 0.1:
        var target_angle := atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_angle, TURN_SPEED * delta)

func _handle_landing() -> void:
    # Detect just-landed
    if is_on_floor() and not was_on_floor:
        _on_landed()

func _on_landed() -> void:
    land_audio.play()
    state_machine.travel("land")

func _jump() -> void:
    velocity.y = JUMP_VELOCITY
    state_machine.travel("jump")

func _update_animations() -> void:
    var horizontal_speed := Vector2(velocity.x, velocity.z).length()
    var current_state := state_machine.get_current_node()

    # Update blend space for ground movement
    anim_tree.set(PARAM_GROUND_BLEND, clampf(horizontal_speed / RUN_SPEED, 0.0, 1.0))

    # Update state machine
    if is_on_floor() and not is_attacking:
        if current_state != "grounded" and current_state != "land":
            state_machine.travel("grounded")
    elif not is_on_floor():
        if velocity.y < -1.0 and current_state != "fall":
            state_machine.travel("fall")
        elif velocity.y > 0 and current_state != "jump":
            # Only travel to jump if we just left the ground
            pass  # Let the jump state play out

func _try_attack() -> void:
    if not is_on_floor():
        return  # No air attacks

    if can_combo and combo_count < 3:
        # Continue combo
        _execute_attack()
    elif combo_count == 0:
        # Start combo
        _execute_attack()

func _execute_attack() -> void:
    combo_count = clamp(combo_count + 1, 1, 3)
    is_attacking = true
    can_combo = false

    var attack_name := "attack_%d" % combo_count
    state_machine.travel("attack")

    # For the sub-state-machine inside attack:
    # The attack sub-SM will play attack_1, attack_2, or attack_3
    # based on combo_count. This is managed by the state machine setup.
    # Or if using AnimationPlayer directly for attacks:
    anim_player.play("character/" + attack_name, 0.1)

# === Methods called by AnimationPlayer Method Call tracks ===

func footstep_left_contact() -> void:
    _play_footstep(footstep_left)

func footstep_right_contact() -> void:
    _play_footstep(footstep_right)

func _play_footstep(player: AudioStreamPlayer3D) -> void:
    if not is_on_floor():
        return
    player.pitch_scale = randf_range(0.9, 1.1)
    player.volume_db = randf_range(-4.0, 0.0)
    player.play()

func attack_swing_begin() -> void:
    swing_audio.play()
    attack_area.monitoring = false

func attack_hit_frame() -> void:
    attack_area.monitoring = true
    var bodies := attack_area.get_overlapping_bodies()
    for body in bodies:
        if body == self:
            continue
        if body.has_method("take_damage"):
            var dir := (body.global_position - global_position).normalized()
            body.take_damage(ATTACK_DAMAGE, dir, ATTACK_KNOCKBACK)
    attack_area.monitoring = false

func attack_combo_window_open() -> void:
    can_combo = true

func attack_combo_window_close() -> void:
    can_combo = false

func attack_animation_complete() -> void:
    is_attacking = false
    can_combo = false
    if combo_count >= 3:
        combo_count = 0
    state_machine.travel("grounded")
```

### SpringArm Camera Setup

```gdscript
# camera_controller.gd — alternative if you want it separate
# Or just configure SpringArm3D properties in the Inspector:
# SpringArm3D:
#   spring_length: 5.0      (distance behind character)
#   collision_mask: 1       (collide with world geometry)
#   shape: SphereShape3D    (radius 0.3 — prevents camera clipping)
#
# Camera3D child of SpringArm3D:
#   position: (0, 0, 0)     (SpringArm handles the offset)
```

### Animation Track Configuration Details

For the walk cycle (`character/walk`, looping):
```
Track 1: Property — Skeleton3D:position.y (foot bones bob)
Track 2: Method Call — player.footstep_left_contact() at 0.0s, 0.5s
Track 3: Method Call — player.footstep_right_contact() at 0.25s, 0.75s
Duration: 1.0s, Loop: enabled
```

For the attack (`character/attack_1`):
```
Track 1: Property — RightHand rotation (sword swing arc)
Track 2: Method Call — player.attack_swing_begin() at 0.0s
Track 3: Method Call — player.attack_hit_frame() at 0.35s
Track 4: Method Call — player.attack_combo_window_open() at 0.5s
Track 5: Method Call — player.attack_combo_window_close() at 0.8s
Track 6: Method Call — player.attack_animation_complete() at 0.9s
Duration: 0.9s, Loop: disabled
```

---

## 2D Bridge: Sprite Animation and 2D State Machines

> **Context shift.** The 3D section animates skeletal rigs with Mixamo clips, root motion, and blend spaces. 2D sprite animation is fundamentally different: you're switching between frames of a sprite sheet, not interpolating bone transforms. This bridge covers the two tools Godot provides for this — `AnimatedSprite2D` and `AnimationPlayer` — and how to combine them into a full RPG character state machine.

### AnimatedSprite2D vs AnimationPlayer: The Core Decision

Two tools, different purposes, often used together:

| | `AnimatedSprite2D` | `AnimationPlayer` |
|---|---|---|
| **What it animates** | Sprite frames (the art) | Any property on any node |
| **Best for** | Walk cycles, idle loops, attack swings | Screen flash, camera shake, chest opening, sound cues |
| **Timeline** | Simple: frame index over time | Full keyframe editor with multiple tracks |
| **Triggering** | `play("walk")` from code | `play("hit_flash")` from code |
| **Signals** | `animation_finished`, `frame_changed` | `animation_finished`, method call tracks |

**Use both on the same node.** `AnimatedSprite2D` handles the frame cycling; `AnimationPlayer` handles effects layered on top (color flash, position shake, particles trigger). They run independently and don't interfere.

### Setting Up AnimatedSprite2D

1. Add an `AnimatedSprite2D` node to your player
2. In the Inspector, click **Sprite Frames** > **New SpriteFrames**
3. Click the SpriteFrames resource to open the editor at the bottom
4. Click **Add Animation** and name it `idle`
5. Click **Add frames from Sprite Sheet** — select your sprite sheet PNG
6. Set the grid size (e.g. 4 columns × 2 rows for a 4×2 sheet)
7. Select the frames for the idle animation, click **Add X Frames**
8. Set FPS (8–12 for pixel art, 24 for HD) and enable Loop

Repeat for `walk_down`, `walk_up`, `walk_side`, `attack`, `hurt`, `die`.

**Suggested sprite sheet layout for top-down RPG characters:**
```
Row 0: idle        (4 frames)
Row 1: walk_down   (6 frames)
Row 2: walk_up     (6 frames)
Row 3: walk_side   (6 frames)  ← flip horizontally for left
Row 4: attack      (5 frames)
Row 5: hurt        (3 frames)
Row 6: die         (6 frames)
```

Export from **Aseprite**: File > Export Sprite Sheet > Layout: Packed or Grid. Use consistent frame size. Check "Trim Cels" off to maintain consistent pixel position across frames.

### Direction-Based Animation from Code

Wire the movement direction to the correct animation:

```gdscript
# scripts/player.gd (extends CharacterBody2D)
extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

enum Direction { DOWN, UP, LEFT, RIGHT }
var facing: Direction = Direction.DOWN

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

    if input_dir != Vector2.ZERO:
        velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
        _update_facing(input_dir)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

    move_and_slide()
    _update_animation()

func _update_facing(input_dir: Vector2) -> void:
    if abs(input_dir.x) > abs(input_dir.y):
        facing = Direction.RIGHT if input_dir.x > 0 else Direction.LEFT
    elif input_dir.y > 0:
        facing = Direction.DOWN
    else:
        facing = Direction.UP

func _update_animation() -> void:
    var moving := velocity.length() > 10.0
    match facing:
        Direction.DOWN:
            sprite.play("walk_down" if moving else "idle")
            sprite.flip_h = false
        Direction.UP:
            sprite.play("walk_up" if moving else "idle")
            sprite.flip_h = false
        Direction.LEFT:
            sprite.play("walk_side" if moving else "idle")
            sprite.flip_h = true
        Direction.RIGHT:
            sprite.play("walk_side" if moving else "idle")
            sprite.flip_h = false
```

### AnimationPlayer for 2D Effects

`AnimationPlayer` works identically in 2D and 3D — it animates any property on any node. Here are the most useful tracks for a top-down RPG:

**Damage flash (red modulate):**
```
Animation: "hit_flash" — duration: 0.2s, no loop
Track 0: Sprite2D:modulate
  0.00s: Color(1, 1, 1, 1)        ← normal
  0.05s: Color(1, 0.2, 0.2, 1)   ← red flash
  0.15s: Color(1, 1, 1, 1)        ← back to normal
```

**Camera shake on heavy hit:**
```
Animation: "camera_shake" — duration: 0.3s, no loop
Track 0: Camera2D:offset
  0.00s: Vector2(0, 0)
  0.05s: Vector2(6, -4)
  0.10s: Vector2(-5, 3)
  0.15s: Vector2(4, -2)
  0.20s: Vector2(-3, 1)
  0.30s: Vector2(0, 0)
```

**Torch flicker (authored version of the code script):**
```
Animation: "torch_flicker" — duration: 1.0s, loop
Track 0: PointLight2D:energy  (bezier curve)
  Keyframes: 1.2, 0.9, 1.4, 1.0, 0.8, 1.3, 1.1 — irregular pattern
```

**Shader dissolve on enemy death:**
```
Animation: "dissolve_death" — duration: 0.8s, no loop
Track 0: ShaderMaterial:shader_parameter/dissolve_amount
  0.0s: 0.0
  0.8s: 1.0
```

Trigger from code:
```gdscript
@onready var anim: AnimationPlayer = $AnimationPlayer

func take_damage(amount: int) -> void:
    health -= amount
    anim.play("hit_flash")

func die() -> void:
    anim.play("dissolve_death")
    await anim.animation_finished
    queue_free()
```

### Code-Driven State Machine for 2D Characters

In 3D, `AnimationTree` is the standard way to manage character animation states — it reads animations from `AnimationPlayer` and blends between skeletal poses. In 2D with frame-based sprites, `AnimationTree` is rarely the right tool. Frame-based animation switches between discrete sprite images — there's nothing to blend between. A walk_down frame and a walk_right frame can't be interpolated like bone transforms can.

The standard 2D approach is a **code-driven state machine** that controls `AnimatedSprite2D` directly. Here's a clean version that handles the full RPG character:

```gdscript
# scripts/player.gd
extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
var health: int = 100

enum State { IDLE, WALK, ATTACK, HURT, DIE }
enum Direction { DOWN, UP, LEFT, RIGHT }
var state: State = State.IDLE
var facing: Direction = Direction.DOWN

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

    # Movement (only in idle/walk states)
    if state in [State.IDLE, State.WALK]:
        if input_dir != Vector2.ZERO:
            velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
            _update_facing(input_dir)
            state = State.WALK
        else:
            velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
            if velocity.length() < 10.0:
                state = State.IDLE
    elif state == State.ATTACK:
        velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

    move_and_slide()
    _update_animation()

func _update_facing(input_dir: Vector2) -> void:
    if abs(input_dir.x) > abs(input_dir.y):
        facing = Direction.RIGHT if input_dir.x > 0 else Direction.LEFT
    elif input_dir.y > 0:
        facing = Direction.DOWN
    else:
        facing = Direction.UP

func _update_animation() -> void:
    match state:
        State.IDLE:
            sprite.play("idle")
        State.WALK:
            match facing:
                Direction.DOWN:
                    sprite.play("walk_down")
                    sprite.flip_h = false
                Direction.UP:
                    sprite.play("walk_up")
                    sprite.flip_h = false
                Direction.LEFT:
                    sprite.play("walk_side")
                    sprite.flip_h = true
                Direction.RIGHT:
                    sprite.play("walk_side")
                    sprite.flip_h = false
        State.ATTACK:
            sprite.play("attack")
        State.HURT:
            sprite.play("hurt")
        State.DIE:
            sprite.play("die")

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack") and state in [State.IDLE, State.WALK]:
        state = State.ATTACK
        sprite.play("attack")
        await sprite.animation_finished
        state = State.IDLE

func take_damage(amount: int) -> void:
    if state == State.DIE:
        return
    health -= amount
    anim.play("hit_flash")  # AnimationPlayer handles the visual effect
    if health <= 0:
        state = State.DIE
        sprite.play("die")
        await sprite.animation_finished
        queue_free()
    else:
        state = State.HURT
        sprite.play("hurt")
        await sprite.animation_finished
        state = State.IDLE
```

This is cleaner than an AnimationTree for frame-based sprites. The `enum State` + `match` pattern gives you explicit control over which states can transition to which, and `await sprite.animation_finished` handles one-shot animations (attack, hurt, die) without timers or callback signals.

`AnimationPlayer` handles effects that layer on top — the `hit_flash` modulate track, camera shake, dissolve shader animation. `AnimatedSprite2D` handles the frame cycling. They work independently and don't interfere.

### When AnimationTree IS Useful in 2D

AnimationTree works in 2D when you use `AnimationPlayer` for all animation (including frame cycling) instead of `AnimatedSprite2D`. Create AnimationPlayer animations that keyframe `Sprite2D.frame` over time, then wire AnimationTree to that AnimationPlayer. This approach trades the simplicity of `AnimatedSprite2D.play()` for AnimationTree's state machine editor. It's more setup, but it gives you the visual state machine graph if you prefer that workflow.

Godot also has `Skeleton2D` and `Bone2D` for 2D skeletal animation — separate limbs rather than frame-swapped sprites (think Cuphead). AnimationTree with BlendSpace2D makes sense there, since bone poses can actually be interpolated. That's a different workflow from frame-based sprites and beyond what you need for a top-down RPG.

### 2D vs 3D Animation: Key Differences

**Root motion** doesn't exist in 2D sprite animation. In 3D, the animation can move the character's root bone and the `CharacterBody3D` reads that displacement. In 2D, movement is always code-driven — `velocity` in `_physics_process` controls position, the walk animation just cycles legs in place.

**No retargeting or Mixamo.** The 2D equivalent of browsing Mixamo is downloading sprite sheets from Itch.io, Kenney, or the LPC Character Generator — or drawing your own.

### Try It: Animated Walking Character

With the dungeon from Modules 3 and 4 (~30 minutes):

1. Replace the placeholder `Sprite2D` on the player with an `AnimatedSprite2D`
2. Set up SpriteFrames with idle, walk_down, walk_up, walk_side animations (use any free RPG sprite sheet)
3. Wire movement direction to animation using `_update_animation()` above
4. Walk around the dungeon — the character should animate directionally

### Try It: Combat and Effects (~45 minutes)

5. Add an `AnimationPlayer` with a `hit_flash` animation (modulate track from the section above)
6. Add the attack state and `_unhandled_input` handler — press attack, watch the animation play, then return to idle
7. Add `take_damage()` with hurt/die states and the `dissolve_death` AnimationPlayer animation + shader from Module 6's bridge on an enemy

The result: a character that animates directionally while moving, flashes red when damaged, plays attack and hurt animations with proper state transitions, and enemies that dissolve on death. The dungeon room is now a functional top-down RPG prototype.

---

## API Quick Reference

### AnimationPlayer

| Method / Property | Description |
|-------------------|-------------|
| `play(name, blend_time)` | Play animation by name, with optional blend |
| `play_backwards(name, blend_time)` | Play animation in reverse |
| `pause()` | Pause playback at current position |
| `stop()` | Stop and reset to beginning |
| `queue(name)` | Queue animation to play after current |
| `seek(seconds, update)` | Jump to a specific time |
| `is_playing()` | Whether an animation is currently playing |
| `current_animation` | Name of currently playing animation |
| `current_animation_position` | Current playback position in seconds |
| `current_animation_length` | Total length of current animation |
| `speed_scale` | Playback speed multiplier |
| `animation_finished` | Signal emitted when animation completes |
| `animation_changed` | Signal emitted when animation switches |
| `get_animation_list()` | Array of all animation names |
| `add_animation_library(name, lib)` | Add an AnimationLibrary |
| `get_animation_library(name)` | Get a library by name |

### AnimationTree

| Method / Property | Description |
|-------------------|-------------|
| `active` | Enable/disable the tree (must be true to process) |
| `anim_player` | NodePath to the AnimationPlayer |
| `tree_root` | The root AnimationNode (StateMachine, BlendSpace, etc.) |
| `set(param, value)` | Set a parameter by path string |
| `get(param)` | Get a parameter value by path string |
| `get_root_motion_position()` | Delta position from root motion this frame |
| `get_root_motion_rotation()` | Delta rotation from root motion this frame |
| `get_root_motion_position_accumulator()` | Accumulated position since last reset |
| `root_motion_track` | NodePath to the root motion bone |

### AnimationNodeStateMachinePlayback

| Method / Property | Description |
|-------------------|-------------|
| `travel(state_name)` | Transition to state, following defined transitions |
| `start(state_name)` | Instantly jump to state, ignoring transitions |
| `stop()` | Stop the state machine |
| `get_current_node()` | Name of the current active state |
| `get_travel_path()` | Array of states in the planned travel path |
| `is_playing()` | Whether the state machine is active |
| `get_current_play_position()` | Position within current animation |

### BlendSpace Parameters

```gdscript
# BlendSpace1D — float parameter
anim_tree.set("parameters/BLEND_NAME/blend_position", 0.5)

# BlendSpace2D — Vector2 parameter
anim_tree.set("parameters/BLEND_NAME/blend_position", Vector2(0.5, 0.5))

# Read current value
var current: float = anim_tree.get("parameters/BLEND_NAME/blend_position")
```

### BoneAttachment3D

| Property | Description |
|----------|-------------|
| `bone_name` | Name of the bone to attach to |
| `bone_idx` | Index of the bone (set automatically from bone_name) |
| `use_external_skeleton` | Use a Skeleton3D node not in the parent |
| `external_skeleton` | NodePath to external Skeleton3D (if above is true) |

### Skeleton3D

```gdscript
skeleton.get_bone_count()                 # Total bones
skeleton.find_bone(name)                  # Index from name (-1 if not found)
skeleton.get_bone_name(idx)               # Name from index
skeleton.get_bone_pose(idx)               # Transform3D local pose
skeleton.set_bone_pose(idx, transform)    # Set local pose (overrides animation)
skeleton.get_bone_global_pose(idx)        # Transform3D in skeleton space
skeleton.get_bone_pose_position(idx)      # Vector3 position only
skeleton.get_bone_pose_rotation(idx)      # Quaternion rotation only
skeleton.reset_bone_pose(idx)             # Reset to rest pose
skeleton.reset_bone_poses()               # Reset all bones
```

### SkeletonIK3D

| Property | Description |
|----------|-------------|
| `root_bone` | Starting bone of the IK chain |
| `tip_bone` | End effector bone (reaches for target) |
| `target` | NodePath to target Node3D |
| `target_node` | Reference to target node directly |
| `interpolation` | Blend amount (0=no IK, 1=full IK) |
| `min_distance` | Stop IK when within this distance of target |
| `use_magnet` | Use a magnet point to control chain direction |
| `magnet` | NodePath to magnet Node3D |

```gdscript
ik.start()   # Enable IK solving
ik.stop()    # Disable IK solving
```

---

## Common Pitfalls

### 1. AnimationTree Active but Nothing Plays

**WRONG:**
```gdscript
func _ready() -> void:
    anim_tree.active = true
    state_machine.travel("idle")
    # Nothing plays — anim_player is not set
```

**RIGHT:**
```gdscript
func _ready() -> void:
    # In the Inspector, make sure AnimationTree.anim_player points to your AnimationPlayer node
    # Or set it from code:
    anim_tree.anim_player = NodePath("../AnimationPlayer")  # Adjust path as needed
    anim_tree.active = true
    state_machine.travel("idle")
    # Now it works
```

Always verify: AnimationTree Inspector → **Anim Player** field must point to the AnimationPlayer node. If it's empty, nothing will play.

### 2. start() Instead of travel() Causes Visible Pops

**WRONG:**
```gdscript
# Instant state change — character snaps from run to idle with no blend
func stop_moving() -> void:
    state_machine.start("idle")  # Hard cut, no crossfade
```

**RIGHT:**
```gdscript
# travel() uses the xfade_time configured on the transition
func stop_moving() -> void:
    state_machine.travel("idle")  # Smooth crossfade over configured xfade_time

# In the state machine editor, set xfade_time = 0.2 on the run → idle transition
# This gives a 0.2 second crossfade between animations
```

Use `start()` only for initialization or hard resets (respawn, scene load). For all gameplay transitions, use `travel()`.

### 3. Fighting Between AnimationPlayer and Code

**WRONG:**
```gdscript
func _physics_process(delta: float) -> void:
    # AnimationPlayer animates position.y for the idle bob
    # Code ALSO sets position — they fight, character stutters
    position.y = sin(Time.get_ticks_msec() * 0.001) * 0.1

func _ready() -> void:
    anim_player.play("idle")  # Also animates position.y
```

**RIGHT:**
```gdscript
# Let AnimationPlayer OWN the animated property
# Don't touch position.y from code when AnimationPlayer is animating it
# Use a Method Call track if code needs to react to animation state

# Alternative: animate a CHILD node's position, not the root
# Character root position is controlled by CharacterBody3D physics
# A child "Mesh" node can have its position animated for idle bob
```

If AnimationPlayer and code both write to the same property, the animation loses or the code loses, or they alternate. Pick one owner per property.

### 4. Root Motion Character Sliding

**WRONG:**
```gdscript
# Root motion enabled, but blend space speed doesn't match animation speed
func _physics_process(delta: float) -> void:
    var root_pos := anim_tree.get_root_motion_position()
    velocity.x = root_pos.x / delta  # Velocity from animation
    velocity.z = root_pos.z / delta

# Character slides because the animation walk speed is 2 m/s
# but the code expects it to be 7 m/s
```

**RIGHT:**
```gdscript
# Option 1: Use animation speed scale to match code speed
func _update_animation_speed() -> void:
    var target_speed := Vector2(velocity.x, velocity.z).length()
    # Walk animation is authored at 2.5 m/s
    anim_tree.set("parameters/walk/TimeScale/scale", target_speed / 2.5)

# Option 2: Don't fight it — let root motion dictate speed
# Remove manual velocity setting, let animation drive movement entirely
# This means your animation's speed IS your character's speed
```

### 5. travel() Every Frame Resets Transitions

**WRONG:**
```gdscript
func _physics_process(delta: float) -> void:
    # Called every frame — resets the crossfade timer every frame
    # Character can never finish a transition
    state_machine.travel("idle")
```

**RIGHT:**
```gdscript
func _physics_process(delta: float) -> void:
    var desired_state := _get_desired_state()
    # Only travel if the state actually needs to change
    if state_machine.get_current_node() != desired_state:
        state_machine.travel(desired_state)

func _get_desired_state() -> String:
    if not is_on_floor():
        return "fall" if velocity.y <= 0 else "jump"
    if Vector2(velocity.x, velocity.z).length() < 0.5:
        return "idle"
    return "walk"
```

`travel()` is not idempotent — calling it repeatedly with the same state while a transition is in progress keeps restarting the transition. Guard it with a state check.

---

## Exercises

### Exercise 1: Treasure Chest (30–45 min)

Build an animated treasure chest that opens when the player enters an area.

**Requirements:**
- `AnimationPlayer` with a `chest_open` animation containing:
  - Lid rotation: animate `HingeMesh:rotation_degrees:y` from 0 to -110 degrees over 0.8 seconds with cubic easing
  - Creak sound: Audio track at 0.0s
  - Particles: Method Call track at 0.4s that calls `spawn_treasure_particles()`
  - Light intensity: `PointLight3D:light_energy` from 0 to 2.0 over 1.0 second (treasure glows)
- `Area3D` trigger that plays the animation when the player enters (once only)
- `await anim.animation_finished` before marking chest as looted

**Stretch goals:**
- Add a `chest_idle` animation (looping): the light pulses gently using a Bezier track
- Add an item pickup Tween that makes the reward float up and scale to 0

### Exercise 2: Attack Combo System (60–90 min)

Build a 3-hit melee combo using Method Call tracks for precise timing.

**Requirements:**
- Three attack animations: `attack_1`, `attack_2`, `attack_3`
- Method Call tracks in each animation:
  - `attack_swing_sound()` at start
  - `apply_damage()` at the hit frame (different for each animation)
  - `open_combo_window()` partway through (the window to continue combo)
  - `close_combo_window()` when window closes
  - `attack_complete()` at animation end
- Pressing attack during the combo window chains to the next attack
- Not pressing during the window resets to `attack_1`
- Visual feedback: apply a brief hit flash to enemies using a Tween

**Stretch goals:**
- Heavy attack (hold button) skips to `attack_3` with extra damage
- Each attack in the combo has a different sound effect and particle burst

### Exercise 3: Cutscene System (90–120 min)

Build a reusable cutscene that plays when the player enters a boss room.

**Requirements:**
- `AnimationPlayer` with a `boss_intro` animation (10 seconds):
  - Camera: animate `CutsceneCamera:position` and `CutsceneCamera:rotation_degrees` along a preset path (3–4 keyframes)
  - Boss entrance: animate boss `position` and `rotation_degrees`
  - Music: Method Call track at 0.0s calls `change_music("boss_theme")`
  - Dialogue: Method Call tracks at 2.0s, 5.0s, 8.0s call `show_dialogue_line(text)` with string arguments
  - Environment: animate `DirectionalLight3D:light_color` from white to red over 3 seconds
- Skippable with Escape/Start button — pressing it calls `anim.seek(anim.current_animation_length, true)` and immediately fires any remaining callbacks
- After cutscene, `await anim.animation_finished` → restore player camera → begin boss fight

**Stretch goals:**
- Letterbox bars: animate two `ColorRect` nodes sliding in from top and bottom at cutscene start, sliding back out at end
- Timeline marker system: `anim_player.animation_finished` isn't the only signal — add a custom signal that fires at arbitrary named moments via Method Call tracks

---

## Key Takeaways

1. **AnimationPlayer keyframes ANY property on ANY node** — not just character transforms. Colors, shader uniforms, visibility, audio volume, script variables. If it's in the Inspector, it can be animated.

2. **Method Call tracks trigger GDScript functions at specific frames** — this is essential for footstep sounds, damage application at the right swing frame, VFX spawning at impact, combo window management. Don't poll for animation state in `_process`; react to it via callbacks.

3. **AnimationTree + AnimationNodeStateMachine = character animation state machine**. AnimationPlayer holds animations; AnimationTree blends and transitions between them. Always use `travel()` for smooth transitions — it respects crossfade time. Reserve `start()` for initialization and hard resets.

4. **BlendSpace1D blends animations by a single float** (like movement speed). **BlendSpace2D blends by a Vector2** (like movement direction). Set `blend_position` from code every frame based on character velocity, not just when the character starts/stops moving.

5. **Root motion lets animations drive movement** — the animation bakes the character's path and velocity. Great for realistic third-person characters where foot slip is noticeable. Avoid it for arcade platformers or anything requiring immediate, snappy input response.

6. **BoneAttachment3D attaches objects to skeleton bones** — weapons in hands, hats on heads, shields on arms, VFX at the tip of a staff. Pre-place them in the scene tree or instantiate them from code. Set `bone_name` to match the exact bone name in the skeleton.

7. **Tween for simple procedural animations, AnimationPlayer for complex authored animations.** They complement each other perfectly. Use Tweens for damage reactions, item pickups, UI feedback, and anything driven by runtime values. Use AnimationPlayer for artist-authored character animations, cutscenes, environmental effects with precise timing.

---

## What's Next

**[Module 11: UI & Menus](module-11-ui-menus.md)**

Your characters are alive. Now let's build the interface around them. Module 11 covers Godot's Control node system, anchors and margins for responsive UI, the theme system for consistent styling, building menus that actually feel good to navigate, and a production-grade HUD that updates reactively via signals. You'll also implement settings screens, pause menus, and loading screens — the infrastructure every game needs but few tutorials cover properly.

---

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
