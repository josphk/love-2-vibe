# Module 1: Finite State Machines

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 4-6 hours
**Prerequisites:** [Module 0: What "Game AI" Actually Means](module-00-what-game-ai-means.md)

---

## Overview

The finite state machine is where game AI begins. It is the most important pattern in this entire roadmap — not because it's the most powerful, but because it's the most useful. A surprising number of excellent, shipped games run entirely on FSMs. If you only learn one AI technique, make it this one.

The concept is simple enough to explain in one sentence: your NPC is always in exactly one **state**, and **transitions** between states are triggered by conditions. A guard is either patrolling, or chasing, or attacking, or searching — never two at once. When the player enters the guard's vision, it transitions from patrol to chase. When the player escapes, it transitions from chase to search. When the search timer expires, it goes back to patrol. That's it. That's the whole pattern.

FSMs work because they're predictable, debuggable, and easy to reason about. When your guard is in the "patrol" state, you know exactly what it's doing and exactly what conditions will change that. There's no hidden complexity, no emergent surprises, no mysterious behavior that you can't trace. When something goes wrong — and it will — you can step through the logic and find the broken transition in minutes. This debuggability is worth more than any amount of theoretical elegance, especially when you're shipping a game and need to fix an AI bug at 2 AM.

---

## 1. States, Transitions, and the State Diagram

Every FSM has three components: **states**, **transitions**, and **actions**. Let's define them precisely.

A **state** is a distinct mode of behavior. While the NPC is in a state, it does one thing. The "Patrol" state means "walk between waypoints." The "Chase" state means "move toward the player." The "Attack" state means "damage the player if in range." States are mutually exclusive — the NPC is in exactly one state at any given moment.

A **transition** is a condition that causes a state change. "Player visible" is a transition from Patrol to Chase. "Player in attack range" is a transition from Chase to Attack. "Player escaped" is a transition from Chase to Search. Transitions have a *source state* and a *target state* — the same condition might mean different things in different states.

An **action** is code that runs at specific moments: **enter** (when transitioning into a state), **update** (every frame while in the state), and **exit** (when transitioning out of a state). Enter actions set things up (play an animation, start a timer). Update actions do the ongoing work (move toward target, count down a timer). Exit actions clean up (stop an animation, reset variables).

The best way to design an FSM is to draw it on paper first. This is called a **state diagram**:

```
                    player_visible
    ┌─────────┐ ──────────────────→ ┌─────────┐
    │  PATROL │                     │  CHASE  │
    │         │ ←────────────────── │         │
    └────┬────┘   search_timeout    └────┬────┘
         │                               │
         │                          player_in_range
         │                               │
         │                               ▼
         │                          ┌─────────┐
         │                          │ ATTACK  │
         │                          │         │
         │                          └────┬────┘
         │                               │
         │         player_escaped        │
         │    ┌──────────────────────────┘
         │    ▼
    ┌─────────┐
    │ SEARCH  │
    │         │
    └─────────┘
         │
         │ search_timeout
         │
         └──────→ (back to PATROL)
```

Every circle is a state. Every arrow is a transition, labeled with its condition. Draw this *before* you code. Five minutes of sketching saves hours of confused debugging. Keep scratch paper next to your keyboard — this advice will repeat throughout the roadmap because it's that important.

---

## 2. A Minimal FSM Implementation

Let's implement a basic FSM. The simplest approach — and the one you should start with — is an `if/elseif` chain or a match/switch on the current state.

```gdscript
# GDScript — Simple enum-based FSM
extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK, SEARCH }

var current_state: State = State.IDLE
var player: Node2D = null
var speed := 100.0
var attack_range := 50.0
var detect_range := 200.0
var search_timer := 0.0
var last_known_pos := Vector2.ZERO

# Patrol
var patrol_points := [Vector2(100, 200), Vector2(400, 200), Vector2(400, 400)]
var patrol_index := 0

func _process(delta: float) -> void:
    player = get_node_or_null("/root/Game/Player")
    var dist_to_player = global_position.distance_to(player.global_position) if player else INF

    match current_state:
        State.IDLE:
            _state_idle(delta)
        State.PATROL:
            _state_patrol(delta, dist_to_player)
        State.CHASE:
            _state_chase(delta, dist_to_player)
        State.ATTACK:
            _state_attack(delta, dist_to_player)
        State.SEARCH:
            _state_search(delta, dist_to_player)

func _change_state(new_state: State) -> void:
    # Exit actions for old state
    match current_state:
        State.CHASE:
            last_known_pos = player.global_position if player else global_position
        State.ATTACK:
            pass  # Could stop attack animation here

    current_state = new_state

    # Enter actions for new state
    match new_state:
        State.SEARCH:
            search_timer = 5.0
        State.PATROL:
            pass  # Pick nearest patrol point, etc.

func _state_idle(_delta: float) -> void:
    # Just stand there. Transition to patrol after a beat.
    _change_state(State.PATROL)

func _state_patrol(delta: float, dist_to_player: float) -> void:
    if dist_to_player < detect_range:
        _change_state(State.CHASE)
        return

    var target = patrol_points[patrol_index]
    var direction = (target - global_position).normalized()
    velocity = direction * speed
    move_and_slide()

    if global_position.distance_to(target) < 10.0:
        patrol_index = (patrol_index + 1) % patrol_points.size()

func _state_chase(delta: float, dist_to_player: float) -> void:
    if dist_to_player < attack_range:
        _change_state(State.ATTACK)
        return
    if dist_to_player > detect_range * 1.5:
        _change_state(State.SEARCH)
        return

    var direction = (player.global_position - global_position).normalized()
    velocity = direction * speed * 1.5
    move_and_slide()

func _state_attack(delta: float, dist_to_player: float) -> void:
    if dist_to_player > attack_range * 1.2:
        _change_state(State.CHASE)
        return
    # Deal damage, play animation, etc.
    velocity = Vector2.ZERO

func _state_search(delta: float, dist_to_player: float) -> void:
    if dist_to_player < detect_range:
        _change_state(State.CHASE)
        return

    search_timer -= delta
    if search_timer <= 0:
        _change_state(State.PATROL)
        return

    var direction = (last_known_pos - global_position).normalized()
    velocity = direction * speed * 0.7
    move_and_slide()

    if global_position.distance_to(last_known_pos) < 10.0:
        velocity = Vector2.ZERO  # Stand and look around
```

```lua
-- Lua (LÖVE) — Same FSM pattern
local guard = {
    x = 100, y = 200,
    speed = 100,
    state = "idle",
    attack_range = 50,
    detect_range = 200,
    search_timer = 0,
    last_known_x = 0, last_known_y = 0,
    patrol = {{100, 200}, {400, 200}, {400, 400}},
    patrol_index = 1,
}

function guard:change_state(new_state)
    -- Exit actions
    if self.state == "chase" then
        self.last_known_x = player.x
        self.last_known_y = player.y
    end

    self.state = new_state

    -- Enter actions
    if new_state == "search" then
        self.search_timer = 5.0
    end
end

function guard:update(dt)
    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if self.state == "idle" then
        self:change_state("patrol")

    elseif self.state == "patrol" then
        if dist < self.detect_range then
            self:change_state("chase")
            return
        end
        local target = self.patrol[self.patrol_index]
        local tx, ty = target[1] - self.x, target[2] - self.y
        local tdist = math.sqrt(tx * tx + ty * ty)
        if tdist < 10 then
            self.patrol_index = self.patrol_index % #self.patrol + 1
        else
            self.x = self.x + (tx / tdist) * self.speed * dt
            self.y = self.y + (ty / tdist) * self.speed * dt
        end

    elseif self.state == "chase" then
        if dist < self.attack_range then
            self:change_state("attack")
            return
        end
        if dist > self.detect_range * 1.5 then
            self:change_state("search")
            return
        end
        local nx, ny = dx / dist, dy / dist
        self.x = self.x + nx * self.speed * 1.5 * dt
        self.y = self.y + ny * self.speed * 1.5 * dt

    elseif self.state == "attack" then
        if dist > self.attack_range * 1.2 then
            self:change_state("chase")
            return
        end
        -- Deal damage, play animation, etc.

    elseif self.state == "search" then
        if dist < self.detect_range then
            self:change_state("chase")
            return
        end
        self.search_timer = self.search_timer - dt
        if self.search_timer <= 0 then
            self:change_state("patrol")
            return
        end
        local sx = self.last_known_x - self.x
        local sy = self.last_known_y - self.y
        local sdist = math.sqrt(sx * sx + sy * sy)
        if sdist > 10 then
            self.x = self.x + (sx / sdist) * self.speed * 0.7 * dt
            self.y = self.y + (sy / sdist) * self.speed * 0.7 * dt
        end
    end
end
```

This is a complete, functional AI. Five states, clear transitions, enter/exit actions. It's not the most elegant code architecture, but it works, it's readable, and you can debug it by printing `current_state` every frame. For many games, this is all you need.

---

## 3. Enter and Exit Actions — The Secret Weapon

The difference between an FSM that feels robotic and one that feels alive is almost entirely in the **enter and exit actions**. These are the moments of transition — the NPC reacting to a change in situation — and they're where players notice the most.

Consider the transition from Patrol to Chase. Without enter/exit actions:

```
Frame 1: Guard walking along patrol route
Frame 2: Guard moving directly toward player at chase speed
```

The guard instantly snaps from one behavior to another. It's functional but feels mechanical. Now add enter/exit actions:

```
Enter Chase:
  - Play "alert" animation (guard startles, raises weapon)
  - Emit "!" particle effect above head
  - Play alert sound effect
  - Set speed to 0 for 0.3 seconds (reaction delay)
  - Store last known player position

Exit Patrol:
  - Stop walking animation
```

Now the transition feels like a *moment*. The player sees the guard react, which builds tension and communicates information. That 0.3-second delay before the chase begins gives the player time to register "I've been spotted" and start responding. It's more fun and more fair.

Common enter/exit actions that make a big difference:

| Transition | Enter Action | Why It Matters |
|-----------|-------------|----------------|
| → Chase | Alert animation, reaction delay | Player sees they've been spotted |
| → Search | Look-around animation, slow speed | Feels like the guard is uncertain |
| → Patrol (from Search) | Shrug animation, "must have been nothing" bark | Comic relief, tension release |
| → Attack | Wind-up animation | Telegraph for the player to react |
| → Flee | Stumble animation, faster speed | Communicates desperation |

---

## 4. The State Explosion Problem

FSMs work beautifully until they don't. The breaking point comes when your NPC needs many states and the transitions between them form a tangled web.

Imagine you start with 5 states (Idle, Patrol, Chase, Attack, Search). That's manageable — maybe 8-10 transitions. Now the designer says:

- "Can the guard call for backup when it spots the player?"
- "Can it flee when health is low?"
- "Can it pick up ammo when it runs out?"
- "Can it take cover during combat?"

Each new behavior isn't just a new state — it's new transitions to and from *every other state*. Can the guard call for backup from Chase? From Attack? Can it flee from Attack? From Search? Can it pick up ammo while searching? While chasing?

```
States:  5     → 9 states
Transitions: ~10 → ~30+ transitions
Complexity: manageable → spaghetti
```

This is called **state explosion**, and it's the fundamental limitation of flat FSMs. The number of possible transitions grows roughly as N² (where N is the number of states), and each transition needs to be explicitly authored and tested.

There are three main solutions to state explosion:

1. **Hierarchical FSMs** (covered in section 5 below) — reduce complexity through nesting
2. **Behavior Trees** (Module 2) — replace the flat web with a composable tree structure
3. **Utility AI** (Module 5) — replace explicit transitions with scored evaluations

Don't treat state explosion as a failure of FSMs. Treat it as a signal that your NPC has outgrown the tool. An FSM with 5-7 states is clean and maintainable. An FSM with 15 states needs a different architecture. The art is recognizing when you've hit that threshold.

---

## 5. Hierarchical State Machines

The first defense against state explosion is hierarchy. Instead of one flat FSM with many states, you nest FSMs inside each other. A high-level FSM handles broad behavioral modes, and each mode contains a sub-FSM for the details.

```
Top-Level FSM:
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   PEACEFUL   │───→│    COMBAT    │───→│   FLEEING    │
│              │    │              │    │              │
│ ┌──────────┐ │    │ ┌──────────┐ │    │ ┌──────────┐ │
│ │  Idle    │ │    │ │  Melee   │ │    │ │ Run Away │ │
│ │  Patrol  │ │    │ │  Ranged  │ │    │ │ Find     │ │
│ │  Wander  │ │    │ │  Dodge   │ │    │ │  Exit    │ │
│ │  Converse│ │    │ │  Cover   │ │    │ │ Hide     │ │
│ └──────────┘ │    │ └──────────┘ │    │ └──────────┘ │
└──────────────┘    └──────────────┘    └──────────────┘
```

The top level only has three transitions: "enter combat when threatened" and "flee when health is critical" and "return to peaceful when danger passes." Inside each top-level state, the sub-FSM handles its own transitions without worrying about the others. The "Melee vs. Ranged" decision only exists inside Combat. The "Idle vs. Patrol" decision only exists inside Peaceful.

This dramatically reduces transition count. Instead of every low-level state needing transitions to every other low-level state, you only need transitions within each group plus the top-level transitions.

```gdscript
# GDScript — Hierarchical FSM structure
enum TopState { PEACEFUL, COMBAT, FLEEING }
enum PeacefulState { IDLE, PATROL, WANDER }
enum CombatState { MELEE, RANGED, DODGE, COVER }

var top_state: TopState = TopState.PEACEFUL
var peaceful_state: PeacefulState = PeacefulState.IDLE
var combat_state: CombatState = CombatState.MELEE

func _process(delta: float) -> void:
    # Top-level transitions
    match top_state:
        TopState.PEACEFUL:
            if _threat_detected():
                _enter_top_state(TopState.COMBAT)
            else:
                _update_peaceful(delta)
        TopState.COMBAT:
            if _health_critical():
                _enter_top_state(TopState.FLEEING)
            elif not _threat_detected():
                _enter_top_state(TopState.PEACEFUL)
            else:
                _update_combat(delta)
        TopState.FLEEING:
            if _is_safe():
                _enter_top_state(TopState.PEACEFUL)
            else:
                _update_fleeing(delta)

func _update_combat(delta: float) -> void:
    var dist = global_position.distance_to(player.global_position)
    # Sub-state transitions only care about combat concerns
    match combat_state:
        CombatState.MELEE:
            if dist > melee_range:
                combat_state = CombatState.RANGED
            if _incoming_attack():
                combat_state = CombatState.DODGE
        CombatState.RANGED:
            if dist < melee_range:
                combat_state = CombatState.MELEE
            if _taking_damage():
                combat_state = CombatState.COVER
        # ... etc
```

```lua
-- Lua — Hierarchical FSM using nested tables
local fsm = {
    top = "peaceful",
    sub = {
        peaceful = "idle",
        combat = "melee",
        fleeing = "run_away",
    }
}

function update_ai(guard, dt)
    -- Top-level transitions
    if fsm.top == "peaceful" then
        if threat_detected(guard) then
            fsm.top = "combat"
            fsm.sub.combat = "melee"  -- reset sub-state on enter
        else
            update_peaceful(guard, dt)
        end
    elseif fsm.top == "combat" then
        if guard.health < 20 then
            fsm.top = "fleeing"
            fsm.sub.fleeing = "run_away"
        elseif not threat_detected(guard) then
            fsm.top = "peaceful"
            fsm.sub.peaceful = "patrol"
        else
            update_combat(guard, dt)
        end
    elseif fsm.top == "fleeing" then
        if is_safe(guard) then
            fsm.top = "peaceful"
            fsm.sub.peaceful = "idle"
        else
            update_fleeing(guard, dt)
        end
    end
end
```

Hierarchical FSMs are a good middle ground between flat FSMs and full behavior trees. They handle moderate complexity well and remain easy to debug because you can inspect both the top-level state and the current sub-state.

---

## 6. Table-Driven FSMs

As your FSM grows, the `if/elseif` approach gets unwieldy. A cleaner architecture is to define states and transitions as *data* — a table that maps (current_state, condition) → next_state. This separates the FSM structure from the behavior code.

```lua
-- Lua — Table-driven FSM
local transitions = {
    idle = {
        { condition = "start_patrol", target = "patrol" },
    },
    patrol = {
        { condition = "player_visible", target = "chase" },
    },
    chase = {
        { condition = "player_in_range", target = "attack" },
        { condition = "player_lost",     target = "search" },
    },
    attack = {
        { condition = "player_out_of_range", target = "chase" },
        { condition = "player_lost",         target = "search" },
    },
    search = {
        { condition = "player_visible", target = "chase" },
        { condition = "timer_expired",  target = "patrol" },
    },
}

local state_updates = {
    idle    = function(guard, dt) end,
    patrol  = function(guard, dt) move_to_waypoint(guard, dt) end,
    chase   = function(guard, dt) move_toward_player(guard, dt) end,
    attack  = function(guard, dt) do_attack(guard, dt) end,
    search  = function(guard, dt) move_to_last_known(guard, dt) end,
}

local condition_checks = {
    start_patrol       = function(guard) return true end,
    player_visible     = function(guard) return can_see_player(guard) end,
    player_in_range    = function(guard) return dist_to_player(guard) < guard.attack_range end,
    player_out_of_range = function(guard) return dist_to_player(guard) > guard.attack_range * 1.2 end,
    player_lost        = function(guard) return not can_see_player(guard) end,
    timer_expired      = function(guard) return guard.search_timer <= 0 end,
}

function update_fsm(guard, dt)
    -- Check transitions for current state
    local possible = transitions[guard.state]
    if possible then
        for _, t in ipairs(possible) do
            if condition_checks[t.condition](guard) then
                guard.state = t.target
                break  -- only one transition per frame
            end
        end
    end

    -- Run current state's update
    local update_fn = state_updates[guard.state]
    if update_fn then
        update_fn(guard, dt)
    end
end
```

The advantage of table-driven FSMs is that you can define new NPCs by swapping in different transition tables without changing any code. A cowardly NPC has a "health < 50% → flee" transition. A brave NPC has "health < 10% → flee." Same engine, different data.

---

## 7. Transition Hysteresis — Preventing Flickering

One of the most common FSM bugs is **flickering**: the NPC rapidly switches between two states because it's right on the threshold of a transition condition.

```
Frame 1: player at distance 199 (< 200 detect range) → CHASE
Frame 2: guard moves toward player, player backs up to 201 → PATROL
Frame 3: player at 199 again → CHASE
Frame 4: → PATROL
... (guard vibrates between states)
```

The fix is **hysteresis** — using different thresholds for entering and leaving a state. You enter Chase at 200 units, but you don't leave Chase until the player is at 300 units. This creates a "dead zone" that prevents flickering.

```gdscript
# GDScript — Hysteresis in transitions
func _state_patrol(delta: float, dist: float) -> void:
    # Enter chase at 200
    if dist < detect_range:
        _change_state(State.CHASE)

func _state_chase(delta: float, dist: float) -> void:
    # Leave chase at 300 (50% wider than detect range)
    if dist > detect_range * 1.5:
        _change_state(State.SEARCH)
```

The general rule: **exit thresholds should be more generous than entry thresholds.** If you start chasing at distance 200, stop chasing at distance 300. If you start attacking at distance 50, stop attacking at distance 65. The exact ratios depend on your game, but 1.2x to 1.5x is a good starting point.

---

## 8. FSMs in Practice — Real Game Examples

FSMs aren't just a textbook exercise. They're the backbone of AI in many beloved games.

**Pac-Man Ghosts (1980):** Each ghost has three states — Scatter (move to home corner), Chase (pursue Pac-Man using ghost-specific targeting), and Frightened (wander randomly, flee from Pac-Man). The transitions are timer-based (Scatter ↔ Chase alternates on a global timer) and event-based (power pellet → Frightened). Four ghosts, three states each, and the result is one of the most iconic AI systems in gaming history.

**Doom (1993):** Most enemies have a simple FSM: Idle → See Player → Chase → Attack → (player hidden?) → Chase → (give up?) → Idle. The genius is in the tuning — different enemies have different detection ranges, speeds, attack patterns, and give-up timers. The same FSM powers the lowly Zombie and the terrifying Cyberdemon.

**Half-Life (1998):** The soldiers in Half-Life use an FSM with notable additions: they communicate state changes to nearby allies ("enemy spotted!" triggers nearby soldiers to also enter Combat), and their Combat state includes sub-behaviors for grenade throwing and retreating. This was revolutionary for its time — the soldiers felt like a coordinated team even though each one was running its own FSM.

**Hollow Knight (2017):** Most regular enemies in Hollow Knight are clean FSMs. The Husk Guard, for example, has: Idle (standing), Patrol (walking), Alert (saw the player, raising shield), Attack (lunging), and Recover (post-attack cooldown). The transitions are distance-based with timing variations. Boss enemies use more complex phase-based FSMs (covered in Module 9).

The pattern is clear: FSMs scale from the simplest arcade game to modern indie hits. The complexity lives in the tuning and the enter/exit actions, not in the architecture.

---

## Code Walkthrough: A Complete Guard NPC

Let's build a full guard NPC from scratch, combining everything from this module. This guard patrols, detects the player, chases, attacks, searches, and returns to patrol. We'll add enter/exit actions, hysteresis, and a simple debug display.

```gdscript
# GDScript — Complete guard NPC
extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, SEARCH }

@export var speed := 100.0
@export var chase_speed := 160.0
@export var detect_range := 180.0
@export var lose_range := 270.0  # hysteresis: wider than detect
@export var attack_range := 45.0
@export var search_duration := 4.0

var state: State = State.PATROL
var player: Node2D = null
var patrol_points: Array[Vector2] = []
var patrol_index := 0
var search_timer := 0.0
var last_known_pos := Vector2.ZERO
var reaction_timer := 0.0  # delay before acting on state change

# Debug
var state_names := {
    State.PATROL: "PATROL",
    State.CHASE: "CHASE",
    State.ATTACK: "ATTACK",
    State.SEARCH: "SEARCH",
}

func _ready() -> void:
    # Set up patrol points relative to starting position
    var origin = global_position
    patrol_points = [
        origin + Vector2(-100, 0),
        origin + Vector2(100, 0),
        origin + Vector2(100, 100),
        origin + Vector2(-100, 100),
    ]

func _process(delta: float) -> void:
    player = get_tree().get_first_node_in_group("player")
    if not player:
        return

    # Reaction delay (enter action for state transitions)
    if reaction_timer > 0:
        reaction_timer -= delta
        velocity = Vector2.ZERO
        return

    var dist = global_position.distance_to(player.global_position)

    match state:
        State.PATROL:
            update_patrol(delta, dist)
        State.CHASE:
            update_chase(delta, dist)
        State.ATTACK:
            update_attack(delta, dist)
        State.SEARCH:
            update_search(delta, dist)

    move_and_slide()

func change_state(new_state: State) -> void:
    # Exit actions
    if state == State.CHASE or state == State.ATTACK:
        last_known_pos = player.global_position

    # Enter actions
    match new_state:
        State.CHASE:
            reaction_timer = 0.3  # brief pause before chasing
        State.SEARCH:
            search_timer = search_duration
        State.ATTACK:
            reaction_timer = 0.15  # wind-up before attack

    state = new_state

func update_patrol(delta: float, dist: float) -> void:
    if dist < detect_range:
        change_state(State.CHASE)
        return

    var target = patrol_points[patrol_index]
    var to_target = target - global_position
    if to_target.length() < 8.0:
        patrol_index = (patrol_index + 1) % patrol_points.size()
    else:
        velocity = to_target.normalized() * speed

func update_chase(delta: float, dist: float) -> void:
    if dist < attack_range:
        change_state(State.ATTACK)
        return
    if dist > lose_range:
        change_state(State.SEARCH)
        return

    velocity = (player.global_position - global_position).normalized() * chase_speed

func update_attack(delta: float, dist: float) -> void:
    if dist > attack_range * 1.3:
        change_state(State.CHASE)
        return
    velocity = Vector2.ZERO
    # Damage logic would go here

func update_search(delta: float, dist: float) -> void:
    if dist < detect_range:
        change_state(State.CHASE)
        return

    search_timer -= delta
    if search_timer <= 0:
        change_state(State.PATROL)
        return

    var to_last = last_known_pos - global_position
    if to_last.length() > 8.0:
        velocity = to_last.normalized() * speed * 0.6
    else:
        velocity = Vector2.ZERO
```

```lua
-- Lua (LÖVE) — Complete guard NPC
local Guard = {}
Guard.__index = Guard

function Guard.new(x, y)
    local self = setmetatable({}, Guard)
    self.x, self.y = x, y
    self.speed = 100
    self.chase_speed = 160
    self.detect_range = 180
    self.lose_range = 270
    self.attack_range = 45
    self.search_duration = 4.0
    self.state = "patrol"
    self.patrol = {
        {x - 100, y}, {x + 100, y},
        {x + 100, y + 100}, {x - 100, y + 100},
    }
    self.patrol_index = 1
    self.search_timer = 0
    self.last_known_x, self.last_known_y = 0, 0
    self.reaction_timer = 0
    self.vx, self.vy = 0, 0
    return self
end

function Guard:change_state(new_state)
    -- Exit actions
    if self.state == "chase" or self.state == "attack" then
        self.last_known_x = player.x
        self.last_known_y = player.y
    end
    -- Enter actions
    if new_state == "chase" then
        self.reaction_timer = 0.3
    elseif new_state == "search" then
        self.search_timer = self.search_duration
    elseif new_state == "attack" then
        self.reaction_timer = 0.15
    end
    self.state = new_state
end

function Guard:dist_to(tx, ty)
    local dx, dy = tx - self.x, ty - self.y
    return math.sqrt(dx * dx + dy * dy), dx, dy
end

function Guard:move_toward(tx, ty, spd, dt)
    local dist, dx, dy = self:dist_to(tx, ty)
    if dist > 1 then
        self.x = self.x + (dx / dist) * spd * dt
        self.y = self.y + (dy / dist) * spd * dt
    end
end

function Guard:update(dt)
    if self.reaction_timer > 0 then
        self.reaction_timer = self.reaction_timer - dt
        return
    end

    local dist = self:dist_to(player.x, player.y)

    if self.state == "patrol" then
        if dist < self.detect_range then
            self:change_state("chase"); return
        end
        local t = self.patrol[self.patrol_index]
        local tdist = self:dist_to(t[1], t[2])
        if tdist < 8 then
            self.patrol_index = self.patrol_index % #self.patrol + 1
        else
            self:move_toward(t[1], t[2], self.speed, dt)
        end

    elseif self.state == "chase" then
        if dist < self.attack_range then
            self:change_state("attack"); return
        end
        if dist > self.lose_range then
            self:change_state("search"); return
        end
        self:move_toward(player.x, player.y, self.chase_speed, dt)

    elseif self.state == "attack" then
        if dist > self.attack_range * 1.3 then
            self:change_state("chase"); return
        end

    elseif self.state == "search" then
        if dist < self.detect_range then
            self:change_state("chase"); return
        end
        self.search_timer = self.search_timer - dt
        if self.search_timer <= 0 then
            self:change_state("patrol"); return
        end
        local sdist = self:dist_to(self.last_known_x, self.last_known_y)
        if sdist > 8 then
            self:move_toward(self.last_known_x, self.last_known_y, self.speed * 0.6, dt)
        end
    end
end

function Guard:draw()
    -- Draw guard
    if self.state == "patrol" then
        love.graphics.setColor(0, 0.7, 0)     -- green
    elseif self.state == "chase" then
        love.graphics.setColor(1, 0.5, 0)     -- orange
    elseif self.state == "attack" then
        love.graphics.setColor(1, 0, 0)       -- red
    elseif self.state == "search" then
        love.graphics.setColor(1, 1, 0)       -- yellow
    end
    love.graphics.circle("fill", self.x, self.y, 12)

    -- Draw state label
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.state:upper(), self.x - 20, self.y - 25)
end
```

This guard NPC has personality. The reaction delays make it feel like it's processing information. The hysteresis prevents flickering. The color-coded debug display (in the Lua version) lets you see the AI thinking in real time. And the whole thing is under 100 lines per implementation.

---

## Common Pitfalls

### 1. Forgetting to handle the "stuck" case

Your guard chases the player, the player runs behind a wall, and the guard presses into the wall forever because the chase state only knows "move toward player." Always pair FSMs with basic obstacle handling — at minimum, a timer that transitions to Search if the guard hasn't made progress toward the player in N seconds.

### 2. Transition flickering

The NPC rapidly switches between two states because it's on the boundary of a condition. The fix is hysteresis: use different thresholds for entering and exiting a state (see section 7). If you detect at 200, lose at 300.

### 3. No enter/exit actions

The NPC instantly snaps from one behavior to another with no animation, no delay, no feedback. This is functionally correct but feels robotic. Even a 0.2-second reaction delay and a simple animation cue transform the experience (see section 3).

### 4. Testing transitions in isolation

You test "Patrol → Chase" and it works. You test "Chase → Attack" and it works. But you never test "Patrol → Chase → Attack → Chase → Search → Patrol" as a complete sequence. Transitions can interact in unexpected ways — a variable set in one state's exit action might break another state's enter action. Always test the full cycle.

### 5. Building too many states before testing

You design 10 states on paper and implement all of them before testing any of them. Then nothing works and you can't tell which state is the problem. Build two states, test them, add a third, test again. Incremental development is especially important with FSMs because bugs compound across transitions.

### 6. Using string comparison for states (in typed languages)

In GDScript or C#, use enums for states, not strings. `State.CHASE` gets compile-time checking and autocomplete. `"chase"` can be misspelled as `"Chase"` or `"chse"` and you'll get silent bugs. In Lua, strings are fine — it's the idiomatic approach — but be consistent with casing.

---

## Exercises

### Exercise 1: The Five-State Guard
**Time:** 1-2 hours

Implement the guard from the state diagram in section 1 with all five states: Idle, Patrol, Chase, Attack, Search. Requirements:

1. The guard patrols between at least 3 waypoints
2. Detecting the player triggers Chase (with a visible reaction — a pause or animation)
3. Getting within attack range triggers Attack
4. Losing the player triggers Search (move to last known position)
5. Search timeout returns to Patrol
6. Add a debug display showing the current state name above the guard

**Concepts practiced:** FSM implementation, enter/exit actions, state transitions

**Stretch goal:** Add hysteresis to all transitions. Add a sixth state — "Alert" — that triggers when the player is at the edge of detection range (a "suspicious" state that transitions to Chase if the player stays visible and back to Patrol if they hide).

---

### Exercise 2: Multiple Personality Guards
**Time:** 1.5-2 hours

Create three guards that share the same FSM code but have different parameters, producing distinct personalities:

1. **Aggressive guard:** Large detect range, small lose range, fast chase speed, short search time (gives up quickly but detects easily)
2. **Cautious guard:** Small detect range, large lose range, slow chase speed, long search time (hard to trigger but persistent once alerted)
3. **Jumpy guard:** Medium detect range, very large lose range, very fast chase speed, very long search time, but with a random chance each frame to transition from Search back to Patrol early ("lost it... wait, no... okay, lost it for real")

Run all three simultaneously and observe how different they feel despite sharing the same code.

**Concepts practiced:** Parameter-driven personality, FSM tuning, the "fun over correctness" principle

**Stretch goal:** Add a "fear" parameter that makes the guard flee instead of chase when health is below a threshold. The aggressive guard never flees. The cautious guard flees at 40% health. The jumpy guard flees at 70%.

---

### Exercise 3: Pac-Man Ghost FSM
**Time:** 2-3 hours

Implement one Pac-Man ghost with three states: Scatter, Chase, and Frightened.

1. **Scatter:** Move toward a fixed corner of the screen
2. **Chase:** Move toward the player (simple direct pursuit for now)
3. **Frightened:** Move in a random direction, change direction every 1-2 seconds
4. Scatter and Chase alternate on a timer (7 seconds Scatter, 20 seconds Chase, repeat)
5. Collecting a "power pellet" (press a key to simulate) transitions to Frightened for 8 seconds
6. The ghost should visually change color per state (blue when frightened, etc.)

**Concepts practiced:** Timer-based transitions, event-based transitions, visual state communication

**Stretch goal:** Add the Pac-Man targeting rule for Blinky (red ghost): in Chase mode, target the player's current position. Then add Pinky's rule: target 4 tiles *ahead* of the player's current direction. Notice how the same FSM with different targeting logic creates different "personalities."

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| *Game Programming Patterns*, "State" chapter | Book (free) | The definitive readable explanation of FSMs in games, with clean code examples and the progression from if/else to State pattern |
| "Finite-State Machines: Theory and Implementation" from *Game AI Pro* | Book chapter (free) | Covers practical FSM pitfalls, hierarchical FSMs, and production concerns |
| Red Blob Games — search for state machine content | Interactive guides | Amit Patel's visual approach makes abstract FSM concepts tangible |
| "The Pac-Man Dossier" by Jamey Pittman | Article | Deep reverse-engineering of Pac-Man ghost AI — the best FSM case study ever written |
| *Programming Game AI by Example* by Mat Buckland, Chapter 2 | Book | Thorough FSM treatment with C++ examples and a focus on game applications |

---

## Key Takeaways

1. **An FSM means: one state at a time, transitions triggered by conditions.** The NPC is always in exactly one state. Conditions cause transitions. Enter/exit actions fire on transitions. That's the whole pattern.

2. **Draw the state diagram before you code.** Paper and pen. Every state as a circle, every transition as a labeled arrow. This takes 5 minutes and prevents hours of debugging.

3. **Enter and exit actions are what make FSMs feel alive.** The transition moments — reaction delays, alert animations, sound cues — are where players notice the AI the most. Don't skip them.

4. **Hysteresis prevents flickering.** Use wider thresholds for exiting a state than for entering it. If you detect at 200, lose at 300.

5. **State explosion is the signal to upgrade.** An FSM with 5-7 states is clean. An FSM with 15+ states is spaghetti. When you hit the wall, look at behavior trees (Module 2) or utility AI (Module 5).

6. **FSMs are not a beginner tool you graduate from.** They're a professional tool you use forever. Many shipped games run entirely on FSMs. Master them before moving on.

---

## What's Next?

You now have the fundamental building block of game AI. Every enemy, NPC, and boss you build from here will either be an FSM or something that evolved from the FSM concept.

In [Module 2: Behavior Trees](module-02-behavior-trees.md), you'll learn the industry-standard solution to the state explosion problem. Behavior trees replace the flat web of states and transitions with a composable tree structure — small, reusable behaviors combined with Sequence and Selector nodes. You'll redesign the guard NPC as a behavior tree and see how adding new behaviors becomes a matter of inserting a branch rather than rewiring a diagram.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
