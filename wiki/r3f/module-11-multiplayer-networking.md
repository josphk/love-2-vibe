# Module 11: Multiplayer & Networking

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Time:** 8–12 hours
**Prerequisites:** [Module 5: Game Architecture & State](module-05-game-architecture-state.md)

---

## What You'll Learn

- Multiplayer architecture patterns and tradeoffs
- WebSocket communication between browser and server
- Authoritative server design with input validation
- Client-side prediction and server reconciliation
- Entity interpolation for smooth remote player movement
- Overview of Colyseus, PartyKit, and optimization strategies

---

## 1. Multiplayer Architecture Overview

### Client-Server vs Peer-to-Peer

| Aspect | Client-Server | Peer-to-Peer |
|---|---|---|
| **Authority** | Server owns game state | Peers share authority |
| **Cheat resistance** | High — server validates | Low — peers trust each other |
| **Latency** | Client → Server → Client | Client → Client (lower) |
| **Scaling** | Server costs grow | Free but limited players |
| **Complexity** | Moderate | High (NAT traversal, sync) |

For web-based R3F games, **client-server is the standard**. Browsers can't easily accept inbound connections, making true P2P impractical without WebRTC relay servers.

### The Authoritative Server Model

The server is the single source of truth:

1. Client sends **inputs** (not positions) to the server
2. Server **simulates** the game, applying inputs
3. Server **broadcasts** updated state to all clients
4. Clients **render** the received state

This prevents most cheating — a client claiming to be at position (999, 999) is ignored because the server calculates positions from validated inputs.

### Tick Rate and Update Rate

- **Tick rate**: How often the server simulates (e.g., 20–60 Hz)
- **Update rate**: How often the server sends state to clients (often same as tick rate, sometimes lower)
- **Client frame rate**: 60+ FPS — much faster than server updates

This mismatch means clients must **interpolate** between server updates to appear smooth.

---

## 2. WebSocket Basics

### Why WebSockets?

HTTP is request-response. Games need bidirectional, low-latency, persistent connections. WebSockets provide exactly this — a single TCP connection that stays open for continuous message passing.

### Browser WebSocket API

```js
const ws = new WebSocket('ws://localhost:3001')

ws.onopen = () => {
  console.log('Connected')
  ws.send(JSON.stringify({ type: 'join', name: 'Player1' }))
}

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data)
  console.log('Received:', msg)
}

ws.onclose = (event) => {
  console.log(`Disconnected: ${event.code} ${event.reason}`)
}

ws.onerror = (error) => {
  console.error('WebSocket error:', error)
}
```

### Message Format Convention

Use a `type` field to distinguish messages:

```js
// Client → Server
{ type: 'input', seq: 42, keys: { up: true, left: false } }
{ type: 'chat', text: 'hello' }

// Server → Client
{ type: 'state', players: [...], items: [...] }
{ type: 'player_joined', id: 'abc', name: 'Player2' }
{ type: 'player_left', id: 'abc' }
```

### Connection States

`ws.readyState` returns one of:

| Value | Constant | Meaning |
|---|---|---|
| 0 | `CONNECTING` | Not yet open |
| 1 | `OPEN` | Ready to send |
| 2 | `CLOSING` | Close in progress |
| 3 | `CLOSED` | Connection closed |

Always check `ws.readyState === WebSocket.OPEN` before sending.

---

## 3. Building a Simple Server

### Node.js + `ws` Library

```bash
mkdir game-server && cd game-server
npm init -y
npm install ws
```

### Minimal Broadcast Server

```js
// server.js
import { WebSocketServer } from 'ws'

const wss = new WebSocketServer({ port: 3001 })
const players = new Map()
let nextId = 1

const TICK_RATE = 20
const SPEED = 5

function broadcast(data) {
  const msg = JSON.stringify(data)
  for (const ws of wss.clients) {
    if (ws.readyState === 1) ws.send(msg)
  }
}

wss.on('connection', (ws) => {
  const id = String(nextId++)
  players.set(id, { id, x: Math.random() * 10 - 5, y: 0, z: Math.random() * 10 - 5, input: {} })

  ws.send(JSON.stringify({ type: 'welcome', id, players: [...players.values()] }))
  broadcast({ type: 'player_joined', player: players.get(id) })

  ws.on('message', (raw) => {
    try {
      const msg = JSON.parse(raw)
      if (msg.type === 'input') {
        const p = players.get(id)
        if (p) p.input = msg.keys || {}
      }
    } catch {}
  })

  ws.on('close', () => {
    players.delete(id)
    broadcast({ type: 'player_left', id })
  })
})

// Game loop
setInterval(() => {
  const dt = 1 / TICK_RATE
  for (const p of players.values()) {
    if (p.input.up) p.z -= SPEED * dt
    if (p.input.down) p.z += SPEED * dt
    if (p.input.left) p.x -= SPEED * dt
    if (p.input.right) p.x += SPEED * dt
    p.x = Math.max(-10, Math.min(10, p.x))
    p.z = Math.max(-10, Math.min(10, p.z))
  }
  broadcast({ type: 'state', players: [...players.values()], t: Date.now() })
}, 1000 / TICK_RATE)

console.log('Server running on ws://localhost:3001')
```

Key patterns here:

- **Player map** keyed by ID for fast lookup
- **Input storage** — store latest input, apply each tick
- **Fixed tick rate** — `setInterval` at 20 Hz (50ms)
- **Broadcast** — send full state to all clients each tick

---

## 4. Connecting R3F to the Server

### WebSocket Hook

```tsx
// hooks/useMultiplayer.ts
import { useEffect, useRef, useCallback, useState } from 'react'

export function useMultiplayer(url: string) {
  const wsRef = useRef<WebSocket | null>(null)
  const [myId, setMyId] = useState<string | null>(null)
  const [players, setPlayers] = useState<any[]>([])

  useEffect(() => {
    const ws = new WebSocket(url)
    wsRef.current = ws

    ws.onmessage = (e) => {
      const msg = JSON.parse(e.data)
      switch (msg.type) {
        case 'welcome':
          setMyId(msg.id)
          setPlayers(msg.players)
          break
        case 'state':
          setPlayers(msg.players)
          break
        case 'player_joined':
          setPlayers((prev) => [...prev, msg.player])
          break
        case 'player_left':
          setPlayers((prev) => prev.filter((p) => p.id !== msg.id))
          break
      }
    }

    ws.onclose = () => setMyId(null)
    return () => ws.close()
  }, [url])

  const sendInput = useCallback((keys: Record<string, boolean>) => {
    const ws = wsRef.current
    if (ws?.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'input', keys }))
    }
  }, [])

  return { myId, players, sendInput }
}
```

### Rendering Remote Players

```tsx
import { Canvas, useFrame } from '@react-three/fiber'
import { useMultiplayer } from '../hooks/useMultiplayer'
import { useKeyboard } from '../hooks/useKeyboard'

function Player({ position, color }: { position: number[]; color: string }) {
  return (
    <mesh position={position as [number, number, number]}>
      <boxGeometry args={[0.6, 1, 0.6]} />
      <meshStandardMaterial color={color} />
    </mesh>
  )
}

function Game() {
  const { myId, players, sendInput } = useMultiplayer('ws://localhost:3001')
  const keys = useKeyboard()

  useFrame(() => {
    sendInput(keys.current)
  })

  return (
    <>
      <mesh rotation-x={-Math.PI / 2} position-y={-0.5}>
        <planeGeometry args={[20, 20]} />
        <meshStandardMaterial color="#4a5" />
      </mesh>
      {players.map((p) => (
        <Player
          key={p.id}
          position={[p.x, p.y, p.z]}
          color={p.id === myId ? '#4af' : '#f44'}
        />
      ))}
    </>
  )
}
```

### Simple Keyboard Hook

```tsx
import { useEffect, useRef } from 'react'

export function useKeyboard() {
  const keys = useRef({ up: false, down: false, left: false, right: false })

  useEffect(() => {
    const map: Record<string, string> = {
      ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right',
      w: 'up', s: 'down', a: 'left', d: 'right',
    }
    const onKey = (e: KeyboardEvent) => {
      if (map[e.key]) (keys.current as any)[map[e.key]] = e.type === 'keydown'
    }
    window.addEventListener('keydown', onKey)
    window.addEventListener('keyup', onKey)
    return () => {
      window.removeEventListener('keydown', onKey)
      window.removeEventListener('keyup', onKey)
    }
  }, [])

  return keys
}
```

At this point you have a working multiplayer prototype. But it feels laggy — every action takes a round trip. Sections 5–7 address this.

---

## 5. Authoritative Server Model

### Why the Server Must Own Truth

If clients send positions directly, cheating is trivial — modify the client to report any position. Instead:

```
Client: "I'm pressing W"  →  Server: "OK, you moved to (3.0, 0, -2.5)"
```

The server simulates movement using the **same physics rules** as the client but is the final authority.

### Server Input Processing with Sequence Numbers

```js
ws.on('message', (raw) => {
  const msg = JSON.parse(raw)
  if (msg.type === 'input') {
    const p = players.get(id)
    if (!p) return

    // Validate: keys must be booleans
    const keys = msg.keys
    if (typeof keys !== 'object') return
    p.input = {
      up: keys.up === true,
      down: keys.down === true,
      left: keys.left === true,
      right: keys.right === true,
    }
    p.lastInputSeq = msg.seq || 0
  }
})
```

When the server broadcasts state, include the last processed input sequence per player. This is critical for client-side prediction.

---

## 6. Client-Side Prediction

### The Problem

Without prediction, pressing "W" shows no movement for ~50–150ms (round trip). This feels terrible.

### The Solution

1. Apply input **locally immediately** (predict)
2. Store each input with a sequence number
3. When server confirms state, **reconcile**: replay any unconfirmed inputs on top of the server position

### Prediction Implementation

```tsx
function usePrediction(myId: string | null, players: any[], sendInput: Function) {
  const pendingInputs = useRef<any[]>([])
  const seqRef = useRef(0)
  const predictedPos = useRef({ x: 0, y: 0, z: 0 })

  // Reconcile when server state arrives
  useEffect(() => {
    const me = players.find((p) => p.id === myId)
    if (!me) return

    // Start from server-confirmed position
    predictedPos.current = { x: me.x, y: me.y, z: me.z }

    // Remove confirmed inputs
    pendingInputs.current = pendingInputs.current.filter(
      (input) => input.seq > me.lastInputSeq
    )

    // Re-apply unconfirmed inputs
    for (const input of pendingInputs.current) {
      applyInput(predictedPos.current, input.keys, input.dt)
    }
  }, [players, myId])

  const processInput = useCallback((keys: any, dt: number) => {
    const seq = ++seqRef.current
    pendingInputs.current.push({ seq, keys: { ...keys }, dt })
    applyInput(predictedPos.current, keys, dt)
    sendInput({ ...keys, seq })
    return predictedPos.current
  }, [sendInput])

  return { predictedPos, processInput }
}

function applyInput(pos: { x: number; y: number; z: number }, keys: any, dt: number) {
  const speed = 5
  if (keys.up) pos.z -= speed * dt
  if (keys.down) pos.z += speed * dt
  if (keys.left) pos.x -= speed * dt
  if (keys.right) pos.x += speed * dt
  pos.x = Math.max(-10, Math.min(10, pos.x))
  pos.z = Math.max(-10, Math.min(10, pos.z))
}
```

### Key Insight

The movement function `applyInput` must be **identical** on client and server. Any discrepancy causes jitter as the client predicts one thing and the server corrects another.

---

## 7. Entity Interpolation

### The Problem

Remote players only update at the server tick rate (20 Hz). Rendering them directly causes jerky, stepwise movement.

### The Solution: Snapshot Buffer

Maintain a buffer of recent snapshots and interpolate between them, rendering slightly in the past:

```tsx
function useInterpolation(players: any[], myId: string | null) {
  const bufferRef = useRef(new Map<string, { t: number; x: number; y: number; z: number }[]>())
  const INTERP_DELAY = 100 // render 100ms behind

  useEffect(() => {
    for (const p of players) {
      if (p.id === myId) continue
      if (!bufferRef.current.has(p.id)) bufferRef.current.set(p.id, [])
      const buf = bufferRef.current.get(p.id)!
      buf.push({ t: Date.now(), x: p.x, y: p.y, z: p.z })
      while (buf.length > 20) buf.shift()
    }
  }, [players, myId])

  const getInterpolatedPositions = useCallback(() => {
    const renderTime = Date.now() - INTERP_DELAY
    const result = new Map<string, [number, number, number]>()

    for (const [id, buf] of bufferRef.current) {
      if (buf.length < 2) {
        if (buf.length === 1) result.set(id, [buf[0].x, buf[0].y, buf[0].z])
        continue
      }

      let i = buf.length - 1
      while (i > 0 && buf[i].t > renderTime) i--

      const a = buf[i]
      const b = buf[Math.min(i + 1, buf.length - 1)]
      const range = b.t - a.t
      const t = range > 0 ? Math.min(1, (renderTime - a.t) / range) : 0

      result.set(id, [
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t,
      ])
    }
    return result
  }, [])

  return getInterpolatedPositions
}
```

### The Tradeoff

Interpolation adds ~100ms latency to remote players. For most games this is unnoticeable, but for competitive FPS you'd also implement **lag compensation** on the server (rewinding time for hit detection).

---

## 8. Colyseus

[Colyseus](https://colyseus.io/) is a room-based multiplayer framework that handles much of the boilerplate.

### Core Concepts

| Concept | Description |
|---|---|
| **Room** | A game session. Players join rooms. |
| **State** | Schema-defined game state that auto-syncs to clients. |
| **Schema** | Typed classes with automatic delta serialization. |
| **Client SDK** | `colyseus.js` — handles connection, state sync, reconnection. |

### Server-Side Room

```ts
import { Room, Client } from '@colyseus/core'
import { Schema, MapSchema, type } from '@colyseus/schema'

class Player extends Schema {
  @type('number') x = 0
  @type('number') z = 0
  @type('number') score = 0
}

class GameState extends Schema {
  @type({ map: Player }) players = new MapSchema<Player>()
}

export class ArenaRoom extends Room<GameState> {
  maxClients = 4

  onCreate() {
    this.setState(new GameState())
    this.setSimulationInterval((dt) => this.update(dt), 1000 / 20)
  }

  onJoin(client: Client) {
    const player = new Player()
    player.x = Math.random() * 10 - 5
    player.z = Math.random() * 10 - 5
    this.state.players.set(client.sessionId, player)
  }

  onMessage(client: Client, type: string, message: any) {
    if (type === 'input') {
      const p = this.state.players.get(client.sessionId)
      if (p) { /* apply validated input */ }
    }
  }

  onLeave(client: Client) {
    this.state.players.delete(client.sessionId)
  }

  update(dt: number) { /* server tick */ }
}
```

### Client Connection

```ts
import { Client } from 'colyseus.js'

const client = new Client('ws://localhost:2567')
const room = await client.joinOrCreate('arena')

room.state.players.onAdd((player, sessionId) => {
  console.log('Player joined:', sessionId)
})

room.state.players.onRemove((player, sessionId) => {
  console.log('Player left:', sessionId)
})

room.send('input', { up: true })
```

### Why Use Colyseus?

- **Automatic delta serialization** — only changed fields are sent
- **Schema validation** — type-safe state
- **Matchmaking** — built-in room management
- **Reconnection** — handles dropped connections gracefully

---

## 9. PartyKit

[PartyKit](https://www.partykit.io/) is a serverless WebSocket platform. Deploy "parties" — small server scripts on Cloudflare's edge.

```ts
// party/arena.ts
import type { Party, Connection } from 'partykit/server'

export default class ArenaServer implements Party.Server {
  players = new Map<string, { x: number; z: number }>()

  onConnect(conn: Connection) {
    this.players.set(conn.id, { x: 0, z: 0 })
    this.broadcast(JSON.stringify({ type: 'state', players: Object.fromEntries(this.players) }))
  }

  onMessage(message: string, sender: Connection) {
    const msg = JSON.parse(message)
    if (msg.type === 'input') {
      const p = this.players.get(sender.id)
      if (p) { /* apply input */ }
    }
    this.broadcast(JSON.stringify({ type: 'state', players: Object.fromEntries(this.players) }))
  }

  onClose(conn: Connection) {
    this.players.delete(conn.id)
    this.broadcast(JSON.stringify({ type: 'state', players: Object.fromEntries(this.players) }))
  }
}
```

**When to use PartyKit:** Prototyping, game jams, casual games. Zero infrastructure setup. Not ideal for high-tick-rate competitive games.

---

## 10. Bandwidth Optimization

### Delta Compression

Only send what changed since the last update. Colyseus does this automatically; with raw WebSockets you implement it manually.

### Binary Protocols

JSON is verbose. For high-frequency data, binary formats save 50–80% bandwidth:

| Format | Size vs JSON | Notes |
|---|---|---|
| **MessagePack** | ~60% smaller | Drop-in JSON replacement |
| **Protocol Buffers** | ~70–80% smaller | Google standard, schema required |
| **Manual ArrayBuffer** | Minimal overhead | Maximum control |

### Manual Binary Example

```ts
// 13 bytes instead of ~80 bytes JSON
function encodePlayer(id: number, x: number, y: number, z: number) {
  const buf = new ArrayBuffer(13)
  const view = new DataView(buf)
  view.setUint8(0, id)
  view.setFloat32(1, x)
  view.setFloat32(5, y)
  view.setFloat32(9, z)
  return buf
}
```

### Other Strategies

- **Reduce tick rate** for distant entities
- **Area of interest** — only send data about nearby entities
- **Quantize** — round positions to 2 decimal places
- **Send input changes only** — not every frame

---

## 11. Security Basics

### Never Trust the Client

Every message from the client is potentially malicious. Validate everything server-side.

### Input Validation

```ts
function validateInput(msg: any) {
  if (typeof msg !== 'object' || msg === null) return null
  if (msg.type !== 'input') return null
  const keys = msg.keys
  if (typeof keys !== 'object') return null
  return {
    type: 'input',
    seq: typeof msg.seq === 'number' ? Math.floor(msg.seq) : 0,
    keys: {
      up: keys.up === true, down: keys.down === true,
      left: keys.left === true, right: keys.right === true,
    },
  }
}
```

### Rate Limiting

```ts
const rateLimits = new Map<string, { count: number; resetTime: number }>()

function checkRateLimit(id: string, maxPerSecond = 30): boolean {
  const now = Date.now()
  let entry = rateLimits.get(id)
  if (!entry || now > entry.resetTime) {
    entry = { count: 0, resetTime: now + 1000 }
    rateLimits.set(id, entry)
  }
  entry.count++
  return entry.count <= maxPerSecond
}
```

### Common Attack Vectors

| Attack | Mitigation |
|---|---|
| Speed hacking | Server calculates positions from inputs |
| Teleporting | Validate movement delta per tick |
| Message flooding | Rate limiting |
| Packet sniffing | Use `wss://` (TLS) |

---

## Code Walkthrough: Multiplayer Arena

Combines all sections above into a complete 2–4 player arena with item collection.

### Server (`server/index.js`)

```js
import { WebSocketServer } from 'ws'

const wss = new WebSocketServer({ port: 3001 })
const players = new Map()
const items = new Map()
let nextId = 1

const TICK_RATE = 20
const SPEED = 5
const ARENA = 10
const COLLECT_DIST = 1.0

for (let i = 0; i < 6; i++) spawnItem()

function spawnItem() {
  const id = `item_${nextId++}`
  items.set(id, { id, x: Math.random() * ARENA * 2 - ARENA, z: Math.random() * ARENA * 2 - ARENA })
}

function broadcast(data) {
  const msg = JSON.stringify(data)
  for (const ws of wss.clients) {
    if (ws.readyState === 1) ws.send(msg)
  }
}

wss.on('connection', (ws) => {
  const id = String(nextId++)
  players.set(id, { id, x: 0, y: 0, z: 0, score: 0, input: {}, lastSeq: 0 })

  ws.send(JSON.stringify({
    type: 'welcome', id,
    players: [...players.values()].map(({ input, ...p }) => p),
    items: [...items.values()],
  }))
  broadcast({ type: 'player_joined', id })

  ws.on('message', (raw) => {
    try {
      const msg = JSON.parse(raw)
      if (msg.type === 'input') {
        const p = players.get(id)
        if (!p) return
        p.input = {
          up: msg.keys?.up === true, down: msg.keys?.down === true,
          left: msg.keys?.left === true, right: msg.keys?.right === true,
        }
        p.lastSeq = typeof msg.seq === 'number' ? msg.seq : 0
      }
    } catch {}
  })

  ws.on('close', () => {
    players.delete(id)
    broadcast({ type: 'player_left', id })
  })
})

setInterval(() => {
  const dt = 1 / TICK_RATE
  for (const p of players.values()) {
    if (p.input.up) p.z -= SPEED * dt
    if (p.input.down) p.z += SPEED * dt
    if (p.input.left) p.x -= SPEED * dt
    if (p.input.right) p.x += SPEED * dt
    p.x = Math.max(-ARENA, Math.min(ARENA, p.x))
    p.z = Math.max(-ARENA, Math.min(ARENA, p.z))

    for (const [itemId, item] of items) {
      const dx = p.x - item.x, dz = p.z - item.z
      if (Math.sqrt(dx * dx + dz * dz) < COLLECT_DIST) {
        p.score++
        items.delete(itemId)
        spawnItem()
      }
    }
  }
  broadcast({
    type: 'state',
    players: [...players.values()].map(({ input, ...p }) => p),
    items: [...items.values()],
    t: Date.now(),
  })
}, 1000 / TICK_RATE)

console.log('Arena server on ws://localhost:3001')
```

### Client Scene

```tsx
import { Canvas, useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import { useRef } from 'react'
import { useMultiplayer } from '../hooks/useMultiplayer'
import { useKeyboard } from '../hooks/useKeyboard'

function Player({ position, score, color, name }: {
  position: number[]; score: number; color: string; name: string
}) {
  const meshRef = useRef<THREE.Group>(null)

  useFrame(() => {
    if (!meshRef.current) return
    const m = meshRef.current.position
    m.x += (position[0] - m.x) * 0.3
    m.z += (position[2] - m.z) * 0.3
  })

  return (
    <group ref={meshRef} position={position as [number, number, number]}>
      <mesh>
        <capsuleGeometry args={[0.3, 0.6, 8, 16]} />
        <meshStandardMaterial color={color} />
      </mesh>
      <Text position={[0, 1.2, 0]} fontSize={0.3} color="white" anchorX="center">
        {name} ({score})
      </Text>
    </group>
  )
}

function Item({ position }: { position: [number, number] }) {
  const ref = useRef<THREE.Mesh>(null)
  useFrame((state) => {
    if (!ref.current) return
    ref.current.rotation.y = state.clock.elapsedTime * 2
    ref.current.position.y = 0.5 + Math.sin(state.clock.elapsedTime * 3) * 0.15
  })

  return (
    <mesh ref={ref} position={[position[0], 0.5, position[1]]}>
      <octahedronGeometry args={[0.25]} />
      <meshStandardMaterial color="#fd0" emissive="#fa0" emissiveIntensity={0.5} />
    </mesh>
  )
}

const COLORS = ['#4af', '#f44', '#4f4', '#fa4']

function GameLoop() {
  const { myId, gameState, sendInput } = useMultiplayer('ws://localhost:3001')
  const keys = useKeyboard()
  const seqRef = useRef(0)

  useFrame(() => {
    seqRef.current++
    sendInput(keys.current, seqRef.current)
  })

  return (
    <>
      {/* Arena floor */}
      <mesh rotation-x={-Math.PI / 2}>
        <planeGeometry args={[20, 20]} />
        <meshStandardMaterial color="#3a7c4f" />
      </mesh>
      {/* Players */}
      {gameState.players.map((p, i) => (
        <Player
          key={p.id}
          position={[p.x, p.y, p.z]}
          score={p.score}
          color={COLORS[i % COLORS.length]}
          name={p.id === myId ? 'You' : `P${p.id}`}
        />
      ))}
      {/* Items */}
      {gameState.items.map((item) => (
        <Item key={item.id} position={[item.x, item.z]} />
      ))}
    </>
  )
}

export default function GameScene() {
  return (
    <Canvas camera={{ position: [0, 15, 15], fov: 50 }}>
      <ambientLight intensity={0.6} />
      <directionalLight position={[5, 10, 5]} intensity={1} />
      <GameLoop />
    </Canvas>
  )
}
```

### Running It

```bash
# Terminal 1
cd server && node index.js

# Terminal 2
npm run dev

# Open 2+ browser tabs to localhost:5173
```

---

## API Quick Reference

### Browser WebSocket

| API | Description |
|-----|-------------|
| `new WebSocket(url)` | Create connection |
| `ws.send(data)` | Send string or binary |
| `ws.close()` | Close connection |
| `ws.readyState` | Connection state (0-3) |
| `ws.onopen` | Connection established |
| `ws.onmessage` | Message received |
| `ws.onclose` | Connection closed |

### Node.js ws Server

| API | Description |
|-----|-------------|
| `new WebSocketServer({ port })` | Create server |
| `wss.on('connection', fn)` | New client connected |
| `ws.on('message', fn)` | Received from client |
| `ws.send(data)` | Send to client |
| `wss.clients` | Set of all connections |

### Multiplayer Patterns

| Pattern | What It Solves |
|---------|---------------|
| Authoritative server | Cheating, state conflicts |
| Client-side prediction | Local input lag |
| Entity interpolation | Choppy remote movement |
| Delta compression | Bandwidth usage |

---

## Common Pitfalls

### 1. Sending Position Instead of Input

```tsx
// WRONG — cheatable
ws.send(JSON.stringify({ type: 'move', x: player.x, z: player.z }))

// RIGHT — server computes position
ws.send(JSON.stringify({ type: 'input', keys: { up: true } }))
```

### 2. No Reconnection Handling

```tsx
// WRONG — dies silently
const ws = new WebSocket(url)

// RIGHT — reconnect with backoff
function connect(url: string, delay = 1000) {
  const ws = new WebSocket(url)
  ws.onclose = () => setTimeout(() => connect(url, Math.min(delay * 2, 10000)), delay)
  return ws
}
```

### 3. Using Server State for Local Player

```tsx
// WRONG — laggy local movement
<Player position={[serverState.x, 0, serverState.z]} />

// RIGHT — predicted position locally, interpolated for remote
const pos = isLocal ? predictedPos : interpolatedPos
```

### 4. Sending Input Every Frame

```tsx
// WRONG — 60 messages/sec even when idle
useFrame(() => ws.send(JSON.stringify({ type: 'input', keys })))

// RIGHT — only on change
useFrame(() => {
  if (inputChanged(prev, current)) {
    ws.send(JSON.stringify({ type: 'input', keys: current }))
    prev = { ...current }
  }
})
```

### 5. Ghost Players on Disconnect

```js
// WRONG
ws.on('close', () => console.log('bye'))

// RIGHT
ws.on('close', () => {
  players.delete(id)
  broadcast({ type: 'player_left', id })
})
```

---

## Exercises

### Exercise 1: Chat System
Add real-time chat to the arena. Validate message length (max 200 chars), rate limit (5/sec), render as scrolling HTML overlay.

### Exercise 2: Server-Authoritative Items with Respawn Timer
Items respawn after 3 seconds. Broadcast item states including `active` flag. First to 10 points triggers game over.

### Exercise 3: Lag Simulation
Add artificial latency (0ms, 100ms, 300ms) via `setTimeout`. Observe prediction and interpolation behavior. Tune `INTERP_DELAY`.

### Exercise 4 (Stretch): Implement with Colyseus
Rebuild with Colyseus schema-based state sync. Compare code volume and complexity vs raw WebSockets.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [Gabriel Gambetta: Fast-Paced Multiplayer](https://www.gabrielgambetta.com/client-server-game-architecture.html) | Article Series | The definitive guide to prediction, interpolation, lag compensation |
| [Colyseus Documentation](https://docs.colyseus.io/) | Official Docs | Room lifecycle, schema sync, matchmaking |
| [PartyKit Documentation](https://docs.partykit.io/) | Official Docs | Serverless WebSocket rooms |
| [Valve: Source Multiplayer Networking](https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking) | Article | Classic reference on tick rates and interpolation |
| [MDN: WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket) | Reference | Browser WebSocket events, states, binary data |
| [Glenn Fiedler: Networked Physics](https://gafferongames.com/post/introduction_to_networked_physics/) | Article Series | Synchronizing physics across the network |

---

## Key Takeaways

1. **The server is the authority.** Clients send inputs, the server simulates and broadcasts truth. This prevents cheating and guarantees consistency.

2. **Client-side prediction eliminates perceived latency.** Apply inputs locally, buffer them, reconcile when the server responds. If prediction logic matches the server, players never feel the lag.

3. **Entity interpolation smooths remote players.** Render 100ms in the past, interpolating between server snapshots. The delay is imperceptible; the smoothness is everything.

4. **Start with raw WebSockets, graduate to frameworks.** Understanding the protocol makes you a better debugger. Colyseus and PartyKit save plumbing work once you understand the fundamentals.

5. **Validate everything server-side.** Rate limit messages, sanitize inputs, enforce rules on the server. Never trust client data.

6. **Bandwidth adds up.** Keep payloads small, send changes not full state, consider binary protocols at scale.

---

## What's Next?

Your game is no longer isolated to a single browser tab. Players connect, move, interact, and see each other in real time. The core techniques — authoritative server, client-side prediction, entity interpolation — are the same ones used in every multiplayer game from Fortnite to World of Warcraft.

**[Module 12: WebGPU & The Cutting Edge](module-12-webgpu-cutting-edge.md)** takes you into next-generation rendering with compute shaders, TSL node materials, and GPU-driven particle simulations. Or if you're ready to ship, **[Module 13: Build, Ship & What's Next](module-13-ship-whats-next.md)** covers production optimization, deployment, and getting your game in front of real players.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
