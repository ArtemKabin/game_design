extends Control

# MapUI: Manages void background (#0a2041), Fog of War room unlocking, and Level transitions.
@onready var void_bg: ColorRect = $BackgroundVoid
@onready var room_nodes_container: Control = $RoomNodes
@onready var level_0_button: Button = $RoomNodes/Level0_Bridge_Btn
@onready var level_1_button: Button = $RoomNodes/Level1_CargoBay_Btn
@onready var level_2_button: Button = $RoomNodes/Level2_EngineRoom_Btn
@onready var level_3_button: Button = $RoomNodes/Level3_Security_Btn
@onready var level_4_button: Button = $RoomNodes/Level4_Reactor_Btn
@onready var level_5_button: Button = $RoomNodes/Level5_Finale_Btn

func _ready() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("level_completed"):
		gm.connect("level_completed", _on_level_completed)
	update_fog_of_war()

func update_fog_of_war() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if not gm:
		return
		
	var states: Dictionary = gm.level_states
	# Level 0 is always visible in the center
	_set_room_button_state(level_0_button, states.get(0, 1))
	_set_room_button_state(level_1_button, states.get(1, 0))
	_set_room_button_state(level_2_button, states.get(2, 0))
	_set_room_button_state(level_3_button, states.get(3, 0))
	_set_room_button_state(level_4_button, states.get(4, 0))
	_set_room_button_state(level_5_button, states.get(5, 0))

func _set_room_button_state(btn: Button, state: int) -> void:
	if not btn:
		return
	match state:
		0: # LOCKED (Fog of War)
			btn.disabled = true
			btn.modulate = Color(0.1, 0.1, 0.15, 0.4)
			btn.text = "??? [VERBOUNGEN]"
		1: # UNLOCKED
			btn.disabled = false
			btn.modulate = Color(0.9, 0.9, 1.0, 1.0)
		2: # COMPLETED
			btn.disabled = false
			btn.modulate = Color(0.4, 1.0, 0.5, 1.0)

func _on_level_completed(_level_id: int) -> void:
	update_fog_of_war()
