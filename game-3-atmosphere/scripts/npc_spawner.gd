extends Node3D
## The named, talkable people outside (outside.tscn). Builds a walking graph
## from the footways in data/hka_site.json inside `area` (SitePaths.walk_graph)
## and puts every NPC with place "outside" from data/encounters.json on it as
## an Npc. NPCs walk from point to point and only turn back at dead ends.
## The many anonymous walkers are crowd.gd.

@export_file("*.json") var data_path := "res://data/hka_site.json"
## Map area (x, z) the NPCs stay in: around the path between the dorm houses.
@export var area := Rect2(-75.0, -135.0, 150.0, 180.0)

var _adj := {}   ## Vector2 -> Array of Vector2 (neighbours)


func _ready() -> void:
	var d := SitePaths.load_site(data_path)
	if d.is_empty():
		return
	_adj = SitePaths.walk_graph(d, area, SitePaths.WALK_KINDS)
	if _adj.is_empty():
		push_warning("NpcSpawner: no footways in area.")
		return
	var nodes: Array = _adj.keys()
	for info in Encounters.npcs_for("outside"):
		var npc := Npc.new()
		npc.name = "Npc_" + str(info["id"])
		npc.npc_id = info["id"]
		npc.walk_speed = randf_range(1.1, 1.5)
		npc.start_on_graph(self, nodes.pick_random())
		add_child(npc)


## Next point after `node`, not going back to `prev` unless it is a dead end.
func next_node(node: Vector2, prev: Vector2) -> Vector2:
	var options: Array = _adj.get(node, [])
	if options.is_empty():
		return node
	var forward := options.filter(func(n: Vector2) -> bool: return n != prev)
	return forward.pick_random() if not forward.is_empty() else prev
