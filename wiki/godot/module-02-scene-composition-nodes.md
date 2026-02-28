# Module 2: Scene Composition & the Node Tree

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** [Module 1: GDScript & the Engine Lifecycle](module-01-gdscript-engine-lifecycle.md)

---

## Overview

This is the module where Godot clicks. Every other engine has some version of "prefabs" or "components" — Godot's version is scenes. A scene is a saved tree of nodes. Any scene can be instanced inside any other scene. This is not a minor feature — it's the fundamental architecture of every Godot game. Once you internalize this, you'll never think about game architecture the same way.

In React, you compose components. In Godot, you compose scenes. A "Torch" scene (mesh + light + particles) becomes a reusable building block. A "Room" scene instances multiple torches, props, and enemies. A "Dungeon" scene instances multiple rooms. It's turtles all the way down. The scene tree is both your visual hierarchy AND your game architecture. There's no external dependency injection framework to configure, no prefab override system to learn, no Unity-style component inspector oddities. Just nodes in trees, all the way down.

By the end of this module, you'll build a modular dungeon from reusable scene pieces, spawn and destroy scenes at runtime, use groups for broadcasting, and understand scene inheritance for creating enemy variants. The mini-project is deliberately architectural rather than visual — this is the module where you learn to think in Godot.

---

## 1. Everything Is a Node

### Godot's Philosophy

Open any Godot project and look at the Scene dock on the left. What you see is a tree. Every item in that tree is a node. A node is the fundamental unit of everything in Godot — game objects, UI elements, audio players, state machines, HTTP request handlers. Everything is a node.

This is not a metaphor or an oversimplification. There are no "GameObjects with components" like Unity, no "Actors with components" like Unreal. A node IS the thing. You pick the right node type for what you need, then you add child nodes to compose additional behavior.

Every node shares a common base:
- **Properties** — data attached to the node (position, color, health, speed)
- **Methods** — functions the node can call or that can be called on it
- **Signals** — events the node emits when something happens

And every node participates in the tree lifecycle: `_ready()` when added to the tree, `_process(delta)` every frame, `_exit_tree()` when removed.

### The Inheritance Hierarchy

Godot nodes form an inheritance hierarchy. You don't need to memorize it, but understanding the major branches helps you pick the right base class:

```
Object
└── RefCounted          (reference-counted data, not in tree)
└── Node                (base for everything in the tree)
    ├── Node2D          (2D transform: position, rotation, scale)
    │   ├── Sprite2D
    │   ├── CollisionShape2D
    │   ├── CharacterBody2D
    │   └── ...
    ├── Node3D          (3D transform: position, rotation, scale)
    │   ├── MeshInstance3D
    │   ├── Camera3D
    │   ├── Light3D
    │   │   ├── DirectionalLight3D
    │   │   ├── OmniLight3D
    │   │   └── SpotLight3D
    │   ├── AudioStreamPlayer3D
    │   ├── Area3D
    │   ├── PhysicsBody3D
    │   │   ├── StaticBody3D
    │   │   ├── RigidBody3D
    │   │   └── CharacterBody3D
    │   └── ...
    ├── Control         (UI: anchors, margins, layout)
    │   ├── Label
    │   ├── Button
    │   ├── Panel
    │   └── ...
    ├── Timer           (count down, emit timeout signal)
    ├── AnimationPlayer (play animations on properties)
    ├── AudioStreamPlayer (non-positional audio)
    └── HTTPRequest     (async web requests)
```

The key insight: Node3D means "I exist in 3D space." Control means "I am a UI element." Node (base) means "I have no transform — I'm just logic." Pick your base class, then add children.

### Common Node Types Reference

| Node Type | Use Case |
|---|---|
| `Node` | Pure logic containers, autoloads, state machines |
| `Node2D` | Any 2D game object |
| `Node3D` | Any 3D game object — use as scene roots |
| `Control` | UI panels, HUDs, menus |
| `MeshInstance3D` | Renders a 3D mesh |
| `Camera3D` | The player's view into the world |
| `DirectionalLight3D` | Sun — parallel rays, infinite range |
| `OmniLight3D` | Point light — radiates in all directions |
| `SpotLight3D` | Cone-shaped beam |
| `AudioStreamPlayer3D` | Plays audio at a 3D position (spatialized) |
| `Area3D` | Detect overlap — no physics response |
| `StaticBody3D` | Immovable collision (floors, walls) |
| `RigidBody3D` | Physics-simulated object |
| `CharacterBody3D` | Player/enemy — manual movement control |
| `CollisionShape3D` | Defines the collision shape of a physics body |
| `AnimationPlayer` | Keyframe animations on any property |
| `Timer` | One-shot or repeating countdown |
| `Marker3D` | Empty 3D transform — spawn points, attach points |
| `GPUParticles3D` | GPU-accelerated particle system |
| `Label3D` | Text floating in 3D space |
| `HTTPRequest` | Web API calls |

### You Compose Behavior, You Don't Inherit It

Here's the pattern you'll use constantly: pick the base class that gives you the spatial/physics behavior you need, then add children that provide additional capabilities.

An enemy:
```
CharacterBody3D   ← gives you move_and_slide(), collision
├── MeshInstance3D    ← visible body
├── CollisionShape3D  ← hitbox
├── AudioStreamPlayer3D ← footstep sounds
├── AnimationPlayer   ← walk/attack/death animations
├── Area3D            ← detection radius (with its own CollisionShape3D)
└── Marker3D          ← loot spawn point
```

No component system needed. The tree IS the component system.

---

## 2. Scenes: Godot's Building Blocks

### What a Scene Actually Is

A scene is a saved tree of nodes stored in a `.tscn` file (text-based, human-readable). That's it. The file describes:
- The root node type and name
- All child nodes, their types, and properties
- Scripts attached to nodes
- External resources (meshes, textures, materials) referenced by path

The mental model that unlocks everything:

> **A scene is a class. An instance is an object.**

When you save `torch.tscn`, you've defined a class. Every time you drag it into another scene, you're creating an instance. Change the source scene, and all instances update. Override a property on one instance, and only that instance changes. This is exactly like a class/instance relationship in programming.

### Building a Torch Scene Step by Step

Let's build a complete reusable Torch scene. Follow along in the editor.

**Step 1: Create the scene.**
- In the FileSystem dock, right-click the `res://` folder (or a subfolder like `res://props/`)
- Select "New Scene"
- Or use the menu: Scene > New Scene

**Step 2: Choose the root node.**
- Click "Other Node" in the Scene dock
- Search for and select `Node3D`
- Rename it in the Inspector: `Torch`

**Step 3: Add the torch body.**
- Select the `Torch` root node
- Press Ctrl+A (or click the + icon in the Scene dock) to add a child node
- Search for `MeshInstance3D` and add it
- Rename it: `Body`
- In the Inspector, click the Mesh property and select "New CylinderMesh"
- Set height: `0.8`, top radius: `0.04`, bottom radius: `0.06` (a tapered handle)
- Create a new StandardMaterial3D on the mesh, set albedo color to a dark brown

**Step 4: Add the flame light.**
- Select the `Torch` root node, add a child `OmniLight3D`
- Rename it: `FlameLight`
- Set Position Y to `0.9` (above the top of the torch body)
- In Inspector:
  - Color: warm orange `#FF6020`
  - Energy: `2.0`
  - Range: `4.0`
  - Enable "Shadow" for atmosphere (optional, performance cost)

**Step 5: Add the flame particles.**
- Select the `Torch` root node, add a child `GPUParticles3D`
- Rename it: `FlameParticles`
- Set Position Y to `0.9`
- In Inspector, set Amount: `16`
- Create a new ParticleProcessMaterial:
  - Emission Shape: Box, with box extents `0.03, 0.03, 0.03`
  - Direction: `0, 1, 0` (upward)
  - Spread: `15`
  - Initial Velocity: min `0.2`, max `0.5`
  - Scale Min: `0.1`, Scale Max: `0.3`
  - Color curve: orange to transparent
- Set Lifetime: `0.4`

**Step 6: Save the scene.**
- Ctrl+S
- Save as `res://props/torch.tscn`

Your scene tree now looks like:
```
Torch (Node3D)
├── Body (MeshInstance3D)
├── FlameLight (OmniLight3D)
└── FlameParticles (GPUParticles3D)
```

**Step 7: Use it anywhere.**
- Open another scene (your level, room, etc.)
- In the FileSystem dock, drag `torch.tscn` into the viewport or Scene dock
- Repeat 4 more times
- Each torch is an independent instance — move them wherever you want

Every instance references the same source scene. If you decide the torch light should be yellow instead of orange, change it in `torch.tscn` once, and all instances update immediately.

### The .tscn File Format

You don't need to edit these manually, but seeing the format demystifies things:

```ini
[gd_scene load_steps=4 format=3 uid="uid://b7abc12345"]

[ext_resource type="Script" path="res://props/torch.gd" id="1_abc"]

[sub_resource type="CylinderMesh" id="CylinderMesh_xyz"]
height = 0.8
top_radius = 0.04
bottom_radius = 0.06

[sub_resource type="StandardMaterial3D" id="Material_def"]
albedo_color = Color(0.25, 0.15, 0.08, 1)

[node name="Torch" type="Node3D"]
script = ExtResource("1_abc")

[node name="Body" type="MeshInstance3D" parent="."]
mesh = SubResource("CylinderMesh_xyz")
surface_material_override/0 = SubResource("Material_def")

[node name="FlameLight" type="OmniLight3D" parent="."]
position = Vector3(0, 0.9, 0)
light_color = Color(1, 0.376, 0.125, 1)
light_energy = 2.0
omni_range = 4.0

[node name="FlameParticles" type="GPUParticles3D" parent="."]
position = Vector3(0, 0.9, 0)
amount = 16
```

Each `[node]` block is a node in the tree. `parent="."` means child of the root. `parent="Body"` would mean child of Body. Simple, readable, version-control friendly.

### Overrides on Instances

When you instance a scene, you can override specific properties on that instance without modifying the source scene. In the editor, overridden properties appear in a different color in the Inspector.

Useful patterns:
- All torches share the same mesh and particles, but one specific torch has a blue flame (override FlameLight color)
- All enemies use the same AI script, but a boss has `health = 500` while normal enemies have `health = 100` (override via @export)
- All rooms share the same lighting setup, but the final boss room has all lights set to red (override all light colors)

Overrides are stored in the parent scene that contains the instance, not in the source scene. Source stays clean.

---

## 3. Instancing Scenes at Runtime

### PackedScene and instantiate()

Spawning things at runtime is how you create enemies, bullets, pickups, explosions, UI popups — anything that needs to appear after the game starts. The pattern is always the same:

1. Get a reference to the scene as a `PackedScene`
2. Call `.instantiate()` to create a new node tree from it
3. Call `add_child()` to add it to the scene tree

```gdscript
extends Node3D

var enemy_scene: PackedScene = preload("res://enemies/goblin.tscn")

func spawn_enemy(spawn_position: Vector3) -> void:
    var enemy: Node3D = enemy_scene.instantiate()
    enemy.position = spawn_position
    add_child(enemy)
```

The instance returned by `.instantiate()` is the root node of the spawned scene. If `goblin.tscn` has a root node of type `CharacterBody3D`, the returned value is a `CharacterBody3D`.

### preload() vs load()

These are two ways to get a PackedScene reference, and they behave very differently:

```gdscript
# preload — evaluated at parse time (when the script file loads)
var bullet_scene: PackedScene = preload("res://weapons/bullet.tscn")

# load — evaluated at runtime when this line executes
var level_scene: PackedScene = load("res://levels/level_05.tscn")
```

**preload:**
- The path must be a string literal (no variables)
- Godot loads the resource when the script is first parsed
- If the path is wrong, you get an error at parse time — caught early
- Fast at runtime because it's already loaded
- Use for: scenes you know about when writing the script (enemies, bullets, effects)

**load:**
- The path can be a variable or expression
- Godot loads the resource when that line of code runs
- Slightly slower because it goes to disk
- Returns `null` if the file doesn't exist (you must handle this)
- Use for: dynamically determined content (load level from a variable, load a scene based on player choice)

```gdscript
extends Node3D

# preload for known scenes — loaded at parse time, always available
const GOBLIN_SCENE: PackedScene = preload("res://enemies/goblin.tscn")
const SKELETON_SCENE: PackedScene = preload("res://enemies/skeleton.tscn")
const BULLET_SCENE: PackedScene = preload("res://weapons/bullet.tscn")

# load for dynamic content — runtime decision
func load_level(level_number: int) -> void:
    var path := "res://levels/level_%02d.tscn" % level_number
    var scene: PackedScene = load(path)
    if scene == null:
        push_error("Level not found: " + path)
        return
    get_tree().change_scene_to_packed(scene)
```

Note the use of `const` for preloaded scenes — they never change after loading, so const is correct and more efficient than `var`.

### Full Spawn System Example

Here's a more complete spawn system showing the full pattern:

```gdscript
class_name EnemySpawner
extends Node3D

@export var enemy_scene: PackedScene
@export var max_enemies: int = 10
@export var spawn_interval: float = 3.0

var spawned_enemies: Array[Node] = []
var spawn_timer: float = 0.0

func _process(delta: float) -> void:
    if spawned_enemies.size() >= max_enemies:
        return

    spawn_timer += delta
    if spawn_timer >= spawn_interval:
        spawn_timer = 0.0
        spawn_one()

func spawn_one() -> void:
    if enemy_scene == null:
        push_error("EnemySpawner: no enemy_scene assigned!")
        return

    var enemy := enemy_scene.instantiate()
    enemy.position = global_position  # spawn at this node's world position

    # Listen for when this enemy dies so we can remove it from our list
    enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))

    add_child(enemy)
    spawned_enemies.append(enemy)

func _on_enemy_removed(enemy: Node) -> void:
    spawned_enemies.erase(enemy)

func despawn_all() -> void:
    for enemy in spawned_enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    spawned_enemies.clear()
```

### Removing Instances: queue_free()

Never call `free()` directly on a node that's in the scene tree. It removes and deletes it immediately, which can cause crashes if anything else is referencing it in the same frame.

Always use `queue_free()`:

```gdscript
# Wrong — can crash if something else references this node this frame
enemy.free()

# Right — marks for deletion at the end of the current frame
enemy.queue_free()

# Also right — same as queue_free() called from within the node itself
func die() -> void:
    queue_free()
```

`queue_free()` is safe because Godot waits until the end of the frame to actually delete the node, after all `_process()` calls have completed.

To check if a node is still valid (hasn't been queue_freed):

```gdscript
if is_instance_valid(some_node):
    some_node.do_something()
```

---

## 4. Node References and the $ Shorthand

### All the Ways to Find Nodes

Once you're inside a script, you need to get references to other nodes. Godot gives you several ways:

**Direct child by name — the `$` shorthand:**
```gdscript
# These are identical
var light := $FlameLight
var light := get_node("FlameLight")
```

**Path navigation:**
```gdscript
# Navigate down the tree
var health_bar := $UI/HUD/HealthBar
var attack_anim := $Model/AnimationPlayer

# Navigate up then down
var sibling := get_parent().get_node("OtherChild")

# Absolute path from scene root
var player := get_node("/root/GameScene/Player")
```

**`get_parent()` — go up one level:**
```gdscript
var parent_room: Node3D = get_parent()
```

**`get_children()` — all direct children as an array:**
```gdscript
var children := get_children()
for child in children:
    if child is MeshInstance3D:
        child.visible = false
```

**`get_tree()` — the whole scene tree:**
```gdscript
# Get all nodes with a specific name anywhere in the tree
var all_players := get_tree().get_nodes_in_group("players")
```

### Scene-Unique Names with %

Godot 4 introduced scene-unique names, and they're the best way to reference nodes you access often. Here's why the old way is fragile:

```gdscript
# Fragile — breaks if you reparent HealthLabel
@onready var health_label := $UI/HUD/HealthContainer/HealthLabel

# Also fragile — breaks if you rename any node in the path
@onready var anim_player := $Body/Rig/AnimationPlayer
```

With scene-unique names, enable "Access as Scene Unique Name" on a node (right-click the node in the Scene dock > Access as Scene Unique Name), and then reference it with `%`:

```gdscript
# Robust — works regardless of where HealthLabel is in the tree
@onready var health_label := %HealthLabel

# Works regardless of the AnimationPlayer's position in the hierarchy
@onready var anim_player := %AnimationPlayer
```

The `%` prefix tells Godot "find the node with this unique name anywhere in my scene, regardless of its path." You can reparent the node anywhere within the scene and the reference still works.

Rules for scene-unique names:
- Unique name must be unique within the scene (obviously)
- Only works for nodes within the same scene (not in instanced sub-scenes)
- The `%` syntax only works with `get_node()` or `$` from a node within the same scene

### The Full @onready Pattern

You can't access child nodes in the class body because the node tree isn't ready yet. Use `@onready`:

```gdscript
class_name Torch
extends Node3D

# These would be null if accessed at class body time
# @onready makes them initialize in _ready()
@onready var flame_light: OmniLight3D = %FlameLight
@onready var flame_particles: GPUParticles3D = %FlameParticles
@onready var flicker_timer: Timer = %FlickerTimer

func _ready() -> void:
    # Safe here — tree is ready
    flame_light.light_color = Color(1.0, 0.4, 0.1)
    flicker_timer.timeout.connect(_on_flicker)

func _on_flicker() -> void:
    flame_light.light_energy = randf_range(1.5, 2.5)
```

Without `@onready`, `flame_light` would be `null` when `_ready()` runs because the value would be evaluated during class body parsing, before the tree is set up.

### Typed Gets for Safety

When you get a node, Godot knows its type if you declare it:

```gdscript
# Untyped — valid but loses autocomplete and type safety
var light = $FlameLight

# Typed — autocomplete, type errors caught at runtime, clearer intent
var light: OmniLight3D = $FlameLight

# Cast with as — returns null if wrong type (no crash)
var light := $FlameLight as OmniLight3D
if light == null:
    push_error("FlameLight is not an OmniLight3D!")
    return
```

---

## 5. Groups: Broadcasting to Many Nodes

### What Groups Are

Groups are tags you apply to nodes. A node can be in any number of groups. Groups let you find and communicate with many nodes at once without holding direct references to all of them.

Think of groups as: "all nodes that share this characteristic." Common groups in real games:
- `"enemies"` — every enemy that can be targeted or damaged
- `"destructible"` — every object that can be broken
- `"interactable"` — everything the player can press E on
- `"save_data"` — every node that needs to write to the save file
- `"damageable"` — everything that has health
- `"pause_exempt"` — UI nodes that stay active when the game is paused

### Adding Nodes to Groups

**In the editor (best for permanent membership):**
- Select the node in the Scene dock
- In the Node dock (bottom right, next to Inspector), click the "Groups" tab
- Click "Add" and type the group name

**In code (good for dynamic membership):**
```gdscript
func _ready() -> void:
    add_to_group("enemies")
    add_to_group("damageable")

func die() -> void:
    remove_from_group("enemies")  # no longer targetable
    queue_free()
```

**Check membership:**
```gdscript
if node.is_in_group("enemies"):
    node.alert_nearby()
```

### Broadcasting with call_group()

The power of groups is calling a function on every member at once:

```gdscript
# Call take_damage(10) on every node in the "enemies" group
get_tree().call_group("enemies", "take_damage", 10)

# Same as above but only nodes currently in the viewport
get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "enemies", "take_damage", 10)
```

This is significantly cleaner than maintaining arrays of references and iterating them manually. The SceneTree handles the iteration, and if a node is queue_freed mid-broadcast, Godot handles that gracefully.

### Getting All Nodes in a Group

```gdscript
# Returns Array[Node]
var all_enemies := get_tree().get_nodes_in_group("enemies")

for enemy in all_enemies:
    var dist: float = global_position.distance_to(enemy.global_position)
    if dist < alert_range:
        enemy.alert()
```

### A Complete Group-Based Damage System

Here's a practical example: an explosion that damages everything in radius:

```gdscript
class_name Explosion
extends Area3D

@export var damage: float = 50.0
@export var force: float = 10.0

func _ready() -> void:
    # Detect all overlapping bodies on spawn
    body_entered.connect(_on_body_entered)
    # Self-destruct after animation
    await get_tree().create_timer(2.0).timeout
    queue_free()

func _on_body_entered(body: Node3D) -> void:
    # Check if this body is damageable
    if body.is_in_group("damageable"):
        body.take_damage(damage)

    # Apply physics force if it's a rigid body
    if body is RigidBody3D:
        var direction := (body.global_position - global_position).normalized()
        body.apply_central_impulse(direction * force)
```

And the base damageable script:

```gdscript
class_name Damageable
extends Node3D

signal died
signal health_changed(new_health: float, max_health: float)

@export var max_health: float = 100.0

var health: float:
    set(value):
        health = clampf(value, 0.0, max_health)
        health_changed.emit(health, max_health)
        if health <= 0.0:
            _die()

func _ready() -> void:
    health = max_health
    add_to_group("damageable")

func take_damage(amount: float) -> void:
    health -= amount

func _die() -> void:
    died.emit()
    queue_free()
```

### Groups as an Event Bus

Groups can also work as a lightweight event bus when combined with signals:

```gdscript
# Alert all enemies that the player has been spotted
func spotted_player(player: Node3D) -> void:
    var enemies := get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy.has_method("on_player_spotted"):
            enemy.on_player_spotted(player)
```

---

## 6. class_name: Custom Node Types

### Making Your Scripts First-Class Types

By default, a script is anonymous — it's just "a script." Adding `class_name` registers it with Godot's type system:

```gdscript
class_name Enemy
extends CharacterBody3D

@export var health: int = 100
@export var speed: float = 3.0
@export var damage: int = 10
@export var detection_range: float = 8.0

signal died
signal spotted_player(player: Node3D)
```

Once you add `class_name Enemy`, several things become true:

**1. It appears in the Add Node dialog.** Search "Enemy" in the Add Node dialog and it shows up. Your custom types are first-class citizens alongside built-in Godot nodes.

**2. You can type-check against it:**
```gdscript
# Check if a node is an Enemy (or a subclass of Enemy)
if node is Enemy:
    node.take_damage(10)

# Safe cast
var enemy := node as Enemy
if enemy != null:
    enemy.alert()
```

**3. You can use it as an @export type:**
```gdscript
class_name TowerDefenseBase
extends Node3D

# Inspector shows a slot that only accepts Enemy nodes
@export var target: Enemy

# Array of enemies
@export var priority_targets: Array[Enemy] = []
```

**4. You can use it in function signatures for type safety:**
```gdscript
func apply_debuff(target: Enemy, debuff_type: String, duration: float) -> void:
    target.add_debuff(debuff_type, duration)
```

### class_name Best Practices

Add `class_name` to any script you'll:
- Reference by type in other scripts
- Use as an @export type
- Type-check against with `is`
- Subclass in inherited scenes

Don't bother with `class_name` for:
- One-off scripts with no external references
- Simple autoloads that are singletons (though you can)
- Anonymous helper scripts

```gdscript
# Good candidates for class_name
class_name Player extends CharacterBody3D
class_name Enemy extends CharacterBody3D
class_name Projectile extends Area3D
class_name Door extends StaticBody3D
class_name CollectibleItem extends Area3D
class_name WeaponData extends Resource  # Resources too!

# Probably don't need class_name
# (just a level-specific script with no outside references)
extends Node3D
func _ready() -> void:
    start_cutscene()
```

### Inner Classes

Scripts can also have inner classes (no separate file needed):

```gdscript
class_name StatusEffectManager
extends Node

class StatusEffect:
    var name: String
    var duration: float
    var damage_per_second: float

    func _init(n: String, d: float, dps: float) -> void:
        name = n
        duration = d
        damage_per_second = dps

var active_effects: Array[StatusEffect] = []

func add_effect(effect: StatusEffect) -> void:
    active_effects.append(effect)
```

Inner classes are useful for data structures that don't need to be full nodes or resources.

---

## 7. Scene Inheritance

### The Problem Scene Inheritance Solves

You have five enemy types. They all share:
- The same physics setup (CharacterBody3D + CollisionShape3D)
- The same health/damage system
- The same navigation agent (NavigationAgent3D)
- The same detection radius (Area3D)

But each has different:
- Meshes
- Stats (health, speed, damage)
- Special abilities

Without scene inheritance, you'd either copy-paste the base setup five times (nightmare to maintain) or try to cram all variants into one scene with visibility toggles (also a nightmare).

Scene inheritance gives you a base scene that defines the shared structure, and inherited scenes that extend it.

### Creating an Inherited Scene

1. Build and save your base scene: `base_enemy.tscn`
2. In the FileSystem dock, right-click `base_enemy.tscn`
3. Select "New Inherited Scene"
4. Save as `goblin.tscn`

The inherited scene starts as an exact copy of the base. The difference: any node that exists in the base is shown with a yellow icon in the Scene dock, indicating it's inherited. You can:
- Override properties on inherited nodes
- Add new child nodes to inherited nodes
- Add entirely new nodes at the root level
- You CANNOT delete or reparent inherited nodes (without placeholdering them)

### Base Enemy Scene

```
BaseEnemy (CharacterBody3D) — base_enemy.tscn
├── CollisionShape3D (CapsuleShape3D)
├── MeshInstance3D (placeholder — subclasses swap the mesh)
├── NavigationAgent3D
├── Area3D (detection radius)
│   └── CollisionShape3D (SphereShape3D, radius 6)
├── AnimationPlayer
├── AudioStreamPlayer3D
└── Marker3D (loot spawn point)
```

Base script:

```gdscript
class_name BaseEnemy
extends CharacterBody3D

signal died(position: Vector3)
signal spotted_player(player: Node3D)

@export var health: int = 100
@export var speed: float = 3.0
@export var damage: int = 10
@export var loot_table: Array[PackedScene] = []

@onready var nav_agent: NavigationAgent3D = %NavigationAgent3D
@onready var detection_area: Area3D = %DetectionArea
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var loot_spawn: Marker3D = %LootSpawn

var target: Node3D = null
var is_alive: bool = true

func _ready() -> void:
    add_to_group("enemies")
    add_to_group("damageable")
    detection_area.body_entered.connect(_on_detection_area_body_entered)

func _physics_process(delta: float) -> void:
    if not is_alive or target == null:
        return
    _move_toward_target(delta)

func _move_toward_target(_delta: float) -> void:
    nav_agent.target_position = target.global_position
    var next_pos := nav_agent.get_next_path_position()
    var direction := (next_pos - global_position).normalized()
    velocity = direction * speed
    move_and_slide()

func take_damage(amount: int) -> void:
    if not is_alive:
        return
    health -= amount
    if health <= 0:
        die()

func die() -> void:
    is_alive = false
    remove_from_group("enemies")
    died.emit(global_position)
    _spawn_loot()
    queue_free()

func _spawn_loot() -> void:
    for loot_scene in loot_table:
        var loot := loot_scene.instantiate()
        loot.global_position = loot_spawn.global_position
        get_parent().add_child(loot)

func _on_detection_area_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        target = body
        spotted_player.emit(body)
```

### Goblin Inherited Scene

The Goblin inherits from BaseEnemy and overrides with goblin-specific values:

```gdscript
class_name Goblin
extends BaseEnemy

# Goblins are fast and weak
func _ready() -> void:
    super._ready()
    health = 40
    speed = 5.5
    damage = 5

func die() -> void:
    # Goblins screech when they die
    %AudioStreamPlayer3D.play()
    await %AudioStreamPlayer3D.finished
    super.die()
```

In the editor, the Goblin scene:
- Swaps the MeshInstance3D mesh to a goblin model (override on inherited node)
- Adds a `GoblinScreech.ogg` to the AudioStreamPlayer3D
- Changes the CollisionShape3D to be shorter

### Skeleton Inherited Scene

```gdscript
class_name Skeleton
extends BaseEnemy

@export var bone_projectile: PackedScene = preload("res://projectiles/bone.tscn")
@export var attack_range: float = 8.0

func _ready() -> void:
    super._ready()
    health = 60
    speed = 2.0
    damage = 15

func _physics_process(delta: float) -> void:
    if target == null or not is_alive:
        return

    var dist := global_position.distance_to(target.global_position)
    if dist <= attack_range:
        _ranged_attack()
    else:
        super._physics_process(delta)  # move toward target normally

func _ranged_attack() -> void:
    if not %AttackTimer.is_stopped():
        return
    var proj := bone_projectile.instantiate()
    proj.global_position = %BoneThrowPoint.global_position
    proj.direction = (target.global_position - global_position).normalized()
    get_parent().add_child(proj)
    %AttackTimer.start(2.0)
```

### Dragon Boss Inherited Scene

```gdscript
class_name Dragon
extends BaseEnemy

@export var fire_breath_scene: PackedScene = preload("res://abilities/fire_breath.tscn")
@export var phase_two_threshold: float = 0.5  # enter phase 2 at 50% health

var in_phase_two: bool = false

func _ready() -> void:
    super._ready()
    health = 2000
    speed = 4.0
    damage = 75

func take_damage(amount: int) -> void:
    super.take_damage(amount)
    var health_ratio := float(health) / float(2000)
    if health_ratio <= phase_two_threshold and not in_phase_two:
        _enter_phase_two()

func _enter_phase_two() -> void:
    in_phase_two = true
    speed *= 1.5
    # Change material to show damage
    %MeshInstance3D.set_surface_override_material(0, preload("res://materials/dragon_damaged.tres"))
    %AnimationPlayer.play("enrage")

func die() -> void:
    # Dramatic death sequence — don't call super immediately
    %AnimationPlayer.play("death")
    await %AnimationPlayer.animation_finished
    super.die()
```

This inheritance chain (Dragon → BaseEnemy → CharacterBody3D) gives you everything for free while letting each variant override exactly what it needs.

---

## 8. Resources: Data Containers

### What Resources Are

Resources are data objects that save to disk as `.tres` (text) or `.res` (binary) files. They're not nodes — they have no transform, no physics, no place in the scene tree. They're pure data.

Godot uses resources everywhere internally: Meshes, Materials, Textures, AudioStreams, Fonts — all resources. You can create your own.

### Creating a Custom Resource

```gdscript
class_name WeaponData
extends Resource

@export var weapon_name: String = "Iron Sword"
@export var damage: float = 10.0
@export var attack_speed: float = 1.0
@export var range: float = 1.5
@export var icon: Texture2D
@export var attack_animation: StringName = &"slash"
@export var hit_sound: AudioStream
@export var is_two_handed: bool = false
```

To create a `.tres` file in the editor:
- FileSystem dock > Right-click > New Resource
- Search for "WeaponData" in the dialog
- Save as e.g. `res://data/weapons/iron_sword.tres`
- Click the file to open it in the Inspector and fill in the values

### Using Resources in Nodes

```gdscript
class_name PlayerWeapon
extends Node3D

@export var weapon_data: WeaponData

func _ready() -> void:
    if weapon_data == null:
        push_error("PlayerWeapon: no weapon_data assigned!")
        return
    print("Equipped: ", weapon_data.weapon_name)
    print("Damage: ", weapon_data.damage)
    _apply_weapon_stats()

func _apply_weapon_stats() -> void:
    %AttackCooldownTimer.wait_time = 1.0 / weapon_data.attack_speed

func attack(target: Node3D) -> void:
    if target.has_method("take_damage"):
        target.take_damage(weapon_data.damage)
    %AnimationPlayer.play(weapon_data.attack_animation)
    %AudioStreamPlayer3D.stream = weapon_data.hit_sound
    %AudioStreamPlayer3D.play()
```

In the Inspector, drag your `iron_sword.tres` into the `weapon_data` slot. Swap to `flame_sword.tres` to change weapons entirely without touching code.

### Resources Are Shared by Default

Important: if two nodes reference the same `.tres` file, they share the same resource object. Modifying one modifies both:

```gdscript
# Both nodes reference the same iron_sword.tres
# Changing damage here changes it for all nodes using iron_sword.tres
func upgrade_weapon() -> void:
    weapon_data.damage += 5.0  # MODIFIES THE SHARED RESOURCE
```

To get an independent copy, use `.duplicate()`:

```gdscript
func _ready() -> void:
    # Create a per-instance copy so upgrades don't affect other nodes
    weapon_data = weapon_data.duplicate()
```

This pattern is common for stat systems where each enemy has the same base stats resource but individual modified copies.

### Resources vs Nodes: When to Use Which

| Use a Node when... | Use a Resource when... |
|---|---|
| The thing needs to exist in the scene tree | The thing is pure data with no world presence |
| The thing needs physics, transform, signals | The thing needs to be saved and loaded as a file |
| The thing processes/updates every frame | The thing is shared between many instances |
| The thing is visible or has spatial presence | The thing is configured in the editor inspector |

Examples: Enemies are nodes. Enemy stats are resources. Sound effects are resources (AudioStream). The AudioStreamPlayer3D that plays them is a node. Mesh geometry is a resource (Mesh). The MeshInstance3D that renders it is a node.

Module 5 goes much deeper into resources — data-driven design, save systems, and custom resource importers.

---

## 9. The SceneTree

### Accessing the SceneTree

Every node in the tree has access to the SceneTree via `get_tree()`. The SceneTree is the manager of the entire running game.

```gdscript
# Get the SceneTree
var tree := get_tree()
```

### Changing Scenes

The most common SceneTree operation: loading a completely new scene:

```gdscript
# Change scene by file path — old scene is freed
get_tree().change_scene_to_file("res://levels/level_02.tscn")

# Change scene from a PackedScene reference
var next_level: PackedScene = preload("res://levels/level_02.tscn")
get_tree().change_scene_to_packed(next_level)
```

Both methods free the current scene and load the new one. Use `change_scene_to_packed` when you have the PackedScene already loaded (avoids a second disk read).

For persistent data between scene changes (player stats, inventory), use an Autoload singleton — covered in Module 4.

### Pausing the Game

```gdscript
# Pause — _process and _physics_process stop for most nodes
get_tree().paused = true

# Resume
get_tree().paused = false
```

By default, when the tree is paused, all node processing stops. To make a node keep running while paused (like a pause menu):

```gdscript
# In the pause menu script
func _ready() -> void:
    # This node (and its children) process even when tree is paused
    process_mode = Node.PROCESS_MODE_ALWAYS
```

Process modes:

| Mode | Behavior |
|---|---|
| `PROCESS_MODE_INHERIT` | Default — inherits parent's mode |
| `PROCESS_MODE_PAUSABLE` | Stops when tree is paused (default for most nodes) |
| `PROCESS_MODE_WHEN_PAUSED` | Only processes when tree IS paused |
| `PROCESS_MODE_ALWAYS` | Always processes regardless of pause state |
| `PROCESS_MODE_DISABLED` | Never processes |

Typical pause menu setup:

```gdscript
class_name PauseMenu
extends Control

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        _toggle_pause()

func _toggle_pause() -> void:
    get_tree().paused = not get_tree().paused
    visible = get_tree().paused
```

### One-Shot Timers with create_timer()

For simple delays without adding a Timer node:

```gdscript
# Wait 2 seconds then do something
await get_tree().create_timer(2.0).timeout
do_the_thing()

# In a function
func delayed_spawn() -> void:
    await get_tree().create_timer(1.5).timeout
    spawn_enemy(Vector3.ZERO)
```

`create_timer()` creates a temporary timer that emits `timeout` once and is cleaned up. Much lighter than adding a Timer node for a one-off delay.

For a timer that keeps running even when paused, pass `true` for `process_always`:

```gdscript
await get_tree().create_timer(2.0, true).timeout  # runs even when paused
```

### Quitting the Game

```gdscript
get_tree().quit()

# With an exit code (for CI/testing)
get_tree().quit(0)   # success
get_tree().quit(1)   # error
```

### Useful SceneTree Properties

```gdscript
# Current number of frames rendered
var frame_count: int = get_tree().get_frame()

# All nodes in a group
var enemies := get_tree().get_nodes_in_group("enemies")

# Number of nodes currently in the tree
var node_count: int = get_tree().get_node_count()

# The root viewport
var root := get_tree().root
```

---

## 10. Ownership and Saved Scenes

### How Scene Saving Works

When Godot saves a `.tscn` file, it only saves nodes that are **owned** by the scene root. The `owner` property of a node determines this.

When you add a node through the editor, Godot automatically sets its `owner` to the scene root. When you `add_child()` at runtime, Godot does NOT set ownership — the node is ephemeral.

```gdscript
# This node will NOT be saved when the scene is saved to disk
# It only exists at runtime
func _ready() -> void:
    var marker := Marker3D.new()
    marker.name = "RuntimeMarker"
    add_child(marker)
    # marker.owner is null — not saved
```

### Ownership in Tool Scripts

If you're writing a `@tool` script that adds nodes through code (for editor use), you must set ownership:

```gdscript
@tool
extends EditorScript

func _run() -> void:
    var root := EditorInterface.get_edited_scene_root()
    var new_node := Node3D.new()
    new_node.name = "GeneratedNode"
    root.add_child(new_node)
    new_node.owner = root  # Without this, won't be saved!
```

### Practical Implications

For runtime-spawned enemies, projectiles, and effects — you don't want them saved. Their `owner` being null is correct. They spawn, they do their thing, they queue_free.

For procedural generation that you want to bake into a scene (e.g., generate a dungeon layout once and save it), you need to set ownership.

For save games, you need a different approach — serialize the game state to a file (Module 6) rather than relying on scene saving.

```gdscript
# Properly set ownership for a node you want saved (tool scripts, editor plugins)
func add_permanent_node(parent: Node, new_node: Node) -> void:
    parent.add_child(new_node)
    new_node.owner = get_tree().edited_scene_root
    # Now new_node will be included when scene is saved
```

---

## 11. Code Walkthrough: Modular Dungeon Builder

### Project Structure

```
res://
├── autoloads/
│   └── dungeon_manager.gd
├── enemies/
│   ├── base_enemy.tscn
│   ├── base_enemy.gd
│   ├── goblin.tscn
│   ├── goblin.gd
│   ├── skeleton.tscn
│   └── skeleton.gd
├── props/
│   ├── torch.tscn
│   └── chest.tscn
├── rooms/
│   ├── room_base.tscn
│   ├── room_base.gd
│   ├── room_start.tscn
│   ├── room_hallway.tscn
│   ├── room_treasure.tscn
│   └── room_boss.tscn
├── player/
│   ├── player.tscn
│   └── player.gd
└── main.tscn
```

### Room Base Scene

The base room scene is a reusable building block:

```
RoomBase (Node3D) — room_base.tscn
├── Floor (StaticBody3D)
│   ├── MeshInstance3D (plane mesh, stone material)
│   └── CollisionShape3D (box)
├── Walls (Node3D)  — container for wall segments
│   ├── WallNorth (StaticBody3D + MeshInstance3D + CollisionShape3D)
│   ├── WallSouth (StaticBody3D + MeshInstance3D + CollisionShape3D)
│   ├── WallEast  (StaticBody3D + MeshInstance3D + CollisionShape3D)
│   └── WallWest  (StaticBody3D + MeshInstance3D + CollisionShape3D)
├── DoorMarkers (Node3D) — where connecting rooms attach
│   ├── DoorNorth (Marker3D)
│   ├── DoorSouth (Marker3D)
│   ├── DoorEast  (Marker3D)
│   └── DoorWest  (Marker3D)
├── PropSlots (Node3D) — where torches, chests, etc. go
│   ├── PropSlot1 (Marker3D)
│   ├── PropSlot2 (Marker3D)
│   ├── PropSlot3 (Marker3D)
│   └── PropSlot4 (Marker3D)
├── EnemySpawns (Node3D)
│   ├── Spawn1 (Marker3D)
│   └── Spawn2 (Marker3D)
└── NavigationRegion3D (baked nav mesh for this room)
```

Room base script:

```gdscript
class_name RoomBase
extends Node3D

signal room_cleared
signal player_entered(player: Node3D)

enum RoomType { START, HALLWAY, TREASURE, BOSS, STANDARD }

@export var room_type: RoomType = RoomType.STANDARD
@export var room_size: Vector2 = Vector2(10, 10)
@export var prop_scenes: Array[PackedScene] = []
@export var enemy_scenes: Array[PackedScene] = []
@export var max_enemies: int = 3

@onready var door_markers: Node3D = %DoorMarkers
@onready var prop_slots: Node3D = %PropSlots
@onready var enemy_spawns: Node3D = %EnemySpawns

var active_enemies: int = 0
var is_cleared: bool = false
var is_visited: bool = false
var connections: Dictionary = {}  # direction -> connected RoomBase

func _ready() -> void:
    add_to_group("rooms")
    _populate_props()

func activate() -> void:
    # Called when player enters this room
    if not is_visited:
        is_visited = true
        _spawn_enemies()

func _populate_props() -> void:
    if prop_scenes.is_empty():
        return
    var slots := prop_slots.get_children()
    for slot in slots:
        if randf() > 0.5:  # 50% chance to place a prop
            var prop := prop_scenes.pick_random().instantiate()
            prop.global_position = slot.global_position
            add_child(prop)

func _spawn_enemies() -> void:
    if enemy_scenes.is_empty() or room_type == RoomType.START:
        return
    var spawns := enemy_spawns.get_children()
    var spawn_count := mini(max_enemies, spawns.size())
    for i in spawn_count:
        var enemy := enemy_scenes.pick_random().instantiate()
        enemy.global_position = spawns[i].global_position
        enemy.died.connect(_on_enemy_died)
        add_child(enemy)
        active_enemies += 1

func _on_enemy_died(_position: Vector3) -> void:
    active_enemies -= 1
    if active_enemies <= 0 and not is_cleared:
        is_cleared = true
        room_cleared.emit()

func get_door_marker(direction: String) -> Marker3D:
    return door_markers.get_node(direction) as Marker3D

func connect_room(direction: String, other_room: RoomBase) -> void:
    connections[direction] = other_room
```

### Room Variants

The treasure room inherits from RoomBase and adds a chest:

```gdscript
# room_treasure.gd (on room_treasure.tscn, inherited from room_base.tscn)
class_name RoomTreasure
extends RoomBase

const CHEST_SCENE: PackedScene = preload("res://props/chest.tscn")

func _ready() -> void:
    room_type = RoomType.TREASURE
    max_enemies = 1  # fewer enemies but a chest reward
    super._ready()
    _place_chest()

func _place_chest() -> void:
    var chest := CHEST_SCENE.instantiate()
    # Place chest in the center of the room
    chest.global_position = global_position + Vector3(0, 0, 0)
    add_child(chest)
```

### Dungeon Generator

This is the main scene's script — or an autoload:

```gdscript
class_name DungeonManager
extends Node

const ROOM_SIZE: float = 12.0  # world units between room centers

var room_scenes: Array[PackedScene] = [
    preload("res://rooms/room_start.tscn"),
    preload("res://rooms/room_hallway.tscn"),
    preload("res://rooms/room_treasure.tscn"),
    preload("res://rooms/room_boss.tscn"),
]

var rooms: Array[RoomBase] = []
var room_grid: Dictionary = {}  # Vector2i -> RoomBase
var current_room: RoomBase = null

func generate_dungeon(num_rooms: int) -> void:
    _clear_existing()
    _place_start_room()
    _expand_dungeon(num_rooms - 2)  # -2 for start and boss rooms
    _place_boss_room()
    print("Dungeon generated: %d rooms" % rooms.size())

func _clear_existing() -> void:
    for room in rooms:
        if is_instance_valid(room):
            room.queue_free()
    rooms.clear()
    room_grid.clear()

func _place_start_room() -> void:
    var start_scene := room_scenes[0]  # room_start.tscn
    var start_room: RoomBase = start_scene.instantiate()
    start_room.position = Vector3.ZERO
    add_child(start_room)
    rooms.append(start_room)
    room_grid[Vector2i.ZERO] = start_room
    current_room = start_room

func _expand_dungeon(num_rooms: int) -> void:
    var attempts := 0
    var max_attempts := num_rooms * 10

    while rooms.size() < num_rooms + 1 and attempts < max_attempts:
        attempts += 1
        # Pick a random existing room and try to add a neighbor
        var source_room: RoomBase = rooms.pick_random()
        var source_grid_pos := _world_to_grid(source_room.position)
        var direction := _random_direction()
        var target_grid_pos := source_grid_pos + direction

        if room_grid.has(target_grid_pos):
            continue  # Already occupied

        # Pick a random non-boss, non-start room type
        var room_scene := room_scenes[1 + randi() % (room_scenes.size() - 2)]
        var new_room: RoomBase = room_scene.instantiate()
        new_room.position = Vector3(
            target_grid_pos.x * ROOM_SIZE,
            0,
            target_grid_pos.y * ROOM_SIZE
        )
        add_child(new_room)
        rooms.append(new_room)
        room_grid[target_grid_pos] = new_room

func _place_boss_room() -> void:
    # Place boss room at the farthest point from start
    var farthest_pos := Vector2i.ZERO
    var max_dist := 0
    for grid_pos in room_grid.keys():
        var dist := absi(grid_pos.x) + absi(grid_pos.y)  # Manhattan distance
        if dist > max_dist:
            max_dist = dist
            farthest_pos = grid_pos

    # Find a free neighbor of the farthest room
    for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        var candidate := farthest_pos + dir
        if not room_grid.has(candidate):
            var boss_room: RoomBase = room_scenes[3].instantiate()  # room_boss.tscn
            boss_room.position = Vector3(
                candidate.x * ROOM_SIZE,
                0,
                candidate.y * ROOM_SIZE
            )
            add_child(boss_room)
            rooms.append(boss_room)
            room_grid[candidate] = boss_room
            return

func _world_to_grid(world_pos: Vector3) -> Vector2i:
    return Vector2i(
        roundi(world_pos.x / ROOM_SIZE),
        roundi(world_pos.z / ROOM_SIZE)
    )

func _random_direction() -> Vector2i:
    var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
    return dirs[randi() % dirs.size()]

func get_room_at_world_pos(world_pos: Vector3) -> RoomBase:
    var grid_pos := _world_to_grid(world_pos)
    return room_grid.get(grid_pos, null)
```

### Player Script

Simple player to walk through the dungeon:

```gdscript
class_name Player
extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.002

@onready var camera: Camera3D = %Camera3D
@onready var dungeon_manager: DungeonManager = null

var pitch: float = 0.0

func _ready() -> void:
    add_to_group("player")
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    # Find the dungeon manager
    dungeon_manager = get_tree().get_first_node_in_group("dungeon_manager")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        pitch -= event.relative.y * mouse_sensitivity
        pitch = clampf(pitch, -PI / 3.0, PI / 3.0)
        camera.rotation.x = pitch
    if event.is_action_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(_delta: float) -> void:
    var input_dir := Input.get_vector(
        "move_left", "move_right", "move_forward", "move_back"
    )
    var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if is_on_floor():
        velocity.x = move_dir.x * speed
        velocity.z = move_dir.z * speed
    else:
        velocity.y -= 9.8 * _delta  # gravity

    move_and_slide()

    # Notify dungeon manager of player position (for room activation)
    if dungeon_manager != null:
        var room := dungeon_manager.get_room_at_world_pos(global_position)
        if room != null and room != dungeon_manager.current_room:
            dungeon_manager.current_room = room
            room.activate()
```

### Main Scene Setup

The main scene script ties everything together:

```gdscript
extends Node3D

@onready var dungeon_manager: DungeonManager = %DungeonManager
@onready var player: Player = %Player

func _ready() -> void:
    dungeon_manager.generate_dungeon(10)  # 10-room dungeon
    # Spawn player at first room's position
    if dungeon_manager.rooms.size() > 0:
        player.global_position = dungeon_manager.rooms[0].global_position + Vector3(0, 1, 0)
```

The scene tree for `main.tscn`:
```
Main (Node3D)
├── DungeonManager (DungeonManager) — the generator, rooms get added here as children
├── Player (CharacterBody3D with player.gd)
│   ├── CollisionShape3D
│   └── Camera3D (first person)
├── DirectionalLight3D (ambient dungeon lighting)
└── WorldEnvironment (fog settings for atmosphere)
```

---

## API Quick Reference

### Node

| Method / Property | Description |
|---|---|
| `add_child(node)` | Add a node as a child |
| `remove_child(node)` | Remove a child (node is not freed) |
| `queue_free()` | Mark for deletion at end of frame |
| `get_node("path")` | Get a node by path string |
| `get_node_or_null("path")` | Get node or null if not found |
| `get_children()` | Array of all direct children |
| `get_parent()` | Parent node |
| `get_child(index)` | Child by index |
| `get_child_count()` | Number of direct children |
| `has_node("path")` | Check if node exists at path |
| `add_to_group("name")` | Add to a group |
| `remove_from_group("name")` | Remove from a group |
| `is_in_group("name")` | Check group membership |
| `reparent(new_parent)` | Move to new parent, keep world transform |
| `is_inside_tree()` | Whether node is currently in the tree |
| `owner` | The node that owns this one (for scene saving) |
| `process_mode` | How node behaves when tree is paused |
| `name` | Node name |

### SceneTree

| Method / Property | Description |
|---|---|
| `change_scene_to_file(path)` | Load new scene from path |
| `change_scene_to_packed(scene)` | Load new scene from PackedScene |
| `paused` | Get/set pause state |
| `quit(code)` | Exit the game |
| `create_timer(time)` | One-shot timer, returns SceneTreeTimer |
| `call_group("name", "method", args)` | Call method on all group members |
| `get_nodes_in_group("name")` | Array of all nodes in group |
| `get_first_node_in_group("name")` | First node in group (useful for singletons) |
| `get_node_count()` | Total nodes in tree |
| `root` | The root Window node |
| `current_scene` | The currently active scene node |

### PackedScene

| Method | Description |
|---|---|
| `instantiate()` | Create a new instance of the scene |
| `can_instantiate()` | Check if scene can be instantiated |

### ResourceLoader

| Method | Description |
|---|---|
| `preload("path")` | Compile-time load (keyword, not a method) |
| `load("path")` | Runtime load, returns Resource or null |
| `load_threaded_request("path")` | Begin async background load |
| `load_threaded_get_status("path")` | Check async load status |
| `load_threaded_get("path")` | Get result of async load |

### class_name

```gdscript
class_name MyClass       # registers as a type
extends BaseClass        # inherits from base

# Now usable as:
# - Type in Add Node dialog
# - Type annotation: var x: MyClass
# - Type check: if node is MyClass
# - Export type: @export var ref: MyClass
```

### owner

```gdscript
# Set ownership so node is saved with scene (tool scripts only)
new_node.owner = get_tree().edited_scene_root

# Check ownership
if node.owner == scene_root:
    print("This node will be saved")
```

---

## Common Pitfalls

### 1. Adding a Node That's Already in a Tree

**WRONG:**
```gdscript
var enemy := ENEMY_SCENE.instantiate()
add_child(enemy)
# ... later, try to move it to a different parent ...
other_node.add_child(enemy)  # ERROR: node already has parent
```

**RIGHT:**
```gdscript
var enemy := ENEMY_SCENE.instantiate()
add_child(enemy)
# ... later, move it properly ...
enemy.reparent(other_node)  # reparent() handles removing from old parent first

# Or remove then add:
enemy.get_parent().remove_child(enemy)
other_node.add_child(enemy)
```

Always use `reparent()` when you need to move a node between parents. It preserves the world transform by default.

### 2. Calling load() Every Frame

**WRONG:**
```gdscript
func _process(delta: float) -> void:
    if should_spawn:
        var scene = load("res://enemies/goblin.tscn")  # disk access every frame!
        var enemy = scene.instantiate()
        add_child(enemy)
```

**RIGHT:**
```gdscript
const GOBLIN_SCENE: PackedScene = preload("res://enemies/goblin.tscn")  # once at parse time

func _process(delta: float) -> void:
    if should_spawn:
        var enemy := GOBLIN_SCENE.instantiate()  # just cloning, no disk access
        add_child(enemy)
```

Load from disk once. Clone (instantiate) as many times as needed. `preload` and `const` together are the standard pattern for scenes you spawn frequently.

### 3. Expecting Runtime-Spawned Nodes to Persist in Saved Scenes

**WRONG:**
```gdscript
func _ready() -> void:
    var extra_torch := preload("res://props/torch.tscn").instantiate()
    extra_torch.position = Vector3(2, 0, 0)
    add_child(extra_torch)
    # Expected: this torch appears when I reopen the editor
    # Reality: it doesn't. It only exists at runtime.
```

**RIGHT:**
```gdscript
# Option A: Place the torch in the scene editor (not via script)
# Drag torch.tscn into the scene — now it's in the .tscn file

# Option B: For tool scripts, set ownership
@tool
extends Node3D
func _add_torch_to_scene() -> void:
    var torch := preload("res://props/torch.tscn").instantiate()
    torch.position = Vector3(2, 0, 0)
    add_child(torch)
    torch.owner = get_tree().edited_scene_root  # now it saves
```

Nodes spawned via `add_child()` in a `@tool` script need their `owner` set to appear in the saved scene. Nodes spawned in regular `_ready()` are runtime-only — correct and expected for gameplay spawning.

### 4. Deep $ Paths That Break on Reparenting

**WRONG:**
```gdscript
# This breaks if you move HealthLabel anywhere in the scene
@onready var health_label := $UI/HUD/PlayerInfo/StatsPanel/HealthLabel
```

**RIGHT:**
```gdscript
# Right-click HealthLabel in Scene dock > Access as Scene Unique Name
# Then reference it with %
@onready var health_label := %HealthLabel
```

Use the `%UniqueName` pattern for any node you reference often in scripts. It survives reparenting, scene reorganization, and structural changes. Reserve `$Path/To/Node` for short paths to nodes that are structurally stable (like direct children).

### 5. Giant Monolithic Scenes

**WRONG:**
```
GameLevel (Node3D)  ← one massive .tscn file
├── Player (CharacterBody3D)
│   ├── ... 30 nodes for player ...
├── Enemy1 (CharacterBody3D)
│   ├── ... 15 nodes for enemy ...
├── Enemy2 (CharacterBody3D)
│   ├── ... 15 nodes for enemy ...
├── Torch1 (Node3D)
│   ├── ... 3 nodes for torch ...
├── Torch2 ... 9 more copies ...
├── UI (Control)
│   ├── ... 25 nodes for HUD ...
└── ... etc
```

**RIGHT:**
```
GameLevel (Node3D)  ← instances sub-scenes
├── Player (instance of player.tscn)
├── Enemy1 (instance of goblin.tscn)
├── Enemy2 (instance of goblin.tscn)
├── Torch1 (instance of torch.tscn)
├── Torch2 ... etc
└── HUD (instance of hud.tscn)
```

One scene per reusable thing. The level scene should be mostly references to other scenes. This makes iteration fast (edit torch.tscn, all torches update), collaboration possible (different team members work on different scenes), and keeps individual files manageable.

---

## Exercises

### Exercise 1: Reusable Collectible Scene (30–45 minutes)

Build a collectible gem that the player can pick up.

**Requirements:**
- Scene structure:
  ```
  Collectible (Area3D)
  ├── MeshInstance3D (sphere or gem mesh)
  ├── CollisionShape3D (sphere collision)
  ├── OmniLight3D (glowing aura)
  ├── GPUParticles3D (sparkle effect)
  └── AnimationPlayer (bobbing up and down)
  ```
- Script on root:
  - Signal: `collected(value: int)`
  - `@export var gem_value: int = 10`
  - When an `Area3D.body_entered` fires for a node in the `"player"` group: emit `collected`, play a pickup sound, and `queue_free()`
- Animate the gem bobbing with AnimationPlayer (oscillate position Y between -0.1 and 0.1)
- Save as `res://collectibles/gem.tscn`
- Create a test level: scatter 10 instances (different gem_value on each), have a counter Label update when collected

**Stretch goal:** Create a `GemData` resource with `value`, `color`, and `icon`. Create 3 `.tres` files (common, rare, legendary). Have the Collectible scene take a `@export var gem_data: GemData` and apply the color to the mesh material.

### Exercise 2: Enemy SpawnPoint with Variants (45–60 minutes)

Build a spawn point that creates random enemy variants at intervals.

**Requirements:**
- Create a base `EnemyBase.gd` script (class_name, health, speed, take_damage, die)
- Create 3 inherited scenes: `enemy_slow.tscn` (high health, low speed), `enemy_fast.tscn` (low health, high speed), `enemy_balanced.tscn`
- Each variant overrides stats in its `_ready()` via `super._ready()`
- `SpawnPoint` scene:
  ```
  SpawnPoint (Node3D)
  ├── Marker3D (spawn position)
  └── Timer (5 second interval, autostart)
  ```
- SpawnPoint script:
  - `@export var enemy_variants: Array[PackedScene]`
  - `@export var max_spawned: int = 5`
  - On Timer timeout: if `spawned_count < max_spawned`, instantiate a random variant
  - Track spawned count with `tree_exited` signal
  - `@export var spawn_count: int = 0` visible in inspector for debugging
- Place 3 SpawnPoints in a test level with different enemy_variants arrays

**Stretch goal:** Add a `difficulty_multiplier: float` export that scales spawned enemies' health and speed using a custom `scale_difficulty(float)` method on EnemyBase.

### Exercise 3: Dungeon Builder Extensions (60–90 minutes)

Extend the dungeon builder from the walkthrough with three additions.

**Part A: Minimap (using groups)**
- Each `RoomBase._ready()` adds itself to group `"rooms"` and stores its grid position
- Create a `Minimap` Control node (CanvasLayer > Control > custom drawn)
- In `Minimap._process()`: get all nodes in `"rooms"` group, draw a small square for each room at its grid position (visited rooms: white, unvisited: dark gray, current: yellow)
- Use `get_tree().get_nodes_in_group("rooms")` — no direct references needed

**Part B: Locked Door Logic**
- Create a `Key` collectible scene (inherits from the gem scene) — emits `key_collected` signal when picked up
- Create a `LockedDoor` StaticBody3D that blocks passage between rooms
- `LockedDoor` listens for the `key_collected` signal (connect via group or Autoload)
- When the signal fires, animate the door opening (AnimationPlayer rotating the door mesh)
- Place one locked door between the start room and the rest of the dungeon
- Spawn one Key in the start room

**Part C: Room Enemy Spawners**
- Modify the `DungeonManager` to assign `enemy_scenes` arrays to room instances after generating them
- Standard rooms get goblins, treasure rooms get skeletons (tougher guards), boss room gets the dragon
- Hook up `room.room_cleared` signal: when all enemies die, spawn a chest (from `chest.tscn`) at the room center

---

## Key Takeaways

1. **Scenes are Godot's composition unit.** Build small, focused scenes. Compose them into larger ones. A scene can be a torch, a door, an enemy, a room, or an entire level. The scale is up to you.

2. **PackedScene.instantiate() is how you spawn anything at runtime.** Store your PackedScene references as `const` with `preload()` for scenes you know at compile time. The instance is just a new tree of nodes — set properties on it before or after `add_child()`.

3. **preload() for scenes you know about at compile time, load() for dynamic content.** preload is parsed at compile time (literal path only), load runs at runtime. Never call load() in `_process()`. Never call `free()` — always `queue_free()`.

4. **Groups are tags for broadcasting. call_group() beats maintaining arrays of references.** Enemies join the "enemies" group, damageable things join "damageable". An explosion doesn't need to know about individual enemies — it just calls the group. This decouples systems cleanly.

5. **%UniqueName (scene-unique names) is the most robust way to reference nodes within a scene.** Right-click > "Access as Scene Unique Name", then reference with `%NodeName`. Survives reparenting. Use `@onready var node := %NodeName` for any node you access in scripts.

6. **class_name makes your scripts into first-class types.** Use it for any script you'll reference by type in other scripts — enemies, players, items, resources. It enables type annotations, `is` checks, @export type slots, and autocomplete.

7. **Scene inheritance creates variants without duplicating work.** Build the base once (BaseEnemy with all shared nodes and logic). Inherit it for each variant (Goblin, Skeleton, Dragon). Override only what differs. `super.method()` chains calls to the parent implementation.

---

## What's Next

[Module 3: Assets & World Building](module-03-assets-world-building.md)

Your scenes are well-structured. Now let's fill them with beautiful 3D assets, materials, and lighting. Module 3 covers importing 3D models from Blender, PBR materials and the StandardMaterial3D workflow, lighting setups (global illumination, SDFGI, sky lighting), and post-processing effects (bloom, tone mapping, ambient occlusion). By the end you'll have a dungeon that doesn't just run — it looks good.

---

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
