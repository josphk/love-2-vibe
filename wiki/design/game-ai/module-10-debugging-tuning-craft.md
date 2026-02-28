# Module 10: Debugging, Tuning & The Craft

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 4-6 hours
**Prerequisites:** All prior modules

---

## Overview

This is the capstone module, and it's about something that can't be captured in an algorithm: the *craft* of game AI. You now know FSMs, behavior trees, steering behaviors, pathfinding, utility scoring, GOAP, perception systems, group coordination, and boss patterns. The question is no longer "how do I make the NPC do X?" but "how do I make the NPC *feel right*?"

The difference between functional AI and great AI lives in two places: **debug visualization** (can you see what the AI is thinking?) and **tuning** (does the behavior feel good to play against?). Both are iterative processes that can't be skipped or shortcut. The best AI programmers in the industry all say the same thing: invest in debug tools first, then tune by feel, and be willing to make the AI "worse" in service of fun.

This module collects the meta-skills that make everything else work — the practices that turn your technical knowledge into shipped games with AI that players remember.

---

## 1. Debug Visualization — Your Most Important Tool

If you can't see what the AI is thinking, you can't tune it. This is not metaphorical. You will spend more time with debug overlays on than off during AI development. Every AI system you build should have a visual debug mode from day one — not as polish, but as infrastructure.

**What to visualize:**

| System | Visualization | Why |
|--------|--------------|-----|
| **FSM/BT state** | Text label above NPC ("PATROL", "CHASE") | Instantly see what state every NPC is in |
| **Vision cone** | Semi-transparent arc | See exactly what the NPC can see |
| **Hearing range** | Circle outline | See the detection boundary |
| **Pathfinding route** | Line or dots from NPC to destination | Verify the path makes sense |
| **Steering forces** | Colored arrows from NPC | See what forces are acting and their relative strength |
| **Utility scores** | Bar chart near NPC or on HUD | Understand why the NPC chose its current action |
| **Memory** | Line to last known position (fading) | See what the NPC "remembers" |
| **Influence map** | Heat overlay on the level | See danger zones, cover values, tactical scores |
| **Attack telegraphs** | Range circles, timing indicators | Verify telegraphs are visible and timed correctly |
| **Alert level** | Color-coded NPC body | Instantly read awareness state |

```lua
-- Lua — Debug overlay system
local debug_enabled = true
local debug_layers = {
    states = true,
    vision = true,
    paths = true,
    steering = true,
    utility = false,  -- toggle with keys
    influence = false,
}

function draw_debug(npcs, player, influence_map, walls)
    if not debug_enabled then return end

    for _, npc in ipairs(npcs) do
        -- State label
        if debug_layers.states then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(npc.state or "?", npc.x - 20, npc.y - 25)
        end

        -- Vision cone
        if debug_layers.vision then
            local alpha = npc.can_see_player and 0.3 or 0.1
            love.graphics.setColor(0.2, 0.8, 0.2, alpha)
            local half_fov = math.rad(npc.fov / 2)
            love.graphics.arc("fill", npc.x, npc.y, npc.view_dist,
                npc.facing - half_fov, npc.facing + half_fov)
        end

        -- Pathfinding route
        if debug_layers.paths and npc.path then
            love.graphics.setColor(0.2, 0.5, 1, 0.6)
            for i = 1, #npc.path - 1 do
                love.graphics.line(
                    npc.path[i][1], npc.path[i][2],
                    npc.path[i+1][1], npc.path[i+1][2])
            end
        end

        -- Steering force vectors
        if debug_layers.steering then
            if npc.debug_forces then
                for _, force in ipairs(npc.debug_forces) do
                    love.graphics.setColor(force.color)
                    love.graphics.line(npc.x, npc.y,
                        npc.x + force.x * 0.5, npc.y + force.y * 0.5)
                end
            end
        end

        -- Memory line
        if npc.last_known_x and npc.memory_confidence and npc.memory_confidence > 0 then
            love.graphics.setColor(1, 1, 0, npc.memory_confidence * 0.5)
            love.graphics.line(npc.x, npc.y, npc.last_known_x, npc.last_known_y)
            love.graphics.circle("line", npc.last_known_x, npc.last_known_y, 8)
        end
    end

    -- Influence map overlay
    if debug_layers.influence and influence_map then
        for y = 1, influence_map.rows do
            for x = 1, influence_map.cols do
                local v = influence_map.grid[y][x]
                if v > 0 then
                    local intensity = math.min(v / 10, 1)
                    love.graphics.setColor(intensity, 0, 0, 0.2)
                    love.graphics.rectangle("fill",
                        (x-1) * influence_map.cell_size,
                        (y-1) * influence_map.cell_size,
                        influence_map.cell_size, influence_map.cell_size)
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == "f1" then debug_enabled = not debug_enabled end
    if key == "f2" then debug_layers.states = not debug_layers.states end
    if key == "f3" then debug_layers.vision = not debug_layers.vision end
    if key == "f4" then debug_layers.paths = not debug_layers.paths end
    if key == "f5" then debug_layers.steering = not debug_layers.steering end
    if key == "f6" then debug_layers.utility = not debug_layers.utility end
    if key == "f7" then debug_layers.influence = not debug_layers.influence end
end
```

```gdscript
# GDScript — Debug drawing
@export var debug_enabled := true

func _draw() -> void:
    if not debug_enabled:
        return

    # State label
    draw_string(ThemeDB.fallback_font, Vector2(-20, -30), state_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

    # Vision cone
    var alpha = 0.3 if can_see_player else 0.1
    # ... draw arc

    # Path
    if path.size() > 1:
        for i in range(path.size() - 1):
            draw_line(to_local(path[i]), to_local(path[i+1]), Color(0.2, 0.5, 1, 0.6), 2)
```

**Build the debug overlay before you build the AI.** This sounds backwards, but it's the most productive order. When you add a new behavior, you'll see it working (or not) immediately. Without the overlay, you'll stare at an NPC walking around and wonder "is it chasing because it saw me, or because it heard me, or because the patrol route goes that way?"

---

## 2. Intentional Imperfection

This is the counterintuitive truth of game AI: **making your AI worse makes your game better.** An NPC that plays perfectly — finding the optimal position, landing every shot, never losing track of the player — is not fun to fight. The player needs windows of opportunity, patterns to exploit, and moments where they feel clever. Perfect AI denies all of those.

Imperfection should feel **natural**, not random. The NPC should feel like it's making a *mistake*, not executing a random failure chance.

**Reaction delays:** Add a 0.2-0.5 second delay between perception and action. The guard sees you, pauses (the "processing" moment), then reacts. This is both more realistic and more fair than instant response.

```lua
-- Lua — Reaction delay system
function on_player_detected(npc)
    -- Don't react instantly — add human-like delay
    npc.reaction_pending = true
    npc.reaction_timer = 0.3 + love.math.random() * 0.2  -- 0.3-0.5 seconds
end

function update_reaction(npc, dt)
    if npc.reaction_pending then
        npc.reaction_timer = npc.reaction_timer - dt
        if npc.reaction_timer <= 0 then
            npc.reaction_pending = false
            npc:change_state("chase")  -- now react
        end
    end
end
```

**Accuracy variance:** NPCs shouldn't hit 100% of shots. Add aim error that decreases with proximity and increases with NPC stress.

```lua
-- Lua — Aim with intentional error
function aim_at_player(npc)
    local dx = player.x - npc.x
    local dy = player.y - npc.y
    local base_angle = math.atan2(dy, dx)

    -- Error based on distance (farther = more error)
    local dist = math.sqrt(dx^2 + dy^2)
    local error_range = math.min(dist / 500, 1) * 0.3  -- up to 0.3 radians

    -- Error based on NPC stress
    if npc.health < npc.max_health * 0.3 then
        error_range = error_range * 1.5  -- more panicked = less accurate
    end

    local aim_error = (love.math.random() * 2 - 1) * error_range
    return base_angle + aim_error
end
```

**Losing track:** NPCs should occasionally "lose" the player during a chase, especially around corners. Instead of perfect tracking, the NPC chases the player's last known position and has to re-acquire visual contact.

**Suboptimal pathfinding:** Occasionally, the NPC takes a slightly longer route. Not dramatically wrong — just not the mathematically shortest path. This can be achieved by adding small random costs to A* edges.

**"I almost saw you" moments:** When the player is just outside the vision cone, the NPC could briefly turn toward them (driven by a wider "peripheral awareness" zone) and then turn away. The player feels a spike of tension — "that was close!" — without being detected. These near-misses are more memorable than either detection or obliviousness.

---

## 3. Difficulty Through Parameters, Not Code

The same AI architecture should support easy, normal, and hard difficulty through parameter changes alone. Different difficulty levels should not run different code paths — they should run the same code with different numbers.

```lua
-- Lua — Difficulty parameter table
local difficulty_params = {
    easy = {
        detect_range = 150,
        detect_rate = 0.5,
        reaction_delay = 0.5,
        chase_speed = 80,
        attack_damage = 8,
        accuracy = 0.5,
        search_duration = 3,
        alert_propagation_range = 100,
        lose_track_chance = 0.15,
    },
    normal = {
        detect_range = 200,
        detect_rate = 1.0,
        reaction_delay = 0.3,
        chase_speed = 110,
        attack_damage = 15,
        accuracy = 0.7,
        search_duration = 6,
        alert_propagation_range = 200,
        lose_track_chance = 0.08,
    },
    hard = {
        detect_range = 280,
        detect_rate = 2.0,
        reaction_delay = 0.1,
        chase_speed = 140,
        attack_damage = 22,
        accuracy = 0.9,
        search_duration = 12,
        alert_propagation_range = 350,
        lose_track_chance = 0.02,
    },
}

-- Apply to NPC on creation
function create_npc(x, y, difficulty)
    local params = difficulty_params[difficulty]
    return {
        x = x, y = y,
        detect_range = params.detect_range,
        detect_rate = params.detect_rate,
        reaction_delay = params.reaction_delay,
        chase_speed = params.chase_speed,
        attack_damage = params.attack_damage,
        accuracy = params.accuracy,
        search_duration = params.search_duration,
        -- ... all other parameters from the table
    }
end
```

This approach has a critical advantage: **balance testers can adjust difficulty by editing a data table, not by understanding your AI code.** It also makes A/B testing trivial — you can compare two difficulty profiles by swapping tables.

---

## 4. Performance Budgeting

AI is expensive. Every NPC running perception checks, pathfinding, behavior tree evaluations, and steering calculations adds up. On a typical 2D game targeting 60 FPS, you have ~16.6ms per frame for everything — rendering, physics, audio, and AI.

**Rule of thumb:** Budget 2-4ms per frame for AI. If you have 20 NPCs, that's 0.1-0.2ms per NPC. That's plenty for FSMs and steering, but tight for A* pathfinding or large behavior trees.

**Techniques for staying within budget:**

**Stagger updates.** Don't update every NPC every frame. Use a round-robin where each NPC updates its "expensive" AI (pathfinding, utility scoring) every 3-5 frames, but updates "cheap" AI (steering, collision avoidance) every frame.

```lua
-- Lua — Staggered AI updates
function update_all_npcs(npcs, dt, frame_count)
    for i, npc in ipairs(npcs) do
        -- Cheap updates every frame
        update_steering(npc, dt)
        update_movement(npc, dt)

        -- Expensive updates staggered across frames
        if (frame_count + i) % 4 == 0 then
            update_perception(npc, dt * 4)  -- compensate for less frequent updates
            update_behavior_tree(npc, dt * 4)
        end

        -- Very expensive updates (pathfinding) even less frequently
        if (frame_count + i) % 15 == 0 then
            if npc.needs_repath then
                update_pathfinding(npc)
                npc.needs_repath = false
            end
        end
    end
end
```

**AI Level of Detail (LOD).** NPCs far from the player run simplified AI. A guard 500 pixels away doesn't need per-frame vision cone checks — a distance check every half-second is sufficient. A guard off-screen might only update its patrol position occasionally.

```lua
-- Lua — AI LOD based on distance to player
function get_ai_lod(npc, player)
    local dist = distance(npc.x, npc.y, player.x, player.y)
    if dist < 200 then return "full" end
    if dist < 500 then return "reduced" end
    return "minimal"
end

function update_npc_with_lod(npc, dt, lod)
    if lod == "full" then
        -- Full AI: vision cone, hearing, full BT, steering
        update_perception(npc, dt)
        update_behavior_tree(npc, dt)
        update_steering(npc, dt)
    elseif lod == "reduced" then
        -- Simplified: distance check only, basic movement
        if distance(npc.x, npc.y, player.x, player.y) < npc.detect_range then
            npc.state = "alert"
        end
        update_basic_movement(npc, dt)
    else
        -- Minimal: just advance patrol timer
        npc.patrol_timer = npc.patrol_timer + dt
    end
end
```

**Object pooling for pathfinding.** If many NPCs request paths to the same destination, share the result. Or use a flow field (Module 4) when 10+ NPCs navigate to the same goal.

---

## 5. The "Watch Someone Play" Test

The ultimate validation of your AI is watching someone play who doesn't know the rules. You can't do this test alone — you already know how the AI works. You need fresh eyes.

**What to watch for:**
- **Does the player feel threatened?** If they walk past enemies without concern, the AI isn't creating tension.
- **Does the player feel capable?** If they're frustrated and confused, the AI is too aggressive or too opaque.
- **Does the player ever say "whoa, that was smart"?** This is the gold standard. The AI did something the player didn't expect but finds believable.
- **Does the player ever say "that's BS"?** This is the red flag. Something felt unfair — a detection that was too fast, damage they couldn't avoid, or an attack they couldn't see coming.
- **Does the player learn the patterns?** After a few encounters, they should be anticipating NPC behavior and developing strategies. If they're not learning, the AI is too random. If they're bored, the AI is too predictable.

**How to conduct the test:**
1. Sit behind the player (or watch a recording). Don't explain anything.
2. Note moments of delight, frustration, confusion, and boredom.
3. After the session, ask: "What did you think of the enemies?" Listen. Don't defend your design.
4. Look for patterns across multiple testers. One person's frustration is anecdotal. Three people struggling at the same point is a design problem.

---

## 6. The "Fun First" Philosophy

If a technically correct AI behavior makes the game less fun, the behavior is wrong. Fun overrides correctness, always. This is the hardest principle for engineers to accept because it means willfully writing "bad" code — AI that cheats, that misses on purpose, that forgets the player's position, that takes suboptimal routes.

**Examples of "incorrect" but fun AI decisions:**

- **The first shot always misses.** The player needs to register that enemies are shooting before they take damage.
- **Enemies don't all attack simultaneously.** Even if they all see the player, only 2-3 attack while others hang back. This prevents overwhelming damage and creates a cinematic stagger.
- **The director nudges threats toward the player.** If the player hasn't encountered anything in 30 seconds, spawn or redirect an NPC toward them. Silence is boring.
- **NPCs hesitate before entering a room.** Even if they know the player is inside, they pause at the doorway. This gives the player time to prepare and creates a tense standoff moment.
- **Fleeing enemies occasionally stumble.** A 5% chance to trip during flee behavior lets the player catch up and creates satisfying "almost got away" moments.

None of these are technically correct. All of them make the game better. The craft is in knowing when to break the rules.

---

## 7. Common AI Smells (and How to Fix Them)

"AI smells" are behavioral patterns that signal something is wrong. Like code smells, they're symptoms, not diagnoses — but they point you toward the problem.

| Smell | Symptom | Likely Cause | Fix |
|-------|---------|-------------|-----|
| **The Statue** | NPC stands motionless for long periods | Missing transition, deadlocked state | Check for states with no exit conditions. Add timeout transitions. |
| **The Oscillator** | NPC rapidly switches between two behaviors | Transition flickering (threshold boundary) | Add hysteresis. Different thresholds for entering and exiting states. |
| **The Lemming** | NPC walks into walls or off cliffs | Pathfinding/steering not working, no obstacle avoidance | Verify obstacle avoidance is blended with navigation. Add wall feelers. |
| **The Psychic** | NPC knows things it shouldn't (player behind wall) | Missing LOS check, detection not using perception system | Ensure all detection goes through the perception system, not distance alone. |
| **The Goldfish** | NPC forgets the player instantly when LOS breaks | No memory system, binary detection | Add memory with decay. Investigate last known position before giving up. |
| **The Mime** | NPC in combat just stands near the player doing nothing | Attack cooldowns too long, missing attack state, broken attack transition | Check attack cooldowns. Verify the attack state exists and has valid transitions. |
| **The Mob** | All NPCs cluster on the same point | No separation force, no role differentiation | Add separation steering. Use squad roles or influence maps for positioning. |
| **The Terminator** | NPC is impossibly accurate and responsive | No intentional imperfection, no reaction delay | Add aim error, reaction delays, and occasional "losing track." |

---

## 8. The Tuning Loop

Tuning AI is iterative. There is no formula that produces the "right" values on the first try. The process is:

1. **Implement** the behavior with reasonable default values
2. **Visualize** it with debug overlays
3. **Play** against it — feel the experience
4. **Identify** what feels wrong (too fast? too slow? unfair? boring?)
5. **Adjust** one or two parameters
6. **Repeat** from step 3

**Important rules:**
- Change one thing at a time. If you adjust speed AND detection range AND reaction delay simultaneously, you won't know which change caused the improvement.
- Keep notes. "Detection range 200→180 felt much better because the player had time to hide behind pillars" is invaluable context when you come back to tune later.
- Trust your gut. If it feels wrong, it is wrong, even if the numbers "should" be right. The numbers serve the feel, not the other way around.

```lua
-- Lua — Tuning with live parameter adjustment
local tuning = {
    detect_range = 200,
    chase_speed = 120,
    reaction_delay = 0.3,
    search_duration = 5.0,
    attack_cooldown = 1.0,
}

-- Live adjustment during play
function love.keypressed(key)
    if key == "1" then tuning.detect_range = tuning.detect_range + 10 end
    if key == "2" then tuning.detect_range = tuning.detect_range - 10 end
    if key == "3" then tuning.chase_speed = tuning.chase_speed + 10 end
    if key == "4" then tuning.chase_speed = tuning.chase_speed - 10 end
    if key == "5" then tuning.reaction_delay = tuning.reaction_delay + 0.05 end
    if key == "6" then tuning.reaction_delay = tuning.reaction_delay - 0.05 end
end

-- Display current values
function draw_tuning_hud()
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(string.format(
        "TUNING: Range=%d  Speed=%d  Delay=%.2f  Search=%.1f  Cooldown=%.1f",
        tuning.detect_range, tuning.chase_speed, tuning.reaction_delay,
        tuning.search_duration, tuning.attack_cooldown
    ), 10, 10)
    love.graphics.print("Keys: 1/2=range  3/4=speed  5/6=delay", 10, 28)
end
```

Building live-tuning controls pays for itself in the first 10 minutes. Adjusting a number in code, recompiling, and testing takes 30 seconds. Pressing a key during gameplay and seeing the effect instantly takes 0.1 seconds. Over hundreds of tuning iterations, this adds up to hours saved.

---

## Code Walkthrough: A Complete Debug-Ready NPC

Here's a guard NPC with full debug visualization — the kind of setup you should have for every NPC during development.

```lua
-- Lua (LÖVE) — Guard with full debug overlay
local guard = {
    x = 300, y = 300,
    speed = 80, chase_speed = 130,
    state = "patrol",
    facing = 0,
    -- Perception
    fov = 90, view_dist = 200,
    can_see_player = false,
    -- Memory
    last_known_x = nil, last_known_y = nil,
    memory_confidence = 0,
    -- Patrol
    patrol = {{150,200},{450,200},{450,400},{150,400}},
    patrol_idx = 1,
    -- Steering forces (for debug)
    debug_forces = {},
    -- Search
    search_timer = 0,
    -- Imperfection
    reaction_timer = 0,
}

local player = { x = 400, y = 300 }
local debug_on = true

function love.update(dt)
    -- Player movement
    if love.keyboard.isDown("w") then player.y = player.y - 150 * dt end
    if love.keyboard.isDown("s") then player.y = player.y + 150 * dt end
    if love.keyboard.isDown("a") then player.x = player.x - 150 * dt end
    if love.keyboard.isDown("d") then player.x = player.x + 150 * dt end

    -- Perception
    guard.can_see_player = check_vision(guard, player)

    -- Memory
    if guard.can_see_player then
        guard.last_known_x = player.x
        guard.last_known_y = player.y
        guard.memory_confidence = 1.0
    elseif guard.memory_confidence > 0 then
        guard.memory_confidence = guard.memory_confidence - dt / 8
    end

    -- Reaction delay
    if guard.reaction_timer > 0 then
        guard.reaction_timer = guard.reaction_timer - dt
        return
    end

    -- FSM
    guard.debug_forces = {}

    if guard.state == "patrol" then
        if guard.can_see_player then
            guard.state = "chase"
            guard.reaction_timer = 0.3 + love.math.random() * 0.2
            return
        end
        local t = guard.patrol[guard.patrol_idx]
        local dx, dy = t[1] - guard.x, t[2] - guard.y
        local dist = math.sqrt(dx^2 + dy^2)
        if dist < 8 then
            guard.patrol_idx = guard.patrol_idx % #guard.patrol + 1
        else
            guard.x = guard.x + dx/dist * guard.speed * 0.6 * dt
            guard.y = guard.y + dy/dist * guard.speed * 0.6 * dt
            guard.facing = math.atan2(dy, dx)
            table.insert(guard.debug_forces, {
                x = dx/dist * 40, y = dy/dist * 40,
                color = {0, 1, 0, 0.6}, label = "patrol"
            })
        end

    elseif guard.state == "chase" then
        if not guard.can_see_player and guard.memory_confidence <= 0 then
            guard.state = "search"
            guard.search_timer = 5.0
            return
        end
        local tx = guard.can_see_player and player.x or guard.last_known_x
        local ty = guard.can_see_player and player.y or guard.last_known_y
        if tx then
            local dx, dy = tx - guard.x, ty - guard.y
            local dist = math.sqrt(dx^2 + dy^2)
            if dist > 3 then
                guard.x = guard.x + dx/dist * guard.chase_speed * dt
                guard.y = guard.y + dy/dist * guard.chase_speed * dt
                guard.facing = math.atan2(dy, dx)
                table.insert(guard.debug_forces, {
                    x = dx/dist * 60, y = dy/dist * 60,
                    color = {1, 0.3, 0, 0.8}, label = "chase"
                })
            end
        end

    elseif guard.state == "search" then
        if guard.can_see_player then
            guard.state = "chase"
            return
        end
        guard.search_timer = guard.search_timer - dt
        if guard.search_timer <= 0 then
            guard.state = "patrol"
            guard.memory_confidence = 0
            return
        end
        -- Move to last known position
        if guard.last_known_x then
            local dx = guard.last_known_x - guard.x
            local dy = guard.last_known_y - guard.y
            local dist = math.sqrt(dx^2 + dy^2)
            if dist > 10 then
                guard.x = guard.x + dx/dist * guard.speed * 0.5 * dt
                guard.y = guard.y + dy/dist * guard.speed * 0.5 * dt
                guard.facing = math.atan2(dy, dx)
            else
                guard.facing = guard.facing + dt * 2  -- look around
            end
        end
    end
end

function check_vision(npc, target)
    local dx = target.x - npc.x
    local dy = target.y - npc.y
    local dist = math.sqrt(dx^2 + dy^2)
    if dist > npc.view_dist then return false end
    local angle = math.atan2(dy, dx)
    local diff = angle - npc.facing
    while diff > math.pi do diff = diff - 2*math.pi end
    while diff < -math.pi do diff = diff + 2*math.pi end
    return math.abs(diff) < math.rad(npc.fov / 2)
end

function love.keypressed(key)
    if key == "tab" then debug_on = not debug_on end
end

function love.draw()
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    if debug_on then
        -- Vision cone
        local half_fov = math.rad(guard.fov / 2)
        local cone_color = guard.can_see_player
            and {1, 0.3, 0.3, 0.2}
            or {0.3, 0.8, 0.3, 0.1}
        love.graphics.setColor(cone_color)
        love.graphics.arc("fill", guard.x, guard.y, guard.view_dist,
            guard.facing - half_fov, guard.facing + half_fov)

        -- Steering force arrows
        for _, force in ipairs(guard.debug_forces) do
            love.graphics.setColor(force.color)
            love.graphics.setLineWidth(2)
            love.graphics.line(guard.x, guard.y,
                guard.x + force.x, guard.y + force.y)
            love.graphics.setLineWidth(1)
        end

        -- Memory line
        if guard.last_known_x and guard.memory_confidence > 0 then
            love.graphics.setColor(1, 1, 0, guard.memory_confidence * 0.5)
            love.graphics.setLineWidth(1)
            love.graphics.line(guard.x, guard.y, guard.last_known_x, guard.last_known_y)
            love.graphics.circle("line", guard.last_known_x, guard.last_known_y, 6)
        end

        -- Patrol path
        love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
        for i = 1, #guard.patrol do
            local j = i % #guard.patrol + 1
            love.graphics.line(guard.patrol[i][1], guard.patrol[i][2],
                guard.patrol[j][1], guard.patrol[j][2])
        end
    end

    -- Guard
    local state_colors = {
        patrol = {0, 0.7, 0},
        chase = {1, 0.4, 0},
        search = {1, 1, 0},
    }
    love.graphics.setColor(state_colors[guard.state] or {1,1,1})
    love.graphics.circle("fill", guard.x, guard.y, 10)

    -- Player
    love.graphics.setColor(0.2, 0.5, 1)
    love.graphics.circle("fill", player.x, player.y, 8)

    -- HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("State: " .. guard.state:upper(), guard.x - 25, guard.y - 25)
    love.graphics.print(string.format("Memory: %.0f%%", guard.memory_confidence * 100),
        guard.x - 25, guard.y + 15)
    love.graphics.print("WASD to move | TAB to toggle debug", 10, 580)
end
```

---

## Common Pitfalls

### 1. Shipping without debug tools

You developed the AI, it seems to work, you remove the debug code and ship. Then a tester reports "the guard just stood there." Without debug visualization, you have no idea which state it was in or why it was stuck. Keep the debug overlay in the build (behind a toggle) throughout development.

### 2. Tuning by spreadsheet instead of feel

You calculated that detection range should be 200 pixels based on screen size ratios and player movement speed. But it doesn't feel right. Trust the feel. The math gives you a starting point. Iteration gives you the right answer.

### 3. Making AI perfectly consistent

Every guard has identical parameters. They all detect at the same range, chase at the same speed, search for the same duration. The result feels artificial. Add ±10-15% random variation to NPC parameters at spawn time. Each guard is slightly different, and the group feels organic.

### 4. Not testing on different skill levels

You're good at your own game, so the AI feels too easy. You increase difficulty. Now casual players can't get past the first encounter. Test with players at multiple skill levels. Difficulty settings should be tuned for different audiences, not different parameters of the developer's taste.

### 5. Over-tuning one encounter

You spent 8 hours perfecting one guard's behavior. It's beautiful. But it's also one guard in a game with 50 encounters. Spread your tuning time across the game. A universally "good enough" AI is better than one perfect guard and 49 default guards.

### 6. Ignoring performance until it's too late

You have 30 NPCs running full A* pathfinding every frame and wonder why the game runs at 15 FPS. Profile AI cost early. Budget 2-4ms per frame. Use staggered updates and AI LOD from the start, not as a desperate optimization pass at the end.

---

## Exercises

### Exercise 1: Full Debug Overlay
**Time:** 1.5-2 hours

Take any NPC you built in a previous module and add a complete debug overlay. Requirements:

1. Current state/behavior name as text above the NPC
2. Vision cone (colored by detection state)
3. Path line (if using pathfinding)
4. Steering force vectors as colored arrows
5. Memory line to last known position (fading with confidence)
6. Toggle all overlays with a key press

**Concepts practiced:** Debug visualization, understanding AI state, tool-building

**Stretch goal:** Add a utility score bar chart showing all action scores in real-time (if the NPC uses utility AI).

---

### Exercise 2: Intentional Imperfection Tuning
**Time:** 1-1.5 hours

Take a guard NPC and add three types of intentional imperfection:

1. **Reaction delay:** 0.3-0.5 second pause before reacting to the player
2. **Lose track chance:** 10% chance per second during chase to "lose" the player and enter search
3. **Accuracy variance:** If the guard has a ranged attack, add aim error that increases with distance

With debug overlay on, tune these values until the guard feels "challenging but fair." Document the final values and why they feel right.

**Concepts practiced:** Intentional imperfection, tuning by feel, fairness calibration

**Stretch goal:** Add difficulty profiles that only change these imperfection parameters. Easy = more imperfection. Hard = less.

---

### Exercise 3: The Playtest
**Time:** 1-2 hours (plus finding a tester)

Find someone who hasn't played your game. Sit them down with a stealth or combat prototype from an earlier module. Watch them play for 10 minutes without helping or explaining. Take notes:

1. Three moments where they seemed engaged (what was the AI doing?)
2. Three moments where they seemed frustrated (what went wrong?)
3. Did they learn the NPC patterns? How quickly?
4. What did they say about the enemies afterward?

Based on your observations, identify the top 3 tuning changes that would most improve the experience. Implement them.

**Concepts practiced:** Playtesting, observation, evidence-based tuning, the "watch someone play" test

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| "Debugging AI: Tools and Techniques" from *Game AI Pro* | Book chapter (free) | Practical debug visualization and logging techniques for production AI |
| "The Art of Imperfection in Game AI" on Game Developer | Articles | Thoughtful treatment of why "worse" AI is often better game design |
| *Game Programming Patterns* by Robert Nystrom, "Game Loop" and "Update Method" | Book (free) | Relevant for AI performance budgeting and update scheduling |
| "Juice It or Lose It" GDC talk by Martin Jonasson & Petri Purho | GDC talk | While not AI-specific, the philosophy of "juicing" applies directly to making AI feel alive |
| *The Art of Game Design* by Jesse Schell, Chapter on Playtesting | Book | The best framework for conducting playtests and interpreting results |

---

## Key Takeaways

1. **Debug visualization is your most important AI tool.** Draw states, paths, perception, steering vectors, and scores. If you can't see it, you can't tune it. Build debug overlays before building the AI.

2. **Intentional imperfection makes AI feel alive.** Reaction delays, accuracy variance, and occasional "losing track" create exploitable windows and natural-feeling behavior. Perfect AI is boring. Believably imperfect AI is engaging.

3. **Difficulty lives in parameters, not code.** One AI architecture, multiple difficulty profiles, zero code duplication. Detection range, reaction speed, accuracy, and search duration are all tuning knobs.

4. **The "watch someone play" test is the ultimate validation.** Fresh eyes reveal problems you can't see. If the player says "that was BS," you have a telegraph problem. If they say "whoa, smart," you've nailed it.

5. **Performance budgets prevent late-stage crises.** Budget 2-4ms per frame for AI. Use staggered updates and LOD from the start. Profile early.

6. **Fun overrides correctness, always.** If a technically correct behavior makes the game less fun, it's wrong. First shots that miss, enemies that don't all attack at once, directors that nudge threats toward the player — these "cheats" make games great.

---

## What Comes After?

You've completed the Game AI Learning Roadmap. You now have a comprehensive toolkit: FSMs and behavior trees for decisions, steering and pathfinding for movement, utility AI and GOAP for complex reasoning, perception for awareness, group AI for coordination, boss patterns for set-piece encounters, and debug/tuning practices for polish.

The path forward is practice. Pick a game you love. Build an enemy that feels like it belongs in that game. Then build another. Each implementation will teach you things no tutorial can — the feel of getting a detection range *just right*, the satisfaction of watching a group of NPCs flank the player without being scripted to do so, the thrill of a boss fight that makes the player pump their fist when they win.

Game AI is a craft. The algorithms are the easy part. The art is in the tuning, the imperfection, and the relentless focus on the player's experience. Go make something that feels alive.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
