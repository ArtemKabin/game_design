extends Control

# Played between two levels. PLACEHOLDER: the actual minigame is still being designed.
# GameManager.pending_level holds the level that comes after this transition.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton


func _ready() -> void:
	title_label.text = "ÜBERGANG → LEVEL %d" % GameManager.pending_level
	continue_button.pressed.connect(GameManager.continue_after_transition)
	continue_button.grab_focus()
