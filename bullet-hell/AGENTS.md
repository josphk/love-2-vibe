# Bullet Hell — Agent Context

## Overview
A classic vertical-scrolling bullet hell shooter built with LÖVE2D and Lua. The player controls a ship at the bottom of the screen, dodging dense enemy bullet patterns and firing back. Inspired by Touhou Project and Ikaruga.

## Genre
Vertical bullet hell / shoot-'em-up (shmup)

## Architecture
- **12 Lua files**, ~1900 lines total, zero external dependencies
- Modular design: each file is a self-contained system loaded via `require()`
- `main.lua` orchestrates the game loop and wires all systems together

## Key Files
| File | Purpose |
|---|---|
| `main.lua` | Game loop: load → update → draw, collision detection, state management |
| `player.lua` | Ship movement (WASD/arrows), 4-power-level shooting, lives, invulnerability, focus mode |
| `enemy.lua` | 5 enemy types (Drone, Spinner, Turret, Weaver, Heavy) with pixel-art Space Invaders sprites |
| `bullet.lua` | Bullet pool for both enemy and player projectiles, glow rendering |
| `patterns.lua` | 8 bullet pattern generators: radial, aimed, spiral, wave, expanding ring, cross, spinning spiral, shotgun |
| `spawner.lua` | 5 hand-crafted waves + endless procedural mode with scaling difficulty |
| `sprites.lua` | Runtime pixel-art sprite generation using `ImageData` — two animation frames per enemy |
| `particles.lua` | Lightweight explosion and spark effects |
| `background.lua` | 3-layer parallax starfield |
| `hud.lua` | Score, lives, bombs, wave indicator, power level, graze counter |
| `utils.lua` | Distance, angle, clamp, circle collision, array sweep |
| `conf.lua` | 480×720 portrait window |

## Controls
- **Arrow keys / WASD** — Move
- **Space / Z** — Shoot
- **Left Shift** — Focus mode (slow movement, visible hitbox)
- **X** — Bomb (clears all enemy bullets)
- **R** — Restart after game over

## Core Mechanics
- **Tiny hitbox** (3px radius) — classic bullet hell convention
- **Graze system** — near misses award bonus score
- **4 power levels** widening the shot spread, dropped by enemies
- **Bomb system** — screen-clearing panic button with limited uses
- **Focus mode** — halves movement speed, reveals the precise hitbox

## Enemy Types
| Type | Behaviour | HP |
|---|---|---|
| Drone | Drifts down, fires aimed bursts | 8 |
| Spinner | Hovers, fires rotating 4-arm spirals | 20 |
| Turret | Stationary, alternates radial bursts and crosses | 35 |
| Weaver | Fast zigzag, fires sinusoidal wave bullets | 12 |
| Heavy | Slow, fires expanding rings + shotgun + spinning spirals | 60 |

## How to Run
```bash
love bullet-hell/
```

## Design Notes for Agents
- All sprites are generated at runtime via `love.image.newImageData()` — no `.png` files needed
- Bullet patterns are composable: each pattern function takes a bullet pool and spawns into it
- The spawner has a clear wave definition format — easy to add new waves
- Difficulty in endless mode scales linearly: `difficulty = 1 + (wave - 5) * 0.15`
- The game runs in a fixed 480×720 portrait window (classic shmup aspect ratio)
