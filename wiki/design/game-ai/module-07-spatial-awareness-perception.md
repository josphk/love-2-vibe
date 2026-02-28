# Module 7: Spatial Awareness & Perception

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 5-8 hours
**Prerequisites:** [Module 1: Finite State Machines](module-01-finite-state-machines.md)

---

## Overview

Every module so far has assumed that NPCs magically know where the player is. The guard "detects" the player through a simple distance check — if the player is within 200 pixels, the guard knows. That works for many games, but when awareness itself is a game mechanic — stealth games, horror games, survival horror — you need a proper perception system.

A perception system gives NPCs simulated senses. **Vision** is a cone (angle + distance) with line-of-sight occlusion. The guard can only "see" targets within its field of view that aren't behind walls. **Hearing** is a radius triggered by events — footsteps, gunshots, breaking glass — with distance attenuation. **Memory** bridges the gap between "fully aware" and "completely oblivious": when the NPC loses sight of the player, it doesn't instantly forget. It remembers the last known position and investigates.

This module is where game AI connects most directly to game design. A perception system's tuning determines how a stealth game *feels*. Detection that's too generous makes the game frustrating. Detection that's too lenient makes it boring. The sweet spot — where the player feels like they're outwitting a competent but beatable opponent — requires careful calibration and clear communication to the player.

---

## 1. Vision Cones

A vision cone has three properties: **field-of-view angle** (how wide the NPC can see), **view distance** (how far), and **occlusion** (whether walls block sight).

```
Vision cone:
              view distance
         ←─────────────────→
              .  .  .  .  .
            .               .
          .         FOV       .
        .      ┌─────────┐     .
       .       │   NPC   │ ───→ facing direction
        .      └─────────┘     .
          .                   .
            .               .
              .  .  .  .  .
```

The math: check if the target is (1) within view distance and (2) within the FOV angle from the NPC's facing direction.

```gdscript
# GDScript — Vision cone check
@export var fov_angle := 90.0  # degrees, total spread
@export var view_distance := 250.0

func can_see(target: Vector2) -> bool:
    var to_target = target - global_position
    var distance = to_target.length()

    # Distance check
    if distance > view_distance:
        return false

    # Angle check
    var facing = Vector2.RIGHT.rotated(rotation)
    var angle_to_target = rad_to_deg(facing.angle_to(to_target))
    if abs(angle_to_target) > fov_angle / 2.0:
        return false

    # Occlusion check (raycast)
    var space = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(global_position, target)
    query.exclude = [self]
    var result = space.intersect_ray(query)

    # If raycast hit something before reaching target, view is blocked
    if result and result.position.distance_to(global_position) < distance - 5.0:
        return false

    return true
```

```lua
-- Lua — Vision cone check
function can_see(npc, target_x, target_y, walls)
    local dx = target_x - npc.x
    local dy = target_y - npc.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Distance check
    if dist > npc.view_distance then return false end

    -- Angle check
    local angle_to_target = math.atan2(dy, dx)
    local angle_diff = angle_to_target - npc.facing_angle
    -- Normalize to [-pi, pi]
    while angle_diff > math.pi do angle_diff = angle_diff - 2 * math.pi end
    while angle_diff < -math.pi do angle_diff = angle_diff + 2 * math.pi end

    local half_fov = math.rad(npc.fov_angle / 2)
    if math.abs(angle_diff) > half_fov then return false end

    -- Occlusion check (ray vs walls)
    for _, wall in ipairs(walls) do
        if ray_intersects_rect(npc.x, npc.y, target_x, target_y, wall) then
            return false
        end
    end

    return true
end

function ray_intersects_rect(x1, y1, x2, y2, rect)
    -- Simplified ray-AABB intersection test
    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then return false end

    -- Check multiple points along the ray
    local steps = math.ceil(len / 5)
    for i = 0, steps do
        local t = i / steps
        local px = x1 + dx * t
        local py = y1 + dy * t
        if px >= rect.x and px <= rect.x + rect.w and
           py >= rect.y and py <= rect.y + rect.h then
            return true
        end
    end
    return false
end
```

**Visualization is critical.** Draw the vision cone during development — a filled arc showing the FOV with the view distance as radius. Color it differently when the player is detected. Players should also see an approximation of the cone (many stealth games show it on the minimap or as a visible light beam).

---

## 2. Hearing — Event-Driven Detection

Vision is continuous — checked every frame. Hearing is event-driven — triggered by specific game events. When the player sprints, fires a weapon, breaks a window, or knocks over an object, a **sound event** is generated at that position with a **loudness** value.

NPCs within hearing range register the event and may react — turning toward the sound, investigating the source, or going to alert.

```lua
-- Lua — Sound event system
local sound_events = {}

function emit_sound(x, y, loudness, source)
    table.insert(sound_events, {
        x = x, y = y,
        loudness = loudness,  -- hearing radius in pixels
        source = source,
        age = 0,
    })
end

function process_sounds_for_npc(npc, dt)
    for _, sound in ipairs(sound_events) do
        local dist = distance(npc.x, npc.y, sound.x, sound.y)
        if dist < sound.loudness then
            -- Loudness attenuates with distance
            local effective_loudness = sound.loudness - dist
            if effective_loudness > npc.hearing_threshold then
                -- NPC heard something
                npc.heard_sound = true
                npc.sound_x = sound.x
                npc.sound_y = sound.y
                npc.sound_loudness = effective_loudness
            end
        end
    end
end

-- Clean up old sound events each frame
function update_sounds(dt)
    for i = #sound_events, 1, -1 do
        sound_events[i].age = sound_events[i].age + dt
        if sound_events[i].age > 0.5 then  -- sounds last half a second
            table.remove(sound_events, i)
        end
    end
end

-- Usage: when the player runs
emit_sound(player.x, player.y, 150, "footsteps")

-- When the player fires a weapon
emit_sound(player.x, player.y, 400, "gunshot")

-- When an object breaks
emit_sound(barrel.x, barrel.y, 200, "breaking_object")
```

**Sound propagation through geometry:** In a simple implementation, sound passes through walls at full strength. For more realism, check if there's a wall between the NPC and the sound source — if so, reduce the effective loudness by 50-70%. Sound traveling through open doorways should be less attenuated than through solid walls.

---

## 3. NPC Memory — Bridging Awareness and Ignorance

In most games, the NPC either knows where the player is (player_visible = true) or doesn't (player_visible = false). This binary creates jarring behavior — the instant the player breaks line of sight, the guard stops chasing and stands still.

Memory bridges this gap. When the NPC loses sight of the player, it **remembers** the last known position and transitions to a search behavior. Memory decays over time — the NPC becomes less certain of where the player was.

```lua
-- Lua — NPC memory system
local memory = {
    last_seen_x = nil,
    last_seen_y = nil,
    last_seen_time = 0,
    confidence = 0,        -- 0 to 1: how sure the NPC is
    max_memory_time = 8.0, -- seconds before forgetting
}

function update_memory(npc, can_see_target, target_x, target_y, dt)
    if can_see_target then
        -- Seeing the target: update memory with full confidence
        memory.last_seen_x = target_x
        memory.last_seen_y = target_y
        memory.last_seen_time = 0
        memory.confidence = 1.0
    else
        -- Not seeing: memory decays
        if memory.confidence > 0 then
            memory.last_seen_time = memory.last_seen_time + dt
            memory.confidence = math.max(0,
                1.0 - (memory.last_seen_time / memory.max_memory_time))
        end
    end
end

-- Usage in AI decision making:
-- if memory.confidence > 0.5 then investigate last_seen position
-- if memory.confidence > 0 and < 0.5 then search area generally
-- if memory.confidence == 0 then return to patrol
```

Memory also enables **investigation behavior**. Instead of "chase → instantly give up," the NPC follows a more believable sequence: "chase → lose sight → go to last known position → search area → give up gradually." This sequence is what makes stealth games tense — the player hides and watches the guard investigate where they just were.

---

## 4. Alert Levels — The Awareness Gradient

The best stealth games don't use binary detection. They use a **gradient** — multiple alert levels with different behaviors and different transitions between them.

```
Alert Level Progression:

  UNAWARE → SUSPICIOUS → SEARCHING → ALERT → COMBAT
     │          │            │          │        │
     │          │            │          │        │
  Normal     Heard a      Looking    Confirmed  Active
  patrol     noise or     for the    threat     engagement
             glimpse      source     detected
```

Each level has different NPC behavior:

| Level | Movement | Detection | Behavior |
|-------|----------|-----------|----------|
| **Unaware** | Normal speed, fixed patrol | Standard FOV and hearing | Predictable, exploitable |
| **Suspicious** | Slower, stops frequently | Wider FOV, better hearing | Turns toward stimulus, pauses |
| **Searching** | Methodical, covers area | Full 360° awareness | Goes to investigation point, looks around |
| **Alert** | Fast, purposeful | Maximum range and sensitivity | Moves to last known position aggressively |
| **Combat** | Combat speed | N/A (already engaged) | Fights using combat AI |

```lua
-- Lua — Alert level system
local UNAWARE = 1
local SUSPICIOUS = 2
local SEARCHING = 3
local ALERT = 4
local COMBAT = 5

local alert_names = { "unaware", "suspicious", "searching", "alert", "combat" }

local npc = {
    alert_level = UNAWARE,
    alert_timer = 0,
    suspicion_meter = 0,       -- fills up toward detection
    suspicion_threshold = 1.0, -- how full it needs to be for state change
}

function update_alert(npc, can_see, heard_sound, dist_to_player, dt)
    if npc.alert_level == UNAWARE then
        if can_see then
            -- Distance affects detection speed
            local detection_rate = 1.0 - (dist_to_player / npc.view_distance)
            npc.suspicion_meter = npc.suspicion_meter + detection_rate * dt * 2
        elseif heard_sound then
            npc.alert_level = SUSPICIOUS
            npc.alert_timer = 5.0
        end
        if npc.suspicion_meter >= npc.suspicion_threshold then
            npc.alert_level = ALERT
            npc.suspicion_meter = 0
        end

    elseif npc.alert_level == SUSPICIOUS then
        if can_see then
            npc.suspicion_meter = npc.suspicion_meter + dt * 3
            if npc.suspicion_meter >= npc.suspicion_threshold then
                npc.alert_level = ALERT
            end
        else
            npc.alert_timer = npc.alert_timer - dt
            if npc.alert_timer <= 0 then
                npc.alert_level = UNAWARE
                npc.suspicion_meter = 0
            end
        end

    elseif npc.alert_level == SEARCHING then
        if can_see then
            npc.alert_level = COMBAT
        else
            npc.alert_timer = npc.alert_timer - dt
            if npc.alert_timer <= 0 then
                npc.alert_level = SUSPICIOUS
                npc.alert_timer = 3.0
            end
        end

    elseif npc.alert_level == ALERT then
        if can_see and dist_to_player < npc.attack_range then
            npc.alert_level = COMBAT
        elseif not can_see then
            npc.alert_level = SEARCHING
            npc.alert_timer = 8.0
        end

    elseif npc.alert_level == COMBAT then
        if not can_see then
            npc.alert_level = SEARCHING
            npc.alert_timer = 10.0
        end
    end
end
```

The suspicion meter is particularly important. It fills up gradually based on how visible the player is (closer = faster fill). This creates the classic stealth game tension: the player is partially visible, the meter is creeping up, and they have to decide whether to risk staying or retreat. The meter is typically shown to the player as a UI element (the yellow-to-red awareness indicator).

---

## 5. Detection Meters and Distance Scaling

The suspicion meter should scale with multiple factors:

- **Distance:** Closer = faster detection. An NPC 10 meters away fills the meter much faster than one 50 meters away.
- **Visibility:** Standing in light fills faster than hiding in shadow. Moving fills faster than standing still. Crouching fills slower than standing.
- **Cover:** Behind half-cover fills at 50%. Behind full cover fills at 0%.
- **NPC alert level:** A suspicious NPC detects faster than an unaware one.

```lua
-- Lua — Detection rate calculation
function detection_rate(npc, target, dt)
    if not in_vision_cone(npc, target.x, target.y) then
        return 0
    end
    if not has_line_of_sight(npc, target) then
        return 0
    end

    local dist = distance(npc.x, npc.y, target.x, target.y)
    local dist_factor = 1.0 - (dist / npc.view_distance)  -- 1.0 at close, 0.0 at max range

    -- Visibility modifiers
    local visibility = 1.0
    if target.is_crouching then visibility = visibility * 0.5 end
    if target.is_in_shadow then visibility = visibility * 0.3 end
    if not target.is_moving then visibility = visibility * 0.6 end
    if target.in_half_cover then visibility = visibility * 0.5 end

    -- Alert level modifier
    local alert_mod = 1.0
    if npc.alert_level == SUSPICIOUS then alert_mod = 1.5 end
    if npc.alert_level == SEARCHING then alert_mod = 2.0 end
    if npc.alert_level == ALERT then alert_mod = 3.0 end

    return dist_factor * visibility * alert_mod * dt
end
```

This produces nuanced detection behavior. A player crouching in shadow at long range is nearly invisible. The same player standing in light at close range is instantly detected. The system communicates "rules" the player can learn — stay in shadow, stay far, crouch, don't move — without the designer explicitly coding each scenario.

---

## 6. The Stimulus System — Unified Perception

Instead of handling vision, hearing, and other senses separately, a clean architecture uses a unified **stimulus system**. All perception inputs — visual contacts, sounds, damage taken, allied alerts — are converted to stimuli with a common format.

```lua
-- Lua — Unified stimulus system
local Stimulus = {}

function Stimulus.new(type, x, y, intensity, source)
    return {
        type = type,          -- "visual", "audio", "damage", "alert"
        x = x, y = y,
        intensity = intensity, -- 0 to 1
        source = source,       -- what caused it
        age = 0,
    }
end

-- NPC's perception system processes all stimuli uniformly
function process_stimuli(npc, stimuli, dt)
    local strongest = nil
    local strongest_intensity = 0

    for _, stim in ipairs(stimuli) do
        local effective = stim.intensity

        -- Apply per-type modifiers
        if stim.type == "visual" then
            if not in_vision_cone(npc, stim.x, stim.y) then
                effective = 0
            end
        elseif stim.type == "audio" then
            local dist = distance(npc.x, npc.y, stim.x, stim.y)
            effective = effective * math.max(0, 1 - dist / 300)
        elseif stim.type == "damage" then
            effective = 1.0  -- always noticed
        elseif stim.type == "alert" then
            local dist = distance(npc.x, npc.y, stim.x, stim.y)
            effective = effective * math.max(0, 1 - dist / 200)
        end

        if effective > strongest_intensity then
            strongest_intensity = effective
            strongest = stim
        end
    end

    if strongest then
        react_to_stimulus(npc, strongest)
    end
end

function react_to_stimulus(npc, stim)
    if stim.type == "damage" then
        npc.alert_level = COMBAT
        update_memory(npc, false, stim.x, stim.y, 0)
    elseif stim.intensity > 0.8 then
        npc.alert_level = ALERT
        update_memory(npc, true, stim.x, stim.y, 0)
    elseif stim.intensity > 0.3 then
        npc.alert_level = SUSPICIOUS
        npc.investigate_x = stim.x
        npc.investigate_y = stim.y
    end
end
```

---

## 7. Communication Between NPCs

One NPC spots the player and shouts. Nearby NPCs hear the shout and enter alert mode. This is **NPC-to-NPC communication**, and it's what makes stealth games feel like you're up against a coordinated team rather than isolated individuals.

The simplest approach: when an NPC enters Alert or Combat, it emits a sound event (an "alert" stimulus) that nearby NPCs can hear. More sophisticated approaches use a **shared awareness** system where detecting NPCs propagate their knowledge to allies.

```lua
-- Lua — NPC alert propagation
function alert_nearby(npc, radius)
    for _, ally in ipairs(all_npcs) do
        if ally ~= npc then
            local dist = distance(npc.x, npc.y, ally.x, ally.y)
            if dist < radius then
                -- Share knowledge
                if npc.memory.confidence > 0.5 then
                    ally.memory.last_seen_x = npc.memory.last_seen_x
                    ally.memory.last_seen_y = npc.memory.last_seen_y
                    ally.memory.confidence = math.max(ally.memory.confidence, 0.6)

                    -- Escalate alert level
                    if ally.alert_level < SEARCHING then
                        ally.alert_level = SEARCHING
                        ally.alert_timer = 10.0
                    end
                end
            end
        end
    end
end

-- Called when an NPC enters ALERT or COMBAT:
function on_enter_alert(npc)
    alert_nearby(npc, 200)  -- alert allies within 200 pixels
    -- Could also emit a sound event for distant allies
    emit_sound(npc.x, npc.y, 300, "alert_shout")
end
```

This creates cascade effects: one NPC spots the player, alerts two nearby guards, who then move to investigate from different directions. The player suddenly has three guards converging on their position from a single detection event. This is the kind of emergent coordination that makes stealth games exciting.

---

## 8. Putting It All Together — A Stealth Guard

Here's a complete guard NPC integrating vision, hearing, memory, alert levels, and communication:

```lua
-- Lua (LÖVE) — Complete stealth guard
local Guard = {}
Guard.__index = Guard

function Guard.new(x, y, patrol_points)
    return setmetatable({
        x = x, y = y,
        speed = 60,
        facing = 0,
        -- Vision
        fov = 90,
        view_dist = 200,
        -- Hearing
        hearing_range = 150,
        -- State
        alert_level = 1,  -- UNAWARE
        suspicion = 0,
        alert_timer = 0,
        -- Memory
        last_seen_x = nil, last_seen_y = nil,
        memory_confidence = 0,
        memory_decay = 8.0,
        memory_time = 0,
        -- Patrol
        patrol = patrol_points,
        patrol_idx = 1,
    }, Guard)
end

function Guard:update(dt, player, walls, all_guards)
    local sees_player = can_see(self, player.x, player.y, walls)
    local dist = distance(self.x, self.y, player.x, player.y)

    -- Update memory
    if sees_player then
        self.last_seen_x = player.x
        self.last_seen_y = player.y
        self.memory_confidence = 1.0
        self.memory_time = 0
    elseif self.memory_confidence > 0 then
        self.memory_time = self.memory_time + dt
        self.memory_confidence = math.max(0,
            1 - self.memory_time / self.memory_decay)
    end

    -- Update alert level
    self:update_alert(sees_player, dist, dt)

    -- Behavior based on alert level
    if self.alert_level == 1 then -- UNAWARE
        self:do_patrol(dt)
    elseif self.alert_level == 2 then -- SUSPICIOUS
        self:do_investigate(dt)
    elseif self.alert_level == 3 then -- SEARCHING
        self:do_search(dt)
    elseif self.alert_level >= 4 then -- ALERT/COMBAT
        self:do_chase(dt, player)
        if self.alert_level == 4 then
            alert_nearby_guards(self, all_guards, 250)
        end
    end
end

function Guard:update_alert(sees, dist, dt)
    if self.alert_level == 1 then
        if sees then
            local rate = (1 - dist / self.view_dist) * 2
            self.suspicion = self.suspicion + rate * dt
            if self.suspicion >= 1.0 then
                self.alert_level = 4
                self.suspicion = 0
            elseif self.suspicion > 0.3 then
                self.alert_level = 2
                self.alert_timer = 5
            end
        else
            self.suspicion = math.max(0, self.suspicion - dt * 0.5)
        end

    elseif self.alert_level == 2 then
        if sees then
            self.suspicion = self.suspicion + dt * 3
            if self.suspicion >= 1.0 then
                self.alert_level = 4
            end
        else
            self.alert_timer = self.alert_timer - dt
            if self.alert_timer <= 0 then
                self.alert_level = 1
                self.suspicion = 0
            end
        end

    elseif self.alert_level == 3 then
        if sees then
            self.alert_level = 5
        else
            self.alert_timer = self.alert_timer - dt
            if self.alert_timer <= 0 then
                self.alert_level = 2
                self.alert_timer = 3
            end
        end

    elseif self.alert_level >= 4 then
        if not sees and self.memory_confidence <= 0 then
            self.alert_level = 3
            self.alert_timer = 10
        end
    end
end

function Guard:do_patrol(dt)
    local target = self.patrol[self.patrol_idx]
    local dist = distance(self.x, self.y, target[1], target[2])
    if dist < 8 then
        self.patrol_idx = self.patrol_idx % #self.patrol + 1
    else
        move_toward_point(self, target[1], target[2], self.speed * 0.6, dt)
    end
end

function Guard:do_investigate(dt)
    if self.last_seen_x then
        move_toward_point(self, self.last_seen_x, self.last_seen_y,
            self.speed * 0.4, dt)
    end
    -- Look around slowly
    self.facing = self.facing + dt * 1.0
end

function Guard:do_search(dt)
    if self.last_seen_x then
        local dist = distance(self.x, self.y, self.last_seen_x, self.last_seen_y)
        if dist > 15 then
            move_toward_point(self, self.last_seen_x, self.last_seen_y,
                self.speed * 0.7, dt)
        else
            self.facing = self.facing + dt * 2.0  -- spin and search
        end
    end
end

function Guard:do_chase(dt, player)
    move_toward_point(self, player.x, player.y, self.speed * 1.2, dt)
end

function Guard:draw()
    -- Draw vision cone
    local half_fov = math.rad(self.fov / 2)
    local cone_color = {0.3, 0.6, 0.3, 0.15}
    if self.alert_level == 2 then cone_color = {0.8, 0.8, 0, 0.2} end
    if self.alert_level >= 3 then cone_color = {0.8, 0.2, 0.2, 0.2} end

    love.graphics.setColor(cone_color)
    love.graphics.arc("fill", self.x, self.y, self.view_dist,
        self.facing - half_fov, self.facing + half_fov)

    -- Draw guard body
    local body_color = {0, 0.7, 0}
    if self.alert_level == 2 then body_color = {0.8, 0.8, 0} end
    if self.alert_level == 3 then body_color = {1, 0.5, 0} end
    if self.alert_level >= 4 then body_color = {1, 0, 0} end

    love.graphics.setColor(body_color)
    love.graphics.circle("fill", self.x, self.y, 10)

    -- Draw alert name
    love.graphics.setColor(1, 1, 1)
    local names = {"UNAWARE","SUSPICIOUS","SEARCHING","ALERT","COMBAT"}
    love.graphics.print(names[self.alert_level] or "?", self.x - 25, self.y - 22)

    -- Draw suspicion meter
    if self.suspicion > 0 and self.alert_level < 4 then
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", self.x - 15, self.y - 32, 30, 4)
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("fill", self.x - 15, self.y - 32, 30 * self.suspicion, 4)
    end
end
```

---

## Common Pitfalls

### 1. Binary detection instead of gradual

The NPC either sees you or doesn't — there's no in-between. This feels unfair because the player can't tell when they're about to be spotted. Always use a detection meter that fills up gradually, giving the player time to react and retreat.

### 2. Instant forgetting

The player breaks line of sight and the guard immediately stops chasing. This breaks immersion and makes stealth too easy. Use memory with decay — the guard should investigate the last known position and search the area before giving up.

### 3. Perfect NPC awareness of sounds

Every footstep is heard at full accuracy regardless of distance or obstacles. Scale sound intensity with distance and check for wall obstruction. Sounds through walls should be muffled (reduced intensity) and imprecise (the NPC knows the general direction but not the exact location).

### 4. Not communicating alert states to the player

The guard is suspicious but the player has no way to know. Always show the NPC's awareness state — through body language (standing vs. crouching vs. weapon raised), color coding, UI indicators (awareness meters), or sound cues (the guard muttering "Hm?" when suspicious).

### 5. Detection rates that don't scale with distance

The suspicion meter fills at the same rate whether the player is 10 feet away or 100 feet away. Closer should mean faster detection. This gives the player an intuitive understanding of the risk gradient.

### 6. No cooldown between alert levels

The guard goes from COMBAT → SEARCHING → SUSPICIOUS → UNAWARE in 5 seconds flat. Each de-escalation should take time, with the guard being more vigilant (wider detection, faster meter fill) at higher alert levels. It should take 20-30 seconds to fully return to UNAWARE after combat.

---

## Exercises

### Exercise 1: Vision Cone Playground
**Time:** 1.5-2 hours

Build a test scene with one guard and a player (controlled by mouse). Draw the vision cone visibly. Requirements:

1. The vision cone is drawn as a semi-transparent arc
2. The cone changes color when the player is detected (green → yellow → red)
3. Place walls that block line of sight (gray rectangles)
4. Display "VISIBLE" or "HIDDEN" text on screen
5. Add FOV and range sliders (keyboard controls to adjust)

**Concepts practiced:** Vision cone math, line-of-sight occlusion, visual debugging

**Stretch goal:** Add peripheral vision — a wider but shorter cone outside the main FOV that fills the suspicion meter at 50% rate.

---

### Exercise 2: Full Stealth Prototype
**Time:** 2.5-3 hours

Build a stealth prototype integrating everything from this module:

1. A guard with a visible vision cone patrolling between waypoints
2. Suspicion meter that fills based on distance and visibility
3. Alert levels: Unaware → Suspicious → Searching → Combat
4. Hearing — the player's footsteps make sounds when running (not when walking)
5. Memory — the guard investigates the last known position when the player hides
6. Communication — when one guard enters Alert, nearby guards enter Searching
7. Use at least two guards to demonstrate communication

**Concepts practiced:** All perception systems integrated, alert levels, NPC communication

**Stretch goal:** Add shadows (dark areas) where the player's visibility is reduced. Add throwable objects that create sound distractions.

---

### Exercise 3: Perception Debug HUD
**Time:** 1.5-2 hours

Build a comprehensive debug overlay for your perception system that shows:

1. Vision cone for each NPC (with occlusion visible)
2. Hearing radius as a circle
3. Memory indicator (line to last known position, fading with confidence decay)
4. Alert level as color-coded text above each NPC
5. Suspicion meter as a bar above each NPC
6. Sound event markers (briefly flash where sounds occur)
7. Communication links (lines between NPCs when one alerts another)

Toggle the overlay with a key press. This tool will be invaluable for tuning.

**Concepts practiced:** Debug visualization, perception system inspection, tuning workflow

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| "Perception and Awareness in Game AI" from *Game AI Pro* | Book chapter (free) | Production-tested perception system architecture covering vision, hearing, and memory |
| "How Does the AI See the World?" on Red Blob Games | Interactive article | Beautiful interactive exploration of line-of-sight and visibility algorithms |
| "Stealth Game AI" from *Game AI Pro* | Book chapter (free) | Practical architecture specifically for stealth game perception and alert systems |
| *Metal Gear Solid V* AI GDC postmortem | GDC talk | Deep dive into one of the most sophisticated stealth AI systems ever shipped |
| *Hitman* series AI talks (IOI) | GDC talks | World-class perception system design for open-ended stealth gameplay |

---

## Key Takeaways

1. **Vision cones = angle + distance + occlusion.** Check if the target is within FOV, within range, and not behind a wall. These three checks create believable "sight."

2. **Hearing is event-driven, not continuous.** Sounds are emitted by gameplay events and received by NPCs within range. Attenuate by distance, obstruct by walls.

3. **Memory bridges the awareness gap.** When the NPC loses sight, it remembers the last known position and investigates. Memory decays over time. This is what creates stealth game tension.

4. **Alert levels create a gradient, not a binary.** Unaware → Suspicious → Searching → Alert → Combat, each with different behavior and detection sensitivity. The player should be able to read and predict each level.

5. **Detection meters must be visible to the player.** If the player can't tell they're about to be detected, the system is unfair. Show awareness through UI, body language, sound cues, and color changes.

6. **NPC communication creates coordinated threat.** One guard spotting the player and alerting others turns individual AI into group AI, dramatically increasing the challenge and making the world feel alive.

---

## What's Next?

You now have NPCs with senses — they can see, hear, remember, and communicate. The next module takes the group coordination concept further.

In [Module 8: Group & Crowd Behavior](module-08-group-crowd-behavior.md), you'll learn how to coordinate multiple NPCs as a unit — formations, squad tactics, influence maps, and leader-follower patterns. Where this module covered one NPC alerting nearby allies, Module 8 covers NPCs that actively cooperate: flanking, covering each other, and acting as a coordinated team.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
