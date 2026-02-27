# Module 4: Physics & CharacterBody3D

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** [Module 3: 3D Assets & World Building](module-03-assets-world-building.md)

---

## Overview

Your world has assets and lighting. Now things need to collide, fall, bounce, and respond to the player. Godot has a complete physics engine built in — as of Godot 4.4, it's powered by Jolt, the same physics engine used by Horizon Forbidden West. No packages to install, no dependencies to manage, no PhysX licenses to worry about. It just works when you add a physics body node.

This module covers the four physics body types (StaticBody3D, RigidBody3D, CharacterBody3D, AnimatableBody3D), collision shapes, Area3D for triggers and detection zones, raycasting for line-of-sight and ground checks, collision layers and masks for fine-grained control, and joints for connecting bodies. These are the building blocks of almost every gameplay mechanic — platformers, shooters, puzzles, vehicles, ragdolls. You'll use some combination of these nodes in every project you build.

By the end of this module, you'll build a Rube Goldberg physics puzzle — dominoes, ramps, balls, seesaws, and triggers — with a CharacterBody3D that walks around and kicks the first domino to start the chain. It's a hands-on tour of every major physics system in one scene. When you understand why each piece is the right tool for its job, you can build anything.

---

## 1. Physics Body Types

Godot's physics system has four distinct body types. Picking the right one is the most important decision you'll make when setting up any physical object. Use the wrong one and you'll fight the engine instead of working with it.

### StaticBody3D

The floor, walls, ramps, terrain, and anything else that doesn't move. StaticBody3D participates in the physics simulation but is never moved by it. Other objects collide with it and bounce off or slide along it, but the body itself stays put.

If you need to move a StaticBody3D programmatically (without it pushing other objects), you can update its position in `_process`, but physics objects will pass through it because the physics engine won't know it moved. Use AnimatableBody3D instead when you need a static-like object that actually moves.

**When to use it:** floors, walls, ceiling, ramps, level geometry, any permanent fixture in the world.

### RigidBody3D

Physics-simulated objects. Gravity pulls them down. Forces push them around. They collide with each other and with static surfaces, bouncing and sliding according to their mass and material properties. You don't control their position directly — you apply forces and impulses and let the simulation figure out where they end up.

This is the right type for dominoes, balls, crates, barrels, debris, ragdoll parts, anything that obeys physics and should feel "heavy" and "real."

**When to use it:** any object that should be physically simulated — thrown, dropped, knocked over, stacked.

### CharacterBody3D

Player and NPC characters. The physics engine handles collision detection and sliding along surfaces, but YOU control the velocity directly in `_physics_process`. CharacterBody3D is explicitly NOT simulated by physics — gravity doesn't apply unless you write it yourself, forces don't push it unless you apply them manually. This gives you full control over how the character moves, jumps, and feels.

The key method is `move_and_slide()`. You set `velocity`, call `move_and_slide()`, and Godot handles the collision detection, surface sliding, and step climbing. You get clean, responsive character movement without fighting against rigid body simulation.

**When to use it:** player characters, NPCs, any entity that needs responsive, programmer-controlled movement.

### AnimatableBody3D

Moving platforms, elevators, doors, rotating hazards. Like StaticBody3D in that it doesn't get pushed by the simulation, but unlike StaticBody3D in that it actually pushes other physics objects when it moves. A RigidBody3D sitting on an AnimatableBody3D platform will be carried along with it.

You move it by setting its position or using a Tween/AnimationPlayer. The physics engine tracks how it moves between frames and applies that motion to any objects it's touching.

**When to use it:** any scripted-movement object that needs to push or carry physics objects — moving platforms, elevators, rotating doors, mechanical traps.

### Comparison Table

| Body Type | Moves by physics? | Moves by script? | Pushes others? | Use for |
|---|---|---|---|---|
| StaticBody3D | No | No (stays put) | No | Floors, walls, terrain |
| RigidBody3D | Yes | Via forces/impulses | Yes | Balls, dominoes, crates |
| CharacterBody3D | No | Yes (velocity) | Limited | Player, NPCs |
| AnimatableBody3D | No | Yes (position) | Yes | Moving platforms, doors |

### The CollisionShape3D Requirement

Every physics body node requires at least one CollisionShape3D child node. Without it, the body has no physical presence — it won't collide with anything, won't trigger any detection, and Godot will print a warning in the Output panel. The CollisionShape3D is the actual geometric boundary the physics engine uses; the body node is just the type declaration.

```
StaticBody3D
└── CollisionShape3D   ← required, assigns the shape in Inspector
    (shape: BoxShape3D, SphereShape3D, etc.)
```

Multiple CollisionShape3D children are allowed. You can combine shapes to approximate complex objects — for example, a character might have a CapsuleShape3D for the body and a smaller SphereShape3D for the head, each as a separate CollisionShape3D.

---

## 2. CollisionShape3D: Giving Things Physical Form

The CollisionShape3D node holds a Shape3D resource that defines the physical boundary. Choosing the right shape matters enormously for performance and correctness.

### Shape Types

**BoxShape3D** — An axis-aligned box defined by size (half-extents). Use for crates, walls, floors, bricks, dominoes. Fast and exact for rectangular objects.

```gdscript
var shape := CollisionShape3D.new()
var box := BoxShape3D.new()
box.size = Vector3(1.0, 2.0, 0.5)  # width, height, depth
shape.shape = box
add_child(shape)
```

**SphereShape3D** — A sphere defined by radius. Perfectly smooth rolling physics. Use for balls, orbs, projectiles. Fastest collision detection of all shapes.

```gdscript
var sphere := SphereShape3D.new()
sphere.radius = 0.5
```

**CapsuleShape3D** — A cylinder with hemispherical caps, defined by radius and height. The default shape for CharacterBody3D characters. Slides along surfaces and over small bumps better than a box or cylinder.

```gdscript
var capsule := CapsuleShape3D.new()
capsule.radius = 0.4
capsule.height = 1.8
```

**CylinderShape3D** — A cylinder defined by radius and height. Use for barrels, columns, wheels. More expensive than a capsule but gives the right shape for cylindrical objects that shouldn't roll like a sphere.

```gdscript
var cylinder := CylinderShape3D.new()
cylinder.radius = 0.3
cylinder.height = 1.0
```

**ConvexPolygonShape3D** — A convex hull automatically fit around a mesh. Every face points outward. No concavities. Significantly more expensive than primitives but handles irregular shapes on moving objects. Godot can auto-generate these from a MeshInstance3D.

```gdscript
# Auto-generate convex shape from a mesh resource
var mesh_instance: MeshInstance3D = $MeshInstance3D
var convex_shape := mesh_instance.mesh.create_convex_shape()
var col_shape := CollisionShape3D.new()
col_shape.shape = convex_shape
add_child(col_shape)
```

**ConcavePolygonShape3D** — The exact triangle mesh of the object. Handles any shape including concavities (hollows, tunnels, arches). Very expensive. Can ONLY be used on static bodies (StaticBody3D). Using it on a moving body will cause errors and unpredictable behavior.

```gdscript
# Auto-generate from mesh (static only!)
var concave_shape := mesh_instance.mesh.create_trimesh_shape()
```

**HeightMapShape3D** — Optimized shape for terrain heightmaps. Feed it an array of height values and it builds an efficient collision surface. Use for large terrain meshes where ConcavePolygonShape3D would be too slow.

**WorldBoundaryShape3D** — An infinite flat plane. Only valid for StaticBody3D. Useful as a "catch-all" floor to prevent objects from falling into the void. Place one at y = -100 under your level.

### Shape Selection Rules

1. Use primitives (box, sphere, capsule) whenever possible. They're the fastest by a large margin.
2. Combine multiple primitives to approximate complex shapes rather than using ConvexPolygonShape3D.
3. ConvexPolygonShape3D is acceptable for moderately complex moving objects where primitives don't fit.
4. ConcavePolygonShape3D: ONLY for static geometry. Never on RigidBody3D or CharacterBody3D.
5. For level geometry imported from a 3D modeler, use the "Generate Collision" option when importing — Godot will automatically create appropriate shapes.

### Generating Collision in the Editor

In the editor, select a MeshInstance3D and go to the Mesh menu at the top of the viewport. You'll find:
- **Create Trimesh Static Body** — wraps in StaticBody3D with ConcavePolygonShape3D (good for level geo)
- **Create Convex Static Body** — wraps in StaticBody3D with ConvexPolygonShape3D
- **Create Collision Shape** — adds a CollisionShape3D as a sibling (for putting inside an existing body)

For imported scenes (GLB, FBX), enable the "Generate > Physics Bodies" option in the Import dock. Godot will generate appropriate collision shapes for each mesh automatically on import.

### Visualizing Collision Shapes

Go to **Debug menu > Visible Collision Shapes** in the editor. Collision shapes will be shown as blue/orange wireframes overlaid on your scene. This is invaluable for debugging — mismatched collision shapes are one of the most common sources of physics bugs.

At runtime, you can enable this from code:

```gdscript
# Show collision shapes at runtime
get_tree().debug_collisions_hint = true
```

---

## 3. RigidBody3D Deep Dive

RigidBody3D is where physics simulation lives. Understanding its properties and methods is key to building satisfying physics-based gameplay.

### Key Properties

**mass** — How heavy the object is in kilograms. Affects how forces accelerate it and how much it pushes other objects. Default is 1.0. A bowling ball might be 5.0, a domino 0.5, a wrecking ball 500.0.

**gravity_scale** — Multiplier on gravity. 1.0 is normal gravity. 0.0 floats. 2.0 falls twice as fast. Negative values float upward.

**linear_damp** — Air resistance for linear movement. Higher values slow down translation faster. 0.0 is no damping (slides forever in space). Use ~0.5 for realistic air resistance.

**angular_damp** — Air resistance for rotation. Prevents objects from spinning forever. Higher values stabilize rotation faster.

**linear_velocity** and **angular_velocity** — Current velocity vectors. You can read and set these directly, though for most cases you should prefer forces and impulses.

**freeze** — Set to true to make the body ignore physics (stops moving, can't be pushed). Useful for objects that shouldn't move until a gameplay event triggers them.

**freeze_mode** — Either `FREEZE_MODE_STATIC` (acts like a StaticBody3D, other objects collide with it) or `FREEZE_MODE_KINEMATIC` (ignores all collisions). Default is STATIC.

**can_sleep** — Allows the physics engine to stop simulating the body when it's motionless, saving CPU. True by default. Disable if the body should never sleep (e.g., a magnet that needs to always respond).

### Physics Material

PhysicsMaterial controls surface properties. Create one as an override or share one between objects:

```gdscript
extends RigidBody3D

func _ready() -> void:
    mass = 2.0
    gravity_scale = 1.0

    # Create a physics material
    var mat := PhysicsMaterial.new()
    mat.bounce = 0.5      # 0.0 = no bounce, 1.0 = perfect elastic
    mat.friction = 0.8    # 0.0 = ice, 1.0 = rubber
    mat.rough = false     # rough = friction applies even when sliding fast
    mat.absorbent = false # absorbent = bounce is reduced on collision
    physics_material_override = mat
```

You can also set a PhysicsMaterial in the Inspector — just assign a new or existing PhysicsMaterial resource to the `physics_material_override` property.

### Applying Forces and Impulses

Forces are continuous — they accumulate over time. Apply them in `_physics_process`. Impulses are instant one-shot velocity changes — apply them once in response to an event.

```gdscript
extends RigidBody3D

# ---- FORCES (continuous, call in _physics_process) ----

# Push in a direction (world space, from center of mass)
func apply_thrust(direction: Vector3) -> void:
    apply_central_force(direction * 100.0)

# Push at a specific point (causes rotation if not at center)
func apply_push_at_point(force: Vector3, point: Vector3) -> void:
    apply_force(force, point)

# Spin the object
func apply_spin(torque: Vector3) -> void:
    apply_torque(torque)

# ---- IMPULSES (instant, call once) ----

# Kick from center (no rotation)
func kick(direction: Vector3) -> void:
    apply_central_impulse(direction * 50.0)

# Kick at a point (causes rotation based on offset from center)
func kick_at_point(impulse: Vector3, point: Vector3) -> void:
    apply_impulse(impulse, point)

# Spin impulse (instant angular velocity change)
func spin_impulse(torque_impulse: Vector3) -> void:
    apply_torque_impulse(torque_impulse)
```

The distinction between force and impulse matters for gameplay feel. Kicking a domino should be an impulse — one event, immediate effect. Jet thrust or a magnet should be forces — continuous, building up over time.

### Contact Monitoring and Signals

By default, RigidBody3D doesn't emit signals when it hits things. You have to enable contact monitoring:

```gdscript
extends RigidBody3D

func _ready() -> void:
    contact_monitor = true          # enable contact tracking
    max_contacts_reported = 4       # how many simultaneous contacts to track

    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    print("Collided with: ", body.name)

    # Check the impact velocity to determine collision strength
    var impact_speed := linear_velocity.length()
    if impact_speed > 10.0:
        print("Hard hit! Speed: ", impact_speed)

func _on_body_exited(body: Node) -> void:
    print("No longer touching: ", body.name)
```

Available signals on RigidBody3D:
- `body_entered(body: Node)` — another physics body started touching this one
- `body_exited(body: Node)` — a physics body stopped touching this one
- `body_shape_entered(body_rid, body, body_shape_index, local_shape_index)` — shape-level contact
- `body_shape_exited(...)` — shape-level separation
- `sleeping_state_changed` — emitted when the body goes to sleep or wakes up

### Custom Physics Integration

For full control over how a RigidBody3D moves each frame, override `_integrate_forces`:

```gdscript
extends RigidBody3D

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    # state gives you direct access to the physics step
    # Read current state:
    var vel := state.linear_velocity
    var ang_vel := state.angular_velocity
    var transform := state.transform

    # Apply drag manually
    state.linear_velocity *= 0.99

    # Clamp speed
    if state.linear_velocity.length() > 20.0:
        state.linear_velocity = state.linear_velocity.normalized() * 20.0

    # Access collision info
    for i in state.get_contact_count():
        var contact_pos := state.get_contact_local_position(i)
        var contact_normal := state.get_contact_local_normal(i)
        var collider := state.get_contact_collider_object(i)
        print("Contact at ", contact_pos, " with ", collider.name)
```

`_integrate_forces` is called every physics step. Use it for hover vehicles, custom gravity, buoyancy, or any case where you need fine-grained control over physics integration.

---

## 4. CharacterBody3D: Player Movement

CharacterBody3D is the standard choice for player characters. It gives you complete control over movement while Godot handles the collision detection, surface normal calculations, and step climbing. The core loop is: set `velocity`, call `move_and_slide()`.

### Key Properties

**velocity** — A Vector3 you control. This is what the character will try to move at each frame. `move_and_slide()` uses this, modifies it based on collisions, and stores the actual resulting velocity back into it.

**up_direction** — The direction the character considers "up." Usually `Vector3.UP` (0, 1, 0). Used to determine what counts as a floor vs a wall vs a ceiling.

**floor_max_angle** — Maximum slope angle in radians that counts as a "floor." Steeper than this and the surface is considered a wall. Default is about 45 degrees (`PI / 4`).

**floor_snap_length** — How far the character snaps down to floors when walking. Prevents bouncing at the top of ramps. Default is 0.1. Increase if character bounces on gentle slopes.

**motion_mode** — `MOTION_MODE_GROUNDED` (default, for standard platformers and first-person) or `MOTION_MODE_FLOATING` (for flying characters, zero-gravity, swimming — no concept of floor).

**wall_min_slide_angle** — Minimum angle between the wall normal and the movement direction before sliding happens. Prevents the character from sliding along very slightly angled surfaces unintentionally.

### The Standard Movement Template

This is the pattern you'll use in almost every CharacterBody3D:

```gdscript
extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8

func _physics_process(delta: float) -> void:
    # Step 1: Apply gravity (only when airborne)
    if not is_on_floor():
        velocity.y -= gravity * delta

    # Step 2: Handle jumping
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    # Step 3: Get movement input
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

    # Step 4: Convert input to world-space direction relative to character facing
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    # Step 5: Apply horizontal velocity
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        # Decelerate smoothly when no input
        velocity.x = move_toward(velocity.x, 0.0, speed)
        velocity.z = move_toward(velocity.z, 0.0, speed)

    # Step 6: Move and slide (collision detection + sliding)
    move_and_slide()
```

**Why `transform.basis * Vector3(input_dir.x, 0, input_dir.y)`?** The `transform.basis` converts the input from local space (relative to where the character is facing) to world space. Without this, pressing "forward" always moves in the world's -Z direction regardless of which way the character faces.

**Why `move_toward` for deceleration?** `move_toward(current, target, step)` moves a float toward a target by at most `step` per call. Using it for horizontal velocity gives smooth deceleration without going negative — it stops at zero. Multiplying by `delta` would be more frame-rate independent but `speed` here is the deceleration rate, which feels fine without delta since `_physics_process` runs at fixed tick rate.

### Helper Functions

After calling `move_and_slide()`, several helper functions tell you what happened:

```gdscript
func _physics_process(delta: float) -> void:
    # ... velocity setup ...
    move_and_slide()

    # What surface is the character on/touching?
    if is_on_floor():
        print("On ground, normal: ", get_floor_normal())

    if is_on_wall():
        print("Touching wall, normal: ", get_wall_normal())

    if is_on_ceiling():
        print("Head on ceiling")

    # Get detailed collision info for each collision this frame
    for i in get_slide_collision_count():
        var collision := get_slide_collision(i)
        var collider := collision.get_collider()         # the other object
        var normal := collision.get_normal()             # surface normal at impact
        var position := collision.get_position()         # world position of collision
        var depth := collision.get_depth()               # penetration depth
        var travel := collision.get_travel()             # how far we actually moved
        var remainder := collision.get_remainder()       # blocked movement remaining

        print("Hit: ", collider.name, " at ", position)

        # Interact with RigidBody3D on impact
        if collider is RigidBody3D:
            var push_dir := -normal
            var push_force := 5.0
            collider.apply_central_impulse(push_dir * push_force)
```

`get_slide_collision_count()` returns how many collisions occurred this frame. You can loop over them and respond to each one — push crates, trigger effects, take damage from spikes.

### Coyote Time and Input Buffering

Two small quality-of-life additions that make platformers feel much better:

```gdscript
extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8
@export var coyote_time: float = 0.15    # seconds to still jump after walking off edge
@export var jump_buffer_time: float = 0.1  # seconds to buffer jump input before landing

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

func _physics_process(delta: float) -> void:
    # Update coyote time
    if is_on_floor():
        coyote_timer = coyote_time
    else:
        coyote_timer -= delta

    # Buffer jump input
    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer = jump_buffer_time
    else:
        jump_buffer_timer -= delta

    # Apply gravity
    if not is_on_floor():
        velocity.y -= gravity * delta

    # Jump: use coyote timer and jump buffer
    if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
        velocity.y = jump_velocity
        jump_buffer_timer = 0.0
        coyote_timer = 0.0

    # Horizontal movement
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed)
        velocity.z = move_toward(velocity.z, 0.0, speed)

    move_and_slide()
```

---

## 5. Third-Person Camera Setup

A third-person camera needs to: follow the player, rotate with mouse input, and avoid clipping through walls. SpringArm3D handles all three.

### SpringArm3D

SpringArm3D is a node that extends a "spring" from its origin toward a target position. If anything is in the way (according to its collision mask), it shortens the spring to keep the camera in front of the obstacle. This prevents the camera from clipping through walls automatically.

Set up the scene tree like this:

```
CharacterBody3D (Player)
├── CollisionShape3D (CapsuleShape3D)
├── MeshInstance3D (player model)
└── SpringArm3D
    └── Camera3D
```

Camera3D should be positioned at the end of the spring (e.g., Position (0, 0, 0) — the spring itself determines where the camera ends up). Set `spring_length` on SpringArm3D to control how far back the camera sits.

### Player Script with Camera

```gdscript
extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8
@export var mouse_sensitivity: float = 0.005
@export var spring_length: float = 5.0

@onready var spring_arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
    # Capture mouse so it doesn't leave the window
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    # Configure spring arm
    spring_arm.spring_length = spring_length
    spring_arm.collision_mask = 1  # collide with World layer (layer 1)
    spring_arm.margin = 0.3        # keep camera this far from surfaces

func _input(event: InputEvent) -> void:
    # Handle mouse look
    if event is InputEventMouseMotion:
        # Rotate the entire character left/right
        rotate_y(-event.relative.x * mouse_sensitivity)

        # Tilt the spring arm up/down (not the character)
        spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)

        # Clamp vertical look angle (-45 deg to +45 deg)
        spring_arm.rotation.x = clampf(
            spring_arm.rotation.x,
            -PI / 4.0,
            PI / 4.0
        )

    # Release mouse with Escape
    if event.is_action_pressed("ui_cancel"):
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed)
        velocity.z = move_toward(velocity.z, 0.0, speed)

    move_and_slide()
```

### SpringArm3D Properties

**spring_length** — How far the arm extends. The camera sits at the end of it. Typical values: 3.0 to 8.0 depending on your game scale.

**collision_mask** — Which layers the spring arm tests against when checking for obstacles. Usually just the World layer (layer 1). Don't include Player layer here or the spring will always be at zero length because the character itself blocks it.

**margin** — How far from a surface the camera stops. Prevents z-fighting. 0.2 to 0.5 is usually fine.

**shape** — Optionally assign a shape for the spring arm to use instead of a pure raycast. A small SphereShape3D prevents the camera from getting too close to thin obstacles.

### Input Action Setup

Make sure these input actions exist in Project Settings > Input Map:
- `move_forward` — W / Up Arrow
- `move_back` — S / Down Arrow
- `move_left` — A / Left Arrow
- `move_right` — D / Right Arrow
- `jump` — Space

You can also add gamepad inputs to the same actions — Godot treats keyboard and controller identically once the action is defined.

---

## 6. Area3D: Triggers and Detection Zones

Area3D detects when other physics bodies or areas overlap it. It does NOT collide — things pass right through it. This makes it ideal for invisible trigger zones, pickup detection, damage volumes, AI detection ranges, and anything else that reacts to presence without pushing back.

### Area3D Basics

Like all physics bodies, Area3D requires a CollisionShape3D child. The shape defines the detection zone's bounds.

```
Area3D (pickup zone)
└── CollisionShape3D (SphereShape3D, radius = 1.0)
```

### Collecting Pickups

```gdscript
extends Area3D

signal item_collected(item_name: String)

@export var item_name: String = "coin"
@export var point_value: int = 10

func _ready() -> void:
    # Connect signals (or connect in editor)
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    # Only respond to the player
    if body is CharacterBody3D:
        item_collected.emit(item_name)
        print("Collected ", item_name, " worth ", point_value, " points")
        queue_free()  # remove the pickup
```

### Damage Zone

```gdscript
extends Area3D

@export var damage_per_second: float = 20.0

var bodies_inside: Array[Node3D] = []

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
    if body.has_method("take_damage"):
        bodies_inside.append(body)

func _on_body_exited(body: Node3D) -> void:
    bodies_inside.erase(body)

func _physics_process(delta: float) -> void:
    for body in bodies_inside:
        if is_instance_valid(body):
            body.take_damage(damage_per_second * delta)
```

### Detection Range (AI Awareness)

```gdscript
extends Area3D

var player_in_range: bool = false
var detected_player: Node3D = null

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        player_in_range = true
        detected_player = body
        print("Player detected!")

func _on_body_exited(body: Node3D) -> void:
    if body.is_in_group("player"):
        player_in_range = false
        detected_player = null
        print("Player left detection range")

# Check overlap at any time (polling instead of signals)
func get_nearby_enemies() -> Array:
    return get_overlapping_bodies().filter(func(b): return b.is_in_group("enemy"))
```

### Area3D Signals Reference

| Signal | When it fires |
|---|---|
| `body_entered(body)` | A physics body enters the area |
| `body_exited(body)` | A physics body leaves the area |
| `area_entered(area)` | Another Area3D enters this area |
| `area_exited(area)` | Another Area3D leaves this area |

### Monitoring vs Monitorable

**monitoring** — Can this area detect others entering it? If false, the body_entered/body_exited signals never fire. Default: true.

**monitorable** — Can other areas detect THIS area entering them? If false, this area is invisible to other Area3D nodes. Default: true.

Turn off `monitoring` on areas that don't need to detect (they only need to be detected by others) to save CPU.

### Polling Overlaps

Instead of using signals, you can poll at any time:

```gdscript
func _physics_process(delta: float) -> void:
    var nearby_bodies := get_overlapping_bodies()
    var nearby_areas := get_overlapping_areas()

    for body in nearby_bodies:
        print("Overlapping: ", body.name)
```

This only works if `monitoring` is true. Note that polling every frame is less efficient than signals for most use cases, but useful when you need to check overlap at a specific moment rather than react to enter/exit events.

---

## 7. Collision Layers and Masks

Godot provides 32 collision layers. Every physics object has a `collision_layer` (what it IS) and a `collision_mask` (what it can COLLIDE WITH or DETECT). Two objects only interact when Object A's mask includes Object B's layer and vice versa — or in the case of one-sided detection (Area3D), just when the Area3D's mask includes the body's layer.

### Why This Matters

Without layers, every object checks collision against every other object. With layers, you can make projectiles ignore other projectiles, make triggers only detect the player, make ghosts pass through walls but not through other ghosts, and so on. This dramatically improves both performance and correctness.

### Naming Your Layers

Go to **Project Settings > Layer Names > 3D Physics**. Name the first several layers for clarity:

```
Layer 1: World          (StaticBody3D floors, walls, level geometry)
Layer 2: Player         (CharacterBody3D player character)
Layer 3: Enemies        (enemy CharacterBody3D or RigidBody3D)
Layer 4: Projectiles    (bullets, arrows, thrown objects)
Layer 5: Pickups        (coins, powerups)
Layer 6: Triggers       (Area3D zones)
```

Once named, the Inspector will show checkboxes with labels instead of anonymous numbers.

### Layer Logic Examples

**Player:**
- Layer: 2 (it IS a Player)
- Mask: 1, 3, 5 (sees World, Enemies, Pickups — but NOT other projectiles or triggers directly)

**Enemy:**
- Layer: 3 (it IS an Enemy)
- Mask: 1, 2, 4 (sees World, Player, Projectiles)

**Bullet/Projectile:**
- Layer: 4 (it IS a Projectile)
- Mask: 1, 3 (hits World and Enemies — does NOT hit the player who shot it, does NOT hit other bullets)

**Coin pickup (Area3D):**
- Layer: 5 (it IS a Pickup)
- Mask: 2 (detects Player only)

**Damage zone (Area3D):**
- Layer: 6 (it IS a Trigger)
- Mask: 2 (detects Player only)

### Setting Layers in Code

```gdscript
extends CharacterBody3D

func _ready() -> void:
    # Reset all layers/masks first (clear to 0)
    collision_layer = 0
    collision_mask = 0

    # Set what this object IS (layer 2 = Player)
    set_collision_layer_value(2, true)

    # Set what this object COLLIDES WITH
    set_collision_mask_value(1, true)   # World
    set_collision_mask_value(3, true)   # Enemies
    set_collision_mask_value(5, true)   # Pickups

    # Check layer values
    print("On layer 2: ", get_collision_layer_value(2))
    print("Sees layer 1: ", get_collision_mask_value(1))
```

```gdscript
extends Area3D

func _ready() -> void:
    # This trigger area IS on layer 6
    collision_layer = 0
    set_collision_layer_value(6, true)

    # This trigger only detects Players (layer 2)
    collision_mask = 0
    set_collision_mask_value(2, true)
```

### Setting Layers via Bitmask

If you know the exact bit pattern, you can set it directly. Layer 1 = bit 0 = value 1. Layer 2 = bit 1 = value 2. Layer 3 = bit 2 = value 4. Layer 4 = bit 3 = value 8.

```gdscript
# Layers 1 and 3 simultaneously (1 + 4 = 5)
collision_mask = 5

# Layers 1, 2, and 3 simultaneously (1 + 2 + 4 = 7)
collision_layer = 7
```

Using `set_collision_layer_value(n, true)` is clearer and less error-prone than direct bitmask math.

---

## 8. RayCast3D: Line of Sight and Ground Detection

RayCast3D fires a ray from its origin in a direction and reports what it hits. Add it as a child node, point it in the right direction, and query it in `_physics_process`. It automatically updates every physics frame.

### Setup

```
CharacterBody3D (Player)
├── CollisionShape3D
├── MeshInstance3D
├── SpringArm3D
│   └── Camera3D
└── RayCast3D (GroundCheck)
    (target_position: Vector3(0, -1.5, 0))   ← points straight down
```

In the Inspector, set `target_position` to the ray's endpoint relative to the node. For a ground check from a character's feet, point it down: `Vector3(0, -0.6, 0)`. For wall detection pointing forward: `Vector3(0, 0, -1.0)`.

### Basic Usage

```gdscript
@onready var ray: RayCast3D = $RayCast3D

func _physics_process(delta: float) -> void:
    if ray.is_colliding():
        var collider := ray.get_collider()          # the object hit
        var point := ray.get_collision_point()      # world position of hit
        var normal := ray.get_collision_normal()    # surface normal at hit
        var shape_idx := ray.get_collider_shape()  # shape index on collider

        print("Ray hit: ", collider.name)
        print("  at position: ", point)
        print("  surface normal: ", normal)
    else:
        print("Ray hit nothing")
```

### AI Line of Sight

```gdscript
extends Node3D

@onready var sight_ray: RayCast3D = $SightRay

@export var player: Node3D

func _physics_process(delta: float) -> void:
    if player == null:
        return

    # Point the ray toward the player
    var to_player := player.global_position - global_position
    sight_ray.target_position = to_player

    if sight_ray.is_colliding():
        var hit := sight_ray.get_collider()
        # If the first thing in the way IS the player, we can see them
        if hit == player:
            print("Player visible!")
        else:
            print("Player obscured by: ", hit.name)
```

### RayCast3D Configuration

```gdscript
@onready var ray: RayCast3D = $RayCast3D

func _ready() -> void:
    ray.enabled = true                     # must be true to work
    ray.target_position = Vector3(0, -2, 0)  # direction + length
    ray.collision_mask = 1                 # only test World layer
    ray.exclude_parent = true             # don't hit our own body
    ray.hit_from_inside = false           # ignore shape we're inside
    ray.hit_back_faces = false            # ignore back faces of meshes
```

**exclude_parent = true** is almost always what you want. Without it, a RayCast3D attached to a CharacterBody3D will immediately hit the character's own collision shape.

### One-Shot Raycasts from Code

Sometimes you want a single raycast at a specific moment without a persistent node. Use `PhysicsDirectSpaceState3D`:

```gdscript
func cast_ray_from_camera(camera: Camera3D, mouse_pos: Vector2) -> Dictionary:
    var space_state := get_world_3d().direct_space_state
    var origin := camera.project_ray_origin(mouse_pos)
    var end := origin + camera.project_ray_normal(mouse_pos) * 1000.0

    var query := PhysicsRayQueryParameters3D.create(origin, end)
    query.collision_mask = 1  # hit world geometry only
    query.exclude = [self]    # exclude this object

    var result := space_state.intersect_ray(query)
    # result is a Dictionary with: position, normal, collider, shape, rid
    # empty if nothing hit
    return result

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        var cam: Camera3D = get_viewport().get_camera_3d()
        var hit := cast_ray_from_camera(cam, event.position)
        if hit:
            print("Clicked on: ", hit["collider"].name, " at ", hit["position"])
```

### ShapeCast3D

ShapeCast3D is like RayCast3D but sweeps a shape through space instead of a point. Useful for detecting ledges (sweep a box forward and down), checking if an area is clear before teleporting, or wide ground checks:

```gdscript
@onready var shape_cast: ShapeCast3D = $ShapeCast3D

func _ready() -> void:
    # Configure a capsule sweep for ledge detection
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.6
    shape_cast.shape = capsule
    shape_cast.target_position = Vector3(0, -0.5, 0)
    shape_cast.collision_mask = 1
    shape_cast.max_results = 4

func check_ceiling_clearance() -> bool:
    shape_cast.target_position = Vector3(0, 2.0, 0)  # check 2m up
    shape_cast.force_shapecast_update()
    return not shape_cast.is_colliding()
```

---

## 9. Joints: Connecting Bodies

Joints constrain the relative movement between two physics bodies. They're how you build doors, seesaws, chains, vehicle suspensions, ragdolls, and mechanical puzzles.

Every joint node has two properties: `node_a` and `node_b` — the paths to the two Node3D objects being connected. The joint's position and rotation determine the constraint point. At least one of the two nodes should be a physics body (RigidBody3D, AnimatableBody3D).

### PinJoint3D (Ball and Socket)

Allows rotation in all three axes but no translation. The two nodes stay attached at the joint's position. Use for: chain links, pendulums, ball-and-socket connections, rope segments.

```gdscript
# Scene setup:
# Node3D (scene root)
# ├── StaticBody3D (anchor)
# │   └── CollisionShape3D
# ├── RigidBody3D (pendulum bob)
# │   └── CollisionShape3D
# └── PinJoint3D (at pivot point)

extends Node3D

@onready var joint: PinJoint3D = $PinJoint3D
@onready var anchor: StaticBody3D = $Anchor
@onready var bob: RigidBody3D = $Bob

func _ready() -> void:
    joint.node_a = joint.get_path_to(anchor)
    joint.node_b = joint.get_path_to(bob)

    # Bias: how strongly the joint corrects for drift (0.0 to 1.0)
    joint.set_param(PinJoint3D.PARAM_BIAS, 0.3)

    # Damping: how quickly oscillation settles
    joint.set_param(PinJoint3D.PARAM_DAMPING, 1.0)

    # Impulse clamp: maximum force the joint can apply
    joint.set_param(PinJoint3D.PARAM_IMPULSE_CLAMP, 0.0)  # 0 = unlimited
```

### HingeJoint3D (Single Axis Rotation)

Rotates around one axis only. The joint's Y axis is the hinge axis by default. Use for: doors, seesaws, wheels, levers, gates.

```gdscript
extends Node3D

@onready var joint: HingeJoint3D = $HingeJoint3D
@onready var anchor: StaticBody3D = $Anchor
@onready var door: RigidBody3D = $Door

func _ready() -> void:
    joint.node_a = joint.get_path_to(anchor)
    joint.node_b = joint.get_path_to(door)

    # Enable angular limits (restrict swing)
    joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
    joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-90.0))
    joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(0.0))

    # Enable motor (self-powered rotation)
    joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
    joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
    joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 1.0)

func open_door() -> void:
    # Enable motor to push door open
    joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
    joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 2.0)
```

### SliderJoint3D (Linear Movement)

Allows movement along one axis and rotation around that same axis. Use for: pistons, elevators, sliding drawers, hydraulic arms.

```gdscript
extends Node3D

@onready var joint: SliderJoint3D = $SliderJoint3D

func _ready() -> void:
    joint.node_a = joint.get_path_to($Anchor)
    joint.node_b = joint.get_path_to($Piston)

    # Linear travel limits
    joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -2.0)
    joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 2.0)

    # Motor for automatic actuation
    joint.set_param(SliderJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, 1.0)
    joint.set_param(SliderJoint3D.PARAM_LINEAR_MOTOR_MAX_IMPULSE, 10.0)
```

### ConeTwistJoint3D (Ragdoll Limbs)

Allows rotation within a cone, plus twist around the cone's axis. Mimics shoulder and hip joints. Use for: ragdoll shoulders, hips, spine connections.

```gdscript
extends Node3D

@onready var joint: ConeTwistJoint3D = $ShoulderJoint

func _ready() -> void:
    joint.node_a = joint.get_path_to($Torso)
    joint.node_b = joint.get_path_to($UpperArm)

    # Swing limit (how far the arm can swing in a cone)
    joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(60.0))

    # Twist limit (how far the arm can rotate along its own axis)
    joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(45.0))
```

### Generic6DOFJoint3D (Full Control)

Six degrees of freedom — you control each axis independently. Linear X/Y/Z and Angular X/Y/Z can each be locked, free, or limited. The most powerful and most complex joint type. Use when the specific joint types above don't fit your needs.

### Joint Positioning Tip

The joint node's position in the scene is the pivot point. Place it exactly where the connection should be (e.g., at the door's hinge edge, at the seesaw's fulcrum, at the chain link's contact point). The orientation matters too — for HingeJoint3D, the hinge axis is the joint's local Y axis.

---

## 10. AnimatableBody3D: Moving Platforms

AnimatableBody3D is for scripted-movement objects that need to push RigidBody3D objects along with them. A platform that moves up and carries anything sitting on it. A door that sweeps open and pushes away objects in its path.

### Basic Moving Platform

```gdscript
extends AnimatableBody3D

@export var travel: Vector3 = Vector3(0, 5, 0)  # where it moves to (relative)
@export var speed: float = 2.0                    # units per second (one direction)
@export var pause_at_ends: float = 0.5            # seconds to pause at each end

var progress: float = 0.0
var direction: float = 1.0
var start_position: Vector3
var pause_timer: float = 0.0

func _ready() -> void:
    start_position = position

func _physics_process(delta: float) -> void:
    # Handle pausing at endpoints
    if pause_timer > 0.0:
        pause_timer -= delta
        return

    # Advance progress
    progress += (speed / travel.length()) * delta * direction

    # Reverse at endpoints
    if progress >= 1.0:
        progress = 1.0
        direction = -1.0
        pause_timer = pause_at_ends
    elif progress <= 0.0:
        progress = 0.0
        direction = 1.0
        pause_timer = pause_at_ends

    # Move to interpolated position
    # NOTE: Use move_and_collide or direct position assignment
    # AnimatableBody3D uses sync_to_physics, which is set in Inspector
    position = start_position.lerp(start_position + travel, progress)
```

**Important:** In the Inspector, check whether **Sync to Physics** is enabled on the AnimatableBody3D. With sync enabled, position updates happen in the physics step and properly interact with physics objects. Without it, fast-moving platforms can tunnel through or fail to carry objects correctly.

### Animated Platform with AnimationPlayer

For cinematic platforms or complex paths, use AnimationPlayer:

```gdscript
extends AnimatableBody3D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    # The AnimationPlayer animates the 'position' or 'transform' property
    # AnimatableBody3D detects the delta between frames and pushes physics objects
    anim.play("platform_loop")
```

In the AnimationPlayer, keyframe the `position` property directly on the AnimatableBody3D. Use loop mode for continuously moving platforms.

### Rotating Hazard

```gdscript
extends AnimatableBody3D

@export var rotation_speed: float = 90.0  # degrees per second

func _physics_process(delta: float) -> void:
    # Rotate around Y axis — sweeps physics objects out of the way
    rotate_y(deg_to_rad(rotation_speed) * delta)
```

---

## 11. Debugging Physics

Physics bugs can be tricky to track down because collisions happen in the physics step, not the render step, and the results accumulate over time. Here's a systematic approach.

### Visible Collision Shapes

The most useful debug tool. In the editor: **Debug menu > Visible Collision Shapes**. Collision shapes appear as colored wireframes over your scene:
- Blue wireframes: shapes that are active and enabled
- Orange wireframes: shapes that are disabled

At runtime from code:

```gdscript
func _ready() -> void:
    # Show all collision shapes
    get_tree().debug_collisions_hint = true

    # Show navigation meshes too
    get_tree().debug_navigation_hint = true
```

### Physics Monitor

Open **Debugger panel > Monitors tab** while the game is running. You'll find physics-specific metrics:
- Physics 3D — active rigid bodies, collision pairs, islands
- Memory — how much the physics simulation is using

### Slowing Down Physics

When debugging fast physics events (collisions, bounces, chain reactions), slow everything down:

```gdscript
func _ready() -> void:
    Engine.time_scale = 0.1  # 10% speed — everything in slow motion

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        Engine.time_scale = 1.0  # back to normal
```

`Engine.time_scale` affects all physics, animations, and timers. It does NOT affect `_process` and `_physics_process` call frequency — it affects `delta` values instead.

### Logging Collision Info

```gdscript
extends CharacterBody3D

func _physics_process(delta: float) -> void:
    # ... movement code ...
    move_and_slide()

    # After move_and_slide, log what happened
    if get_slide_collision_count() > 0:
        for i in get_slide_collision_count():
            var col := get_slide_collision(i)
            print("[Frame %d] Collision: %s, normal: %s, depth: %.3f" % [
                Engine.get_physics_frames(),
                col.get_collider().name,
                col.get_normal(),
                col.get_depth()
            ])
```

### Performance Tips

1. **Fewer shapes is faster.** One CapsuleShape3D beats four BoxShape3D combined.
2. **Simpler shapes are faster.** Box < Convex < Concave. Use the simplest shape that fits.
3. **Disable physics when off-screen.** Set `freeze = true` on RigidBody3D when the object is far from the camera or off-screen.
4. **Use `can_sleep = true`** on RigidBody3D (default). Sleeping bodies use almost no CPU.
5. **Limit `max_contacts_reported`** on RigidBody3D. Don't set it higher than you need.
6. **Reduce `max_results`** on ShapeCast3D.
7. **Disable `contact_monitor`** on RigidBody3D unless you're actually using the body_entered signal.
8. **Use collision layers** to prevent unnecessary collision pair checks between objects that never interact.

### Common Error Messages

**"CharacterBody3D: No collision shape found"** — You forgot to add a CollisionShape3D child, or you assigned a shape but left its Shape property empty.

**"RigidBody3D: The shape is not a convex shape..."** — You tried to use ConcavePolygonShape3D on a RigidBody3D. Change to a convex shape or a set of primitives.

**"Physics body moved while unlocked"** — You changed a StaticBody3D's position in `_process` instead of `_physics_process`. Move physics body position changes to `_physics_process`.

---

## 12. Code Walkthrough: Rube Goldberg Physics Puzzle

This mini-project brings together every system from this module. A player character walks up to a row of dominoes and kicks the first one. The domino chain knocks a ball down a ramp. The ball lands on a seesaw, launching a second ball. The second ball enters a trigger zone, which spawns a fireworks display.

### Project Structure

```
rube_goldberg/
├── main.tscn              (root scene, ties everything together)
├── player/
│   ├── player.tscn        (CharacterBody3D with SpringArm + Camera)
│   └── player.gd
├── objects/
│   ├── domino.tscn        (RigidBody3D with BoxShape3D)
│   ├── ramp.tscn          (StaticBody3D angled surface)
│   ├── ball.tscn          (RigidBody3D with SphereShape3D + bounce material)
│   ├── seesaw.tscn        (RigidBody3D + HingeJoint3D + StaticBody3D anchor)
│   └── trigger_zone.tscn  (Area3D with CollisionShape3D)
└── setup/
    └── level_builder.gd   (autoload/tool to place dominoes programmatically)
```

### Floor

```gdscript
# floor.tscn — just create in editor:
# StaticBody3D
# ├── CollisionShape3D (BoxShape3D: size = Vector3(40, 0.2, 40))
# └── MeshInstance3D (BoxMesh: size = Vector3(40, 0.2, 40))
# Position at y = 0.
# No script needed.
```

### Domino Scene (res://objects/domino.tscn)

```
RigidBody3D (Domino)
├── CollisionShape3D (BoxShape3D: size = Vector3(0.2, 1.0, 0.5))
└── MeshInstance3D (BoxMesh: size = Vector3(0.2, 1.0, 0.5))
```

Domino script:

```gdscript
# domino.gd
extends RigidBody3D

@export var domino_index: int = 0

func _ready() -> void:
    mass = 0.3
    gravity_scale = 1.0

    contact_monitor = true
    max_contacts_reported = 2
    body_entered.connect(_on_body_entered)

    # Create physics material for slight bounce and good friction
    var mat := PhysicsMaterial.new()
    mat.bounce = 0.1
    mat.friction = 0.7
    physics_material_override = mat

func _on_body_entered(body: Node) -> void:
    if body is RigidBody3D and body.name.begins_with("Domino"):
        pass  # domino hit domino — physics handles it automatically
    elif body is StaticBody3D:
        pass  # hit the floor — fine
```

### Domino Placement Script (spawns all dominoes)

```gdscript
# In main.gd or a tool script — run in _ready to place dominos
extends Node3D

@export var domino_scene: PackedScene
@export var domino_count: int = 15
@export var domino_spacing: float = 0.6

func _ready() -> void:
    _place_dominoes()

func _place_dominoes() -> void:
    for i in domino_count:
        var domino: RigidBody3D = domino_scene.instantiate()
        add_child(domino)

        # Line them up along the X axis, standing upright
        domino.position = Vector3(i * domino_spacing, 0.5, 0.0)
        domino.domino_index = i

    print("Placed ", domino_count, " dominoes")
```

### Ramp (StaticBody3D)

```gdscript
# ramp.gd
extends StaticBody3D

# No script needed for a simple ramp — just rotate the node in the editor.
# Scene:
# StaticBody3D (Ramp), rotated 20 degrees on X axis
# ├── CollisionShape3D (BoxShape3D: size = Vector3(2, 0.2, 5))
# └── MeshInstance3D (BoxMesh: size = Vector3(2, 0.2, 5))
#
# Position the bottom of the ramp at the end of the domino line.
# The ball rolls down the ramp after the last domino pushes it.
```

### Ball (RigidBody3D)

```gdscript
# ball.gd
extends RigidBody3D

func _ready() -> void:
    mass = 1.0
    gravity_scale = 1.0

    var mat := PhysicsMaterial.new()
    mat.bounce = 0.6     # bouncy
    mat.friction = 0.3   # somewhat slippery
    physics_material_override = mat

    # Enable contact detection so we can react to hitting the seesaw
    contact_monitor = true
    max_contacts_reported = 4
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body.name == "Seesaw":
        print("Ball landed on seesaw!")
```

### Seesaw (RigidBody3D + HingeJoint3D)

```gdscript
# seesaw.gd
extends Node3D

@onready var hinge: HingeJoint3D = $HingeJoint
@onready var plank: RigidBody3D = $Plank
@onready var anchor: StaticBody3D = $Anchor

func _ready() -> void:
    # Connect hinge joint to anchor (static) and plank (rigid)
    hinge.node_a = hinge.get_path_to(anchor)
    hinge.node_b = hinge.get_path_to(plank)

    # Allow the seesaw to rotate freely within limits
    hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
    hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-45.0))
    hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(45.0))

    # Set up the plank physics
    plank.mass = 2.0
    var mat := PhysicsMaterial.new()
    mat.bounce = 0.2
    mat.friction = 0.5
    plank.physics_material_override = mat
```

Scene tree for seesaw:

```
Node3D (Seesaw root)
├── StaticBody3D (Anchor)
│   └── CollisionShape3D (small BoxShape3D for the fulcrum)
├── RigidBody3D (Plank) — the seesaw board
│   ├── CollisionShape3D (BoxShape3D: Vector3(4, 0.15, 0.8))
│   └── MeshInstance3D
├── HingeJoint3D — positioned at center of plank, rotated so hinge axis is Z
└── RigidBody3D (SecondBall) — sitting on the light end of the seesaw, ready to be launched
    ├── CollisionShape3D (SphereShape3D)
    └── MeshInstance3D
```

### Area3D Trigger Zone

```gdscript
# trigger_zone.gd
extends Area3D

signal chain_completed

var triggered: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

    # Only detect balls/rigid bodies
    collision_mask = 0
    set_collision_mask_value(1, true)  # world
    # Actually we want to detect the second ball — adjust mask as needed

func _on_body_entered(body: Node3D) -> void:
    if triggered:
        return

    if body is RigidBody3D:
        triggered = true
        chain_completed.emit()
        _celebrate()

func _celebrate() -> void:
    print("=== RUBE GOLDBERG CHAIN COMPLETE! ===")

    # Could spawn particles, play sound, show UI, etc.
    # For now, just print
    var timer := get_tree().create_timer(2.0)
    timer.timeout.connect(func(): get_tree().reload_current_scene())
```

### Player Script (full version for the puzzle)

```gdscript
# player.gd
extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 5.0
@export var gravity: float = 9.8
@export var mouse_sensitivity: float = 0.005
@export var kick_force: float = 15.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var kick_ray: RayCast3D = $KickRay

var can_kick: bool = true

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    spring_arm.spring_length = 4.0
    spring_arm.collision_mask = 1

    kick_ray.enabled = true
    kick_ray.target_position = Vector3(0, 0, -2.0)  # 2m in front
    kick_ray.collision_mask = 0
    kick_ray.set_collision_mask_value(1, true)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
        spring_arm.rotation.x = clampf(spring_arm.rotation.x, -PI / 3.0, PI / 3.0)

    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = (
            Input.MOUSE_MODE_VISIBLE
            if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
            else Input.MOUSE_MODE_CAPTURED
        )

func _physics_process(delta: float) -> void:
    # Gravity
    if not is_on_floor():
        velocity.y -= gravity * delta

    # Jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    # Horizontal movement
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed)
        velocity.z = move_toward(velocity.z, 0.0, speed)

    move_and_slide()

    # Kick action — checks RayCast3D for a domino or rigid body in front
    if Input.is_action_just_pressed("kick") and can_kick:
        _try_kick()

func _try_kick() -> void:
    if not kick_ray.is_colliding():
        return

    var target := kick_ray.get_collider()
    if target is RigidBody3D:
        # Apply impulse in the direction we're facing
        var kick_dir := -transform.basis.z  # character's forward
        kick_dir.y = 0.3  # slight upward angle
        kick_dir = kick_dir.normalized()

        target.apply_central_impulse(kick_dir * kick_force)
        print("Kicked: ", target.name, " with force: ", kick_dir * kick_force)

        can_kick = false
        # Simple cooldown
        get_tree().create_timer(0.5).timeout.connect(func(): can_kick = true)
```

### Main Scene Setup (main.gd)

```gdscript
# main.gd
extends Node3D

@export var domino_scene: PackedScene
@export var domino_count: int = 12
@export var domino_spacing: float = 0.65

func _ready() -> void:
    _place_dominoes()
    _connect_signals()

func _place_dominoes() -> void:
    var domino_parent := Node3D.new()
    domino_parent.name = "Dominoes"
    add_child(domino_parent)

    for i in domino_count:
        var domino: RigidBody3D = domino_scene.instantiate()
        domino_parent.add_child(domino)
        domino.name = "Domino_%02d" % i
        domino.position = Vector3(-3.0 + i * domino_spacing, 0.6, 0.0)
        domino.domino_index = i

func _connect_signals() -> void:
    var trigger: Area3D = $TriggerZone
    trigger.chain_completed.connect(_on_chain_completed)

func _on_chain_completed() -> void:
    print("You win! The Rube Goldberg machine completed!")
    $HUD/WinLabel.visible = true
```

### Collision Layer Setup for the Project

In Project Settings > Layer Names > 3D Physics, name the layers:
```
Layer 1: World
Layer 2: Player
Layer 3: Physics Objects  (dominoes, balls, seesaw)
Layer 4: Triggers
```

Layer assignments:
```
Floor (StaticBody3D):      layer=1, mask=0 (doesn't need to detect anything)
Ramp (StaticBody3D):       layer=1, mask=0
Dominoes (RigidBody3D):    layer=3, mask=1+3 (hits world and other physics objects)
Balls (RigidBody3D):       layer=3, mask=1+3
Seesaw plank (RigidBody):  layer=3, mask=1+3
Player (CharacterBody3D):  layer=2, mask=1+3 (hits world and physics objects)
Trigger (Area3D):          layer=4, mask=3 (detects physics objects)
```

---

## API Quick Reference

### CharacterBody3D

| Method / Property | Description |
|---|---|
| `velocity: Vector3` | Current velocity. Set this, then call move_and_slide() |
| `move_and_slide()` | Moves according to velocity, handles collisions/sliding |
| `is_on_floor() -> bool` | True if standing on a floor surface |
| `is_on_wall() -> bool` | True if touching a wall |
| `is_on_ceiling() -> bool` | True if head on ceiling |
| `get_floor_normal() -> Vector3` | Normal of floor being stood on |
| `get_wall_normal() -> Vector3` | Normal of wall being touched |
| `get_slide_collision_count() -> int` | Number of collisions this frame |
| `get_slide_collision(idx) -> KinematicCollision3D` | Collision info for index |
| `floor_max_angle: float` | Max slope angle that counts as floor (radians) |
| `floor_snap_length: float` | Snap distance to stay on floor on ramps |
| `up_direction: Vector3` | What direction is "up" (default Vector3.UP) |
| `motion_mode` | GROUNDED or FLOATING |

### RigidBody3D

| Method / Property | Description |
|---|---|
| `mass: float` | Object mass in kg |
| `gravity_scale: float` | Multiplier on gravity (0 = float, 1 = normal) |
| `linear_velocity: Vector3` | Current linear velocity |
| `angular_velocity: Vector3` | Current angular velocity |
| `linear_damp: float` | Linear drag (0 = none) |
| `angular_damp: float` | Angular drag (0 = none) |
| `freeze: bool` | Suspend physics simulation |
| `can_sleep: bool` | Allow automatic sleep when stationary |
| `contact_monitor: bool` | Enable body_entered/exited signals |
| `max_contacts_reported: int` | Max simultaneous contacts to track |
| `apply_central_force(force)` | Continuous force from center (use in _physics_process) |
| `apply_force(force, position)` | Force at specific point (causes torque) |
| `apply_central_impulse(impulse)` | Instant velocity change from center |
| `apply_impulse(impulse, position)` | Instant velocity change at point |
| `apply_torque(torque)` | Continuous angular force |
| `apply_torque_impulse(torque)` | Instant angular velocity change |
| `physics_material_override` | PhysicsMaterial resource (bounce, friction) |

### Area3D

| Method / Property | Description |
|---|---|
| `monitoring: bool` | Can this area detect others entering it? |
| `monitorable: bool` | Can other areas detect this one? |
| `get_overlapping_bodies() -> Array` | All physics bodies currently inside |
| `get_overlapping_areas() -> Array` | All Area3D nodes currently inside |
| `body_entered(body: Node3D)` | Signal: physics body entered |
| `body_exited(body: Node3D)` | Signal: physics body exited |
| `area_entered(area: Area3D)` | Signal: another Area3D entered |
| `area_exited(area: Area3D)` | Signal: another Area3D exited |

### RayCast3D

| Method / Property | Description |
|---|---|
| `enabled: bool` | Must be true for the ray to work |
| `target_position: Vector3` | Ray endpoint (local space, relative to node) |
| `collision_mask: int` | Which layers to test against |
| `exclude_parent: bool` | Ignore the parent body (usually set true) |
| `is_colliding() -> bool` | True if ray hit something this frame |
| `get_collider() -> Object` | The object that was hit |
| `get_collider_shape() -> int` | Shape index on the collider |
| `get_collision_point() -> Vector3` | World position of the hit |
| `get_collision_normal() -> Vector3` | Surface normal at the hit |
| `force_raycast_update()` | Force immediate update (outside physics step) |

### SpringArm3D

| Property | Description |
|---|---|
| `spring_length: float` | Max arm length (how far back the camera sits) |
| `collision_mask: int` | Which layers block the spring |
| `margin: float` | Distance from surface to stop at |
| `shape: Shape3D` | Optional shape for sphere-cast instead of ray |
| `get_hit_length() -> float` | Current actual arm length (shorter if blocked) |

### CollisionShape3D Shape Types

| Shape | Best For | Cost |
|---|---|---|
| BoxShape3D | Crates, walls, dominoes, floors | Fast |
| SphereShape3D | Balls, orbs, projectiles | Fastest |
| CapsuleShape3D | Characters, cylinders with smooth ends | Fast |
| CylinderShape3D | Barrels, columns, wheels | Fast |
| ConvexPolygonShape3D | Complex moving objects | Moderate |
| ConcavePolygonShape3D | Exact static geometry (STATIC ONLY) | Slow |
| HeightMapShape3D | Large terrain | Efficient |
| WorldBoundaryShape3D | Infinite floor catch-all | Very fast |

### Joints

| Joint | Movement Allowed | Use For |
|---|---|---|
| PinJoint3D | All rotation, no translation | Pendulums, chains, ball joints |
| HingeJoint3D | Single-axis rotation | Doors, seesaws, wheels |
| SliderJoint3D | Single-axis translation + rotation | Pistons, elevators |
| ConeTwistJoint3D | Cone rotation + twist | Ragdoll shoulders/hips |
| Generic6DOFJoint3D | Fully configurable | Everything else |

### Collision Layer/Mask Functions

| Function | Description |
|---|---|
| `set_collision_layer_value(layer, enabled)` | Set a specific layer bit on/off |
| `set_collision_mask_value(layer, enabled)` | Set a specific mask bit on/off |
| `get_collision_layer_value(layer) -> bool` | Check if a layer bit is set |
| `get_collision_mask_value(layer) -> bool` | Check if a mask bit is set |
| `collision_layer: int` | Raw bitmask of all layer bits |
| `collision_mask: int` | Raw bitmask of all mask bits |

---

## Common Pitfalls

### 1. Moving RigidBody3D by Setting Position

WRONG:
```gdscript
extends RigidBody3D

func _process(delta: float) -> void:
    # This breaks physics — the body teleports, doesn't interact correctly
    position.x += 1.0 * delta
```

RIGHT:
```gdscript
extends RigidBody3D

func _physics_process(delta: float) -> void:
    # Use forces for continuous movement
    apply_central_force(Vector3.RIGHT * 10.0)

    # Or set velocity directly for precise control
    # linear_velocity = Vector3(1.0, linear_velocity.y, linear_velocity.z)

    # Or for a one-time kick, use impulse (called once, not every frame)
    # apply_central_impulse(Vector3.RIGHT * 50.0)
```

Never move a RigidBody3D by directly setting its position unless you're initializing it in `_ready`. Once the simulation is running, use forces, impulses, or velocity.

### 2. Using ConcavePolygonShape3D on a Moving Body

WRONG:
```gdscript
extends RigidBody3D  # or CharacterBody3D

func _ready() -> void:
    var col := CollisionShape3D.new()
    var concave := mesh.create_trimesh_shape()  # ConcavePolygonShape3D
    col.shape = concave  # ERROR — concave shapes are static-only
    add_child(col)
```

RIGHT:
```gdscript
extends RigidBody3D

func _ready() -> void:
    var col := CollisionShape3D.new()

    # Option 1: convex hull (single convex shape)
    var convex := mesh.create_convex_shape()
    col.shape = convex

    # Option 2: multiple primitive shapes to approximate the object
    var box := BoxShape3D.new()
    box.size = Vector3(1.0, 2.0, 0.5)
    col.shape = box

    add_child(col)
```

ConcavePolygonShape3D is ONLY valid for StaticBody3D. Using it on anything that moves will cause physics errors, incorrect behavior, or crashes.

### 3. CharacterBody3D Not Moving (Forgot move_and_slide)

WRONG:
```gdscript
extends CharacterBody3D

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * 5.0
    velocity.z = direction.z * 5.0
    # Character doesn't move — forgot move_and_slide()!
```

RIGHT:
```gdscript
extends CharacterBody3D

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * 5.0
    velocity.z = direction.z * 5.0

    move_and_slide()  # REQUIRED — this is what actually moves the character
```

Setting `velocity` alone does nothing. CharacterBody3D only moves when you call `move_and_slide()`. This is the most common beginner mistake.

### 4. Area3D Not Detecting Anything (Wrong Layers)

WRONG:
```gdscript
# Area3D (pickup)
extends Area3D

func _ready() -> void:
    # collision_mask left at default 1 (World layer only)
    body_entered.connect(_on_body_entered)

# Player is on layer 2, but Area3D only looks at layer 1
# Player walks through pickup — nothing happens
func _on_body_entered(body: Node3D) -> void:
    print("Collected!")  # never fires
```

RIGHT:
```gdscript
extends Area3D

func _ready() -> void:
    # Area3D needs to have mask set to detect player's layer
    collision_mask = 0
    set_collision_mask_value(2, true)  # Player is on layer 2

    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    print("Collected!")  # now fires when player overlaps
```

Also check: does the player's own `collision_layer` include a layer that the Area3D is scanning for? Both directions need to match. Use Debug > Visible Collision Shapes and check the Physics Monitor to verify layers are set correctly.

### 5. RayCast3D Always Returns False (Not Enabled)

WRONG:
```gdscript
extends CharacterBody3D

@onready var ray: RayCast3D = $RayCast3D

func _ready() -> void:
    # Ray was left disabled in the inspector — never updates
    pass

func _physics_process(delta: float) -> void:
    if ray.is_colliding():  # always false
        print("Hit something")
```

RIGHT:
```gdscript
extends CharacterBody3D

@onready var ray: RayCast3D = $RayCast3D

func _ready() -> void:
    ray.enabled = true                          # must be explicitly enabled
    ray.target_position = Vector3(0, 0, -2.0)  # must have a non-zero target
    ray.collision_mask = 1                      # must match something's layer
    ray.exclude_parent = true                   # don't hit our own body

func _physics_process(delta: float) -> void:
    if ray.is_colliding():
        print("Hit: ", ray.get_collider().name)
```

Three things must be right for RayCast3D to work: `enabled = true`, a valid non-zero `target_position`, and a `collision_mask` that matches the layer of whatever you're trying to hit.

---

## Exercises

### Exercise 1: Simple Platformer with Moving Platform and Coin (30–45 min)

Build a basic platformer scene with:

**Setup:**
1. Create a floor (StaticBody3D + BoxShape3D, scale it wide and flat)
2. Add 3–4 floating platforms at different heights (StaticBody3D each)
3. Add a CharacterBody3D player with the standard movement template from Section 4
4. Add a SpringArm3D + Camera3D from Section 5
5. Set up input actions in Project Settings: move_forward, move_back, move_left, move_right, jump

**Moving Platform:**
6. Add one AnimatableBody3D platform that moves up and down using the script from Section 10
7. Set `travel = Vector3(0, 3, 0)` and `speed = 1.5`
8. Place a RigidBody3D box on the platform — verify it rides up and down

**Coin:**
9. Create a coin scene: Area3D + CollisionShape3D (CylinderShape3D) + MeshInstance3D (CylinderMesh)
10. Set the Area3D's collision_mask to detect the Player layer
11. Attach the pickup script from Section 6 — emit a signal when collected
12. Connect the signal in the main scene to update a score counter in a Label node

**Stretch goals:**
- Add a second coin type worth more points
- Make collected coins spin before disappearing (rotate_y in _process before queue_free)
- Add a "you win" message when all coins are collected

### Exercise 2: Bowling Game (45–60 min)

Build a bowling lane:

**Setup:**
1. StaticBody3D lane: long, flat, narrow (40 x 0.2 x 4 units)
2. Side gutters: two StaticBody3D boxes running alongside the lane
3. 10 bowling pins: RigidBody3D + CylinderShape3D, arranged in triangular formation at the end
4. Bowling ball launcher: at the start of the lane, a RigidBody3D ball with `freeze = true`

**Pin setup:**
```gdscript
# Arrange pins in a triangle: 4-3-2-1 formation
# Row 0 (front): 1 pin at z = 0
# Row 1: 2 pins at z = 1.0
# Row 2: 3 pins at z = 2.0
# Row 3: 4 pins at z = 3.0

var pin_positions := [
    Vector3(0, 0.5, 0),
    Vector3(-0.3, 0.5, 1.0), Vector3(0.3, 0.5, 1.0),
    Vector3(-0.6, 0.5, 2.0), Vector3(0.0, 0.5, 2.0), Vector3(0.6, 0.5, 2.0),
    Vector3(-0.9, 0.5, 3.0), Vector3(-0.3, 0.5, 3.0), Vector3(0.3, 0.5, 3.0), Vector3(0.9, 0.5, 3.0),
]
```

**Launch mechanic:**
```gdscript
# Press Space to launch the ball
func _input(event: InputEvent) -> void:
    if event.is_action_just_pressed("jump"):
        ball.freeze = false
        ball.apply_central_impulse(Vector3(0, 0, 20.0))
```

**Pin counter:**
5. Add an Area3D at the end of the lane (behind the pins, width of the lane)
6. Set `monitoring = true`, collision_mask = Physics Objects layer
7. When a pin falls into the zone: increment a knocked-over counter, update a HUD Label
8. Show "Strike!" if count reaches 10

**Stretch goals:**
- Allow two balls per "frame" (classic bowling scoring)
- Reset pins between frames
- Track score across 10 frames

### Exercise 3: Physics-Based Vehicle (60–90 min)

Build a vehicle using joints:

**Chassis:**
1. RigidBody3D chassis: BoxShape3D, mass = 10.0
2. Position it slightly above the floor

**Wheels:**
3. Create 4 wheel scenes: RigidBody3D + CylinderShape3D (rotated 90 degrees on Z), mass = 1.0
4. Attach each wheel to the chassis using HingeJoint3D:
   - node_a: chassis, node_b: wheel
   - Joint positioned at each corner of the chassis
   - HingeJoint3D axis points sideways (Z axis)
   - Enable motor on front wheels

**Driving:**
```gdscript
# In chassis script
@onready var front_left_joint: HingeJoint3D = $FrontLeftJoint
@onready var front_right_joint: HingeJoint3D = $FrontRightJoint

func _physics_process(delta: float) -> void:
    var throttle := Input.get_axis("move_back", "move_forward")

    # Drive via wheel motor
    front_left_joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, throttle != 0.0)
    front_right_joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, throttle != 0.0)

    var target_vel := throttle * 10.0  # radians per second
    front_left_joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, target_vel)
    front_right_joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, target_vel)
    front_left_joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 50.0)
    front_right_joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 50.0)
```

**Ramp:**
5. Add a StaticBody3D ramp (angled ~25 degrees, wide enough to drive over)
6. Drive the vehicle up the ramp

**Stretch: Spring-loaded catapult**
7. Add a RigidBody3D arm connected to a StaticBody3D base with a HingeJoint3D
8. Use a SliderJoint3D for a spring-loaded mechanism: pull the arm back, release to launch a ball
9. Place a ball in a cup on the catapult arm

---

## Key Takeaways

1. **Four body types, each with a distinct role.** StaticBody3D for walls and floors. RigidBody3D for physics-simulated objects. CharacterBody3D for player and NPC movement. AnimatableBody3D for scripted-movement objects that push physics objects. Use the wrong one and you'll spend hours fighting the engine instead of building your game.

2. **Every physics body requires a CollisionShape3D child.** The shape defines the physical boundary. Use primitives (BoxShape3D, SphereShape3D, CapsuleShape3D) whenever possible — they're significantly faster. Save ConvexPolygonShape3D for complex moving objects, and NEVER use ConcavePolygonShape3D on anything that moves.

3. **CharacterBody3D.move_and_slide() is the player movement function.** The full loop is: apply gravity to velocity, handle jump input, apply horizontal velocity from input, call `move_and_slide()`. Setting velocity alone does nothing. `move_and_slide()` must be called every `_physics_process` frame.

4. **Area3D is for detection, not collision.** Things pass through it. Use it for pickup zones, damage volumes, AI detection ranges, and trigger events. Set `monitoring = true` to receive signals, `monitorable = true` to be detected by others. Always set the collision_mask to match only the layers you care about.

5. **Collision layer = what it IS. Collision mask = what it SEES.** Two objects only interact when their layers and masks cross-reference each other. Name your layers in Project Settings. Set layers and masks carefully, especially on Area3D nodes, or detection simply won't work.

6. **RayCast3D requires enabled = true, a valid target_position, and a matching collision_mask.** Use it for ground detection, wall detection, aiming reticles, AI line-of-sight checks, and clicking on objects in the world. For one-shot queries, use PhysicsDirectSpaceState3D instead of a node.

7. **Joints connect bodies with movement constraints.** HingeJoint3D for doors and seesaws, PinJoint3D for pendulums and chains, SliderJoint3D for pistons and elevators, ConeTwistJoint3D for ragdoll limbs. The joint's position is the pivot point — place it accurately. Enable limits and motors via `set_flag` and `set_param`.

---

## What's Next

**[Module 5: Game Architecture — Signals, Resources, Autoloads, and Scene Management](module-05-game-architecture.md)**

Physics handles the movement. Module 5 is where you learn to structure an actual game. We'll cover Godot's signal system (the backbone of decoupled, maintainable code), Resource files for data-driven design, Autoload singletons for game state and managers, and the scene management patterns you'll use to build menus, transitions, and multi-scene games. Everything you built in this module will get a proper architecture around it.

---

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
