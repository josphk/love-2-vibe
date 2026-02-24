-- gems.lua
-- XP gems and health pickups dropped by enemies.
-- Gems are attracted toward the player when within pickup range.

local Utils = require("utils")

local Gems = {}
Gems.__index = Gems

--------------------------------------------------------------------------------
-- Gem tiers by XP value
--------------------------------------------------------------------------------
local TIERS = {
    { maxXP = 1,  r = 0.35, g = 0.55, b = 1.00, size = 3 },  -- blue (small)
    { maxXP = 3,  r = 0.30, g = 0.85, b = 0.35, size = 4 },  -- green
    { maxXP = 5,  r = 0.90, g = 0.25, b = 0.25, size = 5 },  -- red
    { maxXP = 99, r = 0.95, g = 0.85, b = 0.20, size = 7 },  -- gold (big)
}

local function tierFor(xp)
    for _, t in ipairs(TIERS) do
        if xp <= t.maxXP then return t end
    end
    return TIERS[#TIERS]
end

function Gems.new()
    local self = setmetatable({}, Gems)
    self.list = {}
    return self
end

--- Drop an XP gem at (x, y).
function Gems:spawn(x, y, xp)
    local t = tierFor(xp)
    table.insert(self.list, {
        x = x + (math.random() - 0.5) * 12,
        y = y + (math.random() - 0.5) * 12,
        xp = xp,
        size = t.size,
        r = t.r, g = t.g, b = t.b,
        age = 0,
        magnetized = false,
        dead = false,
    })
end

--- Drop a healing item at (x, y).
function Gems:spawnHealth(x, y, amount)
    table.insert(self.list, {
        x = x + (math.random() - 0.5) * 10,
        y = y + (math.random() - 0.5) * 10,
        heal = amount,
        xp = 0,
        size = 5,
        r = 0.2, g = 1.0, b = 0.4,
        age = 0,
        magnetized = false,
        dead = false,
    })
end

--------------------------------------------------------------------------------
-- Update: attract and collect gems.  Returns total XP gained and heal amount.
--------------------------------------------------------------------------------
function Gems:update(dt, player)
    local xpGained = 0
    local healed = 0
    local pr = player.pickupRange * player.areaMult

    for _, g in ipairs(self.list) do
        if not g.dead then
            g.age = g.age + dt
            local dist = Utils.distance(g.x, g.y, player.x, player.y)

            -- Magnetize when within pickup range
            if dist < pr then
                g.magnetized = true
            end

            -- Fly toward player
            if g.magnetized then
                local a = Utils.angleTo(g.x, g.y, player.x, player.y)
                local speed = 350 + 200 * math.min(1, g.age)
                g.x = g.x + math.cos(a) * speed * dt
                g.y = g.y + math.sin(a) * speed * dt
                dist = Utils.distance(g.x, g.y, player.x, player.y)
            end

            -- Collect
            if dist < 14 then
                g.dead = true
                xpGained = xpGained + g.xp
                if g.heal then
                    healed = healed + g.heal
                end
            end
        end
    end

    -- Sweep dead
    if #self.list > 300 then Utils.sweep(self.list) end

    return xpGained, healed
end

--------------------------------------------------------------------------------
-- Draw  (inside camera transform)
--------------------------------------------------------------------------------
function Gems:draw()
    for _, g in ipairs(self.list) do
        if not g.dead then
            local pulse = 0.75 + 0.25 * math.sin(g.age * 6)
            if g.heal then
                -- Health pickup: cross shape
                love.graphics.setColor(g.r, g.g, g.b, pulse)
                love.graphics.rectangle("fill", g.x - 2, g.y - g.size, 4, g.size * 2)
                love.graphics.rectangle("fill", g.x - g.size, g.y - 2, g.size * 2, 4)
            else
                -- XP gem: diamond shape
                love.graphics.setColor(g.r, g.g, g.b, 0.4 * pulse)
                love.graphics.circle("fill", g.x, g.y, g.size * 1.5)
                love.graphics.setColor(g.r, g.g, g.b, 0.9 * pulse)
                love.graphics.push()
                love.graphics.translate(g.x, g.y)
                love.graphics.rotate(math.pi / 4)
                love.graphics.rectangle("fill", -g.size / 2, -g.size / 2, g.size, g.size)
                love.graphics.pop()
            end
        end
    end
end

return Gems
