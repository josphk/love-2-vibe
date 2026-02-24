-- hud.lua
-- Screen-space HUD: lives, score, wave, bullet-time meter, crosshair.

local HUD = {}

function HUD.draw(player, spawner, bt, screenW, screenH)
    local font = love.graphics.getFont()

    ---------- Lives (top-left) ----------
    love.graphics.setColor(1, 0.35, 0.3, 1)
    local livesStr = "LIVES "
    for i = 1, player.lives do livesStr = livesStr .. "♥ " end
    love.graphics.print(livesStr, 12, 10)

    ---------- Score (top-right) ----------
    love.graphics.setColor(1, 1, 1, 0.9)
    local scoreStr = string.format("%08d", player.score)
    love.graphics.print(scoreStr, screenW - font:getWidth(scoreStr) - 12, 10)

    ---------- Wave (top-center) ----------
    love.graphics.setColor(1, 1, 0.5, 0.9)
    local waveStr
    if spawner.betweenWaves and spawner.wave > 0 then
        waveStr = string.format("WAVE %d CLEAR", spawner.wave)
    elseif spawner.wave == 0 then
        waveStr = "GET READY"
    else
        waveStr = string.format("WAVE %d", spawner.wave)
    end
    love.graphics.print(waveStr, (screenW - font:getWidth(waveStr)) / 2, 10)

    ---------- Graze (below lives) ----------
    love.graphics.setColor(0.7, 0.7, 1.0, 0.7)
    love.graphics.print(string.format("GRAZE %d", player.graze), 12, 28)

    ---------- Bullet-time meter (bottom-center) ----------
    local meterW = 180
    local meterH = 8
    local mx = (screenW - meterW) / 2
    local my = screenH - 24

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
    love.graphics.rectangle("fill", mx - 1, my - 1, meterW + 2, meterH + 2, 3, 3)

    -- Fill
    local frac = bt.meter / bt.maxMeter
    local mr, mg, mb = 0.3, 0.6, 1.0
    if bt.active then mr, mg, mb = 0.5, 0.8, 1.0 end
    if frac < 0.2 then mr, mg, mb = 1.0, 0.3, 0.2 end
    love.graphics.setColor(mr, mg, mb, 0.85)
    love.graphics.rectangle("fill", mx, my, meterW * frac, meterH, 2, 2)

    -- Label
    love.graphics.setColor(0.7, 0.8, 1.0, 0.6)
    local label = bt.active and "▶ BULLET TIME" or "CHRONO"
    love.graphics.print(label, mx + (meterW - font:getWidth(label)) / 2, my - 16)

    ---------- Controls hint (bottom-left, fades out) ----------
    if spawner.gameTime < 12 then
        local a = math.max(0, 1 - spawner.gameTime / 12)
        love.graphics.setColor(0.6, 0.6, 0.6, a * 0.6)
        love.graphics.print("WASD: move   LMB: slow time → aim → fire   RMB: cancel", 12, screenH - 22)
    end
end

--- Draw the custom crosshair (call last, in screen space).
function HUD.drawCrosshair(btActive, screenW, screenH)
    local mx, my = love.mouse.getPosition()

    if btActive then
        -- Large crosshair during bullet time
        local s = 14
        love.graphics.setColor(0.5, 0.8, 1.0, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.line(mx - s, my, mx - 5, my)
        love.graphics.line(mx + 5, my, mx + s, my)
        love.graphics.line(mx, my - s, mx, my - 5)
        love.graphics.line(mx, my + 5, mx, my + s)
        love.graphics.setLineWidth(1)
        -- Center dot
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", mx, my, 2)
        -- Outer ring
        love.graphics.setColor(0.4, 0.6, 1.0, 0.3)
        love.graphics.circle("line", mx, my, 20)
    else
        -- Small crosshair during normal play
        local s = 7
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.line(mx - s, my, mx - 2, my)
        love.graphics.line(mx + 2, my, mx + s, my)
        love.graphics.line(mx, my - s, mx, my - 2)
        love.graphics.line(mx, my + 2, mx, my + s)
        love.graphics.circle("fill", mx, my, 1)
    end
end

return HUD
