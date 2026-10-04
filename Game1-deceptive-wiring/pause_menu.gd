extends Control

# Pause menu, toggled with Escape (ui_cancel). Pauses the game while open.
# "Neu starten" restarts the whole ship from the bridge: the way out of a dead end
# (Level 1's tarp gap is one on purpose, see docs/decisions/0015).

@onready var resume_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var menu_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MenuButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	elif not get_tree().paused:  # something else (the map) is not already pausing
		open()


func open() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.restart_game()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to_main_menu()
