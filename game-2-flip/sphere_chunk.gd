# sphere_chunk.gd
# Hazard chunk with a continuous floor (ground in BOTH worlds) and spheres that
# each exist in one world only. The player passes a sphere by being in the
# other world. Spheres may patrol left/right at a constant speed.
#
# `spheres` is set by game.gd before add_child. One entry per sphere:
#   [x, in_dark_world, patrol_distance, patrol_speed]
#   x               chunk-local x of the sphere's START position
#   in_dark_world   false = exists in WHITE world, true = exists in BLACK world
#   patrol_distance px to move right (negative = left) before turning; 0 = still
#   patrol_speed    px/s
class_name SphereChunk
extends Chunk

signal sphere_hit(body: Node)

const FLOOR_HEIGHT := 32.0
const SPHERE_Y     := -22.0   # centre at player height, bottom on the floor

const SPHERE_SCENE  := preload("res://sphere.tscn")
const PLATFORM_DRAW := preload("res://platform_draw.gd")

@export var spheres: Array = []


func _ready() -> void:
	_build()


func _build() -> void:
	# Continuous floor, drawn with the normal platform look.
	var floor_body := StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask  = 0
	floor_body.position = Vector2(width * 0.5, FLOOR_HEIGHT * 0.5)
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(width, FLOOR_HEIGHT)
	shape.shape = rect
	floor_body.add_child(shape)
	var draw := Node2D.new()
	draw.set_script(PLATFORM_DRAW)
	draw.width  = width
	draw.height = FLOOR_HEIGHT
	floor_body.add_child(draw)
	add_child(floor_body)

	for spec in spheres:
		var s := SPHERE_SCENE.instantiate()
		s.position        = Vector2(float(spec[0]), SPHERE_Y)
		s.in_dark_world   = bool(spec[1])
		s.patrol_distance = float(spec[2])
		s.patrol_speed    = float(spec[3])
		add_child(s)
		(s.get_node("KillZone") as Area2D).body_entered.connect(_on_sphere_body_entered)


func _on_sphere_body_entered(body: Node) -> void:
	sphere_hit.emit(body)
