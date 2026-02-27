# Module 7: UI, Menus & Save Data

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 4-6 hours
**Prerequisites:** [Module 6: Audio & Juice](module-06-audio-juice.md)

---

## Overview

You have a game that plays well, looks good, and sounds right. But when someone launches it, they stare at the gameplay with no explanation. When they close it, their high score vanishes. When they want to turn the volume down, they cannot. These are the problems this module solves.

UI, menus, and save data are not glamorous. Nobody posts a screenshot of a volume slider on social media. But they are the difference between a tech demo and a game someone would actually pay for. Think about it -- every game you have ever played had a main menu, a pause screen, and some way to persist progress. Hollow Knight remembers which benches you sat on. Celeste remembers your best time. Even Vampire Survivors has a settings screen. These features are table stakes.

The good news: building UI in LOVE is straightforward because you already know how to draw rectangles and text. A button is just a rectangle that reacts to mouse position. A slider is a rectangle with a draggable handle. A save file is a Lua table serialized to a string and written to disk. None of this is conceptually hard. The challenge is organizing it all cleanly so your game does not become a rat's nest of `if` checks.

By the end of this module, you will have a main menu with hover-effect buttons, a settings screen with a working volume slider, a pause overlay, a HUD, and a high score system that persists across sessions. All wired together with the game state patterns you learned in Module 2.

---

## Core Concepts

### 1. Text Rendering

Text in LOVE revolves around **font objects**. You create a font, set it as active, and draw with it. Two functions do the drawing: `love.graphics.print` and `love.graphics.printf`.

```lua
function love.load()
    -- Load a TTF file at a specific size
    titleFont = love.graphics.newFont("assets/fonts/PressStart2P.ttf", 32)
    bodyFont = love.graphics.newFont("assets/fonts/PressStart2P.ttf", 16)

    -- Or use LOVE's built-in default font at a specific size
    hudFont = love.graphics.newFont(14)
end

function love.draw()
    love.graphics.setFont(titleFont)
    love.graphics.print("ASTEROID BLASTER", 100, 50)

    love.graphics.setFont(bodyFont)
    love.graphics.printf("Press Enter to Start", 0, 300, 800, "center")
end
```

The key difference between `print` and `printf`:
- **`print(text, x, y)`** -- draws text at an exact position. No wrapping, no alignment. The text starts at `(x, y)` and runs to the right.
- **`printf(text, x, y, limit, align)`** -- draws text within a bounding width (`limit`). You get alignment: `"left"`, `"center"`, `"right"`, or `"justify"`. Text wraps if it exceeds the limit. This is what you want for centered menu text.

**Measuring text** is critical for building buttons and centering things manually:

```lua
local font = love.graphics.getFont()
local textWidth = font:getWidth("Hello World")
local textHeight = font:getHeight()  -- height of a line in this font
local wrappedWidth, lines = font:getWrap("A longer piece of text", 200)
```

`getWidth` gives you the pixel width of a specific string. `getHeight` gives you the line height of the font (not a specific string -- all strings in the same font have the same line height). These are essential for centering text inside buttons.

**The font statefulness trap:** `love.graphics.setFont` is sticky, just like `setColor`. If you set a 32px title font to draw your menu header and forget to switch back, your HUD text will be huge. The safe pattern:

```lua
function love.draw()
    -- Draw UI with big font
    love.graphics.setFont(titleFont)
    love.graphics.print("GAME TITLE", 100, 50)

    -- ALWAYS reset to your default font when done
    love.graphics.setFont(bodyFont)
    love.graphics.print("Score: " .. score, 10, 10)
end
```

Or use `love.graphics.push`/`pop` to isolate graphics state changes (covered in the HUD section).

**Bitmap fonts** are an alternative for pixel art games. Instead of a TTF file, you create a font from an image where each character is a fixed-width glyph:

```lua
local bitmapFont = love.graphics.newImageFont(
    "assets/fonts/font.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
)
```

The second argument tells LOVE which characters appear in the image, left to right. Bitmap fonts give you that authentic retro look but are less flexible than TTF.

**Try this now:** Load a TTF font (Google Fonts has free ones -- Press Start 2P is a classic pixel font), draw your name centered on screen at three different sizes, and display the pixel width of each string in the corner.

---

### 2. Building Buttons

A button in LOVE is three things: a rectangle, some text, and a check for whether the mouse is hovering over it. That is all. There is no built-in button widget.

The basic pattern:

```lua
function love.load()
    button = {
        x = 300,
        y = 250,
        width = 200,
        height = 50,
        text = "Play",
        hovered = false,
    }
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    button.hovered = mx >= button.x and mx <= button.x + button.width
                 and my >= button.y and my <= button.y + button.height
end

function love.draw()
    if button.hovered then
        love.graphics.setColor(0.4, 0.4, 0.8)
    else
        love.graphics.setColor(0.2, 0.2, 0.5)
    end
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)

    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local textW = font:getWidth(button.text)
    local textH = font:getHeight()
    love.graphics.print(
        button.text,
        button.x + (button.width - textW) / 2,
        button.y + (button.height - textH) / 2
    )
end
```

**Click detection matters.** Use `love.mousepressed`, not `love.mouse.isDown`. If you check `isDown` in `love.update`, the button fires every single frame the mouse is held down -- 60 clicks per second. That is never what you want.

```lua
function love.mousepressed(x, y, mouseButton)
    if mouseButton == 1 and button.hovered then
        -- button was clicked!
        print("Play clicked")
    end
end
```

Now let's make a **reusable button factory:**

```lua
local function newButton(text, x, y, width, height, onClick)
    return {
        text = text,
        x = x, y = y,
        width = width, height = height,
        onClick = onClick,
        hovered = false,
        pressed = false,
    }
end

local function updateButton(btn)
    local mx, my = love.mouse.getPosition()
    btn.hovered = mx >= btn.x and mx <= btn.x + btn.width
              and my >= btn.y and my <= btn.y + btn.height
end

local function drawButton(btn, font)
    -- Background
    if btn.pressed and btn.hovered then
        love.graphics.setColor(0.15, 0.15, 0.4)
    elseif btn.hovered then
        love.graphics.setColor(0.4, 0.4, 0.8)
    else
        love.graphics.setColor(0.2, 0.2, 0.5)
    end
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 4, 4)

    -- Text (centered)
    love.graphics.setColor(1, 1, 1)
    local textW = font:getWidth(btn.text)
    local textH = font:getHeight()
    love.graphics.print(
        btn.text,
        btn.x + (btn.width - textW) / 2,
        btn.y + (btn.height - textH) / 2
    )
end

local function buttonMousePressed(btn, x, y, mouseButton)
    if mouseButton == 1 and btn.hovered then
        btn.pressed = true
    end
end

local function buttonMouseReleased(btn, x, y, mouseButton)
    if mouseButton == 1 and btn.pressed then
        btn.pressed = false
        if btn.hovered and btn.onClick then
            btn.onClick()
        end
    end
end
```

Notice the **press-then-release** pattern. The click only fires if you pressed *and* released while hovering. This matches how every real UI works -- you can press a button, drag your mouse off it, and release to cancel. Games like Slay the Spire and Balatro use this exact pattern for their card interactions.

**Try this now:** Create three buttons stacked vertically ("Play", "Settings", "Quit") and make each one print its label to the console when clicked. Add a visual "pressed" state that darkens the button while the mouse is held down.

---

### 3. Layout Strategies

Hard-coding `x = 300, y = 250` for every button falls apart the moment you change your window size or add a new menu item. You need layout logic.

**Centering a single element:**

```lua
local screenW, screenH = love.graphics.getDimensions()
local buttonW, buttonH = 200, 50
local x = (screenW - buttonW) / 2
local y = (screenH - buttonH) / 2
```

**Centering a vertical list of buttons:**

```lua
local buttonW, buttonH = 200, 50
local spacing = 15
local buttons = { "Play", "Settings", "Quit" }
local totalHeight = #buttons * buttonH + (#buttons - 1) * spacing

local screenW, screenH = love.graphics.getDimensions()
local startX = (screenW - buttonW) / 2
local startY = (screenH - totalHeight) / 2

for i, label in ipairs(buttons) do
    local y = startY + (i - 1) * (buttonH + spacing)
    -- create button at (startX, y, buttonW, buttonH)
end
```

**The anchor point approach** is more flexible. Instead of calculating absolute positions, define elements relative to anchors:

```lua
local function anchorCenter(elementW, elementH, containerW, containerH)
    return (containerW - elementW) / 2, (containerH - elementH) / 2
end

local function anchorTopRight(elementW, elementH, containerW, padding)
    return containerW - elementW - padding, padding
end

-- Usage
local scoreX, scoreY = anchorTopRight(100, 20, love.graphics.getWidth(), 10)
```

For responsive layouts, calculate positions as fractions of screen dimensions:

```lua
local x = screenW * 0.5 - buttonW / 2  -- horizontally centered
local y = screenH * 0.7                 -- 70% down the screen
```

This keeps your UI proportional if the window resizes. For a fixed-resolution pixel art game, you can safely use absolute positions. For anything else, think in ratios.

**Try this now:** Create a vertical menu of 4 buttons that is always centered on screen, regardless of window size. Test by changing your `conf.lua` resolution.

---

### 4. Main Menu Design

Your main menu is the first thing a player sees. It sets the tone. Here is a minimal but complete main menu state:

```lua
-- states/menu.lua
local Gamestate = require("lib.hump.gamestate")

local MenuState = {}
local PlayState, SettingsState
local buttons = {}
local titleFont, buttonFont

function MenuState:init()
    PlayState = require("states.play")
    SettingsState = require("states.settings")

    titleFont = love.graphics.newFont("assets/fonts/title.ttf", 48)
    buttonFont = love.graphics.newFont("assets/fonts/ui.ttf", 20)
end

function MenuState:enter()
    local screenW, screenH = love.graphics.getDimensions()
    local btnW, btnH = 220, 50
    local spacing = 15
    local startX = (screenW - btnW) / 2
    local startY = screenH * 0.5

    buttons = {
        newButton("Play", startX, startY, btnW, btnH, function()
            Gamestate.switch(PlayState)
        end),
        newButton("Settings", startX, startY + btnH + spacing, btnW, btnH, function()
            Gamestate.switch(SettingsState)
        end),
        newButton("Quit", startX, startY + 2 * (btnH + spacing), btnW, btnH, function()
            love.event.quit()
        end),
    }
end

function MenuState:update(dt)
    for _, btn in ipairs(buttons) do
        updateButton(btn)
    end
end

function MenuState:draw()
    -- Background
    love.graphics.clear(0.08, 0.08, 0.15)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("ASTEROID BLASTER", 0, 100, love.graphics.getWidth(), "center")

    -- Subtitle
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.printf("A Space Shooter", 0, 160, love.graphics.getWidth(), "center")

    -- Buttons
    love.graphics.setFont(buttonFont)
    for _, btn in ipairs(buttons) do
        drawButton(btn, buttonFont)
    end
end

function MenuState:mousepressed(x, y, mouseButton)
    for _, btn in ipairs(buttons) do
        buttonMousePressed(btn, x, y, mouseButton)
    end
end

function MenuState:mousereleased(x, y, mouseButton)
    for _, btn in ipairs(buttons) do
        buttonMouseReleased(btn, x, y, mouseButton)
    end
end

return MenuState
```

**Background art or animation** adds life. Even something simple -- slowly scrolling stars, a parallax background, a pulsing title -- makes the menu feel polished:

```lua
function MenuState:update(dt)
    self.bgScroll = (self.bgScroll or 0) + 20 * dt
    -- update buttons...
end

function MenuState:draw()
    -- Scrolling star field
    for _, star in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, star.brightness)
        love.graphics.circle("fill", star.x, (star.y + self.bgScroll * star.speed) % screenH, 1)
    end
    -- then draw title and buttons on top...
end
```

**State transitions** from the menu should feel intentional. At minimum, switch states when a button is clicked. For more polish, use a fade transition (see Module 2's FadeState pattern).

**Try this now:** Build a main menu with a title, three buttons, and a simple animated background (scrolling stars, floating particles, or a color-cycling gradient).

---

### 5. Pause Menu

The pause menu is the poster child for **state stacking** (push/pop). You do not want to destroy the game state when the player pauses. You want to freeze it and draw an overlay on top.

```lua
-- states/pause.lua
local Gamestate = require("lib.hump.gamestate")

local PauseState = {}
local MenuState
local buttons = {}
local font

function PauseState:init()
    MenuState = require("states.menu")
    font = love.graphics.newFont(20)
end

function PauseState:enter(previous)
    self.previous = previous
    local screenW, screenH = love.graphics.getDimensions()
    local btnW, btnH = 200, 45
    local startX = (screenW - btnW) / 2
    local startY = screenH * 0.45

    buttons = {
        newButton("Resume", startX, startY, btnW, btnH, function()
            Gamestate.pop()
        end),
        newButton("Settings", startX, startY + 60, btnW, btnH, function()
            -- push settings on top of pause on top of game
            Gamestate.push(SettingsState)
        end),
        newButton("Quit to Menu", startX, startY + 120, btnW, btnH, function()
            Gamestate.switch(MenuState)  -- switch, not pop -- abandon the game
        end),
    }
end

function PauseState:update(dt)
    -- Game does NOT update -- it is frozen
    for _, btn in ipairs(buttons) do
        updateButton(btn)
    end
end

function PauseState:draw()
    -- Draw the game underneath (frozen)
    if self.previous and self.previous.draw then
        self.previous:draw()
    end

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    -- Pause title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf("PAUSED", 0, love.graphics.getHeight() * 0.3,
                         love.graphics.getWidth(), "center")

    -- Buttons
    for _, btn in ipairs(buttons) do
        drawButton(btn, font)
    end
end

function PauseState:mousepressed(x, y, mouseButton)
    for _, btn in ipairs(buttons) do
        buttonMousePressed(btn, x, y, mouseButton)
    end
end

function PauseState:mousereleased(x, y, mouseButton)
    for _, btn in ipairs(buttons) do
        buttonMouseReleased(btn, x, y, mouseButton)
    end
end

function PauseState:keypressed(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

return PauseState
```

**The overlay pattern** is the key technique. You draw the previous state's `draw()` first, then draw a dark semi-transparent rectangle over the whole screen, then draw your pause UI on top. The game world is visible but dimmed.

**Input blocking** happens naturally with state stacking. When `PauseState` is on top, only `PauseState` receives input callbacks. The game state below does not get `update` or `keypressed` calls, so the game world freezes automatically. This is one of the big wins of using push/pop over manual if/else pausing.

In your play state, triggering the pause is one line:

```lua
-- states/play.lua
function PlayState:keypressed(key)
    if key == "escape" then
        Gamestate.push(PauseState)
    end
end
```

**Try this now:** Add a pause state to any existing game. Pressing Escape should push the pause overlay. Pressing Escape again (or clicking Resume) should pop back to the game with all state intact.

---

### 6. Settings Screen

A settings screen needs interactive widgets: sliders for volume, toggles for options, and display of current keybindings. Let's build the most common one -- a **horizontal slider**.

```lua
local function newSlider(x, y, width, min, max, value, label)
    return {
        x = x, y = y,
        width = width, height = 20,
        min = min, max = max,
        value = value,
        label = label,
        dragging = false,
    }
end

local function updateSlider(slider)
    if slider.dragging then
        local mx = love.mouse.getX()
        local ratio = (mx - slider.x) / slider.width
        ratio = math.max(0, math.min(1, ratio))
        slider.value = slider.min + ratio * (slider.max - slider.min)
    end
end

local function drawSlider(slider, font)
    -- Label
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(slider.label, slider.x, slider.y - 20)

    -- Track
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", slider.x, slider.y, slider.width, slider.height, 4, 4)

    -- Fill
    local ratio = (slider.value - slider.min) / (slider.max - slider.min)
    love.graphics.setColor(0.3, 0.5, 0.9)
    love.graphics.rectangle("fill", slider.x, slider.y,
                            slider.width * ratio, slider.height, 4, 4)

    -- Handle
    local handleX = slider.x + slider.width * ratio
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", handleX, slider.y + slider.height / 2, 12)

    -- Value display
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(string.format("%.0f%%", slider.value * 100),
                        slider.x + slider.width + 15, slider.y)
end

local function sliderMousePressed(slider, x, y, mouseButton)
    if mouseButton == 1 then
        -- Check if click is on the track or handle
        if x >= slider.x - 12 and x <= slider.x + slider.width + 12
           and y >= slider.y - 12 and y <= slider.y + slider.height + 12 then
            slider.dragging = true
            -- Immediately update value to click position
            local ratio = (x - slider.x) / slider.width
            ratio = math.max(0, math.min(1, ratio))
            slider.value = slider.min + ratio * (slider.max - slider.min)
        end
    end
end

local function sliderMouseReleased(slider, x, y, mouseButton)
    if mouseButton == 1 then
        slider.dragging = false
    end
end
```

**Applying settings in real-time** is important for volume sliders. The player should hear the change as they drag:

```lua
function SettingsState:update(dt)
    updateSlider(self.volumeSlider)

    -- Apply volume immediately
    love.audio.setVolume(self.volumeSlider.value)
end
```

**Toggle switches** are simpler -- they are just buttons that flip a boolean:

```lua
local function newToggle(x, y, label, value)
    return {
        x = x, y = y,
        width = 50, height = 26,
        label = label,
        value = value,
    }
end

local function drawToggle(toggle, font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(toggle.label, toggle.x, toggle.y - 20)

    -- Track
    if toggle.value then
        love.graphics.setColor(0.2, 0.7, 0.3)
    else
        love.graphics.setColor(0.4, 0.4, 0.4)
    end
    love.graphics.rectangle("fill", toggle.x, toggle.y, toggle.width, toggle.height, 13, 13)

    -- Knob
    love.graphics.setColor(1, 1, 1)
    local knobX = toggle.value and (toggle.x + toggle.width - 13) or (toggle.x + 13)
    love.graphics.circle("fill", knobX, toggle.y + toggle.height / 2, 10)
end

local function toggleMousePressed(toggle, x, y, mouseButton)
    if mouseButton == 1
       and x >= toggle.x and x <= toggle.x + toggle.width
       and y >= toggle.y and y <= toggle.y + toggle.height then
        toggle.value = not toggle.value
    end
end
```

**Keybinding display** can start simple -- just show the current bindings in a table. Full rebinding is a stretch goal, but here is the concept:

```lua
-- Waiting for a key press to rebind
function SettingsState:keypressed(key)
    if self.waitingForRebind then
        settings.keybinds[self.waitingForRebind] = key
        self.waitingForRebind = nil
    end
end
```

**Try this now:** Build a settings screen with a master volume slider and a fullscreen toggle. Make the volume slider actually change `love.audio.setVolume` as you drag it.

---

### 7. love.filesystem Basics

LOVE has a sandboxed filesystem. You can read files from your game directory (where `main.lua` lives), but you can **only write** to a specific **save directory** that LOVE manages for you. This is by design -- it prevents a buggy game from trashing the player's hard drive.

**The save directory** differs per platform:

| Platform | Save directory |
|---|---|
| Windows | `%APPDATA%/LOVE/<identity>/` |
| macOS | `~/Library/Application Support/LOVE/<identity>/` |
| Linux | `~/.local/share/love/<identity>/` |

The `<identity>` is your game's name, set in `conf.lua`:

```lua
-- conf.lua
function love.conf(t)
    t.identity = "asteroid_blaster"  -- determines save folder name
end
```

You can also set it at runtime with `love.filesystem.setIdentity("asteroid_blaster")`, but `conf.lua` is the standard place.

**Basic file operations:**

```lua
-- Write a string to a file (creates it if it doesn't exist)
love.filesystem.write("save.dat", "hello world")

-- Read a file into a string
local contents = love.filesystem.read("save.dat")
-- contents is now "hello world", or nil if the file doesn't exist

-- Check if a file/directory exists
local info = love.filesystem.getInfo("save.dat")
if info then
    print("File exists, size: " .. info.size)
end

-- Create a directory (for organizing saves)
love.filesystem.createDirectory("saves")
love.filesystem.write("saves/slot1.dat", data)

-- Find your actual save directory on disk
print(love.filesystem.getSaveDirectory())
-- e.g. "/Users/you/Library/Application Support/LOVE/asteroid_blaster"
```

**The sandboxing model** is strict. `love.filesystem.write` always writes to the save directory. You cannot write to the desktop, the project folder, or anywhere else. `love.filesystem.read` checks the save directory *first*, then falls back to the game directory (the source folder or .love archive). This means a save file can "override" a bundled default file, which is handy for config.

**Reading line by line** for config-style files:

```lua
if love.filesystem.getInfo("settings.cfg") then
    for line in love.filesystem.lines("settings.cfg") do
        local key, value = line:match("^(%w+)=(.+)$")
        if key and value then
            settings[key] = tonumber(value) or value
        end
    end
end
```

**Lua gotcha:** `love.filesystem.read` returns `nil` if the file does not exist, not an empty string and not an error. Always check the return value before using it.

**Try this now:** Set an identity in `conf.lua`, write a string to a file, then print `love.filesystem.getSaveDirectory()` to find it on disk. Open the file in a text editor to verify it worked.

---

### 8. Serialization

You have tables full of game data -- high scores, settings, player progress. `love.filesystem.write` accepts strings. So you need to convert tables to strings (**serialization**) and strings back to tables (**deserialization**).

**The naive approach** works for flat data:

```lua
-- Save
local data = "volume=" .. settings.volume .. "\n"
           .. "fullscreen=" .. tostring(settings.fullscreen) .. "\n"
love.filesystem.write("settings.cfg", data)

-- Load (parse each line)
for line in love.filesystem.lines("settings.cfg") do
    local key, val = line:match("(%w+)=(.*)")
    if key == "volume" then settings.volume = tonumber(val) end
    if key == "fullscreen" then settings.fullscreen = val == "true" end
end
```

This is fine for two fields. It does not scale to nested tables, arrays, or complex data.

**json.lua** is a single-file JSON library for Lua. JSON is familiar if you come from JavaScript, and the files are human-readable and editable:

```lua
local json = require("lib.json")

-- Serialize a table to a JSON string
local data = {
    highScores = {
        { name = "ACE", score = 15000 },
        { name = "BOB", score = 12000 },
    },
    settings = { volume = 0.8, fullscreen = false },
}
local str = json.encode(data)
love.filesystem.write("save.json", str)

-- Deserialize a JSON string back to a table
local contents = love.filesystem.read("save.json")
local loaded = json.decode(contents)
print(loaded.highScores[1].name)  -- "ACE"
```

The save file looks like what you would expect:

```json
{
    "highScores": [
        {"name": "ACE", "score": 15000},
        {"name": "BOB", "score": 12000}
    ],
    "settings": {"volume": 0.8, "fullscreen": false}
}
```

**serpent** produces human-readable Lua source code. The output is a valid Lua table literal, which makes debugging saves trivially easy -- you can just read the file:

```lua
local serpent = require("lib.serpent")

-- Serialize
local str = serpent.dump(data)
love.filesystem.write("save.lua", str)

-- Deserialize
local contents = love.filesystem.read("save.lua")
local ok, loaded = serpent.load(contents)
if ok then
    print(loaded.highScores[1].name)
end
```

The save file looks like:

```lua
{highScores={{name="ACE",score=15000},{name="BOB",score=12000}},settings={fullscreen=false,volume=0.8}}
```

Use `serpent.block(data)` instead of `serpent.dump(data)` for a pretty-printed, multi-line version.

**bitser** is a binary serializer. Saves are smaller and faster to read/write, but not human-readable. Useful for games with large save files or frequent autosaves:

```lua
local bitser = require("lib.bitser")

-- Serialize to binary string
local str = bitser.dumps(data)
love.filesystem.write("save.dat", str)

-- Deserialize
local contents = love.filesystem.read("save.dat")
local loaded = bitser.loads(contents)
```

**Choosing the right serializer:**

| Library | Format | Readable? | Speed | Best for |
|---|---|---|---|---|
| json.lua | JSON | Yes | Good | Settings, high scores, web-compatible data |
| serpent | Lua | Yes | Good | Debug-friendly saves, config files |
| bitser | Binary | No | Fast | Large save files, frequent saves |

For most LOVE games, **json.lua or serpent** is the right choice. Use bitser only if profiling shows save/load as a bottleneck, which it almost never is.

**Try this now:** Create a table with three high scores (name + score). Serialize it to JSON, write it to disk, read it back, deserialize it, and print the top score's name.

---

### 9. Save/Load Pattern

Serialization is the mechanism. The save/load *pattern* is how you use it in practice. Here is a robust pattern:

```lua
-- save.lua (a reusable save module)
local json = require("lib.json")

local Save = {}

local SAVE_FILE = "save.json"

local DEFAULT_DATA = {
    version = 1,
    highScores = {},
    settings = {
        volume = 0.8,
        musicVolume = 0.5,
        fullscreen = false,
        screenShake = true,
    },
}

function Save.load()
    local info = love.filesystem.getInfo(SAVE_FILE)
    if not info then
        -- No save file exists, return defaults
        return Save.deepCopy(DEFAULT_DATA)
    end

    local contents, err = love.filesystem.read(SAVE_FILE)
    if not contents then
        print("Warning: Could not read save file: " .. tostring(err))
        return Save.deepCopy(DEFAULT_DATA)
    end

    local ok, data = pcall(json.decode, contents)
    if not ok or type(data) ~= "table" then
        print("Warning: Corrupt save file, using defaults")
        -- Optionally backup the corrupt file
        love.filesystem.write(SAVE_FILE .. ".bak", contents)
        return Save.deepCopy(DEFAULT_DATA)
    end

    -- Migrate from older save versions
    data = Save.migrate(data)

    return data
end

function Save.save(data)
    data.version = DEFAULT_DATA.version  -- stamp the current version
    local str = json.encode(data)
    local ok, err = love.filesystem.write(SAVE_FILE, str)
    if not ok then
        print("Error saving: " .. tostring(err))
    end
end

function Save.migrate(data)
    -- Handle saves from older game versions
    if not data.version or data.version < 1 then
        -- v0 -> v1: added settings.screenShake
        data.settings = data.settings or {}
        data.settings.screenShake = data.settings.screenShake
            or DEFAULT_DATA.settings.screenShake
        data.version = 1
    end
    -- Add more migration steps here as your save format evolves:
    -- if data.version < 2 then ... data.version = 2 end
    return data
end

function Save.deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Save.deepCopy(v)
    end
    return copy
end

return Save
```

**Key principles:**

1. **Always have defaults.** If the save file is missing, return sensible defaults. The player's first launch should not crash.

2. **Handle corruption gracefully.** Wrap deserialization in `pcall` (Lua's try/catch equivalent). If the file is garbled, log a warning and use defaults. Never let a corrupt save crash the game.

3. **Version your saves.** When you add new fields in an update, old save files will not have them. The `migrate` function fills in missing fields so old saves still work. This is the same concept as database migrations.

4. **Save on events, not every frame.** Save when the player finishes a round, changes settings, or quits. Never in `love.update`. Writing to disk 60 times per second is wasteful and can cause stutters.

5. **Deep copy defaults.** If you return the DEFAULT_DATA table directly, any modifications to the returned table also modify your defaults (tables are references in Lua). Always deep copy.

**When to save:**

```lua
-- In your play state, when a round ends:
function PlayState:roundOver(score)
    local saveData = Save.load()
    table.insert(saveData.highScores, { name = "???", score = score })
    table.sort(saveData.highScores, function(a, b) return a.score > b.score end)
    -- Keep only top 10
    while #saveData.highScores > 10 do
        table.remove(saveData.highScores)
    end
    Save.save(saveData)
end

-- In your settings state, when a setting changes:
function SettingsState:applySettings()
    local saveData = Save.load()
    saveData.settings.volume = self.volumeSlider.value
    saveData.settings.fullscreen = self.fullscreenToggle.value
    Save.save(saveData)
end

-- On quit (optional safety save):
function love.quit()
    -- save any unsaved progress
    return false  -- allow quit
end
```

**Try this now:** Create a save module with defaults, save/load functions, and corruption handling. Write a settings table to disk, manually corrupt the file (open it and delete a bracket), then verify your game handles the corruption gracefully instead of crashing.

---

### 10. HUD Design

The **HUD** (heads-up display) is UI that floats on top of the game world during gameplay. Score, health, ammo, minimap -- all HUD elements. The key challenge: HUD elements must stay in **screen space** while the game world moves in **world space**.

If you are using a camera system (from `hump.camera` or a manual translate/scale), your game world is drawn in transformed coordinates. But your HUD should always be at the same screen position regardless of where the camera is looking. The pattern:

```lua
function PlayState:draw()
    -- 1. Draw game world (with camera)
    camera:attach()
        -- draw tilemap, enemies, player, particles...
        self.map:draw()
        for _, entity in ipairs(self.entities) do
            entity:draw()
        end
    camera:detach()

    -- 2. Draw HUD (no camera -- screen coordinates)
    self:drawHUD()
end

function PlayState:drawHUD()
    love.graphics.setColor(1, 1, 1)

    -- Health bar
    local barX, barY = 20, 20
    local barW, barH = 200, 20
    local healthRatio = self.player.health / self.player.maxHealth

    -- Background
    love.graphics.setColor(0.3, 0.1, 0.1)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 4, 4)

    -- Fill
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, barY, barW * healthRatio, barH, 4, 4)

    -- Border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", barX, barY, barW, barH, 4, 4)

    -- Score (top-right)
    love.graphics.setFont(hudFont)
    local scoreText = string.format("SCORE: %06d", self.score)
    local textW = hudFont:getWidth(scoreText)
    love.graphics.print(scoreText, love.graphics.getWidth() - textW - 20, 20)
end
```

**The UI layer pattern** uses `love.graphics.push` and `love.graphics.pop` to isolate graphics state:

```lua
function PlayState:drawHUD()
    love.graphics.push("all")  -- saves color, font, transform, blend mode...

    love.graphics.setFont(hudFont)
    love.graphics.setColor(1, 1, 1)
    -- draw all HUD elements...

    love.graphics.pop()  -- restores everything
end
```

`push("all")` saves every piece of graphics state. When you `pop`, everything reverts -- the font, the color, the transform, all of it. This prevents your HUD drawing code from leaking state into other draw calls. It is the graphics equivalent of using `local` variables.

**Health bar variations:**

```lua
-- Segmented health (like Zelda hearts)
local maxHearts = 5
local currentHealth = 3.5  -- half-hearts allowed
for i = 1, maxHearts do
    local hx = 20 + (i - 1) * 28
    if i <= math.floor(currentHealth) then
        -- full heart
        love.graphics.draw(heartFull, hx, 20)
    elseif i <= currentHealth then
        -- half heart
        love.graphics.draw(heartHalf, hx, 20)
    else
        -- empty heart
        love.graphics.draw(heartEmpty, hx, 20)
    end
end
```

**Minimap concept** (simplified):

```lua
local function drawMinimap(entities, playerX, playerY, mapW, mapH)
    local mmX, mmY = love.graphics.getWidth() - 110, 10
    local mmW, mmH = 100, 100

    -- Background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", mmX, mmY, mmW, mmH)

    -- Entities as dots
    for _, e in ipairs(entities) do
        local dotX = mmX + (e.x / mapW) * mmW
        local dotY = mmY + (e.y / mapH) * mmH
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", dotX, dotY, 2)
    end

    -- Player dot
    local px = mmX + (playerX / mapW) * mmW
    local py = mmY + (playerY / mapH) * mmH
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", px, py, 3)

    -- Border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", mmX, mmY, mmW, mmH)
end
```

**Try this now:** Add a HUD to a game with a health bar in the top-left, a score in the top-right, and an FPS counter in the bottom-left. Make sure the HUD stays fixed on screen while the game world scrolls (if you have a camera).

---

## Code Walkthrough

Let's wire everything together into a complete UI system. This walkthrough builds five things: a main menu, a settings screen, a pause overlay, a high score system, and a HUD. All connected through game states.

### Project Structure

```
my-game/
  main.lua
  conf.lua
  lib/
    hump/
      gamestate.lua
    json.lua
  modules/
    button.lua
    slider.lua
    save.lua
  states/
    menu.lua
    play.lua
    pause.lua
    settings.lua
    gameover.lua
  assets/
    fonts/
```

### conf.lua

```lua
function love.conf(t)
    t.window.title = "Space Blaster"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1
    t.identity = "space_blaster"
end
```

### modules/button.lua

```lua
local Button = {}

function Button.new(text, x, y, width, height, onClick)
    return {
        text = text,
        x = x, y = y,
        width = width, height = height,
        onClick = onClick,
        hovered = false,
        pressed = false,
        colors = {
            normal  = { 0.2, 0.2, 0.5 },
            hover   = { 0.35, 0.35, 0.7 },
            pressed = { 0.15, 0.15, 0.35 },
        },
    }
end

function Button.update(btn)
    local mx, my = love.mouse.getPosition()
    btn.hovered = mx >= btn.x and mx <= btn.x + btn.width
              and my >= btn.y and my <= btn.y + btn.height
end

function Button.draw(btn, font)
    local colors = btn.colors
    if btn.pressed and btn.hovered then
        love.graphics.setColor(colors.pressed)
    elseif btn.hovered then
        love.graphics.setColor(colors.hover)
    else
        love.graphics.setColor(colors.normal)
    end
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 6, 6)

    -- Border
    love.graphics.setColor(0.5, 0.5, 0.8, 0.5)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 6, 6)

    -- Centered text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf(btn.text, btn.x, btn.y + (btn.height - font:getHeight()) / 2,
                         btn.width, "center")
end

function Button.mousepressed(btn, x, y, mouseButton)
    if mouseButton == 1 and btn.hovered then
        btn.pressed = true
    end
end

function Button.mousereleased(btn, x, y, mouseButton)
    if mouseButton == 1 and btn.pressed then
        btn.pressed = false
        if btn.hovered and btn.onClick then
            btn.onClick()
        end
    end
end

return Button
```

### modules/slider.lua

```lua
local Slider = {}

function Slider.new(label, x, y, width, min, max, value)
    return {
        label = label,
        x = x, y = y,
        width = width, height = 20,
        min = min, max = max,
        value = value,
        dragging = false,
    }
end

function Slider.update(slider)
    if slider.dragging then
        local mx = love.mouse.getX()
        local ratio = math.max(0, math.min(1, (mx - slider.x) / slider.width))
        slider.value = slider.min + ratio * (slider.max - slider.min)
    end
end

function Slider.draw(slider, font)
    love.graphics.setFont(font)

    -- Label
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.print(slider.label, slider.x, slider.y - font:getHeight() - 4)

    -- Track
    love.graphics.setColor(0.25, 0.25, 0.3)
    love.graphics.rectangle("fill", slider.x, slider.y, slider.width, slider.height, 4, 4)

    -- Fill
    local ratio = (slider.value - slider.min) / (slider.max - slider.min)
    love.graphics.setColor(0.3, 0.5, 0.9)
    love.graphics.rectangle("fill", slider.x, slider.y,
                            slider.width * ratio, slider.height, 4, 4)

    -- Handle
    local hx = slider.x + slider.width * ratio
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", hx, slider.y + slider.height / 2, 12)

    -- Value
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.print(string.format("%d%%", slider.value * 100),
                        slider.x + slider.width + 20, slider.y)
end

function Slider.mousepressed(slider, x, y, mouseButton)
    if mouseButton ~= 1 then return end
    if x >= slider.x - 12 and x <= slider.x + slider.width + 12
       and y >= slider.y - 12 and y <= slider.y + slider.height + 12 then
        slider.dragging = true
        local ratio = math.max(0, math.min(1, (x - slider.x) / slider.width))
        slider.value = slider.min + ratio * (slider.max - slider.min)
    end
end

function Slider.mousereleased(slider, x, y, mouseButton)
    if mouseButton == 1 then
        slider.dragging = false
    end
end

return Slider
```

### modules/save.lua

```lua
local json = require("lib.json")

local Save = {}

local SAVE_FILE = "save.json"

local DEFAULT_DATA = {
    version = 1,
    highScores = {},
    settings = {
        masterVolume = 0.8,
        musicVolume = 0.5,
        sfxVolume = 1.0,
        fullscreen = false,
    },
}

function Save.load()
    local info = love.filesystem.getInfo(SAVE_FILE)
    if not info then
        return Save.deepCopy(DEFAULT_DATA)
    end

    local contents = love.filesystem.read(SAVE_FILE)
    if not contents then
        return Save.deepCopy(DEFAULT_DATA)
    end

    local ok, data = pcall(json.decode, contents)
    if not ok or type(data) ~= "table" then
        love.filesystem.write(SAVE_FILE .. ".bak", contents)
        return Save.deepCopy(DEFAULT_DATA)
    end

    data = Save.migrate(data)
    return data
end

function Save.save(data)
    data.version = DEFAULT_DATA.version
    local ok, str = pcall(json.encode, data)
    if ok then
        love.filesystem.write(SAVE_FILE, str)
    end
end

function Save.migrate(data)
    if not data.version then data.version = 0 end

    if data.version < 1 then
        data.settings = data.settings or {}
        for k, v in pairs(DEFAULT_DATA.settings) do
            if data.settings[k] == nil then
                data.settings[k] = v
            end
        end
        data.highScores = data.highScores or {}
        data.version = 1
    end

    return data
end

function Save.addHighScore(data, name, score)
    table.insert(data.highScores, { name = name, score = score })
    table.sort(data.highScores, function(a, b) return a.score > b.score end)
    while #data.highScores > 10 do
        table.remove(data.highScores)
    end
end

function Save.deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Save.deepCopy(v)
    end
    return copy
end

return Save
```

### main.lua

```lua
local Gamestate = require("lib.hump.gamestate")
local MenuState = require("states.menu")
local Save = require("modules.save")

function love.load()
    -- Load saved data and apply settings
    local saveData = Save.load()
    love.audio.setVolume(saveData.settings.masterVolume)

    Gamestate.registerEvents()
    Gamestate.switch(MenuState)
end
```

### states/menu.lua

```lua
local Gamestate = require("lib.hump.gamestate")
local Button = require("modules.button")
local Save = require("modules.save")

local MenuState = {}
local PlayState, SettingsState

local titleFont, subtitleFont, buttonFont, scoreFont
local buttons

function MenuState:init()
    PlayState = require("states.play")
    SettingsState = require("states.settings")

    titleFont = love.graphics.newFont(48)
    subtitleFont = love.graphics.newFont(16)
    buttonFont = love.graphics.newFont(20)
    scoreFont = love.graphics.newFont(14)
end

function MenuState:enter()
    self.saveData = Save.load()
    self.time = 0

    local sw = love.graphics.getWidth()
    local btnW, btnH = 220, 50
    local startX = (sw - btnW) / 2
    local startY = 280
    local spacing = 60

    buttons = {
        Button.new("Play", startX, startY, btnW, btnH, function()
            Gamestate.switch(PlayState)
        end),
        Button.new("Settings", startX, startY + spacing, btnW, btnH, function()
            Gamestate.switch(SettingsState)
        end),
        Button.new("Quit", startX, startY + spacing * 2, btnW, btnH, function()
            love.event.quit()
        end),
    }
end

function MenuState:update(dt)
    self.time = self.time + dt
    for _, btn in ipairs(buttons) do
        Button.update(btn)
    end
end

function MenuState:draw()
    love.graphics.clear(0.06, 0.06, 0.12)
    local sw, sh = love.graphics.getDimensions()

    -- Animated title (gentle float)
    local titleY = 80 + math.sin(self.time * 1.5) * 5
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SPACE BLASTER", 0, titleY, sw, "center")

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(0.5, 0.5, 0.65)
    love.graphics.printf("Defend the Galaxy", 0, titleY + 55, sw, "center")

    -- Buttons
    for _, btn in ipairs(buttons) do
        Button.draw(btn, buttonFont)
    end

    -- High scores
    local scores = self.saveData.highScores
    if #scores > 0 then
        love.graphics.setFont(scoreFont)
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.printf("HIGH SCORES", 0, sh - 160, sw, "center")

        love.graphics.setColor(0.7, 0.7, 0.8)
        for i = 1, math.min(5, #scores) do
            local entry = scores[i]
            local text = string.format("%d. %s - %d", i, entry.name, entry.score)
            love.graphics.printf(text, 0, sh - 140 + i * 18, sw, "center")
        end
    end
end

function MenuState:mousepressed(x, y, btn)
    for _, b in ipairs(buttons) do
        Button.mousepressed(b, x, y, btn)
    end
end

function MenuState:mousereleased(x, y, btn)
    for _, b in ipairs(buttons) do
        Button.mousereleased(b, x, y, btn)
    end
end

return MenuState
```

### states/settings.lua

```lua
local Gamestate = require("lib.hump.gamestate")
local Button = require("modules.button")
local Slider = require("modules.slider")
local Save = require("modules.save")

local SettingsState = {}

local font, headerFont
local sliders, backButton
local saveData

function SettingsState:init()
    headerFont = love.graphics.newFont(28)
    font = love.graphics.newFont(16)
end

function SettingsState:enter()
    saveData = Save.load()
    local sw = love.graphics.getWidth()
    local sliderW = 300
    local startX = (sw - sliderW) / 2

    sliders = {
        Slider.new("Master Volume", startX, 180, sliderW, 0, 1,
                   saveData.settings.masterVolume),
        Slider.new("Music Volume", startX, 260, sliderW, 0, 1,
                   saveData.settings.musicVolume),
        Slider.new("SFX Volume", startX, 340, sliderW, 0, 1,
                   saveData.settings.sfxVolume),
    }

    backButton = Button.new("Back", (sw - 150) / 2, 440, 150, 45, function()
        -- Save settings before leaving
        saveData.settings.masterVolume = sliders[1].value
        saveData.settings.musicVolume = sliders[2].value
        saveData.settings.sfxVolume = sliders[3].value
        Save.save(saveData)
        Gamestate.switch(require("states.menu"))
    end)
end

function SettingsState:update(dt)
    for _, s in ipairs(sliders) do
        Slider.update(s)
    end
    Button.update(backButton)

    -- Apply volume changes in real-time
    love.audio.setVolume(sliders[1].value)
end

function SettingsState:draw()
    love.graphics.clear(0.06, 0.06, 0.12)

    love.graphics.setFont(headerFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SETTINGS", 0, 80, love.graphics.getWidth(), "center")

    for _, s in ipairs(sliders) do
        Slider.draw(s, font)
    end

    Button.draw(backButton, font)
end

function SettingsState:mousepressed(x, y, btn)
    for _, s in ipairs(sliders) do
        Slider.mousepressed(s, x, y, btn)
    end
    Button.mousepressed(backButton, x, y, btn)
end

function SettingsState:mousereleased(x, y, btn)
    for _, s in ipairs(sliders) do
        Slider.mousereleased(s, x, y, btn)
    end
    Button.mousereleased(backButton, x, y, btn)
end

function SettingsState:keypressed(key)
    if key == "escape" then
        -- Save and go back
        saveData.settings.masterVolume = sliders[1].value
        saveData.settings.musicVolume = sliders[2].value
        saveData.settings.sfxVolume = sliders[3].value
        Save.save(saveData)
        Gamestate.switch(require("states.menu"))
    end
end

return SettingsState
```

### states/pause.lua

```lua
local Gamestate = require("lib.hump.gamestate")
local Button = require("modules.button")

local PauseState = {}

local font, buttons

function PauseState:init()
    font = love.graphics.newFont(20)
end

function PauseState:enter(previous)
    self.previous = previous
    local sw, sh = love.graphics.getDimensions()
    local btnW, btnH = 200, 45
    local startX = (sw - btnW) / 2

    buttons = {
        Button.new("Resume", startX, sh * 0.42, btnW, btnH, function()
            Gamestate.pop()
        end),
        Button.new("Quit to Menu", startX, sh * 0.42 + 60, btnW, btnH, function()
            Gamestate.switch(require("states.menu"))
        end),
    }
end

function PauseState:update(dt)
    for _, btn in ipairs(buttons) do
        Button.update(btn)
    end
end

function PauseState:draw()
    -- Draw frozen game underneath
    if self.previous and self.previous.draw then
        self.previous:draw()
    end

    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf("PAUSED", 0, love.graphics.getHeight() * 0.3,
                         love.graphics.getWidth(), "center")

    for _, btn in ipairs(buttons) do
        Button.draw(btn, font)
    end
end

function PauseState:mousepressed(x, y, btn)
    for _, b in ipairs(buttons) do
        Button.mousepressed(b, x, y, btn)
    end
end

function PauseState:mousereleased(x, y, btn)
    for _, b in ipairs(buttons) do
        Button.mousereleased(b, x, y, btn)
    end
end

function PauseState:keypressed(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

return PauseState
```

### states/play.lua (with HUD and high scores)

```lua
local Gamestate = require("lib.hump.gamestate")
local Save = require("modules.save")

local PlayState = {}
local PauseState, GameOverState
local hudFont

function PlayState:init()
    PauseState = require("states.pause")
    GameOverState = require("states.gameover")
    hudFont = love.graphics.newFont(16)
end

function PlayState:enter()
    self.score = 0
    self.health = 100
    self.maxHealth = 100
    self.player = { x = 400, y = 500 }
    self.time = 0
end

function PlayState:update(dt)
    self.time = self.time + dt

    -- Game logic here (simplified for demonstration)
    if love.keyboard.isDown("left") then
        self.player.x = self.player.x - 300 * dt
    end
    if love.keyboard.isDown("right") then
        self.player.x = self.player.x + 300 * dt
    end

    -- Simulate scoring
    self.score = self.score + math.floor(100 * dt)

    -- Simulate damage over time (for demo purposes)
    if love.keyboard.isDown("space") then
        self.health = math.max(0, self.health - 30 * dt)
    end

    if self.health <= 0 then
        -- Save high score and transition to game over
        local saveData = Save.load()
        Save.addHighScore(saveData, "PLR", self.score)
        Save.save(saveData)
        Gamestate.switch(GameOverState, self.score)
    end
end

function PlayState:draw()
    love.graphics.clear(0.02, 0.02, 0.08)

    -- Draw game world
    love.graphics.setColor(0.3, 0.7, 1)
    love.graphics.rectangle("fill", self.player.x - 15, self.player.y - 15, 30, 30)

    -- Draw HUD (after game world, no camera transform)
    self:drawHUD()
end

function PlayState:drawHUD()
    love.graphics.push("all")
    love.graphics.setFont(hudFont)

    local sw = love.graphics.getWidth()

    -- Health bar (top-left)
    local barX, barY, barW, barH = 15, 15, 180, 18
    local healthRatio = self.health / self.maxHealth

    love.graphics.setColor(0.2, 0.05, 0.05)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 3, 3)

    -- Color shifts from green to red as health drops
    local r = 1 - healthRatio
    local g = healthRatio
    love.graphics.setColor(r, g, 0.1)
    love.graphics.rectangle("fill", barX, barY, barW * healthRatio, barH, 3, 3)

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("line", barX, barY, barW, barH, 3, 3)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("HP: %d/%d",
        self.health, self.maxHealth), barX + 5, barY + 1)

    -- Score (top-right)
    local scoreText = string.format("SCORE: %06d", self.score)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(scoreText, 0, 15, sw - 15, "right")

    -- FPS (bottom-left, for debugging)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 15,
                        love.graphics.getHeight() - 25)

    love.graphics.pop()
end

function PlayState:keypressed(key)
    if key == "escape" then
        Gamestate.push(PauseState)
    end
end

return PlayState
```

### states/gameover.lua

```lua
local Gamestate = require("lib.hump.gamestate")
local Button = require("modules.button")

local GameOverState = {}
local MenuState
local font, scoreFont, buttons

function GameOverState:init()
    MenuState = require("states.menu")
    font = love.graphics.newFont(36)
    scoreFont = love.graphics.newFont(20)
end

function GameOverState:enter(previous, finalScore)
    self.finalScore = finalScore or 0
    local sw, sh = love.graphics.getDimensions()
    local btnW, btnH = 200, 45

    buttons = {
        Button.new("Play Again", (sw - btnW) / 2, sh * 0.55, btnW, btnH, function()
            Gamestate.switch(require("states.play"))
        end),
        Button.new("Main Menu", (sw - btnW) / 2, sh * 0.55 + 60, btnW, btnH, function()
            Gamestate.switch(MenuState)
        end),
    }
end

function GameOverState:update(dt)
    for _, btn in ipairs(buttons) do
        Button.update(btn)
    end
end

function GameOverState:draw()
    love.graphics.clear(0.1, 0.02, 0.02)

    love.graphics.setFont(font)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() * 0.25,
                         love.graphics.getWidth(), "center")

    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Final Score: " .. self.finalScore, 0,
                         love.graphics.getHeight() * 0.38,
                         love.graphics.getWidth(), "center")

    for _, btn in ipairs(buttons) do
        Button.draw(btn, scoreFont)
    end
end

function GameOverState:mousepressed(x, y, btn)
    for _, b in ipairs(buttons) do
        Button.mousepressed(b, x, y, btn)
    end
end

function GameOverState:mousereleased(x, y, btn)
    for _, b in ipairs(buttons) do
        Button.mousereleased(b, x, y, btn)
    end
end

return GameOverState
```

---

## API Reference

### love.graphics (Text & Font)

| Function | Description |
|---|---|
| `love.graphics.newFont(size)` | Create a font from LOVE's default at the given size |
| `love.graphics.newFont(path, size)` | Create a font from a TTF file |
| `love.graphics.newImageFont(path, glyphs)` | Create a bitmap font from an image |
| `love.graphics.setFont(font)` | Set the active font (sticky) |
| `love.graphics.getFont()` | Get the current active font |
| `love.graphics.print(text, x, y, r, sx, sy)` | Draw text at a position |
| `love.graphics.printf(text, x, y, limit, align)` | Draw text with alignment and wrapping |
| `font:getWidth(text)` | Pixel width of a string in this font |
| `font:getHeight()` | Line height of this font |
| `font:getWrap(text, limit)` | Returns wrap width and table of wrapped lines |
| `love.graphics.push(stackType)` | Save graphics state (`"all"` or `"transform"`) |
| `love.graphics.pop()` | Restore saved graphics state |

### love.mouse

| Function | Description |
|---|---|
| `love.mouse.getPosition()` | Returns x, y of mouse cursor |
| `love.mouse.getX()` / `getY()` | Individual axis position |
| `love.mouse.isDown(button)` | Is a mouse button held? (1=left, 2=right, 3=middle) |
| `love.mousepressed(x, y, button)` | Callback: mouse button pressed (define as function) |
| `love.mousereleased(x, y, button)` | Callback: mouse button released |
| `love.wheelmoved(x, y)` | Callback: scroll wheel moved (y > 0 = up, y < 0 = down) |

### love.filesystem

| Function | Description |
|---|---|
| `love.filesystem.write(name, data)` | Write string to file in save directory |
| `love.filesystem.read(name)` | Read file as string (returns nil if missing) |
| `love.filesystem.getInfo(name)` | Returns info table if file exists, nil otherwise |
| `love.filesystem.createDirectory(name)` | Create a directory in save directory |
| `love.filesystem.getSaveDirectory()` | Full OS path to save directory |
| `love.filesystem.getIdentity()` | Get the current identity string |
| `love.filesystem.setIdentity(name)` | Set the identity (determines save folder) |
| `love.filesystem.lines(name)` | Iterator over lines in a file |
| `love.filesystem.remove(name)` | Delete a file or empty directory |
| `love.filesystem.enumerate(dir)` | List files in a directory (returns table) |

### Serialization Libraries

| Library | Function | Description |
|---|---|---|
| json.lua | `json.encode(table)` | Table to JSON string |
| json.lua | `json.decode(string)` | JSON string to table |
| serpent | `serpent.dump(table)` | Table to compact Lua string |
| serpent | `serpent.block(table)` | Table to pretty-printed Lua string |
| serpent | `serpent.load(string)` | Lua string to table (returns ok, data) |
| bitser | `bitser.dumps(table)` | Table to binary string |
| bitser | `bitser.loads(string)` | Binary string to table |

---

## Libraries & Tools

### json.lua / dkjson

Single-file JSON encoder/decoder. Drop `json.lua` into your `lib/` folder and `require("lib.json")`. The most universally understood format -- save files are debuggable with any text editor. Handles nested tables, arrays, strings, numbers, booleans, and null. Does not handle Lua-specific types (functions, userdata, metatables).

- json.lua: [https://github.com/rxi/json.lua](https://github.com/rxi/json.lua)
- dkjson: [http://dkolf.de/dkjson-lua/](http://dkolf.de/dkjson-lua/)

### bitser

Binary serializer built specifically for LOVE. Significantly faster than JSON for large data sets. Save files are not human-readable, which makes debugging harder. Supports LOVE-specific types like FFI cdata. Use this when save/load performance matters (large game worlds, frequent autosaves).

- [https://github.com/gvx/bitser](https://github.com/gvx/bitser)

### serpent

Serializes Lua tables to valid Lua source code. Save files are human-readable and look like the data structure you wrote in code. The `block` formatter produces nicely indented output. Good middle ground between JSON's universality and bitser's performance.

- [https://github.com/pkulchenko/serpent](https://github.com/pkulchenko/serpent)

### Suit

An **immediate-mode GUI** library for LOVE. Instead of creating button objects and managing their state, you call `suit.Button("Play", x, y, w, h)` every frame in your draw/update loop and check the return value. If you have done any work with Dear ImGui, this will feel familiar. Excellent for debug UIs and tools. Less suited for a polished player-facing menu because styling takes effort.

- [https://github.com/vrld/suit](https://github.com/vrld/suit)

### LoveFrames

A **retained-mode GUI** framework. You create widget objects (buttons, sliders, text inputs, panels) and they manage their own state, rendering, and input. More like traditional desktop GUI toolkits. Heavier than Suit, but better for complex multi-panel UIs like inventory screens or editors.

- [https://github.com/linux-man/LoveFrames](https://github.com/linux-man/LoveFrames)

### Hand-rolled vs. library: honest tradeoffs

Building your own buttons and sliders (as we did in this module) teaches you how UI works and gives you total control over look and feel. The downside: you will spend time on text inputs, scroll lists, dropdown menus, and other widgets that Suit or LoveFrames give you for free.

For a game with a main menu, pause screen, and settings, hand-rolling is fine and educational. For a game with an inventory system, crafting UI, dialogue trees, and a shop -- consider using a library. The time you save on widget code can go into the game itself.

---

## Common Pitfalls

**1. Forgetting to setFont back after drawing UI text.**
You set a 48px title font to draw your menu header. Then `love.draw` continues to the HUD. Your score text is now giant because `setFont` is sticky. Fix: either reset the font after drawing, or use `love.graphics.push("all")` and `love.graphics.pop()` to isolate font changes.

**2. Mouse position in world coords vs. screen coords.**
If you have a camera that translates the game world, `love.mouse.getPosition()` returns *screen* coordinates. Your button positions are also in screen coordinates, so button hover detection works fine. But if you try to detect clicks on *game world* objects using raw mouse position, you need to transform the coordinates through the camera inverse. UI clicks: screen coords. Game world clicks: camera-adjusted coords.

**3. love.filesystem.write creates files in the save dir, not the project dir.**
You call `love.filesystem.write("scores.json", data)` and then look for the file next to `main.lua`. It is not there. It is in the save directory (`love.filesystem.getSaveDirectory()`). This is by design -- LOVE sandboxes writes for safety. If you want to find your save files, print the save directory path on startup.

**4. Saving every frame instead of on events.**
You put `Save.save(data)` inside `love.update`. Now your game writes to disk 60 times per second, causing micro-stutters and unnecessarily wearing out the player's SSD. Save on meaningful events: settings changed, high score achieved, level completed, game quit. Never in the update loop.

**5. Not handling corrupt or missing save files.**
Your game works great until someone's antivirus quarantines the save file, or a crash corrupts it mid-write, or the player manually edits it and makes a typo. Without `pcall` around your deserialization, the game crashes on startup with a cryptic error. Always wrap deserialize calls in `pcall`, always fall back to defaults, and optionally back up the corrupt file before overwriting it.

**6. Click-through: clicking a UI button also triggers a game action behind it.**
The player clicks "Resume" on the pause menu. The click event gets processed by the pause state (good) and also by the game state underneath (bad), firing a weapon or performing an action. With state stacking (push/pop), this happens naturally if you are not careful about input routing. The fix: when using hump's push/pop, only the top state receives input callbacks. If you are rolling your own system, make sure only the topmost state processes mouse/keyboard events. A consumed click should not propagate downward.

---

## Exercises

### Exercise 1: Reusable Button Module

**Time:** 45-60 minutes

Build a self-contained `button.lua` module that can be dropped into any LOVE project.

Requirements:
1. `Button.new(text, x, y, width, height, onClick)` -- creates a button table.
2. Three visual states: normal, hovered, and pressed. Each uses a different background color.
3. Click fires on mouse *release* while hovering, not on press (standard UI behavior).
4. Text is centered horizontally and vertically within the button.
5. Colors and font are customizable via optional parameters or by modifying the button table after creation.
6. Test it by creating a vertical menu of at least 3 buttons, each printing a message to the console when clicked.

**Stretch:** Add keyboard navigation. Track which button is "selected" with up/down arrow keys. Press Enter to click the selected button. Draw a highlight border around the selected button. This is essential for gamepad support.

---

### Exercise 2: Full Menu System

**Time:** 1.5-2 hours

Wire together a complete menu system using game states (DIY state tables or hump.gamestate).

Requirements:
1. **Main menu** with Play, Settings, and Quit buttons, plus a game title.
2. **Settings screen** with a working volume slider that changes `love.audio.setVolume` in real-time, a back button, and at least one toggle switch (e.g., fullscreen, screen shake).
3. **Pause overlay** accessible by pressing Escape during gameplay. The game world is visible but dimmed underneath. Resume and Quit to Menu buttons.
4. All menu transitions use the state system -- no raw `if/else` chains.
5. Settings are saved to disk when leaving the settings screen and loaded when the game starts.

**Stretch:** Add a fade transition between states. The screen fades to black over 0.3 seconds, switches the state, then fades back in.

---

### Exercise 3: Persistent High Score System

**Time:** 1-1.5 hours

Build a high score system that survives between game sessions.

Requirements:
1. When a game round ends, the player can enter a 3-letter name (like old arcade machines). Use `love.textinput` to capture characters.
2. The score and name are saved to a JSON file using `love.filesystem`.
3. The main menu displays the top 5 scores.
4. Scores are sorted highest-first and capped at 10 entries.
5. If the save file is missing or corrupt, the game starts with an empty score list and does not crash.

**Stretch:** Add save versioning. Start with version 1 (name + score). Then add a "date" field to each entry (version 2). Write a migration function that gracefully adds the missing "date" field to old v1 saves, setting it to "unknown" for legacy entries. Test by manually creating a v1 save file and verifying your game upgrades it to v2 on load.

---

## Recommended Reading & Resources

### Essential

| Resource | URL | What You Get |
|---|---|---|
| LOVE Wiki: love.filesystem | [https://love2d.org/wiki/love.filesystem](https://love2d.org/wiki/love.filesystem) | Official docs for all file operations |
| LOVE Wiki: love.graphics.newFont | [https://love2d.org/wiki/love.graphics.newFont](https://love2d.org/wiki/love.graphics.newFont) | Font creation details and supported formats |
| LOVE Wiki: love.graphics.printf | [https://love2d.org/wiki/love.graphics.printf](https://love2d.org/wiki/love.graphics.printf) | Text alignment and wrapping reference |
| json.lua (rxi) | [https://github.com/rxi/json.lua](https://github.com/rxi/json.lua) | Single-file JSON library -- read the README |
| Google Fonts | [https://fonts.google.com](https://fonts.google.com) | Free TTF fonts for your game UI |

### Go Deeper

| Resource | URL | What You Get |
|---|---|---|
| Suit (immediate mode GUI) | [https://github.com/vrld/suit](https://github.com/vrld/suit) | Alternative to hand-rolling UI widgets |
| serpent | [https://github.com/pkulchenko/serpent](https://github.com/pkulchenko/serpent) | Human-readable Lua serialization |
| bitser | [https://github.com/gvx/bitser](https://github.com/gvx/bitser) | Fast binary serialization for LOVE |
| Kenney UI Pack | [https://kenney.nl/assets/ui-pack](https://kenney.nl/assets/ui-pack) | Free UI art (buttons, panels, icons) |
| Sheepolution Ch. 18 (Saving/Loading) | [https://sheepolution.com/learn/book/18](https://sheepolution.com/learn/book/18) | Another take on LOVE filesystem |
| Game UI Database | [https://www.gameuidatabase.com](https://www.gameuidatabase.com) | Screenshots of UI from real games -- great for inspiration |

---

## Key Takeaways

- **A button is just a rectangle + text + mouse hit detection.** There is no built-in button widget in LOVE. You build it from primitives, and once you have a reusable module, you never build it again.

- **Use `love.mousepressed` for clicks, not `love.mouse.isDown`.** Checking `isDown` in your update loop fires 60 times per second. `mousepressed` fires once. Better yet, use press-then-release for standard UI feel.

- **`love.filesystem.write` always goes to the save directory, never the project folder.** This sandbox exists to protect the player. Use `love.filesystem.getSaveDirectory()` to find your saves on disk.

- **Always wrap deserialization in `pcall`.** Save files get corrupted, hand-edited, or deleted. If your decode call is not wrapped in error handling, your game crashes on startup. Fall back to defaults. Back up the broken file. Move on.

- **Version your save data from day one.** Adding a field later means old save files lack it. A `migrate` function that fills in missing fields gracefully is ten lines of code and saves hours of player frustration.

- **Draw the HUD after detaching the camera.** Game world elements move with the camera. HUD elements stay fixed on screen. The pattern is: `camera:attach()`, draw world, `camera:detach()`, draw HUD.

- **`love.graphics.push("all")` and `pop()` are your state isolation tool.** Use them to prevent font, color, and transform changes from leaking between your HUD code and your game world rendering.

---

## What's Next?

You have menus, settings, save data, and a HUD. Your game has every piece of chrome it needs to feel finished. The next step is to actually build a complete game.

[Module 8: Build Your First Real Game](module-08-build-first-real-game.md) is where you scope a small project, commit to finishing it, and apply everything from Modules 0-7 into a shippable product.

Back to the [LOVE2D Learning Roadmap](love2d-learning-roadmap.md).
