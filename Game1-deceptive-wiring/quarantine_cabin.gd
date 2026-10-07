extends Room

# Quarantine cabin: an airport-style queue. Barrier tapes force a slalom through the room,
# and in the middle lane sits a station (disinfect hands, take temperature, ...). The door
# the player came through stays shut for good, and the exit opens only once the station
# is used: no way back, only forward. Cabins A to D chain into each other; D's exit leads
# to the bridge (Level 0), so the whole quarantine loop drops the player back at the start
# and the rail trip has to be driven again.
# See docs/decisions/0017. Doors and texts are set per instance in world.tscn.

const DOOR_PLACEMENTS := {
	"top_left": {"position": Vector2(-380, -160), "rotation": PI / 2.0},
	"top_right": {"position": Vector2(380, -160), "rotation": PI / 2.0},
	"left": {"position": Vector2(-410, 0), "rotation": 0.0},
	"right": {"position": Vector2(410, 0), "rotation": 0.0},
}

@export_multiline var intro_text: String = ""
@export var station_label: String = "Hände desinfizieren"
@export_multiline var station_text: String = ""   # status after using the station
@export_enum("top_left", "left", "right", "top_right") var door_in_side: String = "left"
@export var door_in_target_room: int = -1
@export var door_in_spawn: Vector2 = Vector2.ZERO
@export_enum("top_left", "left", "right", "top_right") var door_out_side: String = "right"
@export var door_out_target_room: int = -1
@export var door_out_spawn: Vector2 = Vector2.ZERO

@onready var door_in: Area2D = $DoorIn
@onready var door_out: Area2D = $DoorOut
@onready var station: Area2D = $Station
@onready var station_label_node: Label = $Station/Label
@onready var title_label: Label = $TitleLabel

var station_done: bool = false
var is_near_station: bool = false


func _ready() -> void:
	title_label.text = room_title
	_place_door(door_in, door_in_side)
	door_in.target_room_id = door_in_target_room
	door_in.target_spawn = door_in_spawn
	_place_door(door_out, door_out_side)
	door_out.target_room_id = door_out_target_room
	door_out.target_spawn = door_out_spawn
	register_doors([door_in, door_out])  # door_in never opens, door_out once the station is done

	station_label_node.text = station_label
	station.body_entered.connect(_on_station_body_entered)
	station.body_exited.connect(_on_station_body_exited)


func _place_door(door: Area2D, side: String) -> void:
	var placement: Dictionary = DOOR_PLACEMENTS.get(side, DOOR_PLACEMENTS["left"])
	door.position = placement["position"]
	door.rotation = placement["rotation"]


func _on_enter(_from_room_id: int = -1) -> void:
	player.interact_pressed.connect(_on_player_interact)
	if station_done:
		set_status("%s: Station erledigt, der Ausgang ist offen." % room_title)
	else:
		set_status(intro_text)


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	player.hide_interaction_hint()
	is_near_station = false


# --- Station (mandatory, opens the exit) -----------------------------------

func _on_station_body_entered(body: Node2D) -> void:
	if body == player and not station_done:
		is_near_station = true
		player.show_interaction_hint("[E] %s" % station_label)


func _on_station_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_station = false
		player.hide_interaction_hint()


func _use_station() -> void:
	station_done = true
	is_near_station = false
	station.modulate = Color(0.5, 0.9, 0.6, 1.0)
	player.hide_interaction_hint()
	door_out.open()
	set_status(station_text)


func _on_player_interact() -> void:
	if is_near_station and not station_done:
		_use_station()
