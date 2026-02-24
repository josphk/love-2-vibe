-- hud.lua
-- Heads-up display: score, lives, bombs, wave indicator, bullet count, power.

local HUD = {}

function HUD.draw(player, spawner, bulletPool, screenW, screenH)
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()

    -- Top-left: Score
    love.graphics.print(string.format("SCORE  %08d", player.score), 10, 8)

    -- Top-left below score: Graze counter
    love.graphics.setColor(0.7, 0.7, 1.0, 0.9)
    love.graphics.print(string.format("GRAZE  %d", player.graze), 10, 26)

    -- Top-right: Wave
    love.graphics.setColor(1, 1, 0.5, 1)
    local waveText
    if spawner.endless then
        waveText = string.format("WAVE  ENDLESS (x%.1f)", spawner.difficulty)
    else
        waveText = string.format("WAVE  %d / %d", spawner.wave, 5)
    end
    love.graphics.print(waveText, screenW - font:getWidth(waveText) - 10, 8)

    -- Bottom-left: Lives
    love.graphics.setColor(1, 0.3, 0.3, 1)
    local livesStr = "LIVES  "
    for i = 1, player.lives do
        livesStr = livesStr .. "♥ "
    end
    love.graphics.print(livesStr, 10, screenH - 55)

    -- Bottom-left: Bombs
    love.graphics.setColor(0.3, 0.8, 1, 1)
    local bombStr = "BOMBS  "
    for i = 1, player.bombs do
        bombStr = bombStr .. "★ "
    end
    love.graphics.print(bombStr, 10, screenH - 38)

    -- Bottom-left: Power level
    love.graphics.setColor(1, 0.8, 0.2, 1)
    love.graphics.print(string.format("POWER  %d / 4", player.power), 10, screenH - 21)

    -- Bottom-right: bullet count (debug)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
    local bcount = bulletPool:countEnemy()
    local bcText = string.format("bullets: %d", bcount)
    love.graphics.print(bcText, screenW - font:getWidth(bcText) - 10, screenH - 21)

    -- Wave announcement
    if spawner.betweenWaves and spawner.betweenTimer > 0 then
        love.graphics.setColor(1, 1, 1, math.min(1, spawner.betweenTimer))
        local ann
        if spawner.wave == 0 then
            ann = "GET READY!"
        else
            ann = string.format("WAVE %d CLEAR!", spawner.wave)
        end
        local aw = font:getWidth(ann)
        love.graphics.print(ann, (screenW - aw) / 2, screenH / 2 - 20)
    end
end

return HUD
