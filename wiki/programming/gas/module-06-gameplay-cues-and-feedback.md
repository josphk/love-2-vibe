# Module 6: Gameplay Cues & Feedback

**Part of:** [GAS Learning Roadmap](gas-learning-roadmap.md)
**Estimated study time:** 3–4 hours
**Prerequisites:** [Module 3: Gameplay Effects](module-03-gameplay-effects.md), [Module 4: Gameplay Abilities](module-04-gameplay-abilities.md)

---

## Overview

Your ability system works. Effects apply, attributes change, tags get granted and revoked. But the player sees nothing — no particles, no sound, no screen shake. You need feedback. The question is: where does the feedback code go?

The wrong answer is inside the effect or ability code. If your "apply fire damage" function also spawns flame particles, plays a burning sound, and shakes the camera, you've coupled gameplay logic to presentation. That coupling hurts in predictable ways: you can't reuse fire damage logic without the visuals, you can't change the visuals without touching gameplay code, and in a networked game the server runs gameplay logic but should never spawn particles.

**Gameplay cues** are the solution. A cue is an event that says "something visually interesting happened" without specifying what the visual response should be. The gameplay code emits cues. Separate handlers respond to cues with visuals and audio. Neither side knows about the other. This module builds that decoupled feedback layer.

By the end of this module you'll have a cue system that automatically triggers visual and audio feedback when effects apply, abilities activate, and tags change — without any coupling between gameplay logic and presentation.

---

## 1. Why Decouple Feedback?

Consider this code:

```
function apply_fire_damage(target, amount):
    target.health -= amount
    target.tags:add("Status.Burning")
    spawn_particles("fire_burst", target.position)
    play_sound("fire_hit.wav")
    camera_shake(0.2)
    show_damage_number(target.position, amount, "red")
```

This function does two things: gameplay logic and presentation. They're tangled together. Problems:

**Reuse breaks.** A poison effect that ticks fire damage (a fire-themed DoT) calls the same function. Now you get fire particles every tick. You want different particles for poison-fire vs. direct fire, but the visuals are hardcoded into the damage function.

**Testing breaks.** Unit testing `apply_fire_damage` requires mocking the particle system, sound system, and camera. The gameplay logic is simple — `health -= amount` — but the test setup is complex because of the coupled visuals.

**Networking breaks.** In multiplayer, the server applies damage. The server should never call `spawn_particles` or `play_sound` — those run on clients. With coupled code, you need `if is_server then skip visuals` checks everywhere.

**Iteration breaks.** The designer wants to change the fire damage VFX. They have to find every function that deals fire damage and modify the particle calls. If they miss one, inconsistency.

The decoupled version:

```
function apply_fire_damage(target, amount):
    target.health -= amount
    target.tags:add("Status.Burning")
    emit_cue("GameplayCue.Damage.Fire", {target = target, magnitude = amount})
```

The gameplay function emits a cue — a declaration that something happened. Somewhere else, a handler is registered:

```
register_cue_handler("GameplayCue.Damage.Fire", function(params):
    spawn_particles("fire_burst", params.target.position)
    play_sound("fire_hit.wav")
    camera_shake(0.2 * params.magnitude / 50)
    show_damage_number(params.target.position, params.magnitude, "red")
)
```

Now the gameplay function doesn't know about visuals. The visual handler doesn't know about gameplay. Either can change independently. Testing gameplay skips cues. The server skips the handler registration. The designer modifies one handler to change all fire damage visuals.

---

## 2. Burst vs. Looping Cues

Cues come in two flavors, matching the two modes of game feedback:

**Burst cues** fire once. They represent a moment: damage dealt, an ability activated, a critical hit. They trigger one-shot responses — a particle burst, a sound effect, a screen flash. Burst cues have no duration; they fire and they're done.

**Looping cues** run for a duration. They represent ongoing states: burning, frozen, channeling, shielded. They trigger persistent responses — a looping particle effect, a continuous sound, a glowing overlay. Looping cues have a start and an end — they fire when the state begins and stop when it ends.

The distinction maps directly to effects:

| Effect Type | Cue Type | Example |
|------------|----------|---------|
| Instant effect | Burst | Damage number, hit flash |
| Duration effect start | Looping start | Burning VFX begins |
| Duration effect end | Looping end | Burning VFX stops |
| Periodic tick | Burst | DoT damage number per tick |
| Ability activation | Burst | Cast sound, muzzle flash |
| Channel start | Looping start | Channeling beam VFX |
| Channel end | Looping end | Beam disappears |

**Pseudocode:**
```
CueType:
    BURST       // fire once
    LOOP_START  // begin looping effect
    LOOP_END    // end looping effect
```

When a duration effect applies, it emits two cues over its lifetime:
1. `LOOP_START` when the effect is applied → handler starts a looping particle/sound
2. `LOOP_END` when the effect expires or is removed → handler stops the particle/sound

The looping handler needs to track the active visual so it can stop it later. More on this in section 5.

---

## 3. The Cue Manager

The cue system has two sides: **emitting** (gameplay code sends cues) and **handling** (presentation code responds to cues). The **CueManager** connects them.

**Pseudocode:**
```
CueManager:
    handlers: map<string, list<function>>    // cue_tag → handler functions

    function register(cue_tag, handler_fn):
        if cue_tag not in handlers:
            handlers[cue_tag] = []
        handlers[cue_tag].add(handler_fn)

    function emit(cue_tag, cue_type, params):
        // Direct match: "GameplayCue.Damage.Fire"
        if cue_tag in handlers:
            for each handler in handlers[cue_tag]:
                handler(cue_type, params)

        // Hierarchical match: also fire handlers for parent tags
        // "GameplayCue.Damage.Fire" also triggers "GameplayCue.Damage" handlers
        parent = get_parent_tag(cue_tag)
        while parent is not nil:
            if parent in handlers:
                for each handler in handlers[parent]:
                    handler(cue_type, params)
            parent = get_parent_tag(parent)
```

The hierarchical matching is important. You can register a handler for `GameplayCue.Damage` that responds to *all* damage types (fire, ice, physical). Or register for the specific `GameplayCue.Damage.Fire` for fire-specific visuals. Both can coexist — a fire damage event triggers both the generic damage handler (shows damage number) and the specific fire handler (spawns fire particles).

**Lua:**
```lua
local CueManager = {}
CueManager.__index = CueManager

function CueManager.new()
    return setmetatable({
        handlers = {},
    }, CueManager)
end

function CueManager:register(cue_tag, handler_fn)
    if not self.handlers[cue_tag] then
        self.handlers[cue_tag] = {}
    end
    table.insert(self.handlers[cue_tag], handler_fn)
end

function CueManager:unregister(cue_tag, handler_fn)
    local list = self.handlers[cue_tag]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == handler_fn then
            table.remove(list, i)
        end
    end
end

function CueManager:emit(cue_tag, cue_type, params)
    -- Fire handlers for this exact tag
    self:_fire_handlers(cue_tag, cue_type, params)

    -- Walk up the hierarchy
    local parent = self:_parent_tag(cue_tag)
    while parent do
        self:_fire_handlers(parent, cue_type, params)
        parent = self:_parent_tag(parent)
    end
end

function CueManager:_fire_handlers(tag, cue_type, params)
    local list = self.handlers[tag]
    if not list then return end
    for _, handler in ipairs(list) do
        handler(cue_type, params)
    end
end

function CueManager:_parent_tag(tag)
    local last_dot = tag:match(".*()%.")
    if last_dot then
        return tag:sub(1, last_dot - 1)
    end
    return nil
end
```

**GDScript:**
```gdscript
class_name CueManager

var handlers: Dictionary = {}    # tag -> Array[Callable]

func register(cue_tag: String, handler_fn: Callable) -> void:
    if not handlers.has(cue_tag):
        handlers[cue_tag] = []
    handlers[cue_tag].append(handler_fn)

func unregister(cue_tag: String, handler_fn: Callable) -> void:
    if handlers.has(cue_tag):
        handlers[cue_tag].erase(handler_fn)

func emit(cue_tag: String, cue_type: int, params: Dictionary) -> void:
    _fire_handlers(cue_tag, cue_type, params)

    # Walk up the hierarchy
    var parent := _parent_tag(cue_tag)
    while parent != "":
        _fire_handlers(parent, cue_type, params)
        parent = _parent_tag(parent)

func _fire_handlers(tag: String, cue_type: int, params: Dictionary) -> void:
    if not handlers.has(tag):
        return
    for handler in handlers[tag]:
        handler.call(cue_type, params)

func _parent_tag(tag: String) -> String:
    var idx := tag.rfind(".")
    if idx >= 0:
        return tag.substr(0, idx)
    return ""
```

---

## 4. Cue Parameters

Cues carry data that handlers use to scale their response. A damage cue carries the damage amount so the particle handler can spawn more particles for bigger hits. A status cue carries the target entity so the VFX attaches to the right character.

**Standard cue parameters:**

```
CueParams:
    source: Entity           // who caused this (caster)
    target: Entity           // who it happened to
    magnitude: number        // how much (damage, healing, etc.)
    position: Vector2/3      // where in the world
    direction: Vector2/3     // directional effects (knockback direction)
    effect_id: string        // which effect triggered this
    tags: list<string>       // any additional context tags
```

Not every parameter is relevant for every cue. Handlers use what they need and ignore the rest. A damage number handler uses `magnitude` and `position`. A directional blood splatter handler uses `position` and `direction`. A generic hit sound handler only needs the cue tag itself.

**Scaling feedback with magnitude:**

Good game feel scales visual intensity with gameplay magnitude. A 10-damage hit gets small particles and a quiet sound. A 100-damage critical gets a particle explosion, screen shake, and a loud impact. The cue system makes this natural:

```
register_handler("GameplayCue.Damage", function(cue_type, params):
    // Scale particles with damage
    particle_count = math.ceil(params.magnitude / 10)
    spawn_particles("hit_burst", params.target.position, {count = particle_count})

    // Scale screen shake with damage
    shake_intensity = params.magnitude / 200    // 0.05 for 10 dmg, 0.5 for 100 dmg
    camera_shake(shake_intensity)

    // Scale sound volume
    volume = math.min(0.3 + params.magnitude / 150, 1.0)
    play_sound("hit.wav", {volume = volume})
)
```

**Lua:**
```lua
cue_manager:register("GameplayCue.Damage", function(cue_type, params)
    local count = math.ceil((params.magnitude or 10) / 10)
    spawn_particles("hit_burst", params.target.x, params.target.y, count)

    local shake = (params.magnitude or 10) / 200
    camera:shake(shake)

    local vol = math.min(0.3 + (params.magnitude or 10) / 150, 1.0)
    play_sound("hit", vol)
end)

-- Specific handler for fire damage — adds fire-specific visuals ON TOP of generic damage
cue_manager:register("GameplayCue.Damage.Fire", function(cue_type, params)
    spawn_particles("fire_burst", params.target.x, params.target.y, 8)
    play_sound("fire_whoosh", 0.6)
end)
```

**GDScript:**
```gdscript
cue_manager.register("GameplayCue.Damage", func(cue_type: int, params: Dictionary):
    var count := ceili(params.get("magnitude", 10) / 10.0)
    spawn_particles("hit_burst", params.target.global_position, count)

    var shake := params.get("magnitude", 10) / 200.0
    camera.shake(shake)

    var vol := minf(0.3 + params.get("magnitude", 10) / 150.0, 1.0)
    play_sound("hit", vol)
)

cue_manager.register("GameplayCue.Damage.Fire", func(cue_type: int, params: Dictionary):
    spawn_particles("fire_burst", params.target.global_position, 8)
    play_sound("fire_whoosh", 0.6)
)
```

Because `GameplayCue.Damage.Fire` matches both the specific fire handler and the generic `GameplayCue.Damage` handler (via hierarchy), a fire hit plays both the generic hit effect and the fire-specific effect. Layered feedback from composition.

---

## 5. Looping Cue Lifecycle

Looping cues are more complex than burst cues because they have state — the visual effect needs to exist for the duration of the gameplay state, then clean up when it ends.

The lifecycle:
1. An effect applies that grants `Status.Burning` → emit `GameplayCue.Status.Burning`, type `LOOP_START`
2. Handler creates a persistent visual: fire particles attached to the entity, looping burn sound
3. Time passes... the visual stays active
4. The burn effect expires → emit `GameplayCue.Status.Burning`, type `LOOP_END`
5. Handler destroys the persistent visual: particles stop, sound fades out

The handler needs to track active visuals so it can stop them:

**Pseudocode:**
```
LoopingCueHandler:
    active_visuals: map<string, {particle, sound}>    // keyed by "tag:entity_id"

    function handle(cue_type, params):
        key = params.cue_tag .. ":" .. params.target.id

        if cue_type == LOOP_START:
            // Create visuals
            particle = create_looping_particles("burning", params.target.position)
            sound = play_looping_sound("fire_loop.wav", params.target.position)
            active_visuals[key] = {particle = particle, sound = sound}

        elif cue_type == LOOP_END:
            // Destroy visuals
            visual = active_visuals[key]
            if visual:
                visual.particle:stop()
                visual.sound:stop()
                active_visuals[key] = nil
```

**Lua:**
```lua
local LoopingCueTracker = {}
LoopingCueTracker.__index = LoopingCueTracker

function LoopingCueTracker.new()
    return setmetatable({
        active = {},    -- key -> {particle, sound, ...}
    }, LoopingCueTracker)
end

function LoopingCueTracker:make_key(cue_tag, target)
    return cue_tag .. ":" .. tostring(target.id)
end

function LoopingCueTracker:start(cue_tag, target, visuals)
    local key = self:make_key(cue_tag, target)
    -- Stop existing if any (prevents duplicates)
    self:stop(cue_tag, target)
    self.active[key] = visuals
end

function LoopingCueTracker:stop(cue_tag, target)
    local key = self:make_key(cue_tag, target)
    local visuals = self.active[key]
    if visuals then
        if visuals.particle then visuals.particle:stop() end
        if visuals.sound then visuals.sound:stop() end
        self.active[key] = nil
    end
end

-- Usage: register a handler that uses the tracker
local loop_tracker = LoopingCueTracker.new()

cue_manager:register("GameplayCue.Status.Burning", function(cue_type, params)
    if cue_type == "loop_start" then
        local particle = create_fire_particles(params.target)
        local sound = play_looping_sound("fire_loop")
        loop_tracker:start("GameplayCue.Status.Burning", params.target, {
            particle = particle,
            sound = sound,
        })
    elseif cue_type == "loop_end" then
        loop_tracker:stop("GameplayCue.Status.Burning", params.target)
    end
end)
```

**GDScript:**
```gdscript
class_name LoopingCueTracker

var active: Dictionary = {}    # key -> {particle: Node, sound: AudioStreamPlayer}

func make_key(cue_tag: String, target: Node) -> String:
    return cue_tag + ":" + str(target.get_instance_id())

func start(cue_tag: String, target: Node, visuals: Dictionary) -> void:
    var key := make_key(cue_tag, target)
    stop(cue_tag, target)    # prevent duplicates
    active[key] = visuals

func stop(cue_tag: String, target: Node) -> void:
    var key := make_key(cue_tag, target)
    if active.has(key):
        var visuals: Dictionary = active[key]
        if visuals.has("particle"):
            visuals.particle.queue_free()
        if visuals.has("sound"):
            visuals.sound.stop()
            visuals.sound.queue_free()
        active.erase(key)

# Usage
var loop_tracker := LoopingCueTracker.new()

func _on_burning_cue(cue_type: int, params: Dictionary) -> void:
    if cue_type == CueType.LOOP_START:
        var particle := create_fire_particles(params.target)
        var sound := play_looping_sound("fire_loop")
        loop_tracker.start("GameplayCue.Status.Burning", params.target, {
            particle = particle,
            sound = sound,
        })
    elif cue_type == CueType.LOOP_END:
        loop_tracker.stop("GameplayCue.Status.Burning", params.target)
```

---

## 6. Connecting Cues to the Effect System

Cues should fire automatically when effects apply, expire, or tick. This means the effect system (Module 3) emits cues at the right moments — the effect code doesn't know what visual response will happen, it just announces what occurred.

**Where cues get emitted:**

| Event | Cue Type | Tag Pattern |
|-------|----------|-------------|
| Instant effect applies | Burst | Effect's `cue_tag` |
| Duration effect starts | Loop Start | Effect's `cue_tag` |
| Duration effect expires | Loop End | Effect's `cue_tag` |
| Duration effect is removed early | Loop End | Effect's `cue_tag` |
| Periodic effect ticks | Burst | Effect's `periodic_cue_tag` |
| Ability activates | Burst | Ability's `cue_tag` |
| Ability ends | Burst | Ability's `end_cue_tag` |

**Modifying the effect application pipeline:**

```
function apply_effect(target, effect_def, context):
    // ... existing logic from Module 3 (requirements, stacking, etc.) ...

    // After successful application, emit cue
    if effect_def.cue_tag:
        params = {
            source = context.source,
            target = target,
            magnitude = calculate_magnitude(effect_def, context),
            position = target.position,
        }

        if effect_def.duration_type == "instant":
            cue_manager:emit(effect_def.cue_tag, BURST, params)
        else:
            cue_manager:emit(effect_def.cue_tag, LOOP_START, params)
```

**Modifying the effect expiry/removal:**

```
function remove_effect(target, active_effect):
    // ... existing removal logic (remove modifiers, remove tags) ...

    // Emit loop end cue
    if active_effect.definition.cue_tag:
        params = {target = target}
        cue_manager:emit(active_effect.definition.cue_tag, LOOP_END, params)
```

**Modifying periodic ticking:**

```
function tick_periodic_effect(target, active_effect):
    // ... existing periodic logic (apply instant modification) ...

    // Emit burst cue for the tick
    tick_cue = active_effect.definition.periodic_cue_tag or active_effect.definition.cue_tag
    if tick_cue:
        params = {
            target = target,
            magnitude = active_effect.definition.tick_magnitude,
        }
        cue_manager:emit(tick_cue, BURST, params)
```

**Lua integration:**
```lua
-- In your apply_effect function (Module 3), add at the end:
function apply_effect(target_asc, effect_def, context)
    -- ... existing application logic ...

    -- Emit cue
    if effect_def.cue_tag and cue_manager then
        local params = {
            source = context and context.source,
            target = target_asc.entity,
            magnitude = effect_def.modifiers and effect_def.modifiers[1]
                and math.abs(effect_def.modifiers[1].value) or 0,
            position = target_asc.entity and target_asc.entity.position,
        }

        if effect_def.duration_type == "instant" then
            cue_manager:emit(effect_def.cue_tag, "burst", params)
        else
            cue_manager:emit(effect_def.cue_tag, "loop_start", params)
        end
    end
end

-- In your effect expiry logic:
function expire_effect(target_asc, active_effect)
    -- ... existing removal logic ...

    if active_effect.def.cue_tag and cue_manager then
        cue_manager:emit(active_effect.def.cue_tag, "loop_end", {
            target = target_asc.entity,
        })
    end
end
```

**GDScript integration:**
```gdscript
# In your apply_effect function (Module 3), add at the end:
func apply_effect(target_asc: AbilitySystemComponent, effect_def: EffectDefinition, context: Dictionary) -> void:
    # ... existing application logic ...

    if effect_def.cue_tag and cue_manager:
        var params := {
            source = context.get("source"),
            target = target_asc.entity,
            magnitude = abs(effect_def.modifiers[0].value) if effect_def.modifiers.size() > 0 else 0,
            position = target_asc.entity.global_position,
        }

        if effect_def.duration_type == "instant":
            cue_manager.emit(effect_def.cue_tag, CueType.BURST, params)
        else:
            cue_manager.emit(effect_def.cue_tag, CueType.LOOP_START, params)

# In your effect removal logic:
func expire_effect(target_asc: AbilitySystemComponent, active_effect: ActiveEffect) -> void:
    # ... existing removal ...

    if active_effect.def.cue_tag and cue_manager:
        cue_manager.emit(active_effect.def.cue_tag, CueType.LOOP_END, {
            target = target_asc.entity,
        })
```

---

## 7. Cue Tags and the Hierarchy

Cues use the same hierarchical tag system from Module 2. This enables flexible handler registration:

```
Tag hierarchy:
GameplayCue
├── GameplayCue.Damage
│   ├── GameplayCue.Damage.Fire
│   ├── GameplayCue.Damage.Ice
│   ├── GameplayCue.Damage.Physical
│   └── GameplayCue.Damage.Poison
├── GameplayCue.Heal
├── GameplayCue.Status
│   ├── GameplayCue.Status.Burning
│   ├── GameplayCue.Status.Frozen
│   ├── GameplayCue.Status.Poisoned
│   └── GameplayCue.Status.Stunned
├── GameplayCue.Ability
│   ├── GameplayCue.Ability.Fireball
│   ├── GameplayCue.Ability.Heal
│   └── GameplayCue.Ability.Slash
└── GameplayCue.UI
    ├── GameplayCue.UI.LevelUp
    └── GameplayCue.UI.ItemPickup
```

**Handler registration strategies:**

**Generic handler at a parent level:**
```
register("GameplayCue.Damage", show_damage_number)
// Catches ALL damage types — fire, ice, physical, poison
```

**Specific handler at a leaf level:**
```
register("GameplayCue.Damage.Fire", spawn_fire_particles)
// Only fires for fire damage — ice damage doesn't trigger this
```

**Layered handlers (both register):**
```
register("GameplayCue.Damage", show_damage_number)        // all damage
register("GameplayCue.Damage.Fire", spawn_fire_particles)  // fire only
register("GameplayCue.Damage.Ice", spawn_ice_shards)        // ice only
```

When fire damage occurs: `show_damage_number` runs (generic) AND `spawn_fire_particles` runs (specific). When physical damage occurs: only `show_damage_number` runs (no specific handler). This layering is powerful — generic feedback for free, specific feedback where it matters.

**Catch-all handler:**
```
register("GameplayCue", log_all_cues)
// Catches literally everything — useful for debugging
```

---

## 8. Common Cue Patterns

### Damage Numbers

Floating numbers that show damage or healing amounts. One of the most impactful feedback elements.

```lua
cue_manager:register("GameplayCue.Damage", function(cue_type, params)
    if cue_type ~= "burst" then return end
    local color = {1, 0.2, 0.2}    -- red for damage
    local text = tostring(math.floor(params.magnitude))
    spawn_floating_text(params.position, text, color)
end)

cue_manager:register("GameplayCue.Heal", function(cue_type, params)
    if cue_type ~= "burst" then return end
    local color = {0.2, 1, 0.2}    -- green for healing
    local text = "+" .. tostring(math.floor(params.magnitude))
    spawn_floating_text(params.position, text, color)
end)
```

### Hit Stop (Frame Freeze)

A brief pause on impact. Sells the weight of a hit. Common in action games.

```lua
cue_manager:register("GameplayCue.Damage.Physical", function(cue_type, params)
    if cue_type ~= "burst" then return end
    if params.magnitude > 30 then    -- only for heavy hits
        freeze_frame(0.05)           -- 50ms freeze
    end
end)
```

### Screen Shake

Scales with magnitude. Subtle for small hits, dramatic for big ones.

```lua
cue_manager:register("GameplayCue.Damage", function(cue_type, params)
    if cue_type ~= "burst" then return end
    local intensity = math.min(params.magnitude / 100, 1.0)
    local duration = 0.1 + intensity * 0.2
    camera:shake(intensity, duration)
end)
```

### Status Effect Overlays

Tint the entity's sprite while a status is active. Uses looping cues.

```lua
cue_manager:register("GameplayCue.Status.Burning", function(cue_type, params)
    if cue_type == "loop_start" then
        params.target:set_color_tint(1.0, 0.5, 0.2, 0.3)    -- orange tint
    elseif cue_type == "loop_end" then
        params.target:clear_color_tint()
    end
end)

cue_manager:register("GameplayCue.Status.Frozen", function(cue_type, params)
    if cue_type == "loop_start" then
        params.target:set_color_tint(0.3, 0.5, 1.0, 0.3)    -- blue tint
    elseif cue_type == "loop_end" then
        params.target:clear_color_tint()
    end
end)
```

### Ability Cast Sounds

One-shot sound when an ability fires.

```lua
cue_manager:register("GameplayCue.Ability.Fireball", function(cue_type, params)
    if cue_type ~= "burst" then return end
    play_sound("fireball_cast", 0.8)
end)

cue_manager:register("GameplayCue.Ability.Heal", function(cue_type, params)
    if cue_type ~= "burst" then return end
    play_sound("heal_chime", 0.6)
end)
```

### Death Cue

A dramatic response when something dies. Registered at a single tag.

```lua
cue_manager:register("GameplayCue.Death", function(cue_type, params)
    if cue_type ~= "burst" then return end
    camera:shake(0.4, 0.3)
    freeze_frame(0.1)
    play_sound("death_impact", 1.0)
    spawn_particles("death_burst", params.target.x, params.target.y, 20)
end)
```

---

## 9. Cues in a Networked Context

This is the primary reason cues exist as a separate system. In a multiplayer game:

- **Server** runs gameplay logic: ability activation, effect application, attribute changes, tag management. The server never spawns particles or plays sounds.
- **Client** runs presentation: particles, sounds, animations, UI. The client receives cue events and plays the visual/audio response.

The data flow:

```
Server:
  1. Apply fire damage effect
  2. Modify health attribute
  3. Emit cue: GameplayCue.Damage.Fire (magnitude=40, target=enemy3)
  4. Send cue event to clients (network message)

Client:
  1. Receive cue event
  2. CueManager dispatches to handlers
  3. Handlers spawn particles, play sounds, show damage number
```

The server uses the same `emit_cue` call. But instead of local handlers, the emit is serialized and sent over the network. The client's CueManager receives it and dispatches normally.

**Why this works:** The cue is a small, serializable message: `{tag: "GameplayCue.Damage.Fire", type: "burst", params: {target_id: 3, magnitude: 40, position: {x: 120, y: 80}}}`. It's cheap to send over the network. The visual response (which might involve creating particle systems, playing spatial audio, etc.) happens locally on each client using their own assets and rendering.

You don't need to implement networking for this module. But designing the cue system as a serializable event layer means you *could* add networking later without restructuring anything. The server just routes cue events to clients instead of (or in addition to) handling them locally.

**Single-player optimization:** In single-player, the distinction between server and client doesn't exist — but the decoupling still pays off in code organization and testability. You get the architectural benefit without the networking complexity.

---

## 10. Integrating Cues Into Your Effect Definitions

The final step is adding cue tags to your existing effect definitions from Module 3. Each effect knows which cue to emit — the effect system emits it automatically at the right lifecycle moments.

**Updated effect definition (from Module 3):**

```
fire_damage_effect:
    duration_type: "instant"
    modifiers: [{attribute: "health", operation: "add", value: -40}]
    cue_tag: "GameplayCue.Damage.Fire"              // ← NEW

burn_dot_effect:
    duration_type: "duration"
    duration: 5.0
    period: 1.0
    tags_to_grant: ["Status.Burning"]
    modifiers: []
    periodic_instant: {attribute: "health", operation: "add", value: -5}
    cue_tag: "GameplayCue.Status.Burning"            // ← looping cue
    periodic_cue_tag: "GameplayCue.Damage.Fire"      // ← burst on each tick

heal_effect:
    duration_type: "instant"
    modifiers: [{attribute: "health", operation: "add", value: 30}]
    cue_tag: "GameplayCue.Heal"

attack_buff:
    duration_type: "duration"
    duration: 10.0
    modifiers: [{attribute: "attack_power", operation: "multiply", value: 1.3}]
    tags_to_grant: ["Status.AttackBuffed"]
    cue_tag: "GameplayCue.Status.AttackBuffed"
```

The cue tag is part of the effect data. Designers can change which cue an effect emits without touching code. They can reuse the same cue for multiple effects (all fire damage effects share `GameplayCue.Damage.Fire`). They can create new visual responses by registering new handlers for new cue tags.

**Lua:**
```lua
local fire_damage_effect = {
    duration_type = "instant",
    modifiers = {{attribute = "health", operation = "add", value = -40}},
    cue_tag = "GameplayCue.Damage.Fire",
}

local burn_dot_effect = {
    duration_type = "duration",
    duration = 5.0,
    period = 1.0,
    tags_to_grant = {"Status.Burning"},
    periodic_instant = {attribute = "health", operation = "add", value = -5},
    cue_tag = "GameplayCue.Status.Burning",
    periodic_cue_tag = "GameplayCue.Damage.Fire",
}
```

**GDScript:**
```gdscript
var fire_damage_effect := EffectDefinition.new()
fire_damage_effect.duration_type = "instant"
fire_damage_effect.modifiers = [{attribute = "health", operation = "add", value = -40}]
fire_damage_effect.cue_tag = "GameplayCue.Damage.Fire"

var burn_dot_effect := EffectDefinition.new()
burn_dot_effect.duration_type = "duration"
burn_dot_effect.duration = 5.0
burn_dot_effect.period = 1.0
burn_dot_effect.tags_to_grant = ["Status.Burning"]
burn_dot_effect.periodic_instant = {attribute = "health", operation = "add", value = -5}
burn_dot_effect.cue_tag = "GameplayCue.Status.Burning"
burn_dot_effect.periodic_cue_tag = "GameplayCue.Damage.Fire"
```

---

## Exercise

Build a cue system and integrate it with your existing effect/ability pipeline.

1. **CueManager** — implement `register(cue_tag, handler)`, `unregister(cue_tag, handler)`, and `emit(cue_tag, cue_type, params)`. Support hierarchical matching: emitting `GameplayCue.Damage.Fire` triggers handlers registered for both `GameplayCue.Damage.Fire` and `GameplayCue.Damage`.

2. **Connect to effects** — modify your `apply_effect` function from Module 3 to emit burst cues for instant effects and loop_start cues for duration effects. Modify your effect expiry logic to emit loop_end cues. Modify periodic ticking to emit burst cues per tick.

3. **Register handlers** — create handlers for at least:
   - `GameplayCue.Damage` → print/log damage number and amount
   - `GameplayCue.Damage.Fire` → print/log "fire particles at [position]"
   - `GameplayCue.Heal` → print/log healing amount
   - `GameplayCue.Status.Burning` → print/log "burning VFX start/stop"
   - `GameplayCue.Status.Stunned` → print/log "stun VFX start/stop"

4. **LoopingCueTracker** — implement tracking for looping cues so that loop_end correctly cleans up what loop_start created.

**Test scenario:**

Using your ability system from Module 4:
1. Mage casts Fireball on Enemy → cues fire: `GameplayCue.Damage.Fire` (burst, magnitude=40) + `GameplayCue.Status.Burning` (loop_start). Verify both the generic damage handler and the fire-specific handler trigger.
2. Burn ticks 5 times → each tick fires `GameplayCue.Damage.Fire` (burst, magnitude=5).
3. Burn expires → `GameplayCue.Status.Burning` (loop_end). Verify looping tracker cleans up.
4. Mage casts Heal on self → `GameplayCue.Heal` (burst, magnitude=30).
5. Apply stun to mage → `GameplayCue.Status.Stunned` (loop_start). Stun expires → `GameplayCue.Status.Stunned` (loop_end).
6. Register a catch-all handler on `GameplayCue` and verify it catches every cue emitted.

**Stretch goals:**
- If using Love2D: replace print/log handlers with actual particle systems and sounds. Love2D's `love.graphics.newParticleSystem` and `love.audio.newSource` work well.
- If using Godot: replace print handlers with `GPUParticles2D` nodes and `AudioStreamPlayer` nodes.
- Implement screen shake that scales with damage magnitude.
- Implement floating damage/healing numbers using the cue params.
- Add a cue history/log for debugging: store the last 50 cues with timestamps, viewable via a debug key.

---

## Read

- GASDocumentation — Gameplay Cues: https://github.com/tranek/GASDocumentation#concepts-gc — the original Unreal cue architecture. Focus on the burst/looping distinction and how cues map to effects.
- Game Programming Patterns — Observer: https://gameprogrammingpatterns.com/observer.html — cues are the Observer pattern. Effects are subjects that emit events. Handlers are observers that react. The pattern is identical.
- Game Programming Patterns — Event Queue: https://gameprogrammingpatterns.com/event-queue.html — for more complex scenarios, cues can be queued and processed in batches. Useful for networking and for controlling the order of visual responses.
- "Juice it or Lose it" GDC talk — search for Martin Jonasson & Petri Purho. The definitive talk on why feedback matters. Cues are the architectural backbone that delivers juice systematically.
- "Game Feel" by Steve Swink — the book on making games feel responsive and satisfying. Cues are how ability systems deliver game feel.

---

## Summary

Gameplay cues decouple visual/audio feedback from gameplay logic. The pattern is simple: gameplay code emits cue events, presentation code handles them. Neither side knows about the other.

Burst cues fire once for instant events (damage dealt, ability cast). Looping cues track duration states (burning, channeling, buffed) with start and end events. The cue tag hierarchy enables both generic handlers (all damage → damage number) and specific handlers (fire damage → fire particles) to coexist.

The CueManager is a small system — register, emit, match. But it pays dividends in code organization, testability, networking readiness, and designer iteration speed. Effects define which cues to emit. Handlers define the response. Changing visuals never requires touching gameplay code.

**Next up:** [Module 7: Building an Ability System](module-07-building-an-ability-system.md) — the capstone module that integrates every layer into a working game prototype.
