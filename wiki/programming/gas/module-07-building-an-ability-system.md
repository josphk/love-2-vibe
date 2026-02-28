# Module 7: Building an Ability System

**Part of:** [GAS Learning Roadmap](gas-learning-roadmap.md)
**Estimated study time:** 20–40 hours
**Prerequisites:** All previous modules ([Module 0](module-00-the-case-for-gas.md) through [Module 6](module-06-gameplay-cues-and-feedback.md))

---

## Overview

This is the capstone. You're going to build a small but complete ability system — multiple characters with different ability sets, interacting effects, visual feedback, and enough gameplay to exercise every part of the architecture. The goal isn't to build an MMO. The goal is to confront every integration decision and come out with a system that works end-to-end.

You've built the pieces: attributes with modifier pipelines (Module 1), hierarchical tags (Module 2), data-driven effects (Module 3), ability lifecycles (Module 4), async ability patterns (Module 5), and decoupled feedback (Module 6). Each piece works in isolation. Integration is where it gets real — systems interact in ways you didn't plan for, edge cases surface at the seams, and you discover which design decisions hold up under pressure.

By the end of this module you'll have a working game prototype that exercises every layer of the ability system, with real gameplay interactions proving the architecture works.

---

## 1. Choosing Your Format

Pick a format that heavily features abilities. The system needs enough complexity to reveal integration bugs.

**Arena battle (recommended).** Two or more characters fighting each other with abilities. AI-controlled or player-controlled — both work. This format forces you to wire up every layer: attributes define stats, tags define state, effects modify both, abilities use all three, cues show what's happening. A round of combat exercises dozens of ability interactions.

**Roguelike ability demo.** Player character with upgradeable abilities fighting waves of enemies. Good for testing ability grants (finding new abilities as pickups), effect stacking (multiple DoTs), and the feel of the cue system under sustained combat.

**Turn-based RPG combat.** Party of characters vs. a group of enemies. Easier to debug (you control the pace) and still exercises the full pipeline. Less testing of async abilities (Module 5) since abilities resolve between turns, but everything else gets thoroughly tested.

**What to avoid:** Anything that doesn't heavily feature abilities. A platformer with one attack move won't exercise the system enough. You need at least 4-5 abilities across your characters, with effects that interact through tags and attributes.

---

## 2. The Ability System Component as Integration Point

The ASC from Module 4 is the integration point. Everything routes through it. Before building gameplay, finalize the ASC API — this is the contract between your ability system and the rest of your game.

**Minimal ASC API:**

```
AbilitySystemComponent:
    // Attribute access
    get_attribute(name) → number
    get_base_attribute(name) → number
    set_base_attribute(name, value)

    // Tag access
    has_tag(tag) → bool
    has_any_tag(tags) → bool
    has_all_tags(tags) → bool

    // Effect operations
    apply_effect(effect_def, context)
    remove_effects_with_tag(tag)
    get_active_effects() → list

    // Ability operations
    grant_ability(ability_def)
    revoke_ability(ability_name)
    activate_ability(ability_name, target) → bool
    can_activate_ability(ability_name) → bool

    // Lifecycle
    update(dt)
```

This API is all external code needs. The game's combat system calls `activate_ability`. The UI calls `get_attribute` and `can_activate_ability`. The health system checks `has_tag("State.Dead")`. Nothing outside the ASC touches modifiers, active effects, or tag containers directly.

**Lua:**
```lua
local ASC = {}
ASC.__index = ASC

function ASC.new(config)
    local asc = setmetatable({
        -- Core systems
        attributes = AttributeSet.new(),
        tags = TagContainer.new(),
        active_effects = {},
        granted_abilities = {},

        -- Module 5: async
        task_runner = AbilityTaskRunner.new(),
        active_ability = nil,

        -- Module 6: cues
        cue_manager = config.cue_manager,    -- shared or per-entity

        -- Identity
        entity = config.entity,
        name = config.name or "unnamed",
    }, ASC)

    -- Initialize attributes from config
    if config.attributes then
        for attr_name, base_value in pairs(config.attributes) do
            asc.attributes:set_base(attr_name, base_value)
        end
    end

    -- Grant initial abilities
    if config.abilities then
        for _, ability_def in ipairs(config.abilities) do
            asc:grant_ability(ability_def)
        end
    end

    -- Set initial tags
    if config.tags then
        for _, tag in ipairs(config.tags) do
            asc.tags:add(tag)
        end
    end

    return asc
end

function ASC:get_attribute(name)
    return self.attributes:get_current(name)
end

function ASC:has_tag(tag)
    return self.tags:has(tag)
end

function ASC:apply_effect(effect_def, context)
    -- Check requirements
    if effect_def.requirements then
        if not effect_def.requirements:check(self.tags) then
            return false
        end
    end

    if effect_def.duration_type == "instant" then
        -- Apply directly to base values
        for _, mod in ipairs(effect_def.modifiers or {}) do
            local base = self.attributes:get_base(mod.attribute)
            if mod.operation == "add" then
                self.attributes:set_base(mod.attribute, base + mod.value)
            end
        end
        -- Emit burst cue
        if effect_def.cue_tag and self.cue_manager then
            self.cue_manager:emit(effect_def.cue_tag, "burst", {
                source = context and context.source,
                target = self.entity,
                magnitude = effect_def.modifiers and effect_def.modifiers[1]
                    and math.abs(effect_def.modifiers[1].value) or 0,
            })
        end
    else
        -- Duration or infinite: create active effect
        local active = {
            def = effect_def,
            remaining = effect_def.duration or math.huge,
            tick_timer = 0,
            context = context,
            modifiers = {},
        }
        -- Apply modifiers to attributes
        for _, mod in ipairs(effect_def.modifiers or {}) do
            local modifier_id = self.attributes:add_modifier(
                mod.attribute, mod.operation, mod.value, effect_def.id
            )
            table.insert(active.modifiers, {attribute = mod.attribute, id = modifier_id})
        end
        -- Grant tags
        for _, tag in ipairs(effect_def.tags_to_grant or {}) do
            self.tags:add(tag)
        end
        table.insert(self.active_effects, active)
        -- Emit loop start cue
        if effect_def.cue_tag and self.cue_manager then
            self.cue_manager:emit(effect_def.cue_tag, "loop_start", {
                target = self.entity,
            })
        end
    end
    return true
end

function ASC:activate_ability(ability_name, target)
    local ability = self.granted_abilities[ability_name]
    if not ability then return false end
    return try_activate_ability(self, ability, target)
end

function ASC:update(dt)
    -- Tick active effects
    local i = 1
    while i <= #self.active_effects do
        local active = self.active_effects[i]
        local expired = false

        -- Tick duration
        if active.def.duration_type == "duration" then
            active.remaining = active.remaining - dt
            if active.remaining <= 0 then
                expired = true
            end
        end

        -- Tick periodic
        if not expired and active.def.period then
            active.tick_timer = active.tick_timer + dt
            if active.tick_timer >= active.def.period then
                active.tick_timer = active.tick_timer - active.def.period
                -- Apply periodic instant effect
                if active.def.periodic_instant then
                    local pi = active.def.periodic_instant
                    local base = self.attributes:get_base(pi.attribute)
                    if pi.operation == "add" then
                        self.attributes:set_base(pi.attribute, base + pi.value)
                    end
                end
                -- Periodic cue
                local cue = active.def.periodic_cue_tag or active.def.cue_tag
                if cue and self.cue_manager then
                    self.cue_manager:emit(cue, "burst", {
                        target = self.entity,
                        magnitude = active.def.periodic_instant
                            and math.abs(active.def.periodic_instant.value) or 0,
                    })
                end
            end
        end

        -- Handle expiry
        if expired then
            self:_remove_active_effect(i)
        else
            i = i + 1
        end
    end

    -- Tick ability tasks
    self.task_runner:update(dt)

    -- Clamp health to [0, max_health]
    if self.attributes:has("health") and self.attributes:has("max_health") then
        local health = self.attributes:get_current("health")
        local max_hp = self.attributes:get_current("max_health")
        if health > max_hp then
            self.attributes:set_base("health", max_hp)
        elseif health <= 0 and not self.tags:has("State.Dead") then
            self.attributes:set_base("health", 0)
            self.tags:remove("State.Alive")
            self.tags:add("State.Dead")
            if self.cue_manager then
                self.cue_manager:emit("GameplayCue.Death", "burst", {
                    target = self.entity,
                })
            end
        end
    end
end

function ASC:_remove_active_effect(index)
    local active = self.active_effects[index]
    -- Remove modifiers
    for _, mod in ipairs(active.modifiers) do
        self.attributes:remove_modifier(mod.attribute, mod.id)
    end
    -- Remove granted tags
    for _, tag in ipairs(active.def.tags_to_grant or {}) do
        self.tags:remove(tag)
    end
    -- Emit loop end cue
    if active.def.cue_tag and self.cue_manager then
        self.cue_manager:emit(active.def.cue_tag, "loop_end", {
            target = self.entity,
        })
    end
    table.remove(self.active_effects, index)
end
```

**GDScript:**
```gdscript
class_name ASC
extends Node

var attributes := AttributeSet.new()
var tags := TagContainer.new()
var active_effects: Array[Dictionary] = []
var granted_abilities: Dictionary = {}
var task_runner := AbilityTaskRunner.new()
var cue_manager: CueManager
var entity: Node

func _init(config: Dictionary = {}) -> void:
    cue_manager = config.get("cue_manager")
    entity = config.get("entity")

    for attr_name in config.get("attributes", {}).keys():
        attributes.set_base(attr_name, config.attributes[attr_name])

    for ability_def in config.get("abilities", []):
        grant_ability(ability_def)

    for tag in config.get("tags", []):
        tags.add(tag)

func get_attribute(attr_name: String) -> float:
    return attributes.get_current(attr_name)

func has_tag(tag: String) -> bool:
    return tags.has(tag)

func apply_effect(effect_def: Dictionary, context: Dictionary = {}) -> bool:
    if effect_def.has("requirements"):
        if not effect_def.requirements.check(tags):
            return false

    if effect_def.duration_type == "instant":
        for mod in effect_def.get("modifiers", []):
            var base := attributes.get_base(mod.attribute)
            if mod.operation == "add":
                attributes.set_base(mod.attribute, base + mod.value)
        if effect_def.has("cue_tag") and cue_manager:
            cue_manager.emit(effect_def.cue_tag, CueType.BURST, {
                source = context.get("source"),
                target = entity,
                magnitude = absf(effect_def.modifiers[0].value) if effect_def.modifiers.size() > 0 else 0,
            })
    else:
        var active := {
            def = effect_def,
            remaining = effect_def.get("duration", INF),
            tick_timer = 0.0,
            context = context,
            modifier_ids = [],
        }
        for mod in effect_def.get("modifiers", []):
            var mod_id := attributes.add_modifier(mod.attribute, mod.operation, mod.value)
            active.modifier_ids.append({attribute = mod.attribute, id = mod_id})
        for tag in effect_def.get("tags_to_grant", []):
            tags.add(tag)
        active_effects.append(active)
        if effect_def.has("cue_tag") and cue_manager:
            cue_manager.emit(effect_def.cue_tag, CueType.LOOP_START, {target = entity})
    return true

func activate_ability(ability_name: String, target: ASC = null) -> bool:
    if not granted_abilities.has(ability_name):
        return false
    return _try_activate(granted_abilities[ability_name], target)

func _process(delta: float) -> void:
    _update_effects(delta)
    _clamp_health()
```

---

## 3. Defining Your Characters

Create at least two character archetypes with different attribute spreads and ability sets. This tests the system's ability to handle varied configurations through data, not code.

**Example: Warrior + Mage**

```
Warrior:
    attributes:
        health: 200
        max_health: 200
        stamina: 100
        max_stamina: 100
        attack_power: 25
        armor: 15
    tags: [State.Alive, Class.Warrior]
    abilities:
        - Slash (instant, physical damage)
        - Shield Bash (instant, stun + damage)
        - War Cry (self-buff, attack power up)
        - Defensive Stance (toggle, damage reduction)

Mage:
    attributes:
        health: 80
        max_health: 80
        mana: 150
        max_mana: 150
        attack_power: 10
        spell_power: 35
    tags: [State.Alive, Class.Mage]
    abilities:
        - Fireball (instant, fire damage + burn DoT)
        - Frost Nova (AoE, ice damage + freeze)
        - Heal (instant, self-heal)
        - Arcane Shield (self-buff, damage absorption)
```

The archetypes test different subsystems:
- **Warrior** tests stamina costs, physical abilities that bypass silence, toggle abilities, self-buffs
- **Mage** tests mana costs, spell abilities blocked by silence, DoT effects, AoE targeting, healing clamped to max

**Lua data definitions:**
```lua
local warrior_config = {
    name = "Warrior",
    attributes = {
        health = 200, max_health = 200,
        stamina = 100, max_stamina = 100,
        attack_power = 25, armor = 15,
    },
    tags = {"State.Alive", "Class.Warrior"},
    abilities = {slash, shield_bash, war_cry, defensive_stance},
}

local mage_config = {
    name = "Mage",
    attributes = {
        health = 80, max_health = 80,
        mana = 150, max_mana = 150,
        attack_power = 10, spell_power = 35,
    },
    tags = {"State.Alive", "Class.Mage"},
    abilities = {fireball, frost_nova, heal, arcane_shield},
}
```

---

## 4. Defining Your Abilities and Effects

Each ability is an ability definition (Module 4) that references effect definitions (Module 3). Define all the data upfront — the code doesn't change per ability.

**Slash (Warrior):**
```
slash:
    cost: {attribute: "stamina", amount: 15}
    cooldown: 1.5s
    cooldown_tag: "Cooldown.Ability.Slash"
    requirements:
        require: [State.Alive]
        block: [State.Stunned, Cooldown.Ability.Slash]
    effects:
        - slash_damage: instant, health -25 (uses attack_power scaling)
    cue_tag: "GameplayCue.Ability.Slash"
```

**Shield Bash (Warrior):**
```
shield_bash:
    cost: {attribute: "stamina", amount: 30}
    cooldown: 6.0s
    cooldown_tag: "Cooldown.Ability.ShieldBash"
    requirements:
        require: [State.Alive]
        block: [State.Stunned, Cooldown.Ability.ShieldBash]
    effects:
        - bash_damage: instant, health -15
        - stun: duration 2.0s, grants State.Stunned
    cue_tag: "GameplayCue.Ability.ShieldBash"
```

**Fireball (Mage):**
```
fireball:
    cost: {attribute: "mana", amount: 30}
    cooldown: 3.0s
    cooldown_tag: "Cooldown.Ability.Fireball"
    requirements:
        require: [State.Alive]
        block: [State.Stunned, State.Silenced, Cooldown.Ability.Fireball]
    effects:
        - fire_damage: instant, health -40
        - burn_dot: duration 5.0s, period 1.0s, periodic -5 health,
                    grants Status.Burning
    cue_tag: "GameplayCue.Ability.Fireball"
```

**Frost Nova (Mage, AoE):**
```
frost_nova:
    cost: {attribute: "mana", amount: 45}
    cooldown: 8.0s
    cooldown_tag: "Cooldown.Ability.FrostNova"
    requirements:
        require: [State.Alive]
        block: [State.Stunned, State.Silenced, Cooldown.Ability.FrostNova]
    targeting: aoe_around_caster, radius: 3.0
    effects:
        - frost_damage: instant, health -25
        - freeze: duration 3.0s, grants State.Frozen, State.Stunned
                  modifiers: [{move_speed, override, 0}]
    cue_tag: "GameplayCue.Ability.FrostNova"
```

**Heal (Mage):**
```
heal:
    cost: {attribute: "mana", amount: 25}
    cooldown: 5.0s
    cooldown_tag: "Cooldown.Ability.Heal"
    requirements:
        require: [State.Alive]
        block: [State.Silenced, Cooldown.Ability.Heal]
    target: self
    effects:
        - healing: instant, health +30
    cue_tag: "GameplayCue.Ability.Heal"
```

**War Cry (Warrior, self-buff):**
```
war_cry:
    cost: {attribute: "stamina", amount: 20}
    cooldown: 15.0s
    cooldown_tag: "Cooldown.Ability.WarCry"
    requirements:
        require: [State.Alive]
        block: [State.Stunned, Cooldown.Ability.WarCry]
    target: self
    effects:
        - attack_boost: duration 10.0s, modifiers: [{attack_power, multiply, 1.3}],
                        grants Status.WarCry
    cue_tag: "GameplayCue.Ability.WarCry"
```

**Defensive Stance (Warrior, toggle):**
```
defensive_stance:
    cost: none
    cooldown: 1.0s
    cooldown_tag: "Cooldown.Ability.DefensiveStance"
    requirements:
        require: [State.Alive]
        block: [State.Stunned, Cooldown.Ability.DefensiveStance]
    toggle: true
    active_tag: "Stance.Defensive"
    effects:
        - defense_mode: infinite, modifiers: [
            {damage_taken, multiply, 0.75},
            {attack_power, multiply, 0.7}
          ], grants Stance.Defensive
    cue_tag: "GameplayCue.Status.DefensiveStance"
```

**Arcane Shield (Mage, self-buff):**
```
arcane_shield:
    cost: {attribute: "mana", amount: 40}
    cooldown: 12.0s
    cooldown_tag: "Cooldown.Ability.ArcaneShield"
    requirements:
        require: [State.Alive]
        block: [State.Silenced, Cooldown.Ability.ArcaneShield]
    target: self
    effects:
        - shield: duration 8.0s, grants Status.Shielded, Immune.Damage.Physical
    cue_tag: "GameplayCue.Status.ArcaneShield"
```

Notice: Arcane Shield grants `Immune.Damage.Physical`. If your physical damage effects have a requirement that blocks on `Immune.Damage.Physical`, the warrior's Slash will be completely blocked while the shield is up. The mage's Fireball still works because it's fire damage, not physical. **This interaction emerges from data — no special-case code.**

---

## 5. Designing Effect Interactions

The real test of an ability system is how effects interact through tags and attributes. Here are interactions that should work without any special-case code — purely through tag requirements, modifiers, and the existing pipeline:

### Fire + Ice Interaction
Burning and Frozen are opposing states. Apply fire to a frozen target → remove freeze and deal bonus damage. Apply ice to a burning target → remove burn and deal bonus damage.

**Implementation via tag requirements:**
```
burn_dot:
    tags_to_remove: [Status.Frozen]    // fire removes ice
    // If target was frozen, bonus damage is a separate instant effect
    // triggered by a "Status.Frozen was removed" check

freeze:
    tags_to_remove: [Status.Burning]   // ice removes fire
```

Or simpler: just let both states coexist but have the newer one remove the older via `tags_to_remove`. No special code.

### Stun Prevents Casting
Stunned entities can't activate abilities. This already works — every ability blocks on `State.Stunned`. Shield Bash applies a 2-second stun. During those 2 seconds, the target can't cast.

### Silence Blocks Spells But Not Physical
Mage abilities block on `State.Silenced`. Warrior abilities don't. A silence effect grants `State.Silenced`. The warrior keeps swinging; the mage can't cast.

### Damage Immunity
Arcane Shield grants `Immune.Damage.Physical`. Physical damage effects check `block: [Immune.Damage.Physical]` in their requirements. While the shield is up, physical damage is rejected at application time.

A broader immunity tag like `Immune.Damage.All` blocks everything. The hierarchy means you can add `Immune.Damage.Fire` to block only fire damage. Effects that check for `Immune.Damage` (prefix match) catch all sub-types.

### Health Reaches Zero → Death
When `update()` ticks and health ≤ 0, the ASC removes `State.Alive` and adds `State.Dead`. Every ability requires `State.Alive` — dead entities can't act. This is one line of logic in the ASC's update function, not per-ability code.

### Resource Regeneration
Stamina and mana regenerate over time. Model this as an infinite-duration effect with periodic ticking:

```
stamina_regen:
    duration_type: "infinite"
    period: 1.0
    periodic_instant: {attribute: "stamina", operation: "add", value: 5}
    // Regenerates 5 stamina per second

mana_regen:
    duration_type: "infinite"
    period: 1.0
    periodic_instant: {attribute: "mana", operation: "add", value: 3}
```

Apply these effects at character creation. They tick forever, slowly restoring resources. If you want to stop regeneration during combat, add a tag requirement: `block: [State.InCombat]`.

---

## 6. The Game Loop

Your game loop drives everything. Each frame:

1. **Process input** — determine which abilities the player (or AI) wants to activate
2. **Activate abilities** — call `asc:activate_ability(name, target)` for each action
3. **Update all ASCs** — call `asc:update(dt)` on every entity, which ticks effects, checks expiry, handles periodic ticks, runs ability tasks
4. **Check game state** — is anyone dead? Is the fight over?
5. **Render** — draw the game, which uses attribute values and cue-driven visuals

**Pseudocode:**
```
function game_loop(dt):
    // 1. Input / AI decisions
    for each entity:
        action = entity.ai:decide(entity.asc, enemies)
        if action:
            entity.asc:activate_ability(action.ability, action.target)

    // 2. Update all ability systems
    for each entity:
        entity.asc:update(dt)

    // 3. Check game state
    for each entity:
        if entity.asc:has_tag("State.Dead"):
            handle_death(entity)

    if all_enemies_dead():
        victory()
    if player_dead():
        defeat()
```

**Lua (Love2D):**
```lua
function love.update(dt)
    -- AI decisions
    for _, entity in ipairs(entities) do
        if entity.ai and entity.asc:has_tag("State.Alive") then
            local action = entity.ai:decide(entity.asc, get_enemies(entity))
            if action then
                entity.asc:activate_ability(action.ability, action.target)
            end
        end
    end

    -- Update all ASCs
    for _, entity in ipairs(entities) do
        entity.asc:update(dt)
    end

    -- Check for deaths
    for _, entity in ipairs(entities) do
        if entity.asc:has_tag("State.Dead") and not entity.dead_handled then
            entity.dead_handled = true
            print(entity.name .. " has been defeated!")
        end
    end
end
```

**GDScript:**
```gdscript
func _process(delta: float) -> void:
    for entity in entities:
        if entity.ai and entity.asc.has_tag("State.Alive"):
            var action := entity.ai.decide(entity.asc, get_enemies(entity))
            if action:
                entity.asc.activate_ability(action.ability, action.target)

    for entity in entities:
        entity.asc._process(delta)

    for entity in entities:
        if entity.asc.has_tag("State.Dead") and not entity.dead_handled:
            entity.dead_handled = true
            print(entity.name + " has been defeated!")
```

---

## 7. Simple AI for Testing

You need at least basic AI to drive a battle without manual input. A simple priority-based AI is enough:

```
AI Decision Loop:
    1. If health < 30% and can heal → heal
    2. If target is stunned and have a big damage ability → use it
    3. If buff not active and buff available → use buff
    4. If best damage ability is off cooldown → use it
    5. If no ability available → wait (auto-attack or skip)
```

**Lua:**
```lua
local SimpleAI = {}
SimpleAI.__index = SimpleAI

function SimpleAI.new(priority_list)
    return setmetatable({
        priorities = priority_list,
    }, SimpleAI)
end

function SimpleAI:decide(asc, enemies)
    for _, priority in ipairs(self.priorities) do
        -- Check condition
        if priority.condition(asc, enemies) then
            -- Check if ability can activate
            local ability_name = priority.ability
            if asc:can_activate_ability(ability_name) then
                local target = priority.target(asc, enemies)
                return {ability = ability_name, target = target}
            end
        end
    end
    return nil    -- nothing to do
end

-- Example: Warrior AI
local warrior_ai = SimpleAI.new({
    {
        ability = "War Cry",
        condition = function(asc, enemies)
            return not asc:has_tag("Status.WarCry")
        end,
        target = function(asc, enemies) return asc end,    -- self
    },
    {
        ability = "Shield Bash",
        condition = function(asc, enemies)
            -- Use if any enemy is casting
            for _, e in ipairs(enemies) do
                if e.asc:has_tag("State.Channeling") or e.asc:has_tag("State.Casting") then
                    return true
                end
            end
            return false
        end,
        target = function(asc, enemies)
            for _, e in ipairs(enemies) do
                if e.asc:has_tag("State.Channeling") then return e.asc end
            end
            return enemies[1] and enemies[1].asc
        end,
    },
    {
        ability = "Slash",
        condition = function() return true end,    -- always use if available
        target = function(asc, enemies)
            return enemies[1] and enemies[1].asc
        end,
    },
})

-- Example: Mage AI
local mage_ai = SimpleAI.new({
    {
        ability = "Heal",
        condition = function(asc, enemies)
            local hp = asc:get_attribute("health")
            local max_hp = asc:get_attribute("max_health")
            return hp < max_hp * 0.4    -- heal below 40%
        end,
        target = function(asc, enemies) return asc end,
    },
    {
        ability = "Arcane Shield",
        condition = function(asc, enemies)
            return not asc:has_tag("Status.Shielded")
        end,
        target = function(asc, enemies) return asc end,
    },
    {
        ability = "Frost Nova",
        condition = function(asc, enemies)
            -- Use if 2+ enemies nearby (or just any enemy)
            return #enemies >= 2
        end,
        target = function(asc, enemies)
            return enemies    -- AoE targets all
        end,
    },
    {
        ability = "Fireball",
        condition = function() return true end,
        target = function(asc, enemies)
            return enemies[1] and enemies[1].asc
        end,
    },
})
```

The AI is simple. That's fine. Its job is to exercise the ability system, not to play well.

---

## 8. Logging and Debugging

The single most important feature for integration work is comprehensive logging. When effects interact in unexpected ways, the log tells you exactly what happened.

**Log every pipeline event:**

```
[00:01.20] [Warrior] Activate: Slash → target: Mage
[00:01.20]   [Check] Require State.Alive: PASS
[00:01.20]   [Check] Block State.Stunned: PASS
[00:01.20]   [Check] Block Cooldown.Ability.Slash: PASS
[00:01.20]   [Cost] stamina: 100 - 15 = 85
[00:01.20]   [Cooldown] Cooldown.Ability.Slash for 1.5s
[00:01.20]   [Effect] slash_damage → Mage: health 80 → 55 (instant, -25)
[00:01.20]   [Cue] GameplayCue.Damage.Physical (burst, magnitude=25)
[00:02.70]   [Expire] Cooldown.Ability.Slash on Warrior (duration ended)

[00:03.50] [Mage] Activate: Fireball → target: Warrior
[00:03.50]   [Check] Require State.Alive: PASS
[00:03.50]   [Check] Block State.Stunned: PASS
[00:03.50]   [Check] Block State.Silenced: PASS
[00:03.50]   [Check] Block Cooldown.Ability.Fireball: PASS
[00:03.50]   [Cost] mana: 150 - 30 = 120
[00:03.50]   [Cooldown] Cooldown.Ability.Fireball for 3.0s
[00:03.50]   [Effect] fire_damage → Warrior: health 200 → 160 (instant, -40)
[00:03.50]   [Effect] burn_dot → Warrior: Status.Burning granted, 5.0s duration
[00:03.50]   [Cue] GameplayCue.Damage.Fire (burst, magnitude=40)
[00:03.50]   [Cue] GameplayCue.Status.Burning (loop_start)
[00:04.50]   [Tick] burn_dot on Warrior: health 160 → 155 (periodic, -5)
[00:04.50]   [Cue] GameplayCue.Damage.Fire (burst, magnitude=5)
```

**Implementation:**

```lua
local Logger = {}
Logger.__index = Logger

function Logger.new(config)
    return setmetatable({
        enabled = config and config.enabled or true,
        start_time = love.timer.getTime(),
        entries = {},
        max_entries = 500,
    }, Logger)
end

function Logger:log(category, message, ...)
    if not self.enabled then return end
    local time = love.timer.getTime() - self.start_time
    local entry = string.format("[%06.2f] [%s] %s", time, category, string.format(message, ...))
    table.insert(self.entries, entry)
    if #self.entries > self.max_entries then
        table.remove(self.entries, 1)
    end
    print(entry)    -- also print to console
end

-- Usage in ASC
function ASC:activate_ability(ability_name, target)
    self.logger:log("Ability", "%s: Activate %s → target: %s",
        self.name, ability_name, target and target.name or "self")
    -- ... activation logic with logging at each step ...
end
```

**A debug overlay** is equally valuable. Show live attribute values, active tags, active effects with remaining durations, and cooldown timers. Toggle it with a key:

```lua
function draw_debug_overlay(asc, x, y)
    love.graphics.print(asc.name, x, y)
    y = y + 20

    -- Attributes
    for name, attr in pairs(asc.attributes.attrs) do
        love.graphics.print(string.format("  %s: %.0f / %.0f (base: %.0f)",
            name, attr.current, asc.attributes:get_current("max_" .. name) or attr.current, attr.base),
            x, y)
        y = y + 16
    end

    -- Tags
    love.graphics.print("  Tags: " .. table.concat(asc.tags:to_list(), ", "), x, y)
    y = y + 16

    -- Active effects
    for _, active in ipairs(asc.active_effects) do
        local remaining = active.def.duration_type == "duration"
            and string.format(" (%.1fs)", active.remaining) or ""
        love.graphics.print("  Effect: " .. (active.def.id or "?") .. remaining, x, y)
        y = y + 16
    end
end
```

---

## 9. System Initialization Order

Getting the initialization sequence right matters. Components depend on each other:

1. **Create the CueManager** (Module 6) — shared across all entities
2. **Register cue handlers** — connect visual/audio callbacks
3. **Create entities with ASCs** — each gets its own attributes, tags, effects
4. **Apply initial effects** — resource regeneration, passive abilities, equipment bonuses
5. **Grant abilities** — fill each entity's ability roster
6. **Start the game loop** — now everything is wired up

**Lua initialization:**
```lua
function init_game()
    -- 1. Cue system
    local cue_mgr = CueManager.new()

    -- 2. Register handlers
    cue_mgr:register("GameplayCue.Damage", function(cue_type, params)
        if cue_type == "burst" then
            print(string.format("  ** %d damage! **", params.magnitude or 0))
        end
    end)
    cue_mgr:register("GameplayCue.Heal", function(cue_type, params)
        if cue_type == "burst" then
            print(string.format("  ** +%d healed **", params.magnitude or 0))
        end
    end)
    cue_mgr:register("GameplayCue.Status.Burning", function(cue_type, params)
        if cue_type == "loop_start" then print("  ** Burning! **") end
        if cue_type == "loop_end" then print("  ** Burn ended **") end
    end)
    cue_mgr:register("GameplayCue.Death", function(cue_type, params)
        if cue_type == "burst" then print("  ** DEATH **") end
    end)

    -- 3. Create entities
    local warrior = {
        name = "Warrior",
        asc = ASC.new({
            name = "Warrior",
            cue_manager = cue_mgr,
            attributes = {health = 200, max_health = 200, stamina = 100, max_stamina = 100,
                          attack_power = 25, armor = 15},
            tags = {"State.Alive", "Class.Warrior"},
        }),
        ai = warrior_ai,
    }

    local mage = {
        name = "Mage",
        asc = ASC.new({
            name = "Mage",
            cue_manager = cue_mgr,
            attributes = {health = 80, max_health = 80, mana = 150, max_mana = 150,
                          attack_power = 10, spell_power = 35},
            tags = {"State.Alive", "Class.Mage"},
        }),
        ai = mage_ai,
    }

    -- 4. Apply passive effects (regeneration)
    warrior.asc:apply_effect(stamina_regen_effect, {})
    mage.asc:apply_effect(mana_regen_effect, {})

    -- 5. Grant abilities
    for _, ability in ipairs({slash, shield_bash, war_cry, defensive_stance}) do
        warrior.asc:grant_ability(ability)
    end
    for _, ability in ipairs({fireball, frost_nova, heal, arcane_shield}) do
        mage.asc:grant_ability(ability)
    end

    return {warrior, mage}
end
```

---

## 10. Networking Architecture (Conceptual)

You don't need to implement networking. But understanding where it fits validates your architecture. If your system cleanly separates into these layers, you've built it right:

**Server (authoritative):**
- Owns the real ASC for each entity
- Processes ability activations (CanActivate, CommitCost, Activate)
- Applies effects and ticks durations
- Runs AI
- Sends state updates to clients

**Client (predictive):**
- Has a local copy of the ASC for display and prediction
- When the player presses Fireball, the client *predicts* the result: checks CanActivate locally, plays the cue immediately (for responsiveness), and sends the input to the server
- When the server confirms (or denies) the ability activation, the client reconciles: if confirmed, everything matches; if denied, the client rolls back the prediction (removes the cue, restores attributes)

**What gets replicated (sent over the network):**
- Attribute base values (health, mana)
- Tag changes (State.Stunned added/removed)
- Active effect changes (new effect applied, effect expired)
- Cue events (GameplayCue.Damage.Fire with params)

**What stays local:**
- The cue handlers (particle spawning, sounds, screen shake)
- UI state (cooldown bar filling, health bar animation)
- Input processing

The key insight: your cue system is *already* the client-server boundary. The server emits cue events; the client handles them with visuals. In single-player, both happen on the same machine. In multiplayer, there's a network message between emit and handle. The architecture doesn't change — only the transport.

---

## 11. Integration Testing Checklist

Use this checklist to verify your system works end-to-end. Each test exercises a specific integration point:

### Basic Operations
- [ ] Create an entity with attributes, tags, and abilities
- [ ] Activate an ability: verify cost is deducted, cooldown is applied, effect hits target
- [ ] Wait for cooldown to expire, activate again: verify it works
- [ ] Try to activate while on cooldown: verify it fails

### Effect Interactions
- [ ] Apply a DoT (burn): verify periodic ticks reduce health each period
- [ ] Apply a buff (war cry): verify attribute modifier is active during duration
- [ ] Wait for buff to expire: verify attribute returns to base value
- [ ] Apply immunity (arcane shield with Immune.Damage.Physical): verify physical damage is blocked
- [ ] Apply fire damage while immune to physical: verify fire damage still lands

### Tag Interactions
- [ ] Stun an entity: verify it can't activate abilities while stunned
- [ ] Silence an entity: verify spells fail but physical abilities succeed
- [ ] Kill an entity (health → 0): verify State.Dead is applied, all abilities fail

### Stacking and Edge Cases
- [ ] Apply two burns: verify stacking policy works (refresh, stack, highest, etc.)
- [ ] Apply a heal that would exceed max health: verify clamping
- [ ] Apply a cost that would reduce mana below 0: verify it's rejected at CanActivate
- [ ] Remove a buff early (cleanse): verify modifiers are removed and attributes recalculate

### Cue System
- [ ] Verify instant effects emit burst cues
- [ ] Verify duration effects emit loop_start on apply and loop_end on expiry
- [ ] Verify periodic effects emit burst cues each tick
- [ ] Verify hierarchical matching works (fire damage triggers both specific and generic handlers)

### Full Battle
- [ ] Run a warrior vs. mage battle for 30+ seconds
- [ ] Verify no crashes, no NaN values, no infinite loops
- [ ] Verify the log shows a coherent sequence of events
- [ ] Verify someone eventually dies (game reaches an end state)

---

## Exercise

Build the complete system. This is the capstone — integrate everything from Modules 0–6.

**Minimum viable scope:**

1. **Two character types** — different attribute spreads. Warrior (high health, stamina, physical abilities) and Mage (low health, high mana, spell abilities).

2. **At least 4 abilities per character** — covering instant damage, DoT, self-buff, and at least one defensive/utility ability. See Section 4 for example definitions.

3. **Effect interactions via tags** — stun prevents casting, silence blocks spells but not physical, immunity blocks specific damage types, fire removes frozen, etc. At least 3 non-trivial interactions.

4. **Cue system** — every ability activation and effect application emits a cue. Handlers provide feedback (print/log or actual particles/sounds). Looping cues for duration effects.

5. **Automated battle** — AI-controlled or scripted. Both characters use abilities, effects interact, someone wins. The full pipeline runs end-to-end.

6. **Comprehensive logging** — every ability activation, requirement check, cost payment, effect application, tag change, and cue emission is logged. The log should tell a complete story of the battle.

**Test scenario:**

Run a warrior vs. mage battle. Verify this sequence occurs naturally through the AI:
1. Mage casts Arcane Shield (grants Immune.Damage.Physical)
2. Warrior uses Slash → blocked by immunity tag. No damage.
3. Mage casts Fireball → 40 fire damage + burn DoT
4. Warrior uses Shield Bash → stuns mage for 2s
5. While stunned, mage can't cast (verify Fireball/Heal fail)
6. Stun expires, mage casts Heal
7. Arcane Shield expires, warrior's Slash now works
8. Battle continues until one entity reaches 0 health → State.Dead
9. Dead entity can't use abilities (verify)

**Stretch goals:**
- Add a third character type (Rogue? Healer? Ranger?) with unique abilities.
- Implement one async ability (channeled heal or charged shot) using Module 5 patterns.
- If using Love2D or Godot: add actual visual feedback (health bars, particle effects, floating damage numbers) through the cue system.
- Implement effect cleansing: an ability that removes all effects matching `Status.*` from the target.
- Add resource regeneration as infinite-duration periodic effects.
- Build a replay viewer that reads the log and shows the battle step by step.

---

## Read

- GASDocumentation — complete: https://github.com/tranek/GASDocumentation — reread the entire document now that you understand every concept. It reads very differently the second time.
- GASDocumentation — Networking: https://github.com/tranek/GASDocumentation#concepts-p — prediction, reconciliation, and replicated ability state. Understand the model even if building single-player.
- Source code of open-source GAS implementations — search GitHub for "gameplay ability system" in Lua, GDScript, C#, or your preferred language. Reading someone else's integration decisions is invaluable at this stage.
- Game Programming Patterns (complete): https://gameprogrammingpatterns.com — the Command, Observer, State, and Component chapters are all directly relevant to what you've built.
- "Networking Gameplay Abilities" GDC talks — search for presentations on ability system networking in action RPGs and MMOs. The architecture you've built maps directly to how production games handle this.

---

## Summary

The capstone module integrates every layer: attributes with modifier pipelines, hierarchical tags for state and requirements, data-driven effects with duration and stacking, ability lifecycles with costs and cooldowns, async patterns for multi-frame abilities, and decoupled cue feedback.

The ASC is the integration point — the single API surface that external code uses. Characters are defined as data configurations. Abilities reference effects. Effects modify attributes and tags. Tags gate ability activation. Cues provide feedback. The loop is complete.

The key insight from building the full system: the individual pieces are simple. Attributes are maps with recalculation. Tags are sets with hierarchy. Effects are data bundles with timers. Abilities are lifecycle wrappers. The complexity is in *composition* — how the pieces interact when combined. That composition is what you've been building toward, and it's what makes a data-driven ability system powerful.

You now have the architectural knowledge to build ability systems for any game, in any engine. The patterns are universal. The vocabulary is shared. And the next time someone asks "how should we handle ability interactions?" — you know the answer: attributes, tags, effects, abilities, cues.
