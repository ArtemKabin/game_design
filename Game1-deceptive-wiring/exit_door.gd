extends Area2D

# Exit of a room. Instance res://exit_door.tscn at the room edge.
# Closed and inert until open() is called. Once open, the door leaf slides up,
# the glow comes on and the player walking into it fires player_entered.

signal player_entered

@onready var door_leaf: ColorRect = $DoorLeaf
@onready var glow: PointLight2D = $Glow
@onready var label: Label = $Label

var is_open: bool = false


func _ready() -> void:
	monitoring = false
	label.visible = false
	glow.energy = 0.0
	body_entered.connect(_on_body_entered)


func open() -> void:
	if is_open:
		return
	is_open = true
	label.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(door_leaf, "position:y", door_leaf.position.y - 128.0, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(glow, "energy", 1.6, 0.6)
	tween.tween_callback(func() -> void: monitoring = true)


func _on_body_entered(body: Node2D) -> void:
	if is_open and body is CharacterBody2D:
		player_entered.emit()
