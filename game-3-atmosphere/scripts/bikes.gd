extends Node3D
## Cyclists on the long cycleway that crosses the whole map diagonally (the
## red line, `route_roads` = indices into "roads" of data/hka_site.json,
## default 133 + 5). They ride on the right in both directions, enter at one
## map edge and leave at the other. Pooled (`pool_size`): nothing is created
## or freed while playing. Bike model: scenes/props/bike.tscn (without its
## collision) plus a rider. Riders keep their distance and brake for people
## on foot (player, NPCs, campus crowd).

@export_file("*.json") var data_path := "res://data/hka_site.json"
@export var route_roads := PackedInt32Array([133, 5])
@export var pool_size := 14
## Seconds between two new cyclists (random in this range).
@export var spawn_interval := Vector2(2.0, 5.0)
## m/s (4–6.5 = 15–23 km/h)
@export var speed := Vector2(4.0, 6.5)

const BIKE := preload("res://scenes/props/bike.tscn")
const LANE_OFFSET := 0.7   ## the cycleway is 3 m wide
const MIN_GAP := 3.5
const WHEEL_RADIUS := 0.33
const RIDER_COLORS := [Color(0.8, 0.35, 0.3), Color(0.35, 0.55, 0.4), Color(0.85, 0.75, 0.35),
	Color(0.55, 0.45, 0.7), Color(0.3, 0.3, 0.32), Color(0.9, 0.9, 0.88), Color(0.7, 0.5, 0.35)]


class Rider:
	var node: Node3D
	var wheels: Array[Node3D] = []
	var shirt: StandardMaterial3D
	var lane := 0
	var s := 0.0
	var speed := 0.0
	var cruise := 5.0
	var active := false


var _lanes: Array[PolyPath] = []
var _riders: Array[Rider] = []
var _spawn_timer := 0.5


func _ready() -> void:
	var d := SitePaths.load_site(data_path)
	if d.is_empty():
		return
	var line := SitePaths.chain(d["roads"], route_roads)
	if line.size() < 2:
		push_warning("Bikes: route_roads do not form a way.")
		return
	_lanes = [PolyPath.new(PolyPath.offset(line, LANE_OFFSET)),
		PolyPath.new(PolyPath.offset(PolyPath.reversed(line), LANE_OFFSET))]
	for i in pool_size:
		_riders.append(_make_rider())
	# Some already on their way when the scene loads.
	for i in int(pool_size / 2.0):
		var lane := i % 2
		_spawn(lane, randf_range(0.05, 0.95) * _lanes[lane].length)
	print("Bikes: cycleway %.0f m" % _lanes[0].length)


func _physics_process(delta: float) -> void:
	if _lanes.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(spawn_interval.x, spawn_interval.y)
		_spawn(randi() % 2, 0.0)
	var peds := SitePaths.pedestrian_positions(get_tree())
	for r in _riders:
		if not r.active:
			continue
		var lane := _lanes[r.lane]
		var target := r.cruise
		var gap := _gap_ahead(r)
		if gap < INF:
			target = minf(target, maxf(0.0, (gap - MIN_GAP) * 1.5))
		var ped := SitePaths.nearest_ahead(r.node.transform, peds, 1.0, 0.9)
		if ped < 7.0:
			target = minf(target, maxf(0.0, (ped - 1.6) * 1.2))
		r.speed = move_toward(r.speed, target, (2.0 if target > r.speed else 6.0) * delta)
		r.s += r.speed * delta
		if r.s >= lane.length:
			_despawn(r)
			continue
		_place(r, lane)
		for w in r.wheels:
			w.rotate_object_local(Vector3.UP, -r.speed / WHEEL_RADIUS * delta)


func _gap_ahead(r: Rider) -> float:
	var best := INF
	for o in _riders:
		if o == r or not o.active or o.lane != r.lane:
			continue
		var d := o.s - r.s
		if d > 0.0 and d < best:
			best = d
	return best


func _spawn(lane: int, s: float) -> void:
	var r: Rider = null
	for x in _riders:
		if not x.active:
			r = x
			break
	if r == null:
		return
	for o in _riders:
		if o.active and o.lane == lane and absf(o.s - s) < MIN_GAP * 2.0:
			return
	r.lane = lane
	r.s = s
	r.cruise = randf_range(speed.x, speed.y)
	r.speed = r.cruise
	r.active = true
	r.shirt.albedo_color = RIDER_COLORS.pick_random()
	r.node.visible = true
	_place(r, _lanes[lane])


func _despawn(r: Rider) -> void:
	r.active = false
	r.node.visible = false
	r.node.position = Vector3(0, -50, 0)


func _place(r: Rider, lane: PolyPath) -> void:
	var p := lane.point_at(r.s)
	var dir := lane.dir_at(r.s, 1.5)
	r.node.transform = Transform3D(Basis.looking_at(Vector3(dir.x, 0.0, dir.y), Vector3.UP), Vector3(p.x, 0.0, p.y))


func _make_rider() -> Rider:
	var r := Rider.new()
	var bike := BIKE.instantiate() as Node3D
	var col := bike.get_node_or_null("Collision") as CollisionShape3D
	if col:
		col.disabled = true
	bike.visible = false
	bike.position = Vector3(0, -50, 0)
	add_child(bike)
	r.node = bike
	for n in ["WheelFront", "WheelBack"]:
		var w := bike.get_node_or_null(n) as Node3D
		if w:
			r.wheels.append(w)
	# Rider: body leaning forward over the bar, head, backpack.
	r.shirt = StandardMaterial3D.new()
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.22
	cm.height = 0.95
	cm.material = r.shirt
	body.mesh = cm
	body.position = Vector3(0, 1.35, 0.12)
	body.rotation.x = -0.35
	bike.add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.13
	hm.height = 0.26
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.85, 0.7, 0.58)
	hm.material = skin
	head.mesh = hm
	head.position = Vector3(0, 1.88, -0.08)
	bike.add_child(head)
	var legs := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.3, 0.55, 0.2)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.2, 0.22, 0.28)
	lm.material = dark
	legs.mesh = lm
	legs.position = Vector3(0, 0.75, 0.05)
	bike.add_child(legs)
	var pack := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.32, 0.38, 0.16)
	pm.material = dark
	pack.mesh = pm
	pack.position = Vector3(0, 1.45, 0.38)
	pack.rotation.x = -0.35
	bike.add_child(pack)
	return r
