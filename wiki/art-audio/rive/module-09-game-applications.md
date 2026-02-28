# Module 9: Game-Specific Applications

[← Back to Rive Learning Roadmap](rive-learning-roadmap.md)

**Time Estimate:** 4–6 hours (building one complete component), 12–16 hours (building all five categories)
**Prerequisites:** [Module 4: The State Machine](module-04-state-machine.md), [Module 5: Listeners & Interactivity](module-05-listeners-interactivity.md), [Module 7: Data Binding](module-07-data-binding.md)

---

## Overview

You've learned Rive's individual systems — vector drawing, bones, state machines, listeners, data binding, exporting. Now it's time to apply them to the thing you're actually here for: making games.

Even if Rive isn't your primary character animation tool (Spine handles that better for LÖVE), Rive *excels* at game UI. Menus, HUD elements, dialogue boxes, loading screens, notification popups — these are the places where Rive's state machine + interactivity model outperforms every alternative. A designer can build a complete interactive button with hover/press/disabled states, spring physics, and sound triggers — all in one .riv file, no code changes needed.

This module walks through five concrete game UI categories with enough detail to actually build them.

### Learning Objectives

By the end of this module, you should be able to:

1. Design animated menus and buttons with full interaction states
2. Build HUD elements driven by game data (health, ammo, score)
3. Create loading screens and level transitions that go beyond spinning circles
4. Construct dialogue systems with character portraits, mood changes, and choice UI
5. Design notification/popup systems that feel polished and game-appropriate

---

## 1. Animated Menus & Buttons

### Why This Matters

Buttons are the first thing players interact with. A static rectangle with text says "I didn't care about this part." An animated button with hover feedback, press response, and spring physics says "every part of this game was crafted." The quality bar for game UI has risen dramatically — players notice.

### Anatomy of a Game Button

A complete game button in Rive typically needs:

**Visual States:**
- **Idle** — default appearance, possibly with subtle ambient animation (gentle glow, slight float)
- **Hover** — visual change when cursor enters (scale up, color shift, glow intensify)
- **Pressed** — response to click/tap (scale down, color darken, satisfying squish)
- **Disabled** — grayed out, no interaction response
- **Selected/Active** — for toggle buttons or menu items that stay selected

**State Machine Design:**

```
Inputs:
  - isHovered (boolean) — set by listener
  - isPressed (boolean) — set by listener
  - isDisabled (boolean) — set by game code
  - isSelected (boolean) — set by game code

States:
  Entry → Idle
  Idle → Hover        (when isHovered == true AND isDisabled == false)
  Hover → Idle        (when isHovered == false)
  Hover → Pressed     (when isPressed == true)
  Pressed → Hover     (when isPressed == false AND isHovered == true)
  Pressed → Idle      (when isPressed == false AND isHovered == false)
  Any State → Disabled (when isDisabled == true)
  Disabled → Idle     (when isDisabled == false)
```

**Listener Setup:**
- Pointer Enter on button shape → sets `isHovered = true`
- Pointer Exit on button shape → sets `isHovered = false`
- Pointer Down on button shape → sets `isPressed = true`
- Pointer Up on button shape → sets `isPressed = false`

### Transition Timing Guide

| Transition | Duration | Easing | Why |
|-----------|----------|--------|-----|
| Idle → Hover | 100–150ms | Ease out | Fast response feels snappy |
| Hover → Pressed | 50–80ms | Linear | Near-instant confirms the click |
| Pressed → Hover | 150–200ms | Ease out (overshoot) | Spring-back feels satisfying |
| Any → Disabled | 200ms | Ease in-out | Smooth enough to notice |
| Disabled → Idle | 150ms | Ease out | Snappy re-enable |

### Menu Transitions

Menus aren't just collections of buttons — they're screens that need entrance and exit animations.

**Common patterns:**
- **Slide in** — menu panel slides from off-screen. Use a number input for direction (left, right, top, bottom).
- **Scale + fade** — menu scales from 0.8 to 1.0 while fading from 0% to 100% opacity. Feels modern and light.
- **Staggered reveal** — menu items appear one by one with slight delays. Creates a cascading effect that draws the eye downward through options.
- **Spring physics** — overshoot on entrance (scale to 1.05 then settle to 1.0). Adds life without feeling slow.

**State machine for a menu screen:**

```
Inputs:
  - showMenu (boolean) — triggers entrance/exit

States:
  Entry → Hidden
  Hidden → Entering    (when showMenu == true)
  Entering → Visible   (automatic, after entrance animation completes)
  Visible → Exiting    (when showMenu == false)
  Exiting → Hidden     (automatic, after exit animation completes)
```

### Navigation Elements

For menus with multiple selectable items (like a main menu with Play, Options, Credits):

- Use a **number input** for the selected index
- Each menu item checks if its index matches the selection
- Animate the "selected" indicator (underline, highlight, arrow) to slide between positions rather than jump
- Consider a separate state machine layer for the selection indicator vs. the individual button states

### Common Mistakes

- **No disabled state.** Players will click buttons during transitions. Without a disabled state, you get double-triggers or broken navigation.
- **Hover animations that block.** If your hover animation takes 500ms and the player moves fast, the button feels laggy. Keep hover transitions under 150ms.
- **Forgetting keyboard/gamepad.** Mouse hover is great for PC, but console games need focus states driven by input index, not cursor position. Design your state machine to accept both listener-driven and code-driven selection.

---

## 2. HUD Elements

### Why This Matters

The HUD is the most data-driven part of game UI. Health changes, ammo depletes, scores increment, timers count down — all in real-time, all needing to feel good. Rive's data binding and state machine make HUD elements that would require complex code in a traditional approach.

### Health Bar

The health bar is the canonical example. Here's how to build a complete one:

**Artboard Structure:**
```
health-bar (artboard)
├── background (rectangle, dark)
├── fill-bar (rectangle, clipped or scaled)
├── damage-flash (rectangle, red, 0% opacity normally)
├── border-frame (decorative frame on top)
├── health-text (text element, optional)
└── warning-overlay (animated effect for critical health)
```

**State Machine Design:**

```
Inputs:
  - healthPercent (number, 0–100) — bound to fill width/scale
  - takeDamage (trigger) — fires damage animation
  - heal (trigger) — fires heal animation
  - isCritical (boolean) — true when health < 20%

Layer 1: Fill State
  - Fill animation driven by healthPercent
  - Fill bar width = healthPercent% of max width
  - Color transitions: green (100–60%), yellow (60–30%), red (30–0%)

Layer 2: Effects
  Entry → Idle
  Idle → DamageShake   (when takeDamage fires)
  DamageShake → Idle   (automatic, after shake completes)
  Idle → HealGlow      (when heal fires)
  HealGlow → Idle      (automatic, after glow completes)

Layer 3: Critical Warning
  Entry → Normal
  Normal → Warning     (when isCritical == true)
  Warning → Normal     (when isCritical == false)
  // Warning state: pulsing red overlay, maybe screen edge vignette
```

**Key Techniques:**
- **Smooth depletion:** Don't snap the fill bar to the new value. Use Rive's animation interpolation — animate from current width to target width over 200–300ms.
- **Color gradient:** Animate the fill color along with the width. At 100% health the bar is green; at 50% it's yellow; at 20% it's red. Use a blend state driven by `healthPercent` with keyframes at these breakpoints.
- **Damage feedback:** The `takeDamage` trigger fires a quick shake animation (3–5 frames of horizontal offset) plus a red flash overlay that fades out.
- **Heal feedback:** Green particle-like glow that rises, plus a brief brightness boost on the fill bar.

### Ammo Counter

**Approach 1: Numeric display**
- Text element bound to ammo count
- Scale/bounce animation on the text when value changes (trigger: `ammoChanged`)
- Color shift when ammo is low (number input drives blend state)
- "Empty" state with distinct warning animation

**Approach 2: Visual bullets**
- Individual bullet icons that disappear as ammo depletes
- Use visibility/solo animation — each bullet has a "present" and "absent" state
- Reload animation plays all bullets reappearing in sequence
- More visually interesting but requires more artboard complexity

**State Machine:**
```
Inputs:
  - ammoCount (number)
  - maxAmmo (number, or hardcoded in design)
  - reload (trigger)
  - fire (trigger)

States:
  Idle → Firing       (when fire triggers)
  Firing → Idle       (automatic)
  Idle → Reloading    (when reload triggers)
  Reloading → Idle    (automatic, after reload animation)
  Any State → Empty   (when ammoCount == 0)
```

### Score Display

Score displays need satisfying increment animations:

- **Rolling numbers:** Animate from old value to new value over 300–500ms, digits rolling like an odometer
- **Scale pop:** Brief scale-up (1.0 → 1.2 → 1.0) when score changes
- **Particle burst:** Small celebratory effect on score increase
- **Combo multiplier:** Separate element that appears/scales when combos are active

**Implementation in Rive:**
- Text binding for the score number
- Trigger input `scoreChanged` that fires the pop/particle animation
- Number input `comboMultiplier` that drives a blend state (hidden at 1x, visible and growing at higher multipliers)

### Minimap Frame

The minimap content is rendered by the game engine, but the frame can be a Rive element:

- Animated border (subtle pulse, glow effects)
- Directional indicator that rotates with player facing
- Alert state when enemies are nearby (border turns red, pulses faster)
- Expansion animation for zooming in/out

### Common Mistakes

- **Animating too much.** HUD elements are peripheral — they should inform, not distract. Idle animations should be barely noticeable. Save dramatic effects for state changes (taking damage, scoring).
- **Not testing at game speed.** A health bar that looks great in isolation might feel sluggish when health drops during fast gameplay. Test your animations in context, at game pace.
- **Hardcoding values.** A health bar that assumes max health is 100 breaks when you add a power-up that raises it to 150. Use ratios (healthPercent = current/max * 100) rather than absolute values.

---

## 3. Loading & Transition Screens

### Why This Matters

Loading screens are dead time. Players are waiting. An engaging loading animation transforms that wait from frustrating to pleasant — and it signals that the game is still working, not frozen.

### Loading Indicators

Go beyond the spinning circle:

**Character-based loaders:**
- Your game's character performing an idle animation
- Character running/walking (suggesting progress)
- Character interacting with a loading-themed prop (turning a crank, pushing a gear)

**Thematic loaders:**
- A quill drawing a map (for an adventure game)
- Gears turning (for a steampunk game)
- Pixels assembling into an image (for a retro game)
- A cauldron bubbling (for a fantasy game)

**Progress-driven loaders:**
- Use a number input (0–100) for actual load progress
- Animate a fill, progress bar, or path drawing along with the load
- Add "phase" text binding: "Loading assets...", "Building world...", "Almost ready..."

**State Machine:**
```
Inputs:
  - loadProgress (number, 0–100)
  - isComplete (boolean)

States:
  Entry → Loading
  Loading → Complete   (when isComplete == true)
  Complete → FadeOut   (automatic, after "ready" animation)

  // Loading state: loop animation + progress-driven elements
  // Complete state: celebratory animation, "Press any key" text appears
```

### Level Transitions

Level transitions are brief (0.5–2 seconds) and need to feel seamless:

**Wipe transitions:**
- Directional wipe (left-to-right, top-to-bottom)
- Iris wipe (circle closing in, classic Mario-style)
- Custom shape wipe (star, hexagon, thematic to your game)
- All achievable with animated clipping masks in Rive

**Fade transitions:**
- Simple fade to black and back
- Fade to a color that matches the destination (blue for underwater level, orange for desert)
- Fade with a brief overlay element (game logo, level name)

**Animated transitions:**
- Doors closing then opening
- A curtain dropping and rising
- The screen "shattering" into pieces then reassembling
- A character animation that covers the screen (running across, jumping through)

**Implementation pattern:**
```
Inputs:
  - startTransition (trigger)
  - transitionType (number) — 0: wipe, 1: fade, 2: iris
  - showLevelName (boolean)

States:
  Entry → Idle (transparent, not blocking)
  Idle → TransitionOut   (when startTransition fires)
  TransitionOut → Hold   (automatic, screen fully covered)
  Hold → TransitionIn    (automatic or trigger-driven, after level loads)
  TransitionIn → Idle    (automatic, screen clear)
```

The game engine triggers `startTransition`, waits for the "Hold" state (screen fully covered), loads the new level, then advances to `TransitionIn`.

### Splash Screens

First impressions matter:

- Studio logo with animated reveal (draw-on effect using trim paths)
- Game title with dramatic entrance (scale, particles, lighting effects)
- Interactive elements even on the splash (parallax on mouse move, clickable Easter eggs)
- "Press Start" text with idle animation (pulse, shimmer, glow)

### Common Mistakes

- **Loading animation stalls.** If your loading animation loops every 2 seconds but the load takes 15 seconds, players see the same loop 7+ times. Design loops that have enough variation to stay interesting, or tie animation to actual progress.
- **Transition too slow.** Level transitions should be fast (0.5–1.5s per direction). A 3-second transition feels like a loading screen masquerading as an animation.
- **No skip option.** Splash screens should be skippable after the first view. Build a "skip" state into your state machine.

---

## 4. Dialogue Systems

### Why This Matters

Dialogue is where story meets UI. A static text box with a portrait is functional. An animated text box with expression changes, emphasis effects, and interactive choice buttons is *immersive*. Rive is uniquely suited to dialogue UI because it combines animation, interactivity, and data binding in one file.

### Dialogue Box Architecture

**Artboard Structure:**
```
dialogue-box (artboard)
├── box-background (shape with 9-slice or stretchable design)
├── character-portrait (nested artboard — the key piece)
├── speaker-name (text, bound to character name)
├── dialogue-text (text, bound to current dialogue line)
├── continue-indicator (animated arrow/prompt)
├── choice-container (group, shown only during choices)
│   ├── choice-1 (nested button artboard)
│   ├── choice-2 (nested button artboard)
│   └── choice-3 (nested button artboard)
└── box-decorations (animated borders, corners)
```

### Character Portraits with Expressions

This is where nested artboards shine:

**Portrait artboard (reusable component):**
```
character-portrait (artboard)
├── body (static or breathing idle)
├── face
│   ├── eyes (with blink animation)
│   ├── eyebrows (position-driven by expression)
│   ├── mouth (shape-driven by expression)
│   └── extras (blush, sweat drops, etc.)

Inputs:
  - expression (number) — 0: neutral, 1: happy, 2: sad, 3: angry, 4: surprised
  - isTalking (boolean) — drives mouth animation
  - blink (trigger) — manual blink trigger (also auto-blinks on timer)
```

The parent dialogue box sets the portrait's `expression` input when dialogue changes mood. The portrait handles all the animation internally — the parent just says "be happy" or "be angry."

### Expression Changes

**Blend state approach:**
- Create a 1D blend state driven by the `expression` number input
- Keyframe each expression at integer values (0=neutral, 1=happy, etc.)
- Transitions between expressions automatically interpolate
- Benefit: transitioning from expression 1 to expression 3 passes smoothly through expression 2

**Discrete state approach:**
- Separate animation states for each expression
- Transitions with short blend times (100–200ms)
- More control over specific transitions (angry-to-sad might animate differently than happy-to-sad)
- Better for expressions that don't blend well (neutral mouth doesn't interpolate naturally to surprised O-shape)

### Dialogue Text Presentation

Rive doesn't do typewriter-style text reveal natively (it would need per-character control). Options:

- **Full text swap:** Bind the text element to the full dialogue line. Text appears all at once. Simple, works well.
- **Hybrid approach:** Game engine handles typewriter effect on a text element, Rive handles everything else (box animation, portrait, decorations). The text element is rendered by the game engine on top of or within the Rive artboard.
- **Reveal animation:** Fade in the text element (opacity 0→1 over 200ms). Not typewriter, but adds a transition feel.

### Choice Buttons

When dialogue presents choices:

**State machine for the choice system:**
```
Inputs:
  - showChoices (boolean)
  - choiceCount (number) — how many choices to show (1–4)
  - choice1Text, choice2Text, choice3Text (text bindings)
  - selectedChoice (number) — which choice the player is hovering/focusing

States:
  Entry → Hidden
  Hidden → Revealing    (when showChoices == true)
  Revealing → Shown     (automatic, after entrance animation)
  Shown → Hidden        (when showChoices == false)
```

Each choice button is a nested artboard with its own hover/press states (reuse the button component from section 1). The parent dialogue box controls which choices are visible and feeds them their text.

### Dialogue Box Animation

The box itself needs animation:

- **Entrance:** Slide up from bottom, scale from 0, or unfold from center
- **Exit:** Reverse of entrance, or a quick fade
- **Text change:** Subtle bounce or pulse when new dialogue line appears
- **Speaker change:** Brief exit-and-re-enter when the speaking character changes
- **Emphasis:** Shake on angry dialogue, grow on surprised dialogue, gentle wave on sad dialogue

**State machine:**
```
Inputs:
  - isVisible (boolean)
  - newLine (trigger) — fires when dialogue text changes
  - emphasis (number) — 0: none, 1: shake, 2: bounce, 3: wave
  - speakerChanged (trigger)

Layer 1: Visibility
  Hidden → Entering (when isVisible == true)
  Entering → Visible (automatic)
  Visible → Exiting (when isVisible == false)
  Exiting → Hidden (automatic)

Layer 2: Text Effects
  Idle → TextPulse (when newLine fires)
  TextPulse → Idle (automatic)

Layer 3: Emphasis
  Driven by emphasis number via blend state
```

### Common Mistakes

- **Portraits that clip.** If expressions change the character's silhouette (arms raised, hair standing up), make sure the portrait container has enough padding. Clipping during animation looks broken.
- **Choice buttons without keyboard support.** Dialogue choices must support keyboard/gamepad selection (up/down to navigate, confirm to select). Don't rely solely on mouse listeners.
- **Box resize without animation.** When switching from 2-line to 4-line dialogue, the box should smoothly resize, not snap. Animate the box height.

---

## 5. In-Game Notifications

### Why This Matters

Notifications are the "juice" — the small touches that make a game feel polished. Achievement popups, damage numbers, quest updates, item pickups. Individually small, collectively massive for game feel.

### Achievement Popups

**Structure:**
```
achievement-popup (artboard)
├── background-panel (slides in from edge)
├── icon-container (animated icon specific to achievement)
├── title-text ("Achievement Unlocked!")
├── description-text (bound to achievement name)
├── progress-bar (optional, for progressive achievements)
└── particles/glow effects
```

**Lifecycle:**
1. Entrance: panel slides in from top-right (or wherever your game places them)
2. Display: holds for 3–5 seconds
3. Exit: slides back out

**State machine:**
```
Inputs:
  - show (trigger)
  - achievementName (text binding)
  - iconType (number) — which icon to display

States:
  Entry → Hidden
  Hidden → Entering    (when show fires)
  Entering → Display   (automatic)
  Display → Exiting    (automatic, timed — exit time: 4 seconds)
  Exiting → Hidden     (automatic)
```

**Polish details:**
- Icon does a celebratory animation during Display (bounce, spin, glow)
- Sound trigger on Entering state
- Gold/sparkle particles during Display
- Subtle parallax on the background panel

### Damage Numbers

Damage numbers need to be spawned dynamically (one per hit), so Rive handles the animation template, and the game engine handles instantiation:

**Single damage number artboard:**
```
Inputs:
  - damageValue (text binding)
  - isCritical (boolean)
  - play (trigger)

Animation:
  - Scale from 0 to 1.0 (or 1.5 for critical) over 100ms
  - Float upward over 800ms
  - Fade out over last 300ms
  - Critical hits: larger scale, different color, screen shake (handled by game engine)
```

The game engine creates a new instance of this artboard for each hit, positions it at the damage location, sets the value and critical flag, fires `play`, and destroys it after the animation completes.

### Quest Updates

**Structure:**
```
quest-notification (artboard)
├── banner-background
├── quest-icon (type-specific: main quest, side quest, etc.)
├── status-text ("New Quest" / "Quest Updated" / "Quest Complete")
├── quest-name (text binding)
├── objective-text (text binding, optional)
└── decorative elements
```

**State variations:**
- "New Quest": grand entrance, gold color, fanfare icon animation
- "Quest Updated": subtle entrance, silver color, brief icon pulse
- "Quest Complete": celebratory entrance, special effect, checkmark animation

Use a number input for `questStatus` (0: new, 1: updated, 2: complete) driving a blend state or discrete states for the different visual treatments.

### Item Pickup Notifications

Briefer than quest updates:

- Small popup near the action (not screen edge)
- Item icon + name + quantity
- Quick entrance (100ms), brief hold (1s), quick exit (200ms)
- Stack multiple pickups (each new one pushes previous ones up)

### Common Mistakes

- **Notifications that block gameplay.** Notifications should never obscure critical gameplay elements. Position them in safe areas and keep them brief.
- **No queue system.** If 5 achievements trigger simultaneously, they shouldn't overlap. The game engine needs a queue — show one at a time, or stack them.
- **Over-animated.** A 3-second entrance animation on a damage number that should flash and disappear in 800ms total kills the game's pacing.

---

## Case Study 1: Complete Game Menu Screen

**The Challenge:** Build a main menu for a 2D adventure game with: title, three buttons (Play, Options, Credits), animated background, and a character that reacts to button hover.

**Artboard Architecture:**
```
main-menu (parent artboard)
├── background-art (parallax layers)
├── title-logo (animated entrance)
├── btn-play (nested button artboard)
├── btn-options (nested button artboard)
├── btn-credits (nested button artboard)
├── character-mascot (nested artboard with reactions)
└── ambient-particles
```

**Implementation Steps:**

1. **Background:** 3 layers at different parallax rates, driven by cursor position (pointer move listener). Subtle, but adds depth.

2. **Title:** Entrance animation plays once on menu load. Idle animation loops after (subtle glow, gentle float).

3. **Buttons:** Each is a nested artboard instance sharing the same button component. Each has its own exposed `isHovered` and `isPressed` inputs.

4. **Character mascot:** Watches the cursor (eye tracking from Module 5). Reacts to button hover — points at the hovered button, or changes expression.

5. **State machine layers:**
   - Layer 1: Menu entrance sequence (staggered reveal of title → buttons → character)
   - Layer 2: Button interaction (each button's state machine runs independently via nesting)
   - Layer 3: Character reactions (driven by which button is hovered)
   - Layer 4: Ambient effects (particles, background animation, loops independently)

**What Makes It Work:** The menu feels alive because multiple independent systems animate simultaneously. The character reacting to button hover creates a connection between UI and world. The staggered entrance gives each element a moment of attention.

---

## Case Study 2: Animated Health Bar with Full Feedback

**The Challenge:** Build the health bar described in the module exercises — with idle pulse, damage shake, heal glow, critical warning, and smooth depletion.

**Implementation:**

1. **Fill bar** scaled by `healthPercent` number input (0–100). Uses a blend state with three keyframes:
   - At 100: fill color = green, width = full
   - At 50: fill color = yellow, width = half
   - At 0: fill color = red, width = zero

2. **Damage response** on `takeDamage` trigger:
   - Frame 0–2: horizontal shake (offset ±3px, ±2px, ±1px)
   - Frame 0–4: red flash overlay (opacity 0→80→0%)
   - Frame 0–6: "lost health" ghost segment fades out (shows the chunk that was lost)

3. **Heal response** on `heal` trigger:
   - Frame 0–3: brief green glow along the fill bar
   - Frame 0–5: small sparkle particles rise from the bar

4. **Critical state** driven by `isCritical` boolean:
   - Looping red pulse on the border (opacity oscillates 50%→100%)
   - Heartbeat-like rhythm on the fill bar (slight scale pulse)
   - Warning icon appears at the end of the bar

5. **Idle state** (subtle, always running):
   - Very slight shimmer on the fill bar (a highlight that sweeps left to right, barely noticeable)

**Runtime Integration:**
```
// Game code (pseudocode)
healthBar.setNumberInput("healthPercent", player.health / player.maxHealth * 100)

if (player.justTookDamage) {
    healthBar.fireTrigger("takeDamage")
}
if (player.justHealed) {
    healthBar.fireTrigger("heal")
}
healthBar.setBoolInput("isCritical", player.health < player.maxHealth * 0.2)
```

---

## Case Study 3: Dialogue System with Mood-Reactive Portraits

**The Challenge:** Build a dialogue box with a character portrait that changes expression based on the dialogue mood, animated text transitions, and interactive choice buttons.

**Implementation:**

1. **Portrait component** (nested artboard):
   - 5 expressions (neutral, happy, sad, angry, surprised) as a 1D blend state
   - Idle blink animation on a separate layer (random timing, 3–7 second intervals)
   - `isTalking` boolean drives a simple mouth open/close loop
   - Expression transitions take 200ms with ease-in-out

2. **Dialogue box** (parent artboard):
   - Box entrance/exit animated (slide up + fade, 300ms)
   - `newLine` trigger causes a brief pulse on the box (scale 1.0→1.02→1.0, 150ms)
   - `speakerChanged` trigger causes box to briefly exit and re-enter (quick — 200ms out, 200ms in)
   - Speaker name text bound to `speakerName` input
   - Dialogue text bound to `dialogueText` input

3. **Choice buttons** (nested artboard instances):
   - Up to 4 choices, visibility controlled by `choiceCount` number input
   - Each choice has hover/press/selected states
   - Selected choice briefly scales up before the box exits
   - Entrance: staggered slide-in from right (choice 1 first, then 2, etc.)

4. **Connecting it all:**
   - Game dialogue engine sets `speakerName`, `dialogueText`, `expression` for each line
   - Fires `newLine` when text changes, `speakerChanged` when speaker changes
   - Sets `showChoices`, `choiceCount`, and choice text bindings when player reaches a decision point
   - Reads `selectedChoice` to determine which branch to follow

---

## Common Pitfalls (All Categories)

1. **Designing in isolation.** Your health bar looks great against a white background. Does it read clearly over busy gameplay art? Always test UI elements against representative game backgrounds.

2. **Forgetting mobile/console input.** Hover states don't exist on touch devices. Gamepad users can't point-click. Every interactive element needs a code-driven selection state alongside (or instead of) pointer listeners.

3. **Overloading one artboard.** Resist putting your entire HUD in a single artboard. Separate artboards for health bar, ammo counter, minimap, score, etc. The game engine composites them. This keeps each artboard's state machine manageable and allows independent updates.

4. **Ignoring animation budget.** Ten simultaneously animating Rive artboards on a mobile device will hurt frame rate. Profile early. Simplify animations for low-end targets.

5. **Static text in the .riv file.** Don't bake "Health" or "Score" into the design as static text if you might localize. Use text binding for everything that might change — including labels, not just values.

6. **No fallback for missing data.** What does your health bar show if `healthPercent` is never set? What does the dialogue box display with empty text? Design sensible defaults — a full health bar and placeholder text are better than a broken-looking element.

---

## Exercises

### Exercise 1: Interactive Button Component (Beginner)
Build a reusable game button with these states: idle (subtle glow pulse), hover (scale up + brighten), pressed (scale down + darken), disabled (grayscale + no interaction). Use listeners for hover and press. Test that rapid mouse movement doesn't break the state machine.

### Exercise 2: Animated Health Bar (Intermediate)
Build the health bar described in Case Study 2. Requirements: smooth fill driven by a number input, color transitions (green→yellow→red), damage shake on trigger, heal glow on trigger, critical warning state when health is below 20%. Bonus: add a "shield" overlay that absorbs damage before health, with its own visual treatment.

### Exercise 3: Dialogue Box System (Advanced)
Build a dialogue box with: animated entrance/exit, character portrait with at least 3 expressions (driven by number input), text binding for speaker name and dialogue text, a `newLine` trigger that animates the text transition, and choice buttons (2–4) that appear on command with hover states. The portrait should blink independently of expression changes.

### Exercise 4: Complete Notification Stack (Advanced)
Build a notification system with three notification types (achievement, quest update, item pickup) that share a common entrance/exit pattern but have distinct visual treatments. Each type uses different color schemes, icons, and animation emphasis. Use nested artboards so all three types can be instantiated from the game engine independently.

---

## Recommended Reading & Resources

### Essential
- [Rive Help Center — Artboards & Nesting](https://help.rive.app) — Reference for nested artboard setup
- [Rive Community Files](https://rive.app/community) — Search for "game UI", "button", "health bar" for real examples
- [Game UI Database](https://www.gameuidatabase.com/) — Screenshot reference for professional game UI (not Rive-specific, but invaluable for design inspiration)

### Supplementary
- [Juice It or Lose It (GDC Talk)](https://www.youtube.com/watch?v=Fy0aCDmgnxg) — The classic talk on game feel through UI polish
- [The Art of Game Design (Schell), Chapter on UI](https://www.schellgames.com/art-of-game-design/) — Framework for thinking about player interface

### Advanced
- [Rive Runtime Documentation](https://help.rive.app/runtimes) — Details on programmatic input control
- [Material Design Motion Guidelines](https://m3.material.io/styles/motion/overview) — Not game-specific, but the principles of easing, duration, and choreography apply directly

---

## Key Takeaways

1. **Rive's sweet spot is game UI.** Even if you use another tool for character animation, Rive excels at interactive menus, HUD elements, dialogue boxes, and notifications.

2. **State machine design is UX design.** The states and transitions you define determine how the UI *feels*. Fast transitions feel snappy; slow transitions feel heavy. Match the pacing to your game's tone.

3. **Nested artboards are your component system.** Build buttons once, reuse everywhere. Build a portrait once, drop it into any dialogue box. This is the same component thinking from web/app development, applied to game UI.

4. **Data binding connects game state to visuals.** Health percentage, ammo count, score, dialogue text — bind them and let Rive handle the visual response. The game engine just feeds numbers and strings.

5. **Polish is in the transitions.** The difference between "functional" and "polished" is in the entrance animations, the feedback effects, the idle states. These take time but define the player's impression of your game.

---

## What's Next

[Module 10: Workflow, Optimization & Production Tips →](module-10-workflow-optimization.md)

You've built individual game UI components. Module 10 covers the workflow for managing them in production: organizing your Rive files, optimizing for performance, collaborating with developers, versioning binary assets, and a suggested practice progression to solidify all your skills.
