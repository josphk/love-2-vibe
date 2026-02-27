# Module 13: Build, Ship & What's Next

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 4–8 hours
**Prerequisites:** Any previous module — this is the capstone. Have a project you want to ship.

---

## Overview

You've built something. Now ship it. This is the module most tutorials skip — they teach you how to make a game, then leave you staring at the Export menu wondering why your build crashes, why your web version has no audio, and why your itch.io page looks like it was made in 2003. This module covers the complete pipeline from "game that runs in the editor" to "link I can send to my friends."

Shipping matters for reasons beyond the obvious. Every game you ship teaches you something no tutorial can — what players actually click, what breaks under real conditions, what you'd do differently. The feedback loop from releasing something, even something tiny, is irreplaceable. A jam game you shipped in 48 hours is worth more to your growth than a polished masterpiece that lives forever in a project folder. The Godot community has a phrase for this: done is better than perfect.

This module also covers the practical tools around shipping: the profiler, optimization strategies, GDExtension for when GDScript isn't fast enough, and a map of where to go after you've finished the wiki. By the end you'll have a signed-off export preset, a project page on itch.io, and enough knowledge to keep going on your own. The wiki ends here. Your games don't.

---

## 1. Export Templates

### What Export Templates Are

When you run your game in the editor, Godot uses the editor binary itself to execute your project. Export templates are stripped-down versions of the Godot runtime — no editor, just the engine — compiled for each target platform. You need them installed before you can export anything.

### Installing Export Templates

Go to **Editor > Manage Export Templates**. Click **Download and Install** next to the version matching your Godot install. This downloads a `.tpz` file (roughly 500MB) and installs it into your user data directory.

If you're on a slow connection or restricted network, download manually from [godotengine.org/download](https://godotengine.org/download) — there's a "Export Templates" link at the bottom of each release. Then use **Install from File** to point at the downloaded `.tpz`.

```
# On Linux/macOS, templates install here:
~/.local/share/godot/export_templates/4.x.stable/

# On Windows:
%APPDATA%\Godot\export_templates\4.x.stable\
```

### Creating Export Presets

Go to **Project > Export**. Each platform you want to target needs its own preset.

Click **Add** and pick your platform. The preset stores:
- The target platform and architecture
- Which features are enabled
- File include/exclude filters
- Platform-specific options (icons, signing, etc.)

You can have multiple presets for the same platform — for example, a "Windows Debug" and "Windows Release" preset.

### The Export Dialog Fields You Actually Need

**Export Path** — where the output file goes. Use a folder like `exports/windows/MyGame.exe`. This folder must exist before exporting.

**Resources** tab — by default Godot exports everything in `res://`. Use **Filters to export non-resource files** if you have files Godot doesn't auto-detect (custom data formats, etc.). Use **Filters to exclude** to strip development-only assets from the build.

**Features** tab — custom feature tags. These show up in `OS.has_feature("your_tag")` at runtime. Use them for platform-specific behavior:

```gdscript
# In your game code
if OS.has_feature("demo"):
    show_demo_watermark()

if OS.has_feature("web"):
    hide_graphics_settings()  # Web can't change renderer settings at runtime
```

### Encryption

If you want to protect your game data from casual extraction, enable PCK encryption. Generate a 256-bit hex key:

```bash
# Generate a random 64-character hex key
openssl rand -hex 32
```

Paste it into **Encryption > Encryption Key** in the export preset. Store this key somewhere safe — if you lose it, you can't open your own PCK.

Note: PCK encryption prevents casual snooping but is not DRM. A determined person with the right tools can still extract assets. Use it to protect creative work from casual copying, not as a security boundary.

### Debugging Exports

Add the `--verbose` flag when launching an exported game from the command line to see log output. On Windows and Linux, you can also export a **debug build** (toggle in the export dialog) which keeps print statements and the remote debugger active.

```bash
# Run exported build with console output visible
./MyGame --verbose

# Connect remote debugger to a running export
# In Godot editor: Debug > Connect to Remote

# Export from command line (useful for CI)
godot --headless --export-release "Windows Desktop" exports/windows/MyGame.exe
```

---

## 2. Web Export

### Why Web Export is Different

The HTML5 export runs your game inside a browser via WebAssembly. This is incredible for distribution — players click a link and your game runs. No download, no install. But the browser environment has restrictions the desktop doesn't, and several of them will bite you if you don't know about them.

### Setting Up the HTML Export Preset

Add an export preset for **Web**. The important settings:

**Head Include** — paste any custom `<meta>` or `<script>` tags here. Most people leave this empty.

**Export Type** — leave as "HTML5 Single File" for itch.io. This puts everything into one `.html` file plus a `.pck`.

**GDNative** — if you're using GDExtension with native libs, web export requires those libs compiled to WebAssembly. Most popular GDExtension addons don't support web. Check before you commit.

### SharedArrayBuffer: The Wall You'll Hit

Godot 4 web exports require `SharedArrayBuffer`, which requires two HTTP headers:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Without these headers, your game will fail to load with a cryptic error about `SharedArrayBuffer is not defined`.

**On itch.io:** In your project settings, find the **Embed Options** section. Check **SharedArrayBuffer support**. itch.io will add the required headers automatically. This is the only thing you need to do for itch.io.

**On your own server (nginx):**

```nginx
location /game/ {
    add_header Cross-Origin-Opener-Policy "same-origin";
    add_header Cross-Origin-Embedder-Policy "require-corp";
}
```

**On GitHub Pages:** GitHub Pages does not support these headers. You can't use raw GitHub Pages for Godot 4 web exports. Use itch.io, or a service that lets you set headers (Netlify, Cloudflare Pages with a `_headers` file).

```
# Cloudflare Pages _headers file
/game/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
```

### Audio Autoplay Restrictions

Browsers block audio until the user interacts with the page. Your game's audio will be silent until the player clicks or presses a key. Godot handles this automatically with its web audio unlock mechanism — you don't need to write any code. But you do need to be aware:

- Don't play critical audio in `_ready()` assuming it'll be heard on first load
- Your main menu music is fine — players will click something before they need to hear it
- If you have a splash screen with audio, add a "Click to Start" prompt

### Testing Locally

You cannot open the exported HTML file directly in a browser from disk (it'll fail with CORS errors). You need a local HTTP server:

```bash
# Python (built-in, easiest)
cd exports/web
python3 -m http.server 8080
# Open http://localhost:8080/index.html

# Node.js (if you have it)
npx serve exports/web

# Godot's built-in server (Project > Export, then "Export and Open")
# This is the easiest option during development
```

### itch.io Embed Settings

When you upload your web build to itch.io:
1. Set **Kind of project** to "HTML"
2. Check the box next to your `.html` file to mark it as the main file
3. Under **Embed options**, set a viewport size matching your game's window size
4. Check **SharedArrayBuffer support**
5. Check **Mobile friendly** if your game works on mobile

The **Fullscreen button** option is worth enabling — players expect it for web games.

---

## 3. Desktop Export

### Windows Export

The minimum for a Windows build: add a Windows Desktop preset, set the export path to something like `exports/windows/MyGame.exe`, and click **Export Project**.

**Setting the application icon:** Windows reads the icon from the `.exe` itself. Godot uses `rcedit` to embed it. Download `rcedit-x64.exe` from the [rcedit releases page](https://github.com/electron/rcedit/releases) and point Godot at it in **Editor Settings > Export > Windows > rcedit**.

Then in your export preset under **Application**, set:
- **Icon**: path to a `.ico` file (you can convert PNG to ICO with online tools or ImageMagick)
- **File Version / Product Version**: `1.0.0.0`
- **Company Name / Product Name**: your studio name and game name

```bash
# Convert PNG to ICO with ImageMagick
magick icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico
```

**Zip it up.** Windows users expect a zip they can extract. Put your `.exe` and any required DLLs (if you have GDExtension native libs) into a zip. Godot exports a self-contained `.exe` for most projects — no DLLs needed unless you're using native extensions.

### macOS Export

macOS export produces a `.app` bundle (a folder that looks like a file). You can zip this for distribution.

**Code signing basics:** Without code signing, macOS will show a warning that the app "cannot be opened because the developer cannot be verified." Your players need to right-click > Open the first time. This is annoying but acceptable for itch.io games.

For actual code signing, you need an Apple Developer account ($99/year). The process:
1. Create a Developer ID Application certificate in Xcode / Apple Developer portal
2. In your export preset under **Signing**, enable signing and point at your `.p12` certificate
3. For notarization (required to avoid Gatekeeper on recent macOS), you need to submit to Apple after signing

For itch.io distribution, unsigned builds work fine. Include instructions on your game page: "On macOS, right-click the app and select Open the first time you run it."

### Linux Export

Linux export produces a self-contained binary. Mark it executable and it runs.

```bash
# Set executable bit after download (users shouldn't need to do this, but some do)
chmod +x MyGame.x86_64
./MyGame.x86_64
```

For wider compatibility, export for **x86_64** (the most common desktop architecture) and also consider an **arm64** build if you want to support ARM Linux (Raspberry Pi, Apple Silicon via Rosetta, etc.).

**AppImage** — for a more polished Linux distribution, look into `appimagetool` to wrap your export into a single `.AppImage` file. AppImages are self-contained, run on any Linux distro without installation, and are the de-facto standard for distributing Linux desktop apps outside of package managers. This is an optional polish step, not required.

### One-Click Install Feel

For desktop games on itch.io, install the [itch.io app](https://itch.io/app). This lets players one-click install your game from itch.io and launch it from a library. Your exported build works automatically with this — no extra steps.

---

## 4. Profiling & Performance

### The Built-in Profiler

Open the Profiler from the bottom panel while your game is running in the editor. Hit **Start** to begin recording.

The profiler shows a flame graph of time spent per frame, broken down by:
- **Script functions** — your GDScript code
- **Physics** — PhysicsServer calls
- **Servers** — RenderingServer, AudioServer, etc.
- **Idle** — frame idle time

The most important column is **Self** time — time spent in that function excluding children. Sort by Self to find your actual bottlenecks.

A target of 16.6ms per frame = 60fps. 33.3ms = 30fps. If your frame time spikes above these, the profiler tells you where.

### The Monitors Tab

While the game is running in the editor, the **Debugger > Monitors** tab shows real-time graphs of:

- **FPS** — frames per second
- **Process time / Physics time** — ms per frame for each
- **Draw calls** — how many rendering commands per frame
- **Vertices / Primitives** — geometry count
- **Objects in frame** — visible node count
- **Physics active bodies / collision pairs**

Watch these as you play. Spikes in draw calls or physics often explain performance drops more clearly than the profiler.

### Identifying Bottlenecks

Three categories of bottlenecks:

**CPU-bound (script/physics):** Frame time is high, GPU time is fine. The profiler shows your scripts taking a long time. Solutions: cache node references, avoid per-frame allocations, move logic to servers directly, use C++ via GDExtension for hot paths.

**GPU-bound (rendering):** Frame time is fine in CPU, but the rendering server is slow. High draw calls, high poly counts, expensive shaders. Solutions: reduce draw calls via MultiMesh or batching, lower shadow cascade count, simplify shaders, use LOD.

**Memory pressure:** You're creating/freeing many objects per frame causing GC pressure. Solution: object pooling.

### Physics Performance

Physics in Godot runs at a fixed tick rate (default 60Hz). If your physics tick takes too long:
- Reduce active RigidBody3D count — static bodies are nearly free, but dynamic ones cost
- Use `CollisionShape3D` with simple shapes (sphere, box, capsule) instead of trimesh for dynamic bodies
- Trimesh colliders are only for static, non-moving geometry
- Enable **Physics Interpolation** (Project Settings > Physics > Common > Physics Interpolation) for smoother visuals at lower physics tick rates

```gdscript
# Check physics interpolation is working
func _ready() -> void:
    # This node will interpolate between physics ticks
    set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_ON)
```

---

## 5. Optimization Techniques

### Reduce Draw Calls

A "draw call" is one command to the GPU to draw a mesh. Modern games target under 1000 draw calls per frame for desktop, under 200 for mobile/web.

**Static batching:** Mark static meshes as `use_static_shadow` and bake lighting. Godot can batch static meshes in certain conditions.

**MultiMeshInstance3D:** For large numbers of identical objects (trees, rocks, bullets, particles), use `MultiMeshInstance3D` instead of individual `MeshInstance3D` nodes. This sends all instances in a single draw call.

```gdscript
# Spawning 1000 trees with MultiMesh (one draw call total)
extends MultiMeshInstance3D

func _ready() -> void:
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = preload("res://assets/tree.obj")
    multimesh.instance_count = 1000

    for i: int in 1000:
        var t := Transform3D()
        t.origin = Vector3(
            randf_range(-50.0, 50.0),
            0.0,
            randf_range(-50.0, 50.0)
        )
        multimesh.set_instance_transform(i, t)
```

### Level of Detail (LOD)

Use `VisibleOnScreenNotifier3D` to disable distant objects entirely, or use `LOD` nodes if your meshes have LOD variants. Godot 4 has built-in automatic LOD for imported meshes — enable it in the import settings.

```gdscript
# Disable AI processing for objects far from camera
extends CharacterBody3D

@onready var visibility_notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

func _ready() -> void:
    visibility_notifier.screen_exited.connect(_on_screen_exited)
    visibility_notifier.screen_entered.connect(_on_screen_entered)

func _on_screen_exited() -> void:
    set_process(false)
    set_physics_process(false)

func _on_screen_entered() -> void:
    set_process(true)
    set_physics_process(true)
```

### Occlusion Culling

Enable occlusion culling in Project Settings > Rendering > Occlusion Culling. Add `OccluderInstance3D` nodes to your large solid geometry (walls, terrain). The renderer will skip drawing objects behind occluders, reducing both draw calls and fill rate.

### Object Pooling

Avoid `Node.new()` and `queue_free()` every frame for frequently spawned objects (bullets, particles, enemies). Allocate a pool at startup and reuse:

```gdscript
# Simple object pool
class_name BulletPool
extends Node

const POOL_SIZE: int = 200

var _pool: Array[Bullet] = []
var _next: int = 0

@export var bullet_scene: PackedScene

func _ready() -> void:
    for i: int in POOL_SIZE:
        var b: Bullet = bullet_scene.instantiate()
        b.visible = false
        b.set_physics_process(false)
        add_child(b)
        _pool.append(b)

func get_bullet() -> Bullet:
    var b: Bullet = _pool[_next]
    _next = (_next + 1) % POOL_SIZE
    b.visible = true
    b.set_physics_process(true)
    return b

func return_bullet(b: Bullet) -> void:
    b.visible = false
    b.set_physics_process(false)
    b.global_position = Vector3.ZERO
```

### GDScript Performance Tips

**Cache node references in `_ready()`, never call `get_node()` in `_process()`:**

```gdscript
# BAD — get_node() every frame
func _process(delta: float) -> void:
    get_node("Player").health -= 1

# GOOD — cached reference
@onready var _player: Player = $Player

func _process(delta: float) -> void:
    _player.health -= 1
```

**Avoid allocating new objects in `_process()`:**

```gdscript
# BAD — creates a new Vector3 every frame
func _process(delta: float) -> void:
    var offset: Vector3 = Vector3(1.0, 0.0, 0.0)
    position += offset * delta

# GOOD — use a constant
const MOVE_DIR := Vector3(1.0, 0.0, 0.0)

func _process(delta: float) -> void:
    position += MOVE_DIR * delta
```

**Use `@export` variables instead of magic numbers.** Cacheable, tweak-able, and profile-friendly.

**Match `_process` vs `_physics_process` to actual need.** Visual-only logic (animations, UI) belongs in `_process`. Physics and collision logic belongs in `_physics_process`. Never query collision state in `_process` — use `_physics_process` where it's valid.

### Rendering Settings for Performance

In Project Settings > Rendering:

- **Anti-aliasing:** MSAA 2x is a good balance. TAA has quality advantages but costs more.
- **Shadow atlas size:** Lower this if shadows are a bottleneck. 2048 is a good default.
- **Shadow distance:** The `DirectionalLight3D` shadow distance — lower it if you don't need far shadows.
- **SSAO / SSIL / SSR:** These are expensive. Disable for mobile/web. Use selectively for desktop.
- **Volumetric fog:** Expensive. Use simple fog (`WorldEnvironment`) for most cases.
- **Glow / Bloom:** Cheap on desktop, moderate on mobile. Use the `WorldEnvironment` version, not canvas effects.

---

## 6. Polish Checklist

### Game Feel

Before you ship, do a pass on game feel. This is the difference between "technically works" and "feels good to play":

**Screen shake:** A small shake on impact, death, or explosion makes hits register viscerally.

```gdscript
# Simple screen shake via camera trauma system
class_name CameraShaker
extends Camera3D

var _trauma: float = 0.0
var _trauma_power: float = 2.0
var _max_offset: Vector2 = Vector2(0.05, 0.05)

const DECAY: float = 0.8

func add_trauma(amount: float) -> void:
    _trauma = minf(_trauma + amount, 1.0)

func _process(delta: float) -> void:
    _trauma = maxf(_trauma - DECAY * delta, 0.0)
    var shake: float = pow(_trauma, _trauma_power)
    var seed_x: float = Time.get_ticks_msec() * 0.01
    h_offset = _max_offset.x * shake * sin(seed_x * 43.0)
    v_offset = _max_offset.y * shake * sin(seed_x * 71.0)
```

**Juice particles:** `GPUParticles3D` on impacts, pickups, and deaths. Keep particle counts low on web.

**Sound feedback:** Every button press, every hit, every pickup should have a sound. Use `AudioStreamPlayer` for global audio, `AudioStreamPlayer3D` for positional audio. Randomize pitch slightly (`pitch_scale = randf_range(0.9, 1.1)`) to prevent repetitive sounds from becoming annoying.

### Settings Menu

A basic settings menu goes a long way. At minimum:

```gdscript
# Audio settings — save with ConfigFile
class_name SettingsManager
extends Node

const SETTINGS_PATH: String = "user://settings.cfg"

var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
    load_settings()

func set_master_volume(db: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
    _config.set_value("audio", "master_volume", db)
    save_settings()

func get_master_volume() -> float:
    return _config.get_value("audio", "master_volume", 0.0)

func set_fullscreen(enabled: bool) -> void:
    if enabled:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    _config.set_value("display", "fullscreen", enabled)
    save_settings()

func save_settings() -> void:
    _config.save(SETTINGS_PATH)

func load_settings() -> void:
    if _config.load(SETTINGS_PATH) == OK:
        var vol: float = get_master_volume()
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), vol)
```

### Save and Load

Use `FileAccess` for simple save data:

```gdscript
# Simple save/load with JSON
class_name SaveManager
extends Node

const SAVE_PATH: String = "user://save.json"

func save_game(data: Dictionary) -> void:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "\t"))
        file.close()

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return {}
    var content: String = file.get_as_text()
    file.close()
    var result: Variant = JSON.parse_string(content)
    if result is Dictionary:
        return result
    return {}

func delete_save() -> void:
    DirAccess.remove_absolute(SAVE_PATH)
```

### Accessibility Basics

- **Subtitles/captions** for dialogue and story beats
- **Color-blind modes** — avoid red/green as the only differentiator
- **Remappable controls** — use `InputMap` and save keybinds to the settings config
- **Pause menu** — always let players pause and quit cleanly
- **Resolution options** — at least Windowed/Fullscreen toggle

### Error Handling

Before shipping, audit your `_ready()` functions for null checks:

```gdscript
# Crash-safe node initialization
func _ready() -> void:
    var player: Node = get_node_or_null("Player")
    if player == null:
        push_error("Player node not found in scene tree")
        return
    # ... proceed safely
```

Use `assert()` for logic invariants during development — asserts are stripped in release builds:

```gdscript
func take_damage(amount: int) -> void:
    assert(amount >= 0, "Damage must be non-negative")
    health -= amount
```

---

## 7. Publishing to itch.io

### Account Setup

Go to [itch.io](https://itch.io) and create a free account. Go to your dashboard and click **Create new project**.

Fill in:
- **Title** — your game name
- **Project URL** — the slug for your game page URL
- **Kind of project** — Games
- **Classification** — Game
- **Uploads** — leave this for now, do it after export
- **Description** — write something! Even one sentence is better than nothing.
- **Screenshots** — take at least 3-4 screenshots from in-game

### Uploading Builds Manually

For each platform, zip your export and upload it:

1. Windows: zip the folder containing `.exe`
2. macOS: zip the `.app` bundle
3. Linux: zip the `.x86_64` binary
4. Web: zip the entire web export folder

In the Uploads section, mark each upload with the correct platform tag so itch.io shows the right download button to each user. For web, mark it as "This file will be played in the browser."

### Butler CLI — Automated Uploads

[Butler](https://itchio.itch.io/butler) is itch.io's command-line upload tool. It does incremental uploads (only changed files), which is much faster than manual zipping.

```bash
# Install butler
# Download from https://itchio.itch.io/butler and add to PATH

# Authenticate (one-time)
butler login

# Upload a build
# Format: butler push <path> <user>/<game>:<channel>
butler push exports/windows/ your-username/your-game:windows
butler push exports/web/ your-username/your-game:html5
butler push exports/linux/ your-username/your-game:linux
butler push exports/macos/ your-username/your-game:mac

# Check status
butler status your-username/your-game
```

Channels are arbitrary labels — `windows`, `html5`, `linux`, `mac` are conventional but you can use anything. itch.io shows the correct download based on the platform tag you assign in the dashboard.

### HTML Embed Settings on itch.io

On your game's edit page, scroll to the Uploads section:
1. Check the box on your `.html` file to make it the playable version
2. Under **Embed options**, set **Viewport dimensions** to match your `display/window/size/viewport_width` and `height` from Project Settings
3. Enable **Enable SharedArrayBuffer**
4. Optionally enable **Mobile friendly** and **Fullscreen button**

Then under the main **Embed options** section (further down the page), set the **Embed type** — "Click to launch in fullscreen" is a good default that avoids iframe layout issues.

### Pricing Considerations

itch.io supports:
- **Free** — maximum exposure, zero revenue
- **Pay what you want** with a minimum of $0 — lets people pay if they want to
- **Paid** — sets a minimum price

For your first few games: free or pay-what-you-want. The goal is shipping and getting feedback, not revenue. Once you have something polished, paid is fine.

itch.io takes 10% by default. You can raise this to support the platform or lower it (minimum is 10% but you can give 0% if you pay itch.io a flat fee instead).

### Devlog

Write a devlog post when you launch. Even a short one: "I made this game in a weekend, here's what I learned." Devlogs get featured in itch.io's feed, drive traffic to your page, and create a record of your progress. The Godot community on itch.io is active — tag your game with "Godot" in the tags.

---

## 8. GDExtension & C++

### When to Use GDExtension

GDScript handles 95% of game logic comfortably. Use GDExtension when:

- You have a computation-heavy algorithm that GDScript can't run fast enough (pathfinding for 10,000 agents, custom physics, procedural generation)
- You need to integrate a C or C++ library that has no GDScript wrapper (specific audio codec, ML inference, platform SDK)
- You're building an addon you want to distribute with native performance

Don't reach for GDExtension to solve a problem you haven't profiled yet. "GDScript is slow" is usually "my GDScript has unnecessary allocations and unoptimized loops."

### godot-cpp

[godot-cpp](https://github.com/godotengine/godot-cpp) is the official C++ binding library for GDExtension. It gives you the full Godot API from C++.

```bash
# Set up a GDExtension project
mkdir my_extension && cd my_extension
git init
git submodule add https://github.com/godotengine/godot-cpp.git

# godot-cpp uses SCons as its build system
# Install SCons: pip install scons

# Build the binding library for your platform
cd godot-cpp
scons platform=linux target=template_debug
scons platform=linux target=template_release
```

### Writing a GDExtension Class

A minimal GDExtension class that exposes a fast function to GDScript:

```cpp
// fast_math.h
#ifndef FAST_MATH_H
#define FAST_MATH_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

class FastMath : public Node {
    GDCLASS(FastMath, Node)

protected:
    static void _bind_methods();

public:
    // Returns the sum of squares of an array — example heavy computation
    double sum_of_squares(const PackedFloat64Array& values);
};

#endif
```

```cpp
// fast_math.cpp
#include "fast_math.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void FastMath::_bind_methods() {
    ClassDB::bind_method(D_METHOD("sum_of_squares", "values"),
                         &FastMath::sum_of_squares);
}

double FastMath::sum_of_squares(const PackedFloat64Array& values) {
    double total = 0.0;
    for (int i = 0; i < values.size(); ++i) {
        double v = values[i];
        total += v * v;
    }
    return total;
}
```

```gdscript
# Using the extension in GDScript
var math: FastMath = FastMath.new()
var values: PackedFloat64Array = PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0])
var result: float = math.sum_of_squares(values)
print(result)  # 55.0
```

### The .gdextension File

The `.gdextension` file tells Godot where to find your compiled library:

```ini
[configuration]
entry_symbol = "my_extension_init"
compatibility_minimum = "4.1"

[libraries]
linux.debug.x86_64 = "res://bin/libmy_extension.linux.template_debug.x86_64.so"
linux.release.x86_64 = "res://bin/libmy_extension.linux.template_release.x86_64.so"
windows.debug.x86_64 = "res://bin/libmy_extension.windows.template_debug.x86_64.dll"
windows.release.x86_64 = "res://bin/libmy_extension.windows.template_release.x86_64.dll"
macos.debug = "res://bin/libmy_extension.macos.template_debug.framework"
macos.release = "res://bin/libmy_extension.macos.template_release.framework"
```

### Popular GDExtension Addons

Some addons you'd install as pre-built GDExtension (not write yourself):

- **Jolt Physics** — alternative physics engine, significantly faster for large simulations
- **LimboAI** — behavior tree AI library
- **GDSQLite** — SQLite database bindings
- **FastNoiseLite** — already built into Godot 4, but the standalone version has more options

---

## 9. Where to Go Next

### Game Jams

Jams are the single best accelerant for your growth. You build something complete under time pressure, get community feedback, and see what other developers built with the same constraints.

**Ludum Dare** (ludumdare.com) — runs three times a year, 48 or 72 hours. The "Compo" (solo, 48hr) and "Jam" (teams, 72hr) tracks. One of the oldest and most prestigious game jams.

**GMTK Game Jam** (itch.io, hosted by Game Maker's Toolkit) — runs once a year, 48 hours. Massive community (~20,000 entries in recent years). Very Godot-friendly.

**Godot Wild Jam** — monthly, Godot-only jam. Smaller but very supportive community. Good for beginners.

**Global Game Jam** (globalgamejam.org) — runs at physical venues worldwide in January. Good for meeting local developers.

For your first jam: pick a 48-72 hour jam, scope extremely small (one mechanic), and finish. Playable and submitted beats polished and incomplete.

### Godot Community Resources

**Official docs:** [docs.godotengine.org](https://docs.godotengine.org) — the best game engine documentation available. Use it constantly.

**Godot Discord:** discord.gg/godotengine — active, beginner-friendly, organized by topic.

**Godot subreddit:** r/godot — good for inspiration, help, and seeing what others are building.

**GDQuest** (gdquest.com) — high-quality free and paid tutorials, especially for 2D.

**KidsCanCode** — excellent beginner-to-intermediate Godot resources.

**Bitlytic** (YouTube) — deep dives into Godot systems, especially audio and shaders.

### Advanced Topics After This Wiki

These are the next horizons after you've shipped a few games:

**NavigationServer3D** — proper navmesh generation and agent pathfinding. Essential for any game with AI that needs to navigate around obstacles.

**Terrain systems** — Godot has no built-in terrain editor like Unity's. Look at the **Terrain3D** plugin (C++ extension) for production-quality terrain.

**VR/XR** — Godot has first-class OpenXR support via the XRInterface. Works with Meta Quest, SteamVR, and other platforms. See the [Godot XR docs](https://docs.godotengine.org/en/stable/tutorials/xr/index.html).

**Multiplayer deep dive** — this wiki covered the basics in Module 11. The next level is relay vs. direct connections, matchmaking, cheat prevention, and lag compensation. Look at the **Nakama** server (open-source, has a Godot SDK) for production multiplayer.

**Shaders** — Godot's shader language is close to GLSL. The [Godot Shader Language docs](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/index.html) and [The Book of Shaders](https://thebookofshaders.com) are the resources here.

**Procedural generation** — noise maps, wave function collapse, grammar-based generation. Module 8 touched this; the rabbit hole goes much deeper.

### Learning by Shipping

The most important advice: keep shipping. Make small games. Make bad games. Make games that embarrass you six months later. The only way to get better is reps, and reps means finished games, not bigger and bigger "current projects."

A useful mental model: your first ten games are a cost of admission. They're not for players — they're for you to learn the craft. Ship them anyway. Get them out of your system. Game eleven starts getting interesting.

---

## 10. Your Shipping Workflow (Code Walkthrough)

### Pre-Export Checklist Script

Keep this as a comment at the top of your main scene's script, or as a `TODO` in your project:

```gdscript
# PRE-EXPORT CHECKLIST
# =====================
# [ ] Project Settings > Application > Name set correctly
# [ ] Project Settings > Application > Run > Main Scene set
# [ ] Project Settings > Display > Window > Viewport Width/Height set
# [ ] Icon set in Project Settings > Application > Boot Splash / Config
# [ ] All debug print() calls removed or behind a debug flag
# [ ] Audio bus layout saved
# [ ] Input actions all named and saved
# [ ] Save file path uses "user://" not "res://"
# [ ] Web export tested locally with python -m http.server
# [ ] Version string updated in Project Settings
# [ ] All export presets have correct paths that exist on disk
```

### Automate Export with Command Line

Godot's command-line interface makes exporting scriptable:

```bash
#!/bin/bash
# export_all.sh — run from project root

GODOT="godot"  # or full path to Godot binary
PROJECT_PATH="."

# Create output directories
mkdir -p exports/windows
mkdir -p exports/linux
mkdir -p exports/web
mkdir -p exports/mac

# Export all presets
$GODOT --headless --path "$PROJECT_PATH" \
    --export-release "Windows Desktop" exports/windows/MyGame.exe

$GODOT --headless --path "$PROJECT_PATH" \
    --export-release "Linux/X11" exports/linux/MyGame.x86_64

$GODOT --headless --path "$PROJECT_PATH" \
    --export-release "Web" exports/web/index.html

$GODOT --headless --path "$PROJECT_PATH" \
    --export-release "macOS" exports/mac/MyGame.app

echo "All exports complete."
```

### Butler Upload Script

```bash
#!/bin/bash
# upload_all.sh — uploads all builds to itch.io

ITCHIO_USER="your-username"
ITCHIO_GAME="your-game-slug"

butler push exports/windows/ $ITCHIO_USER/$ITCHIO_GAME:windows
butler push exports/linux/   $ITCHIO_USER/$ITCHIO_GAME:linux
butler push exports/web/     $ITCHIO_USER/$ITCHIO_GAME:html5
butler push exports/mac/     $ITCHIO_USER/$ITCHIO_GAME:mac

echo "Upload complete."
butler status $ITCHIO_USER/$ITCHIO_GAME
```

### GitHub Actions CI/CD for Godot

Automate builds and uploads on every push to `main`. Store your butler API key as a GitHub Actions secret named `BUTLER_CREDENTIALS`.

```yaml
# .github/workflows/export.yml
name: Export and Upload

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  export:
    name: Export Godot Project
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      - name: Install Godot
        run: |
          wget -q https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
          unzip -q Godot_v4.3-stable_linux.x86_64.zip
          mv Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot
          chmod +x /usr/local/bin/godot

      - name: Install Export Templates
        run: |
          mkdir -p ~/.local/share/godot/export_templates/
          wget -q https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz \
               -O templates.tpz
          unzip -q templates.tpz -d ~/.local/share/godot/export_templates/
          mv ~/.local/share/godot/export_templates/templates \
             ~/.local/share/godot/export_templates/4.3.stable

      - name: Create export directories
        run: |
          mkdir -p exports/web
          mkdir -p exports/linux

      - name: Export Web
        run: |
          godot --headless --path . \
            --export-release "Web" exports/web/index.html

      - name: Export Linux
        run: |
          godot --headless --path . \
            --export-release "Linux/X11" exports/linux/MyGame.x86_64

      - name: Upload to itch.io
        env:
          BUTLER_CREDENTIALS: ${{ secrets.BUTLER_CREDENTIALS }}
        run: |
          # Install butler
          wget -q https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default \
               -O butler.zip
          unzip -q butler.zip
          chmod +x butler
          # Upload
          ./butler push exports/web/ your-username/your-game:html5
          ./butler push exports/linux/ your-username/your-game:linux

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: game-exports
          path: exports/
```

### Version Management

Track your version in `project.godot` and expose it at runtime:

```gdscript
# Accessible anywhere via ProjectSettings
func get_version() -> String:
    return ProjectSettings.get_setting("application/config/version", "0.0.0")

# Display in your main menu
func _ready() -> void:
    $VersionLabel.text = "v" + get_version()
```

Set the version in Project Settings > Application > Config > Version. Increment before each upload to itch.io so players can tell which version they're playing when reporting bugs.

---

## API Quick Reference

| Tool / API | What It Does | Where to Find It |
|---|---|---|
| `godot --headless --export-release` | Export project from CLI | Terminal |
| `butler push` | Upload build to itch.io | butler CLI |
| `Debugger > Profiler` | Per-frame script timing | Editor bottom panel |
| `Debugger > Monitors` | Real-time performance graphs | Editor bottom panel |
| `MultiMeshInstance3D` | Render many instances in one draw call | Node in scene tree |
| `VisibleOnScreenNotifier3D` | Callbacks when node leaves screen | Node in scene tree |
| `OS.has_feature("web")` | Check current platform at runtime | GDScript global |
| `DisplayServer.window_set_mode()` | Toggle fullscreen | GDScript global |
| `AudioServer.set_bus_volume_db()` | Set audio bus volume | GDScript global |
| `FileAccess` | Read/write files in user:// | GDScript class |
| `ConfigFile` | INI-style config read/write | GDScript class |
| `ProjectSettings.get_setting()` | Read project settings at runtime | GDScript global |
| `set_physics_process(false)` | Disable physics tick for a node | Node method |
| `push_error()` | Log an error (visible in editor + remote debugger) | GDScript global |
| `assert()` | Debug invariant (stripped in release builds) | GDScript keyword |

---

## Common Pitfalls

**WRONG — calling `get_node()` every physics frame:**
```gdscript
func _physics_process(delta: float) -> void:
    get_node("Player").velocity = Vector3.ZERO  # Path lookup every tick
```

**RIGHT — cache in `_ready()`:**
```gdscript
@onready var _player: CharacterBody3D = $Player

func _physics_process(delta: float) -> void:
    _player.velocity = Vector3.ZERO
```

---

**WRONG — trying to open the web export HTML from disk:**
```
# Double-clicking index.html gives CORS/SharedArrayBuffer errors
file:///home/user/exports/web/index.html
```

**RIGHT — serve it with a local HTTP server:**
```bash
cd exports/web && python3 -m http.server 8080
# Then open http://localhost:8080
```

---

**WRONG — using trimesh collision for a dynamic RigidBody:**
```
# ConcavePolygonShape3D on a RigidBody3D = physics engine sadness
# Godot will warn you about this, and it will be very slow
```

**RIGHT — use convex or primitive shapes for dynamic bodies:**
```
# ConvexPolygonShape3D, BoxShape3D, SphereShape3D, CapsuleShape3D
# Save trimesh (ConcavePolygonShape3D) for static geometry only
```

---

**WRONG — using `res://` paths for save files:**
```gdscript
var file := FileAccess.open("res://save.json", FileAccess.WRITE)
# Fails on all exported builds — res:// is read-only in exports
```

**RIGHT — use `user://` for any file you write at runtime:**
```gdscript
var file := FileAccess.open("user://save.json", FileAccess.WRITE)
# user:// maps to the correct writable location on each platform
```

---

**WRONG — forgetting SharedArrayBuffer headers on custom hosting:**
```
# Game loads but prints: "SharedArrayBuffer is not defined"
# Audio doesn't work. Threading doesn't work. Game may not start at all.
```

**RIGHT — set the required COOP/COEP headers on your server:**
```nginx
add_header Cross-Origin-Opener-Policy "same-origin";
add_header Cross-Origin-Embedder-Policy "require-corp";
# On itch.io: just check "Enable SharedArrayBuffer" in embed settings
```

---

**WRONG — shipping without testing the actual export:**
```
# "Works in editor" is not the same as "works in export"
# Shaders compile differently, paths resolve differently,
# and some nodes behave differently without the editor running
```

**RIGHT — test your export builds before uploading:**
```bash
# Export, then run the actual binary
./exports/linux/MyGame.x86_64
# Or for web: python3 -m http.server 8080 and open localhost:8080
```

---

## Exercises

### Exercise 1: Export All Three Platforms

Export your current project for Windows, Linux, and Web. For each platform:
- Verify the build runs (use a local server for web)
- Fix any export-only bugs you find (common: `res://` paths, missing resources)
- Note the file size of each export

Stretch goal: set up the CI/CD GitHub Actions workflow and confirm it runs successfully on push.

### Exercise 2: Profile and Optimize

Open your project in the editor, start the profiler, and play through your game for 30 seconds. Find the single most expensive function in the profiler's Self time column. Optimize it — cache references, reduce allocations, or restructure the logic. Measure before and after.

Also open the Monitors tab and identify: what is your average draw call count? Can you reduce it with MultiMesh or disabling off-screen processing?

### Exercise 3: Ship to itch.io

Create an itch.io account if you don't have one. Install butler. Write a `upload.sh` script. Ship your project:
1. Web build (required — this is what most players will use)
2. At least one desktop build
3. Fill in the game page: description, screenshots, tags
4. Share the link

Announce it in the Godot Wild Jam Discord or r/godot. The first ship is the hardest. After this one, the next is easier.

### Exercise 4: Juice Pass

Pick your project and do a dedicated "juice pass" — improving game feel without adding new mechanics:
1. Add screen shake to at least one impact or event
2. Add a sound to at least three interactions that currently have no audio
3. Add particle effects to at least one event
4. Add a settings menu with master volume control that saves to `user://settings.cfg`

Playtest before and after. Notice how different the game feels with the same mechanics and better feedback.

---

## Recommended Reading

| Resource | What It Covers | Link |
|---|---|---|
| Godot Export Docs | All export options, templates, encryption | [docs.godotengine.org/en/stable/tutorials/export/](https://docs.godotengine.org/en/stable/tutorials/export/index.html) |
| Godot Web Export Docs | SharedArrayBuffer, COOP/COEP, browser specifics | [docs.godotengine.org — web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) |
| butler Docs | CLI reference, API keys, channels | [itch.io/docs/butler/](https://itch.io/docs/butler/) |
| Godot Profiler Guide | How to read profiler output | [docs.godotengine.org — profiling](https://docs.godotengine.org/en/stable/tutorials/performance/using_the_profiler.html) |
| GDExtension Tutorial | Complete C++ extension walkthrough | [docs.godotengine.org — GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html) |
| godot-cpp repository | Source, build instructions, examples | [github.com/godotengine/godot-cpp](https://github.com/godotengine/godot-cpp) |
| Godot Performance Tips | Official optimization guide | [docs.godotengine.org — performance](https://docs.godotengine.org/en/stable/tutorials/performance/index.html) |
| itch.io Creator Docs | Publishing, embedding, pricing | [itch.io/docs/creators/](https://itch.io/docs/creators/) |
| GitHub Actions for Godot | Community CI/CD recipes | [github.com/abarichello/godot-ci](https://github.com/abarichello/godot-ci) |
| The Book of Shaders | Shader fundamentals (platform-agnostic) | [thebookofshaders.com](https://thebookofshaders.com) |

---

## Key Takeaways

- Export templates must be installed before you can build for any platform. Install them via **Editor > Manage Export Templates**.
- Web exports require the `SharedArrayBuffer` HTTP headers (`COOP: same-origin`, `COEP: require-corp`). On itch.io, check the "Enable SharedArrayBuffer" checkbox. On your own server, add the headers in your nginx/Cloudflare config.
- Never use `res://` paths for files you write at runtime. Use `user://` — it maps to the correct writable directory on every platform.
- Test your exports before shipping. "Works in editor" is not a guarantee.
- The profiler's **Self** time column tells you where your code actually spends time. Sort by it to find real bottlenecks.
- Cache node references in `_ready()` using `@onready`. Never call `get_node()` in `_process()` or `_physics_process()`.
- MultiMesh renders thousands of identical objects in a single draw call. Use it for anything you'd otherwise spawn hundreds of nodes for.
- Trimesh colliders (`ConcavePolygonShape3D`) are only for static geometry. Use convex shapes for dynamic bodies.
- Butler is the fastest way to upload builds to itch.io, especially once you have CI/CD set up.
- GDExtension is the right tool for performance-critical code and C library integration — but profile first. Most GDScript performance issues are fixable without dropping to C++.
- Ship small things often. The fastest path to making good games is making many games.

---

## Congratulations — You've Completed the Wiki

You started at Module 0 with a blank Godot install and no idea how a scene tree works. You're finishing at Module 13 with the tools to build, profile, optimize, and ship games across web and desktop platforms.

This wiki covered the full stack: scenes, scripting, 3D fundamentals, cameras, physics, shaders, lighting, post-processing, procedural worlds, audio, architecture, UI, multiplayer, WebGPU, and now shipping. That's not a beginner's curriculum anymore. That's the foundation of a working game developer.

The path forward is not more tutorials. It's games. Make a jam game this weekend. Make something ugly that works. Make something ambitious that half-works. Ship it. Look at what players do with it. Make the next one.

The Godot community is friendly, the engine is free and open-source, and the tools are genuinely excellent. You're in a good position. Go build something.

**[Back to the Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)**
