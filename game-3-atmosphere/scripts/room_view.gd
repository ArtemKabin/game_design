extends Node
## Autoload "RoomView": decides what the top-down camera shows.
## Indoors: the zone (room) the player stands in is lit, every other zone is
## shaded, and occluders (cutaway walls, locked rooms, zone shades) that stand
## in front of the active zone (camera side, south, +z) are cut down.
## Outdoors (no zones): occluders such as buildings are cut down while the
## player stands right behind (north of) them.
##
## An occluder needs `occluder_rect() -> Rect2` (world x/z) and `set_cut(bool)`.
## It may define `cut_reach` (metres behind it that it can hide; default REACH).

## A 2.6 m wall seen at 60° hides about 1.5 m behind it.
const REACH := 1.8
const X_MARGIN := 0.3
const PLAYER_HALF := 0.3

var active: Node = null
var _occluders: Array = []
var _zones: Array = []
var _inside: Array = []
var _last_player_pos := Vector3(INF, 0, INF)


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


## Outdoors there is no zone: follow the player's position instead.
func _physics_process(_delta: float) -> void:
	if active != null or _occluders.is_empty():
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var pos := player.global_position
	if pos.distance_to(_last_player_pos) < 0.2:
		return
	_last_player_pos = pos
	_refresh()


func _set_active(z: Node) -> void:
	if z == active:
		return
	active = z
	for zone in _zones:
		zone.set_lit(zone == active)
	_refresh()


func _refresh() -> void:
	for o in _occluders:
		o.set_cut(_should_cut(o))


## The area that must stay visible: the active zone, or outdoors the player.
func _view_rect() -> Variant:
	if active != null:
		return active.occluder_rect()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var p := player.global_position
		return Rect2(p.x - PLAYER_HALF, p.z - PLAYER_HALF, PLAYER_HALF * 2.0, PLAYER_HALF * 2.0)
	return null


func _should_cut(o: Node) -> bool:
	if o == active:
		return false
	var view = _view_rect()
	if view == null:
		return false
	var a: Rect2 = view
	var r: Rect2 = o.occluder_rect()
	var reach = o.get("cut_reach")
	if reach == null:
		reach = REACH
	var front := a.end.y
	return r.position.y >= front - 0.05 and r.position.y <= front + reach \
		and r.end.x > a.position.x - X_MARGIN and r.position.x < a.end.x + X_MARGIN
