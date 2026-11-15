extends Node3D
## One dorm room, 3.0 × 5.5 m inside, entrance in the middle of the south wall.
## A locked room gets a roof and a closed door, so the player can neither look
## nor walk in. Set `locked = false` to make a room enterable later.
## A locked room is one occluder for RoomView: when it stands in front of the
## active zone, walls and door drop to stubs and the roof to a low dark slab.

@export var locked := false

const ROOF_COLOR := Color(0.42, 0.4, 0.38)
const DOOR_COLOR := Color(0.45, 0.33, 0.22)
const ROOF_FULL_SIZE := Vector3(3.4, 0.1, 5.9)
const ROOF_CUT_SIZE := Vector3(3.2, 0.05, 5.7)
const OUTER := Vector3(3.4, 2.6, 5.9)

var _roof: Block
var _door: Block


func _ready() -> void:
	if not locked:
		return
	$Actions.queue_free()
	$Furniture.queue_free()
	$Zones.queue_free()
	for wall in $Walls.get_children():
		RoomView.unregister_occluder(wall)
	_roof = _add_block("Roof", ROOF_FULL_SIZE, Vector3(0, 2.6, 0), ROOF_COLOR)
	_door = _add_block("Door", Vector3(0.9, 2.1, 0.05), Vector3(0, 0, 2.85), DOOR_COLOR)
	RoomView.register_occluder(self)


func _exit_tree() -> void:
	if locked:
		RoomView.unregister_occluder(self)


func occluder_rect() -> Rect2:
	var box := global_transform * AABB(Vector3(-OUTER.x / 2.0, 0.0, -OUTER.z / 2.0), OUTER)
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


func set_cut(value: bool) -> void:
	for wall in $Walls.get_children():
		(wall as Block).set_cut(value)
	_door.set_cut(value)
	# Cut: slab just below the wall stubs, so outlines and the door stay visible.
	_roof.size = ROOF_CUT_SIZE if value else ROOF_FULL_SIZE
	_roof.position.y = Block.CUT_HEIGHT - 0.07 if value else 2.6


func _add_block(block_name: String, block_size: Vector3, pos: Vector3, block_color: Color) -> Block:
	var b := Block.new()
	b.name = block_name
	b.size = block_size
	b.color = block_color
	b.position = pos
	add_child(b)
	return b
