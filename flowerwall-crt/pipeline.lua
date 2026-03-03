-- 4-pass canvas pipeline: pre-blur → CRT → bloom threshold → bloom blur → composite

local Pipeline = {}

local INTERNAL_W = 640
local INTERNAL_H = 480
local BLOOM_W = 320
local BLOOM_H = 240

Pipeline.INTERNAL_W = INTERNAL_W
Pipeline.INTERNAL_H = INTERNAL_H
Pipeline.enabled = true
Pipeline.params = {}

local scene, blurA, blurB, crtOut, bloomA, bloomB
local blurShader, crtShader, thresholdShader, bloomShader
local noiseTexture

function Pipeline.init(shaders, noise, presets)
    scene  = love.graphics.newCanvas(INTERNAL_W, INTERNAL_H)
    blurA  = love.graphics.newCanvas(INTERNAL_W, INTERNAL_H)
    blurB  = love.graphics.newCanvas(INTERNAL_W, INTERNAL_H)
    crtOut = love.graphics.newCanvas(INTERNAL_W, INTERNAL_H)
    bloomA = love.graphics.newCanvas(BLOOM_W, BLOOM_H)
    bloomB = love.graphics.newCanvas(BLOOM_W, BLOOM_H)

    scene:setFilter("nearest", "nearest")
    blurA:setFilter("linear", "linear")
    blurB:setFilter("linear", "linear")
    crtOut:setFilter("linear", "linear")
    bloomA:setFilter("linear", "linear")
    bloomB:setFilter("linear", "linear")

    blurShader      = love.graphics.newShader(shaders.blur)
    crtShader       = love.graphics.newShader(shaders.crt)
    thresholdShader = love.graphics.newShader(shaders.threshold)
    bloomShader     = love.graphics.newShader(shaders.bloom)

    noiseTexture = noise

    -- Static uniforms
    crtShader:send("noise_texture", noiseTexture)
    bloomShader:send("bloom_resolution", {BLOOM_W, BLOOM_H})

    Pipeline.applyPreset(presets[1])
end

function Pipeline.applyPreset(preset)
    for k, v in pairs(preset.params) do
        Pipeline.params[k] = v
    end
end

local function sendParams()
    local p = Pipeline.params

    blurShader:send("radius", p.blur_radius)

    crtShader:send("time", love.timer.getTime())
    crtShader:send("enable_slotmask",  p.enable_slotmask)
    crtShader:send("enable_gridmask",  p.enable_gridmask)
    crtShader:send("mask_strength",    p.mask_strength)
    crtShader:send("pixel_size",       p.pixel_size)
    crtShader:send("enable_grain",     p.enable_grain)
    crtShader:send("grain_strength",   p.grain_strength)
    crtShader:send("enable_curving",   p.enable_curving)
    crtShader:send("curve_power",      p.curve_power)
    crtShader:send("enable_scanlines", p.enable_scanlines)
    crtShader:send("scanlines_interval",  p.scanlines_interval)
    crtShader:send("scanlines_opacity",   p.scanlines_opacity)
    crtShader:send("scanlines_thickness", p.scanlines_thickness)
    crtShader:send("enable_smearing",  p.enable_smearing)
    crtShader:send("smearing_strength", p.smearing_strength)
    crtShader:send("enable_wiggle",    p.enable_wiggle)
    crtShader:send("wiggle",           p.wiggle)

    thresholdShader:send("threshold", p.bloom_threshold)
end

function Pipeline.beginDraw()
    love.graphics.setCanvas(scene)
    love.graphics.clear(0, 0, 0, 1)
end

function Pipeline.endDraw()
    love.graphics.setCanvas()

    local screenW, screenH = love.graphics.getDimensions()
    local scaleX = screenW / INTERNAL_W
    local scaleY = screenH / INTERNAL_H
    local scale  = math.min(scaleX, scaleY)
    local ox = (screenW - INTERNAL_W * scale) / 2
    local oy = (screenH - INTERNAL_H * scale) / 2

    if not Pipeline.enabled then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(scene, ox, oy, 0, scale, scale)
        return
    end

    sendParams()

    -- Pass 0: Horizontal pre-blur (scene → blurA)
    love.graphics.setCanvas(blurA)
    love.graphics.clear(0, 0, 0, 1)
    blurShader:send("step_dir", {1, 0})
    love.graphics.setShader(blurShader)
    love.graphics.draw(scene)
    love.graphics.setShader()

    -- Pass 1: Vertical pre-blur (blurA → blurB)
    love.graphics.setCanvas(blurB)
    love.graphics.clear(0, 0, 0, 1)
    blurShader:send("step_dir", {0, 1})
    love.graphics.setShader(blurShader)
    love.graphics.draw(blurA)
    love.graphics.setShader()

    -- Pass 2: CRT effects (blurB → crtOut)
    love.graphics.setCanvas(crtOut)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(crtShader)
    love.graphics.draw(blurB)
    love.graphics.setShader()

    -- Pass 3a: Bloom threshold (crtOut → bloomA, half-res)
    love.graphics.setCanvas(bloomA)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(thresholdShader)
    love.graphics.draw(crtOut, 0, 0, 0, BLOOM_W / INTERNAL_W, BLOOM_H / INTERNAL_H)
    love.graphics.setShader()

    -- Pass 3b: Bloom blur (bloomA → bloomB)
    love.graphics.setCanvas(bloomB)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(bloomShader)
    love.graphics.draw(bloomA)
    love.graphics.setShader()

    love.graphics.setCanvas()

    -- Final composite to screen
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(crtOut, ox, oy, 0, scale, scale)

    -- Additive bloom overlay
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, Pipeline.params.bloom_intensity)
    love.graphics.draw(bloomB, ox, oy, 0,
        scale * INTERNAL_W / BLOOM_W,
        scale * INTERNAL_H / BLOOM_H)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function Pipeline.toggle()
    Pipeline.enabled = not Pipeline.enabled
end

return Pipeline
