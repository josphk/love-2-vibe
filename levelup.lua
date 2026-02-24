-- levelup.lua
-- Level-up choice screen.
-- When the player gains a level the game pauses and presents 3 random upgrade choices:
--   • A new weapon (if fewer than max weapons)
--   • An upgrade for an existing weapon (if below max level)
--   • A passive stat boost

local Weapons = require("weapons")
local Utils   = require("utils")

local LevelUp = {}
LevelUp.__index = LevelUp

--------------------------------------------------------------------------------
-- Passive upgrade pool
--------------------------------------------------------------------------------
local PASSIVES = {
    { name = "Max HP +20",      desc = "Increase maximum health",      apply = function(p) p.maxHp = p.maxHp + 20; p.hp = p.hp + 20 end },
    { name = "Move Speed +12%", desc = "Move faster",                  apply = function(p) p.speedMult = p.speedMult + 0.12 end },
    { name = "Might +15%",      desc = "Increase all damage",          apply = function(p) p.mightMult = p.mightMult + 0.15 end },
    { name = "Armor +1",        desc = "Reduce damage taken by 1",     apply = function(p) p.armor = p.armor + 1 end },
    { name = "Recovery +0.5/s", desc = "Regenerate HP over time",      apply = function(p) p.recovery = p.recovery + 0.5 end },
    { name = "Pickup Range +25",desc = "Collect gems from further away",apply = function(p) p.pickupRange = p.pickupRange + 25 end },
    { name = "Cooldown -8%",    desc = "Weapons fire faster",          apply = function(p) p.cooldownMult = math.max(0.1, p.cooldownMult - 0.08) end },
    { name = "Area +10%",       desc = "Increase weapon area",         apply = function(p) p.areaMult = p.areaMult + 0.10 end },
}

--------------------------------------------------------------------------------
-- Generate a list of choices for the player.
--------------------------------------------------------------------------------
local function generateChoices(player)
    local pool = {}

    -- 1) New weapons the player doesn't own yet
    local owned = {}
    for _, w in ipairs(player.weapons) do owned[w.key] = true end

    if #player.weapons < player.maxWeapons then
        for _, key in ipairs(Weapons.ALL_KEYS) do
            if not owned[key] then
                local def = Weapons.DEFS[key]
                table.insert(pool, {
                    kind = "new_weapon",
                    key  = key,
                    name = "NEW: " .. def.name,
                    desc = def.desc,
                    icon = def.icon,
                    apply = function(p)
                        table.insert(p.weapons, Weapons.create(key))
                    end,
                })
            end
        end
    end

    -- 2) Upgrades for existing weapons
    for _, w in ipairs(player.weapons) do
        if w.level < w.def.maxLevel then
            local nextLv = w.level + 1
            table.insert(pool, {
                kind = "upgrade_weapon",
                key  = w.key,
                name = w.def.name .. " Lv." .. nextLv,
                desc = w.def.levelDescs[nextLv] or "+Stats",
                icon = w.def.icon,
                apply = function(_p)
                    Weapons.levelUp(w)
                end,
            })
        end
    end

    -- 3) Passive stat boosts (always available)
    for _, pas in ipairs(PASSIVES) do
        table.insert(pool, {
            kind = "passive",
            name = pas.name,
            desc = pas.desc,
            icon = "↑",
            apply = pas.apply,
        })
    end

    -- Shuffle then pick up to 3 unique choices,
    -- biased: prefer weapons/upgrades over passives early on.
    Utils.shuffle(pool)

    -- Sort so weapon-related choices come first, passives last.
    table.sort(pool, function(a, b)
        local order = { new_weapon = 1, upgrade_weapon = 2, passive = 3 }
        return (order[a.kind] or 9) < (order[b.kind] or 9)
    end)

    local choices = {}
    local seen = {}
    for _, c in ipairs(pool) do
        local id = c.kind .. (c.key or c.name)
        if not seen[id] then
            seen[id] = true
            table.insert(choices, c)
            if #choices >= 3 then break end
        end
    end

    return choices
end

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
function LevelUp.new()
    local self = setmetatable({}, LevelUp)
    self.active  = false
    self.choices = {}
    return self
end

function LevelUp:open(player)
    self.active  = true
    self.choices = generateChoices(player)
end

function LevelUp:close()
    self.active = false
    self.choices = {}
end

--- Handle key press. Returns true if a choice was made.
function LevelUp:keypressed(key, player)
    if not self.active then return false end
    local idx = tonumber(key)
    if idx and idx >= 1 and idx <= #self.choices then
        self.choices[idx].apply(player)
        self:close()
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Draw  (screen-space overlay, NOT inside camera transform)
--------------------------------------------------------------------------------
function LevelUp:draw(screenW, screenH)
    if not self.active then return end

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    local font = love.graphics.getFont()
    local boxW = 320
    local boxH = 40 + #self.choices * 70
    local bx = (screenW - boxW) / 2
    local by = (screenH - boxH) / 2

    -- Panel background
    love.graphics.setColor(0.08, 0.08, 0.18, 0.95)
    love.graphics.rectangle("fill", bx, by, boxW, boxH, 6, 6)
    love.graphics.setColor(0.5, 0.5, 0.8, 0.8)
    love.graphics.rectangle("line", bx, by, boxW, boxH, 6, 6)

    -- Title
    love.graphics.setColor(1, 1, 0.3, 1)
    local title = "LEVEL UP!"
    love.graphics.print(title, bx + (boxW - font:getWidth(title)) / 2, by + 10)

    -- Choices
    local cy = by + 40
    for i, c in ipairs(self.choices) do
        local hover = false  -- could add mouse hover later

        -- Choice box
        love.graphics.setColor(0.15, 0.15, 0.30, 0.9)
        love.graphics.rectangle("fill", bx + 10, cy, boxW - 20, 58, 4, 4)
        love.graphics.setColor(0.5, 0.5, 0.7, 0.6)
        love.graphics.rectangle("line", bx + 10, cy, boxW - 20, 58, 4, 4)

        -- Key hint
        love.graphics.setColor(1, 0.9, 0.3, 1)
        love.graphics.print("[" .. i .. "]", bx + 18, cy + 6)

        -- Icon
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(c.icon or "?", bx + 50, cy + 6)

        -- Name
        local nameColor = { 1, 1, 1 }
        if c.kind == "new_weapon" then nameColor = { 0.3, 1, 0.5 }
        elseif c.kind == "upgrade_weapon" then nameColor = { 0.5, 0.8, 1 } end
        love.graphics.setColor(nameColor[1], nameColor[2], nameColor[3], 1)
        love.graphics.print(c.name, bx + 70, cy + 6)

        -- Description
        love.graphics.setColor(0.7, 0.7, 0.7, 0.85)
        love.graphics.print(c.desc, bx + 70, cy + 26)

        cy = cy + 64
    end

    -- Hint
    love.graphics.setColor(0.6, 0.6, 0.6, 0.5 + 0.3 * math.sin(love.timer.getTime() * 3))
    local hint = "Press 1, 2, or 3 to choose"
    love.graphics.print(hint, bx + (boxW - font:getWidth(hint)) / 2, by + boxH - 22)
end

return LevelUp
