-- background.lua
-- Draws the arena floor with an angled tile grid, walls with visible depth,
-- and a dark void beyond.

local Background = {}

-- Arena bounds in game-space
Background.ARENA = { x = 50, y = 40, w = 700, h = 520 }

local TILE = 48
local WALL_DEPTH = 18   -- visible south-wall thickness

local FLOOR_COLORS = {
    { 0.10, 0.11, 0.14 },
    { 0.11, 0.12, 0.16 },
    { 0.09, 0.10, 0.13 },
    { 0.10, 0.11, 0.15 },
}

function Background.draw()
    local A = Background.ARENA

    -- Floor tiles
    local cols = math.ceil(A.w / TILE)
    local rows = math.ceil(A.h / TILE)
    for r = 0, rows do
        for c = 0, cols do
            local ci = ((c * 7 + r * 13) % #FLOOR_COLORS) + 1
            local clr = FLOOR_COLORS[ci]
            love.graphics.setColor(clr[1], clr[2], clr[3], 1)
            local tx = A.x + c * TILE
            local ty = A.y + r * TILE
            local tw = math.min(TILE, A.x + A.w - tx)
            local th = math.min(TILE, A.y + A.h - ty)
            if tw > 0 and th > 0 then
                love.graphics.rectangle("fill", tx, ty, tw, th)
            end
        end
    end

    -- Grid lines
    love.graphics.setColor(0.16, 0.17, 0.22, 0.4)
    for r = 0, rows do
        local y = A.y + r * TILE
        love.graphics.line(A.x, y, A.x + A.w, y)
    end
    for c = 0, cols do
        local x = A.x + c * TILE
        love.graphics.line(x, A.y, x, A.y + A.h)
    end

    -- South wall face (depth effect)
    love.graphics.setColor(0.06, 0.06, 0.09, 1)
    love.graphics.rectangle("fill", A.x, A.y + A.h, A.w, WALL_DEPTH)
    love.graphics.setColor(0.12, 0.12, 0.18, 0.6)
    love.graphics.line(A.x, A.y + A.h, A.x + A.w, A.y + A.h)

    -- East wall face
    love.graphics.setColor(0.05, 0.05, 0.08, 1)
    local pts = {
        A.x + A.w, A.y,
        A.x + A.w + WALL_DEPTH * 0.5, A.y + WALL_DEPTH * 0.4,
        A.x + A.w + WALL_DEPTH * 0.5, A.y + A.h + WALL_DEPTH * 0.4,
        A.x + A.w, A.y + A.h,
    }
    love.graphics.polygon("fill", pts)

    -- Arena border (top surface edge)
    love.graphics.setColor(0.28, 0.30, 0.42, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", A.x, A.y, A.w, A.h)
    love.graphics.setLineWidth(1)

    -- Corner accents
    local cn = 10
    love.graphics.setColor(0.45, 0.50, 0.70, 0.6)
    -- top-left
    love.graphics.line(A.x, A.y, A.x + cn, A.y)
    love.graphics.line(A.x, A.y, A.x, A.y + cn)
    -- top-right
    love.graphics.line(A.x + A.w, A.y, A.x + A.w - cn, A.y)
    love.graphics.line(A.x + A.w, A.y, A.x + A.w, A.y + cn)
    -- bottom-left
    love.graphics.line(A.x, A.y + A.h, A.x + cn, A.y + A.h)
    love.graphics.line(A.x, A.y + A.h, A.x, A.y + A.h - cn)
    -- bottom-right
    love.graphics.line(A.x + A.w, A.y + A.h, A.x + A.w - cn, A.y + A.h)
    love.graphics.line(A.x + A.w, A.y + A.h, A.x + A.w, A.y + A.h - cn)
end

return Background
