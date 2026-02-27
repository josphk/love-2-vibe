# Module 1: GDScript & the Engine Lifecycle

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 0: Setup & First Scene](module-00-setup-first-scene.md)

---

## Overview

Module 0 got you running. You typed some GDScript, rotated a sphere, clicked things. But you were copying patterns without deeply understanding the language or when and why things happen in what order. This module fixes that.

GDScript is not Python. It looks like Python — the indentation, the colons, the `for x in list` syntax — but it has static typing, export annotations, engine-specific lifecycle functions, and a signal system that replaces callbacks and events. Python is a general-purpose language bolted to many game engines. GDScript is built specifically for Godot, and every feature in it exists to make game development cleaner. Once you understand the language deeply, instead of just copying snippets, you'll stop fighting the engine and start flowing with it.

By the end of this module you'll have internalized the language itself, the full node lifecycle, the critical difference between `_process` and `_physics_process`, and you'll have built a character controller that uses both correctly. This is the foundation everything else sits on — signals, scene architecture, physics, UI, all of it assumes you understand what's in this module.

---

## 1. GDScript Types and Static Typing

GDScript is dynamically typed by default, meaning you can write `var speed = 2.0` and the engine figures out the type at runtime. This works, but it costs you: no autocomplete on the variable, no parse-time error checking, slightly slower execution. For anything beyond a quick prototype, use static typing everywhere.

### The Three Ways to Declare a Variable

```gdscript
# Untyped — works, but you lose autocomplete and error checking
var speed = 2.0

# Explicitly typed — annotates the type, catches mismatches at parse time
var speed: float = 2.0

# Type inference with := — typed, but less verbose (engine infers float from 2.0)
var speed := 2.0
```

The `:=` operator (walrus-style inference) is your friend when the type is obvious from the right-hand side. Use explicit type annotations when the type isn't obvious, or when you want the annotation as documentation.

### Built-in Types Reference

Godot's type system is richer than Python's. These are the types you'll use constantly:

| Type | Description | Example |
|------|-------------|---------|
| `int` | 64-bit integer | `var score: int = 0` |
| `float` | 64-bit float | `var speed: float = 5.0` |
| `bool` | True/false | `var is_grounded: bool = false` |
| `String` | UTF-32 string | `var name: String = "Hero"` |
| `StringName` | Interned string (fast comparison) | `var action: StringName = &"jump"` |
| `Vector2` | 2D vector (x, y) | `var pos: Vector2 = Vector2(10, 5)` |
| `Vector2i` | Integer 2D vector | `var tile: Vector2i = Vector2i(3, 4)` |
| `Vector3` | 3D vector (x, y, z) | `var pos: Vector3 = Vector3.ZERO` |
| `Vector3i` | Integer 3D vector | `var chunk: Vector3i = Vector3i(0, 0, 0)` |
| `Color` | RGBA color | `var tint: Color = Color.RED` |
| `Rect2` | 2D rectangle | `var bounds: Rect2 = Rect2(0, 0, 100, 50)` |
| `Transform3D` | 3D position + rotation + scale | `var xform: Transform3D` |
| `Basis` | 3x3 rotation/scale matrix | `var rot: Basis` |
| `Array` | Dynamic untyped array | `var items: Array = []` |
| `Dictionary` | Hash map | `var data: Dictionary = {}` |
| `NodePath` | Path to a node | `var path: NodePath = ^"../Player"` |

### Typed Arrays

Untyped arrays accept anything. Typed arrays enforce element type — you get autocomplete on elements and runtime type errors if you insert the wrong type:

```gdscript
# Untyped — anything goes, no autocomplete on elements
var items: Array = []

# Typed — enemies must be Enemy nodes, you get Enemy autocomplete
var enemies: Array[Enemy] = []

# Typed with built-in type
var scores: Array[int] = []
var names: Array[String] = []
```

### PackedArrays

For large numeric arrays (especially in performance-sensitive code), use `PackedArray` variants. These store data in a contiguous memory block instead of as Godot Variant objects, making iteration and bulk operations significantly faster:

```gdscript
var positions: PackedVector3Array = PackedVector3Array()
var indices: PackedInt32Array = PackedInt32Array()
var floats: PackedFloat32Array = PackedFloat32Array()
var bytes: PackedByteArray = PackedByteArray()

# Useful for procedural geometry, pathfinding grids, serialization
```

### Null Safety — There Isn't Any

Godot does not have Kotlin-style null safety or TypeScript's strict null checks. A typed variable can still be null at runtime. Be aware:

```gdscript
var enemy: Enemy = null  # valid — typed but null
enemy.take_damage(10)    # runtime error: invalid call on null

# Always guard nullable references
if enemy != null:
    enemy.take_damage(10)

# Or with the null-safe operator (Godot 4.2+)
enemy?.take_damage(10)  # no-op if enemy is null
```

The `?.` null-safe operator was added in Godot 4.2. Use it when calling methods on things that might be null. It does not work for property access yet — `enemy?.health` is not valid syntax as of Godot 4.3.

---

## 2. Functions, Return Types, and Lambdas

### Function Declaration

```gdscript
func function_name(param1: Type, param2: Type) -> ReturnType:
    # body
    return value
```

Return type annotation with `->` is optional but strongly recommended. Without it, the editor can't help you when you call the function.

```gdscript
# No return type — editor can't help callers
func calculate_damage(base, multiplier):
    return base * multiplier

# With types — callers know exactly what they're getting
func calculate_damage(base: float, multiplier: float) -> float:
    return base * multiplier

# Void functions
func reset_health() -> void:
    health = max_health

# No return value needed — just omit the arrow
func fire_weapon() -> void:
    muzzle_flash.visible = true
    bullet_spawner.spawn()
```

### Default Parameters

Parameters can have default values, making them optional at the call site:

```gdscript
func calculate_damage(base: float, multiplier: float = 1.0, crit: bool = false) -> float:
    var damage := base * multiplier
    if crit:
        damage *= 2.0
    return damage

# All three ways to call it
calculate_damage(10.0)              # base=10, multiplier=1.0, crit=false
calculate_damage(10.0, 1.5)         # base=10, multiplier=1.5, crit=false
calculate_damage(10.0, 1.5, true)   # base=10, multiplier=1.5, crit=true
```

### Static Functions

Static functions belong to the class, not an instance. Useful for utility functions and factory methods:

```gdscript
class_name MathUtils

static func lerp_clamped(a: float, b: float, t: float) -> float:
    return lerp(a, b, clamp(t, 0.0, 1.0))

static func random_point_in_circle(radius: float) -> Vector2:
    var angle := randf_range(0.0, TAU)
    var r := sqrt(randf()) * radius
    return Vector2(cos(angle), sin(angle)) * r
```

Call static functions on the class name: `MathUtils.lerp_clamped(0.0, 1.0, 0.5)`.

### Lambdas (Callables)

GDScript supports lambda functions — anonymous functions assigned to variables. The type is `Callable`:

```gdscript
# Basic lambda
var double := func(x: float) -> float: return x * 2.0

# Multi-line lambda
var calculate := func(a: float, b: float) -> float:
    var result := a * b
    return result + 1.0

# Call it
var result := double.call(5.0)  # returns 10.0
```

Lambdas are especially useful as callbacks and with array methods:

```gdscript
var enemies: Array[Enemy] = get_all_enemies()

# Find the nearest enemy
var nearest := enemies.reduce(func(a: Enemy, b: Enemy) -> Enemy:
    var dist_a := position.distance_to(a.position)
    var dist_b := position.distance_to(b.position)
    return a if dist_a < dist_b else b
)

# Filter to alive enemies
var alive := enemies.filter(func(e: Enemy) -> bool: return e.health > 0)
```

### vs Python and JavaScript

If you're coming from Python: GDScript functions look identical but static typing is a first-class feature, not an optional hint. If you're from JavaScript/TypeScript: `func` replaces `function`/`() =>`, return types use `->` instead of `:`, and there's no `async/await` — instead you use `await` on signals (covered in Section 10).

---

## 3. Enums and match

### Defining Enums

Enums give names to integer constants. Without an explicit starting value, they start at 0 and increment:

```gdscript
enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER }
# TITLE = 0, PLAYING = 1, PAUSED = 2, GAME_OVER = 3

# With explicit values
enum Direction { NORTH = 0, EAST = 90, SOUTH = 180, WEST = 270 }

# Using them
var current_state: GameState = GameState.TITLE
var facing: Direction = Direction.NORTH
```

### Named Enums with class_name

Enums defined inside a class with `class_name` are accessible from any script that references the class:

```gdscript
# player_state.gd
class_name PlayerState

enum State { IDLE, WALKING, RUNNING, JUMPING, FALLING, DEAD }
```

```gdscript
# In another script
var state: PlayerState.State = PlayerState.State.IDLE
```

For enums only used within one script, keep them in the script without class_name. For enums shared across many scripts, put them in a dedicated file with class_name.

### The match Statement

`match` is GDScript's `switch` — but better. It's pattern matching with exhaustive coverage warnings and no fall-through:

```gdscript
enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER }
var current_state: GameState = GameState.TITLE

func handle_state() -> void:
    match current_state:
        GameState.TITLE:
            show_title_screen()
        GameState.PLAYING:
            update_game()
        GameState.PAUSED:
            show_pause_menu()
        GameState.GAME_OVER:
            show_game_over()
```

Unlike C's switch, there is no fall-through and no `break` needed. Each arm is independent.

### match with Multiple Values and Wildcards

```gdscript
func describe_health(hp: int) -> String:
    match hp:
        0:
            return "Dead"
        1, 2, 3:
            return "Critical"
        var n when n < 25:
            return "Low"
        var n when n < 75:
            return "Medium"
        _:
            return "Full"
```

The `_` wildcard matches anything not caught above. The `var n when condition` pattern binds the value to a local variable and adds a guard condition. This is more powerful than most switch statements in other languages.

### Practical Game State Example

```gdscript
class_name GameManager
extends Node

enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER }

var state: GameState = GameState.TITLE

func transition_to(new_state: GameState) -> void:
    var old_state := state
    state = new_state

    match new_state:
        GameState.TITLE:
            get_tree().change_scene_to_file("res://scenes/title.tscn")
        GameState.PLAYING:
            if old_state == GameState.PAUSED:
                Engine.time_scale = 1.0
                $PauseMenu.hide()
            else:
                get_tree().change_scene_to_file("res://scenes/game.tscn")
        GameState.PAUSED:
            Engine.time_scale = 0.0
            $PauseMenu.show()
        GameState.GAME_OVER:
            $GameOverScreen.show()
            $GameOverScreen.animate_in()
```

---

## 4. @export Annotations Deep Dive

`@export` is how your scripts expose variables to the Godot editor Inspector. It's the bridge between code and content. Instead of hardcoding numbers in scripts, you define the variable in code and tune it in the inspector without touching code. Designers and your future self both benefit.

### Basic @export

```gdscript
@export var health: int = 100
@export var move_speed: float = 5.0
@export var player_name: String = "Hero"
@export var is_invincible: bool = false
```

Each of these appears as an editable field in the Inspector when the node is selected. Change the value in the inspector, save the scene — the script gets the new value at runtime.

### @export_range

Restricts a number to a range, with an optional step:

```gdscript
# @export_range(min, max) — slider in inspector
@export_range(0, 100) var health: int = 100

# @export_range(min, max, step) — slider with step increments
@export_range(0.0, 20.0, 0.5) var move_speed: float = 5.0

# @export_range with "or_greater" / "or_less" hints — unclamped but suggests range
@export_range(0.0, 100.0, 1.0, "or_greater") var stamina: float = 100.0
```

### @export_enum

Displays a dropdown in the inspector with named string options, stored as an int:

```gdscript
@export_enum("Sword", "Bow", "Staff", "Wand") var weapon_type: int = 0
@export_enum("Easy:0", "Normal:1", "Hard:2", "Nightmare:3") var difficulty: int = 1
```

For proper typed enums in the inspector, use the enum type directly:

```gdscript
enum WeaponType { SWORD, BOW, STAFF, WAND }
@export var weapon: WeaponType = WeaponType.SWORD
```

### @export_file and @export_dir

Adds a file browser button to the inspector:

```gdscript
# Filter to specific file extensions
@export_file("*.tscn") var next_level: String
@export_file("*.png", "*.jpg") var portrait_path: String

# Directory picker
@export_dir var audio_folder: String
```

### @export_multiline

For strings that need a multiline text editor in the inspector:

```gdscript
@export_multiline var dialogue_text: String = ""
@export_multiline var item_description: String = "A powerful weapon forged in ancient fires."
```

### @export_group and @export_subgroup

Groups organize inspector properties into collapsible sections. Essential for scripts with many exported variables:

```gdscript
extends CharacterBody3D

@export_group("Stats")
@export var max_health: int = 100
@export var max_stamina: float = 100.0

@export_group("Combat")
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 2.0

@export_subgroup("Crit System")
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.1
@export var crit_multiplier: float = 2.0

@export_group("Movement")
@export var move_speed: float = 5.0
@export var run_multiplier: float = 1.8
@export var jump_height: float = 2.0
@export var gravity_scale: float = 1.0

@export_group("Visual")
@export var trail_color: Color = Color.CYAN
@export var hit_flash_duration: float = 0.1
```

In the inspector, each `@export_group` creates a collapsible section header. `@export_subgroup` creates a nested section within the current group.

### @export_category

For scripts with a huge number of properties, `@export_category` creates a top-level category separator — a bigger visual break than a group:

```gdscript
@export_category("Character Configuration")
@export_group("Stats")
# ...
@export_category("Audio")
@export var footstep_sounds: Array[AudioStream] = []
```

### Exporting Node References

You can export node references directly:

```gdscript
@export var target: Node3D
@export var weapon_attachment: BoneAttachment3D
@export var health_bar: ProgressBar
```

The inspector shows a drag-and-drop node picker. Drag a node from the scene tree into the slot. This is cleaner than hardcoded paths for optional references.

### Full Example — Enemy Configuration

```gdscript
extends CharacterBody3D
class_name Enemy

@export_category("Enemy Configuration")

@export_group("Identity")
@export var enemy_name: String = "Goblin"
@export_enum("Melee", "Ranged", "Magic") var enemy_type: int = 0
@export_file("*.tscn") var loot_table_scene: String

@export_group("Stats")
@export_range(1, 1000) var max_health: int = 50
@export_range(0.0, 50.0, 0.5) var move_speed: float = 3.0
@export_range(0.0, 100.0, 1.0) var attack_damage: float = 8.0
@export_range(0.1, 5.0, 0.1) var attack_interval: float = 1.5

@export_group("Detection")
@export_range(0.5, 30.0, 0.5) var sight_range: float = 10.0
@export_range(0.5, 10.0, 0.5) var attack_range: float = 2.0
@export var sight_angle: float = 90.0

@export_group("Visual")
@export var hit_color: Color = Color.RED
@export_range(0.05, 0.5, 0.05) var hit_flash_time: float = 0.1
```

---

## 5. @onready and Node References

### The Problem

When GDScript initializes class properties (anything outside a function), the node hasn't been added to the scene tree yet. Trying to reference child nodes at that point returns null:

```gdscript
extends Node3D

# BAD — this runs during object construction, before _ready
# $Label3D is null here. If you try to use it, crash.
var label = $Label3D

func _ready() -> void:
    label.text = "Hello"  # null reference error
```

### @onready Solves This

`@onready` defers the property initialization until `_ready()` runs. By then, the node and all its children are in the scene tree and accessible:

```gdscript
extends Node3D

# GOOD — initializes when _ready is called, not before
@onready var label: Label3D = $Label3D

func _ready() -> void:
    label.text = "Hello"  # works perfectly
```

Think of `@onready var label: Label3D = $Label3D` as shorthand for:

```gdscript
var label: Label3D

func _ready() -> void:
    label = $Label3D
```

It's exactly that, just cleaner.

### Node Reference Patterns

There are four ways to get a node reference:

```gdscript
# 1. $ shorthand — relative path from current node
@onready var sprite: Sprite3D = $Sprite3D
@onready var health_bar: ProgressBar = $UI/HUD/HealthBar

# 2. % unique name — node must be marked with % in the scene tree
# Right-click a node in the scene tree, check "Access as Unique Name"
@onready var health_bar: ProgressBar = %HealthBar
@onready var minimap: SubViewport = %Minimap

# 3. get_node() — explicit, works anywhere
@onready var player: CharacterBody3D = get_node("../Player")
@onready var game_manager: GameManager = get_node("/root/GameManager")

# 4. get_parent() / find_child() / get_children()
@onready var parent_body: RigidBody3D = get_parent() as RigidBody3D
```

### When to Use Each Pattern

**Use `$Path`** for direct children and short paths. Clean and readable.

**Use `%UniqueName`** for nodes you need to reference from multiple scripts or across the scene hierarchy. Mark the node as unique in the scene tree (right-click > "Access as Unique Name"), then reference it with `%`. The path doesn't break if you reorganize the scene hierarchy.

**Use `get_node("../absolute/path")`** when the node is far up the tree or at an absolute path from root. Also needed when the path is dynamic (computed at runtime).

**Avoid** deeply nested `$Parent/Child/Grandchild/Node` paths — they break the moment you reorganize the scene tree. Prefer `%UniqueName` for anything more than one level deep.

### Null Checking Node References

`@onready` guarantees the assignment runs, but it doesn't guarantee the node exists in the scene. If you renamed a node in the editor but forgot to update the script, you get null:

```gdscript
@onready var label: Label3D = $Label3D

func _ready() -> void:
    # Defensive check during development
    if not is_instance_valid(label):
        push_error("Label3D not found — check node path")
        return
    label.text = "Ready"
```

For production code, trust your `@onready` references — if the scene is set up correctly they're valid. For debugging, `push_error` leaves a red message in the Output panel without crashing.

### Getting Typed References

The `as` keyword casts a node to a specific type. If the cast fails, you get null (not a crash). Useful when `get_node()` returns a generic `Node`:

```gdscript
@onready var player: CharacterBody3D = get_node("../Player") as CharacterBody3D
# player is null if the node isn't actually a CharacterBody3D
```

With `$` and `%`, Godot already knows the type from your annotation, so no cast is needed.

---

## 6. The Node Lifecycle

This is the most important section in the module. Understanding when Godot calls your functions — and in what order — determines whether your code works correctly. Every bug that says "my variable is null" or "my node doesn't exist yet" is a lifecycle bug.

### The Full Lifecycle

```
_init()                 — Object constructed. No scene tree access. No $Node refs. Use for data init only.
_enter_tree()           — Node added to the scene tree. Called every time, including re-parenting.
_ready()                — Node AND all children are in tree and ready. Called once per scene entry.
_process(delta)         — Called every rendered frame. Variable timestep.
_physics_process(delta) — Called every physics tick. Fixed timestep (default 60/sec).
_input(event)           — Raw input event received. Called for ALL input.
_unhandled_input(event) — Input not consumed by UI controls or _input. Use for gameplay.
_exit_tree()            — Node removed from tree. Do cleanup here.
_notification(what)     — Low-level engine notifications (used rarely).
```

### Lifecycle Order Visualization

To truly understand this, create a new scene with a parent node and a child node, and attach this script to each:

```gdscript
# lifecycle_logger.gd
extends Node3D

@export var node_label: String = "Node"

func _init() -> void:
    print("[%s] _init — time: %f" % [node_label, Time.get_ticks_msec() / 1000.0])

func _enter_tree() -> void:
    print("[%s] _enter_tree — time: %f" % [node_label, Time.get_ticks_msec() / 1000.0])

func _ready() -> void:
    print("[%s] _ready — time: %f" % [node_label, Time.get_ticks_msec() / 1000.0])

func _exit_tree() -> void:
    print("[%s] _exit_tree — time: %f" % [node_label, Time.get_ticks_msec() / 1000.0])

func _process(_delta: float) -> void:
    # Only print a few frames so the output doesn't flood
    if Engine.get_process_frames() <= 3:
        print("[%s] _process — frame: %d" % [node_label, Engine.get_process_frames()])

func _physics_process(_delta: float) -> void:
    if Engine.get_physics_frames() <= 3:
        print("[%s] _physics_process — frame: %d" % [node_label, Engine.get_physics_frames()])
```

Set the parent node's `node_label` to "Parent" and the child's to "Child". Run the scene. The output will look like:

```
[Parent] _init
[Child] _init
[Parent] _enter_tree
[Child] _enter_tree
[Child] _ready          ← children ready BEFORE parent
[Parent] _ready
[Parent] _process — frame: 1
[Child] _process — frame: 1
[Parent] _physics_process — frame: 1
[Child] _physics_process — frame: 1
```

The key observation: **children's `_ready` is called before the parent's `_ready`**. This means in your parent's `_ready`, you can safely assume all children are already ready. This is why `@onready` works — by the time `_ready` runs on your node, every child node is already initialized.

### _init()

Constructor. Runs when the object is created with `new()` or when the scene instantiates it. The scene tree does not exist yet. Do not reference `$Children`, do not call `get_node()`, do not access `get_parent()`. Safe operations: initialize primitive variables, create data structures.

```gdscript
func _init() -> void:
    # SAFE
    health = max_health
    inventory = []
    stats = { "kills": 0, "deaths": 0 }

    # UNSAFE — these will fail or return null
    # $Label.text = "Hello"   # node doesn't exist
    # get_parent().add_child(something)  # no parent yet
```

### _enter_tree()

Called when the node is added to the scene tree. This happens every time — including when you `reparent()` a node. At this point the node is in the tree but children may not be ready yet. Use it when you need to react to being added to a specific tree (e.g., registering with a manager):

```gdscript
func _enter_tree() -> void:
    # Register with a game manager when entering any tree
    if has_node("/root/EnemyManager"):
        get_node("/root/EnemyManager").register_enemy(self)
```

### _ready()

Your primary initialization function. Called once, after the node and all its children are in the tree. This is where you set up `@onready` variables, connect signals, configure initial state, spawn children. 99% of your initialization code goes here.

```gdscript
func _ready() -> void:
    # @onready vars are already set by this point
    health_bar.max_value = max_health
    health_bar.value = health

    # Connect signals
    $HitArea.body_entered.connect(_on_hit_area_body_entered)

    # Configure initial state
    set_physics_process(false)  # disable until needed
```

### _process(delta) and _physics_process(delta)

Covered in depth in Section 7. Short version: `_process` runs every rendered frame (variable rate), `_physics_process` runs at a fixed rate. Both receive `delta` — the time in seconds since the last call of that function.

### _input(event) and _unhandled_input(event)

Both receive `InputEvent` objects. `_input` is called first, for every event. If your code calls `get_viewport().set_input_as_handled()`, the event is marked consumed and `_unhandled_input` won't receive it. UI `Control` nodes consume input events automatically.

Use `_input` for: UI interactions, debugging, things that must intercept input before anything else.
Use `_unhandled_input` for: gameplay input that shouldn't fire when UI is open.

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # Only fires if no UI consumed the event
    if event.is_action_pressed("pause"):
        toggle_pause()
```

### _exit_tree()

Called when the node is removed from the scene tree — either by `queue_free()`, by a scene change, or by `reparent()`. Use it for cleanup: disconnecting signals connected to external nodes, unregistering from managers, stopping audio.

```gdscript
func _exit_tree() -> void:
    # Unregister from manager
    if has_node("/root/EnemyManager"):
        get_node("/root/EnemyManager").unregister_enemy(self)

    # Stop any audio
    $AudioStreamPlayer3D.stop()
```

### Controlling Lifecycle with set_process()

You can enable and disable `_process` and `_physics_process` calls at runtime:

```gdscript
# Disable — _process won't be called until re-enabled
set_process(false)
set_physics_process(false)

# Re-enable
set_process(true)
set_physics_process(true)

# Check current state
if is_processing():
    print("_process is active")
```

This is more efficient than putting an `if is_active:` guard inside `_process` — if the function isn't called at all, there's zero overhead.

---

## 7. _process vs _physics_process — The Critical Difference

This is where most beginners make their first serious Godot mistake.

### Variable vs Fixed Timestep

`_process(delta)` runs once per rendered frame. If your monitor is 60Hz and your game maintains 60fps, it runs 60 times per second. If your game drops to 30fps, it runs 30 times per second. The `delta` value changes — it's approximately 0.016 at 60fps, 0.033 at 30fps. Multiply anything by `delta` to make it framerate-independent.

`_physics_process(delta)` runs at the physics tick rate, which defaults to 60 ticks per second and is **independent of rendering framerate**. Whether you're rendering at 144fps or 20fps, physics still ticks at 60Hz. The `delta` value here is always approximately 0.016 (1/60).

```
Rendering at 144fps:
Frame: |---physics---|---physics---|---physics---render---physics---render---|
        1            2             3        4            5

Rendering at 30fps:
Frame: |---physics---physics---physics---physics---render---physics---physics---physics--|
        1            2         3          4                  5         6         7

Physics ticks at the same rate. Rendering catches up.
```

### The Rule

- **Visual updates, animation control, camera smoothing, particle tweaks, UI** → `_process`
- **CharacterBody3D movement, RigidBody3D forces, collision queries, gameplay logic** → `_physics_process`
- **Input polling** → `_physics_process` (so input-driven movement matches physics timing)

If you move a `CharacterBody3D` in `_process`, the movement is inconsistent — at 144fps it moves tiny amounts per frame, at 30fps it moves larger amounts. Even with `delta` multiplication, the physics engine doesn't know you moved the body and collision detection becomes unreliable.

### Demonstration Script

Create a new scene: `Node3D` root, two `MeshInstance3D` children (two spheres). Attach this script to each sphere, set `use_physics` to false on one and true on the other:

```gdscript
# process_vs_physics_demo.gd
extends MeshInstance3D

@export var use_physics: bool = false
@export var move_speed: float = 3.0

# The sphere using _process will visually stutter if FPS drops
func _process(delta: float) -> void:
    if not use_physics:
        position.x = sin(Time.get_ticks_msec() * 0.001) * 3.0

# The sphere using _physics_process stays smooth
func _physics_process(delta: float) -> void:
    if use_physics:
        position.x = sin(Time.get_ticks_msec() * 0.001) * 3.0
```

Now cap the FPS artificially to see the difference:

```gdscript
# In a GameManager or autoload, force a low FPS cap
func _ready() -> void:
    Engine.max_fps = 15  # artificially low to show the difference
```

At 15fps, the `_process` sphere lurches — it only updates 15 times per second. The `_physics_process` sphere updates 60 times per second regardless of render rate.

Remove the FPS cap for your actual game.

### Physics Interpolation

Godot 4.3+ has built-in physics interpolation (`ProjectSettings > Physics > Common > Physics Interpolation`). When enabled, Godot interpolates rendered positions between physics ticks, making `_physics_process` movement visually smooth even at lower physics rates. Enable this for production games.

### When delta Matters

Always multiply by delta in `_process`:

```gdscript
# WRONG — moves faster at higher FPS
position.x += 3.0

# CORRECT — moves at 3 units/second regardless of FPS
position.x += 3.0 * delta
```

In `_physics_process`, delta is almost always 1/physics_fps (approximately 0.016), so the math still works with delta. But always use it anyway — the physics rate is configurable and you want your game to work at any setting.

---

## 8. Input Handling In Depth

### Three Input Layers

```
UI Controls (_gui_input) — Buttons, LineEdits, etc. consume input first.
↓
_input(event) — Called for every input event on every node.
↓
_unhandled_input(event) — Only events not consumed by UI or _input.
```

Most gameplay code belongs in `_unhandled_input` or uses polling in `_physics_process`. This way clicking a UI button doesn't trigger a jump.

### The InputMap System

Never hardcode key constants like `KEY_W` or `MOUSE_BUTTON_LEFT`. Instead, define **actions** in Project Settings > Input Map, then check for those actions in code. This gives you:

- Rebindable controls (critical for accessibility)
- Gamepad support for free (bind the action to a gamepad button too)
- Clean, readable code (`"jump"` vs `KEY_SPACE`)

**Setting up actions:**
1. Open **Project > Project Settings > Input Map** tab
2. Type an action name (e.g., `jump`) in the "Add Action" field, press Enter
3. Click the `+` button to add a binding — keyboard key, mouse button, or gamepad input
4. Repeat for: `move_left`, `move_right`, `move_forward`, `move_back`, `jump`, `attack`, `interact`

**Using actions in code:**

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        jump()
    if event.is_action_pressed("attack"):
        attack()

func _physics_process(delta: float) -> void:
    # Poll for held-down inputs
    if Input.is_action_pressed("attack") and attack_cooldown <= 0.0:
        attack()
```

### Input Polling vs Event Handling

**Event handling** (`_unhandled_input`): Best for actions that fire once on press — jumping, attacking, interacting. Guaranteed not to miss inputs (no "between frames" issues).

**Polling** (`Input.is_action_pressed` in `_physics_process`): Best for continuous inputs — movement, holding a button to charge an attack.

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # Fire once when pressed — event is the right tool
    if event.is_action_pressed("jump"):
        if is_on_floor():
            velocity.y = jump_velocity

func _physics_process(delta: float) -> void:
    # Continuous movement — polling is the right tool
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    move_and_slide()
```

### Input.get_vector()

`Input.get_vector(negative_x, positive_x, negative_y, positive_y)` returns a `Vector2` combining four directional actions. The vector is automatically normalized (you won't move faster diagonally):

```gdscript
# Returns Vector2 from (-1,-1) to (1,1)
var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

# input_dir.x: negative = left, positive = right
# input_dir.y: negative = forward, positive = back
# (in 3D, forward is -Z, so input_dir.y maps to -velocity.z)
```

### Input.get_axis()

For single-axis input (scrolling, zooming, 1D sliders):

```gdscript
# Returns float from -1.0 to 1.0
var zoom := Input.get_axis("zoom_out", "zoom_in")
camera_distance -= zoom * zoom_speed * delta

var turn := Input.get_axis("turn_left", "turn_right")
rotation.y -= turn * turn_speed * delta
```

### Mouse Input

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        rotate_y(-motion.relative.x * mouse_sensitivity)
        $Camera3D.rotate_x(-motion.relative.y * mouse_sensitivity)

    if event is InputEventMouseButton:
        var click := event as InputEventMouseButton
        if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
            attack()
```

Capture the mouse for first-person games:

```gdscript
func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # hide cursor, lock to window

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
```

### Adding Actions via Code (Testing Only)

For quick tests or procedurally defined controls, you can add InputMap actions at runtime. Not recommended for shipping games — use Project Settings:

```gdscript
func _ready() -> void:
    # Add an action
    InputMap.add_action("test_action")

    # Bind a key to it
    var key_event := InputEventKey.new()
    key_event.keycode = KEY_T
    InputMap.action_add_event("test_action", key_event)
```

---

## 9. Signals Introduction

Signals are Godot's built-in observer pattern. Instead of Node A holding a direct reference to Node B and calling `B.do_thing()`, Node A emits a signal and any interested node can listen for it. This decouples your code — A doesn't need to know B exists.

### Why Signals Beat Direct References

**Without signals (tightly coupled):**
```gdscript
# Enemy must know about HUD to update it — bad
func take_damage(amount: int) -> void:
    health -= amount
    get_node("/root/Game/HUD/HealthBar").value = health  # fragile hardcoded path
    get_node("/root/Game/HUD/DamagePopup").show_damage(amount)
```

**With signals (decoupled):**
```gdscript
# Enemy just announces what happened — HUD listens independently
signal health_changed(new_health: int)
signal damage_taken(amount: int)

func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health)
    damage_taken.emit(amount)
```

The HUD connects to these signals. The Enemy doesn't care if a HUD exists or not.

### Declaring Custom Signals

```gdscript
# Simple signal — no data
signal died
signal jumped
signal attack_started

# Signal with data
signal health_changed(new_health: int)
signal item_collected(item_name: String, item_value: int)
signal enemy_spotted(enemy: Enemy, distance: float)
```

Signal names use snake_case by convention.

### Emitting Signals

```gdscript
signal health_changed(new_health: int)
signal died

var health: int = 100

func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health)

    if health <= 0:
        health = 0
        died.emit()
```

### Connecting Signals via the Editor

1. Select the node that emits the signal in the Scene Tree
2. Open the **Node** dock (next to the Inspector)
3. Click the **Signals** tab
4. Double-click the signal you want to connect
5. Choose the node that should receive it
6. Godot generates a method stub in the target node's script

This is fine for scene-specific connections. For dynamic connections (spawned objects, runtime-created nodes), connect in code.

### Connecting Signals via Code

```gdscript
# In the listener's _ready():
func _ready() -> void:
    $Enemy.health_changed.connect(_on_enemy_health_changed)
    $Enemy.died.connect(_on_enemy_died)

func _on_enemy_health_changed(new_health: int) -> void:
    health_bar.value = new_health

func _on_enemy_died() -> void:
    score += 100
    $Enemy.queue_free()
```

### Connecting with Lambda (inline)

```gdscript
func _ready() -> void:
    $Enemy.died.connect(func():
        score += 100
        $Enemy.queue_free()
    )
```

Clean for simple one-liners. Use named functions for anything more than two lines.

### Disconnecting Signals

Godot 4 automatically disconnects signals when a node is freed (if connected to a method on that node). But if you connected with a lambda or a method on a still-alive node, disconnect manually:

```gdscript
# Store the callable to disconnect later
var _health_handler: Callable

func _ready() -> void:
    _health_handler = _on_enemy_health_changed
    $Enemy.health_changed.connect(_health_handler)

func _exit_tree() -> void:
    if is_instance_valid($Enemy):
        $Enemy.health_changed.disconnect(_health_handler)
```

### Built-in Signals

Every node type has built-in signals. Common ones:

| Node | Signal | When |
|------|--------|------|
| `Timer` | `timeout` | Timer reaches zero |
| `Area3D` | `body_entered(body)` | Physics body enters area |
| `Area3D` | `body_exited(body)` | Physics body exits area |
| `Button` | `pressed` | Button clicked |
| `CharacterBody3D` | *(none built-in — use manually)* | — |
| `AnimationPlayer` | `animation_finished(name)` | Animation completes |
| `HTTPRequest` | `request_completed(result, code, headers, body)` | HTTP response arrives |

Find all signals for a node type in the Godot docs under that class, or in the Node dock's Signals tab.

### Signal Preview — Deeper Architecture

This section is just an introduction. Module 5 covers signal architecture in full: signal buses, autoload event systems, typed signals with class validation, and patterns for large game codebases. What you need now: declare signals, emit them when something happens, connect listeners. That's the pattern.

---

## 10. Coroutines and await

GDScript has first-class coroutine support via the `await` keyword. A function that uses `await` pauses its execution and resumes when the awaited thing completes. The caller is not blocked — other code runs while the coroutine waits.

### Awaiting Signals

```gdscript
# This function pauses at await and resumes when body_entered fires
func wait_for_player_entry() -> void:
    print("Waiting for player to enter area...")
    await $TriggerArea.body_entered
    print("Player entered!")
    start_cutscene()
```

### Awaiting Timers

`create_timer()` creates a one-shot timer and returns it. Await its `timeout` signal:

```gdscript
func spawn_wave() -> void:
    for i in 5:
        spawn_enemy()
        await get_tree().create_timer(0.5).timeout
    print("Wave complete")

func show_damage_number(amount: int, position: Vector3) -> void:
    var label := DamageLabel.instantiate()
    add_child(label)
    label.global_position = position
    label.set_text(str(amount))

    # Float up and fade over 1 second
    var tween := create_tween()
    tween.tween_property(label, "position:y", label.position.y + 2.0, 1.0)
    tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
    await tween.finished
    label.queue_free()
```

### Awaiting Frames

Wait for the next frame or a specific number of frames:

```gdscript
# Wait one frame
await get_tree().process_frame

# Wait one physics frame
await get_tree().physics_frame
```

Useful when you need to let the engine process something before continuing:

```gdscript
func spawn_and_configure() -> void:
    var enemy := EnemyScene.instantiate()
    add_child(enemy)
    await get_tree().process_frame  # let _ready() run on the new node
    enemy.set_target(player)        # now safe to configure
```

### Sequential Animations Without Callback Hell

The classic problem with callbacks: deep nesting for sequential async operations. With `await`, sequential game events read top-to-bottom:

```gdscript
# Without await — nested callback hell
func start_cutscene() -> void:
    door_anim.play("open")
    door_anim.animation_finished.connect(func(_name):
        camera_tween.start()
        camera_tween.finished.connect(func():
            dialogue_system.show_line("Welcome, hero.")
            dialogue_system.line_completed.connect(func():
                level_music.play()
            )
        )
    )

# With await — reads like normal code
func start_cutscene() -> void:
    door_anim.play("open")
    await door_anim.animation_finished

    var tween := create_tween()
    tween.tween_property(camera, "position", cutscene_position, 1.5)
    await tween.finished

    dialogue_system.show_line("Welcome, hero.")
    await dialogue_system.line_completed

    level_music.play()
```

### Coroutine Return Values

A function that uses `await` returns a signal-like object to its caller. You can await the function itself:

```gdscript
func get_player_choice() -> int:
    choice_dialog.show()
    await choice_dialog.choice_made  # choice_made emits with an int
    return choice_dialog.selected_index

func handle_quest_start() -> void:
    var choice := await get_player_choice()
    match choice:
        0: start_quest_path_a()
        1: start_quest_path_b()
```

### Pitfalls

Be careful awaiting on freed objects. If the node emitting the signal is freed before the await completes, you get an error:

```gdscript
# RISKY — enemy might die before the timer fires
await $Enemy.died  # if $Enemy is freed mid-wait, error

# SAFE — check validity after resuming
var timer := get_tree().create_timer(5.0)
await timer.timeout
if is_instance_valid(enemy_ref):
    enemy_ref.retreat()
```

---

## 11. Dictionaries, Arrays, and Iteration

### Arrays

GDScript arrays are dynamic, zero-indexed, and can hold any type (or a specific type with typed arrays):

```gdscript
# Declaration
var items: Array[String] = ["sword", "shield", "potion"]
var scores: Array[int] = []

# Add
items.append("bow")
items.push_back("staff")  # same as append
items.insert(0, "dagger")  # insert at index 0

# Remove
items.remove_at(0)     # remove by index
items.erase("potion")  # remove first matching value
var last := items.pop_back()  # remove and return last element

# Access
var first := items[0]
var last_item := items[-1]  # negative indexing works
var size := items.size()    # NOT .length — Godot uses .size()

# Check membership
if "potion" in items:
    use_potion()

# Iterate
for item in items:
    print(item)

for i in items.size():
    print("%d: %s" % [i, items[i]])
```

### Array Functional Methods

GDScript arrays have `filter`, `map`, `reduce`, and `sort_custom` — all take lambdas:

```gdscript
var enemies: Array[Enemy] = get_all_enemies()

# Filter — returns new array with matching elements
var alive_enemies := enemies.filter(func(e: Enemy) -> bool: return e.health > 0)
var nearby := enemies.filter(func(e: Enemy) -> bool:
    return position.distance_to(e.position) < 15.0
)

# Map — returns new array with transformed elements
var enemy_positions: Array[Vector3] = enemies.map(func(e: Enemy) -> Vector3:
    return e.global_position
)
var health_values: Array[int] = enemies.map(func(e: Enemy) -> int: return e.health)

# Reduce — fold to single value
var total_health: int = enemies.reduce(func(acc: int, e: Enemy) -> int:
    return acc + e.health, 0
)

# Sort with custom comparator
enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
    return a.health < b.health  # sort ascending by health
)

# Find first matching element (returns null if not found)
var boss := enemies.filter(func(e: Enemy) -> bool: return e.is_boss).front()
```

### Dictionaries

Dictionaries are unordered key-value stores. Keys and values can be any type:

```gdscript
# Declaration
var player_stats: Dictionary = {
    "health": 100,
    "mana": 50,
    "stamina": 75,
    "level": 1
}

# Access
var hp := player_stats["health"]    # bracket notation
var hp2 := player_stats.health      # dot notation (works for string keys)

# Safe access with default
var rage := player_stats.get("rage", 0)  # returns 0 if "rage" doesn't exist

# Modify
player_stats["health"] = 80
player_stats.level += 1

# Check key
if "health" in player_stats:
    print("Has health stat")
if player_stats.has("mana"):
    print("Has mana stat")

# Add new key
player_stats["speed"] = 10

# Remove
player_stats.erase("stamina")

# Size
print(player_stats.size())

# Iterate keys
for key in player_stats:
    print("%s = %s" % [key, player_stats[key]])

# Iterate key-value pairs
for key in player_stats.keys():
    var value = player_stats[key]
```

### Nested Structures

Real game data often nests dictionaries and arrays:

```gdscript
var inventory: Dictionary = {
    "weapons": ["sword", "bow"],
    "consumables": {
        "potion": { "count": 3, "heal_amount": 50 },
        "elixir": { "count": 1, "heal_amount": 100 }
    },
    "equipped": "sword"
}

# Deep access
var potion_count: int = inventory["consumables"]["potion"]["count"]
inventory["consumables"]["potion"]["count"] -= 1
```

For complex data structures in production code, prefer typed `Resource` or `class_name` objects over raw Dictionaries — you get type safety and autocomplete.

### Range and Iteration Patterns

```gdscript
# Range — exclusive end
for i in range(5):          # 0, 1, 2, 3, 4
    print(i)

for i in range(2, 8):       # 2, 3, 4, 5, 6, 7
    print(i)

for i in range(0, 10, 2):   # 0, 2, 4, 6, 8
    print(i)

for i in range(10, 0, -1):  # 10, 9, 8, ..., 1
    print(i)

# Shorthand — range(n) when starting from 0
for i in 5:                 # same as range(5)
    print(i)

# Enumerate equivalent (index + value)
for i in items.size():
    print("%d: %s" % [i, items[i]])
```

### PackedArray Operations

When working with geometry, physics, or large numeric datasets, use packed arrays for performance:

```gdscript
var vertices := PackedVector3Array()
var uvs := PackedVector2Array()
var indices := PackedInt32Array()

# Bulk append
vertices.append_array(PackedVector3Array([
    Vector3(0, 0, 0),
    Vector3(1, 0, 0),
    Vector3(0.5, 1, 0)
]))

# Array operations are similar to regular arrays
print(vertices.size())  # 3
for v in vertices:
    print(v)
```

---

## 12. Code Walkthrough: Character Controller

This is the capstone for the module. Build a complete character controller from scratch using everything covered above.

### Scene Setup

Create a new scene:
1. Root node: `CharacterBody3D` (rename to "Player")
2. Add child: `CollisionShape3D` → shape: `CapsuleShape3D` (height 1.8, radius 0.4)
3. Add child: `MeshInstance3D` → mesh: `CapsuleMesh`
4. Add child: `Camera3D` (position Y: 1.6 — eye height)
5. Add child: `GPUParticles3D` (for movement trail)
6. Save as `res://scenes/player.tscn`

Also create the level:
1. Root: `Node3D`
2. Add a `WorldEnvironment` with a default `Environment` resource
3. Add a `DirectionalLight3D`
4. Add a `StaticBody3D` with `CollisionShape3D` (BoxShape, large flat plane) as the floor
5. Add a `MeshInstance3D` (PlaneMesh) for the floor visual
6. Instantiate `player.tscn` as a child
7. Save as `res://scenes/main.tscn`

In Project Settings > Input Map, add these actions:
- `move_left` → A key
- `move_right` → D key
- `move_forward` → W key
- `move_back` → S key
- `jump` → Space key

### The Complete Player Script

```gdscript
# player.gd
extends CharacterBody3D
class_name Player

# ─────────────────────────────────────────────────
# Configuration — tunable in inspector
# ─────────────────────────────────────────────────
@export_group("Movement")
@export var move_speed: float = 5.0
@export var run_speed: float = 9.0
@export var acceleration: float = 12.0
@export var deceleration: float = 20.0
@export var jump_height: float = 2.0
@export var gravity_multiplier: float = 1.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var camera_lerp_speed: float = 10.0

@export_group("Visual")
@export var trail_active_speed: float = 4.0
@export var trail_color: Color = Color.CYAN

# ─────────────────────────────────────────────────
# Constants (derived from exported values)
# ─────────────────────────────────────────────────
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# ─────────────────────────────────────────────────
# Signals
# ─────────────────────────────────────────────────
signal jumped
signal landed
signal speed_changed(new_speed: float)

# ─────────────────────────────────────────────────
# Node references
# ─────────────────────────────────────────────────
@onready var camera: Camera3D = $Camera3D
@onready var trail: GPUParticles3D = $GPUParticles3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

# ─────────────────────────────────────────────────
# Internal state
# ─────────────────────────────────────────────────
var jump_velocity: float
var was_on_floor: bool = false
var current_speed: float = 0.0
var is_running: bool = false

# ─────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────
func _ready() -> void:
    # Derive jump velocity from desired jump height using physics formula
    # v = sqrt(2 * g * h)
    jump_velocity = sqrt(2.0 * gravity * gravity_multiplier * jump_height)

    # Setup trail visual
    var particle_material := StandardMaterial3D.new()
    particle_material.albedo_color = trail_color
    particle_material.emission_enabled = true
    particle_material.emission = trail_color
    trail.process_material = ParticleProcessMaterial.new()
    trail.emitting = false

    # Capture mouse for first-person-style camera
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
    # Release mouse when scene exits
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# ─────────────────────────────────────────────────
# Input — event-based (fires once per press)
# ─────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
    # Mouse look
    if event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        rotate_y(-motion.relative.x * mouse_sensitivity)
        camera.rotate_x(-motion.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, -PI / 2.5, PI / 2.5)

    # Release mouse
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# ─────────────────────────────────────────────────
# Physics — all movement lives here
# ─────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_jump()
    _handle_movement(delta)
    _check_landing()
    move_and_slide()
    _update_speed_tracking()

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * gravity_multiplier * delta

func _handle_jump() -> void:
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
        jumped.emit()

func _handle_movement(delta: float) -> void:
    # Get raw directional input
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

    # Transform from camera-relative to world-space direction
    # transform.basis is the player's local orientation
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    # Choose speed based on sprint input
    is_running = Input.is_action_pressed("sprint") if InputMap.has_action("sprint") else false
    var target_speed := run_speed if is_running else move_speed

    if direction != Vector3.ZERO:
        # Accelerate toward input direction
        velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
    else:
        # Decelerate to zero
        velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

func _check_landing() -> void:
    if is_on_floor() and not was_on_floor:
        landed.emit()
    was_on_floor = is_on_floor()

func _update_speed_tracking() -> void:
    var horizontal_speed := Vector2(velocity.x, velocity.z).length()
    if abs(horizontal_speed - current_speed) > 0.1:
        current_speed = horizontal_speed
        speed_changed.emit(current_speed)

# ─────────────────────────────────────────────────
# Visual updates — smooth camera and trail
# ─────────────────────────────────────────────────
func _process(delta: float) -> void:
    _update_trail()

func _update_trail() -> void:
    var horizontal_speed := Vector2(velocity.x, velocity.z).length()
    var should_trail := horizontal_speed > trail_active_speed and is_on_floor()

    if trail.emitting != should_trail:
        trail.emitting = should_trail
```

### What Each Section Does

**`@export_group` blocks**: All tunable values exposed to the inspector. No magic numbers in the logic code. Level designers can tune feel without touching code.

**`@onready` block**: All node references gathered in one place at the top. Clear at a glance what external nodes this script depends on.

**`_ready()`**: One-time setup. Derives the jump velocity from physics formulas (using the exported `jump_height` to back-calculate velocity). Captures the mouse.

**`_unhandled_input(event)`**: Mouse look (one-time rotation per mouse move event) and escape to release cursor. Using `_unhandled_input` means UI menus can consume input without the camera rotating behind them.

**`_physics_process(delta)`**: All gameplay logic. Gravity, jump, movement, `move_and_slide()`. Everything that depends on physics consistency lives here.

**`_process(delta)`**: Visual-only updates. The trail particle toggling is visual — even if it was off by a frame or two due to FPS variation it wouldn't matter. It's pure cosmetic. Camera smoothing (if you add it) also lives here.

**Signals**: `jumped`, `landed`, and `speed_changed` let other systems (audio, UI, achievement tracking) react to player state without knowing how the player works.

### Camera Smoothing (Optional Enhancement)

For a smoother camera follow, instead of parenting Camera3D directly to the player, create a separate `Node3D` that follows the player position with lerp in `_process`:

```gdscript
# camera_rig.gd — attach to a Node3D separate from the player
extends Node3D

@export var target: Node3D
@export var follow_speed: float = 10.0
@export var offset: Vector3 = Vector3(0, 2, 5)

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    var target_pos := target.global_position + offset
    global_position = global_position.lerp(target_pos, follow_speed * delta)
    look_at(target.global_position, Vector3.UP)
```

This gives springy camera follow without physics involvement.

---

## API Quick Reference

| Symbol | What It Does | Example |
|--------|-------------|---------|
| `var x: float` | Typed variable declaration | `var speed: float = 5.0` |
| `var x := 5.0` | Type-inferred declaration | `var speed := 5.0` |
| `@export` | Expose to inspector | `@export var health: int = 100` |
| `@export_range(a, b)` | Inspector slider | `@export_range(0, 100) var speed: float` |
| `@export_enum("A", "B")` | Inspector dropdown | `@export_enum("Melee","Ranged") var type: int` |
| `@export_group("Name")` | Group inspector fields | `@export_group("Combat")` |
| `@onready` | Init after _ready | `@onready var label: Label3D = $Label3D` |
| `$NodeName` | Get child by name | `$Camera3D.rotate_x(0.1)` |
| `%UniqueName` | Get unique-named node | `%HealthBar.value = hp` |
| `func f() -> void` | Typed function | `func jump() -> void:` |
| `signal x(val: int)` | Declare signal | `signal health_changed(new_health: int)` |
| `signal.emit(args)` | Fire signal | `health_changed.emit(health)` |
| `signal.connect(fn)` | Listen to signal | `died.connect(_on_player_died)` |
| `await signal` | Pause until signal fires | `await $Timer.timeout` |
| `get_tree().create_timer(t)` | One-shot timer | `await get_tree().create_timer(1.0).timeout` |
| `_ready()` | Post-tree-entry init | All `@onready` refs available here |
| `_process(delta)` | Per-frame visual update | Camera, UI, particle logic |
| `_physics_process(delta)` | Per-physics-tick update | Movement, collision, gameplay |
| `_input(event)` | All input events | Catch-all input handling |
| `_unhandled_input(event)` | Non-UI input | Gameplay input |
| `_exit_tree()` | Cleanup on removal | Disconnect signals, stop audio |
| `Input.is_action_pressed("x")` | Polling: held down | Continuous movement |
| `Input.is_action_just_pressed("x")` | Polling: pressed this frame | Jump, attack trigger |
| `Input.get_vector(l, r, f, b)` | 2D directional input | WASD movement direction |
| `Input.get_axis(neg, pos)` | 1D axis input | Zoom, scroll |
| `move_and_slide()` | Physics body movement | CharacterBody3D locomotion |
| `queue_free()` | Destroy node next frame | Bullet hit, pickup collected |
| `is_instance_valid(x)` | Check if node alive | Guard null references |
| `set_process(bool)` | Toggle _process calls | Disable during cutscene |

---

## Common Pitfalls

### 1. Class-level Node References

**WRONG:**
```gdscript
extends Node3D
var label = $Label3D  # null — node doesn't exist during class init
```

**RIGHT:**
```gdscript
extends Node3D
@onready var label: Label3D = $Label3D  # initialized in _ready, works correctly
```

The `@onready` annotation defers the assignment until `_ready()` runs, at which point all children are in the tree.

---

### 2. Moving CharacterBody3D in _process

**WRONG:**
```gdscript
func _process(delta: float) -> void:
    velocity.z -= move_speed * delta
    move_and_slide()  # physics called from render loop — jittery, unreliable
```

**RIGHT:**
```gdscript
func _physics_process(delta: float) -> void:
    velocity.z -= move_speed * delta
    move_and_slide()  # physics in physics loop — consistent collision, smooth
```

`move_and_slide()` is a physics operation. It needs to run in `_physics_process` to interact correctly with the physics engine. Running it in `_process` causes jitter and missed collisions.

---

### 3. Hardcoding Key Constants

**WRONG:**
```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.keycode == KEY_SPACE and key_event.pressed:
            jump()
```

**RIGHT:**
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        jump()
```

Hardcoded key constants break gamepad support, break remapping, and make your code harder to read. Define actions in the InputMap and check action names.

---

### 4. Connecting Signals to Freed Objects

**WRONG:**
```gdscript
# Connected, then enemy is freed. Callback fires on dead object.
$Enemy.died.connect(hud._on_enemy_died)
$Enemy.queue_free()  # signal fires, tries to call method on freed HUD... crash
```

**RIGHT:**
```gdscript
# Option 1: Check validity in the callback
func _on_enemy_died() -> void:
    if not is_instance_valid(self):
        return
    score += 100

# Option 2: Use CONNECT_ONE_SHOT for signals that fire once
$Enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)

# Option 3: Disconnect in _exit_tree
func _exit_tree() -> void:
    if is_instance_valid($Enemy) and $Enemy.died.is_connected(_on_enemy_died):
        $Enemy.died.disconnect(_on_enemy_died)
```

Godot 4 auto-disconnects signals when the **object holding the connection** is freed. But if the signal emitter is freed first and the connection is set to call a method on a still-alive object, the signal won't fire (the emitter is gone). The real danger is more subtle: a node holding references to freed objects and acting on stale state.

---

### 5. Untyped Variables Everywhere

**WRONG:**
```gdscript
var speed = 5  # int? float? who knows
var enemies = []  # Array of what?
var name = get_name()  # String? Node? method return type unknown

func get_speed():
    return speed  # caller has no idea what type comes back
```

**RIGHT:**
```gdscript
var speed: float = 5.0
var enemies: Array[Enemy] = []
var name: String = get_name()

func get_speed() -> float:
    return speed
```

Static typing in GDScript is essentially free — it runs at parse time, not runtime. You get better error messages, editor autocomplete, and documentation for free. There is no reason to skip it.

---

## Exercises

### Exercise 1: Collectible with Signal Counter (20–30 min)

Add a collectible pickup to the character controller scene.

**Setup:**
1. Create `collectible.tscn`: root `Area3D`, child `CollisionShape3D` (SphereShape), child `MeshInstance3D` (SphereMesh with emissive material)
2. Place several instances in the level scene

**Collectible script:**
```gdscript
# collectible.gd
extends Area3D

signal collected(value: int)

@export var point_value: int = 10
@export var collect_sound: AudioStream

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if body is Player:
        collected.emit(point_value)
        queue_free()
```

**HUD script:**
```gdscript
# hud.gd
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
var score: int = 0

func _ready() -> void:
    # Find all collectibles and connect to each
    for collectible in get_tree().get_nodes_in_group("collectibles"):
        collectible.collected.connect(_on_collected)

func _on_collected(value: int) -> void:
    score += value
    score_label.text = "Score: %d" % score
```

Add collectibles to a "collectibles" group in the scene tree (select node, check Inspector > Groups). Run the scene, collect all items, watch the score.

**Goal:** Practice signals decoupling (collectible doesn't know about HUD), `queue_free()`, and `get_nodes_in_group()`.

---

### Exercise 2: Lifecycle Visualizer (45–60 min)

Build a scene that shows the full node lifecycle in real time.

**Scene setup:** `Node3D` root with 5 `Node3D` children (A, B, C, D, E). Each has the lifecycle_logger.gd script from Section 6 attached with its name set in the `node_label` export.

**Add a controller node** that dynamically adds and removes nodes at runtime:

```gdscript
# lifecycle_controller.gd
extends Node3D

@export var spawn_node_scene: PackedScene

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):  # Enter key
        add_dynamic_node()

    if event.is_action_pressed("ui_cancel"):  # Escape
        remove_last_dynamic_node()

func add_dynamic_node() -> void:
    if spawn_node_scene:
        var node := spawn_node_scene.instantiate()
        node.name = "Dynamic_%d" % get_child_count()
        node.set("node_label", node.name)
        add_child(node)
        print("--- Added %s ---" % node.name)

func remove_last_dynamic_node() -> void:
    var children := get_children()
    if children.size() > 0:
        var last := children[-1]
        print("--- Removing %s ---" % last.name)
        last.queue_free()
```

**Goal:** See the lifecycle order yourself. Notice children _ready before parent, _enter_tree before _ready, _exit_tree when removed. Build the mental model.

---

### Exercise 3: State-Driven Character (60–90 min)

Extend the character controller from Section 12 with a proper state machine.

**Add to player.gd:**

```gdscript
enum PlayerState { IDLE, WALKING, RUNNING, JUMPING, FALLING }

var state: PlayerState = PlayerState.IDLE

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_jump()
    _handle_movement(delta)
    _update_state()
    move_and_slide()
    _update_speed_tracking()

func _update_state() -> void:
    var prev_state := state
    var horizontal_speed := Vector2(velocity.x, velocity.z).length()

    if not is_on_floor():
        state = PlayerState.FALLING if velocity.y < 0 else PlayerState.JUMPING
    elif horizontal_speed < 0.5:
        state = PlayerState.IDLE
    elif horizontal_speed < move_speed * 0.9:
        state = PlayerState.WALKING
    else:
        state = PlayerState.RUNNING

    if state != prev_state:
        _on_state_changed(prev_state, state)

func _on_state_changed(from: PlayerState, to: PlayerState) -> void:
    print("State: %s → %s" % [PlayerState.keys()[from], PlayerState.keys()[to]])

    match to:
        PlayerState.IDLE:
            trail.emitting = false
        PlayerState.WALKING:
            trail.emitting = false
        PlayerState.RUNNING:
            trail.emitting = true
        PlayerState.JUMPING:
            trail.emitting = false
        PlayerState.FALLING:
            trail.emitting = false
```

**Extension challenges:**
- Add a sprint state that requires a held key and stamina system
- Change mesh color based on state (`mesh.get_surface_override_material(0).albedo_color = ...`)
- Add a `state_changed` signal that other systems can listen to
- Print state transition duration (time spent in each state)

**Goal:** Practice enums, match statements, and state-driven behavior. Notice how `_on_state_changed` is cleaner than checking state every frame and running behavior every tick.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [GDScript reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html) | Official Docs | Complete language reference — bookmark this |
| [Idle and physics processing](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html) | Official Docs | Official explanation of _process vs _physics_process |
| [InputEvent system](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html) | Official Docs | How input flows through the engine — good diagrams |
| [Using signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html) | Official Docs | Official signals tutorial with editor screenshots |
| [GDQuest GDScript from Zero](https://gdquest.github.io/learn-gdscript/) | Interactive | Practice GDScript in the browser, great for solidifying syntax |
| [Godot CharacterBody3D tutorial](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html) | Official Docs | Deeper look at move_and_slide and character physics |

---

## Key Takeaways

1. **Use static typing everywhere.** `var x: float = 1.0` or `var x := 1.0`. It's free performance, free autocomplete, and free error detection at parse time. Untyped code is a debugging tax you pay later.

2. **`@onready` is mandatory for node references.** Nodes don't exist at class-level initialization time. `@onready var label: Label3D = $Label3D` is the correct, zero-cost way to get node refs.

3. **`_process(delta)` for visuals, `_physics_process(delta)` for gameplay.** Never move a physics body in `_process`. Never put non-visual logic in `_process` when it depends on physics state. This distinction eliminates an entire class of jitter and collision bugs.

4. **Use InputMap actions, never hardcode keys.** `Input.is_action_pressed("jump")` not `event.keycode == KEY_SPACE`. Your game needs to support rebinding, gamepads, and accessibility. InputMap gives you all of this for free.

5. **Signals decouple your code.** Emit events from objects that have state. Let other objects listen and react. The collectible doesn't need to know a HUD exists. The player doesn't need to know about the audio system. Signals make this clean.

6. **`@export` turns scripts into configurable components.** Define your tunable values with `@export`, group them with `@export_group`, constrain them with `@export_range`. Level designers (or future you) can tweak feel without touching code.

7. **`await` + signals = clean coroutines.** Waiting for a timer, an animation, a player choice — all of these become readable sequential code instead of nested callbacks. Learn this pattern and use it freely.

---

## What's Next

You know the language and you know the engine's heartbeat. You can write typed GDScript with confidence, you know exactly when each lifecycle function runs, and you've built a character that moves correctly using the right process loop.

**[Module 2: Scenes, Nodes, and the Scene Tree](module-02-scenes-nodes-scene-tree.md)** covers Godot's most powerful idea — scenes as reusable, composable building blocks. You'll learn to design scene hierarchies that scale, understand instancing (Godot's prefab system), build an inventory of reusable scene components, and understand the parent-child relationship and signal-over-direct-reference architecture that makes large Godot projects maintainable.

Sneak peek: every entity in your game — player, enemy, bullet, pickup, UI element — should be its own scene. The scene tree is not just an organizational tool. It's your entire game architecture. Module 2 explains why.

---

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
