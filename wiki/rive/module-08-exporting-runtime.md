# Module 8: Exporting & Runtime Integration

[← Back to Rive Learning Roadmap](rive-learning-roadmap.md)

**Time estimate:** 3–5 hours
**Prerequisites:** Modules 4–7 (state machine, listeners, advanced animation, data binding)

---

## Overview

Everything you've built in Modules 0–7 lives inside the Rive editor. This module is about getting it out — into actual applications, games, and products. Rive exports a single `.riv` binary file that contains all artwork, animations, state machine logic, and data binding definitions. No separate atlases, no JSON sidecar files, no image folders. One file, everything included.

But exporting is only half the story. The other half is the runtime — the library that loads .riv files, advances state machines, handles inputs, and renders frames. Rive has official runtimes for web, mobile, Flutter, Unity, Unreal, and C++. Each follows the same conceptual pattern but with platform-specific APIs.

This module also includes an honest assessment of the LÖVE/Lua situation and a detailed Rive vs Spine comparison to help you make informed tooling decisions for your projects.

### Learning Objectives

By the end of this module, you will be able to:

1. Export .riv files from the Rive editor
2. Understand the runtime architecture and API pattern
3. Load, configure, and render Rive content in at least one runtime
4. Set inputs, fire triggers, and read outputs from your application code
5. Make informed decisions about when to use Rive vs Spine

---

## Core Concepts

### 1. The .riv Export Format

Rive exports a single binary file with the `.riv` extension. This file is a compact, optimized container for everything your artboard needs.

**What's inside a .riv file:**

- All vector artwork (paths, shapes, fills, strokes)
- All bones, meshes, and constraints
- All timeline animations (keyframes, curves, timing)
- All state machine definitions (states, transitions, conditions, inputs)
- All listener configurations
- All data binding definitions
- Embedded fonts (for text elements)
- Embedded images (if you used raster images)

**What's NOT inside:**

- Source editing metadata (layer names, guide lines, editor preferences)
- Version history
- Runtime-bound data (text values, colors, images set at runtime)

**File size:**

.riv files are remarkably compact for vector content:

| Content | Typical size |
|---------|-------------|
| Simple icon with animation | 5–15 KB |
| Interactive button with state machine | 15–40 KB |
| Character with full rig and animations | 40–100 KB |
| Complex UI screen with nested artboards | 100–300 KB |
| Heavy file with embedded raster images | 500 KB–2 MB+ |

Vector art keeps files small. Embedded raster images are the main size driver. If your .riv file is over 500KB, check whether you can replace raster images with vector art.

**Export requirements:**

As of 2025, exporting requires a paid Rive plan (Cadet tier at $9/month annually). The free tier lets you design, animate, and preview without limits, but the Export button requires a subscription. This is Rive's primary monetization model — the tool is free to learn, paid to ship.

**Why it matters:** The single-file format simplifies deployment. No atlas packing, no asset pipeline, no "forgot to include the JSON file" bugs. One file per interactive element. Drop it into your project, load it with the runtime, done.

**Common mistake:** Expecting to edit .riv files outside the Rive editor. The .riv format is binary and proprietary. There's no way to hand-edit it, diff it in Git, or convert it to another format. Rive is both the editor and the format — they're inseparable.

**Try this now:** If you have a paid Rive plan, export one of your artboards as a .riv file. Note the file size. If you don't have a paid plan, observe the Export button and its requirements — understanding the cost model is part of making informed tooling decisions.

---

### 2. The Runtime Architecture

Every Rive runtime follows the same conceptual architecture, regardless of platform:

```
Your Application Code
        ↓ (load file, set inputs)
    Rive Runtime Library
        ↓ (advance state machine, compute transforms)
    Renderer Backend
        ↓ (draw commands)
    Screen
```

**The runtime lifecycle:**

1. **Load:** Read the .riv file and parse its contents into memory
2. **Instantiate:** Create an artboard instance and state machine controller
3. **Configure:** Get references to inputs and data bindings
4. **Loop:** Every frame:
   a. Update inputs from your application state
   b. Advance the state machine by delta time
   c. Render the artboard to screen

**Pseudocode (applies to all runtimes):**

```
// 1. Load
file = loadRiveFile("character.riv")

// 2. Instantiate
artboard = file.artboard("MainCharacter")
stateMachine = artboard.stateMachine("GameLogic")

// 3. Configure (get input references once)
healthInput = stateMachine.getNumber("health")
isWalkingInput = stateMachine.getBool("isWalking")
damageInput = stateMachine.getTrigger("onDamage")

// 4. Loop (every frame)
function update(deltaTime):
    // Set inputs from game state
    healthInput.setValue(player.health / player.maxHealth)
    isWalkingInput.setValue(player.velocity > 0)
    if player.tookDamage:
        damageInput.fire()

    // Advance and render
    stateMachine.advance(deltaTime)
    renderer.draw(artboard)
```

**Key principle:** Your game code only sets inputs and renders. All animation logic — transitions, blending, timing — is handled by the state machine inside the .riv file. The runtime is a black box that takes inputs and produces frames.

**Why it matters:** This architecture means the developer's job is minimal: load the file, set inputs, render. The designer owns all visual behavior. Changes to animation timing, transitions, and blending require only a new .riv file — no code changes.

**Common mistake:** Trying to control animation playback directly (play/pause/seek) instead of using state machine inputs. Direct playback control bypasses the state machine. If you've built a state machine, use inputs to drive it — that's the whole point. Direct playback is only appropriate for simple, non-interactive animations.

**Try this now:** Read through the pseudocode above and mentally map it to your project's game loop. Where would the load happen? Where would inputs be set? Where would rendering happen? Even if you're not integrating yet, understanding where Rive fits in your architecture is valuable.

---

### 3. Official Runtimes

Rive maintains official runtimes for multiple platforms. Each is open-source and follows the architecture above.

**Web (JavaScript/WASM):**

The most mature runtime. Uses WebAssembly for performance with a JavaScript API. Renders via Canvas or WebGL. Excellent for browser games, web apps, and interactive websites.

```javascript
// Web runtime example
const rive = new Rive({
    src: "character.riv",
    canvas: document.getElementById("canvas"),
    stateMachines: "GameLogic",
    onLoad: () => {
        const inputs = rive.stateMachineInputs("GameLogic");
        const health = inputs.find(i => i.name === "health");
        health.value = 0.75;
    }
});
```

**Flutter:**

First-class support, used by major apps including Duolingo. Flutter and Rive share a similar philosophy (declarative UI, design-as-code), making them natural partners.

**iOS (Swift/SwiftUI) and Android (Kotlin):**

Native mobile runtimes for integrating Rive into native apps. Support both UIKit/SwiftUI (iOS) and Compose/Views (Android).

**Unity:**

Official runtime for game development. Provides components for rendering Rive artboards in Unity scenes, with full state machine input access from C# scripts.

```csharp
// Unity runtime example
public class RiveController : MonoBehaviour
{
    public RiveFile riveFile;
    private StateMachine stateMachine;
    private SMINumber healthInput;

    void Start()
    {
        var artboard = riveFile.Artboard("MainCharacter");
        stateMachine = artboard.StateMachine("GameLogic");
        healthInput = stateMachine.GetNumber("health");
    }

    void Update()
    {
        healthInput.Value = player.Health / player.MaxHealth;
        stateMachine.Advance(Time.deltaTime);
    }
}
```

**Unreal Engine:**

Official plugin for Unreal. Integrates with Unreal's widget system for UI, and can be used in 3D scenes with render targets.

**C++:**

Low-level runtime for custom engines. Provides the core state machine and rendering logic without platform-specific abstractions. This is the foundation that other runtimes are built on.

**React / React Native:**

Wrapper around the web runtime for React applications, providing component-based integration with hooks for input management.

**Why it matters:** Rive's multi-platform strategy means your .riv files are portable. An animation designed for a web prototype can be deployed to a Unity game or a Flutter app with minimal changes — the file is the same, only the runtime integration code differs.

**Common mistake:** Assuming all runtimes have identical feature parity. The web runtime is typically the most up-to-date. Newer features (data binding, mesh deformation) may land on web first and other platforms later. Check the runtime's release notes for your platform.

---

### 4. The LÖVE/Lua Situation (Honest Assessment)

There is **no official or community LÖVE/Lua runtime for Rive.** This is important context if LÖVE is your primary engine.

**Your options:**

**Option 1: Rive for UI + Spine for characters (pragmatic split)**

Use Rive for designing and prototyping interactive UI. Export sprite sheets from Rive for use in LÖVE as traditional frame-based animation. Use Spine with its official LÖVE runtime for in-game character animation.

- Pros: Best of both worlds. Rive's design workflow for UI, Spine's LÖVE integration for characters.
- Cons: Two tools to learn and maintain. Rive's interactive features (state machines, listeners) are lost when exporting as sprite sheets.

**Option 2: Rive's C++ runtime via LuaJIT FFI**

Technically possible. Rive's C++ runtime is open source. LuaJIT's FFI can call C functions. You'd write C bindings for the Rive C++ API and call them from LÖVE.

- Pros: Full Rive functionality in LÖVE.
- Cons: Significant engineering effort. You'd build and maintain the C binding layer, handle memory management across the FFI boundary, and integrate rendering with LÖVE's graphics pipeline. Not recommended for a first project.

**Option 3: Move to a supported engine**

If Rive's interactive features are essential to your project, consider Unity, Unreal, or a web framework where Rive integrates natively. The web runtime is excellent for browser-based games.

- Pros: Full Rive integration with official support.
- Cons: Leaving the LÖVE ecosystem.

**Option 4: Export sprite sheets**

Design and animate in Rive, then export as image sequences or sprite sheets. Load those in LÖVE as traditional frame-based animation using libraries like anim8.

- Pros: Works with any engine. Rive's design workflow is still faster than manual spriting.
- Cons: Loses all interactive features — state machines, listeners, blend states, data binding. The .riv file becomes a production tool, not a runtime format.

**The pragmatic recommendation:** Learn Rive for the concepts and design workflow. The skills transfer — state machine thinking, blend states, interaction design — are valuable regardless of which engine you use. For LÖVE projects today, use Spine for character animation (official runtime) and Rive's design workflow + sprite sheet export for UI elements.

---

### 5. Rive vs Spine: When to Use Which

Both tools do skeletal animation with bones, meshes, and keyframes. Their strengths diverge beyond that core.

| Scenario | Spine | Rive | Notes |
|----------|-------|------|-------|
| Character walk/run/attack cycles | ✅ Better | Possible | Spine's animation workflow is more mature for complex character animation |
| Complex skeletal character with many animations | ✅ | ✅ | Both handle this well |
| In-LÖVE game character animation | ✅ Official runtime | ❌ No runtime | Spine wins by default for LÖVE |
| Animated game UI (menus, HUD, buttons) | ❌ | ✅ | Rive's state machine + listeners are purpose-built for interactive UI |
| Interactive elements (hover, click, tracking) | ❌ | ✅ | Spine has no equivalent to listeners |
| State-driven animation (no code logic) | ❌ | ✅ | Spine requires code for all transition logic |
| Unity/Unreal game project | Either | ✅ Slight edge | Rive's state machine reduces code; Spine is well-established |
| Web-based game | ❌ | ✅ | Rive's web runtime is excellent; Spine's web support is limited |
| Data-bound dynamic content | ❌ | ✅ | Spine has no data binding |
| Established animation pipeline | ✅ | Growing | Spine has years of AAA/indie adoption |
| Free tier capability | Limited | ✅ Full (except export) | Rive's free tier is more generous for learning |

**When to use both:**

The tools complement rather than compete for many projects. A game in Unity might use:
- **Spine** for player character and enemy animations (complex skeletal animation with many interruptible states)
- **Rive** for all UI (menus, HUD, dialogue, notifications) because the state machine eliminates transition code

**Cost comparison:**

| | Spine | Rive |
|---|---|---|
| Learning | $0 (trial) | $0 (free tier) |
| Shipping | $79 Essential / $379 Pro (one-time) | $9/month Cadet / $42/month Team (subscription) |

Spine's one-time purchase is cheaper long-term. Rive's subscription is lower upfront. Both are inexpensive relative to the value they provide.

**Transferable skills:**

The good news: ~70% of what you learn transfers between the tools. Bones, keyframes, easing curves, mesh deformation, weight painting, IK constraints — all work the same conceptually. Rive adds state machines and interactivity. Spine adds more granular animation features (multi-track mixing, inverse kinematics chains, path constraints).

---

## Case Studies

### Case Study 1: Web Game with Full Rive Integration

**The scenario:** A browser-based puzzle game using the web runtime.

**Architecture:**

```
Game Logic (JavaScript)
    ↓ sets inputs
Rive Web Runtime (WASM)
    ↓ renders
HTML Canvas
```

**Integration points:**
- Game board rendered traditionally (Canvas 2D)
- UI overlay rendered by Rive (HUD, score, timer, menus)
- Rive artboards positioned absolutely over the game canvas
- Game state drives Rive inputs: `score`, `timer`, `isGameOver`

**Key decisions:**
- Used a single "GameUI" .riv file with nested artboards for each UI element
- State machine inputs exposed: `score` (number), `timeRemaining` (number), `onCorrect` (trigger), `onWrong` (trigger), `isGameOver` (boolean)
- All UI animation (score pop, timer urgency, game over screen) handled by Rive
- Game code: ~200 lines for Rive integration (load, inputs, render)

**Result:** Polished, animated game UI with no custom rendering code. Designer iterated on UI feel without touching JavaScript.

---

### Case Study 2: Unity Mobile Game UI

**The scenario:** A mobile RPG using Unity with Rive for all UI.

**Architecture:**
- Game world: Unity 3D rendering (characters, environment)
- UI layer: Rive artboards rendered to Unity UI canvases
- Each screen is a separate .riv file: MainMenu.riv, Battle.riv, Inventory.riv, Dialogue.riv

**Integration pattern:**
```csharp
// Each screen manager loads its Rive file
public class BattleUI : MonoBehaviour
{
    private RiveFile battleRiv;
    private SMINumber playerHealth, enemyHealth;
    private SMITrigger onPlayerDamage, onEnemyDamage, onVictory;

    void Start()
    {
        // Load and configure
        battleRiv = LoadRiveFile("Battle.riv");
        playerHealth = battleRiv.GetNumber("playerHealth");
        enemyHealth = battleRiv.GetNumber("enemyHealth");
        onPlayerDamage = battleRiv.GetTrigger("onPlayerDamage");
    }

    // Called by battle system
    public void OnPlayerHit(float damage)
    {
        playerHealth.Value = battleSystem.PlayerHP / battleSystem.PlayerMaxHP;
        onPlayerDamage.Fire();
    }
}
```

**Key decisions:**
- Separate .riv files per screen (smaller load, independent iteration)
- Battle UI state machine has 15+ inputs for health, mana, status effects, turn indicators
- Designer could iterate on battle UI "feel" (damage shake intensity, health bar color thresholds) without code changes

**Result:** UI development was 3x faster than the previous project's code-based UI. Designer ownership of animation timing eliminated the back-and-forth of "can you make the health bar shake a bit more?"

---

### Case Study 3: Sprite Sheet Export for LÖVE

**The scenario:** A LÖVE game using Rive for asset creation but not runtime integration.

**Workflow:**
1. Design character in Rive (vector tools, bones, animations)
2. Preview and iterate in Rive's editor
3. Export each animation as a sprite sheet (PNG sequence)
4. Load sprite sheets in LÖVE using anim8 or similar library
5. State management in Lua code (traditional approach)

**What was gained:**
- Faster asset creation (Rive's vector tools + bones > drawing each frame)
- Iteration speed (change a bone animation, re-export — no manual frame drawing)
- Consistent style (vector design ensures clean, scalable art)

**What was lost:**
- No state machine (transition logic back in Lua code)
- No listeners (interaction back to LÖVE event handling)
- No blend states (hard cuts between sprite animations)
- No data binding (text/colors rendered by LÖVE)

**Honest assessment:** This workflow is better than pure hand-drawing but significantly less powerful than native Rive runtime integration. The design workflow value is real, but ~60% of Rive's features (everything interactive/runtime) are unusable.

---

## Common Pitfalls

1. **Loading performance:** .riv files are small, but parsing them is not instant. For games with many .riv files, preload during loading screens rather than on-demand. First-frame rendering after load can be slow as the state machine initializes.

2. **Frame rate mismatch:** Rive state machines advance by delta time. If your game runs at variable frame rate, ensure you're passing accurate delta time. A fixed 1/60 will cause animations to play at wrong speed on 30fps or 120fps displays.

3. **Input name typos:** If you request an input named "heatlh" (typo) that doesn't exist in the .riv file, most runtimes return null silently. Your game code sets values on null, nothing happens, and you spend 30 minutes debugging. Validate input names at load time and log warnings for mismatches.

4. **Multiple artboards vs one large artboard:** Use separate artboards (and separate .riv files) for independent UI elements. One giant artboard with everything creates a single point of failure and prevents granular loading. Exception: tightly coupled elements that animate together should share an artboard.

5. **Render pipeline integration:** Rive renders to a canvas/surface. In game engines, this surface needs to be composited with your game world correctly (draw order, transparency, coordinate space). Getting this wrong creates visual artifacts like Rive content rendering behind the game world or at the wrong scale.

6. **State machine memory:** Each state machine instance holds state. If you instantiate 100 characters from the same .riv file, you have 100 independent state machine instances in memory. The .riv file data is shared (loaded once), but the state is per-instance.

---

## Exercises

### Exercise 1: Export and Inspect (Beginner)

Understand the .riv file format through direct experience.

**Requirements:**
- Export one of your existing artboards as a .riv file (requires paid plan)
- Note the file size and compare it to what you'd expect from a PNG/GIF of the same visual
- If you can't export (free plan), read through the [Rive Runtimes overview](https://help.rive.app/runtimes/overview) and write down the API pattern: load → instantiate → configure → loop

**Success criteria:** You can articulate the .riv file's contents and the runtime lifecycle without referencing documentation.

---

### Exercise 2: Web Runtime Integration (Intermediate)

Load a .riv file in a web page and interact with it.

**Requirements:**
- Create an HTML page with a canvas element
- Load the Rive web runtime from CDN
- Load a .riv file with a state machine
- Display it on the canvas
- Add JavaScript controls (buttons or sliders) that set state machine inputs
- Verify that changing inputs from JavaScript drives the expected animations

**Success criteria:** A working web page where user interaction (via HTML controls) drives Rive animation state.

---

### Exercise 3: Input API Mapping (Intermediate)

Design the API between a game and a Rive UI file.

**Requirements:**
- Take one of your complex Rive files (a health bar, menu, or character)
- Document every input and data binding as an API:

```
# Character.riv API

## Inputs
- health (number, 0-1): Current health percentage
- isWalking (bool): Whether character is moving
- onDamage (trigger): Fire when character takes damage

## Data Bindings
- nameText (string): Character display name
- portraitImage (image): Character portrait
```

- For each input, write the game-side code that would set it (pseudocode or real code for your target platform)

**Success criteria:** A complete API document that a developer could use to integrate your Rive file without opening the Rive editor.

---

### Exercise 4: Platform Evaluation (Research)

Evaluate Rive runtime options for your specific project.

**Requirements:**
- Identify your target platform (LÖVE, Unity, web, mobile)
- Read the runtime documentation for that platform
- Build a decision matrix:
  - Does an official runtime exist?
  - What rendering backend does it use?
  - What's the state machine API like?
  - Are all features supported (blend states, nested artboards, data binding)?
  - What's the performance profile?
- If LÖVE: evaluate the four options listed in this module and recommend one for your project with reasoning

**Success criteria:** A written recommendation (1 page) on how to integrate Rive into your specific project, including fallback plans if the primary approach has issues.

---

## Recommended Reading & Resources

### Essential (Read First)

- [Rive Runtimes Overview](https://help.rive.app/runtimes/overview) — Platform matrix and general runtime concepts
- [Rive Web Runtime](https://help.rive.app/runtimes/overview/web-js) — Most accessible runtime for first integration
- [Rive GitHub Repositories](https://github.com/rive-app) — Open-source runtime code for all platforms

### Deepening

- [Rive Unity Runtime](https://help.rive.app/game-runtimes/unity) — Unity-specific integration guide
- [Rive C++ Runtime](https://help.rive.app/runtimes/overview/cpp) — Low-level runtime for custom engines (relevant for LÖVE FFI approach)
- [Rive Pricing](https://rive.app/pricing) — Current pricing tiers and what each includes

### Broader Context

- [Spine Runtimes](http://esotericsoftware.com/spine-runtimes) — For comparison: Spine's runtime ecosystem and integration patterns
- [LÖVE Wiki: Libraries](https://love2d.org/wiki/Category:Libraries) — LÖVE ecosystem context for understanding where Rive would fit

---

## Key Takeaways

1. **One .riv file contains everything.** Artwork, animations, state machines, listeners, data bindings — all in a compact binary. No asset pipeline complexity.

2. **The runtime pattern is universal.** Load → instantiate → configure inputs → advance + render each frame. This pattern is identical across all platforms.

3. **Your game code just sets inputs.** All animation logic lives in the .riv file. The developer's job is to map game state to Rive inputs. The designer owns everything else.

4. **No LÖVE runtime exists.** For LÖVE projects, use Spine for character animation (official runtime) and Rive for design workflow + sprite sheet export. The Rive skills you learn transfer to other engines.

5. **Rive and Spine complement each other.** Spine excels at complex character animation with code-driven logic. Rive excels at interactive UI with designer-owned logic. Many projects benefit from both.

6. **Export requires a paid plan.** The free tier is sufficient for learning. Budget $9/month when you're ready to ship.

7. **Web runtime is the easiest starting point.** If you want to see your Rive content running outside the editor, a simple HTML page with the web runtime is the fastest path.

---

## What's Next

In **[Module 9: Game-Specific Applications](module-09-game-applications.md)**, you'll apply everything from Modules 0–8 to concrete game development patterns. Animated menus, HUD elements, loading screens, dialogue systems, and notification popups — each built as a practical Rive project with state machine design, data binding, and production considerations.
