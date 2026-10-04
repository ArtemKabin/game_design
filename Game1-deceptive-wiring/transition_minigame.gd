extends Node2D

# Transition minigame between two levels: "Frachtlauf".
# You are the heavy cart (snake-style driving, see heavy_cart.gd). Reach the exit
# zone without touching a wall. A wall is game over and restarts the run.
# GameManager.pending_level is the level that follows.

@onready var heavy_cart: CharacterBody2D = $HeavyCart
@onready var exit_zone: Area2D = $ExitZone
@onready var header_label: Label = $CanvasLayer/HUD/HeaderLabel
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var controls_label: Label = $CanvasLayer/HUD/ControlsGuideLabel
@onready var game_over_ui: Control = $CanvasLayer/GameOverUI

var is_finished: bool = false


func _ready() -> void:
	header_label.text = "ÜBERGANG → LEVEL %d: FRACHTLAUF" % GameManager.pending_level
	controls_label.text = GameManager.CONTROLS_TEXT

	heavy_cart.started_driving.connect(_on_cart_started_driving)
	heavy_cart.crashed_into_wall.connect(_on_cart_crashed_into_wall)
	exit_zone.body_entered.connect(_on_exit_zone_body_entered)
	game_over_ui.restart_requested.connect(func() -> void: get_tree().reload_current_scene())

	heavy_cart.board(null)
	status_label.text = "Du sitzt im Schwerlastwagen. [%s] zum Anfahren. Er bremst nicht. Berühre keine Wand!" \
		% heavy_cart.facing_key_name()


func _on_cart_started_driving() -> void:
	status_label.text = "Quer lenken: W/S beim Geradeausfahren, A/D beim Hoch- oder Runterfahren. Ziel: der leuchtende Bereich."


func _on_cart_crashed_into_wall() -> void:
	game_over_ui.show_game_over("💥 CRASH",
		"Der Schwerlastwagen kennt keine Bremse. Die Wand schon. Noch einmal.")


func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body != heavy_cart or is_finished:
		return
	is_finished = true
	status_label.text = "ZIEL erreicht!"
	GameManager.continue_after_transition()
