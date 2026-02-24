-- spawner.lua
-- Wave-based enemy spawner with escalating difficulty.

local Enemy = require("enemy")

local Spawner = {}
Spawner.__index = Spawner

--------------------------------------------------------------------------------
-- Wave definitions
-- Each wave is a list of spawn entries:
--   { time = <seconds into wave>, type = "<enemy type>", x = <x pos> | "random" }
-- After all predefined waves, an endless procedural mode kicks in.
--------------------------------------------------------------------------------

local WAVES = {
    -- Wave 1: gentle introduction – a few drones
    {
        duration = 10,
        spawns = {
            { time = 0.5, type = "drone", x = 120 },
            { time = 1.0, type = "drone", x = 360 },
            { time = 2.5, type = "drone", x = 240 },
            { time = 4.0, type = "drone", x = 100 },
            { time = 4.0, type = "drone", x = 380 },
            { time = 6.0, type = "drone", x = 200 },
            { time = 6.5, type = "drone", x = 280 },
        },
    },
    -- Wave 2: spinners + drones
    {
        duration = 14,
        spawns = {
            { time = 0.0, type = "spinner", x = 240 },
            { time = 1.0, type = "drone",   x = 80  },
            { time = 1.5, type = "drone",   x = 400 },
            { time = 3.0, type = "spinner", x = 140 },
            { time = 3.0, type = "spinner", x = 340 },
            { time = 5.0, type = "drone",   x = 200 },
            { time = 5.5, type = "drone",   x = 300 },
            { time = 7.0, type = "weaver",  x = 240 },
            { time = 9.0, type = "drone",   x = 120 },
            { time = 9.0, type = "drone",   x = 360 },
        },
    },
    -- Wave 3: turrets
    {
        duration = 16,
        spawns = {
            { time = 0.0, type = "turret",  x = 160 },
            { time = 0.0, type = "turret",  x = 320 },
            { time = 3.0, type = "drone",   x = 80  },
            { time = 3.5, type = "drone",   x = 400 },
            { time = 5.0, type = "weaver",  x = 240 },
            { time = 7.0, type = "spinner", x = 100 },
            { time = 7.0, type = "spinner", x = 380 },
            { time = 10.0,type = "drone",   x = 200 },
            { time = 10.0,type = "drone",   x = 280 },
        },
    },
    -- Wave 4: heavy enemy introduction
    {
        duration = 18,
        spawns = {
            { time = 0.0, type = "heavy",   x = 240 },
            { time = 2.0, type = "drone",   x = 100 },
            { time = 2.0, type = "drone",   x = 380 },
            { time = 4.0, type = "weaver",  x = 160 },
            { time = 4.0, type = "weaver",  x = 320 },
            { time = 7.0, type = "spinner", x = 240 },
            { time = 9.0, type = "drone",   x = 120 },
            { time = 9.0, type = "drone",   x = 360 },
            { time = 11.0,type = "turret",  x = 240 },
            { time = 13.0,type = "drone",   x = 200 },
            { time = 13.0,type = "drone",   x = 300 },
        },
    },
    -- Wave 5: everything
    {
        duration = 22,
        spawns = {
            { time = 0.0, type = "turret",  x = 120 },
            { time = 0.0, type = "turret",  x = 360 },
            { time = 1.0, type = "spinner", x = 240 },
            { time = 3.0, type = "heavy",   x = 200 },
            { time = 3.0, type = "weaver",  x = 380 },
            { time = 5.0, type = "drone",   x = 80  },
            { time = 5.0, type = "drone",   x = 400 },
            { time = 7.0, type = "weaver",  x = 140 },
            { time = 7.0, type = "weaver",  x = 340 },
            { time = 10.0,type = "heavy",   x = 300 },
            { time = 12.0,type = "spinner", x = 100 },
            { time = 12.0,type = "spinner", x = 380 },
            { time = 14.0,type = "drone",   x = 200 },
            { time = 14.0,type = "drone",   x = 280 },
            { time = 16.0,type = "turret",  x = 240 },
        },
    },
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Spawner.new(screenW, screenH)
    local self = setmetatable({}, Spawner)
    self.screenW = screenW
    self.screenH = screenH
    self.wave = 0
    self.waveTimer = 0
    self.spawnIndex = 0
    self.currentWave = nil
    self.enemies = {}
    self.betweenWaves = true
    self.betweenTimer = 2.0   -- delay before first wave
    self.endless = false
    self.endlessTimer = 0
    self.difficulty = 1       -- scales with waves cleared
    return self
end

--------------------------------------------------------------------------------
-- Start next wave
--------------------------------------------------------------------------------
function Spawner.nextWave(self)
    self.wave = self.wave + 1
    self.waveTimer = 0
    self.spawnIndex = 1
    self.difficulty = 1 + (self.wave - 1) * 0.15

    if self.wave <= #WAVES then
        self.currentWave = WAVES[self.wave]
        self.endless = false
    else
        self.currentWave = nil
        self.endless = true
        self.endlessTimer = 0
    end

    self.betweenWaves = false
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function Spawner.update(self, dt, bulletPool, playerX, playerY)
    -- Between-waves pause
    if self.betweenWaves then
        self.betweenTimer = self.betweenTimer - dt
        if self.betweenTimer <= 0 then
            self:nextWave()
        end
        -- Still update existing enemies
        self:updateEnemies(dt, bulletPool, playerX, playerY)
        return
    end

    self.waveTimer = self.waveTimer + dt

    -- Scripted wave spawning
    if self.currentWave then
        while self.spawnIndex <= #self.currentWave.spawns do
            local entry = self.currentWave.spawns[self.spawnIndex]
            if self.waveTimer >= entry.time then
                local ex = entry.x
                if ex == "random" then
                    ex = 40 + math.random() * (self.screenW - 80)
                end
                local e = Enemy.new(entry.type, ex, -30, self.screenW, self.screenH)
                table.insert(self.enemies, e)
                self.spawnIndex = self.spawnIndex + 1
            else
                break
            end
        end

        -- Check if wave is over (all spawned and all dead)
        if self.spawnIndex > #self.currentWave.spawns then
            local allDead = true
            for _, e in ipairs(self.enemies) do
                if not e.dead then allDead = false; break end
            end
            if allDead or self.waveTimer > self.currentWave.duration + 5 then
                self.betweenWaves = true
                self.betweenTimer = 3.0
            end
        end
    end

    -- Endless mode: procedural spawning
    if self.endless then
        self.endlessTimer = self.endlessTimer - dt
        if self.endlessTimer <= 0 then
            local interval = math.max(0.5, 2.5 - self.difficulty * 0.15)
            self.endlessTimer = interval
            local etype = Enemy.TYPES[math.random(#Enemy.TYPES)]
            local ex = 40 + math.random() * (self.screenW - 80)
            local e = Enemy.new(etype, ex, -30, self.screenW, self.screenH)
            -- Scale HP with difficulty
            e.hp = math.floor(e.hp * self.difficulty)
            e.maxHp = e.hp
            table.insert(self.enemies, e)
        end
        self.difficulty = self.difficulty + dt * 0.01
    end

    self:updateEnemies(dt, bulletPool, playerX, playerY)
end

--------------------------------------------------------------------------------
-- Update all enemies, sweep dead
--------------------------------------------------------------------------------
function Spawner.updateEnemies(self, dt, bulletPool, playerX, playerY)
    for _, e in ipairs(self.enemies) do
        if not e.dead then
            e:update(dt, bulletPool, playerX, playerY)
        end
    end
    -- Periodic cleanup
    if #self.enemies > 30 then
        local j = 1
        for i = 1, #self.enemies do
            if not self.enemies[i].dead then
                if i ~= j then
                    self.enemies[j] = self.enemies[i]
                    self.enemies[i] = nil
                end
                j = j + 1
            else
                self.enemies[i] = nil
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function Spawner.draw(self)
    for _, e in ipairs(self.enemies) do
        if not e.dead then
            e:draw()
        end
    end
end

return Spawner
