-- deck.lua
-- 5-card deck, auto top-deck play every 3s. On play: apply buff (duration 8-12s), cycle card to bottom.

local Buffs = require("buffs")

local Deck = {}
Deck.__index = Deck

-- Card definitions: id, name, stat, percent (10-20)
local CARD_POOL = {
    { id = "chrono_regen_15", name = "Chrono Regen", stat = "chrono_regen", percent = 15 },
    { id = "chrono_regen_20", name = "Chrono Regen+", stat = "chrono_regen", percent = 20 },
    { id = "chrono_drain_10", name = "Efficient Time", stat = "chrono_drain", percent = 10 },
    { id = "damage_15", name = "Beam Power", stat = "damage", percent = 15 },
    { id = "damage_20", name = "Beam Power+", stat = "damage", percent = 20 },
    { id = "max_lives_1", name = "Extra Heart", stat = "max_lives", percent = 20 },
    { id = "shield_20", name = "Shield", stat = "shield", percent = 20 },
    { id = "speed_15", name = "Swift", stat = "speed", percent = 15 },
    { id = "graze_meter_15", name = "Graze Charge", stat = "graze_meter", percent = 15 },
    { id = "invuln_time_20", name = "Quick Recovery", stat = "invuln_time", percent = 20 },
}

-- Fixed starter deck: 5 cards (one per key stat for first pass)
local STARTER_IDS = { "chrono_regen_15", "damage_15", "shield_20", "speed_15", "max_lives_1" }

local function getCardById(id)
    for _, c in ipairs(CARD_POOL) do
        if c.id == id then return c end
    end
    return nil
end

--- Return a copy of the card pool for the pick UI.
function Deck.getCardPool()
    local out = {}
    for _, c in ipairs(CARD_POOL) do table.insert(out, c) end
    return out
end

local BASE_INTERVAL = 3.0
local BUFF_DURATION_MIN = 8
local BUFF_DURATION_MAX = 12

--- selectedIds: optional array of 5 card ids; if nil, use STARTER_IDS.
function Deck.new(selectedIds)
    local self = setmetatable({}, Deck)
    self.list = {}
    local ids = selectedIds and #selectedIds > 0 and selectedIds or STARTER_IDS
    for _, id in ipairs(ids) do
        local c = getCardById(id)
        if c then table.insert(self.list, c) end
    end
    self.cardTimer = BASE_INTERVAL
    self.baseInterval = BASE_INTERVAL
    return self
end

--- Play the top card: add buff, cycle to bottom. Requires gameTime for buff duration.
--- Optional onPlay callback(card) is called after adding the buff (e.g. to grant flat shield).
function Deck:playTopCard(gameTime, onPlay)
    if #self.list == 0 then return end
    self.lastPlayedAt = gameTime
    local card = self.list[1]
    table.remove(self.list, 1)
    table.insert(self.list, card)

    local duration = BUFF_DURATION_MIN + math.random() * (BUFF_DURATION_MAX - BUFF_DURATION_MIN)
    local mult
    if card.stat == "chrono_drain" then
        mult = 1 - card.percent / 100
    else
        mult = 1 + card.percent / 100
    end
    Buffs.add(card.stat, mult, duration, gameTime)
    if onPlay then onPlay(card) end
end

--- Update timer; play top card when timer hits 0. Optional onPlay(card) callback.
function Deck:update(dt, gameTime, onPlay)
    self.cardTimer = self.cardTimer - dt
    if self.cardTimer <= 0 then
        self:playTopCard(gameTime, onPlay)
        self.cardTimer = self.baseInterval
    end
end

--- Reduce timer (e.g. gem pickup). Does not go below 0.
function Deck:reduceTimer(amount)
    self.cardTimer = math.max(0, self.cardTimer - amount)
end

--- Reset deck state for new run. selectedIds: optional; if provided, re-build list from those ids.
function Deck:reset(selectedIds)
    self.list = {}
    local ids = selectedIds and #selectedIds > 0 and selectedIds or STARTER_IDS
    for _, id in ipairs(ids) do
        local c = getCardById(id)
        if c then table.insert(self.list, c) end
    end
    self.cardTimer = self.baseInterval
end

return Deck
