extends Control

# Ship map with Fog of War. Rooms light up as GameManager unlocks them.
# Progress goes LEFT on purpose, see README "Left-to-Right Subversion".

const ROOM_NAMES := {0: "Brücke", 1: "Frachtraum", 2: "Finale"}

@onready var level_buttons: Dictionary = {
	0: $RoomNodes/Level0_Bridge_Btn,
	1: $RoomNodes/Level1_CargoBay_Btn,
	2: $RoomNodes/Level2_Final_Btn,
}
@onready var path_0_to_1: Line2D = $Paths/Path0to1
@onready var path_1_to_2: Line2D = $Paths/Path1to2
@onready var hint_label: Label = $HintLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	for level_id in level_buttons:
		level_buttons[level_id].pressed.connect(_on_room_pressed.bind(level_id))
	back_button.pressed.connect(GameManager.go_to_main_menu)
	update_fog_of_war()


func update_fog_of_war() -> void:
	for level_id in level_buttons:
		_set_room_button_state(level_buttons[level_id], level_id, GameManager.get_level_state(level_id))
	# Paths are only drawn once the room they lead to is out of the fog.
	path_0_to_1.visible = GameManager.get_level_state(1) != GameManager.LevelState.LOCKED
	path_1_to_2.visible = GameManager.get_level_state(2) != GameManager.LevelState.LOCKED


func _set_room_button_state(btn: Button, level_id: int, state: GameManager.LevelState) -> void:
	match state:
		GameManager.LevelState.LOCKED:
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.4, 0.5)
			btn.text = "???\n[VERBORGEN]"
		GameManager.LevelState.UNLOCKED:
			btn.disabled = false
			btn.modulate = Color(0.9, 0.9, 1.0, 1.0)
			btn.text = "LEVEL %d\n%s" % [level_id, ROOM_NAMES[level_id]]
		GameManager.LevelState.COMPLETED:
			btn.disabled = false
			btn.modulate = Color(0.4, 1.0, 0.5, 1.0)
			btn.text = "LEVEL %d ✔\n%s" % [level_id, ROOM_NAMES[level_id]]


func _on_room_pressed(level_id: int) -> void:
	if not GameManager.has_level_scene(level_id):
		hint_label.text = "Level %d ist noch nicht gebaut." % level_id
		return
	GameManager.start_level(level_id)
