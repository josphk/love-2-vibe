# Module 11: UI & Menus

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** [Module 5: Signals, Resources & Game Architecture](module-05-signals-resources-architecture.md)

---

## Overview

Every game needs UI: menus, HUDs, health bars, inventory screens, loading indicators. Godot has a complete UI system built on Control nodes — a hierarchy of buttons, labels, containers, and layout tools that handles anchoring, responsive sizing, theming, and keyboard/gamepad navigation out of the box. The system is mature, expressive, and deeply integrated with the rest of the engine. You won't be reaching for a third-party library here.

The key mental shift: Control nodes are separate from your 3D scene. They live in a CanvasLayer that renders on top of everything, completely unaffected by the 3D camera. You build layouts with containers (VBoxContainer, HBoxContainer, MarginContainer) that automatically handle sizing and placement, then style everything with a Theme resource that controls fonts, colors, and styleboxes globally across every Control node in your scene. Change the Theme once; the whole UI updates.

By the end of this module, you'll build a complete game UI kit: a main menu with Start/Settings/Credits buttons, an in-game HUD with health bar and score, a pause menu overlay, a minimap rendered via SubViewport, and a loading screen with a real progress bar backed by Godot's threaded ResourceLoader. These aren't toy examples — the patterns here are the same ones used in shipped games.

---

## 1. Control Nodes: The UI Building Blocks

`Control` is the base class for every UI element in Godot. It has a `position`, `size`, `rect_min_size`, anchor settings, and a full focus system. You never use `Control` directly — you use its many subclasses. Here's the full toolkit.

### The Core Nodes

**Label** — Displays text. Key properties:
- `text`: the string to display
- `horizontal_alignment` / `vertical_alignment`: LEFT, CENTER, RIGHT, TOP, BOTTOM
- `autowrap_mode`: wraps text inside the available rect
- `visible_characters`: how many characters to show (use for typewriter effects)

**Button** — A clickable button. The most-used UI node. Key properties and signals:
- `text`: button label
- `pressed` signal: emitted on click
- `disabled`: grays out the button and stops input
- `toggle_mode`: turns it into a toggle (on/off)
- Use `TextureButton` instead when you want image-based buttons with hover/pressed/disabled states.

**TextureRect** — Displays a `Texture2D`. Stretch modes control how the image fills the rect:
- `STRETCH_KEEP`: original size, no scaling
- `STRETCH_SCALE`: stretch to fill (may distort)
- `STRETCH_KEEP_ASPECT_CENTERED`: scale to fit, maintain ratio, center it
- `STRETCH_TILE`: tile the texture

**ProgressBar** — Health bars, loading bars, XP bars. Key properties:
- `value`: current value (0–100 by default)
- `min_value` / `max_value`: define the range
- `show_percentage`: toggles the built-in percentage label
- Style the fill and background separately via the "fill" and "background" StyleBoxes in the theme.

**LineEdit** — Single-line text input. Player name entry, chat, search boxes. Signals:
- `text_changed(new_text)`: fires on every keystroke
- `text_submitted(new_text)`: fires when Enter is pressed

**TextEdit** — Multi-line text area. Debug consoles, notes, editors. Has `text_changed` but no submit signal — handle that yourself with `get_line()`.

**RichTextLabel** — Formatted text using BBCode. Great for dialogue, item descriptions, changelogs:
- `bbcode_enabled = true`: enable the parser
- `text = "[b]Bold[/b] and [color=red]red[/color]"`: set content
- `visible_characters`: control how many characters render (typewriter effect)
- Built-in animated effects: `[wave]`, `[shake]`, `[rainbow]`

**Panel** — A styled background rectangle. No content on its own — nest other nodes inside it. Its appearance is controlled entirely by its "panel" StyleBox.

**CheckBox / CheckButton** — Boolean toggles. CheckBox looks like a checkbox, CheckButton looks like an iOS-style toggle. Both emit `toggled(button_pressed: bool)`.

**SpinBox** — Numeric input with up/down arrows. Good for settings that need integer ranges.

**HSlider / VSlider** — Drag a handle along a track. Perfect for volume and brightness sliders. Emits `value_changed(value: float)`.

**OptionButton** — A dropdown selector. Add items with `add_item("Label", id)`. Emits `item_selected(index: int)`.

### Creating Nodes from Code

Sometimes you need to build UI dynamically:

```gdscript
extends Control

func _ready() -> void:
    var label := Label.new()
    label.text = "Hello, Godot!"
    label.add_theme_font_size_override("font_size", 32)
    add_child(label)

    var button := Button.new()
    button.text = "Click Me"
    button.pressed.connect(func(): print("Clicked!"))
    add_child(button)
```

The `add_theme_*_override` methods let you override a single property from the theme on a specific node — useful for one-off adjustments without breaking your global Theme.

---

## 2. Containers: Automatic Layout

This is the rule: **never position UI nodes with absolute coordinates**. Absolute positions break on different screen sizes, different resolutions, and different aspect ratios. Containers solve this. They automatically measure their children, apply spacing, and update when the window resizes. Always use containers.

### The Container Toolkit

**VBoxContainer** — Stacks children vertically, top to bottom. Adds separation between children (controlled by the `separation` constant in the theme).

**HBoxContainer** — Stacks children horizontally, left to right.

**MarginContainer** — Adds padding around a single child. Use it as the outermost wrapper for any panel to keep content away from the edges. Properties: `add_theme_constant_override("margin_left", 16)` etc.

**CenterContainer** — Centers its single child in the available space. Use it for splash screens, loading indicators, or anything that should be dead-center.

**GridContainer** — Grid layout. Set `columns` to define the number of columns; rows are added automatically. Perfect for inventory grids, settings pages, ability bars.

**PanelContainer** — Combines MarginContainer behavior with a Panel background. Draws a StyleBox behind its content. Saves you from nesting a Panel + MarginContainer + content.

**ScrollContainer** — Makes its content scrollable when it exceeds the container size. Wrap a VBoxContainer inside one for long lists. Set `horizontal_scroll_mode` and `vertical_scroll_mode` to SCROLL_MODE_AUTO to only show scrollbars when needed.

**HSplitContainer / VSplitContainer** — Two children separated by a draggable divider. Useful for editor-style UIs and debug panels.

**FlowContainer** — Wraps children like a word-processor wraps words. Underused but handy for tag clouds and flex-layout-style UIs.

### Nesting Containers for Real Layouts

Real menus require nesting. Here's a typical main menu:

```
MarginContainer
  └── VBoxContainer
      ├── Label ("My Game")
      ├── Control (spacer, custom_minimum_size.y = 40)
      ├── VBoxContainer (button group)
      │   ├── Button ("Start Game")
      │   ├── Button ("Settings")
      │   ├── Button ("Credits")
      │   └── Button ("Quit")
      └── Label ("v1.0.0")
```

The outer `MarginContainer` keeps everything away from screen edges. The inner `VBoxContainer` for buttons keeps them evenly spaced. No pixel math required.

### Size Flags: Controlling How Children Use Space

Every Control node has `size_flags_horizontal` and `size_flags_vertical`. These tell the parent container how to allocate leftover space.

| Flag | Meaning |
|------|---------|
| `SHRINK_BEGIN` | Align to start, take minimum size |
| `SHRINK_CENTER` | Align to center, take minimum size |
| `SHRINK_END` | Align to end, take minimum size |
| `FILL` | Stretch to fill available space |
| `EXPAND` | Request a share of extra space |
| `EXPAND + FILL` | Take all available extra space and fill it |

The most common pattern: give a spacer node `EXPAND + FILL` to push subsequent elements to the bottom (or right in HBoxContainer):

```gdscript
var spacer := Control.new()
spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
add_child(spacer)  # Pushes everything after it to the bottom
```

### Custom Minimum Size

Every Control has `custom_minimum_size`. Set it to guarantee a minimum footprint even when the container would otherwise shrink it:

```gdscript
button.custom_minimum_size = Vector2(200, 48)
```

This is how you make uniform button sizes without hard-coding positions.

---

## 3. Anchors and Margins

Containers handle layout inside a parent. Anchors handle positioning when a node needs to stick to a specific region of its parent — especially important for HUD elements that must be pinned to screen corners regardless of resolution.

### How Anchors Work

An anchor defines a reference point as a fraction of the parent's size (0.0 to 1.0). Four anchor values: `anchor_left`, `anchor_right`, `anchor_top`, `anchor_bottom`. Then `offset_left/right/top/bottom` define the pixel distance from those anchor points.

For example, to pin a node to the top-right corner:
```
anchor_left = 1.0
anchor_right = 1.0
anchor_top = 0.0
anchor_bottom = 0.0
offset_left = -200   # 200px from the right edge
offset_right = -8    # 8px margin from the right
offset_top = 8       # 8px from the top
offset_bottom = 56   # 48px tall
```

### Anchor Presets

You'll almost never set raw anchor values. In the editor, the toolbar shows an anchor preset picker. In code, use `set_anchors_preset()`:

```gdscript
# Available presets
control.set_anchors_preset(Control.PRESET_FULL_RECT)          # fills parent
control.set_anchors_preset(Control.PRESET_TOP_LEFT)
control.set_anchors_preset(Control.PRESET_TOP_RIGHT)
control.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
control.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
control.set_anchors_preset(Control.PRESET_CENTER)
control.set_anchors_preset(Control.PRESET_CENTER_TOP)
control.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
control.set_anchors_preset(Control.PRESET_LEFT_WIDE)          # full height, left side
control.set_anchors_preset(Control.PRESET_RIGHT_WIDE)         # full height, right side
```

### HUD Layout with Corner Anchors

A typical HUD pins different elements to different corners:

```
CanvasLayer (layer = 1)
  └── Control (FULL_RECT anchor — fills viewport)
      ├── HealthBar (ProgressBar, PRESET_TOP_LEFT, offset 16px from edges)
      ├── ScoreLabel (Label, PRESET_TOP_RIGHT, offset 16px from edges)
      ├── MinimapRect (TextureRect, PRESET_BOTTOM_RIGHT, offset 16px from edges)
      └── AmmoLabel (Label, PRESET_BOTTOM_LEFT, offset 16px from edges)
```

Each element snaps to its corner and stays there regardless of window size. If you resize the game window, the health bar stays top-left, the score stays top-right.

```gdscript
@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var score_label: Label = $Control/ScoreLabel

func update_health(current: int, maximum: int) -> void:
    health_bar.max_value = maximum
    health_bar.value = current

func update_score(score: int) -> void:
    score_label.text = "Score: %d" % score
```

---

## 4. CanvasLayer: UI Over 3D

Here is the most important structural rule for game UI: **never parent your HUD to a Camera3D or any 3D node**. If you do, the HUD moves with the camera, which is almost never what you want. Use `CanvasLayer` instead.

`CanvasLayer` is a special node that renders its children on a 2D canvas completely independent of the 3D viewport. It doesn't move with the camera. It doesn't get depth-tested. It just draws on top of everything at a fixed screen position.

### Scene Tree Structure

```
Main (Node3D or Node)
├── World (Node3D)
│   ├── Camera3D
│   ├── DirectionalLight3D
│   ├── Player (CharacterBody3D)
│   └── Level (Node3D)
├── HUD (CanvasLayer, layer = 1)
│   └── Control (FULL_RECT)
│       ├── HealthBar (ProgressBar, top-left)
│       ├── ScoreLabel (Label, top-right)
│       └── MinimapContainer (Control, bottom-right)
├── PauseMenu (CanvasLayer, layer = 10)
│   └── Panel (FULL_RECT, semi-transparent)
│       └── CenterContainer
│           └── VBoxContainer
│               ├── Label ("Paused")
│               ├── Button ("Resume")
│               ├── Button ("Settings")
│               └── Button ("Main Menu")
└── LoadingScreen (CanvasLayer, layer = 100)
    └── Panel (FULL_RECT, opaque)
        └── CenterContainer
            └── VBoxContainer
                ├── Label ("Loading...")
                └── ProgressBar
```

### Layer Ordering

The `layer` property controls draw order. Higher = renders on top:
- `layer = 1` — HUD (always visible in gameplay)
- `layer = 10` — Pause menu (on top of HUD)
- `layer = 100` — Loading screen (on top of absolutely everything)

```gdscript
# In HUD.gd
extends CanvasLayer

func _ready() -> void:
    layer = 1

# In PauseMenu.gd
extends CanvasLayer

func _ready() -> void:
    layer = 10
    visible = false  # Hidden until paused
    process_mode = Node.PROCESS_MODE_ALWAYS  # Must work while game is paused
```

### Process Mode for Pause Menus

When the game is paused (`get_tree().paused = true`), nodes stop processing by default. The pause menu itself needs to keep working. Set its `process_mode` to `PROCESS_MODE_ALWAYS`:

```gdscript
# PauseMenu.gd
extends CanvasLayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if visible:
            resume()
        else:
            pause()

func pause() -> void:
    get_tree().paused = true
    visible = true
    $Panel/CenterContainer/VBoxContainer/ResumeButton.grab_focus()

func resume() -> void:
    get_tree().paused = false
    visible = false
```

---

## 5. Theme System

Styling individual nodes one by one leads to inconsistent UIs that are painful to update. The Theme system solves this: one Theme resource controls fonts, colors, and styleboxes for all Control nodes that inherit from it. Change the Theme; the entire UI updates.

### What a Theme Controls

A Theme stores style overrides organized by **type** (Button, Label, Panel, etc.) and **data type** (StyleBox, Color, Font, integer constant, icon):

| Data Type | Examples |
|-----------|----------|
| StyleBox | Button normal/hover/pressed/disabled/focus, Panel background |
| Color | Button font_color, Label font_color, font_shadow_color |
| Font | default_font, per-node font |
| Integer | separation (VBox/HBox), margin (MarginContainer), icon_separation |
| Texture | icons for CheckBox, OptionButton arrow, etc. |

### Creating and Applying a Theme

1. In the Inspector on any Control node, click the "Theme" property and create a new Theme resource.
2. Save it as `res://ui/game_theme.tres`.
3. Assign it to the **root** Control node (or a CanvasLayer's root Control). All children inherit it automatically.
4. Override on individual nodes only when you need an exception.

### Building a Theme in Code

```gdscript
# res://ui/theme_builder.gd
static func create_game_theme() -> Theme:
    var theme := Theme.new()

    # Default font and size
    var font := preload("res://fonts/my_font.tres")
    theme.set_default_font(font)
    theme.set_default_font_size(18)

    # ---- Button styles ----

    # Normal state
    var btn_normal := StyleBoxFlat.new()
    btn_normal.bg_color = Color(0.15, 0.15, 0.25, 0.92)
    btn_normal.corner_radius_top_left = 8
    btn_normal.corner_radius_top_right = 8
    btn_normal.corner_radius_bottom_left = 8
    btn_normal.corner_radius_bottom_right = 8
    btn_normal.content_margin_left = 24
    btn_normal.content_margin_right = 24
    btn_normal.content_margin_top = 12
    btn_normal.content_margin_bottom = 12
    btn_normal.border_width_left = 2
    btn_normal.border_width_right = 2
    btn_normal.border_width_top = 2
    btn_normal.border_width_bottom = 2
    btn_normal.border_color = Color(0.4, 0.4, 0.7, 0.6)
    theme.set_stylebox("normal", "Button", btn_normal)

    # Hover state
    var btn_hover := btn_normal.duplicate()
    btn_hover.bg_color = Color(0.25, 0.25, 0.45, 0.95)
    btn_hover.border_color = Color(0.6, 0.6, 1.0, 0.9)
    theme.set_stylebox("hover", "Button", btn_hover)

    # Pressed state
    var btn_pressed := btn_normal.duplicate()
    btn_pressed.bg_color = Color(0.1, 0.1, 0.2, 0.95)
    btn_pressed.border_color = Color(0.8, 0.8, 1.0, 1.0)
    theme.set_stylebox("pressed", "Button", btn_pressed)

    # Disabled state
    var btn_disabled := btn_normal.duplicate()
    btn_disabled.bg_color = Color(0.08, 0.08, 0.12, 0.5)
    btn_disabled.border_color = Color(0.2, 0.2, 0.3, 0.4)
    theme.set_stylebox("disabled", "Button", btn_disabled)

    # Focus state (for gamepad/keyboard navigation — style this prominently)
    var btn_focus := StyleBoxFlat.new()
    btn_focus.bg_color = Color(0, 0, 0, 0)  # transparent fill
    btn_focus.corner_radius_top_left = 8
    btn_focus.corner_radius_top_right = 8
    btn_focus.corner_radius_bottom_left = 8
    btn_focus.corner_radius_bottom_right = 8
    btn_focus.border_width_left = 2
    btn_focus.border_width_right = 2
    btn_focus.border_width_top = 2
    btn_focus.border_width_bottom = 2
    btn_focus.border_color = Color.WHITE
    theme.set_stylebox("focus", "Button", btn_focus)

    # Button font colors
    theme.set_color("font_color", "Button", Color.WHITE)
    theme.set_color("font_hover_color", "Button", Color.WHITE)
    theme.set_color("font_pressed_color", "Button", Color(0.8, 0.8, 1.0))
    theme.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.5))

    # ---- Panel style ----
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.88)
    panel_style.corner_radius_top_left = 12
    panel_style.corner_radius_top_right = 12
    panel_style.corner_radius_bottom_left = 12
    panel_style.corner_radius_bottom_right = 12
    panel_style.border_width_left = 1
    panel_style.border_width_right = 1
    panel_style.border_width_top = 1
    panel_style.border_width_bottom = 1
    panel_style.border_color = Color(0.3, 0.3, 0.5, 0.5)
    theme.set_stylebox("panel", "Panel", panel_style)

    # ---- ProgressBar style ----
    var pb_bg := StyleBoxFlat.new()
    pb_bg.bg_color = Color(0.1, 0.1, 0.15, 0.8)
    pb_bg.corner_radius_top_left = 4
    pb_bg.corner_radius_top_right = 4
    pb_bg.corner_radius_bottom_left = 4
    pb_bg.corner_radius_bottom_right = 4
    theme.set_stylebox("background", "ProgressBar", pb_bg)

    var pb_fill := StyleBoxFlat.new()
    pb_fill.bg_color = Color(0.2, 0.8, 0.3)
    pb_fill.corner_radius_top_left = 4
    pb_fill.corner_radius_top_right = 4
    pb_fill.corner_radius_bottom_left = 4
    pb_fill.corner_radius_bottom_right = 4
    theme.set_stylebox("fill", "ProgressBar", pb_fill)

    # VBoxContainer / HBoxContainer separation
    theme.set_constant("separation", "VBoxContainer", 12)
    theme.set_constant("separation", "HBoxContainer", 12)

    return theme
```

### The Theme Editor

For most workflows, the Inspector's Theme Editor is faster than code. Open any saved `.tres` Theme resource, and the editor shows a visual tree of all node types and their overridable properties. You can:
- Preview changes live in the editor
- Import styles from another Theme
- Copy styleboxes between states (normal to hover, then tweak)

Use code generation when you need the theme to be data-driven (e.g., loaded from a config file, or created at runtime based on user preferences).

---

## 6. Focus and Keyboard/Gamepad Navigation

A UI that only works with a mouse is an incomplete UI. Every menu you build should be fully navigable with keyboard arrow keys, Tab/Shift-Tab, and gamepad d-pad. Godot's focus system makes this straightforward.

### Focus Basics

- **Focused node**: the Control that currently receives keyboard/gamepad input
- `grab_focus()`: programmatically give focus to a node
- `release_focus()`: remove focus
- `has_focus()`: check if a node currently has focus
- `focus_entered` signal: emitted when focus arrives
- `focus_exited` signal: emitted when focus leaves

### Setting Initial Focus

When a menu appears, the first interactive element should grab focus immediately. Otherwise gamepad users see no selection and don't know where to start:

```gdscript
# MainMenu.gd
extends CanvasLayer

@onready var start_button: Button = $Panel/VBoxContainer/StartButton

func _ready() -> void:
    start_button.grab_focus()

func show_menu() -> void:
    visible = true
    start_button.grab_focus()
```

### Focus Neighbors

For complex layouts where the auto-navigation doesn't work correctly, set focus neighbors explicitly. Each Control has four neighbor properties that accept `NodePath` values:

```gdscript
# In the editor: set focus_neighbor_* in the Inspector
# In code:
start_button.focus_neighbor_bottom = settings_button.get_path()
settings_button.focus_neighbor_top = start_button.get_path()
settings_button.focus_neighbor_bottom = quit_button.get_path()
quit_button.focus_neighbor_top = settings_button.get_path()
quit_button.focus_neighbor_bottom = start_button.get_path()  # Wrap around
start_button.focus_neighbor_top = quit_button.get_path()      # Wrap around
```

VBoxContainer and HBoxContainer set focus neighbors automatically for their children — you only need to override when you have non-linear navigation (e.g., a button group that wraps, or cross-container navigation).

### Handling ui_cancel (Back Button / Escape)

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        back()

func back() -> void:
    # Return to previous menu / close overlay
    queue_free()
```

Always call `set_input_as_handled()` when you consume a UI event so it doesn't propagate to the game world.

### Focus StyleBox

The "focus" StyleBox on a Button is how focused buttons are visually distinguished for gamepad users. By default it's invisible — style it prominently:

```gdscript
# A bright white border that clearly shows which button is selected
var focus_style := StyleBoxFlat.new()
focus_style.bg_color = Color(0, 0, 0, 0)       # Transparent background
focus_style.border_color = Color.WHITE
focus_style.border_width_left = 3
focus_style.border_width_right = 3
focus_style.border_width_top = 3
focus_style.border_width_bottom = 3
focus_style.corner_radius_top_left = 8
focus_style.corner_radius_top_right = 8
focus_style.corner_radius_bottom_left = 8
focus_style.corner_radius_bottom_right = 8
theme.set_stylebox("focus", "Button", focus_style)
```

---

## 7. RichTextLabel and BBCode

`RichTextLabel` is `Label`'s powerful sibling. Enable `bbcode_enabled = true` and you get inline formatting, color, font sizing, images, and animated effects — all in a single text node.

### BBCode Reference

```gdscript
var rtl := $RichTextLabel
rtl.bbcode_enabled = true

# Basic formatting
rtl.text = "[b]Bold[/b]"
rtl.text = "[i]Italic[/i]"
rtl.text = "[u]Underline[/u]"
rtl.text = "[s]Strikethrough[/s]"

# Colors
rtl.text = "[color=red]Red text[/color]"
rtl.text = "[color=#ff6644]Hex color[/color]"

# Size
rtl.text = "[font_size=32]Big Text[/font_size]"

# Alignment (wraps a paragraph)
rtl.text = "[center]Centered heading[/center]"
rtl.text = "[right]Right-aligned[/right]"

# Images (displays a texture inline)
rtl.text = "[img=32x32]res://icons/sword.png[/img]"

# Clickable URLs (connect url_clicked signal)
rtl.text = "[url=https://godotengine.org]Visit Godot[/url]"

# Tables
rtl.text = "[table=2][cell]Name[/cell][cell]Value[/cell][cell]Sword[/cell][cell]50 dmg[/cell][/table]"

# Animated effects (built-in)
rtl.text = "[wave]Wavy text[/wave]"
rtl.text = "[shake]Shaking text[/shake]"
rtl.text = "[rainbow]Rainbow text[/rainbow]"
rtl.text = "[pulse color=#ff0000 freq=2.0]Pulsing[/pulse]"
rtl.text = "[tornado radius=5.0 freq=2.0]Tornado[/tornado]"
```

### Item Description Example

A complete item description card using multiple BBCode styles:

```gdscript
func set_item_description(item: ItemResource) -> void:
    var rtl: RichTextLabel = $ItemPanel/Description
    rtl.bbcode_enabled = true

    var rarity_colors := {
        "common": "white",
        "uncommon": "#00ff7f",
        "rare": "#4488ff",
        "epic": "#aa44ff",
        "legendary": "#ff8800"
    }
    var color := rarity_colors.get(item.rarity, "white")

    rtl.text = (
        "[font_size=22][b]%s[/b][/font_size]\n" % item.name
        + "[color=%s][i]%s[/i][/color]\n\n" % [color, item.rarity.capitalize()]
        + "[color=gray]Damage:[/color] [color=red]%d[/color]\n" % item.damage
        + "[color=gray]Speed:[/color] [color=yellow]%.1f[/color]\n\n" % item.attack_speed
        + "[i]%s[/i]" % item.lore_text
    )
```

### Typewriter Effect

The `visible_characters` property controls how many characters are rendered. Animate it with a Tween for a typewriter effect:

```gdscript
var _typewriter_tween: Tween

func type_text(rtl: RichTextLabel, full_text: String, chars_per_sec: float = 30.0) -> void:
    rtl.text = full_text
    rtl.visible_characters = 0
    rtl.visible_ratio = 0.0  # Equivalent but 0.0-1.0 range

    if _typewriter_tween:
        _typewriter_tween.kill()

    _typewriter_tween = create_tween()
    var duration := full_text.length() / chars_per_sec
    _typewriter_tween.tween_property(rtl, "visible_characters", full_text.length(), duration)
    await _typewriter_tween.finished

func skip_typewriter() -> void:
    if _typewriter_tween and _typewriter_tween.is_running():
        _typewriter_tween.kill()
        $DialogueBox/Text.visible_ratio = 1.0
```

Connect a button or `ui_accept` action to `skip_typewriter()` so players can skip ahead during dialogue.

---

## 8. SubViewport for Minimap

A minimap requires rendering the world from a top-down perspective and displaying that render in a small corner of the HUD. SubViewport makes this possible: it renders a separate camera's view to a texture, and you display that texture in a TextureRect.

### Scene Structure

```
MinimapSystem (Node3D)
├── SubViewport
│   ├── Camera3D (MinimapCamera, orthographic, looking straight down)
│   └── MinimapMarkers (Node3D — for icons/dots on the minimap)
```

And in the HUD:
```
HUD (CanvasLayer)
└── Control (FULL_RECT)
    └── MinimapContainer (Control, PRESET_BOTTOM_RIGHT)
        ├── Panel (background + border)
        └── TextureRect (MinimapView, PRESET_FULL_RECT)
```

### Wiring It Together

```gdscript
# MinimapSystem.gd
extends Node3D

@export var player: CharacterBody3D
@onready var minimap_camera: Camera3D = $SubViewport/Camera3D
@onready var sub_viewport: SubViewport = $SubViewport

const MINIMAP_HEIGHT := 80.0   # Height above ground
const MINIMAP_RANGE  := 60.0   # Orthogonal half-size (zoom level)

func _ready() -> void:
    sub_viewport.size = Vector2i(256, 256)
    sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sub_viewport.transparent_bg = false

    minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    minimap_camera.size = MINIMAP_RANGE
    minimap_camera.rotation_degrees = Vector3(-90, 0, 0)

    # Connect the viewport texture to the HUD's TextureRect
    var hud_minimap: TextureRect = get_tree().get_first_node_in_group("minimap_view")
    if hud_minimap:
        hud_minimap.texture = sub_viewport.get_texture()

func _process(_delta: float) -> void:
    if not player:
        return
    minimap_camera.global_position = Vector3(
        player.global_position.x,
        player.global_position.y + MINIMAP_HEIGHT,
        player.global_position.z
    )
```

```gdscript
# HUD.gd — receive the texture
extends CanvasLayer

@onready var minimap_view: TextureRect = $Control/MinimapContainer/Panel/TextureRect

func _ready() -> void:
    minimap_view.add_to_group("minimap_view")
    minimap_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
```

### SubViewport Settings Reference

| Property | Value | Reason |
|----------|-------|--------|
| `size` | `Vector2i(256, 256)` | Resolution of the minimap render |
| `render_target_update_mode` | `UPDATE_ALWAYS` | Re-render every frame |
| `transparent_bg` | `false` | Opaque background for the minimap |
| `own_world_3d` | `false` | Uses the main world (sees the same geometry) |
| `use_hdr_2d` | `false` | Standard SDR rendering is fine for minimaps |

For a static map (dungeon, fixed level), consider `UPDATE_ONCE` or `UPDATE_WHEN_VISIBLE` to save GPU time.

---

## 9. Loading Screen with Progress

Never call `load()` during gameplay. It blocks the main thread and freezes the game while the OS loads the file from disk. Use `ResourceLoader.load_threaded_request()` instead: it loads in the background while your loading screen animates.

### The Loading Screen Scene

```
LoadingScreen (CanvasLayer, layer = 100)
└── Panel (FULL_RECT, opaque black)
    └── CenterContainer (FULL_RECT)
        └── VBoxContainer
            ├── Label (title_label, "Loading...")
            ├── ProgressBar (progress_bar, min=0, max=100)
            └── Label (status_label, "")
```

### Complete Loading Screen Script

```gdscript
# LoadingScreen.gd
extends CanvasLayer

signal load_complete

@onready var progress_bar: ProgressBar = $Panel/CenterContainer/VBoxContainer/ProgressBar
@onready var status_label: Label = $Panel/CenterContainer/VBoxContainer/StatusLabel
@onready var title_label: Label = $Panel/CenterContainer/VBoxContainer/TitleLabel

var _scene_path: String = ""
var _processing_load: bool = false

func _ready() -> void:
    layer = 100
    visible = false
    progress_bar.min_value = 0.0
    progress_bar.max_value = 100.0

func load_scene(path: String, loading_text: String = "Loading...") -> void:
    _scene_path = path
    _processing_load = true
    title_label.text = loading_text
    status_label.text = ""
    progress_bar.value = 0.0
    visible = true

    var err := ResourceLoader.load_threaded_request(path)
    if err != OK:
        status_label.text = "Error: could not start loading."
        _processing_load = false
        return

func _process(_delta: float) -> void:
    if not _processing_load:
        return

    var progress: Array = []
    var status := ResourceLoader.load_threaded_get_status(_scene_path, progress)

    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            var pct: float = progress[0] * 100.0
            progress_bar.value = pct
            status_label.text = "%d%%" % int(pct)

        ResourceLoader.THREAD_LOAD_LOADED:
            progress_bar.value = 100.0
            status_label.text = "100%"
            _processing_load = false

            var packed_scene := ResourceLoader.load_threaded_get(_scene_path) as PackedScene
            _scene_path = ""
            load_complete.emit()
            # Small delay so the 100% state is visible
            await get_tree().create_timer(0.1).timeout
            get_tree().change_scene_to_packed(packed_scene)
            visible = false

        ResourceLoader.THREAD_LOAD_FAILED:
            status_label.text = "Load failed!"
            push_error("LoadingScreen: failed to load %s" % _scene_path)
            _processing_load = false
            _scene_path = ""
```

### Using the Loading Screen

```gdscript
# From any script:
func go_to_game() -> void:
    var loading_screen: CanvasLayer = preload("res://ui/loading_screen.tscn").instantiate()
    get_tree().root.add_child(loading_screen)
    loading_screen.load_scene("res://levels/level_01.tscn", "Loading Level 1...")
```

Because the LoadingScreen is added directly to the scene tree root, it survives scene transitions automatically. Remove it after `load_complete` fires, or let it self-manage by staying hidden.

---

## 10. In-World UI: Sprite3D and Label3D

Not all UI is a flat overlay. Sometimes you need text and images that exist inside the 3D world — player name tags, damage numbers, quest markers, item pickups, in-game computer screens.

### Label3D

`Label3D` renders text directly in 3D space. It supports the same font properties as `Label` but lives at a `Vector3` position with a `Vector3` rotation.

Key properties:
- `text`: the string to display
- `font_size`: size in 3D units
- `modulate`: tint/alpha
- `billboard`: face the camera automatically
  - `BaseMaterial3D.BILLBOARD_DISABLED` (default): oriented like any 3D object
  - `BaseMaterial3D.BILLBOARD_ENABLED`: always faces the camera (good for name tags)
  - `BaseMaterial3D.BILLBOARD_FIXED_Y`: only rotates on Y axis (billboard but stays upright)
- `no_depth_test`: when `true`, renders on top of all geometry (no z-fighting)
- `alpha_cut`: `ALPHA_CUT_DISABLED`, `ALPHA_CUT_DISCARD`, `ALPHA_CUT_OPAQUE_PREPASS`

### Sprite3D

`Sprite3D` puts a `Texture2D` into 3D space. Useful for:
- Map markers and pings
- Quest indicators and exclamation marks
- Item pickups before the player collects them
- Animated 2D characters in a 3D world (pixel art, flat-shaded)

Same `billboard` options as `Label3D`.

### Floating Damage Numbers

The classic VFX that every action game uses: a number pops up, floats upward, and fades out:

```gdscript
# DamageNumbers.gd — attach to a Node3D in your scene
extends Node3D

const FLOAT_HEIGHT := 2.0
const FLOAT_DURATION := 0.8
const FONT_SIZE := 48

func spawn(world_position: Vector3, amount: int, is_crit: bool = false) -> void:
    var label := Label3D.new()
    label.text = ("★ " if is_crit else "") + str(amount)
    label.font_size = FONT_SIZE * (1.5 if is_crit else 1.0)
    label.modulate = Color.RED if not is_crit else Color.YELLOW
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.global_position = world_position + Vector3(
        randf_range(-0.3, 0.3),  # Slight horizontal scatter
        1.0,
        randf_range(-0.3, 0.3)
    )
    add_child(label)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "position:y", label.position.y + FLOAT_HEIGHT, FLOAT_DURATION)\
         .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(label, "modulate:a", 0.0, FLOAT_DURATION)\
         .set_delay(FLOAT_DURATION * 0.4)
    tween.set_parallel(false)
    tween.tween_callback(label.queue_free)
```

### In-World Control UI on a 3D Surface

For proper 2D UI on a 3D mesh (a computer terminal in the level, a control panel, a shop sign), use a `SubViewport` as the mesh's texture:

```
TerminalProp (Node3D)
├── MeshInstance3D (monitor screen mesh)
└── SubViewport (render_target_update_mode = UPDATE_ALWAYS)
    └── Control (FULL_RECT)
        └── Panel
            └── VBoxContainer
                ├── Label ("SYSTEM ONLINE")
                └── Button ("Access Files")
```

In the MeshInstance3D material, set the albedo texture to the `SubViewport`'s `ViewportTexture`. The buttons become interactive in 3D space — combine with a raycast from the player to send input events to the SubViewport using `push_input()`.

---

## 11. Code Walkthrough: Complete Game UI Kit

This section builds every component of a real game's UI. Read through the full scene trees and scripts to understand how everything connects.

### Main Menu

**Scene tree:**
```
MainMenu (CanvasLayer, layer = 1)
└── Panel (FULL_RECT, semi-opaque dark background)
    └── MarginContainer (FULL_RECT, margin 80px all sides)
        └── VBoxContainer
            ├── Label ("MY GAME", font_size=72, center aligned)
            ├── Control (spacer, EXPAND+FILL)
            ├── VBoxContainer (button_container)
            │   ├── Button (StartButton, "Start Game")
            │   ├── Button (SettingsButton, "Settings")
            │   ├── Button (CreditsButton, "Credits")
            │   └── Button (QuitButton, "Quit")
            └── Label (version_label, "v1.0.0", right aligned)
```

```gdscript
# MainMenu.gd
extends CanvasLayer

signal start_game_pressed
signal settings_pressed
signal credits_pressed

@onready var start_button: Button = $Panel/MarginContainer/VBoxContainer/VBoxContainer/StartButton
@onready var settings_button: Button = $Panel/MarginContainer/VBoxContainer/VBoxContainer/SettingsButton
@onready var credits_button: Button = $Panel/MarginContainer/VBoxContainer/VBoxContainer/CreditsButton
@onready var quit_button: Button = $Panel/MarginContainer/VBoxContainer/VBoxContainer/QuitButton

func _ready() -> void:
    start_button.pressed.connect(func(): start_game_pressed.emit())
    settings_button.pressed.connect(func(): settings_pressed.emit())
    credits_button.pressed.connect(func(): credits_pressed.emit())
    quit_button.pressed.connect(func(): get_tree().quit())

    # Set up focus wrapping for keyboard/gamepad users
    start_button.focus_neighbor_top = quit_button.get_path()
    quit_button.focus_neighbor_bottom = start_button.get_path()

    # Grab initial focus
    start_button.grab_focus()

    # Animate in
    modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.4)
```

### Settings Menu

```gdscript
# SettingsMenu.gd
extends CanvasLayer

@onready var master_slider: HSlider = $Panel/VBoxContainer/MasterVolume/HSlider
@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXVolume/HSlider
@onready var fullscreen_check: CheckButton = $Panel/VBoxContainer/Fullscreen/CheckButton
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

const SETTINGS_FILE := "user://settings.cfg"
var _config := ConfigFile.new()

func _ready() -> void:
    _load_settings()

    master_slider.value_changed.connect(_on_master_volume_changed)
    music_slider.value_changed.connect(_on_music_volume_changed)
    sfx_slider.value_changed.connect(_on_sfx_volume_changed)
    fullscreen_check.toggled.connect(_on_fullscreen_toggled)
    back_button.pressed.connect(_on_back_pressed)

    back_button.grab_focus()

func _on_master_volume_changed(value: float) -> void:
    # AudioServer uses decibels: linear_to_db converts 0.0-1.0 to dB
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index("Master"),
        linear_to_db(value)
    )
    _config.set_value("audio", "master", value)
    _config.save(SETTINGS_FILE)

func _on_music_volume_changed(value: float) -> void:
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index("Music"),
        linear_to_db(value)
    )
    _config.set_value("audio", "music", value)
    _config.save(SETTINGS_FILE)

func _on_sfx_volume_changed(value: float) -> void:
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index("SFX"),
        linear_to_db(value)
    )
    _config.set_value("audio", "sfx", value)
    _config.save(SETTINGS_FILE)

func _on_fullscreen_toggled(pressed: bool) -> void:
    if pressed:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    _config.set_value("display", "fullscreen", pressed)
    _config.save(SETTINGS_FILE)

func _on_back_pressed() -> void:
    visible = false

func _load_settings() -> void:
    if _config.load(SETTINGS_FILE) != OK:
        return  # No saved settings yet — use defaults

    master_slider.value = _config.get_value("audio", "master", 1.0)
    music_slider.value = _config.get_value("audio", "music", 0.8)
    sfx_slider.value = _config.get_value("audio", "sfx", 1.0)
    fullscreen_check.button_pressed = _config.get_value("display", "fullscreen", false)
```

### In-Game HUD

```gdscript
# HUD.gd
extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var health_label: Label = $Control/HealthBar/Label
@onready var score_label: Label = $Control/ScoreLabel
@onready var ammo_label: Label = $Control/AmmoLabel
@onready var minimap_view: TextureRect = $Control/MinimapContainer/TextureRect

func _ready() -> void:
    layer = 1

func set_health(current: int, maximum: int) -> void:
    health_bar.max_value = maximum
    health_bar.value = current
    health_label.text = "%d / %d" % [current, maximum]

    # Color shift: green to yellow to red based on health %
    var pct := float(current) / float(maximum)
    var fill_color: Color
    if pct > 0.5:
        fill_color = Color.GREEN.lerp(Color.YELLOW, (1.0 - pct) * 2.0)
    else:
        fill_color = Color.YELLOW.lerp(Color.RED, (0.5 - pct) * 2.0)

    var fill_style := health_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
    if fill_style:
        fill_style.bg_color = fill_color
        health_bar.add_theme_stylebox_override("fill", fill_style)

func set_score(score: int) -> void:
    score_label.text = "Score  %06d" % score

func set_ammo(current: int, magazine: int) -> void:
    if magazine == -1:
        ammo_label.text = "Inf"
    else:
        ammo_label.text = "%d / %d" % [current, magazine]

func set_minimap_texture(texture: ViewportTexture) -> void:
    minimap_view.texture = texture
```

### Pause Menu

```gdscript
# PauseMenu.gd
extends CanvasLayer

signal resume_pressed
signal quit_to_main_pressed

@onready var resume_button: Button = $Panel/CenterContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $Panel/CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Panel/CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
    layer = 10
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

    resume_button.pressed.connect(resume)
    settings_button.pressed.connect(_open_settings)
    quit_button.pressed.connect(func(): quit_to_main_pressed.emit())

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        resume()

func open() -> void:
    get_tree().paused = true
    visible = true
    resume_button.grab_focus()

    modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2)

func resume() -> void:
    get_tree().paused = false
    visible = false

func _open_settings() -> void:
    # Show settings overlay — implement by toggling a SettingsMenu CanvasLayer
    pass
```

### Game Controller: Wiring It All Together

```gdscript
# GameController.gd — top-level scene script or autoload
extends Node

@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var loading_screen: CanvasLayer = $LoadingScreen
@onready var main_menu: CanvasLayer = $MainMenu

func _ready() -> void:
    main_menu.start_game_pressed.connect(_start_game)
    main_menu.settings_pressed.connect(_open_settings)
    pause_menu.resume_pressed.connect(func(): pass)  # Already handled in PauseMenu
    pause_menu.quit_to_main_pressed.connect(_quit_to_main)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") and not main_menu.visible:
        if pause_menu.visible:
            pause_menu.resume()
        else:
            pause_menu.open()

func _start_game() -> void:
    main_menu.visible = false
    loading_screen.load_scene("res://levels/level_01.tscn", "Loading...")

func _open_settings() -> void:
    # Toggle SettingsMenu CanvasLayer
    pass

func _quit_to_main() -> void:
    get_tree().paused = false
    await get_tree().create_timer(0.05).timeout
    get_tree().change_scene_to_file("res://main_menu.tscn")
```

---

## 12. Animating UI with Tweens

Static menus feel lifeless. A well-animated UI communicates responsiveness and polish — buttons that pulse when focused, panels that slide in from off-screen, health bars that smoothly drain rather than snapping to the new value. Godot's `Tween` system makes this straightforward without any animation tracks or AnimationPlayer overhead.

### The Tween Workflow

A Tween is created on demand with `create_tween()`, animates one or more properties, and is automatically freed when complete. You don't need to manage its lifecycle:

```gdscript
# Fade in a panel over 0.3 seconds
func show_panel() -> void:
    $Panel.modulate.a = 0.0
    $Panel.visible = true
    var tween := create_tween()
    tween.tween_property($Panel, "modulate:a", 1.0, 0.3)\
         .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
```

Key Tween methods:

| Method | Description |
|--------|-------------|
| `tween_property(object, property, final_val, duration)` | Animate a property to a target value |
| `tween_callback(callable)` | Call a function at this point in the sequence |
| `tween_interval(duration)` | Wait for a duration before continuing |
| `set_parallel(true)` | Run subsequent tweeners at the same time |
| `set_trans(Tween.TRANS_*)` | Easing curve type |
| `set_ease(Tween.EASE_*)` | Ease in, out, or in-out |
| `set_loops(count)` | Loop the tween N times (0 = infinite) |
| `kill()` | Stop and discard the tween |

### Common UI Animations

**Slide-in from left:**
```gdscript
func animate_in_from_left(panel: Control) -> void:
    var start_x := -panel.size.x
    var end_x := panel.position.x
    panel.position.x = start_x
    panel.visible = true

    var tween := create_tween()
    tween.tween_property(panel, "position:x", end_x, 0.35)\
         .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
```

**Slide-out to right:**
```gdscript
func animate_out_to_right(panel: Control) -> void:
    var end_x := get_viewport().get_visible_rect().size.x
    var tween := create_tween()
    tween.tween_property(panel, "position:x", end_x, 0.25)\
         .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.tween_callback(func(): panel.visible = false)
```

**Button press feedback (scale bounce):**
```gdscript
# Connect to Button.button_down signal
func _on_button_down() -> void:
    var tween := create_tween()
    tween.tween_property($Button, "scale", Vector2(0.92, 0.92), 0.08)\
         .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Connect to Button.button_up signal
func _on_button_up() -> void:
    var tween := create_tween()
    tween.tween_property($Button, "scale", Vector2(1.0, 1.0), 0.12)\
         .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
```

**Smooth health bar drain:**
```gdscript
var _health_tween: Tween

func set_health_animated(current: int, maximum: int) -> void:
    health_bar.max_value = maximum

    if _health_tween:
        _health_tween.kill()

    _health_tween = create_tween()
    _health_tween.tween_property(health_bar, "value", float(current), 0.4)\
                 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
```

**Score counter roll-up:**
```gdscript
var _displayed_score: int = 0
var _score_tween: Tween

func set_score_animated(new_score: int) -> void:
    if _score_tween:
        _score_tween.kill()

    _score_tween = create_tween()
    _score_tween.tween_method(
        func(value: int) -> void:
            score_label.text = "Score  %06d" % value,
        _displayed_score,
        new_score,
        0.6
    ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _score_tween.tween_callback(func(): _displayed_score = new_score)
```

**Focus pulse on a button (infinite loop):**
```gdscript
# Play this when a button grabs focus to draw attention
func pulse_button(button: Button) -> void:
    var tween := create_tween()
    tween.set_loops()  # Loop forever until killed
    tween.tween_property(button, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.5)\
         .set_trans(Tween.TRANS_SINE)
    tween.tween_property(button, "modulate", Color.WHITE, 0.5)\
         .set_trans(Tween.TRANS_SINE)

    button.focus_exited.connect(func():
        tween.kill()
        button.modulate = Color.WHITE
    , CONNECT_ONE_SHOT)
```

### Transition Between Menus

A clean full-screen transition avoids jarring cuts between menus:

```gdscript
# ScreenTransition.gd — CanvasLayer at layer 200
extends CanvasLayer

@onready var overlay: ColorRect = $ColorRect

func transition(callable: Callable, duration: float = 0.3) -> void:
    overlay.modulate.a = 0.0
    overlay.visible = true

    var tween := create_tween()
    # Fade to black
    tween.tween_property(overlay, "modulate:a", 1.0, duration)\
         .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    # Execute the scene change in the middle
    tween.tween_callback(callable)
    # Fade back in
    tween.tween_property(overlay, "modulate:a", 0.0, duration)\
         .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_callback(func(): overlay.visible = false)

# Usage:
# screen_transition.transition(func(): get_tree().change_scene_to_file("res://game.tscn"))
```

### Easing Curve Reference

The `TRANS_*` constant controls the shape of the curve; `EASE_*` controls which end of the curve is emphasized.

| TRANS | Character |
|-------|-----------|
| `TRANS_LINEAR` | Constant speed, robotic feel |
| `TRANS_QUAD` | Gentle acceleration/deceleration, versatile default |
| `TRANS_CUBIC` | Slightly stronger than QUAD |
| `TRANS_QUART` | Strong acceleration/deceleration |
| `TRANS_EXPO` | Very sharp start or end, dramatic |
| `TRANS_SINE` | Smooth and natural, good for breathing/idle |
| `TRANS_BOUNCE` | Bounces at the end, playful |
| `TRANS_BACK` | Overshoots slightly, then settles, energetic |
| `TRANS_ELASTIC` | Rubber-band overshoot, cartoonish |
| `TRANS_SPRING` | Physics-based spring, most natural |

For UI:
- **Panels sliding in**: TRANS_BACK + EASE_OUT (pleasant overshoot)
- **Health bar draining**: TRANS_QUAD + EASE_OUT
- **Fade in/out**: TRANS_QUAD or TRANS_SINE
- **Score counting**: TRANS_QUAD + EASE_OUT
- **Error shake**: TRANS_SINE + EASE_IN_OUT with a loop

---

## API Quick Reference

### Control

| Member | Type | Description |
|--------|------|-------------|
| `grab_focus()` | Method | Give this Control keyboard/gamepad focus |
| `release_focus()` | Method | Remove focus |
| `has_focus()` | Method | Returns `true` if this node has focus |
| `set_anchors_preset(preset)` | Method | Apply an anchor preset (PRESET_TOP_LEFT, PRESET_FULL_RECT, etc.) |
| `size_flags_horizontal` | Property | FILL, EXPAND, SHRINK_BEGIN, SHRINK_CENTER, SHRINK_END |
| `size_flags_vertical` | Property | Same flags, vertical axis |
| `custom_minimum_size` | Vector2 | Minimum size regardless of container |
| `focus_neighbor_top/bottom/left/right` | NodePath | Override auto-focus navigation |
| `focus_entered` | Signal | Focus arrived |
| `focus_exited` | Signal | Focus left |
| `add_theme_*_override(name, value)` | Method | Override a single theme property locally |

### CanvasLayer

| Member | Type | Description |
|--------|------|-------------|
| `layer` | int | Draw order. Higher = on top. |
| `offset` | Vector2 | Offset the entire layer |
| `follow_viewport_enabled` | bool | Scale layer with viewport |
| `follow_viewport_scale` | float | Scale factor when follow_viewport_enabled |

### Containers

| Node | Key Property | Behavior |
|------|-------------|----------|
| `VBoxContainer` | `separation` (theme constant) | Stack vertically |
| `HBoxContainer` | `separation` (theme constant) | Stack horizontally |
| `MarginContainer` | `margin_*` (theme constants) | Add padding |
| `GridContainer` | `columns` | Grid with N columns |
| `ScrollContainer` | `horizontal_scroll_mode`, `vertical_scroll_mode` | Scrollable content |
| `CenterContainer` | — | Center single child |
| `PanelContainer` | panel StyleBox | Panel background + margins |

### Theme

| Method | Description |
|--------|-------------|
| `set_stylebox(name, type, stylebox)` | Assign a StyleBox for a node type/state |
| `set_color(name, type, color)` | Assign a Color |
| `set_font(name, type, font)` | Assign a Font |
| `set_font_size(name, type, size)` | Assign a font size |
| `set_constant(name, type, value)` | Assign an integer constant (spacing, margin) |
| `set_default_font(font)` | Set the fallback font for all nodes |
| `set_default_font_size(size)` | Set the fallback font size |

### RichTextLabel

| Member | Type | Description |
|--------|------|-------------|
| `bbcode_enabled` | bool | Enable BBCode parsing |
| `text` | String | Content (uses BBCode if enabled) |
| `visible_characters` | int | How many characters to render (-1 = all) |
| `visible_ratio` | float | 0.0–1.0 equivalent of visible_characters |
| `append_text(text)` | Method | Add text without replacing existing content |
| `clear()` | Method | Clear all content |
| `url_clicked(meta)` | Signal | Fired when a `[url]` tag is clicked |

### SubViewport

| Member | Type | Description |
|--------|------|-------------|
| `size` | Vector2i | Render resolution |
| `render_target_update_mode` | Enum | UPDATE_DISABLED, UPDATE_ONCE, UPDATE_WHEN_VISIBLE, UPDATE_ALWAYS |
| `transparent_bg` | bool | Transparent background |
| `own_world_3d` | bool | Use a separate 3D world |
| `get_texture()` | Method | Returns the ViewportTexture |

### Label3D

| Member | Type | Description |
|--------|------|-------------|
| `text` | String | Displayed text |
| `font_size` | int | Size in 3D units |
| `billboard` | BaseMaterial3D.BillboardMode | BILLBOARD_DISABLED, BILLBOARD_ENABLED, BILLBOARD_FIXED_Y |
| `no_depth_test` | bool | Render on top of all 3D geometry |
| `modulate` | Color | Tint and alpha |
| `alpha_cut` | Enum | How to handle transparent pixels |

### ResourceLoader (Threaded)

| Method | Description |
|--------|-------------|
| `load_threaded_request(path, type_hint, use_sub_threads)` | Start async load |
| `load_threaded_get_status(path, progress)` | Query status; fills `progress[0]` (0.0–1.0) |
| `load_threaded_get(path)` | Retrieve loaded resource (call only after THREAD_LOAD_LOADED) |

Status codes: `THREAD_LOAD_INVALID_RESOURCE`, `THREAD_LOAD_IN_PROGRESS`, `THREAD_LOAD_FAILED`, `THREAD_LOAD_LOADED`.

---

## Common Pitfalls

### 1. Absolute Positioning

**WRONG:**
```gdscript
# Positions elements at fixed pixel coordinates
$HealthBar.position = Vector2(20, 20)
$ScoreLabel.position = Vector2(1080, 20)  # Only works at 1280x720!
```

This breaks instantly on any resolution other than the one you tested on. The health bar might be off-screen at 1920x1080.

**RIGHT:**
```gdscript
# Use containers and anchor presets instead
$HealthBar.set_anchors_preset(Control.PRESET_TOP_LEFT)
$ScoreLabel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
# Let containers handle the rest
```

Use containers as your default layout strategy. Use anchors when an element must be pinned to a specific corner or edge. Test at 1280x720, 1920x1080, and 2560x1440 to verify your layout holds.

---

### 2. No Focus Setup

**WRONG:**
```gdscript
func _ready() -> void:
    # Menu opens, no grab_focus() called
    # Gamepad user sees no selected button, d-pad does nothing
    pass
```

This is an accessibility failure. Gamepad and keyboard users cannot navigate the menu at all.

**RIGHT:**
```gdscript
func _ready() -> void:
    $VBoxContainer/StartButton.grab_focus()

    # Also set up wrapping so focus doesn't dead-end at the list edges
    var buttons: Array[Button] = [start_button, settings_button, quit_button]
    for i in buttons.size():
        buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()
        buttons[i].focus_neighbor_top = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
```

---

### 3. HUD Parented to Camera3D

**WRONG:**
```
Camera3D
└── CanvasLayer (HUD)        # WRONG! Moves with camera rotation/position
    └── ProgressBar (health)
```

The HUD moves with the camera. It may rotate or drift as the player looks around.

**RIGHT:**
```
Main (Node3D)
├── Camera3D                 # 3D camera by itself
├── Player
└── CanvasLayer (HUD)        # Sibling of the 3D world, NOT a child of Camera3D
    └── ProgressBar (health)
```

CanvasLayer is always a sibling of the 3D world (or a child of the root node), never a child of any 3D node.

---

### 4. Blocking Load

**WRONG:**
```gdscript
func go_to_next_level() -> void:
    # Blocks the main thread — game freezes while loading!
    var scene := load("res://levels/level_02.tscn")
    get_tree().change_scene_to_packed(scene)
```

On large scenes, this freezes the game for several seconds with no feedback to the player.

**RIGHT:**
```gdscript
func go_to_next_level() -> void:
    loading_screen.load_scene("res://levels/level_02.tscn")
    # Loading screen shows real progress via load_threaded_get_status()
    # Game loop continues running, animations play, player sees a progress bar
```

`ResourceLoader.load_threaded_request()` loads in a background thread. The game loop keeps running and you animate a progress bar with the real load percentage.

---

### 5. Styling Every Button Individually

**WRONG:**
```gdscript
func _ready() -> void:
    # 50 buttons, each with its own one-off overrides
    $StartButton.add_theme_stylebox_override("normal", make_button_style(Color.BLUE))
    $SettingsButton.add_theme_stylebox_override("normal", make_button_style(Color.BLUE))
    $CreditsButton.add_theme_stylebox_override("normal", make_button_style(Color.BLUE))
    # ... 47 more buttons
```

This is duplicated work. When the design changes, you update 50 buttons individually.

**RIGHT:**
```gdscript
# Create one Theme resource, assign to root Control
# All buttons inherit the style automatically
func _ready() -> void:
    var root_control: Control = $Panel
    root_control.theme = ThemeBuilder.create_game_theme()
    # All 50 buttons now styled identically
    # Change Theme once to restyle everything
```

Create one Theme, assign it to the topmost Control node (or the root of each major UI scene), and let inheritance do the work.

---

### Bonus Pitfalls

**Bonus 1: Not handling process mode on UI that runs during pause**

If your pause menu or settings overlay does not have `process_mode = PROCESS_MODE_ALWAYS`, its buttons stop responding the moment `get_tree().paused = true` is set. Everything freezes — including the "Resume" button. Set `process_mode` to `PROCESS_MODE_ALWAYS` on the CanvasLayer or its root Control for any UI that must remain interactive during pause.

**Bonus 2: Using a single ProgressBar stylebox reference across multiple nodes**

```gdscript
# WRONG: Both bars share the same StyleBoxFlat instance
var fill_style := StyleBoxFlat.new()
fill_style.bg_color = Color.GREEN
health_bar.add_theme_stylebox_override("fill", fill_style)
mana_bar.add_theme_stylebox_override("fill", fill_style)

# Later, changing health bar color changes BOTH bars!
fill_style.bg_color = Color.RED  # Also changes mana bar
```

Always `duplicate()` a stylebox before modifying it for a specific node:

```gdscript
# RIGHT: Each bar has its own independent StyleBoxFlat
var health_fill := StyleBoxFlat.new()
health_fill.bg_color = Color.GREEN
health_bar.add_theme_stylebox_override("fill", health_fill)

var mana_fill := health_fill.duplicate()
mana_fill.bg_color = Color(0.2, 0.4, 1.0)
mana_bar.add_theme_stylebox_override("fill", mana_fill)
```

**Bonus 3: Connecting to pressed inside _process**

```gdscript
# WRONG: Reconnects every frame — pressed fires hundreds of times per click
func _process(_delta: float) -> void:
    $Button.pressed.connect(_on_button_pressed)
```

Connect signals once in `_ready()`, or disconnect before reconnecting if you need to change the handler dynamically. Use `is_connected()` to check first.

```gdscript
# RIGHT: Connect once on ready
func _ready() -> void:
    $Button.pressed.connect(_on_button_pressed)
```

**Bonus 4: Forgetting to set custom_minimum_size on empty containers**

A `CenterContainer` or `PanelContainer` with no children and no `custom_minimum_size` collapses to zero size and becomes invisible. When building dynamic UIs that add children later, give the container a minimum size:

```gdscript
tooltip_panel.custom_minimum_size = Vector2(200, 80)
```

This prevents the container from disappearing before its children are populated.

---

## Responsive Design: Viewport Stretch Settings

Your containers and anchors handle layout — but they need to know the rules for how the game window itself scales. Configure this in **Project Settings > Display > Window > Stretch**:

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| **Mode** | `canvas_items` | Scales the 2D canvas (and thus the CanvasLayer UI) with the window |
| **Aspect** | `keep_height` | Maintains the height; adds horizontal letterboxing on narrow windows |
| **Scale** | `1.0` | Base scale; HiDPI displays may benefit from `2.0` |

With `mode = canvas_items` and `aspect = keep_height`, your UI designed at 1920x1080 will scale cleanly to any window size. Wider windows add more horizontal space; narrower windows add horizontal black bars. This is the most common setup for desktop games.

For pixel-art or fixed-resolution games, use `mode = viewport` instead — the entire scene renders at a fixed resolution and is scaled up with nearest-neighbor filtering. UI designed at 320x180 will display sharply at 1920x1080 as a 6x scale.

In GDScript you can query the actual viewport size at runtime:

```gdscript
var viewport_size := get_viewport().get_visible_rect().size
# Use this to position elements that need to be viewport-size-aware at runtime
```

---

## Exercises

### Exercise 1: Settings Menu with Persistent Config (30–45 min)

Build a complete settings menu that saves and loads preferences.

Requirements:
- Three `HSlider` nodes connected to the Master, Music, and SFX audio buses via `AudioServer`
- A `CheckButton` for fullscreen toggle using `DisplayServer.window_set_mode()`
- An `OptionButton` for resolution presets: 1280x720, 1920x1080, 2560x1440
- Persist all settings with `ConfigFile` to `user://settings.cfg`
- Load saved settings in `_ready()` so they apply on game launch

Stretch goals:
- Add a "Reset to Defaults" button
- Add a graphics quality dropdown (Low/Medium/High) that adjusts shadow quality and SSAO
- Show the current value next to each slider (e.g., "Master Volume: 80%")

---

### Exercise 2: Dialogue System (60–90 min)

Build a dialogue system suitable for an RPG or visual novel.

Requirements:
- `RichTextLabel` for dialogue text with BBCode enabled
- Typewriter effect using `visible_characters` animated with a `Tween`
- Character portrait using `TextureRect` (left side, shows who is speaking)
- Speaker name using a `Label` above the text
- Next button (or `ui_accept` action) to advance text; if typing is in progress, skip to the end first
- Choice system: a `VBoxContainer` of `Button` nodes shown at the end of a dialogue entry
- Dialogue data as a `Resource` subclass (not hard-coded strings in the script)

Data structure to implement:

```gdscript
# DialogueLine.gd
class_name DialogueLine
extends Resource

@export var speaker_name: String = ""
@export var portrait: Texture2D
@export var text: String = ""
@export var choices: Array[DialogueChoice] = []

# DialogueChoice.gd
class_name DialogueChoice
extends Resource

@export var label: String = ""
@export var next_line_index: int = -1  # -1 = end dialogue
```

Stretch goals:
- Animate the portrait in/out when the speaker changes
- Add a `[shake]` effect to text for emotional moments
- Support branching: dialogue trees that loop back or lead to different endings

---

### Exercise 3: Shop/Inventory UI (60–90 min)

Build a shop and inventory screen.

Requirements:
- Inventory grid using `GridContainer` (6 columns, N rows)
- Each cell is a `PanelContainer` with a `TextureRect` (item icon) and `Label` (quantity)
- Tooltip: when hovering over an item, show a `RichTextLabel` panel with item name, stats, and description
- Shop panel alongside inventory: another `GridContainer` showing items for sale
- Drag-and-drop: drag items between inventory slots and equipment slots using `_get_drag_data()`, `_can_drop_data()`, `_drop_data()`
- Buy button with price label; disable if player cannot afford

Slot implementation:

```gdscript
# ItemSlot.gd
extends PanelContainer

signal item_clicked(slot: ItemSlot)

@export var item: ItemResource = null :
    set(value):
        item = value
        _refresh()

func _refresh() -> void:
    $TextureRect.texture = item.icon if item else null
    $Label.text = str(item.quantity) if item and item.stackable else ""
    $Label.visible = item != null and item.stackable

func _get_drag_data(_position: Vector2) -> Variant:
    if not item:
        return null
    var preview := TextureRect.new()
    preview.texture = item.icon
    preview.custom_minimum_size = Vector2(48, 48)
    set_drag_preview(preview)
    return {"slot": self, "item": item}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("item")

func _drop_data(_position: Vector2, data: Variant) -> void:
    var source_slot: ItemSlot = data["slot"]
    var temp := item
    item = source_slot.item
    source_slot.item = temp
```

Stretch goals:
- Equipment slots (helmet, chest, weapon, etc.) with type restrictions
- Item comparison tooltip showing stat differences vs. currently equipped item
- Animated "new item acquired" popup using a Tween

---

## Key Takeaways

1. **Never use absolute positioning for UI layout.** Containers — VBoxContainer, HBoxContainer, GridContainer, MarginContainer — automatically handle sizing, spacing, and responsive layout. They adjust when the window resizes. Raw coordinates do not.

2. **CanvasLayer keeps UI independent of the 3D camera.** Always place HUDs, menus, and overlays as CanvasLayer nodes that are siblings of the 3D world root, never children of Camera3D. Use the `layer` property for draw ordering: 1 for HUD, 10 for pause, 100 for loading.

3. **Theme resources give you global consistent styling.** Create one Theme, assign it to the root Control of each major UI scene, and every descendant inherits it. Change the Theme once to restyle the entire game. Use `add_theme_*_override()` only for intentional exceptions.

4. **Focus + focus neighbors = gamepad and keyboard navigation.** Call `grab_focus()` when a menu opens so players know where they are. Set `focus_neighbor_*` for wrapping and cross-container navigation. Style the "focus" StyleBox prominently so it is obvious which element is selected. Test every menu without touching the mouse.

5. **RichTextLabel with BBCode handles formatted text, dialogue, and item descriptions.** Use `visible_characters` with a Tween for typewriter effects. Built-in `[wave]`, `[shake]`, and `[rainbow]` effects work out of the box. Build your dialogue data as Resource subclasses for clean separation of data and presentation.

6. **SubViewport renders to a texture — use it for minimaps, security camera feeds, and in-world screens.** Attach a Camera3D inside the SubViewport, point it where you want, then display the resulting ViewportTexture in a TextureRect. For dynamic content, set `render_target_update_mode = UPDATE_ALWAYS`; for static maps, `UPDATE_ONCE` saves GPU cycles.

7. **ResourceLoader.load_threaded_request() for async loading with progress bars.** Never freeze the game with synchronous `load()` on large scenes. Request the load, poll `load_threaded_get_status()` in `_process()`, update a ProgressBar, and transition when status returns `THREAD_LOAD_LOADED`. Players see feedback instead of a frozen screen.

---

## What's Next

**Module 12: Multiplayer & Networking** — Your game has menus, a HUD, a minimap, and a loading screen. It looks and feels like a real game. Now let's make it multiplayer. Module 12 covers Godot's high-level multiplayer API: spawning players over a network, synchronizing positions with MultiplayerSynchronizer, authoritative server logic, and building a working lobby with player name display. The UI skills from this module transfer directly — lobby screens, player list panels, and ping indicators are all built with the same Control nodes you learned here.

---

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
