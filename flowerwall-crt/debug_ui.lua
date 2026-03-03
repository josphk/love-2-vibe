-- Debug overlay: F1 panel with preset buttons and mouse-driven sliders.

local DebugUI = {}

DebugUI.visible = false

local pipeline_ref
local presets_ref
local activePreset = 1

local PANEL_W = 310
local MARGIN  = 10
local ROW_H   = 22
local SLIDER_H = 14
local BTN_H   = 28

local dragging = nil  -- index into controls list

-- Ordered list of parameter controls built once at init
local controls = {}

-- Parameter definitions grouped by feature
local groups = {
    { name = "Pre-Blur", params = {
        { key = "blur_radius", label = "Blur Radius", min = 0, max = 15, step = 0.5 },
    }},
    { name = "Mask", params = {
        { key = "mask_type", label = "Mask Type", type = "radio",
          options = { "None", "Slot", "Grid" } },
        { key = "mask_strength", label = "Strength", min = 0, max = 1, step = 0.05 },
        { key = "pixel_size", label = "Pixel Size", min = 3, max = 6, step = 1 },
    }},
    { name = "Scanlines", params = {
        { key = "enable_scanlines", label = "Scanlines", type = "toggle" },
        { key = "scanlines_interval", label = "Interval", min = 1, max = 20, step = 1 },
        { key = "scanlines_opacity", label = "Opacity", min = 0, max = 1, step = 0.05 },
        { key = "scanlines_thickness", label = "Thickness", min = 0, max = 10, step = 1 },
    }},
    { name = "Grain", params = {
        { key = "enable_grain", label = "Grain", type = "toggle" },
        { key = "grain_strength", label = "Strength", min = 0, max = 1, step = 0.05 },
    }},
    { name = "Curving", params = {
        { key = "enable_curving", label = "Barrel Dist.", type = "toggle" },
        { key = "curve_power", label = "Power", min = 1.0, max = 1.1, step = 0.005 },
    }},
    { name = "VHS Smearing", params = {
        { key = "enable_smearing", label = "Smearing", type = "toggle" },
        { key = "smearing_strength", label = "Strength", min = 0, max = 1, step = 0.05 },
    }},
    { name = "VHS Wiggle", params = {
        { key = "enable_wiggle", label = "Wiggle", type = "toggle" },
        { key = "wiggle", label = "Amount", min = 0, max = 0.2, step = 0.01 },
    }},
    { name = "Bloom", params = {
        { key = "bloom_threshold", label = "Threshold", min = 0, max = 1, step = 0.02 },
        { key = "bloom_intensity", label = "Intensity", min = 0, max = 2, step = 0.05 },
    }},
}

-- Map mask_type radio to enable_slotmask / enable_gridmask
local function getMaskType()
    local p = pipeline_ref.params
    if p.enable_gridmask > 0.5 then return 3 end
    if p.enable_slotmask > 0.5 then return 2 end
    return 1
end

local function setMaskType(idx)
    local p = pipeline_ref.params
    p.enable_slotmask = (idx == 2) and 1 or 0
    p.enable_gridmask = (idx == 3) and 1 or 0
end

function DebugUI.init(pipeline, presets)
    pipeline_ref = pipeline
    presets_ref  = presets
end

function DebugUI.toggle()
    DebugUI.visible = not DebugUI.visible
end

-- Layout helpers
local function panelX()
    return love.graphics.getWidth() - PANEL_W
end

local function sliderRect(y)
    local x = panelX() + MARGIN + 100
    return x, y + 3, PANEL_W - MARGIN * 2 - 110, SLIDER_H
end

-- Hit test helpers
local function pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

-- Build the control layout (called each frame for simplicity)
local function layoutControls()
    controls = {}
    local y = 6 + BTN_H + MARGIN + (math.ceil(#presets_ref / 3)) * (BTN_H + 4) + MARGIN
    local px = panelX()

    for _, g in ipairs(groups) do
        -- group header
        table.insert(controls, { type = "header", label = g.name, y = y })
        y = y + ROW_H

        for _, p in ipairs(g.params) do
            local ctrl = { y = y, def = p }

            if p.type == "toggle" then
                ctrl.type = "toggle"
            elseif p.type == "radio" then
                ctrl.type = "radio"
            else
                ctrl.type = "slider"
            end

            table.insert(controls, ctrl)
            y = y + ROW_H
        end
        y = y + 4
    end
end

function DebugUI.draw()
    if not DebugUI.visible then return end

    local sw, sh = love.graphics.getDimensions()
    local px = panelX()
    local font = love.graphics.getFont()

    -- Panel background
    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", px, 0, PANEL_W, sh)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("line", px, 0, PANEL_W, sh)

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Flowerwall CRT", px + MARGIN, 8)

    -- Pipeline toggle status
    local statusText = pipeline_ref.enabled and "ON" or "OFF"
    local statusColor = pipeline_ref.enabled and {0.3, 1, 0.3} or {1, 0.3, 0.3}
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("F2: " .. statusText, px + MARGIN + 160, 8)

    -- Preset buttons (3 per row)
    local btnW = math.floor((PANEL_W - MARGIN * 2 - 8) / 3)
    local by = 30
    for i, p in ipairs(presets_ref) do
        local col = ((i - 1) % 3)
        local row = math.floor((i - 1) / 3)
        local bx = px + MARGIN + col * (btnW + 4)
        local bby = by + row * (BTN_H + 4)

        if i == activePreset then
            love.graphics.setColor(0.25, 0.45, 0.7, 1)
        else
            love.graphics.setColor(0.18, 0.18, 0.18, 1)
        end
        love.graphics.rectangle("fill", bx, bby, btnW, BTN_H, 3, 3)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.rectangle("line", bx, bby, btnW, BTN_H, 3, 3)
        love.graphics.setColor(1, 1, 1, 1)
        local tw = font:getWidth(p.name)
        love.graphics.print(p.name, bx + (btnW - tw) / 2, bby + 6)
    end

    -- Controls
    layoutControls()
    local params = pipeline_ref.params

    for ci, ctrl in ipairs(controls) do
        local cy = ctrl.y

        if ctrl.type == "header" then
            love.graphics.setColor(0.6, 0.8, 1, 1)
            love.graphics.print(ctrl.label, px + MARGIN, cy + 2)
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.line(px + MARGIN, cy + ROW_H - 2, px + PANEL_W - MARGIN, cy + ROW_H - 2)

        elseif ctrl.type == "toggle" then
            local val = params[ctrl.def.key] or 0
            local on = val > 0.5
            love.graphics.setColor(0.75, 0.75, 0.75, 1)
            love.graphics.print(ctrl.def.label, px + MARGIN, cy + 2)
            -- Toggle box
            local bx = px + PANEL_W - MARGIN - 40
            if on then
                love.graphics.setColor(0.3, 0.7, 0.3, 1)
            else
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
            end
            love.graphics.rectangle("fill", bx, cy + 3, 34, SLIDER_H, 3, 3)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(on and "ON" or "OFF", bx + 6, cy + 2)

        elseif ctrl.type == "radio" then
            love.graphics.setColor(0.75, 0.75, 0.75, 1)
            love.graphics.print(ctrl.def.label, px + MARGIN, cy + 2)
            local selected = getMaskType()
            local optW = math.floor((PANEL_W - MARGIN * 2 - 100 - 8) / #ctrl.def.options)
            for oi, opt in ipairs(ctrl.def.options) do
                local ox = px + MARGIN + 100 + (oi - 1) * (optW + 4)
                if oi == selected then
                    love.graphics.setColor(0.25, 0.45, 0.7, 1)
                else
                    love.graphics.setColor(0.2, 0.2, 0.2, 1)
                end
                love.graphics.rectangle("fill", ox, cy + 3, optW, SLIDER_H, 2, 2)
                love.graphics.setColor(1, 1, 1, 1)
                local tw = font:getWidth(opt)
                love.graphics.print(opt, ox + (optW - tw) / 2, cy + 2)
            end

        elseif ctrl.type == "slider" then
            local def = ctrl.def
            local val = params[def.key] or def.min
            local norm = (val - def.min) / (def.max - def.min)
            norm = math.max(0, math.min(1, norm))

            love.graphics.setColor(0.75, 0.75, 0.75, 1)
            love.graphics.print(def.label, px + MARGIN, cy + 2)

            -- Track
            local sx, sy, sw_track, sh_track = sliderRect(cy)
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", sx, sy, sw_track, sh_track, 2, 2)

            -- Fill
            love.graphics.setColor(0.3, 0.55, 0.8, 1)
            love.graphics.rectangle("fill", sx, sy, sw_track * norm, sh_track, 2, 2)

            -- Handle
            local hx = sx + sw_track * norm
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.circle("fill", hx, sy + sh_track / 2, 5)

            -- Value text
            love.graphics.setColor(0.9, 0.9, 0.9, 1)
            local fmt = def.step >= 1 and "%d" or "%.2f"
            love.graphics.print(string.format(fmt, val), sx + sw_track + 6, cy + 2)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function DebugUI.mousepressed(x, y, button)
    if not DebugUI.visible or button ~= 1 then return false end
    local px = panelX()
    if x < px then return false end

    -- Check preset buttons
    local btnW = math.floor((PANEL_W - MARGIN * 2 - 8) / 3)
    local by = 30
    for i, p in ipairs(presets_ref) do
        local col = ((i - 1) % 3)
        local row = math.floor((i - 1) / 3)
        local bx = px + MARGIN + col * (btnW + 4)
        local bby = by + row * (BTN_H + 4)
        if pointInRect(x, y, bx, bby, btnW, BTN_H) then
            activePreset = i
            pipeline_ref.applyPreset(presets_ref[i])
            return true
        end
    end

    -- Check controls
    layoutControls()
    for ci, ctrl in ipairs(controls) do
        if ctrl.type == "toggle" then
            local bx = px + PANEL_W - MARGIN - 40
            if pointInRect(x, y, bx, ctrl.y, 40, ROW_H) then
                local cur = pipeline_ref.params[ctrl.def.key] or 0
                pipeline_ref.params[ctrl.def.key] = cur > 0.5 and 0 or 1
                activePreset = 0
                return true
            end
        elseif ctrl.type == "radio" then
            local optW = math.floor((PANEL_W - MARGIN * 2 - 100 - 8) / #ctrl.def.options)
            for oi = 1, #ctrl.def.options do
                local ox = px + MARGIN + 100 + (oi - 1) * (optW + 4)
                if pointInRect(x, y, ox, ctrl.y, optW, ROW_H) then
                    setMaskType(oi)
                    activePreset = 0
                    return true
                end
            end
        elseif ctrl.type == "slider" then
            local sx, sy, sw, sh = sliderRect(ctrl.y)
            if pointInRect(x, y, sx - 6, sy - 4, sw + 12, sh + 8) then
                dragging = ci
                DebugUI.mousemoved(x, y, 0, 0)
                return true
            end
        end
    end

    return true  -- consume click on panel
end

function DebugUI.mousereleased(x, y, button)
    if button == 1 then dragging = nil end
end

function DebugUI.mousemoved(x, y, dx, dy)
    if not dragging then return end
    local ctrl = controls[dragging]
    if not ctrl or ctrl.type ~= "slider" then dragging = nil; return end

    local sx, _, sw = sliderRect(ctrl.y)
    local norm = (x - sx) / sw
    norm = math.max(0, math.min(1, norm))

    local def = ctrl.def
    local raw = def.min + norm * (def.max - def.min)
    local snapped = math.floor(raw / def.step + 0.5) * def.step
    snapped = math.max(def.min, math.min(def.max, snapped))
    pipeline_ref.params[def.key] = snapped
    activePreset = 0
end

return DebugUI
