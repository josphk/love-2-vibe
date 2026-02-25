-- spawner.lua
-- Wave-based enemy spawner for the isometric arena.
-- 7 hand-crafted waves → endless procedural mode with HP scaling.

local Map   = require("map")
local Enemy = require("enemy")

local Spawner = {}
Spawner.__index = Spawner

--------------------------------------------------------------------------------
-- Hand-crafted waves  (all positions in grid-space, verified floor tiles)
--------------------------------------------------------------------------------
local WAVES = {
    -- Wave 1: introduction — just turrets in the open
    {
        { type = "turret", x = 8,  y = 3 },
        { type = "turret", x = 16, y = 3 },
    },
    -- Wave 2: turrets + spinner
    {
        { type = "turret",  x = 5,  y = 4 },
        { type = "turret",  x = 19, y = 4 },
        { type = "spinner", x = 12, y = 4, targetX = 12, targetY = 4 },
    },
    -- Wave 3: orbiters — bullets start bouncing off pillars
    {
        { type = "orbiter", x = 9,  y = 5, orbitCX = 12, orbitCY = 5, orbitR = 3 },
        { type = "orbiter", x = 15, y = 5, orbitCX = 12, orbitCY = 5, orbitR = 3 },
        { type = "turret",  x = 12, y = 3 },
    },
    -- Wave 4: bouncers! — the core reflection mechanic
    {
        { type = "bouncer", x = 8,  y = 4, targetX = 8,  targetY = 4 },
        { type = "bouncer", x = 16, y = 4, targetX = 16, targetY = 4 },
        { type = "dasher",  x = 12, y = 3 },
        { type = "dasher",  x = 4,  y = 8 },
    },
    -- Wave 5: heavy boss + support
    {
        { type = "heavy",   x = 12, y = 4, targetX = 12, targetY = 4 },
        { type = "orbiter", x = 8,  y = 6, orbitCX = 12, orbitCY = 5, orbitR = 4 },
        { type = "orbiter", x = 16, y = 6, orbitCX = 12, orbitCY = 5, orbitR = 4 },
    },
    -- Wave 6: mixed chaos
    {
        { type = "spinner", x = 6,  y = 3, targetX = 6,  targetY = 3 },
        { type = "spinner", x = 18, y = 3, targetX = 18, targetY = 3 },
        { type = "bouncer", x = 12, y = 4, targetX = 12, targetY = 4 },
        { type = "dasher",  x = 4,  y = 10 },
        { type = "dasher",  x = 20, y = 10 },
    },
    -- Wave 7: everything
    {
        { type = "turret",  x = 5,  y = 3 },
        { type = "turret",  x = 19, y = 3 },
        { type = "spinner", x = 12, y = 3, targetX = 12, targetY = 3 },
        { type = "orbiter", x = 8,  y = 5, orbitCX = 12, orbitCY = 5, orbitR = 4 },
        { type = "orbiter", x = 16, y = 5, orbitCX = 12, orbitCY = 5, orbitR = 4 },
        { type = "heavy",   x = 12, y = 6, targetX = 12, targetY = 6 },
        { type = "bouncer", x = 4,  y = 8, targetX = 4,  targetY = 8 },
        { type = "bouncer", x = 20, y = 8, targetX = 20, targetY = 8 },
    },
}

function Spawner.new()
    local self = setmetatable({}, Spawner)
    self.enemies = {}
    self.wave = 0
    self.waveTimer = 0
    self.betweenWaves = true
    self.betweenTimer = 2.5
    self.allCleared = false
    self.gameTime = 0

    -- Wave splash timers (P1)
    self.waveStartFlash = 0
    self.waveClearFlash = 0
    return self
end

--- Pick a random floor position for endless spawns.
local function randomFloorPos()
    for _ = 1, 50 do
        local x = 3 + math.random() * (Map.GW - 5)
        local y = 3 + math.random() * (Map.GH * 0.5 - 2)   -- upper half
        if not Map.isWall(x, y) then return x, y end
    end
    return 12, 4   -- fallback
end

function Spawner:nextWave()
    self.wave = self.wave + 1
    self.betweenWaves = false
    self.allCleared = false
    self.waveStartFlash = 1.5  -- wave splash timer (P1)
    self.waveClearFlash = 0    -- clear stale splash

    local waveData
    if self.wave <= #WAVES then
        waveData = WAVES[self.wave]
    else
        -- Endless: random wave with scaling count
        waveData = {}
        local count = 3 + self.wave
        for _ = 1, math.min(count, 12) do
            local t = Enemy.TYPES[math.random(#Enemy.TYPES)]
            local x, y = randomFloorPos()
            table.insert(waveData, { type = t, x = x, y = y, targetX = x, targetY = y })
        end
    end

    for _, entry in ipairs(waveData) do
        local e = Enemy.new(entry.type, entry.x, entry.y)
        if entry.targetX then e.targetX = entry.targetX end
        if entry.targetY then e.targetY = entry.targetY end
        if entry.orbitCX then e.orbitCX = entry.orbitCX end
        if entry.orbitCY then e.orbitCY = entry.orbitCY end
        if entry.orbitR  then e.orbitR  = entry.orbitR end

        -- Scale HP for later waves
        if self.wave > #WAVES then
            local mult = 1 + (self.wave - #WAVES) * 0.2
            e.hp = math.floor(e.hp * mult)
            e.maxHp = e.hp
        end

        table.insert(self.enemies, e)
    end
end

function Spawner:update(dt, bulletPool, playerX, playerY)
    self.gameTime = self.gameTime + dt

    if self.betweenWaves then
        self.betweenTimer = self.betweenTimer - dt
        if self.betweenTimer <= 0 then
            self:nextWave()
        end
        return
    end

    -- Update enemies
    local anyAlive = false
    for _, e in ipairs(self.enemies) do
        if not e.dead then
            e:update(dt, bulletPool, playerX, playerY)
            anyAlive = true
        end
    end

    -- Check wave clear
    if not anyAlive and not self.allCleared then
        self.allCleared = true
        self.betweenWaves = true
        self.betweenTimer = 2.5
        self.waveClearFlash = 1.2  -- wave clear splash (P1)
        self.waveStartFlash = 0   -- clear stale splash
    end

    -- Decay splash timers (P1)
    if self.waveStartFlash > 0 then self.waveStartFlash = self.waveStartFlash - dt end
    if self.waveClearFlash > 0 then self.waveClearFlash = self.waveClearFlash - dt end
end

function Spawner:draw()
    for _, e in ipairs(self.enemies) do
        if not e.dead then e:draw() end
    end
end

function Spawner:aliveCount()
    local n = 0
    for _, e in ipairs(self.enemies) do if not e.dead then n = n + 1 end end
    return n
end

return Spawner
