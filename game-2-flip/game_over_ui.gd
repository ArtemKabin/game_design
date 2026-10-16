extends Control

# Shared game-over panel. Instance res://game_over_ui.tscn under a CanvasLayer.
# show_game_over(title, subtitle) shows it and focuses the restart button;
# Enter/Space/E/F or R emit restart_requested. What "restart" means is the level's job.

signal restart_requested

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
@onready var restart_button: Button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(func() -> void: restart_requested.emit())


func show_game_over(title: String, subtitle: String) -> void:
	title_label.text = title
	subtitle_label.text = subtitle
	visible = true
	restart_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart_requested.emit()
