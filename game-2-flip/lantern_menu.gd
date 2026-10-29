# lantern_menu.gd
# A vertical keyboard menu in the pixel font with a small lantern as the focus
# cursor. Expected children (see main_menu.tscn for an example):
#   Buttons (VBoxContainer) – invisible Buttons, each with a child "Label" (PixelText)
#   Cursor  (TextureRect)   – 32x48, gets the red/blue lantern per world
# The owning scene connects the buttons' `pressed` signals. Enter/Space press
# the focused button, up/down move the focus (Godot's default UI navigation).
class_name LanternMenu
extends Control

const CURSOR_RED_PATH  := "res://assets/env/lantern_red.png"
const CURSOR_BLUE_PATH := "res://assets/env/lantern_blue.png"
const CURSOR_GAP := 16.0

@onready var buttons_box: Container   = $Buttons
@onready var cursor:      TextureRect = $Cursor

var _buttons: Array[Button] = []
var _focused: Button = null
var _bob: float = 0.0
var _tex_red:  Texture2D = null
var _tex_blue: Texture2D = null


func _ready() -> void:
	_tex_red  = load(CURSOR_RED_PATH) as Texture2D
	_tex_blue = load(CURSOR_BLUE_PATH) as Texture2D
	var empty := StyleBoxEmpty.new()
	for child in buttons_box.get_children():
		if child is Button:
			var btn := child as Button
			_buttons.append(btn)
			btn.focus_entered.connect(_on_button_focused.bind(btn))
			for style in ["normal", "hover", "pressed", "focus", "disabled"]:
				btn.add_theme_stylebox_override(style, empty)
	# Keep keyboard focus inside this menu (wrap top/bottom, no left/right):
	# otherwise Godot's focus search can wander into another menu's buttons,
	# e.g. from the options overlay back into the main menu behind it.
	var n := _buttons.size()
	for i in range(n):
		var btn := _buttons[i]
		var prev := _buttons[(i - 1 + n) % n]
		var next := _buttons[(i + 1) % n]
		btn.focus_neighbor_top    = btn.get_path_to(prev)
		btn.focus_neighbor_bottom = btn.get_path_to(next)
		btn.focus_previous        = btn.get_path_to(prev)
		btn.focus_next            = btn.get_path_to(next)
		btn.focus_neighbor_left   = btn.get_path_to(btn)
		btn.focus_neighbor_right  = btn.get_path_to(btn)
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_world()


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _focused == null:
		return
	_bob += delta * 3.0
	cursor.global_position = _cursor_pos(_focused) + Vector2(0.0, roundf(2.0 * sin(_bob)))


## Focus the first (or given) entry and show the cursor there.
func focus_first() -> void:
	if not _buttons.is_empty():
		focus_button(_buttons[0])


func focus_button(btn: Button) -> void:
	btn.grab_focus()
	_on_button_focused(btn)


func buttons() -> Array[Button]:
	return _buttons


func focused_button() -> Button:
	return _focused


func label_of(btn: Button) -> PixelText:
	return btn.get_node("Label") as PixelText


func _cursor_pos(btn: Button) -> Vector2:
	var label := label_of(btn)
	var text_left := btn.global_position.x + (btn.size.x - label.text_width()) * 0.5
	return Vector2(text_left - cursor.size.x - CURSOR_GAP,
		btn.global_position.y + (btn.size.y - cursor.size.y) * 0.5)


func _on_button_focused(btn: Button) -> void:
	_focused = btn


func _on_world_flipped(_is_dark: bool) -> void:
	_apply_world()


func _apply_world() -> void:
	cursor.texture = _tex_blue if WorldState.is_dark else _tex_red
	var fg := WorldState.get_fg_color()
	for btn in _buttons:
		label_of(btn).color = fg
