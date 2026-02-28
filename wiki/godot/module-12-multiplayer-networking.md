# Module 12: Multiplayer & Networking

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Prerequisites:** Module 05 (signals, resources, architecture)
**Estimated study time:** 8–12 hours

---

## Overview

Multiplayer transforms a game from a solo experience into a shared world, and Godot 4 ships with a first-class multiplayer system built directly into the engine. The `MultiplayerAPI` handles peer management, Remote Procedure Calls (RPCs), and high-level node synchronization without requiring you to manually manage sockets or serialize every packet by hand. If you've ever tried to roll your own networking layer, you know how much hidden complexity lives there — Godot abstracts most of it while still giving you escape hatches when you need them.

The system is split into two layers. The low-level layer (`ENetMultiplayerPeer`, `WebSocketMultiplayerPeer`, `WebRTCMultiplayerPeer`) handles the actual transport: opening ports, managing connections, and shuttling raw bytes across the wire. The high-level layer (`@rpc` annotations, `MultiplayerSpawner`, `MultiplayerSynchronizer`) gives you declarative tools to synchronize game state across all peers. You can stay entirely in the high-level layer for most games, dropping into the low-level only when you need custom packet formats or extreme bandwidth optimization.

This module focuses on the most common real-world pattern: a **listen server** (or dedicated server) where one peer is the authority, using **ENet** as the transport. You'll learn how RPCs work, how `MultiplayerSpawner` keeps the scene tree in sync across all clients, how `MultiplayerSynchronizer` propagates property values efficiently, and how the **authority model** prevents clients from lying to each other. By the end you'll have a working 3D multiplayer arena — lobby, spawn system, synchronized movement, and a basic combat scoreboard.

---

## 1. Multiplayer Architecture

### The Mental Model

Godot multiplayer follows a **client-server topology**. One machine runs the server; every other machine is a client. In a **listen server** setup, the host is simultaneously a client playing the game and the server processing authority — this is the easiest setup for a "one player hosts the game" experience. A **dedicated server** runs headless (no rendering), handling only game logic; clients connect and receive the game state.

Every connected peer gets a **unique integer ID**. The server always has ID `1`. Clients get IDs in the range `2–2^31`. When you call `multiplayer.get_unique_id()`, you get your own ID. When you iterate `multiplayer.get_peers()`, you get the list of everyone else connected to you.

```gdscript
# Who am I?
var my_id: int = multiplayer.get_unique_id()

# Am I the server?
var is_server: bool = multiplayer.is_server()

# Who is connected to me?
var peers: Array = multiplayer.get_peers()
```

### The Authority Concept

Every node in the scene tree has a **multiplayer authority** — the peer ID that "owns" that node and has the right to make changes to it. By default, authority is `1` (the server owns everything). You can transfer authority with `set_multiplayer_authority(peer_id)`.

Authority matters for:
- **RPCs with `authority` mode** — only the authority can call them
- **MultiplayerSynchronizer** — only the authority's values are broadcast
- **`is_multiplayer_authority()`** — lets a node check if the local machine owns it

Think of it this way: the server owns all game objects by default. When a player spawns their character, you transfer authority of that character node to the client who owns it. Now that client's `MultiplayerSynchronizer` sends their position to everyone else, instead of the server doing it.

### Network Topology Options

| Topology | When to Use | Notes |
|---|---|---|
| Listen Server | Casual/indie MP, "host a game" | Host has latency advantage; simple |
| Dedicated Server | Competitive, always-on | Headless export; fair for all |
| Client-Server | Most games | Authority stays on server |
| Peer-to-Peer | Rare in Godot | WebRTC only; no built-in P2P for ENet |

### The multiplayer_peer Property

The `SceneTree` has a `multiplayer` property (a `MultiplayerAPI` instance). You assign a transport peer to `multiplayer.multiplayer_peer` to enable networking. Until you assign a peer, nothing is transmitted — the `@rpc` calls just execute locally.

```gdscript
# This is how networking starts:
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
peer.create_server(7777, 4)         # port 7777, max 4 clients
multiplayer.multiplayer_peer = peer  # now the scene tree is networked
```

---

## 2. ENetMultiplayerPeer

ENet is Godot's default transport layer — a UDP-based protocol that adds optional reliability, ordering, and sequencing on top of raw UDP. It's battle-tested for games (used in Quake-era games, Source engine, many others) and handles the gnarly parts of UDP networking for you.

### Creating a Server

```gdscript
extends Node

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func host_game(port: int, max_players: int) -> void:
    var error: Error = peer.create_server(port, max_players)
    if error != OK:
        push_error("Failed to create server: " + str(error))
        return

    multiplayer.multiplayer_peer = peer

    # Wire up signals
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

    print("Server listening on port %d, max %d players" % [port, max_players])


func _on_peer_connected(peer_id: int) -> void:
    print("Peer connected: ", peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
    print("Peer disconnected: ", peer_id)
```

### Creating a Client

```gdscript
extends Node

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func join_game(address: String, port: int) -> void:
    var error: Error = peer.create_client(address, port)
    if error != OK:
        push_error("Failed to create client: " + str(error))
        return

    multiplayer.multiplayer_peer = peer

    # Wire up signals
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

    print("Connecting to %s:%d..." % [address, port])


func _on_connected_to_server() -> void:
    print("Connected! My peer ID: ", multiplayer.get_unique_id())


func _on_connection_failed() -> void:
    push_error("Connection failed.")
    multiplayer.multiplayer_peer = null  # clean up


func _on_server_disconnected() -> void:
    print("Server closed the connection.")
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

### Connection Signals Reference

| Signal | Who Receives It | When |
|---|---|---|
| `peer_connected(id)` | Server and all clients | Any new peer joins |
| `peer_disconnected(id)` | Server and all clients | Any peer leaves |
| `connected_to_server` | Client only | Successfully connected |
| `connection_failed` | Client only | Could not connect |
| `server_disconnected` | Client only | Server shut down or timed out |

### Port Forwarding Basics

ENet uses UDP. For players outside your LAN to connect, the host machine needs the game port forwarded in their router. This is outside your game's control — just document what port to forward. For development:

- **LAN testing**: No port forwarding needed. Use the host's LAN IP (e.g., `192.168.1.x`).
- **Internet testing**: The host forwards the port, shares their public IP. Or use a relay/STUN service.
- **Recommended dev approach**: Use [ngrok](https://ngrok.com/) or Tailscale for testing across the internet without fussing with routers.

For released games, consider a relay server or a matchmaking backend so players never need to deal with ports at all.

---

## 3. RPCs (Remote Procedure Calls)

RPCs are the backbone of Godot multiplayer. An RPC is a method call that executes on remote peers — you call it locally, and the engine serializes the call and its arguments, sends them over the network, and the receiving peers deserialize and execute it.

### The @rpc Annotation

```gdscript
# Basic RPC — callable by anyone, runs on the peer you call it on
@rpc
func my_rpc_function() -> void:
    print("This ran remotely!")
```

The `@rpc` annotation takes up to four arguments:

```gdscript
@rpc("mode", "sync", "transfer_mode", channel)
```

**Mode** (who can call this RPC):
- `"any_peer"` — any connected peer can call this
- `"authority"` — only the authority of this node can call it (default)

**Sync** (does it also run on the caller?):
- `"call_remote"` — only runs on remote peers, not the caller (default)
- `"call_local"` — runs on both caller and remote peers

**Transfer Mode** (reliability):
- `"unreliable"` — UDP with no guarantees. Fastest. Use for position updates.
- `"unreliable_ordered"` — UDP but out-of-order packets are dropped. Use for input.
- `"reliable"` — guaranteed delivery and ordering. Use for important events.

**Channel**: Integer, default 0. Channels are independent ordered streams within a connection. Use separate channels for different types of traffic to avoid head-of-line blocking.

### RPC Examples

```gdscript
extends CharacterBody3D

# Position update — unreliable is fine, we'll get the next one anyway
@rpc("any_peer", "call_remote", "unreliable")
func sync_position(pos: Vector3, vel: Vector3) -> void:
    global_position = pos
    velocity = vel


# Taking damage — reliable because missing this would be a bug
@rpc("authority", "call_remote", "reliable")
func take_damage(amount: int, attacker_id: int) -> void:
    health -= amount
    if health <= 0:
        die()


# Chat message — reliable, runs on everyone including sender
@rpc("any_peer", "call_local", "reliable")
func send_chat(message: String) -> void:
    print("[%d]: %s" % [multiplayer.get_remote_sender_id(), message])
```

### Calling RPCs

```gdscript
# Call on ALL peers (including server if you're a client, or all clients if server)
sync_position.rpc(global_position, velocity)

# Call on a specific peer by ID
take_damage.rpc_id(target_peer_id, 10, multiplayer.get_unique_id())

# Shorthand: multiplayer.rpc() also works but the direct method call is cleaner
```

### get_remote_sender_id()

Inside an RPC, you can check who called it:

```gdscript
@rpc("any_peer", "call_local", "reliable")
func request_spawn() -> void:
    var caller_id: int = multiplayer.get_remote_sender_id()
    # 0 means it was called locally (not over the network)
    if caller_id == 0:
        caller_id = multiplayer.get_unique_id()
    print("Spawn requested by peer: ", caller_id)
```

This is critical for **server-side validation** — always check `get_remote_sender_id()` to confirm that the peer sending a request is allowed to do what they're asking.

### RPC with Static Typing and Arguments

GDScript's static typing works with RPC arguments — the engine serializes supported types: `bool`, `int`, `float`, `String`, `Vector2`, `Vector3`, `Quaternion`, `Color`, `Array`, `Dictionary`, `PackedByteArray`, and `NodePath`.

```gdscript
@rpc("authority", "call_remote", "reliable")
func initialize_player(
    player_name: String,
    spawn_position: Vector3,
    team: int
) -> void:
    $Label3D.text = player_name
    global_position = spawn_position
    assign_team(team)
```

---

## 4. MultiplayerSpawner

Manually tracking which nodes exist on which peers and spawning/despawning them in sync is tedious and error-prone. `MultiplayerSpawner` automates this: you register which scenes can be spawned, and whenever the server instantiates one under the spawner's tracked path, it's automatically replicated to all connected clients. Peers who join later also receive the spawn retroactively.

### Basic Setup

1. Add a `MultiplayerSpawner` node to your scene.
2. Set **Spawn Path** to the node that will contain spawned instances (e.g., `../Players`).
3. Add scenes to the **Auto Spawn List** in the inspector.

```gdscript
# In your game manager / server script
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node3D = $Players

func _ready() -> void:
    # Only the server drives spawning
    if not multiplayer.is_server():
        return

    # Connect to the spawner's signals if needed
    spawner.spawned.connect(_on_node_spawned)
    spawner.despawned.connect(_on_node_despawned)

    # When a new peer connects, spawn their player
    multiplayer.peer_connected.connect(_spawn_player)


func _spawn_player(peer_id: int) -> void:
    if not multiplayer.is_server():
        return

    var player: Node3D = preload("res://scenes/player.tscn").instantiate()
    player.name = str(peer_id)  # IMPORTANT: name must be unique and match peer ID pattern
    player.set_multiplayer_authority(peer_id)

    players_container.add_child(player)
    # MultiplayerSpawner will automatically replicate this to all clients


func _on_node_spawned(node: Node) -> void:
    print("Node spawned: ", node.name)


func _on_node_despawned(node: Node) -> void:
    print("Node despawned: ", node.name)
```

### Custom Spawn Functions

Sometimes you need to pass data along with the spawn (like starting position or team assignment). Use a custom spawn function:

```gdscript
# In the spawner's script (or configure via inspector)
func _ready() -> void:
    spawner.spawn_function = _custom_spawn


func _custom_spawn(data: Variant) -> Node:
    # data is whatever you pass to spawner.spawn(data)
    var player_data: Dictionary = data as Dictionary
    var player: Node3D = preload("res://scenes/player.tscn").instantiate()
    player.name = str(player_data["peer_id"])
    player.global_position = player_data["spawn_pos"]
    player.set_multiplayer_authority(player_data["peer_id"])
    return player


func spawn_player_at(peer_id: int, spawn_position: Vector3) -> void:
    if not multiplayer.is_server():
        return

    var data: Dictionary = {
        "peer_id": peer_id,
        "spawn_pos": spawn_position,
    }
    spawner.spawn(data)
```

### Despawning

To despawn, just free the node on the server. `MultiplayerSpawner` will replicate the despawn automatically:

```gdscript
func despawn_player(peer_id: int) -> void:
    if not multiplayer.is_server():
        return

    var player: Node = players_container.get_node_or_null(str(peer_id))
    if player:
        player.queue_free()  # MultiplayerSpawner handles the rest
```

### Naming Convention

Node names for spawned characters **must be deterministic and consistent** across server and client. The simplest approach: name them after the peer ID. The spawner uses the node path to identify nodes across the network, so mismatches cause synchronization failures.

---

## 5. MultiplayerSynchronizer

`MultiplayerSynchronizer` is your declarative property sync system. You add it as a child of a node, configure which properties to replicate, and the engine handles sending deltas to all peers at the configured interval. No manual packing, no per-property RPCs for continuous values.

### Basic Setup

1. Add `MultiplayerSynchronizer` as a child of the node you want to sync.
2. In the inspector, add **Replication Config** entries for each property to sync.
3. Set the **Replication Interval** (seconds between syncs, 0 = every frame).
4. The **authority** of the parent node sends; all others receive.

```gdscript
# player.tscn structure:
# CharacterBody3D (player)
#   └── MultiplayerSynchronizer

# In player.gd
extends CharacterBody3D

@export var player_name: String = ""
@export var health: int = 100
@export var team: int = 0

@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer


func _ready() -> void:
    # Configure sync in the inspector, or do it in code:
    # Sync position and rotation continuously (unreliable is fine for smooth movement)
    # Sync health and name reliably when they change
    pass


func _physics_process(delta: float) -> void:
    # Only the authority processes input and moves
    if not is_multiplayer_authority():
        return

    _handle_input(delta)
    move_and_slide()
    # MultiplayerSynchronizer automatically broadcasts position to others
```

### Configuring in Code

```gdscript
func _setup_synchronizer() -> void:
    var config: SceneReplicationConfig = SceneReplicationConfig.new()

    # Sync position — fast, unreliable is fine
    var pos_prop: SceneReplicationConfig.ReplicationProperty
    # Note: in practice, configure via inspector for cleaner workflow
    # Code config is verbose; inspector is preferred

    sync.replication_config = config
```

The inspector approach is strongly preferred for `MultiplayerSynchronizer`. In the Replication Config panel, you add property paths like:
- `CharacterBody3D:position`
- `CharacterBody3D:rotation`
- Custom properties you defined with `@export`

### Replication Interval

- `0.0` = sync every physics frame (expensive for many nodes)
- `0.1` = sync 10 times per second (good for most game objects)
- `0.5` = sync twice per second (fine for slow-moving objects, UI state)

### Delta vs Full Sync

By default the synchronizer sends **full state** every interval. For properties that rarely change (player name, team, max health), this is wasteful. You can mark properties as **on_change** so they only sync when their value actually changes:

In the inspector's Replication Config, each property has two checkboxes:
- **Sync** — include in the periodic interval sync
- **Spawn** — send this property when the node is first spawned

For `health`, you might want both. For `position`, you only want Sync. For `player_name`, you might only want Spawn.

### Visibility Filters

`MultiplayerSynchronizer` supports **visibility filters** — you can control which peers receive sync updates for a given node. This is powerful for area-of-interest systems (only sync enemies you can see):

```gdscript
func _ready() -> void:
    sync.set_visibility_for(peer_id, false)   # hide from specific peer
    sync.set_visibility_for(peer_id, true)    # show to specific peer
    sync.visibility_filter = _visibility_filter_func


func _visibility_filter_func(peer_id: int) -> bool:
    # Return true if this peer should receive syncs
    var their_player: Node3D = get_player_node(peer_id)
    if their_player == null:
        return false
    return global_position.distance_to(their_player.global_position) < 100.0
```

---

## 6. Authority & Ownership

Authority is the most important concept in Godot multiplayer. Get it wrong and you'll have clients fighting each other for control of nodes, or the server overwriting player input.

### set_multiplayer_authority() and is_multiplayer_authority()

```gdscript
# Server sets authority when spawning a player
func _spawn_player(peer_id: int) -> void:
    var player: CharacterBody3D = player_scene.instantiate()
    player.name = str(peer_id)
    players.add_child(player)
    player.set_multiplayer_authority(peer_id)
    # Now peer_id's machine is the authority for this node


# In player.gd — run input ONLY on the authoritative machine
func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        # We're not in charge of this player — just render their synced position
        return

    var direction: Vector3 = _get_input_direction()
    velocity = direction * SPEED
    move_and_slide()
```

### Authority Propagation

Authority propagates to children by default. If you set authority on a `CharacterBody3D`, all child nodes (including the `MultiplayerSynchronizer`) inherit it. This is the expected behavior — don't fight it.

### Server-Authoritative vs Client-Authoritative

**Server-authoritative**: The server owns all gameplay nodes. Clients send input as RPCs; the server processes them and syncs results back. Most secure. Higher perceived latency.

```gdscript
# Client sends input to server
@rpc("any_peer", "call_remote", "unreliable_ordered")
func submit_input(direction: Vector2, jump: bool) -> void:
    if not multiplayer.is_server():
        return
    var peer_id: int = multiplayer.get_remote_sender_id()
    var player: PlayerController = get_player(peer_id)
    if player:
        player.apply_input(direction, jump)
```

**Client-authoritative**: Each client owns their own character. They move locally and broadcast their position. Lower perceived latency, but clients can cheat by sending fake positions.

```gdscript
# Client moves their own character and syncs via MultiplayerSynchronizer
# No server validation — trust the client's position
func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        return  # Just display synced position from authority
    # ... handle input, move, MultiplayerSynchronizer handles the rest
```

**Hybrid**: Client-authoritative for position (use prediction), server-authoritative for combat/damage. This is what most real games use. The section on client prediction covers it in more detail.

### Authority Transfer

You can change authority at runtime — useful for picking up objects, transferring control, or handing a node to a different player:

```gdscript
# Server transfers a power-up node to the player who picked it up
func _on_pickup_collected(pickup: Node3D, collector_peer_id: int) -> void:
    if not multiplayer.is_server():
        return
    pickup.set_multiplayer_authority(collector_peer_id)
    # Now that client's synchronizer drives the pickup's state
```

---

## 7. State Synchronization Patterns

Raw synchronization — "send position every frame" — works but feels bad. Here's how real games handle it.

### Snapshot Interpolation

Instead of applying received positions immediately, buffer them and interpolate between the last two received snapshots. This smooths out jitter from variable network latency.

```gdscript
extends CharacterBody3D

const INTERPOLATION_OFFSET: float = 0.1  # 100ms behind "live"

var _position_buffer: Array[Dictionary] = []


func _physics_process(delta: float) -> void:
    if is_multiplayer_authority():
        return  # Authority moves for real

    _interpolate_position()


func _receive_snapshot(pos: Vector3, timestamp: float) -> void:
    _position_buffer.append({"pos": pos, "time": timestamp})
    # Keep buffer from growing unbounded
    while _position_buffer.size() > 20:
        _position_buffer.pop_front()


func _interpolate_position() -> void:
    var render_time: float = Time.get_ticks_msec() / 1000.0 - INTERPOLATION_OFFSET

    # Find the two snapshots surrounding render_time
    for i: int in range(_position_buffer.size() - 1):
        var older: Dictionary = _position_buffer[i]
        var newer: Dictionary = _position_buffer[i + 1]

        if render_time >= older["time"] and render_time <= newer["time"]:
            var t: float = (render_time - older["time"]) / (newer["time"] - older["time"])
            global_position = older["pos"].lerp(newer["pos"], t)
            return

    # Extrapolate if we don't have a future snapshot (risky but beats freezing)
    if _position_buffer.size() > 0:
        global_position = _position_buffer[-1]["pos"]
```

### Client-Side Prediction

For player-controlled characters, waiting for the server round-trip before moving feels terrible. Client-side prediction lets the client move immediately, then reconciles with the authoritative server result.

The basic algorithm:
1. Client applies input locally and moves immediately (predict).
2. Client sends input to server with a sequence number.
3. Server processes input, sends back authoritative position + sequence number.
4. Client compares: if its predicted position matches, do nothing. If it diverges, snap/lerp to the server's position (reconcile).

```gdscript
extends CharacterBody3D

var _pending_inputs: Array[Dictionary] = []
var _sequence: int = 0


func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        return

    # Record input with sequence number
    var input: Dictionary = {
        "seq": _sequence,
        "direction": _get_input_direction(),
        "delta": delta,
    }
    _pending_inputs.append(input)
    _sequence += 1

    # Apply locally (prediction)
    _apply_input(input)

    # Send to server for validation
    submit_input.rpc_id(1, input["seq"], input["direction"], delta)


@rpc("authority", "call_remote", "unreliable_ordered")
func receive_correction(seq: int, authoritative_pos: Vector3) -> void:
    # Remove acknowledged inputs from pending list
    _pending_inputs = _pending_inputs.filter(func(i): return i["seq"] > seq)

    # If there's a significant mismatch, correct and re-simulate
    if global_position.distance_to(authoritative_pos) > 0.5:
        global_position = authoritative_pos
        # Re-apply all pending inputs on top of corrected position
        for pending: Dictionary in _pending_inputs:
            _apply_input(pending)


func _apply_input(input: Dictionary) -> void:
    velocity = input["direction"] * SPEED
    move_and_slide()
```

### Bandwidth Optimization

- **Delta compression**: Only send values that changed. `MultiplayerSynchronizer`'s on_change mode does this for you.
- **Quantization**: Reduce float precision. A position doesn't need 32-bit floats — 16-bit fixed point is often enough. Implement with `PackedByteArray` for custom packets.
- **Interest management**: Don't sync objects far away from a player. Use visibility filters on `MultiplayerSynchronizer`.
- **Dead reckoning**: If an object is moving in a straight line, stop sending updates and let clients extrapolate. Send a correction only when the trajectory changes significantly.
- **Tick rate**: Most games sync at 20-64 Hz, not 60 Hz. Reduce `MultiplayerSynchronizer` interval to 0.05 (20 Hz) for a significant bandwidth win.

---

## 8. Lobby & Game Flow

A complete multiplayer game needs more than just in-game sync. It needs a lobby where players gather, confirm readiness, and transition together into the match.

### Lobby Data Model

```gdscript
# lobby_data.gd — a Resource for sharing lobby state
class_name LobbyData
extends Resource

@export var players: Dictionary = {}
# Key: peer_id (int), Value: PlayerInfo resource

class PlayerInfo:
    var peer_id: int
    var player_name: String
    var is_ready: bool = false
    var team: int = 0
```

### Lobby Manager

```gdscript
# lobby_manager.gd
extends Node

signal player_list_changed
signal game_starting(countdown: int)

var players: Dictionary = {}  # peer_id -> PlayerInfo


func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _on_peer_connected(peer_id: int) -> void:
    # Server tells the new peer about all existing players
    if multiplayer.is_server():
        for existing_id: int in players:
            var info: Dictionary = players[existing_id]
            _send_player_info.rpc_id(peer_id, existing_id, info["name"], info["ready"])


func _on_peer_disconnected(peer_id: int) -> void:
    players.erase(peer_id)
    _broadcast_player_left.rpc(peer_id)
    player_list_changed.emit()


# Called by each client to register themselves
@rpc("any_peer", "call_remote", "reliable")
func register_player(player_name: String) -> void:
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id == 0:
        sender_id = multiplayer.get_unique_id()

    players[sender_id] = {"name": player_name, "ready": false}
    _broadcast_player_joined.rpc(sender_id, player_name)
    player_list_changed.emit()


@rpc("any_peer", "call_local", "reliable")
func _broadcast_player_joined(peer_id: int, player_name: String) -> void:
    if not players.has(peer_id):
        players[peer_id] = {"name": player_name, "ready": false}
    player_list_changed.emit()


@rpc("any_peer", "call_local", "reliable")
func _broadcast_player_left(peer_id: int) -> void:
    players.erase(peer_id)
    player_list_changed.emit()


@rpc("any_peer", "call_remote", "reliable")
func _send_player_info(peer_id: int, name: String, ready: bool) -> void:
    players[peer_id] = {"name": name, "ready": ready}
    player_list_changed.emit()


# Client calls this to toggle their ready state
@rpc("any_peer", "call_remote", "reliable")
func set_ready(is_ready: bool) -> void:
    if not multiplayer.is_server():
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if players.has(sender_id):
        players[sender_id]["ready"] = is_ready
        _sync_ready_state.rpc(sender_id, is_ready)
        _check_all_ready()


@rpc("authority", "call_local", "reliable")
func _sync_ready_state(peer_id: int, is_ready: bool) -> void:
    if players.has(peer_id):
        players[peer_id]["ready"] = is_ready
    player_list_changed.emit()


func _check_all_ready() -> void:
    if not multiplayer.is_server():
        return
    if players.size() < 2:
        return
    for info: Dictionary in players.values():
        if not info["ready"]:
            return
    # All ready — start the game
    _start_game.rpc()


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
    get_tree().change_scene_to_file("res://scenes/arena.tscn")
```

### Handling Late Joiners

Late joiners are tricky — the game state has evolved since launch. Strategies:

1. **Snapshot send on join**: Server serializes full game state to JSON/binary and sends it as a reliable RPC to the new peer. They initialize from that snapshot.
2. **Re-spawn all nodes**: When a peer connects mid-game, `MultiplayerSpawner` automatically spawns existing tracked nodes for them. You still need to sync their current state.
3. **Spectator only**: Simplest — late joiners can only spectate until the next round.

### Handling Disconnects

```gdscript
# In your arena/game manager
func _ready() -> void:
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_player_disconnected(peer_id: int) -> void:
    if not multiplayer.is_server():
        return
    # Remove their player node — MultiplayerSpawner handles replication of the despawn
    var player: Node = $Players.get_node_or_null(str(peer_id))
    if player:
        player.queue_free()
    # Update scoreboard
    _remove_from_scoreboard.rpc(peer_id)


func _on_server_disconnected() -> void:
    # Return everyone to main menu
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

---

## 9. Security Considerations

If your game has any competitive element, assume players will try to cheat. The golden rule: **never trust the client**. Verify everything on the server.

### Server-Side Validation

Every action a client requests should be validated before executing:

```gdscript
# BAD — client says "I shot player X for 50 damage", server blindly applies it
@rpc("any_peer", "call_remote", "reliable")
func deal_damage_bad(target_id: int, amount: int) -> void:
    get_player(target_id).health -= amount  # Client can send any amount!


# GOOD — server calculates damage based on game state, not client input
@rpc("any_peer", "call_remote", "reliable")
func request_attack(target_id: int) -> void:
    if not multiplayer.is_server():
        return

    var attacker_id: int = multiplayer.get_remote_sender_id()
    var attacker: PlayerNode = get_player(attacker_id)
    var target: PlayerNode = get_player(target_id)

    if attacker == null or target == null:
        return

    # Validate: is the attacker alive?
    if attacker.health <= 0:
        return

    # Validate: is the target in range?
    if attacker.global_position.distance_to(target.global_position) > ATTACK_RANGE:
        return  # Client is lying about being close enough

    # Server calculates damage from server-side stats
    var damage: int = attacker.get_attack_damage()
    target.take_damage(damage, attacker_id)
```

### Rate Limiting

Prevent spam attacks — a client flooding your server with RPCs can degrade performance for everyone:

```gdscript
var _last_attack_time: Dictionary = {}  # peer_id -> timestamp
const ATTACK_COOLDOWN: float = 0.5


@rpc("any_peer", "call_remote", "reliable")
func request_attack(target_id: int) -> void:
    if not multiplayer.is_server():
        return

    var sender_id: int = multiplayer.get_remote_sender_id()
    var now: float = Time.get_ticks_msec() / 1000.0

    # Rate limit check
    if _last_attack_time.has(sender_id):
        if now - _last_attack_time[sender_id] < ATTACK_COOLDOWN:
            return  # Too fast — ignore

    _last_attack_time[sender_id] = now
    # ... proceed with attack
```

### Position Validation

For client-authoritative movement, validate positions server-side:

```gdscript
@rpc("any_peer", "call_remote", "unreliable_ordered")
func update_position(new_pos: Vector3) -> void:
    if not multiplayer.is_server():
        return

    var sender_id: int = multiplayer.get_remote_sender_id()
    var player: PlayerNode = get_player(sender_id)
    if player == null:
        return

    # Sanity check: did they teleport?
    var max_distance_per_frame: float = player.SPEED * 2.0 * (1.0 / 20.0)  # 2x speed at 20Hz
    if player.global_position.distance_to(new_pos) > max_distance_per_frame:
        # Suspicious — reject and send correction
        player.force_position.rpc_id(sender_id, player.global_position)
        return

    player.global_position = new_pos
```

### Additional Security Principles

- **Authenticate peer IDs**: ENet peer IDs are not secret. Use a token system if you need to associate peers with player accounts.
- **Validate node ownership**: In every RPC, check that `get_remote_sender_id()` matches the expected authority.
- **Sanitize strings**: Player names go through your UI. Validate length, strip invalid characters.
- **Cap Array/Dictionary sizes**: Malformed packets with huge arrays can cause memory issues. Check `.size()` before iterating.
- **Dedicated server for competitive play**: A listen server lets the host see all game state, enabling aimbot-style advantages. A dedicated headless server removes this.

---

## 10. Building the Multiplayer Arena (Code Walkthrough)

This section walks through a complete multiplayer arena. Four scenes: `main_menu.tscn`, `lobby.tscn`, `arena.tscn`, and `player.tscn`. Core features: host/join, player list, synchronized movement and health, melee attack, kill counter.

### Scene Structure

```
main_menu.tscn
  └── MainMenu (Control)

lobby.tscn
  └── Lobby (Control)
       ├── LobbyManager (Node)
       ├── PlayerList (VBoxContainer)
       ├── ReadyButton (Button)
       └── StartButton (Button)  [host only]

arena.tscn
  └── Arena (Node3D)
       ├── GameManager (Node)
       ├── MultiplayerSpawner
       ├── Players (Node3D)  ← spawn path
       ├── SpawnPoints (Node3D)
       │    ├── SpawnPoint1 (Marker3D)
       │    ├── SpawnPoint2 (Marker3D)
       │    ├── SpawnPoint3 (Marker3D)
       │    └── SpawnPoint4 (Marker3D)
       ├── Environment (Node3D)
       └── HUD (CanvasLayer)
            ├── HealthBar (ProgressBar)
            └── Scoreboard (VBoxContainer)

player.tscn
  └── Player (CharacterBody3D)
       ├── CollisionShape3D
       ├── MeshInstance3D
       ├── AttackArea (Area3D)
       │    └── CollisionShape3D
       ├── Label3D  ← shows player name
       └── MultiplayerSynchronizer
```

### network_manager.gd (Autoload)

```gdscript
# network_manager.gd — add as autoload named "NetworkManager"
extends Node

signal server_created
signal joined_server
signal connection_failed
signal player_disconnected(peer_id: int)

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 4


func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)


func host(port: int = DEFAULT_PORT) -> void:
    peer = ENetMultiplayerPeer.new()
    var error: Error = peer.create_server(port, MAX_PLAYERS)
    if error != OK:
        push_error("Host failed: %s" % error_string(error))
        return
    multiplayer.multiplayer_peer = peer
    server_created.emit()
    print("Hosting on port %d" % port)


func join(address: String, port: int = DEFAULT_PORT) -> void:
    peer = ENetMultiplayerPeer.new()
    var error: Error = peer.create_client(address, port)
    if error != OK:
        push_error("Join failed: %s" % error_string(error))
        connection_failed.emit()
        return
    multiplayer.multiplayer_peer = peer
    print("Joining %s:%d..." % [address, port])


func disconnect_from_game() -> void:
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer = null
    peer = ENetMultiplayerPeer.new()


func _on_peer_connected(id: int) -> void:
    print("Peer connected: %d" % id)


func _on_peer_disconnected(id: int) -> void:
    print("Peer disconnected: %d" % id)
    player_disconnected.emit(id)


func _on_connected_to_server() -> void:
    print("Connected to server. My ID: %d" % multiplayer.get_unique_id())
    joined_server.emit()


func _on_connection_failed() -> void:
    push_error("Connection failed.")
    multiplayer.multiplayer_peer = null
    connection_failed.emit()


func _on_server_disconnected() -> void:
    print("Server disconnected.")
    multiplayer.multiplayer_peer = null
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

### main_menu.gd

```gdscript
extends Control

@onready var address_input: LineEdit = $VBox/AddressInput
@onready var port_input: LineEdit = $VBox/PortInput
@onready var name_input: LineEdit = $VBox/NameInput
@onready var status_label: Label = $VBox/StatusLabel


func _ready() -> void:
    NetworkManager.server_created.connect(_on_server_created)
    NetworkManager.joined_server.connect(_on_joined_server)
    NetworkManager.connection_failed.connect(_on_connection_failed)
    address_input.text = "127.0.0.1"
    port_input.text = "7777"
    name_input.text = "Player%d" % randi_range(100, 999)


func _on_host_pressed() -> void:
    if name_input.text.strip_edges().is_empty():
        status_label.text = "Enter a name first."
        return
    var port: int = int(port_input.text)
    NetworkManager.host(port)


func _on_join_pressed() -> void:
    if name_input.text.strip_edges().is_empty():
        status_label.text = "Enter a name first."
        return
    var address: String = address_input.text.strip_edges()
    var port: int = int(port_input.text)
    NetworkManager.join(address, port)
    status_label.text = "Connecting..."


func _on_server_created() -> void:
    # Store the player name somewhere accessible — a simple autoload works
    PlayerData.local_name = name_input.text.strip_edges()
    get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_joined_server() -> void:
    PlayerData.local_name = name_input.text.strip_edges()
    get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_connection_failed() -> void:
    status_label.text = "Connection failed. Check address and port."
```

### player.gd

```gdscript
extends CharacterBody3D

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 6.0
const ATTACK_RANGE: float = 2.0
const ATTACK_DAMAGE: int = 20
const ATTACK_COOLDOWN: float = 0.5

@export var player_name: String = ""
@export var health: int = 100
@export var kills: int = 0

@onready var name_label: Label3D = $Label3D
@onready var attack_area: Area3D = $AttackArea
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

var _attack_timer: float = 0.0

const GRAVITY: float = 9.8


func _ready() -> void:
    # Set name label for all peers (it syncs via MultiplayerSynchronizer)
    name_label.text = player_name

    if is_multiplayer_authority():
        # Set up camera for local player
        var camera: Camera3D = Camera3D.new()
        camera.position = Vector3(0, 2, 5)
        camera.rotation_degrees.x = -15.0
        add_child(camera)
        camera.make_current()


func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        # Remote player — just update label if name changed
        name_label.text = player_name
        return

    # Gravity
    if not is_on_floor():
        velocity.y -= GRAVITY * delta

    # Jump
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Movement
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction: Vector3 = (
        transform.basis * Vector3(input_dir.x, 0, input_dir.y)
    ).normalized()

    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()

    # Attack cooldown
    _attack_timer -= delta
    if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0:
        _attack_timer = ATTACK_COOLDOWN
        _try_attack()


func _try_attack() -> void:
    # Find players in attack range
    for body: Node3D in attack_area.get_overlapping_bodies():
        if body == self:
            continue
        if body is CharacterBody3D:
            # Send attack RPC to server for validation
            request_attack.rpc_id(1, body.get_path())


@rpc("any_peer", "call_remote", "reliable")
func request_attack(target_path: NodePath) -> void:
    if not multiplayer.is_server():
        return

    var attacker_id: int = multiplayer.get_remote_sender_id()
    var attacker: CharacterBody3D = get_node_or_null(
        "/root/Arena/Players/" + str(attacker_id)
    )
    var target: CharacterBody3D = get_node_or_null(target_path)

    if attacker == null or target == null:
        return

    if attacker.health <= 0:
        return

    # Validate range server-side
    if attacker.global_position.distance_to(target.global_position) > ATTACK_RANGE * 1.5:
        return  # Out of range — reject

    # Apply damage (this RPC runs on all clients via authority=server)
    target.apply_damage.rpc(ATTACK_DAMAGE, attacker_id)


@rpc("authority", "call_local", "reliable")
func apply_damage(amount: int, attacker_id: int) -> void:
    health -= amount
    health = max(0, health)

    if health <= 0 and multiplayer.is_server():
        # Award kill to attacker
        var attacker: CharacterBody3D = get_node_or_null(
            "/root/Arena/Players/" + str(attacker_id)
        )
        if attacker:
            attacker.kills += 1
        _respawn.rpc_id(multiplayer.get_unique_id() if is_multiplayer_authority() else int(name))


@rpc("authority", "call_local", "reliable")
func _respawn() -> void:
    health = 100
    # Teleport to a spawn point
    var spawn_points: Node = get_node("/root/Arena/SpawnPoints")
    if spawn_points and spawn_points.get_child_count() > 0:
        var idx: int = randi() % spawn_points.get_child_count()
        global_position = spawn_points.get_child(idx).global_position
```

### arena.gd (Game Manager)

```gdscript
extends Node

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_node: Node3D = $Players
@onready var spawn_points: Node3D = $SpawnPoints

var _player_scene: PackedScene = preload("res://scenes/player.tscn")


func _ready() -> void:
    if not multiplayer.is_server():
        return

    # Spawn all currently connected peers (including server/host)
    _spawn_player(1)  # Host
    for peer_id: int in multiplayer.get_peers():
        _spawn_player(peer_id)

    # Spawn future joiners
    multiplayer.peer_connected.connect(_spawn_player)
    multiplayer.peer_disconnected.connect(_despawn_player)


func _spawn_player(peer_id: int) -> void:
    if not multiplayer.is_server():
        return

    if players_node.get_node_or_null(str(peer_id)) != null:
        return  # Already spawned

    var player: CharacterBody3D = _player_scene.instantiate()
    player.name = str(peer_id)

    # Pick a spawn point
    var sp_count: int = spawn_points.get_child_count()
    var idx: int = (peer_id - 1) % max(sp_count, 1)
    if sp_count > 0:
        player.position = spawn_points.get_child(idx).global_position

    # Set player name from lobby data if available
    # In a full game you'd read from LobbyData resource
    player.player_name = "Player %d" % peer_id

    players_node.add_child(player)
    player.set_multiplayer_authority(peer_id)


func _despawn_player(peer_id: int) -> void:
    if not multiplayer.is_server():
        return

    var player: Node = players_node.get_node_or_null(str(peer_id))
    if player:
        player.queue_free()
```

### MultiplayerSynchronizer Config for player.tscn

In the inspector for `MultiplayerSynchronizer` inside `player.tscn`, add these to the Replication Config:

| Property Path | Sync | Spawn |
|---|---|---|
| `CharacterBody3D:position` | Yes | Yes |
| `CharacterBody3D:rotation` | Yes | Yes |
| `CharacterBody3D:velocity` | Yes | No |
| `CharacterBody3D:player_name` | No | Yes |
| `CharacterBody3D:health` | Yes | Yes |
| `CharacterBody3D:kills` | Yes | Yes |

Set the synchronizer's **Replication Interval** to `0.05` (20 Hz) for a balance of smoothness and bandwidth.

### HUD / Scoreboard

```gdscript
# hud.gd
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var scoreboard: VBoxContainer = $Scoreboard

var _local_player: CharacterBody3D = null


func _process(_delta: float) -> void:
    _update_health()
    _update_scoreboard()


func _update_health() -> void:
    if _local_player == null:
        _local_player = _find_local_player()
    if _local_player:
        health_bar.value = _local_player.health


func _find_local_player() -> CharacterBody3D:
    var my_id: int = multiplayer.get_unique_id()
    var players: Node = get_node_or_null("/root/Arena/Players")
    if players:
        return players.get_node_or_null(str(my_id)) as CharacterBody3D
    return null


func _update_scoreboard() -> void:
    # Clear and rebuild scoreboard entries
    for child in scoreboard.get_children():
        child.queue_free()

    var players: Node = get_node_or_null("/root/Arena/Players")
    if players == null:
        return

    var player_list: Array[Node] = players.get_children()
    # Sort by kills descending
    player_list.sort_custom(func(a, b): return a.kills > b.kills)

    for player: Node in player_list:
        var label: Label = Label.new()
        label.text = "%s — Kills: %d  HP: %d" % [
            player.player_name,
            player.kills,
            player.health,
        ]
        scoreboard.add_child(label)
```

---

## API Quick Reference

| Class / Property | Type | Description |
|---|---|---|
| `multiplayer` | `MultiplayerAPI` | The scene tree's multiplayer interface (access from any node) |
| `multiplayer.get_unique_id()` | `int` | Your peer ID (1 = server) |
| `multiplayer.is_server()` | `bool` | True if this peer is the server |
| `multiplayer.get_peers()` | `Array[int]` | All connected peer IDs (excluding self) |
| `multiplayer.get_remote_sender_id()` | `int` | Inside an RPC: who called it (0 = local) |
| `multiplayer.multiplayer_peer` | `MultiplayerPeer` | Assign to enable networking |
| `ENetMultiplayerPeer` | Class | UDP-based transport (most common) |
| `.create_server(port, max)` | `Error` | Start a server |
| `.create_client(address, port)` | `Error` | Connect to a server |
| `@rpc(mode, sync, transfer, ch)` | Annotation | Mark a method as callable remotely |
| `.rpc(args...)` | Method | Call RPC on all peers |
| `.rpc_id(id, args...)` | Method | Call RPC on specific peer |
| `MultiplayerSpawner` | Node | Auto-spawns/despawns registered scenes |
| `MultiplayerSynchronizer` | Node | Auto-syncs properties to all peers |
| `set_multiplayer_authority(id)` | Method | Set which peer owns a node |
| `is_multiplayer_authority()` | Method | True if local peer owns this node |
| `SceneReplicationConfig` | Resource | Config for MultiplayerSynchronizer |
| `multiplayer.peer_connected` | Signal | New peer joined |
| `multiplayer.peer_disconnected` | Signal | Peer left |
| `multiplayer.connected_to_server` | Signal | Client: connected successfully |
| `multiplayer.connection_failed` | Signal | Client: failed to connect |
| `multiplayer.server_disconnected` | Signal | Client: server went away |

---

## Common Pitfalls

### 1. Running game logic on all peers instead of just the server

WRONG:
```gdscript
func _on_player_died(peer_id: int) -> void:
    # This runs on every peer — causes duplicate respawns, race conditions
    respawn_player(peer_id)
```

RIGHT:
```gdscript
func _on_player_died(peer_id: int) -> void:
    if not multiplayer.is_server():
        return  # Only the server manages game state
    respawn_player(peer_id)
```

---

### 2. Not checking authority before processing input

WRONG:
```gdscript
func _physics_process(delta: float) -> void:
    # Every peer processes input for every player node — chaos
    var dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    velocity = Vector3(dir.x, 0, dir.y) * SPEED
    move_and_slide()
```

RIGHT:
```gdscript
func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        return  # Not my character — don't touch it
    var dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    velocity = Vector3(dir.x, 0, dir.y) * SPEED
    move_and_slide()
```

---

### 3. Forgetting to name spawned nodes consistently

WRONG:
```gdscript
func _spawn_player(peer_id: int) -> void:
    var player: Node = player_scene.instantiate()
    # Name is auto-assigned — "Player", "Player2", etc. — breaks MultiplayerSynchronizer
    players.add_child(player)
```

RIGHT:
```gdscript
func _spawn_player(peer_id: int) -> void:
    var player: Node = player_scene.instantiate()
    player.name = str(peer_id)  # Deterministic, matches peer ID
    players.add_child(player)
    player.set_multiplayer_authority(peer_id)
```

---

### 4. Trusting RPC arguments from clients for game-critical values

WRONG:
```gdscript
@rpc("any_peer", "call_remote", "reliable")
func deal_damage(target_id: int, amount: int) -> void:
    # Client-supplied `amount` — anyone can send 99999
    get_player(target_id).health -= amount
```

RIGHT:
```gdscript
@rpc("any_peer", "call_remote", "reliable")
func request_attack(target_id: int) -> void:
    if not multiplayer.is_server():
        return
    var attacker_id: int = multiplayer.get_remote_sender_id()
    # Server calculates damage from its own authoritative stats
    var damage: int = get_player(attacker_id).get_stat("attack_power")
    get_player(target_id).health -= damage
```

---

### 5. Using reliable transfer mode for position updates

WRONG:
```gdscript
@rpc("any_peer", "call_local", "reliable")  # Reliable for positions = head-of-line blocking
func sync_position(pos: Vector3) -> void:
    global_position = pos
```

RIGHT:
```gdscript
@rpc("any_peer", "call_local", "unreliable_ordered")  # Old packets drop — that's fine
func sync_position(pos: Vector3) -> void:
    global_position = pos
```

---

### 6. Calling RPCs before multiplayer_peer is assigned

WRONG:
```gdscript
func _ready() -> void:
    # multiplayer_peer not set yet — RPC runs locally only, silently
    announce_join.rpc(player_name)
```

RIGHT:
```gdscript
func _ready() -> void:
    # Wait until connected_to_server fires (for client) or after create_server (for host)
    if multiplayer.is_server():
        _on_ready_to_announce()
    else:
        multiplayer.connected_to_server.connect(_on_ready_to_announce)


func _on_ready_to_announce() -> void:
    announce_join.rpc(player_name)
```

---

## Exercises

### Exercise 1: Basic Host/Join

Create a two-scene project: `main_menu.tscn` and `world.tscn`. In the main menu, add a Host button and a Join button (with an IP field). Wire them up using `ENetMultiplayerPeer`. When connected, change to the world scene and print all peer IDs to the screen in a Label.

**Stretch goal**: Display each peer's ID and connection time in a scrolling list. Update it live when peers join/leave.

---

### Exercise 2: Synchronized Cubes

In a world scene, add a `MultiplayerSpawner` and a `Players` node. When a peer connects, spawn a `MeshInstance3D` (cube) for them under `Players`. Attach a `MultiplayerSynchronizer` to sync the cube's position. Let the authoritative peer move their cube with WASD. All other peers should see it move.

**Stretch goal**: Add a color `@export` variable. Let each player pick a color in the lobby; sync the color on spawn and render it as the cube's material color.

---

### Exercise 3: Server-Authoritative Combat

Extend Exercise 2 into a combat demo. Add health to each cube. Implement a "bump" mechanic: when two cubes overlap (use `Area3D`), the touching peer sends a `request_hit` RPC to the server. The server validates proximity, deducts health, and broadcasts the updated health to all peers. Display each cube's health as a `Label3D` above it.

**Stretch goal**: Add a respawn timer. When a cube's health reaches 0, it becomes invisible and a `Label3D` counts down 3 seconds before it respawns at a random spawn point with full health.

---

### Exercise 4: Full Lobby Flow

Build a complete lobby system. Features required:
- Player name entry
- Player list showing all connected peers and their ready state
- A "Ready" toggle button (syncs to all clients via RPC)
- A "Start Game" button (host only, enabled only when all players are ready)
- Graceful handling of players leaving the lobby
- Transition to the arena scene when the host starts the game

**Stretch goal**: Add a minimum player count check (require at least 2 players before the Start button activates). Display a "Waiting for players..." message when below the minimum.

---

## Recommended Reading

| Resource | Description |
|---|---|
| [Godot Docs: High-level multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) | Official overview of MultiplayerAPI, ENet, RPCs |
| [Godot Docs: @rpc annotation](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-rpc) | Full reference for RPC modes and transfer types |
| [Godot Docs: MultiplayerSpawner](https://docs.godotengine.org/en/stable/classes/class_multiplayerspawner.html) | Spawner class reference |
| [Godot Docs: MultiplayerSynchronizer](https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html) | Synchronizer class reference and visibility filters |
| [Godot Docs: ENetMultiplayerPeer](https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html) | Low-level ENet config options |
| [Gabriel Gambetta: Fast-Paced Multiplayer](https://www.gabrielgambetta.com/client-server-game-architecture.html) | The definitive guide to client-side prediction and lag compensation |
| [Valve Developer Wiki: Source Multiplayer Networking](https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking) | Deep dive on interpolation, prediction, and lag compensation concepts |
| [Godot Docs: WebSocketMultiplayerPeer](https://docs.godotengine.org/en/stable/classes/class_websocketmultiplayerpeer.html) | Browser-compatible transport for web exports |

---

## Key Takeaways

- The server always has peer ID `1`. Clients get IDs `2+`. Use `multiplayer.get_unique_id()` and `multiplayer.is_server()` constantly — they are your compass.
- Authority is per-node, not per-peer. Transfer it to clients for their own characters so `MultiplayerSynchronizer` sends the right direction.
- `@rpc` modes are not optional choices — `unreliable` for continuous data (position, rotation), `reliable` for events (damage, death, chat). Mixing them up causes stuttering or dropped events.
- `MultiplayerSpawner` + `MultiplayerSynchronizer` handle 80% of what most games need. Learn them well before reaching for raw RPC calls.
- The server validates everything. Clients are untrusted by design. Check `get_remote_sender_id()` in every RPC that modifies game state.
- Client-side prediction is an optimization, not a requirement. Start with server-authoritative movement (input RPCs → server moves → sync back). Add prediction only if the latency is unacceptable.
- Node naming is critical for multiplayer. Spawned nodes must have deterministic, consistent names (peer ID is the standard pattern) — the network layer uses paths to identify nodes.
- Handling disconnects gracefully is not optional for a shipped game. Connect to `peer_disconnected` and `server_disconnected` on day one; don't leave it for later.
- ENet is UDP-based. NAT traversal and port forwarding are real user problems. For production games, use a relay/matchmaking service to avoid asking users to configure their routers.
- Bandwidth compounds fast with many players. Set realistic `MultiplayerSynchronizer` intervals (20 Hz is usually plenty), use visibility filters for large worlds, and profile early.

---

## What's Next

**[Module 13: Ship & What's Next](module-13-ship-whats-next.md)** — Write your first vertex and fragment shaders in Godot's shader language, build a water surface, add post-processing effects with `WorldEnvironment` and `CompositorEffect`, and understand the rendering pipeline well enough to diagnose visual bugs.
