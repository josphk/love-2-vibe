# Vampire Survivors — Agent Context

## Overview
A Vampire Survivors-style roguelite built with LÖVE2D and Lua. The player roams an infinite 2D plane while weapons fire automatically. Enemies swarm from all directions; killing them drops XP gems that fuel a level-up system with weapon and stat choices. Survive as long as you can.

## Genre
Auto-battler / horde-survival roguelite

## Architecture
- **14 Lua files**, ~2300 lines total, zero external dependencies
- Camera-based rendering on an infinite world plane
- Multi-colour palette pixel-art sprites generated at runtime
- Includes `how-it-was-made.html` — a standalone beginner tutorial page with 10 SVG diagrams

## Key Files
| File | Purpose |
|---|---|
| `main.lua` | Game loop, state management (playing / level-up / game over), collision wiring |
| `player.lua` | Free WASD movement, HP, XP, stat multipliers (might, speed, cooldown, area, armor, recovery) |
| `weapons.lua` | 6 auto-firing weapons × 5 levels each, unified projectile pool with per-weapon fire functions |
| `enemy.lua` | 6 enemy types (Bat, Fly, Zombie, Skeleton, Ghost, Golem) with chase AI and knockback |
| `spawner.lua` | Time-based difficulty tiers: new enemy types unlock at 0:00, 0:30, 1:00, 2:00, 3:00, 5:00 |
| `gems.lua` | 4-tier XP gems (blue/green/red/gold) + health pickups, magnetic collection |
| `levelup.lua` | Pause screen presenting 3 random choices: new weapon, weapon upgrade, or passive stat boost |
| `camera.lua` | Smooth-following camera with world↔screen coordinate conversion |
| `sprites.lua` | Multi-colour palette pixel-art: player + 6 enemy types, 2 animation frames each |
| `background.lua` | Infinite tiled ground with deterministic colour variation |
| `particles.lua` | Explosions, sparks, floating damage numbers, floating text |
| `hud.lua` | XP bar, HP bar, timer, level, kills, weapon slot icons, stat summary |
| `utils.lua` | Math helpers: distance, findNearest, shuffle, sweep, circle collision |
| `conf.lua` | 800×600 landscape window |

## Controls
- **WASD / Arrow keys** — Move (only input during gameplay)
- **1 / 2 / 3** — Choose upgrade on level-up screen
- **R** — Restart after death

## Weapons (all auto-fire)
| Weapon | Type | Behaviour |
|---|---|---|
| Magic Wand | Projectile | Bolt at nearest enemy, pierce scales with level |
| Holy Whip | Area | Slash in front of player, high knockback |
| Garlic Aura | Area (follow) | Constant damage ring around player |
| Throwing Axe | Projectile | Arcing throw with gravity, passes through enemies |
| King Bible | Orbital | Books orbit the player, re-hit on cooldown |
| Lightning Ring | Targeted | Instant strike on random nearby enemies |

## Passive Upgrades
Max HP, Move Speed, Might (damage), Armor, Recovery (HP regen), Pickup Range, Cooldown Reduction, Area

## Enemy Unlock Timeline
| Time | Enemy | Speed | HP |
|---|---|---|---|
| 0:00 | Bat | 110 | 8 |
| 0:30 | Fly | 140 | 5 |
| 1:00 | Zombie | 45 | 20 |
| 2:00 | Skeleton | 65 | 30 |
| 3:00 | Ghost | 80 | 18 |
| 5:00 | Golem | 30 | 120 |

## How to Run
```bash
love vampire-survivors/
```

## Design Notes for Agents
- The weapon system is data-driven: each weapon is a definition table with `levels[]` and a `fire()` function
- All projectiles (from all weapons) share one flat pool `Weapons.projectiles` — update and draw in single loops
- Pierce tracking uses a `hitSet` keyed by `tostring(enemy)` — for orbital weapons, `hitCooldown` allows re-hits
- The level-up choice generator shuffles all options then sorts by priority (new weapon > upgrade > passive)
- Difficulty scaling: `HP × (1 + time × 0.005)`, spawn rate `0.8 + time × 0.012` enemies/sec
- The camera uses `lerp` smoothing: `camera.x = lerp(camera.x, player.x, smoothing * dt)`
- Background draws tiles only within the camera's visible bounds (computed from camera position ± screen half-size)
