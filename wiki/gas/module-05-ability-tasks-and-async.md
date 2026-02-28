# Module 5: Ability Tasks & Async Patterns

**Part of:** [GAS Learning Roadmap](gas-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 4: Gameplay Abilities](module-04-gameplay-abilities.md)

---

## Overview

Up to now, abilities have been instantaneous — activate, apply effect, done. One frame. But many interesting abilities take time. A charged shot that grows stronger the longer you hold the button. A channeled heal that ticks every half-second and cancels if you move. A three-hit combo where each attack chains from the previous one with timing windows. These are **multi-frame abilities**, and they're a significant complexity jump from everything you've built so far.

The core challenge: how do you write ability logic that spans multiple frames without blocking the game loop? You can't just `sleep(2)` — the game has to keep running. You need something that says "wait for X, then continue doing Y" while the rest of the game ticks normally.

In Unreal's GAS, this is solved with **Ability Tasks** — asynchronous sub-objects that run inside an active ability, waiting for events, timers, or input. You don't need Unreal's implementation, but you need the concept. This module covers two practical approaches: **coroutines** (natural in Lua and GDScript) and **state machines** (universal, more explicit). Both solve the same problem — they just trade readability for explicitness.

By the end of this module you'll be able to build channeled abilities, charge-up abilities, and combo sequences that properly handle interruption and cancellation.

---

## 1. The Problem With Multi-Frame Abilities

Consider a "Charging Laser" ability:
1. Player holds the button → charge begins
2. Charge increases over 3 seconds, visual indicator grows
3. Player releases → laser fires, damage scales with charge time
4. If stunned during charge → ability cancels, no damage

In a single-frame ability, all of this would happen in one function call. But charging takes time. The ability needs to persist across frames, tracking state (current charge time), responding to events (button release, stun), and eventually completing (firing the laser).

With your current system, you'd need something like this:

```
// Naive approach — polluting update() with ability state
function update(dt):
    if charging_laser:
        charge_time += dt
        if charge_time >= max_charge:
            fire_laser(charge_time)
            charging_laser = false
        if input_released("fire"):
            fire_laser(charge_time)
            charging_laser = false
        if entity:has_tag("State.Stunned"):
            charging_laser = false    // cancel
```

This works for one ability. Add ten multi-frame abilities and your `update()` is a tangled mess of state flags and conditionals. Each ability's logic is scattered across the update loop, mixed with every other ability's logic. You can't reason about one ability in isolation.

**Ability tasks** solve this by encapsulating each ability's async logic into a self-contained unit that runs alongside the game loop without scattering its state across global update functions.

---

## 2. Coroutines: Sequential Logic Across Frames

**Coroutines** are the most natural solution in languages that support them — and both Lua and GDScript do. A coroutine is a function that can pause (yield) and resume later. The ability's logic reads like sequential code, but it executes across many frames.

Here's the charging laser as a coroutine:

```
// The ability reads like a recipe — step by step
function charging_laser_ability(asc, ability):
    charge_time = 0

    // Charge phase: wait for release or max charge
    while charge_time < 3.0:
        yield()                              // pause until next frame
        charge_time += dt
        if input_released("fire"):
            break
        if asc:has_tag("State.Stunned"):
            cancel_ability(asc, ability)
            return                           // clean exit

    // Fire phase
    damage = 20 + (charge_time * 30)         // 20 base + 30 per second charged
    apply_effect(target, make_damage(damage), {source = asc})
    end_ability(asc, ability)
```

This is the same logic as the scattered `update()` version, but it's self-contained. The coroutine pauses at `yield()`, the game loop continues, and next frame the coroutine resumes right where it left off. No state flags, no conditionals in update — the ability's control flow *is* its state.

### How the Ability System Drives Coroutines

The ability system needs a way to create and resume coroutines each frame:

**Pseudocode:**
```
AbilityTaskRunner:
    active_tasks: list of {coroutine, owner_asc, ability}

    function start_task(asc, ability, task_function):
        co = create_coroutine(task_function, asc, ability)
        active_tasks.add({coroutine = co, owner = asc, ability = ability})

    function update(dt):
        for each task in active_tasks:
            if coroutine_is_alive(task.coroutine):
                resume_coroutine(task.coroutine, dt)
            else:
                active_tasks.remove(task)
```

Each frame, the runner resumes all active ability coroutines, passing the delta time. Coroutines that have finished (returned) are cleaned up.

**Lua:**
```lua
local AbilityTaskRunner = {}
AbilityTaskRunner.__index = AbilityTaskRunner

function AbilityTaskRunner.new()
    return setmetatable({
        active_tasks = {},
    }, AbilityTaskRunner)
end

function AbilityTaskRunner:start_task(asc, ability, task_fn)
    local co = coroutine.create(function()
        task_fn(asc, ability)
    end)
    table.insert(self.active_tasks, {
        coroutine = co,
        owner = asc,
        ability = ability,
    })
    -- Resume immediately to run until the first yield
    coroutine.resume(co)
end

function AbilityTaskRunner:update(dt)
    local i = 1
    while i <= #self.active_tasks do
        local task = self.active_tasks[i]
        if coroutine.status(task.coroutine) == "suspended" then
            local ok, err = coroutine.resume(task.coroutine, dt)
            if not ok then
                print("Ability task error: " .. tostring(err))
                table.remove(self.active_tasks, i)
            else
                i = i + 1
            end
        elseif coroutine.status(task.coroutine) == "dead" then
            table.remove(self.active_tasks, i)
        else
            i = i + 1
        end
    end
end

function AbilityTaskRunner:cancel_tasks_for(asc)
    local i = 1
    while i <= #self.active_tasks do
        if self.active_tasks[i].owner == asc then
            table.remove(self.active_tasks, i)
        else
            i = i + 1
        end
    end
end
```

**GDScript:**
```gdscript
class_name AbilityTaskRunner

var active_tasks: Array[Dictionary] = []

func start_task(asc: AbilitySystemComponent, ability: AbilityDefinition, task_callable: Callable) -> void:
    # GDScript uses await with signals or timers for coroutine-like behavior
    # We track the task so we can cancel it
    var task := {asc = asc, ability = ability, running = true}
    active_tasks.append(task)
    # Start the async function
    task_callable.call(asc, ability, task)

func cancel_tasks_for(asc: AbilitySystemComponent) -> void:
    for task in active_tasks:
        if task.asc == asc:
            task.running = false
    active_tasks = active_tasks.filter(func(t): return t.running)
```

### Writing Abilities With Coroutines

Once the runner is in place, writing multi-frame abilities becomes straightforward. Each ability is a function that yields when it needs to wait:

**Lua:**
```lua
-- Helper: yield for N seconds
local function wait_seconds(seconds)
    local elapsed = 0
    while elapsed < seconds do
        local dt = coroutine.yield()    -- yields, gets dt when resumed
        elapsed = elapsed + dt
    end
end

-- Helper: yield until a condition is true
local function wait_until(condition_fn)
    while not condition_fn() do
        coroutine.yield()
    end
end

-- Helper: yield until a condition is true OR timeout
local function wait_until_or_timeout(condition_fn, timeout)
    local elapsed = 0
    while elapsed < timeout do
        if condition_fn() then return true end
        local dt = coroutine.yield()
        elapsed = elapsed + dt
    end
    return false    -- timed out
end
```

**GDScript:**
```gdscript
# GDScript uses await with timers and signals natively

# Wait for N seconds
func wait_seconds(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout

# Wait until condition (check each frame)
func wait_until(condition: Callable) -> void:
    while not condition.call():
        await get_tree().process_frame
```

These helpers are your building blocks. With them, ability logic reads naturally:

**Lua:**
```lua
local function charging_laser(asc, ability)
    local charge_time = 0
    local max_charge = 3.0

    -- Grant a tag so the UI can show the charging indicator
    asc.tags:add("State.Charging")

    -- Charge phase
    while charge_time < max_charge do
        local dt = coroutine.yield()
        charge_time = charge_time + dt

        -- Check for interruption
        if asc.tags:has("State.Stunned") then
            asc.tags:remove("State.Charging")
            return    -- ability cancelled, coroutine ends
        end

        -- Check for release
        if not love.keyboard.isDown("space") then
            break    -- player released, proceed to fire
        end
    end

    -- Fire
    local damage = 20 + math.floor(charge_time * 30)
    local damage_effect = make_instant_effect("health", "add", -damage)
    local target = asc.current_target
    if target then
        apply_effect(target, damage_effect, {source = asc})
    end

    asc.tags:remove("State.Charging")
end
```

---

## 3. State Machines: Explicit Phase Management

**State machines** are the alternative to coroutines. Instead of implicit control flow (yield/resume), you explicitly define states and transitions. Each state has enter, update, and exit callbacks.

For the charging laser:

```
ChargingLaserStateMachine:
    states:
        charging:
            enter: set charge_time = 0, grant State.Charging tag
            update(dt):
                charge_time += dt
                if stunned → transition to "cancelled"
                if released → transition to "firing"
                if charge_time >= max → transition to "firing"
            exit: (nothing)

        firing:
            enter: calculate damage, apply effect, emit cue
            update: (instant transition)
            exit: (nothing)
            → transition to "done"

        cancelled:
            enter: remove State.Charging tag
            update: (instant transition)
            exit: (nothing)
            → transition to "done"

        done:
            enter: end_ability()
```

**Pseudocode:**
```
AbilityStateMachine:
    current_state: string
    states: map<string, {enter, update, exit}>
    data: map                    // shared state across phases

    function transition(new_state):
        if current_state:
            states[current_state].exit(data)
        current_state = new_state
        states[current_state].enter(data)

    function update(dt):
        result = states[current_state].update(data, dt)
        if result is string:        // returned a state name
            transition(result)
```

**Lua:**
```lua
local AbilityStateMachine = {}
AbilityStateMachine.__index = AbilityStateMachine

function AbilityStateMachine.new(states, initial_state)
    local sm = setmetatable({
        states = states,
        current_state = nil,
        data = {},
    }, AbilityStateMachine)
    sm:transition(initial_state)
    return sm
end

function AbilityStateMachine:transition(new_state)
    if self.current_state and self.states[self.current_state].exit then
        self.states[self.current_state].exit(self.data)
    end
    self.current_state = new_state
    if self.states[new_state].enter then
        self.states[new_state].enter(self.data)
    end
end

function AbilityStateMachine:update(dt)
    local state = self.states[self.current_state]
    if state.update then
        local next_state = state.update(self.data, dt)
        if next_state then
            self:transition(next_state)
        end
    end
end

function AbilityStateMachine:is_done()
    return self.current_state == "done"
end
```

**GDScript:**
```gdscript
class_name AbilityStateMachine

var states: Dictionary = {}
var current_state: String = ""
var data: Dictionary = {}

func _init(p_states: Dictionary, initial_state: String) -> void:
    states = p_states
    transition(initial_state)

func transition(new_state: String) -> void:
    if current_state and states.has(current_state) and states[current_state].has("exit"):
        states[current_state].exit.call(data)
    current_state = new_state
    if states[new_state].has("enter"):
        states[new_state].enter.call(data)

func update(dt: float) -> void:
    if states.has(current_state) and states[current_state].has("update"):
        var next_state = states[current_state].update.call(data, dt)
        if next_state:
            transition(next_state)

func is_done() -> bool:
    return current_state == "done"
```

### Coroutines vs. State Machines

| | Coroutines | State Machines |
|---|---|---|
| **Readability** | Sequential — reads like a script | Explicit states — reads like a flowchart |
| **Debugging** | Harder to inspect mid-execution | Easy — check current_state and data |
| **Complexity** | Better for simple sequences | Better for complex branching |
| **Language support** | Lua (native), GDScript (await) | Any language |
| **Cancellation** | Stop resuming the coroutine | Transition to "cancelled" state |
| **Serialization** | Hard (can't save coroutine state) | Easy (save current_state + data) |

**Practical recommendation:** Use coroutines for simple timed sequences (channel for X seconds, charge and release). Use state machines for abilities with complex branching (combo trees, abilities with multiple decision points). Many production systems use both — coroutines for the common case, state machines for the complex case.

---

## 4. Channeled Abilities

A channeled ability continuously applies effects while a condition holds — the button is held, the caster isn't interrupted, and the channel hasn't timed out.

**Design:** A channeled heal ticks 10 HP every 0.5 seconds for up to 5 seconds. Moving or getting stunned interrupts the channel.

**Coroutine version (Lua):**
```lua
local function channeled_heal(asc, ability)
    local tick_interval = 0.5
    local max_duration = 5.0
    local heal_per_tick = 10
    local elapsed = 0
    local tick_timer = 0

    -- Pay cost upfront (already handled by commit_cost)
    asc.tags:add("State.Channeling")

    while elapsed < max_duration do
        local dt = coroutine.yield()
        elapsed = elapsed + dt
        tick_timer = tick_timer + dt

        -- Check interruption conditions
        if asc.tags:has("State.Stunned") or asc.tags:has("State.Silenced") then
            break    -- interrupted
        end

        -- Check if the player stopped channeling (released key)
        if not love.keyboard.isDown("e") then
            break    -- voluntary cancel
        end

        -- Tick heal
        if tick_timer >= tick_interval then
            tick_timer = tick_timer - tick_interval
            local heal_effect = make_instant_effect("health", "add", heal_per_tick)
            apply_effect(asc, heal_effect, {source = asc})
        end
    end

    asc.tags:remove("State.Channeling")
    end_ability(asc, ability)
end
```

**State machine version (Lua):**
```lua
local function make_channeled_heal_sm(asc, ability)
    return AbilityStateMachine.new({
        channeling = {
            enter = function(data)
                data.elapsed = 0
                data.tick_timer = 0
                data.tick_interval = 0.5
                data.max_duration = 5.0
                data.heal_per_tick = 10
                asc.tags:add("State.Channeling")
            end,
            update = function(data, dt)
                data.elapsed = data.elapsed + dt
                data.tick_timer = data.tick_timer + dt

                if asc.tags:has("State.Stunned") or asc.tags:has("State.Silenced") then
                    return "interrupted"
                end
                if not love.keyboard.isDown("e") then
                    return "finished"
                end
                if data.elapsed >= data.max_duration then
                    return "finished"
                end

                if data.tick_timer >= data.tick_interval then
                    data.tick_timer = data.tick_timer - data.tick_interval
                    local heal = make_instant_effect("health", "add", data.heal_per_tick)
                    apply_effect(asc, heal, {source = asc})
                end
            end,
            exit = function(data)
                asc.tags:remove("State.Channeling")
            end,
        },
        interrupted = {
            enter = function(data)
                -- Could emit a cue: GameplayCue.Ability.Interrupted
            end,
            update = function() return "done" end,
        },
        finished = {
            enter = function(data) end,
            update = function() return "done" end,
        },
        done = {
            enter = function(data)
                end_ability(asc, ability)
            end,
        },
    }, "channeling")
end
```

**Key design decisions for channels:**

**Cost timing.** Is the full cost paid upfront, or does the channel cost resources per tick? Upfront is simpler. Per-tick means the channel can end early if the caster runs out of mana — check cost each tick and break if insufficient.

**Partial benefit.** Does a cancelled channel give partial healing? In the coroutine version, yes — each tick applies independently. The player gets however many ticks completed before interruption. This is usually the desired behavior.

**Movement interruption.** Many channels break on movement. Track the caster's position on channel start; if it changes beyond a threshold, interrupt. Or grant a `State.Rooted` tag during channeling and let the movement system enforce it.

---

## 5. Charge-Up Abilities

Hold to charge, release to fire. Damage (or other magnitude) scales with charge time.

**Lua (coroutine):**
```lua
local function charged_shot(asc, ability)
    local max_charge = 3.0
    local min_damage = 10
    local max_damage = 100
    local charge_time = 0

    asc.tags:add("State.Charging")

    -- Charge phase: accumulate time while button held
    while charge_time < max_charge do
        local dt = coroutine.yield()
        charge_time = charge_time + dt

        -- Interruption check
        if asc.tags:has("State.Stunned") then
            asc.tags:remove("State.Charging")
            return    -- cancelled, no shot
        end

        -- Release check
        if not love.mouse.isDown(1) then
            break
        end
    end

    -- Calculate damage based on charge
    local charge_ratio = math.min(charge_time / max_charge, 1.0)
    local damage = min_damage + (max_damage - min_damage) * charge_ratio

    -- Fire
    local target = get_target_at_cursor()
    if target then
        local damage_effect = make_instant_effect("health", "add", -damage)
        apply_effect(target, damage_effect, {source = asc, charge = charge_ratio})
    end

    asc.tags:remove("State.Charging")
    end_ability(asc, ability)
end
```

**GDScript:**
```gdscript
func charged_shot(asc: AbilitySystemComponent, ability: AbilityDefinition, task: Dictionary) -> void:
    var max_charge := 3.0
    var min_damage := 10.0
    var max_damage := 100.0
    var charge_time := 0.0

    asc.tags.add("State.Charging")

    # Charge phase
    while charge_time < max_charge and task.running:
        await get_tree().process_frame
        charge_time += get_process_delta_time()

        if asc.tags.has("State.Stunned"):
            asc.tags.remove("State.Charging")
            return

        if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            break

    # Calculate and fire
    var charge_ratio := minf(charge_time / max_charge, 1.0)
    var damage := min_damage + (max_damage - min_damage) * charge_ratio

    var target := get_target_at_cursor()
    if target:
        var damage_effect := make_instant_effect("health", "add", -damage)
        apply_effect(target, damage_effect, {source = asc, charge = charge_ratio})

    asc.tags.remove("State.Charging")
    end_ability(asc, ability)
```

**Charge tiers** are a common design pattern. Instead of linear scaling, charge has distinct levels:

```
Charge tiers:
  0.0 - 0.5s: Level 0 (weak shot, 10 damage)
  0.5 - 1.5s: Level 1 (normal shot, 40 damage)
  1.5 - 3.0s: Level 2 (power shot, 80 damage)
  3.0s (max):  Level 3 (mega shot, 120 damage, AoE)
```

Visual feedback should indicate the current tier — the cue system from Module 6 handles this. Emit different cues at tier transitions: `GameplayCue.Charge.Level1`, `GameplayCue.Charge.Level2`, etc.

---

## 6. Combo Sequences

Combos chain multiple actions with timing windows. Press attack → attack → attack for a three-hit combo. Miss the timing window and the combo resets.

The key data structures:

```
ComboDefinition:
    steps: [
        {ability: "Slash1", window: 0.6},    // 0.6s to input next
        {ability: "Slash2", window: 0.5},    // 0.5s to input next
        {ability: "Slash3", window: 0},      // final hit, no follow-up
    ]
```

**Lua (coroutine):**
```lua
local function combo_sequence(asc, combo_def)
    for i, step in ipairs(combo_def.steps) do
        -- Execute this combo step
        local ability = get_ability(step.ability)
        activate(asc, ability, asc.current_target)

        -- Wait for the step's animation/execution time
        wait_seconds(step.execute_time or 0.3)

        -- If this isn't the last step, wait for input within the window
        if i < #combo_def.steps then
            local next_input = false
            local window_timer = 0

            while window_timer < step.window do
                local dt = coroutine.yield()
                window_timer = window_timer + dt

                -- Check for interruption
                if asc.tags:has("State.Stunned") then
                    return    -- combo broken
                end

                -- Check for next attack input
                if input_pressed("attack") then
                    next_input = true
                    break
                end
            end

            if not next_input then
                break    -- window expired, combo ends here
            end
        end
    end

    end_ability(asc, nil)
end
```

**GDScript:**
```gdscript
func combo_sequence(asc: AbilitySystemComponent, combo_def: Dictionary, task: Dictionary) -> void:
    for i in range(combo_def.steps.size()):
        var step: Dictionary = combo_def.steps[i]

        # Execute this step
        var ability := get_ability(step.ability)
        activate(asc, ability, asc.current_target)

        # Wait for execution
        await get_tree().create_timer(step.get("execute_time", 0.3)).timeout

        # If not the last step, wait for input
        if i < combo_def.steps.size() - 1:
            var got_input := false
            var window_timer := 0.0

            while window_timer < step.window and task.running:
                await get_tree().process_frame
                window_timer += get_process_delta_time()

                if asc.tags.has("State.Stunned"):
                    return

                if Input.is_action_just_pressed("attack"):
                    got_input = true
                    break

            if not got_input:
                break    # combo dropped

    end_ability(asc, null)
```

### Input Buffering

Raw input checking (did the player press the button *this exact frame*?) feels bad. Players press the button slightly before the window opens, and the input is lost. **Input buffering** fixes this:

```
InputBuffer:
    buffer: list of {action, timestamp}
    buffer_duration: 0.15    // 150ms buffer

    function record_input(action):
        buffer.add({action = action, time = current_time()})

    function consume_buffered(action):
        cutoff = current_time() - buffer_duration
        for each entry in buffer (newest first):
            if entry.action == action and entry.time >= cutoff:
                buffer.remove(entry)
                return true
        return false
```

With buffering, the combo check becomes `if input_buffer:consume_buffered("attack")` instead of `if input_pressed("attack")`. The player can press slightly early and the input is still caught.

---

## 7. Cancellation and Interruption

Every multi-frame ability needs a clean cancellation path. This is the "unhappy path" — what happens when things go wrong mid-ability?

**Sources of cancellation:**
- **Stun/CC:** A crowd control effect interrupts the ability
- **Death:** The caster dies
- **Player input:** The player cancels deliberately (pressing escape, starting a different ability)
- **Range:** The target moves out of range during a channel
- **Cost:** For per-tick channels, running out of resources

**The cancellation contract:** When an ability is cancelled, it must:
1. Remove any tags it granted (e.g., `State.Channeling`, `State.Charging`)
2. Stop any ongoing effects it was managing (periodic ticks)
3. Not apply its completion effects (the laser shouldn't fire if cancelled mid-charge)
4. Return the ability to idle so it can be activated again later

**Pseudocode:**
```
function cancel_ability(asc, ability):
    // Remove ability-specific tags
    for each tag in ability.active_tags:
        asc.tags:remove(tag)

    // Stop the ability's coroutine or state machine
    task_runner:cancel_tasks_for(asc)

    // The cooldown still applies (most games charge cooldown even on cancel)
    // Some games give a reduced cooldown on cancel — implement as a design choice
```

**Coroutine approach:** Cancellation means simply stopping the coroutine. Since the coroutine runs to completion or stops being resumed, cleanup happens in two ways:

1. **Explicit checks within the coroutine** — the coroutine checks for stun/death each frame and returns early if found, cleaning up first.
2. **External cancellation** — the task runner removes the coroutine, but any cleanup the coroutine would have done on exit doesn't run. You need a separate cleanup path.

Pattern for clean coroutine cancellation:

**Lua:**
```lua
local function ability_with_cleanup(asc, ability)
    -- Track what we need to clean up
    local cleanup = function()
        asc.tags:remove("State.Channeling")
        -- Remove any other temporary state
    end

    asc.tags:add("State.Channeling")

    local success, err = pcall(function()
        -- Ability logic here
        while true do
            local dt = coroutine.yield()
            if asc.tags:has("State.Stunned") then
                error("interrupted")    -- jump to cleanup
            end
            -- ... ability logic ...
        end
    end)

    -- Cleanup always runs, whether the ability completed or was interrupted
    cleanup()
end
```

A simpler pattern: use a wrapper that guarantees cleanup:

```lua
function with_cleanup(cleanup_fn, ability_fn)
    return function(asc, ability)
        local ok, err = pcall(ability_fn, asc, ability)
        cleanup_fn(asc, ability)
        if not ok and err ~= "cancelled" then
            print("Ability error: " .. tostring(err))
        end
    end
end
```

**State machine approach:** Cancellation transitions to a "cancelled" or "cleanup" state. Since state transitions call `exit` on the current state and `enter` on the new state, cleanup is built into the structure. This is one of the state machine's advantages — the cleanup path is explicit.

---

## 8. Ability Exclusivity

Most games prevent multiple abilities from being active simultaneously on the same entity. A mage can't channel a heal and charge a fireball at the same time.

**Simple approach: one active ability at a time.**

```
function try_activate_ability(asc, ability, target):
    if asc.active_ability is not nil:
        // An ability is already running
        if ability.can_interrupt_active:
            cancel_ability(asc, asc.active_ability)
        else:
            return false    // can't activate while another is running
    // ... proceed with activation
```

**Tag-based approach:** Active abilities grant a tag like `State.Casting` or `Ability.Active.Fireball`. Other abilities block on `State.Casting`. This uses the existing tag system — no special exclusivity code.

**Priority-based approach:** Some abilities should be able to interrupt lower-priority ones. An interrupt ability should cancel a channel. A dodge should cancel a charge-up. Assign priorities:

```
Ability priorities:
  Normal abilities: priority 1
  Movement abilities (dodge, dash): priority 2
  Interrupt/counter abilities: priority 3
```

When activating an ability, if another is active, only interrupt if the new ability's priority is higher:

```
function try_activate_ability(asc, ability, target):
    if asc.active_ability:
        if ability.priority > asc.active_ability.priority:
            cancel_ability(asc, asc.active_ability)
        else:
            return false
    // ... proceed
```

**Queueing:** Some games queue the next ability. If you press Fireball while a current ability is finishing, it starts as soon as the current one ends. This is input buffering applied to abilities:

```
function queue_ability(asc, ability_name, target):
    asc.queued_ability = {name = ability_name, target = target}

// In the ability end callback:
function end_ability(asc, ability):
    asc.active_ability = nil
    if asc.queued_ability:
        try_activate_ability(asc, asc.queued_ability.name, asc.queued_ability.target)
        asc.queued_ability = nil
```

---

## 9. Integrating Tasks With the ASC

The ability task system needs to connect to the ASC from Module 4. Here's how they fit together:

**Pseudocode:**
```
AbilitySystemComponent:
    // ... existing fields from Module 4 ...
    task_runner: AbilityTaskRunner
    active_ability: AbilityInstance or nil

    function activate_ability(ability_name, target):
        ability = granted_abilities[ability_name]
        if not ability: return false
        if not can_activate(self, ability): return false

        // Handle exclusivity
        if active_ability:
            return false    // or interrupt based on priority

        commit_cost(self, ability)
        apply_cooldown(self, ability)

        if ability.is_async:
            // Multi-frame ability: start a task
            active_ability = {ability = ability, target = target}
            task_runner:start_task(self, ability, ability.task_function)
        else:
            // Instant ability: execute immediately
            activate(self, ability, target)
            end_ability(self, ability)

    function update(dt):
        // Tick effects (Module 3)
        update_effects(self, dt)

        // Tick active ability tasks
        task_runner:update(dt)

        // Check if active task has completed
        if active_ability and not task_runner:has_tasks_for(self):
            active_ability = nil
```

The ASC decides whether an ability is instant or async based on the ability definition. Instant abilities run the same one-frame pipeline from Module 4. Async abilities start a task (coroutine or state machine) and mark themselves as active until the task completes.

---

## 10. Common Async Patterns Reference

A quick reference for the most common multi-frame ability patterns:

### Delayed Ability
Apply effects after a wind-up delay.
```
function delayed_strike(asc, ability):
    asc.tags:add("State.Casting")
    wait_seconds(0.8)                    // wind-up
    if not asc.tags:has("State.Stunned"):
        apply_effects(asc, ability)      // strike lands
    asc.tags:remove("State.Casting")
```

### Channeled With Tick
Continuously apply effects on a timer.
```
function drain_life(asc, ability):
    asc.tags:add("State.Channeling")
    elapsed = 0
    while elapsed < 6.0 and not interrupted(asc):
        wait_seconds(0.5)
        apply_damage_to_target(-8)
        apply_heal_to_self(+5)
        elapsed += 0.5
    asc.tags:remove("State.Channeling")
```

### Charge and Release
Scale effect with hold time.
```
function charge_and_release(asc, ability):
    charge = wait_for_release(max_time = 2.0)
    damage = lerp(10, 100, charge / 2.0)
    apply_damage(target, damage)
```

### Multi-Phase
Distinct phases with different behavior.
```
function meteor(asc, ability):
    // Phase 1: Target selection (mark ground)
    target_pos = get_aimed_position()
    spawn_indicator(target_pos)

    // Phase 2: Delay (meteor is falling)
    wait_seconds(1.5)

    // Phase 3: Impact
    targets = get_entities_in_radius(target_pos, 5.0)
    for each target in targets:
        apply_damage(target, 80)
    spawn_explosion_cue(target_pos)
```

### Combo With Branching
Different follow-ups based on input.
```
function branching_combo(asc, ability):
    // First hit
    activate_slash_1(asc)
    wait_seconds(0.3)

    // Branch: heavy or light?
    input = wait_for_input({"light_attack", "heavy_attack"}, timeout = 0.6)
    if input == "light_attack":
        activate_slash_2_light(asc)
    elif input == "heavy_attack":
        activate_slash_2_heavy(asc)
    else:
        return    // no input, combo ends
```

---

## Exercise

Build a coroutine-based (or state-machine-based) ability task system. Integrate it with your ASC from Module 4. Create three multi-frame abilities:

1. **Charged Shot** — Hold to charge for up to 3 seconds. Release to fire. Damage scales linearly from 10 (instant release) to 100 (full charge). Getting stunned during charge cancels the ability without firing. Grant `State.Charging` while charging. Verify charge time affects damage correctly.

2. **Healing Channel** — Channel for up to 5 seconds, healing 10 HP per 0.5-second tick. Interrupted by stun or silence. Grant `State.Channeling` while active. Verify partial healing works (interrupt after 3 ticks = 30 HP healed). Verify the channel costs mana upfront, not per-tick.

3. **Three-Hit Combo** — Three attacks in sequence: Slash1 (15 damage), Slash2 (20 damage), Slash3 (35 damage). Each step has a 0.6-second input window to continue. Missing the window ends the combo at whatever step was reached. Getting stunned breaks the combo. Verify that partial combos work (two hits = 35 total damage, three hits = 70 total).

**Test scenarios:**
1. Charged Shot: hold for 1.5s, release → damage should be ~55. Hold for 0s (instant) → damage should be 10. Get stunned at 1.0s → no damage.
2. Healing Channel: channel full duration → 100 HP healed (10 ticks). Get stunned after 1.5s → 30 HP healed (3 ticks). Channel on full health → healing is clamped to max.
3. Combo: complete all 3 hits → 70 total damage. Complete 2 hits, miss window → 35 total damage. Get stunned after hit 1 → only 15 damage.
4. Exclusivity: verify you can't start a new ability while another is active.

**Stretch goals:**
- Implement input buffering (150ms buffer) for the combo and verify it feels better.
- Implement ability priority: a "Dodge Roll" (priority 2) can interrupt a channel (priority 1).
- Add a delayed ability: "Meteor" with 1.5s cast time → AoE damage. Interruptible during cast.
- Implement a branching combo: light attack → choose heavy or light for the second hit, with different effects per branch.

---

## Read

- GASDocumentation — Ability Tasks: https://github.com/tranek/GASDocumentation#concepts-at — how Unreal handles async ability sub-tasks. Focus on the concept (wait-for-event patterns), not the C++ API.
- Lua Coroutine Tutorial (Programming in Lua): https://www.lua.org/pil/9.1.html — the definitive guide to Lua coroutines. Essential for Love2D implementations.
- GDScript `await` documentation: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#awaiting-for-signals-or-coroutines — Godot's native async pattern.
- "Coroutines for Game Logic" blog posts — search for game-specific coroutine patterns. Unity's coroutines (conceptually identical) have extensive community documentation that applies to any engine.
- "Implementing Combo Systems" — search for fighting game or action game combo architecture. The timing-window pattern recurs across genres from Devil May Cry to Hades.
- Game Programming Patterns — State: https://gameprogrammingpatterns.com/state.html — state machines for game objects. Directly applicable to multi-phase abilities.

---

## Summary

Multi-frame abilities are where the ability system meets real-time gameplay. The two primary tools are **coroutines** (sequential logic that yields across frames) and **state machines** (explicit states with transitions). Both solve the same problem — encapsulating async ability logic without scattering state across the game loop.

Channeled abilities tick effects on a timer. Charge-up abilities scale magnitude with hold time. Combos chain actions with timing windows. All three patterns share the same fundamentals: wait for conditions, check for interruption, apply effects at the right moment.

Cancellation is the most important design consideration. Every async ability must have a clean exit path — remove temporary tags, stop ongoing effects, return to idle. Build cancellation handling before you build the happy path.

**Next up:** [Module 6: Gameplay Cues & Feedback](module-06-gameplay-cues-and-feedback.md) — decoupling visual and audio feedback from gameplay logic using event-driven cues.
