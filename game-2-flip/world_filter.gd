# world_filter.gd
# Full-screen colour grade that gives each world its mood (see world_state.gd):
#   RED world  → warm tint, full saturation (dark wood, reddish)
#   BLUE world → blue tint, mostly desaturated (grey with a blue cast)
# Everything drawn below this CanvasLayer is affected: corridor, floors,
# hazards, the player and the lanterns. The HUD sits on a higher layer.
extends CanvasLayer

const FADE_TIME := 0.35   # same as the background / fog colour tweens

@onready var rect: ColorRect = $Rect

var tint:       Color = Color.WHITE
var saturation: float = 1.0


func _ready() -> void:
	tint       = WorldState.get_tint()
	saturation = WorldState.get_saturation()
	_apply()
	WorldState.world_flipped.connect(_on_world_flipped)


func _process(_delta: float) -> void:
	_apply()


func _apply() -> void:
	rect.material.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	rect.material.set_shader_parameter("saturation", saturation)


func _on_world_flipped(_is_dark: bool) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "tint", WorldState.get_tint(), FADE_TIME).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "saturation", WorldState.get_saturation(), FADE_TIME).set_trans(Tween.TRANS_SINE)
