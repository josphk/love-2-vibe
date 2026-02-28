# Module 4: The State Machine (Rive's Superpower)

[← Back to Rive Learning Roadmap](rive-learning-roadmap.md)

**Time estimate:** 3–5 hours
**Prerequisites:** Modules 0–3 (orientation, vector design, rigging, timeline animation)

---

## Overview

The state machine is the feature that separates Rive from every other animation tool. In traditional animation workflows — Spine, After Effects, CSS animations — you create animations as isolated clips and then write code to manage transitions between them. Which animation plays when? What happens during the crossfade? What if two inputs conflict? You solve all of that in code, and it gets complex fast.

Rive inverts this. You build the transition logic visually, directly in the editor. States, transitions, conditions, blending — all defined by the designer, all testable without writing a single line of code. Your game code reduces to setting input values: `isWalking = true`, `health = 0.3`, `fire("onDamage")`. The state machine handles the rest.

This module teaches you to think in states and transitions — a mental model that applies far beyond Rive. Finite state machines are everywhere in game development: character controllers, AI behavior, UI flows, dialogue systems. Mastering them here gives you a transferable skill.

### Learning Objectives

By the end of this module, you will be able to:

1. Design a state machine that manages multiple animations with clean transitions
2. Use all three input types (boolean, number, trigger) appropriately
3. Build layered state machines for independent animation concerns
4. Create blend states for smooth animation mixing
5. Test and debug state machines entirely in the Rive editor

---

## Core Concepts

### 1. States

A state is a node in your state machine graph that plays an animation. When the state machine is "in" a state, that state's animation plays. Simple as that.

**Types of states:**

- **Animation state:** Plays a specific timeline animation. This is the most common type. You create a state, assign it an animation (like "Idle" or "Walk"), and configure playback (loop, ping-pong, one-shot).
- **Entry state:** The starting point. Every state machine has one. When the artboard loads, the state machine begins at Entry and immediately follows any unconditional transition to your default state.
- **Exit state:** Ends the state machine. Rarely used in game contexts (you usually want the state machine running indefinitely), but useful for one-shot UI sequences like a splash screen that plays once and stops.
- **Any State:** A special source that can transition to any other state regardless of the current state. Think of it as a global interrupt — "no matter what's happening, if `onDamage` fires, go to the Hurt state."
- **Blend state:** Instead of playing a single animation, it blends between multiple animations based on a numeric input. Covered in detail later in this module.

**Why it matters:** States enforce structure. Instead of a tangle of `if/elseif` chains in code deciding which animation plays, you have a clear visual graph. Each state has one job: play its animation. The transitions handle the switching logic.

**Common mistake:** Creating too many states for variations that should be handled by blend states. If you have `Walk_Slow`, `Walk_Normal`, `Walk_Fast` as separate states with transitions between them, you're fighting the tool. Use a single blend state controlled by a `speed` number input instead.

**Try this now:** In a new Rive file, create a simple artboard with a shape. Make two timeline animations: "Idle" (subtle pulse) and "Active" (bigger movement). Switch to the State Machine, and you'll see the Entry state already there. Add two animation states, assign your animations, and draw a transition from Entry to the Idle state.

---

### 2. Transitions

Transitions are the arrows connecting states. They define when and how the state machine moves from one state to another.

**Transition properties:**

- **Duration:** How long the crossfade takes. A 300ms transition blends the outgoing and incoming animations smoothly. A 0ms transition snaps instantly.
- **Exit time:** When the transition can fire relative to the current animation's playback. "After 80% of the animation has played" prevents a walk cycle from cutting off mid-stride.
- **Conditions:** Rules that must be satisfied for the transition to fire. Without conditions, a transition fires as soon as exit time is reached.
- **Interpolation:** How the blend between outgoing and incoming animations is eased. Linear is the default. Cubic gives a smoother feel.

**Transition evaluation order:**

When multiple transitions leave the same state, Rive evaluates them top-to-bottom in the transitions list. The first transition whose conditions are met fires. This ordering matters — put your most specific conditions first and your fallback transitions last.

**Why it matters:** Transitions are where the "feel" of your interactive animation lives. A snappy 100ms transition feels responsive for UI buttons. A 400ms transition with easing feels natural for character locomotion. Getting transition timing right is the difference between animations that feel mechanical and animations that feel alive.

**Common mistake:** Setting exit time on transitions that should fire immediately. If the user clicks a button, the press animation should start now — not after the idle animation finishes its current loop. For immediate responses, set exit time to 0 or disable it.

**Try this now:** In your test file, draw a transition from Idle to Active and another from Active back to Idle. Set no conditions yet — just unconditional transitions with different durations. Preview the state machine and watch it ping-pong between states. Experiment with transition duration (0ms vs 200ms vs 500ms) to feel the difference.

---

### 3. Inputs

Inputs are the variables that drive your state machine. They're the API surface between your animation and the outside world — whether that's user interaction in the editor or game code at runtime.

**Boolean inputs:**

True/false values. Best for binary states: `isHovering`, `isPressed`, `isWalking`, `isAlive`, `isDarkMode`. Transitions check boolean conditions: "when `isHovering` == true, transition from Normal to Hover."

```
// In game code:
stateMachine.setBool("isWalking", player.velocity > 0)
```

**Number inputs:**

Numeric values. Best for continuous ranges: `health` (0–100), `speed` (0–1), `progress` (0–1), `rotation` (-180–180). Used with both transition conditions ("when `health` < 20, go to Critical state") and blend states ("blend between idle and walk based on `speed`").

```
// In game code:
stateMachine.setNumber("health", player.health / player.maxHealth)
```

**Trigger inputs:**

One-shot events. They fire once and auto-reset — you can't "hold" a trigger. Best for discrete events: `onClick`, `onDamage`, `onLevelUp`, `onCollect`. Transitions respond to triggers: "when `onDamage` fires, transition to Hurt state."

```
// In game code:
stateMachine.fire("onDamage")
```

**Choosing the right input type:**

| Situation | Input type | Why |
|-----------|-----------|-----|
| Something is on or off | Boolean | Persistent binary state |
| Something has a range of values | Number | Continuous interpolation |
| Something happened once | Trigger | Fire-and-forget event |
| Mouse is hovering | Boolean | State persists while hovering |
| User clicked a button | Trigger | Discrete moment |
| Player health | Number | Continuous 0–100 range |
| Player is dead | Boolean | Binary threshold |

**Why it matters:** Choosing the wrong input type creates awkward workarounds. If you use a boolean for a click event, you have to manually reset it. If you use a trigger for hover state, you can't maintain the hover because triggers auto-reset. Match the input type to the nature of the data.

**Common mistake:** Using number inputs where booleans would be clearer. If your number only ever takes values 0 and 1, and transitions only check `== 0` or `== 1`, it should be a boolean. Numbers are for ranges and blend states.

**Try this now:** Add three inputs to your state machine: a boolean `isActive`, a number `intensity` (0–1), and a trigger `reset`. Set conditions on your transitions: Idle→Active fires when `isActive` == true, Active→Idle fires when `isActive` == false. In the editor preview, toggle the boolean and watch the transitions fire.

---

### 4. Conditions on Transitions

Conditions are rules attached to transitions that determine when the transition can fire. A transition without conditions fires whenever its exit time is reached. A transition with conditions fires only when all conditions are satisfied.

**Condition operators:**

- Boolean: `== true`, `== false`
- Number: `==`, `!=`, `>`, `>=`, `<`, `<=`
- Trigger: (no operator — the condition is simply "this trigger was fired")

**Multiple conditions on one transition:**

When you add multiple conditions to a single transition, they're AND-ed together. All conditions must be true for the transition to fire. For example: "transition when `isGrounded` == true AND `speed` > 0.5" — both must be satisfied simultaneously.

**OR logic:**

Rive doesn't have an explicit OR operator on conditions. Instead, you create multiple transitions between the same two states, each with different conditions. If any transition's conditions are met, that transition fires.

Example: "Go to Alert state when `health` < 20 OR when `onDangerNearby` fires" → create two separate transitions from Normal to Alert, one with each condition.

**Why it matters:** Conditions are the decision logic of your state machine. Well-designed conditions make your state machine predictable and debuggable. Poorly designed conditions create hard-to-trace bugs where "the wrong animation plays sometimes."

**Common mistake:** Creating circular transitions without clear conditions. If State A transitions to State B on `isActive == true` and State B transitions to State A on `isActive == true`, you'll get an infinite loop. Make sure transition conditions create clean, non-overlapping paths.

**Try this now:** Add a condition to your Idle→Active transition: `isActive == true AND intensity > 0.5`. Now the transition only fires when both conditions are met. Toggle the boolean alone in the preview — nothing happens. Set the number above 0.5 — still nothing. Set both — the transition fires. This is how you create precise animation control.

---

### 5. Layers

Layers let you run multiple state machines simultaneously on the same artboard. Each layer operates independently, controlling different aspects of your animation.

**Why layers exist:**

Without layers, you'd need states for every combination of behaviors. A character that can be idle or walking, AND happy or sad, AND blinking or not blinking would need 2 × 2 × 2 = 8 states. With three layers (body, expression, blink), you need only 2 + 2 + 2 = 6 states. The combinatorial explosion disappears.

**How layers interact:**

Each layer animates its own set of properties. The body layer controls position, rotation, and scale of body bones. The expression layer controls face-related properties. The blink layer just animates eyelid position. As long as layers don't animate the same property, they compose cleanly.

**When layers DO conflict:**

If two layers animate the same property, the top layer wins. This is useful for override effects — a "damage flash" layer at the top can override any color, no matter what the base animation is doing.

**Layer use cases in games:**

| Layer | Controls | States |
|-------|----------|--------|
| Locomotion | Body position, limbs | Idle, Walk, Run, Jump |
| Expression | Face bones, eyes, mouth | Neutral, Happy, Sad, Angry |
| Blink | Eyelids only | Open, Blinking (on timer) |
| Effects | Overlay, particles, flash | None, Damage, Heal, LevelUp |

**Why it matters:** Layers are how you manage complexity in real projects. A game character with 10 animations across 3 behavioral dimensions is manageable. Without layers, you'd need dozens of states and transitions to cover every combination.

**Common mistake:** Putting everything in one layer. If your single layer's state machine graph looks like spaghetti, it's time to split into layers. A good rule: if two groups of states never interact (body motion doesn't care about facial expression), they belong in separate layers.

**Try this now:** Add a second layer to your state machine. Keep the first layer controlling overall state (Idle/Active). In the second layer, create a simple blink animation that plays on a loop independent of the first layer. Preview it — the blink should play regardless of whether the main state is Idle or Active.

---

### 6. Blend States

Blend states mix between multiple animations based on a numeric input value, producing smooth interpolation instead of hard transitions.

**1D Blend State:**

A single number input controls the blend. You define animation keypoints along the range:

- `speed` = 0 → Idle animation (100%)
- `speed` = 0.5 → Walk animation (100%)
- `speed` = 1.0 → Run animation (100%)
- `speed` = 0.3 → 60% Idle + 40% Walk (interpolated)

The beauty: you don't define the in-between poses. Rive interpolates them automatically. As `speed` increases from 0 to 1, the character smoothly transitions from idle through walk to run with no popping or jarring transitions.

**Additive blending:**

Instead of replacing animations, additive blending layers an animation on top of whatever's currently playing. Use cases:

- A "lean left/right" additive animation on top of a walk cycle
- A "breathing" additive animation on top of any pose
- A "recoil" additive animation on top of an aim pose

**2D Blend State (Joystick):**

Two number inputs control blending in two dimensions. Think of it as a grid:

```
         Look Up
            |
Look Left --+-- Look Right
            |
         Look Down
```

A character's head direction can be driven by two inputs (`lookX`, `lookY`) and Rive blends between four directional poses. This is how you create smooth head tracking or aim direction.

**Why it matters:** Blend states eliminate the most common source of animation jank: hard transitions between similar animations. Walking to running should be a gradient, not a switch. Blend states make it one.

**Common mistake:** Setting blend keypoints at uneven intervals without adjusting the input range. If your game sends `speed` values from 0–10, but your blend keypoints are at 0, 0.5, and 1.0, most of your range (1–10) maps to the same animation. Normalize your inputs to match your blend keypoints.

**Try this now:** Replace your two separate animation states with a single 1D blend state. Map your `intensity` number input to blend between the Idle animation (at 0) and the Active animation (at 1). Drag the number slider in the preview and watch the smooth interpolation.

---

## Case Studies

### Case Study 1: Interactive Button with Full State Coverage

**The problem:** A game needs buttons that feel responsive and polished, with clear visual feedback for every interaction state.

**The state machine design:**

States:
- **Normal** — default appearance, subtle idle animation (breathing scale or gentle glow)
- **Hover** — slightly enlarged, highlight effect
- **Pressed** — scaled down, darkened
- **Disabled** — desaturated, no animation

Inputs:
- `isHovering` (boolean) — set by pointer enter/exit listeners
- `isPressed` (boolean) — set by pointer down/up listeners
- `isDisabled` (boolean) — set by game code

Transitions:
1. Entry → Normal (unconditional)
2. Normal → Hover (when `isHovering == true AND isDisabled == false`)
3. Hover → Normal (when `isHovering == false`)
4. Hover → Pressed (when `isPressed == true`)
5. Pressed → Hover (when `isPressed == false AND isHovering == true`)
6. Pressed → Normal (when `isPressed == false AND isHovering == false`)
7. Any State → Disabled (when `isDisabled == true`)
8. Disabled → Normal (when `isDisabled == false`)

**Key design decisions:**
- The Disabled transition comes from Any State because disabling should work regardless of current state
- Pressed→Normal handles the case where the user clicks and drags off the button
- Pressed→Hover handles the normal click release while still hovering
- All transitions are short (100–150ms) for snappy UI feel

**What this teaches:** Even a "simple" button has 8 transitions when you cover all edge cases. The state machine makes these edge cases visible and testable. In code, this would be a mess of boolean flags and timing logic.

---

### Case Study 2: Character Locomotion with Blend States

**The problem:** A character needs to smoothly transition between idle, walk, and run based on movement speed, with an independent jump system.

**State machine design (2 layers):**

**Layer 1: Ground Movement (blend state)**

Instead of separate states for idle/walk/run, use a single 1D blend state:
- Input: `moveSpeed` (number, 0–1)
- Keypoints: 0.0 → Idle, 0.4 → Walk, 1.0 → Run

This single blend state replaces three animation states and all transitions between them. The character smoothly transitions from idle through walk to run as `moveSpeed` changes.

**Layer 2: Jump Override**

States:
- **Grounded** (no animation — lets Layer 1 play through)
- **Jump_Ascend** (jump-up animation)
- **Jump_Apex** (float at top)
- **Jump_Descend** (falling animation)
- **Land** (landing impact)

Inputs:
- `isGrounded` (boolean)
- `onJump` (trigger)
- `verticalSpeed` (number)

Transitions:
1. Entry → Grounded
2. Grounded → Jump_Ascend (when `onJump` fires)
3. Jump_Ascend → Jump_Apex (when `verticalSpeed` < 0.1)
4. Jump_Apex → Jump_Descend (when `verticalSpeed` < -0.1)
5. Jump_Descend → Land (when `isGrounded == true`)
6. Land → Grounded (after animation completes, exit time = 100%)

**Key design decisions:**
- The ground movement layer runs continuously, even during jumps. The jump layer's animations only affect upper body or overlay the movement.
- `verticalSpeed` drives apex/descent detection rather than timers, keeping the animation synced with actual physics.
- Land returns to Grounded only after the landing animation completes (exit time), preventing premature return to idle.

**What this teaches:** Layers separate concerns. Ground movement and jumping are independent systems. Adding a new ground state (crouch, sprint) doesn't affect the jump layer at all.

---

### Case Study 3: UI Health Bar with Event Reactions

**The problem:** A health bar that doesn't just fill/deplete but reacts to game events with personality.

**State machine design:**

**Layer 1: Fill Level**

A single blend state driven by `health` (number, 0–1):
- At 1.0: Full bar, green color, gentle pulse animation
- At 0.5: Half bar, yellow color, slightly faster pulse
- At 0.2: Low bar, red color, urgent pulsing
- At 0.0: Empty bar, flat gray

The color transitions and pulse speed are baked into the blend animations — no conditional logic needed.

**Layer 2: Events**

States:
- **Idle** (no overlay effect)
- **Damage** (screen shake, red flash, bar jitters)
- **Heal** (green glow, bar sparkles)
- **Critical** (persistent warning effect — red border, heartbeat)

Inputs:
- `onDamage` (trigger)
- `onHeal` (trigger)
- `isCritical` (boolean) — set when health drops below 20%

Transitions:
1. Entry → Idle
2. Idle → Damage (when `onDamage` fires)
3. Damage → Idle (exit time 100%)
4. Damage → Critical (exit time 100%, when `isCritical == true`)
5. Idle → Heal (when `onHeal` fires)
6. Heal → Idle (exit time 100%)
7. Idle → Critical (when `isCritical == true`)
8. Critical → Idle (when `isCritical == false`)

**What this teaches:** Combining a blend state layer for continuous data (health percentage) with a discrete event layer (damage/heal reactions) is a powerful pattern. The health bar is both data-driven and event-reactive.

---

## Common Pitfalls

1. **The "mega state machine":** Putting every behavior in one layer creates an unmanageable graph. If you have more than 8–10 states in a single layer, you probably need to split into multiple layers.

2. **Forgotten Any State transitions:** If a trigger should work from any state (like `onDamage`), use Any State as the source. If you only transition from specific states, you'll miss edge cases where the event fires during an unexpected state.

3. **Exit time confusion:** Exit time is a percentage of the current animation, not absolute time. A 2-second animation with 50% exit time transitions after 1 second. A 0.5-second animation with 50% exit time transitions after 0.25 seconds. This catches people when animations have different lengths.

4. **Boolean vs trigger confusion:** Using a boolean for a one-shot event means you have to reset it manually (either in code or with another transition). Triggers auto-reset. If you find yourself adding "reset" transitions just to clear a boolean, switch to a trigger.

5. **Transition priority bugs:** When multiple transitions can fire simultaneously, only the first one (top of the list) fires. If your "damage" transition is below your "idle" transition and both conditions are met, you'll never see the damage animation. Reorder transitions with the most important/specific conditions first.

6. **Blend state dead zones:** If your blend keypoints are at 0.0, 0.5, and 1.0, but your game only sends values between 0.0 and 0.3, you'll only ever see a blend between the first two animations. The third animation is wasted. Map your blend keypoints to your actual data range.

7. **Ignoring the test panel:** Rive's editor lets you toggle inputs and scrub numbers in real-time. If you're not testing in the editor, you're missing the tool's biggest advantage. Test every transition and edge case before exporting.

---

## Exercises

### Exercise 1: Toggle Switch (Beginner)

Build an animated toggle switch with a state machine.

**Requirements:**
- Two states: Off and On
- One boolean input: `isOn`
- The toggle knob slides from left to right (or vice versa) with a smooth transition
- The background color changes between the two states
- Transition duration: 200ms with ease-in-out

**Success criteria:** Toggling the boolean in the editor preview smoothly animates between Off and On states in both directions.

---

### Exercise 2: Character Expression System (Intermediate)

Build a character face with a state machine controlling expressions.

**Requirements:**
- Create a simple face (eyes, eyebrows, mouth)
- States: Neutral, Happy, Sad, Surprised, Angry
- One number input: `expression` (0–4, where each integer maps to an expression)
- Transitions from Any State to each expression, conditioned on the number value
- Each expression should have a subtle idle animation (blinking for Neutral, slight smile oscillation for Happy, etc.)

**Bonus:** Add a second layer for autonomous blinking that works regardless of expression.

**Success criteria:** Scrubbing the number input between 0–4 smoothly transitions between all five expressions, and blinking continues independently.

---

### Exercise 3: Multi-Layer Character Controller (Advanced)

Build a character with a full locomotion state machine.

**Requirements:**
- **Layer 1 — Body:** 1D blend state with `speed` input (0–1) blending between Idle (0), Walk (0.5), and Run (1.0)
- **Layer 2 — Expression:** States for Neutral, Alert, and Exhausted with transitions based on `speed` (Exhausted when speed > 0.8, Alert when speed > 0.3, Neutral otherwise)
- **Layer 3 — Actions:** States for None, Wave, and Attack, triggered by `onWave` and `onAttack` triggers. Actions play once and return to None.
- All three layers operate simultaneously

**Success criteria:** You can adjust `speed` to blend body animation, expression changes automatically based on speed, and action triggers play one-shot animations regardless of current speed.

---

### Exercise 4: Full Game Menu State Machine (Advanced)

Build a game menu screen with interconnected state machines.

**Requirements:**
- Main menu with three buttons (Play, Settings, Quit)
- Each button is a nested artboard with its own state machine (Normal, Hover, Pressed states)
- The parent artboard has a state machine managing screen transitions:
  - Main Menu → Settings Panel (slides in from right)
  - Settings Panel → Main Menu (slides back)
- Use a trigger input `onNavigate` and a number input `targetScreen` to control navigation
- The entire flow should work with just editor preview — no code

**Success criteria:** You can hover and click buttons in preview, navigate between screens with animated transitions, and the entire UI flow feels polished.

---

## Recommended Reading & Resources

### Essential (Read First)

- [Rive State Machine Documentation](https://help.rive.app/editor/state-machine) — Complete reference for state machine features
- [Rive Inputs](https://help.rive.app/editor/state-machine/inputs) — Detailed guide to boolean, number, and trigger inputs
- [Rive Transitions](https://help.rive.app/editor/state-machine/transitions) — Transition timing, conditions, and configuration

### Deepening

- [Rive Layers](https://help.rive.app/editor/state-machine/layers) — Multi-layer state machine design
- [Rive Blend States](https://help.rive.app/editor/state-machine/blend-states) — 1D and 2D blend state setup
- [Rive Community Files](https://rive.app/community) — Study real-world state machine designs by reverse-engineering community files

### Broader Context

- [Finite State Machines in Game Development](https://gameprogrammingpatterns.com/state.html) — Robert Nystrom's "Game Programming Patterns" chapter on the State pattern. The same mental model, applied in code.
- [Rive Blog: State Machine Deep Dives](https://rive.app/blog) — Official tutorials and feature announcements

---

## Key Takeaways

1. **States are exclusive within a layer.** The state machine is in exactly one state per layer at any time. This constraint is what makes state machines predictable.

2. **Inputs are your API.** Boolean for persistent binary state, number for continuous ranges, trigger for one-shot events. Choose the right type for the data.

3. **Transitions define feel.** Duration, exit time, and easing determine whether your animations feel responsive or sluggish. Tune these obsessively.

4. **Layers separate concerns.** Body movement, facial expression, and effects should be independent layers. This prevents combinatorial explosion and keeps each layer simple.

5. **Blend states replace multiple similar states.** If you have idle/walk/run as separate states with transitions, you probably want a blend state instead.

6. **Test in the editor.** Rive's preview panel lets you toggle every input and test every transition. Use it. The state machine is only as good as the edge cases you've tested.

7. **The designer owns the logic.** With state machines, animation logic lives in the .riv file, not in game code. Designers can iterate on feel and timing without developer involvement.

---

## What's Next

In **[Module 5: Listeners & Interactivity](module-05-listeners-interactivity.md)**, you'll connect your state machines to direct user input. Listeners let your animations respond to hovers, clicks, and cursor movement — making your state machines interactive without writing any code. You'll build pointer tracking, hover effects, and click reactions that work entirely within the Rive editor.
