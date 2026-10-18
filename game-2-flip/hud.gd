# hud.gd
# On-screen HUD: world state indicator, score, status messages.
# BGOverlay is now a TRANSPARENT flash-only element (alpha=0 at rest).
# The actual background colour is handled by bg.gd on a lower CanvasLayer.
extends Control

@onready var world_label:  Label     = $TopBar/WorldLabel
@onready var score_label:  Label     = $TopBar/ScoreLabel
@onready var status_label: Label     = $StatusLabel
@onready var bg_overlay:   ColorRect = $BGOverlay

var _status_tween: Tween = null


func _ready() -> void:
	WorldState.world_flipped.connect(_on_world_flipped)
	bg_overlay.color = Color(0, 0, 0, 0)   # fully transparent at rest
	_refresh()


func _on_world_flipped(_is_dark: bool) -> void:
	_refresh()
	# Brief full-screen flash on flip, then fade out to transparent.
	var flash := WorldState.get_fg_color()
	flash.a = 0.18
	var tween := create_tween()
	tween.tween_property(bg_overlay, "color", flash,               0.06)
	tween.tween_property(bg_overlay, "color", Color(0, 0, 0, 0),  0.35)


func _refresh() -> void:
	if WorldState.is_dark:
		world_label.text              = "◉  SCHWARZE WELT"
		world_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		score_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	else:
		world_label.text              = "○  WEISZE WELT"
		world_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))
		score_label.add_theme_color_override("font_color", Color(0.22, 0.22, 0.22))


func set_score(score: int) -> void:
	score_label.text = "SCORE  %d" % score


## Show a message that fades out after `duration` seconds (0 = permanent).
func show_status(text: String, duration: float = 3.5) -> void:
	if _status_tween and _status_tween.is_running():
		_status_tween.kill()
	status_label.text       = text
	status_label.modulate.a = 1.0
	if duration > 0.0:
		_status_tween = create_tween()
		_status_tween.tween_interval(duration)
		_status_tween.tween_property(status_label, "modulate:a", 0.0, 0.6)
