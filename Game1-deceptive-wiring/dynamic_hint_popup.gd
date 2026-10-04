extends Control

# Dynamic Sci-Fi Terminal Hint Pop-up ("Hinweis Terminal")
@onready var popup_panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var hint_text_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HintTextLabel
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	visible = false
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("hint_triggered"):
		gm.connect("hint_triggered", _on_hint_triggered)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _on_hint_triggered(hint_text: String) -> void:
	hint_text_label.text = hint_text
	visible = true
	popup_panel.pivot_offset = popup_panel.size / 2.0
	popup_panel.scale = Vector2(0.8, 0.8)
	var tween: Tween = create_tween()
	tween.tween_property(popup_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_close_pressed() -> void:
	visible = false
