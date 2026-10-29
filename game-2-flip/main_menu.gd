# main_menu.gd
# Main menu for FLIP: corridor wall, pixel-font title, SPIELEN / OPTIONEN with
# the lantern cursor (lantern_menu.gd), the best list, and the options overlay.
# The menu flips worlds on its own every few seconds, which drives the colour
# filter and the lantern colour — a preview of the mechanic. No exit button:
# the game runs in the browser.
extends Node2D

const FLIP_INTERVAL := 3.5   # seconds between automatic world flips

@onready var menu:        LanternMenu     = $CanvasLayer/Root/Menu
@onready var start_btn:   Button          = $CanvasLayer/Root/Menu/Buttons/StartButton
@onready var options_btn: Button          = $CanvasLayer/Root/Menu/Buttons/OptionsButton
@onready var options:     Control         = $CanvasLayer/Root/OptionsMenu
@onready var scoreboard:  ScoreboardPanel = $CanvasLayer/Root/ScoreboardPanel
@onready var title:       PixelText       = $CanvasLayer/Root/Title
@onready var tagline:     PixelText       = $CanvasLayer/Root/Tagline

var _flip_timer: float = 0.0


func _ready() -> void:
	WorldState.reset()
	WorldState.world_flipped.connect(_on_world_flipped)
	start_btn.pressed.connect(_on_start_pressed)
	options_btn.pressed.connect(_open_options)
	options.closed.connect(_close_options)
	_apply_world()
	scoreboard.refresh()
	menu.focus_first()


func _process(delta: float) -> void:
	_flip_timer += delta
	if _flip_timer >= FLIP_INTERVAL:
		_flip_timer = 0.0
		WorldState.flip()


func _on_world_flipped(_is_dark: bool) -> void:
	_apply_world()


func _apply_world() -> void:
	var fg := WorldState.get_fg_color()
	title.color   = fg
	tagline.color = fg.darkened(0.2)


# The options overlay replaces the menu content instead of sitting on top of it.
func _open_options() -> void:
	for n in [menu, scoreboard, title, tagline]:
		n.visible = false
	options.open()


func _close_options() -> void:
	for n in [menu, scoreboard, title, tagline]:
		n.visible = true
	menu.focus_button(options_btn)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
