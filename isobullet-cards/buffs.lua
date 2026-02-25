-- buffs.lua
-- Active duration-based buffs. Each buff has statId, multiplier, endTime.
-- getMultiplier(statId) returns product of all active buffs for that stat (or 1.0).

local Buffs = {}

-- { { statId, multiplier, endTime }, ... }
Buffs.active = {}

--- Add a buff for a stat. multiplier is applied (e.g. 1.15 for +15%).
--- durationSeconds: how long the buff lasts.
function Buffs.add(statId, multiplier, durationSeconds, gameTime)
    gameTime = gameTime or 0
    local duration = durationSeconds
    table.insert(Buffs.active, {
        statId = statId,
        multiplier = multiplier,
        endTime = gameTime + duration,
        duration = duration,
    })
end

--- Remove expired buffs. Call with current game time each frame.
function Buffs.update(gameTime)
    local i = 1
    while i <= #Buffs.active do
        if Buffs.active[i].endTime <= gameTime then
            table.remove(Buffs.active, i)
        else
            i = i + 1
        end
    end
end

--- Get combined multiplier for a stat (product of all active buffs for that stat).
--- Returns 1.0 if none.
function Buffs.getMultiplier(statId)
    local mult = 1.0
    for _, b in ipairs(Buffs.active) do
        if b.statId == statId then
            mult = mult * b.multiplier
        end
    end
    return mult
end

--- Get list of active buffs for HUD (statId, multiplier, remaining, duration for bar).
function Buffs.getActiveList(gameTime)
    local list = {}
    gameTime = gameTime or 0
    for _, b in ipairs(Buffs.active) do
        local remaining = b.endTime - gameTime
        if remaining > 0 and b.duration then
            table.insert(list, {
                statId = b.statId,
                multiplier = b.multiplier,
                remaining = remaining,
                duration = b.duration,
            })
        end
    end
    return list
end

--- Clear all buffs (e.g. on reset).
function Buffs.clear()
    Buffs.active = {}
end

return Buffs
