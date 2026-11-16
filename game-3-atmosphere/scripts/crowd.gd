extends Node3D
## Campus foot traffic (outside.tscn): `count` anonymous students walking on
## all footways of data/hka_site.json. Each one appears at an end of the
## footway network (dead ends: house doors, the map edge), walks the shortest
## way (AStar2D) to another end at least `min_trip` metres away, "goes in"
## there and reappears somewhere else after a moment.
##
## Lightweight on purpose: two MultiMeshes (bodies, backpacks) for everybody,
## no node or physics body per person. They are not solid and not
## interactive (the named, talkable people are npc.gd). They keep right,
## stop briefly when the player is in the way, and cars and bikes stop for
## them (group "crowd", positions()).

@export_file("*.json") var data_path := "res://data/hka_site.json"
@export var count := 90
## Map area (x, z) to walk in; empty = the whole map.
@export var area := Rect2()
@export var speed := Vector2(1.0, 1.6)
@export var min_trip := 60.0

const COLORS := [Color(0.62, 0.6, 0.57), Color(0.5, 0.42, 0.38), Color(0.38, 0.42, 0.36),
	Color(0.7, 0.66, 0.55), Color(0.55, 0.38, 0.4), Color(0.42, 0.4, 0.5), Color(0.75, 0.72, 0.7),
	Color(0.3, 0.3, 0.32), Color(0.6, 0.5, 0.35)]
const PACK_COLORS := [Color(0.2, 0.22, 0.28), Color(0.45, 0.2, 0.2), Color(0.2, 0.35, 0.3), Color(0.15, 0.15, 0.15)]


class Walker:
	var path := PackedVector2Array()
	var i := 1           ## next point of path
	var pos := Vector2.ZERO
	var dir := Vector2.UP
	var speed := 1.3
	var side := 0.5      ## metres right of the path centre
	var scale := 1.0
	var phase := 0.0
	var wait := 0.0
	var blocked := 0.0
	var hidden := true


var _astar := AStar2D.new()
var _ends := PackedInt64Array()
var _walkers: Array[Walker] = []
var _bodies: MultiMesh
var _packs: MultiMesh
var _positions := PackedVector3Array()
var _hidden := Transform3D(Basis().scaled(Vector3(0.001, 0.001, 0.001)), Vector3(0, -100, 0))


func _ready() -> void:
	add_to_group("crowd")
	var d := SitePaths.load_site(data_path)
	if d.is_empty():
		return
	var adj := SitePaths.walk_graph(d, area, SitePaths.WALK_KINDS)
	if adj.size() < 2:
		push_warning("Crowd: no footways.")
		return
	var ids := {}
	for p in adj:
		var id := ids.size()
		ids[p] = id
		_astar.add_point(id, p)
	for p in adj:
		for n in adj[p]:
			if not _astar.are_points_connected(ids[p], ids[n]):
				_astar.connect_points(ids[p], ids[n])
		if adj[p].size() == 1:
			_ends.append(ids[p])
	if _ends.size() < 2:
		_ends = _astar.get_point_ids()
	_bodies = _make_multimesh(_body_mesh())
	_packs = _make_multimesh(_pack_mesh())
	for i in count:
		var w := Walker.new()
		w.speed = randf_range(speed.x, speed.y)
		w.side = randf_range(0.35, 0.9)
		w.scale = randf_range(0.9, 1.05)
		w.phase = randf() * TAU
		_bodies.set_instance_color(i, COLORS.pick_random())
		_packs.set_instance_color(i, PACK_COLORS.pick_random())
		_walkers.append(w)
		_new_trip(w, true)
	print("Crowd: %d people on %d footway points (%d ends)" % [count, adj.size(), _ends.size()])


## Positions of everybody walking (cars and bikes brake for them).
func positions() -> PackedVector3Array:
	return _positions


func _physics_process(delta: float) -> void:
	if _walkers.is_empty():
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var pp := Vector2.INF
	if player:
		pp = Vector2(player.global_position.x, player.global_position.z)
	_positions.resize(0)
	for idx in _walkers.size():
		var w := _walkers[idx]
		if w.wait > 0.0:
			w.wait -= delta
			if w.wait <= 0.0 and w.hidden:
				_new_trip(w, false)
		elif not w.hidden:
			_walk(w, delta, pp)
		if w.hidden:
			_bodies.set_instance_transform(idx, _hidden)
			_packs.set_instance_transform(idx, _hidden)
			continue
		var at := w.pos + PolyPath.right_of(w.dir) * w.side
		var bob := absf(sin(w.phase)) * 0.05
		var b := Basis.looking_at(Vector3(w.dir.x, 0.0, w.dir.y), Vector3.UP).scaled(Vector3.ONE * w.scale)
		_bodies.set_instance_transform(idx, Transform3D(b, Vector3(at.x, bob, at.y)))
		_packs.set_instance_transform(idx, Transform3D(b, Vector3(at.x, bob, at.y)))
		_positions.append(Vector3(at.x, 0.0, at.y))


func _walk(w: Walker, delta: float, player: Vector2) -> void:
	var target := w.path[w.i]
	var to := target - w.pos
	var dist := to.length()
	if dist > 0.001:
		w.dir = to / dist
	# Somebody (the player) in the way: wait a moment, then squeeze past.
	var rel := player - (w.pos + PolyPath.right_of(w.dir) * w.side)
	var along := rel.dot(w.dir)
	if along > 0.0 and along < 1.0 and absf(rel.dot(PolyPath.right_of(w.dir))) < 0.6 and w.blocked < 1.5:
		w.blocked += delta
		return
	if along < 0.0:
		w.blocked = 0.0
	var step := w.speed * delta
	w.phase += step * 3.2
	if step >= dist:
		w.pos = target
		w.i += 1
		if w.i >= w.path.size():
			# Arrived: goes inside, comes back elsewhere.
			w.hidden = true
			w.wait = randf_range(1.0, 6.0)
	else:
		w.pos += w.dir * step


## A new walk from one end to another. `anywhere`: start somewhere along the
## way (scene start), so the paths are busy right away.
func _new_trip(w: Walker, anywhere: bool) -> void:
	for _attempt in 6:
		var a: int = _ends[randi() % _ends.size()]
		var b: int = _ends[randi() % _ends.size()]
		if a == b or _astar.get_point_position(a).distance_to(_astar.get_point_position(b)) < min_trip:
			continue
		var path := _astar.get_point_path(a, b)
		if path.size() < 2:
			continue
		w.path = path
		w.i = 1
		w.pos = path[0]
		w.blocked = 0.0
		if anywhere:
			w.i = randi_range(1, path.size() - 1)
			w.pos = path[w.i - 1].lerp(path[w.i], randf())
		w.dir = (path[w.i] - w.pos).normalized()
		w.hidden = false
		return
	w.wait = 1.0   # try again later


func _make_multimesh(mesh: Mesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	# Instances move over the whole map: no culling by the initial bounds.
	mmi.custom_aabb = AABB(Vector3(-1000, -10, -1000), Vector3(2000, 20, 2000))
	add_child(mmi)
	return mm


## Capsule like the player (a bit slimmer), feet at y = 0.
func _body_mesh() -> Mesh:
	var cm := CapsuleMesh.new()
	cm.radius = 0.26
	cm.height = 1.7
	var st := SurfaceTool.new()
	st.append_from(cm, 0, Transform3D(Basis(), Vector3(0, 0.85, 0)))
	var mesh := st.commit()
	mesh.surface_set_material(0, _vertex_color_material())
	return mesh


## Backpack on the back (+Z, the front is -Z).
func _pack_mesh() -> Mesh:
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.42, 0.18)
	var st := SurfaceTool.new()
	st.append_from(bm, 0, Transform3D(Basis(), Vector3(0, 1.15, 0.3)))
	var mesh := st.commit()
	mesh.surface_set_material(0, _vertex_color_material())
	return mesh


func _vertex_color_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	return m
