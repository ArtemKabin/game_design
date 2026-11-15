@tool
extends Node3D
## One building, extruded from its real outline (world x/z polygon, map
## coordinates). Optional plinth (`base`, e.g. the open car park under the
## dorm), courtyards (holes), windows and floor bands as a MultiMesh,
## collision via CollisionPolygon3D, a name label for named buildings.
## Outdoors it is an occluder for RoomView: cut down while the player stands
## right behind (north of) it.

const COLORS := {
	"university": Color(0.56, 0.55, 0.53), "school": Color(0.6, 0.54, 0.46), "office": Color(0.56, 0.55, 0.52),
	"apartments": Color(0.62, 0.55, 0.46), "residential": Color(0.62, 0.55, 0.46), "dormitory": Color(0.64, 0.57, 0.47),
	"hotel": Color(0.6, 0.52, 0.43), "industrial": Color(0.5, 0.5, 0.5), "shed": Color(0.45, 0.38, 0.3),
	"garage": Color(0.48, 0.48, 0.48), "roof": Color(0.4, 0.4, 0.42), "carport": Color(0.4, 0.4, 0.42),
}
const ROOF := Color(0.38, 0.37, 0.36)
const PLINTH := Color(0.27, 0.27, 0.29)
const WINDOW := Color(0.22, 0.28, 0.36)
const BAND := Color(0.45, 0.43, 0.4)
const STUB_H := 0.3
const FOOT := -0.15   ## walls start below the ground layers (site.gd GRASS_Y)
const BAY_CLEAR := 2.3   ## no windows this close to a glass stairwell front

var cut_reach := 8.0
var _rings: Array[PackedVector2Array] = []   ## outer ring first, then courtyards
var _roof := PackedVector2Array()
var _rect := Rect2()
var _cut := false
var _full: Array[Node3D] = []
var _stub: MeshInstance3D


func setup(d: Dictionary) -> void:
	var outer := _ring(d["poly"])
	_rings.append(outer)
	for h in d.get("holes", []):
		_rings.append(_ring(h))
	_roof = _ring(d["roof_poly"]) if d.has("roof_poly") else outer
	_rect = Rect2(outer[0], Vector2.ZERO)
	for p in outer:
		_rect = _rect.expand(p)
	var label_text: String = d.get("name", "")
	var kind: String = d.get("kind", "yes")
	name = (label_text if label_text != "" else kind).validate_node_name()
	var height: float = d["h"]
	var base: float = d.get("base", 0.0)
	cut_reach = height / tan(deg_to_rad(60.0)) + 1.0
	var color: Color = COLORS.get(kind, Color(0.6, 0.57, 0.52))
	if d.get("roof_only", false):
		_full.append(_add_mesh(_extrude(2.8, 3.1, color, true)))
		return
	if base > 0.0:
		_full.append(_add_mesh(_extrude(FOOT, base, PLINTH, false)))
	_full.append(_add_mesh(_extrude(base if base > 0.0 else FOOT, height, color, true)))
	_stub = _add_mesh(_extrude(FOOT, STUB_H, color, true))
	_stub.visible = false
	var bays: Array = d.get("bays", [])
	_full.append(_add_windows(height, base, d["floors"], d["floor_h"], bays))
	var body := StaticBody3D.new()
	var col := CollisionPolygon3D.new()
	col.polygon = outer
	col.depth = height
	col.rotation.x = PI / 2.0
	col.position.y = height / 2.0
	body.add_child(col)
	add_child(body)
	if label_text != "":
		var l := Label3D.new()
		l.text = label_text
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.pixel_size = 0.03
		l.font_size = 64
		l.outline_size = 16
		var c := _rect.get_center()
		l.position = Vector3(c.x, height + 3.0, c.y)
		add_extra(l)


## Extra decoration (entrances, labels) that is hidden together with the building.
func add_extra(n: Node3D) -> void:
	_full.append(n)
	add_child(n)


func _ready() -> void:
	if Engine.is_editor_hint() or _stub == null:
		return
	var view := get_node_or_null("/root/RoomView")
	if view:
		view.register_occluder(self)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var view := get_node_or_null("/root/RoomView")
	if view:
		view.unregister_occluder(self)


func occluder_rect() -> Rect2:
	return _rect


func set_cut(value: bool) -> void:
	if value == _cut or _stub == null:
		return
	_cut = value
	for n in _full:
		n.visible = not value
	_stub.visible = value


static func _ring(arr: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v in arr:
		p.append(Vector2(v[0], v[1]))
	return p


## Outward normal of edge a->b of `ring`; for courtyards "outward" points into the courtyard.
func _edge_normal(a: Vector2, b: Vector2, ring_index: int) -> Vector2:
	var n := Vector2(b.y - a.y, a.x - b.x).normalized()
	var probe := (a + b) / 2.0 + n * 0.2
	var in_solid := Geometry2D.is_point_in_polygon(probe, _rings[0])
	for i in range(1, _rings.size()):
		if Geometry2D.is_point_in_polygon(probe, _rings[i]):
			in_solid = false
	return -n if in_solid else n


func _extrude(y0: float, y1: float, wall_color: Color, with_roof: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(wall_color)
	for r in _rings.size():
		var ring := _rings[r]
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			var n2 := _edge_normal(a, b, r)
			var normal := Vector3(n2.x, 0, n2.y)
			st.set_normal(normal)
			var p0 := Vector3(a.x, y0, a.y)
			var p1 := Vector3(b.x, y0, b.y)
			var p2 := Vector3(b.x, y1, b.y)
			var p3 := Vector3(a.x, y1, a.y)
			_tri(st, p0, p1, p2, normal)
			_tri(st, p0, p2, p3, normal)
	if with_roof:
		st.set_color(ROOF)
		st.set_normal(Vector3.UP)
		var idx := Geometry2D.triangulate_polygon(_roof)
		for t in range(0, idx.size(), 3):
			_tri(st, Vector3(_roof[idx[t]].x, y1, _roof[idx[t]].y), Vector3(_roof[idx[t + 1]].x, y1, _roof[idx[t + 1]].y),
				Vector3(_roof[idx[t + 2]].x, y1, _roof[idx[t + 2]].y), Vector3.UP)
	return st.commit()


## Adds a triangle whose front face (clockwise in Godot) points along `facing`.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, facing: Vector3) -> void:
	if (b - a).cross(c - a).dot(facing) > 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _add_mesh(mesh: ArrayMesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	mi.material_override = m
	add_child(mi)
	return mi


## Windows every ~3.2 m on edges longer than 2.5 m, one floor band per floor.
func _add_windows(height: float, base: float, floors: int, floor_h: float, bays: Array) -> MultiMeshInstance3D:
	var xforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for r in _rings.size():
		var ring := _rings[r]
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			var length := a.distance_to(b)
			if length < 2.5:
				continue
			var dir := (b - a) / length
			var o2 := _edge_normal(a, b, r)
			var out := Vector3(o2.x, 0, o2.y)
			var x_axis := Vector3(dir.x, 0, dir.y)
			var count := maxi(1, int(length / 3.2))
			var step := length / count
			for f in floors:
				var y0 := base + f * floor_h
				if y0 + 2.2 > height:
					break
				for k in count:
					var p := a + dir * step * (k + 0.5)
					var near_bay := false
					for bay in bays:
						if p.distance_to(Vector2(bay[0], bay[1])) < BAY_CLEAR:
							near_bay = true
					if near_bay:
						continue
					var basis := Basis(x_axis * minf(1.3, step - 0.5), Vector3.UP * 1.4, out * 0.06)
					xforms.append(Transform3D(basis, Vector3(p.x, y0 + 1.6, p.y) + out * 0.04))   # 0.01..0.07 in front of the wall
					colors.append(WINDOW)
				if f > 0:
					var mid := (a + b) / 2.0
					var bb := Basis(x_axis * length, Vector3.UP * 0.15, out * 0.08)
					xforms.append(Transform3D(bb, Vector3(mid.x, y0, mid.y) + out * 0.05))   # 0.01..0.09 in front of the wall
					colors.append(BAND)
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	box.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = box
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi
