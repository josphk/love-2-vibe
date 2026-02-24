-- weapons.lua
-- Auto-firing weapon system.  Each weapon has multiple upgrade levels,
-- a cooldown, and produces projectiles / area effects automatically.
--
-- Weapon categories:
--   projectile  — moves in a direction, damages enemies it touches
--   area        — static or player-following area that ticks damage
--   orbital     — circles around the player
--   targeted    — instant strike on a random nearby enemy

local Utils = require("utils")

local Weapons = {}
Weapons.__index = Weapons

--------------------------------------------------------------------------------
-- Active projectile / effect pool  (shared across all weapons)
--------------------------------------------------------------------------------
Weapons.projectiles = {}   -- filled at runtime

--------------------------------------------------------------------------------
-- Weapon definitions
-- Each entry: name, desc, icon (text char), maxLevel, levels (stat per lv),
-- and a fire() function that creates projectiles.
--------------------------------------------------------------------------------
local DEFS = {}

---------- 1. MAGIC WAND ----------
DEFS.wand = {
    name = "Magic Wand",
    desc = "Fires a bolt at the nearest enemy",
    icon = "◆",
    maxLevel = 5,
    levels = {
        { damage = 10, cooldown = 1.2, count = 1, pierce = 0, speed = 350 },
        { damage = 15, cooldown = 1.1, count = 1, pierce = 1, speed = 360 },
        { damage = 15, cooldown = 1.0, count = 2, pierce = 1, speed = 380 },
        { damage = 22, cooldown = 0.9, count = 2, pierce = 2, speed = 400 },
        { damage = 28, cooldown = 0.7, count = 3, pierce = 3, speed = 420 },
    },
    levelDescs = {
        "Base weapon",
        "+Damage, +Pierce",
        "+Projectile",
        "+Damage, +Pierce",
        "+Projectile, -Cooldown",
    },
    fire = function(w, player, enemies)
        local s = w.stats
        for i = 1, s.count do
            local target = Utils.findNearest(player.x, player.y, enemies)
            if target then
                local a = Utils.angleTo(player.x, player.y, target.x, target.y)
                -- Slight spread for multi-shot
                a = a + (i - (s.count + 1) / 2) * 0.15
                table.insert(Weapons.projectiles, {
                    x = player.x, y = player.y,
                    vx = math.cos(a) * s.speed,
                    vy = math.sin(a) * s.speed,
                    damage = math.floor(s.damage * player.mightMult),
                    radius = 5,
                    pierce = s.pierce,
                    lifetime = 2.5,
                    age = 0,
                    visual = "orb",
                    r = 0.4, g = 0.7, b = 1.0,
                    dead = false,
                    hitSet = {},
                })
            end
        end
    end,
}

---------- 2. HOLY WHIP ----------
DEFS.whip = {
    name = "Holy Whip",
    desc = "Slashes the area in front of you",
    icon = "━",
    maxLevel = 5,
    levels = {
        { damage = 18, cooldown = 1.3, width = 70,  height = 24 },
        { damage = 25, cooldown = 1.2, width = 85,  height = 28 },
        { damage = 25, cooldown = 1.1, width = 100, height = 32 },
        { damage = 35, cooldown = 1.0, width = 120, height = 36 },
        { damage = 45, cooldown = 0.8, width = 140, height = 40 },
    },
    levelDescs = {
        "Base weapon",
        "+Damage, +Area",
        "+Area",
        "+Damage, +Area, -Cooldown",
        "+Damage, +Area, -Cooldown",
    },
    fire = function(w, player, enemies)
        local s = w.stats
        local hw = s.width * player.areaMult / 2
        local hh = s.height * player.areaMult / 2
        local cx = player.x + player.facing * (hw + 8)
        local cy = player.y
        table.insert(Weapons.projectiles, {
            x = cx, y = cy,
            vx = 0, vy = 0,
            damage = math.floor(s.damage * player.mightMult),
            radius = math.max(hw, hh),   -- rough circle for collision
            pierce = 999,
            lifetime = 0.2,
            age = 0,
            visual = "whip",
            hw = hw, hh = hh,
            facing = player.facing,
            r = 1.0, g = 0.95, b = 0.6,
            dead = false,
            hitSet = {},
            knockback = 200,
        })
    end,
}

---------- 3. GARLIC AURA ----------
DEFS.garlic = {
    name = "Garlic Aura",
    desc = "Damages nearby enemies continuously",
    icon = "◎",
    maxLevel = 5,
    levels = {
        { damage = 3,  cooldown = 0.45, auraRadius = 55  },
        { damage = 4,  cooldown = 0.40, auraRadius = 65  },
        { damage = 5,  cooldown = 0.35, auraRadius = 75  },
        { damage = 7,  cooldown = 0.30, auraRadius = 90  },
        { damage = 10, cooldown = 0.25, auraRadius = 110 },
    },
    levelDescs = {
        "Base weapon",
        "+Damage, +Area, -Cooldown",
        "+Damage, +Area, -Cooldown",
        "+Damage, +Area, -Cooldown",
        "+Damage, +Area, -Cooldown",
    },
    fire = function(w, player, enemies)
        local s = w.stats
        local rad = s.auraRadius * player.areaMult
        table.insert(Weapons.projectiles, {
            x = player.x, y = player.y,
            vx = 0, vy = 0,
            damage = math.floor(s.damage * player.mightMult),
            radius = rad,
            pierce = 999,
            lifetime = 0.15,
            age = 0,
            visual = "garlic",
            r = 0.6, g = 1.0, b = 0.5,
            dead = false,
            hitSet = {},
            knockback = 120,
            followPlayer = true,
        })
    end,
}

---------- 4. THROWING AXE ----------
DEFS.axe = {
    name = "Throwing Axe",
    desc = "Lobs axes that pass through enemies",
    icon = "⚔",
    maxLevel = 5,
    levels = {
        { damage = 22, cooldown = 1.6, count = 1, speed = 250, pierce = 3 },
        { damage = 28, cooldown = 1.5, count = 1, speed = 270, pierce = 5 },
        { damage = 28, cooldown = 1.4, count = 2, speed = 280, pierce = 5 },
        { damage = 35, cooldown = 1.2, count = 2, speed = 300, pierce = 8 },
        { damage = 45, cooldown = 1.0, count = 3, speed = 320, pierce = 99 },
    },
    levelDescs = {
        "Base weapon",
        "+Damage, +Pierce",
        "+Count",
        "+Damage, +Pierce, -Cooldown",
        "+Count, +Pierce, -Cooldown",
    },
    fire = function(w, player, enemies)
        local s = w.stats
        for i = 1, s.count do
            local angle = -math.pi / 2 + (math.random() - 0.5) * 0.8
            table.insert(Weapons.projectiles, {
                x = player.x, y = player.y,
                vx = math.cos(angle) * s.speed * (0.8 + math.random() * 0.4),
                vy = math.sin(angle) * s.speed,
                ay = 180,   -- gravity pulls it into an arc
                damage = math.floor(s.damage * player.mightMult),
                radius = 10 * player.areaMult,
                pierce = s.pierce,
                lifetime = 3.0,
                age = 0,
                visual = "axe",
                r = 0.8, g = 0.6, b = 0.3,
                dead = false,
                hitSet = {},
                rotation = 0,
            })
        end
    end,
}

---------- 5. KING BIBLE ----------
DEFS.bible = {
    name = "King Bible",
    desc = "Holy books orbit around you",
    icon = "▣",
    maxLevel = 5,
    levels = {
        { damage = 8,  cooldown = 4.0, count = 1, orbitR = 70,  duration = 3.0, orbitSpeed = 3.5 },
        { damage = 10, cooldown = 3.8, count = 2, orbitR = 75,  duration = 3.2, orbitSpeed = 3.8 },
        { damage = 12, cooldown = 3.5, count = 2, orbitR = 80,  duration = 3.5, orbitSpeed = 4.0 },
        { damage = 15, cooldown = 3.0, count = 3, orbitR = 90,  duration = 4.0, orbitSpeed = 4.2 },
        { damage = 20, cooldown = 2.5, count = 4, orbitR = 100, duration = 5.0, orbitSpeed = 4.5 },
    },
    levelDescs = {
        "Base weapon",
        "+Count, +Duration",
        "+Damage, +Duration",
        "+Count, +Damage, +Duration",
        "+All stats",
    },
    fire = function(w, player, enemies)
        local s = w.stats
        local rad = s.orbitR * player.areaMult
        for i = 1, s.count do
            local startAngle = (i / s.count) * math.pi * 2
            table.insert(Weapons.projectiles, {
                x = player.x, y = player.y,
                vx = 0, vy = 0,
                damage = math.floor(s.damage * player.mightMult),
                radius = 10,
                pierce = 999,
                lifetime = s.duration,
                age = 0,
                visual = "bible",
                r = 0.9, g = 0.85, b = 0.4,
                dead = false,
                hitSet = {},
                hitCooldown = 0.3,   -- can re-hit same enemy after this delay
                orbitR = rad,
                orbitSpeed = s.orbitSpeed,
                orbitAngle = startAngle,
                followPlayer = true,
            })
        end
    end,
}

---------- 6. LIGHTNING RING ----------
DEFS.lightning = {
    name = "Lightning Ring",
    desc = "Strikes a random nearby enemy",
    icon = "⚡",
    maxLevel = 5,
    levels = {
        { damage = 25, cooldown = 2.5, count = 1, range = 250 },
        { damage = 30, cooldown = 2.2, count = 1, range = 280 },
        { damage = 30, cooldown = 2.0, count = 2, range = 300 },
        { damage = 40, cooldown = 1.8, count = 2, range = 340 },
        { damage = 55, cooldown = 1.4, count = 3, range = 400 },
    },
    levelDescs = {
        "Base weapon",
        "+Damage, -Cooldown",
        "+Count",
        "+Damage, -Cooldown, +Range",
        "+All stats",
    },
    fire = function(w, player, enemies)
        local s = w.stats
        -- Collect enemies within range
        local inRange = {}
        for _, e in ipairs(enemies) do
            if not e.dead then
                local d = Utils.distance(player.x, player.y, e.x, e.y)
                if d <= s.range * player.areaMult then
                    table.insert(inRange, e)
                end
            end
        end
        Utils.shuffle(inRange)
        local hits = math.min(s.count, #inRange)
        for i = 1, hits do
            local e = inRange[i]
            local dmg = math.floor(s.damage * player.mightMult)
            -- Create a visual-only lightning bolt projectile
            table.insert(Weapons.projectiles, {
                x = e.x, y = e.y - 300,
                vx = 0, vy = 0,
                damage = 0,  -- damage applied directly below
                radius = 0,
                pierce = 0,
                lifetime = 0.25,
                age = 0,
                visual = "lightning",
                targetX = e.x, targetY = e.y,
                r = 0.8, g = 0.8, b = 1.0,
                dead = false,
                hitSet = {},
            })
            -- Apply damage directly
            e:takeDamage(dmg)
            e:applyKnockback(player.x, player.y, 80)
        end
    end,
}

--------------------------------------------------------------------------------
-- Weapon instance constructor
--------------------------------------------------------------------------------

--- Create a new weapon instance from a definition key.
function Weapons.create(key)
    local def = DEFS[key]
    assert(def, "Unknown weapon: " .. tostring(key))
    return {
        key      = key,
        def      = def,
        level    = 1,
        timer    = def.levels[1].cooldown * 0.5,  -- start half-ready
        stats    = def.levels[1],
    }
end

--- Level up an existing weapon instance. Returns true if successful.
function Weapons.levelUp(weapon)
    if weapon.level >= weapon.def.maxLevel then return false end
    weapon.level = weapon.level + 1
    weapon.stats = weapon.def.levels[weapon.level]
    return true
end

--------------------------------------------------------------------------------
-- Update all weapons on a player (fire when ready).
--------------------------------------------------------------------------------
function Weapons.updatePlayer(player, enemies, dt)
    for _, w in ipairs(player.weapons) do
        w.timer = w.timer - dt * (1 / math.max(0.1, player.cooldownMult))
        if w.timer <= 0 then
            w.timer = w.stats.cooldown
            w.def.fire(w, player, enemies)
        end
    end
end

--------------------------------------------------------------------------------
-- Update all active projectiles.
--------------------------------------------------------------------------------
function Weapons.updateProjectiles(dt, player, enemies, particles)
    local projs = Weapons.projectiles
    for _, p in ipairs(projs) do
        if not p.dead then
            p.age = p.age + dt

            -- Follow player (garlic, bible)
            if p.followPlayer then
                if p.orbitAngle then
                    -- Orbital movement (bible)
                    p.orbitAngle = p.orbitAngle + p.orbitSpeed * dt
                    p.x = player.x + math.cos(p.orbitAngle) * p.orbitR
                    p.y = player.y + math.sin(p.orbitAngle) * p.orbitR
                else
                    -- Stick to player (garlic)
                    p.x = player.x
                    p.y = player.y
                end
            else
                -- Normal movement
                if p.ay then
                    p.vy = (p.vy or 0) + p.ay * dt
                end
                p.x = p.x + (p.vx or 0) * dt
                p.y = p.y + (p.vy or 0) * dt
            end

            -- Axe rotation
            if p.rotation then
                p.rotation = p.rotation + 12 * dt
            end

            -- Lifetime
            if p.age >= p.lifetime then
                p.dead = true
            end

            -- Collision with enemies
            if not p.dead and p.radius > 0 then
                for _, e in ipairs(enemies) do
                    if not e.dead then
                        -- Check hit cooldown per-enemy (for piercing / orbiting weapons)
                        local eid = tostring(e)
                        local lastHit = p.hitSet[eid]
                        local canHit = true
                        if lastHit then
                            if p.hitCooldown then
                                canHit = (p.age - lastHit) >= p.hitCooldown
                            else
                                canHit = false  -- already hit, no re-hit
                            end
                        end

                        if canHit and Utils.circlesOverlap(p.x, p.y, p.radius, e.x, e.y, e.radius) then
                            p.hitSet[eid] = p.age
                            local killed = e:takeDamage(p.damage)
                            if p.knockback then
                                e:applyKnockback(p.x, p.y, p.knockback)
                            end
                            particles:spark(e.x, e.y, p.r, p.g, p.b)
                            particles:damageNumber(e.x, e.y - 12, p.damage, 1, 1, 0.3)

                            if not p.hitCooldown then
                                p.pierce = p.pierce - 1
                                if p.pierce < 0 then
                                    p.dead = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Sweep dead projectiles
    if #projs > 100 then Utils.sweep(projs) end
end

--------------------------------------------------------------------------------
-- Draw all active projectiles (inside camera transform).
--------------------------------------------------------------------------------
function Weapons.drawProjectiles()
    for _, p in ipairs(Weapons.projectiles) do
        if not p.dead then
            local alpha = 1
            -- Fade out near end of life
            if p.lifetime - p.age < 0.3 then
                alpha = (p.lifetime - p.age) / 0.3
            end

            if p.visual == "orb" then
                love.graphics.setColor(p.r, p.g, p.b, 0.3 * alpha)
                love.graphics.circle("fill", p.x, p.y, p.radius * 2)
                love.graphics.setColor(p.r, p.g, p.b, 0.9 * alpha)
                love.graphics.circle("fill", p.x, p.y, p.radius)
                love.graphics.setColor(1, 1, 1, 0.6 * alpha)
                love.graphics.circle("fill", p.x, p.y, p.radius * 0.4)

            elseif p.visual == "whip" then
                love.graphics.setColor(p.r, p.g, p.b, 0.7 * alpha)
                love.graphics.rectangle("fill",
                    p.x - p.hw, p.y - p.hh, p.hw * 2, p.hh * 2, 3, 3)
                love.graphics.setColor(1, 1, 1, 0.4 * alpha)
                love.graphics.rectangle("fill",
                    p.x - p.hw * 0.8, p.y - p.hh * 0.5,
                    p.hw * 1.6, p.hh, 2, 2)

            elseif p.visual == "garlic" then
                love.graphics.setColor(p.r, p.g, p.b, 0.12 * alpha)
                love.graphics.circle("fill", p.x, p.y, p.radius)
                love.graphics.setColor(p.r, p.g, p.b, 0.35 * alpha)
                love.graphics.circle("line", p.x, p.y, p.radius)

            elseif p.visual == "axe" then
                love.graphics.push()
                love.graphics.translate(p.x, p.y)
                love.graphics.rotate(p.rotation or 0)
                love.graphics.setColor(p.r, p.g, p.b, 0.9 * alpha)
                love.graphics.rectangle("fill", -6, -8, 12, 16, 2, 2)
                love.graphics.setColor(0.6, 0.6, 0.6, 0.8 * alpha)
                love.graphics.rectangle("fill", -4, -10, 8, 6, 1, 1)
                love.graphics.pop()

            elseif p.visual == "bible" then
                love.graphics.push()
                love.graphics.translate(p.x, p.y)
                love.graphics.rotate(p.age * 5)
                love.graphics.setColor(p.r, p.g, p.b, 0.85 * alpha)
                love.graphics.rectangle("fill", -5, -7, 10, 14, 1, 1)
                love.graphics.setColor(1, 1, 1, 0.5 * alpha)
                love.graphics.line(-3, -4, 3, -4)
                love.graphics.line(0, -6, 0, 0)
                love.graphics.pop()

            elseif p.visual == "lightning" then
                love.graphics.setColor(p.r, p.g, p.b, alpha)
                love.graphics.setLineWidth(2)
                -- Jagged bolt from top to target
                local tx, ty = p.targetX, p.targetY
                local sx, sy = tx + (math.random() - 0.5) * 20, ty - 300
                local segments = 6
                local prevX, prevY = sx, sy
                for i = 1, segments do
                    local t = i / segments
                    local nx = Utils.lerp(sx, tx, t) + (math.random() - 0.5) * 18
                    local ny = Utils.lerp(sy, ty, t)
                    love.graphics.line(prevX, prevY, nx, ny)
                    prevX, prevY = nx, ny
                end
                love.graphics.setLineWidth(1)
                -- Flash at impact
                love.graphics.setColor(1, 1, 1, 0.5 * alpha)
                love.graphics.circle("fill", tx, ty, 12 * alpha)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Expose definitions for level-up screen
--------------------------------------------------------------------------------
Weapons.DEFS = DEFS

--- List of all weapon keys.
Weapons.ALL_KEYS = {}
for k in pairs(DEFS) do table.insert(Weapons.ALL_KEYS, k) end
table.sort(Weapons.ALL_KEYS)

return Weapons
