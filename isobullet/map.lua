-- map.lua
-- Isometric grid map with walls, coordinate conversion, line-of-sight,
-- standard raycast, raycast-with-normal, and reflecting raycast.

local Utils = require("utils")

local Map = {}
Map.GW, Map.GH = 24, 18
Map.TILE_W, Map.TILE_H = 48, 24
Map.CAMERA_OFFSET_Y = 140

Map.cells = {}   -- [row][col]  0 = floor, 1 = wall
Map.screenW = 1024
Map.screenH = 720

function Map.setScreenSize(w, h)
    Map.screenW = w
    Map.screenH = h
end

--------------------------------------------------------------------------------
-- Coordinate conversion
--------------------------------------------------------------------------------

function Map.gridToScreen(gx, gy)
    local sx = Map.screenW / 2 + (gx - gy) * Map.TILE_W / 2
    local sy = Map.screenH / 2 + (gx + gy) * Map.TILE_H / 2 - Map.CAMERA_OFFSET_Y
    return sx, sy
end

--- Convert a screen-space direction vector to grid-space.
function Map.screenDirToGridDir(sdx, sdy)
    local gdx = sdx / Map.TILE_W + sdy / Map.TILE_H
    local gdy = -sdx / Map.TILE_W + sdy / Map.TILE_H
    return gdx, gdy
end

function Map.screenToGrid(sx, sy)
    local rx = (sx - Map.screenW / 2) / (Map.TILE_W / 2)
    local ry = (sy - Map.screenH / 2 + Map.CAMERA_OFFSET_Y) / (Map.TILE_H / 2)
    local gx = (rx + ry) / 2
    local gy = (ry - rx) / 2
    return gx, gy
end

--------------------------------------------------------------------------------
-- Wall queries
--------------------------------------------------------------------------------

function Map.isWall(gx, gy)
    local ix = math.floor(gx + 0.5)
    local iy = math.floor(gy + 0.5)
    if ix < 1 or ix > Map.GW or iy < 1 or iy > Map.GH then return true end
    return Map.cells[iy] and Map.cells[iy][ix] == 1
end

function Map.lineOfSight(x0, y0, x1, y1, steps)
    steps = steps or 50
    for i = 0, steps do
        local t = i / steps
        local x = x0 + (x1 - x0) * t
        local y = y0 + (y1 - y0) * t
        if Map.isWall(x, y) then return false end
    end
    return true
end

--------------------------------------------------------------------------------
-- Raycasting
--------------------------------------------------------------------------------

--- Basic raycast — returns the point just before a wall hit.
function Map.raycast(x0, y0, dx, dy, maxLen)
    maxLen = maxLen or 20
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return x0, y0 end
    dx, dy = dx / len, dy / len
    local steps = math.ceil(maxLen * 6)
    for i = 1, steps do
        local t = i / steps * maxLen
        local x = x0 + dx * t
        local y = y0 + dy * t
        if Map.isWall(x, y) then
            local prevT = (i - 1) / steps * maxLen
            return x0 + dx * prevT, y0 + dy * prevT
        end
    end
    return x0 + dx * maxLen, y0 + dy * maxLen
end

--- Raycast that also returns the wall normal at the hit point.
--- Returns  hitX, hitY, normalX, normalY   (normals are nil if no wall hit).
function Map.raycastWithNormal(x0, y0, dx, dy, maxLen)
    maxLen = maxLen or 25
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return x0, y0, nil, nil end
    dx, dy = dx / len, dy / len
    local steps = math.ceil(maxLen * 10)
    local prevX, prevY = x0, y0
    for i = 1, steps do
        local t = i / steps * maxLen
        local x = x0 + dx * t
        local y = y0 + dy * t
        if Map.isWall(x, y) then
            -- Determine which face was hit via axis separation
            local wallInX = Map.isWall(x, prevY)
            local wallInY = Map.isWall(prevX, y)
            local nx, ny = 0, 0
            if wallInX and not wallInY then
                -- X-movement entered a wall → vertical face → reflect X
                nx = dx > 0 and -1 or 1
            elseif wallInY and not wallInX then
                -- Y-movement entered a wall → horizontal face → reflect Y
                ny = dy > 0 and -1 or 1
            else
                -- Corner or ambiguous — reflect both
                nx = dx > 0 and -1 or 1
                ny = dy > 0 and -1 or 1
                local nlen = math.sqrt(nx * nx + ny * ny)
                nx, ny = nx / nlen, ny / nlen
            end
            return prevX, prevY, nx, ny
        end
        prevX, prevY = x, y
    end
    return x0 + dx * maxLen, y0 + dy * maxLen, nil, nil
end

--- Reflecting raycast — traces a ray that bounces off walls.
--- Returns a list of segments: { {x1,y1,x2,y2}, ... }
function Map.reflectRaycast(x0, y0, dx, dy, maxBounces, maxTotalLen)
    maxTotalLen = maxTotalLen or 30
    local segments = {}
    local cx, cy = x0, y0
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return segments end
    local cdx, cdy = dx / len, dy / len
    local remaining = maxTotalLen

    for _ = 0, maxBounces do
        local hx, hy, nx, ny = Map.raycastWithNormal(cx, cy, cdx, cdy, remaining)
        local segLen = Utils.distance(cx, cy, hx, hy)
        table.insert(segments, { x1 = cx, y1 = cy, x2 = hx, y2 = hy })
        remaining = remaining - segLen
        if not nx or remaining <= 0.5 then break end
        -- Reflect direction off wall normal
        cdx, cdy = Utils.reflect(cdx, cdy, nx, ny)
        -- Nudge off wall to avoid re-hitting same surface
        cx = hx + nx * 0.08
        cy = hy + ny * 0.08
    end

    return segments
end

--------------------------------------------------------------------------------
-- Map generation
--------------------------------------------------------------------------------

function Map.build()
    for iy = 1, Map.GH do
        Map.cells[iy] = {}
        for ix = 1, Map.GW do
            if ix == 1 or ix == Map.GW or iy == 1 or iy == Map.GH then
                -- Border walls
                Map.cells[iy][ix] = 1
            elseif (ix == 7 or ix == 18) and iy >= 5 and iy <= 7 then
                -- Top pillars
                Map.cells[iy][ix] = 1
            elseif (ix == 7 or ix == 18) and iy >= 11 and iy <= 13 then
                -- Bottom pillars
                Map.cells[iy][ix] = 1
            elseif iy == 9 and ix >= 11 and ix <= 14 then
                -- Center horizontal bar
                Map.cells[iy][ix] = 1
            else
                Map.cells[iy][ix] = 0
            end
        end
    end
end

return Map
