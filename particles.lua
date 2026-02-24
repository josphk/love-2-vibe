-- particles.lua
-- Lightweight particle effects, floating text, and beam trail rendering.

local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)
    self.list  = {}
    self.texts = {}
    self.beams = {}    -- beam trail effects
    return self
end

--------------------------------------------------------------------------------
-- Particle spawners
--------------------------------------------------------------------------------

function Particles:burst(x, y, r, g, b, count, speed)
    count = count or 10; speed = speed or 100
    for _ = 1, count do
        local a   = math.random() * math.pi * 2
        local spd = speed * (0.3 + math.random() * 0.7)
        table.insert(self.list, {
            x = x, y = y,
            vx = math.cos(a) * spd, vy = math.sin(a) * spd,
            r = r, g = g, b = b,
            life = 0.2 + math.random() * 0.3,
            maxLife = 0.4,
            size = 1.5 + math.random() * 2.5,
        })
    end
end

function Particles:spark(x, y, r, g, b)
    for _ = 1, 4 do
        local a   = math.random() * math.pi * 2
        local spd = 30 + math.random() * 50
        table.insert(self.list, {
            x = x, y = y,
            vx = math.cos(a) * spd, vy = math.sin(a) * spd,
            r = r or 1, g = g or 0.8, b = b or 0.3,
            life = 0.1 + math.random() * 0.12,
            maxLife = 0.22,
            size = 1 + math.random() * 1.5,
        })
    end
end

function Particles:text(x, y, str, r, g, b)
    table.insert(self.texts, {
        x = x + (math.random() - 0.5) * 8, y = y,
        text = str,
        vy = -40, life = 0.7, maxLife = 0.7,
        r = r or 1, g = g or 1, b = b or 1,
    })
end

--- Register a beam trail (the bright line left by the player's shot).
function Particles:beam(x1, y1, x2, y2, destroyedCount)
    table.insert(self.beams, {
        x1 = x1, y1 = y1, x2 = x2, y2 = y2,
        age = 0, lifetime = 0.45,
        destroyed = destroyedCount or 0,
    })
end

--------------------------------------------------------------------------------
-- Update (worldDt for world-space particles)
--------------------------------------------------------------------------------
function Particles:update(dt)
    -- Particles
    local j = 1
    for i = 1, #self.list do
        local p = self.list[i]
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life > 0 then
            if i ~= j then self.list[j] = p; self.list[i] = nil end
            j = j + 1
        else self.list[i] = nil end
    end

    -- Texts
    j = 1
    for i = 1, #self.texts do
        local t = self.texts[i]
        t.y = t.y + t.vy * dt; t.life = t.life - dt
        if t.life > 0 then
            if i ~= j then self.texts[j] = t; self.texts[i] = nil end
            j = j + 1
        else self.texts[i] = nil end
    end

    -- Beams (use real dt so they fade even during slow-mo)
    j = 1
    for i = 1, #self.beams do
        local b = self.beams[i]
        b.age = b.age + dt   -- intentionally real dt
        if b.age < b.lifetime then
            if i ~= j then self.beams[j] = b; self.beams[i] = nil end
            j = j + 1
        else self.beams[i] = nil end
    end
end

--------------------------------------------------------------------------------
-- Draw (inside camera transform)
--------------------------------------------------------------------------------
function Particles:draw()
    -- Beam trails
    for _, b in ipairs(self.beams) do
        local t = b.age / b.lifetime
        local alpha = 1.0 - t
        -- Wide glow
        love.graphics.setLineWidth(math.max(1, 28 * (1 - t)))
        love.graphics.setColor(1, 0.9, 0.5, 0.18 * alpha)
        love.graphics.line(b.x1, b.y1, b.x2, b.y2)
        -- Mid glow
        love.graphics.setLineWidth(math.max(1, 10 * (1 - t)))
        love.graphics.setColor(1, 0.85, 0.4, 0.45 * alpha)
        love.graphics.line(b.x1, b.y1, b.x2, b.y2)
        -- Core
        love.graphics.setLineWidth(math.max(1, 3 * (1 - t * 0.5)))
        love.graphics.setColor(1, 1, 0.95, 0.95 * alpha)
        love.graphics.line(b.x1, b.y1, b.x2, b.y2)
        love.graphics.setLineWidth(1)
    end

    -- Particles
    for _, p in ipairs(self.list) do
        local a = math.max(0, p.life / p.maxLife)
        love.graphics.setColor(p.r, p.g, p.b, a)
        love.graphics.circle("fill", p.x, p.y, p.size * (0.3 + 0.7 * a))
    end

    -- Floating text
    local font = love.graphics.getFont()
    for _, t in ipairs(self.texts) do
        local a = math.max(0, t.life / t.maxLife)
        love.graphics.setColor(t.r, t.g, t.b, a)
        love.graphics.print(t.text, math.floor(t.x - font:getWidth(t.text) / 2), math.floor(t.y))
    end
end

return Particles
