-- utils.lua
-- Shared math and table utilities.

local Utils = {}

function Utils.distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.distance2(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return dx * dx + dy * dy
end

function Utils.angleTo(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function Utils.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.circlesOverlap(x1, y1, r1, x2, y2, r2)
    local dx, dy = x2 - x1, y2 - y1
    local rsum = r1 + r2
    return (dx * dx + dy * dy) <= rsum * rsum
end

--- Shortest distance from point (px,py) to the line segment (x1,y1)-(x2,y2).
function Utils.pointToSegmentDist(px, py, x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local len2 = dx * dx + dy * dy
    if len2 == 0 then return Utils.distance(px, py, x1, y1) end
    local t = Utils.clamp(((px - x1) * dx + (py - y1) * dy) / len2, 0, 1)
    return Utils.distance(px, py, x1 + t * dx, y1 + t * dy)
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

--- Shuffle array in-place.
function Utils.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

return Utils
