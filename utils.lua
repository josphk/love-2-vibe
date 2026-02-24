-- utils.lua
-- Shared utility functions.

local Utils = {}

function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.distance2(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy
end

function Utils.angleTo(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function Utils.clamp(val, lo, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.circlesOverlap(x1, y1, r1, x2, y2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local rsum = r1 + r2
    return (dx * dx + dy * dy) <= rsum * rsum
end

--- Find the nearest alive enemy to (x,y). Returns enemy, dist or nil.
function Utils.findNearest(x, y, list)
    local best, bestD2 = nil, math.huge
    for _, e in ipairs(list) do
        if not e.dead then
            local d2 = Utils.distance2(x, y, e.x, e.y)
            if d2 < bestD2 then
                best = e
                bestD2 = d2
            end
        end
    end
    return best, math.sqrt(bestD2)
end

--- Shuffle an array in-place (Fisher-Yates).
function Utils.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

--- Remove dead entries from an array in-place.
function Utils.sweep(list, field)
    field = field or "dead"
    local j = 1
    for i = 1, #list do
        if not list[i][field] then
            if i ~= j then list[j] = list[i]; list[i] = nil end
            j = j + 1
        else
            list[i] = nil
        end
    end
end

return Utils
