extends Node2D

# Main menu. Start opens the ship map, which then loads the levels.
# Button signals are connected in main_menu.tscn.


func _on_start_button_pressed() -> void:
	GameManager.go_to_map()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
