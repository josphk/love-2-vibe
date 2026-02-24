-- map.lua
-- Isometric grid map: build, coordinate conversion, line-of-sight, raycast.

local Utils = require("utils")

local Map = {}
Map.GW, Map.GH = 24, 18
Map.TILE_W, Map.TILE_H = 48, 24
Map.CAMERA_OFFSET_Y = 140

Map.cells = {}  -- [row][col] = 0 floor, 1 wall
Map.screenW = 800
Map.screenH = 600

function Map.setScreenSize(w, h)
    Map.screenW = w
    Map.screenH = h
end

function Map.gridToScreen(gx, gy)
    local sx = Map.screenW / 2 + (gx - gy) * Map.TILE_W / 2
    local sy = Map.screenH / 2 + (gx + gy) * Map.TILE_H / 2 - Map.CAMERA_OFFSET_Y
    return sx, sy
end

function Map.screenToGrid(sx, sy)
    local rx = (sx - Map.screenW / 2) / (Map.TILE_W / 2)
    local ry = (sy - Map.screenH / 2 + Map.CAMERA_OFFSET_Y) / (Map.TILE_H / 2)
    local gx = (rx + ry) / 2
    local gy = (ry - rx) / 2
    return gx, gy
end

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

function Map.raycast(x0, y0, dx, dy, maxLen)
    maxLen = maxLen or 20
    local steps = math.ceil(maxLen * 4)
    for i = 1, steps do
        local t = i / steps * maxLen
        local x = x0 + dx * t
        local y = y0 + dy * t
        if Map.isWall(x, y) then
            return x0 + dx * (t - maxLen / steps), y0 + dy * (t - maxLen / steps)
        end
    end
    return x0 + dx * maxLen, y0 + dy * maxLen
end

function Map.build()
    for iy = 1, Map.GH do
        Map.cells[iy] = {}
        for ix = 1, Map.GW do
            if ix == 1 or ix == Map.GW or iy == 1 or iy == Map.GH then
                Map.cells[iy][ix] = 1
            elseif (ix == 6 or ix == 18) and iy >= 5 and iy <= 14 then
                Map.cells[iy][ix] = 1
            elseif (iy == 6 or iy == 12) and ix >= 8 and ix <= 16 then
                Map.cells[iy][ix] = 1
            else
                Map.cells[iy][ix] = 0
            end
        end
    end
    -- Spawn points clear (row, col) so floor at (gx, gy) = (col, row)
    local clear = { {4,4},{4,5}, {15,20},{15,19}, {17,12},{17,13}, {10,14},{10,15}, {8,18},{8,17} }
    for _, p in ipairs(clear) do
        local row, col = p[1], p[2]
        if Map.cells[row] and Map.cells[row][col] then Map.cells[row][col] = 0 end
    end
end

return Map
