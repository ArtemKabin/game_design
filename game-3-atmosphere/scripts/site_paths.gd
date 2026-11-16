class_name SitePaths
extends RefCounted
## Helpers for everything that moves on the site data (data/hka_site.json):
## loading it, joining roads into one line, the footway walking graph and the
## positions of everybody on foot (cars and bikes stop for them).

const WALK_KINDS := ["footway", "path", "pedestrian", "steps", "living_street"]


static func load_site(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Site data missing: " + path)
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


## Joins roads (indices into d["roads"]) end to end. A road is cut where the
## next one starts (so a chain can turn off a longer way) and turned around
## if needed.
static func chain(roads: Array, ids: PackedInt32Array) -> PackedVector2Array:
	var parts: Array[PackedVector2Array] = []
	for idx in ids:
		if idx < 0 or idx >= roads.size():
			continue
		var pts := PackedVector2Array()
		for v in roads[idx]["pts"]:
			pts.append(Vector2(v[0], v[1]))
		parts.append(pts)
	var line := PackedVector2Array()
	for i in parts.size():
		var pts := parts[i]
		if line.size() > 0 and line[line.size() - 1].distance_to(pts[pts.size() - 1]) < line[line.size() - 1].distance_to(pts[0]):
			pts.reverse()
		if i + 1 < parts.size():
			var nxt := parts[i + 1]
			for k in pts.size():
				if pts[k].distance_to(nxt[0]) < 0.5 or pts[k].distance_to(nxt[nxt.size() - 1]) < 0.5:
					pts = pts.slice(0, k + 1)
					break
		for p in pts:
			if line.size() == 0 or line[line.size() - 1].distance_to(p) > 0.5:
				line.append(p)
	return line


## Walking graph: Vector2 point -> Array of neighbour points, from the ways
## of `kinds` inside `area` (empty rect = whole map). Segments through a
## building are left out; only the largest connected part is returned.
static func walk_graph(d: Dictionary, area: Rect2, kinds: Array) -> Dictionary:
	var buildings: Array[PackedVector2Array] = []
	for b in d.get("buildings", []):
		if b.get("roof_only", false):
			continue
		var poly := PackedVector2Array()
		for v in b["poly"]:
			poly.append(Vector2(v[0], v[1]))
		buildings.append(poly)
	var adj := {}
	for r in d.get("roads", []):
		if not kinds.has(r["kind"]):
			continue
		var pts: Array = r["pts"]
		for k in range(1, pts.size()):
			var a := _key(pts[k - 1])
			var b := _key(pts[k])
			if a == b:
				continue
			if area.has_area() and not (area.has_point(a) and area.has_point(b)):
				continue
			var mid := (a + b) * 0.5
			var blocked := false
			for poly in buildings:
				if Geometry2D.is_point_in_polygon(mid, poly):
					blocked = true
					break
			if blocked:
				continue
			_link(adj, a, b)
			_link(adj, b, a)
	var seen := {}
	var best: Array = []
	for start in adj:
		if seen.has(start):
			continue
		var part: Array = [start]
		seen[start] = true
		var i := 0
		while i < part.size():
			for n in adj[part[i]]:
				if not seen.has(n):
					seen[n] = true
					part.append(n)
			i += 1
		if part.size() > best.size():
			best = part
	var out := {}
	for n in best:
		out[n] = adj[n]
	return out


## Positions of the player, the NPCs (group "pedestrians") and the campus
## crowd (nodes in group "crowd" with positions()).
static func pedestrian_positions(tree: SceneTree) -> PackedVector3Array:
	var out := PackedVector3Array()
	for group in ["player", "pedestrians"]:
		for n in tree.get_nodes_in_group(group):
			if n is Node3D:
				out.append((n as Node3D).global_position)
	for n in tree.get_nodes_in_group("crowd"):
		if n.has_method("positions"):
			out.append_array(n.positions())
	return out


## Distance to the nearest position in front of (dir = 1) or behind (dir = -1)
## a vehicle at `xf` (front = -Z) within `half_width` to the side, INF if none.
static func nearest_ahead(xf: Transform3D, positions: PackedVector3Array, dir: float, half_width: float) -> float:
	var best := INF
	var fwd := -xf.basis.z * dir
	var side := xf.basis.x
	for p in positions:
		var rel := p - xf.origin
		rel.y = 0.0
		var along := rel.dot(fwd)
		if along > 0.0 and along < best and absf(rel.dot(side)) < half_width:
			best = along
	return best


static func _key(v: Array) -> Vector2:
	return Vector2(snappedf(v[0], 0.1), snappedf(v[1], 0.1))


static func _link(adj: Dictionary, a: Vector2, b: Vector2) -> void:
	if not adj.has(a):
		adj[a] = []
	if not adj[a].has(b):
		adj[a].append(b)
