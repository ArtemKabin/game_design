extends Node3D
## Ambient traffic outside (outside.tscn), built from data/hka_site.json.
## (Paths: poly_path.gd, data and pedestrians: site_paths.gd.)
##
## Front road: a chain of roads (`route_roads`, indices into "roads"; default
## the 7 m road north of the dorm). Cars drive on the right lane in both
## directions, enter at one map edge and leave at the other.
## Parking: some cars turn nose-first into a free bay along the front road
## (`park_chance`), others turn off into the big car park on the left
## (`lot_chance`, aisles `lot_aisles`), drive down an aisle, park in a free
## stall, back out, drive back to the front road and leave the map.
## Free bays/stalls come from the data: inside a "parking" area, no parked
## (static) car, building, tree or other road there.
## Cars are pooled (`pool_size`): nothing is created or freed while playing.
## They stop for the player and for NPCs (group "pedestrians"), keep their
## distance and only pull out when the way is clear.
## Turn on `debug_spots` to see bays (orange/blue) and lot stalls (green).

@export_file("*.json") var data_path := "res://data/hka_site.json"
@export var route_roads := PackedInt32Array([164, 165, 48])
## Car-park aisles that start at the front road; each entry is a chain of
## road indices (cut where the next one starts).
@export var lot_aisles: Array[PackedInt32Array] = [PackedInt32Array([94]), PackedInt32Array([64, 37])]
@export var pool_size := 16
## Seconds between two new cars (random in this range).
@export var spawn_interval := Vector2(3.0, 7.0)
@export_range(0.0, 1.0) var lot_chance := 0.35
@export_range(0.0, 1.0) var park_chance := 0.2
## Seconds a car stays parked (random in this range).
@export var park_time := Vector2(8.0, 25.0)
## m/s on the front road (8.3 = 30 km/h) and in the car park.
@export var cruise_speed := 8.3
@export var lot_speed := 3.5
@export var debug_spots := false

const LANE_OFFSET := 1.75   ## lane centre from the road centre (right-hand traffic)
const AISLE_OFFSET := 1.2   ## same in the car-park aisles
const CAR_SIZE := Vector3(1.8, 1.4, 4.4)
const MIN_GAP := 7.5        ## centre to centre distance to the car ahead
const ACCEL := 3.0
const BRAKE := 8.0
const STREET_TURN_IN := 7.0 ## turn into a bay starts this far before it
const LOT_TURN_IN := 5.0
const BACK_OUT := 6.0       ## backing out ends this far along the lane
const AISLE_ENTER_S := 5.0  ## where a car arrives on an aisle after turning off

enum State { IDLE, DRIVE, TRANSFER, PARK_IN, PARKED, PARK_OUT }


class Car:
	var body: AnimatableBody3D
	var shape: CollisionShape3D
	var paint: StandardMaterial3D
	var tail: StandardMaterial3D
	var state := 0
	var path := 0         ## index into _paths
	var s := 0.0          ## position along that path (while manoeuvring: where it blocks)
	var speed := 0.0
	var spot := {}
	var entry := -1       ## car-park aisle the car is heading for / leaving, -1 = none
	var curve: PolyPath
	var m := 0.0          ## distance along the manoeuvre curve
	var s0 := 0.0
	var next_path := 0
	var next_s := 0.0
	var wait := 0.0
	var in_lane := true   ## blocks cars behind it


var _paths: Array[PolyPath] = []   ## 0, 1 = front road lanes; then per aisle: in, out
var _limits: Array[float] = []
## per aisle: {"in": path, "out": path, "junction": [s on lane 0, s on lane 1]}
var _entries: Array[Dictionary] = []
var _spots: Array[Dictionary] = []
var _cars: Array[Car] = []
var _colors: Array[Color] = []
var _peds := PackedVector3Array()
var _spawn_timer := 1.0


func _ready() -> void:
	var d := SitePaths.load_site(data_path)
	if d.is_empty():
		return
	var center := SitePaths.chain(d["roads"], route_roads)
	if center.size() < 2:
		push_warning("Traffic: route_roads do not form a road.")
		return
	_add_path(PolyPath.offset(center, LANE_OFFSET), cruise_speed)
	_add_path(PolyPath.offset(PolyPath.reversed(center), LANE_OFFSET), cruise_speed)
	var finder := _SpotFinder.new(d, route_roads, center)
	finder.find(self, PolyPath.new(center), {"lane0": 0, "lane1": 1, "start": 30.0, "end": 30.0,
		"pitch": 2.8, "car_gap": 3.0, "turn_in": STREET_TURN_IN, "out_dir": 1, "entry": -1})
	for chain in lot_aisles:
		var aisle := SitePaths.chain(d["roads"], chain)
		if aisle.size() < 2:
			continue
		var in_id := _add_path(PolyPath.offset(aisle, AISLE_OFFSET), lot_speed)
		var out_id := _add_path(PolyPath.offset(PolyPath.reversed(aisle), AISLE_OFFSET), lot_speed)
		var start := aisle[0]
		_entries.append({"in": in_id, "out": out_id,
			"junction": [_paths[0].closest_s(start), _paths[1].closest_s(start)]})
		finder.find(self, PolyPath.new(aisle), {"lane0": in_id, "lane1": in_id, "start": 10.0, "end": 3.0,
			"pitch": 2.6, "car_gap": 2.3, "fixed": 4.6, "turn_in": LOT_TURN_IN, "out_dir": -1,
			"entry": _entries.size() - 1})
	for c in d["cars"]:
		_colors.append(Color(c[3], c[4], c[5]))
	if _colors.is_empty():
		_colors.append(Color(0.6, 0.6, 0.62))
	if debug_spots:
		for sp in _spots:
			var c: Vector2 = sp["center"]
			var col := Color(0.3, 0.9, 0.3) if sp["entry"] >= 0 else (Color(1, 0.5, 0.1) if sp["path"] == 0 else Color(0.2, 0.6, 1))
			_part(self, Vector3(0.6, 0.05, 0.6), Vector3(c.x, 0.05, c.y), _plain(col))
	var lot := 0
	for sp in _spots:
		if sp["entry"] >= 0:
			lot += 1
	print("Traffic: %d street bays, %d car-park stalls, front road %.0f m" % [_spots.size() - lot, lot, _paths[0].length])
	for i in pool_size:
		_cars.append(_make_car())
	_warm_start()


func _physics_process(delta: float) -> void:
	if _paths.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(spawn_interval.x, spawn_interval.y)
		_spawn(randi() % 2, 0.0, true)
	_peds = SitePaths.pedestrian_positions(get_tree())
	for car in _cars:
		match car.state:
			State.DRIVE:
				_drive(car, delta)
			State.TRANSFER:
				_transfer(car, delta)
			State.PARK_IN:
				_park_in(car, delta)
			State.PARKED:
				car.wait -= delta
				if car.wait <= 0.0 and _can_back_out(car):
					_start_back_out(car)
			State.PARK_OUT:
				_back_out(car, delta)


# --- Behaviour ----------------------------------------------------------------

func _drive(car: Car, delta: float) -> void:
	var path := _paths[car.path]
	var target: float = _limits[car.path]
	var gap := _gap_ahead(car)
	if gap < INF:
		target = minf(target, maxf(0.0, (gap - MIN_GAP) * 1.2))
	var ped := _pedestrian(car, 1.0)
	if ped < 12.0:
		target = minf(target, maxf(0.0, (ped - 4.0) * 1.0))
	var on_road := car.path <= 1
	var action := ""   # what happens at `action_s`
	var action_s := INF
	if not car.spot.is_empty() and car.path == car.spot["path"]:
		action = "park"
		action_s = car.spot["s"] - car.spot["turn_in"]
	elif on_road and car.entry >= 0 and not car.spot.is_empty():
		action = "turn_off"
		action_s = _entries[car.entry]["junction"][car.path] - 4.0
	elif not on_road and car.entry >= 0 and car.path == _entries[car.entry]["out"]:
		action = "merge"
		action_s = path.length - 3.0
	if action != "":
		target = minf(target, 2.8 + maxf(action_s - car.s, 0.0) * 0.45)
		if action == "merge" and not _merge_clear(car):
			target = minf(target, maxf(0.0, action_s - car.s) * 1.0)
	var a := ACCEL if target > car.speed else BRAKE
	car.speed = move_toward(car.speed, target, a * delta)
	car.s += car.speed * delta
	_set_brake(car, target < car.speed - 0.5 or car.speed < 0.3)
	if car.s >= action_s:
		match action:
			"park":
				_start_park_in(car)
				return
			"turn_off":
				_start_turn_off(car)
				return
			"merge":
				if _merge_clear(car):
					_start_merge(car)
					return
				car.s = action_s
	if on_road and car.s >= path.length:
		_despawn(car)
		return
	_place(car, path.point_at(car.s), path.dir_at(car.s))


## Front road -> car-park aisle.
func _start_turn_off(car: Car) -> void:
	var road := _paths[car.path]
	var e: Dictionary = _entries[car.entry]
	var aisle := _paths[e["in"]]
	var p0 := road.point_at(car.s)
	var p3 := aisle.point_at(AISLE_ENTER_S)
	_start_transfer(car, PolyPath.bezier(p0, p0 + road.dir_at(car.s) * 3.5, p3 - aisle.dir_at(AISLE_ENTER_S) * 3.0, p3),
		e["in"], AISLE_ENTER_S)


## Car-park aisle -> front road, in a random direction.
func _start_merge(car: Car) -> void:
	var out := _paths[car.path]
	var lane := randi() % 2
	var road := _paths[lane]
	var js: float = _entries[car.entry]["junction"][lane] + 6.0
	var p0 := out.point_at(car.s)
	var p3 := road.point_at(js)
	car.entry = -1
	_start_transfer(car, PolyPath.bezier(p0, p0 + out.dir_at(car.s) * 3.0, p3 - road.dir_at(js) * 3.5, p3), lane, js)


func _start_transfer(car: Car, points: PackedVector2Array, next_path: int, next_s: float) -> void:
	car.curve = PolyPath.new(points)
	car.m = 0.0
	car.s0 = car.s
	car.next_path = next_path
	car.next_s = next_s
	car.state = State.TRANSFER


func _transfer(car: Car, delta: float) -> void:
	var v := clampf(car.speed, 2.5, 4.5)
	if _pedestrian(car, 1.0) < 4.0:
		v = 0.0
	car.speed = v
	car.m = minf(car.m + v * delta, car.curve.length)
	var u := car.m / car.curve.length
	if u >= 0.5 and car.path != car.next_path:
		car.path = car.next_path
	car.s = car.s0 + u * 4.0 if car.path != car.next_path else car.next_s - (1.0 - u) * 4.0
	_place(car, car.curve.point_at(car.m), car.curve.dir_at(car.m, 0.6))
	if car.m >= car.curve.length - 0.01:
		car.state = State.DRIVE
		car.path = car.next_path
		car.s = car.next_s


func _start_park_in(car: Car) -> void:
	var path := _paths[car.path]
	var p0 := path.point_at(car.s)
	var c: Vector2 = car.spot["center"]
	var n: Vector2 = car.spot["n"]
	car.curve = PolyPath.new(PolyPath.bezier(p0, p0 + path.dir_at(car.s) * 3.5, c - n * 3.2, c))
	car.m = 0.0
	car.state = State.PARK_IN


func _park_in(car: Car, delta: float) -> void:
	var left := car.curve.length - car.m
	var v := clampf(left * 1.2, 0.6, maxf(car.speed, 2.8))
	if _pedestrian(car, 1.0) < 4.0:
		v = 0.0
	car.speed = v
	car.m = minf(car.m + v * delta, car.curve.length)
	var u := car.m / car.curve.length
	car.in_lane = u < 0.6
	car.s = car.spot["s"] - car.spot["turn_in"] * (1.0 - u)
	_set_brake(car, true)
	_place(car, car.curve.point_at(car.m), car.curve.dir_at(car.m, 0.6))
	if car.m >= car.curve.length - 0.01:
		car.state = State.PARKED
		car.speed = 0.0
		car.in_lane = false
		car.wait = randf_range(park_time.x, park_time.y)
		_set_brake(car, false)


## Backing out only when nobody walks behind the car and no car comes.
func _can_back_out(car: Car) -> bool:
	if _pedestrian(car, -1.0) < 6.0:
		return false
	var spot_s: float = car.spot["s"]
	var lot: bool = car.spot["entry"] >= 0
	for o in _cars:
		if o == car or o.state == State.IDLE or o.state == State.PARKED:
			continue
		if o.path == car.spot["path"]:
			var lo := spot_s - (12.0 if lot else 30.0)
			if o.s > lo and o.s < spot_s + (10.0 if lot else 3.0):
				return false
		elif lot and o.path == _entries[car.spot["entry"]]["out"]:
			var mirrored := _paths[o.path].length - spot_s
			if absf(o.s - mirrored) < 12.0:
				return false
	return true


func _start_back_out(car: Car) -> void:
	var spot_s: float = car.spot["s"]
	# Street: end up further along the same lane. Car park: on the way out
	# (the aisle's other side), facing the front road.
	var path := _paths[car.spot["path"]]
	var end_s := spot_s - BACK_OUT
	if car.spot["entry"] >= 0:
		path = _paths[_entries[car.spot["entry"]]["out"]]
		end_s = path.length - (spot_s + BACK_OUT)
	var e := path.point_at(end_s)
	var de := path.dir_at(end_s)
	var c: Vector2 = car.spot["center"]
	var n: Vector2 = car.spot["n"]
	car.curve = PolyPath.new(PolyPath.bezier(c, c - n * 3.0, e + de * 3.0, e))
	car.m = 0.0
	car.state = State.PARK_OUT


func _back_out(car: Car, delta: float) -> void:
	var left := car.curve.length - car.m
	var v := clampf(minf(car.m + 0.4, left) * 1.0, 0.4, 2.0)
	if _pedestrian(car, -1.0) < 4.0:
		v = 0.0
	car.m = minf(car.m + v * delta, car.curve.length)
	var u := car.m / car.curve.length
	var spot_s: float = car.spot["s"]
	var k: float = car.spot["out_dir"]
	car.in_lane = u > 0.4
	car.s = spot_s - BACK_OUT * k * u
	_set_brake(car, true)
	# Reversing: the nose points against the direction of motion.
	_place(car, car.curve.point_at(car.m), -car.curve.dir_at(car.m, 0.6))
	if car.m >= car.curve.length - 0.01:
		var sp := car.spot
		sp["taken"] = false
		car.spot = {}
		car.state = State.DRIVE
		car.in_lane = true
		car.speed = 0.0
		if sp["entry"] >= 0:
			# Leave the car park: drive back up the aisle on the other side.
			car.entry = sp["entry"]
			car.path = _entries[car.entry]["out"]
			car.s = _paths[car.path].length - (spot_s + BACK_OUT)
		else:
			car.s = spot_s - BACK_OUT


func _merge_clear(car: Car) -> bool:
	if _pedestrian(car, 1.0) < 5.0:
		return false
	var e: Dictionary = _entries[car.entry]
	for o in _cars:
		if o.state != State.DRIVE or o.path > 1:
			continue
		var js: float = e["junction"][o.path]
		if o.s > js - 30.0 and o.s < js + 10.0:
			return false
	return true


## Distance (centre to centre) to the next car on the same path, INF if none.
func _gap_ahead(car: Car) -> float:
	var best := INF
	for o in _cars:
		if o == car or o.path != car.path or o.state == State.IDLE or not o.in_lane:
			continue
		var d := o.s - car.s
		if d > 0.0 and d < best:
			best = d
	return best


## Distance to the nearest pedestrian (player or NPC) in front of (dir = 1)
## or behind (dir = -1) the car, INF if nobody is in its way.
func _pedestrian(car: Car, dir: float) -> float:
	return SitePaths.nearest_ahead(car.body.global_transform, _peds, dir, 1.9)


# --- Pool -------------------------------------------------------------------

func _spawn(lane: int, s: float, may_park: bool) -> Car:
	var car: Car = null
	for c in _cars:
		if c.state == State.IDLE:
			car = c
			break
	if car == null:
		return null
	for o in _cars:
		if o.state != State.IDLE and o.path == lane and o.in_lane and absf(o.s - s) < MIN_GAP * 1.5:
			return null
	car.path = lane
	car.s = s
	car.speed = cruise_speed * 0.8
	car.state = State.DRIVE
	car.in_lane = true
	car.spot = {}
	car.entry = -1
	if may_park:
		var r := randf()
		if r < lot_chance:
			car.spot = _free_spot(func(sp: Dictionary) -> bool: return sp["entry"] >= 0 and _entries[sp["entry"]]["junction"][lane] > s + 25.0)
			if not car.spot.is_empty():
				car.entry = car.spot["entry"]
		elif r < lot_chance + park_chance:
			car.spot = _free_spot(func(sp: Dictionary) -> bool: return sp["entry"] < 0 and sp["path"] == lane and sp["s"] > s + 25.0)
		if not car.spot.is_empty():
			car.spot["taken"] = true
	car.paint.albedo_color = _colors.pick_random()
	car.body.visible = true
	car.shape.disabled = false
	var path := _paths[lane]
	_place(car, path.point_at(s), path.dir_at(s))
	return car


func _despawn(car: Car) -> void:
	if not car.spot.is_empty():
		car.spot["taken"] = false
	car.spot = {}
	car.entry = -1
	car.state = State.IDLE
	car.body.visible = false
	car.shape.disabled = true
	car.body.position = Vector3(0, -50, 0)


func _free_spot(accept: Callable) -> Dictionary:
	var options: Array[Dictionary] = []
	for sp in _spots:
		if not sp["taken"] and accept.call(sp):
			options.append(sp)
	return options.pick_random() if not options.is_empty() else {}


## Cars already on the road and some parked ones when the scene loads.
func _warm_start() -> void:
	for lane in 2:
		for i in 3:
			_spawn(lane, randf_range(0.1, 0.9) * _paths[lane].length, false)
	for i in 7:
		var lot := i < 4
		var sp := _free_spot(func(x: Dictionary) -> bool: return (x["entry"] >= 0) == lot)
		var car := _spawn(randi() % 2, 0.0, false)
		if car == null or sp.is_empty():
			if car:
				_despawn(car)
			continue
		sp["taken"] = true
		car.spot = sp
		car.path = sp["path"]
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


func _add_path(points: PackedVector2Array, limit: float) -> int:
	_paths.append(PolyPath.new(points))
	_limits.append(limit)
	return _paths.size() - 1


func add_spot(spot: Dictionary) -> void:
	_spots.append(spot)


## Finds free parking places beside a centre line from the site data.
class _SpotFinder:
	var parks: Array = []       ## [rect, polygon]
	var buildings: Array = []
	var others: Array = []      ## [a, b, half width] of every other road segment
	var cars: Array[Vector2] = []
	var trees: Array[Vector2] = []

	func _init(d: Dictionary, skip_roads: PackedInt32Array, near_line: PackedVector2Array) -> void:
		var near := Rect2(near_line[0], Vector2.ZERO)
		for p in near_line:
			near = near.expand(p)
		near = near.grow(20.0)
		parks = _polys(d["areas"], "parking")
		for b in d["buildings"]:
			if not b.get("roof_only", false):
				buildings.append_array(_polys([b], ""))
		var roads: Array = d["roads"]
		for i in roads.size():
			if skip_roads.has(i):
				continue
			var pts: Array = roads[i]["pts"]
			var hw := float(roads[i]["w"]) / 2.0
			for k in range(1, pts.size()):
				var a := Vector2(pts[k - 1][0], pts[k - 1][1])
				var b := Vector2(pts[k][0], pts[k][1])
				var r := Rect2(a, Vector2.ZERO).expand(b).grow(hw + 1.6)
				if r.intersects(near):
					others.append([a, b, hw, r])
		for c in d["cars"]:
			cars.append(Vector2(c[0], c[1]))
		for t in d["trees"]:
			trees.append(Vector2(t[0], t[1]))

	## Adds spots along `line` to `traffic`. opt: lane0/lane1 (path of the
	## spots on the right/left side), start/end margins, pitch, car_gap,
	## fixed (centre offset; else found from the parking area), turn_in,
	## out_dir, entry.
	func find(traffic, line: PolyPath, opt: Dictionary) -> void:
		# Road segments that are part of this line itself do not block it.
		var blockers: Array = []
		for seg in others:
			if line.distance_to(seg[0]) > 0.6 or line.distance_to(seg[1]) > 0.6:
				blockers.append(seg)
		var s: float = opt["start"]
		while s < line.length - opt["end"]:
			var p := line.point_at(s)
			var right := PolyPath.right_of(line.dir_at(s))
			for side in [1, -1]:
				var n: Vector2 = right * side
				var c := _bay_center(p, n, opt.get("fixed", -1.0))
				if c == Vector2.INF or not _free(c, opt["car_gap"], blockers):
					continue
				var path_id: int = opt["lane0"] if side == 1 else opt["lane1"]
				# Lane 1 of the front road runs the other way.
				var lane_s := s
				if opt["entry"] < 0 and side == -1:
					lane_s = line.length - s
				traffic.add_spot({"path": path_id, "s": lane_s, "center": c, "n": n, "taken": false,
					"turn_in": opt["turn_in"], "out_dir": opt["out_dir"], "entry": opt["entry"]})
			s += opt["pitch"]

	func _bay_center(p: Vector2, n: Vector2, fixed: float) -> Vector2:
		if fixed > 0.0:
			for o in [fixed - 2.0, fixed, fixed + 1.5]:
				if not _inside(p + n * o, parks):
					return Vector2.INF
			return p + n * fixed
		var inner := -1.0
		var outer := -1.0
		var o := 3.0
		while o <= 11.0:
			var inside := _inside(p + n * o, parks)
			if inside and inner < 0.0:
				inner = o
			if inner >= 0.0:
				if not inside:
					break
				outer = o
			o += 0.25
		if inner < 0.0 or outer - inner < 3.5:
			return Vector2.INF
		return p + n * (inner + 2.4)

	func _free(c: Vector2, car_gap: float, roads: Array) -> bool:
		for b in cars:
			if b.distance_to(c) < car_gap:
				return false
		for t in trees:
			if t.distance_to(c) < 2.5:
				return false
		if _inside(c, buildings):
			return false
		for seg in roads:
			if not (seg[3] as Rect2).has_point(c):
				continue
			var q := Geometry2D.get_closest_point_to_segment(c, seg[0], seg[1])
			if q.distance_to(c) < seg[2] + 1.6:
				return false
		return true

	static func _polys(list: Array, kind: String) -> Array:
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
			out.append([r, poly])
		return out

	static func _inside(p: Vector2, polys: Array) -> bool:
		for e in polys:
			if (e[0] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, e[1]):
				return true
		return false
