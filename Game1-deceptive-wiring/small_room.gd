extends Room

# Small side room: the quarantine cabins A-D and the storage room. See docs/decisions/0015.
# Two doors (DoorIn at the top, DoorOut on the right), both open from the start, and an
# optional pickup. Where the doors lead is set per instance in world.tscn via the exports
# below, so one scene serves every cabin and the storage room.

@export_multiline var intro_text: String = ""
# Shown from the second visit on (the cabins loop back to A). Empty = always intro_text.
@export_multiline var loop_text: String = ""
@export var pickup_item: String = ""     # inventory id, "" = no pickup in this room
@export var pickup_label: String = ""    # shown on the hint and in the room
@export_multiline var pickup_text: String = ""
@export var door_in_target_room: int = -1
@export var door_in_spawn: Vector2 = Vector2.ZERO
@export var door_out_enabled: bool = true
@export var door_out_target_room: int = -1
@export var door_out_spawn: Vector2 = Vector2.ZERO

@onready var door_in: Area2D = $DoorIn
@onready var door_out: Area2D = $DoorOut
@onready var pickup: Area2D = $Pickup
@onready var pickup_label_node: Label = $Pickup/Label
@onready var title_label: Label = $TitleLabel

var visits: int = 0
var is_near_pickup: bool = false


func _ready() -> void:
	title_label.text = room_title
	door_in.target_room_id = door_in_target_room
	door_in.target_spawn = door_in_spawn
	door_in.open(false)
	door_out.target_room_id = door_out_target_room
	door_out.target_spawn = door_out_spawn
	if door_out_enabled:
		door_out.open(false)
	else:
		door_out.visible = false
	register_doors([door_in, door_out])

	if pickup_item == "" or GameManager.has_item(pickup_item):
		pickup.visible = false
		pickup.monitoring = false
	else:
		pickup_label_node.text = pickup_label
		pickup.body_entered.connect(_on_pickup_body_entered)
		pickup.body_exited.connect(_on_pickup_body_exited)


func _on_enter() -> void:
	visits += 1
	player.interact_pressed.connect(_on_player_interact)
	if visits > 1 and loop_text != "":
		set_status(loop_text)
	else:
		set_status(intro_text)


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	player.hide_interaction_hint()
	is_near_pickup = false


func _on_pickup_body_entered(body: Node2D) -> void:
	if body == player and pickup.visible:
		is_near_pickup = true
		player.show_interaction_hint("[E] %s nehmen" % pickup_label)


func _on_pickup_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_pickup = false
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if not is_near_pickup or not pickup.visible:
		return
	GameManager.add_item(pickup_item)
	pickup.visible = false
	pickup.set_deferred("monitoring", false)
	is_near_pickup = false
	player.hide_interaction_hint()
	set_status(pickup_text)
