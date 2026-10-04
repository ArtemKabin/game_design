extends Node2D

# Level 1: Cargo Bay & Quarantine Maze ("Umfahren" vs "Umgehen")
# Trap: Steering right around the obstacle ("umgehen") or clicking Cabin A-D loops backward.
# Solution: Use corner heavy cart to smash left straight through the obstacle ("umfahren").

@onready var cart_node: Area2D = $HeavyCart
@onready var obstacle_node: Node2D = $ObstacleWall
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var cabin_a_btn: Button = $CanvasLayer/QuarantinePanel/CabinA
@onready var cabin_b_btn: Button = $CanvasLayer/QuarantinePanel/CabinB
@onready var cabin_c_btn: Button = $CanvasLayer/QuarantinePanel/CabinC
@onready var cabin_d_btn: Button = $CanvasLayer/QuarantinePanel/CabinD
@onready var bypass_right_btn: Button = $CanvasLayer/NavigationPanel/BypassRightBtn
@onready var smash_left_btn: Button = $CanvasLayer/NavigationPanel/SmashLeftBtn

var is_solved: bool = false

func _ready() -> void:
	status_label.text = "FRACHTRAUM: Frachtgut blockiert den Weg. Umgehen Sie das Hindernis?"
	
	if cabin_a_btn: cabin_a_btn.pressed.connect(func(): _on_quarantine_cabin_pressed("Kabine A"))
	if cabin_b_btn: cabin_b_btn.pressed.connect(func(): _on_quarantine_cabin_pressed("Kabine B"))
	if cabin_c_btn: cabin_c_btn.pressed.connect(func(): _on_quarantine_cabin_pressed("Kabine C"))
	if cabin_d_btn: cabin_d_btn.pressed.connect(func(): _on_quarantine_cabin_pressed("Kabine D"))
	
	if bypass_right_btn: bypass_right_btn.pressed.connect(_on_bypass_right_pressed)
	if smash_left_btn: smash_left_btn.pressed.connect(_on_smash_left_pressed)

# TRAP 1: Navigating quarantine cabins (Looping Trap)
func _on_quarantine_cabin_pressed(cabin_name: String) -> void:
	if is_solved: return
	status_label.text = "FALLE! " + cabin_name + " ist eine Schlangen-Quarantäne! Weg blockiert, zurück auf Anfang."
	_get_game_manager().register_failure(1, "Quarantäne-Schleife ausgelöst.")

# TRAP 2: Steer right ("umgehen" - to bypass politely)
func _on_bypass_right_pressed() -> void:
	if is_solved: return
	status_label.text = "FALLE: Rechter Ausweichversuch versinkt im automatischen Schutzkreis!"
	_get_game_manager().register_failure(1, "Rechtsausweichen-Falle ausgelöst.")

# SOLUTION: Smash Left ("umfahren" - double meaning: to drive over/smash)
func _on_smash_left_pressed() -> void:
	if is_solved: return
	is_solved = true
	
	# Animate heavy cart smashing left through the obstacle wall
	var tween: Tween = create_tween()
	if cart_node and obstacle_node:
		tween.tween_property(cart_node, "position:x", cart_node.position.x - 300, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(obstacle_node, "modulate:a", 0.0, 0.5)
	
	status_label.text = "ERFOLG: Mit dem Schwerlastwagen durch das Hindernis gerammt! Frachtraum passiert."
	_get_game_manager().complete_level(1)

func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
