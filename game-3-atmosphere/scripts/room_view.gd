extends Node
## Autoload "RoomView": decides what the top-down camera shows.
## The zone (room) the player stands in is lit, every other zone is shaded.
## Occluders (cutaway walls, locked rooms, zone shades) that stand in front of
## the active zone, i.e. on the camera side (south, +z) within REACH, are cut
## down so they never hide the player.
##
## An occluder needs `occluder_rect() -> Rect2` (world x/z) and `set_cut(bool)`.

## A 2.6 m wall seen at 60° hides about 1.5 m behind it.
const REACH := 1.8
const X_MARGIN := 0.3

var active: Node = null
var _occluders: Array = []
var _zones: Array = []
var _inside: Array = []


func register_occluder(o: Node) -> void:
	if not _occluders.has(o):
		_occluders.append(o)
		o.set_cut(_should_cut(o))


func unregister_occluder(o: Node) -> void:
	_occluders.erase(o)


func register_zone(z: Node) -> void:
	if not _zones.has(z):
		_zones.append(z)
		z.set_lit(z == active)


func unregister_zone(z: Node) -> void:
	_zones.erase(z)
	_inside.erase(z)
	if z == active:
		active = null


func enter(z: Node) -> void:
	_inside.erase(z)
	_inside.append(z)
	_set_active(z)


## Leaving a zone switches to another zone the player still overlaps. In a
## doorway between two zones the last active one stays.
func exit(z: Node) -> void:
	_inside.erase(z)
	if z == active and not _inside.is_empty():
		_set_active(_inside.back())


func _set_active(z: Node) -> void:
	if z == active:
		return
	active = z
	for zone in _zones:
		zone.set_lit(zone == active)
	for o in _occluders:
		o.set_cut(_should_cut(o))


func _should_cut(o: Node) -> bool:
	if active == null or o == active:
		return false
	var a: Rect2 = active.occluder_rect()
	var r: Rect2 = o.occluder_rect()
	var front := a.end.y
	return r.position.y >= front - 0.05 and r.position.y <= front + REACH \
		and r.end.x > a.position.x - X_MARGIN and r.position.x < a.end.x + X_MARGIN
