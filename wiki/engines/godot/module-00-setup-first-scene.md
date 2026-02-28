# Module 0: Setup & First Scene

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** None (basic programming knowledge assumed — Python, JS, or C# background)

---

## Overview

You're about to build 3D games with Godot — a free, open-source engine that runs as a single executable with no installer, no account, no nonsense. There's no Node.js to manage, no package.json, no webpack config. You download one file, double-click it, and you're in. By the end of this module you'll have a working solar system toy running in Godot's built-in game window: a glowing sun, orbiting planets, and click interactions — all from scratch.

This module covers the absolute foundations: downloading Godot, navigating the editor (viewport, scene tree, inspector, file system dock), creating nodes, attaching scripts, and running a game loop with `_process(delta)`. The game loop is where everything interesting happens. It's the heartbeat of every game, simulation, and interactive experience you'll build. Get comfortable with it here.

You'll also wire up click interactions via input events, use `@export` to expose variables to the inspector, and build a complete mini-project. It's small, but it touches every concept you need to build on. Godot's scene system is composable — you'll feel that immediately once the planets start orbiting.

---

## 1. Getting Godot

### Download and Run

Go to [godotengine.org/download](https://godotengine.org/download). Grab the latest stable release — Godot 4.3 or newer required for this module. The download is a single `.zip` containing one executable. Extract it anywhere — your Desktop, your Documents folder, wherever. No installer. No admin rights. No package manager.

On macOS, you may need to right-click and select "Open" the first time to bypass the Gatekeeper warning. On Linux, `chmod +x` the binary if it doesn't run directly.

### .NET vs Standard — Which One to Download

On the download page you'll see two versions:

| Version | Description | Use If |
|---------|-------------|--------|
| **Standard** (GDScript) | Built-in scripting language, Python-like | You're new to Godot, or want fast iteration |
| **.NET** (C#) | Adds C# support via .NET 6+ | You specifically want C# |

**Recommendation: download the standard version.** This module uses GDScript. GDScript is not a toy language — it's deeply integrated with the engine, autocompletes engine API perfectly, and reloads scripts without restarting the game. C# is a solid option if you're coming from Unity, but GDScript is faster to learn and produces less boilerplate for Godot-specific code.

### Creating a New Project

Open Godot. You'll see the Project Manager — a list of recent projects with buttons to create or import.

1. Click **New Project**
2. Give it a name: `solar-system-toy`
3. Choose a folder — Godot will create a subfolder with your project name
4. Leave Renderer at the default (Forward+)
5. Click **Create & Edit**

The editor opens. Your project directory now exists on disk.

### Project Structure

```
solar-system-toy/
├── .godot/               # Engine cache — don't touch, don't commit to version control
├── project.godot         # Project settings file — human-readable, similar to package.json
├── icon.svg              # Default project icon
└── (your files will go here)
```

Everything in your project lives under `res://` — Godot's virtual filesystem root. `res://main.tscn` is a scene file at the root of your project. `res://scenes/planet.tscn` is inside a `scenes/` subfolder. When you write code that references files, always use `res://` paths, not absolute OS paths.

The `.godot/` folder is engine-generated cache (imported assets, shader cache, etc.). Add it to `.gitignore` if you're using version control.

`project.godot` is a key-value text file with global settings: project name, main scene path, display resolution, physics settings. You can edit it directly in a text editor, but the **Project > Project Settings** menu in the editor is easier.

---

## 2. The Editor Tour

### The Four Main Docks

Godot's editor is organized around four main areas. Learn these now — everything you do will involve at least two of them.

**Viewport (center)** — The 3D (or 2D) view where you see and manipulate your scene visually. You spend most of your time here. Switch between 3D and 2D using the buttons at the top. The Script editor is also accessible from the top tabs.

**Scene Tree (top-left)** — Shows every node in your current scene as a hierarchy. This is the structure of your game. Nodes can have children. Children are positioned relative to their parent. Adding, removing, reparenting, and naming nodes all happen here. If you know the DOM or React's component tree, this is the same idea.

**Inspector (right)** — Shows the properties of the currently selected node. Select a `MeshInstance3D` and the inspector shows its mesh, material, visibility, transform. Change any value and you see it update in real time. This is also where `@export` variables from your scripts show up.

**FileSystem Dock (bottom-left)** — Your project's files. All your `.tscn` scene files, `.gd` scripts, textures, and audio live here. Double-click a scene to open it. Drag a resource from here into the inspector to assign it to a property.

### The Toolbar

Along the top of the viewport:

- **Play buttons** — Triangle (play project), triangle with scene icon (play current scene), stop. Use **F5** to run the project and **F6** to run just the current scene.
- **Transform tools** — Select (Q), Move (W), Rotate (E), Scale (R). Same as most 3D editors.
- **Local/Global space toggle** — Affects whether transform gizmos are aligned to the object or to world axes.

### Navigating the 3D Viewport

| Action | Control |
|--------|---------|
| Orbit around focus point | Middle mouse button + drag |
| Zoom in/out | Scroll wheel |
| Pan (strafe) | Shift + middle mouse + drag |
| Focus on selected node | F |
| Perspective / Orthographic toggle | Numpad 5 |
| Front view | Numpad 1 |
| Top view | Numpad 7 |
| Right view | Numpad 3 |
| Free-look (fly around) | Right-click + WASD |

The **F key** is the one you'll use constantly. Select a node in the Scene Tree, press F in the viewport, and the camera snaps to focus on it. If your scene looks empty, you've probably just flown out of bounds — select any node and press F.

---

## 3. Your First Node

### Everything Is a Node

Godot's fundamental concept: everything in a scene is a **node**. A node is an object with:
- A type (what it can do — mesh, light, physics body, script executor, etc.)
- A name
- A transform (position, rotation, scale)
- A parent (except the root node)
- Zero or more children

A **scene** is a saved tree of nodes. You build scenes by combining nodes. You combine scenes with other scenes. That's the whole system.

### Adding the Root Node

Open the Scene Tree. It says "Create Root Node." Click **3D Scene** — this adds a `Node3D` as the root. Rename it: click the node, press F2, type `SolarSystem`, press Enter.

A `Node3D` is a plain transform node. It doesn't render anything by itself, but it gives everything parented to it a shared coordinate space. Every 3D scene should start with one.

### Add a Sphere

In the Scene Tree, click the "+" button (or press Ctrl+A) to add a child node. Search for `MeshInstance3D`. Add it. Name it `Sun`.

With `Sun` selected, look in the Inspector on the right. Find the **Mesh** property — it says "empty." Click the dropdown next to it, select **New SphereMesh**. A sphere appears in the viewport.

The `SphereMesh` is a built-in primitive mesh resource. In the inspector, you can expand it to change the radius (default 0.5 — change it to 1.0 for the sun). `MeshInstance3D` is the node that renders geometry; the `Mesh` property holds the actual shape data.

### Add a Light

Add another child to the root `SolarSystem` node — this time, search for `DirectionalLight3D`. Name it `Sun Light`.

In the inspector, set **Energy** to 2.0. Rotate it so it's pointing downward at an angle: in the viewport, use the rotate tool (E) and tilt it, or set the Transform rotation directly in the inspector (try `-45` on X, `45` on Y).

A `DirectionalLight3D` simulates a distant light source like the sun — parallel rays hitting everything from one direction. It illuminates your scene but doesn't illuminate it correctly yet because you only have one sphere and the light is pointing at the wrong angle. You'll fix this properly in the lighting section.

### Add a Camera

Without a camera, you see nothing when you run the game. The editor viewport has its own camera, but the game window has its own separate camera that you must place.

Add a `Camera3D` as a child of the root node. Name it `Camera`. In the inspector (or viewport), set its position: click the node, use the Move tool (W) to drag it backward and upward, or type directly in Transform: Position Z = 20, Position Y = 10. Then rotate it down slightly so it's looking at the sphere: Rotation X = -25.

Press the **Preview** button at the top-left of the viewport, or just run the game with F5.

### Run It — F5

Press F5. Godot will ask you to choose a main scene. Click **Select** and choose the current scene. The game window opens. You see a sphere. Congratulations — that's a Godot 3D scene running.

Close the game window to return to the editor. Everything about your game starts from here.

---

## 4. GDScript Crash Course

### Attaching a Script

In the Scene Tree, right-click the `Sun` node. Select **Attach Script**. A dialog appears:
- Template: Empty (or "Node: Default" — both work)
- Path: leave as-is (it'll create `sun.gd` next to your scene file)

Click **Create**. The Script editor opens with a new `.gd` file.

### The Anatomy of a GDScript File

```gdscript
extends MeshInstance3D

# This file is attached to a MeshInstance3D node.
# 'extends' tells Godot what type of node this script can be attached to.
```

`extends` is like class inheritance. Your script inherits all the methods and properties of `MeshInstance3D`. You can call `rotate_y()`, access `mesh`, set `visible` — all the things a `MeshInstance3D` can do.

### Variables

```gdscript
# Untyped — works, but avoid for anything serious
var speed = 2.0

# Statically typed — preferred
var speed: float = 2.0
var planet_name: String = "Mercury"
var is_selected: bool = false
var child_count: int = 0
```

Static typing in GDScript gives you autocomplete, type errors at parse time (before running the game), and slightly better performance. Get into the habit immediately.

### Functions

```gdscript
func greet(name: String) -> String:
    return "Hello, " + name

func do_something() -> void:
    print("no return value")
```

The `-> void` return type annotation is optional but recommended. It makes your intent clear and catches bugs.

### Built-in Lifecycle Functions

Two functions Godot calls automatically on every node:

**`_ready()`** — Called once when the node enters the scene tree. Use it for setup: get references to child nodes, initialize variables, create materials, connect signals.

**`_process(delta)`** — Called every frame. `delta` is the time in seconds since the last frame — typically about `0.016` at 60fps. This is your game loop. Everything that changes continuously lives here.

```gdscript
extends MeshInstance3D

func _ready() -> void:
    print("Sun node is ready!")

func _process(delta: float) -> void:
    # This runs every frame
    pass
```

### Your First Rotation Script

Replace the contents of `sun.gd` with this:

```gdscript
extends MeshInstance3D

var rotation_speed: float = 2.0

func _process(delta: float) -> void:
    rotate_y(rotation_speed * delta)
```

Save with Ctrl+S. Run with F5. The sphere rotates. This is the foundation of every moving object in your game.

### Delta Time — Why It Matters

`rotate_y(0.1)` — this rotates 0.1 radians per **frame**. On a 60fps machine that's 6 radians/sec. On a 120fps monitor it's 12 radians/sec. Your game runs at different speeds on different hardware. That's broken.

`rotate_y(rotation_speed * delta)` — this rotates `rotation_speed` radians per **second**, regardless of frame rate. Always multiply by delta for any continuous movement.

### print() for Debugging

```gdscript
func _ready() -> void:
    print("speed is: ", rotation_speed)
    print("position: ", position)
```

Output shows up in the **Output** panel at the bottom of the editor. This is your primary debugging tool. Use it aggressively.

### GDScript Compared to What You Know

If you're coming from Python, GDScript is immediately familiar — indentation-based, duck-typed by default, `print()`, `str()`, `len()`. The main differences are `func` instead of `def`, and Godot's type annotations.

If you're from JavaScript: `var` works the same. `func` is `function`. There's no `this` — you access the node's own properties directly. `_ready()` is like a constructor plus `componentDidMount`. `_process()` is `requestAnimationFrame` running automatically.

If you're from C#: GDScript will feel loose at first. The optional typing helps. Think of it as Python with a Godot-specific stdlib. You can always switch to C# later — the engine API is identical.

---

## 5. @export — Tweaking from the Inspector

### The Problem @export Solves

Hardcoded values in scripts are annoying. You change a number, save the script, switch back to the game, run it, see the result, realize you need a different number, switch back to the script... over and over.

`@export` solves this by surfacing your script variables directly in the Inspector. Change the value there — no code edits, no save, no reload. The value updates immediately, even while the game is running.

### Basic Usage

```gdscript
extends MeshInstance3D

@export var rotation_speed: float = 2.0

func _process(delta: float) -> void:
    rotate_y(rotation_speed * delta)
```

Now select the `Sun` node in the Scene Tree. Look at the Inspector. Under a section labeled with your script name, you'll see a "Rotation Speed" field showing `2.0`. Change it to `5.0`. Run the game. The sphere spins faster. Change it while the game is running and watch it update live.

This is Godot's version of "props you configure without touching code." It's the single best tool for iteration speed.

### More @export Examples

```gdscript
@export var rotation_speed: float = 2.0
@export var mesh_color: Color = Color.CORNFLOWER_BLUE
@export var planet_name: String = "Sun"
@export var orbit_radius: float = 5.0
@export var is_emissive: bool = true
```

Every type shows a different inspector widget: float gets a number field, Color gets a color picker, String gets a text box, bool gets a checkbox.

### @export_range for Sliders

```gdscript
# Clamp the value and show a slider in the inspector
@export_range(0.0, 10.0, 0.1) var rotation_speed: float = 2.0
```

Arguments are `min, max, step`. This is useful when you know the valid range of a value — prevents you from accidentally setting speed to 10000.

### @onready — Get References to Child Nodes

```gdscript
# Gets the OmniLight3D child node named "Light" when the scene is ready
@onready var light: OmniLight3D = $Light

# Equivalent to writing this in _ready():
# light = get_node("Light")
```

`$NodeName` is shorthand for `get_node("NodeName")`. It finds a child by name. `@onready` defers the assignment until `_ready()` runs, which is when the full scene tree is available. You'll use `@onready` constantly.

---

## 6. Materials and Color

### Creating a Material in the Editor

With the `Sun` node selected, look at the Mesh property in the inspector. Click the SphereMesh to expand it. Find **Material** (or **Surface 0 Material**) — click the dropdown and select **New StandardMaterial3D**.

A gray sphere becomes a white sphere with a material you can configure. Click the material to expand it in the inspector. You'll see sections for:
- **Albedo** — the base color
- **Roughness / Metallic** — surface shininess
- **Emission** — self-glow
- And many more

Change Albedo Color to yellow-orange. Enable Emission, set Emission Color to orange. Set Emission Energy Multiplier to 2.0. The sun starts to glow.

### The Local to Scene Problem

When you create a material on a mesh resource (the SphereMesh itself), that material is shared. If you have two spheres using the same SphereMesh, they share the same material — change the color of one and both change. To avoid this, enable **Local to Scene** on the material resource: in the inspector, click the material, find the dropdown at the top, check "Local to Scene." Now each instance of this scene gets its own copy of the material.

For planets you'll create as separate scene files, this isn't an issue — each scene file is its own thing. But if you instance the same planet scene multiple times, you need materials created in code to give each instance its own color.

### Creating Materials in Code

```gdscript
extends MeshInstance3D

@export var mesh_color: Color = Color.CORNFLOWER_BLUE

func _ready() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = mesh_color
    mat.emission_enabled = true
    mat.emission = Color.ORANGE
    mat.emission_energy_multiplier = 2.0
    # Set the material on surface 0 of this MeshInstance3D
    mesh_surface_set_material(0, mat)
```

`:=` is GDScript's type inference operator. `var mat := StandardMaterial3D.new()` means "create a new StandardMaterial3D and infer the type of `mat`." It's equivalent to `var mat: StandardMaterial3D = StandardMaterial3D.new()`, just shorter.

`mesh_surface_set_material(0, mat)` sets the material on surface index 0. Most simple meshes have one surface (index 0). Complex imported meshes might have multiple surfaces.

Creating materials in `_ready()` means each script instance creates its own material object — no accidental sharing, and the color comes from `@export var mesh_color` so each planet can be a different color.

### Useful StandardMaterial3D Properties

```gdscript
mat.albedo_color = Color(1.0, 0.5, 0.2)  # Orange-ish
mat.roughness = 0.8                        # 0 = mirror-smooth, 1 = totally matte
mat.metallic = 0.0                         # 0 = plastic/rock, 1 = metal
mat.emission_enabled = true
mat.emission = Color.ORANGE_RED
mat.emission_energy_multiplier = 3.0       # How bright the glow is
mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA  # Enable if you want opacity < 1
mat.albedo_color.a = 0.8                   # 80% opacity (only works with transparency enabled)
```

---

## 7. Lighting Basics

### Light Types

**DirectionalLight3D** — Simulates a far-away light source (the sun, the moon). All rays are parallel. Position doesn't matter; rotation determines direction. Has shadows. Use as the primary scene light.

```
Scene Tree:
└── DirectionalLight3D
    - Transform: Rotation X = -45, Y = 45
    - Light/Color: white
    - Light/Energy: 1.5
    - Shadow: enabled
```

**OmniLight3D** — Point light. Emits in all directions from a position (like a light bulb or torch). Has distance falloff. For the sun in a solar system, put an OmniLight3D at the center — it illuminates all the planets from the center.

```gdscript
# In the sun's _ready() or set in editor:
# Add OmniLight3D as child of Sun node
# Set Range to 50, Energy to 2.0
```

**SpotLight3D** — Cone of light (flashlight, spotlight). Has position, direction, cone angle, and penumbra softness.

### Adding Lights in the Editor

In the Scene Tree, select the root node. Ctrl+A > search for the light type > add. Position and rotate it in the viewport or via the inspector Transform properties.

For the solar system, you want an OmniLight3D at the center of the sun. Add it as a child of the Sun node with position (0, 0, 0) — it inherits the sun's position.

### WorldEnvironment and the Sky

A black void background is boring. Add a `WorldEnvironment` node to your scene to set up a sky.

1. In the Scene Tree, add a `WorldEnvironment` node (child of root)
2. In the inspector, click the **Environment** property > New Environment
3. Click the Environment resource to expand it
4. **Background > Mode**: set to Sky
5. **Background > Sky**: click dropdown > New Sky
6. Click the Sky resource to expand it
7. **Sky Material**: click dropdown > New ProceduralSkyMaterial

You now have a gradient sky — blue at the top, horizon at the bottom. For a space scene, set the sky color to near-black:

In the ProceduralSkyMaterial, set:
- **Sky Top Color**: `Color(0.02, 0.02, 0.05)` — deep dark blue-black
- **Sky Horizon Color**: `Color(0.05, 0.05, 0.1)`
- **Ground Bottom Color**: `Color(0.01, 0.01, 0.02)`

### Ambient Light

In the `Environment` resource, find **Ambient Light > Color** and **Ambient Light > Energy**. Ambient light fills in the dark sides of objects so they're not pure black. Set Energy to `0.1` for a subtle fill — enough to see the dark side of a planet without washing out your lighting.

---

## 8. The _process Game Loop

### This Is the Most Important Section in This Module

`_process(delta)` is your game loop. It runs every frame. Everything that moves continuously, animates, checks for input, or simulates physics lives here. Understand it deeply.

```gdscript
extends Node3D

func _process(delta: float) -> void:
    # This runs every frame — typically 60 times per second
    # delta = seconds since last frame (~0.0167 at 60fps)
    pass
```

### Delta — Frame-Rate Independence

At 60fps, `delta` is approximately `0.0167` seconds. At 30fps, it's `0.0333`. At 144fps, it's `0.0069`. Your game should behave identically across all of these.

**Always multiply continuous movement by delta.** No exceptions.

```gdscript
# BAD — tied to frame rate
func _process(delta: float) -> void:
    rotate_y(0.05)               # Rotates 0.05 rad/frame — different on 30fps vs 144fps

# GOOD — frame-rate independent
func _process(delta: float) -> void:
    rotate_y(2.0 * delta)        # Rotates 2.0 rad/second, always
```

### Rotation in _process

`rotate_y(radians)` rotates around the Y axis by the given amount. Godot uses radians, not degrees. If you think in degrees:

```gdscript
const DEG2RAD = PI / 180.0

func _process(delta: float) -> void:
    rotate_y(90.0 * DEG2RAD * delta)  # Rotate 90 degrees per second
    # Or just: rotate_y(deg_to_rad(90.0) * delta)
```

There's also `rotation.y += angle` for direct assignment, and `rotate_object_local(Vector3.UP, angle)` if you want local-space rotation. For the vast majority of use cases, `rotate_y()` is what you want.

### Translation in _process

```gdscript
@export var move_speed: float = 5.0

func _process(delta: float) -> void:
    # Move forward (toward -Z) at move_speed units per second
    position += Vector3.FORWARD * move_speed * delta

    # Or move along the object's local forward direction:
    translate(Vector3.FORWARD * move_speed * delta)
```

### Orbit Motion in _process

Orbiting is just positioning an object on a circle whose angle advances over time:

```gdscript
var orbit_angle: float = 0.0

@export var orbit_speed: float = 1.0   # radians per second
@export var orbit_radius: float = 5.0

func _process(delta: float) -> void:
    orbit_angle += orbit_speed * delta

    # Circular position in the XZ plane
    position.x = cos(orbit_angle) * orbit_radius
    position.z = sin(orbit_angle) * orbit_radius
```

This moves the planet itself. A cleaner approach (used in the full project below) is to rotate a parent pivot node — the planet doesn't move, the pivot does, and the planet just stays at a fixed offset from the pivot. That's the classic "orbit pivot" pattern.

### _physics_process — When to Use It Instead

There's a second lifecycle function: `_physics_process(delta)`. It runs at a fixed rate (default 60Hz) regardless of rendering frame rate, and it's where you should put physics-related code — collision checks, force application, anything involving physics bodies.

For this module, `_process` is sufficient for everything we're doing. The orbits are kinematic (position-driven), not physics-driven.

---

## 9. Input and Click Interaction

### Two Approaches to Input

**Polling** — Check if a key/button is currently held down. Do this in `_process`.

```gdscript
func _process(delta: float) -> void:
    if Input.is_action_pressed("ui_accept"):
        print("Space or Enter is held down")
    if Input.is_action_pressed("ui_left"):
        position.x -= 5.0 * delta
```

**Events** — React to a specific moment: a key being pressed or released, a mouse click. Do this in `_input` or via signals.

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_SPACE:
            print("Space pressed!")
```

For this module, clicking on 3D objects is the main interaction. That requires the event approach with signals.

### Clicking 3D Objects — Why MeshInstance3D Isn't Enough

You can't click a `MeshInstance3D` directly. Godot doesn't do automatic raycasting against rendered meshes for input events — that would be expensive for complex scenes. Instead, you add a **physics body with collision shape** to the node. The physics system then detects when a ray (from mouse click) intersects the collision shape, and fires an `input_event` signal.

The setup:
1. Add `StaticBody3D` as a child of your `MeshInstance3D`
2. Add `CollisionShape3D` as a child of the `StaticBody3D`
3. Set the CollisionShape3D's shape to a `SphereShape3D` (matching your sphere mesh)
4. Connect the `input_event` signal from the `StaticBody3D` to your script

### Step by Step: Adding Clickability

In the Scene Tree, with `Sun` selected:
1. Add child: `StaticBody3D`
2. Select the `StaticBody3D`, add child: `CollisionShape3D`
3. In the inspector for `CollisionShape3D`, set **Shape** > New SphereShape3D
4. Set the sphere shape's radius to match your mesh radius (1.0)

Now connect the signal: select `StaticBody3D`, go to the **Node** panel (tab next to Inspector on the right side). Find `input_event`. Double-click it. A dialog appears asking where to connect the signal. Select the root `SolarSystem` node or the `Sun` node — wherever you want the handler. Click **Connect**.

Godot generates a function stub in your script:

```gdscript
func _on_static_body_3d_input_event(
    camera: Node,
    event: InputEvent,
    event_position: Vector3,
    normal: Vector3,
    shape_idx: int
) -> void:
    pass
```

Fill it in:

```gdscript
func _on_static_body_3d_input_event(
    camera: Node,
    event: InputEvent,
    event_position: Vector3,
    normal: Vector3,
    shape_idx: int
) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            print("Clicked the sun at: ", event_position)
```

`event is InputEventMouseButton` checks the type. `event.pressed` is true on button-down (false on button-up). `event.button_index` distinguishes left/right/middle.

### Keyboard Input Polling

For game controls (move, speed up, pause), polling in `_process` is the right approach:

```gdscript
func _process(delta: float) -> void:
    if Input.is_action_pressed("ui_accept"):
        time_scale = 5.0   # Fast forward while held
    else:
        time_scale = 1.0

    if Input.is_action_just_pressed("ui_cancel"):
        # ui_cancel = Escape key by default
        get_tree().quit()
```

`is_action_pressed` — true every frame the key is held.
`is_action_just_pressed` — true only on the first frame the key goes down.
`is_action_just_released` — true only on the frame the key comes up.

Default action mappings like `ui_accept` (Space/Enter) and `ui_left/right/up/down` (arrow keys/WASD) are configured in **Project > Project Settings > Input Map**. You can add your own actions there and bind any key/mouse button/gamepad button to them.

---

## 10. Scene Organization

### Best Practices

**One root node per scene.** Every `.tscn` file should have exactly one root node. Name it after what the scene is: `Planet`, `OrbitPivot`, `SolarSystem`. This root node is what gets instanced when you load the scene.

**Node names: PascalCase.** Godot convention is PascalCase for node names: `Sun`, `EarthOrbit`, `MainCamera`. This makes `$Sun` and `$EarthOrbit` readable in code.

**Group with empty Node3D.** If you have several related nodes (all the orbit pivots, all the UI elements), put them under an empty `Node3D` as a logical container. Name it `Orbits`, `Planets`, `UI`.

**Scripts: snake_case filenames.** `sun.gd`, `planet.gd`, `orbit_pivot.gd`. Matches Godot's convention and GDScript's style.

### Saving Scenes as .tscn Files

When you have a node hierarchy you want to reuse, save it as its own scene file. Right-click any node in the Scene Tree > **Save Branch as Scene**. Give it a name. It becomes a `.tscn` file in your FileSystem.

Now that node is a **scene instance** — a reference to another scene. It shows up in the Scene Tree with a clapperboard icon. Double-click the icon to open the sub-scene and edit it independently.

Scene separation matters for planets: instead of building all four planets directly in the main scene, build one `Planet` scene, then drag it from the FileSystem into the main scene four times. Tweak each instance's `@export` variables to give each one a different color, orbit speed, and name.

### Main Scene vs Sub-Scenes

```
solar-system-toy/
├── main.tscn                  # The main scene — run with F5
├── scenes/
│   ├── sun.tscn               # Sun + light, reusable
│   └── planet.tscn            # One planet template — instanced multiple times
└── scripts/
    ├── sun.gd
    └── planet.gd
```

`main.tscn` is the entry point. Set it as the main scene in **Project > Project Settings > Application > Run > Main Scene**.

`planet.tscn` is the reusable template. Every orbit in the main scene contains an instance of `planet.tscn` with different `@export` values.

### Instancing Scenes

To add an instance of `planet.tscn` into your main scene: drag it from the FileSystem dock into the Scene Tree. Or: in the Scene Tree, right-click > **Instantiate Child Scene**, find your file.

Each instance is independent. Editing `planet.tscn` affects all instances (shared base). But `@export` values on each instance are stored in `main.tscn` and override the defaults — so each planet can have its own color and orbit speed without modifying the shared template.

---

## 11. Code Walkthrough: Solar System Toy

Let's build the complete project. Every script, every node.

### Project Structure

```
solar-system-toy/
├── project.godot
├── main.tscn              # Root scene: SolarSystem + Camera + Pivots
├── scenes/
│   ├── sun.tscn           # Sun node with script + OmniLight3D
│   └── planet.tscn        # Planet: MeshInstance3D + StaticBody3D + CollisionShape3D + Label3D
└── scripts/
    ├── sun.gd
    ├── planet.gd
    └── orbit_pivot.gd
```

### Step 1: The Sun Scene

Create a new scene. Add a `MeshInstance3D` as root, name it `Sun`. Set its Mesh to a new SphereMesh, radius 1.5.

Add a child `OmniLight3D`, name it `SunLight`. Set position to (0, 0, 0). In the inspector:
- **Light > Color**: warm white — `Color(1.0, 0.95, 0.8)`
- **Light > Energy**: 3.0
- **OmniLight3D > Range**: 60.0

Right-click the `Sun` root node > Attach Script > save as `scripts/sun.gd`:

```gdscript
# scripts/sun.gd
extends MeshInstance3D

@export var rotation_speed: float = 0.3
@export var sun_color: Color = Color(1.0, 0.9, 0.2)
@export var emission_energy: float = 3.0

func _ready() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = sun_color
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.5, 0.0)
    mat.emission_energy_multiplier = emission_energy
    mesh_surface_set_material(0, mat)

func _process(delta: float) -> void:
    rotate_y(rotation_speed * delta)
```

Save the scene as `scenes/sun.tscn`.

### Step 2: The Planet Scene

Create a new scene. Add a `MeshInstance3D` as root, name it `Planet`. Set Mesh to a new SphereMesh, radius 0.5.

Add children:
- `StaticBody3D` (child of Planet) — for click detection
  - `CollisionShape3D` (child of StaticBody3D) — set Shape to New SphereShape3D, radius 0.5
- `Label3D` (child of Planet) — for the name display, name it `NameLabel`
  - In inspector: set Text to "Planet", set Billboard to Enabled, set Modulate alpha to 0 (hidden by default)
  - Set position Y to 1.2 (above the sphere)

Connect the `input_event` signal from `StaticBody3D` to the `Planet` node. Right-click the `Planet` root > Attach Script > `scripts/planet.gd`:

```gdscript
# scripts/planet.gd
extends MeshInstance3D

@export var planet_name: String = "Planet"
@export var planet_color: Color = Color.CORNFLOWER_BLUE
@export var self_rotation_speed: float = 1.0

@onready var name_label: Label3D = $NameLabel

var is_selected: bool = false

func _ready() -> void:
    # Create a unique material for this instance
    var mat := StandardMaterial3D.new()
    mat.albedo_color = planet_color
    mat.roughness = 0.8
    mat.metallic = 0.0
    mesh_surface_set_material(0, mat)

    # Set the label text but keep it hidden
    name_label.text = planet_name
    name_label.modulate.a = 0.0

func _process(delta: float) -> void:
    # Self-rotation (spin on own axis)
    rotate_y(self_rotation_speed * delta)

func _on_static_body_3d_input_event(
    _camera: Node,
    event: InputEvent,
    _event_position: Vector3,
    _normal: Vector3,
    _shape_idx: int
) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            is_selected = !is_selected
            # Show or hide the name label
            name_label.modulate.a = 1.0 if is_selected else 0.0
            print("Clicked: ", planet_name, " | Selected: ", is_selected)
```

Save as `scenes/planet.tscn`.

### Step 3: The Orbit Pivot Script

The orbit pivot is the key pattern. An empty `Node3D` positioned at the origin, rotating in `_process`. The planet lives as a child at an offset — as the pivot rotates, the planet orbits.

Create `scripts/orbit_pivot.gd` (you'll attach this to `Node3D` nodes in the main scene):

```gdscript
# scripts/orbit_pivot.gd
extends Node3D

@export var orbit_speed: float = 1.0    # radians per second

func _process(delta: float) -> void:
    rotate_y(orbit_speed * delta)
```

That's the entire orbit pivot script. The child planet's offset from the pivot determines the orbit radius.

### Step 4: The Main Scene

Create a new scene. Add a `Node3D` as root, name it `SolarSystem`.

Add children:
- `WorldEnvironment` — set up the dark space sky as described in section 7
- `DirectionalLight3D` — name `SunLight`, energy 0.3 (dim fill light)
- Instance `scenes/sun.tscn` — drag from FileSystem, it becomes a child node
- Four `Node3D` nodes — name them `MercuryOrbit`, `VenusOrbit`, `EarthOrbit`, `MarsOrbit`
  - Attach `scripts/orbit_pivot.gd` to each
  - Inside each orbit node, instance `scenes/planet.tscn`
  - Position each planet **away from the pivot** — this is the orbit radius
- `Camera3D` — name it `MainCamera`, position (0, 15, 20), rotation X = -35

### Step 5: Configure the Orbits

Select `MercuryOrbit` in the Scene Tree. In the Inspector, the `orbit_speed` export shows up. Set:
- MercuryOrbit: orbit_speed = 2.0
- VenusOrbit: orbit_speed = 1.3
- EarthOrbit: orbit_speed = 0.9
- MarsOrbit: orbit_speed = 0.6

Select each `Planet` instance inside each orbit, set its **transform position** to move it away from the pivot (orbit radius):
- Mercury planet: Position X = 4.0
- Venus planet: Position X = 6.5
- Earth planet: Position X = 9.0
- Mars planet: Position X = 12.0

Select each `Planet` instance and set its `@export` variables:
- Mercury: planet_name = "Mercury", planet_color = `Color(0.7, 0.7, 0.7)`, self_rotation_speed = 0.5
- Venus: planet_name = "Venus", planet_color = `Color(0.9, 0.8, 0.5)`, self_rotation_speed = 0.2
- Earth: planet_name = "Earth", planet_color = `Color(0.2, 0.5, 1.0)`, self_rotation_speed = 1.2
- Mars: planet_name = "Mars", planet_color = `Color(0.8, 0.3, 0.2)`, self_rotation_speed = 1.0

### Step 6: Run It

Press F5. Set `main.tscn` as the main scene when prompted. You should see:
- A glowing yellow-orange sun at the center
- Four planets orbiting at different speeds and distances
- Click any planet — its name label appears above it
- The viewport is navigable in the editor (middle-mouse to orbit, scroll to zoom)

The full project is about 50 lines of GDScript across three files. That's the Godot scene system working for you — structure lives in the scene tree, behavior lives in small focused scripts.

### Full Script Listing

For reference, all three scripts together:

```gdscript
# scripts/sun.gd
extends MeshInstance3D

@export var rotation_speed: float = 0.3
@export var sun_color: Color = Color(1.0, 0.9, 0.2)
@export var emission_energy: float = 3.0

func _ready() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = sun_color
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.5, 0.0)
    mat.emission_energy_multiplier = emission_energy
    mesh_surface_set_material(0, mat)

func _process(delta: float) -> void:
    rotate_y(rotation_speed * delta)
```

```gdscript
# scripts/planet.gd
extends MeshInstance3D

@export var planet_name: String = "Planet"
@export var planet_color: Color = Color.CORNFLOWER_BLUE
@export var self_rotation_speed: float = 1.0

@onready var name_label: Label3D = $NameLabel

var is_selected: bool = false

func _ready() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = planet_color
    mat.roughness = 0.8
    mat.metallic = 0.0
    mesh_surface_set_material(0, mat)
    name_label.text = planet_name
    name_label.modulate.a = 0.0

func _process(delta: float) -> void:
    rotate_y(self_rotation_speed * delta)

func _on_static_body_3d_input_event(
    _camera: Node,
    event: InputEvent,
    _event_position: Vector3,
    _normal: Vector3,
    _shape_idx: int
) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            is_selected = !is_selected
            name_label.modulate.a = 1.0 if is_selected else 0.0
            print("Clicked: ", planet_name)
```

```gdscript
# scripts/orbit_pivot.gd
extends Node3D

@export var orbit_speed: float = 1.0

func _process(delta: float) -> void:
    rotate_y(orbit_speed * delta)
```

---

## 2D Bridge: Your First 2D Scene

> **Context shift.** Everything above uses 3D nodes. This section covers the 2D equivalents — same engine, same patterns, different coordinate system. The running example is a top-down action RPG (think Zelda meets Vampire Survivors). Each module's 2D bridge adds a new layer to the same project.

### 3D to 2D: What Changes, What Stays

The engine fundamentals don't change. `_ready()`, `_process(delta)`, `@export`, signals, the scene tree — all identical. Only the node types and coordinate system differ.

| 3D Concept | 2D Equivalent | Notes |
|---|---|---|
| `Node3D` | `Node2D` | Base for all 2D objects |
| `MeshInstance3D` | `Sprite2D` | Shows a texture instead of a mesh |
| `Camera3D` | `Camera2D` | Much simpler — no FOV, just zoom |
| `DirectionalLight3D` | `DirectionalLight2D` | Works with normal maps |
| `OmniLight3D` | `PointLight2D` | Circular 2D light |
| `Vector3` | `Vector2` | `x` and `y` only, no `z` |
| `position.x / .z` | `position.x / .y` | Y is the depth axis in top-down |
| `rotate_y()` | `rotation` (float) | Rotation is a single angle in 2D |
| `_process(delta)` | `_process(delta)` | **Identical** |
| `@export` | `@export` | **Identical** |

**The biggest gotcha:** In 2D, the Y-axis points **down**. The origin (0, 0) is the top-left of the screen by default. A `position.y` of 500 means 500 pixels below the top. This flips from what you might expect if you're used to math coordinates.

### The 2D Viewport

In the top toolbar, there are two tabs: **2D** and **3D**. Click **2D** to switch the viewport. You'll see a flat canvas with a blue rectangle showing the game window bounds (set in Project Settings > Display > Window).

The viewport shows pixel coordinates. The center of the screen at 1280×720 is at position `(640, 360)`.

### Scene Tree for a Top-Down Room

Here's the equivalent of the Module 0 solar system, but as a top-down RPG room:

```
Room (Node2D)                  ← scene root
├── Background (Sprite2D)      ← room floor texture
├── Player (Node2D)            ← player container
│   ├── Sprite2D               ← character art
│   └── Camera2D               ← follows the player
└── Walls (StaticBody2D)       ← room boundaries (preview of Module 4)
    └── CollisionShape2D
```

### Setting Up a Sprite2D

1. Create a new scene. Set the root node to **Node2D** and name it `Room`.
2. Add a **Sprite2D** child. In the Inspector, click the **Texture** property and drag a PNG from the FileSystem dock.
3. The sprite appears centered at the origin. Move it with the Move tool (W) or set `position` directly.

**Import settings matter.** When you import a PNG, Godot uses Linear filtering by default — fine for HD art, but pixel art will look blurry. For pixel art: select the texture in the FileSystem dock, go to the **Import** tab, set **Filter** to `Nearest`, click **Reimport**.

| Art Style | Filter Setting | Mipmaps |
|---|---|---|
| Pixel art | Nearest | Off |
| HD / painted | Linear | On |

For a whole project, set the default in **Project Settings > Rendering > Textures > Default Texture Filter**.

### Camera2D Basics

Add a **Camera2D** as a child of your Player node. It automatically follows the parent. Key properties:

```
Camera2D
├── Position Smoothing > Enabled: true    ← smooth follow
├── Position Smoothing > Speed: 8.0       ← how fast it catches up
├── Zoom: Vector2(2, 2)                   ← zoom in (pixel art looks better zoomed)
└── Limit > Left/Right/Top/Bottom         ← clamp camera to room bounds
```

Compare to `Camera3D` from the 3D section — Camera2D is dramatically simpler. No FOV, no projection modes, no SpringArm. Just position smoothing and bounds.

### Moving a Sprite with `_process(delta)`

This mirrors the 3D section's approach — using `_process` directly on the node before introducing physics bodies (that comes in Module 4's bridge). Attach this to the Player's `Node2D`:

```gdscript
# scripts/player_simple.gd
extends Node2D

@export var speed: float = 200.0

func _process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    position += input_dir * speed * delta
```

Notice `speed` is `200.0` — much larger than the 3D equivalent (which used ~5 units/sec). In 2D, the coordinate system is in **pixels**, not meters. A typical room might be 1280×720 pixels. Moving 200 pixels per second feels natural; moving 5 pixels per second would be imperceptibly slow.

The `Input.get_vector()` call is identical to the 3D version — it returns a normalized `Vector2` based on your four directional actions.

### Try It: A Character in a Room

1. Create a `Node2D` scene named `Room`
2. Add a `Sprite2D` child — assign any PNG as texture (grab one from Kenney: [kenney.nl/assets](https://kenney.nl/assets))
3. Add a `Node2D` child named `Player`
4. Move the player script above onto `Player`
5. Add a `Camera2D` as a child of `Player`, enable Position Smoothing
6. Run with F5

You have a moving character in a 2D scene. This is the 2D equivalent of the solar system toy — your first running 2D scene. The next bridge section (Module 3) will replace the plain background with a proper tiled dungeon room.

---

## API Quick Reference

### Node3D

| Method / Property | Description | Example |
|-------------------|-------------|---------|
| `rotate_y(angle)` | Rotate around world Y axis by radians | `rotate_y(1.0 * delta)` |
| `rotate_object_local(axis, angle)` | Rotate in local space | `rotate_object_local(Vector3.UP, delta)` |
| `position` | Vector3 world position | `position = Vector3(5, 0, 0)` |
| `position.x`, `.y`, `.z` | Individual position components | `position.x = cos(angle) * radius` |
| `translate(offset)` | Move relative to current position | `translate(Vector3.FORWARD * speed * delta)` |
| `global_position` | World-space position (vs local) | `var dist = global_position.distance_to(other.global_position)` |

### MeshInstance3D

| Method / Property | Description | Example |
|-------------------|-------------|---------|
| `mesh` | The Mesh resource (SphereMesh, BoxMesh, etc.) | `mesh = SphereMesh.new()` |
| `mesh_surface_set_material(surface, mat)` | Assign a material to a mesh surface | `mesh_surface_set_material(0, mat)` |
| `get_surface_override_material(surface)` | Get the current material | `var m = get_surface_override_material(0)` |

### StandardMaterial3D

| Property | Type | Description |
|----------|------|-------------|
| `albedo_color` | Color | Base diffuse color |
| `roughness` | float (0–1) | 0 = mirror, 1 = matte |
| `metallic` | float (0–1) | 0 = dielectric, 1 = metal |
| `emission_enabled` | bool | Enable self-illumination |
| `emission` | Color | Glow color |
| `emission_energy_multiplier` | float | Glow brightness |

### GDScript Essentials

| Keyword / Function | Description | Example |
|-------------------|-------------|---------|
| `@export` | Expose variable to Inspector | `@export var speed: float = 2.0` |
| `@onready` | Assign when node enters scene tree | `@onready var label: Label3D = $Label3D` |
| `$NodeName` | Get child node by name | `$Camera.position = Vector3(0, 5, 10)` |
| `_ready()` | Called once on node ready | `func _ready() -> void:` |
| `_process(delta)` | Called every render frame | `func _process(delta: float) -> void:` |
| `print()` | Debug output to Output panel | `print("pos: ", position)` |
| `deg_to_rad(deg)` | Convert degrees to radians | `rotate_y(deg_to_rad(90) * delta)` |

### Input

| Function | Description | Example |
|----------|-------------|---------|
| `Input.is_action_pressed(action)` | True while action held | `Input.is_action_pressed("ui_accept")` |
| `Input.is_action_just_pressed(action)` | True on first frame of press | `Input.is_action_just_pressed("ui_left")` |
| `Input.is_action_just_released(action)` | True on first frame of release | `Input.is_action_just_released("jump")` |

### Light Nodes

| Node | Use Case | Key Properties |
|------|----------|----------------|
| `DirectionalLight3D` | Sun / distant light (parallel rays) | `energy`, `color`, `shadow_enabled` |
| `OmniLight3D` | Point light (bulb, fire, magic glow) | `energy`, `omni_range`, `color` |
| `SpotLight3D` | Flashlight, stage light | `energy`, `spot_angle`, `spot_angle_attenuation` |

### Camera3D

| Property | Description | Example |
|----------|-------------|---------|
| `fov` | Field of view in degrees | `fov = 60.0` |
| `near` | Near clip plane distance | `near = 0.1` |
| `far` | Far clip plane distance | `far = 1000.0` |
| `make_current()` | Set as active camera | `$Camera3D.make_current()` |

---

## Common Pitfalls

### 1. Black Screen — Forgot Camera3D

You run your scene and get a black window. No errors. Just black.

```
# WRONG — no Camera3D in the scene
SolarSystem (Node3D)
└── Sun (MeshInstance3D)

# Game window: completely black
```

```
# RIGHT — Camera3D positioned to see the scene
SolarSystem (Node3D)
├── Sun (MeshInstance3D)
└── MainCamera (Camera3D)  ← position it so the sphere is in view
```

Every 3D scene needs exactly one active `Camera3D`. Position it so your content is within the field of view. Press the **Preview** button in the editor viewport to see what the camera currently sees before running.

### 2. Not Using Delta — Speed Depends on FPS

```gdscript
# WRONG — rotates 0.1 rad per frame
# At 60fps: 6 rad/sec. At 144fps: 14.4 rad/sec. Broken.
func _process(delta: float) -> void:
    rotate_y(0.1)
```

```gdscript
# RIGHT — rotates 2.0 rad per second, always
func _process(delta: float) -> void:
    rotate_y(2.0 * delta)
```

Always multiply continuous movement, rotation, and scaling by `delta`. Without it, your game behaves differently on different hardware.

### 3. Trying to Click a MeshInstance3D Directly

```
# WRONG — MeshInstance3D alone has no collision, gets no input events
Planet (MeshInstance3D)
└── (script with input handler that never fires)
```

```
# RIGHT — StaticBody3D + CollisionShape3D enable click detection
Planet (MeshInstance3D)
└── StaticBody3D           ← physics body, receives input_event signal
    └── CollisionShape3D   ← defines the clickable area
        └── Shape: SphereShape3D (match your mesh radius)
```

The `input_event` signal on `StaticBody3D` only fires if there is a `CollisionShape3D` child with a shape set. Forgetting to set the shape on `CollisionShape3D` (leaving it null) means clicks still don't register.

### 4. Setting Material on the Mesh Resource (Affects All Instances)

```gdscript
# WRONG — modifies the SphereMesh resource shared by all MeshInstance3Ds
# that use this same SphereMesh. Affects all instances.
func _ready() -> void:
    mesh.surface_get_material(0).albedo_color = planet_color
```

```gdscript
# RIGHT — creates a new material instance unique to this node
func _ready() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = planet_color
    mesh_surface_set_material(0, mat)    # Sets override on THIS node only
```

`mesh_surface_set_material(surface, material)` sets a material override on the `MeshInstance3D` node, not on the shared mesh resource. Each node gets its own material, and changing one doesn't affect others.

### 5. Hardcoding Values in Scripts

```gdscript
# WRONG — to test different orbit speeds, you edit the script every time
func _process(delta: float) -> void:
    rotate_y(0.8 * delta)   # Magic number — why 0.8? No idea. Can't change easily.
```

```gdscript
# RIGHT — tweak in the inspector, no code edits required
@export var orbit_speed: float = 0.8

func _process(delta: float) -> void:
    rotate_y(orbit_speed * delta)
```

Use `@export` for any value you might want to adjust while building. Orbit speed, planet color, label text, emission intensity — all of it. This separates configuration from code and makes iteration much faster.

---

## Exercises

### Exercise 1: Add a Moon Orbiting Earth

**Time:** 20–30 minutes

Add a moon that orbits Earth. The moon should orbit Earth, not the sun — so it needs to be nested inside Earth's hierarchy, not the scene root.

The structure:

```
EarthOrbit (Node3D + orbit_pivot.gd, fast orbit speed ~0.9)
└── Earth (Planet scene instance, Position X = 9.0)
    └── MoonOrbit (Node3D + orbit_pivot.gd, fast orbit speed ~4.0)
        └── Moon (MeshInstance3D, small sphere, gray, Position X = 1.5)
```

Hints:
- Add a `Node3D` child inside the Earth `Planet` scene (or directly in the main scene as a child of the Earth instance)
- Attach `orbit_pivot.gd` to it
- Add a `MeshInstance3D` child to the moon orbit node, set a SphereMesh radius of 0.2, offset X = 1.5
- Give the moon orbit node an orbit_speed of about 3.5–5.0 (moons orbit fast relative to the planet)
- Because the moon orbit is parented to Earth, the moon follows Earth through its own orbit automatically

Stretch goal: tilt the moon's orbital plane. Rotate the `MoonOrbit` node's X axis by 15–30 degrees in the inspector. The moon now orbits in a tilted plane relative to Earth.

### Exercise 2: Keyboard Controls for Time Scale

**Time:** 45–60 minutes

Add keyboard controls to speed up and slow down time — all orbits should accelerate or decelerate together.

The challenge: each orbit pivot has its own `orbit_speed` export, set independently. To scale them all, you need either a central signal or a global singleton.

Approach using an Autoload singleton:

1. Create `scripts/time_manager.gd`:

```gdscript
# scripts/time_manager.gd
extends Node

var time_scale: float = 1.0

func _process(_delta: float) -> void:
    if Input.is_action_pressed("ui_page_up"):
        time_scale = min(time_scale + 0.02, 10.0)
    elif Input.is_action_pressed("ui_page_down"):
        time_scale = max(time_scale - 0.02, 0.0)
    if Input.is_action_just_pressed("ui_home"):
        time_scale = 1.0
```

2. Register it as an Autoload: **Project > Project Settings > Autoload** > add `scripts/time_manager.gd`, name `TimeManager`

3. Update `orbit_pivot.gd` to use it:

```gdscript
extends Node3D

@export var orbit_speed: float = 1.0

func _process(delta: float) -> void:
    rotate_y(orbit_speed * TimeManager.time_scale * delta)
```

4. Set up the input actions: **Project > Project Settings > Input Map** > add `ui_page_up` (Page Up key) and `ui_page_down` (Page Down key).

Stretch goal: add a `Label` in a `CanvasLayer` to display the current time scale on screen. Update it in `TimeManager._process`. Show "Paused" when time_scale is 0, "1x", "2x", etc. when running.

### Exercise 3: UI Overlay with Planet Info

**Time:** 60–90 minutes

Add a UI overlay that shows the name and distance of the last clicked planet.

Approach:
1. Add a `CanvasLayer` node to the main scene
2. Add a `Panel` or `Control` node as a child of the CanvasLayer
3. Add a `Label` inside the Panel for the planet info text
4. In `planet.gd`, emit a signal when clicked:

```gdscript
# In planet.gd
signal planet_selected(name: String, position: Vector3)

func _on_static_body_3d_input_event(
    _camera: Node,
    event: InputEvent,
    _event_position: Vector3,
    _normal: Vector3,
    _shape_idx: int
) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            is_selected = !is_selected
            name_label.modulate.a = 1.0 if is_selected else 0.0
            if is_selected:
                planet_selected.emit(planet_name, global_position)
```

5. In the main scene script or a UI controller script, connect the `planet_selected` signal:

```gdscript
# In main scene script or a dedicated ui_controller.gd
@onready var info_label: Label = $CanvasLayer/Panel/InfoLabel

func _ready() -> void:
    # Connect all planet signals at startup
    for orbit in get_node("Orbits").get_children():
        var planet = orbit.get_child(0)  # Assumes planet is first child
        planet.planet_selected.connect(_on_planet_selected)

func _on_planet_selected(name: String, pos: Vector3) -> void:
    var dist = pos.length()  # Distance from origin (sun)
    info_label.text = name + "\nDistance from Sun: " + str(snappedf(dist, 0.1)) + " AU"
```

Stretch goal: add a "follow camera" that smoothly moves `Camera3D` to focus on the clicked planet. Use `lerp()` in `_process` to interpolate the camera position toward the target:

```gdscript
var target_position: Vector3 = Vector3(0, 15, 20)

func _process(delta: float) -> void:
    camera.global_position = lerp(camera.global_position, target_position, 5.0 * delta)

func _on_planet_selected(name: String, pos: Vector3) -> void:
    target_position = pos + Vector3(0, 3, 6)  # Slightly above and behind
```

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [Godot docs — Your first 3D game](https://docs.godotengine.org/en/stable/getting_started/first_3d_game/) | Tutorial | Official step-by-step 3D game tutorial. Covers movement, collision, and scene structure. |
| [GDScript basics](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html) | Reference | Language reference you'll keep open. Covers all syntax, types, and built-in functions. |
| [Godot Node3D class](https://docs.godotengine.org/en/stable/classes/class_node3d.html) | API Reference | Every method and property for 3D nodes. Bookmark it. |
| [Kenney starter kits](https://kenney.nl/assets) | Assets | Free, CC0-licensed game assets. Skip asset creation entirely for prototypes. |
| [GDQuest Learn GDScript](https://gdquest.github.io/learn-gdscript/) | Interactive | Browser-based GDScript exercises. Good for solidifying syntax if you're new to it. |
| [Godot recipes](https://kidscancode.org/godot_recipes/) | Tutorial | Practical Godot patterns for common problems. Well-organized, easy to search. |

---

## Key Takeaways

1. **Godot is a single executable** — no installer, no account, no package manager for the engine itself. Unzip, double-click, build. The friction from idea to running game is nearly zero.

2. **Everything is a node. Nodes live in a scene tree. Scenes save as .tscn files.** This is the entire organizational system. Learn it deeply — it's what makes Godot feel different from Unity and Unreal.

3. **`_process(delta)` is your game loop.** It runs every frame. Multiply movement by `delta` for frame-rate independence. Everything that changes continuously lives here.

4. **`@export` exposes variables to the inspector.** Use it for any value you might want to tweak — orbit speed, planet color, emission intensity. Iterate without touching code.

5. **3D objects need geometry (MeshInstance3D), collision (StaticBody3D + CollisionShape3D), and a camera (Camera3D) to be visible and interactive.** Miss any of these and something silently doesn't work: no camera = black screen, no collision = clicks don't register.

6. **Materials control appearance. StandardMaterial3D handles albedo, emission, roughness, metallic.** Create materials in code with `StandardMaterial3D.new()` and assign with `mesh_surface_set_material(0, mat)` to avoid accidental sharing between instances.

7. **Scenes are composable — build small pieces, combine them into larger scenes.** The planet scene is built once, instanced four times with different `@export` values. The orbit pivot is a three-line script that gives any child node circular motion. Small pieces, composed together.

---

## What's Next?

You have a working Godot 3D project with animation, interaction, and a scene hierarchy. Now it's time to deeply understand the language and the engine's lifecycle.

**[Module 1: GDScript & the Engine Lifecycle](module-01-gdscript-engine-lifecycle.md)** covers GDScript in depth — static typing, inner classes, `match` statements, signals as a first-class pattern, and how the engine's lifecycle (scene tree events, deferred calls, `await`, groups) gives you powerful tools for coordinating nodes. You'll build a more complex version of the solar system that responds to a day/night cycle and uses signals to propagate state changes across the scene tree.

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
