-- particles.lua
-- Lightweight particle effects, floating text, and beam trail rendering.
-- Regular particles stored in screen-pixel space (converted from grid at spawn).
-- Beam trails stored in grid-space (converted to screen at draw time).

local Map = require("map")

local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)
    self.list  = {}    -- screen-space particles
    self.texts = {}    -- floating text
    self.beams = {}    -- beam trail effects (grid-space segments)
    return self
end

--------------------------------------------------------------------------------
-- Spawners (grid-space positions → screen-space storage)
--------------------------------------------------------------------------------

function Particles:burst(gx, gy, r, g, b, count, speed)
    local sx, sy = Map.gridToScreen(gx, gy)
    count = count or 10; speed = speed or 100
    for _ = 1, count do
        local a   = math.random() * math.pi * 2
        local spd = speed * (0.3 + math.random() * 0.7)
        table.insert(self.list, {
            x = sx, y = sy,
            vx = math.cos(a) * spd, vy = math.sin(a) * spd,
            r = r, g = g, b = b,
            life = 0.2 + math.random() * 0.3,
            maxLife = 0.4,
            size = 1.5 + math.random() * 2.5,
        })
    end
end

function Particles:spark(gx, gy, r, g, b)
    local sx, sy = Map.gridToScreen(gx, gy)
    for _ = 1, 5 do
        local a   = math.random() * math.pi * 2
        local spd = 30 + math.random() * 60
        table.insert(self.list, {
            x = sx, y = sy,
            vx = math.cos(a) * spd, vy = math.sin(a) * spd,
            r = r or 1, g = g or 0.8, b = b or 0.3,
            life = 0.1 + math.random() * 0.15,
            maxLife = 0.25,
            size = 1 + math.random() * 2,
        })
    end
end

function Particles:wallSpark(gx, gy)
    self:spark(gx, gy, 0.8, 0.7, 0.2)
end

function Particles:text(gx, gy, str, r, g, b)
    local sx, sy = Map.gridToScreen(gx, gy)
    table.insert(self.texts, {
        x = sx + (math.random() - 0.5) * 8, y = sy,
        text = str,
        vy = -40, life = 0.7, maxLife = 0.7,
        r = r or 1, g = g or 1, b = b or 1,
    })
end

--- Register a beam trail from a list of grid-space segments.
--- segments = { {x1,y1,x2,y2}, ... }
function Particles:addBeamTrail(segments)
    table.insert(self.beams, {
        segments = segments,
        age = 0, lifetime = 0.45,
    })
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function Particles:update(dt)
    -- Particles (screen-space)
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

    -- Floating text
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

    -- Beam trails (use real dt so they fade even during slow-mo)
    j = 1
    for i = 1, #self.beams do
        local b = self.beams[i]
        b.age = b.age + dt
        if b.age < b.lifetime then
            if i ~= j then self.beams[j] = b; self.beams[i] = nil end
            j = j + 1
        else
            self.beams[i] = nil
        end
    end
end

--------------------------------------------------------------------------------
-- Draw (inside camera transform)
--------------------------------------------------------------------------------
function Particles:draw()
    -- Beam trails (grid-space → screen at draw time)
    for _, beam in ipairs(self.beams) do
        local t = beam.age / beam.lifetime
        local alpha = 1.0 - t

        for _, seg in ipairs(beam.segments) do
            local sx1, sy1 = Map.gridToScreen(seg.x1, seg.y1)
            local sx2, sy2 = Map.gridToScreen(seg.x2, seg.y2)

            -- Wide glow
            love.graphics.setLineWidth(math.max(1, 24 * (1 - t)))
            love.graphics.setColor(1, 0.9, 0.5, 0.15 * alpha)
            love.graphics.line(sx1, sy1, sx2, sy2)

            -- Mid glow
            love.graphics.setLineWidth(math.max(1, 8 * (1 - t)))
            love.graphics.setColor(1, 0.85, 0.4, 0.4 * alpha)
            love.graphics.line(sx1, sy1, sx2, sy2)

            -- Core
            love.graphics.setLineWidth(math.max(1, 3 * (1 - t * 0.5)))
            love.graphics.setColor(1, 1, 0.95, 0.9 * alpha)
            love.graphics.line(sx1, sy1, sx2, sy2)
        end
        love.graphics.setLineWidth(1)
    end

    -- Particles (screen-space)
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
