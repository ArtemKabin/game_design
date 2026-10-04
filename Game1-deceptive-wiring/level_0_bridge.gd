extends Node2D

# Level 0: Bridge / Central Hub (2.5D Exploration & Subversion)
# WASD: Walk | E: Open Interactive Cable Wiring Panel (Trap) | F: Hit Vent (Solution)

@onready var player: CharacterBody2D = $Player
@onready var room_emergency_light: PointLight2D = $RoomEmergencyLight
@onready var oxygen_timer: Timer = $OxygenTimer
@onready var flash_timer: Timer = $EmergencyFlashTimer
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var oxygen_bar: ProgressBar = $CanvasLayer/HUD/OxygenBar
@onready var continue_btn: Button = $CanvasLayer/HUD/ContinueButton
@onready var vent_area: Area2D = $WallVent

# Wiring Panel UI
@onready var wiring_panel_ui: Control = $CanvasLayer/WiringPanelUI
@onready var wire_green_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/WireGrid/WireGreenBtn
@onready var wire_red_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/WireGrid/WireRedBtn
@onready var wire_blue_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/WireGrid/WireBlueBtn
@onready var wire_orange_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/WireGrid/WireOrangeBtn
@onready var close_wiring_btn: Button = $CanvasLayer/WiringPanelUI/PanelContainer/VBoxContainer/CloseWiringBtn

# Game Over UI
@onready var game_over_ui: Control = $CanvasLayer/GameOverUI
@onready var restart_btn: Button = $CanvasLayer/GameOverUI/PanelContainer/MarginContainer/VBoxContainer/RestartButton

var is_near_vent: bool = false
var is_trap_active: bool = false
var current_oxygen: float = 100.0
var max_oxygen: float = 100.0
var is_solved: bool = false

func _ready() -> void:
	current_oxygen = max_oxygen
	oxygen_bar.value = current_oxygen
	if wiring_panel_ui:
		wiring_panel_ui.visible = false
	if game_over_ui:
		game_over_ui.visible = false
	
	flash_timer.wait_time = 1.0
	flash_timer.timeout.connect(_on_room_flash_tick)
	flash_timer.start()
	
	oxygen_timer.wait_time = 0.4
	oxygen_timer.timeout.connect(_on_oxygen_tick)
	
	if vent_area:
		vent_area.body_entered.connect(_on_vent_body_entered)
		vent_area.body_exited.connect(_on_vent_body_exited)
		
	if player:
		player.interact_pressed.connect(_on_player_interact)
		player.hit_pressed.connect(_on_player_hit)
		
	# Wire buttons connection
	if wire_green_btn: wire_green_btn.pressed.connect(func(): _on_wire_clicked("Grünes Kabel"))
	if wire_red_btn: wire_red_btn.pressed.connect(func(): _on_wire_clicked("Rotes Kabel"))
	if wire_blue_btn: wire_blue_btn.pressed.connect(func(): _on_wire_clicked("Blaues Kabel"))
	if wire_orange_btn: wire_orange_btn.pressed.connect(func(): _on_wire_clicked("Orangefarbenes Kabel"))
	if close_wiring_btn: close_wiring_btn.pressed.connect(_on_close_wiring_pressed)
	
	# Restart button connection
	if restart_btn:
		restart_btn.pressed.connect(restart_level)

	# Back to the ship map after solving the level
	if continue_btn:
		continue_btn.visible = false
		continue_btn.pressed.connect(GameManager.go_to_map)

	status_label.text = "SYSTEMFEHLER: Sauerstoffzufuhr instabil. Gehe zur Lüftung!"

func _unhandled_input(event: InputEvent) -> void:
	if game_over_ui and game_over_ui.visible:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
			restart_level()

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
		player.show_interaction_hint("[E] Kabel-Schaltkasten öffnen   |   [F] Gegen Lüftung schlagen!")

func _on_vent_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_vent = false
		player.hide_interaction_hint()

func _on_player_interact() -> void:
	if is_solved or (game_over_ui and game_over_ui.visible):
		return
	if is_near_vent or (wiring_panel_ui and wiring_panel_ui.visible):
		open_wiring_panel()

func _on_player_hit() -> void:
	if is_solved or (game_over_ui and game_over_ui.visible):
		return
	if is_near_vent or (wiring_panel_ui and wiring_panel_ui.visible):
		perform_vent_hit()
	else:
		status_label.text = "Du schlägst in die Luft... Gehe nah an die Lüftung heran!"

func open_wiring_panel() -> void:
	if is_solved:
		return
	wiring_panel_ui.visible = true

func _on_wire_clicked(wire_name: String) -> void:
	if is_solved:
		return
	trigger_trap(wire_name + " verbunden: Notabschaltung ausgelöst!")

func trigger_trap(reason: String) -> void:
	if is_trap_active or is_solved:
		return
	is_trap_active = true
	room_emergency_light.color = Color(1.0, 0.1, 0.1)
	status_label.text = "GEFAHR! " + reason
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
	status_label.text = "💀 KRITISCHER SAUERSTOFFVERLUST: GAME OVER."
	_get_game_manager().register_failure(0, "Sauerstoffmangel durch Präzisionsverkabelung.")
	
	if player:
		player.set_physics_process(false)
		player.hide_interaction_hint()
		
	wiring_panel_ui.visible = false
	if game_over_ui:
		game_over_ui.visible = true

func restart_level() -> void:
	get_tree().reload_current_scene()

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
	status_label.text = "ERFOLG: Schlag [F] gegen die Lüftung hat das Ventil gelöst! Level 0 gelöst!"
	_get_game_manager().complete_level(0)
	if continue_btn:
		continue_btn.visible = true

func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func _on_close_wiring_pressed() -> void:
	wiring_panel_ui.visible = false
