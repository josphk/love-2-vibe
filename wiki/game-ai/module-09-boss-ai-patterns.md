# Module 9: Boss AI Patterns

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 6-10 hours
**Prerequisites:** [Module 1: Finite State Machines](module-01-finite-state-machines.md), [Module 7: Spatial Awareness & Perception](module-07-spatial-awareness-perception.md)

---

## Overview

Boss AI is a different discipline from regular NPC AI. A regular enemy needs to be a credible threat in quantity — ten zombies, five guards, a squad of soldiers. A boss needs to be a *performance* — a solo encounter that tests everything the game has taught the player. Boss AI is closer to choreography than intelligence. The boss isn't trying to win. It's creating a dramatic, learnable, escalating challenge.

The worst mistake you can make with boss AI is treating it like smarter enemy AI. A boss that plays optimally — that dodges every attack, finds perfect positioning, and never gives the player an opening — is not a good boss. It's a frustrating wall. A good boss is a **teacher** that gradually reveals its patterns, rewards the player's learning, and escalates complexity at a pace that maintains challenge without causing despair.

This module covers the core patterns: phase systems for escalation, attack telegraphs for fairness, pattern choreography for rhythm, vulnerability windows for reward, and arena design for spatial drama. These are the building blocks of every memorable boss fight from Mega Man to Elden Ring.

---

## 1. Phase Systems — Escalating Complexity

A boss that does the same thing from 100% health to 0% is boring. Phases — triggered by health thresholds — introduce new attacks, increase speed, change the arena, or shift the boss's strategy entirely.

```
Phase Progression:
┌──────────────────────────────────────────────────┐
│ Phase 1 (100%-75%)  │ Phase 2 (75%-50%) │ Phase 3 │
│ Teach core attacks  │ Add new attacks   │ (<25%) │
│ Generous windows    │ Shorter windows   │ All out │
│ Slow pace           │ Medium pace       │ Fast    │
└──────────────────────────────────────────────────┘
```

**Design principles for phases:**
- **Phase 1 teaches.** Introduce the boss's core attacks one at a time with generous telegraph windows. The player should learn the dodge patterns during this phase.
- **Phase 2 combines.** Mix attacks from Phase 1 with new ones. The player's existing knowledge carries forward, but new challenges layer on top.
- **Phase 3 intensifies.** Faster attack speed, shorter telegraphs, combined attack patterns, and possibly arena changes. This phase should feel like a final exam.

```lua
-- Lua — Phase system
local Boss = {}
Boss.__index = Boss

function Boss.new(x, y)
    return setmetatable({
        x = x, y = y,
        health = 100, max_health = 100,
        phase = 1,
        -- Attack system
        attacks = {},
        current_attack = nil,
        attack_timer = 0,
        cooldown = 0,
        -- Phase transition
        transitioning = false,
        transition_timer = 0,
    }, Boss)
end

function Boss:update(dt, player)
    -- Check phase transitions
    local new_phase = self:calculate_phase()
    if new_phase ~= self.phase then
        self:enter_phase(new_phase)
    end

    if self.transitioning then
        self.transition_timer = self.transition_timer - dt
        if self.transition_timer <= 0 then
            self.transitioning = false
        end
        return  -- Boss is invulnerable during transition
    end

    -- Attack pattern
    if self.current_attack then
        self:execute_attack(dt, player)
    else
        self.cooldown = self.cooldown - dt
        if self.cooldown <= 0 then
            self:choose_attack(player)
        end
    end
end

function Boss:calculate_phase()
    local hp_percent = self.health / self.max_health
    if hp_percent > 0.75 then return 1
    elseif hp_percent > 0.40 then return 2
    else return 3
    end
end

function Boss:enter_phase(new_phase)
    self.phase = new_phase
    self.transitioning = true
    self.transition_timer = 2.0  -- dramatic pause
    self.current_attack = nil

    -- Phase-specific setup
    if new_phase == 2 then
        -- Add new attacks, increase speed
        self.attack_speed_mult = 1.3
    elseif new_phase == 3 then
        self.attack_speed_mult = 1.6
        -- Maybe change the arena (spawn hazards, etc.)
    end
end
```

```gdscript
# GDScript — Phase system
extends CharacterBody2D

@export var max_health := 100.0
var health: float
var phase := 1
var transitioning := false
var transition_timer := 0.0
var attack_speed_mult := 1.0

func _ready() -> void:
    health = max_health

func _process(delta: float) -> void:
    var new_phase = _calculate_phase()
    if new_phase != phase:
        _enter_phase(new_phase)

    if transitioning:
        transition_timer -= delta
        if transition_timer <= 0:
            transitioning = false
        return

    _run_attack_pattern(delta)

func _calculate_phase() -> int:
    var hp_pct = health / max_health
    if hp_pct > 0.75: return 1
    elif hp_pct > 0.40: return 2
    else: return 3

func _enter_phase(new_phase: int) -> void:
    phase = new_phase
    transitioning = true
    transition_timer = 2.0

    match new_phase:
        2: attack_speed_mult = 1.3
        3: attack_speed_mult = 1.6
```

**Phase transitions should be dramatic.** A brief invulnerability window (1-2 seconds) with a visual flourish — the boss staggers, the screen shakes, new elements appear — tells the player "something changed" and gives them a moment to breathe before the next phase begins.

---

## 2. Attack Telegraphs — The Fairness Contract

Every boss attack must be **readable**. The player needs to see it coming, understand what it does, and know how to respond. A telegraph is any signal — visual, audio, or behavioral — that communicates an incoming attack.

**Telegraph components:**
- **Wind-up:** A preparation animation that signals the type of attack (arm draws back for a swing, light gathers for a projectile)
- **Indicator:** A visual marker showing the danger zone (red circle on the floor, glowing line showing the swing arc)
- **Sound cue:** An audio signal that reinforces the visual (grunt before a slam, hissing before a fire breath)
- **Timing pause:** A brief freeze at the peak of the wind-up, giving the player a fraction of a second to confirm their dodge

```
Attack Timeline:
├── Telegraph ──┤── Active ─┤── Recovery ──┤
│  Wind-up      │  Damage   │  Vulnerable  │
│  0.6-1.2 sec  │  frames   │  window      │
│  Player reads │  0.2-0.5  │  0.5-1.5 sec │
│  and dodges   │  sec      │  Player      │
│               │           │  attacks     │
```

```lua
-- Lua — Attack with telegraph system
local Attack = {}

function Attack.new(name, telegraph_time, active_time, recovery_time, damage, range)
    return {
        name = name,
        telegraph_time = telegraph_time,
        active_time = active_time,
        recovery_time = recovery_time,
        damage = damage,
        range = range,
        -- Runtime state
        phase = "idle",  -- "telegraph", "active", "recovery"
        timer = 0,
    }
end

function Attack.start(atk)
    atk.phase = "telegraph"
    atk.timer = atk.telegraph_time
end

function Attack.update(atk, dt)
    if atk.phase == "idle" then return false end

    atk.timer = atk.timer - dt

    if atk.timer <= 0 then
        if atk.phase == "telegraph" then
            atk.phase = "active"
            atk.timer = atk.active_time
        elseif atk.phase == "active" then
            atk.phase = "recovery"
            atk.timer = atk.recovery_time
        elseif atk.phase == "recovery" then
            atk.phase = "idle"
            return true  -- attack complete
        end
    end

    return false
end

function Attack.is_damaging(atk)
    return atk.phase == "active"
end

function Attack.is_vulnerable(atk)
    return atk.phase == "recovery"
end

-- Define boss attacks
local slam = Attack.new("slam", 0.8, 0.2, 1.0, 25, 80)
local sweep = Attack.new("sweep", 0.6, 0.3, 0.8, 15, 120)
local charge = Attack.new("charge", 1.0, 0.5, 1.2, 30, 200)
local barrage = Attack.new("barrage", 0.4, 1.0, 0.6, 10, 150)
```

**The telegraph duration IS the difficulty knob.** A 1.2-second telegraph is generous — even beginners can react. A 0.3-second telegraph demands fast reactions and pattern memorization. Tune the telegraph for your target difficulty. Many games make telegraphs longer in easy mode and shorter in hard mode while keeping everything else identical.

---

## 3. Pattern Choreography — Rhythm and Variation

A boss fight should have **rhythm** — a repeating cycle of tension and relief. The basic rhythm is: **telegraph → dodge → punish → breathe → telegraph**. The player is never relaxed (the next attack is always coming) but always has moments to act.

**Attack patterns** define the sequence of attacks. Instead of randomly choosing attacks, bosses cycle through designed sequences:

```lua
-- Lua — Attack pattern system
local patterns = {
    -- Phase 1: Simple patterns, one attack at a time
    phase1 = {
        { "slam", "pause", "slam", "pause", "sweep" },
        { "sweep", "pause", "charge" },
    },
    -- Phase 2: Faster, combinations
    phase2 = {
        { "slam", "sweep", "pause", "charge" },
        { "sweep", "sweep", "slam", "pause", "barrage" },
    },
    -- Phase 3: Relentless
    phase3 = {
        { "charge", "slam", "sweep", "barrage", "slam" },
    },
}

local current_pattern = {}
local pattern_index = 1
local pause_timer = 0

function choose_pattern(phase)
    local pool = patterns["phase" .. phase]
    current_pattern = pool[love.math.random(#pool)]
    pattern_index = 1
end

function next_in_pattern(boss, dt)
    if #current_pattern == 0 then return end

    if pause_timer > 0 then
        pause_timer = pause_timer - dt
        return
    end

    local entry = current_pattern[pattern_index]
    if entry == "pause" then
        pause_timer = 1.0 / (boss.attack_speed_mult or 1)
        pattern_index = pattern_index + 1
    else
        -- Start the attack
        start_attack(boss, entry)
        pattern_index = pattern_index + 1
    end

    -- Pattern complete? Choose a new one
    if pattern_index > #current_pattern then
        pause_timer = 1.5 / (boss.attack_speed_mult or 1)  -- breathing room between patterns
        choose_pattern(boss.phase)
    end
end
```

**The "pause" is not nothing.** The pause between attacks is where the player heals, repositions, and attacks. It's as designed as the attacks themselves. Too short = exhausting. Too long = boring. Phase transitions adjust pause duration to control the pacing.

**Variation prevents memorization fatigue.** Having 2-3 patterns per phase means the player can't fully predict the next attack, but each pattern is learnable. Random attacks feel chaotic. Fixed sequences feel repetitive. Multiple learnable patterns hit the sweet spot.

---

## 4. Vulnerability Windows — Rewarding the Player

The boss must have clear moments where the player can deal damage. These **vulnerability windows** are the payoff for successfully reading and dodging attacks. Without them, the player just survives until the boss dies of natural causes. With them, the player feels active — they're *earning* the kill.

Common vulnerability window patterns:

| Pattern | When | Example |
|---------|------|---------|
| **Post-attack recovery** | After the boss finishes an attack | Dark Souls: most bosses have recovery frames after big swings |
| **Exposed weak point** | After a specific attack reveals it | Zelda: eye opens after a charge attack |
| **Stunned after pattern** | After completing an attack sequence | Mega Man: bosses pause after pattern cycles |
| **Environmental setup** | Player does something to create an opening | Monster Hunter: topple the monster with a trap |
| **Phase transition** | During the dramatic phase-change animation | Many games: boss is vulnerable during transformation |

```lua
-- Lua — Vulnerability window system
function Boss:is_vulnerable()
    if self.transitioning then return false end  -- invulnerable during transitions
    if self.current_attack then
        return Attack.is_vulnerable(self.current_attack)
    end
    return false  -- not vulnerable during cooldown either
end

function Boss:take_damage(amount)
    if not self:is_vulnerable() then
        amount = amount * 0.1  -- minimal chip damage when not vulnerable
    end
    self.health = math.max(0, self.health - amount)
end

-- Visual feedback for vulnerability
function Boss:draw()
    if self:is_vulnerable() then
        -- Flash white/yellow to indicate "hit me now!"
        love.graphics.setColor(1, 1, 0.5)
    elseif self.current_attack and self.current_attack.phase == "telegraph" then
        love.graphics.setColor(1, 0.3, 0.3)  -- Red during telegraph
    else
        love.graphics.setColor(0.6, 0.2, 0.2)  -- Normal boss color
    end
    love.graphics.circle("fill", self.x, self.y, 30)

    -- Health bar
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 200, 550, 400, 20)
    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", 200, 550, 400 * (self.health / self.max_health), 20)

    -- Phase indicators
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Phase " .. self.phase, 360, 530)
end
```

**Communicate vulnerability clearly.** The player must know when they can attack. Visual cues (boss glows, staggers, pants, shows a weak point), audio cues (exhaustion sound, distinct music change), and behavioral cues (boss stops moving, turns away) all signal "NOW."

---

## 5. Arena Design — The Fight Space

The boss arena isn't just a room — it's part of the fight. Arena shape, obstacles, hazards, and phase-triggered changes all contribute to the encounter design.

```
Arena Design Considerations:

┌─────────────────────────────────────┐
│  Pillars for                        │
│  cover ▓   ▓                        │
│                                     │
│     ▓        BOSS SPAWN        ▓    │
│              ★                      │
│  ▓                            ▓     │
│         PLAYER                      │
│         ENTRY →                     │
│                                     │
│  ▓         ▓            ▓      ▓    │
│        Safe zone                    │
│        (brief cover)                │
└─────────────────────────────────────┘

Phase 2: Outer ring becomes lava
Phase 3: Pillars are destroyed
```

**Arena design principles:**
- **Circular or square rooms** work best — the player can dodge in any direction without getting cornered
- **Pillars or cover points** give the player tactical options and create interesting positioning decisions
- **Phase-triggered changes** (floor sections become hazardous, walls break, new areas open) make each phase feel spatially different
- **No cheap corners** — avoid geometry where the player can get stuck and take unavoidable damage
- **Clear boundaries** — the player should always know where the arena edges are

```lua
-- Lua — Arena with phase-triggered hazards
local arena = {
    width = 600, height = 400,
    center_x = 400, center_y = 300,
    pillars = {
        { x = 300, y = 200, radius = 20, alive = true },
        { x = 500, y = 200, radius = 20, alive = true },
        { x = 300, y = 400, radius = 20, alive = true },
        { x = 500, y = 400, radius = 20, alive = true },
    },
    hazard_zones = {},
}

function arena_enter_phase(phase)
    if phase == 2 then
        -- Add hazard zones at arena edges
        arena.hazard_zones = {
            { x = arena.center_x - arena.width/2, y = arena.center_y - arena.height/2,
              w = arena.width, h = 40, damage = 5 },
            { x = arena.center_x - arena.width/2, y = arena.center_y + arena.height/2 - 40,
              w = arena.width, h = 40, damage = 5 },
        }
    elseif phase == 3 then
        -- Destroy pillars
        for _, pillar in ipairs(arena.pillars) do
            pillar.alive = false
        end
        -- More hazard zones — arena shrinks
        table.insert(arena.hazard_zones, {
            x = arena.center_x - arena.width/2, y = arena.center_y - arena.height/2,
            w = 50, h = arena.height, damage = 8,
        })
    end
end
```

---

## 6. The "No Cheap Deaths" Rule

The single most important principle in boss design: **every death must feel fair.** When the player dies, they should be able to say "I should have dodged left" or "I need to learn that pattern" — never "that was impossible" or "I had no way to see that coming."

Fairness checklist for every boss attack:
- **Is the telegraph visible and distinct?** Each attack should have a unique wind-up so the player can tell what's coming.
- **Is there enough reaction time?** The telegraph must be long enough for the player to process and respond. 0.5 seconds is tight. 0.8 seconds is generous.
- **Is the dodge actually achievable?** Test the dodge timing yourself. If you can't do it consistently, the player can't either.
- **Is the damage proportional?** A hard-to-dodge attack should deal less damage. An easy-to-dodge attack can deal more. This maintains fairness across attack types.
- **Are there recovery frames?** After the player gets hit, they need invincibility frames to prevent chain-stun-death from rapid attacks.
- **Is the camera showing the right thing?** The player must be able to see the boss and the attack indicator at all times.

```lua
-- Lua — Fairness systems
local player = {
    -- Invincibility frames after taking damage
    i_frames = 0,
    i_frame_duration = 1.0,

    -- Health with damage proportionality
    health = 100,
}

function player_take_damage(amount)
    if player.i_frames > 0 then return end  -- invulnerable
    player.health = player.health - amount
    player.i_frames = player.i_frame_duration

    -- Screen shake and hit pause for impact
    screen_shake(0.3, 5)
    hit_pause(0.08)  -- freeze both boss and player for 80ms
end

function hit_pause(duration)
    -- Brief freeze frame on hit — makes impacts feel powerful
    -- and gives the player a moment to register what happened
    game_time_scale = 0
    -- Restore after duration
end
```

---

## 7. Difficulty Through Tuning, Not Code

The same boss AI should support easy and hard modes through parameter changes, not different code paths. This is the utility AI philosophy (Module 5) applied to boss design.

```lua
-- Lua — Difficulty profiles for the same boss
local difficulty = {
    easy = {
        telegraph_mult = 1.5,    -- 50% longer telegraphs
        damage_mult = 0.6,       -- 40% less damage
        speed_mult = 0.8,        -- 20% slower
        recovery_mult = 1.4,     -- 40% longer vulnerability windows
        pattern_pause_mult = 1.3, -- 30% longer pauses between attacks
        phase_thresholds = { 0.70, 0.35 },  -- phases trigger earlier
    },
    normal = {
        telegraph_mult = 1.0,
        damage_mult = 1.0,
        speed_mult = 1.0,
        recovery_mult = 1.0,
        pattern_pause_mult = 1.0,
        phase_thresholds = { 0.75, 0.40 },
    },
    hard = {
        telegraph_mult = 0.7,    -- 30% shorter telegraphs
        damage_mult = 1.5,       -- 50% more damage
        speed_mult = 1.3,        -- 30% faster
        recovery_mult = 0.7,     -- 30% shorter vulnerability windows
        pattern_pause_mult = 0.7, -- 30% shorter pauses
        phase_thresholds = { 0.80, 0.50 },
    },
}

-- Apply difficulty to attack creation
function create_attack(name, base_telegraph, base_active, base_recovery, base_damage, range)
    local d = difficulty[current_difficulty]
    return Attack.new(
        name,
        base_telegraph * d.telegraph_mult,
        base_active,
        base_recovery * d.recovery_mult,
        base_damage * d.damage_mult,
        range
    )
end
```

This approach means one boss implementation, three difficulty levels, zero code duplication. Balance testers can adjust the difficulty tables without touching the boss logic.

---

## 8. Boss AI Architecture — Putting It Together

A complete boss uses an FSM for phases, a pattern system for attacks, and the telegraph/vulnerability system for individual attacks.

```
Boss Architecture:
┌─────────────────────────────────────┐
│ Phase FSM (top level)               │
│  Phase 1 → Phase 2 → Phase 3       │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Pattern System (per phase)      │ │
│ │  Pattern pool → select pattern  │ │
│ │  → execute attacks in sequence  │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ Attack System (per attack)  │ │ │
│ │ │  Telegraph → Active →       │ │ │
│ │ │  Recovery → Next attack     │ │ │
│ │ └─────────────────────────────┘ │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Arena System                        │
│  Phase triggers → hazard changes    │
└─────────────────────────────────────┘
```

---

## Code Walkthrough: A Complete Boss Fight

Let's build a boss with three phases, multiple attacks, telegraphs, vulnerability windows, and an arena with phase-triggered hazards.

```lua
-- Lua (LÖVE) — Complete boss fight
local boss = {
    x = 400, y = 200,
    health = 100, max_health = 100,
    phase = 1,
    -- Current attack state
    attack = nil,      -- current attack data
    atk_phase = "idle", -- "idle", "telegraph", "active", "recovery", "cooldown"
    atk_timer = 0,
    -- Pattern
    pattern = {},
    pattern_idx = 1,
    cooldown = 1.0,
    speed_mult = 1.0,
    -- Visual
    flash_timer = 0,
    shake = 0,
}

local player = {
    x = 400, y = 450,
    speed = 200,
    health = 100,
    i_frames = 0,
    radius = 10,
}

-- Attack definitions: {name, telegraph, active, recovery, damage, range, type}
local attack_defs = {
    slam    = { name="SLAM",    tel=0.8, act=0.2, rec=1.0, dmg=20, range=80,  type="circle" },
    sweep   = { name="SWEEP",   tel=0.6, act=0.3, rec=0.8, dmg=15, range=120, type="arc" },
    charge  = { name="CHARGE",  tel=1.0, act=0.4, rec=1.2, dmg=25, range=200, type="line" },
    barrage = { name="BARRAGE", tel=0.4, act=0.8, rec=0.6, dmg=8,  range=150, type="multi" },
}

local patterns = {
    [1] = {
        {"slam", 1.2, "sweep", 1.5},
        {"sweep", 1.0, "slam", 1.0, "sweep"},
    },
    [2] = {
        {"charge", 0.8, "slam", 0.6, "sweep"},
        {"sweep", "sweep", 0.5, "charge", 0.8, "barrage"},
    },
    [3] = {
        {"charge", "slam", "sweep", "barrage", 0.4, "slam"},
        {"barrage", "sweep", "charge", "slam", "sweep"},
    },
}

function pick_pattern()
    local pool = patterns[boss.phase]
    boss.pattern = pool[love.math.random(#pool)]
    boss.pattern_idx = 1
end

function love.load()
    love.window.setMode(800, 600)
    pick_pattern()
end

function love.update(dt)
    -- Player movement
    if love.keyboard.isDown("left") then player.x = player.x - player.speed * dt end
    if love.keyboard.isDown("right") then player.x = player.x + player.speed * dt end
    if love.keyboard.isDown("up") then player.y = player.y - player.speed * dt end
    if love.keyboard.isDown("down") then player.y = player.y + player.speed * dt end
    player.x = math.max(50, math.min(750, player.x))
    player.y = math.max(50, math.min(550, player.y))
    if player.i_frames > 0 then player.i_frames = player.i_frames - dt end

    -- Check phase transition
    local new_phase = 1
    local hp_pct = boss.health / boss.max_health
    if hp_pct <= 0.25 then new_phase = 3
    elseif hp_pct <= 0.60 then new_phase = 2 end

    if new_phase ~= boss.phase then
        boss.phase = new_phase
        boss.speed_mult = 1.0 + (new_phase - 1) * 0.25
        boss.atk_phase = "cooldown"
        boss.atk_timer = 2.0  -- transition pause
        boss.flash_timer = 2.0
        pick_pattern()
    end

    -- Boss attack logic
    boss.flash_timer = math.max(0, boss.flash_timer - dt)
    boss.shake = math.max(0, boss.shake - dt * 10)

    if boss.atk_phase == "idle" or boss.atk_phase == "cooldown" then
        boss.atk_timer = boss.atk_timer - dt * boss.speed_mult
        if boss.atk_timer <= 0 then
            advance_pattern()
        end
    elseif boss.atk_phase == "telegraph" then
        boss.atk_timer = boss.atk_timer - dt * boss.speed_mult
        if boss.atk_timer <= 0 then
            boss.atk_phase = "active"
            boss.atk_timer = boss.attack.act
        end
    elseif boss.atk_phase == "active" then
        boss.atk_timer = boss.atk_timer - dt * boss.speed_mult
        -- Check damage to player
        local dist = math.sqrt((boss.x-player.x)^2 + (boss.y-player.y)^2)
        if dist < boss.attack.range and player.i_frames <= 0 then
            player.health = player.health - boss.attack.dmg
            player.i_frames = 1.0
            boss.shake = 3
        end
        if boss.atk_timer <= 0 then
            boss.atk_phase = "recovery"
            boss.atk_timer = boss.attack.rec
        end
    elseif boss.atk_phase == "recovery" then
        boss.atk_timer = boss.atk_timer - dt * boss.speed_mult
        if boss.atk_timer <= 0 then
            boss.atk_phase = "cooldown"
            boss.atk_timer = 0.3 / boss.speed_mult
        end
    end
end

function advance_pattern()
    if boss.pattern_idx > #boss.pattern then
        boss.atk_timer = 1.5 / boss.speed_mult
        boss.atk_phase = "cooldown"
        pick_pattern()
        return
    end

    local entry = boss.pattern[boss.pattern_idx]
    boss.pattern_idx = boss.pattern_idx + 1

    if type(entry) == "number" then
        -- It's a pause duration
        boss.atk_timer = entry / boss.speed_mult
        boss.atk_phase = "cooldown"
    else
        -- It's an attack name
        boss.attack = attack_defs[entry]
        boss.atk_phase = "telegraph"
        boss.atk_timer = boss.attack.tel
    end
end

function love.keypressed(key)
    if key == "space" then
        -- Player attack — only damages during recovery
        local dist = math.sqrt((boss.x-player.x)^2 + (boss.y-player.y)^2)
        if dist < 60 then
            if boss.atk_phase == "recovery" then
                boss.health = math.max(0, boss.health - 8)
            else
                boss.health = math.max(0, boss.health - 1)  -- chip damage
            end
        end
    end
end

function love.draw()
    local sx = boss.shake > 0 and (love.math.random() - 0.5) * boss.shake or 0

    -- Arena
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Phase 2+ hazard zones
    if boss.phase >= 2 then
        love.graphics.setColor(0.4, 0.1, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, 800, 40)
        love.graphics.rectangle("fill", 0, 560, 800, 40)
    end

    -- Telegraph indicator
    if boss.atk_phase == "telegraph" and boss.attack then
        love.graphics.setColor(1, 0, 0, 0.2 + 0.3 * math.sin(love.timer.getTime() * 10))
        love.graphics.circle("line", boss.x + sx, boss.y, boss.attack.range)
        love.graphics.circle("fill", boss.x + sx, boss.y, boss.attack.range * 0.3)
    end

    -- Boss
    if boss.flash_timer > 0 then
        love.graphics.setColor(1, 1, 1)
    elseif boss.atk_phase == "recovery" then
        love.graphics.setColor(1, 1, 0.3)  -- vulnerable = yellow
    elseif boss.atk_phase == "active" then
        love.graphics.setColor(1, 0.2, 0.2)
    elseif boss.atk_phase == "telegraph" then
        love.graphics.setColor(0.8, 0.4, 0.1)
    else
        love.graphics.setColor(0.5, 0.1, 0.1)
    end
    love.graphics.circle("fill", boss.x + sx, boss.y, 25)

    -- Player
    if player.i_frames > 0 and math.floor(player.i_frames * 10) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.3)  -- flash during i-frames
    else
        love.graphics.setColor(0.2, 0.6, 1)
    end
    love.graphics.circle("fill", player.x, player.y, player.radius)

    -- Boss health bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 150, 20, 500, 16)
    local hp_color = boss.phase == 1 and {0.8,0.1,0.1} or
                     boss.phase == 2 and {0.9,0.5,0.1} or {0.9,0.2,0.5}
    love.graphics.setColor(hp_color)
    love.graphics.rectangle("fill", 150, 20, 500 * (boss.health/boss.max_health), 16)

    -- HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Phase " .. boss.phase .. " | " ..
        (boss.attack and boss.attack.name or "---") .. " | " ..
        boss.atk_phase, 10, 560)
    love.graphics.print("Player HP: " .. player.health ..
        " | Arrow keys to move, SPACE to attack", 10, 580)
end
```

---

## Common Pitfalls

### 1. No telegraph on fast attacks

The boss has a quick jab with no wind-up animation. The player gets hit with no chance to react. Every attack needs a telegraph, even fast ones — a 0.3-second visual flash is enough to make a quick attack feel fair.

### 2. Vulnerability windows too short or nonexistent

The boss recovers instantly and starts the next attack. The player survives but can never deal damage, leading to a boring attrition fight. Recovery windows should be at least 0.5-1.0 seconds — enough for 1-3 player attacks.

### 3. Phase transitions without invulnerability

The boss hits 75% health and starts Phase 2, but the player is mid-combo and kills the boss before the new attacks begin. Add brief invulnerability during phase transitions so the player experiences each phase.

### 4. All attacks having the same dodge strategy

Every attack is dodged by rolling left. The player learns one pattern and autopilots. Design attacks with different dodge strategies: roll sideways for sweeps, jump for ground slams, move away for area attacks, close in for ranged barrages.

### 5. Damage that feels random or unavoidable

The player dies and doesn't understand what hit them. This is a communication failure. Slow down the replay in your mind: what telegraph did the player miss? If there wasn't one, add one. If there was one but it was unclear, make it bigger/louder/more distinct.

### 6. Boss that never attacks the player's position

The boss mechanically alternates between fixed positions regardless of where the player is. Boss attacks should generally target the player's position (or predicted position) while allowing enough telegraph time to dodge. The boss should feel like it's fighting *you*, not performing a routine.

---

## Exercises

### Exercise 1: Three-Phase Boss on Paper
**Time:** 45-60 minutes

Design a boss encounter on paper. For each of 3 phases, define:
- 3-4 attacks with: telegraph visual, telegraph duration, active duration, recovery duration, damage, range, and dodge strategy
- 2 attack patterns (sequences of attacks and pauses)
- Arena changes (if any)
- Phase transition trigger and animation

Draw the arena and annotate safe zones, hazard zones, and how they change per phase.

**Concepts practiced:** Boss design, telegraph design, phase pacing, arena layout

**Stretch goal:** Calculate the DPS (damage per second) the player deals during vulnerability windows. How many pattern cycles does each phase take? Does the fight feel the right length (2-5 minutes)?

---

### Exercise 2: Implement Phase 1
**Time:** 2-3 hours

Implement the first phase of your boss design (or the code walkthrough boss). Requirements:

1. Boss cycles through a pattern of 3 attacks
2. Each attack has a visible telegraph (colored circle, flash, or indicator)
3. Each attack has a recovery window where the boss is visually vulnerable
4. Player can only deal full damage during vulnerability windows
5. Display the boss's health bar and current attack phase

**Concepts practiced:** Attack system, telegraph implementation, vulnerability windows, phase state machine

**Stretch goal:** Add screen shake on player hit and hit pause (brief time freeze) on successful player attacks. These juice elements make the fight feel impactful.

---

### Exercise 3: Full Boss Fight
**Time:** 3-4 hours

Extend Exercise 2 to a complete 3-phase boss fight:

1. Three phases triggered by health thresholds
2. Phase transitions with invulnerability and visual drama
3. Each phase adds new attacks or speeds up existing ones
4. Arena changes in later phases (hazard zones, destroyed cover)
5. Phase 3 should feel like a final push — faster, more intense, but still fair

**Concepts practiced:** Full boss architecture, phase design, difficulty escalation, arena design

**Stretch goal:** Add a difficulty selector that only changes numerical parameters (telegraph timing, damage, speed) without changing any code paths.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| "Boss Battle Design and Structure" from *Game AI Pro* | Book chapter (free) | Practical patterns for phase-based boss design with production examples |
| *Game Feel* by Steve Swink | Book | Attack impact, hit pause, and screen shake — essential for making boss fights feel powerful |
| "What Makes a Good Boss Fight" articles on Game Developer | Articles | Multiple excellent postmortems of boss design in commercial games |
| Hollow Knight / Dark Souls boss analysis videos | Video | Deep community analysis of beloved boss fights — telegraph timing, pattern design, fairness |
| "Designing Boss Fights" GDC talks | GDC talks | Various studios sharing their boss design philosophies and techniques |

---

## Key Takeaways

1. **Boss AI is choreography, not intelligence.** The boss isn't trying to win. It's creating a learnable, escalating performance that tests the player's mastery.

2. **Phases prevent monotony and enable teaching.** Phase 1 teaches attacks individually. Phase 2 combines them. Phase 3 tests everything at higher intensity. Each phase is a new puzzle building on the last.

3. **Telegraphs are the fairness contract.** Every attack must be readable. The telegraph duration is the primary difficulty tuning knob. Longer = easier. Shorter = harder.

4. **Vulnerability windows are the player's reward.** The player must have clear moments to deal damage. These windows are earned by correctly reading and dodging attacks.

5. **Arena design is part of the fight.** Cover, hazards, spatial changes across phases, and clear boundaries all contribute to the encounter. The room is a character in the fight.

6. **Every death must feel fair.** If the player dies and says "that was BS," you have a design bug. Slow down, add telegraphs, lengthen reaction windows, and communicate better.

---

## What's Next?

You now have the tools to create memorable encounters — from common enemies (Modules 1-3) to complex squad combat (Module 8) to solo boss fights (this module). The final module brings it all together.

In [Module 10: Debugging, Tuning & The Craft](module-10-debugging-tuning-craft.md), you'll learn the meta-skills that separate functional AI from *great* AI — debug visualization, performance budgeting, intentional imperfection, and the "fun first" philosophy. This is the capstone that transforms technical knowledge into craft.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
