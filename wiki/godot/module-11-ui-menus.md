# Module 11: UI & Menus

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** [Module 5: Signals, Resources & Game Architecture](module-05-signals-resources-architecture.md)

---

## Overview

Godot's UI system is built on `Control` nodes — a completely separate branch of the scene tree from `Node2D` and `Node3D`. Control nodes understand layout: anchors that keep buttons pinned to screen corners at any resolution, containers that arrange children automatically, themes that apply styles globally without touching individual nodes. Once you internalize how anchors and size flags interact, you stop fighting the UI system and start building fast.

The real insight is that Godot treats UI as a composable scene system, not a special editor mode. Your main menu is a scene. Your HUD is a scene. Your pause menu is a scene. You instance them, hide them, show them, and pass data between them the same way you do with any other scene. `CanvasLayer` puts UI on top of the 3D world without any z-fighting or coordinate confusion. `SubViewport` lets you render the game world into a texture and display it as a minimap widget. Everything composes.

By the end of this module you'll build a complete game UI: a main menu with animated transitions, a HUD with health bar and ammo counter, a pause menu overlay, a minimap using SubViewport, and an async loading screen with a real progress bar. The mini-project ties everything together. You'll also handle gamepad navigation, focus management, and rich text with BBCode — the things that separate a polished UI from a functional one.

---

## 1. Control Node Fundamentals

### Control vs Node2D

Control nodes and Node2D nodes live in separate coordinate systems. Control nodes are sized and positioned by the layout system. Node2D nodes use `position` in world pixels. You can mix them — `CanvasItem` is the common ancestor — but inside a UI tree you almost always want Control nodes exclusively. Using a `Node2D` inside a `Container` breaks the container's layout logic.

```
Node2D          ← 2D world space, position in pixels
Control         ← UI layout space, sized by anchors/containers
  Button
  Label
  VBoxContainer
    HBoxContainer
      TextureRect
      Label
```

### The Rect System

Every Control node has a `Rect` that defines its position and size. You can read it at runtime:

```gdscript
extends Control

func _ready() -> void:
    # Size of this control in pixels
    var size: Vector2 = get_size()

    # Position relative to parent
    var pos: Vector2 = get_position()

    # Both combined — also available as property
    var rect: Rect2 = get_rect()

    # Global position (in screen space)
    var global_pos: Vector2 = global_position

    print("My rect: ", rect)
```

### Anchors and Offsets

Anchors define how a Control's edges are attached to its parent. Each of the four edges (left, top, right, bottom) has an anchor value from `0.0` to `1.0`, where `0.0` is the parent's top/left edge and `1.0` is the parent's bottom/right edge.

The Inspector shows these as **Anchor Left**, **Anchor Top**, **Anchor Right**, **Anchor Bottom**. The **Offset** values add pixel offsets from the anchor point.

Common anchor presets (the dropdown in the toolbar when a Control is selected):

| Preset | Anchors | Use case |
|--------|---------|----------|
| Top Left | (0,0,0,0) | Fixed position, top-left corner |
| Top Right | (1,0,1,0) | Pin to top-right corner |
| Bottom Left | (0,1,0,1) | Pin to bottom-left |
| Bottom Right | (1,1,1,1) | Pin to bottom-right |
| Center | (0.5,0.5,0.5,0.5) | Centered, fixed size |
| Full Rect | (0,0,1,1) | Fill entire parent |
| Top Wide | (0,0,1,0) | Stretch across top |
| Left Wide | (0,0,0,1) | Stretch down left side |

Setting anchors in code:

```gdscript
extends Control

func _ready() -> void:
    # Full rect — fill entire parent
    anchor_left = 0.0
    anchor_top = 0.0
    anchor_right = 1.0
    anchor_bottom = 1.0
    offset_left = 0.0
    offset_top = 0.0
    offset_right = 0.0
    offset_bottom = 0.0

    # Or use the convenience method
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    # Center preset with a specific size
    set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    size = Vector2(400.0, 300.0)
```

### Grow Direction

When the parent resizes, a Control can grow in different directions. The **Grow Direction** property controls which way the Control expands relative to its anchor point:

- `BEGIN` — grows from right to left (or bottom to top)
- `END` — grows from left to right (or top to bottom)
- `BOTH` — grows from the center outward

This matters for things like a health bar anchored to the top-left: you want it to grow to the right as health increases, not grow left and overflow off-screen.

```gdscript
# Health bar pinned to top-left, grows right
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
    health_bar.anchor_left = 0.0
    health_bar.anchor_top = 0.0
    health_bar.anchor_right = 0.0   # Fixed right edge
    health_bar.anchor_bottom = 0.0
    health_bar.grow_horizontal = Control.GROW_DIRECTION_END  # Grows rightward
```

### Minimum Size

Every Control has a **minimum size** — the smallest it can shrink to while still being useful. Containers respect minimum size when laying out children. A Button's minimum size is determined by its text and icon. A Container's minimum size is the sum of its children's minimum sizes plus separation.

You can override minimum size in the Inspector (**Custom Minimum Size**) or in code:

```gdscript
func _ready() -> void:
    # Force this control to be at least 200x50 pixels
    custom_minimum_size = Vector2(200.0, 50.0)
```

---

## 2. Layout with Containers

Containers are Control nodes that automatically arrange their children. You almost never manually position child Controls inside a Container — you set their **size flags** and the Container handles the rest.

### Size Flags

Size flags tell a Container how a child wants to be sized on each axis:

| Flag | Meaning |
|------|---------|
| `SIZE_SHRINK_BEGIN` | Use minimum size, align to start |
| `SIZE_SHRINK_CENTER` | Use minimum size, center |
| `SIZE_SHRINK_END` | Use minimum size, align to end |
| `SIZE_FILL` | Expand to fill available space |
| `SIZE_EXPAND` | Share extra space with other EXPAND children |
| `SIZE_EXPAND_FILL` | Fill AND share extra space (most common) |

In practice you'll use `SIZE_EXPAND_FILL` for elements you want to stretch, and `SIZE_SHRINK_*` variants for fixed-size elements.

```gdscript
extends VBoxContainer

func _ready() -> void:
    # Make a child fill the horizontal space
    var label: Label = $MyLabel
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    # Center something vertically without expanding
    var icon: TextureRect = $Icon
    icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
```

### VBoxContainer and HBoxContainer

The workhorses of UI layout. `VBoxContainer` stacks children vertically, `HBoxContainer` stacks them horizontally. Set **Separation** in the Inspector to add spacing between children.

```gdscript
# Scene tree:
# VBoxContainer
#   Label ("Player Stats")
#   HBoxContainer
#     Label ("HP:")
#     ProgressBar (size_flags_horizontal = EXPAND_FILL)
#   HBoxContainer
#     Label ("Ammo:")
#     Label (ammo_count)
#   Button ("Back to Menu")

extends VBoxContainer

@onready var hp_bar: ProgressBar = $HP_Row/HPBar
@onready var ammo_label: Label = $Ammo_Row/AmmoLabel

func update_hp(current: float, max_hp: float) -> void:
    hp_bar.max_value = max_hp
    hp_bar.value = current

func update_ammo(current: int, max_ammo: int) -> void:
    ammo_label.text = "%d / %d" % [current, max_ammo]
```

### GridContainer

Arranges children in a grid. Set **Columns** and children flow into rows automatically.

```gdscript
# Scene tree:
# GridContainer (columns = 4)
#   TextureButton (item_0)
#   TextureButton (item_1)
#   ...

extends GridContainer

const ITEM_SCENE: PackedScene = preload("res://ui/inventory_item.tscn")

func populate_inventory(items: Array[ItemData]) -> void:
    # Clear existing children
    for child in get_children():
        child.queue_free()

    for item_data in items:
        var slot: TextureButton = ITEM_SCENE.instantiate()
        add_child(slot)
        slot.setup(item_data)
```

### MarginContainer

Adds padding around its single child. The **Margin Left/Right/Top/Bottom** theme overrides control the padding size. Useful for adding breathing room inside panels.

```gdscript
# Add 20px padding on all sides using theme override
func _ready() -> void:
    var margin: MarginContainer = $MarginContainer
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
```

### CenterContainer

Centers its single child both horizontally and vertically. Simple, effective. Use it when you have a panel or dialog box that needs to sit in the middle of the screen.

```
CanvasLayer
  CenterContainer (anchors: full rect)
    PanelContainer (your dialog box, has a fixed size)
      VBoxContainer
        Label
        HBoxContainer
          Button ("Yes")
          Button ("No")
```

### ScrollContainer

Wraps a child that may be larger than the visible area. Scroll bars appear automatically. Common for inventory lists, log windows, and settings pages with many options.

```gdscript
extends ScrollContainer

@onready var content: VBoxContainer = $VBoxContainer

func add_log_entry(text: String) -> void:
    var entry: Label = Label.new()
    entry.text = text
    entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(entry)

    # Scroll to bottom after adding — defer one frame so layout updates first
    await get_tree().process_frame
    scroll_vertical = get_v_scroll_bar().max_value
```

### SplitContainer

Provides a resizable split between two children — useful for editor-style UIs with a side panel and main viewport.

```gdscript
@onready var split: HSplitContainer = $HSplitContainer

func _ready() -> void:
    # Set initial split position in pixels
    split.split_offset = 250

    # React to user dragging the split
    split.dragged.connect(func(offset: int) -> void:
        print("Split dragged to: ", offset)
    )
```

---

## 3. Common UI Controls

### Button

The most used Control. Key properties:

```gdscript
extends Button

func _ready() -> void:
    # Text and icon
    text = "Play Game"
    icon = preload("res://ui/icons/play.png")

    # Alignment
    alignment = HORIZONTAL_ALIGNMENT_CENTER

    # Expand icon to fill height
    expand_icon = true

    # Toggle button (stays pressed)
    toggle_mode = true

    # Connect signals
    pressed.connect(_on_pressed)
    toggled.connect(_on_toggled)

func _on_pressed() -> void:
    print("Button pressed")

func _on_toggled(button_pressed: bool) -> void:
    print("Toggle state: ", button_pressed)
```

`TextureButton` uses separate textures for each state (normal, hover, pressed, disabled, focused). Good for custom icon buttons without theme complexity.

### Label

Displays text. Key properties for making text behave:

```gdscript
extends Label

func _ready() -> void:
    text = "Score: 9999"

    # Auto-wrap long text
    autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    # Clip text that overflows (no wrap)
    clip_text = true

    # Horizontal alignment
    horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # Uppercase rendering
    uppercase = true

    # Override theme font size for this specific label
    add_theme_font_size_override("font_size", 32)

    # Override color
    add_theme_color_override("font_color", Color.YELLOW)
```

### TextureRect

Displays a texture. The **Expand Mode** and **Stretch Mode** determine how the image fills its rect:

| Stretch Mode | Effect |
|--------------|--------|
| `STRETCH_SCALE` | Stretch to fill, ignores aspect ratio |
| `STRETCH_TILE` | Tile the texture |
| `STRETCH_KEEP` | Display at original size |
| `STRETCH_KEEP_CENTERED` | Original size, centered |
| `STRETCH_KEEP_ASPECT` | Scale to fit, maintain aspect ratio |
| `STRETCH_KEEP_ASPECT_CENTERED` | Same, centered |
| `STRETCH_KEEP_ASPECT_COVERED` | Scale to cover, maintain aspect ratio (may crop) |

```gdscript
@onready var portrait: TextureRect = $Portrait

func set_character_portrait(tex: Texture2D) -> void:
    portrait.texture = tex
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
```

### ProgressBar

The standard health/loading bar. Horizontal by default, flip `fill_mode` for vertical.

```gdscript
extends ProgressBar

func _ready() -> void:
    min_value = 0.0
    max_value = 100.0
    value = 75.0

    # Show/hide the percentage label
    show_percentage = false

    # Vertical progress bar (grows upward)
    fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP

func set_health(hp: float, max_hp: float) -> void:
    max_value = max_hp
    # Smooth animation using Tween
    var tween: Tween = create_tween()
    tween.tween_property(self, "value", hp, 0.2).set_ease(Tween.EASE_OUT)
```

### LineEdit and TextEdit

`LineEdit` is single-line input. `TextEdit` is multi-line. Both emit signals when content changes.

```gdscript
extends LineEdit

func _ready() -> void:
    # Placeholder text
    placeholder_text = "Enter your name..."

    # Maximum characters
    max_length = 20

    # Secret mode (passwords)
    secret = true
    secret_character = "•"

    # Connect signals
    text_submitted.connect(_on_submitted)  # Enter key pressed
    text_changed.connect(_on_text_changed)

func _on_submitted(new_text: String) -> void:
    print("Player entered: ", new_text)

func _on_text_changed(new_text: String) -> void:
    # Live validation example
    if new_text.length() < 3:
        add_theme_color_override("font_color", Color.RED)
    else:
        remove_theme_color_override("font_color")
```

### OptionButton

A dropdown selector. Cleaner than a series of radio buttons for mutually exclusive choices.

```gdscript
extends OptionButton

func _ready() -> void:
    # Populate options
    add_item("1920x1080")
    add_item("2560x1440")
    add_item("3840x2160")

    # Add with metadata — store actual values alongside display text
    add_item("Low", 0)
    add_item("Medium", 1)
    add_item("High", 2)
    add_item("Ultra", 3)

    # Select by index
    selected = 1

    # Connect
    item_selected.connect(_on_quality_selected)

func _on_quality_selected(index: int) -> void:
    var quality_level: int = get_item_id(index)
    print("Quality set to: ", quality_level)
```

### TabContainer

Groups multiple panels with tab headers. Each direct child becomes a tab, labeled with the child's name.

```gdscript
extends TabContainer

func _ready() -> void:
    # Set current tab by index
    current_tab = 0

    # Connect tab change
    tab_changed.connect(_on_tab_changed)

    # Customize tab alignment
    tab_alignment = TabBar.ALIGNMENT_CENTER

func _on_tab_changed(tab: int) -> void:
    match tab:
        0: print("Gameplay tab")
        1: print("Graphics tab")
        2: print("Audio tab")
        3: print("Controls tab")
```

### ItemList

A scrollable list of items with optional icons. Good for inventory displays, file browsers, and selection lists.

```gdscript
extends ItemList

func _ready() -> void:
    # Add items
    add_item("Sword")
    add_item("Shield")
    add_item("Health Potion")

    # Add with icon
    var icon: Texture2D = preload("res://icons/sword.png")
    add_item("Magic Sword", icon)

    # Selection mode
    select_mode = ItemList.SELECT_SINGLE

    # Allow multiple selection
    select_mode = ItemList.SELECT_MULTI

    # Connect
    item_selected.connect(_on_item_selected)
    item_activated.connect(_on_item_activated)  # Double-click or Enter

func _on_item_selected(index: int) -> void:
    print("Selected: ", get_item_text(index))

func _on_item_activated(index: int) -> void:
    print("Activated: ", get_item_text(index))
    # Use item
```

---

## 4. Themes & Styling

### What a Theme Is

A `Theme` resource is a database of visual properties — fonts, colors, StyleBoxes, icon textures, constants — organized by Control type. Assigning a Theme to a Control node applies it to that node AND all its descendants. One Theme at your scene root styles everything underneath it.

This is the right way to style Godot UI. If you're adding `add_theme_color_override()` calls everywhere, you're fighting the system. Define your game's look in a Theme, assign it once, done.

### Creating a Theme

In the FileSystem dock: right-click → New Resource → Theme. Save it as `res://ui/game_theme.tres`.

Assign it to your root UI node in the Inspector (`Theme` property). Or load it in code:

```gdscript
extends Control

const GAME_THEME: Theme = preload("res://ui/game_theme.tres")

func _ready() -> void:
    theme = GAME_THEME
```

### Editing a Theme

Double-click a `.tres` Theme file to open the Theme editor at the bottom of the screen. You'll see a panel with:

- **Controls** on the left — select which Control type you're styling (Button, Label, ProgressBar, etc.)
- **Properties** in the middle — Colors, Constants, Fonts, Font Sizes, Icons, Styles
- **Preview** on the right — live preview of how controls look with your theme

For each Control type, you can override:
- **Color** — `font_color`, `font_hover_color`, `font_pressed_color`, etc.
- **Constant** — numeric values like `separation`, `margin`
- **Font** — font resources per state
- **Font Size** — point sizes per state
- **Icon** — texture overrides
- **Style** — `StyleBox` resources per state (normal, hover, pressed, disabled, focus)

### StyleBoxFlat

`StyleBoxFlat` is a programmatic style — no textures needed. It supports:
- Background color
- Border (width, color)
- Corner radius (rounded corners)
- Shadow (offset, size, color)
- Content margins (internal padding)

```gdscript
# Creating a StyleBoxFlat in code
func make_button_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.4, 0.8, 1.0)       # Dark blue
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.4, 0.6, 1.0, 1.0)   # Light blue border
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    style.content_margin_left = 16.0
    style.content_margin_right = 16.0
    style.content_margin_top = 8.0
    style.content_margin_bottom = 8.0
    # Drop shadow
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
    style.shadow_size = 4
    style.shadow_offset = Vector2(2.0, 2.0)
    return style

func _ready() -> void:
    var btn: Button = $MyButton
    btn.add_theme_stylebox_override("normal", make_button_style())
```

### StyleBoxTexture

Uses a texture with nine-patch slicing — the corners stay fixed while the center stretches. Good for UI panels with decorative borders.

```gdscript
func make_panel_style() -> StyleBoxTexture:
    var style: StyleBoxTexture = StyleBoxTexture.new()
    style.texture = preload("res://ui/panel_bg.png")
    # Define the nine-patch margins (don't stretch these pixel regions)
    style.texture_margin_left = 16.0
    style.texture_margin_right = 16.0
    style.texture_margin_top = 16.0
    style.texture_margin_bottom = 16.0
    return style
```

### Type Variations

Godot 4 lets you create variants of a Control type with custom style within a single Theme. For example, you might want a "DangerButton" that uses red colors but otherwise behaves like a Button.

In the Theme editor: click the **+** button next to "Types", enter `Button`, then check "Create Variation" and name it `DangerButton`. Style it with red backgrounds.

Apply it to a specific button:

```gdscript
# In the Inspector, set "Theme Type Variation" to "DangerButton"
# Or in code:
func _ready() -> void:
    $DeleteButton.theme_type_variation = "DangerButton"
```

### Per-Node Overrides vs Theme

Per-node overrides (`add_theme_color_override()`) win over Theme. Use overrides sparingly — for one-off cases where a specific node needs to look different. Use Theme for anything that should be consistent across your game.

```gdscript
# Good: quick one-off override
$ErrorLabel.add_theme_color_override("font_color", Color.RED)

# Also good: removing an override to fall back to Theme
$ErrorLabel.remove_theme_color_override("font_color")

# Check if an override exists
if $ErrorLabel.has_theme_color_override("font_color"):
    print("Error label has a color override")
```

### Loading Fonts

Godot supports `.ttf`, `.otf`, and `.fnt` bitmap fonts. Import a font file, then reference it in your Theme or assign directly:

```gdscript
func _ready() -> void:
    var font: FontFile = preload("res://ui/fonts/Roboto-Regular.ttf")
    $TitleLabel.add_theme_font_override("font", font)
    $TitleLabel.add_theme_font_size_override("font_size", 48)
```

For bitmap fonts (pixel art games), `.fnt` files with a matching texture atlas work great. Import them and use `FontFile` the same way.

---

## 5. CanvasLayer & UI Layering

### The Problem CanvasLayer Solves

If you put a HUD directly in your 3D game scene as a child of `Node3D` nodes, the camera moving around will not move the HUD (Control nodes aren't in 3D space), but depth sorting and camera transforms can cause subtle issues. More importantly, there's no clean separation between game world and UI.

`CanvasLayer` solves this by creating a completely separate 2D canvas that renders independently from the main viewport. It's always on top. The camera moving in 3D doesn't affect it. This is how HUDs, menus, and overlays should be done.

### Scene Structure

```
# Main game scene
Node3D (GameWorld)
  CharacterBody3D (Player)
  MeshInstance3D (Environment)
  DirectionalLight3D
  Camera3D
  CanvasLayer (HUD)         ← UI lives here, layer = 1
    Control (full rect)
      HBoxContainer (top bar)
        HealthBar
        AmmoCounter
      Label (score, top-right)
  CanvasLayer (PauseMenu)   ← higher layer number = renders on top
    Control (full rect)
      PanelContainer (centered dialog)
```

### Layer Ordering

The `layer` property of `CanvasLayer` determines draw order. Higher numbers render on top of lower numbers. The default game canvas (where 2D nodes live) is at layer 0.

Common conventions:
- Layer 1: HUD (health, ammo, score, minimap)
- Layer 2: Notifications, popups
- Layer 5: Pause menu
- Layer 10: Loading screen, transitions
- Layer 100: Debug overlays

```gdscript
extends CanvasLayer

func _ready() -> void:
    layer = 5  # This canvas renders on top of layer 1-4 canvases
```

### follow_viewport

By default, `CanvasLayer` ignores the main viewport's camera transform. This is what you want for HUDs. But for world-space UI that should scroll with the camera (like name tags floating above NPC heads in a 2D game), set `follow_viewport = true`.

```gdscript
# World-space UI that follows the camera
extends CanvasLayer

func _ready() -> void:
    follow_viewport = true
    follow_viewport_scale = 1.0  # Zoom factor relative to main viewport
```

### Showing and Hiding UI Layers

```gdscript
# HUD.gd
extends CanvasLayer

func show_hud() -> void:
    visible = true

func hide_hud() -> void:
    visible = false

# PauseMenu.gd
extends CanvasLayer

func _ready() -> void:
    visible = false  # Start hidden

func open_pause_menu() -> void:
    visible = true
    get_tree().paused = true
    # Make sure UI still processes when paused
    process_mode = Node.PROCESS_MODE_ALWAYS
    $ResumeButton.grab_focus()

func close_pause_menu() -> void:
    visible = false
    get_tree().paused = false
```

### Process Mode and Pausing

When you pause the tree with `get_tree().paused = true`, nodes with the default process mode stop processing. Your pause menu needs to keep working. Set it to `PROCESS_MODE_ALWAYS` so it processes even when the tree is paused.

```gdscript
# In your pause menu scene's root node
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Now _process, _input, etc. work even when game is paused
```

---

## 6. Focus & Gamepad Navigation

### Why Focus Matters

Mouse users click. Gamepad users navigate with d-pad or left stick. Keyboard users tab through inputs. Focus is what makes your UI work for all input types without writing separate code for each.

Every Control node has a **focus mode**. When a Control is focused, it receives keyboard/gamepad input and shows a visual focus indicator (the focus `StyleBox` from your Theme).

Focus modes:
- `FOCUS_NONE` — never focuses (Labels, TextureRects)
- `FOCUS_CLICK` — focuses when clicked (most interactive controls)
- `FOCUS_ALL` — focuses on click OR tab navigation (recommended for gamepad support)

```gdscript
# Enable full focus for gamepad navigation
func _ready() -> void:
    focus_mode = Control.FOCUS_ALL
```

### Focus Neighbors

Tell Godot which control to move focus to in each direction. Set **Focus Neighbor** properties in the Inspector (Left, Right, Top, Bottom) or in code:

```gdscript
extends VBoxContainer

@onready var play_btn: Button = $PlayButton
@onready var settings_btn: Button = $SettingsButton
@onready var quit_btn: Button = $QuitButton

func _ready() -> void:
    # Manual focus routing
    play_btn.focus_neighbor_bottom = play_btn.get_path_to(settings_btn)
    settings_btn.focus_neighbor_top = settings_btn.get_path_to(play_btn)
    settings_btn.focus_neighbor_bottom = settings_btn.get_path_to(quit_btn)
    quit_btn.focus_neighbor_top = quit_btn.get_path_to(settings_btn)

    # Wrap around: bottom of last goes to top of first
    quit_btn.focus_neighbor_bottom = quit_btn.get_path_to(play_btn)
    play_btn.focus_neighbor_top = play_btn.get_path_to(quit_btn)

    # Set initial focus when menu opens
    play_btn.grab_focus()
```

### Grabbing Focus

Always call `grab_focus()` when showing a menu so gamepad users have a starting point:

```gdscript
# MainMenu.gd
func _ready() -> void:
    # Give focus to the first interactive element
    $PlayButton.grab_focus()

# PauseMenu.gd
func open() -> void:
    visible = true
    await get_tree().process_frame  # Wait one frame for layout to settle
    $ResumeButton.grab_focus()
```

### Focus Visual Feedback

The `focus` StyleBox in your Theme defines what a focused button looks like. Without it, focused buttons get a default system outline that probably doesn't match your UI style.

In the Theme editor, for Button → Style → focus, set a `StyleBoxFlat` with a bright border or colored background:

```gdscript
# Programmatic focus style
func make_focus_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.0, 0.0, 0.0, 0.0)      # Transparent fill
    style.border_width_left = 3
    style.border_width_right = 3
    style.border_width_top = 3
    style.border_width_bottom = 3
    style.border_color = Color(1.0, 0.85, 0.0, 1.0)  # Gold border
    style.corner_radius_top_left = 6
    style.corner_radius_top_right = 6
    style.corner_radius_bottom_left = 6
    style.corner_radius_bottom_right = 6
    return style
```

### Handling UI Input Actions

Define UI actions in **Project Settings → Input Map**:
- `ui_accept` — confirm (Enter, A button)
- `ui_cancel` — back/cancel (Escape, B button)
- `ui_left/right/up/down` — navigation (Arrow keys, D-pad, left stick)

These are built-in and work automatically with focused Controls. Buttons respond to `ui_accept` when focused. For custom behavior:

```gdscript
extends Control

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if visible:
            close_menu()
            get_viewport().set_input_as_handled()
```

---

## 7. RichTextLabel & BBCode

### What RichTextLabel Is For

`RichTextLabel` displays text with inline formatting — bold, italic, colors, sizes, images, clickable links, custom effects. The plain `Label` node is for static text. Use `RichTextLabel` for dialogue boxes, item descriptions, log windows, tooltips, and anything with mixed formatting.

Enable BBCode by checking `bbcode_enabled` in the Inspector or in code:

```gdscript
extends RichTextLabel

func _ready() -> void:
    bbcode_enabled = true

    # autowrap is on by default in RichTextLabel
    # For scrolling, put it inside a ScrollContainer or use the built-in scroll
    scroll_following = true  # Auto-scroll to bottom as text is added
```

### BBCode Tags

```gdscript
# Basic formatting
text = "[b]Bold text[/b]"
text = "[i]Italic text[/i]"
text = "[u]Underlined[/u]"
text = "[s]Strikethrough[/s]"
text = "[code]monospace code[/code]"

# Colors
text = "[color=red]Red text[/color]"
text = "[color=#ff6600]Orange hex[/color]"
text = "[color=rgba(255,128,0,0.8)]Semi-transparent[/color]"

# Size
text = "[font_size=32]Big text[/font_size]"

# Alignment (wraps entire paragraphs)
text = "[center]Centered paragraph[/center]"
text = "[right]Right-aligned[/right]"
text = "[fill]Justified text[/fill]"

# Horizontal rule
text = "[hr]"

# Lists
text = "[ul]Bullet item\nAnother item[/ul]"
text = "[ol]Numbered item\nAnother item[/ol]"

# URLs and clickable text
text = "[url=https://godotengine.org]Visit Godot[/url]"

# Inline images
text = "[img]res://ui/icons/coin.png[/img]"
text = "[img=32x32]res://ui/icons/coin.png[/img]"  # Scaled size

# Named font (must exist in Theme)
text = "[font=res://ui/fonts/heading.ttf][font_size=48]Title[/font_size][/font]"
```

### The Push/Pop System (Code API)

Instead of building BBCode strings, you can use the push/pop API for cleaner code:

```gdscript
extends RichTextLabel

func build_item_tooltip(item: ItemData) -> void:
    clear()

    push_bold()
    add_text(item.name)
    pop()  # end bold

    add_newline()

    push_color(item.rarity_color())
    add_text("[%s]" % item.rarity_name())
    pop()

    add_newline()
    add_newline()

    push_italics()
    add_text(item.description)
    pop()

    add_newline()
    add_newline()

    push_color(Color.YELLOW)
    add_text("ATK: +%d" % item.attack_bonus)
    pop()
    add_newline()

    push_color(Color.CYAN)
    add_text("DEF: +%d" % item.defense_bonus)
    pop()
```

### Custom Effects

`RichTextEffect` lets you add custom animated effects to text — wave, tornado, color cycle, fade in letter by letter.

```gdscript
# WaveEffect.gd — makes text bob up and down
extends RichTextEffect

# Use in BBCode as: [wave amp=20 freq=2]Wavy text[/wave]
var bbcode: String = "wave"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
    var amp: float = char_fx.env.get("amp", 10.0)
    var freq: float = char_fx.env.get("freq", 2.0)
    char_fx.offset.y = sin(char_fx.elapsed_time * freq * TAU + char_fx.range.x * 0.5) * amp
    return true
```

Register the effect:

```gdscript
# In your RichTextLabel script
func _ready() -> void:
    bbcode_enabled = true
    install_effect(WaveEffect.new())
    install_effect(ShakeEffect.new())

    text = "[wave amp=15 freq=3]This text waves![/wave]"
```

### Clickable Text with meta

`[url=...]` tags emit the `meta_clicked` signal when clicked. Use this for clickable links in chat logs, help text, and item cross-references.

```gdscript
extends RichTextLabel

func _ready() -> void:
    bbcode_enabled = true
    text = "Check out [url=item:sword_of_fire]Sword of Fire[/url] in the shop."

    meta_clicked.connect(_on_meta_clicked)
    meta_hover_started.connect(_on_meta_hover_started)
    meta_hover_ended.connect(_on_meta_hover_ended)

func _on_meta_clicked(meta: Variant) -> void:
    var meta_str: String = str(meta)
    if meta_str.begins_with("item:"):
        var item_id: String = meta_str.substr(5)
        show_item_details(item_id)
    elif meta_str.begins_with("http"):
        OS.shell_open(meta_str)

func _on_meta_hover_started(meta: Variant) -> void:
    # Show tooltip
    pass

func _on_meta_hover_ended(meta: Variant) -> void:
    # Hide tooltip
    pass
```

### Typewriter Effect

Animating text appearing letter by letter is a classic dialogue effect:

```gdscript
extends RichTextLabel

var full_text: String = ""
var visible_ratio_tween: Tween = null

func display_dialogue(dialogue: String, chars_per_second: float = 30.0) -> void:
    bbcode_enabled = true
    text = dialogue
    # Start at 0 visible characters
    visible_ratio = 0.0

    # Tween visible_ratio from 0 to 1
    if visible_ratio_tween:
        visible_ratio_tween.kill()
    visible_ratio_tween = create_tween()

    var duration: float = float(get_total_character_count()) / chars_per_second
    visible_ratio_tween.tween_property(self, "visible_ratio", 1.0, duration)
    await visible_ratio_tween.finished

func skip_typewriter() -> void:
    if visible_ratio_tween and visible_ratio_tween.is_running():
        visible_ratio_tween.kill()
        visible_ratio = 1.0
```

---

## 8. SubViewport for Minimap

### How SubViewport Works

`SubViewport` renders its children into a texture that you can display anywhere in the UI. The process:

1. Create a `SubViewport` node
2. Put a `Camera2D` (or `Camera3D`) and the things you want to render inside it
3. Reference the viewport's texture: `sub_viewport.get_texture()`
4. Display that texture in a `TextureRect` in your HUD

### Minimap Scene Structure

```
# The SubViewport setup (can be its own scene or inside HUD)
SubViewport (minimap_viewport)    ← renders the minimap
  Camera2D (minimap_camera)
  # OR: for a top-down 3D minimap:
  Camera3D (minimap_camera_3d)    ← orthographic, looking down

# The HUD where minimap displays
CanvasLayer (HUD)
  Control
    PanelContainer (minimap_container, bottom-right corner)
      SubViewportContainer
        SubViewport                 ← same SubViewport as above
      ColorRect (minimap_border)   ← overlay border effect
```

Wait — `SubViewportContainer` is the better way. It handles the `SubViewport` internally and renders it directly. You don't need to manually fetch the texture.

### Using SubViewportContainer

```
# Scene tree for minimap HUD element:
MarginContainer (anchored bottom-right)
  VBoxContainer
    Label ("MAP")
    SubViewportContainer (128x128, stretch = true)
      SubViewport (128x128)
        Camera2D (MinimapCamera)
```

```gdscript
# Minimap.gd — attaches to the SubViewportContainer or a parent node
extends Control

@onready var minimap_camera: Camera2D = $SubViewportContainer/SubViewport/MinimapCamera
@export var player: CharacterBody2D  # Or Node3D for 3D game

@export var zoom_level: float = 0.1   # How zoomed out the minimap is

func _ready() -> void:
    minimap_camera.zoom = Vector2(zoom_level, zoom_level)

func _process(_delta: float) -> void:
    if player:
        # Keep minimap camera centered on player
        minimap_camera.global_position = player.global_position
```

### Top-Down 3D Minimap

For a 3D game, use a `Camera3D` in the `SubViewport` with orthographic projection looking straight down:

```gdscript
# MinimapCamera3D.gd
extends Camera3D

@export var target: Node3D
@export var height: float = 100.0
@export var map_size: float = 50.0   # How many world units visible

func _ready() -> void:
    # Orthographic projection for accurate top-down map
    projection = Camera3D.PROJECTION_ORTHOGONAL
    size = map_size
    # Look straight down
    rotation_degrees = Vector3(-90.0, 0.0, 0.0)

func _process(_delta: float) -> void:
    if target:
        global_position = Vector3(target.global_position.x, height, target.global_position.z)
```

### Render Layers for Minimap

You don't want EVERYTHING in the game world appearing on the minimap — just terrain, walls, key landmarks, and the player icon. Use `VisualInstance3D.layers` (a bitmask) to control what each camera sees.

```gdscript
# In Project Settings → Render → Layers → 3D Render, name layer 2 "Minimap"

# Terrain — visible on main camera AND minimap
terrain_mesh.layers = 0b11  # bits 0 and 1 = layers 1 and 2

# Detailed props — only main camera, not minimap
rock_mesh.layers = 0b01     # only layer 1

# Minimap icons (arrows, dots for enemies)
minimap_icon.layers = 0b10  # only layer 2

# Configure cameras
main_camera.cull_mask = 0b01        # Sees layer 1 only
minimap_camera.cull_mask = 0b10     # Sees layer 2 only
```

### Player Dot on Minimap

For a 2D minimap, draw a dot or arrow representing the player's position:

```gdscript
# MinimapDot.gd — a ColorRect or TextureRect that follows the player
extends Control

@export var player: Node3D
@export var map_center: Vector2 = Vector2(64.0, 64.0)  # Center of 128x128 minimap
@export var world_to_minimap_scale: float = 0.5         # world units per pixel

func _process(_delta: float) -> void:
    if not player:
        return
    var world_pos: Vector3 = player.global_position
    # Convert world XZ to minimap UV
    var minimap_pos: Vector2 = Vector2(world_pos.x, world_pos.z) * world_to_minimap_scale
    position = map_center + minimap_pos - size * 0.5

    # Rotate dot to match player facing direction
    rotation = -player.rotation.y  # Y rotation in 3D → rotation in 2D
```

### SubViewport Performance Tips

SubViewports render every frame by default. For a minimap that doesn't need to update constantly:

```gdscript
# Update minimap at 15 FPS instead of 60
func _ready() -> void:
    var sub_vp: SubViewport = $SubViewportContainer/SubViewport
    sub_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    # Or for manual control:
    sub_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED

    # Manual update timer
    var timer: Timer = Timer.new()
    timer.wait_time = 1.0 / 15.0  # 15 FPS
    timer.autostart = true
    timer.timeout.connect(func() -> void:
        sub_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
    )
    add_child(timer)
```

---

## 9. Loading Screens & Scene Transitions

### The Problem with change_scene_to_file

`get_tree().change_scene_to_file("res://scenes/big_level.tscn")` blocks the main thread while loading. For small scenes, this is fine — instant. For large levels with many assets, it freezes the game for a noticeable moment. The player sees a stutter or a black flash.

The solution is `ResourceLoader.load_threaded_request()` — async loading that happens in a background thread while your loading screen plays an animation or progress bar.

### Async Loading Flow

```gdscript
# SceneManager.gd — autoload singleton
extends Node

signal load_progress_changed(progress: float)
signal scene_loaded

var _next_scene_path: String = ""
var _loading: bool = false

func change_scene(path: String) -> void:
    if _loading:
        return
    _loading = true
    _next_scene_path = path

    # Show loading screen FIRST
    # (LoadingScreen is a separate CanvasLayer autoload or we call it here)
    LoadingScreen.show_loading()

    # Request async load
    ResourceLoader.load_threaded_request(path)

    # Poll in _process
    set_process(true)

func _process(_delta: float) -> void:
    if not _loading:
        return

    var progress: Array = []
    var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_next_scene_path, progress)

    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            var pct: float = progress[0] if progress.size() > 0 else 0.0
            emit_signal("load_progress_changed", pct)
            LoadingScreen.set_progress(pct)

        ResourceLoader.THREAD_LOAD_LOADED:
            set_process(false)
            _loading = false
            var packed_scene: PackedScene = ResourceLoader.load_threaded_get(_next_scene_path)
            LoadingScreen.hide_loading()
            get_tree().change_scene_to_packed(packed_scene)

        ResourceLoader.THREAD_LOAD_FAILED:
            set_process(false)
            _loading = false
            push_error("Failed to load scene: " + _next_scene_path)
            LoadingScreen.hide_loading()
```

### Loading Screen Scene

```gdscript
# LoadingScreen.gd — CanvasLayer autoload, layer = 10
extends CanvasLayer

@onready var progress_bar: ProgressBar = $Control/CenterContainer/VBox/ProgressBar
@onready var status_label: Label = $Control/CenterContainer/VBox/StatusLabel
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var background: ColorRect = $Control/Background

var _target_progress: float = 0.0

func _ready() -> void:
    visible = false
    layer = 10

func show_loading(tip: String = "") -> void:
    visible = true
    progress_bar.value = 0.0
    _target_progress = 0.0
    status_label.text = "Loading..." if tip.is_empty() else tip
    anim.play("fade_in")

func hide_loading() -> void:
    anim.play("fade_out")
    await anim.animation_finished
    visible = false

func set_progress(pct: float) -> void:
    # Target value — lerp in _process for smooth bar
    _target_progress = pct * 100.0

func _process(delta: float) -> void:
    if not visible:
        return
    # Smooth progress bar — don't jump instantly
    progress_bar.value = lerpf(progress_bar.value, _target_progress, delta * 5.0)

    # Update label
    var pct_int: int = int(progress_bar.value)
    status_label.text = "Loading... %d%%" % pct_int
```

### Minimum Loading Time

Sometimes loading finishes so fast the loading screen flashes. Add a minimum display time:

```gdscript
# In SceneManager.gd
const MIN_LOADING_DISPLAY_TIME: float = 0.5  # seconds

var _load_start_time: float = 0.0

func change_scene(path: String) -> void:
    _load_start_time = Time.get_ticks_msec() / 1000.0
    # ... rest of the loading code

# In the THREAD_LOAD_LOADED case:
ResourceLoader.THREAD_LOAD_LOADED:
    var elapsed: float = Time.get_ticks_msec() / 1000.0 - _load_start_time
    var remaining: float = max(0.0, MIN_LOADING_DISPLAY_TIME - elapsed)

    if remaining > 0.0:
        await get_tree().create_timer(remaining).timeout

    # Now transition
    var packed_scene: PackedScene = ResourceLoader.load_threaded_get(_next_scene_path)
    LoadingScreen.hide_loading()
    get_tree().change_scene_to_packed(packed_scene)
```

### Transition Animations

For scene transitions that don't need a full loading screen — just a quick fade or wipe — use an AnimationPlayer on a CanvasLayer with a ColorRect:

```gdscript
# TransitionOverlay.gd — CanvasLayer autoload, layer = 9
extends CanvasLayer

@onready var overlay: ColorRect = $ColorRect
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    layer = 9
    overlay.modulate.a = 0.0
    # "fade_out" animation: ColorRect alpha 0→1 over 0.3s
    # "fade_in" animation: ColorRect alpha 1→0 over 0.3s

func transition_to(path: String) -> void:
    anim.play("fade_out")           # Screen goes black
    await anim.animation_finished
    get_tree().change_scene_to_file(path)
    await get_tree().process_frame  # Wait for new scene to load
    anim.play("fade_in")            # Fade back in
    await anim.animation_finished
```

---

## 10. Building the Complete Game UI

This section walks through the full mini-project: main menu, HUD, pause menu, minimap, and loading screen, all wired together.

### Scene Structure Overview

```
res://
  ui/
    MainMenu.tscn
    HUD.tscn
    PauseMenu.tscn
    Minimap.tscn
    LoadingScreen.tscn (autoload)
    TransitionOverlay.tscn (autoload)
    SceneManager.gd (autoload)
    game_theme.tres
  scenes/
    Main.tscn (game world)
```

Autoloads registered in **Project Settings → Autoload**:
- `SceneManager` → `res://ui/SceneManager.gd`
- `LoadingScreen` → `res://ui/LoadingScreen.tscn`
- `TransitionOverlay` → `res://ui/TransitionOverlay.tscn`

### Main Menu

```gdscript
# MainMenu.gd
extends Control

@onready var play_btn: Button = %PlayButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var settings_panel: Control = %SettingsPanel
@onready var main_panel: Control = %MainPanel
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
    version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.1")

    play_btn.pressed.connect(_on_play_pressed)
    settings_btn.pressed.connect(_on_settings_pressed)
    quit_btn.pressed.connect(_on_quit_pressed)

    # Animate in
    anim.play("menu_appear")
    await anim.animation_finished
    play_btn.grab_focus()

func _on_play_pressed() -> void:
    anim.play("menu_disappear")
    await anim.animation_finished
    SceneManager.change_scene("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
    anim.play("to_settings")
    await anim.animation_finished
    settings_panel.grab_focus_first_child()

func _on_quit_pressed() -> void:
    anim.play("menu_disappear")
    await anim.animation_finished
    get_tree().quit()

func _on_settings_back_pressed() -> void:
    anim.play_backwards("to_settings")
    await anim.animation_finished
    settings_btn.grab_focus()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") and settings_panel.visible:
        _on_settings_back_pressed()
        get_viewport().set_input_as_handled()
```

Settings panel wires to `AudioServer` bus volumes and `DisplayServer` window mode:

```gdscript
# SettingsPanel.gd
extends Control

@onready var master_slider: HSlider = %MasterVolume
@onready var music_slider: HSlider = %MusicVolume
@onready var sfx_slider: HSlider = %SFXVolume
@onready var fullscreen_check: CheckButton = %FullscreenToggle

func _ready() -> void:
    # Load saved settings
    master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
    music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
    sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
    fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

    master_slider.value_changed.connect(func(val: float) -> void:
        AudioServer.set_bus_volume_db(0, linear_to_db(val))
    )
    fullscreen_check.toggled.connect(func(on: bool) -> void:
        if on:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    )

func grab_focus_first_child() -> void:
    master_slider.grab_focus()
```

### HUD

```gdscript
# HUD.gd
extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var ammo_label: Label = %AmmoLabel
@onready var score_label: Label = %ScoreLabel
@onready var minimap: Control = %Minimap
@onready var crosshair: TextureRect = %Crosshair
@onready var ability_cooldown: TextureRect = %AbilityCooldown
@onready var low_health_vignette: ColorRect = %LowHealthVignette

func _ready() -> void:
    layer = 1
    # Connect to game signals via autoload or direct reference
    GameEvents.player_health_changed.connect(_on_health_changed)
    GameEvents.player_ammo_changed.connect(_on_ammo_changed)
    GameEvents.score_changed.connect(_on_score_changed)

    low_health_vignette.modulate.a = 0.0

func _on_health_changed(current: float, maximum: float) -> void:
    health_bar.max_value = maximum
    var tween: Tween = create_tween()
    tween.tween_property(health_bar, "value", current, 0.25).set_ease(Tween.EASE_OUT)

    # Low health warning
    var health_pct: float = current / maximum
    var target_alpha: float = remap(health_pct, 0.0, 0.3, 0.6, 0.0)
    target_alpha = clampf(target_alpha, 0.0, 0.6)
    var vignette_tween: Tween = create_tween()
    vignette_tween.tween_property(low_health_vignette, "modulate:a", target_alpha, 0.3)

func _on_ammo_changed(current: int, reserve: int) -> void:
    ammo_label.text = "%d | %d" % [current, reserve]

    # Flash red when low
    if current <= 3:
        var tween: Tween = create_tween().set_loops(3)
        tween.tween_property(ammo_label, "modulate", Color.RED, 0.1)
        tween.tween_property(ammo_label, "modulate", Color.WHITE, 0.1)

func _on_score_changed(new_score: int) -> void:
    score_label.text = str(new_score).pad_zeros(6)

func show_damage_flash() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(low_health_vignette, "modulate:a", 0.8, 0.05)
    tween.tween_property(low_health_vignette, "modulate:a", low_health_vignette.modulate.a, 0.3)

func set_ability_cooldown(ratio: float) -> void:
    # ratio 0.0 = ready, 1.0 = on cooldown
    ability_cooldown.material.set_shader_parameter("cooldown", ratio)
```

### Pause Menu

```gdscript
# PauseMenu.gd
extends CanvasLayer

@onready var resume_btn: Button = %ResumeButton
@onready var settings_btn: Button = %SettingsButton
@onready var main_menu_btn: Button = %MainMenuButton
@onready var panel: PanelContainer = %Panel
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    layer = 5
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

    resume_btn.pressed.connect(close)
    settings_btn.pressed.connect(_on_settings_pressed)
    main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if visible:
            close()
        else:
            open()
        get_viewport().set_input_as_handled()

    if event.is_action_pressed("ui_cancel") and visible:
        close()
        get_viewport().set_input_as_handled()

func open() -> void:
    visible = true
    get_tree().paused = true
    anim.play("slide_in")
    await anim.animation_finished
    resume_btn.grab_focus()

func close() -> void:
    anim.play("slide_out")
    await anim.animation_finished
    visible = false
    get_tree().paused = false

func _on_settings_pressed() -> void:
    # Push settings panel over the pause menu
    pass

func _on_main_menu_pressed() -> void:
    get_tree().paused = false
    close()
    await get_tree().process_frame
    SceneManager.change_scene("res://ui/MainMenu.tscn")
```

### Minimap Integration

```gdscript
# MinimapHUD.gd — the minimap widget inside HUD
extends Control

@onready var sub_vp: SubViewport = $SubViewportContainer/SubViewport
@onready var minimap_cam: Camera3D = $SubViewportContainer/SubViewport/MinimapCamera
@onready var player_dot: Control = $PlayerDot
@onready var border: Panel = $Border

@export var player: Node3D
@export var cam_height: float = 80.0
@export var cam_size: float = 40.0

func _ready() -> void:
    minimap_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    minimap_cam.size = cam_size
    minimap_cam.rotation_degrees.x = -90.0

    # Only render "Minimap" render layer (layer bit 2)
    minimap_cam.cull_mask = (1 << 1)  # Layer 2

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        return

    var pos: Vector3 = player.global_position
    minimap_cam.global_position = Vector3(pos.x, cam_height, pos.z)

    # Rotate player dot
    player_dot.rotation = -player.rotation.y
    # Player dot stays centered in the minimap (it's always the center)
    player_dot.position = $SubViewportContainer.size * 0.5 - player_dot.size * 0.5
```

### Full SceneManager Autoload

```gdscript
# SceneManager.gd
extends Node

const MIN_LOADING_TIME: float = 0.4

var _loading_path: String = ""
var _is_loading: bool = false
var _load_start: float = 0.0

func _ready() -> void:
    set_process(false)

func change_scene(path: String, show_loading: bool = true) -> void:
    if _is_loading:
        push_warning("SceneManager: Already loading a scene")
        return

    _is_loading = true
    _loading_path = path
    _load_start = Time.get_ticks_msec() / 1000.0

    if show_loading:
        LoadingScreen.show_loading()
    else:
        TransitionOverlay.fade_out()
        await TransitionOverlay.fade_complete

    ResourceLoader.load_threaded_request(path)
    set_process(true)

func _process(_delta: float) -> void:
    if not _is_loading:
        return

    var progress: Array = []
    var status: ResourceLoader.ThreadLoadStatus = \
        ResourceLoader.load_threaded_get_status(_loading_path, progress)

    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            if progress.size() > 0:
                LoadingScreen.set_progress(progress[0])

        ResourceLoader.THREAD_LOAD_LOADED:
            set_process(false)
            _finish_loading()

        ResourceLoader.THREAD_LOAD_FAILED:
            set_process(false)
            _is_loading = false
            push_error("SceneManager: Failed to load '%s'" % _loading_path)
            LoadingScreen.hide_loading()

func _finish_loading() -> void:
    var elapsed: float = Time.get_ticks_msec() / 1000.0 - _load_start
    var wait: float = max(0.0, MIN_LOADING_TIME - elapsed)

    if wait > 0.0:
        await get_tree().create_timer(wait).timeout

    var packed: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
    _is_loading = false

    LoadingScreen.hide_loading()
    await get_tree().process_frame

    get_tree().change_scene_to_packed(packed)

    await get_tree().process_frame
    TransitionOverlay.fade_in()
```

### Wiring It All Together

In your main game scene, add the HUD and PauseMenu as child CanvasLayers. The HUD connects to game state signals. The PauseMenu handles `pause` input automatically.

```gdscript
# Main.gd — the root of the game world scene
extends Node3D

@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var player: CharacterBody3D = $Player

func _ready() -> void:
    # Wire player signals to HUD
    player.health_changed.connect(hud._on_health_changed)
    player.ammo_changed.connect(hud._on_ammo_changed)

    # Wire minimap to player
    hud.get_node("%Minimap").player = player

    # Set initial HUD values
    hud._on_health_changed(player.health, player.max_health)
    hud._on_ammo_changed(player.ammo, player.max_ammo)
```

---

## API Quick Reference

| Class | Purpose | Key Properties / Methods |
|-------|---------|--------------------------|
| `Control` | Base UI node | `anchor_*`, `offset_*`, `size`, `custom_minimum_size`, `theme`, `focus_mode`, `grab_focus()` |
| `Container` | Base layout class | `get_children()`, automatic layout via size flags |
| `VBoxContainer` | Vertical stack | `add_theme_constant_override("separation", n)` |
| `HBoxContainer` | Horizontal stack | Same as VBox |
| `GridContainer` | Grid layout | `columns` |
| `MarginContainer` | Adds padding | `margin_*` constants via theme override |
| `CenterContainer` | Centers child | Use Full Rect anchors |
| `ScrollContainer` | Scrollable content | `scroll_vertical`, `scroll_horizontal` |
| `Button` | Clickable button | `text`, `icon`, `pressed`, `toggled` |
| `Label` | Static text | `text`, `autowrap_mode`, `clip_text` |
| `TextureRect` | Image display | `texture`, `stretch_mode`, `expand_mode` |
| `ProgressBar` | Value bar | `min_value`, `max_value`, `value`, `fill_mode` |
| `LineEdit` | Single-line input | `text`, `placeholder_text`, `text_submitted` |
| `OptionButton` | Dropdown | `add_item()`, `selected`, `item_selected` |
| `TabContainer` | Tabbed panels | `current_tab`, `tab_changed` |
| `ItemList` | Scrollable list | `add_item()`, `select_mode`, `item_selected` |
| `RichTextLabel` | Formatted text | `bbcode_enabled`, `text`, `visible_ratio`, `meta_clicked` |
| `Theme` | Style database | Edited in Theme editor, assigned via `theme` property |
| `StyleBoxFlat` | Programmatic style | `bg_color`, `border_*`, `corner_radius_*`, `shadow_*` |
| `CanvasLayer` | UI canvas | `layer`, `follow_viewport`, `process_mode` |
| `SubViewport` | Render-to-texture | `render_target_update_mode`, `get_texture()` |
| `SubViewportContainer` | Display SubViewport | `stretch`, contains SubViewport as child |
| `ResourceLoader` | Async loading | `load_threaded_request()`, `load_threaded_get_status()`, `load_threaded_get()` |

---

## Common Pitfalls

### Pitfall 1: Positioning Controls with position instead of anchors

**WRONG:**
```gdscript
# This health bar is at pixel 10,10 — will be in the wrong place on different resolutions
$HealthBar.position = Vector2(10.0, 10.0)
```

**RIGHT:**
```gdscript
# Anchor to top-left with pixel offsets — correct at any resolution
$HealthBar.anchor_left = 0.0
$HealthBar.anchor_top = 0.0
$HealthBar.anchor_right = 0.0
$HealthBar.anchor_bottom = 0.0
$HealthBar.offset_left = 10.0
$HealthBar.offset_top = 10.0
# Or just set it in the editor with the anchor preset toolbar
```

### Pitfall 2: Not setting process_mode on pause menus

**WRONG:**
```gdscript
func open_pause_menu() -> void:
    $PauseMenu.visible = true
    get_tree().paused = true
    # Now the pause menu's buttons don't respond because the tree is paused!
```

**RIGHT:**
```gdscript
# In PauseMenu._ready():
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS  # Process even when tree is paused
    # Now the pause menu works correctly
```

### Pitfall 3: Forgetting to grab_focus when showing menus

**WRONG:**
```gdscript
func show_main_menu() -> void:
    visible = true
    # Gamepad user can't navigate — nothing is focused
```

**RIGHT:**
```gdscript
func show_main_menu() -> void:
    visible = true
    await get_tree().process_frame  # Let layout settle first
    $PlayButton.grab_focus()        # Gamepad navigation starts here
```

### Pitfall 4: Calling ResourceLoader.load_threaded_get() before load is complete

**WRONG:**
```gdscript
func load_level(path: String) -> void:
    ResourceLoader.load_threaded_request(path)
    var scene: PackedScene = ResourceLoader.load_threaded_get(path)  # Called immediately!
    # This blocks the main thread waiting for the load to finish — same as synchronous load
```

**RIGHT:**
```gdscript
func _process(_delta: float) -> void:
    var status := ResourceLoader.load_threaded_get_status(_loading_path)
    if status == ResourceLoader.THREAD_LOAD_LOADED:
        var scene: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
        # NOW it's safe to get — load is complete
```

### Pitfall 5: Styling individual nodes instead of using a Theme

**WRONG:**
```gdscript
# Doing this for every button in the game
$Button1.add_theme_color_override("font_color", Color.WHITE)
$Button2.add_theme_color_override("font_color", Color.WHITE)
$Button3.add_theme_color_override("font_color", Color.WHITE)
# Now changing the color means touching every script
```

**RIGHT:**
```gdscript
# Define font_color once in game_theme.tres under Button → Colors
# Assign the theme to the root Control of each scene
# All buttons inherit the color automatically
# To change it game-wide: edit one Theme resource
```

### Pitfall 6: Putting UI directly as children of 3D nodes without CanvasLayer

**WRONG:**
```
Node3D (GameScene)
  Player
  EnemySpawner
  Control (HUD)  ← directly in 3D scene, no CanvasLayer
    ProgressBar
```

**RIGHT:**
```
Node3D (GameScene)
  Player
  EnemySpawner
  CanvasLayer (HUD, layer=1)  ← isolated from 3D coordinate space
    Control
      ProgressBar
```

---

## Exercises

### Exercise 1: Responsive Layout (30–45 minutes)

Build a settings screen with at least four sections (Audio, Graphics, Controls, Gameplay). Requirements:
- Use `TabContainer` for the four sections
- Each tab uses `VBoxContainer` + `MarginContainer` for layout
- Audio tab: three `HSlider` controls (Master, Music, SFX) wired to `AudioServer` bus volumes
- Graphics tab: an `OptionButton` for resolution, a `CheckButton` for fullscreen
- The layout must look correct at 1280x720, 1920x1080, and 2560x1440 (test by resizing the window)
- Back button returns to the previous screen via `SceneManager` or a signal

Bonus: save settings to a config file using `ConfigFile` and load them on startup.

### Exercise 2: Dialogue System with RichTextLabel (45–60 minutes)

Build a dialogue box that:
- Uses `RichTextLabel` with BBCode for character name (bold, colored by character) and dialogue text
- Implements a typewriter effect — text appears letter by letter at a configurable speed
- Spacebar or A button skips the typewriter to reveal the full text immediately
- Next/continue button advances to the next dialogue entry
- Dialogue data comes from a `Resource` class (a `DialogueData` resource with `Array[DialogueLine]`)
- At least one dialogue line uses `[wave]` or a custom BBCode effect
- A clickable `[url=...]` link in one line opens a tooltip panel

### Exercise 3: HUD with Minimap (60–90 minutes)

Build a complete HUD for a top-down game:
- Health bar (ProgressBar, smooth tween on damage)
- Ammo counter (Label, flashes red when <= 20% ammo)
- Score display (Label, right-aligned, zero-padded to 6 digits)
- Minimap in the bottom-right corner using `SubViewportContainer` + `Camera3D` (orthographic, top-down)
- Player is shown as a rotating arrow dot on the minimap
- A "WANTED" star counter in the top-right (5 TextureRect stars that light up)
- Low-health vignette overlay (ColorRect that fades in as health drops below 30%)

The whole HUD must be a single `CanvasLayer` scene that can be instanced into any game scene.

### Exercise 4: Complete Scene Transition System (60–90 minutes)

Build a full scene transition system:
- `SceneManager` autoload with `change_scene(path, use_loading_screen)` method
- For fast loads (< 0.5s): a CrossFade overlay (black ColorRect, fade out → change scene → fade in)
- For slow loads (≥ 0.5s): a loading screen with ProgressBar, a rotating logo, and random loading tips
- Loading screen enforces a minimum display time of 0.5 seconds to avoid flashing
- Main menu calls `SceneManager.change_scene()` to go to the game
- Pause menu calls it to return to main menu
- Add a "simulate slow load" debug checkbox that artificially delays the load to test the loading screen

---

## Recommended Reading

| Resource | URL | What It Covers |
|----------|-----|----------------|
| Control node docs | [docs.godotengine.org/en/stable/classes/class_control.html](https://docs.godotengine.org/en/stable/classes/class_control.html) | Full Control API: anchors, size flags, focus, themes |
| Using Containers | [docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html) | Container types and size flags explained |
| Themes | [docs.godotengine.org/en/stable/tutorials/ui/gui_using_theme_editor.html](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_theme_editor.html) | Theme editor walkthrough |
| RichTextLabel | [docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html) | All BBCode tags, custom effects |
| ResourceLoader | [docs.godotengine.org/en/stable/classes/class_resourceloader.html](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html) | Async loading API reference |
| SubViewport | [docs.godotengine.org/en/stable/classes/class_subviewport.html](https://docs.godotengine.org/en/stable/classes/class_subviewport.html) | SubViewport and render modes |
| Multiple resolutions | [docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) | How to handle different screen sizes |
| Viewport and Canvas | [docs.godotengine.org/en/stable/tutorials/rendering/viewports.html](https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html) | CanvasLayer, Viewport, render architecture |

---

## Key Takeaways

- **Control nodes are NOT Node2D nodes.** They live in a separate coordinate system driven by anchors, offsets, and size flags. Never manually position a Control inside a Container.
- **Anchors define relative attachment to parent edges.** Anchor 0.0 = top/left edge, 1.0 = bottom/right edge. Use the anchor preset toolbar in the editor instead of setting numbers manually.
- **Containers handle layout automatically.** Set `size_flags_horizontal = SIZE_EXPAND_FILL` for elements that should stretch, and let the Container do the math.
- **One Theme, applied once at the top, styles everything underneath it.** Per-node overrides are for exceptions, not the rule. Design your Theme in the Theme editor, assign it to root UI nodes.
- **CanvasLayer isolates UI from the 3D world.** Layer 1 for HUD, layer 5 for pause menu, layer 10 for loading screen and transitions. Always set `process_mode = PROCESS_MODE_ALWAYS` on pause menus.
- **Always grab_focus when showing any menu.** Without it, gamepad users are stuck. Call `grab_focus()` after the open animation finishes (not before, or layout may not be settled).
- **Async loading with ResourceLoader keeps the main thread alive.** Never call `load_threaded_get()` immediately after `load_threaded_request()`. Poll `load_threaded_get_status()` in `_process()` until status is `THREAD_LOAD_LOADED`.
- **SubViewport renders any scene into a texture.** Use `SubViewportContainer` for the simplest setup. Control the camera's cull_mask to show only relevant geometry on the minimap.
- **RichTextLabel's `visible_ratio`** is all you need for typewriter effects. Tween it from 0.0 to 1.0. No need for timers or custom character-by-character logic.
- **Focus neighbors must form a closed graph.** If the last button's bottom neighbor isn't set, gamepad navigation falls off a cliff. Wire the last item back to the first to create a loop.

---

## What's Next

[Module 12: Shaders & Visual Effects](module-12-shaders-vfx.md) — Writing GLSL shaders in Godot's shader language, screen-space effects, particle systems, GPUParticles3D, and making your game look polished.
