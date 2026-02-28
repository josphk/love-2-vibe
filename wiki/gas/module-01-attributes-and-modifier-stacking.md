# Module 1: Attributes & Modifier Stacking

**Part of:** [GAS Learning Roadmap](gas-learning-roadmap.md)
**Estimated study time:** 3–4 hours
**Prerequisites:** [Module 0: The Case for a Gameplay Ability System](module-00-the-case-for-gas.md)

---

## Overview

Every ability system operates on numbers — health, mana, attack power, movement speed, fire resistance. In a naive implementation, you store `health = 100` and modify it directly: `health = health - 40`. But direct modification hides a surprising amount of complexity. What's the base health vs. the current health? If a buff gives +20% health, does another +20% stack additively or multiplicatively? If you remove the first buff, how do you recalculate? What about flat bonuses vs. percentage bonuses — which applies first?

This module builds the numeric foundation for the entire ability system. You'll implement **attributes** (named numeric values with base and current values), **modifiers** (typed operations applied by effects), and a **modifier pipeline** (the ordered process that derives a current value from a base value and all active modifiers). Get this right and every buff, debuff, stat bonus, and damage calculation flows through a single, predictable pipeline. Get it wrong and you'll be chasing stacking bugs for the rest of your project.

By the end of this module you'll have a working `AttributeSet` with modifier add/remove/recalculate operations that handles the classic RPG scenarios: flat bonuses, percentage multipliers, stacking policies, and source-tracked modifier removal.

---

## 1. Base Value vs. Current Value

The single most important distinction in an attribute system is between **base** and **current** value.

- **Base value** — The permanent, underlying stat. Set by character level, equipment, talent points, or other persistent sources. Changes to the base value are relatively rare and intentional. When a character levels up and gains +5 max health, that modifies the base value.

- **Current value** — The result of applying all active modifiers to the base value. This is what the game actually reads. When code asks "what's this character's attack power?", it gets the current value. The current value is always derived — you never set it directly. You set the base value and add/remove modifiers; the system calculates the current value.

This split is essential because temporary effects (buffs, debuffs, status effects) should never touch the base value. If a 10-second buff grants +20% attack power, it adds a modifier. When the buff expires, the modifier is removed, and the current value is recalculated from the base. If you'd modified the base value directly, you'd need to remember the exact modification to reverse it — and reversing modifications in the right order with the right values is a bug factory.

**Pseudocode:**
```
Attribute:
    name: string
    base_value: number
    current_value: number    // derived, never set directly
    modifiers: list          // all active modifiers on this attribute

    get_value() -> current_value
    set_base(new_base):
        base_value = new_base
        recalculate()
```

**Lua:**
```lua
local function Attribute(name, base)
    return {
        name = name,
        base_value = base,
        current_value = base,
        modifiers = {},
    }
end

-- Never read base_value for gameplay decisions. Always read current_value.
local health = Attribute("health", 100)
print(health.current_value)  -- 100
```

**GDScript:**
```gdscript
class_name Attribute

var attribute_name: String
var base_value: float
var current_value: float
var modifiers: Array = []

func _init(p_name: String, base: float):
    attribute_name = p_name
    base_value = base
    current_value = base
```

The exception to "never touch base" is **instant effects** — one-shot damage or healing. When a fireball deals 40 damage, it modifies the base value of health directly (or, more precisely, modifies health's "current base" — the value before temporary modifiers are applied). This is because instant effects have no duration and no modifier to track. More on this distinction in Module 3.

---

## 2. Modifier Types: Add, Multiply, Override

A modifier is a typed operation on an attribute. The three fundamental types are:

**Add (Flat)** — Adds a fixed amount. `+10 attack power`, `-5 movement speed`, `+50 max health`. Simple arithmetic addition.

**Multiply (Percentage)** — Multiplies the value. `×1.2` means +20%. `×0.7` means -30%. Applied after all flat additions. Note: express multipliers as raw multipliers (1.2), not percentages (20%). This avoids ambiguity about whether 20% means "add 20%" or "multiply by 0.2."

**Override** — Sets the value to a specific number, ignoring base and all other modifiers. `= 0 movement speed` (rooted in place), `= 999 attack power` (debug mode). Overrides are rare and should be used sparingly — they bypass the pipeline.

**Why order matters:**

Base attack = 20. Modifiers: +5 flat, ×1.5 multiply.

- Add first, then multiply: (20 + 5) × 1.5 = **37.5**
- Multiply first, then add: (20 × 1.5) + 5 = **35**

These are different results from the same modifiers. The pipeline order defines which you get. GAS and most RPG systems use **Add → Multiply → Override**, which is the first calculation above. This is the conventional order, and you should use it unless you have a specific design reason not to.

**Pseudocode:**
```
Modifier:
    type: "add" | "multiply" | "override"
    value: number
    source_id: string     // who applied this modifier

Pipeline order: Add → Multiply → Override

recalculate(attribute):
    value = attribute.base_value

    // Phase 1: Apply all Add modifiers
    for mod in attribute.modifiers where mod.type == "add":
        value = value + mod.value

    // Phase 2: Apply all Multiply modifiers
    for mod in attribute.modifiers where mod.type == "multiply":
        value = value * mod.value

    // Phase 3: Apply Override (last one wins)
    for mod in attribute.modifiers where mod.type == "override":
        value = mod.value

    attribute.current_value = value
```

**Lua:**
```lua
local MOD_ADD      = "add"
local MOD_MULTIPLY = "multiply"
local MOD_OVERRIDE = "override"

local function Modifier(mod_type, value, source_id)
    return {
        type = mod_type,
        value = value,
        source_id = source_id,
    }
end

local function recalculate(attribute)
    local value = attribute.base_value

    -- Phase 1: Flat additions
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_ADD then
            value = value + mod.value
        end
    end

    -- Phase 2: Multiplicative
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_MULTIPLY then
            value = value * mod.value
        end
    end

    -- Phase 3: Override (last override wins)
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_OVERRIDE then
            value = mod.value
        end
    end

    attribute.current_value = value
end
```

**GDScript:**
```gdscript
enum ModType { ADD, MULTIPLY, OVERRIDE }

class Modifier:
    var type: ModType
    var value: float
    var source_id: String

    func _init(p_type: ModType, p_value: float, p_source: String):
        type = p_type
        value = p_value
        source_id = p_source

func recalculate(attribute: Attribute) -> void:
    var value: float = attribute.base_value

    # Phase 1: Flat additions
    for mod in attribute.modifiers:
        if mod.type == ModType.ADD:
            value += mod.value

    # Phase 2: Multiplicative
    for mod in attribute.modifiers:
        if mod.type == ModType.MULTIPLY:
            value *= mod.value

    # Phase 3: Override (last override wins)
    for mod in attribute.modifiers:
        if mod.type == ModType.OVERRIDE:
            value = mod.value

    attribute.current_value = value
```

---

## 3. Adding and Removing Modifiers

The modifier lifecycle is simple: add a modifier → recalculate → current value updates. Remove a modifier → recalculate → current value updates. Never manually adjust the current value — always add/remove modifiers and let the pipeline handle it.

**Source tracking** is critical. Every modifier records which effect or ability created it (`source_id`). When that effect expires, you remove all modifiers with that source. This is the only clean way to handle buff expiration — you don't need to remember "I added +10 attack," you just remove everything tagged with that effect's ID.

**Pseudocode:**
```
add_modifier(attribute, modifier):
    attribute.modifiers.append(modifier)
    recalculate(attribute)

remove_modifiers_by_source(attribute, source_id):
    attribute.modifiers = attribute.modifiers.filter(m => m.source_id != source_id)
    recalculate(attribute)
```

**Lua:**
```lua
local function add_modifier(attribute, modifier)
    table.insert(attribute.modifiers, modifier)
    recalculate(attribute)
end

local function remove_modifiers_by_source(attribute, source_id)
    local kept = {}
    for _, mod in ipairs(attribute.modifiers) do
        if mod.source_id ~= source_id then
            table.insert(kept, mod)
        end
    end
    attribute.modifiers = kept
    recalculate(attribute)
end

-- Example usage:
local attack = Attribute("attack_power", 20)

-- A buff grants +5 flat and ×1.5 multiply
add_modifier(attack, Modifier(MOD_ADD, 5, "buff_123"))
add_modifier(attack, Modifier(MOD_MULTIPLY, 1.5, "buff_123"))
print(attack.current_value)  -- (20 + 5) × 1.5 = 37.5

-- Buff expires — remove all modifiers from that source
remove_modifiers_by_source(attack, "buff_123")
print(attack.current_value)  -- 20 (back to base)
```

**GDScript:**
```gdscript
func add_modifier(attribute: Attribute, modifier: Modifier) -> void:
    attribute.modifiers.append(modifier)
    recalculate(attribute)

func remove_modifiers_by_source(attribute: Attribute, source_id: String) -> void:
    attribute.modifiers = attribute.modifiers.filter(
        func(mod): return mod.source_id != source_id
    )
    recalculate(attribute)

# Example:
var attack = Attribute.new("attack_power", 20.0)
add_modifier(attack, Modifier.new(ModType.ADD, 5.0, "buff_123"))
add_modifier(attack, Modifier.new(ModType.MULTIPLY, 1.5, "buff_123"))
print(attack.current_value)  # 37.5

remove_modifiers_by_source(attack, "buff_123")
print(attack.current_value)  # 20.0
```

Notice how removal is trivially correct. You don't need to reverse the math (subtract 5, divide by 1.5). You just remove the modifiers and recalculate from scratch. This is why recalculation from base is always preferable to incremental patching — it's impossible to get the order wrong.

---

## 4. Stacking Policies

What happens when two "attack speed +20%" modifiers are applied to the same target? This is the **stacking** question, and it's a game design decision, not a technical one. The attribute system needs to support the designer's chosen policy.

Common stacking policies:

**Stack Additively** — Both modifiers apply. Two "+20%" modifiers give +40% total. This is the simplest approach and what most games use for flat bonuses. For multiplicative modifiers, "additive stacking" means combining them before multiplying: `× (1.0 + 0.2 + 0.2)` = `× 1.4`.

**Stack Multiplicatively** — Each modifier applies independently. Two "×1.2" modifiers give `× 1.2 × 1.2` = `× 1.44`. This is standard in the basic pipeline — each multiply modifier is applied in sequence. It produces diminishing returns for stacking, which many designers prefer.

**Highest Only** — Only the strongest modifier of a given type applies. Two "+20%" and "+30%" modifiers: only +30% counts. Common for percentage-based buffs where stacking would be overpowered.

**Refresh Duration Only** — Reapplying the same effect resets its timer but doesn't add a second modifier. The stat bonus stays the same; only the duration extends. Common for "refreshable" buffs.

**Stack with Cap** — Modifiers stack, but only up to N stacks. Poison stacks up to 5 times, then additional applications only refresh duration. Each stack applies its own modifier, so 5 stacks of "5 damage/sec" poison gives 25 damage/sec.

**Implementing stacking:**

Stacking policy belongs on the *effect* that creates modifiers, not on the attribute or modifier itself. The attribute system doesn't care about stacking — it just has a list of modifiers and a pipeline. Stacking logic runs at *application time*: when an effect tries to add modifiers, the system checks the stacking policy and decides whether to add new modifiers, replace existing ones, or reject the application.

**Pseudocode:**
```
apply_effect_modifiers(attribute, effect, source_id):
    existing = attribute.modifiers.filter(m => m.source_id starts with effect.id)
    stack_count = existing.count()

    switch effect.stacking_policy:
        case "stack_additive":
            // Always add new modifiers
            for mod_def in effect.modifiers:
                add_modifier(attribute, Modifier(mod_def.type, mod_def.value, source_id))

        case "highest_only":
            // Replace if new value is higher
            for mod_def in effect.modifiers:
                existing_mod = find_existing(existing, mod_def.type)
                if existing_mod == null or mod_def.value > existing_mod.value:
                    remove_modifiers_by_source(attribute, existing_mod.source_id)
                    add_modifier(attribute, Modifier(mod_def.type, mod_def.value, source_id))

        case "refresh_duration":
            // Don't add new modifiers — just let the effect system reset the timer
            if stack_count == 0:
                for mod_def in effect.modifiers:
                    add_modifier(attribute, Modifier(mod_def.type, mod_def.value, source_id))

        case "stack_with_cap":
            if stack_count < effect.max_stacks:
                for mod_def in effect.modifiers:
                    add_modifier(attribute, Modifier(mod_def.type, mod_def.value, source_id))
```

**Lua:**
```lua
local function count_stacks(attribute, effect_id)
    local count = 0
    for _, mod in ipairs(attribute.modifiers) do
        if mod.source_id:find(effect_id, 1, true) == 1 then
            count = count + 1
        end
    end
    return count
end

local function apply_with_stacking(attribute, effect, source_id)
    local policy = effect.stacking_policy or "stack_additive"
    local stacks = count_stacks(attribute, effect.id)

    if policy == "stack_additive" then
        -- Always add
        for _, mod_def in ipairs(effect.modifiers) do
            add_modifier(attribute, Modifier(mod_def.type, mod_def.value, source_id))
        end

    elseif policy == "refresh_duration" then
        -- Only add modifiers on first application
        if stacks == 0 then
            for _, mod_def in ipairs(effect.modifiers) do
                add_modifier(attribute, Modifier(mod_def.type, mod_def.value, source_id))
            end
        end
        -- Duration refresh is handled by the effect timer, not here

    elseif policy == "stack_with_cap" then
        if stacks < (effect.max_stacks or 1) then
            for _, mod_def in ipairs(effect.modifiers) do
                add_modifier(attribute, Modifier(mod_def.type, mod_def.value, source_id))
            end
        end
    end
end
```

---

## 5. The AttributeSet

An `AttributeSet` groups related attributes for an entity. A character might have a "core" attribute set (health, max_health, mana, max_mana) and a "combat" attribute set (attack_power, defense, critical_chance). The set provides a single point of access: `attributes:get("health")`.

**Pseudocode:**
```
AttributeSet:
    attributes: map<string, Attribute>

    add(name, base_value):
        attributes[name] = Attribute(name, base_value)

    get(name) -> Attribute:
        return attributes[name]

    get_value(name) -> number:
        return attributes[name].current_value

    set_base(name, value):
        attributes[name].base_value = value
        recalculate(attributes[name])
```

**Lua:**
```lua
local function AttributeSet()
    local self = {
        attributes = {},
    }

    function self.add(name, base_value)
        self.attributes[name] = Attribute(name, base_value)
    end

    function self.get(name)
        return self.attributes[name]
    end

    function self.get_value(name)
        local attr = self.attributes[name]
        return attr and attr.current_value or 0
    end

    function self.set_base(name, value)
        local attr = self.attributes[name]
        if attr then
            attr.base_value = value
            recalculate(attr)
        end
    end

    return self
end

-- Usage:
local attrs = AttributeSet()
attrs.add("health", 100)
attrs.add("max_health", 100)
attrs.add("attack_power", 20)
attrs.add("move_speed", 5.0)
attrs.add("mana", 80)
attrs.add("max_mana", 80)

print(attrs.get_value("health"))       -- 100
print(attrs.get_value("attack_power")) -- 20
```

**GDScript:**
```gdscript
class_name AttributeSet

var attributes: Dictionary = {}

func add(attr_name: String, base_value: float) -> void:
    attributes[attr_name] = Attribute.new(attr_name, base_value)

func get_attribute(attr_name: String) -> Attribute:
    return attributes.get(attr_name)

func get_value(attr_name: String) -> float:
    var attr = attributes.get(attr_name)
    return attr.current_value if attr else 0.0

func set_base(attr_name: String, value: float) -> void:
    var attr = attributes.get(attr_name)
    if attr:
        attr.base_value = value
        recalculate(attr)

# Usage:
var attrs = AttributeSet.new()
attrs.add("health", 100.0)
attrs.add("max_health", 100.0)
attrs.add("attack_power", 20.0)
attrs.add("move_speed", 5.0)
```

---

## 6. Clamping and Derived Attributes

Two common needs that sit on top of the basic pipeline:

### Clamping

Health can't go below 0 or above max_health. Mana can't exceed max_mana. Movement speed shouldn't go negative. **Clamping** enforces these bounds after recalculation.

The simplest approach: each attribute has optional `min_value` and `max_value` fields. After the pipeline runs, clamp the result. For attributes clamped against another attribute (health ≤ max_health), use a reference:

```lua
local function Attribute(name, base, min_val, max_ref)
    return {
        name = name,
        base_value = base,
        current_value = base,
        modifiers = {},
        min_value = min_val,     -- hard floor (e.g., 0)
        max_ref = max_ref,       -- reference to another attribute for ceiling
    }
end

local function recalculate(attribute, attribute_set)
    local value = attribute.base_value

    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_ADD then
            value = value + mod.value
        end
    end
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_MULTIPLY then
            value = value * mod.value
        end
    end
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_OVERRIDE then
            value = mod.value
        end
    end

    -- Clamping
    if attribute.min_value then
        value = math.max(value, attribute.min_value)
    end
    if attribute.max_ref and attribute_set then
        local max_val = attribute_set.get_value(attribute.max_ref)
        value = math.min(value, max_val)
    end

    attribute.current_value = value
end
```

### Derived Attributes

Some attributes are calculated from others rather than having their own base values. Physical damage = attack_power × weapon_multiplier. Effective health = health × (1 + armor/100). These are **derived attributes**.

The simplest implementation: a derived attribute has a calculation function instead of a base value. Whenever a source attribute changes, recalculate derived attributes that depend on it. For a small number of derivations, you can recalculate all derived attributes after any change. For larger systems, build a dependency graph.

```lua
-- Simple approach: recalculate derived attributes after any change
local function recalculate_derived(attribute_set)
    -- Effective HP = health * (1 + armor/100)
    local health = attribute_set.get_value("health")
    local armor = attribute_set.get_value("armor")
    local effective_hp = health * (1 + armor / 100)
    attribute_set.set_base("effective_hp", effective_hp)
end
```

For most games, manual dependency tracking is fine. You rarely have more than a handful of derived attributes, and recalculating them all is cheap.

---

## 7. Common Pitfalls

**Modifying current value directly.** Never do `attribute.current_value = attribute.current_value - 40`. This bypasses the pipeline and will be overwritten on the next recalculation. For instant damage, modify `base_value` and recalculate. For temporary effects, add modifiers.

**Incremental modification instead of full recalculation.** It's tempting to add 10 when a modifier arrives and subtract 10 when it leaves. This breaks when modifier interactions are order-dependent (and they always are eventually). Always recalculate from scratch: base → apply all adds → apply all multiplies → apply overrides → clamp. It's a few microseconds and it's always correct.

**Forgetting to recalculate.** Every operation that changes modifiers or base values must trigger recalculation. If you add a modifier without recalculating, the current value is stale until something else triggers a recalculate. Use the `add_modifier` / `remove_modifiers_by_source` functions consistently — they call `recalculate` internally.

**Not tracking modifier sources.** If you don't know which effect added a modifier, you can't cleanly remove it when the effect expires. Every modifier needs a `source_id`. This becomes critical in Module 3 when effects have durations.

**Mixing up percentage representation.** Is "+20% attack" represented as `0.2` or `1.2`? If it's `0.2`, do you add it or multiply by it? Decide once and be consistent. The cleanest representation is: multiply modifiers store the raw multiplier (`1.2` for +20%, `0.8` for -20%). The pipeline multiplies by this value directly. No ambiguity.

---

## 8. Full Working Example

Here's a complete, testable attribute system that demonstrates all the concepts:

**Lua:**
```lua
------------------------------------------------------
-- Attribute System — Complete Example
------------------------------------------------------

local MOD_ADD      = "add"
local MOD_MULTIPLY = "multiply"
local MOD_OVERRIDE = "override"

-- Modifier constructor
local function Modifier(mod_type, value, source_id)
    return {
        type = mod_type,
        value = value,
        source_id = source_id,
    }
end

-- Attribute constructor
local function Attribute(name, base, min_val)
    return {
        name = name,
        base_value = base,
        current_value = base,
        modifiers = {},
        min_value = min_val or nil,
    }
end

-- Recalculate current value from base + all modifiers
local function recalculate(attribute)
    local value = attribute.base_value

    -- Phase 1: Flat additions
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_ADD then
            value = value + mod.value
        end
    end

    -- Phase 2: Multiplicative
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_MULTIPLY then
            value = value * mod.value
        end
    end

    -- Phase 3: Override (last one wins)
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_OVERRIDE then
            value = mod.value
        end
    end

    -- Clamping
    if attribute.min_value then
        value = math.max(value, attribute.min_value)
    end

    attribute.current_value = value
end

-- Add a modifier and recalculate
local function add_modifier(attribute, modifier)
    table.insert(attribute.modifiers, modifier)
    recalculate(attribute)
end

-- Remove all modifiers from a given source and recalculate
local function remove_modifiers_by_source(attribute, source_id)
    local kept = {}
    for _, mod in ipairs(attribute.modifiers) do
        if mod.source_id ~= source_id then
            table.insert(kept, mod)
        end
    end
    attribute.modifiers = kept
    recalculate(attribute)
end

------------------------------------------------------
-- Test
------------------------------------------------------

local attack = Attribute("attack_power", 20, 0)

print("Base attack:", attack.current_value)
-- Output: Base attack: 20

-- Buff: +5 flat attack from "sword_enchant"
add_modifier(attack, Modifier(MOD_ADD, 5, "sword_enchant"))
print("After +5 flat:", attack.current_value)
-- Output: After +5 flat: 25

-- Buff: ×1.5 attack from "battle_cry"
add_modifier(attack, Modifier(MOD_MULTIPLY, 1.5, "battle_cry"))
print("After ×1.5:", attack.current_value)
-- Output: After ×1.5: 37.5
-- Calculation: (20 + 5) × 1.5 = 37.5

-- Another flat buff: +10 from "food_buff"
add_modifier(attack, Modifier(MOD_ADD, 10, "food_buff"))
print("After +10 flat:", attack.current_value)
-- Output: After +10 flat: 52.5
-- Calculation: (20 + 5 + 10) × 1.5 = 52.5

-- Remove sword enchant
remove_modifiers_by_source(attack, "sword_enchant")
print("After removing enchant:", attack.current_value)
-- Output: After removing enchant: 45.0
-- Calculation: (20 + 10) × 1.5 = 45.0

-- Remove battle cry
remove_modifiers_by_source(attack, "battle_cry")
print("After removing battle cry:", attack.current_value)
-- Output: After removing battle cry: 30
-- Calculation: 20 + 10 = 30

-- Remove food buff
remove_modifiers_by_source(attack, "food_buff")
print("Back to base:", attack.current_value)
-- Output: Back to base: 20
```

**GDScript:**
```gdscript
extends Node

enum ModType { ADD, MULTIPLY, OVERRIDE }

class Modifier:
    var type: int  # ModType enum
    var value: float
    var source_id: String
    func _init(p_type: int, p_value: float, p_source: String):
        type = p_type; value = p_value; source_id = p_source

class Attribute:
    var attribute_name: String
    var base_value: float
    var current_value: float
    var modifiers: Array = []
    var min_value: float = -INF

    func _init(p_name: String, base: float, p_min: float = -INF):
        attribute_name = p_name
        base_value = base
        current_value = base
        min_value = p_min

func recalculate(attr: Attribute) -> void:
    var value: float = attr.base_value
    for mod in attr.modifiers:
        if mod.type == ModType.ADD:
            value += mod.value
    for mod in attr.modifiers:
        if mod.type == ModType.MULTIPLY:
            value *= mod.value
    for mod in attr.modifiers:
        if mod.type == ModType.OVERRIDE:
            value = mod.value
    attr.current_value = max(value, attr.min_value)

func add_modifier(attr: Attribute, mod: Modifier) -> void:
    attr.modifiers.append(mod)
    recalculate(attr)

func remove_modifiers_by_source(attr: Attribute, source_id: String) -> void:
    attr.modifiers = attr.modifiers.filter(
        func(m): return m.source_id != source_id
    )
    recalculate(attr)

func _ready():
    var attack = Attribute.new("attack_power", 20.0, 0.0)

    add_modifier(attack, Modifier.new(ModType.ADD, 5.0, "sword_enchant"))
    print("After +5 flat: ", attack.current_value)  # 25.0

    add_modifier(attack, Modifier.new(ModType.MULTIPLY, 1.5, "battle_cry"))
    print("After ×1.5: ", attack.current_value)  # 37.5

    remove_modifiers_by_source(attack, "sword_enchant")
    print("After removing enchant: ", attack.current_value)  # 30.0

    remove_modifiers_by_source(attack, "battle_cry")
    print("Back to base: ", attack.current_value)  # 20.0
```

---

## 9. Additive vs. Multiplicative Percentage Stacking

This is a design decision that deserves special attention because it affects game balance significantly.

**Multiplicative stacking:** Each percentage modifier is applied independently. Two `×1.2` modifiers give `× 1.2 × 1.2 = × 1.44` (+44%). Three give `× 1.728` (+72.8%). This produces diminishing returns — each additional modifier adds less than the previous one (in absolute terms). Many designers prefer this because it naturally prevents extreme stat inflation.

**Additive stacking:** Percentage modifiers are summed before applying. Two "+20%" modifiers give `× (1.0 + 0.2 + 0.2) = × 1.4` (+40%). Three give `× 1.6` (+60%). This produces linear scaling — each additional modifier adds the same amount. Simpler for players to understand, but can lead to runaway scaling.

To support additive percentage stacking, you need a separate modifier phase. Instead of applying each multiply modifier independently, you sum their deltas and apply once:

```lua
-- Additive percentage stacking:
local function recalculate_additive_percent(attribute)
    local value = attribute.base_value

    -- Phase 1: Flat additions
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_ADD then
            value = value + mod.value
        end
    end

    -- Phase 2: Sum all percentage modifiers, apply once
    local percent_sum = 0
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_MULTIPLY then
            percent_sum = percent_sum + (mod.value - 1.0)
            -- mod.value of 1.2 means +20%, so delta is 0.2
        end
    end
    value = value * (1.0 + percent_sum)

    -- Phase 3: Override
    for _, mod in ipairs(attribute.modifiers) do
        if mod.type == MOD_OVERRIDE then
            value = mod.value
        end
    end

    attribute.current_value = value
end
```

Some games use both: one pipeline phase for "additive percentages" (same-source stacking) and another for "multiplicative percentages" (cross-source stacking). Path of Exile is a well-known example — "increased" modifiers stack additively within a category, while "more" modifiers stack multiplicatively with everything.

For your first implementation, pick one approach. Multiplicative is the default in the standard pipeline and the simpler choice. You can add additive stacking later if your game design requires it.

---

## Exercise

Implement an `AttributeSet` in Lua (or your preferred language). Create attributes for `health`, `max_health`, `attack_power`, and `move_speed`. Implement a `Modifier` with type (add/multiply/override), value, and source ID. Write `add_modifier(attribute, modifier)`, `remove_modifiers_by_source(attribute, source_id)`, and `recalculate(attribute)`.

**Test cases to verify:**

1. Base attack = 20. Add a +5 flat modifier. Current should be 25.
2. Add a ×1.5 multiply modifier. Current should be (20 + 5) × 1.5 = 37.5.
3. Remove the flat modifier. Current should be 20 × 1.5 = 30.
4. Remove the multiply modifier. Current should be 20.
5. Base move_speed = 5. Add a ×0 override modifier (rooted). Current should be 0.
6. Remove the override. Current should be 5.
7. Base health = 100 (min: 0). Add a -150 flat modifier. Current should be 0 (clamped), not -50.

**Stretch goals:**
- Implement a "highest only" stacking policy: when applying a multiply modifier, check if a stronger one from the same effect type already exists.
- Add an `on_change` callback to attributes that fires whenever current_value changes. This will be useful for Module 6 (cues).
- Implement derived attributes: `effective_hp = health × (1 + armor/100)`.

---

## Read

- **GASDocumentation — Attributes and AttributeSets:** https://github.com/tranek/GASDocumentation#concepts-a — covers the base/current value split and attribute aggregation.
- **"Game Attribute Systems"** — search for blog posts on RPG stat systems and modifier stacking. The pattern predates GAS and appears in every RPG engine.
- **"Modifier Stacking in RPGs"** — stacking rules are a game design decision, not just a code one. Read design discussions from games like Path of Exile, Diablo, and Dota 2 for different approaches.

---

## Summary

An **attribute** has a **base value** (permanent) and a **current value** (derived). **Modifiers** are typed operations (add, multiply, override) applied by effects and tracked by source. The **pipeline** recalculates current from base by applying all modifiers in a defined order: flat additions → multiplicative → overrides → clamping.

Key rules:
- Never modify `current_value` directly. Add/remove modifiers and recalculate.
- Never incrementally patch. Recalculate from scratch — it's cheap and always correct.
- Every modifier tracks its source. Remove by source when effects expire.
- Stacking policy is a game design decision defined per-effect, not a system-wide setting.

Next up: [Module 2 — Gameplay Tags](module-02-gameplay-tags.md), where you build the hierarchical tag system that powers every requirement check in the ability system.
