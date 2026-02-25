-- debug_ui.lua
-- Debug overlay for tweaking CRT post-processing parameters in real-time.
-- F1 toggles the panel. Arrow keys navigate and adjust values.

local CRT = require("crt")

local DebugUI = {}

DebugUI.active = false

local selected = 1
local font = nil

function DebugUI.keypressed(key)
    if key == "f1" then
        DebugUI.active = not DebugUI.active
        return true
    end

    if not DebugUI.active then return false end

    local params = CRT.debugParams

    if key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #params end
        return true
    elseif key == "down" then
        selected = selected + 1
        if selected > #params then selected = 1 end
        return true
    elseif key == "left" or key == "right" then
        local p = params[selected]
        local dir = key == "right" and 1 or -1

        if p.type == "bool" then
            p.set(not p.get())
        elseif p.type == "discrete" then
            local idx = p.get() + dir
            if idx < 1 then idx = #p.options end
            if idx > #p.options then idx = 1 end
            p.set(idx)
        elseif p.type == "continuous" then
            local v = p.get() + dir * p.step
            v = math.max(p.min, math.min(p.max, v))
            -- Round to avoid float drift
            v = math.floor(v / p.step + 0.5) * p.step
            p.set(v)
        end
        return true
    end

    return false
end

local function formatValue(p)
    if p.type == "bool" then
        return p.get() and "ON" or "OFF"
    elseif p.type == "discrete" then
        return tostring(p.options[p.get()])
    elseif p.type == "continuous" then
        return string.format("%.2f", p.get())
    end
    return "?"
end

function DebugUI.draw(screenW, screenH)
    if not DebugUI.active then return end

    -- Lazy-init font
    if not font then
        font = love.graphics.newFont(14)
    end

    local params = CRT.debugParams
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(font)

    local lineH = 20
    local padX, padY = 12, 10
    local panelW = 260
    local panelH = padY * 2 + #params * lineH + lineH  -- extra line for hints
    local panelX = screenW - panelW - 10
    local panelY = 10

    -- Background panel
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 4, 4)

    -- Parameter rows
    for i, p in ipairs(params) do
        local y = panelY + padY + (i - 1) * lineH

        if i == selected then
            love.graphics.setColor(0.3, 0.5, 0.9, 0.4)
            love.graphics.rectangle("fill", panelX + 2, y - 1, panelW - 4, lineH, 2, 2)
            love.graphics.setColor(0.5, 0.8, 1.0, 1.0)
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 0.9)
        end

        local val = formatValue(p)
        love.graphics.print(p.name, panelX + padX, y)
        love.graphics.printf(val, panelX, y, panelW - padX, "right")
    end

    -- Controls hint
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    local hintY = panelY + padY + #params * lineH
    love.graphics.print("Up/Down: select  Left/Right: adjust", panelX + padX, hintY)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(prevFont)
end

return DebugUI
