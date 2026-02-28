# Module 4: Pathfinding — A* & Navigation

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 6-10 hours
**Prerequisites:** [Module 3: Steering Behaviors](module-03-steering-behaviors.md)

---

## Overview

Steering behaviors handle *how* an NPC moves — smoothly, organically, with natural momentum. Pathfinding handles *where* it should go. An NPC using Seek to chase the player is helpless when there's a wall between them — it just presses into the wall forever. Pathfinding algorithms find the route around obstacles, and A* (pronounced "A-star") is the workhorse that's been doing this job for decades.

A* is a graph search algorithm. You give it a start node, a goal node, and a graph of connections, and it finds the shortest path. The "graph" can be a grid (each cell connects to its neighbors), a waypoint network (hand-placed points connected by walkable edges), or a navigation mesh (polygons defining walkable areas). The algorithm itself doesn't care about the representation — it just needs nodes and edges.

The thing that makes understanding A* deeply worthwhile — beyond just plugging into an engine's built-in pathfinding — is that the same algorithmic thinking applies to many game AI problems. GOAP (Module 6) uses A* to search through action space. Influence maps (Module 8) use similar cost-based reasoning. Once you internalize graph search with heuristics, you have a mental tool that unlocks multiple later modules. Take the time to implement A* from scratch at least once.

---

## 1. The Problem: Graph Search

Pathfinding is a graph search problem. A **graph** is a set of **nodes** connected by **edges**. In a grid-based game, each walkable cell is a node, and edges connect adjacent cells. The question is: what's the cheapest path from node A to node B?

```
Grid as a graph:

  ┌───┬───┬───┬───┬───┐
  │ S │   │   │   │   │    S = Start
  ├───┼───┼───┼───┼───┤    G = Goal
  │   │ █ │ █ │   │   │    █ = Wall (no node)
  ├───┼───┼───┼───┼───┤
  │   │ █ │   │   │   │
  ├───┼───┼───┼───┼───┤
  │   │   │   │ █ │ G │
  └───┴───┴───┴───┴───┘
```

The naive approach — Breadth-First Search (BFS) — explores nodes in expanding rings from the start. It finds the shortest path, but it explores every direction equally, including directions leading away from the goal. On a large grid, this wastes enormous effort.

**Dijkstra's algorithm** improves on BFS by considering edge costs. Some edges are more expensive (mud, hills), and Dijkstra always expands the cheapest node first. It still explores in all directions, but it finds the cheapest path, not just the shortest.

**A*** improves on Dijkstra by adding a **heuristic** — an estimate of the remaining cost to reach the goal. This estimate guides the search toward the goal, dramatically reducing the number of nodes explored. A* explores in the direction of the goal first, only branching out when obstacles force it to.

```
BFS:              Dijkstra:          A*:
Explores          Explores           Explores toward
everywhere        by cost            the goal
equally                              (guided by heuristic)

  ○ ○ ○ ○          ○ ○ ○              ○
  ○ ○ ○ ○          ○ ○ ○              ○ ○
  ○ ○ ○ ○          ○ ○ ○ ○          ○ ○ ○
  ○ ○ ○ ○          ○ ○ ○ ○            ○ ○ G
  (many nodes)     (fewer nodes)     (fewest nodes)
```

---

## 2. A* — The Algorithm

A* maintains two data structures:

- **Open set** (priority queue): nodes that have been discovered but not yet fully evaluated. Sorted by f-cost (lowest first).
- **Closed set**: nodes that have been fully evaluated. We don't revisit these.

Each node tracks three costs:

- **g-cost**: the actual cost from the start to this node (known, accumulated along the path)
- **h-cost**: the heuristic estimate from this node to the goal (estimated, never exact)
- **f-cost**: g + h (the total estimated cost of the path through this node)

The algorithm:

```
1. Add start node to open set (g=0, h=heuristic(start, goal))
2. While open set is not empty:
   a. Pop the node with lowest f-cost from open set → call it "current"
   b. If current is the goal → reconstruct path, done!
   c. Add current to closed set
   d. For each neighbor of current:
      - If neighbor is in closed set → skip
      - Calculate tentative g-cost = current.g + cost(current, neighbor)
      - If neighbor is not in open set, or tentative g < neighbor.g:
        - Set neighbor.g = tentative g
        - Set neighbor.h = heuristic(neighbor, goal)
        - Set neighbor.f = g + h
        - Set neighbor.parent = current
        - Add neighbor to open set (or update its priority)
3. Open set is empty → no path exists
```

The path is reconstructed by following parent pointers from the goal back to the start.

---

## 3. Heuristics — The Secret Sauce

The heuristic function estimates the cost from a node to the goal without actually pathfinding. A* uses this estimate to prioritize which nodes to explore first. The choice of heuristic depends on how movement works in your game.

**Manhattan distance** (4-directional movement):
```
h = |current.x - goal.x| + |current.y - goal.y|
```

**Euclidean distance** (free movement or 8-directional):
```
h = sqrt((current.x - goal.x)² + (current.y - goal.y)²)
```

**Chebyshev distance** (8-directional, diagonal costs same as cardinal):
```
h = max(|current.x - goal.x|, |current.y - goal.y|)
```

**Octile distance** (8-directional, diagonal costs √2):
```
dx = |current.x - goal.x|
dy = |current.y - goal.y|
h = max(dx, dy) + (√2 - 1) * min(dx, dy)
```

**The admissibility rule:** For A* to guarantee the shortest path, the heuristic must never **overestimate** the actual cost. Manhattan distance works for 4-directional grids because you can't take a shortcut. Euclidean distance is admissible for any movement model because straight-line distance is always the minimum possible cost.

If you use a heuristic that overestimates, A* might find a path that isn't the shortest — but it will find one faster. This is called **weighted A*** and is a valid trade-off in games where "good enough" paths are fine and speed matters.

---

## 4. A* Implementation

Here's a complete A* implementation on a 2D grid:

```gdscript
# GDScript — A* on a grid
class_name AStarGrid

var width: int
var height: int
var grid: Array  # 2D array: 0 = walkable, 1+ = wall/cost

func _init(w: int, h: int) -> void:
    width = w
    height = h
    grid = []
    for y in range(h):
        var row = []
        for x in range(w):
            row.append(0)
        grid.append(row)

func set_wall(x: int, y: int) -> void:
    grid[y][x] = -1

func set_cost(x: int, y: int, cost: int) -> void:
    grid[y][x] = cost

func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
    var open_set = []  # [{pos, f, g, h, parent}]
    var closed = {}
    var g_costs = {}

    var start_h = _heuristic(start, goal)
    open_set.append({
        "pos": start, "f": start_h, "g": 0, "h": start_h, "parent": null
    })
    g_costs[start] = 0

    while open_set.size() > 0:
        # Find node with lowest f-cost
        open_set.sort_custom(func(a, b): return a.f < b.f)
        var current = open_set.pop_front()

        if current.pos == goal:
            return _reconstruct(current)

        closed[current.pos] = true

        for neighbor_pos in _get_neighbors(current.pos):
            if closed.has(neighbor_pos):
                continue
            if grid[neighbor_pos.y][neighbor_pos.x] == -1:
                continue  # wall

            var move_cost = 1 + max(0, grid[neighbor_pos.y][neighbor_pos.x])
            var tentative_g = current.g + move_cost

            if not g_costs.has(neighbor_pos) or tentative_g < g_costs[neighbor_pos]:
                g_costs[neighbor_pos] = tentative_g
                var h = _heuristic(neighbor_pos, goal)
                var node = {
                    "pos": neighbor_pos,
                    "f": tentative_g + h,
                    "g": tentative_g,
                    "h": h,
                    "parent": current,
                }
                open_set.append(node)

    return []  # no path found

func _heuristic(a: Vector2i, b: Vector2i) -> float:
    # Octile distance for 8-directional
    var dx = abs(a.x - b.x)
    var dy = abs(a.y - b.y)
    return max(dx, dy) + (1.414 - 1.0) * min(dx, dy)

func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
    var neighbors: Array[Vector2i] = []
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if dx == 0 and dy == 0:
                continue
            var nx = pos.x + dx
            var ny = pos.y + dy
            if nx >= 0 and nx < width and ny >= 0 and ny < height:
                neighbors.append(Vector2i(nx, ny))
    return neighbors

func _reconstruct(node) -> Array[Vector2i]:
    var path: Array[Vector2i] = []
    var current = node
    while current != null:
        path.push_front(current.pos)
        current = current.parent
    return path
```

```lua
-- Lua — A* on a grid
local AStar = {}

function AStar.new(width, height)
    local grid = {}
    for y = 1, height do
        grid[y] = {}
        for x = 1, width do
            grid[y][x] = 0  -- 0 = walkable, -1 = wall, >0 = extra cost
        end
    end
    return { width = width, height = height, grid = grid }
end

function AStar.find_path(map, sx, sy, gx, gy)
    local open = {}   -- priority queue (table sorted by f)
    local closed = {} -- "y,x" -> true
    local g_costs = {}

    local function key(x, y) return y .. "," .. x end
    local function heuristic(x1, y1, x2, y2)
        local dx, dy = math.abs(x1 - x2), math.abs(y1 - y2)
        return math.max(dx, dy) + (1.414 - 1) * math.min(dx, dy)
    end

    local start_h = heuristic(sx, sy, gx, gy)
    table.insert(open, {
        x = sx, y = sy,
        g = 0, h = start_h, f = start_h,
        parent = nil,
    })
    g_costs[key(sx, sy)] = 0

    while #open > 0 do
        -- Sort by f-cost (simple approach; use a heap for large grids)
        table.sort(open, function(a, b) return a.f < b.f end)
        local current = table.remove(open, 1)

        if current.x == gx and current.y == gy then
            -- Reconstruct path
            local path = {}
            local node = current
            while node do
                table.insert(path, 1, {node.x, node.y})
                node = node.parent
            end
            return path
        end

        closed[key(current.x, current.y)] = true

        -- Check all 8 neighbors
        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx == 0 and dy == 0) then
                    local nx, ny = current.x + dx, current.y + dy
                    local nkey = key(nx, ny)

                    if nx >= 1 and nx <= map.width and
                       ny >= 1 and ny <= map.height and
                       not closed[nkey] and
                       map.grid[ny][nx] ~= -1 then

                        local move_cost = 1 + math.max(0, map.grid[ny][nx])
                        if dx ~= 0 and dy ~= 0 then
                            move_cost = move_cost * 1.414  -- diagonal
                        end
                        local tentative_g = current.g + move_cost

                        if not g_costs[nkey] or tentative_g < g_costs[nkey] then
                            g_costs[nkey] = tentative_g
                            local h = heuristic(nx, ny, gx, gy)
                            table.insert(open, {
                                x = nx, y = ny,
                                g = tentative_g, h = h, f = tentative_g + h,
                                parent = current,
                            })
                        end
                    end
                end
            end
        end
    end

    return nil  -- no path found
end
```

---

## 5. Terrain Costs — Making Pathfinding Tactical

Uniform-cost grids produce shortest paths, but games are more interesting when different terrain has different costs. Mud slows you down. Roads speed you up. Lava hurts. Water requires swimming.

With terrain costs, A* doesn't just find the shortest path — it finds the *cheapest* path. The NPC will walk around a mud patch if the longer road route is faster overall, but will cut through mud if the detour is too long.

```
Cost grid:
┌───┬───┬───┬───┬───┐
│ 1 │ 1 │ 3 │ 3 │ 1 │   1 = normal ground
├───┼───┼───┼───┼───┤   3 = mud (3x slower)
│ 1 │ 1 │ 3 │ 3 │ 1 │   █ = wall
├───┼───┼───┼───┼───┤
│ 1 │ 1 │ 1 │ 1 │ 1 │
├───┼───┼───┼───┼───┤
│ 1 │ 1 │ 1 │ 1 │ 1 │
└───┴───┴───┴───┴───┘

Shortest path goes through mud (4 cells).
Cheapest path goes around mud (6 cells but cost 6 vs. cost 10).
```

Implementation is trivial — just change the edge cost calculation:

```lua
-- Instead of: local move_cost = 1
-- Use:        local move_cost = 1 + map.grid[ny][nx]
-- Where grid values represent extra cost (0 = normal, 2 = mud adds 2)
```

Terrain costs also enable **tactical AI**. An NPC that avoids open areas (high "exposure cost") and prefers cover (low cost) will naturally take cover-based paths without any explicit cover logic. This is a powerful technique — encoding tactical preference into the pathfinding cost function.

---

## 6. Path Smoothing

Raw A* paths on a grid are jagged — they follow grid edges, creating staircase patterns on diagonals and unnecessary waypoints along straight sections. Path smoothing removes redundant waypoints and creates more natural-looking routes.

The simplest smoothing technique is **line-of-sight pruning**: walk along the path and check line-of-sight from each waypoint to subsequent waypoints. If you can see waypoint N+2 from waypoint N, remove waypoint N+1. Repeat until no more waypoints can be removed.

```
Before smoothing:        After smoothing:
S → · → · → ·           S ─────────── ·
              ↓                         ↘
              ·                          ·
              ↓                          ↓
              · → · → G                  · ────── G
```

```lua
-- Lua — Simple path smoothing via line-of-sight pruning
function smooth_path(path, map)
    if #path <= 2 then return path end

    local smoothed = { path[1] }
    local current = 1

    while current < #path do
        local farthest = current + 1
        -- Look ahead as far as possible with clear line of sight
        for i = current + 2, #path do
            if has_line_of_sight(map, path[current], path[i]) then
                farthest = i
            end
        end
        table.insert(smoothed, path[farthest])
        current = farthest
    end

    return smoothed
end

function has_line_of_sight(map, from, to)
    -- Bresenham's line algorithm to check for walls
    local x0, y0 = from[1], from[2]
    local x1, y1 = to[1], to[2]
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy

    while true do
        if map.grid[y0] and map.grid[y0][x0] == -1 then
            return false  -- wall in the way
        end
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then err = err - dy; x0 = x0 + sx end
        if e2 < dx then err = err + dx; y0 = y0 + sy end
    end
    return true
end
```

---

## 7. Navigation Meshes

Grids work for tile-based games, but they're inefficient for open environments. A room that's 100x100 tiles has 10,000 nodes, most of which are in open space where pathfinding is trivial. Navigation meshes (navmeshes) represent walkable areas as **convex polygons**, dramatically reducing the node count.

```
Grid: 10,000 nodes          Navmesh: ~15 polygons
┌──────────────────┐        ┌──────────────────┐
│░░░░░░░░░░░░░░░░░░│        │   A       B      │
│░░░░░░░░░░░░░░░░░░│        │     ┌──┐         │
│░░░░░░██░░░░░░░░░░│        │  C  │██│   D     │
│░░░░░░██░░░░░░░░░░│        │     └──┘         │
│░░░░░░░░░░░░░░░░░░│        │   E       F      │
└──────────────────┘        └──────────────────┘
```

In a navmesh, A* runs on the polygon graph (each polygon is a node, edges connect adjacent polygons). The path is a sequence of polygons, and the actual movement path is computed by the **funnel algorithm** — finding the shortest path through the sequence of polygon edges.

Godot has built-in NavigationServer with navmesh support. You define navigation regions, and the engine generates the navmesh and handles pathfinding queries:

```gdscript
# GDScript — Using Godot's built-in NavigationServer
extends CharacterBody2D

@export var speed := 150.0
var path: PackedVector2Array = []
var path_index := 0

func navigate_to(target: Vector2) -> void:
    path = NavigationServer2D.map_get_path(
        get_world_2d().navigation_map,
        global_position,
        target,
        true  # optimize path
    )
    path_index = 0

func _process(delta: float) -> void:
    if path_index >= path.size():
        return

    var target = path[path_index]
    var to_target = target - global_position

    if to_target.length() < 5.0:
        path_index += 1
    else:
        velocity = to_target.normalized() * speed
        move_and_slide()
```

In LÖVE, you'll implement navmesh pathfinding yourself or use a library. For many 2D games, a grid-based A* is perfectly sufficient — navmeshes are most valuable for open environments with irregular obstacle shapes.

---

## 8. Flow Fields

A* finds a path for one agent. But what if you have 200 agents all pathfinding to the same destination? Running A* 200 times per frame is expensive. **Flow fields** solve this by computing a single vector field that all agents can sample.

A flow field is a grid where each cell stores a direction vector pointing toward the goal. Agents simply read the vector at their current cell and steer in that direction. The field is computed once (or updated periodically) and shared by all agents.

Computing a flow field:
1. Run a Dijkstra-like expansion from the goal outward, computing the cost to reach the goal for every cell
2. For each cell, look at its neighbors and point toward the neighbor with the lowest cost

```
Cost field:              Flow field (arrows point toward goal):
┌───┬───┬───┬───┐       ┌───┬───┬───┬───┐
│ 6 │ 5 │ 4 │ 3 │       │ → │ → │ → │ ↓ │
├───┼───┼───┼───┤       ├───┼───┼───┼───┤
│ 5 │ █ │ █ │ 2 │       │ ↓ │ █ │ █ │ ↓ │
├───┼───┼───┼───┤       ├───┼───┼───┼───┤
│ 4 │ 3 │ 2 │ 1 │       │ → │ → │ → │ ↓ │
├───┼───┼───┼───┤       ├───┼───┼───┼───┤
│ 5 │ 4 │ 3 │ G │       │ → │ → │ → │ G │
└───┴───┴───┴───┘       └───┴───┴───┴───┘
```

```lua
-- Lua — Flow field generation
function generate_flow_field(map, goal_x, goal_y)
    local cost = {}
    for y = 1, map.height do
        cost[y] = {}
        for x = 1, map.width do
            cost[y][x] = math.huge
        end
    end

    -- Dijkstra from goal
    cost[goal_y][goal_x] = 0
    local open = {{goal_x, goal_y}}

    while #open > 0 do
        local current = table.remove(open, 1)
        local cx, cy = current[1], current[2]
        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx == 0 and dy == 0) then
                    local nx, ny = cx + dx, cy + dy
                    if nx >= 1 and nx <= map.width and
                       ny >= 1 and ny <= map.height and
                       map.grid[ny][nx] ~= -1 then
                        local move = 1 + math.max(0, map.grid[ny][nx])
                        local new_cost = cost[cy][cx] + move
                        if new_cost < cost[ny][nx] then
                            cost[ny][nx] = new_cost
                            table.insert(open, {nx, ny})
                        end
                    end
                end
            end
        end
    end

    -- Generate direction vectors
    local flow = {}
    for y = 1, map.height do
        flow[y] = {}
        for x = 1, map.width do
            local best_dx, best_dy = 0, 0
            local best_cost = cost[y][x]
            for dx = -1, 1 do
                for dy = -1, 1 do
                    local nx, ny = x + dx, y + dy
                    if nx >= 1 and nx <= map.width and
                       ny >= 1 and ny <= map.height and
                       cost[ny][nx] < best_cost then
                        best_cost = cost[ny][nx]
                        best_dx, best_dy = dx, dy
                    end
                end
            end
            flow[y][x] = {best_dx, best_dy}
        end
    end

    return flow
end
```

Flow fields are ideal for RTS games (hundreds of units moving to a rally point), tower defense (enemies streaming toward the base), and zombie hordes. The one-time computation cost is high, but the per-agent cost is trivial — just a table lookup.

---

## 9. Combining Pathfinding with Steering

In production, pathfinding and steering work together. A* (or a flow field) gives you the high-level route — a sequence of waypoints. Steering behaviors handle the low-level movement — smooth turns, obstacle avoidance, arrival deceleration.

The pattern:
1. Compute path using A* (waypoints)
2. Set the first waypoint as the steering target
3. Use Arrive to steer toward the current waypoint
4. When within threshold distance, advance to the next waypoint
5. Blend in Obstacle Avoidance for dynamic obstacles (objects that weren't in the pathfinding grid)

```gdscript
# GDScript — Pathfinding + Steering integration
var path: Array[Vector2] = []
var path_index := 0
var waypoint_threshold := 15.0

func _process(delta: float) -> void:
    if path_index >= path.size():
        return  # No path or reached destination

    var target = path[path_index]
    var dist = global_position.distance_to(target)

    # Advance to next waypoint
    if dist < waypoint_threshold:
        path_index += 1
        if path_index >= path.size():
            velocity = Vector2.ZERO
            return

    # Use Arrive for last waypoint, Seek for intermediate ones
    var desired: Vector2
    if path_index == path.size() - 1:
        desired = arrive(path[path_index])
    else:
        desired = seek(path[path_index])

    # Blend with obstacle avoidance
    var avoid = obstacle_avoidance()
    desired = desired + avoid * 1.5

    apply_steering(desired, delta)
```

This integration is what separates demo-quality AI from production-quality AI. The pathfinding ensures the NPC navigates complex environments. The steering ensures it moves naturally while doing so.

---

## Code Walkthrough: Interactive A* Visualizer

Let's build a visual A* demo where you can place walls, set start/goal, and watch the algorithm explore.

```lua
-- Lua (LÖVE) — A* Visualizer
local CELL = 24
local COLS, ROWS = 30, 22
local grid = {}
local path = nil
local start_x, start_y = 2, 2
local goal_x, goal_y = 28, 20
local explored = {}  -- cells A* visited (for visualization)

function love.load()
    love.window.setMode(COLS * CELL, ROWS * CELL)
    for y = 1, ROWS do
        grid[y] = {}
        for x = 1, COLS do
            grid[y][x] = 0
        end
    end
    recalculate()
end

function recalculate()
    explored = {}
    local map = { width = COLS, height = ROWS, grid = grid }
    path = astar_visual(map, start_x, start_y, goal_x, goal_y)
end

function astar_visual(map, sx, sy, gx, gy)
    -- A* with exploration tracking
    local open = {}
    local closed = {}
    local g_costs = {}

    local function key(x, y) return y * 1000 + x end
    local function h(x1, y1, x2, y2)
        local dx, dy = math.abs(x1-x2), math.abs(y1-y2)
        return math.max(dx, dy) + (1.414-1)*math.min(dx, dy)
    end

    local sh = h(sx,sy,gx,gy)
    table.insert(open, {x=sx,y=sy,g=0,h=sh,f=sh,parent=nil})
    g_costs[key(sx,sy)] = 0

    while #open > 0 do
        table.sort(open, function(a,b) return a.f < b.f end)
        local cur = table.remove(open, 1)
        table.insert(explored, {cur.x, cur.y})

        if cur.x == gx and cur.y == gy then
            local p = {}
            local n = cur
            while n do
                table.insert(p, 1, {n.x, n.y})
                n = n.parent
            end
            return p
        end

        closed[key(cur.x, cur.y)] = true

        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx==0 and dy==0) then
                    local nx, ny = cur.x+dx, cur.y+dy
                    local nk = key(nx, ny)
                    if nx>=1 and nx<=map.width and ny>=1 and ny<=map.height
                       and not closed[nk] and map.grid[ny][nx] ~= -1 then
                        local mc = 1 + math.max(0, map.grid[ny][nx])
                        if dx~=0 and dy~=0 then mc = mc * 1.414 end
                        local tg = cur.g + mc
                        if not g_costs[nk] or tg < g_costs[nk] then
                            g_costs[nk] = tg
                            local nh = h(nx,ny,gx,gy)
                            table.insert(open, {
                                x=nx,y=ny,g=tg,h=nh,f=tg+nh,parent=cur
                            })
                        end
                    end
                end
            end
        end
    end
    return nil
end

function love.mousepressed(x, y, button)
    local gx = math.floor(x / CELL) + 1
    local gy = math.floor(y / CELL) + 1
    if gx >= 1 and gx <= COLS and gy >= 1 and gy <= ROWS then
        if button == 1 then
            grid[gy][gx] = grid[gy][gx] == -1 and 0 or -1
        elseif button == 2 then
            goal_x, goal_y = gx, gy
        end
        recalculate()
    end
end

function love.keypressed(key)
    if key == "c" then
        for y = 1, ROWS do
            for x = 1, COLS do grid[y][x] = 0 end
        end
        recalculate()
    end
end

function love.draw()
    -- Draw explored cells
    love.graphics.setColor(0.15, 0.25, 0.35)
    for _, cell in ipairs(explored) do
        love.graphics.rectangle("fill",
            (cell[1]-1)*CELL+1, (cell[2]-1)*CELL+1, CELL-2, CELL-2)
    end

    -- Draw walls
    love.graphics.setColor(0.4, 0.4, 0.4)
    for y = 1, ROWS do
        for x = 1, COLS do
            if grid[y][x] == -1 then
                love.graphics.rectangle("fill",
                    (x-1)*CELL, (y-1)*CELL, CELL, CELL)
            end
        end
    end

    -- Draw path
    if path then
        love.graphics.setColor(0.2, 0.8, 0.2)
        for _, p in ipairs(path) do
            love.graphics.rectangle("fill",
                (p[1]-1)*CELL+4, (p[2]-1)*CELL+4, CELL-8, CELL-8)
        end
    end

    -- Draw start and goal
    love.graphics.setColor(0, 0.5, 1)
    love.graphics.rectangle("fill",
        (start_x-1)*CELL+2, (start_y-1)*CELL+2, CELL-4, CELL-4)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.rectangle("fill",
        (goal_x-1)*CELL+2, (goal_y-1)*CELL+2, CELL-4, CELL-4)

    -- Instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Left-click: toggle wall | Right-click: set goal | C: clear", 4, 2)
end
```

---

## Common Pitfalls

### 1. Using a list instead of a priority queue for the open set

Sorting a list every iteration is O(n log n). For small grids this is fine. For large grids (100x100+), use a proper binary heap for the open set. The performance difference is dramatic — O(log n) insertion and extraction vs O(n log n) sorting.

### 2. Not checking if a path exists before following it

A* returns `nil` (or an empty array) when no path exists. If you blindly start following the path without checking, you get a nil reference crash. Always handle the "no path" case — the NPC should do something sensible (wait, wander, try a different goal).

### 3. Recomputing the path every frame

A* is expensive. Don't run it every frame unless the world is constantly changing. Compute the path once, follow it, and only recompute when the goal moves significantly or the NPC's path is blocked by a new obstacle.

### 4. Forgetting diagonal costs

On a grid with 8-directional movement, diagonal moves should cost √2 ≈ 1.414 times the cardinal cost. If diagonals cost the same as cardinals, the algorithm produces paths that prefer diagonals (because they're "free distance"), leading to zigzag paths that look wrong.

### 5. Path following without steering

You get the A* path (a list of grid positions) and teleport the NPC between them. This looks robotic. Feed the waypoints to a steering behavior (Seek or Arrive) for smooth, natural movement along the path.

### 6. Grid resolution mismatch

The pathfinding grid has 32-pixel cells but the NPC is 20 pixels wide and clips through diagonal wall corners. Ensure the grid resolution accounts for agent size — either use smaller cells or add corner-cutting prevention (don't allow diagonal movement through two adjacent walls).

---

## Exercises

### Exercise 1: Interactive A* Grid
**Time:** 2-3 hours

Build the A* visualizer from the code walkthrough with these additions:

1. Click to place/remove walls
2. Right-click to move the goal
3. Shift-click to place "mud" tiles (cost 3x)
4. Show the explored cells in a lighter color to visualize how A* searches
5. Display the path cost on screen

Watch how the path changes when you add mud — does it go around or through?

**Concepts practiced:** A* implementation, heuristics, terrain costs, algorithm visualization

**Stretch goal:** Add a toggle between Manhattan and Euclidean heuristics. Observe how the explored area changes — Manhattan explores in a diamond pattern, Euclidean in a circle.

---

### Exercise 2: Pathfinding + Steering Integration
**Time:** 2-3 hours

Combine A* from this module with steering from Module 3:

1. Click to set a destination
2. A* computes the path
3. An NPC follows the path using Arrive (for the final waypoint) and Seek (for intermediate waypoints)
4. Add Obstacle Avoidance for dynamic obstacles (circles you can drag around)
5. When a dynamic obstacle blocks the path, recompute A*

**Concepts practiced:** Pathfinding-steering integration, dynamic replanning, practical AI architecture

**Stretch goal:** Add 5 NPCs that all pathfind to the same goal but use local avoidance (Separation) to avoid clumping at waypoints.

---

### Exercise 3: Flow Field for a Tower Defense
**Time:** 2-3 hours

Build a simple tower defense layout with a flow field:

1. A grid with a goal (base) at one end and spawn points at the other
2. Compute a flow field from all cells toward the goal
3. Spawn 50 enemies that follow the flow field using steering
4. Allow placing walls (towers) that recompute the flow field
5. Visualize the flow field as arrows in each cell

**Concepts practiced:** Flow field computation, Dijkstra expansion, efficient multi-agent pathfinding

**Stretch goal:** Add terrain costs to the flow field so enemies prefer roads but will walk through mud if the road is blocked.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| Red Blob Games "Introduction to A*" | Interactive article | The single best A* tutorial on the internet — interactive diagrams you can play with |
| Red Blob Games "Implementation of A*" | Interactive article | Companion to the above with clean, practical code in Python (easy to port) |
| "Navigation Mesh Generation" from *Game AI Pro* | Book chapter (free) | Production navmesh construction and query |
| Red Blob Games on hex grids | Interactive article | Essential if your game uses hex or grid-based maps |
| *Programming Game AI by Example* by Mat Buckland, Ch. 5 | Book | Complete A* treatment with graph search foundations |

---

## Key Takeaways

1. **A* = Dijkstra + heuristic.** The heuristic guides the search toward the goal, making it dramatically faster than brute-force search. Choose the right heuristic for your movement model.

2. **Terrain costs make pathfinding tactical.** Different tile costs cause NPCs to prefer roads, avoid danger zones, and make routing decisions that feel intelligent. Encoding tactical preference into cost is powerful.

3. **Path smoothing is not optional for visual quality.** Raw A* grid paths are jagged. Line-of-sight pruning removes unnecessary waypoints and makes movement look natural.

4. **Pathfinding + steering = production-quality movement.** A* handles the route. Steering handles the motion. Use Seek for intermediate waypoints, Arrive for the final one, and Obstacle Avoidance for dynamic obstacles.

5. **Flow fields scale to many agents.** When many agents pathfind to the same goal, compute one flow field and let all agents sample it. One-time cost, O(1) per agent.

6. **Implement A* from scratch at least once.** Even if you use an engine's built-in pathfinding, understanding the algorithm makes you better at debugging pathfinding issues, tuning heuristics, and recognizing when A* isn't the right tool.

---

## What's Next?

You now have the complete movement stack: steering behaviors for natural motion, and A* for intelligent routing. Your NPCs can navigate complex environments with fluid, believable movement.

The next two modules tackle a different problem: **decision making**. In [Module 5: Decision Making — Utility AI](module-05-utility-ai.md), you'll learn how to replace binary yes/no conditions with scored evaluations. Instead of "is the player visible? Then chase," your NPC will ask "how hungry am I? How dangerous is it? How close is the food?" and pick the best action based on continuous values. This creates NPCs with emergent personality — same code, different curves, different "character."

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
