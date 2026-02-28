# Module 4: Gameplay Abilities

**Part of:** [GAS Learning Roadmap](gas-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 1: Attributes & Modifier Stacking](module-01-attributes-and-modifier-stacking.md), [Module 2: Gameplay Tags](module-02-gameplay-tags.md), [Module 3: Gameplay Effects](module-03-gameplay-effects.md)

---

## Overview

Everything you've built so far — attributes, tags, effects — is infrastructure. Abilities are where that infrastructure meets the player. A "Fireball" ability checks requirements, pays a mana cost, enters cooldown, and applies a fire damage effect to a target. Each step uses systems you've already built. Abilities themselves are surprisingly thin — most of the heavy lifting already happened in Modules 1–3.

An ability is a player-facing action: the thing bound to a key, dragged onto a hotbar, or triggered by AI. It wraps a lifecycle around effect application. Without abilities, you'd call `apply_effect()` directly — abilities add the "can I do this right now?" and "what does it cost?" layers that make effect application feel like gameplay.

By the end of this module you'll have a working ability system where characters can activate abilities with requirements, costs, and cooldowns — all built on the attribute/tag/effect pipeline from previous modules.

---

## 1. The Ability Lifecycle

Every ability activation follows the same sequence. This is the pipeline — it's short, and every step has a clear job:

**CanActivate → CommitCost → Activate → End**

**CanActivate** is the gatekeeper. Before anything happens, you check: does the caster meet the activation requirements? This is a tag query on the caster's tag container. A typical ability requires `State.Alive` and blocks on `State.Stunned`, `State.Silenced`, and its own cooldown tag (`Cooldown.Ability.Fireball`). If any requirement fails, the ability doesn't activate. No mana is spent, no cooldown starts, nothing happens.

**CommitCost** deducts the resource cost. Fireball costs 30 mana — this step applies an instant effect that modifies `mana` by -30. The cost check happens *before* the deduction: verify `mana.current >= cost`, then apply. Some implementations combine the check into CanActivate, others keep it separate. Either works — the important thing is that costs are checked before they're committed.

**Activate** is the actual gameplay. Apply effects to the target, spawn a projectile, start an animation. For simple abilities, this is one function call: `apply_effect(target, fire_damage_effect, context)`. For complex abilities that span multiple frames (channeling, charging), this is where ability tasks take over (Module 5).

**End** cleans up. The ability returns to idle. For instant abilities, End fires immediately after Activate. For ongoing abilities (channels, combos), End fires when the ability completes or is interrupted. End is where you remove any temporary state the ability created — tags granted during casting, visual indicators, held references.

**Pseudocode:**
```
function try_activate_ability(asc, ability, target):
    // Phase 1: Can we do this?
    if not can_activate(asc, ability):
        return false

    // Phase 2: Pay the cost
    if not commit_cost(asc, ability):
        return false

    // Phase 3: Do the thing
    activate(asc, ability, target)
    return true

function can_activate(asc, ability):
    // Check tag requirements on the caster
    if not ability.requirements:check(asc.tags):
        return false

    // Check resource cost
    if ability.cost_attribute and ability.cost_amount:
        current = asc.attributes:get_current(ability.cost_attribute)
        if current < ability.cost_amount:
            return false

    return true

function commit_cost(asc, ability):
    if ability.cost_attribute and ability.cost_amount:
        // Apply instant effect to deduct cost
        cost_effect = make_instant_effect(ability.cost_attribute, "add", -ability.cost_amount)
        apply_effect(asc, cost_effect, {source = asc})
    return true

function activate(asc, ability, target):
    // Apply cooldown
    if ability.cooldown_duration > 0:
        cooldown_effect = make_duration_effect(
            tags_to_grant = {ability.cooldown_tag},
            duration = ability.cooldown_duration
        )
        apply_effect(asc, cooldown_effect, {source = asc})

    // Apply ability effects to target
    context = {source = asc, ability = ability}
    for each effect in ability.effects:
        apply_effect(target, effect, context)

    // End immediately for instant abilities
    end_ability(asc, ability)
```

The pipeline is linear and predictable. When something goes wrong — "my ability won't fire" — you trace the pipeline: did CanActivate fail? Which requirement? Was it the cooldown tag? A missing resource? The pipeline makes debugging straightforward.

---

## 2. Activation Requirements

Activation requirements are tag queries on the caster. They use the same `TagRequirement` from Module 2 — a pair of `require_tags` (all must be present) and `block_tags` (none can be present).

A typical ability's requirements:

| Ability | Require | Block |
|---------|---------|-------|
| Fireball | `State.Alive` | `State.Stunned`, `State.Silenced`, `Cooldown.Ability.Fireball` |
| Melee Slash | `State.Alive` | `State.Stunned`, `Cooldown.Ability.Slash` |
| Heal | `State.Alive` | `State.Silenced`, `Cooldown.Ability.Heal` |
| Berserk | `State.Alive` | `State.Stunned`, `Cooldown.Ability.Berserk`, `Status.Berserk` |

Notice the patterns:

**Everything requires `State.Alive`.** Dead entities don't cast. You could also add `State.Controllable` for cases where an entity is alive but not player-controlled (mind control, cutscene).

**Physical abilities block on `State.Stunned` but not `State.Silenced`.** Silence blocks spells, not sword swings. This distinction falls out naturally from the tag system — no special-case code, just different block lists.

**Cooldown tags block re-activation.** The cooldown tag (e.g., `Cooldown.Ability.Fireball`) is granted by a duration effect when the ability activates. While the tag is present, the ability's block list prevents reactivation. When the cooldown effect expires, the tag is removed, and the ability can fire again.

**Status self-blocking.** Berserk blocks on `Status.Berserk` to prevent stacking the buff. You can't go double-berserk.

Requirements are entirely data-driven. Adding a new blocking condition — say, abilities can't activate during `State.Channeling` — means adding a tag to the block list. No code changes. A "silence" effect grants `State.Silenced`; every spell-type ability already blocks on that tag. The silence works with every spell automatically.

**Pseudocode:**
```
AbilityDefinition:
    name: string
    requirements: TagRequirement
        require_tags: ["State.Alive"]
        block_tags: ["State.Stunned", "State.Silenced", "Cooldown.Ability.Fireball"]
    cost_attribute: "mana"
    cost_amount: 30
    cooldown_duration: 3.0
    cooldown_tag: "Cooldown.Ability.Fireball"
    effects: [fire_damage_effect, burn_dot_effect]
```

**Lua:**
```lua
local fireball = {
    name = "Fireball",
    requirements = TagRequirement.new(
        {"State.Alive"},                                                   -- require
        {"State.Stunned", "State.Silenced", "Cooldown.Ability.Fireball"}   -- block
    ),
    cost_attribute = "mana",
    cost_amount = 30,
    cooldown_duration = 3.0,
    cooldown_tag = "Cooldown.Ability.Fireball",
    effects = {fire_damage_effect, burn_dot_effect},
}
```

**GDScript:**
```gdscript
var fireball := AbilityDefinition.new()
fireball.name = "Fireball"
fireball.requirements = TagRequirement.new(
    ["State.Alive"],
    ["State.Stunned", "State.Silenced", "Cooldown.Ability.Fireball"]
)
fireball.cost_attribute = "mana"
fireball.cost_amount = 30
fireball.cooldown_duration = 3.0
fireball.cooldown_tag = "Cooldown.Ability.Fireball"
fireball.effects = [fire_damage_effect, burn_dot_effect]
```

---

## 3. Costs as Attribute Checks

Ability costs use the same attribute system from Module 1. The pattern is simple: check if you can afford it, then apply an instant effect to pay it.

The most common cost is mana, but the system handles any attribute:

| Ability | Cost Attribute | Cost Amount |
|---------|---------------|-------------|
| Fireball | `mana` | 30 |
| Shield Bash | `stamina` | 25 |
| Blood Strike | `health` | 15 |
| Rage Slam | `rage` | 50 |

The cost check happens in CanActivate: `asc.attributes:get_current("mana") >= 30`. The cost payment happens in CommitCost: apply an instant effect that modifies the attribute by the negative cost amount. This goes through the normal attribute pipeline — if something modifies cost (a "reduce mana costs by 20%" modifier), it's just another modifier on the cost calculation.

**Cost reduction** is where the attribute pipeline pays off. You can model cost reduction as a modifier:

```
// "Mage Mastery" passive: spell costs reduced by 20%
// Instead of modifying every ability, add a "mana_cost_multiplier" attribute
// with a modifier: multiply × 0.8

function get_effective_cost(asc, ability):
    base_cost = ability.cost_amount
    if asc.attributes:has("mana_cost_multiplier"):
        return base_cost * asc.attributes:get_current("mana_cost_multiplier")
    return base_cost
```

Or, more simply, you can keep cost amounts fixed and add cost reduction as a game design rule applied at the CommitCost step. The attribute approach is more powerful but may be over-engineering for simpler games. Use what fits.

**Multiple costs** are possible too. An ability might cost 20 mana and 10 health (life-tap style). CanActivate checks both, CommitCost pays both. The check must be atomic — verify *all* costs can be paid before paying *any* of them.

**Pseudocode:**
```
function can_afford(asc, ability):
    for each cost in ability.costs:
        current = asc.attributes:get_current(cost.attribute)
        if current < cost.amount:
            return false
    return true

function commit_costs(asc, ability):
    // Already verified in can_afford — apply all costs
    for each cost in ability.costs:
        cost_effect = make_instant_effect(cost.attribute, "add", -cost.amount)
        apply_effect(asc, cost_effect, {source = asc})
```

**Lua:**
```lua
function can_afford(asc, ability)
    for _, cost in ipairs(ability.costs) do
        local current = asc.attributes:get_current(cost.attribute)
        if current < cost.amount then
            return false
        end
    end
    return true
end

function commit_costs(asc, ability)
    for _, cost in ipairs(ability.costs) do
        local cost_effect = make_instant_effect(cost.attribute, "add", -cost.amount)
        apply_effect(asc, cost_effect, {source = asc})
    end
end
```

**GDScript:**
```gdscript
func can_afford(asc: AbilitySystemComponent, ability: AbilityDefinition) -> bool:
    for cost in ability.costs:
        var current := asc.attributes.get_current(cost.attribute)
        if current < cost.amount:
            return false
    return true

func commit_costs(asc: AbilitySystemComponent, ability: AbilityDefinition) -> void:
    for cost in ability.costs:
        var cost_effect := make_instant_effect(cost.attribute, "add", -cost.amount)
        apply_effect(asc, cost_effect, {source = asc})
```

---

## 4. Cooldowns as Duration Effects

Cooldowns are one of the most elegant parts of the GAS architecture. They aren't a special system — they're just duration effects that grant tags.

When an ability activates, it applies a cooldown effect to the caster:

```
cooldown_effect:
    duration_type: "duration"
    duration: 3.0
    tags_to_grant: ["Cooldown.Ability.Fireball"]
    modifiers: []        // no attribute changes
```

This effect lives in the caster's active effects list, granting the `Cooldown.Ability.Fireball` tag. The ability's activation requirements block on that tag. When the 3-second duration expires, the effect is removed, the tag is revoked, and the ability can activate again.

That's it. The cooldown system is zero additional code. You already built everything it needs in Modules 2 and 3.

**Why this is powerful:**

**Cooldown reduction is just a modifier.** If a passive grants "20% cooldown reduction," you can implement it as a modifier on the cooldown duration before the effect is created. Or you can create a `cooldown_rate` attribute and apply the duration effect with a modified duration: `duration = base_duration * (1 - asc.attributes:get_current("cooldown_reduction"))`.

**Global cooldowns (GCDs) are just wider tags.** A GCD effect grants `Cooldown.GCD` for 1.5 seconds. All abilities that share the GCD block on `Cooldown.GCD`. Some abilities (like an instant-cast interrupt) skip the GCD by not including it in their block list. No special code — just tag configuration.

**Cooldown resets are just effect removal.** An ability that says "reset all cooldowns" removes all active effects whose tags match `Cooldown.*`. The tag hierarchy handles the matching. A "reset fire spell cooldowns" ability removes effects matching `Cooldown.Ability.Fire.*`.

**Cooldown displays use the effect's remaining duration.** To show a cooldown timer in the UI, find the active effect that grants the cooldown tag and read its `remaining_duration`. The data is already there.

**Pseudocode:**
```
function apply_cooldown(asc, ability):
    if ability.cooldown_duration <= 0:
        return

    // Calculate effective cooldown with any reduction
    duration = ability.cooldown_duration
    if asc.attributes:has("cooldown_reduction"):
        reduction = asc.attributes:get_current("cooldown_reduction")
        duration = duration * (1 - reduction)    // e.g., 3.0 * (1 - 0.2) = 2.4s

    cooldown_effect = EffectDefinition.new({
        duration_type = "duration",
        duration = duration,
        tags_to_grant = {ability.cooldown_tag},
    })
    apply_effect(asc, cooldown_effect, {source = asc})

function get_cooldown_remaining(asc, ability):
    for each active_effect in asc.active_effects:
        if ability.cooldown_tag in active_effect.granted_tags:
            return active_effect.remaining_duration
    return 0    // not on cooldown
```

**Lua:**
```lua
function apply_cooldown(asc, ability)
    if ability.cooldown_duration <= 0 then return end

    local duration = ability.cooldown_duration
    if asc.attributes:has("cooldown_reduction") then
        local reduction = asc.attributes:get_current("cooldown_reduction")
        duration = duration * (1 - reduction)
    end

    local cooldown_effect = EffectDefinition.new({
        duration_type = "duration",
        duration = duration,
        tags_to_grant = {ability.cooldown_tag},
    })
    apply_effect(asc, cooldown_effect, {source = asc})
end

function get_cooldown_remaining(asc, ability)
    for _, active in ipairs(asc.active_effects) do
        if active:has_granted_tag(ability.cooldown_tag) then
            return active.remaining_duration
        end
    end
    return 0
end
```

**GDScript:**
```gdscript
func apply_cooldown(asc: AbilitySystemComponent, ability: AbilityDefinition) -> void:
    if ability.cooldown_duration <= 0:
        return

    var duration := ability.cooldown_duration
    if asc.attributes.has("cooldown_reduction"):
        var reduction := asc.attributes.get_current("cooldown_reduction")
        duration = duration * (1.0 - reduction)

    var cooldown_effect := EffectDefinition.new()
    cooldown_effect.duration_type = "duration"
    cooldown_effect.duration = duration
    cooldown_effect.tags_to_grant = [ability.cooldown_tag]
    apply_effect(asc, cooldown_effect, {source = asc})

func get_cooldown_remaining(asc: AbilitySystemComponent, ability: AbilityDefinition) -> float:
    for active in asc.active_effects:
        if active.has_granted_tag(ability.cooldown_tag):
            return active.remaining_duration
    return 0.0
```

---

## 5. Ability Grants and the Ability Roster

Not every entity has every ability. A warrior has Slash, Shield Bash, Charge. A mage has Fireball, Frost Nova, Teleport. Abilities are **granted** to entities and can be **revoked** dynamically.

The set of abilities an entity can use is its **ability roster** (or granted abilities list). This is a simple list — nothing fancy. The interesting part is *when* abilities get granted and revoked:

**At character creation:** The warrior class grants a base set of abilities. This is your starting roster.

**From equipment:** Equipping a Fire Staff grants `Lightning Bolt`. Unequipping it revokes the ability. The ability is tied to the equipment — if you model equipment as infinite-duration effects, the ability grant can be part of the effect.

**From level-ups or talent trees:** Reaching level 5 grants `Shield Bash`. Taking the "Pyromancer" talent grants `Meteor`. These are permanent grants (until a respec).

**From other abilities or effects:** A "Transformation" ability might revoke your normal abilities and grant a new set. A "possession" effect might override the target's abilities entirely.

**Pseudocode:**
```
function grant_ability(asc, ability_def):
    if ability_def.name in asc.granted_abilities:
        return    // already granted
    asc.granted_abilities[ability_def.name] = ability_def

function revoke_ability(asc, ability_name):
    asc.granted_abilities[ability_name] = nil

function get_ability(asc, ability_name):
    return asc.granted_abilities[ability_name]    // nil if not granted
```

**Lua:**
```lua
function grant_ability(asc, ability_def)
    if asc.granted_abilities[ability_def.name] then
        return    -- already granted
    end
    asc.granted_abilities[ability_def.name] = ability_def
end

function revoke_ability(asc, ability_name)
    asc.granted_abilities[ability_name] = nil
end

function get_ability(asc, ability_name)
    return asc.granted_abilities[ability_name]
end
```

**GDScript:**
```gdscript
func grant_ability(asc: AbilitySystemComponent, ability_def: AbilityDefinition) -> void:
    if asc.granted_abilities.has(ability_def.name):
        return
    asc.granted_abilities[ability_def.name] = ability_def

func revoke_ability(asc: AbilitySystemComponent, ability_name: String) -> void:
    asc.granted_abilities.erase(ability_name)

func get_ability(asc: AbilitySystemComponent, ability_name: String) -> AbilityDefinition:
    return asc.granted_abilities.get(ability_name)
```

Granting and revoking abilities is trivial. The system's power comes from what abilities *do* once granted — they tap into the full attribute/tag/effect pipeline through the lifecycle.

---

## 6. The Ability System Component (ASC)

The **Ability System Component** is the hub that ties everything together. Every entity that participates in the ability system gets an ASC. It owns:

- **Attributes** — the entity's stat block (health, mana, attack power, etc.)
- **Tags** — the entity's current state (`State.Alive`, `Status.Burning`, etc.)
- **Active effects** — all duration and infinite effects currently applied
- **Granted abilities** — the entity's ability roster

The ASC is the single API surface for all ability system operations. External code doesn't reach into attributes or tags directly — it goes through the ASC. This centralization has real benefits:

**Single point of coordination.** When an effect modifies an attribute, the ASC can check if health hit zero and grant `State.Dead`. When a tag is added, the ASC can check if any active effects should be removed (cleanse). Centralization enables cross-cutting reactions.

**Clean API boundary.** The rest of your game code doesn't need to understand modifiers, tag containers, or effect definitions. It calls `asc:activate_ability("Fireball")` and `asc:get_attribute("health")`. Implementation details stay inside.

**Per-entity encapsulation.** Each entity's ASC is independent. Warrior A's attributes don't interfere with Mage B's. This sounds obvious, but in many naive ability systems, global state creeps in.

**Pseudocode:**
```
AbilitySystemComponent:
    // Owned data
    attributes: AttributeSet
    tags: TagContainer
    active_effects: list<ActiveEffect>
    granted_abilities: map<string, AbilityDefinition>

    // Core operations
    function activate_ability(ability_name, target):
        ability = granted_abilities[ability_name]
        if ability is nil:
            return false    // not granted
        return try_activate_ability(self, ability, target)

    function apply_effect(effect_def, context):
        // Delegate to the effect system (Module 3)
        return effect_system.apply_effect(self, effect_def, context)

    function has_tag(tag):
        return tags:has(tag)

    function get_attribute(name):
        return attributes:get_current(name)

    function update(dt):
        // Tick active effects (expiry, periodic ticking)
        update_effects(self, dt)
```

**Lua:**
```lua
local AbilitySystemComponent = {}
AbilitySystemComponent.__index = AbilitySystemComponent

function AbilitySystemComponent.new()
    return setmetatable({
        attributes = AttributeSet.new(),
        tags = TagContainer.new(),
        active_effects = {},
        granted_abilities = {},
    }, AbilitySystemComponent)
end

function AbilitySystemComponent:activate_ability(ability_name, target)
    local ability = self.granted_abilities[ability_name]
    if not ability then
        return false
    end
    return try_activate_ability(self, ability, target)
end

function AbilitySystemComponent:apply_effect(effect_def, context)
    return effect_system_apply(self, effect_def, context)
end

function AbilitySystemComponent:has_tag(tag)
    return self.tags:has(tag)
end

function AbilitySystemComponent:get_attribute(name)
    return self.attributes:get_current(name)
end

function AbilitySystemComponent:update(dt)
    update_effects(self, dt)
end
```

**GDScript:**
```gdscript
class_name AbilitySystemComponent
extends Node

var attributes := AttributeSet.new()
var tags := TagContainer.new()
var active_effects: Array[ActiveEffect] = []
var granted_abilities: Dictionary = {}

func activate_ability(ability_name: String, target: AbilitySystemComponent) -> bool:
    var ability: AbilityDefinition = granted_abilities.get(ability_name)
    if ability == null:
        return false
    return try_activate_ability(self, ability, target)

func apply_effect(effect_def: EffectDefinition, context: Dictionary) -> void:
    effect_system_apply(self, effect_def, context)

func has_tag(tag: String) -> bool:
    return tags.has(tag)

func get_attribute(attribute_name: String) -> float:
    return attributes.get_current(attribute_name)

func _process(delta: float) -> void:
    update_effects(self, delta)
```

---

## 7. Putting It All Together: The Full Activation Flow

Let's trace a complete ability activation to see how every piece connects. The player presses the Fireball key.

**Setup:**
- Caster: a mage with 80 mana, tags `State.Alive`
- Target: an enemy with 100 health, no immunities
- Fireball: costs 30 mana, 3s cooldown, applies -40 fire damage (instant) + burn DoT (5s duration)

**Step 1 — CanActivate:**
```
Check requirements:
  require: [State.Alive] → caster has State.Alive ✓
  block: [State.Stunned, State.Silenced, Cooldown.Ability.Fireball]
    → caster has none of these ✓
Check cost:
  mana.current (80) >= 30 ✓
Result: can activate
```

**Step 2 — CommitCost:**
```
Apply instant effect: mana += -30
  mana base: 80 → 50
```

**Step 3 — Activate:**
```
Apply cooldown to caster:
  Duration effect (3s), grants Cooldown.Ability.Fireball
  Caster now has tag: Cooldown.Ability.Fireball

Apply fire_damage_effect to target:
  Instant effect: health += -40
  Target health base: 100 → 60
  Context: {source = caster, ability = "Fireball"}
  Emit cue: GameplayCue.Damage.Fire

Apply burn_dot_effect to target:
  Duration effect (5s), period 1s
  Grants tag: Status.Burning
  Each tick: health += -5 (instant, modifies base)
  Emit cue: GameplayCue.Status.Burning.Start
```

**Step 4 — End:**
```
Ability returns to idle.
```

**After 3 seconds:**
```
Cooldown effect expires.
Tag Cooldown.Ability.Fireball removed.
Fireball can activate again.
```

**After 5 seconds:**
```
Burn effect expires.
Tag Status.Burning removed.
No more periodic ticks.
Emit cue: GameplayCue.Status.Burning.End
```

Every step uses a system from a previous module. The ability lifecycle is just orchestration — connecting existing pieces in the right order.

---

## 8. Common Ability Patterns

Here are patterns you'll encounter repeatedly. Each is built from the same primitives:

### Self-Buff

An ability that applies a duration effect to the caster, not a target.

```
"War Cry":
    cost: 20 stamina
    cooldown: 15s
    effects: [
        {target: self, duration: 10s, modifiers: [{attack_power, multiply, 1.3}],
         tags_to_grant: [Status.WarCry]}
    ]
```

The only difference from Fireball: the effect targets `self` instead of `target`. The lifecycle is identical.

### Toggle Ability

An ability that activates and stays on until deactivated. Think of an aura or stance.

```
"Defensive Stance":
    cost: 0
    cooldown: 1s (prevents rapid toggling)
    toggle: true
    effects: [
        {target: self, duration: infinite, modifiers: [
            {damage_taken, multiply, 0.8},     // 20% damage reduction
            {attack_power, multiply, 0.7}      // 30% attack penalty
        ], tags_to_grant: [Stance.Defensive]}
    ]
```

When activated, it applies an infinite-duration effect. When "deactivated" (same key press), it removes the effect. Implementation:

```
function activate_toggle(asc, ability, target):
    if asc:has_tag(ability.active_tag):
        // Already active — deactivate
        remove_effects_with_tag(asc, ability.active_tag)
        return
    // Not active — activate normally
    activate(asc, ability, target)
```

### Passive Ability

An ability that's always on once granted. It's not "activated" — it applies its effects immediately on grant and removes them on revoke.

```
"Fire Mastery" (passive):
    on_grant: apply infinite effect → {fire_damage, multiply, 1.25}
    on_revoke: remove the effect
```

Passives skip the lifecycle entirely. They're granted, their effects apply, done. If you model them as always-active infinite effects, they integrate seamlessly.

### Area of Effect (AoE)

An ability that applies effects to multiple targets. The lifecycle runs once for the caster, but the effects are applied to each entity within range.

```
function activate_aoe(asc, ability, targets):
    context = {source = asc, ability = ability}
    for each target in targets:
        for each effect in ability.effects:
            apply_effect(target, effect, context)
```

The "find targets in range" logic is outside the ability system — it's a spatial query. The ability system receives a list of targets and applies effects to each.

### Targeted vs. Skillshot

The ability system doesn't care about targeting. Whether Fireball is a click-to-target spell or a physics-based projectile is a gameplay/input concern. The ability system's job ends at "apply these effects to this target." How the target is determined — click, collision, proximity, AI decision — is separate.

This separation is important: keep targeting logic out of the ability pipeline. Abilities accept targets. Targeting systems provide targets.

---

## 9. Instancing Policies

When an ability is activated, does it create an independent instance? This matters for abilities that last over time (channels, charges, DoTs).

**Non-Instanced (default):** The ability definition is shared. There's only one "Fireball" — you activate it, it does its thing, it ends. For instant abilities, this is fine. Most abilities are non-instanced.

**Instanced per Execution:** Each activation creates a fresh ability instance with its own state. This is needed for abilities that track state during execution — a charging ability tracks charge time, a channeled ability tracks ticks delivered. Without instancing, two rapid activations would fight over shared state.

**Instanced per Actor:** Each entity gets its own copy of the ability. Less common — usually you share the definition and instance per execution when needed.

For simple ability systems, start non-instanced. Instance per execution only when you build multi-frame abilities (Module 5). The distinction matters mainly for bookkeeping — making sure one activation's state doesn't leak into another's.

**Pseudocode:**
```
function activate_ability(asc, ability_def, target):
    if ability_def.instancing == "per_execution":
        // Create a fresh instance for this activation
        instance = AbilityInstance.new(ability_def)
        instance.owner = asc
        instance.target = target
        asc.active_ability_instances[#] = instance
        instance:activate()
    else:
        // Non-instanced — run directly from the definition
        activate(asc, ability_def, target)
```

---

## 10. Debugging the Ability Pipeline

Ability systems are easy to debug when instrumented, nightmarish when not. Log every decision point:

```
[Ability] Fireball: CanActivate check on Entity_Mage
  [Tag] Require State.Alive: PASS
  [Tag] Block State.Stunned: PASS (not present)
  [Tag] Block State.Silenced: PASS (not present)
  [Tag] Block Cooldown.Ability.Fireball: PASS (not present)
  [Cost] mana: need 30, have 80: PASS
[Ability] Fireball: CommitCost
  [Effect] Instant: mana -30 (80 → 50)
[Ability] Fireball: Activate
  [Effect] Cooldown: duration 3.0s, grants Cooldown.Ability.Fireball
  [Effect] FireDamage: instant health -40 on Entity_Enemy (100 → 60)
  [Effect] BurnDot: duration 5.0s, period 1.0s, grants Status.Burning
[Ability] Fireball: End
```

When a player reports "my ability didn't fire," this log tells you exactly which check failed. Was it the cooldown? A stun they didn't see? Not enough mana? The tag requirement system makes the reason explicit.

**Build logging into the pipeline from day one.** Don't add it retroactively — by then you've already wasted hours debugging without it.

A useful pattern: wrap the check functions to return not just pass/fail, but *which* requirement failed:

**Lua:**
```lua
function can_activate_verbose(asc, ability)
    local reasons = {}

    -- Check tag requirements
    for _, req_tag in ipairs(ability.requirements.require_tags) do
        if not asc.tags:has(req_tag) then
            table.insert(reasons, "missing required tag: " .. req_tag)
        end
    end
    for _, block_tag in ipairs(ability.requirements.block_tags) do
        if asc.tags:has(block_tag) then
            table.insert(reasons, "blocked by tag: " .. block_tag)
        end
    end

    -- Check cost
    if ability.cost_attribute and ability.cost_amount then
        local current = asc.attributes:get_current(ability.cost_attribute)
        if current < ability.cost_amount then
            table.insert(reasons, string.format(
                "insufficient %s: need %d, have %d",
                ability.cost_attribute, ability.cost_amount, current
            ))
        end
    end

    return #reasons == 0, reasons
end
```

**GDScript:**
```gdscript
func can_activate_verbose(asc: AbilitySystemComponent, ability: AbilityDefinition) -> Dictionary:
    var reasons: Array[String] = []

    for req_tag in ability.requirements.require_tags:
        if not asc.tags.has(req_tag):
            reasons.append("missing required tag: " + req_tag)
    for block_tag in ability.requirements.block_tags:
        if asc.tags.has(block_tag):
            reasons.append("blocked by tag: " + block_tag)

    if ability.cost_attribute and ability.cost_amount > 0:
        var current := asc.attributes.get_current(ability.cost_attribute)
        if current < ability.cost_amount:
            reasons.append("insufficient %s: need %d, have %d" % [
                ability.cost_attribute, ability.cost_amount, current
            ])

    return {can_activate = reasons.is_empty(), reasons = reasons}
```

---

## Exercise

Build the complete ability activation pipeline. You should already have `AttributeSet`, `TagContainer`, and the effect system from Modules 1–3. Now add:

1. **AbilityDefinition** — name, tag requirements (require/block), cost (attribute + amount), cooldown duration, cooldown tag, and a list of effects to apply.

2. **AbilitySystemComponent (ASC)** — holds an `AttributeSet`, `TagContainer`, active effects list, and granted abilities map. Provides `activate_ability(name, target)`, `apply_effect(effect, context)`, `has_tag(tag)`, `get_attribute(name)`, `update(dt)`.

3. **Ability lifecycle** — implement `can_activate`, `commit_cost`, `activate`, and `end_ability`.

**Test scenario:**

Create two ASCs:
- **Mage:** health=80, max_health=80, mana=100, max_mana=100. Tags: `State.Alive`. Abilities: Fireball, Heal.
- **Enemy:** health=200, max_health=200. Tags: `State.Alive`.

Define abilities:
- **Fireball:** cost 30 mana, cooldown 3s. Applies instant -40 health to target + duration burn (5s, -5 health/second periodic, grants `Status.Burning`).
- **Heal:** cost 25 mana, cooldown 5s. Applies instant +30 health to self.

Test sequence:
1. Mage activates Fireball on Enemy → mana goes to 70, enemy health goes to 160, enemy gets `Status.Burning` and `Cooldown.Ability.Fireball` appears on mage.
2. Mage tries Fireball again → fails (cooldown).
3. Update 1 second → burn ticks, enemy health = 155.
4. Update 2 more seconds → burn ticks twice more (enemy health = 145), cooldown expires, mage can Fireball again.
5. Mage activates Heal on self → mana goes to 45, health goes to 80 (clamped to max).
6. Apply a stun effect to mage (grants `State.Stunned` for 2s). Mage tries Fireball → fails (stunned).
7. Update 2 seconds → stun expires. Mage can act again.

**Stretch goals:**
- Implement a toggle ability (Defensive Stance) that applies a damage reduction modifier while active.
- Implement an ability with multiple costs (Blood Magic: costs 20 mana + 10 health).
- Implement cooldown reduction: give mage a passive that reduces cooldowns by 25%, verify Fireball cooldown becomes 2.25s.
- Add verbose CanActivate that returns the specific reason an ability can't fire.

---

## Read

- GASDocumentation — Gameplay Abilities: https://github.com/tranek/GASDocumentation#concepts-ga — the lifecycle, costs, cooldowns, and instancing policies. This is the primary reference.
- GASDocumentation — Ability System Component: https://github.com/tranek/GASDocumentation#concepts-asc — the central hub. Focus on what the ASC owns and how it coordinates.
- "Ability System design patterns" — search for blog posts on RPG ability lifecycle architectures. The CanActivate → Commit → Execute → End pattern appears across engines.
- Game Programming Patterns — Command pattern: https://gameprogrammingpatterns.com/command.html — abilities are commands. The pattern of "check, then execute" is the Command pattern with a precondition gate.

---

## Summary

Abilities are the player-facing layer that orchestrates attributes, tags, and effects. The ability lifecycle — CanActivate → CommitCost → Activate → End — is the central pipeline. Activation requirements are tag queries. Costs are attribute checks followed by instant effects. Cooldowns are duration effects that grant blocking tags. The Ability System Component (ASC) is the hub that owns all of these systems per entity.

The key insight: abilities contain almost no logic of their own. They're thin orchestrators over the systems you've already built. The power comes from composition — the same attribute pipeline that handles damage also handles costs, the same tag system that checks requirements also handles cooldowns, the same effect system that applies buffs also applies cooldowns.

**Next up:** [Module 5: Ability Tasks & Async Patterns](module-05-ability-tasks-and-async.md) — handling abilities that span multiple frames: channeling, charging, combos, and coroutine patterns.
