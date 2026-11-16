class_name PolyPath
extends RefCounted
## Polyline on the map (x/z as Vector2) with arc-length lookups. Used for car
## lanes, aisles, manoeuvre curves (traffic.gd) and the bike lanes (bikes.gd).

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


func distance_to(p: Vector2) -> float:
	return point_at(closest_s(p)).distance_to(p)


## Arc length of the point of the path closest to p.
func closest_s(p: Vector2) -> float:
	var best := INF
	var best_s := 0.0
	for i in range(1, pts.size()):
		var q := Geometry2D.get_closest_point_to_segment(p, pts[i - 1], pts[i])
		var d := q.distance_to(p)
		if d < best:
			best = d
			best_s = cum[i - 1] + pts[i - 1].distance_to(q)
	return best_s


## Right of a direction on the map (north up, +z = south).
static func right_of(dir: Vector2) -> Vector2:
	return Vector2(-dir.y, dir.x)


## The line shifted `dist` metres to the right (right-hand traffic lanes).
static func offset(line: PackedVector2Array, dist: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in line.size():
		var t := Vector2.ZERO
		if i > 0:
			t += (line[i] - line[i - 1]).normalized()
		if i < line.size() - 1:
			t += (line[i + 1] - line[i]).normalized()
		out.append(line[i] + right_of(t.normalized()) * dist)
	return out


static func reversed(line: PackedVector2Array) -> PackedVector2Array:
	var r := line.duplicate()
	r.reverse()
	return r


static func bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, steps := 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		var u := 1.0 - t
		out.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	return out
