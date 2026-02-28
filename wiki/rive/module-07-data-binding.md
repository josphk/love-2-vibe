# Module 7: Data Binding & Dynamic Content

[← Back to Rive Learning Roadmap](rive-learning-roadmap.md)

**Time estimate:** 2–4 hours
**Prerequisites:** Modules 4–5 (state machine inputs, listeners)

---

## Overview

Until now, every visual element in your Rive files has been static content — text you typed, colors you picked, images you placed. Data binding changes that. It lets you declare that certain properties are dynamic: set at runtime by your application, not baked into the .riv file.

This is one of Rive's newer and most powerful features. A health bar whose fill level is driven by actual player health. A dialogue box whose text changes based on the current conversation. A profile card whose avatar image swaps based on the logged-in user. A themed interface whose colors adapt to dark mode. All of this is possible because data binding lets your application feed live data into your Rive animations, and the state machine and animation system respond to that data as if it were any other input.

For game development, data binding is the bridge between your game's data model and your animated UI. Instead of building separate UI rendering code, you design the UI in Rive and let the runtime populate it with live data.

### Learning Objectives

By the end of this module, you will be able to:

1. Bind text elements to runtime-provided strings
2. Bind colors to runtime values for dynamic theming
3. Bind images for runtime asset swapping
4. Bind numbers for data-driven visualizations
5. Combine data binding with state machines for reactive UI

---

## Core Concepts

### 1. What Data Binding Is

Data binding connects a property of a Rive element (text content, fill color, image source, numeric value) to an external data source. Instead of the property having a fixed value, it has a named binding that the runtime fills in.

**The mental model:**

```
Traditional: Text element → content = "Player 1"         (fixed)
Data-bound:  Text element → content = {{playerName}}      (filled at runtime)
```

At design time, you see placeholder content. At runtime, the application provides the actual value. The animation, state machine, and all visual behaviors work identically — they don't care whether the data was hardcoded or bound.

**What makes this different from inputs:**

State machine inputs (boolean, number, trigger) drive animation state — they control which animations play and how they blend. Data binding drives content — it controls what text appears, what color things are, what image shows. They're complementary:

| Feature | State Machine Inputs | Data Binding |
|---------|---------------------|--------------|
| Purpose | Control animation logic | Supply content |
| Types | Boolean, Number, Trigger | Text, Color, Image, Number |
| Drives | Transitions, blend states | Visual properties |
| Example | `isWalking = true` → play walk | `playerName = "Alice"` → show name |

In practice, you use both: data binding sets the health bar's text label to "HP: 75", while a number input drives the fill animation to 75%.

**Why it matters:** Data binding makes Rive files truly reusable. A single "PlayerCard" artboard works for every player in your game — just bind different data for each instance. Without data binding, you'd need a separate Rive file (or artboard) for each variant.

**Common mistake:** Confusing data binding with state machine inputs. If you want to change which animation plays, use an input. If you want to change what text appears, use data binding. Using the wrong mechanism creates unnecessary complexity.

**Try this now:** Add a text element to an artboard. In the inspector, look for data binding options (the exact UI depends on your Rive version). Set the text content to be data-bound with a name like `displayName`. Preview — you'll see placeholder text. This is the text your runtime will replace.

---

### 2. Text Binding

Text binding connects a Rive text element to a runtime-provided string. The text element retains all its styling (font, size, color, alignment, animation) but displays different content.

**Use cases:**

- Player name above a character
- Score display ("Score: 1,250")
- Dialogue box content
- Button labels (when one button design serves multiple purposes)
- Status messages ("Level Complete!", "Game Over")
- Item names in inventory UI
- Timer display ("2:45")

**Design considerations:**

- **Text overflow:** What happens when the runtime string is longer than your design expected? Rive text elements can be configured with wrapping, truncation, or auto-sizing. Plan for the longest reasonable string.
- **Font availability:** The font must be embedded in the .riv file. If you bind text at runtime, the characters must exist in the embedded font. This matters for localization — CJK characters need a font that includes them.
- **Styling vs content:** Data binding replaces content, not style. Font, size, color, and animation remain as designed. If you need different styling for different content, use multiple text elements controlled by visibility/solo.

**Animation with bound text:**

Bound text elements can still be animated. The text content changes via binding, but:
- The text element can scale, rotate, translate, and fade via timeline animation
- Color can be animated over time (flash red on damage, pulse on critical)
- A state machine can trigger text-appearance animations (slide in, bounce, typewriter reveal)

The binding provides the "what" (content), the animation provides the "how" (presentation).

**Why it matters:** Dynamic text is the most common data binding need in games. Scores, names, messages, labels — most game UI has text that changes. Without data binding, you'd render text in code and lose Rive's animation capabilities. With it, the text is fully integrated into the animated, interactive Rive system.

**Common mistake:** Not testing with varied text lengths. Your design looks great with "HP: 100" but breaks with "HP: 1,000,000". Always test with the shortest and longest expected strings to ensure the layout handles both.

**Try this now:** Create a score display: a decorative frame around a text element. Bind the text to `scoreText`. Animate the frame with a subtle idle pulse. Add a state machine with a `onScoreChange` trigger that plays a brief celebration animation (scale pop, color flash). Test with placeholder text. Imagine the runtime setting `scoreText = "1,250"` and firing `onScoreChange`.

---

### 3. Color Binding

Color binding lets you change fill and stroke colors at runtime. This enables dynamic theming, state-based coloring, and personalization.

**Use cases:**

- **Dark mode / light mode:** Bind background, text, and accent colors. Toggle entire theme by changing bound colors.
- **Team colors:** Player's team color applied to UI elements, character outlines, health bar fills.
- **State feedback:** Red for error, green for success, yellow for warning — bound to a status color.
- **Personalization:** User-chosen accent color applied across the UI.

**How it interacts with animation:**

Color binding sets the base color. Animations can still modify it:
- A bound base color of blue can animate to lighter/darker blue on hover
- A state machine can override the bound color during special states (damage flash overrides team color with red)
- The bound color acts as the resting state; animations modify relative to it

**Binding strategy:**

Identify the colors that need to be dynamic and create a naming scheme:

| Binding name | Purpose | Example value |
|-------------|---------|---------------|
| `primaryColor` | Main brand/team color | `#3B82F6` |
| `backgroundColor` | Panel/card background | `#1F2937` |
| `textColor` | Primary text color | `#F9FAFB` |
| `accentColor` | Highlights, CTAs | `#10B981` |
| `dangerColor` | Errors, critical states | `#EF4444` |

**Why it matters:** Color theming is a common requirement that's painful to implement without data binding. Imagine changing 30 colors across 10 UI elements for dark mode — manually creating alternate artboards for each theme is unsustainable. Data binding makes it one API call.

**Common mistake:** Binding too many colors. If every single shape has a bound color, the runtime API becomes unwieldy. Bind semantic colors (primary, secondary, accent, danger) and derive specific element colors from those in your Rive design.

**Try this now:** Create a simple card UI (background, title, accent stripe). Bind the background fill to `bgColor`, the accent stripe to `accentColor`, and the title text color to `textColor`. Switch between light and dark values in the test panel — the entire card should re-theme.

---

### 4. Image Binding

Image binding lets you swap images at runtime. The image element's transform, animation, and masking remain — only the image content changes.

**Use cases:**

- **Character portraits:** Swap face image based on who's speaking in dialogue
- **Inventory icons:** Same slot layout, different item images
- **Profile avatars:** User-uploaded images displayed in Rive UI
- **Dynamic backgrounds:** Swap scene image based on game level
- **Achievement badges:** Same badge frame, different achievement icon

**Design considerations:**

- **Aspect ratio:** If the bound image has a different aspect ratio than the design-time placeholder, it may crop or letterbox depending on fit mode. Design for a consistent aspect ratio, or use a masking shape that clips to a known area.
- **Image size:** Larger images increase memory usage. Specify maximum dimensions for bound images and downscale on the application side before binding.
- **Fallback:** Design with a visible placeholder that works if no image is bound. A silhouette, icon, or default avatar prevents a blank hole in the UI.

**How it interacts with animation:**

The image element can still be animated:
- Position, scale, rotation via timeline
- Opacity for fade in/out
- Clipping mask reveals (iris wipe, slide reveal)
- State machine transitions (swap image, then animate the new image in)

The image swap is content; the animation is presentation. Change the portrait, then play the "new speaker" animation.

**Why it matters:** Without image binding, every character portrait in a dialogue system would need its own artboard or shape. With binding, one dialogue box artboard handles any character — the runtime swaps the portrait image.

**Common mistake:** Not accounting for image load time. If swapping to a new image requires loading from network/disk, there's a frame where the old image might flash or the slot might be empty. Coordinate image preloading in your application code with the Rive animation timing.

**Try this now:** Create a profile card with a circular image frame (clipping mask on a circle). Place a placeholder image inside. Bind the image to `avatar`. The profile card should show the placeholder in the editor and accept a runtime-provided image. Add an animation that plays when the avatar changes (scale pop or fade transition).

---

### 5. Number Binding and Data-Driven Visualization

Number binding connects numeric properties to runtime values. Combined with state machine number inputs, this creates data-driven visualizations that are fully animated.

**The distinction: binding vs input:**

- **Number input** (state machine): Drives animation logic. `health = 0.3` causes the state machine to transition to "Critical" state.
- **Number binding** (data): Sets a visual property. `healthDisplay = 30` makes a text element show "30".

In practice, you often use both: the number input drives the animation behavior (fill level, color shift) while a bound text element displays the numeric value.

**Data-driven health bar (complete example):**

Properties:
- `health` (number input, 0–1): Drives fill blend state and color transitions
- `healthText` (text binding): Shows "HP: 75/100"
- `barColor` (color binding): Green/yellow/red based on threshold
- `onDamage` (trigger input): Plays shake + flash animation
- `onHeal` (trigger input): Plays glow + fill animation

The runtime sets all of these. The Rive file handles all the visual behavior:
- Fill level interpolates smoothly (blend state)
- Color shifts through thresholds (animated in blend state keypoints)
- Damage shake plays on trigger (state machine layer)
- Text updates to show current/max (data binding)

**Animated number transitions:**

When a number changes (score goes from 100 to 200), you can animate the transition:
- Rive's blend states smoothly interpolate visual properties
- For text, the runtime can send intermediate values (101, 102, ... 200) for a counting-up effect
- Or the text can snap while the visual animation handles the transition feel

**Why it matters:** Games are full of numbers — health, score, ammo, timer, experience, currency. Data binding lets you design how these numbers look and animate in Rive, then feed the actual values from your game loop.

**Common mistake:** Animating the number text counting up in Rive. Rive can't auto-interpolate text content — if you bind `scoreText = "200"`, it snaps to "200". If you want a counting-up effect, your runtime code must send intermediate values frame by frame. Rive handles the visual animation; the runtime handles the data interpolation.

**Try this now:** Build a compact stat display: a circular gauge with a number in the center. The gauge fill is driven by a number input `progress` (0–1) using a blend state. The center text is bound to `valueText`. Add a state machine layer with a `onChange` trigger that plays a brief pulse animation. When `progress` changes and `onChange` fires, the gauge smoothly fills while the text updates and the pulse plays.

---

## Case Studies

### Case Study 1: Dialogue Box System

**The problem:** A game needs an animated dialogue box that displays different characters, text, and expressions.

**The data-bound design:**

Bindings:
- `speakerName` (text): Character name displayed in name plate
- `dialogueText` (text): The dialogue content
- `portrait` (image): Character portrait image
- `nameColor` (color): Color of the name plate (matches character's theme)

State machine inputs:
- `mood` (number, 0–4): Neutral, Happy, Sad, Angry, Surprised → drives portrait expression via blend state
- `onShow` (trigger): Plays box-open animation
- `onHide` (trigger): Plays box-close animation
- `onNextLine` (trigger): Plays text transition (old text fades, new text fades in)

**Runtime flow:**
1. Game sets `speakerName = "Aria"`, `dialogueText = "Watch out!"`, `portrait = [ariaImage]`, `nameColor = #4FC3F7`
2. Game fires `onShow` → box animates open, portrait slides in, text appears
3. Game sets `mood = 3` (Angry) → portrait expression shifts
4. Player presses continue → game fires `onNextLine`, updates text/speaker bindings
5. Dialogue ends → game fires `onHide` → box animates closed

**Key insight:** One Rive artboard handles all dialogue in the game. Characters, text, expressions — all dynamic. The designer controls every animation, transition, and visual detail. The developer just feeds data.

---

### Case Study 2: Dynamic Leaderboard

**The problem:** A game needs an animated leaderboard showing top 5 players with names, scores, and avatars.

**The design:**

A parent artboard with 5 nested "LeaderboardRow" artboards.

Each LeaderboardRow has:
- `rankText` (text binding): "#1", "#2", etc.
- `playerName` (text binding): Player's display name
- `scoreText` (text binding): Formatted score
- `avatar` (image binding): Player's profile image
- `isHighlighted` (boolean input): Highlights the current player's row
- `onUpdate` (trigger input): Plays a value-change animation

Parent artboard:
- State machine manages row entrance animations (stagger from top to bottom)
- `onRefresh` trigger replays the entrance sequence when data updates

**Key insight:** The leaderboard is designed once but displays any data. Whether it's a local high score table or live multiplayer standings, the same Rive file handles it. The entrance stagger animation gives it polish that would take significant custom code to replicate.

---

### Case Study 3: Themed Game Menu

**The problem:** A game supports multiple visual themes (light, dark, seasonal) and the menu UI needs to adapt.

**The design:**

Core color bindings:
- `bgPrimary`, `bgSecondary`: Background colors
- `textPrimary`, `textSecondary`: Text colors
- `accent`: Highlight and CTA color
- `border`: Separator and frame color

Additional bindings:
- `bgImage` (image): Background art (changes seasonally)
- `logoImage` (image): Logo variant (could have seasonal versions)
- `welcomeText` (text): Greeting message ("Happy Holidays!" vs "Welcome Back!")

**Application code pattern:**

```
// Define themes as data objects
themes = {
    dark = { bgPrimary="#111827", textPrimary="#F9FAFB", accent="#6366F1" },
    light = { bgPrimary="#F9FAFB", textPrimary="#111827", accent="#4F46E5" },
    holiday = { bgPrimary="#1B4332", textPrimary="#F0FFF4", accent="#F59E0B" }
}

// Apply theme to Rive
applyTheme(rive, themes.dark)
```

**Key insight:** The Rive file is theme-agnostic. It doesn't know about "dark mode" or "holiday theme" — it just accepts color values. The theming logic lives in application code, which is appropriate because theme selection is an application-level concern.

---

## Common Pitfalls

1. **Binding vs animating conflicts:** If a property is data-bound AND animated on the timeline, the animation overrides the binding during playback. Plan which properties are bound (content) and which are animated (presentation). A text element's content is bound; its scale, position, and opacity are animated.

2. **Font embedding with bound text:** If the runtime provides text with characters not in the embedded font, those characters render as blank or fallback glyphs. Ensure your embedded font covers the character set your application will use (including numbers, punctuation, and any localized characters).

3. **Performance with many bindings:** Each data binding update triggers a recalculation in the Rive renderer. Updating 50 bindings every frame is expensive. Batch updates when possible and only update bindings when values actually change.

4. **Image binding memory:** Each bound image consumes GPU memory. If you're swapping between many images (e.g., 50 inventory icons), preload only the visible ones. Don't bind 50 images simultaneously if only 5 are on screen.

5. **Number precision in text:** When binding a number to a text display (score, percentage), format the number in your application code before binding the text. Don't bind a raw float — `scoreText = "1249.9999923"` is not what you want. Bind `scoreText = "1,250"` instead.

6. **State machine + binding timing:** When you update a binding and fire a trigger simultaneously, the visual update and the animation may not start on the same frame. The binding updates immediately; the state machine transition may take a frame to process. For tight synchronization, update bindings one frame before firing triggers.

---

## Exercises

### Exercise 1: Dynamic Badge (Beginner)

Build a badge/achievement notification.

**Requirements:**
- A badge frame (shield, star, or circle design)
- Text binding for `title` ("First Blood", "Sharpshooter", etc.)
- Color binding for `badgeColor` (bronze, silver, gold tint)
- State machine with `onShow` trigger that plays an entrance animation (scale from 0, bounce, settle)
- After entrance, a subtle idle animation (gentle glow or shimmer)

**Success criteria:** Changing the title and color bindings produces different badges, all with the same polished entrance animation.

---

### Exercise 2: Score Counter with Celebration (Intermediate)

Build a score display with animated feedback.

**Requirements:**
- Large score number (text binding: `scoreText`)
- Subtitle text (text binding: `label` — could be "Score", "Combo", "Streak")
- Number input `value` (0–1) driving a background fill/progress effect
- `onIncrement` trigger: plays a pop-up "+100" animation that fades out
- `onMilestone` trigger: plays a larger celebration effect (burst, sparkles, or scale pop)
- Color binding for accent color to match game theme

**Success criteria:** The counter shows dynamic text, responds to value changes with visual feedback, and fires different effects for regular updates vs milestones.

---

### Exercise 3: Character Info Card (Intermediate)

Build a character information card with full data binding.

**Requirements:**
- Portrait image (image binding: `portrait`)
- Character name (text binding: `characterName`)
- Character class (text binding: `className`)
- Health bar driven by number input `health` (0–1)
- Stat display: three text bindings for `attack`, `defense`, `speed`
- Color binding for `classColor` (warrior=red, mage=blue, rogue=green)
- State machine: `onSelect` trigger plays a card-flip reveal animation

**Success criteria:** The card works as a reusable component — binding different data produces different character cards, all with the same polished animations.

---

### Exercise 4: Live Dashboard Panel (Advanced)

Build a game dashboard with multiple data-bound elements.

**Requirements:**
- Central gauge (circular, fill driven by `mainValue` number input 0–1)
- Gauge center text (text binding: `mainDisplay` — e.g., "75%")
- Three stat bars below the gauge, each with:
  - Label text binding (`stat1Label`, `stat2Label`, `stat3Label`)
  - Value text binding (`stat1Value`, `stat2Value`, `stat3Value`)
  - Fill driven by number inputs (`stat1`, `stat2`, `stat3`, each 0–1)
- Color bindings for theme (`accentColor`, `backgroundColor`)
- `onUpdate` trigger: plays a refresh animation across all elements (staggered pulse)
- `onAlert` trigger: plays a warning effect on the gauge (red flash, pulse)

**Success criteria:** A dashboard that could display any three stats with any values, fully themed and animated.

---

## Recommended Reading & Resources

### Essential (Read First)

- [Rive Data Binding](https://help.rive.app/editor/data-binding) — Official documentation for setting up data bindings

### Deepening

- [Rive Runtimes Overview](https://help.rive.app/runtimes/overview) — How to access data bindings from each runtime (the API for setting bound values)
- [Rive Community Files](https://rive.app/community) — Search for files using data binding to see real-world patterns

### Broader Context

- [React Data Binding Concepts](https://react.dev/learn/responding-to-events) — If you come from web development, Rive's data binding is conceptually similar to React's props/state: external data drives internal rendering
- [Game UI Design Principles](https://www.gamedeveloper.com/) — Articles on designing data-driven game interfaces

---

## Key Takeaways

1. **Data binding separates content from presentation.** The Rive file defines how things look and animate. The runtime provides what data to show. This separation makes Rive files genuinely reusable.

2. **Four binding types cover most needs.** Text for labels and messages, colors for theming, images for visual content, numbers for gauges and indicators.

3. **Binding and inputs are complementary.** Inputs drive animation logic (which state, what blend). Bindings drive content (what text, what image). Use both together for full dynamic UI.

4. **Design for variable content.** Test with the shortest and longest expected strings. Account for missing images. Handle edge case values (0%, 100%, negative, overflow).

5. **Format data in your application, not in Rive.** Numbers should be pre-formatted as strings ("1,250" not 1249.999). Dates, currencies, and localized strings are the application's responsibility.

6. **One artboard, many instances.** A data-bound artboard is a template. The same health bar design serves every character in the game with different bound data.

---

## What's Next

In **[Module 8: Exporting & Runtime Integration](module-08-exporting-runtime.md)**, you'll learn how to get your Rive creations out of the editor and into real applications. You'll understand the .riv export format, explore the available runtimes (including the honest assessment of the LÖVE situation), and see the runtime API pattern for loading files, setting inputs, and binding data.
