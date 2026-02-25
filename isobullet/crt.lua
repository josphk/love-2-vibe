-- crt.lua
-- Low-res canvas + CRT post-processing shader with bloom.
-- Renders the game at half resolution (512x360) then upscales through a GLSL
-- shader with ordered dithering, RGB subpixel mask, screen curvature, and scanlines.
-- Bloom extracts bright pixels, blurs them, and composites additively for neon glow.
-- F10 toggles the effect on/off. F5/F6/F7 cycle CRT parameters.

local CRT = {}

CRT.INTERNAL_W = 512
CRT.INTERNAL_H = 360
CRT.enabled = true

local canvas, crtShader
local bloomA, bloomB, thresholdShader, bloomShader
local BLOOM_W, BLOOM_H
local bayerTex

local BLOOM_THRESHOLD = 0.20
local BLOOM_INTENSITY = 0.9

-- Configurable CRT parameters
local crtColorNum = 8.0
local crtPixelSize = 1.0
local crtMaskIntensity = 0.3
local crtCurve = 0.12

local colorNumOptions = {2, 4, 8, 16}
local colorNumIndex = 3
local pixelSizeOptions = {1, 2, 3, 4}
local pixelSizeIndex = 1

--------------------------------------------------------------------------------
-- Shaders
--------------------------------------------------------------------------------

local crtShaderCode = [[
extern vec2 resolution;
extern float time;
extern float colorNum;
extern float pixelSize;
extern float maskIntensity;
extern float curve;
extern Image bayerTex;

float noise2d(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    // Horizontal noise shake (very subtle, updates once per second)
    float shake = noise2d(vec2(floor(uv.y * resolution.y), floor(time)));
    uv.x += (shake - 0.5) * 0.0005;

    // Screen curvature
    vec2 curveUV = uv * 2.0 - 1.0;
    vec2 offset = curveUV.yx * curve;
    curveUV += curveUV * offset * offset;
    uv = (curveUV + 1.0) * 0.5;

    // Power vignette from signed UVs
    vec2 edgeUV = max(1.0 - curveUV * curveUV, vec2(0.0));
    float vignette = pow(edgeUV.x * edgeUV.y, 0.4);

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0, 0.0, 0.0, 1.0);

    // CRT RGB subpixel mask with staggered cell layout
    vec2 pixelCoord = uv * resolution;
    vec2 coord = pixelCoord / pixelSize;
    vec2 cell_offset = vec2(0.0, fract(floor(coord.x) * 0.5));
    vec2 cellCenter = (floor(coord) + 0.5) * pixelSize / resolution;

    // Subpixel coordinates (3 sub-columns per cell)
    vec2 subcoord = coord * vec2(3.0, 1.0);
    float subCol = mod(floor(subcoord.x), 3.0);

    // RGB mask using step() for GLSL 1.20 compatibility
    vec3 mask = vec3(
        step(subCol, 0.5),
        step(0.5, subCol) * step(subCol, 1.5),
        step(1.5, subCol)
    );

    // Quadratic border falloff within sub-cell (scales with cell size)
    vec2 cell_uv = fract(subcoord + cell_offset) * 2.0 - 1.0;
    float borderCoeff = min((pixelSize - 1.0) * 0.8, 0.8);
    vec2 border2 = 1.0 - cell_uv * cell_uv * borderCoeff;
    float border = max(0.0, border2.x) * max(0.0, border2.y);

    // Cell-based chromatic aberration
    float SPREAD = 0.0025;
    float r = Texel(tex, vec2(cellCenter.x + SPREAD, cellCenter.y)).r;
    float g = Texel(tex, cellCenter).g;
    float b = Texel(tex, vec2(cellCenter.x - SPREAD, cellCenter.y)).b;
    vec3 col = vec3(r, g, b);

    // Saturation + brightness boost
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luma), col, 1.4);
    col *= 1.15;
    col = clamp(col, 0.0, 1.0);

    // 8x8 Bayer ordered dithering
    vec2 bayerCoord = (mod(pixelCoord, 8.0) + 0.5) / 8.0;
    float bayerValue = Texel(bayerTex, bayerCoord).r;
    float ditherAmount = 1.0 / colorNum;
    col += (bayerValue - 0.5) * ditherAmount;

    // Color quantization
    col = floor(col * (colorNum - 1.0) + 0.5) / (colorNum - 1.0);
    col = clamp(col, 0.0, 1.0);

    // Mask application (continuous blend)
    vec3 mask_color = mask * 3.0;
    col *= (1.0 + (mask_color - 1.0) * maskIntensity) * border;

    // Subtle horizontal CRT pulse
    col *= 1.0 + 0.03 * cos(pixelCoord.x / 60.0 + time * 20.0);

    // Scanlines (aligned to pixel grid, nearly static)
    float scanline = 1.0 - 0.25 * (0.5 + 0.5 * sin(pixelCoord.y * 3.14159 + time * 0.15));
    col *= scanline;

    // Vignette fade
    col *= vignette;

    return vec4(col, 1.0) * color;
}
]]

local thresholdShaderCode = [[
extern float threshold;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec4 c = Texel(tex, uv);
    float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    float contrib = max(0.0, luma - threshold) / max(1.0 - threshold, 0.001);
    return vec4(c.rgb * contrib, 1.0);
}
]]

local bloomShaderCode = [[
extern vec2 bloomRes;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec2 texel = 1.0 / bloomRes;
    vec4 bloom = vec4(0.0);
    vec2 point = vec2(16.0, 0.0) * inversesqrt(32.0);

    for (float i = 0.0; i < 32.0; i += 1.0) {
        point *= -mat2(0.7374, 0.6755, -0.6755, 0.7374);
        bloom += Texel(tex, uv + point * sqrt(i) * texel) * (1.0 - i / 32.0);
    }
    bloom *= 3.0 / 32.0;
    bloom += Texel(tex, uv) * 0.5;
    return bloom;
}
]]

--------------------------------------------------------------------------------
-- Init / lifecycle
--------------------------------------------------------------------------------

function CRT.init()
    canvas = love.graphics.newCanvas(CRT.INTERNAL_W, CRT.INTERNAL_H)
    canvas:setFilter("nearest", "nearest")

    BLOOM_W = math.floor(CRT.INTERNAL_W * 0.5)
    BLOOM_H = math.floor(CRT.INTERNAL_H * 0.5)
    bloomA = love.graphics.newCanvas(BLOOM_W, BLOOM_H)
    bloomB = love.graphics.newCanvas(BLOOM_W, BLOOM_H)
    bloomA:setFilter("linear", "linear")
    bloomB:setFilter("linear", "linear")

    -- Create 8x8 Bayer dithering texture
    local bayerMatrix = {
        { 0, 32,  8, 40,  2, 34, 10, 42},
        {48, 16, 56, 24, 50, 18, 58, 26},
        {12, 44,  4, 36, 14, 46,  6, 38},
        {60, 28, 52, 20, 62, 30, 54, 22},
        { 3, 35, 11, 43,  1, 33,  9, 41},
        {51, 19, 59, 27, 49, 17, 57, 25},
        {15, 47,  7, 39, 13, 45,  5, 37},
        {63, 31, 55, 23, 61, 29, 53, 21},
    }
    local bayerData = love.image.newImageData(8, 8)
    for y = 0, 7 do
        for x = 0, 7 do
            local val = bayerMatrix[y + 1][x + 1] / 64.0
            bayerData:setPixel(x, y, val, 0, 0, 1)
        end
    end
    bayerTex = love.graphics.newImage(bayerData)
    bayerTex:setFilter("nearest", "nearest")
    bayerTex:setWrap("repeat", "repeat")

    crtShader = love.graphics.newShader(crtShaderCode)
    crtShader:send("resolution", {CRT.INTERNAL_W, CRT.INTERNAL_H})
    crtShader:send("bayerTex", bayerTex)
    crtShader:send("colorNum", crtColorNum)
    crtShader:send("pixelSize", crtPixelSize)
    crtShader:send("maskIntensity", crtMaskIntensity)
    crtShader:send("curve", crtCurve)
    crtShader:send("time", 0.0)

    thresholdShader = love.graphics.newShader(thresholdShaderCode)
    thresholdShader:send("threshold", BLOOM_THRESHOLD)

    bloomShader = love.graphics.newShader(bloomShaderCode)
    bloomShader:send("bloomRes", {BLOOM_W, BLOOM_H})
end

function CRT.beginDraw()
    if not CRT.enabled then return end
    love.graphics.setCanvas(canvas)
end

function CRT.endDraw(screenW, screenH)
    if not CRT.enabled then return end
    love.graphics.setCanvas()

    -- 1. Extract bright pixels into bloom canvas (downscaled)
    love.graphics.setCanvas(bloomA)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(thresholdShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, 0, 0, 0, BLOOM_W / CRT.INTERNAL_W, BLOOM_H / CRT.INTERNAL_H)
    love.graphics.setShader()

    -- 2. Single-pass golden-angle spiral bloom (bloomA → bloomB)
    love.graphics.setCanvas(bloomB)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(bloomShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bloomA)
    love.graphics.setShader()

    -- 3. Composite bloom onto main canvas (additive)
    love.graphics.setCanvas(canvas)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, BLOOM_INTENSITY)
    love.graphics.draw(bloomB, 0, 0, 0, CRT.INTERNAL_W / BLOOM_W, CRT.INTERNAL_H / BLOOM_H)
    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()

    -- 4. Draw canvas to screen through CRT shader
    local scaleX = screenW / CRT.INTERNAL_W
    local scaleY = screenH / CRT.INTERNAL_H
    local scale = math.min(scaleX, scaleY)
    local ox = (screenW - CRT.INTERNAL_W * scale) / 2
    local oy = (screenH - CRT.INTERNAL_H * scale) / 2

    crtShader:send("time", love.timer.getTime())
    love.graphics.setShader(crtShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
    love.graphics.setShader()
end

function CRT.screenToCanvas(sx, sy, screenW, screenH)
    local scaleX = screenW / CRT.INTERNAL_W
    local scaleY = screenH / CRT.INTERNAL_H
    local scale = math.min(scaleX, scaleY)
    local ox = (screenW - CRT.INTERNAL_W * scale) / 2
    local oy = (screenH - CRT.INTERNAL_H * scale) / 2
    return (sx - ox) / scale, (sy - oy) / scale
end

function CRT.getMousePosition()
    local mx, my = love.mouse.getPosition()
    if not CRT.enabled then return mx, my end
    local sw, sh = love.graphics.getDimensions()
    return CRT.screenToCanvas(mx, my, sw, sh)
end

function CRT.toggle()
    CRT.enabled = not CRT.enabled
end

function CRT.getRenderSize()
    if CRT.enabled then
        return CRT.INTERNAL_W, CRT.INTERNAL_H
    else
        return love.graphics.getDimensions()
    end
end

function CRT.cycleColorNum(direction)
    colorNumIndex = colorNumIndex + direction
    if colorNumIndex > #colorNumOptions then colorNumIndex = 1 end
    if colorNumIndex < 1 then colorNumIndex = #colorNumOptions end
    crtColorNum = colorNumOptions[colorNumIndex]
    crtShader:send("colorNum", crtColorNum)
end

function CRT.cyclePixelSize(direction)
    pixelSizeIndex = pixelSizeIndex + direction
    if pixelSizeIndex > #pixelSizeOptions then pixelSizeIndex = 1 end
    if pixelSizeIndex < 1 then pixelSizeIndex = #pixelSizeOptions end
    crtPixelSize = pixelSizeOptions[pixelSizeIndex]
    crtShader:send("pixelSize", crtPixelSize)
end

function CRT.toggleBlending()
    if crtMaskIntensity < 1.0 then
        crtMaskIntensity = 1.0
    else
        crtMaskIntensity = 0.3
    end
    crtShader:send("maskIntensity", crtMaskIntensity)
end

--------------------------------------------------------------------------------
-- Debug parameter descriptors
--------------------------------------------------------------------------------
CRT.debugParams = {
    {
        name = "CRT Enabled",
        type = "bool",
        get = function() return CRT.enabled end,
        set = function(v) CRT.enabled = v end,
    },
    {
        name = "Color Levels",
        type = "discrete",
        options = colorNumOptions,
        get = function() return colorNumIndex end,
        set = function(i)
            colorNumIndex = i
            crtColorNum = colorNumOptions[i]
            if crtShader then crtShader:send("colorNum", crtColorNum) end
        end,
    },
    {
        name = "Pixel Size",
        type = "discrete",
        options = pixelSizeOptions,
        get = function() return pixelSizeIndex end,
        set = function(i)
            pixelSizeIndex = i
            crtPixelSize = pixelSizeOptions[i]
            if crtShader then crtShader:send("pixelSize", crtPixelSize) end
        end,
    },
    {
        name = "Mask Intensity",
        type = "continuous",
        min = 0.0, max = 1.0, step = 0.05,
        get = function() return crtMaskIntensity end,
        set = function(v)
            crtMaskIntensity = v
            if crtShader then crtShader:send("maskIntensity", crtMaskIntensity) end
        end,
    },
    {
        name = "Curvature",
        type = "continuous",
        min = 0.0, max = 0.5, step = 0.01,
        get = function() return crtCurve end,
        set = function(v)
            crtCurve = v
            if crtShader then crtShader:send("curve", crtCurve) end
        end,
    },
    {
        name = "Bloom Threshold",
        type = "continuous",
        min = 0.0, max = 1.0, step = 0.02,
        get = function() return BLOOM_THRESHOLD end,
        set = function(v)
            BLOOM_THRESHOLD = v
            if thresholdShader then thresholdShader:send("threshold", BLOOM_THRESHOLD) end
        end,
    },
    {
        name = "Bloom Intensity",
        type = "continuous",
        min = 0.0, max = 2.0, step = 0.05,
        get = function() return BLOOM_INTENSITY end,
        set = function(v) BLOOM_INTENSITY = v end,
    },
}

return CRT
