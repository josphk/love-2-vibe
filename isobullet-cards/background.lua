-- background.lua
-- Isometric floor tiles and 3D wall blocks.
-- Walls are drawn with visible south-west and south-east depth faces
-- to create a raised block appearance.

local Map = require("map")

local Background = {}

local WALL_H = 10   -- wall height in pixels (cosmetic depth)

function Background.draw()
    local tw, th = Map.TILE_W, Map.TILE_H
    local hw, hh = tw / 2, th / 2

    for iy = 1, Map.GH do
        for ix = 1, Map.GW do
            local sx, sy = Map.gridToScreen(ix, iy)

            if Map.cells[iy][ix] == 0 then
                ---- Floor tile ----
                -- Subtle color variation via hash
                local ci = ((ix * 7 + iy * 13) % 4)
                local shade = 0.11 + ci * 0.008
                love.graphics.setColor(shade, shade, shade + 0.03, 1)
                love.graphics.polygon("fill",
                    sx - hw, sy, sx, sy - hh, sx + hw, sy, sx, sy + hh)

                -- Grid line
                love.graphics.setColor(0.17, 0.16, 0.22, 0.35)
                love.graphics.polygon("line",
                    sx - hw, sy, sx, sy - hh, sx + hw, sy, sx, sy + hh)
            else
                ---- Wall block (3D raised) ----
                -- South-west face (left visible side)
                love.graphics.setColor(0.18, 0.16, 0.25)
                love.graphics.polygon("fill",
                    sx - hw, sy,
                    sx, sy + hh,
                    sx, sy + hh - WALL_H,
                    sx - hw, sy - WALL_H)

                -- South-east face (right visible side)
                love.graphics.setColor(0.14, 0.12, 0.20)
                love.graphics.polygon("fill",
                    sx, sy + hh,
                    sx + hw, sy,
                    sx + hw, sy - WALL_H,
                    sx, sy + hh - WALL_H)

                -- Top face (raised diamond)
                love.graphics.setColor(0.28, 0.26, 0.36)
                love.graphics.polygon("fill",
                    sx - hw, sy - WALL_H,
                    sx, sy - hh - WALL_H,
                    sx + hw, sy - WALL_H,
                    sx, sy + hh - WALL_H)

                -- Top face edge glow
                love.graphics.setColor(0.42, 0.38, 0.55, 0.5)
                love.graphics.polygon("line",
                    sx - hw, sy - WALL_H,
                    sx, sy - hh - WALL_H,
                    sx + hw, sy - WALL_H,
                    sx, sy + hh - WALL_H)
            end
        end
    end
end

return Background
