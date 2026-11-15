@tool
class_name Block
extends StaticBody3D
## Greybox building block for rebuilding the campus.
## Units are metres. The origin is the BOTTOM centre, so a block placed at
## y = 0 stands on the floor. Mesh and collision are generated and not saved.

@export var size := Vector3(1, 1, 1):
	set(v):
		size = v
		_rebuild()
@export var color := Color(0.8, 0.8, 0.8):
	set(v):
		color = v
		_rebuild()
@export var collides := true:
	set(v):
		collides = v
		_rebuild()
## Walls that can stand between camera and player. They are full height, but
## RoomView cuts them down to CUT_HEIGHT while the player is in a room right
## behind them. Collision always stays full height.
@export var cutaway := false

const CUT_HEIGHT := 0.3

var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _cut := false


func _ready() -> void:
	_rebuild()
	if cutaway and not Engine.is_editor_hint():
		var view := get_node_or_null("/root/RoomView")
		if view:
			view.register_occluder(self)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var view := get_node_or_null("/root/RoomView")
	if view:
		view.unregister_occluder(self)


## Floor rectangle in world space (x, z) for RoomView.
func occluder_rect() -> Rect2:
	var box := global_transform * AABB(Vector3(-size.x / 2.0, 0.0, -size.z / 2.0), size)
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


func set_cut(value: bool) -> void:
	if value != _cut:
		_cut = value
		_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_shape = CollisionShape3D.new()
		add_child(_mesh)
		add_child(_shape)
	var visible_h := size.y
	if _cut:
		visible_h = clampf(CUT_HEIGHT - position.y, 0.0, size.y)
	_mesh.visible = visible_h > 0.001
	var box := BoxMesh.new()
	box.size = Vector3(size.x, maxf(visible_h, 0.001), size.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:  # glass etc.
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = mat
	_mesh.mesh = box
	_mesh.position.y = box.size.y / 2.0
	var shape := BoxShape3D.new()
	shape.size = size
	_shape.shape = shape
	_shape.position.y = size.y / 2.0
	_shape.disabled = not collides
