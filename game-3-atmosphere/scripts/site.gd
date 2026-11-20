@tool
extends Node3D
## The dorm and the campus around it, generated from data/hka_site.json
## (derived from OpenStreetMap, see README; map coordinates, north up).
## Ground areas, roads and paths (connected polylines with round joins,
## clipped where they would run through a building), buildings (see
## site_building.gd), hedges/fences/walls, dorm entrances, trees and parked
## cars (MultiMeshes) and invisible walls along the play-area border.
## Toggle `rebuild` in the inspector after changing the JSON.

@export_file("*.json") var data_path := "res://data/hka_site.json"
@export var rebuild := false:
	set(v):
		if v and is_inside_tree():
			_build()

## Draw order on the ground: every kind has its own height, 6 mm apart, all
## below the walking height (y = 0). Paths lie below car roads, so roads run
## through crossings and path ends disappear under the asphalt. Together with
## the camera's zoom-dependent near plane (camera_rig.gd) nothing z-fights.
const LAYER_STEP := 0.006
const LAYER_ORDER := ["forest", "grass", "construction", "play", "pitch", "parking", "plaza",
	"track", "path", "footway", "steps", "pedestrian", "cycleway", "living_street", "aisle", "service",
	"residential", "unclassified", "tertiary", "secondary", "primary"]
const COLORS := {
	"forest": Color(0.27, 0.38, 0.2), "grass": Color(0.42, 0.56, 0.3), "construction": Color(0.5, 0.43, 0.33),
	"play": Color(0.66, 0.58, 0.42), "pitch": Color(0.6, 0.36, 0.28), "parking": Color(0.36, 0.36, 0.38),
	"plaza": Color(0.58, 0.56, 0.52), "track": Color(0.55, 0.5, 0.42), "path": Color(0.58, 0.53, 0.45),
	"footway": Color(0.62, 0.6, 0.57), "steps": Color(0.66, 0.66, 0.66), "pedestrian": Color(0.6, 0.58, 0.55),
	"cycleway": Color(0.5, 0.38, 0.35), "living_street": Color(0.5, 0.48, 0.46), "aisle": Color(0.4, 0.4, 0.42),
	"service": Color(0.36, 0.36, 0.38), "residential": Color(0.32, 0.32, 0.34), "unclassified": Color(0.32, 0.32, 0.34),
	"tertiary": Color(0.32, 0.32, 0.34), "secondary": Color(0.3, 0.3, 0.32), "primary": Color(0.3, 0.3, 0.32),
}
const GRASS_Y := -0.14   ## base grass plane (outside.tscn), below every layer
const DOOR_NOTE := "Hier wird noch gearbeitet."


static func layer_y(kind: String) -> float:
	return GRASS_Y + LAYER_STEP * (LAYER_ORDER.find(kind) + 1)


const BARRIER_COLOR := {"hedge": Color(0.2, 0.36, 0.17), "fence": Color(0.35, 0.38, 0.36),
	"wall": Color(0.55, 0.53, 0.5), "retaining_wall": Color(0.5, 0.48, 0.45)}
const JOIN_SEGMENTS := 12
const SiteBuilding := preload("res://scripts/site_building.gd")

var _building_polys: Array[PackedVector2Array] = []
var _crop := Rect2()   ## map rectangle; roads cut at its edge get no round cap there
var _building_rects: Array[Rect2] = []


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_building_polys.clear()
	_building_rects.clear()
	var f := FileAccess.open(data_path, FileAccess.READ)
	if f == null:
		push_warning("Site data missing: " + data_path)
		return
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	if d.has("crop"):
		var c: Array = d["crop"]
		_crop = Rect2(c[0], c[1], c[2] - c[0], c[3] - c[1])
	var by_dorm := {}
	var nodes: Array = []
	for b in d["buildings"]:
		var node := SiteBuilding.new()
		node.setup(b)
		add_child(node)
		nodes.append(node)
		if b.has("dorm"):
			by_dorm[b["dorm"]] = node
		if not b.get("roof_only", false):
			var poly := _poly(b["poly"])
			_building_polys.append(poly)
			var r := Rect2(poly[0], Vector2.ZERO)
			for p in poly:
				r = r.expand(p)
			_building_rects.append(r)
	_build_areas(d["areas"])
	_build_roads(d["roads"])
	_build_barriers(d["barriers"])
	_build_entrances(d["entrances"], by_dorm)
	_build_doors(d.get("doors", []), nodes)
	_build_trees(d["trees"])
	_build_cars(d["cars"])
	_build_bounds(d["bounds"])


static func _poly(arr: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v in arr:
		p.append(Vector2(v[0], v[1]))
	return p


static func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## Triangle with its front face (clockwise in Godot) pointing up.
static func _tri_up(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	if (b - a).cross(c - a).y > 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _flat_mesh(n: String, st: SurfaceTool, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = st.commit()
	mi.material_override = _material(color)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_areas(list: Array) -> void:
	var tools := {}
	for a in list:
		var kind: String = a["kind"]
		if not COLORS.has(kind):
			continue
		if not tools.has(kind):
			tools[kind] = SurfaceTool.new()
			tools[kind].begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[kind].set_normal(Vector3.UP)
		var poly := _poly(a["poly"])
		var y := layer_y(kind)
		var idx := Geometry2D.triangulate_polygon(poly)
		for t in range(0, idx.size(), 3):
			_tri_up(tools[kind], Vector3(poly[idx[t]].x, y, poly[idx[t]].y),
				Vector3(poly[idx[t + 1]].x, y, poly[idx[t + 1]].y), Vector3(poly[idx[t + 2]].x, y, poly[idx[t + 2]].y))
	for kind in tools:
		_flat_mesh("Area_" + kind, tools[kind], COLORS[kind])


## Cuts a polyline where it runs through a building (passages, indoor paths).
func _clip_to_outside(line: PackedVector2Array) -> Array:
	var parts: Array = [line]
	var r := Rect2(line[0], Vector2.ZERO)
	for p in line:
		r = r.expand(p)
	for i in _building_polys.size():
		if not _building_rects[i].intersects(r):
			continue
		var next: Array = []
		for part in parts:
			next.append_array(Geometry2D.clip_polyline_with_polygon(part, _building_polys[i]))
		parts = next
	return parts


## Roads: a quad per segment plus a disc at every point, so bends and
## junctions are round and every connected way joins without gaps.
func _build_roads(list: Array) -> void:
	var tools := {}
	for r in list:
		var kind: String = r["kind"]
		if not COLORS.has(kind):
			continue
		if not tools.has(kind):
			tools[kind] = SurfaceTool.new()
			tools[kind].begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[kind].set_normal(Vector3.UP)
		var st: SurfaceTool = tools[kind]
		var y := layer_y(kind)
		var hw: float = r["w"] / 2.0
		for line in _clip_to_outside(_poly(r["pts"])):
			if line.size() < 2:
				continue
			for i in line.size():
				if not _on_crop_edge(line[i]):
					_disc(st, line[i], hw, y)
				if i == 0:
					continue
				var a: Vector2 = line[i - 1]
				var b: Vector2 = line[i]
				if a.distance_to(b) < 0.01:
					continue
				var n := (b - a).normalized().orthogonal() * hw
				var q := [a + n, b + n, b - n, a - n]
				_tri_up(st, Vector3(q[0].x, y, q[0].y), Vector3(q[1].x, y, q[1].y), Vector3(q[2].x, y, q[2].y))
				_tri_up(st, Vector3(q[0].x, y, q[0].y), Vector3(q[2].x, y, q[2].y), Vector3(q[3].x, y, q[3].y))
	for kind in tools:
		_flat_mesh("Road_" + kind, tools[kind], COLORS[kind])


func _on_crop_edge(p: Vector2) -> bool:
	if not _crop.has_area():
		return false
	return absf(p.x - _crop.position.x) < 0.05 or absf(p.x - _crop.end.x) < 0.05 		or absf(p.y - _crop.position.y) < 0.05 or absf(p.y - _crop.end.y) < 0.05


func _disc(st: SurfaceTool, c: Vector2, r: float, y: float) -> void:
	for k in JOIN_SEGMENTS:
		var a0 := TAU * k / JOIN_SEGMENTS
		var a1 := TAU * (k + 1) / JOIN_SEGMENTS
		_tri_up(st, Vector3(c.x, y, c.y), Vector3(c.x + cos(a0) * r, y, c.y + sin(a0) * r),
			Vector3(c.x + cos(a1) * r, y, c.y + sin(a1) * r))


## Box of `size` (x along `dir`, y up, z across) standing on y0 at centre c.
static func _box_xform(c: Vector2, y0: float, size: Vector3, dir: Vector2) -> Transform3D:
	var x_axis := Vector3(dir.x, 0, dir.y)
	var z_axis := Vector3(-dir.y, 0, dir.x)
	return Transform3D(Basis(x_axis, Vector3.UP, z_axis), Vector3(c.x, y0 + size.y / 2.0, c.y))


func _box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	m.material = _material(color)
	mi.mesh = m
	return mi


func _build_barriers(list: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "Barriers"
	add_child(body)
	for bar in list:
		var pts := _poly(bar["pts"])
		var color: Color = BARRIER_COLOR.get(bar["kind"], Color.GRAY)
		for i in range(1, pts.size()):
			var a := pts[i - 1]
			var b := pts[i]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var size := Vector3(length + bar["w"], bar["h"], bar["w"])
			var xf := _box_xform((a + b) / 2.0, 0.0, size, (b - a) / length)
			var mi := _box_mesh(size, color)
			mi.transform = xf
			body.add_child(mi)
			var cs := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = size
			cs.shape = shape
			cs.transform = xf
			body.add_child(cs)


## Dorm entrances: glass stairwell front, door, 8 steps up to the plinth, house-number label.
func _build_entrances(list: Array, by_dorm: Dictionary) -> void:
	for e in list:
		var house: String = e["name"].substr(0, 2)
		var owner: Node3D = by_dorm.get(house, self)
		var p := Vector2(e["p"][0], e["p"][1])
		var d := Vector2(e["d"][0], e["d"][1])
		var n := Vector2(e["n"][0], e["n"][1])
		var base: float = e["base"]
		var top := base + 4 * 2.9
		var parts: Array[Node3D] = []
		if e["glass"]:
			var glass := _box_mesh(Vector3(3.0, top - base, 0.08), Color(0.55, 0.75, 0.9, 0.45))
			glass.transform = _box_xform(p + n * 0.14, base, Vector3(3.0, top - base, 0.08), d)
			parts.append(glass)
		var door := _box_mesh(Vector3(1.4, 2.2, 0.06), Color(0.22, 0.3, 0.35))
		door.transform = _box_xform(p + n * 0.22, base, Vector3(1.4, 2.2, 0.06), d)
		parts.append(door)
		if e["steps"]:
			for i in 8:
				var h := base * (8 - i) / 8.0
				var s := _box_mesh(Vector3(2.0, h, 0.3), Color(0.6, 0.6, 0.62))
				s.transform = _box_xform(p + n * (0.3 + 0.3 * i), 0.0, Vector3(2.0, h, 0.3), d)
				parts.append(s)
		var l := Label3D.new()
		l.text = e["name"]
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.pixel_size = 0.01
		l.font_size = 32
		l.outline_size = 10
		l.no_depth_test = true
		l.render_priority = 5
		l.outline_render_priority = 4
		var lp := p + n * 1.0
		l.position = Vector3(lp.x, base + 3.0, lp.y)
		parts.append(l)
		for part in parts:
			if owner.has_method("add_extra"):
				owner.add_extra(part)
			else:
				add_child(part)
		if e["name"] != "17F":   # 17F is the portal into the dorm (outside.tscn)
			_add_door_action(p + n * (2.9 if e["steps"] else 0.9), "Haus " + e["name"])


## Doors of the other buildings: a door leaf in front of the wall (and in front
## of the windows) and an action that only says the inside is not built yet.
func _build_doors(list: Array, nodes: Array) -> void:
	for e in list:
		var owner: Node3D = nodes[e["b"]]
		var p := Vector2(e["p"][0], e["p"][1])
		var d := Vector2(e["d"][0], e["d"][1])
		var n := Vector2(e["n"][0], e["n"][1])
		var door := _box_mesh(Vector3(1.6, 2.3, 0.08), Color(0.2, 0.26, 0.3))
		door.transform = _box_xform(p + n * 0.12, 0.0, Vector3(1.6, 2.3, 0.08), d)
		owner.add_extra(door)
		_add_door_action(p + n * 0.9, e["title"])


func _add_door_action(at: Vector2, title: String) -> void:
	# Doors with a minigame station in outside.tscn (group door_station) need no placeholder.
	for s in get_tree().get_nodes_in_group("door_station"):
		var p: Vector3 = (s as Node3D).position
		if Vector2(p.x, p.z).distance_to(at) < 3.0:
			return
	var it := Interactable.new()
	it.title = title + " betreten"
	it.minutes = 0
	it.radius = 1.0
	it.note = DOOR_NOTE
	it.position = Vector3(at.x, 0, at.y)
	add_child(it)


func _build_trees(list: Array) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.12
	trunk.bottom_radius = 0.18
	trunk.height = 2.6
	trunk.material = _material(Color(0.4, 0.28, 0.18))
	var crown := SphereMesh.new()
	crown.radius = 1.9
	crown.height = 3.4
	crown.radial_segments = 12
	crown.rings = 6
	crown.material = _material(Color(0.24, 0.42, 0.19))
	var mm_t := _multimesh(trunk, list.size(), false)
	var mm_c := _multimesh(crown, list.size(), false)
	for i in list.size():
		var t: Array = list[i]
		var s: float = t[2]
		mm_t.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(t[0], 1.3 * s, t[1])))
		mm_c.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(t[0], 3.9 * s, t[1])))
	_add_multimesh("TreeTrunks", mm_t)
	_add_multimesh("TreeCrowns", mm_c)


func _build_cars(list: Array) -> void:
	var body := BoxMesh.new()
	body.size = Vector3(1.8, 0.8, 4.4)
	var cabin := BoxMesh.new()
	cabin.size = Vector3(1.6, 0.6, 2.3)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	body.material = mat
	cabin.material = mat
	var mm_b := _multimesh(body, list.size(), true)
	var mm_c := _multimesh(cabin, list.size(), true)
	var bodies := StaticBody3D.new()
	bodies.name = "CarCollision"
	add_child(bodies)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.4, 4.4)
	for i in list.size():
		var c: Array = list[i]
		var basis := Basis(Vector3.UP, c[2])
		var pos := Vector3(c[0], 0, c[1])
		mm_b.set_instance_transform(i, Transform3D(basis, pos + Vector3(0, 0.6, 0)))
		mm_b.set_instance_color(i, Color(c[3], c[4], c[5]))
		mm_c.set_instance_transform(i, Transform3D(basis, pos + Vector3(0, 1.3, 0) + basis * Vector3(0, 0, 0.2)))
		mm_c.set_instance_color(i, Color(0.15, 0.18, 0.22))
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.transform = Transform3D(basis, pos + Vector3(0, 0.7, 0))
		bodies.add_child(cs)
	_add_multimesh("CarBodies", mm_b)
	_add_multimesh("CarCabins", mm_c)


## Invisible walls along the closed play-area polygon.
func _build_bounds(points: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "Bounds"
	add_child(body)
	var pts := _poly(points)
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(length + 1.0, 5.0, 1.0)
		cs.shape = shape
		cs.transform = _box_xform((a + b) / 2.0, 0.0, shape.size, (b - a) / length)
		body.add_child(cs)


func _multimesh(mesh: Mesh, count: int, colors: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors
	mm.mesh = mesh
	mm.instance_count = count
	return mm


func _add_multimesh(n: String, mm: MultiMesh) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = n
	mmi.multimesh = mm
	add_child(mmi)
