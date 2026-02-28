# Module 5: Decision Making — Utility AI

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 5-8 hours
**Prerequisites:** [Module 2: Behavior Trees](module-02-behavior-trees.md)

---

## Overview

FSMs and behavior trees make decisions with binary conditions: is the player visible? Is health below 50%? These yes/no checks work well for straightforward situations, but they produce NPCs that feel mechanical — the thresholds are obvious, the behavior is predictable, and there's no nuance. Utility AI replaces boolean checks with **scored evaluations**, and the difference is dramatic.

Imagine an NPC deciding what to do. A behavior tree checks conditions in priority order: "Am I in danger? Then fight. Am I hungry? Then eat. Otherwise, explore." Utility AI asks a different question: "How much do I want to fight right now? How much do I want to eat? How much do I want to explore?" It scores every option on a 0-to-1 scale and picks the highest. An NPC that's slightly hungry but near enemies will fight first and eat later. One that's starving will risk the danger to eat. These decisions emerge naturally from the scoring, with no explicit rules for each situation.

The magic ingredient is **response curves** — functions that map input values to scores. A linear curve for hunger means the NPC cares equally about going from 10% to 20% hungry as from 80% to 90%. An exponential curve means it barely cares at low hunger but becomes desperate at high hunger. By shaping curves, you give NPCs distinct personalities without writing separate behavior code. An aggressive NPC has a steep combat curve. A cautious one has a steep flee curve. Same system, different tuning.

---

## 1. The Core Loop: Score and Choose

Utility AI follows a simple loop every tick:

1. For each possible action, calculate a **utility score** (0.0 to 1.0)
2. Pick the action with the highest score
3. Execute that action

That's the entire architecture. The complexity lives in how you calculate the scores, not in the decision-making structure.

```
Actions and their scores this tick:
┌──────────────┬───────┐
│ Action       │ Score │
├──────────────┼───────┤
│ Attack       │ 0.82  │ ← highest, execute this
│ Flee         │ 0.35  │
│ Eat          │ 0.61  │
│ Explore      │ 0.20  │
│ Sleep        │ 0.45  │
└──────────────┴───────┘
```

```gdscript
# GDScript — Core utility AI loop
var actions: Array[Dictionary] = []  # [{name, score_fn, execute_fn}]

func _process(delta: float) -> void:
    var best_action = null
    var best_score = -1.0

    for action in actions:
        var score = action.score_fn.call(self)
        if score > best_score:
            best_score = score
            best_action = action

    if best_action:
        best_action.execute_fn.call(self, delta)
```

```lua
-- Lua — Core utility AI loop
local actions = {
    { name = "attack",  score = score_attack,  execute = do_attack },
    { name = "flee",    score = score_flee,     execute = do_flee },
    { name = "eat",     score = score_eat,      execute = do_eat },
    { name = "explore", score = score_explore,  execute = do_explore },
    { name = "sleep",   score = score_sleep,    execute = do_sleep },
}

function update_utility_ai(npc, dt)
    local best = nil
    local best_score = -1

    for _, action in ipairs(actions) do
        local s = action.score(npc)
        if s > best_score then
            best_score = s
            best = action
        end
    end

    if best then
        npc.current_action = best.name
        best.execute(npc, dt)
    end
end
```

---

## 2. Response Curves — Shaping Decisions

A response curve maps an input value (0 to 1) to a score (0 to 1). The shape of the curve determines how the NPC "feels" about that input at different levels.

**Linear:** `score = input`
Cares equally at all levels. Going from 0.1 to 0.2 hunger matters as much as 0.8 to 0.9.

**Quadratic (exponential):** `score = input²`
Barely cares at low values, increasingly cares at high values. The NPC ignores low hunger but panics when starving.

**Inverse quadratic:** `score = 1 - (1 - input)²`
Cares a lot at low values, plateaus at high values. The NPC responds quickly to the first sign of danger but doesn't get increasingly panicked.

**Logistic (S-curve):** `score = 1 / (1 + e^(-k * (input - midpoint)))`
Low response at the bottom, sharp ramp in the middle, plateau at the top. Creates a natural "threshold" without a hard cutoff.

```
Linear:         Quadratic:      Logistic:
1│    /         1│      /       1│     ──
 │   /           │     /         │    /
 │  /            │    /          │   │
 │ /             │  /            │  /
 │/              │/              │──
 └────           └────           └────
  0  1            0  1            0  1
```

```lua
-- Lua — Response curve functions
local function linear(input)
    return math.max(0, math.min(1, input))
end

local function quadratic(input)
    input = math.max(0, math.min(1, input))
    return input * input
end

local function inverse_quadratic(input)
    input = math.max(0, math.min(1, input))
    return 1 - (1 - input) * (1 - input)
end

local function logistic(input, steepness, midpoint)
    steepness = steepness or 10
    midpoint = midpoint or 0.5
    return 1 / (1 + math.exp(-steepness * (input - midpoint)))
end

-- Custom curve: low baseline that spikes at high values
local function spike(input, threshold)
    threshold = threshold or 0.7
    if input < threshold then return input * 0.2 end
    return 0.2 + (input - threshold) / (1 - threshold) * 0.8
end
```

```gdscript
# GDScript — Response curves
static func linear(input: float) -> float:
    return clampf(input, 0.0, 1.0)

static func quadratic(input: float) -> float:
    input = clampf(input, 0.0, 1.0)
    return input * input

static func logistic(input: float, steepness := 10.0, midpoint := 0.5) -> float:
    return 1.0 / (1.0 + exp(-steepness * (input - midpoint)))
```

The choice of curve shape is the core design decision in utility AI. It's where you encode how the NPC "thinks" — what it cares about, how urgently, and at what thresholds.

---

## 3. Considerations — Building a Score from Multiple Factors

Most actions don't depend on a single input. "Should I attack?" depends on health, distance to enemy, ammo count, number of allies, and whether I have a clear shot. Each of these factors is a **consideration**, and they combine to produce the action's final score.

The simplest combination is **multiplication**. Each consideration produces a 0-1 score, and you multiply them together:

```
Attack score = health_factor * distance_factor * ammo_factor
             = 0.9           * 0.7              * 0.8
             = 0.504
```

Multiplication has a useful property: if any factor is 0, the whole score is 0. No health → no attacking. No ammo → no attacking. Each factor acts as a soft veto.

```lua
-- Lua — Multi-factor scoring with considerations
function score_attack(npc)
    -- Factor 1: Health (quadratic — fights more when healthy)
    local health_factor = quadratic(npc.health / npc.max_health)

    -- Factor 2: Distance to enemy (inverse — closer = more desire to fight)
    local dist = distance(npc.x, npc.y, player.x, player.y)
    local dist_normalized = math.min(dist / 300, 1)  -- normalize to 0-1
    local dist_factor = 1 - dist_normalized

    -- Factor 3: Ammo (logistic — doesn't care until low, then cares a lot)
    local ammo_factor = logistic(npc.ammo / npc.max_ammo, 10, 0.2)

    return health_factor * dist_factor * ammo_factor
end

function score_flee(npc)
    -- Inverse of health (low health = high flee desire)
    local danger = 1 - (npc.health / npc.max_health)
    local health_factor = quadratic(danger)

    -- Proximity to threat
    local dist = distance(npc.x, npc.y, player.x, player.y)
    local proximity = 1 - math.min(dist / 200, 1)
    local dist_factor = inverse_quadratic(proximity)

    return health_factor * dist_factor
end

function score_eat(npc)
    -- Hunger drives eating (exponential — desperate when starving)
    local hunger_factor = quadratic(npc.hunger / npc.max_hunger)

    -- Safety check (won't eat if enemies are close)
    local dist = distance(npc.x, npc.y, player.x, player.y)
    local safety = math.min(dist / 200, 1)
    local safety_factor = linear(safety)

    -- Food availability
    local food_factor = npc.knows_food_location and 1.0 or 0.2

    return hunger_factor * safety_factor * food_factor
end
```

```gdscript
# GDScript — Multi-factor scoring
func score_attack() -> float:
    var health_factor = Curves.quadratic(health / max_health)
    var dist = global_position.distance_to(player.global_position)
    var dist_factor = 1.0 - clampf(dist / 300.0, 0.0, 1.0)
    var ammo_factor = Curves.logistic(float(ammo) / max_ammo, 10.0, 0.2)
    return health_factor * dist_factor * ammo_factor

func score_flee() -> float:
    var danger = 1.0 - (health / max_health)
    var health_factor = Curves.quadratic(danger)
    var dist = global_position.distance_to(player.global_position)
    var proximity = 1.0 - clampf(dist / 200.0, 0.0, 1.0)
    return health_factor * Curves.inverse_quadratic(proximity)
```

---

## 4. Personality Through Curve Tuning

Here's where utility AI becomes magical. By changing the curve shapes and parameters for each NPC type, you create distinct personalities without changing any code.

```lua
-- Lua — Personality profiles (same actions, different curves)
local aggressive_profile = {
    attack_health_curve = function(x) return linear(x) end,      -- fights even at low health
    attack_distance_weight = 1.5,                                 -- eager to close distance
    flee_threshold = 0.15,                                        -- barely ever flees
}

local cautious_profile = {
    attack_health_curve = function(x) return quadratic(x) end,    -- only fights when healthy
    attack_distance_weight = 0.7,                                 -- prefers range
    flee_threshold = 0.5,                                         -- flees at half health
}

local berserker_profile = {
    attack_health_curve = function(x) return 1 - quadratic(1-x) end,  -- fights MORE when hurt
    attack_distance_weight = 2.0,                                       -- rushes in
    flee_threshold = 0.0,                                               -- never flees
}
```

The berserker's attack curve is inverted — lower health means *higher* attack score. This NPC becomes more dangerous as it gets wounded. The cautious NPC's quadratic attack curve means it barely wants to fight at 50% health and won't fight at 25%. Same utility system, three radically different behaviors, zero `if/else` personality code.

A visual comparison:

```
Attack desire vs. health remaining:

Aggressive:     Cautious:       Berserker:
1│────          1│      /       1│\
 │    \          │     /         │ \
 │     \         │   /           │  \
 │      \        │  /            │   \
 │       \       │/              │    ──
 └────────       └────           └────────
 0% health      0% health       0% health
```

---

## 5. Score Normalization and the Compensation Factor

When you multiply multiple considerations, scores tend to shrink. Three factors at 0.7 each produce 0.343. This makes actions with more considerations systematically lower-scoring than actions with fewer considerations.

The fix is **compensation**: after multiplying, raise the result to the power of `1/n` (where n is the number of considerations). This normalizes the score to compensate for the number of factors.

```
Without compensation:                    With compensation:
attack = 0.7 * 0.8 * 0.9 = 0.504       attack = 0.504^(1/3) = 0.796
eat    = 0.8 * 0.9 = 0.72              eat    = 0.72^(1/2)  = 0.849

(eat always wins because it has         (fair comparison — both scores
 fewer factors bringing it down)         reflect actual desirability)
```

```lua
-- Lua — Compensated multiplication
function compensated_score(factors)
    local score = 1
    local count = #factors
    for _, f in ipairs(factors) do
        score = score * f
    end
    -- Compensation: geometric mean
    return score ^ (1 / count)
end

-- Usage
local attack_score = compensated_score({
    health_factor,
    distance_factor,
    ammo_factor,
})
```

Not every implementation needs this. If all your actions have roughly the same number of considerations, the bias is small. But if you have actions ranging from 1 to 5 considerations, compensation prevents unfair scoring.

---

## 6. Action Selection Strategies

Always picking the highest score produces consistent but predictable behavior. The player learns that the NPC always does the "best" thing, which can feel robotic. Several selection strategies add natural variation.

**Highest score (greedy):** Always pick the best. Simple, predictable. Good for simple systems.

**Weighted random:** Treat scores as probabilities. Higher scores are more likely, but lower-scoring actions can still occur. This adds natural variation — the NPC usually attacks but occasionally does something unexpected.

```lua
-- Lua — Weighted random selection
function weighted_random_select(actions, npc)
    local scored = {}
    local total = 0
    for _, action in ipairs(actions) do
        local s = action.score(npc)
        if s > 0.01 then  -- ignore negligible scores
            table.insert(scored, { action = action, score = s })
            total = total + s
        end
    end

    local roll = love.math.random() * total
    local cumulative = 0
    for _, entry in ipairs(scored) do
        cumulative = cumulative + entry.score
        if roll <= cumulative then
            return entry.action
        end
    end
    return scored[#scored].action  -- fallback
end
```

**Top-N random:** Pick randomly from the top N scoring actions. Ensures the NPC always does something reasonable but with variation. Top-2 or top-3 is common.

**Score threshold:** Only consider actions above a minimum score. Pick the highest, or pick randomly from those above the threshold. This prevents the NPC from choosing low-scoring actions.

**Inertia/momentum:** Add a bonus to the currently executing action. This prevents rapid action-switching and makes behavior feel more committed. The NPC continues attacking for a few more ticks even when eating becomes slightly more attractive.

```lua
-- Lua — Action inertia
local inertia_bonus = 0.1

function select_with_inertia(actions, npc)
    local best = nil
    local best_score = -1
    for _, action in ipairs(actions) do
        local s = action.score(npc)
        if action.name == npc.current_action then
            s = s + inertia_bonus  -- stick with current action
        end
        if s > best_score then
            best_score = s
            best = action
        end
    end
    return best
end
```

---

## 7. Dual Utility — Scoring Actions AND Targets

So far, we've scored actions: attack vs. flee vs. eat. But within an action, there are often multiple targets. "Attack" — but attack *which* enemy? "Eat" — but eat *which* food source?

**Dual utility** scores both the action and the target. For each action, evaluate it against every possible target and keep the best (action, target) pair.

```lua
-- Lua — Dual utility: scoring action + target
function score_attack_target(npc, target)
    local health_factor = quadratic(npc.health / npc.max_health)
    local dist = distance(npc.x, npc.y, target.x, target.y)
    local dist_factor = 1 - math.min(dist / 300, 1)

    -- Target-specific factors
    local threat_factor = linear(target.damage / 50)  -- prioritize dangerous enemies
    local weakness_factor = 1 - (target.health / target.max_health)  -- prefer wounded

    return health_factor * dist_factor * (threat_factor + weakness_factor) / 2
end

function evaluate_attack(npc, enemies)
    local best_target = nil
    local best_score = 0
    for _, enemy in ipairs(enemies) do
        local s = score_attack_target(npc, enemy)
        if s > best_score then
            best_score = s
            best_target = enemy
        end
    end
    return best_score, best_target
end
```

This produces tactical behavior naturally. The NPC attacks the closest wounded enemy (easiest kill) when it's healthy, but attacks the most dangerous enemy (biggest threat) when allies are dying. No explicit rules — just curve interactions.

---

## 8. Utility AI vs. Other Architectures

| Aspect | FSM | Behavior Tree | Utility AI |
|--------|-----|---------------|------------|
| **Decision type** | Binary (conditions) | Binary (conditions) | Continuous (scores) |
| **Adding actions** | Hard (transition spaghetti) | Moderate (insert branch) | Easy (add action + score function) |
| **Nuanced behavior** | No | Limited | Yes — inherent |
| **Personality** | Needs separate logic | Needs separate tree structure | Curve tuning only |
| **Debuggability** | Excellent (print state) | Good (print active branch) | Moderate (print all scores) |
| **Predictability** | Very predictable | Predictable | Less predictable (by design) |
| **Best for** | Simple enemies | Complex enemies | NPCs with competing needs, survival AI |

**When to use utility AI:**
- NPCs with multiple competing needs (hunger, thirst, safety, social)
- Survival or simulation games where NPC behavior should feel organic
- When you want distinct NPC personalities from the same codebase
- When you want smooth transitions between behaviors (no hard state changes)

**When NOT to use utility AI:**
- Simple enemies that only need 3-4 behaviors (use FSM)
- When you need strict priority ordering (use behavior tree)
- When predictability matters more than nuance (boss patterns, puzzle NPCs)

**Hybrid approach:** Use a behavior tree for the high-level structure and utility AI for specific decision nodes. The behavior tree determines "am I in combat or peaceful?" and within combat, utility AI scores "attack, dodge, use ability, or retreat?"

---

## Code Walkthrough: A Survival NPC

Let's build a complete survival NPC with four needs (hunger, thirst, energy, safety) and five actions (eat, drink, sleep, explore, flee). The NPC's behavior emerges entirely from utility scoring — no explicit rules for what to do when.

```lua
-- Lua (LÖVE) — Complete survival NPC with utility AI
local npc = {
    x = 400, y = 300,
    speed = 80,
    -- Needs (0 = fully satisfied, 1 = desperate)
    hunger = 0.3,
    thirst = 0.2,
    energy = 0.8,  -- high = well-rested
    -- World knowledge
    target_x = nil, target_y = nil,
    current_action = "explore",
}

-- Need decay rates (per second)
local decay = { hunger = 0.02, thirst = 0.03, energy = -0.01 }

-- Food and water sources
local food = { {x = 100, y = 100}, {x = 600, y = 400} }
local water = { {x = 500, y = 100}, {x = 200, y = 500} }
local danger_zone = { x = 350, y = 250, radius = 120 }

-- Response curves
local function quadratic(x) return math.max(0, math.min(1, x))^2 end
local function inv_quad(x) x = math.max(0, math.min(1, x)); return 1-(1-x)^2 end

-- Score functions
local function score_eat(n)
    local hunger_urgency = quadratic(n.hunger)
    local nearest = nearest_dist(n, food)
    local accessibility = 1 - math.min(nearest / 400, 1)
    return hunger_urgency * 0.7 + accessibility * 0.3
end

local function score_drink(n)
    local thirst_urgency = quadratic(n.thirst)  -- thirst is more urgent than hunger
    local nearest = nearest_dist(n, water)
    local accessibility = 1 - math.min(nearest / 400, 1)
    return thirst_urgency * 0.8 + accessibility * 0.2
end

local function score_sleep(n)
    local tiredness = quadratic(1 - n.energy)
    local danger = in_danger(n) and 0.2 or 1.0  -- won't sleep if unsafe
    return tiredness * danger
end

local function score_explore(n)
    return 0.25  -- constant low baseline — explores when nothing else is pressing
end

local function score_flee(n)
    if not in_danger(n) then return 0 end
    local dist = distance(n.x, n.y, danger_zone.x, danger_zone.y)
    local proximity = 1 - math.min(dist / danger_zone.radius, 1)
    return inv_quad(proximity) * 0.9
end

-- Helper functions
function nearest_dist(n, sources)
    local min_d = math.huge
    for _, s in ipairs(sources) do
        local d = distance(n.x, n.y, s.x, s.y)
        if d < min_d then min_d = d end
    end
    return min_d
end

function nearest_source(n, sources)
    local best, min_d = nil, math.huge
    for _, s in ipairs(sources) do
        local d = distance(n.x, n.y, s.x, s.y)
        if d < min_d then min_d = d; best = s end
    end
    return best
end

function in_danger(n)
    return distance(n.x, n.y, danger_zone.x, danger_zone.y) < danger_zone.radius
end

function distance(x1, y1, x2, y2)
    return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

-- Action execution
local actions = {
    { name = "eat",     score = score_eat,
      execute = function(n, dt)
          local target = nearest_source(n, food)
          if target then
              move_toward(n, target.x, target.y, dt)
              if distance(n.x, n.y, target.x, target.y) < 15 then
                  n.hunger = math.max(0, n.hunger - 0.3 * dt)
              end
          end
      end },
    { name = "drink",   score = score_drink,
      execute = function(n, dt)
          local target = nearest_source(n, water)
          if target then
              move_toward(n, target.x, target.y, dt)
              if distance(n.x, n.y, target.x, target.y) < 15 then
                  n.thirst = math.max(0, n.thirst - 0.4 * dt)
              end
          end
      end },
    { name = "sleep",   score = score_sleep,
      execute = function(n, dt)
          -- Stand still and recover energy
          n.energy = math.min(1, n.energy + 0.15 * dt)
      end },
    { name = "explore", score = score_explore,
      execute = function(n, dt)
          if not n.explore_target or distance(n.x, n.y, n.explore_target[1], n.explore_target[2]) < 20 then
              n.explore_target = {
                  love.math.random(50, 750),
                  love.math.random(50, 550)
              }
          end
          move_toward(n, n.explore_target[1], n.explore_target[2], dt)
      end },
    { name = "flee",    score = score_flee,
      execute = function(n, dt)
          local dx = n.x - danger_zone.x
          local dy = n.y - danger_zone.y
          local dist = math.sqrt(dx^2 + dy^2)
          if dist > 0 then
              n.x = n.x + (dx/dist) * n.speed * 1.3 * dt
              n.y = n.y + (dy/dist) * n.speed * 1.3 * dt
          end
      end },
}

function move_toward(n, tx, ty, dt)
    local dx, dy = tx - n.x, ty - n.y
    local dist = math.sqrt(dx^2 + dy^2)
    if dist > 3 then
        n.x = n.x + (dx/dist) * n.speed * dt
        n.y = n.y + (dy/dist) * n.speed * dt
    end
end

function love.update(dt)
    -- Decay needs
    npc.hunger = math.min(1, npc.hunger + decay.hunger * dt)
    npc.thirst = math.min(1, npc.thirst + decay.thirst * dt)
    npc.energy = math.max(0, npc.energy + decay.energy * dt)

    -- Utility AI decision
    local best, best_score = nil, -1
    for _, action in ipairs(actions) do
        local s = action.score(npc)
        if s > best_score then best_score = s; best = action end
    end
    if best then
        npc.current_action = best.name
        best.execute(npc, dt)
    end
end

function love.draw()
    -- Draw danger zone
    love.graphics.setColor(0.4, 0, 0, 0.3)
    love.graphics.circle("fill", danger_zone.x, danger_zone.y, danger_zone.radius)

    -- Draw food sources
    love.graphics.setColor(0.2, 0.8, 0.2)
    for _, f in ipairs(food) do love.graphics.circle("fill", f.x, f.y, 8) end

    -- Draw water sources
    love.graphics.setColor(0.2, 0.4, 1)
    for _, w in ipairs(water) do love.graphics.circle("fill", w.x, w.y, 8) end

    -- Draw NPC
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", npc.x, npc.y, 10)

    -- Draw state and needs
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Action: " .. npc.current_action, 10, 10)
    love.graphics.print(string.format("Hunger: %.0f%%  Thirst: %.0f%%  Energy: %.0f%%",
        npc.hunger * 100, npc.thirst * 100, npc.energy * 100), 10, 30)

    -- Draw utility scores
    local y_offset = 60
    for _, action in ipairs(actions) do
        local s = action.score(npc)
        local bar_width = s * 200
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 10, y_offset, 200, 14)
        love.graphics.setColor(0.2, 0.7, 0.9)
        love.graphics.rectangle("fill", 10, y_offset, bar_width, 14)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%s: %.2f", action.name, s), 220, y_offset)
        y_offset = y_offset + 18
    end
end
```

Watch this NPC for a few minutes and you'll see emergent behavior: it explores until it gets hungry, walks to food, eats, then notices it's thirsty and heads for water. If the danger zone is between it and the nearest food, it detours to the farther food source. If it's very hungry and tired simultaneously, hunger wins (because thirst decays faster). All of this behavior emerges from the curves — nobody scripted "if hungry and thirsty, prioritize the one with higher urgency."

---

## Common Pitfalls

### 1. All scores converging to similar values

If every action scores around 0.4-0.6, the NPC dithers — rapidly switching between actions because the winner changes each tick. Add **inertia** (bonus for the current action) and ensure your curves produce a wider spread of scores.

### 2. Forgetting to normalize inputs to 0-1

A raw distance of 347 pixels doesn't work as a curve input. Normalize everything: `distance / max_distance`, `health / max_health`, `ammo / max_ammo`. Response curves expect 0-1 input and produce 0-1 output.

### 3. Multiplication killing all scores

With 5 considerations each at 0.7, the product is 0.168. Use the compensation factor (geometric mean) or switch to weighted averaging for actions with many considerations.

### 4. No debug visualization

Utility AI is much harder to debug than FSMs because the "current state" isn't a single label — it's a table of scores. Always display the utility scores on screen during development. A bar chart of action scores is the minimum viable debug tool.

### 5. Action thrashing without inertia

The NPC starts walking to food, then next frame eating barely edges out drinking, so it switches to water, then switches back to food. Add inertia: a +0.05 to +0.15 bonus for the currently executing action. This creates commitment without hard state locks.

### 6. Using utility AI for everything

Not every NPC needs utility scoring. A simple enemy that patrols and chases is better served by an FSM. Utility AI shines for NPCs with multiple competing needs — survival games, villager AI, companion NPCs. Don't over-engineer simple enemies.

---

## Exercises

### Exercise 1: Survival NPC with Personalities
**Time:** 1.5-2 hours

Build the survival NPC from the code walkthrough, then create three personality variants:

1. **Lazy NPC:** High sleep curve, low explore baseline, slow movement
2. **Adventurous NPC:** High explore baseline, low sleep curve, fast movement
3. **Nervous NPC:** High flee curve, prefers food/water sources near the edge of the map (far from danger zone)

Run all three simultaneously. Document the behavioral differences you observe.

**Concepts practiced:** Utility scoring, response curves, personality through tuning

**Stretch goal:** Add a "social" need that draws NPCs toward each other. Watch them cluster at food/water sources.

---

### Exercise 2: Utility Score Dashboard
**Time:** 1-2 hours

Build a debug dashboard that shows all utility scores in real-time as bar charts. Requirements:

1. Each action has a horizontal bar showing its current score
2. The winning action is highlighted
3. Individual consideration values are shown for the winning action
4. Add sliders or keyboard controls to adjust need values manually (set hunger to 0.9 and watch the scores react)

This is a tool exercise — the dashboard will help you debug and tune every utility AI system you build.

**Concepts practiced:** Debug visualization, understanding score interactions, real-time tuning

---

### Exercise 3: Combat Utility AI
**Time:** 2-3 hours

Replace the behavior tree or FSM from your earlier guard NPC with a utility-based decision system. Actions:

1. **Melee attack:** High score when close + healthy + enemy nearby
2. **Ranged attack:** High score when medium distance + has ammo
3. **Take cover:** High score when taking damage + cover available
4. **Heal:** High score when health low + not in immediate danger
5. **Retreat:** High score when very low health + escape route exists

Use dual utility to score both the action and the target (which enemy to attack, which cover to use).

**Concepts practiced:** Combat utility, dual utility, integration with movement/steering

**Stretch goal:** Add personality profiles: a "tank" that prefers melee and never retreats, a "sniper" that prefers range and takes cover frequently, a "medic" that prioritizes healing allies over attacking.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| "An Introduction to Utility Theory" by Dave Mark, *Game AI Pro* | Book chapter (free) | The definitive reference — Dave Mark is the foremost advocate of utility AI in games |
| "Building a Better Centaur" by Dave Mark (GDC) | GDC talk | Practical utility AI architecture with real game examples |
| "Improving AI Decision Modeling Through Utility Theory" by Dave Mark & Kevin Dill | GDC talk | Advanced utility techniques including dual utility and curve design |
| *Game Programming Patterns* by Robert Nystrom | Book (free) | The Command and Observer patterns support utility system implementation |
| "The Sims" AI postmortem materials | Articles | The Sims popularized utility-based NPC needs — one of the most influential utility AI implementations |

---

## Key Takeaways

1. **Utility AI replaces boolean conditions with scored evaluations.** Instead of "is health < 50%?", ask "how much do I want to fight, given my health, distance, ammo, and allies?" The nuance creates believable decisions.

2. **Response curves are the design tool.** Linear, quadratic, logistic — the curve shape determines how the NPC "feels" about each input at different levels. Shaping curves is the core creative act.

3. **Personality emerges from curve tuning, not code.** An aggressive NPC has steep combat curves. A cautious one has steep flee curves. Same system, different parameters, distinct characters.

4. **Multiplication combines considerations with soft vetoes.** If any factor is zero, the action scores zero. Compensate with geometric mean when actions have different numbers of considerations.

5. **Inertia prevents action thrashing.** Add a small bonus to the currently executing action so the NPC commits to decisions for a reasonable duration instead of switching every frame.

6. **Debug visualization is mandatory.** Display all utility scores as bars during development. You cannot tune curves by reading numbers in a log — you need to see the scores change in real time.

---

## What's Next?

Utility AI scores options and picks the best one — but it only looks one step ahead. What if the NPC needs to *plan* — to figure out a multi-step sequence of actions to achieve a goal?

In [Module 6: Decision Making — GOAP](module-06-goap.md), you'll learn Goal-Oriented Action Planning, where NPCs construct their own plans from scratch. Given goals and available actions with preconditions and effects, a GOAP planner uses A* (yes, the same algorithm from Module 4) to search through action space and find a sequence that transforms the current world state into a desired one. It's the most ambitious decision-making architecture in this roadmap.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
