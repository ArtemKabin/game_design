extends Room

# Level 2: Hangar, the final level. See docs/decisions/0020.
# A space shuttle waits here. E at the shuttle opens the launch-clearance panel (same
# idea as the wiring panel in Level 0): ground control gives three instructions by radio,
# each a real German double meaning (abheben, einstellen, aufgeben), and each step offers
# the two readings as buttons. The obvious reading fails with a short remark, the step
# stays open, and the launch window starts closing: a bar runs from 100 to 0 (like the
# oxygen in Level 0) until all three steps are done. At 0 it is game over, restart begins
# the clearance again. Three steps done, the shuttle is cleared; E again, the player
# boards, the shuttle leaves the ship, the end.

const STEPS := [
	{
		"radio": "Bodenkontrolle: \"Shuttle, hier Bodenkontrolle. Hebe ab.\" Neben dem Startknopf klingelt ein Telefon.",
		"options": ["Startknopf drücken", "Den Hörer abheben"],
		"correct": 1,
		"fail": "Fehlstart. Das Shuttle hüpft zehn Zentimeter und fällt zurück. Das Telefon klingelt immer noch.",
		"done": "Du hebst ab. Bodenkontrolle: \"Na endlich. Startcode kommt gleich. Stell vorher die Triebwerke ein.\"",
	},
	{
		"radio": "Bodenkontrolle: \"Stell die Triebwerke ein.\"",
		"options": ["Triebwerke abschalten", "Triebwerke justieren"],
		"correct": 0,
		"fail": "Du drehst an Schub und Mischung. Es wird heißer, nicht besser. Bodenkontrolle: \"EINSTELLEN habe ich gesagt. Nicht verstellen.\"",
		"done": "Triebwerke aus. Einstellen heißt aufhören. Betankung läuft. Bodenkontrolle: \"Gut. Und gib dein Gepäck auf.\"",
	},
	{
		"radio": "Bodenkontrolle: \"Gib dein Gepäck auf.\"",
		"options": ["Gepäck zurücklassen", "Gepäck am Schalter aufgeben"],
		"correct": 1,
		"fail": "Du lässt die Tasche stehen. Darin: der Startcode. Bodenkontrolle: \"AUFGEBEN. Wie am Flughafen.\"",
		"done": "Gepäck aufgegeben, Bordkarte in der Hand, Startcode auch. Shuttle startklar.",
	},
]

const WINDOW_TICK_SECONDS := 0.5
const WINDOW_LOSS_PER_TICK := 5.0  # 10 seconds from the first wrong answer to game over

@onready var shuttle: Node2D = $Shuttle
@onready var shuttle_area: Area2D = $Shuttle/InteractArea
@onready var entrance_door: Area2D = $EntranceDoor
# Room-specific UI (clearance panel, end screen). CanvasLayers ignore the room's
# visibility, so it is shown and hidden by hand when the player enters or leaves.
@onready var room_ui_layer: CanvasLayer = $CanvasLayer
@onready var window_bar: ProgressBar = $CanvasLayer/HUD/LaunchWindowBar
@onready var panel: Control = $CanvasLayer/ClearancePanel
@onready var radio_label: Label = $CanvasLayer/ClearancePanel/PanelContainer/VBoxContainer/RadioLabel
@onready var option_buttons: Array[Button] = [
	$CanvasLayer/ClearancePanel/PanelContainer/VBoxContainer/Options/Option1,
	$CanvasLayer/ClearancePanel/PanelContainer/VBoxContainer/Options/Option2,
]
@onready var close_button: Button = $CanvasLayer/ClearancePanel/PanelContainer/VBoxContainer/CloseButton
@onready var end_screen: Control = $CanvasLayer/EndScreen
@onready var end_button: Button = $CanvasLayer/EndScreen/PanelContainer/VBoxContainer/MenuButton

var step: int = 0
var is_near_shuttle: bool = false
var escaped: bool = false
var window_timer: Timer = null


func is_cleared() -> bool:
	return step >= STEPS.size()


func _ready() -> void:
	shuttle_area.body_entered.connect(_on_shuttle_body_entered)
	shuttle_area.body_exited.connect(_on_shuttle_body_exited)
	for i in option_buttons.size():
		option_buttons[i].pressed.connect(_on_option_pressed.bind(i))
	close_button.pressed.connect(_close_panel)
	end_button.pressed.connect(GameManager.go_to_main_menu)
	window_timer = Timer.new()
	window_timer.wait_time = WINDOW_TICK_SECONDS
	window_timer.timeout.connect(_on_window_tick)
	add_child(window_timer)
	# The hint popup (world) opens over the panel after three wrong answers; the window
	# waits while it is read and resumes with the next key press (see _input).
	GameManager.hint_triggered.connect(func(_text: String) -> void: window_timer.paused = true)
	register_doors([entrance_door])
	entrance_door.open(false)  # the player came in through it
	room_ui_layer.visible = false
	panel.visible = false
	end_screen.visible = false


func _on_enter(_from_room_id: int = -1) -> void:
	room_ui_layer.visible = true
	player.interact_pressed.connect(_on_player_interact)
	if is_cleared():
		set_status("HANGAR: Das Shuttle ist startklar. Einsteigen und weg hier.")
	else:
		set_status("HANGAR: Ein Shuttle. Der Weg raus. Die Bodenkontrolle gibt die Startfreigabe, Schritt für Schritt.")


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	player.hide_interaction_hint()
	panel.visible = false
	room_ui_layer.visible = false
	is_near_shuttle = false


func _on_restart() -> void:
	step = 0
	_reset_window()
	panel.visible = false
	player.set_movement_enabled(true)
	set_status("Die Startfreigabe beginnt von vorn. Die Bodenkontrolle meint es wie beim ersten Mal.")
	if is_near_shuttle:
		player.show_interaction_hint("[E] Startfreigabe einholen")


func _input(event: InputEvent) -> void:
	if not is_active or is_game_over:
		return
	# Escape closes the panel instead of opening the pause menu.
	if panel.visible and event.is_action_pressed("ui_cancel"):
		_close_panel()
		get_viewport().set_input_as_handled()
		return
	# After the hint popup closed, nothing has the focus: the next key press hands it
	# back to the panel and lets the launch window run on.
	if panel.visible and event is InputEventKey and event.pressed \
			and get_viewport().gui_get_focus_owner() == null:
		option_buttons[0].grab_focus()
		window_timer.paused = false
		get_viewport().set_input_as_handled()


# --- Launch window (the countdown after a wrong answer) --------------------

func _reset_window() -> void:
	window_timer.stop()
	window_timer.paused = false
	window_bar.value = 100.0


func _on_window_tick() -> void:
	window_bar.value -= WINDOW_LOSS_PER_TICK
	if window_bar.value <= 0.0:
		window_timer.stop()
		panel.visible = false
		player.hide_interaction_hint()
		GameManager.register_failure(room_id, "Startfenster verpasst.")
		game_over.emit("FEHLSTART", "Das Startfenster ist zu. Das Shuttle bleibt stehen. Die Bodenkontrolle fängt von vorn an.")


# --- Shuttle ----------------------------------------------------------------

func _on_shuttle_body_entered(body: Node2D) -> void:
	if body == player and not escaped:
		is_near_shuttle = true
		player.show_interaction_hint("[E] Einsteigen" if is_cleared() else "[E] Startfreigabe einholen")


func _on_shuttle_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_shuttle = false
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if not is_near_shuttle or is_game_over or escaped or panel.visible:
		return
	if is_cleared():
		_board_shuttle()
	else:
		_open_panel()


# --- Launch clearance panel -------------------------------------------------

func _open_panel() -> void:
	_show_step()
	panel.visible = true
	player.set_movement_enabled(false)
	option_buttons[0].grab_focus()


func _close_panel() -> void:
	panel.visible = false
	if not is_game_over:
		player.set_movement_enabled(true)


func _show_step() -> void:
	var data: Dictionary = STEPS[step]
	radio_label.text = data["radio"]
	for i in option_buttons.size():
		option_buttons[i].text = data["options"][i]


func _on_option_pressed(index: int) -> void:
	if is_game_over or is_cleared():
		return
	var data: Dictionary = STEPS[step]
	if index != data["correct"]:
		# The obvious reading: a remark, the step stays open, the launch window closes.
		var text: String = data["fail"]
		if window_timer.is_stopped():
			window_timer.start()
			text += " Das Startfenster schließt sich."
		GameManager.register_failure(room_id, "Startfreigabe: " + data["options"][index])
		set_status(text, true)
		option_buttons[0].grab_focus()
		return
	step += 1
	set_status(data["done"])
	if is_cleared():
		_reset_window()
		_close_panel()
		if is_near_shuttle:
			player.show_interaction_hint("[E] Einsteigen")
	else:
		_show_step()
		option_buttons[0].grab_focus()


# --- Escape -----------------------------------------------------------------

func _board_shuttle() -> void:
	escaped = true
	is_near_shuttle = false
	player.hide_interaction_hint()
	player.set_movement_enabled(false)
	player.visible = false
	GameManager.complete_level(room_id)
	set_status("Luke zu. Triebwerke an. Das Shuttle hebt ab. Diesmal wirklich.")
	var tween: Tween = create_tween()
	tween.tween_property(shuttle, "position", shuttle.position + Vector2(500, -700), 2.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(shuttle, "modulate:a", 0.0, 2.5)
	await tween.finished
	end_screen.visible = true
	end_button.grab_focus()
