# flip_main_menu.gd
# Main menu for the Flip platformer.
extends Node2D

@onready var start_btn: Button = $Panel/VBox/StartButton
@onready var old_game_btn: Button = $Panel/VBox/OldGameButton
@onready var exit_btn: Button  = $Panel/VBox/ExitButton
@onready var bg: ColorRect = $BG
@onready var bg_label: Label = $BGLabel

var _pulse: float = 0.0


func _ready() -> void:
	WorldState.reset()
	WorldState.world_flipped.connect(_on_world_flipped)
	start_btn.grab_focus()
	_apply_colors()

	# Pulse the background subtly.
	var t: Tween = create_tween().set_loops()
	t.tween_callback(func(): WorldState.flip()).set_delay(4.0)


func _process(delta: float) -> void:
	_pulse += delta


func _on_world_flipped(_d: bool) -> void:
	_apply_colors()


func _apply_colors() -> void:
	bg.color = WorldState.get_bg_color()
	var fg: Color = WorldState.get_fg_color()
	bg_label.modulate = Color(fg.r, fg.g, fg.b, 0.06)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://flip_level_0.tscn")


func _on_old_game_pressed() -> void:
	GameManager.go_to_world()


func _on_exit_pressed() -> void:
	get_tree().quit()
