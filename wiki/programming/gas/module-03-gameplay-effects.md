# Module 3: Gameplay Effects

**Part of:** [GAS Learning Roadmap](gas-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 1: Attributes & Modifier Stacking](module-01-attributes-and-modifier-stacking.md), [Module 2: Gameplay Tags](module-02-gameplay-tags.md)

---

## Overview

Effects are where the system starts to feel magical. A **gameplay effect** is a data-driven description of *what happens* — not code, but data. "Modify `health` by -20." "Grant tag `Status.Burning` for 5 seconds." "Increase `attack_power` by 15% for 10 seconds." Each effect is a bundle of attribute modifiers, tag changes, and metadata like duration and stacking rules. You define them as data. You apply them to entities. The system handles the rest.

This module ties together everything from Modules 1 and 2. Effects create modifiers on attributes (Module 1) and grant/remove tags (Module 2). The effect system manages duration, periodic ticking, stacking, and application requirements — all data-driven, all going through the same pipeline.

By the end of this module you'll have a working effect system that can represent damage, healing, buffs, debuffs, damage-over-time, and immunity — all from data definitions, with no special-case code per effect.

---

## 1. Effect Duration Types

Every effect falls into one of three duration categories. This is the most important classification in the system:

**Instant** — Applies once and is done. A fireball dealing 40 damage. A potion healing 50 HP. There is no duration to track. Instant effects modify the **base value** of attributes directly because there's nothing to undo when they expire (they don't expire — they're already done). Instant effects don't create modifiers in the pipeline; they just adjust the number.

**Duration** — Lasts for a set time, then automatically expires. A 10-second attack buff. A 5-second poison. Duration effects apply **modifiers** to attributes (not base values) and grant tags. When the timer runs out, the effect removes its modifiers and tags. The attribute system recalculates, and the entity returns to its pre-effect state.

**Infinite** — Lasts until explicitly removed. An equipment stat bonus. A permanent curse. A passive aura. Infinite effects work exactly like duration effects (modifiers + tags) but have no automatic expiry timer. They persist until code removes them — usually when equipment is unequipped, a cleanse is applied, or a specific game event fires.

**Why the distinction matters:**

Instant effects are simple — fire and forget. You don't track them. Duration and infinite effects are *active* — they're sitting on the entity, contributing modifiers and tags, and need lifecycle management (tracking, stacking, expiry, removal). The effect system's complexity is almost entirely in managing active effects.

**Pseudocode:**
```
EffectDefinition:
    id: string
    duration_type: "instant" | "duration" | "infinite"
    duration: number           // seconds, only for "duration" type
    modifiers: list            // attribute modifications
    tags_to_grant: list        // tags to add to target
    tags_to_remove: list       // tags to remove from target
    requirements: TagRequirement  // must pass for effect to apply
    stacking_policy: string    // how multiple instances interact
    period: number             // for periodic effects (seconds between ticks)
    cue_tag: string            // gameplay cue to emit (Module 6)
```

---

## 2. The Effect Definition

An effect definition is pure data. It describes what the effect does, not how to do it — the system handles execution. Here's the structure with examples:

**Lua:**
```lua
-- Instant damage effect
local FireDamage = {
    id = "effect.fire_damage",
    duration_type = "instant",
    modifiers = {
        { attribute = "health", operation = "add", value = -40 }
    },
    tags_to_grant = {},
    tags_to_remove = {},
    requirements = TagRequirement.new(
        {},                                          -- no require tags
        { "Immune.Damage.Fire", "Immune.Damage.All" } -- block tags
    ),
    stacking_policy = "none",
    cue_tag = "GameplayCue.Damage.Fire",
}

-- Instant healing effect
local SmallHeal = {
    id = "effect.small_heal",
    duration_type = "instant",
    modifiers = {
        { attribute = "health", operation = "add", value = 30 }
    },
    tags_to_grant = {},
    tags_to_remove = {},
    requirements = TagRequirement.new(
        { "State.Alive" },     -- must be alive
        { "Status.Cursed" }    -- curse blocks healing
    ),
    stacking_policy = "none",
    cue_tag = "GameplayCue.Heal",
}

-- Duration buff: +25% attack power for 10 seconds
local BattleCry = {
    id = "effect.battle_cry",
    duration_type = "duration",
    duration = 10.0,
    modifiers = {
        { attribute = "attack_power", operation = "multiply", value = 1.25 }
    },
    tags_to_grant = { "Status.Empowered" },
    tags_to_remove = {},
    requirements = TagRequirement.new({ "State.Alive" }, {}),
    stacking_policy = "refresh_duration",
    cue_tag = "GameplayCue.Buff.BattleCry",
}

-- Duration DOT: 5 damage every 1 second for 8 seconds
local Poison = {
    id = "effect.poison",
    duration_type = "duration",
    duration = 8.0,
    period = 1.0,
    modifiers = {},   -- no persistent modifiers
    periodic_modifiers = {
        { attribute = "health", operation = "add", value = -5 }
    },
    tags_to_grant = { "Status.Poisoned" },
    tags_to_remove = {},
    requirements = TagRequirement.new({}, { "Immune.Status.Poison" }),
    stacking_policy = "stack_with_cap",
    max_stacks = 5,
    cue_tag = "GameplayCue.Status.Poisoned",
}

-- Infinite effect: equipment stat bonus
local IronSwordBonus = {
    id = "effect.iron_sword",
    duration_type = "infinite",
    modifiers = {
        { attribute = "attack_power", operation = "add", value = 10 }
    },
    tags_to_grant = {},
    tags_to_remove = {},
    requirements = TagRequirement.new({}, {}),
    stacking_policy = "none",
}
```

**GDScript:**
```gdscript
# Effect definitions as resources or dictionaries

var fire_damage := {
    "id": "effect.fire_damage",
    "duration_type": "instant",
    "modifiers": [
        {"attribute": "health", "operation": "add", "value": -40.0}
    ],
    "tags_to_grant": [],
    "tags_to_remove": [],
    "requirements": TagRequirement.new([], ["Immune.Damage.Fire", "Immune.Damage.All"]),
    "stacking_policy": "none",
    "cue_tag": "GameplayCue.Damage.Fire",
}

var battle_cry := {
    "id": "effect.battle_cry",
    "duration_type": "duration",
    "duration": 10.0,
    "modifiers": [
        {"attribute": "attack_power", "operation": "multiply", "value": 1.25}
    ],
    "tags_to_grant": ["Status.Empowered"],
    "tags_to_remove": [],
    "requirements": TagRequirement.new(["State.Alive"], []),
    "stacking_policy": "refresh_duration",
    "cue_tag": "GameplayCue.Buff.BattleCry",
}

var poison := {
    "id": "effect.poison",
    "duration_type": "duration",
    "duration": 8.0,
    "period": 1.0,
    "modifiers": [],
    "periodic_modifiers": [
        {"attribute": "health", "operation": "add", "value": -5.0}
    ],
    "tags_to_grant": ["Status.Poisoned"],
    "tags_to_remove": [],
    "requirements": TagRequirement.new([], ["Immune.Status.Poison"]),
    "stacking_policy": "stack_with_cap",
    "max_stacks": 5,
    "cue_tag": "GameplayCue.Status.Poisoned",
}
```

Notice how every effect, from simple damage to complex DOTs to equipment bonuses, uses the same structure. The variety comes from data, not from different code paths.

---

## 3. Active Effects and Lifecycle

When an effect definition is applied to a target, it creates an **active effect** — a runtime instance that tracks duration, ticking, and the modifiers/tags it's contributing. Active effects are what the system manages frame-to-frame.

**Pseudocode:**
```
ActiveEffect:
    definition: EffectDefinition   // the template
    source_id: string              // unique instance ID
    source_context: table          // who applied it, with what stats
    remaining_duration: number     // seconds remaining (-1 for infinite)
    period_timer: number           // time until next periodic tick
    stack_count: number            // current stacks (for stacking effects)
    is_active: boolean
```

**Lua:**
```lua
local active_effect_counter = 0

local function ActiveEffect(definition, context)
    active_effect_counter = active_effect_counter + 1
    local source_id = definition.id .. "." .. active_effect_counter

    return {
        definition = definition,
        source_id = source_id,
        context = context or {},
        remaining_duration = definition.duration or -1,
        period_timer = definition.period or 0,
        stack_count = 1,
        is_active = true,
    }
end
```

**GDScript:**
```gdscript
class ActiveEffect:
    var definition: Dictionary
    var source_id: String
    var context: Dictionary
    var remaining_duration: float
    var period_timer: float
    var stack_count: int
    var is_active: bool

    static var counter: int = 0

    func _init(p_def: Dictionary, p_context: Dictionary = {}):
        counter += 1
        definition = p_def
        source_id = p_def["id"] + "." + str(counter)
        context = p_context
        remaining_duration = p_def.get("duration", -1.0)
        period_timer = p_def.get("period", 0.0)
        stack_count = 1
        is_active = true
```

---

## 4. Applying Effects

The `apply_effect` function is the workhorse. It checks requirements, handles stacking, and then either modifies base values (instant) or installs modifiers and tags (duration/infinite).

**Lua:**
```lua
local function apply_effect(target, effect_def, context)
    -- Step 1: Check application requirements
    if effect_def.requirements then
        if not effect_def.requirements:check(target.tags) then
            -- Requirements not met — effect rejected
            return false, "requirements_failed"
        end
    end

    -- Step 2: Handle by duration type
    if effect_def.duration_type == "instant" then
        return apply_instant_effect(target, effect_def, context)
    else
        return apply_duration_effect(target, effect_def, context)
    end
end

local function apply_instant_effect(target, effect_def, context)
    -- Instant effects modify base values directly
    for _, mod_def in ipairs(effect_def.modifiers or {}) do
        local attr = target.attributes.get(mod_def.attribute)
        if attr then
            if mod_def.operation == "add" then
                attr.base_value = attr.base_value + mod_def.value
            elseif mod_def.operation == "multiply" then
                attr.base_value = attr.base_value * mod_def.value
            elseif mod_def.operation == "override" then
                attr.base_value = mod_def.value
            end
            recalculate(attr)
        end
    end

    -- Grant/remove tags (usually not needed for instant, but supported)
    for _, tag in ipairs(effect_def.tags_to_grant or {}) do
        target.tags:add(tag)
    end
    for _, tag in ipairs(effect_def.tags_to_remove or {}) do
        target.tags:remove(tag)
    end

    -- Emit cue
    if effect_def.cue_tag then
        emit_cue(effect_def.cue_tag, {
            target = target,
            effect = effect_def,
            context = context,
        })
    end

    return true, "applied"
end

local function apply_duration_effect(target, effect_def, context)
    -- Step 2a: Handle stacking
    local policy = effect_def.stacking_policy or "none"
    local existing = find_active_effect(target, effect_def.id)

    if existing and policy == "none" then
        return false, "already_active"

    elseif existing and policy == "refresh_duration" then
        existing.remaining_duration = effect_def.duration or -1
        return true, "refreshed"

    elseif existing and policy == "stack_with_cap" then
        local max_stacks = effect_def.max_stacks or 1
        if existing.stack_count >= max_stacks then
            -- At cap — just refresh duration
            existing.remaining_duration = effect_def.duration or -1
            return true, "stack_capped_refreshed"
        end
        -- Add a stack
        existing.stack_count = existing.stack_count + 1
        existing.remaining_duration = effect_def.duration or -1
        -- Add another set of modifiers for the new stack
        install_modifiers(target, effect_def, existing.source_id .. "." .. existing.stack_count)
        return true, "stacked"
    end

    -- New effect instance (policy is "none" with no existing, or "stack_additive")
    local active = ActiveEffect(effect_def, context)

    -- Install attribute modifiers
    install_modifiers(target, effect_def, active.source_id)

    -- Grant tags
    for _, tag in ipairs(effect_def.tags_to_grant or {}) do
        target.tags:add(tag)
    end

    -- Remove tags
    for _, tag in ipairs(effect_def.tags_to_remove or {}) do
        target.tags:remove(tag)
    end

    -- Track the active effect
    table.insert(target.active_effects, active)

    -- Emit cue (start)
    if effect_def.cue_tag then
        emit_cue(effect_def.cue_tag .. ".Start", {
            target = target,
            effect = effect_def,
            context = context,
        })
    end

    return true, "applied"
end

local function install_modifiers(target, effect_def, source_id)
    for _, mod_def in ipairs(effect_def.modifiers or {}) do
        local attr = target.attributes.get(mod_def.attribute)
        if attr then
            add_modifier(attr, Modifier(mod_def.operation, mod_def.value, source_id))
        end
    end
end

local function find_active_effect(target, effect_id)
    for _, active in ipairs(target.active_effects) do
        if active.definition.id == effect_id and active.is_active then
            return active
        end
    end
    return nil
end
```

**GDScript:**
```gdscript
func apply_effect(target: Node, effect_def: Dictionary, context: Dictionary = {}) -> Array:
    # Check requirements
    var req = effect_def.get("requirements")
    if req and not req.check(target.tags):
        return [false, "requirements_failed"]

    if effect_def["duration_type"] == "instant":
        return apply_instant_effect(target, effect_def, context)
    else:
        return apply_duration_effect(target, effect_def, context)

func apply_instant_effect(target: Node, effect_def: Dictionary, context: Dictionary) -> Array:
    for mod_def in effect_def.get("modifiers", []):
        var attr = target.attributes.get_attribute(mod_def["attribute"])
        if attr:
            match mod_def["operation"]:
                "add":
                    attr.base_value += mod_def["value"]
                "multiply":
                    attr.base_value *= mod_def["value"]
                "override":
                    attr.base_value = mod_def["value"]
            recalculate(attr)

    for tag in effect_def.get("tags_to_grant", []):
        target.tags.add(tag)
    for tag in effect_def.get("tags_to_remove", []):
        target.tags.remove(tag)

    return [true, "applied"]

func apply_duration_effect(target: Node, effect_def: Dictionary, context: Dictionary) -> Array:
    var policy = effect_def.get("stacking_policy", "none")
    var existing = find_active_effect(target, effect_def["id"])

    if existing and policy == "none":
        return [false, "already_active"]
    elif existing and policy == "refresh_duration":
        existing.remaining_duration = effect_def.get("duration", -1.0)
        return [true, "refreshed"]

    # New instance
    var active = ActiveEffect.new(effect_def, context)
    install_modifiers(target, effect_def, active.source_id)

    for tag in effect_def.get("tags_to_grant", []):
        target.tags.add(tag)

    target.active_effects.append(active)
    return [true, "applied"]
```

---

## 5. Updating Active Effects (Duration and Periodic Ticking)

Active effects need to be updated each frame. Duration effects count down their timer. Periodic effects tick when their period elapses. Expired effects are cleaned up.

**Lua:**
```lua
local function update_effects(target, dt)
    local expired = {}

    for _, active in ipairs(target.active_effects) do
        if not active.is_active then
            goto continue
        end

        local def = active.definition

        -- Update periodic timer
        if def.period and def.period > 0 then
            active.period_timer = active.period_timer - dt
            while active.period_timer <= 0 do
                -- Tick! Apply periodic effect
                apply_periodic_tick(target, active)
                active.period_timer = active.period_timer + def.period
            end
        end

        -- Update duration
        if active.remaining_duration > 0 then
            active.remaining_duration = active.remaining_duration - dt
            if active.remaining_duration <= 0 then
                table.insert(expired, active)
            end
        end
        -- remaining_duration == -1 means infinite, skip

        ::continue::
    end

    -- Remove expired effects
    for _, active in ipairs(expired) do
        remove_active_effect(target, active)
    end
end

local function apply_periodic_tick(target, active)
    local def = active.definition
    -- Periodic ticks are instant applications on the attribute's base value
    for _, mod_def in ipairs(def.periodic_modifiers or {}) do
        local attr = target.attributes.get(mod_def.attribute)
        if attr then
            if mod_def.operation == "add" then
                attr.base_value = attr.base_value + mod_def.value
            elseif mod_def.operation == "multiply" then
                attr.base_value = attr.base_value * mod_def.value
            end
            recalculate(attr)
        end
    end

    -- Emit periodic cue
    if def.cue_tag then
        emit_cue(def.cue_tag .. ".Tick", {
            target = target,
            effect = def,
        })
    end
end

local function remove_active_effect(target, active)
    local def = active.definition

    -- Remove attribute modifiers installed by this effect
    for _, mod_def in ipairs(def.modifiers or {}) do
        local attr = target.attributes.get(mod_def.attribute)
        if attr then
            remove_modifiers_by_source(attr, active.source_id)
            -- Also remove stacked modifier sources
            for i = 1, active.stack_count do
                remove_modifiers_by_source(attr, active.source_id .. "." .. i)
            end
        end
    end

    -- Remove granted tags
    for _, tag in ipairs(def.tags_to_grant or {}) do
        target.tags:remove(tag)
    end

    active.is_active = false

    -- Emit cue (end)
    if def.cue_tag then
        emit_cue(def.cue_tag .. ".End", {
            target = target,
            effect = def,
        })
    end

    -- Clean up the active effects list
    local kept = {}
    for _, a in ipairs(target.active_effects) do
        if a.is_active then
            table.insert(kept, a)
        end
    end
    target.active_effects = kept
end
```

**GDScript:**
```gdscript
func update_effects(target: Node, delta: float) -> void:
    var expired: Array = []

    for active in target.active_effects:
        if not active.is_active:
            continue

        var def = active.definition

        # Periodic ticking
        if def.get("period", 0.0) > 0:
            active.period_timer -= delta
            while active.period_timer <= 0:
                apply_periodic_tick(target, active)
                active.period_timer += def["period"]

        # Duration countdown
        if active.remaining_duration > 0:
            active.remaining_duration -= delta
            if active.remaining_duration <= 0:
                expired.append(active)

    for active in expired:
        remove_active_effect(target, active)

func apply_periodic_tick(target: Node, active: ActiveEffect) -> void:
    for mod_def in active.definition.get("periodic_modifiers", []):
        var attr = target.attributes.get_attribute(mod_def["attribute"])
        if attr:
            match mod_def["operation"]:
                "add":
                    attr.base_value += mod_def["value"]
                "multiply":
                    attr.base_value *= mod_def["value"]
            recalculate(attr)

func remove_active_effect(target: Node, active: ActiveEffect) -> void:
    var def = active.definition

    for mod_def in def.get("modifiers", []):
        var attr = target.attributes.get_attribute(mod_def["attribute"])
        if attr:
            remove_modifiers_by_source(attr, active.source_id)

    for tag in def.get("tags_to_grant", []):
        target.tags.remove(tag)

    active.is_active = false
    target.active_effects = target.active_effects.filter(
        func(a): return a.is_active
    )
```

---

## 6. Effect Context: Capturing Source Stats

When a fire mage with 100 spell power casts a fireball, the damage should use the mage's spell power at the time of casting — not the target's stats, and not the mage's stats 3 seconds later when a DOT ticks. This is **effect context** — a snapshot of relevant source data captured at application time.

```lua
-- Context captured when an ability applies an effect
local function create_effect_context(source, ability)
    return {
        source_entity = source,
        source_attack = source.attributes.get_value("attack_power"),
        source_spell = source.attributes.get_value("spell_power"),
        source_level = source.level,
        ability_name = ability.name,
        application_time = game_time(),
    }
end

-- An effect definition can reference context in its modifier values
local ScalingFireDamage = {
    id = "effect.scaling_fire_damage",
    duration_type = "instant",
    modifiers = {
        {
            attribute = "health",
            operation = "add",
            -- value is a function that uses context
            value_fn = function(context)
                return -(20 + context.source_spell * 0.5)
            end
        }
    },
    requirements = TagRequirement.new({}, { "Immune.Damage.Fire" }),
    cue_tag = "GameplayCue.Damage.Fire",
}

-- In apply_instant_effect, resolve value_fn:
local function resolve_value(mod_def, context)
    if mod_def.value_fn then
        return mod_def.value_fn(context)
    end
    return mod_def.value
end
```

**GDScript:**
```gdscript
func create_effect_context(source: Node, ability: Dictionary) -> Dictionary:
    return {
        "source_entity": source,
        "source_attack": source.attributes.get_value("attack_power"),
        "source_spell": source.attributes.get_value("spell_power"),
        "source_level": source.level,
        "ability_name": ability["name"],
    }

# For dynamic values, use callables or a simple formula system:
var scaling_fire_damage := {
    "id": "effect.scaling_fire_damage",
    "duration_type": "instant",
    "modifiers": [
        {
            "attribute": "health",
            "operation": "add",
            "base_value": -20.0,
            "scaling_stat": "source_spell",
            "scaling_factor": -0.5,
        }
    ],
}

func resolve_value(mod_def: Dictionary, context: Dictionary) -> float:
    var value = mod_def.get("base_value", mod_def.get("value", 0.0))
    var scaling_stat = mod_def.get("scaling_stat", "")
    if scaling_stat != "":
        value += context.get(scaling_stat, 0.0) * mod_def.get("scaling_factor", 0.0)
    return value
```

Context is simple but essential. Without it, DOTs would snapshot the caster's current stats on each tick (which change as they gain/lose buffs), leading to inconsistent damage. With context, the damage was "locked in" at cast time.

---

## 7. Stacking in Detail

Stacking is where effect design gets interesting. Here's each policy with concrete examples:

### No Stacking
Second application is rejected. Used for effects that shouldn't overlap.

```lua
-- Shield: only one active at a time
local Shield = {
    id = "effect.shield",
    stacking_policy = "none",
    duration_type = "duration",
    duration = 15.0,
    modifiers = {
        { attribute = "armor", operation = "add", value = 50 }
    },
    tags_to_grant = { "Status.Shielded" },
}
-- Applying Shield while Shield is active → rejected
```

### Duration Refresh
Reapplying resets the timer but doesn't increase the effect. Used for refreshable buffs where you want to maintain uptime but not stack power.

```lua
-- Speed boost: refreshable but doesn't stack
local SpeedBoost = {
    id = "effect.speed_boost",
    stacking_policy = "refresh_duration",
    duration_type = "duration",
    duration = 5.0,
    modifiers = {
        { attribute = "move_speed", operation = "multiply", value = 1.3 }
    },
    tags_to_grant = { "Status.Hasted" },
}
-- First application: +30% speed for 5s
-- Second application 3s later: still +30% speed, timer resets to 5s
```

### Stack with Cap
Each application adds a stack (up to a limit), with each stack contributing its own modifiers. Used for DOTs, wound effects, and combo systems.

```lua
-- Bleed: stacks up to 3 times, each stack does 3 damage/second
local Bleed = {
    id = "effect.bleed",
    stacking_policy = "stack_with_cap",
    max_stacks = 3,
    duration_type = "duration",
    duration = 6.0,
    period = 1.0,
    periodic_modifiers = {
        { attribute = "health", operation = "add", value = -3 }
    },
    tags_to_grant = { "Status.Bleeding" },
}
-- 1 stack: -3 HP/sec
-- 2 stacks: -6 HP/sec
-- 3 stacks (cap): -9 HP/sec
-- 4th application: refreshes duration, stays at 3 stacks
```

### Highest Only
Only the strongest instance applies. Used for percentage buffs where stacking would be too powerful.

```lua
-- Damage amp: only the strongest one counts
local DamageAmp = {
    id = "effect.damage_amp",
    stacking_policy = "highest_only",
    duration_type = "duration",
    duration = 10.0,
    modifiers = {
        { attribute = "attack_power", operation = "multiply", value = 1.2 }
    },
}
-- +20% applied. Then +30% applied → +20% removed, +30% active
-- +30% removed → back to base
```

---

## 8. Removing Effects Explicitly

Duration effects expire automatically. But you also need to remove effects explicitly: when equipment is unequipped (remove its infinite effect), when a cleanse ability fires (remove debuffs), or when a character dies (remove all effects).

```lua
local function remove_effect_by_id(target, effect_id)
    for _, active in ipairs(target.active_effects) do
        if active.definition.id == effect_id and active.is_active then
            remove_active_effect(target, active)
            return true
        end
    end
    return false
end

-- Remove all effects matching a tag pattern
-- Useful for "cleanse all Status effects"
local function remove_effects_granting_tag_matching(target, prefix)
    local to_remove = {}
    for _, active in ipairs(target.active_effects) do
        if active.is_active then
            for _, tag in ipairs(active.definition.tags_to_grant or {}) do
                if tag == prefix or tag:sub(1, #prefix + 1) == prefix .. "." then
                    table.insert(to_remove, active)
                    break
                end
            end
        end
    end
    for _, active in ipairs(to_remove) do
        remove_active_effect(target, active)
    end
end

-- Remove all effects on death
local function remove_all_effects(target)
    for _, active in ipairs(target.active_effects) do
        if active.is_active then
            remove_active_effect(target, active)
        end
    end
end
```

**GDScript:**
```gdscript
func remove_effect_by_id(target: Node, effect_id: String) -> bool:
    for active in target.active_effects:
        if active.definition["id"] == effect_id and active.is_active:
            remove_active_effect(target, active)
            return true
    return false

func remove_effects_granting_tag_matching(target: Node, prefix: String) -> void:
    var to_remove: Array = []
    for active in target.active_effects:
        if active.is_active:
            for tag in active.definition.get("tags_to_grant", []):
                if tag == prefix or tag.begins_with(prefix + "."):
                    to_remove.append(active)
                    break
    for active in to_remove:
        remove_active_effect(target, active)
```

---

## 9. Effect Interactions Through Tags

This is where the architecture pays off. Complex interactions between effects are expressed through tags, not through effects knowing about each other.

**Fire thaws ice:**
```lua
-- When a fire damage effect applies to a frozen target,
-- the frost effect should be removed.
-- One approach: the fire damage effect removes the frozen tag.
local FireDamageThaw = {
    id = "effect.fire_damage_thaw",
    duration_type = "instant",
    modifiers = {
        { attribute = "health", operation = "add", value = -40 }
    },
    tags_to_remove = { "State.Frozen" },
    -- Removing State.Frozen is enough — the frost effect's cleanup
    -- handles the rest if you track which effects granted which tags.
}
```

**Curse blocks healing:**
```lua
-- The heal effect has a block requirement:
local Heal = {
    id = "effect.heal",
    requirements = TagRequirement.new(
        { "State.Alive" },
        { "Status.Cursed" }   -- can't heal while cursed
    ),
    -- ...
}
-- Any effect that grants Status.Cursed automatically blocks healing.
-- The heal effect doesn't know about the curse effect.
-- The curse effect doesn't know about the heal effect.
-- They interact through the tag.
```

**Invincibility blocks all damage:**
```lua
-- Any damage effect blocks on Immune.Damage.All:
local requirements_for_damage = TagRequirement.new(
    {},
    { "Immune.Damage.All" }
)

-- An invincibility effect grants that tag:
local Invincibility = {
    id = "effect.invincibility",
    duration_type = "duration",
    duration = 5.0,
    tags_to_grant = { "Immune.Damage.All" },
}
-- All damage effects are blocked while invincibility is active.
-- No modification to any damage effect needed.
```

**Silence blocks spells but not physical attacks:**
```lua
-- Silence effect grants State.Silenced:
local Silence = {
    id = "effect.silence",
    duration_type = "duration",
    duration = 3.0,
    tags_to_grant = { "State.Silenced" },
}

-- Spell abilities block on State.Silenced:
local Fireball = {
    activation_blocked = { "State.Stunned", "State.Silenced" },
    -- ...
}

-- Physical abilities don't:
local SwordSlash = {
    activation_blocked = { "State.Stunned" },
    -- Not blocked by silence
}
```

Each interaction is expressed as a tag grant on one side and a tag requirement on the other. Neither side knows about the other. Adding new interactions means adding new tags and requirements — not modifying existing code.

---

## 10. The Entity Structure

At this point, let's define what an entity looks like with attributes, tags, and effects. This is the precursor to the full Ability System Component in Module 4.

**Lua:**
```lua
local function Entity(name, stats)
    local entity = {
        name = name,
        attributes = AttributeSet(),
        tags = TagContainer.new(),
        active_effects = {},
    }

    -- Initialize attributes
    for attr_name, base_value in pairs(stats) do
        entity.attributes.add(attr_name, base_value)
    end

    -- All entities start alive
    entity.tags:add("State.Alive")

    return entity
end

-- Usage:
local warrior = Entity("Warrior", {
    health = 200,
    max_health = 200,
    mana = 50,
    max_mana = 50,
    attack_power = 25,
    armor = 30,
    move_speed = 4.0,
})

local mage = Entity("Mage", {
    health = 80,
    max_health = 80,
    mana = 150,
    max_mana = 150,
    spell_power = 40,
    armor = 5,
    move_speed = 3.5,
})

-- Apply effects:
apply_effect(warrior, BattleCry, create_effect_context(warrior, nil))
-- warrior now has +25% attack power and Status.Empowered tag

apply_effect(mage, Poison, create_effect_context(warrior, nil))
-- mage now takes 5 damage per second and has Status.Poisoned tag

-- Each frame:
update_effects(warrior, dt)
update_effects(mage, dt)
```

**GDScript:**
```gdscript
func create_entity(entity_name: String, stats: Dictionary) -> Dictionary:
    var entity = {
        "name": entity_name,
        "attributes": AttributeSet.new(),
        "tags": TagContainer.new(),
        "active_effects": [],
    }

    for attr_name in stats:
        entity["attributes"].add(attr_name, stats[attr_name])

    entity["tags"].add("State.Alive")
    return entity

# Usage:
var warrior = create_entity("Warrior", {
    "health": 200.0,
    "max_health": 200.0,
    "mana": 50.0,
    "attack_power": 25.0,
    "armor": 30.0,
    "move_speed": 4.0,
})
```

---

## 11. Common Pitfalls

**Instant effects creating modifiers.** Instant effects should modify base values, not create modifiers. If you create a modifier for an instant effect, you have a modifier with no tracked duration and no expiry — it lives forever as a "phantom buff."

**Forgetting to clean up tags.** When a duration effect expires, you must remove the tags it granted. If you forget, the entity keeps `Status.Burning` forever even though the burn effect ended. The `remove_active_effect` function handles this — always use it, never manually manipulate the active effects list.

**Stacking bugs from shared source IDs.** If two instances of the same effect share a source ID, removing one removes both their modifiers. Each active effect instance needs a unique source ID. The counter-based approach (`effect_id.1`, `effect_id.2`, ...) handles this.

**Periodic effects that don't account for delta time accumulation.** If `dt` is large (frame spike or slow game), a periodic effect with period=1.0 might need to tick multiple times in a single frame. The `while active.period_timer <= 0` loop handles this. Don't use `if` — use `while`.

**Modifying the active effects list while iterating.** Collect effects to remove in a separate list, then remove them after iteration. Removing during iteration skips elements or crashes.

---

## Exercise

Implement a `GameplayEffect` definition system and an `apply_effect` / `update_effects` pipeline.

**Create these effects:**

1. **Fire Damage** — Instant, -40 health, blocked by `Immune.Damage.Fire`.
2. **Heal** — Instant, +30 health, requires `State.Alive`, blocked by `Status.Cursed`.
3. **Battle Cry** — Duration 10s, +25% attack_power, grants `Status.Empowered`, stacking: refresh duration.
4. **Poison** — Duration 8s, periodic (-5 health every 1s), grants `Status.Poisoned`, stacking: stack with cap (3 stacks).
5. **Iron Skin** — Infinite, +50 armor, grants `Status.Armored`.

**Test scenarios:**

1. Apply Fire Damage to a target with 100 health → health becomes 60.
2. Apply Fire Damage to a target with `Immune.Damage.Fire` → rejected.
3. Apply Heal to a target with 60 health → health becomes 90.
4. Apply Heal to a target with `Status.Cursed` → rejected.
5. Apply Battle Cry, wait 5 seconds, apply again → duration resets to 10s, attack power modifier unchanged.
6. Apply Poison 3 times → 3 stacks, -15 HP/sec. Apply 4th time → stays at 3 stacks, duration refreshes.
7. Apply Iron Skin → +50 armor. Remove it → armor returns to base.
8. Apply Poison. Wait 8 seconds → Poison expires, `Status.Poisoned` removed, damage stops.

**Stretch goals:**
- Implement effect context with scaling: fire damage = 20 + (spell_power × 0.5).
- Add a "Cleanse" instant effect that removes all effects granting `Status.*` tags.
- Implement "highest only" stacking for a percentage attack buff.

---

## Read

- **GASDocumentation — Gameplay Effects:** https://github.com/tranek/GASDocumentation#concepts-ge — covers duration types, stacking, modifiers, and application. This is the most important section for system design.
- **"Data-Driven Gameplay Effects"** blog posts — search for implementations of buff/debuff systems in roguelikes and ARPGs. The pattern is everywhere, even without the GAS name.
- **"Diablo-style Buff Stacking"** design discussions — stacking rules are a decades-old design problem. Diablo, Path of Exile, and Dota 2 all solve it differently.

---

## Summary

A **gameplay effect** is a data-driven bundle of attribute modifiers, tag changes, and metadata. Effects come in three duration types: **instant** (one-shot, modifies base values), **duration** (timed, applies modifiers that auto-expire), and **infinite** (persistent until explicitly removed).

The effect system manages:
- **Application requirements** — tag queries that gate whether an effect applies
- **Stacking** — how multiple instances of the same effect interact (no stack, refresh, stack with cap, highest only)
- **Periodic ticking** — DOT/HOT effects that apply instant modifications on a timer
- **Effect context** — snapshot of source stats at application time for damage formulas
- **Lifecycle** — tracking active effects, counting down durations, cleaning up on expiry

Effects interact through tags, not through knowledge of each other. Fire immunity blocks fire damage because the damage effect's requirements check for `Immune.Damage.Fire`. The fire damage effect doesn't know about the immunity effect. The immunity effect doesn't know about the fire damage effect. They communicate through the tag system.

Next up: [Module 4 — Gameplay Abilities](module-04-gameplay-abilities.md), where effects get wrapped in player-facing actions with costs, cooldowns, and activation requirements.
