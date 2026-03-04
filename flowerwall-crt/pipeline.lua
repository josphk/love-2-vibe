-- 4-pass canvas pipeline: pre-blur → CRT → bloom threshold → bloom blur → composite

local Pipeline = {}

Pipeline.enabled = true
Pipeline.params = {}

local scene, blurA, blurB, crtOut, bloomA, bloomB
local blurShader, crtShader, thresholdShader, bloomShader
local noiseTexture
local canvasW, canvasH, bloomW, bloomH

local function createCanvases(w, h)
    canvasW, canvasH = w, h
    bloomW = math.floor(w / 2)
    bloomH = math.floor(h / 2)

    scene  = love.graphics.newCanvas(w, h)
    blurA  = love.graphics.newCanvas(w, h)
    blurB  = love.graphics.newCanvas(w, h)
    crtOut = love.graphics.newCanvas(w, h)
    bloomA = love.graphics.newCanvas(bloomW, bloomH)
    bloomB = love.graphics.newCanvas(bloomW, bloomH)

    blurA:setFilter("linear", "linear")
    blurB:setFilter("linear", "linear")
    crtOut:setFilter("linear", "linear")
    bloomA:setFilter("linear", "linear")
    bloomB:setFilter("linear", "linear")
end

function Pipeline.init(shaders, noise, presets)
    createCanvases(love.graphics.getDimensions())

    blurShader      = love.graphics.newShader(shaders.blur)
    crtShader       = love.graphics.newShader(shaders.crt)
    thresholdShader = love.graphics.newShader(shaders.threshold)
    bloomShader     = love.graphics.newShader(shaders.bloom)

    noiseTexture = noise
    crtShader:send("noise_texture", noiseTexture)

    Pipeline.applyPreset(presets[1])
end

function Pipeline.resize(w, h)
    createCanvases(w, h)
end

function Pipeline.getDimensions()
    return canvasW, canvasH
end

function Pipeline.applyPreset(preset)
    for k, v in pairs(preset.params) do
        Pipeline.params[k] = v
    end
end

local function sendParams()
    local p = Pipeline.params

    blurShader:send("resolution", {canvasW, canvasH})
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
    bloomShader:send("bloom_resolution", {bloomW, bloomH})
end

function Pipeline.beginDraw()
    love.graphics.setCanvas(scene)
    love.graphics.clear(0, 0, 0, 1)
end

function Pipeline.endDraw()
    love.graphics.setCanvas()

    if not Pipeline.enabled then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(scene)
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
    love.graphics.draw(crtOut, 0, 0, 0, bloomW / canvasW, bloomH / canvasH)
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
    love.graphics.draw(crtOut)

    -- Additive bloom overlay
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, Pipeline.params.bloom_intensity)
    love.graphics.draw(bloomB, 0, 0, 0,
        canvasW / bloomW,
        canvasH / bloomH)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function Pipeline.toggle()
    Pipeline.enabled = not Pipeline.enabled
end

return Pipeline
