extends Node3D
## Ambient traffic on the campus road north of the dorm (outside.tscn).
## The route is a chain of roads from data/hka_site.json (`route_roads`,
## indices into "roads", default: the 7 m road along the parking bays).
## Cars drive on the right lane in both directions, enter at one map edge and
## leave at the other. Some of them turn nose-first into a free bay of the
## parking strips beside the road, stay a while, back out and drive on.
## Free bays are found from the data: inside a "parking" area, not taken by
## a parked car (static MultiMesh cars from site.gd), no building, tree or
## other road there. Cars are pooled (`pool_size`), nothing is created or
## freed while playing. They stop for the player and keep their distance.
## Turn on `debug_spots` to see the bays.

@export_file("*.json") var data_path := "res://data/hka_site.json"
@export var route_roads := PackedInt32Array([164, 165, 48])
@export var pool_size := 14
## Seconds between two new cars (random in this range).
@export var spawn_interval := Vector2(3.0, 8.0)
@export_range(0.0, 1.0) var park_chance := 0.45
## Seconds a car stays parked (random in this range).
@export var park_time := Vector2(8.0, 25.0)
## m/s, 8.3 = 30 km/h
@export var cruise_speed := 8.3
@export var debug_spots := false

const LANE_OFFSET := 1.75   ## lane centre from the road centre (right-hand traffic)
const CAR_SIZE := Vector3(1.8, 1.4, 4.4)
const SPOT_PITCH := 2.8     ## bay width along the road
const MIN_BAY_DEPTH := 3.5
const END_MARGIN := 30.0    ## no parking this close to the map edge
const MIN_GAP := 7.5        ## centre to centre distance to the car ahead
const ACCEL := 3.0
const BRAKE := 8.0
const TURN_IN_BEFORE := 7.0 ## start of the turn into a bay, metres before it
const BACK_OUT_TO := 6.0    ## end of backing out, metres before the bay

enum State { IDLE, DRIVE, PARK_IN, PARKED, PARK_OUT }


## Polyline with arc-length lookups (lanes and manoeuvre curves).
class Path2:
	var pts: PackedVector2Array
	var cum := PackedFloat32Array()
	var length := 0.0

	func _init(points: PackedVector2Array) -> void:
		pts = points
		cum.append(0.0)
		for i in range(1, pts.size()):
			length += pts[i - 1].distance_to(pts[i])
			cum.append(length)

	func _seg(s: float) -> int:
		for i in range(1, cum.size()):
			if s <= cum[i]:
				return i
		return cum.size() - 1

	func point_at(s: float) -> Vector2:
		s = clampf(s, 0.0, length)
		var i := _seg(s)
		var seg := cum[i] - cum[i - 1]
		var f := 0.0 if seg < 0.0001 else (s - cum[i - 1]) / seg
		return pts[i - 1].lerp(pts[i], f)

	## Direction averaged over ±w metres, so bends turn smoothly.
	func dir_at(s: float, w := 2.5) -> Vector2:
		var d := point_at(s + w) - point_at(s - w)
		if d.length() < 0.001:
			var i := _seg(clampf(s, 0.0, length))
			d = pts[i] - pts[i - 1]
		return d.normalized()


class Car:
	var body: AnimatableBody3D
	var shape: CollisionShape3D
	var paint: StandardMaterial3D
	var tail: StandardMaterial3D
	var state := 0
	var lane := 0
	var s := 0.0          ## position along the lane (also while manoeuvring: where it blocks)
	var speed := 0.0
	var spot := {}
	var curve: Path2
	var m := 0.0          ## distance along the manoeuvre curve
	var wait := 0.0
	var in_lane := true   ## blocks cars behind it


var _lanes: Array[Path2] = []
var _spots: Array[Dictionary] = []
var _cars: Array[Car] = []
var _colors: Array[Color] = []
var _spawn_timer := 1.0


func _ready() -> void:
	var f := FileAccess.open(data_path, FileAccess.READ)
	if f == null:
		push_warning("Traffic: site data missing: " + data_path)
		return
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	var center := _route(d["roads"])
	if center.size() < 2:
		push_warning("Traffic: route_roads do not form a road.")
		return
	var back := center.duplicate()
	back.reverse()
	_lanes = [Path2.new(_offset(center, LANE_OFFSET)), Path2.new(_offset(back, LANE_OFFSET))]
	for c in d["cars"]:
		_colors.append(Color(c[3], c[4], c[5]))
	if _colors.is_empty():
		_colors.append(Color(0.6, 0.6, 0.62))
	_find_spots(Path2.new(center), d)
	for i in pool_size:
		_cars.append(_make_car())
	_warm_start()


func _physics_process(delta: float) -> void:
	if _lanes.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(spawn_interval.x, spawn_interval.y)
		_spawn(randi() % 2, 0.0)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	for car in _cars:
		match car.state:
			State.DRIVE:
				_drive(car, delta, player)
			State.PARK_IN:
				_park_in(car, delta, player)
			State.PARKED:
				car.wait -= delta
				if car.wait <= 0.0 and _can_back_out(car, player):
					_start_back_out(car)
			State.PARK_OUT:
				_back_out(car, delta, player)


# --- Behaviour ----------------------------------------------------------------

func _drive(car: Car, delta: float, player: Node3D) -> void:
	var lane := _lanes[car.lane]
	var target := cruise_speed
	var gap := _gap_ahead(car)
	if gap < INF:
		target = minf(target, maxf(0.0, (gap - MIN_GAP) * 1.2))
	var ahead := _player_ahead(car, player, 1.0)
	if ahead < 12.0:
		target = minf(target, maxf(0.0, (ahead - 4.0) * 1.0))
	if not car.spot.is_empty():
		var to_turn: float = car.spot["s"] - TURN_IN_BEFORE - car.s
		target = minf(target, 2.8 + maxf(to_turn, 0.0) * 0.45)
	var a := ACCEL if target > car.speed else BRAKE
	car.speed = move_toward(car.speed, target, a * delta)
	car.s += car.speed * delta
	_set_brake(car, target < car.speed - 0.5 or car.speed < 0.3)
	if not car.spot.is_empty() and car.s >= car.spot["s"] - TURN_IN_BEFORE:
		_start_park_in(car)
		return
	if car.s >= lane.length:
		_despawn(car)
		return
	_place(car, lane.point_at(car.s), lane.dir_at(car.s))


func _start_park_in(car: Car) -> void:
	var lane := _lanes[car.lane]
	var s0 := car.s
	var p0 := lane.point_at(s0)
	var d0 := lane.dir_at(s0)
	var c: Vector2 = car.spot["center"]
	var n: Vector2 = car.spot["n"]
	car.curve = Path2.new(_bezier(p0, p0 + d0 * 3.5, c - n * 3.2, c))
	car.m = 0.0
	car.state = State.PARK_IN


func _park_in(car: Car, delta: float, player: Node3D) -> void:
	var left := car.curve.length - car.m
	var v := clampf(left * 1.2, 0.6, maxf(car.speed, 2.8))
	if _player_ahead(car, player, 1.0) < 4.0:
		v = 0.0
	car.speed = v
	car.m = minf(car.m + v * delta, car.curve.length)
	var u := car.m / car.curve.length
	car.in_lane = u < 0.6
	car.s = car.spot["s"] - TURN_IN_BEFORE * (1.0 - u)
	_set_brake(car, true)
	_place(car, car.curve.point_at(car.m), car.curve.dir_at(car.m, 0.6))
	if car.m >= car.curve.length - 0.01:
		car.state = State.PARKED
		car.speed = 0.0
		car.in_lane = false
		car.wait = randf_range(park_time.x, park_time.y)
		_set_brake(car, false)


func _can_back_out(car: Car, player: Node3D) -> bool:
	if _player_ahead(car, player, -1.0) < 6.0:
		return false
	var spot_s: float = car.spot["s"]
	for o in _cars:
		if o == car or o.lane != car.lane or o.state != State.DRIVE:
			continue
		if o.s > spot_s - 30.0 and o.s < spot_s + 3.0:
			return false
	return true


func _start_back_out(car: Car) -> void:
	var lane := _lanes[car.lane]
	var spot_s: float = car.spot["s"]
	var e := lane.point_at(spot_s - BACK_OUT_TO)
	var de := lane.dir_at(spot_s - BACK_OUT_TO)
	var c: Vector2 = car.spot["center"]
	var n: Vector2 = car.spot["n"]
	car.curve = Path2.new(_bezier(c, c - n * 3.0, e + de * 3.0, e))
	car.m = 0.0
	car.state = State.PARK_OUT


func _back_out(car: Car, delta: float, player: Node3D) -> void:
	var left := car.curve.length - car.m
	var v := clampf(minf(car.m + 0.4, left) * 1.0, 0.4, 2.0)
	if _player_ahead(car, player, -1.0) < 4.0:
		v = 0.0
	car.m = minf(car.m + v * delta, car.curve.length)
	var u := car.m / car.curve.length
	car.in_lane = u > 0.4
	car.s = car.spot["s"] - BACK_OUT_TO * u
	_set_brake(car, true)
	# Reversing: the nose points against the direction of motion.
	_place(car, car.curve.point_at(car.m), -car.curve.dir_at(car.m, 0.6))
	if car.m >= car.curve.length - 0.01:
		car.spot["taken"] = false
		car.spot = {}
		car.state = State.DRIVE
		car.in_lane = true
		car.speed = 0.0


## Distance (centre to centre) to the next car in the same lane, INF if none.
func _gap_ahead(car: Car) -> float:
	var best := INF
	for o in _cars:
		if o == car or o.lane != car.lane or o.state == State.IDLE or not o.in_lane:
			continue
		var d := o.s - car.s
		if d > 0.0 and d < best:
			best = d
	return best


## Distance to the player in front of (dir = 1) or behind (dir = -1) the car,
## INF if the player is not in its way.
func _player_ahead(car: Car, player: Node3D, dir: float) -> float:
	if player == null:
		return INF
	var fwd := -car.body.global_transform.basis.z * dir
	var rel := player.global_position - car.body.global_position
	rel.y = 0.0
	var along := rel.dot(fwd)
	var side := absf(rel.dot(car.body.global_transform.basis.x))
	if along > 0.0 and side < 1.9:
		return along
	return INF


# --- Pool -------------------------------------------------------------------

func _spawn(lane: int, s: float, park := true) -> Car:
	var car: Car = null
	for c in _cars:
		if c.state == State.IDLE:
			car = c
			break
	if car == null:
		return null
	for o in _cars:
		if o.state != State.IDLE and o.lane == lane and o.in_lane and absf(o.s - s) < MIN_GAP * 1.5:
			return null
	car.lane = lane
	car.s = s
	car.speed = cruise_speed * 0.8
	car.state = State.DRIVE
	car.in_lane = true
	car.spot = {}
	if park and randf() < park_chance:
		car.spot = _free_spot(lane, s + 25.0)
		if not car.spot.is_empty():
			car.spot["taken"] = true
	car.paint.albedo_color = _colors.pick_random()
	car.body.visible = true
	car.shape.disabled = false
	var path := _lanes[lane]
	_place(car, path.point_at(s), path.dir_at(s))
	return car


func _despawn(car: Car) -> void:
	if not car.spot.is_empty():
		car.spot["taken"] = false
	car.spot = {}
	car.state = State.IDLE
	car.body.visible = false
	car.shape.disabled = true
	car.body.position = Vector3(0, -50, 0)


func _free_spot(lane: int, after: float) -> Dictionary:
	var options: Array[Dictionary] = []
	for sp in _spots:
		if sp["lane"] == lane and not sp["taken"] and sp["s"] > after:
			options.append(sp)
	return options.pick_random() if not options.is_empty() else {}


## Cars already on the road and a few parked ones when the scene loads.
func _warm_start() -> void:
	for lane in 2:
		var length := _lanes[lane].length
		for i in 3:
			_spawn(lane, randf_range(0.1, 0.9) * length, false)
	for i in 3:
		var lane := randi() % 2
		var sp := _free_spot(lane, 0.0)
		var car := _spawn(lane, 0.0, false)
		if car == null or sp.is_empty():
			if car:
				_despawn(car)
			continue
		sp["taken"] = true
		car.spot = sp
		car.state = State.PARKED
		car.in_lane = false
		car.speed = 0.0
		car.s = sp["s"]
		car.wait = randf_range(2.0, park_time.y)
		_place(car, sp["center"], sp["n"])


func _make_car() -> Car:
	var car := Car.new()
	var body := AnimatableBody3D.new()
	body.name = "Car"
	body.sync_to_physics = false
	body.visible = false
	body.position = Vector3(0, -50, 0)
	add_child(body)
	car.body = body
	car.shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = CAR_SIZE
	car.shape.shape = box
	car.shape.position.y = CAR_SIZE.y / 2.0
	car.shape.disabled = true
	body.add_child(car.shape)
	car.paint = StandardMaterial3D.new()
	car.paint.roughness = 0.6
	# Same proportions as the parked cars of site.gd; the front is -Z.
	_part(body, Vector3(1.8, 0.8, 4.4), Vector3(0, 0.6, 0), car.paint)
	_part(body, Vector3(1.6, 0.6, 2.3), Vector3(0, 1.3, 0.2), _plain(Color(0.15, 0.18, 0.22)))
	var lamp := _plain(Color(1.0, 0.95, 0.75))
	lamp.emission_enabled = true
	lamp.emission = Color(1.0, 0.95, 0.75)
	lamp.emission_energy_multiplier = 0.6
	car.tail = _plain(Color(0.6, 0.05, 0.05))
	car.tail.emission_enabled = true
	car.tail.emission = Color(1.0, 0.1, 0.05)
	for x in [-0.6, 0.6]:
		_part(body, Vector3(0.35, 0.15, 0.05), Vector3(x, 0.75, -2.21), lamp)
		_part(body, Vector3(0.35, 0.15, 0.05), Vector3(x, 0.75, 2.21), car.tail)
	car.state = State.IDLE
	_set_brake(car, false)
	return car


func _part(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)


func _plain(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _set_brake(car: Car, on: bool) -> void:
	car.tail.emission_energy_multiplier = 2.0 if on else 0.3


## Puts the car at map point p (x/z) with its front towards dir.
func _place(car: Car, p: Vector2, dir: Vector2) -> void:
	var b := Basis.looking_at(Vector3(dir.x, 0.0, dir.y), Vector3.UP)
	car.body.transform = Transform3D(b, Vector3(p.x, 0.0, p.y))


# --- Route and parking bays from the site data --------------------------------

func _route(roads: Array) -> PackedVector2Array:
	var line := PackedVector2Array()
	for idx in route_roads:
		if idx < 0 or idx >= roads.size():
			continue
		var pts := PackedVector2Array()
		for v in roads[idx]["pts"]:
			pts.append(Vector2(v[0], v[1]))
		if line.size() > 0 and line[line.size() - 1].distance_to(pts[pts.size() - 1]) < line[line.size() - 1].distance_to(pts[0]):
			pts.reverse()
		for p in pts:
			if line.size() == 0 or line[line.size() - 1].distance_to(p) > 0.5:
				line.append(p)
	return line


## Bays along both sides of the centre line `center`. Spot: lane (0 = with
## the centre line, 1 = against it), s (along that lane), center, n (into the bay).
func _find_spots(center: Path2, d: Dictionary) -> void:
	var near := Rect2(center.pts[0], Vector2.ZERO)
	for p in center.pts:
		near = near.expand(p)
	near = near.grow(15.0)
	var parks := _polys(d["areas"], near, "parking")
	var buildings := _polys(d["buildings"], near, "")
	var others: Array = []   # [a, b, half width] of every other road segment
	for i in d["roads"].size():
		if route_roads.has(i):
			continue
		var r: Dictionary = d["roads"][i]
		var pts: Array = r["pts"]
		for k in range(1, pts.size()):
			var a := Vector2(pts[k - 1][0], pts[k - 1][1])
			var b := Vector2(pts[k][0], pts[k][1])
			if near.has_point(a) or near.has_point(b):
				others.append([a, b, float(r["w"]) / 2.0])
	var blockers: Array[Vector2] = []   # parked cars and trees
	for c in d["cars"]:
		blockers.append(Vector2(c[0], c[1]))
	var trees: Array[Vector2] = []
	for t in d["trees"]:
		trees.append(Vector2(t[0], t[1]))

	var s := END_MARGIN
	while s < center.length - END_MARGIN:
		var p := center.point_at(s)
		var right := _right(center.dir_at(s))
		for side in [1, -1]:
			var n: Vector2 = right * side
			var inner := -1.0
			var outer := -1.0
			var o := 3.0
			while o <= 11.0:
				var inside := _inside_any(p + n * o, parks)
				if inside and inner < 0.0:
					inner = o
				if inner >= 0.0:
					if not inside:
						break
					outer = o
				o += 0.25
			if inner < 0.0 or outer - inner < MIN_BAY_DEPTH:
				continue
			var c := p + n * (inner + CAR_SIZE.z * 0.5 + 0.2)
			if not _bay_free(c, buildings, others, blockers, trees):
				continue
			var lane := 0 if side == 1 else 1
			_spots.append({"lane": lane, "s": s if lane == 0 else center.length - s,
				"center": c, "n": n, "taken": false})
		s += SPOT_PITCH
	if debug_spots:
		for sp in _spots:
			var c: Vector2 = sp["center"]
			_part(self, Vector3(0.6, 0.05, 0.6), Vector3(c.x, 0.05, c.y), _plain(Color(1, 0.4, 0.1) if sp["lane"] == 0 else Color(0.2, 0.6, 1)))
	print("Traffic: %d parking bays, route %.0f m" % [_spots.size(), center.length])


func _bay_free(c: Vector2, buildings: Array, others: Array, blockers: Array[Vector2], trees: Array[Vector2]) -> bool:
	for b in blockers:
		if b.distance_to(c) < 3.0:
			return false
	for t in trees:
		if t.distance_to(c) < 2.5:
			return false
	if _inside_any(c, buildings):
		return false
	for seg in others:
		var q := Geometry2D.get_closest_point_to_segment(c, seg[0], seg[1])
		if q.distance_to(c) < seg[2] + 1.6:
			return false
	return true


## [rect, polygon] pairs of the list entries (optionally of one kind) near `near`.
func _polys(list: Array, near: Rect2, kind: String) -> Array:
	var out: Array = []
	for e in list:
		if kind != "" and e.get("kind", "") != kind:
			continue
		var poly := PackedVector2Array()
		for v in e["poly"]:
			poly.append(Vector2(v[0], v[1]))
		var r := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			r = r.expand(p)
		if r.intersects(near):
			out.append([r, poly])
	return out


static func _inside_any(p: Vector2, polys: Array) -> bool:
	for e in polys:
		if (e[0] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, e[1]):
			return true
	return false


## Right of a direction on the map (north up, +z = south).
static func _right(dir: Vector2) -> Vector2:
	return Vector2(-dir.y, dir.x)


static func _offset(line: PackedVector2Array, dist: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in line.size():
		var t := Vector2.ZERO
		if i > 0:
			t += (line[i] - line[i - 1]).normalized()
		if i < line.size() - 1:
			t += (line[i + 1] - line[i]).normalized()
		out.append(line[i] + _right(t.normalized()) * dist)
	return out


static func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, steps := 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		var u := 1.0 - t
		out.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	return out
