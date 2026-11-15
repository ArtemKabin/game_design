class_name Interactable
extends Area3D
## A place on campus where the player can do something with E.
## Every action costs time and changes stats (see GameState.do_action).

@export var title := "Aktion"
@export var minutes := 30
@export var d_energy := 0.0
@export var d_satiety := 0.0
@export var d_readiness := 0.0
@export var d_stress := 0.0
@export var d_money := 0.0
## Radius of the trigger zone in metres (only used if no shape child exists).
@export var radius := 1.5
## Optional text shown instead of "title (n min)" after the action.
@export var note := ""


func _ready() -> void:
	if not _has_shape():
		var col := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = radius
		col.shape = sphere
		col.position.y = 1.0
		add_child(col)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func prompt() -> String:
	var parts: PackedStringArray = ["[E] " + title]
	if minutes > 0:
		parts.append("%d min" % minutes)
	if d_money != 0.0:
		parts.append("%+.2f €" % d_money)
	if d_energy != 0.0:
		parts.append("Energie %+d" % int(d_energy))
	if d_satiety != 0.0:
		parts.append("Sättigung %+d" % int(d_satiety))
	if d_readiness != 0.0:
		parts.append("Sicherheit %+d" % int(d_readiness))
	if d_stress != 0.0:
		parts.append("Stress %+d" % int(d_stress))
	return "  ·  ".join(parts)


func interact() -> void:
	if GameState.do_action(minutes, d_energy, d_satiety, d_readiness, d_stress, d_money):
		GameState.message.emit(note if note != "" else title + " (" + str(minutes) + " min)")


func _has_shape() -> bool:
	for c in get_children():
		if c is CollisionShape3D:
			return true
	return false


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("add_interactable"):
		body.add_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body.has_method("remove_interactable"):
		body.remove_interactable(self)
