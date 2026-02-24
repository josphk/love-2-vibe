-- utils.lua
-- Utility functions used across the project

local Utils = {}

--- Euclidean distance between two points
function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

--- Angle from (x1,y1) toward (x2,y2) in radians
function Utils.angleTo(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

--- Clamp value between min and max
function Utils.clamp(val, lo, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

--- Linear interpolation
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

--- Check circle-circle collision
function Utils.circlesOverlap(x1, y1, r1, x2, y2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist2 = dx * dx + dy * dy
    local rsum = r1 + r2
    return dist2 <= rsum * rsum
end

--- Remove dead entries from an array in-place (stable)
function Utils.sweep(list, field)
    field = field or "dead"
    local j = 1
    for i = 1, #list do
        if not list[i][field] then
            if i ~= j then
                list[j] = list[i]
                list[i] = nil
            end
            j = j + 1
        else
            list[i] = nil
        end
    end
end

--- Simple deep-copy for tables (no metatables)
function Utils.shallowCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end

return Utils
