# Module 8: Group & Crowd Behavior

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 6-10 hours
**Prerequisites:** [Module 3: Steering Behaviors](module-03-steering-behaviors.md), [Module 4: Pathfinding](module-04-pathfinding-astar-navigation.md)

---

## Overview

A single smart NPC is impressive. A group of NPCs that coordinate is a different challenge entirely. Running the same individual AI for each NPC in a group produces a mob of individuals, not a squad. They all chase the player from the same direction, cluster on the same tile, and block each other in doorways. True group behavior requires NPCs to share information, assign roles, and act as a unit.

This module covers three levels of group AI: **formations** (NPCs maintaining spatial relationships), **squad tactics** (NPCs coordinating roles and objectives), and **influence maps** (spatial data that guides group decision-making). These are the techniques that make F.E.A.R.'s soldiers flank you, that make RTS units move in formation, and that make zombie hordes stream intelligently around obstacles.

The foundation is Module 3's steering behaviors and Module 4's pathfinding. Formation movement is Arrive with offset targets. Squad coordination uses pathfinding for positioning. Influence maps are spatial reasoning tools that inform both. This module adds the *coordination layer* on top of tools you already have.

---

## 1. Formations — Moving as a Unit

A formation is a set of **slots** — offset positions relative to a leader or formation center. Each NPC is assigned a slot and uses Arrive (from Module 3) to maintain its position. When the leader moves, all slots move. The result is a group that travels together while maintaining spatial structure.

```
V-Formation:           Line Formation:         Circle Formation:
      L                  1  2  L  3  4             1
     / \                                        4     2
    1   2                                          L
   / \                                          3     5
  3   4                                            6
```

```lua
-- Lua — Formation system
local Formation = {}
Formation.__index = Formation

function Formation.new(shape)
    local offsets = {}
    if shape == "v" then
        offsets = {
            {-30, 30}, {30, 30},
            {-60, 60}, {60, 60},
        }
    elseif shape == "line" then
        offsets = {
            {-60, 0}, {-30, 0}, {30, 0}, {60, 0},
        }
    elseif shape == "circle" then
        local count = 6
        for i = 1, count do
            local angle = (i - 1) * (2 * math.pi / count)
            table.insert(offsets, {
                math.cos(angle) * 40,
                math.sin(angle) * 40,
            })
        end
    end

    return setmetatable({
        offsets = offsets,
        members = {},      -- NPCs assigned to slots
        leader = nil,
        center_x = 0, center_y = 0,
        facing = 0,        -- formation heading
    }, Formation)
end

function Formation:assign(npcs, leader)
    self.leader = leader
    self.members = {}
    for i, npc in ipairs(npcs) do
        if i <= #self.offsets then
            self.members[i] = npc
        end
    end
end

function Formation:update(dt)
    if not self.leader then return end

    self.center_x = self.leader.x
    self.center_y = self.leader.y
    self.facing = self.leader.facing or 0

    for i, npc in ipairs(self.members) do
        local offset = self.offsets[i]
        if offset then
            -- Rotate offset by formation heading
            local cos_f = math.cos(self.facing)
            local sin_f = math.sin(self.facing)
            local target_x = self.center_x + offset[1] * cos_f - offset[2] * sin_f
            local target_y = self.center_y + offset[1] * sin_f + offset[2] * cos_f

            -- Use Arrive steering to reach slot position
            npc.target_x = target_x
            npc.target_y = target_y
            arrive_toward(npc, target_x, target_y, npc.speed, dt)
        end
    end
end

-- Handle gap-closing when a member is removed
function Formation:remove_member(npc)
    for i, member in ipairs(self.members) do
        if member == npc then
            table.remove(self.members, i)
            -- Remaining members shift up to fill the gap
            break
        end
    end
end
```

```gdscript
# GDScript — Formation slot calculation
class_name Formation

var offsets: Array[Vector2] = []
var members: Array[Node2D] = []
var leader: Node2D = null

func _init(shape: String) -> void:
    if shape == "v":
        offsets = [Vector2(-30, 30), Vector2(30, 30),
                   Vector2(-60, 60), Vector2(60, 60)]
    elif shape == "line":
        offsets = [Vector2(-60, 0), Vector2(-30, 0),
                   Vector2(30, 0), Vector2(60, 0)]

func get_slot_position(index: int) -> Vector2:
    if not leader or index >= offsets.size():
        return Vector2.ZERO
    var offset = offsets[index].rotated(leader.rotation)
    return leader.global_position + offset
```

**Slot assignment matters.** The simplest approach assigns slots by index order, but smarter assignment minimizes the total distance each NPC needs to travel. If an NPC dies and a slot opens, the nearest NPC should shift into the gap rather than all NPCs shuffling positions.

---

## 2. Leader-Follower Patterns

In a leader-follower setup, one NPC handles the "thinking" — pathfinding, threat assessment, objective selection — while followers maintain formation around the leader. This dramatically reduces the AI cost for groups because only one NPC needs full decision-making.

```
Leader:
  - Runs full AI (pathfinding, perception, decision making)
  - Picks destinations, evaluates threats
  - Commands followers via formation or direct orders

Followers:
  - Maintain formation offset from leader
  - React to immediate threats (if attacked, fight back)
  - Execute orders from leader (hold position, advance, retreat)
```

```lua
-- Lua — Leader-follower with orders
local Squad = {}

function Squad.new(leader, followers)
    return {
        leader = leader,
        followers = followers,
        formation = Formation.new("v"),
        current_order = "follow",  -- "follow", "hold", "advance", "retreat"
    }
end

function Squad:update(dt)
    -- Leader makes decisions
    update_leader_ai(self.leader, dt)

    -- Followers execute based on current order
    if self.current_order == "follow" then
        self.formation:assign(self.followers, self.leader)
        self.formation:update(dt)
    elseif self.current_order == "hold" then
        -- Followers stay at current position
        for _, f in ipairs(self.followers) do
            f.target_x = f.x
            f.target_y = f.y
        end
    elseif self.current_order == "advance" then
        -- Followers move toward objective independently
        for _, f in ipairs(self.followers) do
            arrive_toward(f, self.leader.objective_x, self.leader.objective_y,
                f.speed, dt)
        end
    end
end

function Squad:issue_order(order)
    self.current_order = order
end
```

---

## 3. Influence Maps — Spatial Reasoning

An influence map is a grid overlaid on the level where each cell stores one or more numeric values representing things like danger, visibility, territory, or tactical advantage. NPCs query the influence map to make spatially informed decisions.

```
Danger Influence Map:
┌───┬───┬───┬───┬───┐
│ 0 │ 0 │ 2 │ 5 │ 8 │   Values represent danger level.
├───┼───┼───┼───┼───┤   8 = player's position (max danger).
│ 0 │ 1 │ 3 │ 5 │ 7 │   Danger radiates outward.
├───┼───┼───┼───┼───┤   NPCs prefer low-danger cells.
│ 0 │ 0 │ 2 │ 3 │ 5 │
├───┼───┼───┼───┼───┤
│ 0 │ 0 │ 1 │ 2 │ 3 │
└───┴───┴───┴───┴───┘
```

```lua
-- Lua — Influence map
local InfluenceMap = {}

function InfluenceMap.new(width, height, cell_size)
    local cols = math.ceil(width / cell_size)
    local rows = math.ceil(height / cell_size)
    local grid = {}
    for y = 1, rows do
        grid[y] = {}
        for x = 1, cols do
            grid[y][x] = 0
        end
    end
    return {
        grid = grid, cols = cols, rows = rows,
        cell_size = cell_size,
    }
end

function InfluenceMap.clear(map)
    for y = 1, map.rows do
        for x = 1, map.cols do
            map.grid[y][x] = 0
        end
    end
end

function InfluenceMap.add_influence(map, world_x, world_y, radius, strength)
    local cx = math.floor(world_x / map.cell_size) + 1
    local cy = math.floor(world_y / map.cell_size) + 1
    local cell_radius = math.ceil(radius / map.cell_size)

    for dy = -cell_radius, cell_radius do
        for dx = -cell_radius, cell_radius do
            local gx, gy = cx + dx, cy + dy
            if gx >= 1 and gx <= map.cols and gy >= 1 and gy <= map.rows then
                local dist = math.sqrt(dx * dx + dy * dy) * map.cell_size
                if dist < radius then
                    local falloff = 1 - (dist / radius)
                    map.grid[gy][gx] = map.grid[gy][gx] + strength * falloff
                end
            end
        end
    end
end

function InfluenceMap.get_value(map, world_x, world_y)
    local cx = math.floor(world_x / map.cell_size) + 1
    local cy = math.floor(world_y / map.cell_size) + 1
    if cx >= 1 and cx <= map.cols and cy >= 1 and cy <= map.rows then
        return map.grid[cy][cx]
    end
    return 0
end

-- Find the cell with the best score (lowest danger, for example)
function InfluenceMap.find_best_cell(map, prefer_low)
    local best_x, best_y = 1, 1
    local best_val = prefer_low and math.huge or -math.huge
    for y = 1, map.rows do
        for x = 1, map.cols do
            local v = map.grid[y][x]
            if prefer_low and v < best_val then
                best_val = v; best_x = x; best_y = y
            elseif not prefer_low and v > best_val then
                best_val = v; best_x = x; best_y = y
            end
        end
    end
    return (best_x - 0.5) * map.cell_size, (best_y - 0.5) * map.cell_size
end
```

Common influence map layers:

| Layer | Source | Use |
|-------|--------|-----|
| **Danger** | Player position, projectiles, traps | NPCs avoid high-danger cells |
| **Cover** | Static geometry analysis | NPCs prefer cells with cover value |
| **Visibility** | Raycast from player position | NPCs prefer cells the player can't see |
| **Territory** | NPC positions, patrol routes | Determine which areas are "controlled" |
| **Tactical** | Combined: cover + low danger + LOS to target | Find optimal combat positions |

---

## 4. Squad Tactics — Coordinated Combat

Squad tactics go beyond formations. A tactical AI needs to answer: who flanks? Who provides cover fire? Who retreats to heal? This is managed by a **squad coordinator** — a meta-AI that doesn't control any individual NPC directly but assigns roles and objectives.

```lua
-- Lua — Squad coordinator
local Coordinator = {}

function Coordinator.new(squad_members)
    return {
        members = squad_members,
        roles = {},  -- npc -> role
        target = nil,
    }
end

function Coordinator:assign_roles(target, influence_map)
    self.target = target
    local sorted = {}
    for _, npc in ipairs(self.members) do
        if npc.alive then
            local dist = distance(npc.x, npc.y, target.x, target.y)
            table.insert(sorted, { npc = npc, dist = dist })
        end
    end
    table.sort(sorted, function(a, b) return a.dist < b.dist end)

    -- Assign roles by distance
    for i, entry in ipairs(sorted) do
        if i == 1 then
            self.roles[entry.npc] = "assault"  -- closest → engage directly
        elseif i <= 3 then
            self.roles[entry.npc] = "flank"    -- next two → approach from sides
        else
            self.roles[entry.npc] = "support"  -- rest → hang back, cover fire
        end
    end
end

function Coordinator:get_position_for(npc, influence_map)
    local role = self.roles[npc]
    if not role or not self.target then return npc.x, npc.y end

    if role == "assault" then
        -- Move directly toward target
        return self.target.x, self.target.y

    elseif role == "flank" then
        -- Find a position at 90 degrees from the assault line
        local dx = self.target.x - npc.x
        local dy = self.target.y - npc.y
        local dist = math.sqrt(dx^2 + dy^2)
        if dist < 1 then return npc.x, npc.y end

        -- Perpendicular direction
        local perp_x, perp_y = -dy / dist, dx / dist
        -- Pick the side that has lower danger
        local side1_x = self.target.x + perp_x * 80
        local side1_y = self.target.y + perp_y * 80
        local side2_x = self.target.x - perp_x * 80
        local side2_y = self.target.y - perp_y * 80

        local d1 = InfluenceMap.get_value(influence_map, side1_x, side1_y)
        local d2 = InfluenceMap.get_value(influence_map, side2_x, side2_y)
        if d1 < d2 then
            return side1_x, side1_y
        else
            return side2_x, side2_y
        end

    elseif role == "support" then
        -- Stay back, find a position with line of sight to target
        local dx = npc.x - self.target.x
        local dy = npc.y - self.target.y
        local dist = math.sqrt(dx^2 + dy^2)
        if dist < 1 then return npc.x, npc.y end
        -- Position 150 pixels behind current position relative to target
        return npc.x + (dx / dist) * 50, npc.y + (dy / dist) * 50
    end
end

function Coordinator:update(dt, influence_map)
    for _, npc in ipairs(self.members) do
        if npc.alive then
            local tx, ty = self:get_position_for(npc, influence_map)
            arrive_toward(npc, tx, ty, npc.speed, dt)
        end
    end
end

-- Reassign when a member dies
function Coordinator:on_member_death(npc)
    self.roles[npc] = nil
    self:assign_roles(self.target)  -- reassign remaining
end
```

---

## 5. Tactical Position Evaluation

Instead of assigning fixed positions, a sophisticated system **scores** candidate positions based on multiple factors. This is similar to Utility AI (Module 5) applied to spatial decisions.

```lua
-- Lua — Tactical position scoring
function score_position(x, y, npc, target, walls, influence_map)
    local score = 0

    -- Factor 1: Cover from target (can target see this position?)
    local exposed = has_line_of_sight_to(target.x, target.y, x, y, walls)
    local cover_nearby = has_cover_within(x, y, 30, walls)
    if not exposed then
        score = score + 30  -- can't be seen = great
    elseif cover_nearby then
        score = score + 15  -- can peek from cover
    end

    -- Factor 2: Line of sight TO target (can we see the target from here?)
    if has_line_of_sight_to(x, y, target.x, target.y, walls) then
        score = score + 20  -- can shoot from here
    end

    -- Factor 3: Distance to target (not too close, not too far)
    local dist = distance(x, y, target.x, target.y)
    if dist > 80 and dist < 200 then
        score = score + 15  -- ideal combat range
    end

    -- Factor 4: Low danger from influence map
    local danger = InfluenceMap.get_value(influence_map, x, y)
    score = score - danger * 5

    -- Factor 5: Not too close to allies (avoid clustering)
    -- (query other NPC positions)

    return score
end

-- Find the best tactical position in an area
function find_tactical_position(npc, target, walls, influence_map)
    local best_x, best_y = npc.x, npc.y
    local best_score = -math.huge

    -- Sample candidate positions in a grid around the NPC
    for dx = -150, 150, 30 do
        for dy = -150, 150, 30 do
            local cx, cy = npc.x + dx, npc.y + dy
            local s = score_position(cx, cy, npc, target, walls, influence_map)
            if s > best_score then
                best_score = s
                best_x, best_y = cx, cy
            end
        end
    end

    return best_x, best_y
end
```

This is how F.E.A.R.'s soldiers find flanking positions and cover spots. They don't follow scripted flanking routes — they evaluate nearby positions and pick the one with the best tactical score. The result is soldiers that adapt to any level geometry.

---

## 6. Crowd Simulation

When you have dozens or hundreds of agents (zombie hordes, city crowds, army units), individual pathfinding and decision-making become too expensive. Crowd simulation uses simplified movement and flow fields (from Module 4) to manage large numbers of agents efficiently.

```lua
-- Lua — Crowd simulation with flow field + local avoidance
local crowd = {}

function spawn_crowd(count, start_x, start_y)
    for i = 1, count do
        table.insert(crowd, {
            x = start_x + love.math.random(-50, 50),
            y = start_y + love.math.random(-50, 50),
            vx = 0, vy = 0,
            speed = 40 + love.math.random() * 20,
            radius = 5,
        })
    end
end

function update_crowd(dt, flow_field)
    for _, agent in ipairs(crowd) do
        -- Get direction from flow field
        local gx = math.floor(agent.x / CELL_SIZE) + 1
        local gy = math.floor(agent.y / CELL_SIZE) + 1

        local flow_dx, flow_dy = 0, 0
        if flow_field[gy] and flow_field[gy][gx] then
            flow_dx = flow_field[gy][gx][1]
            flow_dy = flow_field[gy][gx][2]
        end

        -- Local avoidance (simplified — push away from nearby agents)
        local avoid_x, avoid_y = 0, 0
        for _, other in ipairs(crowd) do
            if other ~= agent then
                local dx = agent.x - other.x
                local dy = agent.y - other.y
                local dist = math.sqrt(dx^2 + dy^2)
                local min_dist = agent.radius + other.radius + 5
                if dist < min_dist and dist > 0 then
                    avoid_x = avoid_x + (dx / dist) * (min_dist - dist) * 3
                    avoid_y = avoid_y + (dy / dist) * (min_dist - dist) * 3
                end
            end
        end

        -- Combine: flow direction + avoidance
        local desired_x = flow_dx * agent.speed + avoid_x
        local desired_y = flow_dy * agent.speed + avoid_y

        -- Simple steering
        agent.vx = agent.vx + (desired_x - agent.vx) * dt * 5
        agent.vy = agent.vy + (desired_y - agent.vy) * dt * 5

        local speed = math.sqrt(agent.vx^2 + agent.vy^2)
        if speed > agent.speed then
            agent.vx = agent.vx / speed * agent.speed
            agent.vy = agent.vy / speed * agent.speed
        end

        agent.x = agent.x + agent.vx * dt
        agent.y = agent.y + agent.vy * dt
    end
end
```

**Performance tip:** For large crowds (100+), don't check every agent against every other agent for local avoidance. Use spatial hashing — divide the world into cells and only check agents in the same or adjacent cells. This reduces the N² comparison to roughly O(N).

```lua
-- Lua — Spatial hash for efficient neighbor queries
local spatial_hash = {}
local HASH_CELL = 30

function hash_key(x, y)
    return math.floor(x / HASH_CELL) .. "," .. math.floor(y / HASH_CELL)
end

function rebuild_hash(agents)
    spatial_hash = {}
    for _, agent in ipairs(agents) do
        local key = hash_key(agent.x, agent.y)
        spatial_hash[key] = spatial_hash[key] or {}
        table.insert(spatial_hash[key], agent)
    end
end

function get_nearby(x, y)
    local results = {}
    local cx = math.floor(x / HASH_CELL)
    local cy = math.floor(y / HASH_CELL)
    for dx = -1, 1 do
        for dy = -1, 1 do
            local key = (cx + dx) .. "," .. (cy + dy)
            if spatial_hash[key] then
                for _, agent in ipairs(spatial_hash[key]) do
                    table.insert(results, agent)
                end
            end
        end
    end
    return results
end
```

---

## 7. Dynamic Role Assignment

Roles shouldn't be permanent. When a flanker is killed, the support should promote to flanker. When the assault NPC runs low on health, it should swap roles with a healthier squad member. Dynamic role assignment keeps the squad effective as conditions change.

```lua
-- Lua — Dynamic role reassignment
function Coordinator:reassess_roles(dt)
    -- Reassess every few seconds, not every frame
    self.reassess_timer = (self.reassess_timer or 0) + dt
    if self.reassess_timer < 2.0 then return end
    self.reassess_timer = 0

    local alive = {}
    for _, npc in ipairs(self.members) do
        if npc.alive then
            table.insert(alive, npc)
        end
    end

    if #alive == 0 then return end
    if not self.target then return end

    -- Score each NPC for each role
    for _, npc in ipairs(alive) do
        local dist = distance(npc.x, npc.y, self.target.x, self.target.y)
        npc._assault_score = npc.health / npc.max_health * (1 / math.max(dist, 1)) * 100
        npc._flank_score = npc.speed * (1 - dist / 500) * 50
        npc._support_score = (1 - npc.health / npc.max_health) * dist * 0.1
    end

    -- Assign assault to best assault scorer
    table.sort(alive, function(a, b) return a._assault_score > b._assault_score end)
    self.roles[alive[1]] = "assault"

    -- Next best get flank
    for i = 2, math.min(3, #alive) do
        self.roles[alive[i]] = "flank"
    end

    -- Rest get support
    for i = 4, #alive do
        self.roles[alive[i]] = "support"
    end
end
```

---

## Code Walkthrough: Squad Assault Demo

Here's a complete demo with a 4-NPC squad coordinating to engage a target using formations, role assignment, and an influence map.

```lua
-- Lua (LÖVE) — Squad coordination demo (simplified)
local squad = {}
local target = { x = 600, y = 300, alive = true }
local influence = nil
local CELL = 20

function love.load()
    love.window.setMode(800, 600)

    -- Create 4 squad members
    for i = 1, 4 do
        table.insert(squad, {
            x = 100 + (i - 1) * 30,
            y = 300 + (i - 1) * 20,
            speed = 60 + i * 5,
            health = 100, max_health = 100,
            alive = true,
            role = "follow",
            target_x = 0, target_y = 0,
        })
    end

    -- Build influence map
    influence = InfluenceMap.new(800, 600, CELL)
end

function love.update(dt)
    -- Update influence map
    InfluenceMap.clear(influence)
    InfluenceMap.add_influence(influence, target.x, target.y, 200, 10)

    -- Assign roles
    local alive = {}
    for _, npc in ipairs(squad) do
        if npc.alive then table.insert(alive, npc) end
    end

    if #alive > 0 then
        table.sort(alive, function(a, b)
            return distance(a.x, a.y, target.x, target.y) <
                   distance(b.x, b.y, target.x, target.y)
        end)
        alive[1].role = "assault"
        for i = 2, math.min(3, #alive) do alive[i].role = "flank" end
        for i = 4, #alive do alive[i].role = "support" end
    end

    -- Move each NPC based on role
    for _, npc in ipairs(squad) do
        if not npc.alive then goto continue end

        local tx, ty = npc.x, npc.y
        if npc.role == "assault" then
            tx, ty = target.x, target.y
        elseif npc.role == "flank" then
            local dx = target.x - npc.x
            local dy = target.y - npc.y
            local d = math.sqrt(dx^2 + dy^2)
            if d > 1 then
                local px, py = -dy/d, dx/d
                tx = target.x + px * 80
                ty = target.y + py * 80
            end
        elseif npc.role == "support" then
            local dx = npc.x - target.x
            local dy = npc.y - target.y
            local d = math.sqrt(dx^2 + dy^2)
            if d > 1 then
                tx = target.x + (dx/d) * 180
                ty = target.y + (dy/d) * 180
            end
        end

        local dx = tx - npc.x
        local dy = ty - npc.y
        local d = math.sqrt(dx^2 + dy^2)
        if d > 5 then
            npc.x = npc.x + (dx/d) * npc.speed * dt
            npc.y = npc.y + (dy/d) * npc.speed * dt
        end

        ::continue::
    end
end

function love.mousepressed(x, y)
    target.x = x
    target.y = y
end

function love.draw()
    -- Draw influence map as heat overlay
    for y = 1, influence.rows do
        for x = 1, influence.cols do
            local v = influence.grid[y][x]
            if v > 0 then
                local intensity = math.min(v / 10, 1)
                love.graphics.setColor(intensity, 0, 0, 0.2)
                love.graphics.rectangle("fill",
                    (x-1) * CELL, (y-1) * CELL, CELL, CELL)
            end
        end
    end

    -- Draw target
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.circle("fill", target.x, target.y, 12)
    love.graphics.print("TARGET", target.x - 20, target.y + 15)

    -- Draw squad
    local role_colors = {
        assault = {1, 0.5, 0},
        flank = {0.2, 0.6, 1},
        support = {0.2, 0.8, 0.2},
        follow = {0.5, 0.5, 0.5},
    }
    for _, npc in ipairs(squad) do
        if npc.alive then
            local c = role_colors[npc.role] or {1,1,1}
            love.graphics.setColor(c)
            love.graphics.circle("fill", npc.x, npc.y, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(npc.role or "?", npc.x - 15, npc.y - 18)
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Click to move target", 10, 10)
end
```

---

## Common Pitfalls

### 1. All NPCs clustering on the same point

Without role differentiation or spatial separation, all NPCs pathfind to the same position (the player) and stack on top of each other. Use formations, role-based positioning, or separation forces to spread them out.

### 2. Formation members blocking each other in doorways

When a formation tries to pass through a narrow passage, members get stuck because their slots are wider than the opening. Temporarily switch to single-file formation when passing through narrow spaces, then reform on the other side.

### 3. Influence map resolution too fine or too coarse

Too fine (1-pixel cells) = slow to compute, wasteful. Too coarse (100-pixel cells) = imprecise, NPCs make poor spatial decisions. A cell size of 16-32 pixels is typical for 2D games.

### 4. Static role assignment when the situation changes

The "assault" NPC is at 10% health but still charging forward because roles never reassign. Reassess roles periodically (every 1-3 seconds) based on current health, position, and ammo.

### 5. Crowd agents ignoring each other

Without local avoidance, crowd agents walk through each other. This looks terrible. Add at minimum a separation force (from Module 3's steering) or use spatial hashing for efficient neighbor queries.

### 6. Coordinator AI being too smart

The squad coordinator finds the mathematically optimal flanking positions and the squad executes perfectly every time. The player feels like they're fighting a hive mind. Add imperfection — delayed communication, occasional role confusion, and positioning that's "good enough" rather than optimal.

---

## Exercises

### Exercise 1: Formation Movement
**Time:** 1.5-2 hours

Build a formation system with three switchable formations (V, line, circle). A leader follows the mouse cursor, and 4-6 followers maintain formation positions using Arrive steering. Requirements:

1. Press 1/2/3 to switch formations
2. Followers smoothly transition between formation shapes
3. When a follower is "killed" (right-click), the formation closes the gap

**Concepts practiced:** Formation math, slot assignment, Arrive steering, gap-closing

**Stretch goal:** Add a "scatter" command that breaks formation and has each NPC move to a random nearby position, then a "reform" command that reassembles the formation.

---

### Exercise 2: Influence Map Visualizer
**Time:** 1.5-2 hours

Build an interactive influence map visualizer:

1. Click to place "threat sources" that radiate influence
2. Display the influence map as a color-coded heat overlay
3. Place an NPC that automatically moves toward the lowest-danger cell with line-of-sight to the nearest threat (tactical positioning)
4. Add a second layer: "cover" influence near walls

**Concepts practiced:** Influence map computation, multi-layer spatial reasoning, tactical position evaluation

**Stretch goal:** Combine danger and cover layers to find "good cover positions" — cells with high cover value and low danger value.

---

### Exercise 3: Squad Assault
**Time:** 2.5-3 hours

Build a 4-NPC squad that coordinates to engage a player-controlled target:

1. One "assault" that approaches directly
2. Two "flankers" that approach from the sides
3. One "support" that stays back
4. Use an influence map to determine flanking positions
5. When one NPC is "killed" (click on it), roles reassign dynamically

**Concepts practiced:** Squad coordination, role assignment, influence maps, dynamic reassignment

**Stretch goal:** Add multiple squads that operate independently. One squad engages while another takes a wide flanking route.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| "Coordinating Agents with Behavior Trees" from *Game AI Pro* | Book chapter (free) | Production patterns for squad coordination using behavior trees |
| "Influence Maps" by Dave Mark, *Game AI Pro* | Book chapter (free) | The definitive practical guide to building and using influence maps |
| Craig Reynolds' boids page | Web (primary source) | Flocking is the foundation of crowd behavior — revisit for large-group dynamics |
| *Nature of Code* Chapter 6 | Book (free, interactive) | Extended treatment of group behaviors and emergent flocking patterns |
| "The AI of F.E.A.R." by Jeff Orkin | Paper | The squad coordination in F.E.A.R. is the gold standard case study |

---

## Key Takeaways

1. **Formations are offset positions + Arrive steering.** Slot positions relative to a leader, maintained through steering behaviors. Simple math, powerful result.

2. **Squad coordination needs a meta-AI.** The coordinator assigns roles and objectives. Individual NPCs execute their role's movement and behavior. This separation of concerns keeps the system manageable.

3. **Influence maps turn spatial data into decisions.** Danger, cover, visibility — encoded as grid values that NPCs query to find good positions. This replaces hardcoded tactical logic with emergent positioning.

4. **Dynamic role assignment keeps squads effective.** Roles should reassess periodically based on NPC health, position, and the tactical situation. Static assignment fails when conditions change.

5. **Crowd simulation needs spatial hashing.** For 100+ agents, N² neighbor checks are too slow. Divide the world into cells and only check nearby cells. This makes large crowds feasible.

6. **Add imperfection to group AI.** Perfect coordination feels like a hive mind. Delays, occasional mistakes, and "good enough" positioning make groups feel like teams of individuals, not a single entity.

---

## What's Next?

You now know how to make groups of NPCs work together — formations for movement, squad tactics for combat, and influence maps for spatial reasoning. The next module applies many of these concepts to a specific, high-stakes context.

In [Module 9: Boss AI Patterns](module-09-boss-ai-patterns.md), you'll design boss encounters that are memorable — phase systems, attack telegraphs, pattern choreography, and arena design. Boss AI is where game design and AI engineering overlap most tightly, and where getting the tuning right is the difference between a frustrating obstacle and a celebrated highlight.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
