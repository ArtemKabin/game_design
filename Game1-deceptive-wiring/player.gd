extends CharacterBody2D

# 2.5D Player Controller with attached vision flashlight and E / F interaction keys
@export var speed: float = 220.0

@onready var light: PointLight2D = $PointLight2D
@onready var interact_label: Label = $InteractHintLabel

signal interact_pressed
signal hit_pressed

func _ready() -> void:
	if interact_label:
		interact_label.visible = false

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
		
	velocity = input_dir.normalized() * speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			emit_signal("interact_pressed")
		elif event.keycode == KEY_F:
			emit_signal("hit_pressed")

func show_interaction_hint(text: String) -> void:
	if interact_label:
		interact_label.text = text
		interact_label.visible = true

func hide_interaction_hint() -> void:
	if interact_label:
		interact_label.visible = false
