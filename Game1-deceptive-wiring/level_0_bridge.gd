extends Room

# Level 0: Bridge / Central Hub. Tutorial room, start of the game.
# WASD: Walk | E: Open the cable wiring panel (the trap) | F: Hit the vent (the solution)
# Left door -> cargo rail corridor (room 10) -> Level 1. The right door opens once
# Level 1 is solved and will lead to Level 2 (not built yet).

const START_SPAWN := Vector2(0, 150)

@onready var room_emergency_light: PointLight2D = $RoomEmergencyLight
@onready var oxygen_timer: Timer = $OxygenTimer
@onready var flash_timer: Timer = $EmergencyFlashTimer
@onready var vent_area: Area2D = $WallVent
@onready var exit_door_left: Area2D = $ExitDoor
@onready var exit_door_right: Area2D = $ExitDoorRight
@onready var oxygen_bar: ProgressBar = $CanvasLayer/HUD/OxygenBar
# Room-specific UI (oxygen bar, wiring panel). CanvasLayers ignore the room's visibility,
# so it is shown and hidden by hand when the player enters or leaves.
@onready var room_ui_layer: CanvasLayer = $CanvasLayer

# Wiring Panel UI (the trap)
@onready var wiring_panel_ui: Control = $CanvasLayer/WiringPanelUI
@onready var wire_green_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/WireGrid/WireGreenBtn
@onready var wire_red_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/WireGrid/WireRedBtn
@onready var wire_blue_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/WireGrid/WireBlueBtn
@onready var wire_orange_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/WireGrid/WireOrangeBtn
@onready var close_wiring_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/CloseWiringBtn

var is_near_vent: bool = false
var is_trap_active: bool = false
var current_oxygen: float = 100.0
var max_oxygen: float = 100.0
var is_solved: bool = false


func _ready() -> void:
	flash_timer.wait_time = 1.0
	flash_timer.timeout.connect(_on_room_flash_tick)
	oxygen_timer.wait_time = 0.4
	oxygen_timer.timeout.connect(_on_oxygen_tick)

	vent_area.body_entered.connect(_on_vent_body_entered)
	vent_area.body_exited.connect(_on_vent_body_exited)

	wire_green_btn.pressed.connect(func() -> void: _on_wire_clicked("Grünes Kabel"))
	wire_red_btn.pressed.connect(func() -> void: _on_wire_clicked("Rotes Kabel"))
	wire_blue_btn.pressed.connect(func() -> void: _on_wire_clicked("Blaues Kabel"))
	wire_orange_btn.pressed.connect(func() -> void: _on_wire_clicked("Orangefarbenes Kabel"))
	close_wiring_btn.pressed.connect(_on_close_wiring_pressed)

	register_doors([exit_door_left, exit_door_right])
	GameManager.level_completed.connect(_on_level_completed)
	room_ui_layer.visible = false
	_reset_state()


func _on_enter() -> void:
	room_ui_layer.visible = true
	player.interact_pressed.connect(_on_player_interact)
	player.hit_pressed.connect(_on_player_hit)
	if not is_solved:
		set_status("SYSTEMFEHLER: Sauerstoffzufuhr instabil. Gehe zur Lüftung!")
	elif exit_door_right.is_open:
		set_status("Brücke. Die Tür rechts ist offen.")
	else:
		set_status("Brücke. Die Tür links führt zur Frachtschiene.")


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	player.hit_pressed.disconnect(_on_player_hit)
	player.hide_interaction_hint()
	wiring_panel_ui.visible = false
	room_ui_layer.visible = false
	is_near_vent = false


func _on_restart() -> void:
	_reset_state()
	player.global_position = to_global(START_SPAWN)
	player.set_movement_enabled(true)
	set_status("SYSTEMFEHLER: Sauerstoffzufuhr instabil. Gehe zur Lüftung!")


func _reset_state() -> void:
	current_oxygen = max_oxygen
	oxygen_bar.value = current_oxygen
	is_trap_active = false
	wiring_panel_ui.visible = false
	oxygen_timer.stop()
	room_emergency_light.color = Color(1.0, 0.2, 0.2)
	if not is_solved:
		flash_timer.start()


func _input(event: InputEvent) -> void:
	# F (hit) is checked before the GUI gets the event. F is also bound to
	# ui_accept for menus, so without this a focused wire button would swallow
	# the hit and connect a wire instead. Hitting the vent must always work,
	# even while the wiring panel is open. That is the whole puzzle.
	if not is_active or is_game_over or is_solved:
		return
	if event.is_action_pressed("hit") and (is_near_vent or wiring_panel_ui.visible):
		perform_vent_hit()
		get_viewport().set_input_as_handled()


func _on_room_flash_tick() -> void:
	if is_solved:
		return
	var tween: Tween = create_tween()
	if is_trap_active:
		tween.tween_property(room_emergency_light, "energy", 2.8, 0.2)
		tween.tween_property(room_emergency_light, "energy", 0.2, 0.2)
	else:
		tween.tween_property(room_emergency_light, "energy", 1.8, 0.4)
		tween.tween_property(room_emergency_light, "energy", 0.5, 0.6)


func _on_vent_body_entered(body: Node2D) -> void:
	if body == player and not is_solved:
		is_near_vent = true
		# Only the trap is advertised. Hitting the vent (F) is the part the player must figure out.
		player.show_interaction_hint("[E] Kabel-Schaltkasten öffnen")


func _on_vent_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_vent = false
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if is_solved or is_game_over:
		return
	if is_near_vent or wiring_panel_ui.visible:
		open_wiring_panel()


func _on_player_hit() -> void:
	if is_solved or is_game_over:
		return
	if is_near_vent or wiring_panel_ui.visible:
		perform_vent_hit()
	else:
		set_status("Du schlägst in die Luft... Gehe nah an die Lüftung heran!")


func open_wiring_panel() -> void:
	wiring_panel_ui.visible = true
	wire_green_btn.grab_focus()


func _on_wire_clicked(wire_name: String) -> void:
	if is_solved:
		return
	trigger_trap(wire_name + " verbunden: Notabschaltung ausgelöst!")


func trigger_trap(reason: String) -> void:
	if is_trap_active or is_solved:
		return
	is_trap_active = true
	room_emergency_light.color = Color(1.0, 0.1, 0.1)
	set_status("GEFAHR! " + reason)
	oxygen_timer.start()


func _on_oxygen_tick() -> void:
	if is_solved:
		return
	current_oxygen -= 10.0
	oxygen_bar.value = current_oxygen
	if current_oxygen <= 0:
		oxygen_timer.stop()
		trigger_game_over()


func trigger_game_over() -> void:
	set_status("💀 KRITISCHER SAUERSTOFFVERLUST: GAME OVER.")
	GameManager.register_failure(room_id, "Sauerstoffmangel durch Präzisionsverkabelung.")
	player.set_movement_enabled(false)
	player.hide_interaction_hint()
	wiring_panel_ui.visible = false
	game_over.emit("💀 GAME OVER — SAUERSTOFFMANGEL",
		"Die Notabschaltung wurde ausgelöst. Lebenserhaltung kollabiert.")


func perform_vent_hit() -> void:
	if is_solved:
		return
	is_solved = true
	is_trap_active = false
	oxygen_timer.stop()
	flash_timer.stop()
	wiring_panel_ui.visible = false
	current_oxygen = max_oxygen
	oxygen_bar.value = current_oxygen

	var tween: Tween = create_tween()
	tween.tween_property(room_emergency_light, "color", Color(0.2, 1.0, 0.6), 0.5)
	tween.tween_property(room_emergency_light, "energy", 1.5, 0.5)

	player.hide_interaction_hint()
	set_status("ERFOLG: Schlag [F] gegen die Lüftung hat das Ventil gelöst! Level 0 gelöst!")
	GameManager.complete_level(0)
	_open_exit()


func _open_exit() -> void:
	player.set_movement_enabled(false)
	exit_door_left.open()
	await player.pan_camera_to(exit_door_left.global_position)
	set_status("Eine Tür hat sich geöffnet. Links, am Rand des Raums.")
	player.set_movement_enabled(true)


func _on_level_completed(level_id: int) -> void:
	if level_id == 1 and not exit_door_right.is_open:
		exit_door_right.open()
		if is_active:
			set_status("Rechts hat sich eine Tür geöffnet.")


func _on_close_wiring_pressed() -> void:
	wiring_panel_ui.visible = false
