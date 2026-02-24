-- spawner.lua
-- Time-based enemy wave spawner with escalating difficulty.
-- Enemies spawn outside the camera view and walk inward.

local Enemy = require("enemy")
local Utils = require("utils")

local Spawner = {}
Spawner.__index = Spawner

--------------------------------------------------------------------------------
-- Difficulty tiers — which enemy types unlock at what game-time (seconds)
--------------------------------------------------------------------------------
local TIERS = {
    { time =   0, types = { "bat" } },
    { time =  30, types = { "fly" } },
    { time =  60, types = { "zombie" } },
    { time = 120, types = { "skeleton" } },
    { time = 180, types = { "ghost" } },
    { time = 300, types = { "golem" } },
}

function Spawner.new()
    local self = setmetatable({}, Spawner)
    self.enemies = {}
    self.gameTime = 0         -- total elapsed seconds
    self.spawnTimer = 0
    self.difficulty = 1.0     -- multiplier applied to enemy HP/damage
    self.spawnRate  = 0.8     -- enemies per second (increases over time)
    return self
end

--------------------------------------------------------------------------------
-- Determine which enemy types are currently available.
--------------------------------------------------------------------------------
function Spawner:availableTypes()
    local types = {}
    for _, tier in ipairs(TIERS) do
        if self.gameTime >= tier.time then
            for _, t in ipairs(tier.types) do
                table.insert(types, t)
            end
        end
    end
    return types
end

--------------------------------------------------------------------------------
-- Pick a random spawn position outside the camera view.
--------------------------------------------------------------------------------
local function spawnPosition(camX, camY, screenW, screenH)
    local margin = 80
    local side = math.random(4)
    local x, y
    if side == 1 then      -- top
        x = camX + (math.random() - 0.5) * (screenW + margin * 2)
        y = camY - screenH / 2 - margin
    elseif side == 2 then  -- bottom
        x = camX + (math.random() - 0.5) * (screenW + margin * 2)
        y = camY + screenH / 2 + margin
    elseif side == 3 then  -- left
        x = camX - screenW / 2 - margin
        y = camY + (math.random() - 0.5) * (screenH + margin * 2)
    else                   -- right
        x = camX + screenW / 2 + margin
        y = camY + (math.random() - 0.5) * (screenH + margin * 2)
    end
    return x, y
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function Spawner:update(dt, playerX, playerY, camX, camY, screenW, screenH)
    self.gameTime = self.gameTime + dt

    -- Scale difficulty and spawn rate with time
    self.difficulty = 1.0 + self.gameTime * 0.005          -- +50 % every 100 s
    self.spawnRate  = 0.8 + self.gameTime * 0.012          -- ramps up

    -- Spawn timer
    self.spawnTimer = self.spawnTimer + dt * self.spawnRate
    while self.spawnTimer >= 1 do
        self.spawnTimer = self.spawnTimer - 1

        local types = self:availableTypes()
        local typeName = types[math.random(#types)]
        local sx, sy = spawnPosition(camX, camY, screenW, screenH)
        local e = Enemy.new(typeName, sx, sy, self.difficulty)
        table.insert(self.enemies, e)
    end

    -- Occasional swarm burst (every ~20 s, spawn a cluster of 8-15 flies/bats)
    if self.gameTime > 20 and math.random() < dt * 0.04 then
        local burstType = self.gameTime > 30 and "fly" or "bat"
        local count = math.random(8, 15)
        local cx, cy = spawnPosition(camX, camY, screenW, screenH)
        for _ = 1, count do
            local ox = (math.random() - 0.5) * 60
            local oy = (math.random() - 0.5) * 60
            table.insert(self.enemies, Enemy.new(burstType, cx + ox, cy + oy, self.difficulty))
        end
    end

    -- Update all enemies
    for _, e in ipairs(self.enemies) do
        if not e.dead then
            e:update(dt, playerX, playerY)
        end
    end

    -- Sweep dead enemies periodically
    if #self.enemies > 200 then
        Utils.sweep(self.enemies)
    end
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function Spawner:draw()
    for _, e in ipairs(self.enemies) do
        if not e.dead then
            e:draw()
        end
    end
end

return Spawner
