# Module 9: Audio & Game Feel

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 5: Signals, Resources & Game Architecture](module-05-signals-resources-architecture.md) (Modules 6–8 recommended but not required)

---

## Overview

A game with no sound and no screen shake feels dead. Audio and "juice" — screen shake, hit stop, tweens, particle bursts — are what transform correct gameplay into satisfying gameplay. This module covers both: Godot's audio system (streams, buses, spatial audio) and game feel techniques (camera shake, freeze frames, tweened feedback).

Godot's audio system is bus-based: sounds play through buses (Master, SFX, Music), and each bus can have effects (reverb, compression, EQ, delay). AudioStreamPlayer3D gives you spatial audio that pans and attenuates based on distance — a howling enemy sounds louder as you approach, quieter as you flee. The Tween system handles smooth interpolation for any property — scale bounces, color flashes, UI slides — without AnimationPlayer overhead. Tweens are ephemeral and light; spin one up, forget about it.

By the end of this module, you'll take a basic physics playground (or build a simple breakout/shooting gallery) and layer on spatial audio, camera shake, hit stop, particle bursts, and tweened animations until it feels genuinely satisfying to interact with. You'll also build three reusable systems — a CameraShake script, an AudioManager autoload, and a JuiceFX toolkit — that you can drop into any future project.

---

## 1. AudioStreamPlayer: Playing Sounds

Godot has three audio player node types. Which one you use depends on whether positional audio matters.

### The Three Player Types

| Node | Space | Use Cases |
|---|---|---|
| `AudioStreamPlayer` | Non-positional | UI sounds, background music, narrator voice, global SFX |
| `AudioStreamPlayer2D` | 2D positional | Footsteps in a platformer, ambient birds in a 2D world |
| `AudioStreamPlayer3D` | 3D positional (spatial) | Anything in a 3D scene with distance attenuation |

For most menus and global game sounds, `AudioStreamPlayer` is what you want. No position math, no panning — just play the stream.

### Basic Playback

```gdscript
@onready var sfx: AudioStreamPlayer = $SFX

func play_sound(stream: AudioStream) -> void:
    sfx.stream = stream
    sfx.play()
```

Or with a preloaded constant:

```gdscript
const HIT_SOUND: AudioStream = preload("res://audio/sfx/hit.ogg")

func on_hit() -> void:
    $SFX.stream = HIT_SOUND
    $SFX.play()
```

### Stream Types

Godot supports three audio file formats out of the box:

**AudioStreamOggVorbis (.ogg)** — Compressed, small file size. Ideal for music and long ambient tracks. Has a tiny decode overhead, which is negligible for long files but wasteful for short one-shot SFX. Enable looping in the Import dock by checking "Loop."

**AudioStreamWAV (.wav)** — Uncompressed PCM. Zero decode overhead. Use for short SFX where latency matters: gunshots, UI clicks, footsteps. File sizes are larger, but for sounds under a second the difference is trivial. Also supports looping via the Import dock.

**AudioStreamMP3 (.mp3)** — Compressed like OGG but with worse quality at the same bitrate. Avoid unless you're porting assets from a source that only has MP3. Use OGG instead.

**Rule of thumb:** Short SFX = WAV. Long music/ambient = OGG. Never MP3.

### Import Settings

Select an audio file in the FileSystem dock and open the Import tab. Key settings:

- **Loop:** Enable for music or looping ambient sounds. Leave off for one-shot SFX.
- **Loop Offset:** Where in the file the loop restarts. Useful when a music track has a non-looping intro.
- **Compression Mode:** For WAV files, choose between PCM (no compression) or IMA ADPCM (4:1 compression, slightly lower quality). For most SFX, PCM is fine.

### Useful Properties

```gdscript
var player := AudioStreamPlayer.new()
player.stream = preload("res://audio/sfx/pickup.wav")
player.volume_db = -6.0         # Decibels: 0 = full volume, -6 ≈ half amplitude
player.pitch_scale = 1.0        # 1.0 = normal, 2.0 = one octave up
player.bus = "SFX"              # Route to the SFX audio bus
player.autoplay = false         # Don't start on scene load
add_child(player)
player.play()
```

Volume in decibels (dB) is logarithmic. Some reference points:
- `0 dB` = 100% amplitude (full volume)
- `-6 dB` ≈ 50% amplitude
- `-20 dB` ≈ 10% amplitude (quiet)
- `-80 dB` ≈ silence (Godot's effective silence floor)

The `finished` signal fires when a non-looping stream completes — useful for chaining sounds or cleaning up a pooled player:

```gdscript
player.finished.connect(player.queue_free)
```

---

## 2. AudioStreamPlayer3D: Spatial Audio

When a sound lives inside your 3D world — an enemy growling, an engine humming, a waterfall rushing — you want it to come from a position in space. AudioStreamPlayer3D does this: it pans the sound based on direction to the listener and attenuates (reduces volume) based on distance.

### Setup

Attach an `AudioStreamPlayer3D` node to the emitting object. It automatically uses its parent's world position as the sound origin.

```gdscript
# In the emitting object's script:
@onready var audio_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
    audio_3d.stream = preload("res://audio/sfx/engine_loop.ogg")
    audio_3d.max_distance = 30.0
    audio_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    audio_3d.unit_size = 5.0
    audio_3d.bus = "SFX"
    audio_3d.play()
```

Or create it in code and add it to an object:

```gdscript
var audio_3d := AudioStreamPlayer3D.new()
audio_3d.stream = preload("res://audio/sfx/engine_loop.ogg")
audio_3d.max_distance = 30.0
audio_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
audio_3d.unit_size = 5.0
add_child(audio_3d)
audio_3d.play()
```

### Key Properties

**`max_distance`** — Beyond this distance (in world units), the sound is inaudible. Default is 2000; set it to something sensible for your scene scale, e.g. `30.0` for a small room, `500.0` for an open world.

**`unit_size`** — The reference distance at which the sound is at full volume. Think of it as "how close do I need to stand to hear this at 100%?" A small `unit_size` means the sound drops off quickly; a large `unit_size` means it stays loud over distance.

**`attenuation_model`** — How volume falls off with distance:

| Model | Formula | Feel |
|---|---|---|
| `ATTENUATION_INVERSE_DISTANCE` | volume ∝ 1/d | Natural, physically plausible |
| `ATTENUATION_INVERSE_SQUARE_DISTANCE` | volume ∝ 1/d² | Faster drop-off, more dramatic |
| `ATTENUATION_LOGARITHMIC` | volume ∝ log(d) | Gentle drop-off, sounds carry far |
| `ATTENUATION_DISABLED` | No attenuation | Constant volume regardless of distance |

For most games, `ATTENUATION_INVERSE_DISTANCE` is the right default.

**`emission_angle_degrees`** and **`emission_angle_filter_attenuation_db`** — Directional emission. Useful for a speaker facing one direction: sounds coming from behind the speaker are quieter.

**`doppler_tracking`** — Enable Doppler effect for moving sources (sirens, racing cars). Options: disabled, idle, physics. Use `DOPPLER_TRACKING_PHYSICS_STEP` for physics-driven movers.

**`area_mask`** — Bitmask for AudioArea3D nodes. Use audio areas to add reverb zones (inside a cave, inside a building) without applying it globally.

### The Audio Listener

By default, the active `Camera3D` acts as the audio listener — it's where "ears" are. If you want audio to follow a different node (e.g., a first-person character's head), add an `AudioListener3D` node to that node and call `make_current()`:

```gdscript
# On the character's head node:
@onready var listener: AudioListener3D = $AudioListener3D

func _ready() -> void:
    listener.make_current()
```

---

## 3. Audio Bus Layout

The Audio Bus Layout is where Godot's audio signal chain lives. Open it from the **Audio** tab at the bottom of the editor (next to Animation, Debugger, etc.).

### Default Setup

Every project starts with a single Master bus. You should add at minimum:

```
Master (output to speakers)
├── SFX      → Master
├── Music    → Master
└── Ambient  → Master
```

To add a bus: click **Add Bus** in the Audio panel. Set the **Send** dropdown to route it to Master (or another bus for effects chaining).

Why separate buses?
- Players can independently control SFX volume, music volume, ambient volume in settings
- You can mute all SFX during cutscenes without stopping music
- You can add reverb to Ambient without affecting SFX
- Individual buses can be soloed for debugging

### Bus Effects

Click the **+** icon on a bus to add effects. Common ones:

| Effect | Use |
|---|---|
| `AudioEffectReverb` | Cave echo, large rooms, outdoor openness |
| `AudioEffectDelay` | Echo/repeat, old radio effect |
| `AudioEffectCompressor` | Even out volume dynamics, sidechain ducking |
| `AudioEffectLimiter` | Prevent clipping, always on Master |
| `AudioEffectEQ` | Boost/cut frequency bands |
| `AudioEffectChorus` | Thick, wide sound for ambient/music |
| `AudioEffectDistortion` | Guitar crunch, lo-fi effect |
| `AudioEffectLowPassFilter` | Muffle (underwater, muffled explosion) |
| `AudioEffectHighPassFilter` | Remove bass (phone voice, radio) |

Always put an `AudioEffectLimiter` on the Master bus to prevent clipping.

### Controlling Buses from Code

```gdscript
# Get bus index by name (case sensitive)
var sfx_bus_idx := AudioServer.get_bus_index("SFX")
var music_bus_idx := AudioServer.get_bus_index("Music")

# Volume in decibels
AudioServer.set_bus_volume_db(sfx_bus_idx, -6.0)

# Read current volume
var current_vol: float = AudioServer.get_bus_volume_db(sfx_bus_idx)

# Mute/unmute
AudioServer.set_bus_mute(music_bus_idx, true)
AudioServer.set_bus_mute(music_bus_idx, false)

# Solo (for debugging — hear only this bus)
AudioServer.set_bus_solo(sfx_bus_idx, true)

# Bypass all effects on a bus
AudioServer.set_bus_bypass_effects(sfx_bus_idx, true)

# Add a reverb effect to a bus in code
var reverb := AudioEffectReverb.new()
reverb.room_size = 0.8
reverb.wet = 0.3
AudioServer.add_bus_effect(sfx_bus_idx, reverb)
```

### Assigning Sounds to Buses

Every AudioStreamPlayer has a `bus` property. Set it in the Inspector or in code:

```gdscript
$GunShot.bus = "SFX"
$BackgroundMusic.bus = "Music"
$AmbientWind.bus = "Ambient"
```

### Basic AudioManager Autoload

Create a script `res://autoloads/audio_manager.gd` and register it as an autoload in **Project > Project Settings > Autoload**:

```gdscript
# audio_manager.gd
extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var sfx_bus_idx: int
var music_bus_idx: int

func _ready() -> void:
    sfx_bus_idx = AudioServer.get_bus_index("SFX")
    music_bus_idx = AudioServer.get_bus_index("Music")

func set_sfx_volume(linear: float) -> void:
    # linear 0.0-1.0 → decibels
    AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(linear))

func set_music_volume(linear: float) -> void:
    AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(linear))

func play_music(stream: AudioStream) -> void:
    music_player.stream = stream
    music_player.play()

func play_sfx(stream: AudioStream) -> void:
    sfx_player.stream = stream
    sfx_player.play()

func crossfade_to(new_track: AudioStream, duration: float = 1.0) -> void:
    var tween := create_tween()
    tween.tween_property(music_player, "volume_db", -80.0, duration)
    await tween.finished
    music_player.stream = new_track
    music_player.play()
    var fade_in := create_tween()
    fade_in.tween_property(music_player, "volume_db", 0.0, duration)
```

Note: `linear_to_db()` is a built-in Godot function. Use it when converting slider values (0.0–1.0) to decibels for bus volume. The inverse is `db_to_linear()`.

---

## 4. AudioStreamRandomizer

Repetitive sounds are one of the fastest ways to make a game feel cheap. A footstep that plays the exact same "thump" a hundred times in a row breaks immersion. `AudioStreamRandomizer` solves this.

### What It Does

`AudioStreamRandomizer` is a special `AudioStream` that holds a list of streams. Each time it's played, it picks one at random (or shuffles through them without repeats). It also applies random pitch and volume variation.

### Setup

```gdscript
var randomizer := AudioStreamRandomizer.new()

# Add streams with a weight (higher weight = played more often)
randomizer.add_stream(0, preload("res://audio/sfx/footstep_01.ogg"))
randomizer.add_stream(1, preload("res://audio/sfx/footstep_02.ogg"))
randomizer.add_stream(2, preload("res://audio/sfx/footstep_03.ogg"))
randomizer.add_stream(3, preload("res://audio/sfx/footstep_04.ogg"))

# Pitch variation: ±10% (value of 1.1 means range is 1/1.1 to 1.1)
randomizer.random_pitch = 1.1

# Volume variation: ±2dB
randomizer.random_volume_offset_db = 2.0

# Playback mode
randomizer.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS

var footstep_player := AudioStreamPlayer.new()
footstep_player.stream = randomizer
footstep_player.bus = "SFX"
add_child(footstep_player)
```

Playback modes:
- `PLAYBACK_RANDOM_NO_REPEATS` — Random, but won't play the same one twice in a row. Best for footsteps.
- `PLAYBACK_RANDOM` — Fully random (can repeat).
- `PLAYBACK_SEQUENTIAL` — Cycles through in order.

### Why This Matters

The human ear is remarkably good at detecting repetition. Identical SFX played back-to-back register as obviously mechanical. With `AudioStreamRandomizer`:

1. Different clips give natural variety in timbre
2. Random pitch variation (±5-15%) makes each hit feel unique
3. Random volume variation (±2-3dB) adds organic feel

The rule: if a sound plays more than twice per minute, put it in a randomizer with at least 3-4 variants and add pitch variation. This applies to: footsteps, weapon sounds, hit sounds, destruction, pickups, UI button clicks.

### Creating an AudioStreamRandomizer as a Resource

Save it as a `.tres` file to reuse across scenes:

```gdscript
# Save randomizer to disk (run this once in a tool script or editor plugin)
var randomizer := AudioStreamRandomizer.new()
randomizer.add_stream(0, preload("res://audio/sfx/hit_01.ogg"))
randomizer.add_stream(1, preload("res://audio/sfx/hit_02.ogg"))
randomizer.add_stream(2, preload("res://audio/sfx/hit_03.ogg"))
randomizer.random_pitch = 1.15
ResourceSaver.save(randomizer, "res://audio/sfx/hit_randomizer.tres")

# Then load it anywhere:
var hit_randomizer: AudioStreamRandomizer = preload("res://audio/sfx/hit_randomizer.tres")
$HitSFX.stream = hit_randomizer
```

---

## 5. Camera Shake

Camera shake communicates physical impact to the player viscerally. A bullet graze barely registers; a rocket blast shakes everything. The key is making shake feel organic, not jittery.

### The Trauma Model

The best camera shake uses a "trauma" value between 0 and 1. Sources add trauma; trauma decays over time. The actual shake intensity is `trauma²` — this makes weak shakes barely noticeable while strong shakes are dramatic, with a smooth curve between them.

```
Impact → add_trauma(0.4) → trauma = 0.4
Frame 0: shake = 0.4² = 0.16  (medium)
Frame 1: trauma = 0.4 - decay*delta → shake falls off smoothly
...
Frame N: trauma = 0.0 → no shake
```

Stacking works naturally: two hits in quick succession push trauma up to 0.7 or 0.8, creating a harder shake. Once combat stops, it decays to calm.

### Why Noise Instead of randf()

Pure `randf()` creates jittery, nauseating shake. Each frame the offset is a completely different random number — there's no temporal coherence. Noise (Perlin/Simplex via `FastNoiseLite`) generates values that flow smoothly from one to the next. The camera moves in a fluid, believable path rather than vibrating randomly.

### CameraShake Script

Attach this to your `Camera3D`. Assign a `FastNoiseLite` resource in the Inspector.

```gdscript
# camera_shake.gd
class_name CameraShake
extends Camera3D

## Maximum horizontal and vertical offset in world units
@export var max_offset: Vector2 = Vector2(0.5, 0.4)

## Maximum roll rotation in radians
@export var max_rotation: float = 0.05

## How fast trauma decays per second (1.5 = fully gone in ~0.67s)
@export var decay_rate: float = 1.5

## FastNoiseLite resource — set frequency to ~1.0, type to Simplex Smooth
@export var noise: FastNoiseLite

var trauma: float = 0.0
var noise_y: float = 0.0


func add_trauma(amount: float) -> void:
    trauma = minf(trauma + amount, 1.0)


func _process(delta: float) -> void:
    if trauma <= 0.0:
        # Reset offsets when not shaking
        h_offset = 0.0
        v_offset = 0.0
        rotation.z = 0.0
        return

    noise_y += delta * 50.0  # Advance through noise field over time
    var shake := trauma * trauma  # Quadratic curve — snappier feel

    h_offset = max_offset.x * shake * noise.get_noise_2d(0.0, noise_y)
    v_offset = max_offset.y * shake * noise.get_noise_2d(100.0, noise_y)
    rotation.z = max_rotation * shake * noise.get_noise_2d(200.0, noise_y)

    trauma = maxf(trauma - decay_rate * delta, 0.0)
```

**FastNoiseLite setup:** In the Inspector for the noise resource, set:
- `Noise Type` = Simplex Smooth (smoothest result)
- `Frequency` = 0.5–1.0 (higher = faster oscillation, feels more frantic)
- `Fractal Type` = None (FBm adds complexity but it's unnecessary here)

### Triggering Shake

```gdscript
# From anywhere that has a reference to the camera:
@onready var camera: CameraShake = $Camera3D  # or get_viewport().get_camera_3d()

# Small hit
camera.add_trauma(0.2)

# Medium explosion
camera.add_trauma(0.5)

# Massive impact
camera.add_trauma(0.8)
```

Trauma values as a guide:
- `0.1–0.2` — Minor hit, surface contact
- `0.3–0.4` — Bullet hit, fall from height
- `0.5–0.6` — Explosion nearby
- `0.7–0.9` — Direct rocket hit, earthquake
- `1.0` — Maximum possible shake (reserved for dramatic moments)

### Getting a Reference to the Camera

If your camera is deep in the scene tree, use a global reference via an autoload or a group:

```gdscript
# In any script that needs to shake:
func get_camera() -> CameraShake:
    return get_viewport().get_camera_3d() as CameraShake

# Then:
get_camera().add_trauma(0.4)
```

Or add the camera to a group called `"main_camera"` and find it:

```gdscript
func get_camera() -> CameraShake:
    return get_tree().get_first_node_in_group("main_camera") as CameraShake
```

---

## 6. Hit Stop / Freeze Frames

Hit stop is a technique borrowed from fighting games. On a significant impact, the game freezes for 30–200ms. During this tiny pause, the player's brain processes that something important happened. It makes hits feel weighty and satisfying.

### Implementation

```gdscript
func hit_stop(duration: float = 0.05) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
```

The `create_timer` signature is: `create_timer(time, process_always, process_in_physics, ignore_time_scale)`.

The critical parameter is `ignore_time_scale = true` (4th argument). Without it, `Engine.time_scale = 0.0` stops the timer too — the game freezes permanently. With `ignore_time_scale = true`, the timer runs on wall-clock time and fires after `duration` real seconds.

### Duration Guide

| Impact Type | Duration | Effect |
|---|---|---|
| Weak hit, UI confirm | 0.0s | No hit stop needed |
| Light hit, pickup | 16–33ms (1-2 frames) | Barely perceptible, but feels right |
| Normal hit, enemy death | 50–80ms (3-5 frames) | Satisfying thump |
| Heavy attack, boss hit | 100–150ms (6-9 frames) | Dramatic weight |
| Ultimate, giant explosion | 150–250ms (9-15 frames) | Cinematic |

At 60 fps, one frame is ~16.67ms. Think in frames when tuning: "this should freeze for 4 frames."

### Slow Motion Instead of Full Stop

For dramatic moments, slow time instead of stopping it:

```gdscript
func slow_motion(factor: float = 0.2, duration: float = 0.5) -> void:
    Engine.time_scale = factor
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
```

With `factor = 0.2`, the game runs at 20% speed. Combined with slow-motion music pitch shifting, this creates bullet-time.

### Pitch-Shifting Music During Slow Motion

```gdscript
func slow_motion_with_audio(factor: float = 0.2, duration: float = 0.5) -> void:
    Engine.time_scale = factor

    # Pitch shift music to match slow motion
    var music_bus_idx := AudioServer.get_bus_index("Music")
    # Find and adjust pitch shift effect on Music bus
    # (assumes an AudioEffectPitchShift was added to the Music bus)
    var effect := AudioServer.get_bus_effect(music_bus_idx, 0) as AudioEffectPitchShift
    if effect:
        effect.pitch_scale = factor

    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
    if effect:
        effect.pitch_scale = 1.0
```

### Hit Stop with Particles and Shake

Hit stop works best when combined with other effects. The sequence:

```gdscript
func big_impact(position: Vector3) -> void:
    camera.add_trauma(0.6)           # Shake starts
    hit_stop(0.08)                   # Freeze for 80ms
    spawn_particles(position)        # Particles burst (they're paused too)
    play_impact_sound()              # Sound plays
```

Note: particles and physics also freeze during hit stop because `Engine.time_scale` affects all physics and `_process` callbacks. Sounds are not affected by time_scale — audio runs on its own clock.

---

## 7. Tweens: Smooth Transitions for Everything

Godot's Tween system lets you animate any property smoothly over time with a single call. No AnimationPlayer, no keyframes, no separate animation files — just code.

### Creating a Tween

```gdscript
var tween := create_tween()
tween.tween_property(node, "property_path", target_value, duration)
```

Tweens created with `create_tween()` are tied to the node that creates them. If the node is freed, the tween stops automatically.

### Core Methods

```gdscript
var tween := create_tween()

# Animate a property from current value to target over duration (in seconds)
tween.tween_property(node, "position", Vector2(100, 200), 0.5)

# Animate with explicit starting value
tween.tween_property(node, "scale", Vector3.ONE * 1.5, 0.2).from(Vector3.ONE)

# Call a method after previous step completes
tween.tween_callback(some_node.queue_free)

# Wait before next step
tween.tween_interval(0.3)

# Run multiple steps in parallel (instead of sequence)
tween.set_parallel(true)
tween.tween_property(node, "position", target_pos, 0.5)
tween.tween_property(node, "modulate:a", 0.0, 0.5)   # Fade out simultaneously
tween.set_parallel(false)  # Resume sequential
```

### Easing and Transition Types

Every `tween_property` call can have easing and transition type set:

```gdscript
tween.tween_property(node, "scale", Vector3.ONE * 1.3, 0.1) \
    .set_ease(Tween.EASE_OUT) \
    .set_trans(Tween.TRANS_BACK)
```

**Ease types:**
- `EASE_IN` — Starts slow, accelerates
- `EASE_OUT` — Starts fast, decelerates (most natural for UI)
- `EASE_IN_OUT` — S-curve, slow-fast-slow
- `EASE_OUT_IN` — Fast-slow-fast (unusual, rarely used)

**Transition types (the curve shape):**

| Trans | Feel | Good For |
|---|---|---|
| `TRANS_LINEAR` | Constant speed | Progress bars, technical movement |
| `TRANS_SINE` | Gentle curve | Smooth UI fades |
| `TRANS_QUAD` | Moderate acceleration | General UI movement |
| `TRANS_CUBIC` | Stronger curve | Camera moves |
| `TRANS_QUART` / `TRANS_QUINT` | Aggressive acceleration | Fast UI popins |
| `TRANS_EXPO` | Extreme acceleration | Dramatic entrances |
| `TRANS_ELASTIC` | Overshoots, springs back | Playful UI, cartoony scale effects |
| `TRANS_BOUNCE` | Bounces at destination | Ball landing, health bar updates |
| `TRANS_BACK` | Overshoots slightly | Button press, item pickup confirmation |
| `TRANS_SPRING` | Spring-like oscillation | Responsive UI |

### Common Juice Tweens

**Scale punch (hit feedback):**
```gdscript
func punch_scale(node: Node3D, intensity: float = 1.3) -> void:
    var tween := create_tween()
    tween.tween_property(node, "scale", Vector3.ONE * intensity, 0.08) \
        .set_ease(Tween.EASE_OUT) \
        .set_trans(Tween.TRANS_QUAD)
    tween.tween_property(node, "scale", Vector3.ONE, 0.25) \
        .set_ease(Tween.EASE_OUT) \
        .set_trans(Tween.TRANS_ELASTIC)
```

**Color flash (damage feedback):**
```gdscript
func flash_color(mesh: MeshInstance3D, flash_color: Color = Color.RED) -> void:
    # Requires a unique material per instance (not shared)
    var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
    if not mat:
        mat = mesh.get_active_material(0).duplicate() as StandardMaterial3D
        mesh.set_surface_override_material(0, mat)

    var original_color := mat.albedo_color
    var tween := create_tween()
    tween.tween_property(mat, "albedo_color", flash_color, 0.04)
    tween.tween_property(mat, "albedo_color", original_color, 0.15) \
        .set_ease(Tween.EASE_OUT)
```

**UI slide in:**
```gdscript
func slide_in(control: Control, from_offset: Vector2) -> void:
    var original_pos := control.position
    control.position = original_pos + from_offset
    var tween := create_tween()
    tween.tween_property(control, "position", original_pos, 0.35) \
        .set_ease(Tween.EASE_OUT) \
        .set_trans(Tween.TRANS_BACK)
```

**Floating score popup:**
```gdscript
func spawn_score_popup(world_pos: Vector3, score: int) -> void:
    var label := Label3D.new()
    label.text = "+%d" % score
    label.font_size = 64
    label.modulate = Color.YELLOW
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.global_position = world_pos + Vector3.UP * 0.5
    get_tree().current_scene.add_child(label)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "global_position", world_pos + Vector3.UP * 2.5, 0.8) \
        .set_ease(Tween.EASE_OUT) \
        .set_trans(Tween.TRANS_QUAD)
    tween.tween_property(label, "modulate:a", 0.0, 0.8) \
        .set_ease(Tween.EASE_IN)
    tween.chain().tween_callback(label.queue_free)
```

**Fade out and free a node:**
```gdscript
func fade_out_and_free(node: CanvasItem, duration: float = 0.3) -> void:
    var tween := create_tween()
    tween.tween_property(node, "modulate:a", 0.0, duration)
    tween.tween_callback(node.queue_free)
```

### Tween Looping

```gdscript
# Loop forever
tween.set_loops()

# Loop a specific number of times
tween.set_loops(3)

# Ping-pong (play forward then backward)
tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
# Combine with negative values for yoyo effect
```

### Checking if a Tween is Valid

Before killing a tween or checking its state:

```gdscript
var my_tween: Tween

func start_tween() -> void:
    # Kill previous tween if running
    if my_tween and my_tween.is_running():
        my_tween.kill()

    my_tween = create_tween()
    my_tween.tween_property(node, "scale", Vector3.ONE * 1.5, 0.3)
```

---

## 8. Layering Juice: The Impact Stack

Individual effects are subtle. The secret to satisfying game feel is layering multiple effects simultaneously on the same event. When an enemy dies, every sense is engaged at once.

### The Impact Stack

Here is a complete enemy death with full juice:

```gdscript
func kill_enemy(enemy: Enemy) -> void:
    # --- AUDIO ---
    # 1. Play death sound (randomized for variety)
    var sfx := AudioStreamPlayer3D.new()
    sfx.stream = preload("res://audio/sfx/enemy_die.tres")  # AudioStreamRandomizer
    sfx.global_position = enemy.global_position
    sfx.bus = "SFX"
    sfx.autoplay = true
    get_tree().current_scene.add_child(sfx)
    sfx.finished.connect(sfx.queue_free)

    # --- CAMERA ---
    # 2. Screen shake (proportional to enemy size)
    get_camera().add_trauma(enemy.shake_trauma)

    # --- TIME ---
    # 3. Hit stop (brief pause for weight)
    hit_stop(0.06)

    # --- PARTICLES ---
    # 4. Particle burst at death position
    var burst := impact_particles_pool.get_next()
    burst.global_position = enemy.global_position
    burst.emitting = true

    # --- VISUAL FEEDBACK ---
    # 5. Scale punch on the enemy mesh (before removing)
    punch_scale(enemy, 1.4)

    # 6. Flash white
    flash_color(enemy.mesh, Color.WHITE)

    # --- SCORE ---
    # 7. Score popup
    spawn_score_popup(enemy.global_position, enemy.score_value)

    # --- CLEANUP ---
    # 8. Wait for flash to finish, then remove
    await get_tree().create_timer(0.12).timeout
    enemy.queue_free()

    # 9. Update score
    score += enemy.score_value
    score_updated.emit(score)
```

### The Juicing Progression

The same event at different levels of "juice":

**Level 0 — No juice:**
```gdscript
func kill_enemy(enemy: Enemy) -> void:
    enemy.queue_free()
    score += 10
```
The enemy vanishes instantly. It feels like a bug.

**Level 1 — Sound only:**
```gdscript
func kill_enemy(enemy: Enemy) -> void:
    $SFX.play()
    enemy.queue_free()
    score += 10
```
You hear it happened. Better, but no visual acknowledgment.

**Level 2 — Sound + Flash:**
```gdscript
func kill_enemy(enemy: Enemy) -> void:
    $SFX.play()
    flash_color(enemy.mesh, Color.WHITE)
    await get_tree().create_timer(0.1).timeout
    enemy.queue_free()
    score += 10
```
Now you see the flash register before the enemy disappears.

**Level 3 — Full juice (sound + flash + shake + hit stop + particles + popup):**
```
[The complete version above]
```
The player knows, in their bones, that enemy is dead. It felt good.

### Philosophy: Subtlety and Coherence

Each individual effect should be subtle enough that players don't consciously notice it. If players say "wow, the screen shook" they're noticing the effect. If they say "wow, that felt satisfying" — that's the goal. The effects should reinforce the feeling without drawing attention to themselves.

Coherence: all effects should happen at the same moment and be proportional to the same intensity. A massive explosion shouldn't have a tiny shake. A weak hit shouldn't have a massive particle explosion.

---

## 9. Practical Patterns: Footstep System, Music Manager, Impact Sounds

### Footstep System

Footsteps are one of the most common repeated sounds. A good footstep system:
1. Only plays when actually moving
2. Times sounds to step cadence
3. Varies sound based on surface type
4. Uses AudioStreamRandomizer for variation

```gdscript
# footstep_system.gd
# Attach to CharacterBody3D

extends CharacterBody3D

## Time between footstep sounds (seconds)
@export var footstep_interval: float = 0.4
## Adjust timing based on speed
@export var speed_scale: bool = true
## Normal movement speed (used for interval scaling)
@export var base_speed: float = 5.0

@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer

var footstep_timer: float = 0.0

# Map surface material names to AudioStreamRandomizer resources
var surface_materials: Dictionary = {
    "grass": preload("res://audio/sfx/step_grass.tres"),
    "stone": preload("res://audio/sfx/step_stone.tres"),
    "wood": preload("res://audio/sfx/step_wood.tres"),
    "metal": preload("res://audio/sfx/step_metal.tres"),
    "sand": preload("res://audio/sfx/step_sand.tres"),
}
var default_surface: AudioStreamRandomizer = preload("res://audio/sfx/step_stone.tres")


func _physics_process(delta: float) -> void:
    var horizontal_speed := Vector2(velocity.x, velocity.z).length()

    if horizontal_speed > 0.5 and is_on_floor():
        var interval := footstep_interval
        if speed_scale and horizontal_speed > 0:
            interval = footstep_interval * (base_speed / horizontal_speed)
            interval = clampf(interval, 0.15, 0.8)  # Don't go insane

        footstep_timer -= delta
        if footstep_timer <= 0.0:
            play_footstep()
            footstep_timer = interval
    else:
        footstep_timer = 0.0  # Reset on stop so next step plays immediately


func play_footstep() -> void:
    var surface := detect_surface()
    footstep_player.stream = surface_materials.get(surface, default_surface)
    footstep_player.play()


func detect_surface() -> String:
    # Cast a short ray downward to find the floor surface
    var space := get_world_3d().direct_space_state
    var origin := global_position
    var end := global_position + Vector3.DOWN * 1.2
    var query := PhysicsRayQueryParameters3D.create(origin, end)
    var result := space.intersect_ray(query)

    if result.is_empty():
        return "stone"  # Default

    # Check for a SurfaceTag custom property on the collider
    var collider := result["collider"]
    if collider.has_meta("surface_type"):
        return collider.get_meta("surface_type")

    return "stone"  # Default fallback
```

To tag a floor with surface type: select the StaticBody3D in the Inspector, go to "Node" tab, "Groups", and add the group name. Or use a custom Node script property: `collider.set_meta("surface_type", "wood")`.

### Music Manager Autoload

```gdscript
# music_manager.gd
# Register as autoload: MusicManager
extends Node

@onready var player_a: AudioStreamPlayer = $PlayerA
@onready var player_b: AudioStreamPlayer = $PlayerB

var active_player: AudioStreamPlayer
var inactive_player: AudioStreamPlayer

func _ready() -> void:
    player_a.bus = "Music"
    player_b.bus = "Music"
    player_b.volume_db = -80.0
    active_player = player_a
    inactive_player = player_b


func play(track: AudioStream, fade_duration: float = 0.0) -> void:
    if fade_duration <= 0.0:
        active_player.stream = track
        active_player.play()
        return
    crossfade(track, fade_duration)


func crossfade(new_track: AudioStream, duration: float = 1.0) -> void:
    inactive_player.stream = new_track
    inactive_player.volume_db = -80.0
    inactive_player.play()

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(active_player, "volume_db", -80.0, duration) \
        .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(inactive_player, "volume_db", 0.0, duration) \
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

    await tween.finished
    active_player.stop()

    # Swap references
    var temp := active_player
    active_player = inactive_player
    inactive_player = temp


func stop(fade_duration: float = 0.5) -> void:
    if fade_duration <= 0.0:
        active_player.stop()
        return
    var tween := create_tween()
    tween.tween_property(active_player, "volume_db", -80.0, fade_duration)
    tween.tween_callback(active_player.stop)


func is_playing() -> bool:
    return active_player.playing
```

Usage from any script:
```gdscript
MusicManager.play(preload("res://audio/music/menu_theme.ogg"), 0.0)
MusicManager.crossfade(preload("res://audio/music/battle_theme.ogg"), 1.5)
MusicManager.stop(2.0)
```

### Impact Sounds on Physics Collisions

Play a sound when a physics object collides with something. The impact velocity determines the volume:

```gdscript
# physics_impact_sound.gd
# Attach to RigidBody3D

extends RigidBody3D

@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

## Minimum collision speed to trigger a sound (prevents tiny bumps)
@export var min_impact_velocity: float = 1.0
## Speed at which impact sound is at full volume
@export var max_impact_velocity: float = 15.0
## Cooldown between sounds (prevents rapid-fire on bouncing)
@export var sound_cooldown: float = 0.15

var _last_sound_time: float = -999.0

const IMPACT_SOUNDS: AudioStreamRandomizer = preload("res://audio/sfx/impact_randomizer.tres")


func _ready() -> void:
    audio.stream = IMPACT_SOUNDS
    audio.bus = "SFX"
    contact_monitor = true
    max_contacts_reported = 3


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    for i in state.get_contact_count():
        var impulse := state.get_contact_impulse(i)
        var impact_speed := impulse.length() / mass
        _on_impact(impact_speed)


func _on_impact(speed: float) -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if speed < min_impact_velocity:
        return
    if now - _last_sound_time < sound_cooldown:
        return

    _last_sound_time = now

    # Map impact speed to volume
    var t := clampf((speed - min_impact_velocity) / (max_impact_velocity - min_impact_velocity), 0.0, 1.0)
    audio.volume_db = lerp(-20.0, 0.0, t)
    audio.play()
```

---

## 10. Code Walkthrough: Juiced-Up Playground

This section shows a complete scene wiring that applies all the systems from this module to a simple physics sandbox.

### Scene Tree Structure

```
JuicedPlayground (Node3D)
├── World
│   ├── Ground (StaticBody3D)
│   └── SpawnPoint (Marker3D)
├── Camera3D (CameraShake script)
│   └── AudioListener3D
├── UILayer (CanvasLayer)
│   ├── ScoreLabel (Label)
│   └── VolumeControls (VBoxContainer)
│       ├── SFXSlider (HSlider)
│       └── MusicSlider (HSlider)
├── Autoloads (not in scene tree — registered in Project Settings)
│   ├── AudioManager
│   └── JuiceFX
└── ParticlePool (Node3D)
    ├── BurstFX_01 (GPUParticles3D)
    ├── BurstFX_02 (GPUParticles3D)
    └── BurstFX_03 (GPUParticles3D)
```

### The Physics Ball with Full Juice

```gdscript
# juiced_ball.gd
class_name JuicedBall
extends RigidBody3D

## Score awarded when this ball is clicked
@export var score_value: int = 10
## Trauma added to camera on hard impact
@export var impact_trauma: float = 0.3
## Hit stop duration on hard impact (seconds)
@export var hit_stop_duration: float = 0.05

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var collision: CollisionShape3D = $CollisionShape3D

const IMPACT_SFX: AudioStreamRandomizer = preload("res://audio/sfx/impact_randomizer.tres")
const CLICK_SFX: AudioStreamRandomizer = preload("res://audio/sfx/click_randomizer.tres")
const IMPACT_MIN_SPEED: float = 2.0
const IMPACT_MAX_SPEED: float = 20.0
const SOUND_COOLDOWN: float = 0.1

var _last_sound_time: float = -999.0
var _camera: CameraShake


func _ready() -> void:
    audio.stream = IMPACT_SFX
    audio.bus = "SFX"
    contact_monitor = true
    max_contacts_reported = 4
    _camera = get_viewport().get_camera_3d() as CameraShake

    # Make it clickable
    input_ray_pickable = true
    mouse_entered.connect(_on_mouse_entered)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    for i in state.get_contact_count():
        var impulse := state.get_contact_impulse(i)
        var speed := impulse.length() / maxf(mass, 0.001)
        if speed > IMPACT_MIN_SPEED:
            call_deferred("_handle_impact", speed)


func _handle_impact(speed: float) -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if now - _last_sound_time < SOUND_COOLDOWN:
        return
    _last_sound_time = now

    var t := clampf((speed - IMPACT_MIN_SPEED) / (IMPACT_MAX_SPEED - IMPACT_MIN_SPEED), 0.0, 1.0)

    # Sound
    audio.volume_db = lerp(-18.0, 0.0, t)
    audio.play()

    # Shake (proportional to impact force)
    if _camera:
        _camera.add_trauma(impact_trauma * t)

    # Hit stop on hard impacts only
    if t > 0.7:
        JuiceFX.hit_stop(hit_stop_duration)

    # Scale punch
    JuiceFX.punch_scale(self, 1.0 + 0.3 * t)


func _on_mouse_entered() -> void:
    # Click to destroy
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _explode()


func _input_event(_camera_: Camera3D, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _explode()


func _explode() -> void:
    # Full impact stack on destruction
    audio.stream = CLICK_SFX
    audio.play()

    if _camera:
        _camera.add_trauma(0.4)

    JuiceFX.hit_stop(0.07)
    JuiceFX.flash(self, Color.WHITE)
    JuiceFX.spawn_particles(global_position)
    JuiceFX.spawn_score_popup(get_tree().current_scene, global_position, score_value)

    await get_tree().create_timer(0.12).timeout
    queue_free()
```

### JuiceFX Autoload

```gdscript
# juice_fx.gd
# Register as autoload: JuiceFX
extends Node

@export var particles_scene: PackedScene = preload("res://effects/burst_particles.tscn")

var _camera: CameraShake


func _ready() -> void:
    call_deferred("_find_camera")


func _find_camera() -> void:
    _camera = get_viewport().get_camera_3d() as CameraShake


## Add trauma to the main camera (0.0–1.0)
func shake(trauma: float) -> void:
    if not _camera:
        _find_camera()
    if _camera:
        _camera.add_trauma(trauma)


## Freeze time briefly for impact weight
func hit_stop(duration: float = 0.05) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0


## Scale punch effect on a Node3D
func punch_scale(node: Node3D, peak_scale: float = 1.3) -> void:
    if not is_instance_valid(node):
        return
    var tween := create_tween()
    tween.tween_property(node, "scale", Vector3.ONE * peak_scale, 0.08) \
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(node, "scale", Vector3.ONE, 0.25) \
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


## Flash a MeshInstance3D with a color
func flash(node: Node3D, color: Color = Color.WHITE, duration: float = 0.1) -> void:
    if not is_instance_valid(node):
        return
    var mesh := node.get_node_or_null("MeshInstance3D") as MeshInstance3D
    if not mesh:
        mesh = node as MeshInstance3D
    if not mesh:
        return

    var mat := mesh.get_active_material(0)
    if not mat:
        return
    mat = mat.duplicate() as StandardMaterial3D
    mesh.set_surface_override_material(0, mat)

    var original_color := (mat as StandardMaterial3D).albedo_color
    var tween := create_tween()
    tween.tween_property(mat, "albedo_color", color, duration * 0.2)
    tween.tween_property(mat, "albedo_color", original_color, duration * 0.8) \
        .set_ease(Tween.EASE_OUT)
    tween.tween_callback(func(): mesh.set_surface_override_material(0, null))


## Spawn a particle burst at a world position
func spawn_particles(world_position: Vector3) -> void:
    if not particles_scene:
        return
    var burst: GPUParticles3D = particles_scene.instantiate()
    get_tree().current_scene.add_child(burst)
    burst.global_position = world_position
    burst.emitting = true
    burst.one_shot = true
    # Clean up after the particle lifetime
    get_tree().create_timer(burst.lifetime + 0.5).timeout.connect(burst.queue_free)


## Spawn a floating score label at a world position
func spawn_score_popup(scene_root: Node, world_position: Vector3, score: int) -> void:
    var label := Label3D.new()
    label.text = "+%d" % score
    label.font_size = 72
    label.modulate = Color.YELLOW
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.global_position = world_position + Vector3.UP * 0.3
    scene_root.add_child(label)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "global_position", world_position + Vector3.UP * 2.5, 0.9) \
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(label, "modulate:a", 0.0, 0.9) \
        .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
    tween.chain().tween_callback(label.queue_free)
```

### Volume Control UI

```gdscript
# volume_controls.gd
extends VBoxContainer

@onready var sfx_slider: HSlider = $SFXSlider
@onready var music_slider: HSlider = $MusicSlider

var sfx_bus_idx: int
var music_bus_idx: int


func _ready() -> void:
    sfx_bus_idx = AudioServer.get_bus_index("SFX")
    music_bus_idx = AudioServer.get_bus_index("Music")

    # Initialize sliders from current bus volume
    sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))
    music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))

    sfx_slider.value_changed.connect(_on_sfx_changed)
    music_slider.value_changed.connect(_on_music_changed)


func _on_sfx_changed(value: float) -> void:
    AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value))


func _on_music_changed(value: float) -> void:
    AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(value))
```

### Scene Setup Checklist

Before running the juiced playground:

1. **Audio Bus Layout** — Open the Audio tab, create SFX, Music, and Ambient buses all routed to Master. Add AudioEffectLimiter to Master.

2. **FastNoiseLite resource** — Create a new FastNoiseLite resource, set Noise Type = Simplex Smooth, Frequency = 0.8. Assign it to CameraShake's `noise` export.

3. **AudioStreamRandomizer resources** — Create `.tres` files for impact sounds (3–5 variants), click sounds (3–4 variants). Assign them as the ball's streams.

4. **Burst particles scene** — Create a GPUParticles3D with a quick burst (lifetime = 0.3, amount = 30, one_shot = true, explosive = true) and save as `res://effects/burst_particles.tscn`.

5. **Autoloads** — Register `JuiceFX` and `MusicManager` in Project > Project Settings > Autoload.

6. **CameraShake** — Add the `camera_shake.gd` script to your Camera3D. Set max_offset, max_rotation, decay_rate. Assign a FastNoiseLite.

---

## API Quick Reference

### AudioStreamPlayer / AudioStreamPlayer2D / AudioStreamPlayer3D

| Property / Method | Type | Description |
|---|---|---|
| `stream` | `AudioStream` | The audio file to play |
| `bus` | `StringName` | Target audio bus name (e.g. "SFX") |
| `volume_db` | `float` | Volume in decibels (0 = full, -80 = silence) |
| `pitch_scale` | `float` | Pitch multiplier (1.0 = normal, 2.0 = octave up) |
| `autoplay` | `bool` | Play automatically when scene loads |
| `playing` | `bool` | Read-only: is the stream currently playing? |
| `play(from_pos)` | method | Start playback, optionally from position in seconds |
| `stop()` | method | Stop playback |
| `get_playback_position()` | method | Current position in seconds |
| `finished` | signal | Emitted when non-looping stream ends |

### AudioStreamPlayer3D Additional Properties

| Property | Type | Description |
|---|---|---|
| `max_distance` | `float` | Beyond this distance, inaudible |
| `unit_size` | `float` | Distance at which sound is at reference volume |
| `attenuation_model` | `enum` | How volume falls with distance |
| `doppler_tracking` | `enum` | Enable Doppler effect for moving sources |
| `area_mask` | `int` | Bitmask for AudioArea3D reverb zones |
| `emission_angle_degrees` | `float` | Directional emission cone angle |

### AudioServer

| Method | Description |
|---|---|
| `AudioServer.get_bus_index("BusName")` | Get bus index by name |
| `AudioServer.get_bus_count()` | Total number of buses |
| `AudioServer.get_bus_name(index)` | Get name of bus at index |
| `AudioServer.set_bus_volume_db(index, db)` | Set bus volume |
| `AudioServer.get_bus_volume_db(index)` | Get current bus volume |
| `AudioServer.set_bus_mute(index, mute)` | Mute/unmute a bus |
| `AudioServer.is_bus_mute(index)` | Check if bus is muted |
| `AudioServer.set_bus_solo(index, solo)` | Solo a bus (debug) |
| `AudioServer.set_bus_bypass_effects(index, bypass)` | Bypass effects |
| `AudioServer.add_bus_effect(index, effect)` | Add an effect to a bus |
| `AudioServer.get_bus_effect(index, effect_idx)` | Get effect from bus |

### Tween

| Method | Description |
|---|---|
| `create_tween()` | Create a new tween attached to this node |
| `tween.tween_property(obj, prop, to, dur)` | Animate a property |
| `tween.tween_callback(callable)` | Call a function at this step |
| `tween.tween_interval(seconds)` | Wait before next step |
| `tween.set_ease(Tween.EASE_*)` | Set easing type |
| `tween.set_trans(Tween.TRANS_*)` | Set transition curve |
| `tween.set_parallel(bool)` | Run steps in parallel |
| `tween.chain()` | Return to sequential after parallel block |
| `tween.set_loops(count)` | Loop (0 = forever) |
| `tween.kill()` | Stop and invalidate the tween |
| `tween.is_running()` | Check if tween is active |
| `.from(value)` | Set explicit starting value for tween_property |

### Engine Time Control

| Method | Description |
|---|---|
| `Engine.time_scale` | Game speed multiplier (0.0 = frozen, 1.0 = normal) |
| `get_tree().create_timer(time, process_always, process_in_physics, ignore_time_scale)` | Timer that can ignore time_scale |

### AudioStreamRandomizer

| Method / Property | Description |
|---|---|
| `add_stream(index, stream, weight)` | Add a stream variant |
| `remove_stream(index)` | Remove a stream at index |
| `set_stream(index, stream)` | Replace a stream at index |
| `random_pitch` | Max pitch multiplier (1.0 = no variation, 1.1 = ±10%) |
| `random_volume_offset_db` | Max volume variation in dB |
| `playback_mode` | PLAYBACK_RANDOM, PLAYBACK_RANDOM_NO_REPEATS, PLAYBACK_SEQUENTIAL |

### Helper Functions

| Function | Description |
|---|---|
| `linear_to_db(linear)` | Convert 0.0–1.0 linear to decibels |
| `db_to_linear(db)` | Convert decibels to 0.0–1.0 linear |
| `is_instance_valid(obj)` | Check if an object reference is still valid |

---

## Common Pitfalls

### 1. Using `randf()` for Camera Shake

WRONG:
```gdscript
func _process(delta: float) -> void:
    if shaking:
        h_offset = randf_range(-0.5, 0.5)  # Random each frame — jittery!
        v_offset = randf_range(-0.4, 0.4)
```
This produces nauseating noise. Each frame the offset is completely unrelated to the previous frame, creating rapid vibration rather than a fluid camera motion.

RIGHT:
```gdscript
# Use FastNoiseLite for temporally coherent shake
func _process(delta: float) -> void:
    noise_y += delta * 50.0
    h_offset = max_offset.x * shake * noise.get_noise_2d(0, noise_y)
    v_offset = max_offset.y * shake * noise.get_noise_2d(100, noise_y)
```
Noise values flow smoothly — consecutive frames have related values, producing a fluid camera path.

---

### 2. Playing Audio in `_process`

WRONG:
```gdscript
func _process(delta: float) -> void:
    if velocity.length() > 0.1:
        $FootstepPlayer.play()  # Plays every frame — overlapping cacophony!
```
At 60fps this fires 60 times per second, stacking hundreds of overlapping sound instances.

RIGHT:
```gdscript
var footstep_timer: float = 0.0

func _process(delta: float) -> void:
    if velocity.length() > 0.1 and is_on_floor():
        footstep_timer -= delta
        if footstep_timer <= 0.0:
            $FootstepPlayer.play()
            footstep_timer = 0.4  # Seconds between footsteps
```
Use a timer to gate playback frequency.

---

### 3. `Engine.time_scale = 0` Without `ignore_time_scale`

WRONG:
```gdscript
func hit_stop(duration: float) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration).timeout  # This timer is frozen too!
    Engine.time_scale = 1.0  # Never reached — game is stuck
```
When `time_scale = 0`, the default `create_timer` is also frozen and never fires. The game is permanently paused.

RIGHT:
```gdscript
func hit_stop(duration: float) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout  # 4th param: ignore_time_scale
    Engine.time_scale = 1.0
```
Pass `true` as the 4th argument (`ignore_time_scale`) so the timer runs on wall-clock time.

---

### 4. Same SFX Every Time

WRONG:
```gdscript
# Single hardcoded sound for every footstep
const FOOTSTEP = preload("res://audio/sfx/step.ogg")
func play_footstep() -> void:
    $Audio.stream = FOOTSTEP
    $Audio.play()
```
Identical sound every time. Within 30 seconds players will find it grating.

RIGHT:
```gdscript
# AudioStreamRandomizer with variants + pitch variation
const FOOTSTEP_RANDOMIZER: AudioStreamRandomizer = preload("res://audio/sfx/step_randomizer.tres")
func play_footstep() -> void:
    $Audio.stream = FOOTSTEP_RANDOMIZER  # Picks random variant with pitch variation
    $Audio.play()
```
Use `AudioStreamRandomizer` with at least 3–4 variants and `random_pitch = 1.1` for any repeated SFX.

---

### 5. Tweening a Property on a Freed Node

WRONG:
```gdscript
func explode_then_free(node: Node3D) -> void:
    var tween := create_tween()
    tween.tween_property(node, "scale", Vector3.ZERO, 0.3)
    node.queue_free()  # Freed now, but tween still holds a reference → crash
    tween.tween_callback(func(): print("done"))  # May print, may crash
```
If the node is freed mid-tween, Godot may crash or emit errors when the tween tries to access the freed object.

RIGHT — Option A: Check validity in callback:
```gdscript
func explode_then_free(node: Node3D) -> void:
    var tween := create_tween()
    tween.tween_property(node, "scale", Vector3.ZERO, 0.3)
    tween.tween_callback(func():
        if is_instance_valid(node):
            node.queue_free()
    )
```
RIGHT — Option B: Let the tween finish before freeing:
```gdscript
func explode_then_free(node: Node3D) -> void:
    var tween := create_tween()
    tween.tween_property(node, "scale", Vector3.ZERO, 0.3)
    await tween.finished
    if is_instance_valid(node):
        node.queue_free()
```
Always use `is_instance_valid()` when there's any delay between creating a reference and using it.

---

## Exercises

### Exercise 1: Add Audio to the Solar System (20–30 min)

Take the solar system from Module 0 and layer on audio:

1. **Ambient music** — Add an AudioStreamPlayer to the scene root. Assign an ambient space music track (or a looping drone). Set bus to "Music." Play it in `_ready()`. Add a volume slider to the UI.

2. **Sun spatial hum** — Attach an AudioStreamPlayer3D to the Sun node. Assign a low-frequency humming loop. Set `max_distance = 80`, `unit_size = 15`, `attenuation_model = ATTENUATION_INVERSE_DISTANCE`. Play in `_ready()`. As the camera orbits closer to the sun, the hum grows louder.

3. **Click sound on planet selection** — In the planet's click handler, play a short tone. Use `AudioStreamRandomizer` with 2–3 tone variations + `random_pitch = 1.15` so each click sounds unique.

4. **Bonus:** Add a `CameraShake` script to the Camera3D. When clicking a planet, call `add_trauma(0.1)` for a tiny click response.

Goal: By the end, the solar system has a soundscape. Moving the camera feels spatially grounded.

---

### Exercise 2: The Button Masher (45–60 min)

Build a "button masher" mini-game with maximum juice:

**Setup:** A large 3D button (a cylinder or cube) sits in the center of the screen. Clicking it increments a score. There's a 10-second timer. How high can you get the score?

**Layer on the juice:**

1. **Scale pulse** — On click, `punch_scale()` with ELASTIC easing. The button squishes and bounces back.

2. **Color flash** — On click, flash to a bright color (yellow, white) and fade back.

3. **Camera shake** — `add_trauma(0.1)` on each click. After 10 rapid clicks, the trauma has accumulated to 1.0 — full shake.

4. **Randomized click sound** — AudioStreamRandomizer with 3+ short click/pop sounds + `random_pitch = 1.2`. Each click sounds slightly different.

5. **Score popup** — `spawn_score_popup()` on each click. Numbers float up and fade.

6. **Hit stop** — On every 10th click (a "combo"), trigger `hit_stop(0.06)`. It makes combos feel extra weighty.

7. **Particle burst** — Spawn a quick particle burst at the button on each click.

8. **Music** — Background music that speeds up as the score increases (adjust `pitch_scale` on the music player based on score).

Goal: By the end, clicking the button should feel genuinely addictive and satisfying. Show the before/after: the same mechanic with no juice feels like filling out a form; with juice it feels like popping bubble wrap.

---

### Exercise 3: JuiceFX Toolkit (60–90 min)

Build a complete, reusable `JuiceFX` autoload that can be dropped into any future project:

**Required API:**
```gdscript
JuiceFX.shake(trauma: float)                        # Camera shake
JuiceFX.hit_stop(duration: float = 0.05)            # Freeze frames
JuiceFX.punch_scale(node: Node3D, peak: float = 1.3)       # Scale bounce
JuiceFX.flash(node: Node3D, color: Color = Color.WHITE)     # Color flash
JuiceFX.spawn_particles(position: Vector3, preset: String = "default")  # Particle burst
JuiceFX.spawn_score_popup(scene: Node, pos: Vector3, value: int)  # Floating text
JuiceFX.fade_out(node: CanvasItem, duration: float = 0.3)   # Fade and free
JuiceFX.slide_in(control: Control, from: Vector2, duration: float = 0.35)  # UI slide
```

**Steps:**
1. Write the complete `juice_fx.gd` autoload with all functions.
2. Support particle presets: `"default"`, `"explosion"`, `"sparkle"`, `"smoke"` — each a different GPUParticles3D scene.
3. Add configuration: `JuiceFX.set_camera(camera: CameraShake)` for manual camera assignment (fallback to `get_viewport().get_camera_3d()`).
4. Add safety checks everywhere: `is_instance_valid()` before tweening, null checks on the camera.
5. Test it on a simple breakout game: the ball bouncing uses `punch_scale`, breaking blocks uses `flash` + `spawn_particles` + `spawn_score_popup` + `shake`, losing a life uses `hit_stop(0.15)` + `shake(0.8)`.

Goal: A portable, zero-dependency `juice_fx.gd` you can copy into any future Godot project and have full juice in 5 minutes.

---

## Key Takeaways

1. **Three audio players for three contexts.** `AudioStreamPlayer` for global/UI sounds, `AudioStreamPlayer2D` for positioned 2D audio, `AudioStreamPlayer3D` for spatial 3D audio with distance attenuation and panning. Choose based on whether position matters.

2. **Audio buses route sounds with effects.** Set up at minimum Master, SFX, and Music buses. Add an AudioEffectLimiter to Master. Control volumes via `AudioServer.set_bus_volume_db()`. Assign each player a `bus` property.

3. **AudioStreamRandomizer eliminates repetitive SFX.** Any sound that plays more than once per minute should use a randomizer with at least 3–4 variants and `random_pitch = 1.1`. This is the single highest-ROI audio improvement.

4. **Camera shake uses the trauma model.** Track `trauma` (0–1). Add trauma on events. Shake intensity = `trauma²` (quadratic gives more natural feel). Use `FastNoiseLite` — not `randf()` — for temporally coherent, non-jittery shake. Let trauma decay over time.

5. **Hit stop makes impacts feel weighty.** `Engine.time_scale = 0` for 50–80ms. Always pass `ignore_time_scale = true` as the 4th argument to `create_timer` when restoring time — otherwise the game freezes forever. Duration scales with impact severity.

6. **Tweens handle any smooth property transition.** `create_tween()`, then `tween_property(node, "property", to, duration)`. Chain `.set_ease()` and `.set_trans()` for curve control. `EASE_OUT` with `TRANS_BACK` or `TRANS_ELASTIC` for playful UI. Always check `is_instance_valid()` before tweening refs that might be freed.

7. **Juice is cumulative.** Sound alone feels thin. Sound plus shake feels better. Sound plus shake plus hit stop plus particles plus flash plus score popup feels genuinely satisfying. Layer effects that are each individually subtle — together they create the feeling that the game is alive and responsive. That feeling is what players call "good game feel."

---

## What's Next

**Module 10: Animation — AnimationPlayer, AnimationTree & State Machines**

Your game feels great — responsive, punchy, and alive. Now it's time to make characters move. Module 10 covers Godot's animation system from the ground up: `AnimationPlayer` for property tracks and keyframes, `AnimationTree` for blending and state machines, and how to drive animations from character state (walk, run, jump, attack). You'll build a complete character with smooth transitions between states, blend trees for run-cycle blending based on speed, and one-shot attack animations that return cleanly to idle.

[Continue to Module 10: Animation →](module-10-animation-animationtree.md)

---

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
