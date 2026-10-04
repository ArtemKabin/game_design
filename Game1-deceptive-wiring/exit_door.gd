extends Area2D

# Door at the edge of a room. Instance res://exit_door.tscn.
# Closed and inert until open() is called. Once open, the door leaf slides up,
# the glow comes on and the player walking into it fires player_entered.
# The world then teleports the player to target_room_id at target_spawn (room-local).
# target_room_id < 0 means "leads nowhere yet": the world only shows blocked_message.

signal player_entered

@export var target_room_id: int = -1
@export var target_spawn: Vector2 = Vector2.ZERO
@export var blocked_message: String = "Hier geht es noch nicht weiter."

@onready var door_leaf: ColorRect = $DoorLeaf
@onready var glow: PointLight2D = $Glow
@onready var label: Label = $Label

var is_open: bool = false


func _ready() -> void:
	monitoring = false
	label.visible = false
	glow.energy = 0.0
	body_entered.connect(_on_body_entered)


func open(animated: bool = true) -> void:
	if is_open:
		return
	is_open = true
	label.visible = true
	if not animated:
		door_leaf.position.y -= 128.0
		glow.energy = 1.6
		monitoring = true
		return
	var tween: Tween = create_tween()
	tween.tween_property(door_leaf, "position:y", door_leaf.position.y - 128.0, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(glow, "energy", 1.6, 0.6)
	tween.tween_callback(func() -> void: monitoring = true)


func _on_body_entered(body: Node2D) -> void:
	# Only the player on foot. The heavy cart is a CharacterBody2D too and must not count.
	if is_open and body.is_in_group("player"):
		player_entered.emit()
