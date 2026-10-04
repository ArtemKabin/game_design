extends CharacterBody2D

# Shared top-down player with flashlight. Instance res://player.tscn in every level.
# Movement and keys come from the Input Map in project.godot:
#   move_up / move_down / move_left / move_right (WASD + arrows), interact (E), hit (F)

signal interact_pressed
signal hit_pressed

@export var speed: float = 220.0

@onready var interact_label: Label = $InteractHintLabel


func _ready() -> void:
	interact_label.visible = false


func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_pressed.emit()
	elif event.is_action_pressed("hit"):
		hit_pressed.emit()


func show_interaction_hint(text: String) -> void:
	interact_label.text = text
	interact_label.visible = true


func hide_interaction_hint() -> void:
	interact_label.visible = false
