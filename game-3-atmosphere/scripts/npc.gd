class_name Npc
extends Interactable
## A neutral person: a capsule like the player (0.6 × 1.75 m, feet at y = 0)
## in its own colour from data/encounters.json. Walks either on the footway
## graph of an NpcSpawner (outside) or back and forth along `patrol`
## (points in the parent's space, e.g. the roommate in the dorm).
## Pressing E nearby or bumping into it starts an encounter (Encounters
## autoload). A yellow "!" above it means: the next story beat waits here.
## It stops when the player stands in its way and turns around if that
## takes too long; cars stop for it (group "pedestrians").

@export var npc_id := ""
@export var patrol := PackedVector3Array()
@export var walk_speed := 1.3
## Pause at a waypoint (random in this range); patrol ends pause longer.
@export var idle_time := Vector2(0.5, 3.0)

const BUMP_DISTANCE := 0.75
const BUMP_COOLDOWN := 8.0
const NAME_DISTANCE := 7.0
const C_STORY := Color(0.98, 0.8, 0.25)

var _spawner = null   ## NpcSpawner (graph mode) or null (patrol mode)
var _node := Vector2.ZERO
var _prev := Vector2.ZERO
var _patrol_global: Array[Vector3] = []
var _patrol_i := 0
var _patrol_step := 1
var _target := Vector3.ZERO
var _side := 0.5            ## keeps right on footways, so people pass each other
var _idle := 0.0
var _blocked := 0.0
var _cooldown := 0.0
var _name_label: Label3D
var _marker: Label3D


func _ready() -> void:
	var info: Dictionary = Encounters.npc_info(npc_id)
	title = "Mit %s reden" % info.get("name", npc_id)
	minutes = 0
	radius = 1.4
	super()
	add_to_group("pedestrians")
	_build(info)
	_side = randf_range(0.35, 0.75)
	_idle = randf_range(0.0, 2.0)
	if _spawner == null and patrol.size() > 0:
		var parent := get_parent() as Node3D
		for p in patrol:
			_patrol_global.append(parent.to_global(p) if parent else p)
		global_position = _patrol_global[0]
		_patrol_i = 0
	_target = global_position


## Graph mode: called by NpcSpawner before add_child.
func start_on_graph(spawner, node: Vector2) -> void:
	_spawner = spawner
	_node = node
	_prev = node
	position = Vector3(node.x, 0.0, node.y)


func prompt() -> String:
	var s := "[E] " + title
	if Encounters.story_waiting_for(npc_id):
		s += "  ·  ★ Story"
	return s


func interact() -> void:
	_cooldown = BUMP_COOLDOWN
	Encounters.meet(npc_id)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	var to_player := Vector3.INF
	if player:
		to_player = player.global_position - global_position
		to_player.y = 0.0
	_name_label.visible = to_player.length() < NAME_DISTANCE
	_marker.visible = Encounters.story_waiting_for(npc_id)
	if _marker.visible:
		_marker.position.y = 2.45 + 0.08 * sin(Time.get_ticks_msec() * 0.005)

	if Encounters.is_open() or not GameState.running:
		if Encounters.is_open() and to_player.length() < 3.0:
			_face(to_player)
		return
	# Bumping into the NPC starts an encounter.
	if player and to_player.length() < BUMP_DISTANCE and _cooldown <= 0.0 \
			and player.velocity.length() > 0.5 and player.velocity.dot(-to_player) > 0.0:
		_cooldown = BUMP_COOLDOWN
		Encounters.meet(npc_id)
		return
	if _idle > 0.0:
		_idle -= delta
		return
	var to := _target - global_position
	to.y = 0.0
	if to.length() < 0.15:
		_arrive()
		return
	var dir := to.normalized()
	if player and _in_way(to_player, dir):
		_blocked += delta
		if _blocked > 1.5:
			_blocked = 0.0
			_turn_back()
		return
	_blocked = 0.0
	global_position += dir * minf(walk_speed * delta, to.length())
	_face(dir, delta)


func _in_way(to_player: Vector3, dir: Vector3) -> bool:
	var along := to_player.dot(dir)
	var lateral := (to_player - dir * along).length()
	return along > 0.0 and along < 1.4 and lateral < 0.8


func _face(dir: Vector3, delta := 1.0) -> void:
	if dir.length() < 0.01:
		return
	var yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(10.0 * delta, 0.0, 1.0))


func _arrive() -> void:
	if _spawner:
		if randf() < 0.3:
			_idle = randf_range(idle_time.x, idle_time.y)
		var next: Vector2 = _spawner.next_node(_node, _prev)
		_prev = _node
		_node = next
		_set_graph_target()
	elif _patrol_global.size() > 1:
		var at_end := _patrol_i + _patrol_step < 0 or _patrol_i + _patrol_step >= _patrol_global.size()
		if at_end:
			_patrol_step = -_patrol_step
			_idle = randf_range(idle_time.x, idle_time.y) * 2.5
		_patrol_i += _patrol_step
		_target = _patrol_global[_patrol_i]


func _turn_back() -> void:
	if _spawner:
		var t := _node
		_node = _prev
		_prev = t
		_set_graph_target()
	elif _patrol_global.size() > 1:
		_patrol_step = -_patrol_step
		_patrol_i = clampi(_patrol_i + _patrol_step, 0, _patrol_global.size() - 1)
		_target = _patrol_global[_patrol_i]


## Target = next graph node, shifted to the right of the walking direction.
func _set_graph_target() -> void:
	var p := Vector3(_node.x, 0.0, _node.y)
	var d := p - Vector3(_prev.x, 0.0, _prev.y)
	if d.length() > 0.01:
		d = d.normalized()
		p += Vector3(-d.z, 0.0, d.x) * _side
	_target = p


func _build(info: Dictionary) -> void:
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	add_child(body)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.875
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.3
	cm.height = 1.75
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Encounters.npc_color(npc_id)
	cm.material = mat
	mesh.mesh = cm
	mesh.position.y = 0.875
	body.add_child(mesh)
	# Small "nose" so you can see where it looks.
	var nose := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(0.18, 0.08, 0.12)
	nb.material = mat
	nose.mesh = nb
	nose.position = Vector3(0.0, 1.45, -0.3)
	body.add_child(nose)

	_name_label = Label3D.new()
	_name_label.text = info.get("name", npc_id)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.pixel_size = 0.006
	_name_label.font_size = 28
	_name_label.outline_size = 8
	_name_label.position.y = 2.1
	_name_label.no_depth_test = true
	_name_label.render_priority = 10
	_name_label.outline_render_priority = 9
	add_child(_name_label)
	_marker = Label3D.new()
	_marker.text = "!"
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.pixel_size = 0.01
	_marker.font_size = 48
	_marker.outline_size = 12
	_marker.modulate = C_STORY
	_marker.position.y = 2.45
	_marker.no_depth_test = true
	_marker.render_priority = 10
	_marker.outline_render_priority = 9
	add_child(_marker)
