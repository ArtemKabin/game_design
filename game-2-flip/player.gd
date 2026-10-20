# player.gd
# CharacterBody2D — side-scrolling platformer.
# Controls:  A / ←  = slow down (hesitate)   D / →  = speed up   Enter = world_flip
# The player auto-runs RIGHT at auto_speed (set by game.gd each frame).
# Pressing A slows to a stop; pressing D doubles speed briefly.
# There is NO jump. Holes are virtual (see flip_chunk.gd): the floor is always
# solid, a hole kills via kill_by_fall() which plays a short fall animation.
extends CharacterBody2D

signal died

const GRAVITY       := 900.0
const FLIP_COOLDOWN := 0.15   # prevent flip spam; must stay below the time to cross 2 segments at top speed
const FALL_DROP     := 60.0   # px the player sinks during the hole death animation
const FALL_TIME     := 0.35

@onready var body_rect:       ColorRect      = $BodyRect
@onready var eye_rect:        ColorRect      = $EyeRect
@onready var death_particles: CPUParticles2D = $DeathParticles

var is_dead:       bool  = false
var can_move:      bool  = true
var flip_cooldown: float = 0.0
var was_on_floor:  bool  = false
var coyote_timer:  float = 0.0
var _fall_tween:   Tween = null

const COYOTE_TIME  := 0.14

## Set each frame by game.gd. The base horizontal speed.
var auto_speed: float = 0.0


func _ready() -> void:
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_colors()


func _physics_process(delta: float) -> void:
	if is_dead or not can_move:
		return

	# ── Horizontal: A slows to 0, D doubles, neither = auto_speed ────────────
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = clampf(auto_speed + dir * auto_speed, 0.0, auto_speed * 2.2)

	# ── Gravity + coyote ─────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if was_on_floor:
			coyote_timer = COYOTE_TIME
		coyote_timer = maxf(coyote_timer - delta, 0.0)
	else:
		velocity.y   = 0.0
		coyote_timer = 0.0

	was_on_floor  = is_on_floor()
	flip_cooldown = maxf(flip_cooldown - delta, 0.0)

	move_and_slide()

	# ── World flip ────────────────────────────────────────────────────────────
	if Input.is_action_just_pressed("world_flip") and flip_cooldown <= 0.0:
		WorldState.flip()
		flip_cooldown = FLIP_COOLDOWN


func _on_world_flipped(_is_dark: bool) -> void:
	_apply_colors()


func _apply_colors() -> void:
	body_rect.color = WorldState.get_player_color()
	eye_rect.color  = WorldState.get_bg_color()


func kill() -> void:
	if is_dead:
		return
	is_dead  = true
	can_move = false
	velocity = Vector2.ZERO
	body_rect.visible        = false
	eye_rect.visible         = false
	death_particles.emitting = true
	died.emit()


## Death by virtual hole: sink and fade, then the usual particle burst.
## No physics involved — the floor under the player stays solid.
func kill_by_fall() -> void:
	if is_dead:
		return
	is_dead  = true
	can_move = false
	velocity = Vector2.ZERO
	var tween := create_tween().set_parallel(true)
	_fall_tween = tween
	tween.tween_property(body_rect, "position:y", body_rect.position.y + FALL_DROP, FALL_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(eye_rect, "position:y", eye_rect.position.y + FALL_DROP, FALL_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(body_rect, "modulate:a", 0.0, FALL_TIME)
	tween.tween_property(eye_rect,  "modulate:a", 0.0, FALL_TIME)
	tween.chain().tween_callback(_finish_fall)
	died.emit()


func _finish_fall() -> void:
	body_rect.visible        = false
	eye_rect.visible         = false
	death_particles.position = Vector2(0.0, FALL_DROP * 0.5)
	death_particles.emitting = true


func respawn(pos: Vector2) -> void:
	if _fall_tween and _fall_tween.is_valid():
		_fall_tween.kill()   # a still-running fall animation must not hide the new body
	_fall_tween = null
	is_dead    = false
	can_move   = true
	auto_speed = 0.0
	global_position          = pos
	velocity                 = Vector2.ZERO
	scale.x                  = 1.0
	body_rect.visible        = true
	eye_rect.visible         = true
	body_rect.position       = Vector2(-14.0, -18.0)
	eye_rect.position        = Vector2(4.0, -12.0)
	body_rect.modulate.a     = 1.0
	eye_rect.modulate.a      = 1.0
	death_particles.position = Vector2.ZERO
	death_particles.emitting = false
	WorldState.reset()
	_apply_colors()


func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector2.ZERO
