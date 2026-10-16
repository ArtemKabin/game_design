# flip_hud.gd
# Manages the on-screen HUD for the flip platformer.
# Shows: world state indicator, tutorial text, control hint.
extends Control

@onready var world_label:   Label = $TopBar/WorldLabel
@onready var flip_hint:     Label = $TopBar/FlipHint
@onready var status_label:  Label = $StatusLabel
@onready var bg_overlay:    ColorRect = $BGOverlay

var _status_tween: Tween = null


func _ready() -> void:
	WorldState.world_flipped.connect(_on_world_flipped)
	_refresh_world_label()
	bg_overlay.color = WorldState.get_bg_color()


func _on_world_flipped(is_dark: bool) -> void:
	_refresh_world_label()
	# Animated background flash.
	var target_col: Color = WorldState.get_bg_color()
	var flash_col:  Color = WorldState.get_fg_color()
	flash_col.a = 0.25
	var tween := create_tween()
	tween.tween_property(bg_overlay, "color", flash_col, 0.06)
	tween.tween_property(bg_overlay, "color", target_col, 0.28)


func _refresh_world_label() -> void:
	if WorldState.is_dark:
		world_label.text = "◉ SCHWARZE WELT"
		world_label.modulate = Color(0.95, 0.95, 0.95)
		flip_hint.modulate   = Color(0.8, 0.8, 0.8)
	else:
		world_label.text = "○ WEISZE WELT"
		world_label.modulate = Color(0.12, 0.12, 0.12)
		flip_hint.modulate   = Color(0.3, 0.3, 0.3)


## Show a message in the status area (fades out automatically).
func show_status(text: String, duration: float = 3.5) -> void:
	if _status_tween and _status_tween.is_running():
		_status_tween.kill()
	status_label.text = text
	status_label.modulate.a = 1.0
	_status_tween = create_tween()
	_status_tween.tween_interval(duration)
	_status_tween.tween_property(status_label, "modulate:a", 0.0, 0.8)
