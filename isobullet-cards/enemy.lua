-- enemy.lua
-- Arena enemies that fire bullet patterns on the isometric grid.
-- 6 types: Turret, Spinner, Orbiter, Bouncer (NEW), Heavy, Dasher.
-- Turrets only fire when they have line-of-sight to the player.
-- All positions/movement in grid-space.

local Map      = require("map")
local Utils    = require("utils")
local Patterns = require("patterns")

local Enemy = {}
Enemy.__index = Enemy

local PIXEL_SCALE = Map.TILE_W / 2   -- grid→pixel for draw radius

--------------------------------------------------------------------------------
-- Type definitions
--------------------------------------------------------------------------------
local DEFS = {}

-- TURRET: stationary, aimed bursts — only fires with line-of-sight
DEFS.turret = {
    hp = 30, radius = 0.5, score = 200,
    cr = 1.0, cg = 0.55, cb = 0.15,
    fireInterval = 1.8,
    shape = "diamond",
    needsLOS = true,
    pattern = function(self, pool, px, py)
        Patterns.aimedBurst(pool, self, px, py, { count = 5, speed = 7.5, spread = 0.4 })
    end,
    move = function() end,
}

-- SPINNER: rotating spiral arms — always fires
DEFS.spinner = {
    hp = 50, radius = 0.55, score = 350,
    cr = 0.3, cg = 0.95, cb = 0.4,
    fireInterval = 0.12,
    shape = "circle",
    needsLOS = false,
    pattern = function(self, pool)
        Patterns.spiral(pool, self, { arms = 3, speed = 4.5, offset = self.age * 2.8 })
    end,
    move = function(self, dt)
        if self.targetX then
            self.x = Utils.lerp(self.x, self.targetX, dt * 0.8)
            self.y = Utils.lerp(self.y, self.targetY, dt * 0.8)
        end
    end,
}

-- ORBITER: circles a point, radial bursts
DEFS.orbiter = {
    hp = 25, radius = 0.45, score = 250,
    cr = 0.3, cg = 0.5, cb = 1.0,
    fireInterval = 1.5,
    shape = "circle",
    needsLOS = false,
    pattern = function(self, pool)
        Patterns.radialBurst(pool, self, { count = 14, speed = 5.0, offset = self.age })
    end,
    move = function(self, dt)
        local cx = self.orbitCX or 12
        local cy = self.orbitCY or 6
        local r  = self.orbitR  or 3
        self.orbitAngle = (self.orbitAngle or 0) + dt * 1.2
        local nx = cx + math.cos(self.orbitAngle) * r
        local ny = cy + math.sin(self.orbitAngle) * r
        if not Map.isWall(nx, ny) then
            self.x, self.y = nx, ny
        end
    end,
}

-- BOUNCER (NEW): fires bullets with extra bounces — exploits reflection
DEFS.bouncer = {
    hp = 40, radius = 0.5, score = 300,
    cr = 0.95, cg = 0.8, cb = 0.15,
    fireInterval = 1.3,
    shape = "diamond",
    needsLOS = false,
    pattern = function(self, pool)
        Patterns.radialBurst(pool, self, {
            count = 8, speed = 6.0,
            maxBounces = 5,    -- many bounces!
            offset = self.age * 0.5,
            r = 0.95, g = 0.8, b = 0.15,
        })
    end,
    move = function(self, dt)
        if self.targetX then
            self.x = Utils.lerp(self.x, self.targetX, dt * 0.5)
            self.y = Utils.lerp(self.y, self.targetY, dt * 0.5)
        end
    end,
}

-- HEAVY: slow, alternates expanding rings / shotgun / spin spirals
DEFS.heavy = {
    hp = 80, radius = 0.7, score = 500,
    cr = 0.75, cg = 0.25, cb = 0.85,
    fireInterval = 1.6,
    shape = "hexagon",
    needsLOS = false,
    pattern = function(self, pool, px, py)
        if self.phase % 3 == 0 then
            Patterns.expandRing(pool, self, { count = 18, speed = 1.0, accel = 4.0 })
        elseif self.phase % 3 == 1 then
            Patterns.shotgun(pool, self, px, py, { count = 10, speed = 7.5 })
        else
            Patterns.spinSpiral(pool, self, { arms = 4, speed = 3.5, spin = 1.5, offset = self.age })
        end
        self.phase = self.phase + 1
    end,
    move = function(self, dt)
        if self.targetX then
            self.x = Utils.lerp(self.x, self.targetX, dt * 0.3)
            self.y = Utils.lerp(self.y, self.targetY, dt * 0.3)
        end
    end,
}

-- DASHER: fast movement between floor positions, aimed bursts
DEFS.dasher = {
    hp = 20, radius = 0.4, score = 300,
    cr = 0.2, cg = 0.9, cb = 0.95,
    fireInterval = 0.8,
    shape = "triangle",
    needsLOS = true,
    pattern = function(self, pool, px, py)
        Patterns.aimedBurst(pool, self, px, py, { count = 7, speed = 8.0, spread = 0.5 })
    end,
    move = function(self, dt)
        self.dashTimer = (self.dashTimer or 0) - dt
        if self.dashTimer <= 0 then
            -- Pick random floor position in upper half of map
            for _ = 1, 20 do
                local tx = 3 + math.random() * (Map.GW - 5)
                local ty = 3 + math.random() * (Map.GH - 5)
                if not Map.isWall(tx, ty) then
                    self.targetX = tx
                    self.targetY = ty
                    break
                end
            end
            self.dashTimer = 1.5 + math.random()
        end
        if self.targetX then
            local dx = self.targetX - self.x
            local dy = self.targetY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0.3 then
                local speed = 4.0
                local nx = self.x + (dx / dist) * speed * dt
                local ny = self.y + (dy / dist) * speed * dt
                if not Map.isWall(nx, ny) then
                    self.x, self.y = nx, ny
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Enemy.new(typeName, x, y)
    local def = DEFS[typeName]
    assert(def, "Unknown enemy type: " .. tostring(typeName))
    local self = setmetatable({}, Enemy)
    self.typeName = typeName
    self.x, self.y = x, y
    self.hp = def.hp
    self.maxHp = def.hp
    self.radius = def.radius           -- grid units (collision)
    self.drawRadius = def.radius * PIXEL_SCALE  -- pixels (rendering)
    self.score = def.score
    self.cr, self.cg, self.cb = def.cr, def.cg, def.cb
    self.shape = def.shape
    self.needsLOS = def.needsLOS
    self.patternFunc = def.pattern
    self.moveFunc = def.move
    self.fireInterval = def.fireInterval
    self.fireTimer = def.fireInterval * (0.3 + math.random() * 0.5)
    self.phase = 0
    self.age = 0
    self.dead = false
    self.scored = false
    self.hitFlash = 0

    -- Movement state
    self.targetX, self.targetY = nil, nil
    self.orbitCX, self.orbitCY = nil, nil
    self.orbitR = nil
    self.orbitAngle = math.random() * math.pi * 2
    self.dashTimer = 0

    return self
end

function Enemy:update(dt, bulletPool, playerX, playerY)
    if self.dead then return end
    self.age = self.age + dt
    if self.hitFlash > 0 then self.hitFlash = self.hitFlash - dt end

    -- Movement
    self.moveFunc(self, dt)

    -- Clamp within map bounds (floor area)
    self.x = Utils.clamp(self.x, 2, Map.GW - 1)
    self.y = Utils.clamp(self.y, 2, Map.GH - 1)

    -- Fire pattern
    self.fireTimer = self.fireTimer - dt
    if self.fireTimer <= 0 then
        self.fireTimer = self.fireInterval
        -- LOS check for aimed enemies
        if self.needsLOS then
            if Map.lineOfSight(self.x, self.y, playerX, playerY) then
                self.patternFunc(self, bulletPool, playerX, playerY)
            end
        else
            self.patternFunc(self, bulletPool, playerX, playerY)
        end
    end
end

function Enemy:takeDamage(dmg)
    if self.dead then return false end
    self.hp = self.hp - dmg
    self.hitFlash = 0.12
    if self.hp <= 0 then self.dead = true; return true end
    return false
end

function Enemy:draw()
    if self.dead then return end

    local sx, sy = Map.gridToScreen(self.x, self.y)
    local rad = self.drawRadius
    local flash = self.hitFlash > 0
    local r, g, b = self.cr, self.cg, self.cb
    if flash then r, g, b = 1, 1, 1 end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", sx, sy + rad * 0.4, rad * 0.8, rad * 0.3)

    -- Shape
    if self.shape == "diamond" then
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.polygon("fill",
            sx, sy - rad, sx + rad, sy, sx, sy + rad, sx - rad, sy)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.polygon("line",
            sx, sy - rad, sx + rad, sy, sx, sy + rad, sx - rad, sy)
    elseif self.shape == "circle" then
        love.graphics.setColor(r, g, b, 0.85)
        love.graphics.circle("fill", sx, sy, rad)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.circle("line", sx, sy, rad)
    elseif self.shape == "hexagon" then
        local pts = {}
        for i = 0, 5 do
            local a = (i / 6) * math.pi * 2 - math.pi / 6
            table.insert(pts, sx + math.cos(a) * rad)
            table.insert(pts, sy + math.sin(a) * rad)
        end
        love.graphics.setColor(r, g, b, 0.85)
        love.graphics.polygon("fill", pts)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.polygon("line", pts)
    elseif self.shape == "triangle" then
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.polygon("fill",
            sx, sy - rad,
            sx + rad * 0.86, sy + rad * 0.5,
            sx - rad * 0.86, sy + rad * 0.5)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.polygon("line",
            sx, sy - rad,
            sx + rad * 0.86, sy + rad * 0.5,
            sx - rad * 0.86, sy + rad * 0.5)
    end

    -- Inner glow
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.circle("fill", sx, sy, rad * 0.2)

    -- HP bar (when damaged)
    if self.hp < self.maxHp then
        local bw = rad * 2
        local bx = sx - bw / 2
        local by = sy - rad - 8
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", bx, by, bw, 3)
        love.graphics.setColor(0.2, 1, 0.2, 0.9)
        love.graphics.rectangle("fill", bx, by, bw * (self.hp / self.maxHp), 3)
    end
end

-- Collect type names for endless spawner
Enemy.TYPES = {}
for k in pairs(DEFS) do table.insert(Enemy.TYPES, k) end
table.sort(Enemy.TYPES)

return Enemy
