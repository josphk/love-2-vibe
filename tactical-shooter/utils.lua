-- utils.lua
-- Shared math and collision helpers.

local Utils = {}

function Utils.distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.normalize(dx, dy)
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.01 then return 1, 0 end
    return dx / len, dy / len
end

function Utils.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

return Utils
