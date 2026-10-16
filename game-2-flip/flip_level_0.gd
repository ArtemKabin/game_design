# flip_level_0.gd
# Tutorial level: "Zögern lernen"
#
# Level layout (left → right):
#   [START PLATFORM]  [GAP 1: easy, no sphere]  [PLATFORM]  [GAP 2: sphere above]  [GOAL PLATFORM]
#
# Tutorial beat 1 – Walk off the edge, drop, press F mid-air → land.
# Tutorial beat 2 – Same gap, but a sphere hovers above.
#                   White world: sphere is a platform (can use it to ease the jump).
#                   Black world: sphere kills. Player must time F carefully.
#
# State machine:
#   INTRO → BEAT1_WAITING → BEAT1_DONE → BEAT2_INTRO → BEAT2_WAITING → COMPLETE
extends Node2D

signal level_completed

enum State {
	INTRO,
	BEAT1_WAITING,
	BEAT1_DONE,
	BEAT2_INTRO,
	BEAT2_WAITING,
	COMPLETE,
}

const PLAYER_START      := Vector2(  -640,  -64)
const GOAL_POSITION     := Vector2(   860, -192)

# Text shown at each state.
const TEXTS := {
	State.INTRO: "LEVEL 0: ZÖGERN LERNEN\nBewege dich mit A und D. Probiere es aus.",
	State.BEAT1_WAITING: "Vor dir liegt ein Abgrund. Du kannst nicht springen.\n[F] mitten im Fall wechselt die Welt — versuch es!",
	State.BEAT1_DONE: "Gut gemacht! Die Welt wurde gewechselt und du bist gelandet.\nWeiter rechts wartet die eigentliche Prüfung.",
	State.BEAT2_INTRO: "Siehst du die schwebende Kugel?\nIn der WEISZEN Welt ist sie harmlos — du kannst drauf stehen!\nIn der SCHWARZEN Welt ist sie tödlich. Zögere — dann entscheide.",
	State.BEAT2_WAITING: "Überquere den zweiten Abgrund. Die Kugel beobachtet dich.",
	State.COMPLETE: "LEVEL 0 ABGESCHLOSSEN!\nDas Zögern war richtig. Du hast gelernt, wann man flippt.",
}

@onready var hud:          Control       = $CanvasLayer/FlipHUD
@onready var player:       CharacterBody2D = $FlipPlayer
@onready var goal_area:    Area2D        = $GoalArea
@onready var pit1_sensor:  Area2D        = $Pit1AirSensor
@onready var sphere:       Node2D        = $FlipSphere
@onready var game_over_ui: Control       = $CanvasLayer/GameOverUI

var _state: State = State.INTRO
var _death_timer: float = 0.0
var _death_pending: bool = false


func _ready() -> void:
	WorldState.reset()
	player.spawn_position = PLAYER_START
	player.died.connect(_on_player_died)
	goal_area.body_entered.connect(_on_goal_reached)
	pit1_sensor.body_entered.connect(_on_pit1_entered)

	game_over_ui.restart_requested.connect(_on_restart)
	game_over_ui.visible = false

	# Wire sphere KillZone kill signal.
	sphere.get_node("KillZone").body_entered.connect(_on_sphere_body_entered)

	_enter_state(State.INTRO)


func _process(delta: float) -> void:
	if _death_pending:
		_death_timer -= delta
		if _death_timer <= 0.0:
			_death_pending = false
			_show_game_over()


func _on_pit1_entered(body: Node) -> void:
	if body != player or _state != State.BEAT1_WAITING:
		return
	# Player successfully stepped into the air over the first pit — hint the flip.
	hud.show_status("Jetzt! Drücke [F]!", 2.0)


func _on_goal_reached(body: Node) -> void:
	if body != player or _state == State.COMPLETE:
		return
	_enter_state(State.COMPLETE)
	player.set_movement_enabled(false)


func _on_sphere_body_entered(body: Node) -> void:
	# The KillZone's monitoring is only active in black world (set by flip_sphere.gd),
	# so this fires only when the world is dark.
	if body != player or player.is_dead:
		return
	player.kill()


func _on_player_died() -> void:
	_death_pending = true
	_death_timer   = 0.9   # wait for particles before game-over panel


func _show_game_over() -> void:
	hud.show_status("", 0.0)
	game_over_ui.show_game_over(
		"GAME OVER",
		"Die Kugel in der schwarzen Welt hat dich erwischt.\nZögere — warte auf den richtigen Moment."
	)


func _on_restart() -> void:
	game_over_ui.visible = false
	WorldState.reset()
	player.respawn(PLAYER_START)
	_enter_state(State.BEAT2_WAITING if _state == State.COMPLETE else _state)


func _enter_state(new_state: State) -> void:
	_state = new_state
	if TEXTS.has(new_state):
		hud.show_status(TEXTS[new_state], 6.0 if new_state == State.INTRO else 5.0)

	match new_state:
		State.INTRO:
			await get_tree().create_timer(3.0).timeout
			_enter_state(State.BEAT1_WAITING)

		State.BEAT1_DONE:
			await get_tree().create_timer(3.5).timeout
			_enter_state(State.BEAT2_INTRO)

		State.BEAT2_INTRO:
			await get_tree().create_timer(4.5).timeout
			_enter_state(State.BEAT2_WAITING)

		State.COMPLETE:
			GameManager.complete_level(0)


# Called when the player lands after the first pit flip.
# Connected via the FlipSensor Area2D in the scene.
func _on_landing_platform_entered(body: Node) -> void:
	if body == player and _state == State.BEAT1_WAITING:
		_enter_state(State.BEAT1_DONE)


## Called when the player falls into the void.
func _on_void_kill_zone_body_entered(body: Node) -> void:
	if body != player or player.is_dead:
		return
	player.kill()


## Called when the player lands on the mid-platform after gap 1.
## Wire this to MidPlatform body_entered signal in the editor, or do it here.
func _on_mid_platform_body_entered(body: Node) -> void:
	if body == player and _state == State.BEAT1_WAITING:
		_enter_state(State.BEAT1_DONE)
