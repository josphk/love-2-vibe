# Module 6: Audio & Juice

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 4-6 hours
**Prerequisites:** [Module 5: Collision & Physics](module-05-collision-physics.md)

---

## Overview

You have a game that works. Things move, collide, score. And it feels like a tech demo.

The difference between a prototype nobody remembers and a game people keep playing past midnight is **juice** -- the layer of sensory feedback that makes every action feel like it matters. A brick breaks and the screen trembles. A score ticks up with a satisfying pop. Particles scatter like confetti. A sound effect confirms the hit before your eyes even process it.

None of this changes what your game does. It transforms what your game *feels like*.

This module teaches you the core juice toolkit in LOVE2D: audio playback, particle systems, tweening, screen shake, hit stop, and squash-and-stretch. You will start with a flat, silent breakout game and layer effects onto it until it feels alive. By the end, you will understand not just how to add juice, but when to stop -- because over-juicing is a real problem, and it is worse than no juice at all.

If you have watched the "Juice it or lose it" talk by Martin Jonasson and Petri Purho, you already know the philosophy. This module is the LOVE2D implementation guide.

---

## Core Concepts

### 1. What Is "Juice"?

**Juice** is the informal term for the collection of audiovisual feedback that makes game actions feel satisfying. Screen shake, particles, sound effects, tweened animations, hit pauses -- these are all juice. None of them change the underlying mechanics. They change the *feel*.

The canonical reference is the GDC talk "Juice it or lose it" by Martin Jonasson and Petri Purho, where they take a plain Breakout clone and layer on effect after effect until it feels like a completely different game. The mechanics never change -- ball hits bricks, bricks disappear. But the experience goes from sterile to addictive.

Commercial games live and die on juice. Celeste's screen shake on dash makes movement feel powerful. Hollow Knight freezes for 3-4 frames on every nail strike, giving each hit physical weight. Vlambeer (Nuclear Throne, Ridiculous Fishing) built their entire design philosophy around aggressive juice -- camera shake, muzzle flash, recoil, and knockback layered so densely that shooting a basic pistol feels like an event.

The key insight: juice is not decoration. It is communication. Every effect tells the player something happened. A sound confirms a hit before the visual registers. Particles show where the impact occurred. Screen shake says "that was big." Without these signals, the player's brain has to work harder to understand the game state, and the experience feels flat and unresponsive even when the code is running perfectly.

**Try this now:** Open any game you enjoy and mute the audio. Play for 30 seconds. Notice how much worse it feels. Now unmute and pay attention to every sound -- you will hear effects you never consciously noticed but always relied on.

---

### 2. Sound Effects with love.audio

Sound is the single highest-impact juice you can add. Players will tolerate missing particles or no screen shake. They will not tolerate silence. A well-placed sound effect does more for game feel than any visual trick.

LOVE2D's audio system is built around **Source** objects. A Source is a loaded sound that you can play, stop, pause, and configure.

```lua
function love.load()
    -- Load a sound effect
    sfx_hit = love.audio.newSource("assets/audio/hit.wav", "static")

    -- Load background music
    music = love.audio.newSource("assets/audio/bgm.ogg", "stream")
end
```

The second argument to `newSource` is the **source type**:

- **`"static"`** -- loads the entire file into memory. Use for short sound effects (under a few seconds). Low latency, can play multiple times simultaneously.
- **`"stream"`** -- streams from disk. Use for music and long ambient tracks. Low memory usage, but slightly higher latency and you cannot easily play the same stream overlapping itself.

**Rule of thumb:** If the file is under 5 seconds, use `"static"`. If it is music or ambient, use `"stream"`.

#### Playing Sounds

```lua
function love.keypressed(key)
    if key == "space" then
        sfx_hit:stop()   -- rewind to start (needed if already playing)
        sfx_hit:play()
    end
end
```

The `stop()` before `play()` pattern handles the case where the sound is still playing from a previous trigger. Without the stop, calling `play()` on an already-playing static source does nothing -- you get a swallowed input and no audio feedback.

#### Volume and Pitch

```lua
sfx_hit:setVolume(0.7)    -- 0 (silent) to 1 (full volume)
sfx_hit:setPitch(1.2)     -- 1.0 = normal, 2.0 = octave up, 0.5 = octave down
```

A killer technique for variety: **randomize pitch slightly** on each play. This prevents the "machine gun effect" where the same sound repeating quickly feels robotic and grating.

```lua
function play_sfx(source)
    source:stop()
    source:setPitch(1.0 + love.math.random() * 0.2 - 0.1)  -- pitch between 0.9 and 1.1
    source:play()
end
```

That tiny pitch variation makes the same sound feel organic. Every commercial game does this. Celeste randomizes pitch on footstep sounds. Hollow Knight does it on nail strikes. Once you hear the difference, you cannot unhear it.

#### Playing the Same Sound Overlapping (Cloning)

If a bullet hits three enemies in quick succession, you want three overlapping copies of the hit sound, not one sound that restarts. Use `Source:clone()`:

```lua
function play_sfx_overlap(source)
    local s = source:clone()
    s:setPitch(1.0 + love.math.random() * 0.2 - 0.1)
    s:play()
    -- The clone is garbage collected after it finishes playing
end
```

Cloning creates a lightweight copy that shares the underlying audio data. It is cheap -- you can clone hundreds of times without performance issues. The clone plays independently and gets garbage collected when it finishes and nothing references it.

**Lua gotcha:** If you store clones in a local variable inside a function and never reference them again, Lua's garbage collector *might* collect them before they finish playing. In practice, LOVE holds an internal reference to playing sources, so this is safe. But if you experience sounds cutting off early, store your active clones in a table.

**Try this now:** Load a sound effect, play it with `play_sfx` using the pitch variation technique. Press the trigger key rapidly and listen to how the randomized pitch prevents it from sounding robotic.

---

### 3. Music & Background Audio

Music uses the same `Source` API but with `"stream"` type and looping enabled:

```lua
function love.load()
    music = love.audio.newSource("assets/audio/music.ogg", "stream")
    music:setLooping(true)
    music:setVolume(0.5)
    music:play()
end
```

**Use OGG Vorbis for music**, not WAV. A 3-minute WAV file is around 30 MB. The same track in OGG is 2-3 MB. LOVE supports WAV, OGG, and MP3. OGG is the standard choice -- it is open source, well-compressed, and universally supported in LOVE.

#### Ducking Music During Sound Effects

When a loud sound effect plays, it can clash with the music. **Ducking** temporarily lowers the music volume, then brings it back:

```lua
local music_base_volume = 0.5
local music_duck_timer = 0

function duck_music(duration)
    music:setVolume(music_base_volume * 0.3)
    music_duck_timer = duration or 0.3
end

function love.update(dt)
    if music_duck_timer > 0 then
        music_duck_timer = music_duck_timer - dt
        if music_duck_timer <= 0 then
            music:setVolume(music_base_volume)
        end
    end
end
```

This is crude but effective. For smoother ducking, you would tween the volume back up instead of snapping it. We will cover tweening in section 6.

#### Crossfading Between Tracks

When transitioning between game states (menu to gameplay), an abrupt music cut feels jarring. A simple crossfade helps:

```lua
function crossfade_to(new_track, duration)
    local old_track = music
    local fade_duration = duration or 1.0
    local timer = 0

    new_track:setVolume(0)
    new_track:play()

    -- Store crossfade state to process in love.update
    crossfade = {
        old = old_track,
        new = new_track,
        timer = 0,
        duration = fade_duration,
    }
end

-- In love.update:
if crossfade then
    crossfade.timer = crossfade.timer + dt
    local t = math.min(crossfade.timer / crossfade.duration, 1)
    crossfade.old:setVolume(music_base_volume * (1 - t))
    crossfade.new:setVolume(music_base_volume * t)
    if t >= 1 then
        crossfade.old:stop()
        music = crossfade.new
        crossfade = nil
    end
end
```

**Try this now:** Load two different OGG files and implement the crossfade. Press a key to trigger the transition. Listen for the smooth blend versus an abrupt cut.

---

### 4. Generating Sound Effects

You do not need to be a sound designer to have good SFX. Free tools generate retro-style effects in seconds.

**sfxr / jsfxr** is the gold standard for procedural sound effects. The original sfxr was a standalone app. **jsfxr** (https://sfxr.me) is a browser-based version that works identically. Click preset categories (Pickup, Laser, Explosion, Powerup, Hit, Jump, Blip), randomize until you hear something you like, then export as WAV.

Tips for generating good SFX with sfxr:

- **Start with a category preset**, then tweak. Do not start from a blank slate.
- **Export at 44100 Hz, 16-bit.** These are the defaults and work perfectly with LOVE.
- **Generate 3-5 variations** of each sound. Even with pitch randomization, having multiple base sounds adds variety.
- **Keep sounds short.** Most game SFX should be under 0.5 seconds. Anything longer feels sluggish.

#### Organizing Audio Assets

```
my_game/
  assets/
    audio/
      sfx/
        hit_01.wav
        hit_02.wav
        hit_03.wav
        jump.wav
        score.wav
        explode.wav
      music/
        menu.ogg
        gameplay.ogg
```

Load them into a structured table:

```lua
function love.load()
    sfx = {
        hit = {
            love.audio.newSource("assets/audio/sfx/hit_01.wav", "static"),
            love.audio.newSource("assets/audio/sfx/hit_02.wav", "static"),
            love.audio.newSource("assets/audio/sfx/hit_03.wav", "static"),
        },
        jump = love.audio.newSource("assets/audio/sfx/jump.wav", "static"),
        score = love.audio.newSource("assets/audio/sfx/score.wav", "static"),
    }
end

-- Play a random hit sound
function play_hit()
    local s = sfx.hit[love.math.random(#sfx.hit)]
    play_sfx(s)
end
```

Multiple variations plus pitch randomization means the player almost never hears the exact same sound twice. This is how professional games handle repetitive actions.

**Free audio sources beyond sfxr:**

- **freesound.org** -- huge library of Creative Commons sounds. Check licenses (some require attribution).
- **incompetech.com** -- royalty-free music by Kevin MacLeod. Widely used in indie games and YouTube videos. Requires attribution.
- **opengameart.org** -- community-contributed game audio. Mixed licenses, always check.

**Try this now:** Go to https://sfxr.me, generate a "Pickup/Coin" sound, export it as WAV, drop it in your project's assets folder, and play it on a keypress with pitch variation.

---

### 5. Particle Systems

**Particle systems** create visual effects by spawning, animating, and destroying many small images or shapes over time. Explosions, smoke trails, sparks, dust clouds, magic sparkles -- all particles.

LOVE2D has a built-in particle system: `love.graphics.newParticleSystem`. It is GPU-accelerated and handles thousands of particles efficiently.

#### Basic Setup

Every particle system needs a **texture** -- the image each particle uses. A small white square or circle works for most effects because you can tint it with colors.

```lua
function love.load()
    -- Create a tiny 4x4 white image for particles
    local particle_img = love.graphics.newCanvas(4, 4)
    love.graphics.setCanvas(particle_img)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 4, 4)
    love.graphics.setCanvas()

    -- Create the particle system
    psystem = love.graphics.newParticleSystem(particle_img, 200)  -- max 200 particles
    psystem:setParticleLifetime(0.3, 0.8)  -- min, max seconds
    psystem:setEmissionRate(0)              -- 0 = manual burst mode
    psystem:setSpeed(100, 300)             -- min, max pixels/second
    psystem:setSpread(math.pi * 2)         -- full circle
    psystem:setLinearDamping(2)            -- particles slow down over time
    psystem:setSizes(1.5, 0.5)            -- start big, shrink
    psystem:setColors(
        1, 0.8, 0, 1,    -- start: yellow, fully opaque
        1, 0.2, 0, 0     -- end: red, fully transparent
    )
end
```

#### Updating and Drawing

This is where beginners trip up most. **You must update the particle system every frame**, or nothing moves. And you must draw it, or nothing appears.

```lua
function love.update(dt)
    psystem:update(dt)
end

function love.draw()
    love.graphics.draw(psystem, 0, 0)
end
```

The position passed to `love.graphics.draw` is the origin of the particle system. If you set it to `(0, 0)`, particles spawn at the position set by `psystem:setPosition(x, y)`. Alternatively, draw it at the spawn position directly:

```lua
love.graphics.draw(psystem, explosion_x, explosion_y)
```

#### Emitting Particles

With `setEmissionRate(0)`, particles only appear when you explicitly emit them:

```lua
function explode(x, y)
    psystem:setPosition(x, y)
    psystem:emit(30)  -- burst 30 particles at once
end
```

Call this when a brick breaks, an enemy dies, or a bullet hits something. The particles spawn at `(x, y)`, fly outward according to speed and spread, change color over their lifetime, shrink, fade out, and disappear. All from that one `emit(30)` call.

#### Common Particle Recipes

**Explosion (fast, hot):**

```lua
local function make_explosion_ps(img)
    local ps = love.graphics.newParticleSystem(img, 100)
    ps:setParticleLifetime(0.2, 0.5)
    ps:setEmissionRate(0)
    ps:setSpeed(200, 400)
    ps:setSpread(math.pi * 2)
    ps:setLinearDamping(3)
    ps:setSizes(2, 0.2)
    ps:setColors(
        1, 1, 0.5, 1,
        1, 0.3, 0, 0.5,
        0.5, 0, 0, 0
    )
    return ps
end
```

**Dust puff (slow, subtle):**

```lua
local function make_dust_ps(img)
    local ps = love.graphics.newParticleSystem(img, 50)
    ps:setParticleLifetime(0.3, 0.6)
    ps:setEmissionRate(0)
    ps:setSpeed(20, 60)
    ps:setSpread(math.pi * 0.5)        -- half-circle upward
    ps:setDirection(-math.pi / 2)       -- aim upward
    ps:setLinearDamping(5)
    ps:setSizes(1, 1.5)                 -- grow slightly
    ps:setColors(0.7, 0.7, 0.7, 0.6, 0.7, 0.7, 0.7, 0)
    return ps
end
```

**Sparkle trail (continuous):**

```lua
local function make_sparkle_ps(img)
    local ps = love.graphics.newParticleSystem(img, 300)
    ps:setParticleLifetime(0.2, 0.4)
    ps:setEmissionRate(60)              -- continuous emission
    ps:setSpeed(10, 30)
    ps:setSpread(math.pi * 2)
    ps:setSizes(1, 0)
    ps:setColors(1, 1, 1, 0.8, 1, 1, 1, 0)
    return ps
end
```

For a continuous trail, keep the emission rate above zero and update the position each frame to follow the moving object:

```lua
function love.update(dt)
    sparkle_ps:setPosition(player.x, player.y)
    sparkle_ps:update(dt)
end
```

#### Managing Multiple Particle Systems

In a real game, you will have several particle systems running simultaneously -- one for explosions, one for dust, one for sparkles. Keep them in a list:

```lua
local particle_systems = {}

function add_particle_system(ps)
    table.insert(particle_systems, ps)
end

function love.update(dt)
    for i = #particle_systems, 1, -1 do
        particle_systems[i]:update(dt)
        -- Remove systems that are done (no active particles, not emitting)
        if particle_systems[i]:getCount() == 0 and
           particle_systems[i]:getEmissionRate() == 0 then
            table.remove(particle_systems, i)
        end
    end
end

function love.draw()
    for _, ps in ipairs(particle_systems) do
        love.graphics.draw(ps, 0, 0)
    end
end
```

**Try this now:** Create a particle system with the explosion recipe. Click the mouse to emit 30 particles at the cursor position. Experiment with `setColors`, `setSizes`, and `setSpeed` to see how each parameter changes the feel.

---

### 6. Tweening & Easing

A **tween** (short for "in-between") smoothly transitions a value from one state to another over time. Instead of snapping a score display from 0 to 100, you tween it so it rolls up over half a second. Instead of a menu element popping onto screen instantly, it slides in with a bounce.

Tweening is defined by an **easing function** that controls the acceleration curve. Linear easing moves at constant speed. Quadratic easing starts slow and accelerates. Elastic easing overshoots the target and springs back. The easing function is what gives a tween its personality.

#### The flux Library

**flux** (https://github.com/rxi/flux) is a lightweight tweening library for Lua. It is widely used in LOVE2D projects.

**Installation:** Download `flux.lua` and put it in your `lib/` folder.

```lua
local flux = require("lib.flux")
```

**Important:** flux must be updated every frame:

```lua
function love.update(dt)
    flux.update(dt)
end
```

#### Basic Tweening

```lua
-- Tween player.x from its current value to 400 over 0.5 seconds
flux.to(player, 0.5, { x = 400 })
```

That is it. Over the next 0.5 seconds, `player.x` smoothly transitions to 400. You do not need to manage timers or interpolation manually. flux handles it.

#### Easing Functions

The third argument (or a chained method) specifies the easing:

```lua
-- Quad ease-in-out (default: smooth start and end)
flux.to(player, 0.5, { x = 400 }):ease("quadinout")

-- Elastic (overshoots, springs back -- great for UI)
flux.to(ui_element, 0.3, { scale = 1 }):ease("elasticout")

-- Bounce (bounces at the end -- good for landing effects)
flux.to(ball, 0.4, { y = ground_y }):ease("bounceout")

-- Back (overshoots slightly then settles -- subtle, polished)
flux.to(panel, 0.5, { x = target_x }):ease("backout")

-- Linear (constant speed -- rarely what you want for juice)
flux.to(bar, 1.0, { width = target_width }):ease("linear")
```

Available easings in flux: `linear`, `quadin`, `quadout`, `quadinout`, `cubicin`, `cubicout`, `cubicinout`, `quartin`, `quartout`, `quartinout`, `quintin`, `quintout`, `quintinout`, `expoin`, `expoout`, `expoinout`, `sinein`, `sineout`, `sineinout`, `circin`, `circout`, `circinout`, `backin`, `backout`, `backinout`, `elasticin`, `elasticout`, `elasticinout`.

**Naming convention:** `in` means the effect happens at the start, `out` means at the end, `inout` means both. For most juice effects, you want `out` variants -- they start fast (the impact) and settle at the end.

#### Callbacks

flux supports `:oncomplete()` for running code when a tween finishes:

```lua
flux.to(enemy, 0.3, { alpha = 0 }):ease("quadout"):oncomplete(function()
    enemy.dead = true
end)
```

This is how you chain effects: tween an enemy's opacity to zero, then mark it dead when the fade finishes. Without the callback, you would need a manual timer and a state flag.

#### Tweening a Score Counter

One of the most satisfying juice effects is a score that rolls up instead of snapping:

```lua
local display = { score = 0 }
local actual_score = 0

function add_score(points)
    actual_score = actual_score + points
    flux.to(display, 0.5, { score = actual_score }):ease("quartout")
end

function love.draw()
    love.graphics.print("Score: " .. math.floor(display.score), 10, 10)
end
```

The `math.floor` prevents the display from showing decimal places during the tween. The actual score is always an integer -- only the display value is a float that approaches it over time.

#### The hump.timer Alternative

If you already use the **hump** library for game states, `hump.timer` provides tweening alongside other timer utilities (delays, periodic calls). It is a slightly different API:

```lua
local Timer = require("lib.hump.timer")

-- Tween (hump style)
Timer.tween(0.5, player, { x = 400 }, "out-elastic")

-- Delay then execute
Timer.after(1.0, function()
    print("One second later")
end)

-- Must update
function love.update(dt)
    Timer.update(dt)
end
```

**flux vs. hump.timer:** flux is a standalone tween-only library -- small, focused, one file. hump.timer bundles tweening with timers and delays, which is convenient if you already depend on hump. They are interchangeable for tweening purposes. Pick the one that fits your project's existing dependencies.

**Try this now:** Install flux. Create a circle at `x = 100`. Press Space to tween it to `x = 600` with `"elasticout"` easing. Then try `"bounceout"` and `"backout"`. Notice how each easing gives the same motion a completely different personality.

---

### 7. Screen Shake

Screen shake is the most iconic juice technique. A brief, rapid camera displacement simulates physical impact. The ball slams into a brick and the whole screen jolts -- suddenly that collision feels powerful.

#### The Basic Approach

The simplest implementation: offset all drawing by a random amount during the shake.

```lua
local shake = {
    intensity = 0,
    duration = 0,
    timer = 0,
    offset_x = 0,
    offset_y = 0,
}

function start_shake(intensity, duration)
    shake.intensity = intensity
    shake.duration = duration
    shake.timer = duration
end

function love.update(dt)
    if shake.timer > 0 then
        shake.timer = shake.timer - dt
        -- Decay: intensity decreases as the timer runs out
        local progress = shake.timer / shake.duration
        local current_intensity = shake.intensity * progress
        shake.offset_x = (love.math.random() * 2 - 1) * current_intensity
        shake.offset_y = (love.math.random() * 2 - 1) * current_intensity
    else
        shake.offset_x = 0
        shake.offset_y = 0
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(shake.offset_x, shake.offset_y)

    -- All your normal drawing code here
    draw_game()

    love.graphics.pop()

    -- Draw UI AFTER pop, so it doesn't shake
    draw_ui()
end
```

The `love.graphics.push()` / `love.graphics.pop()` pair saves and restores the graphics transform. Everything drawn between them gets the shake offset. UI drawn after the `pop()` stays stable -- you never want your score counter jittering.

**Critical detail:** The intensity **decays over time**. Without decay, the shake runs at full intensity until it stops, which feels jarring and mechanical. The `progress` variable (1.0 at start, 0.0 at end) creates a smooth falloff.

#### Trauma-Based Shake (Vlambeer Style)

Vlambeer popularized a more sophisticated approach: instead of fixed shake events, you accumulate **trauma** that decays continuously. Multiple impacts in quick succession stack their shake, creating escalating intensity during intense moments.

```lua
local camera = {
    trauma = 0,       -- 0 to 1
    max_offset = 10,  -- maximum pixel offset
    decay = 2.0,      -- trauma decay rate per second
}

function add_trauma(amount)
    camera.trauma = math.min(camera.trauma + amount, 1.0)
end

function love.update(dt)
    -- Decay trauma
    camera.trauma = math.max(camera.trauma - camera.decay * dt, 0)

    -- Shake uses trauma squared for a non-linear feel:
    -- small trauma = tiny shake, large trauma = big shake
    local shake = camera.trauma * camera.trauma
    camera.offset_x = (love.math.random() * 2 - 1) * camera.max_offset * shake
    camera.offset_y = (love.math.random() * 2 - 1) * camera.max_offset * shake
end

-- Usage:
-- Ball hits brick:   add_trauma(0.2)
-- Ball hits paddle:  add_trauma(0.1)
-- Boss explodes:     add_trauma(0.8)
```

The `trauma * trauma` (squaring) is the secret sauce. It means low trauma values produce almost no visible shake, while high values produce dramatic shake. The relationship is exponential, not linear. A trauma of 0.3 produces a shake factor of 0.09 (barely perceptible). A trauma of 0.8 produces 0.64 (serious). This matches human perception of impact -- small hits should be subtle, big hits should be dramatic, and the difference between them should feel non-linear.

#### Shake with Perlin Noise

Random shake (using `love.math.random`) produces a jittery, chaotic motion. For smoother shake that still feels organic, use **Perlin noise**:

```lua
local shake_seed = love.math.random(0, 1000)

function love.update(dt)
    camera.trauma = math.max(camera.trauma - camera.decay * dt, 0)
    local shake = camera.trauma * camera.trauma

    -- Use noise instead of random for smoother shake
    shake_seed = shake_seed + dt * 20
    camera.offset_x = (love.math.noise(shake_seed, 0) * 2 - 1) * camera.max_offset * shake
    camera.offset_y = (love.math.noise(0, shake_seed) * 2 - 1) * camera.max_offset * shake
end
```

`love.math.noise` returns values between 0 and 1, smoothly varying over time. The `* 2 - 1` maps it to -1 to 1. The result is a shake that flows instead of jerking, which looks more natural for longer-duration shakes.

**Try this now:** Implement both random and Perlin noise shake. Press one key for random, another for Perlin. The Perlin version feels more like the camera is being shoved; the random version feels more like vibration. Both have their uses.

---

### 8. Hit Stop / Freeze Frames

**Hit stop** (also called **hit pause** or **freeze frames**) freezes the game for 2-5 frames when an attack connects. Everything stops -- the attacker, the target, particles, everything. Then the game resumes.

This tiny pause communicates weight. Without it, attacks pass through enemies like they are made of air. With it, every hit feels like it connects with something solid.

Street Fighter has used hit stop since 1991. Hollow Knight freezes for about 4 frames on nail strikes. Hades uses variable-duration hit stop -- light attacks freeze briefly, heavy attacks freeze longer.

The implementation is absurdly simple:

```lua
local hitstop = {
    timer = 0,
}

function freeze(duration)
    hitstop.timer = duration
end

function love.update(dt)
    if hitstop.timer > 0 then
        hitstop.timer = hitstop.timer - dt
        return  -- skip ALL game logic
    end

    -- Normal game update below this line
    update_ball(dt)
    update_paddle(dt)
    check_collisions()
end
```

That `return` is doing all the work. When the freeze timer is active, `love.update` exits immediately. Nothing moves. Nothing updates. The draw function still runs (the screen is not blank), but the world is frozen.

**When to use it:**

- Ball hits paddle: `freeze(0.03)` -- 2 frames at 60 FPS, barely perceptible but adds weight
- Brick destroyed: `freeze(0.05)` -- 3 frames, slightly more dramatic
- Boss killed: `freeze(0.15)` -- 9 frames, cinematic pause before the explosion

**When NOT to use it:** On continuous events like sliding along a wall or collecting coins in rapid succession. Hit stop on every coin pickup in a dense field would make the game stutter constantly.

**Important:** Do NOT freeze your particle systems. You want particles to keep moving during a hit stop -- they provide visual continuity during the freeze. Update particles outside the early return:

```lua
function love.update(dt)
    -- Always update particles
    for _, ps in ipairs(particle_systems) do
        ps:update(dt)
    end

    if hitstop.timer > 0 then
        hitstop.timer = hitstop.timer - dt
        return
    end

    -- Game logic...
end
```

**Try this now:** Add a 3-frame (0.05 second) hit stop to any collision in a previous project. The difference is immediate and dramatic, especially when paired with a sound effect.

---

### 9. Squash and Stretch

**Squash and stretch** is one of Disney's 12 principles of animation. Applied to games, it means briefly deforming a sprite on impact to suggest elasticity and force. A ball squashes flat when it hits a paddle, then stretches as it bounces away. A character squashes before a jump (anticipation) and stretches at the apex.

In LOVE2D, squash and stretch is just scaling transforms:

```lua
local ball = {
    x = 400,
    y = 300,
    radius = 10,
    scale_x = 1,
    scale_y = 1,
}

function squash_ball()
    ball.scale_x = 1.3   -- wider
    ball.scale_y = 0.7   -- shorter
    -- Tween back to normal
    flux.to(ball, 0.2, { scale_x = 1, scale_y = 1 }):ease("elasticout")
end

function stretch_ball()
    ball.scale_x = 0.7   -- narrower
    ball.scale_y = 1.3   -- taller
    flux.to(ball, 0.2, { scale_x = 1, scale_y = 1 }):ease("elasticout")
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(ball.x, ball.y)
    love.graphics.scale(ball.scale_x, ball.scale_y)
    love.graphics.circle("fill", 0, 0, ball.radius)
    love.graphics.pop()
end
```

**Key principle:** Squash and stretch should preserve approximate volume. When you squash (make wider), make it shorter. When you stretch (make taller), make it narrower. A ball that just gets bigger in all directions does not read as squash -- it reads as growing.

The `"elasticout"` easing on the return tween is important. It makes the sprite overshoot slightly as it returns to normal scale, adding a springy, organic feel. Linear easing looks mechanical.

**Direction matters.** A ball bouncing off a horizontal surface should squash horizontally (wide and flat). A ball bouncing off a vertical wall should squash vertically (tall and narrow). Match the deformation axis to the impact surface:

```lua
function on_horizontal_bounce()
    ball.scale_x = 1.3
    ball.scale_y = 0.7
    flux.to(ball, 0.15, { scale_x = 1, scale_y = 1 }):ease("elasticout")
end

function on_vertical_bounce()
    ball.scale_x = 0.7
    ball.scale_y = 1.3
    flux.to(ball, 0.15, { scale_x = 1, scale_y = 1 }):ease("elasticout")
end
```

**Try this now:** Add squash and stretch to a bouncing ball. First try it with just the deformation (no tween back) -- it looks wrong. Then add the `elasticout` tween and see how it springs back to life.

---

### 10. Layering Juice -- Combining Multiple Effects

Individual juice techniques are good. Combining them for a single event is where the magic happens.

When a brick breaks in Breakout, here is what should happen simultaneously:

1. **Sound effect** plays with slight pitch variation
2. **Particles** burst from the brick's position
3. **Screen shake** fires (small trauma add)
4. **Hit stop** freezes for 2-3 frames
5. **Score** tweens up
6. The brick **squashes** briefly before disappearing (if you want to get fancy)

```lua
function on_brick_destroyed(brick)
    -- Sound
    play_sfx(sfx.brick_break)

    -- Particles
    explosion_ps:setPosition(brick.x + brick.w / 2, brick.y + brick.h / 2)
    explosion_ps:emit(20)

    -- Screen shake
    add_trauma(0.2)

    -- Hit stop
    freeze(0.04)

    -- Score tween
    add_score(10)

    -- Remove the brick
    brick.alive = false
end
```

One function call. Six simultaneous effects. The result feels *dramatically* better than removing the brick silently.

**The "Rule of Three" for juice:** For any given event, use at least three feedback channels. Sound + visual effect + camera response is the minimum for an impact to feel satisfying. Two channels feel thin. Three feel complete. Five feel polished. More than five and you risk overwhelming the player.

**When too much juice is too much:**

Over-juicing is a real problem. Signs you have gone too far:

- Screen shake is so frequent that the camera never settles
- Particles obscure gameplay-critical information
- Hit stop on minor events makes the game feel stuttery
- Sound effects overlap into a constant wall of noise
- The player stops noticing the effects because they are constant

The fix is **contrast**. Reserve your strongest effects (big shake, long hit stop, lots of particles) for your most important events (boss kills, critical hits, level completion). If everything is at maximum intensity, nothing feels special. Vlambeer games look chaotic, but they are carefully calibrated -- the camera shake on a shotgun blast is much stronger than on a pistol shot. The hierarchy of intensity tells the player which events matter most.

**Try this now:** Implement the full `on_brick_destroyed` function above. Then play the game and deliberately break 5 bricks in rapid succession. Does it feel overwhelming? Dial back the shake intensity and particle count until rapid hits feel exciting but not chaotic.

---

## Code Walkthrough: Juicing a Breakout Game

Here is a complete mini-breakout game, first without juice, then with juice layered on. Compare the two versions to see the transformation.

### Before: Plain Breakout

```lua
-- main.lua (no juice)
function love.load()
    paddle = { x = 350, y = 550, w = 100, h = 12, speed = 500 }
    ball = { x = 400, y = 400, vx = 200, vy = -250, radius = 6 }
    score = 0

    bricks = {}
    for row = 0, 4 do
        for col = 0, 9 do
            table.insert(bricks, {
                x = 45 + col * 72,
                y = 50 + row * 28,
                w = 64,
                h = 20,
                alive = true,
            })
        end
    end
end

function love.update(dt)
    -- Paddle movement
    if love.keyboard.isDown("left") then
        paddle.x = paddle.x - paddle.speed * dt
    end
    if love.keyboard.isDown("right") then
        paddle.x = paddle.x + paddle.speed * dt
    end
    paddle.x = math.max(0, math.min(paddle.x, 800 - paddle.w))

    -- Ball movement
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Wall bounces
    if ball.x - ball.radius < 0 then
        ball.x = ball.radius
        ball.vx = math.abs(ball.vx)
    end
    if ball.x + ball.radius > 800 then
        ball.x = 800 - ball.radius
        ball.vx = -math.abs(ball.vx)
    end
    if ball.y - ball.radius < 0 then
        ball.y = ball.radius
        ball.vy = math.abs(ball.vy)
    end

    -- Paddle collision
    if ball.vy > 0 and
       ball.x > paddle.x and ball.x < paddle.x + paddle.w and
       ball.y + ball.radius > paddle.y and ball.y + ball.radius < paddle.y + paddle.h + 10 then
        ball.vy = -math.abs(ball.vy)
        local hit_pos = (ball.x - (paddle.x + paddle.w / 2)) / (paddle.w / 2)
        ball.vx = hit_pos * 300
    end

    -- Brick collision
    for _, brick in ipairs(bricks) do
        if brick.alive and
           ball.x + ball.radius > brick.x and
           ball.x - ball.radius < brick.x + brick.w and
           ball.y + ball.radius > brick.y and
           ball.y - ball.radius < brick.y + brick.h then
            brick.alive = false
            ball.vy = -ball.vy
            score = score + 10
        end
    end
end

function love.draw()
    -- Paddle
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.w, paddle.h)

    -- Ball
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Bricks
    for _, brick in ipairs(bricks) do
        if brick.alive then
            love.graphics.setColor(0.2, 0.7, 1)
            love.graphics.rectangle("fill", brick.x, brick.y, brick.w, brick.h)
        end
    end

    -- Score
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
end
```

### After: Juiced Breakout

```lua
-- main.lua (with juice)
local flux = require("lib.flux")

function love.load()
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)

    -- Paddle
    paddle = { x = 350, y = 550, w = 100, h = 12, speed = 500 }

    -- Ball (with scale for squash/stretch)
    ball = { x = 400, y = 400, vx = 200, vy = -250, radius = 6,
             scale_x = 1, scale_y = 1 }

    -- Score (display value tweens toward actual value)
    actual_score = 0
    display = { score = 0 }

    -- Camera / shake
    camera = { trauma = 0, offset_x = 0, offset_y = 0, decay = 3.0, max_offset = 8 }
    shake_seed = love.math.random(0, 1000)

    -- Hit stop
    hitstop = { timer = 0 }

    -- Audio
    sfx = {
        paddle_hit = love.audio.newSource("assets/audio/sfx/paddle_hit.wav", "static"),
        brick_break = love.audio.newSource("assets/audio/sfx/brick_break.wav", "static"),
        wall_bounce = love.audio.newSource("assets/audio/sfx/wall_bounce.wav", "static"),
    }

    -- Particle system
    local particle_img = love.graphics.newCanvas(4, 4)
    love.graphics.setCanvas(particle_img)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 4, 4)
    love.graphics.setCanvas()

    brick_ps = love.graphics.newParticleSystem(particle_img, 500)
    brick_ps:setParticleLifetime(0.2, 0.5)
    brick_ps:setEmissionRate(0)
    brick_ps:setSpeed(100, 300)
    brick_ps:setSpread(math.pi * 2)
    brick_ps:setLinearDamping(3)
    brick_ps:setSizes(2, 0.3)
    brick_ps:setColors(
        0.2, 0.7, 1.0, 1.0,
        0.1, 0.3, 0.8, 0.0
    )

    paddle_ps = love.graphics.newParticleSystem(particle_img, 100)
    paddle_ps:setParticleLifetime(0.1, 0.3)
    paddle_ps:setEmissionRate(0)
    paddle_ps:setSpeed(50, 120)
    paddle_ps:setSpread(math.pi * 0.6)
    paddle_ps:setDirection(-math.pi / 2)
    paddle_ps:setLinearDamping(4)
    paddle_ps:setSizes(1.2, 0.2)
    paddle_ps:setColors(1, 1, 1, 0.8, 1, 1, 1, 0)

    -- Bricks
    bricks = {}
    local colors = {
        {1.0, 0.3, 0.3},  -- red
        {1.0, 0.6, 0.2},  -- orange
        {1.0, 1.0, 0.3},  -- yellow
        {0.3, 1.0, 0.3},  -- green
        {0.2, 0.7, 1.0},  -- blue
    }
    for row = 0, 4 do
        for col = 0, 9 do
            table.insert(bricks, {
                x = 45 + col * 72,
                y = 50 + row * 28,
                w = 64,
                h = 20,
                alive = true,
                color = colors[row + 1],
            })
        end
    end
end

-- Audio helper with pitch variation
local function play_sfx(source)
    local s = source:clone()
    s:setPitch(1.0 + love.math.random() * 0.2 - 0.1)
    s:play()
end

-- Shake
local function add_trauma(amount)
    camera.trauma = math.min(camera.trauma + amount, 1.0)
end

-- Hit stop
local function freeze(duration)
    hitstop.timer = duration
end

-- Score
local function add_score(points)
    actual_score = actual_score + points
    flux.to(display, 0.4, { score = actual_score }):ease("quartout")
end

-- Ball squash/stretch
local function squash_horizontal()
    ball.scale_x = 1.4
    ball.scale_y = 0.6
    flux.to(ball, 0.15, { scale_x = 1, scale_y = 1 }):ease("elasticout")
end

local function squash_vertical()
    ball.scale_x = 0.6
    ball.scale_y = 1.4
    flux.to(ball, 0.15, { scale_x = 1, scale_y = 1 }):ease("elasticout")
end

function love.update(dt)
    flux.update(dt)

    -- Always update particles (even during hit stop)
    brick_ps:update(dt)
    paddle_ps:update(dt)

    -- Camera shake (always update)
    camera.trauma = math.max(camera.trauma - camera.decay * dt, 0)
    local shake = camera.trauma * camera.trauma
    shake_seed = shake_seed + dt * 20
    camera.offset_x = (love.math.noise(shake_seed, 0) * 2 - 1) * camera.max_offset * shake
    camera.offset_y = (love.math.noise(0, shake_seed) * 2 - 1) * camera.max_offset * shake

    -- Hit stop: skip game logic while frozen
    if hitstop.timer > 0 then
        hitstop.timer = hitstop.timer - dt
        return
    end

    -- Paddle movement
    if love.keyboard.isDown("left") then
        paddle.x = paddle.x - paddle.speed * dt
    end
    if love.keyboard.isDown("right") then
        paddle.x = paddle.x + paddle.speed * dt
    end
    paddle.x = math.max(0, math.min(paddle.x, 800 - paddle.w))

    -- Ball movement
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Wall bounces
    if ball.x - ball.radius < 0 then
        ball.x = ball.radius
        ball.vx = math.abs(ball.vx)
        play_sfx(sfx.wall_bounce)
        squash_vertical()
    end
    if ball.x + ball.radius > 800 then
        ball.x = 800 - ball.radius
        ball.vx = -math.abs(ball.vx)
        play_sfx(sfx.wall_bounce)
        squash_vertical()
    end
    if ball.y - ball.radius < 0 then
        ball.y = ball.radius
        ball.vy = math.abs(ball.vy)
        play_sfx(sfx.wall_bounce)
        squash_horizontal()
    end

    -- Paddle collision
    if ball.vy > 0 and
       ball.x > paddle.x and ball.x < paddle.x + paddle.w and
       ball.y + ball.radius > paddle.y and ball.y + ball.radius < paddle.y + paddle.h + 10 then
        ball.vy = -math.abs(ball.vy)
        local hit_pos = (ball.x - (paddle.x + paddle.w / 2)) / (paddle.w / 2)
        ball.vx = hit_pos * 300

        -- JUICE: paddle hit
        play_sfx(sfx.paddle_hit)
        squash_horizontal()
        add_trauma(0.1)
        paddle_ps:setPosition(ball.x, paddle.y)
        paddle_ps:emit(8)
    end

    -- Brick collision
    for _, brick in ipairs(bricks) do
        if brick.alive and
           ball.x + ball.radius > brick.x and
           ball.x - ball.radius < brick.x + brick.w and
           ball.y + ball.radius > brick.y and
           ball.y - ball.radius < brick.y + brick.h then
            brick.alive = false
            ball.vy = -ball.vy

            -- JUICE: brick destroyed
            play_sfx(sfx.brick_break)
            squash_horizontal()
            add_trauma(0.15)
            freeze(0.04)
            add_score(10)

            -- Colored particles matching the brick
            brick_ps:setPosition(brick.x + brick.w / 2, brick.y + brick.h / 2)
            brick_ps:setColors(
                brick.color[1], brick.color[2], brick.color[3], 1,
                brick.color[1], brick.color[2], brick.color[3], 0
            )
            brick_ps:emit(15)
        end
    end
end

function love.draw()
    -- Apply camera shake to game world
    love.graphics.push()
    love.graphics.translate(camera.offset_x, camera.offset_y)

    -- Paddle
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.w, paddle.h)

    -- Ball (with squash/stretch)
    love.graphics.push()
    love.graphics.translate(ball.x, ball.y)
    love.graphics.scale(ball.scale_x, ball.scale_y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", 0, 0, ball.radius)
    love.graphics.pop()

    -- Bricks
    for _, brick in ipairs(bricks) do
        if brick.alive then
            love.graphics.setColor(brick.color)
            love.graphics.rectangle("fill", brick.x, brick.y, brick.w, brick.h)
        end
    end

    -- Particles (drawn in game world so they shake too)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(brick_ps, 0, 0)
    love.graphics.draw(paddle_ps, 0, 0)

    love.graphics.pop()  -- end camera shake transform

    -- UI (outside shake transform)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. math.floor(display.score), 10, 10)
end
```

**What changed:** The game logic is identical. Ball moves, bounces, breaks bricks. But every collision now triggers a cascade of feedback: a sound with pitch variation, particles colored to match the brick, a camera trauma hit, a brief freeze frame, a squash-and-stretch on the ball, and a tweened score counter. The game *feels* completely different.

Study the `love.update` function and notice the ordering. Particles and camera shake update before the hit stop check, so they keep running during freezes. Tweens update at the top via `flux.update(dt)`. Game logic runs only when not frozen.

---

## API Reference

### love.audio

| Function | Description |
|---|---|
| `love.audio.newSource(path, type)` | Load audio. `type` is `"static"` (SFX) or `"stream"` (music). |
| `source:play()` | Start playback. |
| `source:stop()` | Stop playback and rewind. |
| `source:pause()` | Pause without rewinding. |
| `source:setVolume(vol)` | Set volume: 0 (silent) to 1 (full). |
| `source:setPitch(pitch)` | Set pitch: 1.0 = normal, 2.0 = octave up, 0.5 = octave down. |
| `source:setLooping(bool)` | Enable/disable looping. |
| `source:isPlaying()` | Returns `true` if currently playing. |
| `source:clone()` | Create a lightweight copy for overlapping playback. |
| `source:seek(position)` | Jump to position in seconds. |
| `love.audio.setVolume(vol)` | Set master volume (affects all sources). |
| `love.audio.stop()` | Stop all currently playing sources. |

### love.graphics Particle System

| Function | Description |
|---|---|
| `love.graphics.newParticleSystem(image, max)` | Create a particle system using `image` with `max` particle capacity. |
| `ps:setParticleLifetime(min, max)` | How long each particle lives (seconds). |
| `ps:setEmissionRate(rate)` | Particles per second (0 = burst-only mode). |
| `ps:setSpeed(min, max)` | Particle speed range (pixels/second). |
| `ps:setSpread(spread)` | Emission cone angle (radians). `math.pi * 2` = full circle. |
| `ps:setDirection(angle)` | Base emission direction (radians). 0 = right, `math.pi/2` = down. |
| `ps:setLinearDamping(min, max)` | How quickly particles slow down. |
| `ps:setSizes(s1, s2, ...)` | Size multipliers over lifetime (up to 8 values). |
| `ps:setColors(r,g,b,a, r,g,b,a, ...)` | Color values over lifetime (up to 8 RGBA sets). |
| `ps:setPosition(x, y)` | Set emitter position. |
| `ps:emit(count)` | Burst `count` particles immediately. |
| `ps:update(dt)` | Advance particle simulation. **Must call every frame.** |
| `love.graphics.draw(ps, x, y)` | Render particles. |
| `ps:getCount()` | Number of currently active particles. |
| `ps:reset()` | Kill all particles and reset the system. |
| `ps:setRotation(min, max)` | Initial rotation range for each particle. |
| `ps:setSpin(min, max)` | Rotation speed over lifetime. |

### flux (Tweening Library)

| Function | Description |
|---|---|
| `flux.to(obj, duration, target)` | Tween `obj`'s fields toward `target` values over `duration` seconds. Returns a tween object. |
| `tween:ease(name)` | Set easing function. Returns the tween (chainable). |
| `tween:oncomplete(fn)` | Call `fn` when the tween finishes. Returns the tween. |
| `tween:delay(seconds)` | Wait before starting the tween. Returns the tween. |
| `tween:after(obj, dur, target)` | Chain a new tween to start when this one finishes. |
| `flux.update(dt)` | Advance all active tweens. **Must call every frame.** |

---

## Libraries & Tools

### flux

**What:** Standalone tweening library. One file, no dependencies.

**When to use:** When you need to smoothly animate values -- UI transitions, score counters, entity movement, color shifts.

**Source:** https://github.com/rxi/flux

**Tradeoff:** flux does tweening and only tweening. It does not provide timers, delays (beyond tween delays), or periodic callbacks. If you need those, pair it with a timer library or use hump.timer instead.

### hump.timer

**What:** Part of the hump library suite. Combines tweening, delayed calls, periodic calls, and one-shot timers in one module.

**When to use:** When you already use hump for game states (`hump.gamestate`) or vectors (`hump.vector`) and want to keep dependencies minimal.

**Source:** https://github.com/vrld/hump

**Tradeoff:** The tweening API is slightly more verbose than flux. Easing names use a different format (`"out-elastic"` vs `"elasticout"`). But you get `Timer.after()` and `Timer.every()` for free, which are genuinely useful for delayed spawns, periodic events, and timed power-ups.

**Comparison:**

```lua
-- flux
flux.to(obj, 0.5, { x = 100 }):ease("elasticout")

-- hump.timer
Timer.tween(0.5, obj, { x = 100 }, "out-elastic")
```

Functionally identical. Pick based on your project's existing dependencies.

### sfxr.me / jsfxr

**What:** Browser-based procedural sound effect generator. Click presets, randomize, tweak, export WAV.

**URL:** https://sfxr.me

**When to use:** When you need retro-style SFX fast. Produces 8-bit and chip-tune style sounds. Not suitable for realistic or orchestral effects.

### Free Audio Sources

| Source | Best For | License | URL |
|---|---|---|---|
| sfxr.me | Retro SFX generation | Public domain (you made it) | https://sfxr.me |
| Freesound | Environmental sounds, foley | Mixed (check each file) | https://freesound.org |
| Incompetech | Background music | CC-BY (attribution required) | https://incompetech.com |
| OpenGameArt | Game-specific SFX and music | Mixed (check each file) | https://opengameart.org |
| Kenney | UI sounds, simple SFX | CC0 (no attribution) | https://kenney.nl/assets?q=audio |

**Honest tradeoff on free audio:** Free SFX and music are adequate for prototypes and game jams. For a polished release, you will likely want custom audio or premium packs. The biggest limitation of free audio is *consistency* -- sounds from different sources often have mismatched volume levels, recording quality, and tonal character. Budget time for normalizing and processing your audio files even if the raw sounds are free.

---

## Common Pitfalls

### 1. Creating New Source Objects Every Frame

```lua
-- BAD: loads and decodes audio 60 times per second
function love.update(dt)
    if collision then
        local sfx = love.audio.newSource("hit.wav", "static")
        sfx:play()
    end
end
```

`love.audio.newSource` reads from disk, decodes the file, and allocates memory. Doing this every frame is a performance disaster. Load once in `love.load`, store the reference, and use `clone()` for overlapping playback.

### 2. Forgetting to Update Particle Systems

```lua
-- You set up a beautiful particle system, call emit(), and... nothing appears.
function love.update(dt)
    -- Forgot: psystem:update(dt)
end
```

Particle systems do nothing without their `update(dt)` call. No update, no movement, no lifecycle, no rendering. This is the number one particle bug, and every single LOVE2D developer has made this mistake at least once.

### 3. Screen Shake That Never Decays

```lua
-- BAD: constant intensity until timer runs out
camera.offset_x = (love.math.random() * 2 - 1) * shake.intensity
```

Without decay, the shake runs at full intensity for its entire duration, then stops abruptly. This feels mechanical and jarring. Always multiply the intensity by a decay factor (time remaining / total duration, or use trauma-based decay).

### 4. Too Many Simultaneous Audio Sources

LOVE2D has a limit on simultaneous audio sources (platform-dependent, typically 64-256). If you clone a new source on every collision in a bullet-hell game with hundreds of projectiles, you can hit this limit. Symptoms: sounds silently fail to play, or you get an error.

**Fix:** For rapid-fire events, reuse a small pool of source clones instead of creating unlimited clones:

```lua
local hit_pool = {}
local pool_index = 1
for i = 1, 8 do
    hit_pool[i] = sfx.hit:clone()
end

function play_hit_pooled()
    hit_pool[pool_index]:stop()
    hit_pool[pool_index]:setPitch(1.0 + love.math.random() * 0.2 - 0.1)
    hit_pool[pool_index]:play()
    pool_index = pool_index % #hit_pool + 1
end
```

### 5. Tween Callbacks Firing After Objects Are Destroyed

```lua
flux.to(enemy, 0.5, { alpha = 0 }):oncomplete(function()
    enemy.dead = true  -- What if enemy was already removed from the entity list?
end)
```

If the game state changes (player dies, level resets) while a tween is running, the callback fires on a stale or garbage-collected object. This can cause nil reference errors or modify objects that should no longer exist.

**Fix:** Guard your callbacks:

```lua
flux.to(enemy, 0.5, { alpha = 0 }):oncomplete(function()
    if enemy and not enemy.dead then
        enemy.dead = true
    end
end)
```

Or clear all tweens when changing game states. flux does not have a built-in "stop all" -- you would need to track active tweens and stop them manually, or switch to hump.timer which supports `Timer.clear()`.

### 6. Over-Juicing: When Effects Become Annoying

The most insidious pitfall because it feels like you are making the game better. Signs:

- Players complain the game is "too busy" or "hard to read"
- You cannot see gameplay-critical information through particle effects
- The constant screen shake gives people motion sickness
- Sound effects overlap into incoherent noise

The fix is restraint and hierarchy. Reserve maximum intensity for rare, important events. Use subtle effects for frequent events. Provide options to reduce or disable screen shake (accessibility concern -- some players get motion sick from screen shake).

---

## Exercises

### Exercise 1: Sound Board

**Time:** 45-60 minutes

Build a sound board with 6 buttons on screen:

1. Generate 6 different sound effects using sfxr.me (one from each category: pickup, laser, explosion, powerup, hit, jump).
2. Display 6 colored rectangles on screen, each labeled with the sound name.
3. Clicking a rectangle (or pressing keys 1-6) plays the corresponding sound.
4. Each play uses random pitch variation (0.9 to 1.1).
5. The rectangle briefly scales up (squash and stretch via tween) when its sound plays.

**Stretch:** Add a "Randomize All" button that regenerates the pitch variation range for every sound. Add a volume slider for each sound using `love.mouse.getY()` position while clicking.

---

### Exercise 2: Juice Up Pong

**Time:** 1.5-2 hours

Take a Pong game (from Module 1 or Module 2) and add juice:

1. **SFX:** Paddle hit, wall bounce, and score sounds. All with pitch variation.
2. **Particles:** Burst particles on ball-paddle collision and on scoring.
3. **Screen shake:** Small shake on paddle hit, larger shake on score.
4. **Score tween:** Score display rolls up instead of snapping when a point is scored.
5. **Ball squash/stretch:** Ball deforms on every bounce.
6. **Hit stop:** 2-frame freeze on paddle hit.

**Success criteria:** Mute the game and play for 30 seconds. Then unmute. The difference should be dramatic. Each effect should reinforce what is happening without obscuring it.

---

### Exercise 3: Juice Toggle Demo

**Time:** 2-3 hours

Create a demo (use Breakout or Pong) where pressing specific keys enables or disables individual juice layers:

1. Press **1** to toggle SFX on/off
2. Press **2** to toggle particles on/off
3. Press **3** to toggle screen shake on/off
4. Press **4** to toggle hit stop on/off
5. Press **5** to toggle squash/stretch on/off
6. Press **6** to toggle score tween on/off
7. Press **0** to toggle ALL juice on/off

Display the current state of each toggle on screen (e.g., "SFX: ON", "Shake: OFF"). This demo is extremely instructive -- you can see exactly what each layer contributes by toggling them individually. Start with everything off, then add them one by one. Notice how the first 2-3 layers make the biggest difference, and additional layers have diminishing (but still real) returns.

**Stretch:** Add a "juice intensity" slider (controlled by up/down arrows) that scales all effect magnitudes from 0% to 200%. Find the sweet spot where the game feels best, and note where it starts feeling over-juiced.

---

## Recommended Reading & Resources

### Essential

| Resource | Type | Why |
|---|---|---|
| [Juice it or lose it (GDC)](https://www.youtube.com/watch?v=Fy0aCDmgnxg) | Video (15 min) | The foundational talk. Watch before reading anything else. Shows the before/after of juicing a breakout clone. |
| [The Art of Screenshake (Jan Willem Nijman)](https://www.youtube.com/watch?v=AJdEqssNZ-U) | Video (45 min) | Vlambeer's co-founder explains their approach to screen shake, camera work, and impact feedback. Practical and opinionated. |
| [LOVE2D Wiki: love.audio](https://love2d.org/wiki/love.audio) | Documentation | Official reference for all audio functions. |
| [LOVE2D Wiki: ParticleSystem](https://love2d.org/wiki/ParticleSystem) | Documentation | Complete particle system API with examples. |
| [flux GitHub](https://github.com/rxi/flux) | Library + docs | Tween library source and usage examples. |
| [sfxr.me](https://sfxr.me) | Tool | Browser-based retro SFX generator. |

### Go Deeper

| Resource | Type | Why |
|---|---|---|
| [Game Feel by Steve Swink](https://www.oreilly.com/library/view/game-feel/9780123743282/) | Book | The academic framework for understanding why game feel works. Covers real-time control, simulated space, and polish theory. Dense but invaluable. |
| [Math for Game Programmers: Juicing Your Cameras (GDC)](https://www.youtube.com/watch?v=tu-Qe66AvtY) | Video (30 min) | Deep dive on camera techniques: lerp, lead, framing, and trauma-based shake with mathematical backing. |
| [hump Library](https://github.com/vrld/hump) | Library | Alternative to flux for tweening, plus timers, vectors, and game states. |
| [Freesound.org](https://freesound.org) | Resource | Community sound library. Requires free account. Check licenses. |
| [Incompetech](https://incompetech.com/music/) | Resource | Kevin MacLeod's royalty-free music library. Requires attribution (CC-BY). |
| [Game Design Theory Module 9: Aesthetics, Feel & Juice](../game-design-theory/module-09-aesthetics-feel-juice.md) | Wiki module | The design theory companion to this implementation guide. Covers Steve Swink's full framework, the animation principles, and the philosophy behind juice. |

---

## Key Takeaways

- **Sound is the highest-impact juice you can add.** A well-timed sound effect with slight pitch variation does more for game feel than any visual technique. Add audio first, always.

- **Particle systems require `update(dt)` every frame.** Without it, nothing moves or renders. This is the most common particle bug and the easiest to fix.

- **Use trauma-based screen shake with quadratic falloff.** Accumulate trauma on impacts, square it for the shake factor, and let it decay over time. This produces natural, escalating shake that matches the intensity of the action.

- **Hit stop is the highest effort-to-impact ratio technique.** Three lines of code (a timer, a check, an early return) and suddenly every collision feels like it has physical weight.

- **Tween everything that changes suddenly.** Score jumps, health bar drops, UI element appearances -- any abrupt value change benefits from a 0.3-second tween with appropriate easing. `"elasticout"` for bouncy, `"quartout"` for smooth, `"backout"` for subtle overshoot.

- **Layer at least three feedback channels per event.** Sound + visual + camera response is the minimum for an impact to feel satisfying. But more than five and you risk overwhelming the player.

- **Reserve your strongest effects for your most important events.** If everything shakes at maximum intensity, nothing feels special. Build a hierarchy of feedback intensity that matches the hierarchy of gameplay significance.

---

## What's Next?

Your game now looks and feels alive. Bricks shatter with particles, sounds confirm every hit, the screen trembles on impact, and scores roll up with satisfying easing curves.

Next up: [Module 7: UI, Menus & Save Data](module-07-ui-menus-save-data.md) -- where you will build title screens, pause menus, settings panels, and learn how to persist player progress to disk using `love.filesystem`. Your juicy game needs a front door and a save file.

[Back to the LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
