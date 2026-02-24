# 🎮 love-2-vibe

A collection of games built with [LÖVE2D](https://love2d.org) and Lua — each exploring a different genre using the same framework. Zero external dependencies, zero image files — everything is code.

## Games

### 🚀 [bullet-hell/](bullet-hell/)
A **classic vertical bullet hell** in the style of Touhou Project. Dodge dense bullet patterns, shoot back, and graze for bonus score.

- 480×720 portrait window
- 5 enemy types with Space Invaders-style pixel-art sprites
- 8 bullet pattern generators (spirals, waves, rings, aimed bursts...)
- 5 hand-crafted waves → endless mode
- Focus mode, graze system, bomb mechanic, 4 power levels

**Controls:** WASD/Arrows move · Space/Z shoot · Shift focus · X bomb

---

### 🧛 [vampire-survivors/](vampire-survivors/)
A **Vampire Survivors-style roguelite** — walk an infinite field while weapons fire automatically. Kill enemies, collect XP gems, level up, and choose upgrades.

- 800×600 landscape window with smooth-following camera
- 6 auto-firing weapons (Wand, Whip, Garlic, Axe, Bible, Lightning)
- 6 enemy types unlocking over time (Bat → Fly → Zombie → Skeleton → Ghost → Golem)
- Level-up screen with weapon, upgrade, and passive stat choices
- XP gem magnetism, knockback, damage numbers

**Controls:** WASD/Arrows move · 1/2/3 choose upgrade

Includes [`how-it-was-made.html`](vampire-survivors/how-it-was-made.html) — a standalone beginner tutorial with 10 SVG diagrams explaining every system.

---

### ⏱️ [chronobullet/](chronobullet/)
A **bullet hell with bullet-time aiming** inspired by Arco. Click to slow time to 10%, aim precisely with the mouse, then fire a hitscan beam that pierces enemies and destroys bullets in its path.

- 800×600 angled top-down camera (Y-axis 0.75× compression with depth walls)
- Bullet-time meter: drains while active, recharges from grazes and kills
- Hitscan beam weapon that carves through bullet patterns
- Hitstop on big hits, motion trails during slow-mo, blue tint + vignette
- 5 geometric enemy types, 7 hand-crafted waves → endless mode

**Controls:** WASD move · Left-click slow time → aim → fire · Right-click cancel

---

## Running

Install [LÖVE2D](https://love2d.org) (11.4+), then:

```bash
# Run any game
love bullet-hell/
love vampire-survivors/
love chronobullet/
```

## Project Structure

```
love-2-vibe/
├── README.md
├── bullet-hell/          # Classic vertical shmup
│   ├── AGENTS.md         # Agent context for this game
│   ├── main.lua
│   └── ... (12 files, ~1900 lines)
├── vampire-survivors/    # Auto-battler roguelite
│   ├── AGENTS.md
│   ├── how-it-was-made.html
│   ├── main.lua
│   └── ... (14 files, ~2300 lines)
└── chronobullet/         # Bullet-time bullet hell
    ├── AGENTS.md
    ├── main.lua
    └── ... (14 files, ~1800 lines)
```

Each game is a standalone LÖVE2D project — just point `love` at any folder. Each `AGENTS.md` provides detailed context about the game's architecture, mechanics, and codebase for AI coding agents.

## Shared Patterns

All three games share common design principles despite being different genres:

- **No external assets** — all sprites generated at runtime via `love.image.newImageData()`
- **Modular Lua files** — each system (`player`, `enemy`, `weapons`, etc.) is a separate `require()`-able module
- **`utils.lua`** — shared math helpers (distance, angle, collision, sweep)
- **Particle systems** — lightweight table-based particles, no LÖVE ParticleSystem
- **Data-driven enemies** — type definitions are plain tables; adding a new enemy is just a new table entry

## Tech

- **Language:** Lua
- **Framework:** [LÖVE2D](https://love2d.org) 11.4
- **Total:** ~6000 lines across 40 files
- **Dependencies:** None
