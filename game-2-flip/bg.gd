# bg.gd
# Full-screen background ColorRect that smoothly transitions color on world flip.
# Place this on a CanvasLayer with layer = -1 so it renders behind everything.
extends ColorRect


func _ready() -> void:
	WorldState.world_flipped.connect(_on_world_flipped)
	color = WorldState.get_bg_color()


func _on_world_flipped(_is_dark: bool) -> void:
	var tween := create_tween()
	tween.tween_property(self, "color", WorldState.get_bg_color(), 0.35) \
		.set_trans(Tween.TRANS_SINE)
