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
## Big label and beacon that stay readable in the map view (uni stations).
@export var map_label := false
## Side of the map label: -1 left of the station, 1 right, 0 centered
## (stations close to each other must not overlap in the map view).
@export_range(-1, 1) var map_label_side := 0

var _map_nodes: Array[Node3D] = []
var _near_label: Label3D

var _disc_mat: StandardMaterial3D


func _ready() -> void:
	super()
	_build_marker()
	if map_label:
		_build_map_label()
	_update_clutter()
	GameState.progress_changed.connect(_update_clutter)


func minigame_id() -> String:
	return minigame_scene.get_file().get_basename()


func prompt() -> String:
	var parts: PackedStringArray = ["[E] " + title, "Minispiel", "%d min" % minutes]
	var best := int(GameState.minigame_best.get(minigame_id(), 0))
	if best > 0:
		parts.append("Rekord %d" % best)
	if minigame_id() == "submission":
		if not GameState.submission_open():
			var s := GameState.submission_info()
			return "%s  ·  erst %s %s–%s" % [title, GameState.DAY_NAMES[int(s["day"])], s["start"], s["end"]]
		parts.append("Schwierigkeit: " + GameState.difficulty_name())
	elif not GameState.slot_now(minigame_id()).is_empty():
		parts.append("laut Stundenplan JETZT: Lernpunkte ×%.1f" % GameState.LECTURE_BONUS)
	return "  ·  ".join(parts)


func interact() -> void:
	if minigame_scene == "" or not GameState.is_free():
		return
	if minigame_id() == "submission" and not GameState.submission_open():
		var s := GameState.submission_info()
		GameState.message.emit("Abgabe erst am %s, %s–%s Uhr." % [GameState.DAY_NAMES[int(s["day"])], s["start"], s["end"]])
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
	# Same size on screen indoors (camera ~11 m) and outdoors (~28 m).
	label.fixed_size = true
	label.pixel_size = 0.0007
	label.font_size = 32
	label.outline_size = 10
	label.modulate = accent.lightened(0.35)
	# Always drawn on top, so walls and canopies never hide it.
	label.no_depth_test = true
	label.render_priority = 10
	label.outline_render_priority = 9
	label.position.y = 2.0
	_apply_side(label)
	add_child(label)
	_near_label = label


func _build_map_label() -> void:
	var pillar := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.6
	mesh.bottom_radius = 0.6
	mesh.height = 30.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(accent, 0.45)
	mesh.material = mat
	pillar.mesh = mesh
	pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pillar.position.y = 15.0
	add_child(pillar)
	_map_nodes.append(pillar)
	var label := Label3D.new()
	label.text = title
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.pixel_size = 0.0008
	label.font_size = 32
	label.outline_size = 12
	label.no_depth_test = true
	label.render_priority = 20
	label.outline_render_priority = 19
	label.modulate = accent.lightened(0.3)
	label.position.y = 31.0
	_apply_side(label)
	label.offset.y = 24
	add_child(label)
	_map_nodes.append(label)
	_update_map_nodes()


## Neighbouring stations: label to the left (-1) or right (1) of the station.
func _apply_side(label: Label3D) -> void:
	if map_label_side < 0:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.offset = Vector2(-24, 0)
	elif map_label_side > 0:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.offset = Vector2(24, 0)


func _process(_delta: float) -> void:
	if not _map_nodes.is_empty():
		_update_map_nodes()


## Beacon and big label only in the map view (M / phone map).
func _update_map_nodes() -> void:
	var scene := get_tree().current_scene
	var rig := scene.get_node_or_null("CameraRig") if scene else null
	var on: bool = rig != null and rig.get("overview") == true
	for n in _map_nodes:
		n.visible = on
	# The small label would double the big one in the map view.
	if _near_label:
		_near_label.visible = not on


func _update_clutter() -> void:
	if clutter.is_empty():
		return
	var node := get_node_or_null(clutter) as Node3D
	if node:
		node.visible = not GameState.minigame_done_today(minigame_id())
