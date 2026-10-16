extends Node2D

# Main menu. Start loads the ship (world.tscn); the player begins on the bridge (Level 0).
# Button signals are connected in main_menu.tscn. Keyboard navigation comes
# from Godot's focus system: W/S (ui_up/ui_down) move, Enter/Space/E/F accept.

@onready var start_button: Button = $GraphFrame/VBoxContainer/StartButton


func _ready() -> void:
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	GameManager.go_to_world()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
