# CHRONOBULLET — Agent Context

## Overview
A bullet hell with a bullet-time aiming mechanic, built with LÖVE2D and Lua. The player dodges dense bullet patterns in a bounded arena. Left-click slows everything to 10% speed; a second click fires a hitscan beam that pierces enemies and destroys bullets in its path. Inspired by Arco's tactical time-manipulation gameplay.

## Genre
Bullet hell / tactical action with time manipulation

## Architecture
- **14 Lua files**, ~1800 lines total, zero external dependencies
- Angled top-down camera (Y-axis compressed to 0.75×) with depth-rendered walls
- Dual time scales: real-time (for UI, transitions, particles) and world-time (for gameplay, scaled by bullet-time)
- Custom crosshair (system cursor hidden), geometric enemy rendering

## Key Files
| File | Purpose |
|---|---|
| `main.lua` | Game loop, mouse input state machine (normal → bullet-time → fire), collision, scoring |
| `bullettime.lua` | Time-scale manager: meter drain/recharge, smooth lerp, hitstop, activate/deactivate |
| `player.lua` | WASD movement, mouse aim tracking, hitscan beam weapon with bullet destruction |
| `camera.lua` | Y-axis compression transform, screen shake, zoom, screen↔world coordinate conversion |
| `enemy.lua` | 5 types (Turret, Spinner, Orbiter, Heavy, Dasher) drawn as geometric shapes with shadows |
| `bullet.lua` | Enemy bullet pool with slow-mo motion trails |
| `patterns.lua` | 7 bullet patterns: radial, aimed, spiral, expanding ring, cross, shotgun, spinning spiral |
| `spawner.lua` | 7 hand-crafted waves + endless procedural mode with HP scaling |
| `particles.lua` | Beam trail renderer (glow + core + fade), burst effects, floating combo text |
| `background.lua` | Arena floor with tile grid, 3D south/east wall depth faces, corner accents |
| `sprites.lua` | Top-down player pixel-art sprite (2 frames) |
| `hud.lua` | Lives, score, wave, graze counter, bullet-time meter bar, custom crosshair |
| `utils.lua` | Math helpers including `pointToSegmentDist` for beam collision |
| `conf.lua` | 800×600 landscape window |

## Controls
- **WASD / Arrow keys** — Move
- **Left click** — Enter bullet-time (first click) → Fire beam (second click)
- **Right click** — Cancel bullet-time without firing
- **R** — Restart after game over

## Core Mechanic: Bullet-Time Beam
1. Player left-clicks → `bullettime:activate()` sets `targetScale = 0.10`
2. World updates at 10% speed; player moves at 35% real speed (still responsive)
3. Dashed aim line + beam width corridor preview drawn from player toward mouse
4. Screen tints blue with vignette overlay, bullets show motion trails
5. Player left-clicks again → `player:fireBeam()` traces a hitscan ray
6. Ray checks `pointToSegmentDist` for every bullet and enemy within `BEAM_WIDTH` (14px)
7. Bullets destroyed, enemies damaged, particles spawned, score awarded
8. `bullettime:deactivate()` lerps time back to 1.0

## Bullet-Time Meter
- **Max**: 100, **Drain**: 28/sec while active, **Recharge**: 16/sec while inactive
- **Graze**: +1.5 meter per near-miss bullet
- **Kill**: +10 meter per enemy killed, +12 per beam hit, +1.5 per bullet destroyed
- **Empty**: forced deactivation with 0.6s cooldown lockout

## Scoring
- Enemy kills: per-type score values (200–500)
- Bullet destruction: 15 points each
- Combo bonus: 5+ bullets in one beam = extra ×10 per bullet
- Graze: 20 points per near-miss

## Enemy Types
| Type | Shape | HP | Behaviour |
|---|---|---|---|
| Turret | Diamond | 30 | Stationary, aimed 5-bullet bursts |
| Spinner | Circle | 50 | Hovers, continuous 3-arm spiral |
| Orbiter | Circle | 25 | Orbits a center point, radial bursts |
| Heavy | Hexagon | 80 | Slow, alternates expanding rings / shotgun / spin spirals |
| Dasher | Triangle | 20 | Dashes to random positions, fires aimed bursts |

## Arena
- Bounded play area: (50, 40) to (750, 560) in game-space
- Y-compression at 0.75× creates angled perspective
- South and east walls rendered with depth faces
- All entities clamped within arena bounds

## How to Run
```bash
love chronobullet/
```

## Design Notes for Agents
- Two separate `dt` values flow through the game: `realDt` (for UI/camera/transitions) and `worldDt` (for gameplay)
- The beam is a hitscan, not a projectile — `Utils.pointToSegmentDist()` checks every bullet/enemy against the line
- Hitstop (`bt.hitstop > 0`) sets `timeScale = 0` for a few frames — total freeze for impact
- Camera Y-compression is applied via `love.graphics.scale(1, 0.75)` — all world drawing happens inside this transform
- Mouse→world conversion reverses the compression: `worldY = centerY + (screenY - centerY) / 0.75`
- Enemies use geometric shapes (`love.graphics.polygon`) rather than pixel art — cleaner at the angled view
- The spawner's wave format is simple: `{ type = "spinner", x = 400, y = 180 }` with optional orbit/target params
