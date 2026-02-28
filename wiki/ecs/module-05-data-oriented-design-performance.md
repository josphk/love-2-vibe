# Module 5: Data-Oriented Design & Performance

**Part of:** [ECS Learning Roadmap](ecs-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** [Module 2: Querying and Iteration](module-02-querying-and-iteration.md) (Module 4 helpful but not required)

---

## Overview

Most game performance advice focuses on algorithms: use a spatial hash instead of brute-force collision, cull offscreen entities, batch your draw calls. That advice is correct but incomplete. Even with optimal algorithms, you can still run slowly if your data is laid out wrong in memory. Data-oriented design is the discipline of arranging data so the CPU can consume it as fast as physically possible, and ECS architecture happens to be one of the cleanest ways to enforce it.

This module covers the hardware realities that make data layout matter. You will learn why pointer-chasing through object graphs is slow at a physical level, what Array of Structs versus Struct of Arrays actually means for cache behavior, and why archetype-based ECS implementations are fast by construction rather than by luck. The numbers in this module are approximations, but they are grounded in real hardware behavior. Memorize the order of magnitude, not the exact figures.

The punchline, spoiled up front: the architecture that makes your code cleanest (separate components, iterated by type) is also the architecture that makes your CPU happiest. You are not trading readability for performance. In ECS, you get both.

---

## 1. Cache Lines: The Hardware Reality

Your CPU runs at 3-5 GHz. Your RAM runs at a much slower effective speed. The cache hierarchy exists to bridge that gap, and your data layout determines whether the bridge holds or collapses under you.

**The rule:** when the CPU loads any byte from RAM, it loads the entire 64-byte aligned chunk of memory containing that byte. That chunk is called a cache line. If the next byte you need is in that same 64-byte chunk — cache hit. Essentially free. If it is somewhere else in memory — cache miss. The CPU stalls and waits.

**Latency numbers to burn into your memory:**

| Level     | Approx. latency | Approx. cycles |
|-----------|-----------------|----------------|
| L1 cache  | ~1 ns           | ~4 cycles      |
| L2 cache  | ~4 ns           | ~12 cycles     |
| L3 cache  | ~40 ns          | ~120 cycles    |
| RAM       | ~100 ns         | ~300–400 cycles|

A single RAM access costs 300+ CPU cycles. During those cycles, your CPU is doing nothing useful. It is just waiting.

**The practical implication:** you have 10,000 game entities. Each entity is a table (Lua) or object (GDScript) allocated independently on the heap. Their memory addresses are scattered. When your movement system loops over them, each one is potentially a cache miss. 10,000 misses × 300 cycles each = 3 million wasted cycles per frame. At 60 fps, that is 180 million wasted cycles per second. Before a single float add. Before any physics. Before any game logic. Just from the cost of fetching the data.

Cache misses are the performance tax you pay for pointer-chasing through object graphs. OOP games pay this tax constantly. Every `entity.getComponent(Position)` that walks a hash map or follows a pointer is potentially a cache miss. The game feels slow and profilers show high "memory" time rather than "compute" time, which makes the problem harder to diagnose.

The CPU prefetcher partially saves you. If your access pattern is predictable — sequential array reads, stride of N bytes — the prefetcher detects the pattern and fetches the next cache line before you ask for it. Sequential iteration over a flat array triggers the prefetcher reliably. Random pointer chasing does not. Your data layout is a communication protocol with the prefetcher.

**Pseudocode:**
```
// Cache miss scenario: scattered objects
entities = [ ptr_to_entity_A, ptr_to_entity_B, ptr_to_entity_C, ... ]
for each ptr in entities:
    data = dereference(ptr)   // potential cache miss: could be anywhere in RAM
    update(data)
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Each table is a separate heap allocation — scattered memory
local entities = {}
for i = 1, 10000 do
    entities[i] = { x = math.random(800), y = math.random(600),
                    vx = 1.0, vy = 0.5, hp = 100, sprite = "player.png" }
end

-- This loop chases 10,000 pointers — up to 10,000 cache misses
local function update_scattered(dt)
    for i = 1, #entities do
        local e = entities[i]  -- dereference: potential miss
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
    end
end
```

**GDScript (Godot):**
```gdscript
# Array of Node references — each Node lives at a separate heap address
var entities: Array[Node2D] = []

func update_scattered(dt: float) -> void:
    for entity in entities:
        # Each 'entity' access follows a pointer — potential cache miss
        entity.position.x += entity.velocity.x * dt
        entity.position.y += entity.velocity.y * dt
```

---

## 2. Array of Structs vs. Struct of Arrays

This is the core layout decision. The choice compounds across every system in your game.

**AoS (Array of Structs):** the natural OOP layout. One struct per entity, all structs in one array.

```
entities[0] = { x=1, y=2, vx=3, vy=4, hp=100, sprite="a.png" }
entities[1] = { x=6, y=7, vx=8, vy=9, hp=100, sprite="b.png" }
entities[2] = { x=11, y=12, vx=13, vy=14, hp=75, sprite="c.png" }
```

When MovementSystem processes `entities[0]`, the CPU loads a cache line covering the entire struct: x, y, vx, vy, hp, sprite. It uses x, y, vx, vy. The hp and sprite bytes ride along for free — but they occupy cache space and push out other data you might actually need. Then it moves to `entities[1]`. In a real Lua or GDScript program, that is a separate heap allocation at a different address. Cache miss.

**SoA (Struct of Arrays):** data separated by type into flat arrays.

```
pos_x     = [ 1,  6, 11, 16, ... ]
pos_y     = [ 2,  7, 12, 17, ... ]
vel_x     = [ 3,  8, 13, 18, ... ]
vel_y     = [ 4,  9, 14, 19, ... ]
health    = [ 100, 100, 75, 50, ... ]
```

MovementSystem reads `pos_x[0..15]`, `pos_y[0..15]`, `vel_x[0..15]`, `vel_y[0..15]`. Sequential. A 64-byte cache line holds 16 single-precision floats (64 bytes / 4 bytes each). You process 16 entities per cache miss instead of one. The prefetcher sees a stride of 4 bytes and happily fetches ahead. Cache efficiency goes from worst-case to near-optimal.

The hp and sprite data are in completely separate arrays. MovementSystem never touches them. They never pollute the movement-system cache lines. The systems only pay for the data they actually use.

**Pseudocode:**
```
// AoS update — touches all fields per entity, even unused ones
for i in 0..N:
    entities[i].x += entities[i].vx * dt   // loads whole struct into cache
    entities[i].y += entities[i].vy * dt

// SoA update — only touches position and velocity arrays
for i in 0..N:
    pos_x[i] += vel_x[i] * dt   // sequential reads, prefetcher loves this
    pos_y[i] += vel_y[i] * dt
```

**Lua (tiny-ecs / Love2D):**
```lua
-- AoS: array of tables (the default Lua approach)
local entities_aos = {}
for i = 1, 10000 do
    entities_aos[i] = {
        x  = math.random(800), y  = math.random(600),
        vx = 1.0,              vy = 0.5,
        hp = 100, sprite = "player.png"   -- cold data mixed in
    }
end

local function move_aos(dt)
    for i = 1, #entities_aos do
        local e = entities_aos[i]
        e.x = e.x + e.vx * dt   -- loads hp and sprite into cache too (wasted)
        e.y = e.y + e.vy * dt
    end
end

-- SoA: separate arrays per field
local N = 10000
local pos_x = {}; local pos_y = {}
local vel_x = {}; local vel_y = {}
for i = 1, N do
    pos_x[i] = math.random(800); pos_y[i] = math.random(600)
    vel_x[i] = 1.0;              vel_y[i] = 0.5
end

local function move_soa(dt)
    for i = 1, N do
        pos_x[i] = pos_x[i] + vel_x[i] * dt   -- only position and velocity
        pos_y[i] = pos_y[i] + vel_y[i] * dt   -- tight sequential loop
    end
end
```

**GDScript (Godot):**
```gdscript
const N = 10000

# AoS: Array of Dictionaries — each dict at a separate heap address
var entities_aos: Array[Dictionary] = []
func setup_aos() -> void:
    for i in N:
        entities_aos.append({ "x": randf(), "y": randf(),
                               "vx": 1.0, "vy": 0.5, "hp": 100 })

func move_aos(dt: float) -> void:
    for e in entities_aos:
        e["x"] += e["vx"] * dt   # dictionary lookup + pointer chase per entity
        e["y"] += e["vy"] * dt

# SoA: PackedFloat32Array — contiguous memory, no boxing overhead
var pos_x := PackedFloat32Array(); var pos_y := PackedFloat32Array()
var vel_x := PackedFloat32Array(); var vel_y := PackedFloat32Array()

func setup_soa() -> void:
    pos_x.resize(N); pos_y.resize(N)
    vel_x.resize(N); vel_y.resize(N)
    for i in N:
        pos_x[i] = randf(); pos_y[i] = randf()
        vel_x[i] = 1.0;     vel_y[i] = 0.5

func move_soa(dt: float) -> void:
    for i in N:
        pos_x[i] += vel_x[i] * dt   # contiguous float reads — far fewer misses
        pos_y[i] += vel_y[i] * dt
```

Note: `PackedFloat32Array` in Godot is backed by a contiguous C++ array of 32-bit floats. It is the closest GDScript gets to true SoA performance. Regular `Array` uses Variant boxing and pointer indirection, which behaves like AoS at the hardware level.

---

## 3. Hot/Cold Data Splitting

Not all data is needed at the same frequency. Physics systems touch position and velocity every frame. A renderer may read sprite path once per asset load. A tooltip system reads lore text when the player hovers. These access patterns are wildly different, and mixing the data destroys cache efficiency for the frequent accesses.

**The problem with a bloated entity struct:**

```
entity = {
    x, y, vx, vy,           -- accessed every frame (HOT)
    hp, max_hp,              -- accessed on damage (WARM)
    sprite_path,             -- accessed on spawn (COLD)
    shader_name,             -- accessed on visual change (COLD)
    lore_text,               -- accessed on tooltip hover (VERY COLD)
    equipment_slot_1, ...    -- accessed in inventory screen (VERY COLD)
}
```

When your physics system iterates 10,000 entities, every cache line it loads is packed with cold data. That cold data evicts hot data from L1/L2. Physics slows down because of equipment slots it never reads.

**The solution: split components by access frequency.**

Hot components stay together. Cold components go separately. Systems only query the components they need, so cold data never enters the physics system's working set.

**Pseudocode:**
```
// Before: one fat component
PhysicsBody { x, y, vx, vy, sprite_path, lore_text, equipment[8] }

// After: split by temperature
PhysicsData  { x, y, vx, vy }              // hot — physics every frame
VisualData   { sprite_path, shader_name }  // cold — renderer on change
CharacterData { lore_text, equipment[8] }  // very cold — UI on demand
```

**Lua (tiny-ecs / Love2D):**
```lua
local tiny = require "tiny"

-- Before: bloated single component (bad)
local function make_entity_bloated(world)
    return tiny.entity(world, {
        -- hot
        x=100, y=200, vx=1, vy=0,
        -- cold (loaded into cache alongside hot data every physics tick)
        sprite_path = "assets/hero.png",
        shader_name = "outline",
        lore_text   = "A wandering warrior from the northern provinces...",
        equipment   = { "sword", "shield", nil, nil, nil, nil, nil, nil }
    })
end

-- After: separate components by temperature
local function make_entity_split(world)
    -- PhysicsData: touched every frame, stays hot in cache
    local physics = { x=100, y=200, vx=1, vy=0, is_physics_data=true }
    -- VisualData: touched by renderer system, not physics
    local visual  = { sprite_path="assets/hero.png", shader="outline", is_visual=true }
    -- CharacterData: touched by UI only, never by physics
    local chara   = { lore="A wandering warrior...", equipment={}, is_character=true }
    return tiny.entity(world, physics, visual, chara)
end

-- PhysicsSystem only queries physics_data — cold data never touches this cache
local physics_system = tiny.processingSystem()
physics_system.filter = tiny.requireAll("is_physics_data")
function physics_system:process(e, dt)
    e.x = e.x + e.vx * dt
    e.y = e.y + e.vy * dt
end
```

**GDScript (Godot):**
```gdscript
# Before: one Resource with everything
class_name EntityDataBloated extends Resource
var x: float; var y: float; var vx: float; var vy: float
var sprite_path: String     # cold — never touched by physics
var lore_text: String       # very cold — only tooltip UI
var equipment: Array        # very cold — only inventory screen

# After: split Resources by access frequency
class_name PhysicsData extends Resource   # hot
var x: float; var y: float
var vx: float; var vy: float

class_name VisualData extends Resource   # cold
var sprite_path: String
var shader_name: String

class_name CharacterData extends Resource   # very cold
var lore_text: String
var equipment: Array

# Physics system only holds references to PhysicsData
class_name PhysicsSystem
var physics_components: Array[PhysicsData] = []

func tick(dt: float) -> void:
    for pd in physics_components:   # iterating only hot data
        pd.x += pd.vx * dt
        pd.y += pd.vy * dt
```

Hot/cold splitting is a form of SoA thinking applied at the component design level. You are deciding which data lives together in memory by grouping it by access pattern, not by conceptual relationship.

---

## 4. Why Archetype ECS Is Inherently Cache-Friendly

Archetype ECS gets cache efficiency without requiring you to manually manage SoA arrays. The layout is SoA by construction.

In an archetype ECS (Bevy, Flecs, Unity DOTS), all entities sharing the same component set live in the same archetype chunk. Within each chunk, component data is stored in separate contiguous arrays — one array per component type:

```
Archetype { Position, Velocity }
  positions:   [ x0,y0, x1,y1, x2,y2, ... ]   <-- contiguous
  velocities:  [ vx0,vy0, vx1,vy1, ... ]        <-- contiguous, separate

Archetype { Position, Velocity, Health }
  positions:   [ ... ]
  velocities:  [ ... ]
  health:      [ ... ]
```

MovementSystem queries `(Position, Velocity)`. The ECS gives it the position array and velocity array from each matching archetype. It iterates both sequentially. The CPU prefetcher detects the stride and fetches ahead. Cache misses drop to nearly zero.

This is why Bevy benchmarks at 800+ million entity updates per second on a single thread. It is not because Rust is magic. It is because archetype storage enforces the SoA layout that enables the prefetcher to do its job.

**Contrast with hash-table ECS (tiny-ecs style):** tiny-ecs stores components as fields on Lua tables. Each table is a separate heap allocation. The "archetype" concept does not exist; tiny-ecs uses filter-based queries that scan all entities. Movement still works correctly, but each entity access may chase a pointer to a different cache line. The cache behavior is worse. This is the tradeoff: tiny-ecs is simpler to implement and plenty fast for small entity counts (under ~5,000), but it does not scale to the entity counts that archetype ECS handles.

The deep lesson: **the architecture that is clearest conceptually — separate data by type, iterate by component — is also the architecture that is fastest at the hardware level.** In archetype ECS, these align perfectly. You are not making a performance compromise. You are getting the good design for free because the good design happens to match what the CPU wants.

**Pseudocode:**
```
// Archetype ECS internal layout (SoA per archetype chunk)
archetype_chunk = {
    positions_x:  [p0x, p1x, p2x, p3x, ...]   // contiguous float array
    positions_y:  [p0y, p1y, p2y, p3y, ...]
    velocities_x: [v0x, v1x, v2x, v3x, ...]
    velocities_y: [v0y, v1y, v2y, v3y, ...]
}

// System iteration: sequential reads, no pointer chasing
for i in 0..chunk.count:
    chunk.positions_x[i] += chunk.velocities_x[i] * dt
    chunk.positions_y[i] += chunk.velocities_y[i] * dt
```

**Lua (tiny-ecs / Love2D):**
```lua
-- tiny-ecs does not use archetype chunks, but you can approximate
-- the benefit by keeping component tables in a manually managed SoA pool

local pos_pool = { x = {}, y = {} }
local vel_pool = { x = {}, y = {} }
local entity_to_idx = {}   -- entity id -> pool index
local count = 0

local function add_entity(id, x, y, vx, vy)
    count = count + 1
    pos_pool.x[count] = x;   pos_pool.y[count] = y
    vel_pool.x[count] = vx;  vel_pool.y[count] = vy
    entity_to_idx[id] = count
end

-- This system iterates tight float arrays — close to archetype behavior
local function movement_system(dt)
    local px, py = pos_pool.x, pos_pool.y
    local vx, vy = vel_pool.x, vel_pool.y
    for i = 1, count do
        px[i] = px[i] + vx[i] * dt
        py[i] = py[i] + vy[i] * dt
    end
end
```

**GDScript (Godot):**
```gdscript
# Godot does not expose archetype ECS, but you can build SoA pools manually
# This approximates archetype chunk behavior for performance-critical systems

class_name SoAPool
var pos_x := PackedFloat32Array()
var pos_y := PackedFloat32Array()
var vel_x := PackedFloat32Array()
var vel_y := PackedFloat32Array()
var count: int = 0

func add(x: float, y: float, vx: float, vy: float) -> int:
    pos_x.append(x); pos_y.append(y)
    vel_x.append(vx); vel_y.append(vy)
    count += 1
    return count - 1   # index

func tick(dt: float) -> void:
    # Sequential reads over PackedFloat32Array — contiguous C++ memory
    for i in count:
        pos_x[i] += vel_x[i] * dt
        pos_y[i] += vel_y[i] * dt
```

---

## 5. SIMD and Batch Processing Concepts

SIMD stands for Single Instruction, Multiple Data. Modern CPUs can execute one instruction that operates on multiple values simultaneously. SSE2 handles 4 floats at once. AVX2 handles 8. AVX-512 handles 16.

The compiler can auto-vectorize loops to use SIMD instructions if three conditions are met:

1. Data is in contiguous arrays (no pointer indirection)
2. No branches inside the loop (no `if` statements)
3. Operations are simple and independent (each iteration does not depend on the previous)

SoA satisfies all three. AoS violates condition 1. The compiler cannot pack floats from scattered structs into a SIMD register — the data is not adjacent in memory.

In C/C++, this loop over SoA data auto-vectorizes at `-O2`:

```c
// Compiler sees contiguous floats, no branches, independent ops
// It emits AVX2 instructions: 8 additions per clock cycle
for (int i = 0; i < n; i++) {
    pos_x[i] += vel_x[i] * dt;
    pos_y[i] += vel_y[i] * dt;
}
```

The equivalent loop over AoS does not auto-vectorize because `pos_x` values are not adjacent — they are interleaved with `pos_y`, `vel_x`, `vel_y`, and whatever else is in the struct.

You do not write SIMD intrinsics by hand. You write clean SoA loops and let the compiler find the vectorization opportunity. The layout does the work.

**Lua and GDScript do not give you SIMD.** Interpreted/VM languages cannot generate architecture-specific SIMD instructions at runtime the way an optimizing C/C++ compiler can. This is fine for most game logic. It is the reason why high-performance ECS games (anything needing millions of entity updates per frame) put compute-heavy systems in C or C++ native plugins and keep game logic in the scripting language. The scripting layer handles entity creation, game rules, AI decisions. The C layer handles particle positions, cloth simulation, fluid dynamics.

Understanding SIMD explains why native ECS implementations are as fast as they are, and it gives you the vocabulary to understand why "just use Lua/GDScript" has a ceiling.

**Pseudocode:**
```
// SIMD-friendly loop (SoA layout, no branches, simple ops)
for i in 0..N step 8:            // process 8 floats at once
    pos_x[i..i+8] += vel_x[i..i+8] * dt   // 1 SIMD instruction

// SIMD-hostile loop (AoS layout — data not contiguous)
for i in 0..N:
    entities[i].x += entities[i].vx * dt  // can't vectorize: x is not next to x[1]
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Lua does not auto-vectorize, but writing SIMD-friendly loops
-- gives LuaJIT the best chance to optimize the inner loop.
-- LuaJIT's trace compiler prefers tight loops over flat arrays.

local function move_simd_friendly(pos_x, pos_y, vel_x, vel_y, n, dt)
    -- No branches, sequential access, local variables hoisted out of loop
    -- LuaJIT can compile this to efficient machine code (not SIMD, but fast)
    for i = 1, n do
        pos_x[i] = pos_x[i] + vel_x[i] * dt
        pos_y[i] = pos_y[i] + vel_y[i] * dt
    end
end

-- Branch inside loop: kills LuaJIT's ability to generate tight code
local function move_with_branch(pos_x, pos_y, vel_x, vel_y, active, n, dt)
    for i = 1, n do
        if active[i] then   -- branch: JIT trace splits, worse output
            pos_x[i] = pos_x[i] + vel_x[i] * dt
            pos_y[i] = pos_y[i] + vel_y[i] * dt
        end
    end
end
```

**GDScript (Godot):**
```gdscript
# GDScript does not emit SIMD, but PackedFloat32Array operations
# may be accelerated by Godot's internal C++ implementation.
# Keep loops branch-free for maximum throughput.

func move_simd_friendly(dt: float) -> void:
    # No branches inside the loop — GDScript VM can optimize better
    for i in count:
        pos_x[i] += vel_x[i] * dt
        pos_y[i] += vel_y[i] * dt

# If you need branches, handle them by maintaining separate active/inactive pools
# rather than branching inside the hot loop.
func move_with_pools(active_pool: SoAPool, dt: float) -> void:
    active_pool.tick(dt)   # only active entities are in this pool — no branching
```

---

## Code Walkthrough: 10,000 Particle Benchmark — AoS vs SoA in Lua

This benchmark makes the performance difference concrete. Run it in Love2D and read the numbers yourself.

```lua
-- particle_benchmark.lua
-- Drop this in a Love2D project and call from love.load()

local N = 10000

-- ============================================================
-- AoS setup: array of particle tables
-- ============================================================
local particles_aos = {}
for i = 1, N do
    particles_aos[i] = {
        x  = math.random(800),
        y  = math.random(600),
        vx = math.random(-100, 100) / 10.0,
        vy = math.random(-100, 100) / 10.0,
    }
end

local function update_aos(dt)
    for i = 1, #particles_aos do
        local p = particles_aos[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
    end
end

-- ============================================================
-- SoA setup: separate arrays per field
-- ============================================================
local pos_x = {}; local pos_y = {}
local vel_x = {}; local vel_y = {}
for i = 1, N do
    pos_x[i] = math.random(800);            pos_y[i] = math.random(600)
    vel_x[i] = math.random(-100, 100) / 10.0
    vel_y[i] = math.random(-100, 100) / 10.0
end

local function update_soa(dt)
    for i = 1, N do
        pos_x[i] = pos_x[i] + vel_x[i] * dt
        pos_y[i] = pos_y[i] + vel_y[i] * dt
    end
end

-- ============================================================
-- Benchmark runner
-- ============================================================
local ITERATIONS = 1000
local dt = 1 / 60

-- Warm up: run once to allow LuaJIT to compile traces
update_aos(dt); update_soa(dt)

-- Benchmark AoS
local t0 = love.timer.getTime()
for _ = 1, ITERATIONS do update_aos(dt) end
local aos_time = love.timer.getTime() - t0

-- Benchmark SoA
local t1 = love.timer.getTime()
for _ = 1, ITERATIONS do update_soa(dt) end
local soa_time = love.timer.getTime() - t1

print(string.format(
    "AoS: %.3fs | SoA: %.3fs | Speedup: %.2fx",
    aos_time, soa_time, aos_time / soa_time
))
-- Typical output on modern hardware:
-- AoS: 0.412s | SoA: 0.187s | Speedup: 2.20x
```

**What the numbers mean:** on LuaJIT (which Love2D uses), expect a 1.5x–3x speedup for SoA. The speedup is real but smaller than in C/C++ (where the same comparison shows 5x–20x). The reason is Lua's data model: even though `pos_x` is a sequential Lua table, Lua tables are hash tables under the hood. Integer keys are optimized to array storage in LuaJIT, but there is still overhead — array bounds metadata, GC interaction, VM dispatch — that partially masks the cache improvement.

The SoA loop is also simpler for the LuaJIT trace compiler to reason about. The AoS loop dereferences a pointer (`particles_aos[i]` returns a table reference), then does field lookups on that table (`p.vx`, `p.vy`). Two levels of indirection per iteration. The SoA loop does direct integer-indexed table reads — one level. LuaJIT produces tighter bytecode.

In C/C++ with `-O2`, the SoA loop auto-vectorizes (SIMD), the AoS loop does not, and the underlying cache behavior is also worse for AoS. Both effects stack, giving the larger speedup.

**GDScript equivalent using PackedFloat32Array:**

```gdscript
# particle_benchmark.gd — attach to a Node, call from _ready()
extends Node

const N = 10000
const ITERATIONS = 1000

func run_benchmark() -> void:
    # --- AoS: Array of Dictionaries ---
    var particles_aos: Array[Dictionary] = []
    for i in N:
        particles_aos.append({
            "x": randf_range(0, 800), "y": randf_range(0, 600),
            "vx": randf_range(-10, 10), "vy": randf_range(-10, 10)
        })

    var dt := 1.0 / 60.0
    var t0 := Time.get_ticks_usec()
    for _iter in ITERATIONS:
        for p in particles_aos:
            p["x"] += p["vx"] * dt
            p["y"] += p["vy"] * dt
    var aos_time := (Time.get_ticks_usec() - t0) / 1_000_000.0

    # --- SoA: PackedFloat32Array per field ---
    var pos_x := PackedFloat32Array(); var pos_y := PackedFloat32Array()
    var vel_x := PackedFloat32Array(); var vel_y := PackedFloat32Array()
    pos_x.resize(N); pos_y.resize(N); vel_x.resize(N); vel_y.resize(N)
    for i in N:
        pos_x[i] = randf_range(0, 800); pos_y[i] = randf_range(0, 600)
        vel_x[i] = randf_range(-10, 10); vel_y[i] = randf_range(-10, 10)

    var t1 := Time.get_ticks_usec()
    for _iter in ITERATIONS:
        for i in N:
            pos_x[i] += vel_x[i] * dt
            pos_y[i] += vel_y[i] * dt
    var soa_time := (Time.get_ticks_usec() - t1) / 1_000_000.0

    print("AoS: %.3fs | SoA: %.3fs | Speedup: %.2fx" % [
        aos_time, soa_time, aos_time / soa_time
    ])
    # Typical output: AoS: 0.89s | SoA: 0.31s | Speedup: 2.87x
    # GDScript shows larger gains because PackedFloat32Array is C++ contiguous memory
    # while Dictionary is fully boxed Variant with hash overhead

func _ready() -> void:
    run_benchmark()
```

GDScript shows a larger speedup than Lua (typically 2.5x–4x) because the gap between `Dictionary` (fully boxed Variant, hash table) and `PackedFloat32Array` (raw contiguous C++ floats) is greater than the gap between two Lua table layouts.

---

## Concept Quick Reference

| Term | Definition |
|------|-----------|
| Cache line | 64 bytes loaded atomically when any byte in that range is accessed |
| Cache hit | Requested data was already in L1/L2/L3 — essentially free |
| Cache miss | Requested data was in RAM — costs 300–400 CPU cycles |
| AoS | Array of Structs: one struct per entity, all mixed together |
| SoA | Struct of Arrays: one array per field, separated by type |
| Hot data | Data accessed every frame (position, velocity) |
| Cold data | Data accessed rarely (sprite path, lore text) |
| SIMD | Single Instruction Multiple Data — process N floats per clock cycle |
| Auto-vectorization | Compiler converts scalar loops to SIMD automatically given SoA layout |
| Prefetcher | CPU hardware that detects sequential access patterns and fetches ahead |
| Archetype chunk | Contiguous block of SoA component arrays for one archetype |

---

## Common Pitfalls

**Mixing hot and cold data in one component.** If a component holds both `x, y, vx, vy` and `sprite_path, lore_text`, every physics update loads the cold data into cache. Split them.

**Premature optimization on small entity counts.** Below ~1,000 entities, the cache difference is not perceptible at 60fps. Do not restructure working code to SoA until profiling shows a memory bottleneck. Profile first, then optimize layout.

**Adding branches inside hot loops.** A conditional inside an update loop breaks auto-vectorization potential and gives the JIT compiler a harder job. Instead of `if entity.active then move(entity)`, maintain separate active/inactive pools and only iterate the active pool.

**Forgetting that Lua tables are hash tables.** Lua integer-indexed tables are optimized to array storage by LuaJIT, but they are not raw C arrays. If you need true SoA performance in Lua, consider LuaJIT FFI with `ffi.new("float[?]", N)` — you get actual contiguous C memory.

**Thinking SoA makes sense for everything.** If a system reads all fields of every entity every frame, AoS and SoA have similar cache behavior — every cache line gets used. SoA shines when systems only touch a subset of fields. For a game with 200 entities and 5 systems each reading all fields, SoA is extra complexity for no gain.

**Assuming GDScript PackedFloat32Array is always better.** `PackedFloat32Array` is faster for bulk numeric iteration. It is worse when you need frequent random insertions or deletions (shifting is O(n)). For entity counts under 500 with frequent add/remove, regular `Array` is simpler and fast enough.

---

## Exercises

1. **Run the particle benchmark** in Love2D with N = 1,000, 10,000, and 100,000. Record the AoS and SoA times. At what entity count does the speedup become noticeable? At what count does frame time exceed 16ms (60fps budget)?

2. **Add cold data to the AoS benchmark** — add a `sprite_path` string and a `lore_text` string to each particle table. Re-run the benchmark. Does the AoS time increase? Does the SoA time change? Why?

3. **Implement hot/cold splitting** in a tiny-ecs project: take an entity that has `{x, y, vx, vy, hp, sprite, lore}` and split it into two components: `PhysicsComp {x, y, vx, vy}` and `MetaComp {hp, sprite, lore}`. Verify that a physics system filtering by `PhysicsComp` does not receive `MetaComp` data.

4. **Profile a real system with Love2D profiling.** Use `love.timer.getTime()` to measure a movement system over 10,000 frames. Then restructure the system to use SoA pools (manually managed flat arrays). Measure again. Report the delta.

5. **GDScript challenge:** implement a simple particle simulation using `PackedFloat32Array` for position and velocity. Add boundary collision (bounce off screen edges). Measure performance at 50,000 particles. Then add a `PackedByteArray` for per-particle color and measure whether it changes performance.

6. **Design exercise:** you have a character entity with these fields: `x, y, vx, vy, hp, mp, stamina, sprite_index, sound_footstep_id, dialogue_tree_id, faction_id, reputation_score`. Categorize each field as hot, warm, or cold. Propose a component split that would maximize cache efficiency for a physics-heavy game.

---

## Key Takeaways

- A cache miss costs 300–400 CPU cycles. At 60fps and 10,000 entities, bad layout wastes hundreds of millions of cycles per second before any game logic runs.
- AoS is natural for OOP thinking. SoA is natural for cache efficiency. ECS pushes you toward SoA.
- Store hot data (touched every frame) separately from cold data (touched rarely). The split is at the component level — one component for hot fields, separate components for cold ones.
- Archetype ECS gives you SoA by default. Each archetype chunk stores component arrays contiguously. You get cache efficiency without manually managing flat arrays.
- SIMD auto-vectorization requires SoA layout. You do not write SIMD by hand — you write SoA loops and the compiler does it. Lua/GDScript do not auto-vectorize, but understanding SIMD explains why native ECS implementations are so fast.
- In Lua, SoA gives 1.5x–3x speedup. In C/C++, 5x–20x. The difference comes from SIMD and lower pointer indirection overhead in native code.
- Do not optimize layout prematurely. Profile first. Under 1,000 entities, cache layout rarely matters at 60fps.

---

## What's Next

[Module 6: ECS in Practice](module-06-ecs-in-practice.md) — survey real ECS frameworks (tiny-ecs, Concord, Flecs, Bevy), understand when Godot's node model wins, and learn when NOT to use ECS at all.

Back to [ECS Learning Roadmap](ecs-learning-roadmap.md)
