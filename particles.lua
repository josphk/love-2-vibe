-- particles.lua
-- Lightweight particle effects for explosions, hits, etc.
-- No LÖVE ParticleSystem used – just simple table-based particles for full control.

local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)
    self.list = {}
    return self
end

--- Spawn an explosion burst at (x, y) with given color
function Particles.explode(self, x, y, r, g, b, count, speed)
    count = count or 12
    speed = speed or 120
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = speed * (0.4 + math.random() * 0.6)
        table.insert(self.list, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            r = r or 1, g = g or 1, b = b or 1,
            life = 0.3 + math.random() * 0.4,
            maxLife = 0.5,
            size = 2 + math.random() * 3,
        })
    end
end

--- Small hit spark
function Particles.spark(self, x, y, r, g, b)
    for i = 1, 5 do
        local angle = math.random() * math.pi * 2
        local spd = 50 + math.random() * 60
        table.insert(self.list, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            r = r or 1, g = g or 0.8, b = b or 0.3,
            life = 0.15 + math.random() * 0.15,
            maxLife = 0.3,
            size = 1.5 + math.random() * 1.5,
        })
    end
end

function Particles.update(self, dt)
    local list = self.list
    local j = 1
    for i = 1, #list do
        local p = list[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life > 0 then
            if i ~= j then
                list[j] = p
                list[i] = nil
            end
            j = j + 1
        else
            list[i] = nil
        end
    end
end

function Particles.draw(self)
    for _, p in ipairs(self.list) do
        local alpha = math.max(0, p.life / p.maxLife)
        love.graphics.setColor(p.r, p.g, p.b, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * alpha)
    end
end

return Particles
