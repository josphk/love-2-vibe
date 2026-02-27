# Module 8: Build Your First Real Game

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 40-80 hours (this is the real project)
**Prerequisites:** [Modules 0-7](love2d-learning-roadmap.md)

---

## Overview

You know how to draw sprites, animate them, build tilemaps, detect collisions, play audio, build UI, and save data. You have all the individual skills. Now comes the hard part: **finishing a game**.

This module is different from the others. There is no new API to learn. Instead, this is about the discipline of combining everything you know into a single, cohesive, shippable product. It is the most important module in the entire roadmap, because the gap between "I can make game mechanics" and "I shipped a game" is where most aspiring game developers permanently stall.

By the end of this module, you will have a playable, polished, distributable game that other people can download and play. That puts you ahead of roughly 99% of people who say they want to make games.

---

## Core Concepts

### Why Finishing Matters

Most game projects die. Not because the developer lacked skill, but because they lacked the discipline to push through the unglamorous middle. The first 20% is exciting -- new mechanics, fresh ideas, rapid progress. The last 10% is satisfying -- polish, juice, seeing it come together. The 70% in between is a grind. Menus, edge cases, save systems, build scripts, playtesting, bug fixes.

Derek Yu, creator of Spelunky, wrote the definitive essay on this: "Finishing a Game." His core argument is that finishing is a skill you can only develop by finishing. Starting ten projects teaches you how to start. Finishing one teaches you everything else.

Consider the games you admire. Balatro is a card game with relatively simple mechanics. Vampire Survivors has basic art and straightforward gameplay. Celeste started as a game jam entry. None of these succeeded because they were technically ambitious. They succeeded because their creators **finished them** and polished what was there.

Your first shipped game will not be your best game. It will probably be your simplest game. That is the point. Ship something small. Learn what shipping feels like. Then make something better.

### Choosing Your First Game

Not all games are equal in difficulty to finish. Here is an honest assessment of the four recommended types:

**Arena Survival (Vampire Survivors style).** This is the most forgiving first game. The core loop is simple: move, auto-attack, kill enemies, collect XP, level up, repeat. Art requirements are minimal -- colored rectangles work. Content scales naturally: add more enemy types, more weapons, more upgrades. There is no level design to worry about. The game gets harder by spawning more enemies, not by designing harder challenges. If you are unsure what to pick, pick this.

**Puzzle Game (Sokoban variant, match-3).** Small scope, clear win condition, minimal art. The challenge is designing good puzzles, not engineering complex systems. A Sokoban variant needs a grid, a player, some boxes, and some target tiles. Twenty to thirty levels takes a few hours to design. The risk: puzzle design is a skill in itself. If you find yourself stuck on "how do I make interesting puzzles," you are blocked on design, not code.

**Card Game / Roguelike Deckbuilder.** Minimal art (text on rectangles works for cards), deep gameplay from systems, naturally replayable. The risk: balancing a card game is hard. You need enough cards to be interesting (30-50 minimum), and they all need to interact in non-broken ways. Scope creep is the primary danger here -- it is very easy to keep adding "just one more card."

**Top-Down Action (Zelda-like, one dungeon).** This tests every skill: tilemaps, collision, enemy AI, items, UI, state management. It is the most technically complete project but also the highest scope risk. Limit yourself to one dungeon with five to eight rooms, two to three enemy types, one boss, and one key item. If you are tempted to add a second dungeon, stop. Ship what you have.

**What NOT to pick for a first game:** Open world. MMO. MOBA. Metroidvania (larger scope than you think). Roguelike with procedural generation (generation is a project by itself). Anything requiring online multiplayer. Anything you describe as "like [AAA game] but..."

### Scoping Ruthlessly

**The minimum viable game** is the smallest version of your idea that is still fun to play. Not the version you dreamed of. Not the version with all the features. The version where the core loop works and someone can sit down, play for fifteen minutes, and have a good time.

Here is a scoping exercise. Write down every feature you want in your game. Now cross off the bottom half. Look at what remains. Cross off the bottom half again. What you have left is your minimum viable game. It probably still has too many features, but it is a start.

**The 80/20 rule applies aggressively to games.** 20% of your features deliver 80% of the fun. The auto-attacking weapon system in Vampire Survivors is 80% of the fun. The hundreds of achievements, the secret characters, the unlock conditions -- those are the other 80% of the work for 20% of the fun. Ship the 20% first.

**"Do the hard thing first"** is Derek Yu's other critical insight. If there is one mechanic you are not sure you can build, tackle it on day one. If you discover on day one that your core mechanic does not work, you have lost one day. If you discover it on week three, you have lost three weeks and all your motivation.

**Time-box features.** Give yourself two hours to implement a feature. If it is not working after two hours, either simplify it or cut it. Features that take longer than expected are scope landmines. They blow up your timeline without warning.

### Project Planning for Solo Devs

Forget Gantt charts. You are one person. You need a task list and a calendar. That is it.

**Weekly milestones** are the right granularity. Each week, your game should be playable. Not finished -- playable. Week one: core loop works (move, attack, one enemy). Week two: three enemy types, scoring. Week three: title screen, game over, sound effects. Week four: polish, playtesting, build.

**The "playable every week" rule** is the single most important planning guideline. If your game is not playable at the end of any given week, something went wrong. Either you are building infrastructure instead of content, or your scope is too large. Playable means someone can pick it up and play it, even if it is ugly and incomplete.

**Keep a simple task list.** A text file, a spreadsheet, or a Trello board. Whatever you will actually use. Each item should be small enough to finish in one to three hours. "Add enemy AI" is too big. "Enemy walks toward player" is the right size. "Enemy stops when hitting a wall" is another task. "Enemy takes damage and dies" is another. Small tasks give you a steady stream of completion, which keeps motivation high.

### Architecture for a Real Game

Your game needs a folder structure that scales. Here is a proven layout:

```
mygame/
  main.lua              -- entry point, state machine setup
  conf.lua              -- window settings, identity
  states/               -- game states (title, gameplay, pause, gameover)
    title.lua
    gameplay.lua
    pause.lua
    gameover.lua
  entities/             -- game objects (player, enemies, items, bullets)
    player.lua
    enemy.lua
    bullet.lua
    pickup.lua
  systems/              -- game systems (spawner, combat, camera)
    spawner.lua
    combat.lua
  data/                 -- data tables (enemy definitions, weapon stats, level configs)
    enemies.lua
    weapons.lua
    levels.lua
  assets/               -- art, audio, fonts
    sprites/
    audio/
    fonts/
  lib/                  -- third-party libraries (bump, anim8, hump, etc.)
```

**Data-driven design** is the key architectural principle. Enemy stats, weapon damage, spawn rates, level layouts -- all of these belong in data tables, not hardcoded in logic. When your enemy definitions live in `data/enemies.lua`, you can add a new enemy type by adding a table entry, not by writing new code.

```lua
-- data/enemies.lua
return {
    { name = "slime", hp = 3, speed = 40, damage = 1, xp = 5, color = {0.2, 0.8, 0.2} },
    { name = "bat", hp = 1, speed = 100, damage = 1, xp = 3, color = {0.5, 0.3, 0.6} },
    { name = "skeleton", hp = 8, speed = 60, damage = 2, xp = 15, color = {0.9, 0.9, 0.9} },
}
```

**The entity list pattern** from Module 2 scales to a full game. Every entity (player, enemies, bullets, pickups) goes in a shared list. Update them in a loop. Draw them in a loop. Remove dead ones with backwards iteration. This is not a fancy ECS -- it is a Lua table with `update` and `draw` methods on each item. It works for games with hundreds of entities. You do not need more than this.

### Content Pipeline

Content is what the player experiences: levels, enemies, weapons, items, dialogue, audio. Code is what makes content work. The ratio should be heavily weighted toward content by the end of your project.

**Data files over hardcoded values.** Every number that a designer (you) might want to tweak should be in a data file. Enemy speed, weapon damage, spawn intervals, XP curves -- all data. When you want to make the game harder, you edit a number in a table. You do not hunt through code.

**Procedural generation as a force multiplier.** Even simple procedural generation can dramatically extend content. A random enemy spawn pattern is trivial to implement but creates variety. Random weapon stat rolls (damage within a range, speed within a range) create loot diversity. You do not need complex algorithms -- random selection from curated pools is enough.

**Asset organization matters.** Name files consistently: `enemy_slime_idle.png`, `enemy_bat_fly.png`, `sfx_hit_01.wav`, `sfx_hit_02.wav`. When you have fifty assets, you will thank yourself for the naming convention.

### Playtesting

**You are the worst judge of your own game.** You know where every enemy spawns. You know every mechanic. You know which button does what. You are incapable of experiencing your game as a new player.

**The playtesting protocol:** Hand someone your game. Say nothing except "play this." Do not explain the controls. Do not explain the goal. Do not say "oh, you're supposed to..." when they get stuck. Watch. Take notes. Every time you feel the urge to explain something, write it down -- that is a design problem, not a player problem.

**What feedback to listen to:** If three out of three playtesters get stuck at the same point, that point is broken. If one out of three suggests adding a crafting system, ignore them. Listen to problems ("I didn't understand what to do"), not solutions ("you should add a tutorial popup"). Problems are data. Solutions are opinions.

**When to playtest:** As early as possible. Your first playtest should happen when the core loop works, even if the game is rectangles on a black screen. Discovering that your core mechanic is confusing in week one saves you from building four weeks of content on a broken foundation.

### Polish Checklist

Polish is the difference between a game that feels "done" and one that feels like a school project. Here is the specific checklist:

- **Every action has audio feedback.** Attacks, hits, deaths, pickups, menu navigation, button presses. Silence is the enemy of game feel.
- **Screen transitions exist.** Fade in, fade out, or a quick wipe between states. No jarring hard cuts.
- **UI is consistent.** Same font throughout. Same button style. Same color scheme. Pick a palette and stick to it.
- **Edge cases are handled.** What happens when the player dies with zero lives? What happens when they pause during a level transition? What happens when they Alt-Tab? Test the weird cases.
- **Settings persist.** Volume, fullscreen, controls -- saved and loaded on startup.
- **The game has a clear start and end.** Title screen with a play button. A game over condition. A way to quit gracefully.
- **Performance is stable.** Consistent frame rate. No memory leaks from un-removed entities. No garbage collection stutters from excessive table creation.

### Building and Distribution

A game that only runs on your machine is not a shipped game. You need distributable builds for at least Windows and macOS.

**Creating a .love file** is the first step. A `.love` file is a ZIP archive containing your game files:

```bash
zip -9 -r mygame.love . -x "*.git*" -x "*.aseprite" -x "builds/*"
```

**Fusing for Windows** means concatenating `love.exe` with your `.love` file and including the LOVE DLLs:

```bash
cat love.exe mygame.love > mygame.exe
```

Then copy all `.dll` files from the LOVE download into the same folder. Test on a machine that has never had LOVE installed.

**Fusing for macOS** means copying your `.love` file into a LOVE `.app` bundle and updating the `Info.plist` with your game's name and bundle identifier.

**Use makelove** to automate all of this. It handles downloading LOVE binaries, fusing, bundling, and packaging for all platforms:

```bash
pip install makelove
makelove          # builds all targets from makelove.toml
```

**Test your builds early.** Build for your target platforms in week one, not week four. A path casing bug that only appears on Linux is easier to fix when your game is a moving rectangle than when it is a finished product.

### The Emotional Journey

Every game project follows a predictable emotional arc. Knowing this arc exists makes it easier to survive.

**Week one: Excitement.** Everything is new. Progress is fast. You can see the game taking shape. This is the honeymoon phase.

**Weeks two to three: Momentum.** Still fun. Features are coming together. You might show someone and get positive feedback. Motivation is high.

**Weeks three to five: The Grind.** The exciting parts are done. Now you are building menus, fixing edge cases, balancing numbers, and debugging save file corruption. The game does not feel fun anymore because you have played it five hundred times. This is where most projects die.

**The crisis: "Is this even fun?"** You will ask yourself this. The answer is: you do not know, because you are too close to it. This is why playtesting matters. If playtesters are having fun, the game is fun. Your feelings during the grind are not a reliable indicator.

**The push through.** If you keep working -- even slowly, even reluctantly -- you will reach a point where the game starts feeling complete. Polish makes everything feel better. Audio makes everything feel better. A working title screen makes it feel real.

**The finish line.** Uploading your game to itch.io. Sending the link to someone. Watching a stranger play your game. This feeling is worth every minute of the grind. And now you know you can do it again.

---

## Code Walkthrough

Rather than a complete game (which would be thousands of lines), here are architecture skeletons showing how all the modules connect.

### Arena Survival (Vampire Survivors Style)

```
arena-survivors/
  main.lua
  conf.lua
  states/
    title.lua
    gameplay.lua
    levelup.lua
    gameover.lua
  entities/
    player.lua
    enemy.lua
    bullet.lua
    xp_gem.lua
  systems/
    spawner.lua
    weapons.lua
  data/
    enemies.lua
    weapons.lua
  lib/
    bump.lua
    flux.lua
```

**entities/player.lua:**

```lua
local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.speed = 150
    self.hp = 100
    self.maxHp = 100
    self.xp = 0
    self.xpToNext = 20
    self.level = 1
    self.weapons = {}
    self.invTimer = 0
    return self
end

function Player:update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up")    then dy = -1 end
    if love.keyboard.isDown("s", "down")  then dy =  1 end
    if love.keyboard.isDown("a", "left")  then dx = -1 end
    if love.keyboard.isDown("d", "right") then dx =  1 end

    if dx ~= 0 and dy ~= 0 then
        dx, dy = dx * 0.7071, dy * 0.7071
    end
    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt
    self.invTimer = math.max(0, self.invTimer - dt)

    for _, weapon in ipairs(self.weapons) do
        weapon:update(dt, self)
    end
end

function Player:addXP(amount)
    self.xp = self.xp + amount
    if self.xp >= self.xpToNext then
        self.xp = self.xp - self.xpToNext
        self.level = self.level + 1
        self.xpToNext = math.floor(self.xpToNext * 1.5)
        return true  -- signals level-up to gameplay state
    end
    return false
end

function Player:draw()
    if self.invTimer > 0 and math.floor(self.invTimer * 10) % 2 == 0 then
        return
    end
    love.graphics.setColor(0.2, 0.6, 1.0)
    love.graphics.rectangle("fill", self.x - 12, self.y - 12, 24, 24)
    love.graphics.setColor(1, 1, 1)
end

return Player
```

**systems/spawner.lua:**

```lua
local Enemy = require("entities.enemy")
local enemyData = require("data.enemies")

local Spawner = {}
Spawner.__index = Spawner

function Spawner.new()
    local self = setmetatable({}, Spawner)
    self.timer = 0
    self.interval = 2.0
    self.elapsed = 0
    return self
end

function Spawner:update(dt, player, entities)
    self.elapsed = self.elapsed + dt
    self.timer = self.timer + dt

    local currentInterval = math.max(0.3, self.interval - self.elapsed * 0.01)

    if self.timer >= currentInterval then
        self.timer = 0
        local angle = math.random() * math.pi * 2
        local dist = 400
        local ex = player.x + math.cos(angle) * dist
        local ey = player.y + math.sin(angle) * dist

        local pool = {}
        for _, e in ipairs(enemyData) do
            if self.elapsed >= (e.minTime or 0) then
                table.insert(pool, e)
            end
        end
        if #pool == 0 then pool = { enemyData[1] } end

        local data = pool[math.random(#pool)]
        table.insert(entities, Enemy.new(ex, ey, data))
    end
end

return Spawner
```

### Top-Down Zelda-like (One Dungeon)

```
zelda-dungeon/
  main.lua
  conf.lua
  states/
    title.lua
    gameplay.lua
    pause.lua
    gameover.lua
    victory.lua
  entities/
    player.lua
    enemy.lua
    item.lua
  systems/
    dungeon.lua
    combat.lua
  data/
    rooms.lua
    enemies.lua
    items.lua
  lib/
    bump.lua
    anim8.lua
```

**systems/dungeon.lua:**

```lua
local roomData = require("data.rooms")
local Enemy = require("entities.enemy")
local Item = require("entities.item")

local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon.new()
    local self = setmetatable({}, Dungeon)
    self.currentRoom = "entrance"
    self.entities = {}
    self:loadRoom(self.currentRoom)
    return self
end

function Dungeon:loadRoom(roomId)
    local room = roomData[roomId]
    self.currentRoom = roomId
    self.entities = {}
    self.exits = room.exits

    if not room.cleared then
        for _, def in ipairs(room.enemies or {}) do
            table.insert(self.entities, Enemy.new(def.x, def.y, def.type))
        end
    end

    for _, def in ipairs(room.items or {}) do
        if not def.collected then
            table.insert(self.entities, Item.new(def.x, def.y, def.type))
        end
    end
end

function Dungeon:checkTransition(player)
    for direction, targetRoom in pairs(self.exits) do
        if self:playerAtExit(player, direction) then
            local target = roomData[targetRoom]
            if target.locked and not player.inventory.key then
                return nil  -- locked
            end
            return targetRoom, direction
        end
    end
    return nil
end

function Dungeon:update(dt, player)
    for i = #self.entities, 1, -1 do
        self.entities[i]:update(dt, player)
        if self.entities[i].dead then
            table.remove(self.entities, i)
        end
    end

    local room = roomData[self.currentRoom]
    if not room.cleared and room.enemies and #room.enemies > 0 then
        local enemiesAlive = false
        for _, e in ipairs(self.entities) do
            if e.isEnemy then enemiesAlive = true; break end
        end
        if not enemiesAlive then
            room.cleared = true
        end
    end
end

return Dungeon
```

**data/rooms.lua:**

```lua
return {
    entrance = {
        exits = { north = "hallway" },
        enemies = {},
        items = {},
        cleared = false,
    },
    hallway = {
        exits = { south = "entrance", north = "hub", east = "treasure_room" },
        enemies = {
            { x = 100, y = 80, type = "skeleton" },
            { x = 180, y = 120, type = "skeleton" },
        },
        items = {},
        cleared = false,
    },
    treasure_room = {
        exits = { west = "hallway" },
        enemies = {
            { x = 120, y = 60, type = "bat" },
        },
        items = {
            { x = 140, y = 100, type = "key", collected = false },
        },
        cleared = false,
    },
    boss_room = {
        exits = { south = "hub" },
        locked = true,
        enemies = {
            { x = 160, y = 80, type = "boss" },
        },
        items = {},
        cleared = false,
    },
}
```

Both skeletons demonstrate the same principles: **data-driven design**, separation of entities from systems, game states for flow control, and the entity list pattern. The genre changes the content, not the architecture.

---

## API Reference: Build Tools

This module does not introduce new LOVE APIs. Instead, here is the toolchain reference.

### conf.lua Distribution Settings

| Setting | Purpose | Example |
|---|---|---|
| `t.identity` | Save directory name. Pick once, never change. | `"arena-survivors"` |
| `t.version` | LOVE version for compatibility | `"11.5"` |
| `t.window.title` | Window title bar text | `"Arena Survivors"` |
| `t.window.width/height` | Default window size | `1280`, `720` |
| `t.console` | Opens terminal on Windows. **Must be false for release.** | `false` |
| `t.modules.*` | Disable unused modules | `t.modules.physics = false` |

### makelove Commands

| Command | Purpose |
|---|---|
| `pip install makelove` | Install the build tool |
| `makelove` | Build all targets from `makelove.toml` |
| `makelove win64` | Build Windows 64-bit only |
| `makelove macos` | Build macOS only |

### Creating a .love File Manually

```bash
zip -9 -r mygame.love . -x "*.git*" -x "*.aseprite" -x "builds/*"
```

---

## Libraries & Tools

| Tool | Purpose | URL |
|---|---|---|
| **makelove** | Build tool for creating distributable executables | [github.com/pfirsich/makelove](https://github.com/pfirsich/makelove) |
| **love-release** | Older alternative build tool | [github.com/MisterDA/love-release](https://github.com/MisterDA/love-release) |
| **Aseprite** | Pixel art editor with animation. Paid but excellent. Free alternative: LibreSprite. | [aseprite.org](https://www.aseprite.org) |
| **Tiled** | Map editor (Module 4 recap) | [mapeditor.org](https://www.mapeditor.org) |
| **jsfxr** | Browser-based sound effect generator | [sfxr.me](https://sfxr.me) |
| **Git** | Version control. Not optional for a real project. | [git-scm.com](https://git-scm.com) |
| **itch.io** | Game distribution platform. Free to upload. | [itch.io](https://itch.io) |

---

## Common Pitfalls

**1. Scope creep.** You start with a three-weapon arena game. By week two, you have sketched a skill tree, meta-progression, weapon evolution, and a storyline. None were in your design doc. Each sounded like "just one more thing." Together they tripled your scope. The fix: keep a "maybe later" list. Finish the original scope first. If you have time left (you will not), revisit the list.

**2. Polishing too early.** You spend three days perfecting the title screen animation before the gameplay loop works. You tweak particle colors for an hour instead of implementing the enemy those particles celebrate killing. Polish is the last 10% of work, not the first. Build ugly first. Make it work. Then make it pretty.

**3. Not playtesting until the end.** You work for four weeks in isolation. You show the game to someone. They do not understand the controls. They miss the core mechanic. They get stuck on the first screen. Every one of these could have been caught in week one. Playtest early and often.

**4. Over-engineering invisible systems.** You build an event bus, a component registry, a hot-reloading system, and a debug console. The player will never see any of these. They took two weeks. Your actual game content got two weeks as well. If you spend more time on infrastructure than content, you are building an engine, not a game.

**5. Ignoring build and distribution until the last day.** You finish the game and run `makelove`. It errors. Windows build crashes. macOS bundle is missing assets. Three panicked days of debugging follow. The fix: build in week one. Catch path casing issues and platform bugs early.

**6. Working six-plus months without shipping.** The longer a project takes, the more likely it dies. Motivation decays over time. Your first game should take four to eight weeks. If you are past eight weeks and not close to done, cut drastically and ship what you have. There is no shame in shipping a tiny game.

---

## Exercises

### Exercise 1: Design Doc and Core Loop Weekend

**Time:** One weekend (8-16 hours)

Pick one of the four game types. Then:

1. Write a one-page design document. Include: one-sentence description, core loop, every entity type, every screen, content estimate. If it does not fit on one page, cut until it does.
2. Create the project skeleton: folder structure, `conf.lua`, `main.lua`, game states, player entity.
3. Implement the core loop. For arena survival: movement, auto-attack, one enemy type. For Zelda-like: movement, sword attack, one enemy that takes damage and dies. For puzzle: grid, one movable piece, one win condition.
4. By Sunday night, someone should be able to pick up your laptop and play it.

**Stretch:** Build for Windows and macOS before the weekend is over.

### Exercise 2: Content, Juice, and the Shipping Checklist

**Time:** 2-4 weeks (20-40 hours)

Take the core loop from Exercise 1 and build it into a complete game:

1. **Content.** Enough for 15-30 minutes of gameplay. For arena survival: 3 weapon types, 3-5 enemy types, difficulty scaling. For Zelda-like: 5-8 rooms, 2-3 enemy types, a key, a boss.
2. **Game states.** Title screen, pause, game over. For arena survival: level-up screen.
3. **Audio.** Sound effects for every action. One background music track.
4. **Juice.** Screen shake, particles, hit flash, tweened UI.
5. **Save/load.** Persist high score or best run.
6. **Polish.** Walk through Section 8's checklist.

### Exercise 3: Playtest, Build, and Ship

**Time:** 1-2 weeks (10-15 hours)

1. Build standalone executables for Windows and macOS. Test on a machine without LOVE installed.
2. Get 3 external playtesters. Hand them the build with no instructions. Watch and take notes.
3. Triage feedback: critical (crashes, blocking), important (confusing, unclear), nice-to-have (balance, visual).
4. Fix critical and important issues. Run a second playtest.
5. Upload to itch.io with a description, screenshots, and downloads.

Your game is shipped. You did what most aspiring game developers never do.

---

## Recommended Reading & Resources

### Essential

| Resource | Type | What You Get |
|---|---|---|
| [Finishing a Game (Derek Yu)](https://makegames.tumblr.com/post/1136623767/finishing-a-game) | Blog post | The definitive essay on why finishing matters |
| [LOVE Wiki: Game Distribution](https://love2d.org/wiki/Game_Distribution) | Wiki | Building and distributing LOVE games |
| [makelove](https://github.com/pfirsich/makelove) | Tool | Build tool documentation |
| [itch.io Creator FAQ](https://itch.io/docs/creators) | Docs | Publishing on itch.io |

### Go Deeper

| Resource | Type | What You Get |
|---|---|---|
| [Spelunky (Derek Yu, book)](https://bossfightbooks.com/products/spelunky-by-derek-yu) | Book | Development deep-dive, iteration, and scope |
| [The Art of Game Design (Jesse Schell)](https://www.schellgames.com/art-of-game-design/) | Book | Comprehensive game design framework |
| [Rami Ismail: Surviving Creative Endeavors](https://www.youtube.com/watch?v=Lp_bfMnJeMI) | GDC Talk | Sustaining creative work over years |
| [Kenney Assets](https://kenney.nl/assets) | Asset packs | Free public domain game art |

---

## Key Takeaways

- **Finishing is a skill you build by finishing, not by starting.** Your first shipped game matters more than your tenth abandoned prototype.

- **Scope is the most dangerous variable.** When in doubt, cut features. A focused game with three enemy types beats a sprawling game with thirty.

- **Do the hard thing first.** If one mechanic might not work, tackle it on day one, not week three.

- **Build for your target platforms in week one.** Catch path casing bugs and missing assets early.

- **Playtest with fresh eyes, not your own.** Every urge to explain something is a bug report.

- **The emotional trough is normal and temporary.** Every developer hits the wall where the project stops being fun. Push through. The satisfaction of finishing is on the other side.

- **Ship imperfect.** A finished game with rough edges teaches you more than a perfect game that exists only in your head.

---

## What's Next?

You shipped a game. Someone can download it and play it. That is a genuine accomplishment, and everything that follows builds on it.

[Module 9: Shipping to Steam](module-09-shipping-to-steam.md) covers the path from itch.io to the world's largest game distribution platform -- store pages, build pipelines, Steamworks integration, and the business side of getting your game in front of players.

Back to the [LOVE2D Learning Roadmap](love2d-learning-roadmap.md).
