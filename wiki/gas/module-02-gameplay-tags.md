# Module 2: Gameplay Tags

**Part of:** [GAS Learning Roadmap](gas-learning-roadmap.md)
**Estimated study time:** 2–3 hours
**Prerequisites:** [Module 1: Attributes & Modifier Stacking](module-01-attributes-and-modifier-stacking.md)

---

## Overview

Tags are the most underappreciated part of an ability system, and possibly the most powerful. A **gameplay tag** is a hierarchical label — `Status.Burning`, `Ability.Type.Fire`, `State.Dead`, `Immune.Damage.Fire`. They cost almost nothing to implement — just strings in a set — but they replace enormous amounts of conditional logic.

Without tags, your code says `if target.is_frozen and not ability.type == "fire"`. With tags, your code says `if target:has_tag("State.Frozen") and not ability:has_tag("Ability.Type.Fire")`. That looks similar — but it's profoundly different. The tag version is **data-driven and extensible.** You don't need to modify code to add new states or ability types. You just add new tags. The query functions don't change.

The hierarchy is what makes tags powerful. `Status.Burning` is a child of `Status`. A query like `has_any_matching("Status")` matches any status tag — burning, frozen, poisoned, stunned — without listing them. This means you can create a "cleanse all status effects" ability by removing all tags under `Status.*` without knowing what status effects exist. New statuses automatically work. No code changes.

This module is short but foundational. Tags appear in every subsequent module: effects grant and remove them, abilities check them for activation requirements, cues use them for feedback routing. If attributes are the numbers of your ability system, tags are the words.

---

## 1. What Tags Replace

Before building the tag system, let's see what it replaces. Here's a typical entity without tags:

```lua
local character = {
    is_alive = true,
    is_stunned = false,
    is_silenced = false,
    is_burning = false,
    is_frozen = false,
    is_poisoned = false,
    is_invincible = false,
    is_invisible = false,
    damage_type = "physical",
    element = "fire",
    can_cast = true,
    can_move = true,
    can_attack = true,
}
```

Every new status means a new boolean field. Every check is a direct field access: `if character.is_stunned`. Every new ability that interacts with status needs to know the field name. Want to check "does this character have any negative status"? You write:

```lua
if character.is_stunned or character.is_silenced or character.is_burning
   or character.is_frozen or character.is_poisoned then
    -- has a negative status
end
```

Add a new status — `is_bleeding`, `is_cursed`, `is_feared` — and you need to update every such check. This is the boolean explosion problem, and it's the tag version of the quadratic ability problem from Module 0.

With tags, the same entity looks like:

```lua
local character = {
    tags = TagContainer(),
}
character.tags:add("State.Alive")
```

Checking for any negative status: `character.tags:has_any_matching("Status")`. The check doesn't change when you add new statuses. A "stun" effect grants `State.Stunned` and `Status.Stunned`. A "cleanse" ability removes all tags matching `Status.*`. Adding `Status.Bleeding` tomorrow requires zero code changes.

---

## 2. Tag Hierarchy

Tags use dot-separated hierarchical names. The hierarchy isn't enforced by a tree data structure — it's encoded in the string itself, and hierarchy queries use prefix matching.

**Common tag hierarchies:**

```
State
├── State.Alive
├── State.Dead
├── State.Stunned
├── State.Silenced
└── State.Rooted

Status
├── Status.Burning
├── Status.Frozen
├── Status.Poisoned
├── Status.Bleeding
└── Status.Cursed

Ability
├── Ability.Type
│   ├── Ability.Type.Fire
│   ├── Ability.Type.Ice
│   ├── Ability.Type.Physical
│   └── Ability.Type.Magic
└── Ability.Skill
    ├── Ability.Skill.Fireball
    ├── Ability.Skill.FrostNova
    └── Ability.Skill.Heal

Immune
├── Immune.Damage
│   ├── Immune.Damage.Fire
│   ├── Immune.Damage.Ice
│   └── Immune.Damage.All
├── Immune.Status
│   ├── Immune.Status.Stun
│   └── Immune.Status.Silence
└── Immune.Knockback

Cooldown
├── Cooldown.Fireball
├── Cooldown.FrostNova
└── Cooldown.Heal

GameplayCue
├── GameplayCue.Damage.Fire
├── GameplayCue.Damage.Ice
├── GameplayCue.Heal
└── GameplayCue.Status.Burning
```

The hierarchy depth is your choice. Two or three levels is typical. Deeper hierarchies are possible (`Ability.Type.Magic.Arcane.Conjuration`) but rarely necessary. The rule of thumb: add a level when you need to query a category. If you never query "all fire things," you don't need `Ability.Type.Fire` — just `Ability.Fireball`.

**Tags are strings, not enums.** This is deliberate. Enums require code changes to extend. Strings require nothing — you can add `Status.Petrified` in a data file and every tag query that matches `Status.*` automatically includes it. For performance-sensitive games (thousands of tag checks per frame), you can intern strings into integer IDs. But start with strings — they're fast enough for almost every game, and the readability is worth it.

---

## 3. The Tag Container

A tag container is a set of tags attached to an entity. It's the entity's queryable state description — what the entity *is* and what's *happening to it* right now.

The core data structure is a set (table with tags as keys in Lua, a Dictionary/HashSet in other languages). The operations are:

**Pseudocode:**
```
TagContainer:
    tags: set<string>

    add(tag):
        tags.insert(tag)

    remove(tag):
        tags.delete(tag)

    has(tag) -> bool:
        return tag in tags

    has_any(tag_list) -> bool:
        for tag in tag_list:
            if tag in tags: return true
        return false

    has_all(tag_list) -> bool:
        for tag in tag_list:
            if tag not in tags: return false
        return true

    has_none(tag_list) -> bool:
        for tag in tag_list:
            if tag in tags: return false
        return true

    has_any_matching(prefix) -> bool:
        for tag in tags:
            if tag starts with prefix + ".": return true
            if tag == prefix: return true
        return false

    remove_matching(prefix):
        tags = tags.filter(t => not (t starts with prefix + "." or t == prefix))

    get_all() -> list<string>:
        return tags.to_list()
```

**Lua:**
```lua
local TagContainer = {}
TagContainer.__index = TagContainer

function TagContainer.new()
    local self = setmetatable({}, TagContainer)
    self.tags = {}
    return self
end

function TagContainer:add(tag)
    self.tags[tag] = true
end

function TagContainer:remove(tag)
    self.tags[tag] = nil
end

function TagContainer:has(tag)
    return self.tags[tag] == true
end

function TagContainer:has_any(tag_list)
    for _, tag in ipairs(tag_list) do
        if self.tags[tag] then
            return true
        end
    end
    return false
end

function TagContainer:has_all(tag_list)
    for _, tag in ipairs(tag_list) do
        if not self.tags[tag] then
            return false
        end
    end
    return true
end

function TagContainer:has_none(tag_list)
    for _, tag in ipairs(tag_list) do
        if self.tags[tag] then
            return false
        end
    end
    return true
end

function TagContainer:has_any_matching(prefix)
    local dot_prefix = prefix .. "."
    for tag, _ in pairs(self.tags) do
        if tag == prefix or tag:sub(1, #dot_prefix) == dot_prefix then
            return true
        end
    end
    return false
end

function TagContainer:remove_matching(prefix)
    local dot_prefix = prefix .. "."
    local to_remove = {}
    for tag, _ in pairs(self.tags) do
        if tag == prefix or tag:sub(1, #dot_prefix) == dot_prefix then
            table.insert(to_remove, tag)
        end
    end
    for _, tag in ipairs(to_remove) do
        self.tags[tag] = nil
    end
end

function TagContainer:get_all()
    local result = {}
    for tag, _ in pairs(self.tags) do
        table.insert(result, tag)
    end
    table.sort(result)
    return result
end
```

**GDScript:**
```gdscript
class_name TagContainer

var tags: Dictionary = {}

func add(tag: String) -> void:
    tags[tag] = true

func remove(tag: String) -> void:
    tags.erase(tag)

func has(tag: String) -> bool:
    return tags.has(tag)

func has_any(tag_list: Array[String]) -> bool:
    for tag in tag_list:
        if tags.has(tag):
            return true
    return false

func has_all(tag_list: Array[String]) -> bool:
    for tag in tag_list:
        if not tags.has(tag):
            return false
    return true

func has_none(tag_list: Array[String]) -> bool:
    for tag in tag_list:
        if tags.has(tag):
            return false
    return true

func has_any_matching(prefix: String) -> bool:
    var dot_prefix = prefix + "."
    for tag in tags:
        if tag == prefix or tag.begins_with(dot_prefix):
            return true
    return false

func remove_matching(prefix: String) -> void:
    var dot_prefix = prefix + "."
    var to_remove: Array[String] = []
    for tag in tags:
        if tag == prefix or tag.begins_with(dot_prefix):
            to_remove.append(tag)
    for tag in to_remove:
        tags.erase(tag)

func get_all() -> Array[String]:
    var result: Array[String] = []
    for tag in tags:
        result.append(tag)
    result.sort()
    return result
```

---

## 4. Tag Queries in Practice

These four operations — `has`, `has_any`, `has_all`, `has_none` — power nearly every requirement check in the entire ability system. Let's see how they map to real gameplay scenarios:

**"Can this character cast spells?"**
```lua
-- Requires being alive, blocks on stun and silence
local can_cast = tags:has("State.Alive")
    and tags:has_none({"State.Stunned", "State.Silenced", "State.Dead"})
```

**"Is this character affected by any status condition?"**
```lua
local has_status = tags:has_any_matching("Status")
```

**"Should this fire damage apply?"**
```lua
-- Check if target is immune to fire damage
local blocked = target_tags:has_any({
    "Immune.Damage.Fire",
    "Immune.Damage.All"
})
```

**"Is the Fireball ability off cooldown?"**
```lua
local off_cooldown = not tags:has("Cooldown.Fireball")
```

**"Does this entity have all prerequisites for a quest?"**
```lua
local qualified = tags:has_all({
    "Quest.KilledDragon",
    "Quest.FoundArtifact",
    "State.Alive"
})
```

**"Cleanse all negative status effects."**
```lua
tags:remove_matching("Status")
-- Removes Status.Burning, Status.Poisoned, Status.Frozen, etc.
-- Does NOT remove State.Alive, Immune.Damage.Fire, etc.
```

Notice the pattern: every check is a simple query on the tag container. No boolean fields. No enum comparisons. No switch statements. The tag hierarchy provides the categorization that would otherwise require separate data structures.

---

## 5. Tag Requirements

A **tag requirement** is a pair of conditions: "require all of these tags" and "block if any of these tags." This structure is used throughout GAS — abilities, effects, and cues all use tag requirements to gate their behavior.

**Pseudocode:**
```
TagRequirement:
    require_tags: list<string>    // ALL must be present
    block_tags: list<string>      // NONE must be present

    check(container) -> bool:
        return container.has_all(require_tags)
           and container.has_none(block_tags)
```

**Lua:**
```lua
local TagRequirement = {}
TagRequirement.__index = TagRequirement

function TagRequirement.new(require_tags, block_tags)
    local self = setmetatable({}, TagRequirement)
    self.require_tags = require_tags or {}
    self.block_tags = block_tags or {}
    return self
end

function TagRequirement:check(container)
    return container:has_all(self.require_tags)
       and container:has_none(self.block_tags)
end

-- Examples:

-- Ability activation: must be alive, can't be stunned or silenced
local cast_req = TagRequirement.new(
    { "State.Alive" },                              -- require
    { "State.Stunned", "State.Silenced", "State.Dead" }  -- block
)

-- Fire damage application: target can't be fire-immune
local fire_damage_req = TagRequirement.new(
    {},                                              -- no requirements
    { "Immune.Damage.Fire", "Immune.Damage.All" }    -- block
)

-- Healing: target must be alive, can't be cursed (curse prevents healing)
local heal_req = TagRequirement.new(
    { "State.Alive" },                               -- require
    { "Status.Cursed" }                               -- block
)

-- Testing:
local tags = TagContainer.new()
tags:add("State.Alive")

print(cast_req:check(tags))        -- true (alive, not stunned/silenced)
print(fire_damage_req:check(tags)) -- true (not fire-immune)
print(heal_req:check(tags))        -- true (alive, not cursed)

tags:add("State.Stunned")
print(cast_req:check(tags))        -- false (stunned!)

tags:remove("State.Stunned")
tags:add("Status.Cursed")
print(heal_req:check(tags))        -- false (cursed blocks healing)
```

**GDScript:**
```gdscript
class_name TagRequirement

var require_tags: Array[String] = []
var block_tags: Array[String] = []

func _init(p_require: Array[String] = [], p_block: Array[String] = []):
    require_tags = p_require
    block_tags = p_block

func check(container: TagContainer) -> bool:
    return container.has_all(require_tags) and container.has_none(block_tags)

# Usage:
var cast_req = TagRequirement.new(
    ["State.Alive"],
    ["State.Stunned", "State.Silenced", "State.Dead"]
)

var tags = TagContainer.new()
tags.add("State.Alive")
print(cast_req.check(tags))  # true

tags.add("State.Stunned")
print(cast_req.check(tags))  # false
```

Tag requirements are the building block for ability activation checks (Module 4) and effect application checks (Module 3). Instead of writing `if alive and not stunned and not silenced`, you define a tag requirement once as data and call `check()`. Adding a new blocking condition (like `State.Feared`) means adding one string to the block list — no code changes.

---

## 6. Tag Counting (Reference Counting)

There's a subtle problem with the simple set-based container: what happens when two effects both grant `State.Stunned`? Effect A stuns for 2 seconds, effect B stuns for 5 seconds. After 2 seconds, effect A expires and removes `State.Stunned`. But effect B is still active — the character should still be stunned!

The simple set doesn't handle this. When effect A removes `State.Stunned`, it's gone, even though effect B also granted it. The fix is **reference counting** — tracking how many sources have granted each tag.

**Lua (reference-counted version):**
```lua
local TagContainer = {}
TagContainer.__index = TagContainer

function TagContainer.new()
    local self = setmetatable({}, TagContainer)
    self.tag_counts = {}  -- tag -> count
    return self
end

function TagContainer:add(tag)
    self.tag_counts[tag] = (self.tag_counts[tag] or 0) + 1
end

function TagContainer:remove(tag)
    local count = self.tag_counts[tag]
    if count then
        count = count - 1
        if count <= 0 then
            self.tag_counts[tag] = nil
        else
            self.tag_counts[tag] = count
        end
    end
end

function TagContainer:has(tag)
    return (self.tag_counts[tag] or 0) > 0
end

function TagContainer:get_count(tag)
    return self.tag_counts[tag] or 0
end

-- has_any, has_all, has_none, has_any_matching work the same —
-- they just check if the count is > 0, which :has() already does.
function TagContainer:has_any(tag_list)
    for _, tag in ipairs(tag_list) do
        if self:has(tag) then return true end
    end
    return false
end

function TagContainer:has_all(tag_list)
    for _, tag in ipairs(tag_list) do
        if not self:has(tag) then return false end
    end
    return true
end

function TagContainer:has_none(tag_list)
    for _, tag in ipairs(tag_list) do
        if self:has(tag) then return false end
    end
    return true
end

function TagContainer:has_any_matching(prefix)
    local dot_prefix = prefix .. "."
    for tag, count in pairs(self.tag_counts) do
        if count > 0 and (tag == prefix or tag:sub(1, #dot_prefix) == dot_prefix) then
            return true
        end
    end
    return false
end

function TagContainer:remove_matching(prefix)
    local dot_prefix = prefix .. "."
    local to_remove = {}
    for tag, _ in pairs(self.tag_counts) do
        if tag == prefix or tag:sub(1, #dot_prefix) == dot_prefix then
            table.insert(to_remove, tag)
        end
    end
    for _, tag in ipairs(to_remove) do
        self.tag_counts[tag] = nil  -- force remove regardless of count
    end
end

function TagContainer:get_all()
    local result = {}
    for tag, count in pairs(self.tag_counts) do
        if count > 0 then
            table.insert(result, tag)
        end
    end
    table.sort(result)
    return result
end
```

**GDScript:**
```gdscript
class_name TagContainer

var tag_counts: Dictionary = {}

func add(tag: String) -> void:
    tag_counts[tag] = tag_counts.get(tag, 0) + 1

func remove(tag: String) -> void:
    if tag_counts.has(tag):
        tag_counts[tag] -= 1
        if tag_counts[tag] <= 0:
            tag_counts.erase(tag)

func has(tag: String) -> bool:
    return tag_counts.get(tag, 0) > 0

func get_count(tag: String) -> int:
    return tag_counts.get(tag, 0)

func has_any(tag_list: Array[String]) -> bool:
    for tag in tag_list:
        if has(tag):
            return true
    return false

func has_all(tag_list: Array[String]) -> bool:
    for tag in tag_list:
        if not has(tag):
            return false
    return true

func has_none(tag_list: Array[String]) -> bool:
    for tag in tag_list:
        if has(tag):
            return false
    return true
```

Now the stun scenario works correctly:

```lua
local tags = TagContainer.new()

tags:add("State.Stunned")    -- effect A grants stun (count: 1)
tags:add("State.Stunned")    -- effect B grants stun (count: 2)
print(tags:has("State.Stunned"))  -- true

tags:remove("State.Stunned") -- effect A expires (count: 1)
print(tags:has("State.Stunned"))  -- true (effect B still active)

tags:remove("State.Stunned") -- effect B expires (count: 0)
print(tags:has("State.Stunned"))  -- false
```

Reference counting adds minimal complexity but prevents a whole class of bugs where overlapping effects interfere with each other's tag cleanup. Use it from the start.

Note that `remove_matching` (used for "cleanse all statuses") force-removes regardless of count. This is intentional — a cleanse should remove the tag completely, not just decrement it.

---

## 7. Designing Your Tag Hierarchy

Designing good tags is a game design skill, not a programming one. Here are practical guidelines:

**Start broad, refine later.** Begin with obvious top-level categories: `State`, `Status`, `Ability`, `Immune`, `Cooldown`. Add sub-categories when you need to query them. Don't pre-design a deep hierarchy — let gameplay needs drive it.

**State vs. Status.** A useful convention: `State` tags are fundamental character states (alive, dead, in combat). `Status` tags are conditions applied by effects (burning, poisoned, stunned). The distinction matters because "cleanse all status effects" should remove `Status.*` but not `State.Alive`.

```
State.Alive        -- fundamental, not cleansable
State.Dead         -- fundamental
State.InCombat     -- fundamental
State.Stunned      -- debilitating state, maybe cleansable?
Status.Burning     -- applied by effect, cleansable
Status.Poisoned    -- applied by effect, cleansable
```

The line between State and Status is a design decision. Some games put stun under Status (cleansable), others under State (not cleansable). Pick a convention and be consistent.

**Immune tags are negative requirements.** Instead of checking "does the target resist fire?", check "does the target have `Immune.Damage.Fire`?" Effects use block tags: `block: ["Immune.Damage.Fire"]`. This inverts the logic — immunity prevents application rather than reducing damage. Both approaches work; the tag-based approach is more composable.

**Cooldown tags are elegant.** When a character uses Fireball, the ability applies a duration effect that grants `Cooldown.Fireball` for 3 seconds. The ability's activation requirement blocks on `Cooldown.Fireball`. Cooldowns become just another tag check — no separate cooldown tracking system needed.

**Don't over-tag.** Not everything needs a tag. Tags are for state that needs to be queried by other systems. If nothing ever checks whether a character is "jumping," you don't need a `State.Jumping` tag. If the animation system needs to know, maybe you do. Let queries drive tag creation.

---

## 8. Tags Beyond Abilities

Tags aren't limited to ability systems. Once you have a tag container, you'll find uses everywhere:

**AI decision-making.** An AI queries `target:has_any_matching("Status")` to decide whether to apply another debuff or switch to direct damage. The AI doesn't need to know what statuses exist — just whether the target has any.

**Quest/progression tracking.** `Quest.KilledBoss`, `Achievement.FirstBlood`, `Tutorial.CompletedMovement`. Check prerequisites with `has_all`.

**Equipment effects.** A fire sword grants `Ability.Type.Fire` to attacks. A shield grants `Immune.Damage.Physical` while blocking. Equipment modifies tags just like effects do.

**Level/environment.** `Zone.Underwater` modifies which abilities work. `Weather.Rain` might buff ice damage. Tags on the environment interact with tags on characters.

**UI filtering.** Show only abilities matching `Ability.Type.Fire` in the fire spell page. Filter inventory by `Item.Type.Weapon`. Tags are natural filter criteria.

The tag container is the most reusable piece of the entire ability system. Even if you never build the full GAS architecture, a tag container improves almost any game.

---

## 9. Performance Considerations

For most games, the naive implementation (strings in a hash set) is fast enough. A hash set lookup is O(1). Even `has_any_matching` (which scans all tags with prefix matching) is fast when entities have 10–30 tags.

If you're building a game with thousands of entities each checked multiple times per frame, consider:

**String interning.** Map each tag string to an integer ID at initialization. Store IDs in the set instead of strings. Comparisons become integer equality. Prefix matching becomes range checks if IDs are assigned hierarchically.

```lua
-- String interning example
local tag_ids = {}
local next_id = 0

local function intern(tag)
    if not tag_ids[tag] then
        tag_ids[tag] = next_id
        next_id = next_id + 1
    end
    return tag_ids[tag]
end

-- Now store interned IDs in the container instead of strings
```

**Bitfield tags.** If your total tag count is under 64, store the entire container as a 64-bit integer. Each tag gets a bit position. `has` is a bitwise AND. `has_all` is `(container & mask) == mask`. `has_any` is `(container & mask) ~= 0`. Blazing fast, but limited to 64 tags and loses hierarchy.

**Hierarchical ID ranges.** Assign tag IDs so that children follow parents: `Status` = 100, `Status.Burning` = 101, `Status.Frozen` = 102, etc. Then `has_any_matching("Status")` becomes "has any tag with ID in range [100, 199]." This preserves hierarchy with integer performance.

For a learning project or any game with fewer than a few hundred entities, use strings. Optimize only when profiling shows tag queries are a bottleneck.

---

## Exercise

Implement a `TagContainer` in Lua (or your preferred language). Support: `add(tag)`, `remove(tag)`, `has(tag)`, `has_any(tags)`, `has_all(tags)`, `has_none(tags)`, `has_any_matching(prefix)`, and `remove_matching(prefix)`. Use reference counting for add/remove.

**Test cases:**

1. Add `Status.Burning`, `Status.Poisoned`, `State.Alive`, `Ability.Type.Fire`.
2. `has("Status.Burning")` → true
3. `has("State.Dead")` → false
4. `has_any_matching("Status")` → true
5. `has_all({"State.Alive", "Status.Burning"})` → true
6. `has_none({"State.Dead"})` → true
7. `has_none({"State.Alive"})` → false

8. Write a `TagRequirement` with `require_tags` and `block_tags`. An ability requires `State.Alive` and blocks on `State.Stunned`:
   - Character is alive, not stunned → `check()` returns true
   - Character is alive and stunned → `check()` returns false
   - Character is dead → `check()` returns false

9. Test reference counting:
   - Add `State.Stunned` twice (two stun effects)
   - Remove once → `has("State.Stunned")` still true
   - Remove again → `has("State.Stunned")` now false

10. Test `remove_matching`:
    - Tags: `Status.Burning`, `Status.Poisoned`, `State.Alive`
    - `remove_matching("Status")` → `Status.Burning` and `Status.Poisoned` removed
    - `State.Alive` still present

**Stretch goals:**
- Implement `on_tag_added(tag)` and `on_tag_removed(tag)` callbacks. These will be useful for cues (Module 6) — when `Status.Burning` is added, fire a cue to start the burning VFX.
- Implement `get_tags_matching(prefix)` that returns all tags under a prefix. Useful for UI: "show all active status effects."
- Try the string interning optimization: map strings to integers and benchmark the difference.

---

## Read

- **GASDocumentation — Gameplay Tags:** https://github.com/tranek/GASDocumentation#concepts-gt — how Unreal structures tag hierarchy and matching. The prefix matching concept maps directly to what you've built.
- **"Tag-based game architecture"** — search for blog posts on using tags instead of enums/flags for game state. The pattern is common in roguelike and RPG development.
- **Godot's StringName system:** https://docs.godotengine.org/en/stable/classes/class_stringname.html — relevant if implementing in Godot. StringNames are interned strings, giving you string readability with integer performance.

---

## Summary

A **gameplay tag** is a hierarchical string label. A **tag container** is a set of tags (with reference counting) attached to an entity. The core operations — `has`, `has_any`, `has_all`, `has_none`, `has_any_matching` — replace boolean fields, enum checks, and hardcoded conditionals with a single, extensible query system.

**Tag requirements** (require + block lists) are the gatekeeping mechanism for the entire ability system. Abilities check them for activation. Effects check them for application. Cues check them for feedback routing.

Key rules:
- Tags are strings, not enums. New tags don't require code changes.
- The hierarchy is in the naming convention, not a data structure. Prefix matching provides category queries.
- Use reference counting so overlapping effects don't interfere with each other's tag cleanup.
- Let gameplay needs drive tag design. Don't pre-design — add tags when you need to query them.

Next up: [Module 3 — Gameplay Effects](module-03-gameplay-effects.md), where tags and attributes combine into data-driven effect packages.
