# Multiplayer Networking Domain Map

A curated vocabulary reference for multiplayer game networking. Use these terms to prompt AI tools with specificity — each entry includes a plain-language definition and an example prompt showing the term in context.

**How to use this page:** Scan the branch that matches your networking problem. Grab the precise term, drop it into your prompt, and get better results than vague descriptions ever produce.

---

## Network Architecture

How multiplayer games are structured at a high level.

### Topology & Authority

Who runs the simulation, who trusts whom, and how machines are connected.

- **Client-Server** — One machine (the server) runs the authoritative simulation. All other machines (clients) send input and receive state. The dominant model for competitive multiplayer because the server is the single source of truth.
  *"Implement a client-server architecture in Godot 4 where the server validates all player movement and the client only sends input vectors."*

- **Peer-to-Peer** — Every player's machine communicates directly with every other. No central server. Simple to set up but hard to secure — every peer has full game state and can cheat freely.
  *"Design a peer-to-peer networking layer for a 2-player fighting game using GGPO-style rollback."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=peer+to+peer+vs+client+server+game+networking+diagram)

- **Authoritative Server** — The server's word is final. Clients can predict locally, but the server resolves all conflicts. If the client says "I'm at position X" and the server disagrees, the server wins.
  *"Add server authority to my multiplayer shooter so the server validates hit detection rather than trusting client hit reports."*

- **Host Migration** — When the player acting as server disconnects, another player takes over as host without ending the session. Essential for listen-server games where any player could quit.
  *"Implement host migration for my 4-player co-op game so the session survives if the host drops."*

- **Dedicated Server** — A standalone server process with no local player. Runs headless (no rendering), often in a data center. The gold standard for competitive games because it's neutral territory.
  *"Set up a dedicated server build of my Unity game that runs headless on a Linux VM with no GPU."*

- **Listen Server** — One player's machine acts as both client and server. That player gets zero latency, everyone else doesn't. Common in casual or co-op games where fairness matters less.
  *"Convert my single-player game to multiplayer using a listen-server model where the host player also plays locally."*

- **Relay Server** — A server that forwards packets between players without running game logic. Solves NAT traversal problems and hides player IP addresses. Adds latency but simplifies connectivity.
  *"Route all player traffic through a relay server so players behind strict NATs can connect without port forwarding."*

- **Headless Server** — A server build stripped of rendering, audio, and input — pure simulation. Uses far fewer resources than a full game client, so you can run many instances per machine.
  *"Create a headless server build of my Love2D game that runs the physics simulation without loading any sprites or audio."*

- **Mesh Topology** — Every peer connects to every other peer directly. Bandwidth scales quadratically with player count, which limits it to small player counts (typically 2-8).
  *"Explain why mesh topology breaks down beyond 8 players and how to transition to a client-server model at that threshold."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=mesh+topology+vs+star+topology+network+diagram)

- **Hybrid Topology** — Mixes architectures — for example, a central server for game state but peer-to-peer for voice chat. Lets you pick the right model for each type of data.
  *"Design a hybrid topology where game state runs client-server but voice chat uses peer-to-peer to reduce server bandwidth."*

### Session Management

How players find each other and get into the same game.

- **Lobby** — A waiting area where players gather before a match starts. Can be a UI screen or a lightweight server state. The host or system starts the game when conditions are met.
  *"Build a lobby system that shows connected players, their readiness status, and a countdown timer when all players are ready."*

- **Matchmaking** — The system that groups players into sessions based on criteria like skill, latency, and party size. Good matchmaking is invisible — bad matchmaking is the first thing players notice.
  *"Design a matchmaking algorithm that balances teams by MMR while keeping average queue time under 60 seconds."*

- **Session** — A single instance of a multiplayer game from start to finish. Has a lifecycle: created, joinable, in-progress, completed. Tracks who's in it and what state it's in.
  *"Implement session lifecycle management so sessions clean up their resources when the last player disconnects."*

- **Room** — A named or numbered container for a group of players. Often synonymous with session, but can also mean a subdivision of a larger world (chat rooms, dungeon instances).
  *"Create a room-based system where players can browse available rooms, see player counts, and join or create new ones."*

- **Party** — A persistent group of players that stays together across sessions. The party queues as a unit and gets placed into the same team or session.
  *"Implement a party system where up to 4 friends can group up and matchmake together into squad-based matches."*

- **Backfill** — Dropping a new player into a session that's already in progress to replace someone who left. Keeps matches full but needs careful handling so the new player isn't hopelessly behind.
  *"Add backfill logic to my team deathmatch mode that finds replacement players when someone disconnects mid-match."*

- **Skill-Based Matchmaking (SBMM)** — Matchmaking that prioritizes pairing players of similar skill. Uses rating systems like Elo, Glicko, or TrueSkill. Controversial because it can make every match feel sweaty.
  *"Implement an SBMM system using Glicko-2 ratings that also factors in connection quality to avoid high-ping matches."*

- **Queueing** — The system that holds players in line while matchmaking searches for a valid session. Manages wait times, queue position, and estimated time displays.
  *"Build a queue system that shows estimated wait time and lets players cancel without penalty during the first 30 seconds."*

- **Region Selection** — Letting players choose which geographic server region to connect to, or auto-selecting based on lowest ping. Directly affects latency and player pool size.
  *"Add region selection with auto-detect that pings each region on launch and recommends the lowest-latency option."*

- **Crossplay** — Allowing players on different platforms (PC, console, mobile) to play together. Requires platform-agnostic account systems and careful input-fairness considerations.
  *"Implement crossplay between PC and console builds with an option to opt out of cross-input matchmaking."*

---

## Synchronization

How game state stays consistent across players.

### State Replication

Getting the right data to the right players at the right time.

- **Replication** — The process of copying game state from the server to clients. Not everything gets replicated — only what each client needs to know. The core job of any netcode system.
  *"Set up replication for my multiplayer RPG so that player health, position, and equipped weapon sync to all nearby clients."*

- **Serialization** — Converting game objects into a byte stream for transmission, then reconstructing them on the other end. Efficient serialization is the difference between 10 bytes and 200 bytes per entity per tick.
  *"Write a custom serializer for my entity state that packs position as two 16-bit fixed-point values instead of two 32-bit floats."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=network+serialization+binary+format+diagram)

- **Delta Compression** — Only sending what changed since the last update instead of the full state. If a player's health didn't change, don't send it. Dramatically reduces bandwidth.
  *"Implement delta compression for my world state snapshots so the server only sends changed entity properties each tick."*

- **Snapshot** — A complete capture of the game state at a single point in time. The server takes snapshots at the tick rate and sends them (or deltas of them) to clients.
  *"Build a snapshot system that captures all entity positions and states at 20 Hz and interpolates between them on the client."*

- **State Interpolation** — Smoothly blending between two received snapshots on the client so movement looks fluid despite discrete network updates. The client is always rendering slightly in the past.
  *"Add state interpolation to my networked entities so they move smoothly between server snapshots instead of teleporting."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=network+state+interpolation+game+diagram)

- **Eventual Consistency** — Accepting that different clients may briefly see different states, trusting that they'll converge. Practical for non-critical data like particle effects or ambient NPC behavior.
  *"Use eventual consistency for cosmetic effects like weather particles — don't waste bandwidth keeping them perfectly synced."*

- **World State** — The complete set of all game data at a given moment: every entity position, health value, timer, and flag. The thing you're trying to keep consistent across all players.
  *"Calculate the size of my world state per tick for 100 entities with position, rotation, health, and status flags."*

- **Relevancy** — Rules that determine which entities a client needs to know about. A player on the east side of the map doesn't need updates about entities on the west side.
  *"Implement a relevancy system that only replicates entities within 200 units of each player to reduce bandwidth."*

- **Interest Management** — A broader system for controlling what data each client receives, often based on spatial proximity, team membership, or game phase. Relevancy is one aspect of interest management.
  *"Design an interest management system for my battle royale that expands each player's area of interest as the circle shrinks."*

- **Area of Interest (AOI)** — The spatial region around a player within which entities are replicated. Typically a circle or grid-based zone. Entities outside the AOI simply don't exist for that client.
  *"Set up grid-based area-of-interest zones so the server only sends entity data for the 9 cells surrounding each player."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=area+of+interest+mmo+networking+grid)

### Prediction & Compensation

Making the game feel responsive despite network delay.

- **Client-Side Prediction** — The client immediately applies the player's input locally without waiting for the server. Makes the game feel responsive at the cost of occasional corrections when the server disagrees.
  *"Implement client-side prediction for player movement so inputs feel instant even on 100ms connections."*

- **Server Reconciliation** — When the server's authoritative state arrives and disagrees with the client's prediction, the client rewinds to the server state and replays all unacknowledged inputs. Corrects mispredictions without visible snapping.
  *"Add server reconciliation to my predicted movement so corrections smoothly re-simulate rather than teleporting the player."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=client+side+prediction+server+reconciliation+diagram)

- **Lag Compensation** — The server rewinds time to evaluate actions from a player's perspective at the moment they acted, accounting for their latency. This is why you can get shot around corners.
  *"Implement lag compensation for hit detection so the server rewinds entity positions to match where they were when the shooter fired."*

- **Rollback** — Rewinding the game state to a past frame and resimulating forward with corrected inputs. The foundation of rollback netcode used in fighting games. Allows responsive gameplay without waiting for remote inputs.
  *"Implement rollback netcode for my 2D fighting game that resimulates up to 7 frames when late inputs arrive."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=rollback+netcode+fighting+game+diagram)

- **Input Delay** — Intentionally delaying local input processing by a few frames so remote inputs have time to arrive. The alternative to rollback — simpler but makes the game feel sluggish at high values.
  *"Compare 3 frames of input delay vs. rollback for my fighting game prototype. At what latency does input delay become unacceptable?"*

- **Lockstep** — All clients must receive all inputs for a frame before any client can advance to the next frame. Guarantees perfect sync but any player's lag affects everyone. Used in classic RTS games.
  *"Implement deterministic lockstep for my RTS where all clients simulate identically from the same input stream."*

- **Dead Reckoning** — Predicting where a remote entity will be based on its last known position, velocity, and acceleration. When a real update arrives, blend toward the corrected position.
  *"Add dead reckoning to remote players in my racing game so they coast smoothly during packet gaps instead of freezing."*

- **Extrapolation** — Projecting an entity's future position beyond the latest received data. Riskier than interpolation because you're guessing where something will be, and you can guess wrong.
  *"Use extrapolation for fast-moving projectiles between network updates, then snap to the authoritative position when it arrives."*

- **Rubber-Banding** — The visible artifact of a correction: a player snaps backward to where the server says they actually are. The symptom of prediction disagreement, usually caused by high latency or lost packets.
  *"Reduce rubber-banding in my game by blending corrections over 100ms instead of snapping instantly to the server position."*

- **Desync** — When two machines disagree about the game state and can't converge. Fatal in lockstep games. In client-server games, the server is always right so desyncs manifest as corrections rather than divergence.
  *"Add a desync detection system to my lockstep RTS that checksums game state each frame and alerts when clients diverge."*

---

## Transport & Protocol

The nuts and bolts of sending data over the wire.

### Protocols & Delivery

How packets get from A to B and what guarantees they carry.

- **UDP** — User Datagram Protocol. Fire-and-forget — no delivery guarantees, no ordering, no connection state. Fast and lightweight. The foundation of most real-time game networking because stale data is worse than no data.
  *"Set up a UDP socket in my game server that receives player inputs and broadcasts state snapshots without the overhead of TCP."*

- **TCP** — Transmission Control Protocol. Guarantees delivery and ordering but blocks on lost packets (head-of-line blocking). Fine for login, chat, and menus — terrible for real-time gameplay.
  *"Use TCP for my game's login flow, friend list, and chat system while keeping gameplay traffic on UDP."*

- **Reliable UDP** — A custom layer built on top of UDP that adds selective reliability: you choose which messages must arrive (ability activations) and which can be dropped (position updates). Best of both worlds.
  *"Implement reliable UDP with sequence numbers and acknowledgments so ability casts always arrive but position updates can be dropped."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=reliable+UDP+game+networking+packet+diagram)

- **Packet** — A single unit of data sent over the network. Has a header (metadata) and payload (your game data). Keeping packets under the MTU avoids fragmentation.
  *"Structure my game packets with a 4-byte header containing sequence number, ack, and message type, followed by the payload."*

- **MTU** — Maximum Transmission Unit. The largest packet size the network can carry without fragmenting — typically 1200-1400 bytes for internet traffic. Exceeding it causes fragmentation and increased packet loss.
  *"Keep my game packets under 1200 bytes MTU to avoid fragmentation issues on player connections with unusual network configs."*

- **NAT Punch-Through** — A technique to establish direct peer-to-peer connections between players behind NAT routers. Both sides send packets to a known third-party server, which tells each peer the other's external address.
  *"Implement UDP hole punching via a STUN server so players behind NAT can connect peer-to-peer without port forwarding."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=NAT+punch+through+hole+punching+diagram)

- **WebSocket** — A persistent, full-duplex TCP connection between browser and server. Built on HTTP upgrade. The go-to for browser-based multiplayer, though it inherits TCP's head-of-line blocking.
  *"Build a WebSocket game server in Node.js that handles player connections, input messages, and state broadcasts for a browser game."*

- **WebRTC** — A browser API for real-time peer-to-peer communication, originally designed for video calls. Its data channels support unreliable/unordered delivery, making it the closest thing to UDP in a browser.
  *"Use WebRTC data channels for my browser-based multiplayer game to get UDP-like unreliable delivery without a plugin."*

- **QUIC** — A modern transport protocol built on UDP that provides multiplexed streams without head-of-line blocking. Faster connection setup than TCP. Used by HTTP/3 and increasingly relevant for game networking.
  *"Evaluate QUIC as a transport for my game server — would multiplexed streams help separate chat, state, and voice traffic?"*

- **Protocol Buffer (Protobuf)** — A binary serialization format from Google. You define message schemas in .proto files and generate code for any language. Compact and fast, widely used for game network messages.
  *"Define my game's network messages as Protocol Buffers with fields for entity ID, position, velocity, and action enum."*

### Bandwidth & Optimization

Making the most of limited network capacity.

- **Tick Rate** — How many times per second the server updates the simulation. A 64-tick server simulates 64 times per second. Higher tick rate means more accurate simulation but more CPU and bandwidth cost.
  *"Compare 20-tick vs. 64-tick server performance for my shooter. What's the minimum tick rate where hit registration feels fair?"*

- **Send Rate** — How many times per second the server sends state updates to clients. Can be lower than the tick rate — a server might simulate at 64 Hz but only send updates at 20 Hz to save bandwidth.
  *"Run my server simulation at 60 Hz but cap the network send rate to 20 Hz with interpolation to reduce bandwidth usage."*

- **Bandwidth Budget** — The maximum bits per second you're willing to spend on network traffic per client. Typically 10-50 kbps for a competitive shooter. Everything else is engineering within that constraint.
  *"Calculate my bandwidth budget: 32 players, each getting updates for up to 20 relevant entities at 20 Hz. How many bytes per entity can I afford?"*

- **Packet Loss** — When packets fail to arrive at their destination. Happens constantly on the internet — 1-3% is normal. Game networking must handle it gracefully because it will always happen.
  *"Simulate 5% packet loss in my netcode test environment and verify that my game degrades gracefully without freezing."*

- **Jitter** — Variation in packet arrival times. A packet might take 20ms one tick and 80ms the next. Jitter buffers smooth this out at the cost of added latency.
  *"Add a jitter buffer that holds incoming packets for 2 ticks to smooth out arrival time variation before applying them."*

- **Latency** — The time it takes for data to travel from one machine to another, measured one way. Often estimated as half the round-trip time. The fundamental constraint of all networked games.
  *"Profile my netcode to separate true network latency from server processing time and client-side rendering delay."*

- **RTT (Round-Trip Time)** — The time for a packet to go from client to server and back. The most commonly measured network metric. Typically 20-100ms on good connections, 200ms+ on bad ones.
  *"Display the player's current RTT in the debug HUD and warn when it exceeds 150ms."*

- **Compression** — Reducing the size of network data before sending it. Can be general-purpose (zlib) or game-specific (quantizing floats, bit-packing enums). Every byte saved is bandwidth reclaimed.
  *"Compress my network packets by quantizing float positions to 16-bit fixed-point and bit-packing boolean flags."*

- **Batching** — Collecting multiple small messages into a single packet before sending. Reduces per-packet overhead (headers, syscalls) and improves throughput. Send one fat packet instead of twenty tiny ones.
  *"Batch all entity updates for a single tick into one packet per client instead of sending individual messages per entity."*

- **Priority Queue** — Ranking network messages by importance so the most critical data gets sent first when bandwidth is limited. Player actions matter more than distant NPC animations.
  *"Implement a priority queue that sends local-player corrections at highest priority, nearby players at medium, and distant entities only when bandwidth allows."*

---

## Multiplayer Game Systems

Game-level features built on top of networking.

### Player Interaction

How players communicate, observe, and affect each other.

- **RPC (Remote Procedure Call)** — Calling a function on a remote machine. The client calls "fire weapon" and it executes on the server. The most common abstraction for networked game actions in engines like Unity and Godot.
  *"Use RPCs to send ability activations from client to server, and server-to-all-clients RPCs to broadcast the resulting effects."*

- **Remote Procedure Call** — The full name for RPC. A request from one machine to execute a function on another. Can be client-to-server, server-to-client, or server-to-all. The backbone of high-level netcode APIs.
  *"Define server RPCs for all game-changing actions (attack, use item, interact) and client RPCs for visual-only feedback (particles, sound cues)."*

- **Voice Chat** — Real-time audio communication between players. Usually runs on a separate channel from game data (often peer-to-peer or via a voice service like Vivox). Needs echo cancellation and noise suppression.
  *"Integrate proximity-based voice chat where volume attenuates with in-game distance between players."*

- **Text Chat** — Player-to-player text messaging. Needs content filtering, flood protection, and channel management (global, team, whisper). Runs over TCP/reliable since every message must arrive.
  *"Build a text chat system with team, all, and whisper channels, plus a profanity filter and 1-second flood cooldown."*

- **Emote** — A predefined animation or message a player can trigger to express themselves nonverbally. Dances, waves, taunts. Social glue in multiplayer games.
  *"Add a radial emote wheel with 8 slots that triggers a synced animation visible to all nearby players."*

- **Spectator Mode** — Allowing a player to watch a game without participating. Needs a separate camera system and potentially delayed data to prevent ghosting (feeding info to active players).
  *"Implement spectator mode with free camera and player-follow views, delayed by 30 seconds in competitive matches to prevent ghosting."*

- **Replay System** — Recording and replaying matches. Can store inputs (for deterministic games) or state snapshots (for non-deterministic ones). Requires a stable format that survives game updates.
  *"Build a replay system that records server snapshots and allows playback with a timeline scrubber and free camera."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+replay+system+timeline+UI)

- **Kill Cam** — A short replay showing the victim's death from the killer's perspective. Requires briefly storing recent state history and camera data for each player.
  *"Implement a kill cam that shows the last 5 seconds from the attacker's viewpoint using buffered position and aim data."*

- **Player List** — A UI showing all connected players, their scores, ping, team, and status. Needs to update in real-time as players join, leave, and score.
  *"Build a scoreboard that shows player name, kills, deaths, assists, and ping, sorted by score and updated every second."*

- **Social Presence** — Showing players when their friends are online, what they're playing, and whether they're joinable. The invisible infrastructure that drives organic session formation.
  *"Integrate social presence so players can see friends' online status, current game mode, and join their session directly from the friends list."*

### Shared World

How large, persistent, or seamless multiplayer worlds are built.

- **Instancing** — Creating multiple copies of the same area so different groups of players can play through it simultaneously without interfering. Dungeons, missions, and story areas are commonly instanced.
  *"Instance my dungeon so each party gets their own copy with independent enemy spawns and loot."*

- **Sharding** — Splitting the entire game world into separate copies (shards) each running independently. Each shard is a complete world with its own player population. The classic MMO approach.
  *"Design a sharding strategy for my MMO that balances population across shards and allows friends to transfer between them."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=mmo+server+sharding+architecture+diagram)

- **Zoning** — Dividing a continuous world into spatial zones, each managed by a different server or process. Players crossing zone boundaries transfer from one server to another.
  *"Implement zone-based world partitioning where each 1km x 1km zone runs on its own server process with overlap regions for smooth handoff."*

- **Seamless World** — A world with no loading screens between areas. Players move continuously while the game streams content and transitions server authority behind the scenes.
  *"Design a seamless open world where zone transitions happen invisibly to the player — no loading screens, no visible pop-in."*

- **Phasing** — Showing different versions of the same area to different players based on their quest progress or game state. Two players can stand in the same spot and see different things.
  *"Use phasing so players who've completed the village-burning quest see ruins, while others still see the intact village."*

- **Server Meshing** — Dynamically distributing a single continuous world across multiple servers, with entities handed off seamlessly between them. The holy grail of MMO architecture, notoriously hard to implement.
  *"Explain the challenges of server meshing: entity handoff, cross-server physics, and how to handle players on boundaries between servers."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=server+meshing+mmo+architecture+diagram)

- **Mega-Server** — A single logical server that holds all players in one world, dynamically spinning up instances or layers to manage load. No choosing shards — everyone's "together" even if distributed behind the scenes.
  *"Design a mega-server system that dynamically layers the world — when a zone exceeds 100 players, spin up a new layer and let friends phase to the same one."*

- **Load Balancing** — Distributing players and computation across servers to prevent any single server from being overwhelmed. Can be spatial (zones), player-based (matchmaking), or dynamic (auto-scaling).
  *"Add load balancing to my game servers so new sessions route to the least-loaded server in the player's preferred region."*

- **Persistence** — Saving game state so it survives server restarts. Player inventories, world changes, building placements. Without persistence, everything resets and nothing matters between sessions.
  *"Implement persistence for my survival game so player bases, chests, and terrain modifications save to a database and survive server restarts."*

- **Hot-Joining** — Allowing a player to join a session that's already in progress. Requires sending the current world state to the new player quickly and cleanly without disrupting the existing simulation.
  *"Support hot-joining in my co-op game by sending new players a compressed world state snapshot when they connect mid-session."*

---

## Security & Operations

Keeping multiplayer games fair and running.

### Anti-Cheat & Trust

How games defend against players who don't play fair.

- **Server Authority** — The server is the only machine whose game state matters. Clients propose actions; the server validates and executes them. The single most important anti-cheat measure — never trust the client.
  *"Enforce server authority by having the server ignore client position updates and instead simulate movement from validated inputs."*

- **Input Validation** — Checking that player inputs are legal before processing them. Is this movement speed possible? Can they fire that fast? Is this action available to them right now? Reject anything suspicious.
  *"Add input validation that rejects movement commands exceeding max speed and fire-rate inputs faster than the weapon's cooldown."*

- **Speed Hack** — A cheat that lets a player move or act faster than intended, often by manipulating the local game clock. Server-side movement validation catches this trivially.
  *"Detect speed hacks by comparing the distance a player claims to have moved against the maximum possible distance for the elapsed server time."*

- **Aimbot** — Software that automatically aims at enemies, giving the cheater perfect accuracy. Hard to detect purely from input data. Statistical analysis of accuracy, reaction time, and snap angles can flag suspicious players.
  *"Implement a statistical aimbot detection system that flags players whose headshot rate and snap-to-target speed exceed human norms."*

- **Wallhack** — A cheat that lets a player see through walls, typically by modifying the game client's rendering. Server-side mitigation: don't send data about enemies the player shouldn't be able to see (occlusion culling on the server).
  *"Prevent wallhacks at the server level by only replicating enemy positions to a client when they're within line of sight or a proximity threshold."*

- **Anti-Cheat** — Software systems designed to detect and prevent cheating. Can run at the kernel level (EAC, BattlEye), at the application level, or server-side through behavior analysis.
  *"Compare server-side anti-cheat approaches (input validation, behavior analysis) vs. client-side anti-cheat (kernel drivers, memory scanning) for my indie game."*

- **Cheat Detection** — Identifying cheaters through automated analysis: statistical anomalies, impossible inputs, modified game files, or flagged memory patterns. Can lead to bans or shadow penalties.
  *"Build a cheat detection pipeline that logs suspicious events server-side and flags accounts whose stats deviate significantly from population norms."*

- **Rate Limiting** — Capping how many actions a player can perform in a given time window. Prevents spam, rapid-fire exploits, and denial-of-service through excessive requests.
  *"Add rate limiting so players can only send 30 inputs per second — anything above that is silently dropped and logged."*

- **Trusted Client** — A client the server trusts to report truthfully. This is almost always a mistake in competitive games. The client is in enemy hands — assume it will lie.
  *"Refactor my netcode to remove trusted-client hit detection and move all damage calculation to the authoritative server."*

- **Obfuscation** — Making the game client harder to reverse-engineer by scrambling code, encrypting packets, or randomizing memory layouts. Slows down cheaters but never stops determined ones.
  *"Obfuscate my network protocol by encrypting packets with a session key and rotating the key every 60 seconds."*

### Infrastructure & DevOps

Running multiplayer games at scale.

- **Fleet Management** — Orchestrating pools of game servers across regions: provisioning, monitoring, scaling, and retiring instances. The ops layer that keeps players connected worldwide.
  *"Set up fleet management with Agones on Kubernetes to automatically provision game server pods as matchmaking demand increases."*

- **Auto-Scaling** — Automatically adding or removing server instances based on player demand. Scale up during peak hours, scale down at night. Saves money without sacrificing availability.
  *"Configure auto-scaling rules that spin up new game servers when average player queue time exceeds 30 seconds and scale down when utilization drops below 20%."*

- **Game Server Hosting** — The infrastructure for running dedicated game servers. Can be self-hosted (VMs, bare metal), managed services (Multiplay, GameLift), or container-based (Kubernetes, Agones).
  *"Compare AWS GameLift vs. self-hosted Kubernetes for hosting 200 concurrent game server instances across 3 regions."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+server+hosting+architecture+cloud+diagram)

- **CDN (Content Delivery Network)** — A distributed network of servers that caches and delivers static content (game patches, assets) from locations close to players. Reduces download times and origin server load.
  *"Distribute game patches through a CDN so players download from the nearest edge server instead of hitting our origin server."*

- **Telemetry** — Collecting data about game performance, player behavior, and server health. Network stats, frame rates, crash reports, and gameplay events. The foundation for informed decisions.
  *"Add telemetry that tracks average RTT, packet loss percentage, and desync events per match, and pipe it to a Grafana dashboard."*

- **Monitoring** — Real-time observation of server health, player counts, error rates, and performance metrics. Dashboards and alerts that tell you something's wrong before players start complaining.
  *"Set up monitoring alerts that fire when server tick rate drops below 90% of target, packet loss exceeds 5%, or player count drops suddenly."*

- **Graceful Shutdown** — Cleanly stopping a game server by finishing the current match, saving state, and disconnecting players with notice — rather than just killing the process and losing everything.
  *"Implement graceful shutdown that warns players 5 minutes before maintenance, saves all persistent state, and migrates active sessions to other servers."*

- **Rolling Update** — Deploying a new server version gradually — a few servers at a time — so the entire fleet is never down simultaneously. Players on old servers finish their matches before those servers update.
  *"Deploy server updates with a rolling strategy that updates 10% of instances at a time, waits for active matches to finish, then proceeds."*

- **Canary Deployment** — Routing a small percentage of players to a new server version to catch bugs before rolling it out fleet-wide. If the canary servers show problems, roll back without affecting most players.
  *"Set up canary deployment that routes 5% of new matches to the updated server build and compares crash rates and player reports against the stable fleet."*

- **Playtesting at Scale** — Testing multiplayer games with realistic player counts and network conditions before launch. Bots, staged rollouts, and stress tests that reveal problems you can't find with 4 developers on a LAN.
  *"Organize a 500-player stress test using bot clients that simulate realistic movement, combat, and matchmaking patterns to find our server's breaking point."*
