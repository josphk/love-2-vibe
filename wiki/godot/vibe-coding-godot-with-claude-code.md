# Vibe Coding Godot with Claude Code

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Type:** Workflow guide
**Prerequisites:** [Module 0: Setup & First Scene](module-00-setup-first-scene.md) (you should know the editor basics)

---

## Overview

Godot is a hybrid engine — part code, part visual editor. Unlike pure-code frameworks (Love2D, React Three Fiber) where Claude Code can generate 100% of the project from the terminal, Godot stores scenes and resources as text files (`.tscn`, `.tres`) that Claude can read and generate, but the visual editor is still essential for spatial layout, physics tuning, and UI positioning. The trick is knowing which half of the work to hand to Claude and which half to do yourself in the editor. This guide maps out that split and gives you a practical workflow.

---

## 1. What Claude Code Can Do vs. What Needs the Editor

| Claude Code handles well | Editor is better / required |
|---|---|
| GDScript files (`.gd`) — full scripts from scratch or modifications | Visual scene layout — placing nodes in 3D/2D space by eye |
| Shader code (`.gdshader`) — vertex, fragment, light functions | Physics layer/mask checkboxes — 32 layers, named in Project Settings |
| `.tscn` / `.tres` generation and editing — scenes and resources are text | Animation keyframing — the timeline in AnimationPlayer is visual |
| `project.godot` settings — resolution, input maps, autoloads, rendering | UI anchoring and layout preview — Control nodes need visual feedback |
| Input map configuration — action names, key/gamepad bindings | Particle effect tuning — GPUParticles3D needs real-time preview |
| Resource files — materials, themes, environment configs | Tilemap painting — TileMap and TileSet editors are fully visual |
| Export presets (`export_presets.cfg`) | Lighting and environment preview — WorldEnvironment, DirectionalLight3D |
| Plugin and tool script code | Debugging with remote scene tree — the running game's node inspector |
| Autoload singletons and scene tree structure | Navigation mesh baking — requires the editor's bake button |

The boundary isn't hard. Claude *can* write raw `.tscn` with node positions, and sometimes that's useful for scaffolding. But if you need a tree placed at exactly the right spot on a hillside, you'll drag it there in the viewport. Think of Claude as your code author and the editor as your spatial canvas.

---

## 2. The Hybrid Workflow

This is the loop you'll settle into. It works for new features, bug fixes, and exploratory prototyping.

**Step 1 — Describe what you want to build.** Tell Claude the game mechanic or feature in plain English. Be specific about behavior: "a double-jump that resets when the player lands" is better than "make jumping better."

**Step 2 — Claude generates scripts + scene files.** You get `.gd` scripts and `.tscn` scene files written to disk. Claude can also modify `project.godot` to register input actions or autoloads.

**Step 3 — Open in Godot editor, hit reload.** Godot watches the filesystem. When files change on disk, it detects the changes and reimports. If a scene is open, you may see a dialog asking to reload — click "Reload." For script changes while the game is *not* running, Godot picks them up automatically.

**Step 4 — Playtest (F5).** Run the game. Observe the behavior. The Godot output panel shows `print()` statements and errors. The debugger panel shows the call stack on crashes.

**Step 5 — Describe what's wrong.** Paste error messages from the Godot output panel. Describe visual bugs ("the player clips through the floor," "the health bar fills right-to-left instead of left-to-right"). If you can, paste a screenshot — Claude can read images and identify layout or rendering issues.

**Step 6 — Iterate.** Claude fixes scripts and scene files. You adjust spatial and visual things in the editor — nudging positions, tweaking material colors, resizing UI containers. This is the back-and-forth that gets things done.

**Step 7 — When stuck on editor-side things, ask Claude to guide you.** Claude can't click buttons for you, but it can tell you exactly what to click, where to find settings, and what values to enter. "How do I set up a collision layer for enemies?" gets you a step-by-step walkthrough of the editor UI.

---

## 3. Key Godot Concepts Claude Code Users Should Know

- **`.tscn` files are text.** They look like INI files with `[node]` and `[sub_resource]` blocks. Claude can read, write, and diff them. When you see a `.tscn` in the file tree, know that it's not a binary blob — it's editable code.

- **`project.godot` is INI-like config.** Input actions, autoloads, display settings, rendering options — all stored as key-value pairs. Claude can edit this directly, and Godot picks up the changes on reload.

- **Scene tree = node hierarchy.** Every Godot scene is a tree of nodes. Claude generates this hierarchy as text in `.tscn` files. The editor visualizes the same tree in the Scene dock. Same data, two views.

- **The Inspector panel is where you tune values Claude set in code or scenes.** Select any node in the scene tree and its properties appear in the Inspector on the right. Every `@export` variable, every physics property, every material slot — all tweakable there.

- **`@export` variables appear in the Inspector.** This is the bridge between code and editor. Claude writes `@export var speed: float = 200.0` in a script, and you see a "Speed" field in the Inspector that you can drag to adjust in real time. Use `@export` liberally — it makes tuning fast without touching code.

- **Resources (`.tres`) are shared data objects.** Materials, themes, curves, gradients — these are all resources that can be saved as `.tres` files. Claude can generate them as text. They're referenced by path in `.tscn` files.

---

## 4. Example Prompts

### Scaffolding a new feature
- *"Create a CharacterBody3D player scene with WASD movement and mouse look. Include a Camera3D as a child node. Save it as `player.tscn` with the script as `player.gd`."*
- *"Set up an enemy scene with a basic state machine — idle, chase, and attack states. Use an Area3D for detection range."*
- *"Add an `input_map` section to `project.godot` with actions for move_left, move_right, jump, and interact, mapped to WASD and spacebar."*

### Generating / editing scene files
- *"Read `main_menu.tscn` and add a Settings button between Start and Quit. Wire it to a `_on_settings_pressed` function."*
- *"Create a HUD scene with a ProgressBar for health, a Label for score, and a TextureRect for the minimap frame. Use a MarginContainer as root."*

### Debugging
- *"Here's the error from Godot's output panel: `Invalid call. Nonexistent function 'get_overlapping_bodies' in base 'CharacterBody3D'.` What's wrong and how do I fix it?"*
- *"My player falls through the floor. The floor is a StaticBody3D with a CollisionShape3D. The player is a CharacterBody3D. What am I likely missing?"*

### Asking Claude to guide you through editor steps
- *"Walk me through setting up collision layers in the Godot editor. I want the player on layer 1, enemies on layer 2, and projectiles on layer 3, with the right masks so projectiles hit enemies but not the player."*
- *"How do I create a Curve3D path for enemies to patrol along? Step-by-step in the editor."*

### Asking for explanations
- *"Explain the difference between `_process` and `_physics_process` and when I should use each."*
- *"What's the difference between an Area3D and a StaticBody3D? When would I use one vs. the other?"*

---

## 5. Limitations & Workarounds

**Claude can't see your viewport.** It doesn't know what the game looks like when running. Workaround: describe what you see, paste error output, or share a screenshot. Claude can analyze images and give feedback on visible issues.

**Physics tuning is iterative.** Getting jump height, gravity, friction, and collision shapes to feel right takes real-time testing. Workaround: ask Claude to put physics values behind `@export` variables so you can drag sliders in the Inspector while the game runs (if using tool mode) or between runs.

**Animation keyframes are hard to author as raw `.tscn`.** The AnimationPlayer data format in `.tscn` files is verbose and tricky to write by hand. Workaround: create animations in the editor's timeline, then ask Claude for the code-based approach using `AnimationPlayer.create_animation()` or Tween nodes for simpler motion.

**UI layout needs the editor for pixel-perfect results.** Claude can generate the full node tree — containers, margins, anchors — but getting a UI to look right at different resolutions requires visual feedback. Workaround: let Claude scaffold the node hierarchy and set anchor presets, then adjust sizing and spacing in the editor's 2D viewport.

**Godot's scene reload has quirks.** Sometimes Godot doesn't pick up external `.tscn` changes cleanly, especially if the scene is open in the editor. Workaround: if things look stale, close the scene tab and reopen it, or use Scene > Reload Saved Scene.
