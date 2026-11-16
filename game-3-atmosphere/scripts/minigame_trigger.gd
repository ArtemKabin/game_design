class_name MinigameTrigger
extends Interactable
## A station in the hub that opens a full-screen minigame (scenes/minigames/).
## `minutes` is what a run costs on the clock; it is charged when the player
## comes back, together with the rewards (GameState.apply_minigame_result).
## Shows a pulsing floor disc and a label in `accent`, the colour of the stat
## the minigame mainly helps (same colours as the HUD bars).
## `clutter` (optional) is hidden once the minigame was played today, so the
## room looks cleaned up.

@export_file("*.tscn") var minigame_scene := ""
@export var accent := Color(0.35, 0.6, 1.0)
@export var clutter: NodePath

var _disc_mat: StandardMaterial3D


func _ready() -> void:
	super()
	_build_marker()
	_update_clutter()
	GameState.progress_changed.connect(_update_clutter)


func minigame_id() -> String:
	return minigame_scene.get_file().get_basename()


func prompt() -> String:
	var parts: PackedStringArray = ["[E] " + title, "Minispiel", "%d min" % minutes]
	var best := int(GameState.minigame_best.get(minigame_id(), 0))
	if best > 0:
		parts.append("Rekord %d" % best)
	return "  ·  ".join(parts)


func interact() -> void:
	if minigame_scene == "" or not GameState.running:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var pos: Vector3 = player.global_position if player else global_position
	GameState.start_minigame(minigame_scene, pos, minutes)


func _build_marker() -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.6
	mesh.bottom_radius = radius * 0.6
	mesh.height = 0.01
	mesh.radial_segments = 32
	_disc_mat = StandardMaterial3D.new()
	_disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_disc_mat.albedo_color = Color(accent, 0.35)
	mesh.material = _disc_mat
	disc.mesh = mesh
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.position.y = 0.03
	add_child(disc)
	var tw := create_tween().set_loops()
	tw.tween_property(_disc_mat, "albedo_color:a", 0.65, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_disc_mat, "albedo_color:a", 0.2, 0.9).set_trans(Tween.TRANS_SINE)

	var label := Label3D.new()
	label.text = title
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.006
	label.font_size = 32
	label.outline_size = 10
	label.modulate = accent.lightened(0.35)
	label.position.y = 1.5
	add_child(label)


func _update_clutter() -> void:
	if clutter.is_empty():
		return
	var node := get_node_or_null(clutter) as Node3D
	if node:
		node.visible = not GameState.minigame_done_today(minigame_id())
