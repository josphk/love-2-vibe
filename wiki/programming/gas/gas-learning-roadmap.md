# GAS (Gameplay Ability System) Learning Roadmap

**For:** Game programmers who want to build scalable ability/effect systems without hardcoding every interaction · Engine-agnostic (pseudocode, Lua/Love2D & GDScript/Godot examples) · Reads > watches · ADHD-friendly

---

## How This Roadmap Works

This roadmap teaches you the **architecture behind ability systems** — the patterns that Unreal's Gameplay Ability System (GAS) popularized, extracted from any single engine. You don't need Unreal. You don't need C++. The ideas — attributes with modifier pipelines, hierarchical tags, data-driven effects, ability lifecycles — are universal. Any game with more than a handful of abilities benefits from these patterns.

Modules 0 through 4 are linear — each builds directly on the last. Module 5 (async ability tasks) unlocks after Module 4 and covers the complexity jump of multi-frame abilities. Module 6 (cues/feedback) is independent once you have effects and abilities (Modules 3+4). Module 7 (capstone) integrates everything and is best saved for last.

Each module below is a summary. Click the "Deep dive" link on any module to open the full study guide with detailed explanations, code examples, and additional exercises.

**Dependency graph:**
```
0 → 1 → 2 → 3 → 4 (linear foundation)
                    ↓
     5 (ability tasks / async — after 4)
     6 (cues / feedback — after 3+4)
     7 (capstone — after all)
```

---

## Module 0: The Case for a Gameplay Ability System

> **Deep dive:** [Full study guide](module-00-the-case-for-gas.md)

**Goal:** Understand why hardcoded abilities break down and what a structured ability system gives you.

You've built abilities before. A fireball function that subtracts health. A heal spell that adds it back. A poison status that ticks damage in `update()`. It works — until it doesn't. The problems start when abilities interact. What happens when a character has fire resistance? When poison and regeneration are both active? When a shield ability should block the fireball but not the poison? When a stun should prevent casting but not interrupt a channeled ability that's already started?

Hardcoded abilities lead to an explosion of special cases. Every new ability needs to know about every existing ability. A "freeze" spell checks if the target has "fire shield." A "silence" ability checks a list of ability types to determine which ones it blocks. These cross-cutting interactions grow quadratically — 10 abilities might mean 45 potential interactions, 50 abilities means 1,225. You can't hardcode your way out.

A Gameplay Ability System solves this by decomposing abilities into composable primitives. **Attributes** are numeric stats with defined modification rules. **Tags** are hierarchical labels that describe state. **Effects** are data-driven packages that modify attributes and tags. **Abilities** are the player-facing actions that apply effects and check requirements. Each piece is simple. The power comes from composition.

**Key concepts:**
- **Ability explosion:** As abilities increase, interactions grow quadratically. 10 abilities with pairwise interactions = 45 checks. 50 = 1,225. Hardcoding doesn't scale.
- **Separation of concerns:** Instead of each ability knowing about every other ability, you separate *what changes* (effects on attributes/tags) from *what's allowed* (tag-based requirements) from *what the player does* (ability activation). Each layer is independent.
- **Data-driven design:** Abilities become data — "apply +20 fire damage, grant tag `Status.Burning` for 5 seconds" — not code. Designers can create new abilities by combining existing building blocks.
- **The GAS vocabulary:** Attributes, Tags, Effects, Abilities, Cues. Even if you don't use Unreal, this vocabulary gives you a shared language for ability system architecture.

**Read:**
- GAS documentation overview (Unreal): https://docs.unrealengine.com/en-US/gameplay-ability-system-for-unreal-engine/ — skim for the conceptual model, not the C++ API. Focus on how the pieces relate.
- "The Sixty Minute Crash Course" by tranek: https://github.com/tranek/GASDocumentation — the community-standard GAS reference. Read sections 1-3 for the big picture. Engine-specific, but the architecture is universal.
- "Practical Game Design Patterns" — Ability System chapters from game architecture blogs. Search for "data-driven ability system design" for engine-agnostic treatments.

**Exercise:** Take a game you've built (or a favorite game you know well). List 10 abilities or status effects. Now list every pairwise interaction that would need special handling if hardcoded (fire + ice resistance, stun + casting, heal + poison, etc.). How many interactions did you find? Could any be eliminated if abilities operated through a shared attribute/tag system instead of knowing about each other directly?

**Time:** 2–3 hours

---

## Module 1: Attributes & Modifier Stacking

> **Deep dive:** [Full study guide](module-01-attributes-and-modifier-stacking.md)

**Goal:** Build a numeric attribute system with base values, current values, and a modifier pipeline.

Every ability system operates on numbers — health, mana, attack power, movement speed, fire resistance. In a naive implementation, you just store `health = 100` and modify it directly. But "directly" hides a surprising amount of complexity. What's the base health vs. the current health? If a buff gives +20% health, does another +20% buff stack additively (base × 1.4) or multiplicatively (base × 1.2 × 1.2)? If you remove the first buff, how do you recalculate? What about flat bonuses vs. percentage bonuses — which applies first?

An **attribute** in GAS terms has a **base value** (the permanent stat) and a **current value** (the result after all active modifiers are applied). When modifiers change, you recalculate the current value from the base value by running through the modifier pipeline. This pipeline has an order: typically flat additions first, then percentage multipliers, then overrides. The order matters enormously — "add 10 then multiply by 1.5" gives a different result than "multiply by 1.5 then add 10."

The modifier pipeline is the core of your attribute system. Each modifier has a **type** (add, multiply, override), a **value**, a **source** (which effect or ability applied it), and optionally a **priority** or **channel** for stacking rules. When a modifier is added or removed, recalculate the current value. Never modify the base value for temporary effects — that's what modifiers are for.

**Key concepts:**
- **Base value vs. current value:** Base is permanent (level-up stats, equipment). Current is base + all active modifiers. Effects modify current through modifiers; they rarely touch base directly.
- **Modifier types:** Add (flat: `+10`), Multiply (percentage: `×1.2`), Override (set to exact value). The pipeline applies them in a defined order — typically: Add → Multiply → Override.
- **Stacking policies:** Can two "attack speed +20%" modifiers coexist? Options: stack additively (40% total), stack multiplicatively (44% total), use highest only, refresh duration only, stack with a cap.
- **Recalculation:** When any modifier is added, removed, or changed, re-derive the current value from scratch: start from base, apply all active modifiers in pipeline order. Never incrementally patch — recalculating from base is simpler and bug-free.
- **Modifier source tracking:** Each modifier remembers its source (the effect or ability that created it). When the source expires, its modifiers are automatically removed and the attribute recalculates.

**Read:**
- GASDocumentation — Attributes and AttributeSets: https://github.com/tranek/GASDocumentation#concepts-a — covers base/current value split, attribute aggregation
- "Game Attribute Systems" — search for blog posts on RPG stat systems and modifier stacking. The pattern predates GAS and appears in every RPG engine.
- "Modifier Stacking in RPGs" by Hooded Horse / design blogs — stacking rules are a game design decision, not just a code one

**Exercise:** Implement an `AttributeSet` in Lua (or pseudocode). Create attributes for `health`, `max_health`, `attack_power`, and `move_speed`. Implement a `Modifier` with type (add/multiply/override), value, and source ID. Write `add_modifier(attribute, modifier)`, `remove_modifier(attribute, source_id)`, and `recalculate(attribute)`. Test: base attack = 20, add a +5 flat modifier, add a ×1.5 multiply modifier. Current should be (20 + 5) × 1.5 = 37.5. Remove the flat modifier. Current should be 20 × 1.5 = 30. Verify recalculation is correct.

**Time:** 3–4 hours

---

## Module 2: Gameplay Tags

> **Deep dive:** [Full study guide](module-02-gameplay-tags.md)

**Goal:** Learn hierarchical tag systems — the query language that ties abilities, effects, and requirements together.

Tags are the most underappreciated part of an ability system, and possibly the most powerful. A **gameplay tag** is a hierarchical label — `Status.Burning`, `Ability.Type.Fire`, `State.Dead`, `Immune.Damage.Fire`. They cost almost nothing to implement, but they replace enormous amounts of conditional logic.

Without tags, your code says `if target.is_frozen and not ability.type == "fire"`. With tags, your code says `if target.tags:has("State.Frozen") and not ability.tags:has_any("Ability.Type.Fire")`. That looks like the same thing — but it's profoundly different. The tag version is **data-driven and extensible.** You don't need to modify code to add new states or ability types. You just add new tags. The queries don't change.

The hierarchy is what makes tags powerful. `Status.Burning` is a child of `Status`. A query like `has_any_matching("Status")` matches any status tag — burning, frozen, poisoned, stunned — without listing them. This means you can create a "cleanse all status effects" ability by removing all tags under `Status.*` without knowing what status effects exist. New statuses automatically work. No code changes.

**Tag containers** are sets of tags attached to an entity. The core operations are: `has(tag)` (exact match), `has_any(tags)` (at least one matches), `has_all(tags)` (all must match), and `has_any_matching(prefix)` (hierarchical match). These four operations power nearly every requirement check in the entire ability system.

**Key concepts:**
- **Hierarchical tags:** `Ability.Type.Fire`, `Status.Burning`, `State.Dead`. The dot-separated hierarchy enables prefix matching. Tags are strings (or interned IDs for performance), not enums — new tags don't require code changes.
- **Tag container:** A set of tags attached to an entity. Think of it as a flexible, queryable description of what an entity *is* and what's *happening to it* right now.
- **Tag queries:** `has(tag)`, `has_any(tags)`, `has_all(tags)`, `has_none(tags)`. These are the conditionals of your ability system. Effects, abilities, and cues all use tag queries to decide what to do.
- **Tag requirements:** A pair of conditions: "require all of these tags" and "block if any of these tags." An ability might require `State.Alive` and block on `State.Stunned`. This replaces hardcoded `if alive and not stunned` checks.
- **Tag granting/removing:** Effects grant and remove tags as a core operation, alongside modifying attributes. A "stun" effect grants `State.Stunned` for 2 seconds. Systems check for the tag, not for "is stunned" booleans.

**Read:**
- GASDocumentation — Gameplay Tags: https://github.com/tranek/GASDocumentation#concepts-gt — how Unreal structures tag hierarchy and matching
- "Tag-based game architecture" — search for blog posts on using tags instead of enums/flags for game state. The pattern is common in roguelike and RPG development.
- Godot's `StringName` system and how it enables efficient string-based tags: https://docs.godotengine.org/en/stable/classes/class_stringname.html — relevant if implementing in Godot

**Exercise:** Implement a `TagContainer` in Lua (or your preferred language). Support: `add(tag)`, `remove(tag)`, `has(tag)`, `has_any(tags)`, `has_all(tags)`, `has_none(tags)`, and `has_any_matching(prefix)` (matches any tag starting with prefix + "."). Test it: add `Status.Burning`, `Status.Poisoned`, `State.Alive`, `Ability.Type.Fire`. Verify `has_any_matching("Status")` returns true, `has_all({"State.Alive", "Status.Burning"})` returns true, `has_none({"State.Dead"})` returns true. Then write a `TagRequirement` struct with `require_tags` and `block_tags` lists, and a `check(container)` function. An ability requires `State.Alive` and blocks on `State.Stunned` — verify it passes when alive and not stunned, fails otherwise.

**Time:** 2–3 hours

---

## Module 3: Gameplay Effects

> **Deep dive:** [Full study guide](module-03-gameplay-effects.md)

**Goal:** Build data-driven effects that modify attributes and tags with duration, stacking, and requirements.

Effects are where the system starts to feel magical. A **gameplay effect** is a data-driven description of *what happens* — not code, but data. "Modify `health` by -20." "Grant tag `Status.Burning` for 5 seconds." "Increase `attack_power` by 15% for 10 seconds." Each effect is a bundle of attribute modifiers, tag changes, and metadata like duration and stacking rules. You create them as data. You apply them to entities. The system handles the rest.

Effects come in three **duration types.** **Instant** effects apply once and are done — a heal for 50 HP, a damage burst. They modify the base value directly because there's no duration to track. **Duration** effects last for a set time — a 10-second attack buff, a 5-second poison. They apply modifiers that are automatically removed when the duration expires. **Infinite** effects last until explicitly removed — an equipment stat bonus, a permanent curse. Duration and infinite effects use the modifier pipeline from Module 1; instant effects bypass it.

**Stacking** is where effect design gets interesting. If a character is hit with two poison effects, do they stack? If so, how? Options include: **stack count** (each application adds a stack, each stack applies its own modifier), **duration refresh** (reapplying resets the timer but doesn't add more damage), **highest wins** (only the strongest instance counts), or **no stacking** (second application is rejected). The stacking policy is part of the effect definition, not the code.

Effects also have **application requirements** — tag queries that must pass for the effect to apply. A fire damage effect might require the target NOT to have `Immune.Damage.Fire`. A healing effect might require `State.Alive`. This is where tags (Module 2) pay off — requirements are data, not code.

**Key concepts:**
- **Duration types:** Instant (one-shot, modifies base value), Duration (timed, applies modifiers that auto-expire), Infinite (persistent until explicitly removed). Every effect is one of these three.
- **Effect data:** An effect definition contains: attribute modifiers (which attribute, what operation, what value), tag grants (tags to add), tag removals (tags to remove), duration, stacking policy, application requirements, and a period (for periodic effects like damage-over-time).
- **Periodic effects:** Duration effects can tick on a period. "10 damage every 2 seconds for 10 seconds" is a periodic effect with period=2, duration=10, applying an instant -10 health modification each tick.
- **Stacking policies:** Stack count (accumulate instances), duration refresh (reset timer), highest wins (keep strongest), no stacking (reject duplicates). Defined per-effect, not globally.
- **Application requirements:** Tag queries checked before the effect applies. `require: [State.Alive]`, `block: [Immune.Damage.All]`. If requirements fail, the effect is rejected — no special-case code needed.
- **Effect context:** Who applied this effect? What ability triggered it? What was the source's attack power at the time? Capturing context at application time enables damage formulas that reference the caster's stats.

**Read:**
- GASDocumentation — Gameplay Effects: https://github.com/tranek/GASDocumentation#concepts-ge — covers duration types, stacking, modifiers, and application. The most important section for system design.
- "Data-Driven Gameplay Effects" blog posts — search for implementations of buff/debuff systems in roguelikes and ARPGs. The pattern is everywhere, even without the GAS name.
- "Diablo-style Buff Stacking" design discussions — stacking rules are a decades-old design problem. Diablo, Path of Exile, and Dota 2 all solve it differently.

**Exercise:** Implement a `GameplayEffect` definition in Lua (or pseudocode). It should contain: a list of attribute modifiers, tags to grant, tags to remove, a duration type (instant/duration/infinite), a duration in seconds, a stacking policy, and a tag requirement. Write an `apply_effect(target, effect, context)` function that: (1) checks tag requirements, (2) handles stacking, (3) for instant effects — directly modifies base values, (4) for duration/infinite effects — adds modifiers to attributes and grants tags, (5) schedules removal at expiry. Test: apply a "Poison" effect (duration=5s, periodic damage -5 health every 1s, grants `Status.Poisoned`), then apply a "Fire Shield" effect (infinite, grants `Immune.Damage.Fire`). Verify poison ticks work and the fire immunity tag is present.

**Time:** 4–6 hours

---

## Module 4: Gameplay Abilities

> **Deep dive:** [Full study guide](module-04-gameplay-abilities.md)

**Goal:** Implement the ability lifecycle — activation, costs, cooldowns, and applying effects.

Abilities are the player-facing layer — the thing you bind to a key, drag onto a hotbar, or trigger via AI. Everything you've built so far (attributes, tags, effects) is infrastructure. Abilities are where that infrastructure meets gameplay. A "Fireball" ability checks its requirements, pays its cost, enters its cooldown, and applies a fire damage effect to the target. Each of those steps uses the systems you've already built.

The **ability lifecycle** has defined phases. **Can Activate** checks prerequisites: does the caster have enough mana? Is the ability off cooldown? Does the caster have the required tags (`State.Alive`, not `State.Stunned`, not `State.Silenced`)? **Activate** fires the ability — play an animation, spawn a projectile, apply effects. **End** cleans up — the ability is done, returns to idle. **Cooldown** is itself a gameplay effect (usually infinite duration, removed after N seconds) that grants a tag like `Cooldown.Ability.Fireball`. The "can activate" check blocks on that tag. Cooldowns aren't special-cased — they're just effects and tags.

**Costs** work the same way. Casting Fireball costs 30 mana. The "commit cost" step applies an instant effect that modifies the mana attribute by -30. If the caster doesn't have enough mana, the "can activate" check catches it — you check `mana.current >= cost` before committing. Some systems model costs as effects too, keeping everything in the same pipeline.

**Ability grants** connect abilities to entities. An entity has an **Ability System Component** (ASC) — a container that holds its attributes, tags, active effects, and granted abilities. The ASC is the central hub. When you call `activate_ability(entity, "Fireball")`, you're asking that entity's ASC to run the fireball lifecycle.

**Key concepts:**
- **Ability lifecycle:** CanActivate → CommitCost → Activate → (execute gameplay) → End. Each phase has clear responsibilities. Failed checks at CanActivate prevent wasted resources.
- **Activation requirements:** Tag queries on the caster. Require `State.Alive`, block `State.Stunned`, block `Cooldown.Ability.Fireball`. Completely data-driven — add new blocking states by adding tags, not by modifying ability code.
- **Costs as attribute checks:** Before activation, verify the caster can afford it. `mana.current >= 30`. On commit, apply the cost. If you model costs as instant effects, the same pipeline handles them.
- **Cooldowns as effects:** Activating an ability applies a cooldown effect that grants a tag (`Cooldown.Ability.Fireball`) for N seconds. The CanActivate check blocks on that tag. Cooldown reduction is just a modifier on the cooldown duration.
- **Ability grants:** The set of abilities an entity can use. A warrior has `Slash`, `Shield Bash`, `Charge`. A mage has `Fireball`, `Frost Nova`, `Teleport`. Abilities are granted and revoked dynamically — equipping a staff might grant `Lightning Bolt`.
- **Ability System Component (ASC):** The hub on each entity that owns attributes, tags, active effects, and granted abilities. Every ability operation goes through the ASC.

**Read:**
- GASDocumentation — Gameplay Abilities: https://github.com/tranek/GASDocumentation#concepts-ga — lifecycle, costs, cooldowns, instancing policies
- "Ability System design patterns" — search for blog posts on RPG ability systems, particularly those discussing activation requirements and cooldown architectures
- GASDocumentation — Ability System Component: https://github.com/tranek/GASDocumentation#concepts-asc — the central container that ties everything together

**Exercise:** Implement an `Ability` definition and an `AbilitySystemComponent` (ASC). An ability has: a name, activation tag requirements (require/block), a mana cost, a cooldown duration, and a list of effects to apply on activation. The ASC holds: an `AttributeSet`, a `TagContainer`, a list of active effects, and a list of granted abilities. Write `can_activate(asc, ability)` and `activate_ability(asc, ability, target)`. Test: grant a "Fireball" ability (cost: 30 mana, cooldown: 3s, applies instant -40 health to target, applies duration burn for 5s). Activate it — verify mana is deducted, cooldown tag is applied, target takes damage and gets `Status.Burning`. Try to activate again immediately — verify it fails (cooldown). Wait 3 seconds, try again — verify it works.

**Time:** 4–6 hours

---

## Module 5: Ability Tasks & Async Patterns

> **Deep dive:** [Full study guide](module-05-ability-tasks-and-async.md)

**Goal:** Handle abilities that span multiple frames — channeling, combos, charge-up, and coroutine patterns.

Up to now, abilities have been instantaneous — activate, apply effect, done. But many interesting abilities take time. A charged shot that grows stronger the longer you hold the button. A channeled heal that ticks every half-second and cancels if you move. A three-hit combo where each attack chains from the previous one with timing windows. These are **multi-frame abilities**, and they're a significant complexity jump.

In Unreal's GAS, these are handled by **Ability Tasks** — asynchronous sub-objects that run inside an active ability, waiting for events, timers, or input. You don't need Unreal's implementation, but you need the concept. An ability task is something that says "wait for X, then do Y" — while the ability remains active across multiple frames.

The simplest implementation uses **coroutines** (Lua has them built-in, GDScript has `await`). An ability's execution becomes a coroutine that can yield: `wait_for_seconds(2)`, `wait_for_input("release")`, `wait_for_event("animation_finished")`. Each frame, the ability system resumes active coroutines and checks if their wait condition is satisfied. This keeps the ability's logic readable — it reads like sequential code even though it executes across many frames.

**State machines** are the alternative to coroutines. A charging ability has states: `Charging → Releasing → Recovering`. Each state defines what happens on enter, update, and exit. State machines are more explicit than coroutines and easier to debug, but more verbose. Some developers use coroutines for simple timing and state machines for complex multi-phase abilities.

**Key concepts:**
- **Ability tasks:** Sub-operations within an ability that span multiple frames. "Wait 2 seconds," "Wait for button release," "Play animation and wait for notify." They keep the ability alive across frames without blocking the game loop.
- **Coroutines for abilities:** Lua's `coroutine.create/resume/yield` and GDScript's `await` let you write sequential ability logic that pauses and resumes. `yield(wait_seconds(1.5))` pauses the ability for 1.5 seconds without blocking anything else.
- **Channeled abilities:** Abilities that continuously apply effects while a condition holds (button held, caster alive, not interrupted). A channeled heal ticks every 0.5 seconds. Moving or getting stunned interrupts the channel.
- **Charge-up abilities:** Hold to increase power, release to fire. Track charge time, scale effect magnitude. Common in action games (Mega Man, Breath of the Wild bow).
- **Combo sequences:** Abilities that chain — attack 1 → attack 2 → attack 3, with timing windows between each. If the player inputs too late, the combo resets. Implemented as a state machine or coroutine with timed waits.
- **Cancellation and interruption:** Any async ability needs a clean cancel path. Getting stunned during a channel should cancel the ability, clean up active effects, and return to idle. Always handle the unhappy path.

**Read:**
- GASDocumentation — Ability Tasks: https://github.com/tranek/GASDocumentation#concepts-at — how Unreal handles async abilities. Focus on the concept, not the C++ API.
- Lua coroutine tutorial: https://www.lua.org/pil/9.1.html — if you're implementing in Lua, coroutines are the natural tool for multi-frame abilities
- "Coroutines for Game Logic" blog posts — search for game-specific coroutine patterns. Unity's coroutines (conceptually similar) have extensive community documentation.
- "Implementing Combo Systems" — search for fighting game or action game combo system design. The timing window pattern recurs across genres.

**Exercise:** Implement a coroutine-based ability task system. Create three abilities: (1) **Charged Shot** — hold to charge for up to 3 seconds, release to fire, damage scales with charge time; (2) **Healing Channel** — channel for 5 seconds, healing 10 HP per second, interrupted by movement or stun; (3) **Three-Hit Combo** — three attacks in sequence, each with a 0.5-second input window to continue the combo, increasing damage per hit. Each ability should properly handle cancellation (stun interrupts everything, cleans up state). Verify that multiple abilities can't be active simultaneously on the same entity.

**Time:** 4–6 hours

---

## Module 6: Gameplay Cues & Feedback

> **Deep dive:** [Full study guide](module-06-gameplay-cues-and-feedback.md)

**Goal:** Decouple visual/audio feedback from gameplay logic using cue events.

Your ability system works. Effects apply, attributes change, tags get granted and revoked. But the player sees nothing — no particles, no sound, no screen shake. You need feedback. The question is: where does the feedback code go?

The wrong answer is inside the effect or ability code. If your "apply fire damage" function also spawns flame particles, plays a burning sound, and shakes the camera, you've coupled gameplay logic to presentation. That coupling hurts in predictable ways: you can't reuse the fire damage logic without the visuals, you can't change the visuals without touching gameplay code, and in a networked game, the server runs gameplay logic but should never spawn particles.

**Gameplay cues** are the solution. A cue is an event that says "something visually interesting happened" without specifying what the visual response should be. When a fire damage effect applies, it emits a cue: `GameplayCue.Damage.Fire`. A separate cue handler — registered in a lookup table — receives that cue and spawns the appropriate particles, sound, and screen shake. The gameplay code doesn't know or care what the visual response is. The visual code doesn't know or care what triggered it.

Cues map naturally to the tag hierarchy. `GameplayCue.Damage.Fire` for fire damage visuals. `GameplayCue.Status.Burning` for the ongoing burning VFX. `GameplayCue.Heal` for healing sparkles. The cue tag determines which handler runs. Adding new visual responses is just registering new handlers — no gameplay code changes.

**Key concepts:**
- **Gameplay cue:** An event emitted by gameplay logic (effects, abilities) that triggers visual/audio feedback. Decouples logic from presentation completely.
- **Cue types:** **Burst** cues fire once (damage number, hit flash, impact sound). **Looping** cues run for a duration (burning VFX, shield glow, channeling particles). Burst cues map to instant/one-shot effects. Looping cues map to duration/infinite effects.
- **Cue tags:** Cues use the same hierarchical tag system. `GameplayCue.Damage.Fire`, `GameplayCue.Heal`, `GameplayCue.Status.Stunned`. Handlers register for specific tags or tag prefixes.
- **Cue handler registry:** A lookup table mapping cue tags to handler functions. `GameplayCue.Damage.Fire → spawn_fire_particles, play_fire_sound, camera_shake(0.2)`. Multiple handlers can respond to one cue.
- **Cue parameters:** Data passed with the cue — magnitude (how much damage for scaling particle count), location (where to spawn effects), source and target (for directional effects). Handlers use these to scale their response.
- **Network implications:** In multiplayer, gameplay runs on the server, cues run on clients. The server sends cue events; clients play the visuals. This separation is the reason cues exist in the first place.

**Read:**
- GASDocumentation — Gameplay Cues: https://github.com/tranek/GASDocumentation#concepts-gc — the original cue architecture. Focus on the burst/looping distinction and the decoupling rationale.
- "Observer" pattern from Game Programming Patterns: https://gameprogrammingpatterns.com/observer.html — cues are observers. Effects are subjects. The pattern is identical.
- "Juice it or Lose it" GDC talk — search for the Martin Jonasson & Petri Purho talk. It's about feedback and polish, which is exactly what cues deliver at an architectural level.

**Exercise:** Implement a cue system. Create a `CueManager` with `register_handler(cue_tag, handler_function)` and `emit_cue(cue_tag, params)`. Handlers receive parameters (magnitude, position, source, target). Connect it to your effect system: when a fire damage effect applies, emit `GameplayCue.Damage.Fire` with the damage amount. When a burning status effect starts, emit `GameplayCue.Status.Burning.Start`. When it ends, emit `GameplayCue.Status.Burning.End`. Write handlers that print/log what they'd do (or, if you're in Love2D, actually spawn particles and play sounds). Verify that adding a new effect type only requires adding a new cue handler — no gameplay code changes.

**Time:** 3–4 hours

---

## Module 7: Building an Ability System

> **Deep dive:** [Full study guide](module-07-building-an-ability-system.md)

**Goal:** Capstone — integrate all components into a working ability system with real gameplay.

This is where everything comes together. You're going to build a small but complete ability system — multiple characters with different ability sets, interacting effects, visual feedback, and enough gameplay to exercise every part of the architecture. The goal isn't to build an MMO. The goal is to confront every integration decision and come out with a system that works end-to-end.

Pick a format that exercises the system well. **An arena battle** (two AI-controlled characters fighting with abilities) is ideal — it forces you to wire up every layer: attributes define stats, tags define state, effects modify both, abilities use all three, and cues show what's happening. **A roguelike ability demo** (player with upgradeable abilities fighting waves of enemies) works similarly well. **A turn-based RPG combat prototype** tests the same architecture with different timing. Avoid anything that doesn't heavily feature abilities — a platformer with one attack move won't exercise the system enough to reveal integration bugs.

The **Ability System Component (ASC)** is the integration point. Each entity with abilities gets an ASC that owns its attributes, tag container, active effects list, and granted abilities. The ASC is the single API surface: `asc:activate_ability(name)`, `asc:apply_effect(effect, source)`, `asc:has_tag(tag)`, `asc:get_attribute(name)`. Everything routes through here. If your ASC API is clean, the rest of the system stays manageable.

**Networking** is not in scope for this capstone, but you should know where it fits. In a networked game, the server owns the authoritative ASC — it processes abilities, applies effects, and runs gameplay logic. The client predicts locally (speculatively activating abilities for responsiveness) and reconciles when the server confirms or rejects. Cues run on the client. The architecture you've built — with clean separation between logic (server), data (replicated ASC), and feedback (client cues) — is exactly why GAS works for multiplayer. You don't need to implement networking, but designing with this separation means you *could*.

**Key concepts:**
- **The Ability System Component (ASC):** The hub that owns attributes, tags, effects, and abilities for an entity. Every operation goes through the ASC. Keep its API clean and minimal.
- **Integration testing:** The hardest bugs are at the seams — an effect that grants a tag that should block an ability that applies another effect. Test combinations, not just individual pieces.
- **Effect interactions:** This is where complexity lives. Poison ticks health down. Regeneration ticks it up. A damage shield absorbs incoming attribute modifications. An invincibility effect blocks all damage effects. Design these interactions through tags and requirements, not special-case code.
- **System initialization order:** Attributes must exist before effects can modify them. Tags must exist before requirements can check them. Abilities must be granted before they can activate. Get the initialization sequence right.
- **Networking architecture (conceptual):** Server = authoritative ASC + gameplay logic. Client = predicted ASC + cues + input. Replication sends attribute changes and cue events. Prediction activates abilities locally; reconciliation corrects mismatches. You don't need to implement this, but understanding the split validates your architecture.
- **Debugging ability systems:** Log every effect application, modifier change, tag grant, requirement check, and ability activation. When "the buff isn't working," the log tells you exactly which check failed. Ability systems are easy to debug when instrumented, nightmarish when not.

**Read:**
- GASDocumentation — full document: https://github.com/tranek/GASDocumentation — revisit the whole thing now that you understand every concept. It will read very differently.
- "Networking Gameplay Effects" sections from GAS documentation — understand the prediction/reconciliation model even if you're building single-player
- Source code of open-source GAS implementations — search GitHub for "gameplay ability system" in Lua, GDScript, or your preferred language. Reading someone else's integration decisions is invaluable.

**Exercise:** Build and finish the system. Minimum viable scope: two character types with different attribute sets (e.g., warrior with high health/low mana, mage with low health/high mana). At least 4 abilities total across the characters, using instant effects, duration effects, and at least one periodic effect. Tag-based requirements that create real gameplay interactions (fire resistance blocks fire damage, stun prevents casting, silence blocks spells but not physical attacks). A cue system that provides visual/audio feedback for every ability and effect. Run a simulated battle (manual or AI-controlled) and verify every interaction works correctly. Log every system event to prove the pipeline is working.

**Time:** 20–40 hours

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| GASDocumentation (tranek) | https://github.com/tranek/GASDocumentation | Community-standard GAS reference. Engine-specific, but the architecture is universal. |
| Unreal GAS Overview | https://docs.unrealengine.com/en-US/gameplay-ability-system-for-unreal-engine/ | Official docs. Skim for the conceptual model. |
| Game Programming Patterns | https://gameprogrammingpatterns.com | Free online. Observer, Event Queue, and Component chapters are directly relevant. |
| ECS FAQ (Sander Mertens) | https://github.com/SanderMertens/ecs-faq | GAS uses components internally. Understanding ECS helps for advanced implementations. |
| Lua Coroutines (PiL) | https://www.lua.org/pil/9.1.html | Essential if implementing ability tasks in Love2D. |
| Godot StringName | https://docs.godotengine.org/en/stable/classes/class_stringname.html | Efficient string-based tags in Godot. |
| "Juice it or Lose it" talk | Search: "Juice it or Lose it GDC" | Why feedback (cues) matters for game feel. |

---

## ADHD-Friendly Tips

- **Module 1 is the unlock.** If you only finish one module, make it Module 1 (Attributes). Once you can create stats with a proper modifier pipeline, every game you build gets better — not just ability-heavy ones.
- **Build the effect pipeline early.** Modules 1 through 3 (attributes → tags → effects) are the core loop. Once effects work, abilities (Module 4) are surprisingly straightforward — they're just wrappers that check requirements and apply effects.
- **Tags are deceptively powerful.** Module 2 feels simple, and it is. But tags eliminate more special-case code than any other single concept in this roadmap. When you're tempted to write `if target.is_frozen`, add a tag instead.
- **Draw the data flow.** Ability → checks tags → pays cost (effect on self) → applies effect to target → effect modifies attributes + grants tags → cue fires. Sketch this pipeline on paper. When something doesn't work, trace the pipeline to find where it breaks.
- **Test with two abilities, not ten.** Get "Fireball" and "Heal" working end-to-end before adding more. Two abilities that fully exercise the pipeline teach you more than ten abilities with shortcuts.
- **The "one layer" rule.** Each session, work on one layer. Attributes today. Tags tomorrow. Effects the day after. Each layer is self-contained and testable on its own. You get a complete, satisfying unit of progress each session.
- **Hardcode first, data-drive second.** It's fine to start with hardcoded ability definitions. Once you see the pattern, extract them into data tables. Don't try to build the data-driven editor before you understand what the data needs to contain.
