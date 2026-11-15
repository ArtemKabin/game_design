class_name Zone
extends Area3D
## A walkable room (interior only). While the player is inside, the zone is
## lit; otherwise a dark see-through shade covers it, so other rooms are harder
## to read. The shade is also an occluder: in front of the active zone it
## shrinks to the floor so it does not darken the room behind it.

## Interior size in metres, origin bottom centre (like Block).
@export var size := Vector3(3, 2.6, 3)

const SHADE_COLOR := Color(0.02, 0.02, 0.05, 0.6)

var _shade: MeshInstance3D
var _shade_mesh: BoxMesh
var _lit := false
var _cut := false


func _ready() -> void:
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	col.position.y = size.y / 2.0
	add_child(col)

	_shade_mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = SHADE_COLOR
	_shade_mesh.material = mat
	_shade = MeshInstance3D.new()
	_shade.mesh = _shade_mesh
	_shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shade)
	_update()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	RoomView.register_zone(self)
	RoomView.register_occluder(self)


func _exit_tree() -> void:
	RoomView.unregister_zone(self)
	RoomView.unregister_occluder(self)


func occluder_rect() -> Rect2:
	var box := global_transform * AABB(Vector3(-size.x / 2.0, 0.0, -size.z / 2.0), size)
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


func set_lit(value: bool) -> void:
	_lit = value
	_update()


func set_cut(value: bool) -> void:
	_cut = value
	_update()


func _update() -> void:
	if _shade == null:
		return
	_shade.visible = not _lit
	var h := 0.03 if _cut else size.y
	_shade_mesh.size = Vector3(size.x, h, size.z)
	_shade.position.y = 0.025 + h / 2.0


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		RoomView.enter(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		RoomView.exit(self)
