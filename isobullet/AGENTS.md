# ISOBULLET — Agent Context

## Overview
An isometric bullet hell with bullet-time aiming and bullet reflection. Combines the isometric grid, walls, and visibility mechanics of a tactical shooter with bullet-hell patterns and chronobullet's time-manipulation system. Bullets bounce off walls. The player's hitscan beam reflects too — enabling ricochet shots around corners.

## Genre
Isometric bullet hell / tactical action with time manipulation and bullet reflection

## Architecture
- **14 Lua files**, ~2000 lines total, zero external dependencies
- Isometric 2D grid (24×18) with coordinate conversion (grid ↔ screen)
- Dual time scales: real-time (UI, camera, particles) and world-time (gameplay, bullet-time scaled)
- All gameplay in grid-space; rendering converts via `gridToScreen`
- No external assets — all rendering via `love.graphics` (polygons, circles, lines)

## Key Files
| File | Purpose |
|------|---------|
| `main.lua` | Game loop, mouse input state machine (normal → bullet-time → fire), collision, scoring |
| `map.lua` | Grid build, `gridToScreen`/`screenToGrid`, `isWall`, `lineOfSight`, `raycast`, `raycastWithNormal`, `reflectRaycast` |
| `player.lua` | WASD movement on iso grid, mouse aim, reflecting hitscan beam weapon, aim line preview |
| `enemy.lua` | 6 types (Turret, Spinner, Orbiter, Bouncer, Heavy, Dasher), LOS-aware firing, geometric shapes |
| `bullet.lua` | Enemy bullet pool with wall reflection (axis-separation), bounce counter, wall immunity timer |
| `bullettime.lua` | Time-scale manager: meter drain/recharge, smooth lerp, hitstop, activate/deactivate |
| `patterns.lua` | 7 bullet patterns: radial, aimed, spiral, expanding ring, shotgun, spin spiral, cross |
| `spawner.lua` | 7 hand-crafted waves + endless procedural mode with HP scaling |
| `particles.lua` | Beam trail renderer (multi-segment), burst effects, wall sparks, floating combo text |
| `background.lua` | Isometric floor tiles with 3D wall blocks (south-west/south-east depth faces) |
| `camera.lua` | Screen shake + zoom around center (no Y-compression; iso projection handles perspective) |
| `hud.lua` | Lives, score, wave, graze, bullet-time meter, sight line, damage numbers, crosshair |
| `utils.lua` | Math helpers: distance, normalize, reflect, pointToSegmentDist, sweep |
| `conf.lua` | 1024×720 window |

## Controls
- **WASD / Arrows** — Move on isometric grid
- **Left click** — Enter bullet-time (first click) → Fire reflecting beam (second click)
- **Right click** — Cancel bullet-time without firing
- **R** — Restart after game over
- **Escape** — Quit

## Core Mechanic: Reflecting Beam
1. Player left-clicks → `bullettime:activate()` sets `targetScale = 0.10`
2. World updates at 10% speed; player moves at 35% (responsive but slowed)
3. Color-coded dashed aim line shows full reflecting path:
   - Segment 0: Cyan (direct), Segment 1: Purple (1st bounce), Segment 2: Red, Segment 3: Orange
4. Beam width corridor preview drawn for first segment
5. Player left-clicks again → `player:fireBeam()` calls `Map.reflectRaycast()` for up to 3 bounces
6. Each segment checks `pointToSegmentDist` for every bullet and enemy within `BEAM_WIDTH` (0.5 grid units)
7. Bullets destroyed, enemies damaged, particles spawned at bounce points, score awarded
8. Ricochet bonus: +50 per segment if beam bounced and hit an enemy
9. `bullettime:deactivate()` lerps time back to 1.0

## Bullet Reflection Mechanic
- Each bullet has `maxBounces` (default 2, Bouncer enemy: 5) and `bounces` counter
- On wall hit: axis-separation determines which component to reflect
  - `isWall(newX, oldY)` → X hit → reflect `vx`
  - `isWall(oldX, newY)` → Y hit → reflect `vy`
  - Both → corner → reflect both
- Bullet reverts to pre-hit position with reflected velocity
- Visual: bullets dim with bounces (alpha -0.15/bounce), ring indicator on bounced bullets
- Spark particles emitted at each bounce point
- `wallImmuneTimer` (0.15s) prevents instant reflection on spawn

## Wall Normal Detection (Beam)
- `Map.raycastWithNormal()` steps along a ray at high resolution
- On wall entry, uses same axis-separation as bullet reflection to determine normal
- `Map.reflectRaycast()` chains raycasts with reflected directions, collecting segments
- Returns list of `{x1,y1, x2,y2}` segments for collision and rendering

## Bullet-Time Meter
- **Max**: 100, **Drain**: 28/sec while active, **Recharge**: 16/sec while inactive
- **Graze**: +1.5 per near-miss bullet
- **Kill**: +10 per enemy, +12 per beam hit, +1.5 per bullet destroyed
- **Empty**: forced deactivation with 0.6s cooldown lockout

## Scoring
- Enemy kills: per-type (200–500)
- Bullet destruction: 15 each
- Combo bonus: 5+ bullets = extra ×10 per bullet
- Graze: 20 points per near-miss
- Ricochet bonus: +50 per beam segment on ricochet kills

## Enemy Types
| Type | Shape | HP | Behaviour | LOS Required |
|------|-------|----|-----------|----|
| Turret | Diamond | 30 | Stationary, aimed 5-bullet bursts | Yes |
| Spinner | Circle | 50 | Drifts to position, 3-arm rotating spirals | No |
| Orbiter | Circle | 25 | Orbits a center point, 14-bullet radial bursts | No |
| **Bouncer** | Diamond | 40 | Drifts, fires 8-bullet rings with **5 bounces** | No |
| Heavy | Hexagon | 80 | Drifts slowly, alternates rings/shotgun/spirals | No |
| Dasher | Triangle | 20 | Dashes to random floor positions, aimed 7-bullet bursts | Yes |

## Map Layout
- 24×18 isometric grid, 48×24 pixel tiles, 1024×720 window
- Border walls + 4 interior pillars (columns 7 & 18, rows 5-7 & 11-13) + center bar (row 9, cols 11-14)
- Creates corridors, cover zones, and ricochet alleys
- Player starts at grid (12, 16); enemies spawn in upper half

## Isometric Coordinates
- `Map.gridToScreen(gx, gy)` — grid → screen pixel position
- `Map.screenToGrid(sx, sy)` — screen → grid (for mouse aim)
- Camera `screenToWorld` undoes shake+zoom before grid conversion
- Depth sorting by `(x + y)` for enemies and player; bullets drawn unsorted

## Design Notes for Agents
- **Two separate dt values**: `realDt` (UI/camera) and `worldDt` (gameplay)
- **Bullet physics in grid-space**: velocities in grid-units/sec (4-10 for patterns)
- **Beam is hitscan, not projectile**: `pointToSegmentDist()` checks each segment
- **Particles are screen-space** (converted from grid at spawn), except beam trails (grid-space, converted at draw)
- **Wall collision uses rounding**: `isWall` rounds to nearest integer → wall center ±0.5 grid units
- **Enemy LOS-gating**: Turrets and Dashers only fire aimed patterns when they see the player. Spinners, Orbiters, Bouncers, and Heavies always fire.
- **Bouncer is the signature enemy**: its 5-bounce bullets persist much longer, filling corridors with ricocheting projectiles
- **Map geometry IS level design**: pillars create cover (blocks aimed fire) AND danger (amplifies bouncing patterns)

## How to Run
```bash
love isobullet/
```
