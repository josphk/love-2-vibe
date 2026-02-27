# LÖVE Game Dev Learning Roadmap

**For:** Comfortable programmer (JS/TS, Python) · Part-time (5–15 hrs/week) · Reads > watches · ADHD-friendly

---

## How This Roadmap Works

This is **not** a linear course. It's a set of modules you can jump between based on energy and interest. Each module is self-contained with a mini-project. Skip around freely — the only real dependency is Module 0.

**Vibe coding philosophy:** You'll be using Claude Code alongside you from the start. The goal isn't to memorize Lua syntax — it's to understand game concepts well enough to direct Claude effectively and debug what it produces.

Each module below is a summary. Click the deep dive link under each heading for the full study guide with code walkthroughs, exercises, API references, and recommended reading.

---

## Module 0: Setup & First Pixels (Day 1)

> **Deep dive:** [Full study guide](module-00-setup-first-pixels.md)

**Goal:** Get LÖVE running, draw something, feel the dopamine.

**Do this:**

1. Install LÖVE from https://love2d.org
2. Create a folder, add `main.lua`:

```lua
function love.draw()
    love.graphics.print("it works", 400, 300)
end
```

3. Drag the folder onto the LÖVE executable (or run `love .` from terminal)
4. Change the text. Change the position. Draw a rectangle. Break something. Fix it.

**Read:**
- LÖVE wiki Getting Started: https://love2d.org/wiki/Getting_Started
- Lua in 15 Minutes: https://learnxinyminutes.com/docs/lua/ (you'll feel right at home from JS/Python)

**Key Lua gotchas coming from JS/Python:**
- Arrays start at 1, not 0
- `~=` is not-equal (not `!=`)
- `and`/`or`/`not` instead of `&&`/`||`/`!`
- Tables are the only data structure (they're both arrays and dicts)
- No classes built-in, but metatables fake it (or just use a tiny class library)
- `local` keyword matters — without it, variables are global

**Time:** 1–2 hours

---

## Module 1: The Game Loop Trinity

> **Deep dive:** [Full study guide](module-01-game-loop-trinity.md)

**Goal:** Understand `love.load()`, `love.update(dt)`, `love.draw()` — this is the heartbeat of every game.

**Mini-project: Bouncing Ball**

Make a ball that bounces around the screen. This teaches:
- Game state (position, velocity)
- Delta time (`dt`) for frame-independent movement
- Basic collision (screen edges)
- The separation of logic (`update`) from rendering (`draw`)

**Then add:**
- Keyboard input (`love.keyboard.isDown`) to control a paddle
- A score counter
- Boom — you've made Pong

**Read:**
- LÖVE wiki callbacks: https://love2d.org/wiki/love (scan the callback list)
- `love.keyboard`: https://love2d.org/wiki/love.keyboard

**Time:** 3–5 hours

---

## Module 2: Game States & Structure

> **Deep dive:** [Full study guide](module-02-game-states-structure.md)

**Goal:** Learn how to organize a game beyond a single screen.

Once you have more than one screen (menu → game → game over), you need state management. This is where many beginners' code turns to spaghetti.

**Approaches (pick one):**
- **Simple:** A `gameState` variable with if/else in update/draw (fine for small games)
- **Better:** A state table with `enter()`, `update()`, `draw()`, `exit()` functions
- **Library:** `hump.gamestate` — tiny, clean, widely used

**Mini-project:** Add a title screen and game-over screen to your Pong game.

**Read:**
- hump library: https://github.com/vrld/hump (gamestate module)
- Browse the LÖVE wiki "Libraries" page for other useful small libs

**Time:** 2–3 hours

---

## Module 3: Sprites & Animation

> **Deep dive:** [Full study guide](module-03-sprites-animation.md)

**Goal:** Move beyond rectangles into actual game art.

**Key concepts:**
- Loading images: `love.graphics.newImage()`
- Sprite sheets: a single image with multiple frames
- Quads: cutting out rectangles from a sprite sheet
- Animation: cycling through quads over time

**Where to get free art (so you're not blocked on assets):**
- https://itch.io/game-assets/free
- https://opengameart.org
- https://kenney.nl (incredible free asset packs, perfect for prototyping)

**Libraries that help:**
- `anim8` — simple sprite animation: https://github.com/kikito/anim8

**Mini-project:** Replace the rectangles in your Pong/bouncing ball with actual sprites. Add a simple animated character that walks.

**Time:** 3–4 hours

---

## Module 4: Tilemaps & Levels

> **Deep dive:** [Full study guide](module-04-tilemaps-levels.md)

**Goal:** Build game worlds bigger than one screen.

**Key concepts:**
- Tiled map editor (free): https://www.mapeditor.org
- STI (Simple Tiled Implementation) library loads Tiled maps into LÖVE
- Layers (background, collision, foreground)
- Camera/viewport (showing part of a larger world)

**Libraries:**
- STI: https://github.com/karai17/Simple-Tiled-Implementation
- Camera: `hump.camera` or `gamera`

**Mini-project:** Create a small scrolling world with a character that walks around. Doesn't need to be fancy — a few rooms connected together.

**Time:** 4–6 hours

---

## Module 5: Collision & Physics

> **Deep dive:** [Full study guide](module-05-collision-physics.md)

**Goal:** Make things interact physically.

**Two paths:**

1. **Manual collision (simpler, recommended first):**
   - AABB (axis-aligned bounding box) — rectangle overlap detection
   - `bump.lua` library — grid-based collision with sliding responses
   - Great for platformers and top-down games
   - https://github.com/kikito/bump.lua

2. **Box2D physics (built into LÖVE):**
   - `love.physics` wraps Box2D
   - Full rigid body simulation — gravity, friction, joints
   - Overkill for most 2D games, but fun to play with
   - Good for: physics puzzles, Angry Birds-style, ragdolls

**Mini-project (pick one):**
- A platformer character that can jump on platforms (use bump.lua)
- A physics sandbox where you drop shapes and they bounce around (use love.physics)

**Read:**
- bump.lua README (very clear): https://github.com/kikito/bump.lua
- LÖVE physics tutorial: https://love2d.org/wiki/Tutorial:Physics

**Time:** 4–6 hours

---

## Module 6: Audio & Juice

> **Deep dive:** [Full study guide](module-06-audio-juice.md)

**Goal:** Make the game *feel* good.

"Juice" is the collection of small effects that make a game feel alive: screen shake, particle effects, tweens/easing, sound effects. This is the difference between a prototype and something people enjoy playing.

**Key concepts:**
- `love.audio` for sound effects and music
- `love.graphics.newParticleSystem` for particles
- Tweening (smooth value transitions): use `flux` or `timer` from hump
- Screen shake (offset the camera by random amounts, decay over time)

**Where to get free audio:**
- https://sfxr.me (procedural retro sound effects — addictive)
- https://freesound.org
- https://incompetech.com (royalty-free music)

**Mini-project:** Take any previous project and add: sound effects on key events, particles on collisions or pickups, screen shake on big impacts, a tween on the score display when it changes.

**Time:** 3–4 hours

---

## Module 7: UI, Menus & Save Data

> **Deep dive:** [Full study guide](module-07-ui-menus-save-data.md)

**Goal:** The unglamorous but essential stuff.

**Key concepts:**
- Drawing text with different fonts: `love.graphics.newFont()`
- Buttons (just rectangles with mouse-hover detection)
- `love.filesystem` for saving/loading (writes to a platform-appropriate app data folder)
- Serialization: save tables with a library like `bitser` or just `serpent`

**Mini-project:** Add a proper main menu, a pause screen, a settings screen (volume slider, keybinding display), and persistent high scores to one of your projects.

**Time:** 3–5 hours

---

## Module 8: Build Your First Real Game

> **Deep dive:** [Full study guide](module-08-build-first-game.md)

**Goal:** Scope small, finish something, and ship it.

This is where you pick a game idea and commit to finishing it. The #1 rule: **scope mercilessly small.**

**Good first game ideas (all 2D, all proven shippable):**

| Idea | Why it works |
|------|-------------|
| Card game / roguelike deckbuilder | Minimal art needed, deep gameplay from systems |
| Arena survival (Vampire Survivors style) | Simple mechanics, satisfying loop, scalable |
| Puzzle game (Sokoban variant, match-3) | Small scope, clear win condition |
| Top-down action (Zelda-like, one dungeon) | Tests all your skills, satisfying to play |

**The shipping checklist:**
- [ ] Core gameplay loop works and is fun
- [ ] Title screen, pause, game over
- [ ] Sound effects and music
- [ ] Save/load if needed
- [ ] 15–30 minutes of content minimum
- [ ] Tested on Windows and Mac builds
- [ ] Someone other than you has played it and given feedback

**Read:**
- LÖVE wiki on game distribution: https://love2d.org/wiki/Game_Distribution
- For Steam: https://partner.steamgames.com (Steamworks documentation)

**Time:** 30–60+ hours (this is the real project)

---

## Module 9: Shipping to Steam

> **Deep dive:** [Full study guide](module-09-shipping-to-steam.md)

**Goal:** Get your game on the Steam store.

**The process:**
1. Pay the $100 Steamworks fee
2. Set up your store page (screenshots, description, capsule art)
3. Build your game as a fused executable (LÖVE wiki covers this)
4. Upload via Steamworks depot system
5. Configure achievements, cloud saves if relevant
6. Release (or Early Access)

**LÖVE-specific build tips:**
- Windows: Fuse your .love file with love.exe
- macOS: Create a .app bundle
- Use a build script (or let Claude write one) to automate this
- `love-release` tool can help: https://github.com/MisterDA/love-release

**Time:** 5–10 hours for setup, ongoing for store management

---

## Module 10: What's Next

> **Deep dive:** [Full study guide](module-10-whats-next.md)

Once you've shipped a 2D game, you'll have real experience with:
- Game architecture and state management
- Asset pipelines
- Build and distribution
- Scoping and finishing projects
- Working with Claude Code on game logic

**From here, your paths:**
- **Stay in LÖVE:** Make a bigger, better 2D game. The framework scales.
- **Go 3D:** Move to Godot 4 with confidence. You'll already understand game loops, state, physics, and shipping.
- **Console ports:** If your game has traction, pursue the third-party LÖVE console porting path.

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| LÖVE Wiki | https://love2d.org/wiki | Your primary reference |
| Learn Lua in Y Minutes | https://learnxinyminutes.com/docs/lua/ | Quick syntax reference |
| Awesome LÖVE | https://github.com/love2d-community/awesome-love2d | Curated library list |
| Sheepolution's Guide | https://sheepolution.com/learn/book/contents | Text-based LÖVE tutorial (no video!) |
| Kenney Assets | https://kenney.nl | Free game art |
| SFXR | https://sfxr.me | Procedural sound effects |
| LÖVE Forums | https://love2d.org/forums | Community help |
| Itch.io LÖVE tag | https://itch.io/games/made-with-love2d | See what others have built |

---

## ADHD-Friendly Tips

- **Work in 25-min sprints.** Set a timer. When it rings, decide if you want another round. No guilt if you don't.
- **Keep a "spark list."** When you get a random game idea mid-session, write it down and go back to what you're doing. The list will be there when you're ready.
- **Rotate modules when stuck.** Bored of collision? Jump to audio. Frustrated with UI? Go draw some sprites. The roadmap is non-linear on purpose.
- **Ship ugly.** Programmer art is fine. Placeholder sounds are fine. A finished ugly game teaches more than a beautiful unfinished one.
- **Use Claude Code aggressively.** Let it write the boilerplate. Focus your brain energy on the design decisions and the fun parts.
- **Play other LÖVE games on itch.io** when you need inspiration but can't code. Many are open source — read their code.
