-- spawner.lua
-- Wave-based enemy spawner for the arena.

local Enemy = require("enemy")
local Background = require("background")

local Spawner = {}
Spawner.__index = Spawner

--------------------------------------------------------------------------------
-- Hand-crafted waves
--------------------------------------------------------------------------------
local WAVES = {
    -- Wave 1: just turrets
    {
        { type = "turret", x = 200, y = 120 },
        { type = "turret", x = 600, y = 120 },
    },
    -- Wave 2: turrets + spinner
    {
        { type = "turret",  x = 150, y = 100 },
        { type = "turret",  x = 650, y = 100 },
        { type = "spinner", x = 400, y = 180 },
    },
    -- Wave 3: orbiters
    {
        { type = "orbiter", x = 300, y = 200, orbitCX = 400, orbitCY = 250, orbitR = 120 },
        { type = "orbiter", x = 500, y = 200, orbitCX = 400, orbitCY = 250, orbitR = 120 },
        { type = "turret",  x = 400, y = 80 },
    },
    -- Wave 4: dashers
    {
        { type = "dasher",  x = 200, y = 150 },
        { type = "dasher",  x = 600, y = 150 },
        { type = "spinner", x = 400, y = 100 },
        { type = "turret",  x = 150, y = 350 },
        { type = "turret",  x = 650, y = 350 },
    },
    -- Wave 5: heavy!
    {
        { type = "heavy",   x = 400, y = 160 },
        { type = "orbiter", x = 250, y = 200, orbitCX = 400, orbitCY = 200, orbitR = 160 },
        { type = "orbiter", x = 550, y = 200, orbitCX = 400, orbitCY = 200, orbitR = 160 },
    },
    -- Wave 6: chaos
    {
        { type = "spinner", x = 200, y = 120 },
        { type = "spinner", x = 600, y = 120 },
        { type = "heavy",   x = 400, y = 140 },
        { type = "dasher",  x = 300, y = 250 },
        { type = "dasher",  x = 500, y = 250 },
    },
    -- Wave 7: all types
    {
        { type = "turret",  x = 120, y = 80 },
        { type = "turret",  x = 680, y = 80 },
        { type = "spinner", x = 400, y = 100 },
        { type = "orbiter", x = 250, y = 200, orbitCX = 400, orbitCY = 200, orbitR = 180 },
        { type = "orbiter", x = 550, y = 200, orbitCX = 400, orbitCY = 200, orbitR = 180 },
        { type = "heavy",   x = 400, y = 200 },
        { type = "dasher",  x = 200, y = 350 },
        { type = "dasher",  x = 600, y = 350 },
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
    return self
end

function Spawner:nextWave()
    self.wave = self.wave + 1
    self.betweenWaves = false
    self.allCleared = false

    local A = Background.ARENA
    local waveData
    if self.wave <= #WAVES then
        waveData = WAVES[self.wave]
    else
        -- Endless: generate random wave with scaling count
        waveData = {}
        local count = 3 + self.wave
        for _ = 1, math.min(count, 12) do
            local t = Enemy.TYPES[math.random(#Enemy.TYPES)]
            table.insert(waveData, {
                type = t,
                x = A.x + 60 + math.random() * (A.w - 120),
                y = A.y + 40 + math.random() * (A.h * 0.4),
            })
        end
    end

    for _, entry in ipairs(waveData) do
        local e = Enemy.new(entry.type, entry.x, entry.y)
        -- Apply extra properties
        if entry.orbitCX then e.orbitCX = entry.orbitCX end
        if entry.orbitCY then e.orbitCY = entry.orbitCY end
        if entry.orbitR  then e.orbitR  = entry.orbitR  end
        if entry.type == "spinner" or entry.type == "heavy" then
            e.targetX = entry.x
            e.targetY = entry.y
        end
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

    local A = Background.ARENA

    -- Update enemies
    local anyAlive = false
    for _, e in ipairs(self.enemies) do
        if not e.dead then
            e:update(dt, bulletPool, playerX, playerY, A)
            anyAlive = true
        end
    end

    -- Check wave clear
    if not anyAlive and not self.allCleared then
        self.allCleared = true
        self.betweenWaves = true
        self.betweenTimer = 2.5
    end
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
