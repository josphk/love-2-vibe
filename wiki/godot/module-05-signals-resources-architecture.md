# Module 5: Signals, Resources & Game Architecture

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 6–10 hours
**Prerequisites:** [Module 4: Physics & CharacterBody3D](module-04-physics-characterbody3d.md)

---

## Overview

You can build scenes, import assets, handle physics, and move a character. But if you wire all of that together with direct references — this node knows about that node, which calls that function on that other node — you get spaghetti. Every change breaks something else. Every new feature requires touching ten files. This module teaches you how to build games that don't collapse under their own weight.

Godot gives you three architectural superpowers: signals for decoupled communication, Resources for data-driven design, and autoloads for global state. Signals mean nodes don't need to know about each other — they emit events and whoever cares can listen. Resources mean game data (weapon stats, enemy configs, level layouts) lives in editable files, not hardcoded in scripts. Autoloads mean you can have a GameManager, AudioManager, or SceneTransition handler that persists across scene changes.

By the end of this module, you'll build an arena game with proper architecture: title screen, gameplay with HUD, pause menu, game over screen, wave-based enemy spawning, health and score tracking, and a save system — all held together by signals and autoloads with zero spaghetti.

---

## 1. Signals Deep Dive

Signals are Godot's built-in implementation of the observer pattern. You've used them before — connecting a button's `pressed` signal in Module 1, connecting `body_entered` on an Area3D in Module 3. Now it's time to master them completely, including custom signals, all four connection styles, flags, and when to disconnect.

### What Signals Actually Are

Under the hood, a signal is a list of callables. When you emit a signal, Godot iterates that list and calls every connected function. The emitting node doesn't know anything about its listeners — it just yells into the void. Whoever chose to listen gets the call.

This is the decoupling that matters. A `Player` node can have a `died` signal without knowing anything about the `GameManager`, the HUD, the death animation controller, or the respawn system. All of those can connect to `died` and do their thing. The `Player` only knows one thing: emit the signal when health hits zero.

### Declaring Custom Signals

Declare signals at the top of your script with the `signal` keyword, optionally followed by typed parameters:

```gdscript
# player.gd
extends CharacterBody3D

signal health_changed(new_health: int, max_health: int)
signal died
signal item_picked_up(item: Resource)
signal wave_completed(wave_number: int)
```

No types are required for signal parameters, but adding them is good practice — the editor will show them in the Signals tab and other scripters will know what to expect when connecting.

If a signal has no parameters (like `died` above), it's just a notification. If it has parameters, they carry data to every listener.

### Emitting Signals

Call `.emit()` on the signal reference:

```gdscript
# player.gd
@export var max_health: int = 100
var health: int = 100

func take_damage(amount: int) -> void:
    health = clampi(health - amount, 0, max_health)
    health_changed.emit(health, max_health)
    if health <= 0:
        died.emit()

func heal(amount: int) -> void:
    health = clampi(health + amount, 0, max_health)
    health_changed.emit(health, max_health)
```

The signal parameters match the declaration — `health_changed` takes `(new_health: int, max_health: int)`, so `.emit(health, max_health)` passes both values to every listener simultaneously.

### Four Ways to Connect

**1. Editor connection (Node dock > Signals tab)**

Select the emitting node in the scene tree. Open the Node dock on the right side (next to the Inspector tab). Click the "Signals" tab. You'll see all signals for that node type plus any custom signals declared in its script. Double-click a signal to open the connection dialog. Pick the receiving node and the editor auto-generates a `_on_NodeName_signal_name` method in the receiver's script.

This approach is great for connections that are permanent parts of a scene's setup — a button that always calls a specific function. The connection is saved in the `.tscn` file, not in code.

**2. Code connection**

```gdscript
# In the receiver's _ready():
func _ready() -> void:
    player.health_changed.connect(_on_player_health_changed)
    player.died.connect(_on_player_died)

func _on_player_health_changed(new_health: int, max_health: int) -> void:
    health_bar.value = float(new_health) / float(max_health) * 100.0

func _on_player_died() -> void:
    game_over_screen.show()
```

Use this when the connection is established at runtime (because both nodes just entered the scene) or when the relationship is dynamic.

**3. Lambda connection**

```gdscript
func _ready() -> void:
    player.health_changed.connect(func(hp: int, max_hp: int):
        health_label.text = "%d / %d" % [hp, max_hp]
    )

    player.died.connect(func():
        get_tree().paused = true
        game_over_panel.show()
    )
```

Lambdas are great for short, one-off logic that doesn't need its own named method. Be careful: you can't easily disconnect a lambda later because you don't have a reference to it. If you need to disconnect, store the lambda in a variable first.

**4. One-shot connection**

```gdscript
func wait_for_first_hit() -> void:
    enemy.took_damage.connect(
        func(): print("Enemy took its first hit!"),
        CONNECT_ONE_SHOT
    )
```

`CONNECT_ONE_SHOT` automatically disconnects after the first emission. Perfect for "do this exactly once" scenarios: the first time the player enters an area, triggering a cutscene; a tutorial prompt that shows once and never again.

### Connection Flags

Flags are passed as the second argument to `.connect()`:

```gdscript
# Syntax: signal.connect(callable, flags)
some_signal.connect(my_func, CONNECT_DEFERRED)
some_signal.connect(my_func, CONNECT_ONE_SHOT)
some_signal.connect(my_func, CONNECT_REFERENCE_COUNTED)

# Combine with bitwise OR:
some_signal.connect(my_func, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
```

| Flag | Effect |
|------|--------|
| `CONNECT_DEFERRED` | Calls the handler at the end of the current frame instead of immediately. Safe for operations that modify the scene tree (adding/removing nodes) from within a physics callback. |
| `CONNECT_ONE_SHOT` | Auto-disconnects after the first emission. |
| `CONNECT_REFERENCE_COUNTED` | Increments a reference count. The connection is only removed when `.disconnect()` is called the same number of times it was connected. Rarely needed. |

`CONNECT_DEFERRED` is the most important flag in practice. If you're in `_physics_process` and you emit a signal that tries to add or remove a Node from the scene tree, Godot will crash or warn you. Mark the handler as deferred and the scene modification happens safely at idle time.

### Disconnecting

```gdscript
func _exit_tree() -> void:
    if player.died.is_connected(_on_player_died):
        player.died.disconnect(_on_player_died)
```

When should you manually disconnect?

- **Before freeing the listener node** — if a node gets `queue_free()`'d while still connected to signals on other nodes that remain alive, Godot can call into freed memory. Godot 4 is mostly safe about this (it cleans up Object connections when the Object is freed), but manual cleanup is good practice.
- **When rebinding** — if you're reassigning which player the HUD listens to (e.g., multiplayer), disconnect from the old player before connecting to the new one.
- **Lambdas stored in variables** — if you stored a lambda reference and want to remove just that connection.

Check existence before disconnecting with `.is_connected()` to avoid errors.

### Awaiting Signals

You can use `await` to pause a coroutine until a signal fires:

```gdscript
func _ready() -> void:
    # Wait until the player dies before doing anything
    await player.died
    print("Player is dead, showing game over")
    game_over_screen.show()

func start_cutscene() -> void:
    animation_player.play("intro")
    await animation_player.animation_finished
    dialogue_box.start("scene_001")
    await dialogue_box.dialogue_finished
    get_tree().paused = false
```

`await` turns the function into a coroutine. Execution suspends at the `await` line and resumes when the signal fires. This is incredibly powerful for sequencing animations, dialogue, transitions, and tutorial steps without nested callbacks.

---

## 2. The Signal Bus Pattern

Direct signals work great for parent-child communication. The player emits `died`, the GameplayScene (parent) listens and responds. But what about communicating across scenes, between nodes with no relationship? The HUD needs to know the score changed. The AudioManager needs to know the player was hit. The SaveManager needs to know the wave was completed.

You could pass references everywhere. You could use `get_tree().get_root().find_child(...)`. Both are nightmares to maintain. Instead, use a global signal bus.

### Creating the Events Autoload

Create a new script at `res://autoloads/events.gd`:

```gdscript
# events.gd
# Global signal bus. Any node can emit, any node can listen.
# No direct references required.
extends Node

# Player signals
signal player_damaged(amount: int)
signal player_healed(amount: int)
signal player_died
signal player_health_changed(new_health: int, max_health: int)

# Enemy signals
signal enemy_killed(enemy_position: Vector3, score_value: int)
signal enemy_spawned(enemy: Node3D)

# Score / wave signals
signal score_changed(new_score: int)
signal high_score_beaten(new_high_score: int)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

# Game state signals
signal game_state_changed(new_state: int)
signal game_paused
signal game_resumed

# UI signals
signal request_scene_change(scene_path: String)
```

Register it in Project Settings > Autoload (see Section 5 for how). Once registered as "Events", every script in your entire project can access it.

### Emitting on the Bus

```gdscript
# enemy.gd — emits when it dies
func die() -> void:
    Events.enemy_killed.emit(global_position, score_value)
    queue_free()

# player.gd — emits when taking damage
func take_damage(amount: int) -> void:
    health = clampi(health - amount, 0, max_health)
    Events.player_damaged.emit(amount)
    Events.player_health_changed.emit(health, max_health)
    if health <= 0:
        Events.player_died.emit()
```

### Listening on the Bus

```gdscript
# hud.gd — listens to multiple game events
func _ready() -> void:
    Events.player_health_changed.connect(_on_player_health_changed)
    Events.score_changed.connect(_on_score_changed)
    Events.wave_started.connect(_on_wave_started)
    Events.wave_completed.connect(_on_wave_completed)

func _on_player_health_changed(new_health: int, max_health: int) -> void:
    health_bar.value = float(new_health) / float(max_health) * 100.0
    health_label.text = str(new_health)

func _on_score_changed(new_score: int) -> void:
    score_label.text = "Score: %d" % new_score

func _on_wave_started(wave_number: int) -> void:
    wave_label.text = "Wave %d" % wave_number

func _on_wave_completed(wave_number: int) -> void:
    wave_label.text = "Wave %d Complete!" % wave_number
```

The HUD has zero knowledge of the Player, the EnemySpawner, or the GameManager. It just subscribes to events and updates itself. You can rearrange your entire scene tree and the HUD keeps working.

### Signal Bus vs Direct Signals — When to Use Each

| Scenario | Use |
|----------|-----|
| Parent-child communication | Direct signal on the child |
| Sibling node communication within the same scene | Direct signal, parent manages the connection |
| Cross-scene communication (HUD ↔ enemies) | Signal bus (Events autoload) |
| One-time notifications ("player entered tutorial zone") | Signal bus |
| Two nodes that always exist together | Either — direct is simpler |
| Events that multiple unrelated systems need to hear | Signal bus |

The rule of thumb: if you're tempted to write `get_parent().get_parent().find_child("HUD")`, use the signal bus instead.

---

## 3. Custom Resources

Resources are Godot's data containers — serializable objects that live as files on disk. Textures, meshes, audio streams, shaders, and materials are all Resources. But you can create your own.

### Defining a Resource Class

```gdscript
# weapon_data.gd
class_name WeaponData
extends Resource

@export var name: String = "Sword"
@export var damage: float = 10.0
@export var attack_speed: float = 1.0  # attacks per second
@export var range: float = 2.0
@export var knockback_force: float = 200.0
@export var icon: Texture2D
@export var sound_effect: AudioStream
@export var hit_effect_scene: PackedScene
@export_multiline var description: String = ""

# Computed properties can live here too
func get_dps() -> float:
    return damage * attack_speed
```

`class_name WeaponData` registers this resource type globally. `extends Resource` makes it serializable.

### Creating Resource Instances

Two ways:

**In the editor:** Right-click anywhere in the FileSystem dock > New Resource > type "WeaponData" in the search box > double-click it. A new `new_weapon_data.tres` file appears. Rename it to `sword.tres`. Click it to open the Inspector and fill in all the `@export` fields — name, damage, speed, etc. Assign a texture to the icon field, an audio file to sound_effect.

**In code:**
```gdscript
var sword := WeaponData.new()
sword.name = "Iron Sword"
sword.damage = 15.0
sword.attack_speed = 1.2
ResourceSaver.save(sword, "res://resources/weapons/iron_sword.tres")
```

### Using Resources in Scripts

```gdscript
# player.gd
@export var weapon: WeaponData

func attack() -> void:
    if weapon == null:
        push_warning("Player has no weapon equipped!")
        return

    deal_damage_in_range(weapon.damage, weapon.range)

    if weapon.sound_effect:
        audio_player.stream = weapon.sound_effect
        audio_player.play()

    if weapon.hit_effect_scene:
        var effect := weapon.hit_effect_scene.instantiate()
        get_tree().current_scene.add_child(effect)
        effect.global_position = attack_point.global_position

func get_attack_tooltip() -> String:
    if weapon:
        return "%s\n%s\nDPS: %.1f" % [weapon.name, weapon.description, weapon.get_dps()]
    return "No weapon equipped"
```

In the Inspector for the player scene, you drag `sword.tres` into the `weapon` slot. Want a different enemy to use a bow? Create `bow.tres` with different values and drag it in. No code changes.

### Shared vs Duplicated Resources

This is a critical gotcha: when two nodes reference the same `.tres` file, they share the same Resource instance in memory. Modifying one modifies both:

```gdscript
# PROBLEM: Both enemies share the same health resource
var enemy_a_data: EnemyData = preload("res://resources/goblin.tres")
var enemy_b_data: EnemyData = preload("res://resources/goblin.tres")
enemy_a_data.current_health -= 50
# enemy_b_data.current_health is ALSO reduced by 50!
```

Solution: use `duplicate()` to get an independent copy:

```gdscript
# CORRECT: Each enemy gets its own copy of the data
func _ready() -> void:
    data = preload("res://resources/goblin.tres").duplicate()
    # Now modifying data.current_health only affects this enemy
```

The rule: static/read-only data (damage values, names, textures) can be shared. Runtime state (current health, current ammo) must be duplicated per instance.

### Resource vs Node — When to Use Each

| Resource | Node |
|----------|------|
| Data that lives in files | Behavior that exists in the scene |
| Shared configuration | Things that need to be in the scene tree |
| Serializable game content | Things that need `_process`, physics, input |
| Can be used without being in the scene | Must be added to the scene tree to function |
| Examples: WeaponData, EnemyStats, LevelConfig | Examples: Player, Enemy, Camera, Area3D |

The core principle: **Resources are data. Nodes are behavior.** Don't put game logic in Resources. A `WeaponData` resource shouldn't have an `attack()` function — that belongs in the `Player` or `Weapon` node that reads the resource.

---

## 4. Resource-Driven Design Patterns

Custom Resources transform how you design game content. Here are four patterns that show up in almost every serious game.

### Pattern 1: Enemy Configuration

```gdscript
# enemy_data.gd
class_name EnemyData
extends Resource

enum BehaviorType { MELEE, RANGED, HEALER, TANK }

@export var display_name: String = "Enemy"
@export var max_health: int = 50
@export var move_speed: float = 3.0
@export var damage: int = 10
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.0
@export var score_value: int = 100
@export var behavior: BehaviorType = BehaviorType.MELEE

# Visual
@export var mesh: Mesh
@export var material: Material

# Audio
@export var attack_sound: AudioStream
@export var death_sound: AudioStream
@export var hurt_sound: AudioStream

# Drops
@export var drop_chance: float = 0.3
@export var possible_drops: Array[Resource] = []
```

Now a single enemy script handles every enemy type:

```gdscript
# base_enemy.gd
class_name BaseEnemy
extends CharacterBody3D

@export var data: EnemyData

var current_health: int
var attack_timer: float = 0.0

func _ready() -> void:
    if data == null:
        push_error("Enemy has no EnemyData resource assigned!")
        return

    current_health = data.max_health
    # Apply visual from data
    if data.mesh:
        $MeshInstance3D.mesh = data.mesh
    if data.material:
        $MeshInstance3D.set_surface_override_material(0, data.material)

func take_damage(amount: int) -> void:
    current_health -= amount
    if data.hurt_sound:
        $AudioStreamPlayer3D.stream = data.hurt_sound
        $AudioStreamPlayer3D.play()
    if current_health <= 0:
        die()

func die() -> void:
    if data.death_sound:
        $AudioStreamPlayer3D.stream = data.death_sound
        $AudioStreamPlayer3D.play()
    Events.enemy_killed.emit(global_position, data.score_value)
    queue_free()
```

Create `goblin.tres`, `skeleton.tres`, `troll.tres` in the FileSystem — all `EnemyData` instances with different values. Drag them into different enemy scene instances. One script, infinite enemy variety.

### Pattern 2: Loot Table

```gdscript
# loot_entry.gd
class_name LootEntry
extends Resource

@export var item_data: Resource  # ItemData resource
@export var weight: float = 1.0  # Relative probability weight
@export var min_quantity: int = 1
@export var max_quantity: int = 1
```

```gdscript
# loot_table.gd
class_name LootTable
extends Resource

@export var entries: Array[LootEntry] = []

func roll() -> Array[Resource]:
    if entries.is_empty():
        return []

    # Calculate total weight
    var total_weight := 0.0
    for entry in entries:
        total_weight += entry.weight

    # Pick a random entry based on weight
    var roll := randf() * total_weight
    var accumulated := 0.0

    for entry in entries:
        accumulated += entry.weight
        if roll <= accumulated:
            var quantity := randi_range(entry.min_quantity, entry.max_quantity)
            var result: Array[Resource] = []
            for i in quantity:
                result.append(entry.item_data.duplicate())
            return result

    return []
```

Now an enemy's `die()` function rolls its loot table:

```gdscript
func die() -> void:
    if data.loot_table and randf() < data.drop_chance:
        var drops := data.loot_table.roll()
        for item in drops:
            spawn_pickup(item, global_position)
    Events.enemy_killed.emit(global_position, data.score_value)
    queue_free()
```

Designers configure loot by editing `.tres` files. A rare sword has `weight: 0.05`, a common health potion has `weight: 5.0`. No code changes needed.

### Pattern 3: Level Definition

```gdscript
# level_data.gd
class_name LevelData
extends Resource

@export var level_name: String = "Level 1"
@export var wave_count: int = 3
@export var base_enemies_per_wave: int = 5
@export var enemies_increase_per_wave: int = 2
@export var spawn_interval: float = 1.0
@export var enemy_types: Array[EnemyData] = []
@export var boss_enemy: EnemyData  # Spawns on final wave
@export var background_music: AudioStream
@export var environment: Environment
@export var next_level: LevelData  # Chain levels together
@export_multiline var level_description: String = ""

func get_enemy_count_for_wave(wave: int) -> int:
    return base_enemies_per_wave + (wave - 1) * enemies_increase_per_wave
```

The wave spawner reads from the `LevelData` resource and never needs to know about specific enemy types. Add a new level by creating a new `level_01.tres` file in the editor.

### Pattern 4: Ability / Skill System

```gdscript
# ability_data.gd
class_name AbilityData
extends Resource

enum TargetType { SELF, ENEMY, AREA, PROJECTILE }

@export var ability_name: String = "Fireball"
@export var description: String = ""
@export var cooldown: float = 2.0
@export var mana_cost: int = 20
@export var damage: float = 30.0
@export var range: float = 10.0
@export var area_radius: float = 3.0
@export var target_type: TargetType = TargetType.PROJECTILE
@export var icon: Texture2D
@export var effect_scene: PackedScene  # Visual effect when cast
@export var projectile_scene: PackedScene
@export var cast_sound: AudioStream
```

```gdscript
# ability_component.gd — attach to any entity that uses abilities
class_name AbilityComponent
extends Node

@export var abilities: Array[AbilityData] = []
var cooldown_timers: Dictionary = {}

func _ready() -> void:
    for ability in abilities:
        cooldown_timers[ability] = 0.0

func _process(delta: float) -> void:
    for ability in cooldown_timers:
        if cooldown_timers[ability] > 0.0:
            cooldown_timers[ability] -= delta

func try_use_ability(index: int, target_position: Vector3) -> bool:
    if index >= abilities.size():
        return false
    var ability := abilities[index]
    if cooldown_timers[ability] > 0.0:
        return false
    cooldown_timers[ability] = ability.cooldown
    _execute_ability(ability, target_position)
    return true

func _execute_ability(ability: AbilityData, target: Vector3) -> void:
    if ability.cast_sound:
        $AudioStreamPlayer3D.stream = ability.cast_sound
        $AudioStreamPlayer3D.play()
    if ability.effect_scene:
        var effect := ability.effect_scene.instantiate()
        get_tree().current_scene.add_child(effect)
        effect.global_position = get_parent().global_position
    match ability.target_type:
        AbilityData.TargetType.PROJECTILE:
            _spawn_projectile(ability, target)
        AbilityData.TargetType.AREA:
            _apply_area_damage(ability, target)
```

A player and an enemy boss can both use the same `AbilityComponent` with different `AbilityData` resources assigned. Designers build the entire skill system in the FileSystem without writing a line of code.

---

## 5. Autoloads (Singletons)

Autoloads are scripts or scenes that Godot instantiates at startup and keeps alive for the entire game session. They survive scene changes — when you transition from the title screen to the gameplay scene, your autoloads keep running with all their state intact.

### Registering an Autoload

1. Open Project > Project Settings
2. Click the "Autoload" tab
3. In the "Path" field, browse to your script (e.g., `res://autoloads/game_manager.gd`)
4. In the "Name" field, type the global name (e.g., `GameManager`)
5. Click Add
6. Repeat for each autoload

Now every script in the project can access `GameManager` directly, like a global variable.

### GameManager Autoload

```gdscript
# game_manager.gd
extends Node

enum GameState {
    TITLE,
    PLAYING,
    PAUSED,
    GAME_OVER,
    LOADING
}

var current_state: GameState = GameState.TITLE
var score: int = 0
var high_score: int = 0
var current_wave: int = 0
var total_enemies_killed: int = 0

func _ready() -> void:
    load_high_score()

func change_state(new_state: GameState) -> void:
    current_state = new_state
    Events.game_state_changed.emit(new_state)

    match new_state:
        GameState.PLAYING:
            get_tree().paused = false
        GameState.PAUSED:
            get_tree().paused = true
        GameState.GAME_OVER:
            get_tree().paused = false  # Game over screen must run
            if score > high_score:
                high_score = score
                save_high_score()
                Events.high_score_beaten.emit(high_score)

func add_score(amount: int) -> void:
    score += amount
    Events.score_changed.emit(score)

func enemy_killed() -> void:
    total_enemies_killed += 1

func start_game() -> void:
    score = 0
    current_wave = 0
    total_enemies_killed = 0
    change_state(GameState.PLAYING)

func reset_to_title() -> void:
    score = 0
    current_wave = 0
    change_state(GameState.TITLE)

func save_high_score() -> void:
    var config := ConfigFile.new()
    config.set_value("game", "high_score", high_score)
    config.save("user://save.cfg")

func load_high_score() -> void:
    var config := ConfigFile.new()
    if config.load("user://save.cfg") == OK:
        high_score = config.get_value("game", "high_score", 0)
```

### AudioManager Autoload

```gdscript
# audio_manager.gd
extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_pool: Array[AudioStreamPlayer] = []

const SFX_POOL_SIZE := 8

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

func _ready() -> void:
    # Create SFX player pool
    for i in SFX_POOL_SIZE:
        var player := AudioStreamPlayer.new()
        add_child(player)
        sfx_pool.append(player)
    load_volume_settings()

func play_music(stream: AudioStream, fade_in: bool = true) -> void:
    if music_player.stream == stream:
        return
    music_player.stream = stream
    music_player.volume_db = linear_to_db(music_volume)
    music_player.play()

func stop_music() -> void:
    music_player.stop()

func play_sfx(stream: AudioStream, volume_scale: float = 1.0) -> void:
    if stream == null:
        return
    # Find a free player from the pool
    for player in sfx_pool:
        if not player.playing:
            player.stream = stream
            player.volume_db = linear_to_db(sfx_volume * volume_scale)
            player.play()
            return
    # All players busy — use the first one (oldest sound gets cut)
    sfx_pool[0].stream = stream
    sfx_pool[0].play()

func set_master_volume(value: float) -> void:
    master_volume = value
    AudioServer.set_bus_volume_db(0, linear_to_db(value))

func set_music_volume(value: float) -> void:
    music_volume = value
    music_player.volume_db = linear_to_db(value)

func set_sfx_volume(value: float) -> void:
    sfx_volume = value

func save_volume_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "master", master_volume)
    config.set_value("audio", "music", music_volume)
    config.set_value("audio", "sfx", sfx_volume)
    config.save("user://settings.cfg")

func load_volume_settings() -> void:
    var config := ConfigFile.new()
    if config.load("user://settings.cfg") != OK:
        return
    master_volume = config.get_value("audio", "master", 1.0)
    music_volume = config.get_value("audio", "music", 0.8)
    sfx_volume = config.get_value("audio", "sfx", 1.0)
    set_master_volume(master_volume)
    set_music_volume(music_volume)
```

To play a sound anywhere in the game: `AudioManager.play_sfx(weapon.sound_effect)`. No AudioStreamPlayer node juggling required.

### Autoload Gotchas

**Don't abuse autoloads.** Every system does not need to be global. Ask yourself: "Does this need to survive scene changes, or does it just need to be accessed from multiple places?" If it's the latter, use a signal bus instead.

**Don't store scene-specific nodes in autoloads.** The GameManager should not hold a reference to the `Player` node — that node is freed when the scene changes. Store data (score, health), not scene objects.

**Load order matters.** Autoloads are instantiated in the order listed in Project Settings. If `Events.gd` needs to be available when `GameManager._ready()` runs, make sure `Events` is listed above `GameManager`.

**Circular dependencies can happen.** If `Events` connects to `GameManager` in its `_ready()` and `GameManager` connects to `Events` in its `_ready()`, the order matters. The signal bus pattern avoids this — `Events` only declares signals, it doesn't connect anything.

### Common Autoloads Cheatsheet

| Autoload Name | What it does |
|---------------|--------------|
| `Events` | Signal bus — all game-wide event declarations |
| `GameManager` | Score, state machine, wave tracking, high score |
| `AudioManager` | Music and SFX playback with volume control |
| `SceneManager` | Scene transitions with fade animations |
| `SaveManager` | Serialized save/load of game progress |
| `InputManager` | Remappable keybindings saved to disk |

---

## 6. Scene Transitions

Changing scenes is one of the most common operations in any game, and getting it wrong produces either crashes or jarring cuts. Here's the full toolkit.

### Simple Change (Instant)

```gdscript
# Anywhere in your code:
get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
```

This frees the current scene, loads the new one, and runs `_ready()` on all the new nodes. It's synchronous — it can block for a frame if the scene is large. Fine for small scenes. Jarring for big ones.

**Important:** Never call `change_scene_to_file` during `_physics_process` or from within a signal emitted during physics processing. Use `call_deferred` instead:

```gdscript
# Safe version:
call_deferred("_do_scene_change", "res://scenes/gameplay.tscn")

func _do_scene_change(path: String) -> void:
    get_tree().change_scene_to_file(path)
```

### Change with Preloaded Scene

```gdscript
# Preload at script top (happens when script compiles):
const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")

# Use later:
get_tree().change_scene_to_packed(GAMEPLAY_SCENE)
```

Faster than `change_scene_to_file` because the PackedScene is already in memory. Use this for scenes you know you'll always need (title screen → gameplay → game over — these always happen in sequence).

### SceneManager Autoload with Fade

Create the SceneManager as an autoload that includes an AnimationPlayer for fade transitions:

```gdscript
# scene_manager.gd
extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    # Start faded in — play fade_in immediately
    color_rect.color = Color(0, 0, 0, 1)
    anim_player.play("fade_in")

func change_scene(scene_path: String) -> void:
    anim_player.play("fade_out")
    await anim_player.animation_finished
    get_tree().change_scene_to_file(scene_path)
    await get_tree().process_frame  # Wait one frame for scene to load
    anim_player.play("fade_in")

func reload_current_scene() -> void:
    change_scene(get_tree().current_scene.scene_file_path)
```

In the SceneManager's scene (it should be a scene, not just a script, so it can have child nodes), create:
- Root: `CanvasLayer` (layer = 100, to appear on top of everything)
  - `ColorRect` (full screen, black, mouse_filter = IGNORE)
  - `AnimationPlayer` with two animations:
    - `fade_out`: Animates `ColorRect.color.a` from 0.0 to 1.0 over 0.3 seconds
    - `fade_in`: Animates `ColorRect.color.a` from 1.0 to 0.0 over 0.3 seconds

Register this scene (not script) as the SceneManager autoload.

Usage from anywhere:

```gdscript
SceneManager.change_scene("res://scenes/gameplay.tscn")
```

### Threaded Loading for Large Scenes

For large scenes (complex levels, many assets), load on a background thread while showing a loading screen:

```gdscript
# scene_manager.gd — extended with threaded loading
var _queued_scene_path: String = ""

func change_scene_with_loading(scene_path: String) -> void:
    _queued_scene_path = scene_path
    anim_player.play("fade_out")
    await anim_player.animation_finished

    # Start background loading
    ResourceLoader.load_threaded_request(scene_path)

    # Switch to loading screen
    get_tree().change_scene_to_file("res://ui/loading_screen.tscn")
    anim_player.play("fade_in")

    # Poll for completion
    while true:
        var status := ResourceLoader.load_threaded_get_status(scene_path)
        match status:
            ResourceLoader.THREAD_LOAD_LOADED:
                var packed_scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
                anim_player.play("fade_out")
                await anim_player.animation_finished
                get_tree().change_scene_to_packed(packed_scene)
                anim_player.play("fade_in")
                return
            ResourceLoader.THREAD_LOAD_FAILED:
                push_error("Failed to load scene: " + scene_path)
                return
        # Emit progress to loading screen
        var progress := []
        ResourceLoader.load_threaded_get_status(scene_path, progress)
        if not progress.is_empty():
            Events.loading_progress_updated.emit(progress[0])
        await get_tree().process_frame
```

The loading screen subscribes to `Events.loading_progress_updated` and shows a progress bar.

---

## 7. Pausing the Game

Godot's pause system is clean and powerful. One line pauses the game world. One setting keeps the pause menu running.

### The Basic Mechanism

```gdscript
get_tree().paused = true   # Pause
get_tree().paused = false  # Unpause
```

When `paused` is `true`, Godot stops calling `_process`, `_physics_process`, and `_input` on all nodes with `process_mode = PROCESS_MODE_PAUSABLE` (which is the default for most nodes). Physics bodies freeze. Timers stop. The game world halts.

### Process Mode Options

Every Node has a `process_mode` property. Set it in the Inspector or in code.

| Value | Constant | Behavior |
|-------|----------|----------|
| Inherit | `PROCESS_MODE_INHERIT` | Uses parent's mode. Default for most nodes. |
| Pausable | `PROCESS_MODE_PAUSABLE` | Stops when tree is paused. Default effective mode. |
| When Paused | `PROCESS_MODE_WHEN_PAUSED` | Only runs when the tree IS paused. |
| Always | `PROCESS_MODE_ALWAYS` | Runs regardless of pause state. |
| Disabled | `PROCESS_MODE_DISABLED` | Never runs `_process` etc. |

The pause menu must use `PROCESS_MODE_ALWAYS` — otherwise it pauses itself and you can never interact with it.

### Building the Pause Menu

```gdscript
# pause_menu.gd
extends CanvasLayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    # Listen for game state changes
    Events.game_state_changed.connect(_on_game_state_changed)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):  # Escape key
        toggle_pause()

func toggle_pause() -> void:
    var will_pause := not get_tree().paused
    if will_pause:
        GameManager.change_state(GameManager.GameState.PAUSED)
    else:
        GameManager.change_state(GameManager.GameState.PLAYING)

func _on_game_state_changed(new_state: int) -> void:
    match new_state:
        GameManager.GameState.PAUSED:
            visible = true
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        GameManager.GameState.PLAYING:
            visible = false
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed() -> void:
    GameManager.change_state(GameManager.GameState.PLAYING)

func _on_quit_to_menu_button_pressed() -> void:
    get_tree().paused = false  # Must unpause before changing scene
    SceneManager.change_scene("res://scenes/title_screen.tscn")

func _on_quit_game_button_pressed() -> void:
    get_tree().quit()
```

### Animating Paused Elements

Animations run via `AnimationPlayer`, which respects pause by default. If you want a pause menu animation to play while paused, set the `AnimationPlayer`'s `process_mode` to `PROCESS_MODE_ALWAYS` or set it to use `AnimationPlayer.ANIMATION_PROCESS_MANUAL` and tick it from your always-running pause menu script.

For UI animations (tweens), `Tween` also has a `TweenProcessMode`. Use:

```gdscript
var tween := create_tween()
tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)  # Default — pauses with tree
# or:
tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)  # Also pauses with tree
```

Tweens created while the tree is paused and running from an ALWAYS node will run correctly. Tweens created from the paused game world will stop.

---

## 8. Save and Load

Godot provides three save/load mechanisms suited to different needs. Use the right tool.

### ConfigFile — Settings and Simple Persistent Data

`ConfigFile` reads and writes Windows `.ini`-style files. It's perfect for user preferences that need to survive between sessions but don't need complex structure.

```gdscript
# settings_manager.gd

const SETTINGS_PATH := "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var fullscreen: bool = false
var mouse_sensitivity: float = 0.3

func save_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "master_volume", master_volume)
    config.set_value("audio", "music_volume", music_volume)
    config.set_value("audio", "sfx_volume", sfx_volume)
    config.set_value("video", "fullscreen", fullscreen)
    config.set_value("gameplay", "mouse_sensitivity", mouse_sensitivity)
    var err := config.save(SETTINGS_PATH)
    if err != OK:
        push_error("Failed to save settings: " + str(err))

func load_settings() -> void:
    var config := ConfigFile.new()
    var err := config.load(SETTINGS_PATH)
    if err != OK:
        # No settings file yet — use defaults
        return
    master_volume = config.get_value("audio", "master_volume", 1.0)
    music_volume = config.get_value("audio", "music_volume", 0.8)
    sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
    fullscreen = config.get_value("video", "fullscreen", false)
    mouse_sensitivity = config.get_value("gameplay", "mouse_sensitivity", 0.3)

    # Apply loaded settings
    AudioManager.set_master_volume(master_volume)
    AudioManager.set_music_volume(music_volume)
    if fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
```

`get_value()` takes a default as the third argument — so if the key doesn't exist (first run, or the player added a new setting), you get a safe fallback.

### JSON — Game State and Level Progress

JSON is human-readable and easily transferable. Great for save files you might want to inspect or modify externally. Not suitable for binary data (textures, audio) — store references by path instead.

```gdscript
# save_manager.gd (part of GameManager or separate autoload)

const SAVE_PATH := "user://save.json"

func save_game() -> void:
    var player := get_tree().get_first_node_in_group("player")

    var save_data := {
        "version": 1,  # For migration if save format changes later
        "timestamp": Time.get_unix_time_from_system(),
        "score": GameManager.score,
        "high_score": GameManager.high_score,
        "current_wave": GameManager.current_wave,
        "total_kills": GameManager.total_enemies_killed,
        "player": {
            "health": player.health if player else 100,
            "max_health": player.max_health if player else 100,
            "position": {
                "x": player.global_position.x if player else 0.0,
                "y": player.global_position.y if player else 0.0,
                "z": player.global_position.z if player else 0.0,
            }
        }
    }

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Could not open save file for writing: " + str(FileAccess.get_open_error()))
        return
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()
    print("Game saved.")

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_error("Could not open save file for reading.")
        return {}

    var json_text := file.get_as_text()
    file.close()

    var data = JSON.parse_string(json_text)
    if data == null:
        push_error("Save file is corrupt or invalid JSON.")
        return {}

    return data

func apply_save_data(data: Dictionary) -> void:
    if data.is_empty():
        return
    GameManager.score = data.get("score", 0)
    GameManager.high_score = data.get("high_score", 0)
    GameManager.current_wave = data.get("current_wave", 0)

    var player_data: Dictionary = data.get("player", {})
    var player := get_tree().get_first_node_in_group("player")
    if player and not player_data.is_empty():
        player.health = player_data.get("health", player.max_health)
        var pos_data: Dictionary = player_data.get("position", {})
        player.global_position = Vector3(
            pos_data.get("x", 0.0),
            pos_data.get("y", 0.0),
            pos_data.get("z", 0.0)
        )
```

### Resource Serialization — Complex Typed Data

For save data with rich structure, typed arrays, and relationships, serialize a custom Resource. This approach gives you full GDScript type safety:

```gdscript
# save_data.gd
class_name SaveData
extends Resource

@export var version: int = 1
@export var score: int = 0
@export var high_score: int = 0
@export var current_wave: int = 0
@export var player_health: int = 100
@export var player_position: Vector3 = Vector3.ZERO
@export var unlocked_levels: Array[String] = []
@export var inventory_item_paths: Array[String] = []  # Paths to ItemData .tres files
@export var playtime_seconds: float = 0.0
```

```gdscript
# In save_manager.gd or game_manager.gd:

const SAVE_RES_PATH := "user://save.tres"

func save_to_resource() -> void:
    var player := get_tree().get_first_node_in_group("player")
    var data := SaveData.new()
    data.score = GameManager.score
    data.high_score = GameManager.high_score
    data.current_wave = GameManager.current_wave
    if player:
        data.player_health = player.health
        data.player_position = player.global_position
    var err := ResourceSaver.save(data, SAVE_RES_PATH)
    if err != OK:
        push_error("ResourceSaver failed: " + str(err))

func load_from_resource() -> SaveData:
    if not ResourceLoader.exists(SAVE_RES_PATH):
        return null
    var data := ResourceLoader.load(SAVE_RES_PATH) as SaveData
    if data == null:
        push_error("Save resource is invalid or incompatible.")
        return null
    return data
```

### Choosing the Right Approach

| Use case | Recommended approach |
|----------|---------------------|
| Audio/video settings | ConfigFile |
| Key remapping | ConfigFile |
| Score, progress, flags | JSON |
| Complex typed save data | Resource serialization |
| Data you want to inspect in a text editor | JSON |
| Data with lots of GDScript types (Vector3, Color, etc.) | Resource serialization |

**Critical:** Always save to `user://` for runtime data. `res://` is read-only in exported builds (the files live inside the exported .pck archive). The `user://` path maps to:
- Windows: `%APPDATA%\Godot\app_userdata\YourGameName\`
- macOS: `~/Library/Application Support/Godot/app_userdata/YourGameName/`
- Linux: `~/.local/share/godot/app_userdata/YourGameName/`

---

## 9. State Machines

State machines are the right tool for any system with distinct modes of behavior: enemy AI, player controllers, game flow, UI screens. Godot gives you several ways to implement them.

### Enum-Based State Machine

The simplest approach. Works well for 3–8 states.

```gdscript
# enemy_ai.gd
extends BaseEnemy

enum EnemyState {
    IDLE,
    PATROL,
    ALERT,   # Heard something, searching
    CHASE,
    ATTACK,
    RETREAT,
    DEAD
}

var current_state: EnemyState = EnemyState.IDLE
var target: Node3D = null
var patrol_points: Array[Marker3D] = []
var current_patrol_index: int = 0

func _physics_process(delta: float) -> void:
    match current_state:
        EnemyState.IDLE:
            _idle_state(delta)
        EnemyState.PATROL:
            _patrol_state(delta)
        EnemyState.ALERT:
            _alert_state(delta)
        EnemyState.CHASE:
            _chase_state(delta)
        EnemyState.ATTACK:
            _attack_state(delta)
        EnemyState.RETREAT:
            _retreat_state(delta)
        EnemyState.DEAD:
            pass  # No physics processing in dead state

func change_state(new_state: EnemyState) -> void:
    _exit_state(current_state)
    current_state = new_state
    _enter_state(new_state)

func _enter_state(state: EnemyState) -> void:
    match state:
        EnemyState.IDLE:
            $AnimationPlayer.play("idle")
        EnemyState.PATROL:
            $AnimationPlayer.play("walk")
        EnemyState.ALERT:
            $AnimationPlayer.play("look_around")
            $AlertTimer.start(3.0)
        EnemyState.CHASE:
            $AnimationPlayer.play("run")
        EnemyState.ATTACK:
            $AnimationPlayer.play("attack")
            $AttackTimer.start(data.attack_cooldown)
        EnemyState.DEAD:
            $AnimationPlayer.play("death")
            $CollisionShape3D.disabled = true
            Events.enemy_killed.emit(global_position, data.score_value)

func _exit_state(state: EnemyState) -> void:
    match state:
        EnemyState.ALERT:
            $AlertTimer.stop()
        EnemyState.ATTACK:
            $AttackTimer.stop()

func _idle_state(_delta: float) -> void:
    if target != null and _can_see_player():
        change_state(EnemyState.CHASE)
    elif patrol_points.size() > 0:
        change_state(EnemyState.PATROL)

func _patrol_state(delta: float) -> void:
    if target != null and _can_see_player():
        change_state(EnemyState.CHASE)
        return
    var patrol_target := patrol_points[current_patrol_index].global_position
    var direction := (patrol_target - global_position)
    if direction.length() < 0.5:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
    else:
        velocity = direction.normalized() * data.move_speed
        move_and_slide()

func _chase_state(_delta: float) -> void:
    if target == null or not _can_see_player():
        change_state(EnemyState.ALERT)
        return
    var dist := global_position.distance_to(target.global_position)
    if dist <= data.attack_range:
        change_state(EnemyState.ATTACK)
        return
    if current_health < data.max_health * 0.2:
        change_state(EnemyState.RETREAT)
        return
    var direction := (target.global_position - global_position).normalized()
    velocity = direction * data.move_speed
    move_and_slide()
    look_at(target.global_position, Vector3.UP)

func _attack_state(_delta: float) -> void:
    if target == null:
        change_state(EnemyState.IDLE)
        return
    var dist := global_position.distance_to(target.global_position)
    if dist > data.attack_range * 1.5:
        change_state(EnemyState.CHASE)

func _can_see_player() -> bool:
    if target == null:
        return false
    # Simple range check — could add raycasting for line-of-sight
    return global_position.distance_to(target.global_position) < 15.0
```

### Node-Based State Machine (Scalable)

For complex AI with many states, each state becomes its own Node with its own script. The state machine manages transitions.

```gdscript
# state_machine.gd
class_name StateMachine
extends Node

@export var initial_state: Node

var current_state: Node = null

func _ready() -> void:
    # Give each state a reference to its owner
    for child in get_children():
        if child.has_method("enter"):
            child.set("state_machine", self)

    if initial_state:
        transition_to(initial_state)

func _process(delta: float) -> void:
    if current_state and current_state.has_method("update"):
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state and current_state.has_method("physics_update"):
        current_state.physics_update(delta)

func transition_to(new_state: Node) -> void:
    if current_state:
        if current_state.has_method("exit"):
            current_state.exit()
    current_state = new_state
    if current_state.has_method("enter"):
        current_state.enter()
```

```gdscript
# states/enemy_chase_state.gd
class_name EnemyChaseState
extends Node

var state_machine: StateMachine

func enter() -> void:
    owner.get_node("AnimationPlayer").play("run")

func physics_update(delta: float) -> void:
    var enemy := owner as BaseEnemy
    if enemy.target == null:
        state_machine.transition_to(state_machine.get_node("IdleState"))
        return
    var dist := enemy.global_position.distance_to(enemy.target.global_position)
    if dist <= enemy.data.attack_range:
        state_machine.transition_to(state_machine.get_node("AttackState"))
        return
    var direction := (enemy.target.global_position - enemy.global_position).normalized()
    enemy.velocity = direction * enemy.data.move_speed
    enemy.move_and_slide()

func exit() -> void:
    pass
```

The node-based approach scales well: adding a new state is adding a new Node child, not editing a growing `match` block. AnimationTree state machines (covered in Module 10) are built on exactly this concept.

---

## 10. Organizing a Real Project

Good file organization prevents the chaos that kills solo projects. Here's a structure that scales from prototype to shippable game.

### Recommended Directory Structure

```
res://
├── autoloads/
│   ├── events.gd
│   ├── game_manager.gd
│   ├── audio_manager.gd
│   └── scene_manager.tscn    # Scene (not script) so it can have child nodes
│
├── scenes/
│   ├── title_screen.tscn
│   ├── gameplay.tscn
│   └── game_over.tscn
│
├── entities/
│   ├── player/
│   │   ├── player.tscn
│   │   ├── player.gd
│   │   └── player_camera.tscn
│   └── enemies/
│       ├── base_enemy.tscn
│       ├── base_enemy.gd
│       ├── goblin.tscn
│       └── skeleton.tscn
│
├── resources/
│   ├── weapons/
│   │   ├── weapon_data.gd    # Resource class definition
│   │   ├── sword.tres
│   │   ├── bow.tres
│   │   └── staff.tres
│   ├── enemies/
│   │   ├── enemy_data.gd
│   │   ├── goblin_data.tres
│   │   ├── skeleton_data.tres
│   │   └── troll_data.tres
│   ├── levels/
│   │   ├── level_data.gd
│   │   ├── level_01.tres
│   │   └── level_02.tres
│   └── items/
│       ├── item_data.gd
│       ├── health_potion.tres
│       └── shield_charm.tres
│
├── ui/
│   ├── hud.tscn
│   ├── hud.gd
│   ├── pause_menu.tscn
│   ├── pause_menu.gd
│   ├── loading_screen.tscn
│   └── components/
│       ├── health_bar.tscn
│       └── wave_indicator.tscn
│
└── assets/
    ├── models/
    │   ├── characters/
    │   └── environment/
    ├── textures/
    │   ├── ui/
    │   └── environment/
    ├── audio/
    │   ├── music/
    │   └── sfx/
    └── fonts/
```

### Naming Conventions

- **Files and directories:** `snake_case` — `player.gd`, `base_enemy.tscn`, `goblin_data.tres`
- **Class names:** `PascalCase` — `class_name EnemyData`, `class_name BaseEnemy`
- **Script variables and functions:** `snake_case` — `current_health`, `take_damage()`
- **Constants:** `UPPER_SNAKE_CASE` — `const MAX_ENEMIES := 20`
- **Enums and enum values:** `PascalCase` for type, `ALL_CAPS` for values — `enum GameState { PLAYING, PAUSED }`
- **Signals:** `snake_case`, named as past events — `health_changed`, `enemy_died`, `wave_completed`
- **Private-by-convention:** prefix with `_` — `_calculate_path()`, `_cached_target`

### Scene Organization Rules

- Every scene has a clear single responsibility
- Scenes communicate via signals (upward to parent) or via the signal bus (global)
- Scenes never directly modify their siblings or parents
- Data lives in Resources; scenes read from Resources

---

## 11. Code Walkthrough: Arena Game

Now put everything together. Here's a complete mini-project: a wave-based arena game with a title screen, gameplay, pause menu, and game over screen — all wired together with signals and autoloads.

### Project Structure

```
res://
├── autoloads/
│   ├── events.gd
│   └── game_manager.gd
├── scenes/
│   ├── title_screen.tscn
│   ├── gameplay.tscn
│   └── game_over.tscn
├── entities/
│   ├── player/
│   │   ├── player.tscn
│   │   └── player.gd
│   └── enemies/
│       ├── base_enemy.tscn
│       └── base_enemy.gd
├── resources/
│   └── enemies/
│       ├── enemy_data.gd
│       ├── goblin_data.tres
│       └── skeleton_data.tres
├── spawner/
│   ├── wave_spawner.tscn
│   └── wave_spawner.gd
└── ui/
    ├── hud.tscn
    ├── hud.gd
    ├── pause_menu.tscn
    ├── pause_menu.gd
    ├── game_over_screen.tscn
    └── game_over_screen.gd
```

### events.gd

```gdscript
# autoloads/events.gd
# Global signal bus. Register as autoload named "Events".
extends Node

# Player
signal player_damaged(amount: int)
signal player_healed(amount: int)
signal player_died
signal player_health_changed(new_health: int, max_health: int)

# Enemies
signal enemy_killed(enemy_position: Vector3, score_value: int)

# Scoring
signal score_changed(new_score: int)
signal high_score_beaten(new_score: int)

# Waves
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

# Game state
signal game_state_changed(new_state: int)
```

### game_manager.gd

```gdscript
# autoloads/game_manager.gd
# Register as autoload named "GameManager".
extends Node

enum GameState {
    TITLE,
    PLAYING,
    PAUSED,
    GAME_OVER
}

var current_state: GameState = GameState.TITLE
var score: int = 0
var high_score: int = 0
var current_wave: int = 0
var enemies_alive: int = 0

const SAVE_PATH := "user://arena_save.cfg"

func _ready() -> void:
    _load_high_score()
    Events.enemy_killed.connect(_on_enemy_killed)
    Events.player_died.connect(_on_player_died)

func change_state(new_state: GameState) -> void:
    current_state = new_state
    Events.game_state_changed.emit(new_state)
    match new_state:
        GameState.PAUSED:
            get_tree().paused = true
        GameState.PLAYING:
            get_tree().paused = false
        GameState.GAME_OVER:
            get_tree().paused = false
            if score > high_score:
                high_score = score
                _save_high_score()
                Events.high_score_beaten.emit(high_score)
        GameState.TITLE:
            get_tree().paused = false

func add_score(amount: int) -> void:
    score += amount
    Events.score_changed.emit(score)

func start_game() -> void:
    score = 0
    current_wave = 0
    enemies_alive = 0
    change_state(GameState.PLAYING)

func _on_enemy_killed(_pos: Vector3, score_value: int) -> void:
    add_score(score_value)
    enemies_alive = maxi(enemies_alive - 1, 0)

func _on_player_died() -> void:
    change_state(GameState.GAME_OVER)

func _save_high_score() -> void:
    var config := ConfigFile.new()
    config.set_value("game", "high_score", high_score)
    config.save(SAVE_PATH)

func _load_high_score() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) == OK:
        high_score = config.get_value("game", "high_score", 0)
```

### enemy_data.gd

```gdscript
# resources/enemies/enemy_data.gd
class_name EnemyData
extends Resource

@export var display_name: String = "Enemy"
@export var max_health: int = 30
@export var move_speed: float = 3.0
@export var damage: int = 10
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.5
@export var score_value: int = 100

# Color used as material albedo (quick visual differentiation in prototype)
@export var body_color: Color = Color.RED
```

Create `goblin_data.tres` — `EnemyData` with `max_health: 20`, `move_speed: 4.0`, `damage: 8`, `score_value: 50`, `body_color: green`. Create `skeleton_data.tres` — `EnemyData` with `max_health: 40`, `move_speed: 2.5`, `damage: 15`, `score_value: 150`, `body_color: white`.

### base_enemy.gd

```gdscript
# entities/enemies/base_enemy.gd
class_name BaseEnemy
extends CharacterBody3D

@export var data: EnemyData

var current_health: int
var target: Node3D = null
var attack_timer: float = 0.0

const GRAVITY := -9.8

func _ready() -> void:
    add_to_group("enemies")
    if data == null:
        push_error(name + " has no EnemyData assigned!")
        queue_free()
        return
    current_health = data.max_health
    # Apply color to mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = data.body_color
    $MeshInstance3D.set_surface_override_material(0, mat)
    # Find player
    target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    if target == null:
        target = get_tree().get_first_node_in_group("player")
        move_and_slide()
        return

    var dist := global_position.distance_to(target.global_position)

    if dist <= data.attack_range:
        velocity.x = 0.0
        velocity.z = 0.0
        _try_attack(delta)
    else:
        _move_toward_target()

    move_and_slide()

func _move_toward_target() -> void:
    var direction := (target.global_position - global_position)
    direction.y = 0.0
    direction = direction.normalized()
    velocity.x = direction.x * data.move_speed
    velocity.z = direction.z * data.move_speed
    if direction.length() > 0.1:
        look_at(target.global_position, Vector3.UP)

func _try_attack(delta: float) -> void:
    attack_timer -= delta
    if attack_timer <= 0.0:
        attack_timer = data.attack_cooldown
        _do_attack()

func _do_attack() -> void:
    Events.player_damaged.emit(data.damage)

func take_damage(amount: int) -> void:
    current_health -= amount
    if current_health <= 0:
        die()

func die() -> void:
    Events.enemy_killed.emit(global_position, data.score_value)
    queue_free()
```

### player.gd

```gdscript
# entities/player/player.gd
extends CharacterBody3D

@export var max_health: int = 100
@export var move_speed: float = 5.0
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.4

var health: int
var attack_timer: float = 0.0
var is_dead: bool = false

const GRAVITY := -9.8
const MOUSE_SENSITIVITY := 0.003

@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var attack_area: Area3D = $AttackArea

func _ready() -> void:
    add_to_group("player")
    health = max_health
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    Events.player_damaged.connect(_on_player_damaged)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and not get_tree().paused:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        $CameraPivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        $CameraPivot.rotation.x = clampf($CameraPivot.rotation.x, -PI / 2.5, PI / 4)

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    if not is_on_floor():
        velocity.y += GRAVITY * delta

    attack_timer -= delta

    var input_dir := Vector2(
        Input.get_axis("move_left", "move_right"),
        Input.get_axis("move_forward", "move_back")
    )
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed

    if Input.is_action_just_pressed("attack") and attack_timer <= 0.0:
        _attack()

    move_and_slide()

func _attack() -> void:
    attack_timer = attack_cooldown
    var hit_bodies := attack_area.get_overlapping_bodies()
    for body in hit_bodies:
        if body.is_in_group("enemies"):
            body.take_damage(attack_damage)

func _on_player_damaged(amount: int) -> void:
    if is_dead:
        return
    health = clampi(health - amount, 0, max_health)
    Events.player_health_changed.emit(health, max_health)
    if health <= 0:
        _die()

func heal(amount: int) -> void:
    health = clampi(health + amount, 0, max_health)
    Events.player_health_changed.emit(health, max_health)
    Events.player_healed.emit(amount)

func _die() -> void:
    is_dead = true
    Events.player_died.emit()
    # Disable collision and input
    $CollisionShape3D.set_deferred("disabled", true)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
```

**Player scene structure:**
```
Player (CharacterBody3D)
├── MeshInstance3D (capsule mesh)
├── CollisionShape3D (capsule shape)
├── CameraPivot (Node3D)
│   └── Camera3D
└── AttackArea (Area3D)
    └── CollisionShape3D (small sphere, forward of player)
```

### wave_spawner.gd

```gdscript
# spawner/wave_spawner.gd
extends Node3D

@export var enemy_scene: PackedScene
@export var enemy_types: Array[EnemyData] = []
@export var spawn_radius: float = 15.0
@export var total_waves: int = 5
@export var base_enemies_per_wave: int = 3
@export var enemies_increase_per_wave: int = 2

var current_wave: int = 0
var enemies_remaining: int = 0
var spawning_active: bool = false

func _ready() -> void:
    Events.enemy_killed.connect(_on_enemy_killed)
    # Start the first wave after a short delay
    await get_tree().create_timer(2.0).timeout
    _start_next_wave()

func _start_next_wave() -> void:
    current_wave += 1
    GameManager.current_wave = current_wave

    if current_wave > total_waves:
        Events.all_waves_completed.emit()
        return

    var count := base_enemies_per_wave + (current_wave - 1) * enemies_increase_per_wave
    enemies_remaining = count
    Events.wave_started.emit(current_wave)

    spawning_active = true
    for i in count:
        await get_tree().create_timer(0.8).timeout
        if not spawning_active:
            break
        _spawn_enemy()

func _spawn_enemy() -> void:
    if enemy_scene == null or enemy_types.is_empty():
        return

    # Random point on circle edge
    var angle := randf() * TAU
    var spawn_offset := Vector3(cos(angle), 0, sin(angle)) * spawn_radius
    var spawn_pos := global_position + spawn_offset

    var enemy := enemy_scene.instantiate() as BaseEnemy
    get_tree().current_scene.add_child(enemy)
    enemy.global_position = spawn_pos

    # Assign random enemy type from the list
    enemy.data = enemy_types[randi() % enemy_types.size()].duplicate()

    Events.enemy_spawned.emit(enemy)

func _on_enemy_killed(_pos: Vector3, _score: int) -> void:
    enemies_remaining -= 1
    if enemies_remaining <= 0 and spawning_active:
        spawning_active = false
        Events.wave_completed.emit(current_wave)
        await get_tree().create_timer(3.0).timeout
        _start_next_wave()

func stop_spawning() -> void:
    spawning_active = false
```

### hud.gd

```gdscript
# ui/hud.gd
extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBox/HealthBar
@onready var health_label: Label = $MarginContainer/VBox/HealthLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var wave_banner: Label = $WaveBanner  # Centered, fades in/out
@onready var banner_tween: Tween = null

func _ready() -> void:
    Events.player_health_changed.connect(_on_player_health_changed)
    Events.score_changed.connect(_on_score_changed)
    Events.wave_started.connect(_on_wave_started)
    Events.wave_completed.connect(_on_wave_completed)
    Events.all_waves_completed.connect(_on_all_waves_completed)
    # Initialize with starting values
    _on_player_health_changed(100, 100)
    _on_score_changed(0)
    wave_label.text = "Wave: --"
    wave_banner.modulate.a = 0.0

func _on_player_health_changed(new_health: int, max_health: int) -> void:
    health_bar.max_value = max_health
    health_bar.value = new_health
    health_label.text = "%d / %d" % [new_health, max_health]
    # Flash red when low
    if float(new_health) / float(max_health) < 0.3:
        health_bar.modulate = Color.RED
    else:
        health_bar.modulate = Color.WHITE

func _on_score_changed(new_score: int) -> void:
    score_label.text = "Score: %d" % new_score

func _on_wave_started(wave_number: int) -> void:
    wave_label.text = "Wave: %d" % wave_number
    _show_banner("Wave %d" % wave_number)

func _on_wave_completed(wave_number: int) -> void:
    _show_banner("Wave %d Complete!" % wave_number)

func _on_all_waves_completed() -> void:
    _show_banner("All Waves Complete!")

func _show_banner(text: String) -> void:
    wave_banner.text = text
    if banner_tween:
        banner_tween.kill()
    banner_tween = create_tween()
    banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.3)
    banner_tween.tween_interval(2.0)
    banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.5)
```

### pause_menu.gd

```gdscript
# ui/pause_menu.gd
extends CanvasLayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    Events.game_state_changed.connect(_on_game_state_changed)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if GameManager.current_state == GameManager.GameState.PLAYING:
            GameManager.change_state(GameManager.GameState.PAUSED)
        elif GameManager.current_state == GameManager.GameState.PAUSED:
            GameManager.change_state(GameManager.GameState.PLAYING)

func _on_game_state_changed(new_state: int) -> void:
    match new_state:
        GameManager.GameState.PAUSED:
            visible = true
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        GameManager.GameState.PLAYING:
            visible = false
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
    GameManager.change_state(GameManager.GameState.PLAYING)

func _on_quit_to_menu_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_quit_game_pressed() -> void:
    get_tree().quit()
```

### game_over_screen.gd

```gdscript
# ui/game_over_screen.gd
extends CanvasLayer

@onready var score_label: Label = $VBox/ScoreLabel
@onready var high_score_label: Label = $VBox/HighScoreLabel
@onready var new_record_label: Label = $VBox/NewRecordLabel

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    Events.game_state_changed.connect(_on_game_state_changed)
    Events.high_score_beaten.connect(_on_high_score_beaten)

func _on_game_state_changed(new_state: int) -> void:
    if new_state == GameManager.GameState.GAME_OVER:
        _show_game_over()

func _show_game_over() -> void:
    score_label.text = "Score: %d" % GameManager.score
    high_score_label.text = "Best: %d" % GameManager.high_score
    new_record_label.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    visible = true

func _on_high_score_beaten(new_score: int) -> void:
    new_record_label.visible = true
    new_record_label.text = "New Record: %d!" % new_score

func _on_play_again_pressed() -> void:
    visible = false
    get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _on_quit_to_menu_pressed() -> void:
    visible = false
    get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
```

### title_screen.gd

```gdscript
# scenes/title_screen.gd (attached to title_screen.tscn root)
extends Control

@onready var high_score_label: Label = $VBox/HighScoreLabel
@onready var start_button: Button = $VBox/StartButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
    high_score_label.text = "Best Score: %d" % GameManager.high_score
    start_button.pressed.connect(_on_start_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_start_pressed() -> void:
    GameManager.start_game()
    get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
```

### Gameplay Scene Setup

The `gameplay.tscn` root is a `Node3D`. Its children:

```
Gameplay (Node3D)
├── WorldEnvironment
├── DirectionalLight3D
├── ArenaFloor (StaticBody3D)
│   ├── MeshInstance3D (large plane)
│   └── CollisionShape3D
├── Player (instantiated from player.tscn)
├── WaveSpawner (instantiated from wave_spawner.tscn)
├── HUD (instantiated from hud.tscn)
├── PauseMenu (instantiated from pause_menu.tscn)
└── GameOverScreen (instantiated from game_over_screen.tscn)
```

The `gameplay.gd` script is minimal — the heavy lifting is in autoloads and individual scene scripts:

```gdscript
# scenes/gameplay.gd
extends Node3D

func _ready() -> void:
    # Ensure we're in PLAYING state (start_game() was called from title screen)
    if GameManager.current_state != GameManager.GameState.PLAYING:
        GameManager.start_game()
```

### Signal Flow Diagram

Here's how signals flow through the arena game:

```
Player takes damage
  → Events.player_damaged (emitted by base_enemy._do_attack)
      → Player._on_player_damaged()
          → decrements health
          → Events.player_health_changed (emitted by player)
              → HUD._on_player_health_changed() → updates health bar
          → if dead: Events.player_died (emitted by player)
              → GameManager._on_player_died()
                  → change_state(GAME_OVER)
                  → Events.game_state_changed (emitted by GameManager)
                      → PauseMenu._on_game_state_changed()
                      → GameOverScreen._on_game_state_changed() → shows screen

Enemy dies
  → Events.enemy_killed (emitted by base_enemy.die)
      → GameManager._on_enemy_killed() → adds score
          → Events.score_changed (emitted by GameManager)
              → HUD._on_score_changed() → updates score label
      → WaveSpawner._on_enemy_killed() → decrements counter
          → if 0: Events.wave_completed (emitted by wave_spawner)
              → HUD._on_wave_completed() → shows banner
              → (after timer) starts next wave
                  → Events.wave_started
                      → HUD._on_wave_started() → updates wave label
```

No node in this system holds a reference to another unrelated node. The player doesn't know about the HUD. The HUD doesn't know about the enemies. Everything communicates through the signal bus.

---

## API Quick Reference

### Signal Methods

| Method | Description |
|--------|-------------|
| `signal_name.emit(args...)` | Fire the signal with arguments |
| `signal_name.connect(callable)` | Connect a function to this signal |
| `signal_name.connect(callable, flags)` | Connect with flags |
| `signal_name.disconnect(callable)` | Remove a specific connection |
| `signal_name.is_connected(callable)` | Check if connected |
| `signal_name.get_connections()` | Returns Array of connection Dictionaries |

### Resource Methods

| Method | Description |
|--------|-------------|
| `resource.duplicate()` | Shallow copy |
| `resource.duplicate(true)` | Deep copy (duplicates sub-resources too) |
| `ResourceSaver.save(resource, path)` | Save to .tres/.res file |
| `ResourceLoader.load(path)` | Load from file (blocking) |
| `ResourceLoader.exists(path)` | Check if file exists |
| `ResourceLoader.load_threaded_request(path)` | Start background load |
| `ResourceLoader.load_threaded_get_status(path)` | Poll loading progress |
| `ResourceLoader.load_threaded_get(path)` | Get loaded resource |

### ConfigFile Methods

| Method | Description |
|--------|-------------|
| `config.set_value(section, key, value)` | Write a value |
| `config.get_value(section, key, default)` | Read a value with fallback |
| `config.has_section(section)` | Check if section exists |
| `config.has_section_key(section, key)` | Check if key exists |
| `config.save(path)` | Write to disk |
| `config.load(path)` | Read from disk |
| `config.erase_section(section)` | Delete entire section |

### FileAccess Methods

| Method | Description |
|--------|-------------|
| `FileAccess.open(path, mode)` | Open file (READ or WRITE) |
| `FileAccess.file_exists(path)` | Check existence before opening |
| `file.store_string(text)` | Write text |
| `file.get_as_text()` | Read entire file as string |
| `file.close()` | Close file (call after done) |
| `FileAccess.get_open_error()` | Get last open error code |

### SceneTree Methods

| Method | Description |
|--------|-------------|
| `get_tree().change_scene_to_file(path)` | Switch scene by path |
| `get_tree().change_scene_to_packed(packed)` | Switch to preloaded scene |
| `get_tree().reload_current_scene()` | Restart current scene |
| `get_tree().paused` | Get/set pause state |
| `get_tree().quit()` | Exit game |
| `get_tree().get_first_node_in_group(name)` | Find first node in group |
| `get_tree().get_nodes_in_group(name)` | Get all nodes in group |

### Node.process_mode Values

| Constant | Behavior |
|----------|----------|
| `PROCESS_MODE_INHERIT` | Use parent's mode (default) |
| `PROCESS_MODE_PAUSABLE` | Stops when tree is paused |
| `PROCESS_MODE_WHEN_PAUSED` | Only runs when tree IS paused |
| `PROCESS_MODE_ALWAYS` | Runs regardless of pause |
| `PROCESS_MODE_DISABLED` | Never calls _process/_physics_process |

### JSON Methods

| Method | Description |
|--------|-------------|
| `JSON.stringify(data)` | Convert Variant to JSON string |
| `JSON.stringify(data, "\t")` | Pretty-print with tab indentation |
| `JSON.parse_string(text)` | Parse JSON string, returns Variant (null on error) |

### ResourceLoader Threading

| Constant | Meaning |
|----------|---------|
| `THREAD_LOAD_INVALID_RESOURCE` | Path doesn't exist or is wrong type |
| `THREAD_LOAD_IN_PROGRESS` | Still loading |
| `THREAD_LOAD_FAILED` | Load failed |
| `THREAD_LOAD_LOADED` | Ready to retrieve |

---

## Common Pitfalls

### 1. Direct Node References Across Unrelated Scenes

**WRONG:**
```gdscript
# enemy.gd — tight coupling to specific scene structure
func _on_died() -> void:
    get_tree().get_root().get_node("Gameplay/HUD").add_score(100)
    get_tree().get_root().get_node("Gameplay/GameManager").enemy_died()
```
This breaks the moment you rename any node, reorganize the scene, or run the enemy in a different scene. It also creates direct dependencies between unrelated systems.

**RIGHT:**
```gdscript
# enemy.gd — zero knowledge of outside world
func die() -> void:
    Events.enemy_killed.emit(global_position, data.score_value)
    queue_free()
```
The enemy emits a signal and forgets. The HUD, GameManager, and WaveSpawner each subscribe to `Events.enemy_killed` and respond independently.

---

### 2. Storing All Game Data in Autoload Variables

**WRONG:**
```gdscript
# game_manager.gd — cluttered with ad-hoc data
var score: int = 0
var player_health: int = 100
var player_max_health: int = 100
var current_weapon_name: String = ""
var current_weapon_damage: float = 0.0
var current_weapon_range: float = 0.0
var inventory_slot_0: String = ""
var inventory_slot_1: String = ""
# ... 50 more flat variables
```
This becomes unmaintainable fast. You can't serialize it cleanly. You can't pass it around as a unit.

**RIGHT:**
```gdscript
# player_data.gd
class_name PlayerData
extends Resource
@export var health: int = 100
@export var max_health: int = 100
@export var equipped_weapon: WeaponData
@export var inventory: Array[ItemData] = []

# game_manager.gd
var player_data: PlayerData = PlayerData.new()
# Pass the whole resource around, serialize it with ResourceSaver
```

---

### 3. Forgetting process_mode on Pause Menu

**WRONG:**
```gdscript
# pause_menu.gd — missing process_mode setup
extends CanvasLayer

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        toggle_pause()  # This never fires when paused!
```
When `get_tree().paused = true`, the pause menu itself pauses. The `_unhandled_input` callback stops firing. The player can never unpause.

**RIGHT:**
```gdscript
# pause_menu.gd
extends CanvasLayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS  # Runs even when paused
```
Set this in `_ready()` or in the Inspector on the root node of your pause menu scene. Every node that must function during pause needs this — including any AnimationPlayer or Timer inside the pause menu.

---

### 4. Calling change_scene During Physics Processing

**WRONG:**
```gdscript
# player.gd
func _physics_process(delta: float) -> void:
    if health <= 0:
        get_tree().change_scene_to_file("res://scenes/game_over.tscn")
        # Crash or error: modifying scene tree during physics step
```
`_physics_process` runs in the physics thread. Modifying the scene tree (adding, removing nodes, or changing the active scene) from within it is unsafe and will cause errors or crashes.

**RIGHT:**
```gdscript
# player.gd
func _physics_process(delta: float) -> void:
    if health <= 0 and not is_dead:
        is_dead = true
        Events.player_died.emit()  # Signal is handled at idle time

# game_manager.gd — handling the signal safely at idle time
func _on_player_died() -> void:
    change_state(GameState.GAME_OVER)
    # Or if you must change scene directly:
    call_deferred("_change_to_game_over")

func _change_to_game_over() -> void:
    get_tree().change_scene_to_file("res://scenes/game_over.tscn")
```

---

### 5. Saving to res:// in Exported Builds

**WRONG:**
```gdscript
func save_game() -> void:
    var file := FileAccess.open("res://save.json", FileAccess.WRITE)
    # Works in editor. Silently fails in exported builds.
```
`res://` is packed into a `.pck` archive in exported games. It's read-only. `FileAccess.open` returns `null` and `FileAccess.get_open_error()` returns a file system error — silently eating your save data.

**RIGHT:**
```gdscript
func save_game() -> void:
    var file := FileAccess.open("user://save.json", FileAccess.WRITE)
    if file == null:
        push_error("Save failed: " + str(FileAccess.get_open_error()))
        return
    file.store_string(JSON.stringify(data))
    file.close()
```
`user://` is always writable on every platform. Always check for `null` after `FileAccess.open`.

---

### 6. Making Everything an Autoload

**WRONG:**
```gdscript
# Every system is an autoload
# Project Settings > Autoload:
# GameManager, Events, AudioManager, SceneManager,
# PlayerStats, EnemyManager, InventoryManager,
# DialogueManager, QuestManager, CraftingManager,
# WeatherManager, TimeOfDayManager, FactionManager...
```
This turns your game into a tangle of global state. Every system can see every other system. You lose the benefits of encapsulation. It also increases memory usage and makes testing harder.

**RIGHT:**
```gdscript
# Only systems that truly need to persist across scenes are autoloads:
# - Events (signal bus, always needed)
# - GameManager (score, state, save — must survive scene changes)
# - AudioManager (music continuity across scenes)
# - SceneManager (transitions, always alive)

# Everything else lives in the scene that uses it:
# InventoryManager lives in the GameplayScene
# QuestManager lives in the WorldScene
# DialogueManager lives in scenes that have dialogue
```
If a system is only needed in one scene, make it a node in that scene. Autoloads are for systems that genuinely need to outlive any single scene.

---

## Exercises

### Exercise 1: Settings System (30–45 minutes)

Add a settings screen that saves to ConfigFile.

Requirements:
- A settings scene with three `HSlider` nodes: Master Volume, Music Volume, SFX Volume
- A fullscreen toggle CheckBox
- Apply changes immediately as sliders move
- Save to `user://settings.cfg` when the player closes the settings screen
- Load and apply settings on startup in the AudioManager autoload
- Add a "Settings" button to the title screen that opens the settings scene

Steps to implement:
1. Create `ui/settings_screen.tscn` with sliders and checkbox
2. In `settings_screen.gd`, connect each slider's `value_changed` signal to call `AudioManager.set_master_volume()` etc.
3. In `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` or a "Back" button callback, call `AudioManager.save_volume_settings()`
4. In `AudioManager._ready()`, call `load_volume_settings()`
5. Test: change volume, quit, relaunch — settings persist

### Exercise 2: Inventory System (45–60 minutes)

Add items to the arena that the player can pick up, tracked with custom Resources.

Requirements:
- `ItemData` resource: name, icon (Texture2D), effect_type (enum: HEAL, SPEED_BOOST), effect_value
- `InventoryData` resource: `Array[ItemData]` with max capacity
- Pickup nodes (Area3D) scattered in the arena, each with an `ItemData` resource assigned
- When the player enters a pickup's area, add it to the inventory
- HUD shows current inventory (icons only, up to 4 slots)
- Press a number key (1, 2, 3, 4) to use the item in that slot

Steps to implement:
1. Create `item_data.gd` and two example items: `health_potion.tres` (HEAL, 30) and `speed_charm.tres` (SPEED_BOOST, 2.0)
2. Create `pickup.tscn` (Area3D + MeshInstance3D + CollisionShape3D) with `@export var item: ItemData`
3. In `pickup.gd`, connect `body_entered` — when the player enters, emit `Events.item_picked_up(item)` and queue_free
4. Add an `inventory: InventoryData` to the player, connect to `Events.item_picked_up`
5. Add an inventory display to the HUD — 4 TextureRect nodes that update when `Events.item_picked_up` fires
6. In `player.gd`, handle keys 1–4 to use inventory items

### Exercise 3: Level Progression (60–90 minutes)

Add multiple arena levels using LevelData resources, with scene transitions and save progress.

Requirements:
- `LevelData` resource: level_name, wave_count, enemy_types (Array[EnemyData]), background_music, next_level (LevelData)
- Two levels: `level_01.tres` (3 waves, goblins only), `level_02.tres` (5 waves, goblins and skeletons)
- After all waves complete in a level, transition to the next level via SceneManager with a fade
- Show a "Level Complete" banner before transitioning
- Save progress (current level index, high score) to ConfigFile
- Load on startup and offer "Continue" on the title screen if save exists

Steps to implement:
1. Create `level_data.gd`, `level_01.tres`, `level_02.tres`
2. Modify `WaveSpawner` to accept a `LevelData` and configure itself from it
3. Connect `Events.all_waves_completed` in the gameplay scene to show a level complete banner and call `SceneManager.change_scene` after a delay
4. In `GameManager`, track `current_level_index` and save/load it with ConfigFile
5. On the title screen, check if a save exists — show "Continue" button if so
6. On continue, load the saved level index and start the appropriate level

---

## Key Takeaways

1. **Signals decouple everything.** Emit events, let listeners respond. The emitter never knows who's listening. This is the fundamental pattern that keeps large codebases manageable.

2. **A signal bus (Events autoload) is the backbone of game-wide communication.** Any node can emit, any node can listen. Zero coupling between emitter and listener. This replaces fragile `get_node()` chains across scene boundaries.

3. **Custom Resources turn game data into editable files.** Designers create new enemies, weapons, and levels by creating `.tres` files in the FileSystem — no code changes required. The script stays the same; the data changes.

4. **Autoloads persist across scene changes. Use them for managers, not for everything.** GameManager, AudioManager, SceneManager, Events — these genuinely need to survive transitions. Most other systems should live in the scene that uses them.

5. **`get_tree().paused` + `process_mode` gives you a complete pause system in minutes.** Set `PROCESS_MODE_ALWAYS` on any node that must function during pause. Set `PROCESS_MODE_WHEN_PAUSED` on nodes that should only run during pause. The rest works automatically.

6. **Save to `user://` with the right format for the job.** ConfigFile for settings and simple key-value persistence. JSON for readable game state. Resource serialization for complex typed data that benefits from GDScript's type system.

7. **State machines (enum + match) scale from simple enemy AI to entire game flow.** An enum defines your states, a `change_state()` function handles enter/exit logic, and `_physics_process` dispatches to per-state functions. For complex AI, promote each state to its own Node.

---

## What's Next

Architecture is in place. Your game has structure, communication through signals, data-driven content through Resources, persistent state through autoloads, and a save system. The scaffolding is solid.

Now the fun part — **[Module 6: Custom Shaders & Stylized Rendering](module-06-shaders-stylized-rendering.md)**. You'll write your first vertex and fragment shaders in Godot's shader language, build stylized visual effects (cel shading, outlines, screen-space distortion), animate materials procedurally, and make a game that looks like it has a distinct visual identity rather than stock gray boxes. Architecture is in place. Now make it look like something.

---

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
