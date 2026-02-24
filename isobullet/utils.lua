-- utils.lua
-- Shared math, collision, and table utilities.

local Utils = {}

function Utils.distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.normalize(dx, dy)
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return 0, 0 end
    return dx / len, dy / len
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

--- Reflect vector (vx,vy) across normal (nx,ny).
function Utils.reflect(vx, vy, nx, ny)
    local dot = vx * nx + vy * ny
    return vx - 2 * dot * nx, vy - 2 * dot * ny
end

function Utils.circlesOverlap(x1, y1, r1, x2, y2, r2)
    local dx, dy = x2 - x1, y2 - y1
    local rsum = r1 + r2
    return (dx * dx + dy * dy) <= rsum * rsum
end

--- Shortest distance from point (px,py) to line segment (x1,y1)-(x2,y2).
function Utils.pointToSegmentDist(px, py, x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local len2 = dx * dx + dy * dy
    if len2 == 0 then return Utils.distance(px, py, x1, y1) end
    local t = Utils.clamp(((px - x1) * dx + (py - y1) * dy) / len2, 0, 1)
    return Utils.distance(px, py, x1 + t * dx, y1 + t * dy)
end

--- Remove entries where entry[field] is truthy, in-place.
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
