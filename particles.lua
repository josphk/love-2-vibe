-- particles.lua
-- Lightweight particle effects: explosions, sparks, and floating damage numbers.

local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)
    self.list  = {}   -- visual particles
    self.texts = {}   -- floating text (damage numbers, "+XP", etc.)
    return self
end

--------------------------------------------------------------------------------
-- Spawn helpers
--------------------------------------------------------------------------------

function Particles:explode(x, y, r, g, b, count, speed)
    count = count or 12; speed = speed or 120
    for _ = 1, count do
        local a   = math.random() * math.pi * 2
        local spd = speed * (0.4 + math.random() * 0.6)
        table.insert(self.list, {
            x = x, y = y,
            vx = math.cos(a) * spd, vy = math.sin(a) * spd,
            r = r or 1, g = g or 1, b = b or 1,
            life = 0.25 + math.random() * 0.35,
            maxLife = 0.5,
            size = 2 + math.random() * 3,
        })
    end
end

function Particles:spark(x, y, r, g, b)
    for _ = 1, 4 do
        local a   = math.random() * math.pi * 2
        local spd = 40 + math.random() * 50
        table.insert(self.list, {
            x = x, y = y,
            vx = math.cos(a) * spd, vy = math.sin(a) * spd,
            r = r or 1, g = g or 0.8, b = b or 0.3,
            life = 0.12 + math.random() * 0.12,
            maxLife = 0.25,
            size = 1.5 + math.random() * 1.5,
        })
    end
end

function Particles:damageNumber(x, y, amount, r, g, b)
    table.insert(self.texts, {
        x = x + (math.random() - 0.5) * 10,
        y = y,
        text = tostring(amount),
        vy = -50,
        life = 0.7,
        maxLife = 0.7,
        r = r or 1, g = g or 1, b = b or 0.3,
    })
end

function Particles:floatingText(x, y, text, r, g, b)
    table.insert(self.texts, {
        x = x, y = y,
        text = text,
        vy = -35,
        life = 0.9,
        maxLife = 0.9,
        r = r or 1, g = g or 1, b = b or 1,
    })
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function Particles:update(dt)
    -- Particles
    local j = 1
    for i = 1, #self.list do
        local p = self.list[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life > 0 then
            if i ~= j then self.list[j] = p; self.list[i] = nil end
            j = j + 1
        else
            self.list[i] = nil
        end
    end
    -- Floating texts
    j = 1
    for i = 1, #self.texts do
        local t = self.texts[i]
        t.y = t.y + t.vy * dt
        t.life = t.life - dt
        if t.life > 0 then
            if i ~= j then self.texts[j] = t; self.texts[i] = nil end
            j = j + 1
        else
            self.texts[i] = nil
        end
    end
end

--------------------------------------------------------------------------------
-- Draw  (call inside camera transform for world-space particles)
--------------------------------------------------------------------------------
function Particles:draw()
    for _, p in ipairs(self.list) do
        local a = math.max(0, p.life / p.maxLife)
        love.graphics.setColor(p.r, p.g, p.b, a)
        love.graphics.circle("fill", p.x, p.y, p.size * a)
    end
    local font = love.graphics.getFont()
    for _, t in ipairs(self.texts) do
        local a = math.max(0, t.life / t.maxLife)
        love.graphics.setColor(t.r, t.g, t.b, a)
        love.graphics.print(t.text, math.floor(t.x - font:getWidth(t.text) / 2), math.floor(t.y))
    end
end

return Particles
