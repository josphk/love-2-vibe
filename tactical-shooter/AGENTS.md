# TACTICAL-SHOOTER — Agent Context

## Overview
An isometric tactical stealth shooter inspired by Intravenous. The player moves on an isometric grid, uses a field-of-view cone and sight line to aim, and shoots enemies that patrol, chase when they have line of sight, and retreat when low on HP. Four enemy types with distinct stats and behaviors.

## Genre
Tactical shooter / stealth action, isometric view

## Architecture
- **9 Lua files**, ~600 lines total, zero external dependencies
- Isometric 2D grid (24×18) with coordinate conversion (grid ↔ screen)
- No external assets — all rendering via `love.graphics` (ellipses, polygons, lines)
- Modular layout: map, player, enemy, bullet, background, HUD, utils

## Key Files
| File | Purpose |
|------|--------|
| `main.lua` | Game loop, bullet collision vs player/enemies, damage numbers, win/lose, input |
| `map.lua` | Grid build, `gridToScreen` / `screenToGrid`, `isWall`, `lineOfSight`, `raycast` |
| `player.lua` | Player state, WASD movement, mouse aim, shoot cooldown, draw |
| `enemy.lua` | Type definitions (Grunt, Scout, Heavy, Sniper), spawn list, AI (patrol/chase/retreat), draw |
| `bullet.lua` | Bullet list, add, update (move + wall collision), draw |
| `background.lua` | Isometric floor and wall tile drawing |
| `hud.lua` | Damage numbers, FOV cone, player/enemy sight lines, HP bar, game over screen |
| `utils.lua` | `distance`, `normalize`, `clamp` |
| `conf.lua` | 1024×720 window |

## Controls
- **WASD** — Move
- **Mouse** — Aim (world position from cursor)
- **Left click** — Shoot (only if line of sight to cursor; no wall block)
- **R** — Restart after game over
- **Escape** — Quit

## Isometric Coordinates
- `Map.gridToScreen(gx, gy)` — grid cell to screen x,y (uses `Map.screenW`, `Map.screenH`, `Map.CAMERA_OFFSET_Y`)
- `Map.screenToGrid(sx, sy)` — screen to grid (for mouse aim)
- Call `Map.setScreenSize(w, h)` at start of each frame so conversions are correct

## Enemy Types
| Type | HP | Speed | View | Cooldown | Damage | Color |
|------|----|-------|------|----------|--------|-------|
| Grunt | 35 | 2.2 | 7 | 1.4s | 10 | Red |
| Scout | 22 | 3.2 | 9 | 1.8s | 6 | Green |
| Heavy | 65 | 1.4 | 6 | 0.9s | 18 | Dark red |
| Sniper | 30 | 1.6 | 12 | 2.2s | 25 | Purple |

## AI (Dummy)
- **Patrol:** Wander using sin/cos over time
- **Chase:** When player in `viewDist` and `Map.lineOfSight`, set state chase; move toward player; shoot when in range (7 tiles) and cooldown ready
- **Retreat:** When HP < 30% max, move away from player instead of toward
- **Alert decay:** After losing sight, chase toward `lastSeenX/Y` for 3s then return to patrol

## Bullets
- `Bullet.add(x, y, dx, dy, fromPlayer, damage)` — dx,dy can be unnormalized; damage optional (default 28 player, 12 enemy)
- Collision: in `main.lua` after `Bullet.update`, iterate bullets; player bullets vs enemies (radius 0.85), enemy bullets vs player (0.8); on hit apply damage, `HUD.addDamageNumber`, remove bullet

## Design Notes for Agents
- Map uses `Map.cells[iy][ix]` (row, col) = (y, x); spawn clears use `{ row, col }` pairs
- Draw order: sort entities by `x + y` so isometric depth is correct
- Sight lines and FOV use `Map.raycast` so they stop at walls
- No sprites or images; player and enemies are ellipses, bullets are circles

## How to Run
```bash
love tactical-shooter/
```
