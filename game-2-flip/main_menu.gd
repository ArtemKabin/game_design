# main_menu.gd
# Main menu for FLIP. Pressing Start goes straight into the endless game.
extends Node2D

# UI lives on a CanvasLayer with a full-screen Control root (see main_menu.tscn),
# so it stays centred at any window size.
@onready var start_btn: Button    = $CanvasLayer/Root/Center/Panel/VBox/StartButton
@onready var exit_btn:  Button    = $CanvasLayer/Root/Center/Panel/VBox/ExitButton
@onready var bg:        ColorRect = $CanvasLayer/Root/BG
@onready var title_lbl: Label     = $CanvasLayer/Root/BGLabel

var _flip_timer: float = 0.0
const FLIP_INTERVAL := 3.5  # seconds between automatic world flips in the menu


func _ready() -> void:
	WorldState.reset()
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_colors()
	start_btn.grab_focus()


func _process(delta: float) -> void:
	_flip_timer += delta
	if _flip_timer >= FLIP_INTERVAL:
		_flip_timer = 0.0
		WorldState.flip()


func _on_world_flipped(_is_dark: bool) -> void:
	_apply_colors()


func _apply_colors() -> void:
	var tween := create_tween()
	tween.tween_property(bg, "color", WorldState.get_bg_color(), 0.4)
	title_lbl.modulate = Color(WorldState.get_fg_color().r,
		WorldState.get_fg_color().g,
		WorldState.get_fg_color().b, 0.07)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
