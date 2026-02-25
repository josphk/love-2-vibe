-- input.lua
-- Centralized input module: unifies keyboard+mouse and gamepad (DualSense)
-- with automatic hot-swap detection.

local Map = require("map")

local Input = {}

-- State
Input.gamepad    = nil       -- active joystick reference (or nil)
Input.lastDevice = "keyboard"  -- "keyboard" or "gamepad"

-- Action flags (consumed once per frame)
Input.fireJustPressed    = false
Input.cancelJustPressed  = false
Input.restartJustPressed = false
Input.quitJustPressed    = false

-- Trigger state for edge detection (triggers are axes, not buttons)
local prevR2 = 0
local prevL2 = 0

-- Dead zone config
local STICK_DEADZONE   = 0.25
local TRIGGER_DEADZONE = 0.15

--------------------------------------------------------------------------------
-- Dead zone helper: radial with smooth ramp
--------------------------------------------------------------------------------
local function applyDeadzone(x, y, dz)
    local mag = math.sqrt(x * x + y * y)
    if mag < dz then return 0, 0, 0 end
    local scale = (mag - dz) / (1 - dz)
    local nx, ny = x / mag, y / mag
    return nx * scale, ny * scale, scale
end

--------------------------------------------------------------------------------
-- Init: scan for already-connected gamepads
--------------------------------------------------------------------------------
function Input.init()
    local joysticks = love.joystick.getJoysticks()
    for _, js in ipairs(joysticks) do
        if js:isGamepad() then
            Input.gamepad = js
            break
        end
    end
end

--------------------------------------------------------------------------------
-- Movement: returns dx, dy in grid-space (magnitude 0..1 for gamepad, 0 or 1 for keyboard)
--------------------------------------------------------------------------------
function Input.getMovement()
    -- Try gamepad left stick first if gamepad is active device
    if Input.gamepad and Input.lastDevice == "gamepad" then
        local lx = Input.gamepad:getGamepadAxis("leftx")
        local ly = Input.gamepad:getGamepadAxis("lefty")
        local dx, dy, mag = applyDeadzone(lx, ly, STICK_DEADZONE)
        if mag > 0 then
            -- Convert screen-space stick direction to grid-space
            local gdx, gdy = Map.screenDirToGridDir(dx, dy)
            -- Preserve analog magnitude
            local glen = math.sqrt(gdx * gdx + gdy * gdy)
            if glen > 0.001 then
                gdx, gdy = gdx / glen * mag, gdy / glen * mag
            end
            return gdx, gdy
        end
    end

    -- Keyboard fallback (grid-aligned)
    local dx, dy = 0, 0
    if love.keyboard.isDown("a", "left")  then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    if love.keyboard.isDown("w", "up")    then dy = dy - 1 end
    if love.keyboard.isDown("s", "down")  then dy = dy + 1 end
    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx, dy = dx * inv, dy * inv
    end
    return dx, dy
end

--------------------------------------------------------------------------------
-- Gamepad aiming: returns aimAngle, dirX, dirY (screen-space) or nil if centered
--------------------------------------------------------------------------------
function Input.getGamepadAim()
    if not Input.gamepad then return nil end
    local rx = Input.gamepad:getGamepadAxis("rightx")
    local ry = Input.gamepad:getGamepadAxis("righty")
    local dx, dy, mag = applyDeadzone(rx, ry, STICK_DEADZONE)
    if mag > 0 then
        local angle = math.atan2(dy, dx)
        return angle, dx, dy
    end
    return nil
end

function Input.isGamepadAiming()
    return Input.lastDevice == "gamepad"
end

--------------------------------------------------------------------------------
-- Trigger edge detection: call once per frame in love.update
--------------------------------------------------------------------------------
function Input.updateTriggers()
    if not Input.gamepad then return end

    local r2 = Input.gamepad:getGamepadAxis("triggerright")
    local l2 = Input.gamepad:getGamepadAxis("triggerleft")

    -- R2 rising edge
    if r2 > TRIGGER_DEADZONE and prevR2 <= TRIGGER_DEADZONE then
        Input.fireJustPressed = true
        Input.lastDevice = "gamepad"
    end
    -- L2 rising edge
    if l2 > TRIGGER_DEADZONE and prevL2 <= TRIGGER_DEADZONE then
        Input.cancelJustPressed = true
        Input.lastDevice = "gamepad"
    end

    prevR2 = r2
    prevL2 = l2

    -- Detect stick movement for hot-swap
    local lx = Input.gamepad:getGamepadAxis("leftx")
    local ly = Input.gamepad:getGamepadAxis("lefty")
    local rx = Input.gamepad:getGamepadAxis("rightx")
    local ry = Input.gamepad:getGamepadAxis("righty")
    if math.abs(lx) > STICK_DEADZONE or math.abs(ly) > STICK_DEADZONE
    or math.abs(rx) > STICK_DEADZONE or math.abs(ry) > STICK_DEADZONE then
        Input.lastDevice = "gamepad"
    end
end

--------------------------------------------------------------------------------
-- Clear one-shot flags at end of frame
--------------------------------------------------------------------------------
function Input.endFrame()
    Input.fireJustPressed    = false
    Input.cancelJustPressed  = false
    Input.restartJustPressed = false
    Input.quitJustPressed    = false
end

--------------------------------------------------------------------------------
-- LOVE callbacks — delegate from main.lua
--------------------------------------------------------------------------------

function Input.gamepadpressed(joystick, button)
    Input.lastDevice = "gamepad"
    if button == "a" then        -- Cross (X) on DualSense
        Input.restartJustPressed = true
    elseif button == "start" then  -- Options on DualSense
        Input.quitJustPressed = true
    end
end

function Input.joystickadded(joystick)
    if joystick:isGamepad() and not Input.gamepad then
        Input.gamepad = joystick
    end
end

function Input.joystickremoved(joystick)
    if joystick == Input.gamepad then
        Input.gamepad = nil
        Input.lastDevice = "keyboard"
    end
end

return Input
