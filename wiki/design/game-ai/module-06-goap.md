# Module 6: Decision Making — GOAP

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 5-8 hours
**Prerequisites:** [Module 2: Behavior Trees](module-02-behavior-trees.md)

---

## Overview

GOAP — Goal-Oriented Action Planning — is the most ambitious decision-making pattern in this roadmap. Where FSMs and behavior trees encode decisions as hand-authored structures, and utility AI scores predetermined options, GOAP does something fundamentally different: the NPC **constructs its own plan**. You define goals ("kill the player," "get ammunition") and actions with preconditions and effects ("shoot requires has_ammo and target_visible; effect is target_damaged"). The GOAP planner searches for a sequence of actions that transforms the current world state into one where a goal is satisfied.

The landmark implementation was Monolith's **F.E.A.R.** in 2005, and it remains the best case study. In F.E.A.R., an AI soldier with the goal "kill the player" and low ammo might plan: find cover → move to cover → find ammo crate → move to ammo crate → pick up ammo → attack player. If the ammo crate is destroyed mid-plan, the planner re-evaluates and might plan: move to melee range → melee attack. Nobody scripted these sequences — they emerge from the action definitions.

GOAP is powerful but expensive, both computationally and in design effort. For most games, behavior trees or utility AI are sufficient and more maintainable. GOAP shines when you want NPCs that handle novel situations with multi-step plans, particularly in immersive sims and simulation-heavy games. Even if you never ship a GOAP system, understanding it will make you a better AI designer because it forces you to think about actions in terms of preconditions and effects — a discipline that improves any architecture.

---

## 1. World State as Key-Value Pairs

GOAP represents the world as a set of boolean or numeric key-value pairs. This is the planner's model of reality — intentionally simplified and incomplete.

```
Current World State:
┌───────────────────────────┐
│ has_ammo:       false     │
│ target_visible: true      │
│ target_dead:    false     │
│ at_cover:       false     │
│ health_low:     true      │
│ has_weapon:     true       │
│ near_ammo:      false     │
└───────────────────────────┘
```

The world state doesn't need to model everything — just the facts relevant to the NPC's decisions. In F.E.A.R., the world state was about 15-20 keys. You don't need hundreds of variables.

```lua
-- Lua — World state as a simple table
local world_state = {
    has_ammo = false,
    target_visible = true,
    target_dead = false,
    at_cover = false,
    health_low = true,
    has_weapon = true,
    near_ammo = false,
}
```

```gdscript
# GDScript — World state as a dictionary
var world_state := {
    "has_ammo": false,
    "target_visible": true,
    "target_dead": false,
    "at_cover": false,
    "health_low": true,
    "has_weapon": true,
    "near_ammo": false,
}
```

---

## 2. Goals — What the NPC Wants

A goal is a desired world state — a set of key-value pairs that the NPC wants to be true. Goals have priorities, and the planner tries to satisfy the highest-priority goal first.

```
Goals (ordered by priority):
1. survive:      { health_low: false }
2. kill_target:  { target_dead: true }
3. get_ammo:     { has_ammo: true }
```

A goal is satisfied when the current world state contains all the key-value pairs specified by the goal. The goal `{ target_dead: true }` is satisfied when `world_state.target_dead == true`.

```lua
-- Lua — Goal definitions
local goals = {
    { name = "survive",     priority = 3, state = { health_low = false } },
    { name = "kill_target", priority = 2, state = { target_dead = true } },
    { name = "get_ammo",    priority = 1, state = { has_ammo = true } },
}

-- Sort by priority (highest first)
table.sort(goals, function(a, b) return a.priority > b.priority end)
```

---

## 3. Actions — Preconditions, Effects, and Cost

An action is the core building block. Each action has:

- **Preconditions:** World state values that must be true before the action can execute
- **Effects:** World state changes that result from the action
- **Cost:** A numeric value representing the "expense" of this action (time, risk, resource cost)

```
Action: Shoot
  Preconditions: { has_ammo: true, target_visible: true, has_weapon: true }
  Effects:       { target_dead: true, has_ammo: false }
  Cost:          2

Action: Reload
  Preconditions: { near_ammo: true }
  Effects:       { has_ammo: true }
  Cost:          3

Action: Move To Cover
  Preconditions: {}
  Effects:       { at_cover: true }
  Cost:          4

Action: Find Ammo
  Preconditions: {}
  Effects:       { near_ammo: true }
  Cost:          5

Action: Heal
  Preconditions: { at_cover: true }
  Effects:       { health_low: false }
  Cost:          3

Action: Melee Attack
  Preconditions: { has_weapon: true, target_visible: true }
  Effects:       { target_dead: true }
  Cost:          6
```

```lua
-- Lua — Action definitions
local actions = {
    {
        name = "shoot",
        preconditions = { has_ammo = true, target_visible = true, has_weapon = true },
        effects = { target_dead = true },
        cost = 2,
    },
    {
        name = "reload",
        preconditions = { near_ammo = true },
        effects = { has_ammo = true },
        cost = 3,
    },
    {
        name = "move_to_cover",
        preconditions = {},
        effects = { at_cover = true },
        cost = 4,
    },
    {
        name = "find_ammo",
        preconditions = {},
        effects = { near_ammo = true },
        cost = 5,
    },
    {
        name = "heal",
        preconditions = { at_cover = true },
        effects = { health_low = false },
        cost = 3,
    },
    {
        name = "melee",
        preconditions = { has_weapon = true, target_visible = true },
        effects = { target_dead = true },
        cost = 6,
    },
}
```

```gdscript
# GDScript — Action definitions
var actions := [
    {
        "name": "shoot",
        "preconditions": { "has_ammo": true, "target_visible": true, "has_weapon": true },
        "effects": { "target_dead": true },
        "cost": 2,
    },
    {
        "name": "reload",
        "preconditions": { "near_ammo": true },
        "effects": { "has_ammo": true },
        "cost": 3,
    },
    {
        "name": "move_to_cover",
        "preconditions": {},
        "effects": { "at_cover": true },
        "cost": 4,
    },
    {
        "name": "find_ammo",
        "preconditions": {},
        "effects": { "near_ammo": true },
        "cost": 5,
    },
    {
        "name": "heal",
        "preconditions": { "at_cover": true },
        "effects": { "health_low": false },
        "cost": 3,
    },
    {
        "name": "melee",
        "preconditions": { "has_weapon": true, "target_visible": true },
        "effects": { "target_dead": true },
        "cost": 6,
    },
]
```

The cost is what makes plans interesting. Shooting costs 2 but requires ammo. Melee costs 6 but requires no ammo. If the NPC has ammo, it prefers shooting. If not, it plans to find ammo and reload (cost 5+3+2=10) or just melee (cost 6). The planner picks the cheapest valid plan.

---

## 4. The Planner — A* Through Action Space

Here's the key insight: **GOAP planning is A* search, but the graph is action space instead of physical space.**

- **Nodes:** World states
- **Edges:** Actions (applying an action transforms one world state into another)
- **Start:** The goal state (yes, GOAP searches *backwards*)
- **Goal:** The current world state
- **Heuristic:** Number of unsatisfied preconditions

The planner searches backwards from the goal: "To achieve `target_dead = true`, I need the Shoot action. Shoot requires `has_ammo = true`. To achieve that, I need Reload. Reload requires `near_ammo = true`. To achieve that, I need Find Ammo. Find Ammo has no preconditions — plan found!"

```
Backward search from goal:

Goal: { target_dead: true }
    ← Shoot (needs: has_ammo, target_visible, has_weapon)
        ← Reload (needs: near_ammo)
            ← Find Ammo (needs: nothing)
                → Current state satisfies remaining preconditions!

Plan (reversed): Find Ammo → Reload → Shoot
Total cost: 5 + 3 + 2 = 10
```

```lua
-- Lua — GOAP Planner using backward A*
local function goap_plan(current_state, goal_state, available_actions)
    -- A node in the search: { state, action, parent, g_cost }
    local function state_satisfies(state, requirements)
        for key, value in pairs(requirements) do
            if state[key] ~= value then return false end
        end
        return true
    end

    local function copy_state(s)
        local c = {}
        for k, v in pairs(s) do c[k] = v end
        return c
    end

    local function unsatisfied_count(state, current)
        local count = 0
        for key, value in pairs(state) do
            if current[key] ~= value then count = count + 1 end
        end
        return count
    end

    -- Start from the goal, work backwards
    local open = {{
        state = copy_state(goal_state),
        action = nil,
        parent = nil,
        g = 0,
        h = unsatisfied_count(goal_state, current_state),
    }}
    open[1].f = open[1].g + open[1].h

    local iterations = 0
    local max_iterations = 500

    while #open > 0 and iterations < max_iterations do
        iterations = iterations + 1

        -- Find node with lowest f
        table.sort(open, function(a, b) return a.f < b.f end)
        local current = table.remove(open, 1)

        -- Check if current state is satisfied by the actual world state
        if state_satisfies(current_state, current.state) then
            -- Reconstruct plan (reverse the chain)
            local plan = {}
            local node = current
            while node.action do
                table.insert(plan, 1, node.action)
                node = node.parent
            end
            return plan
        end

        -- Try each action that has effects matching unsatisfied conditions
        for _, action in ipairs(available_actions) do
            -- Does this action's effects satisfy any of our current needs?
            local dominated = false -- renamed from useful for clarity
            for key, value in pairs(action.effects) do
                if current.state[key] ~= nil and current.state[key] == value then
                    dominated = true
                    break
                end
            end

            if dominated then
                -- Apply the action backwards: replace effects with preconditions
                local new_state = copy_state(current.state)
                -- Remove the effects this action provides
                for key, value in pairs(action.effects) do
                    if new_state[key] == value then
                        new_state[key] = nil
                    end
                end
                -- Add the preconditions this action requires
                for key, value in pairs(action.preconditions) do
                    new_state[key] = value
                end

                local g = current.g + action.cost
                local h = unsatisfied_count(new_state, current_state)
                table.insert(open, {
                    state = new_state,
                    action = action.name,
                    parent = current,
                    g = g,
                    h = h,
                    f = g + h,
                })
            end
        end
    end

    return nil  -- No plan found
end
```

---

## 5. Plan Execution and Replanning

Once the planner produces a plan, the NPC executes it step by step. Each action in the plan maps to actual game behavior — "find ammo" triggers pathfinding to the nearest ammo crate, "reload" plays a reload animation, "shoot" fires the weapon.

The crucial feature is **replanning**. The world changes — the ammo crate is destroyed, the player moves behind cover, the NPC takes damage. When the current plan becomes invalid (a precondition is no longer satisfiable), the NPC re-plans from its current world state.

```lua
-- Lua — Plan execution with replanning
local current_plan = nil
local plan_step = 1

function update_goap(npc, dt)
    -- Refresh world state from actual game state
    local ws = read_world_state(npc)

    -- Check if current plan is still valid
    if current_plan then
        local action = current_plan[plan_step]
        if not preconditions_met(ws, action) then
            current_plan = nil  -- invalidated, replan
        end
    end

    -- Plan if needed
    if not current_plan then
        local best_goal = get_highest_priority_unsatisfied_goal(ws)
        if best_goal then
            current_plan = goap_plan(ws, best_goal.state, actions)
            plan_step = 1
        end
    end

    -- Execute current step
    if current_plan and plan_step <= #current_plan then
        local action_name = current_plan[plan_step]
        local done = execute_action(npc, action_name, dt)
        if done then
            plan_step = plan_step + 1
        end
    end
end

function read_world_state(npc)
    return {
        has_ammo = npc.ammo > 0,
        target_visible = npc.can_see_player,
        target_dead = not player.alive,
        at_cover = npc.in_cover,
        health_low = npc.health < npc.max_health * 0.3,
        has_weapon = npc.weapon ~= nil,
        near_ammo = npc.nearest_ammo_dist < 30,
    }
end
```

```gdscript
# GDScript — Plan execution
var current_plan: Array[String] = []
var plan_step := 0

func _process(delta: float) -> void:
    var ws = _read_world_state()

    # Validate current plan
    if current_plan.size() > 0 and plan_step < current_plan.size():
        if not _preconditions_met(ws, current_plan[plan_step]):
            current_plan.clear()  # replan

    # Plan if needed
    if current_plan.is_empty():
        var goal = _get_best_goal(ws)
        if goal:
            current_plan = goap_plan(ws, goal.state, actions)
            plan_step = 0

    # Execute
    if plan_step < current_plan.size():
        var done = _execute_action(current_plan[plan_step], delta)
        if done:
            plan_step += 1
```

---

## 6. The F.E.A.R. Case Study

Jeff Orkin's GOAP implementation in F.E.A.R. is the gold standard. Key design decisions worth studying:

**Small world state:** Only ~15 boolean variables. The planner is fast because the state space is small. Don't model everything — model only what matters for decisions.

**Action costs reflect tactical preference:** "Use cover" has lower cost than "charge at player." The planner naturally prefers tactical behavior because it's cheaper. You encode tactical doctrine into costs.

**Sensor system decoupled from planner:** World state is populated by sensors (vision, hearing, damage) that run independently. The planner only reads the world state — it doesn't do any sensing.

**Plans are short:** Typical F.E.A.R. plans are 2-4 actions long. The system replans frequently (whenever the world changes significantly), so plans don't need to be long. Short plans execute quickly and adapt to change.

**Fallback behavior:** If no plan can be found (all goals are impossible), the NPC falls back to a simple FSM — typically "look at threat" or "move to cover." GOAP doesn't replace simple fallback behavior; it augments it.

```
Example F.E.A.R. scenario:

World state: target_visible, has_ammo, not_at_cover, ally_dead
Goal: kill_target

Plan A: Goto_Cover → Shoot (cost: 4+2=6)
Plan B: Shoot (cost: 2) — but NPC is exposed
Plan C: Goto_Cover → Reload → Shoot (if low ammo)

The planner picks the cheapest valid plan.
If a grenade lands, "at_cover" becomes false → replan.
New plan: Move_Away → Goto_New_Cover → Shoot
```

---

## 7. Designing a Good Action Set

The quality of GOAP depends entirely on the action set design. Too few actions and the plans are boring. Too many and the planner is slow. Here are guidelines:

**Keep actions atomic.** "Find ammo crate and move to it and pick up ammo" should be three actions: Find_Ammo, Move_To_Ammo, Pickup_Ammo. This lets the planner combine them flexibly.

**Use procedural preconditions.** Some preconditions can't be evaluated statically. "Is there ammo nearby?" requires a runtime check. Actions can have a `validate` function that runs before planning to determine if the action is currently available.

**Balance costs carefully.** Costs should reflect both the time/resource cost and the tactical desirability. "Use cover" should be cheap to encourage tactical play. "Suicide charge" should be expensive. Adjust costs based on NPC personality — a berserker has low melee costs.

**Test with manual plan tracing.** Before implementing the planner, trace plans by hand. Pick a scenario, write down the world state, and walk through the backward search manually. If the plan doesn't make sense, your actions are wrong.

```
Good action set for a survival NPC:

Action          Preconditions           Effects              Cost
─────────────────────────────────────────────────────────────────
Gather_Wood     {}                      {has_wood: true}      3
Build_Fire      {has_wood: true}        {has_fire: true}      4
Cook_Food       {has_fire: true,        {is_fed: true}        2
                 has_raw_food: true}
Forage          {}                      {has_raw_food: true}  5
Find_Water      {}                      {has_water: true}     4
Drink_Water     {has_water: true}       {is_hydrated: true}   1
Build_Shelter   {has_wood: true}        {has_shelter: true}   8
Sleep           {has_shelter: true}     {is_rested: true}     2

Scenario: NPC is hungry, has nothing.
Goal: { is_fed: true }
Plan: Forage → Gather_Wood → Build_Fire → Cook_Food
Cost: 5 + 3 + 4 + 2 = 14
```

---

## 8. GOAP vs. Other Architectures

| Aspect | FSM | Behavior Tree | Utility AI | GOAP |
|--------|-----|---------------|------------|------|
| **Plans ahead** | No | No | No | Yes — multi-step plans |
| **Handles novel situations** | Poorly | Moderately | Moderately | Well |
| **Design effort** | Low | Medium | Medium | High |
| **Debug complexity** | Low | Low-Medium | Medium | High |
| **Runtime cost** | Minimal | Low | Low | Moderate-High |
| **Best for** | Simple enemies | Complex enemies | Competing needs | Multi-step planning |

**When to use GOAP:**
- Immersive sims where NPCs need to solve problems creatively
- Simulation games where NPCs have complex goal hierarchies
- When you want emergent multi-step behavior without scripting every sequence
- When the same NPC needs to handle many different situations with the same action set

**When NOT to use GOAP:**
- Simple enemies (FSM is faster to implement and debug)
- When you need predictable, designer-controlled behavior (behavior trees)
- When competing needs matter more than multi-step plans (utility AI)
- When you don't have time to build and debug the planner infrastructure

**Hybrid approaches are common.** F.E.A.R. used GOAP for decision-making but FSMs within each action (the "shoot" action had its own sub-states for aiming, firing, and recovering). Many studios use behavior trees as the top-level architecture with GOAP-like planning for specific complex decisions.

---

## Code Walkthrough: A Complete GOAP System

Let's build a complete, runnable GOAP system for a survival NPC that needs to eat, drink, and build shelter.

```lua
-- Lua (LÖVE) — Complete GOAP system

-- GOAP Planner
local function copy_state(s)
    local c = {}; for k,v in pairs(s) do c[k]=v end; return c
end

local function state_satisfies(state, requirements)
    for k, v in pairs(requirements) do
        if state[k] ~= v then return false end
    end
    return true
end

local function plan(world, goal, actions)
    local open = {{
        unmet = copy_state(goal),
        plan = {},
        cost = 0,
    }}

    local iterations = 0
    while #open > 0 and iterations < 300 do
        iterations = iterations + 1
        table.sort(open, function(a,b) return a.cost < b.cost end)
        local current = table.remove(open, 1)

        -- Check if all conditions are met by the world
        if state_satisfies(world, current.unmet) then
            return current.plan
        end

        for _, action in ipairs(actions) do
            -- Does this action provide any unmet condition?
            local dominated = false -- renamed 'provides' for clarity
            for k, v in pairs(action.effects) do
                if current.unmet[k] == v then dominated = true; break end
            end

            if dominated then
                local new_unmet = copy_state(current.unmet)
                -- Remove what the action provides
                for k, v in pairs(action.effects) do
                    if new_unmet[k] == v then new_unmet[k] = nil end
                end
                -- Add what the action requires
                for k, v in pairs(action.preconditions) do
                    new_unmet[k] = v
                end

                local new_plan = {}
                table.insert(new_plan, action.name)
                for _, a in ipairs(current.plan) do
                    table.insert(new_plan, a)
                end

                table.insert(open, {
                    unmet = new_unmet,
                    plan = new_plan,
                    cost = current.cost + action.cost,
                })
            end
        end
    end
    return nil
end

-- Game Setup
local npc = {
    x = 400, y = 300, speed = 60,
    has_wood = false, has_fire = false,
    has_raw_food = false, is_fed = false,
    has_water = false, is_hydrated = false,
    current_plan = nil,
    plan_step = 0,
    action_timer = 0,
}

local actions = {
    { name = "gather_wood",  preconditions = {},
      effects = { has_wood = true }, cost = 3 },
    { name = "build_fire",   preconditions = { has_wood = true },
      effects = { has_fire = true }, cost = 4 },
    { name = "cook_food",    preconditions = { has_fire = true, has_raw_food = true },
      effects = { is_fed = true }, cost = 2 },
    { name = "forage",       preconditions = {},
      effects = { has_raw_food = true }, cost = 5 },
    { name = "find_water",   preconditions = {},
      effects = { has_water = true }, cost = 4 },
    { name = "drink",        preconditions = { has_water = true },
      effects = { is_hydrated = true }, cost = 1 },
}

local goals = {
    { name = "eat", priority = 2, state = { is_fed = true } },
    { name = "drink", priority = 3, state = { is_hydrated = true } },
}

function get_world_state()
    return {
        has_wood = npc.has_wood,
        has_fire = npc.has_fire,
        has_raw_food = npc.has_raw_food,
        is_fed = npc.is_fed,
        has_water = npc.has_water,
        is_hydrated = npc.is_hydrated,
    }
end

function love.update(dt)
    -- Replan if needed
    if not npc.current_plan then
        local ws = get_world_state()
        table.sort(goals, function(a,b) return a.priority > b.priority end)
        for _, goal in ipairs(goals) do
            if not state_satisfies(ws, goal.state) then
                npc.current_plan = plan(ws, goal.state, actions)
                npc.plan_step = 1
                if npc.current_plan then break end
            end
        end
    end

    -- Execute plan step
    if npc.current_plan and npc.plan_step <= #npc.current_plan then
        npc.action_timer = npc.action_timer + dt
        local step_name = npc.current_plan[npc.plan_step]
        local step_duration = 2.0  -- seconds per action

        if npc.action_timer >= step_duration then
            -- Complete the action: apply effects
            for _, action in ipairs(actions) do
                if action.name == step_name then
                    for k, v in pairs(action.effects) do
                        npc[k] = v
                    end
                    break
                end
            end
            npc.action_timer = 0
            npc.plan_step = npc.plan_step + 1

            -- Plan complete?
            if npc.plan_step > #npc.current_plan then
                npc.current_plan = nil
            end
        end
    end
end

function love.draw()
    -- NPC
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", npc.x, npc.y, 15)

    -- Current plan
    love.graphics.setColor(1, 1, 1)
    if npc.current_plan then
        love.graphics.print("Plan:", 10, 10)
        for i, step in ipairs(npc.current_plan) do
            local marker = i == npc.plan_step and ">> " or "   "
            love.graphics.print(marker .. step, 10, 25 + (i-1) * 18)
        end
        if npc.plan_step <= #npc.current_plan then
            local progress = npc.action_timer / 2.0
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", 10, 25 + #npc.current_plan * 18 + 10, 200, 12)
            love.graphics.setColor(0.2, 0.8, 0.4)
            love.graphics.rectangle("fill", 10, 25 + #npc.current_plan * 18 + 10, progress * 200, 12)
        end
    else
        love.graphics.print("All goals satisfied!", 10, 10)
    end

    -- World state
    local ws = get_world_state()
    local y = 200
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("World State:", 10, y)
    y = y + 18
    for k, v in pairs(ws) do
        love.graphics.setColor(v and {0.2, 0.8, 0.2} or {0.8, 0.2, 0.2})
        love.graphics.print(k .. ": " .. tostring(v), 20, y)
        y = y + 16
    end
end
```

---

## Common Pitfalls

### 1. World state too complex

A world state with 50 variables makes the planner slow and hard to debug. Keep it to 10-20 booleans. If you need more complexity, split NPCs into roles with different (smaller) action sets.

### 2. Actions that are too granular or too coarse

"Pick up object with left hand" is too granular — the planner generates unnecessarily long plans. "Win the battle" is too coarse — it doesn't give the planner enough steps to work with. Aim for actions that take 1-5 seconds of game time to execute.

### 3. No fallback for planning failure

If no plan can satisfy any goal, the NPC stands motionless. Always have a fallback behavior (FSM-based idle, wander, or "look around confusedly") for when the planner returns nil.

### 4. Infinite replanning loops

The NPC plans, starts executing, then the world changes and invalidates the plan. It replans, starts executing, then the world changes again. Repeat forever, with the NPC never completing anything. Add a minimum plan execution time or a replan cooldown.

### 5. Not tracing plans by hand first

You implement the planner, define 12 actions, and the NPC produces bizarre plans. Debug by tracing the backward search manually on paper. If you can't trace it, the planner can't either. Paper-first planning is even more important for GOAP than for FSMs.

### 6. Treating GOAP as a silver bullet

GOAP solves a specific problem: multi-step planning in novel situations. It does not solve movement (use steering), detection (use perception systems), or simple priority-based decisions (use behavior trees). GOAP is one tool in the toolbox, not a replacement for the other tools.

---

## Exercises

### Exercise 1: Paper Planning
**Time:** 45-60 minutes

Design a GOAP action set on paper for a medieval RPG guard. Define:
- 5 goals: kill_intruder, stay_healthy, stay_fed, patrol_area, protect_gate
- 10 actions with preconditions, effects, and costs

Then manually trace three scenarios:
1. The guard is healthy, armed, and sees an intruder
2. The guard is wounded and sees an intruder
3. The guard is hungry and no intruder is present

For each, walk through the backward search and write down the resulting plan.

**Concepts practiced:** Action/precondition/effect design, manual plan tracing, cost tuning

**Stretch goal:** Add a "call_reinforcements" action. How does this change the plans?

---

### Exercise 2: Implement the GOAP Planner
**Time:** 2-3 hours

Implement the GOAP planner from the code walkthrough. Verify it with the survival NPC scenario. Then add:

1. A "build_shelter" goal and related actions (requires wood, time)
2. Dynamic world state changes (food spoils after a timer, fire goes out)
3. Replanning when the world changes mid-plan
4. Debug display showing the current plan, current step, and world state

**Concepts practiced:** GOAP planner implementation, backward A* search, replanning

**Stretch goal:** Add action costs that vary based on world state. "Forage" costs more at night. "Travel" costs more in rain. Watch how plans adapt to conditions.

---

### Exercise 3: F.E.A.R.-Style Combat AI
**Time:** 3-4 hours

Build a combat NPC using GOAP with these actions:
- Shoot (needs: ammo, target visible → target damaged)
- Move to cover (→ at cover)
- Find ammo (→ near ammo)
- Reload (needs: near ammo → has ammo)
- Melee (needs: close to target → target damaged)
- Throw grenade (needs: has grenade → area denial)
- Flank (needs: knows target position → better angle)

Goals: kill_target (high priority), stay_alive (highest), get_ammunition (low)

Test scenarios: NPC with full ammo, NPC with no ammo, NPC at low health. Verify the plans make tactical sense.

**Concepts practiced:** Combat GOAP design, tactical cost tuning, the F.E.A.R. pattern

**Stretch goal:** Add plan visualization — draw the plan as a flowchart on screen showing each action's preconditions being satisfied.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| "Three States and a Plan: The AI of F.E.A.R." by Jeff Orkin | Paper (free) | The essential GOAP paper — clearly written by the engineer who built the most famous GOAP implementation |
| "Goal-Oriented Action Planning" from *Game AI Pro* | Book chapter (free) | Updated GOAP treatment with practical implementation guidance and lessons learned |
| Jeff Orkin's AI page at MIT | Papers/talks | Additional papers and talks on the F.E.A.R. AI system and GOAP in general |
| "Applying Goal-Oriented Action Planning to Games" by Jeff Orkin | Paper | Deep dive into the action representation and planner design |
| *Artificial Intelligence for Games* by Millington & Funge, Ch. 5.4 | Book | Formal treatment of planning with comparison to other architectures |

---

## Key Takeaways

1. **GOAP lets NPCs construct their own plans.** Instead of hand-authoring behavior sequences, you define actions with preconditions and effects, and the planner finds the cheapest sequence to achieve a goal. Multi-step emergent behavior with no scripting.

2. **The planner is A* through action space.** Same algorithm from Module 4, but nodes are world states and edges are actions. Backward search from goal to current state. The heuristic is unsatisfied precondition count.

3. **Replanning is essential.** The world changes. Plans become invalid. The NPC must detect invalidation and replan quickly. Short plans (2-4 actions) replan well. Long plans replan poorly.

4. **Cost tuning encodes tactical preference.** Low-cost actions are preferred by the planner. Make tactical behavior cheap and reckless behavior expensive, and NPCs will naturally play smart.

5. **GOAP is high-investment, high-reward.** It requires more design effort and debugging infrastructure than simpler architectures. Use it when you need emergent multi-step plans. Use simpler tools when you don't.

6. **Study F.E.A.R.** Jeff Orkin's papers are the best GOAP resource. The design decisions — small world state, atomic actions, frequent replanning, FSM fallback — are battle-tested guidelines.

---

## What's Next?

You now have the complete decision-making toolkit: FSMs for simple state-based behavior, behavior trees for composable priority-based decisions, utility AI for nuanced scoring, and GOAP for multi-step planning. But all of these assume the NPC already knows what's happening in the world. How does it know the player is there?

In [Module 7: Spatial Awareness & Perception](module-07-spatial-awareness-perception.md), you'll give NPCs senses — vision cones, hearing, memory, and alert states. This is what makes stealth games work and what separates a guard that "magically knows where you are" from one that feels like a real presence in the world.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
