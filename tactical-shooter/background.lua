-- background.lua
-- Isometric floor and wall tiles.

local Map = require("map")

local Background = {}

function Background.draw()
    local tw, th = Map.TILE_W, Map.TILE_H
    local hw, hh = tw / 2, th / 2
    for iy = 1, Map.GH do
        for ix = 1, Map.GW do
            local sx, sy = Map.gridToScreen(ix, iy)
            if Map.cells[iy][ix] == 0 then
                love.graphics.setColor(0.25, 0.24, 0.28)
            else
                love.graphics.setColor(0.35, 0.32, 0.38)
            end
            love.graphics.polygon("fill", sx - hw, sy, sx, sy - hh, sx + hw, sy, sx, sy + hh)
            love.graphics.setColor(0.4, 0.38, 0.45)
            love.graphics.polygon("line", sx - hw, sy, sx, sy - hh, sx + hw, sy, sx, sy + hh)
        end
    end
end

return Background
