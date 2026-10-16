extends Node2D

# The whole ship as one scene. Rooms are children of $Rooms and extend Room (room.gd).
# The world owns the player, the HUD, the game-over panel, the hint popup and the map
# overlay. Rooms the player has not reached yet are invisible (fog of war); rooms the
# player left are greyed out. Walking into an open ExitDoor teleports the player to the
# door's target room; the camera limits switch and the camera glides over.

const START_ROOM_ID := 0
const START_SPAWN := Vector2(0, 150)
# Status texts type in letter by letter and then stay long enough to be read before the
# next one replaces them. Only the newest waiting text is kept.
const STATUS_CHARS_PER_SECOND := 45.0
const STATUS_READ_SECONDS_MIN := 2.0
const STATUS_READ_SECONDS_PER_CHAR := 0.03

@onready var player: CharacterBody2D = $Player
@onready var rooms_node: Node2D = $Rooms
@onready var header_label: Label = $CanvasLayer/HUD/HeaderLabel
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var controls_label: Label = $CanvasLayer/HUD/ControlsGuideLabel
@onready var game_over_ui: Control = $CanvasLayer/GameOverUI
@onready var hint_popup: Control = $CanvasLayer/DynamicHintPopup
@onready var map_overlay: Control = $CanvasLayer/MapOverlay

var current_room: Room = null
var status_pending: String = ""
var status_busy: bool = false
var status_generation: int = 0  # bumped by an instant text to cut a running type-in short


func _ready() -> void:
	controls_label.text = GameManager.CONTROLS_TEXT
	for room in rooms_node.get_children():
		room.visible = false
		room.status_changed.connect(_on_room_status_changed)
		room.game_over.connect(_on_room_game_over)
		room.door_entered.connect(_on_room_door_entered)
	game_over_ui.restart_requested.connect(_on_restart_requested)
	hint_popup.visibility_changed.connect(_on_hint_popup_visibility_changed)
	map_overlay.setup(rooms_node.get_children())
	_enter_room(_room_by_id(START_ROOM_ID), START_SPAWN)


func _room_by_id(room_id: int) -> Room:
	for room in rooms_node.get_children():
		if room.room_id == room_id:
			return room
	return null


func _enter_room(room: Room, local_spawn: Vector2) -> void:
	var from_room_id: int = -1
	if current_room:
		from_room_id = current_room.room_id
		current_room.leave()
	current_room = room
	player.global_position = room.to_global(local_spawn)
	player.set_movement_enabled(true)
	room.enter(player, from_room_id)
	header_label.text = room.room_title
	GameManager.current_level = room.room_id
	map_overlay.set_current(room)


func _on_room_door_entered(door: Area2D) -> void:
	if door.target_room_id < 0:
		_on_room_status_changed(door.blocked_message)
		return
	var target: Room = _room_by_id(door.target_room_id)
	if target == null:
		push_warning("World: no room with id %d" % door.target_room_id)
		return
	_enter_room(target, door.target_spawn)


func _on_room_status_changed(text: String, instant: bool = false) -> void:
	if instant:
		status_pending = ""
		status_generation += 1
		status_label.text = text
		status_label.visible_characters = -1
		return
	if text == status_label.text and not status_busy:
		return
	status_pending = text
	if not status_busy:
		_play_status_queue()


func _play_status_queue() -> void:
	status_busy = true
	while status_pending != "":
		var text: String = status_pending
		var generation: int = status_generation
		status_pending = ""
		status_label.text = text
		status_label.visible_characters = 0
		while status_label.visible_characters < text.length():
			await get_tree().create_timer(1.0 / STATUS_CHARS_PER_SECOND).timeout
			if status_generation != generation:
				break  # an instant text took over
			status_label.visible_characters += 1
		if status_generation != generation:
			continue
		await get_tree().create_timer(STATUS_READ_SECONDS_MIN + text.length() * STATUS_READ_SECONDS_PER_CHAR).timeout
	status_busy = false


func _on_room_game_over(title: String, subtitle: String) -> void:
	current_room.is_game_over = true
	game_over_ui.show_game_over(title, subtitle)
	# A hint popup opened by the same failure keeps the focus until it is closed.
	if hint_popup.visible:
		hint_popup.close_button.grab_focus()


func _on_restart_requested() -> void:
	game_over_ui.visible = false
	current_room.is_game_over = false
	current_room.restart()


func _on_hint_popup_visibility_changed() -> void:
	if not hint_popup.visible and game_over_ui.visible:
		game_over_ui.restart_button.grab_focus()
