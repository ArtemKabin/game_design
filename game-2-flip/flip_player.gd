# flip_player.gd
# Side-scrolling CharacterBody2D for the Flip platformer.
# Controls:
#   A / Left  = move left
#   D / Right = move right
#   F         = world_flip  (the core mechanic)
# There is NO jump button. The player must use ledge momentum + flip to cross pits.
extends CharacterBody2D

signal died

const SPEED        := 220.0
const GRAVITY      := 900.0
const COYOTE_TIME  := 0.12   # seconds you can still "flip" after walking off a ledge
const FLIP_COOLDOWN := 0.35  # prevent spam-flipping

@onready var body_rect: ColorRect = $BodyRect
@onready var eye_rect: ColorRect  = $EyeRect
@onready var death_particles: CPUParticles2D = $DeathParticles

var can_move: bool   = true
var is_dead: bool    = false
var coyote_timer: float = 0.0
var flip_cooldown_timer: float = 0.0
var was_on_floor: bool = false

## Spawn position saved by the level for respawn.
var spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_colors()


func _physics_process(delta: float) -> void:
	if not can_move or is_dead:
		return

	# ── Horizontal movement ──────────────────────────────────────────────────
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * SPEED

	# ── Gravity ──────────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if was_on_floor:
			coyote_timer = COYOTE_TIME  # start coyote window when leaving floor
		coyote_timer -= delta
	else:
		velocity.y = 0.0
		coyote_timer = 0.0

	was_on_floor = is_on_floor()

	# ── Flip cooldown ────────────────────────────────────────────────────────
	if flip_cooldown_timer > 0.0:
		flip_cooldown_timer -= delta

	move_and_slide()

	# Flip the player sprite to face direction of movement.
	if dir != 0:
		scale.x = sign(dir)

	# ── World-flip input ─────────────────────────────────────────────────────
	# Allow flip when airborne OR during the brief coyote window (mid-jump feeling).
	if Input.is_action_just_pressed("world_flip") and flip_cooldown_timer <= 0.0:
		if not is_on_floor() or coyote_timer > 0.0:
			WorldState.flip()
			flip_cooldown_timer = FLIP_COOLDOWN
		else:
			# Standing on ground: still allowed, but teach the player intentionality.
			WorldState.flip()
			flip_cooldown_timer = FLIP_COOLDOWN


func _on_world_flipped(_is_dark: bool) -> void:
	_apply_colors()


func _apply_colors() -> void:
	body_rect.color = WorldState.get_player_color()
	# Eye is always slightly offset for readability.
	eye_rect.color = WorldState.get_bg_color()


func kill() -> void:
	if is_dead:
		return
	is_dead = true
	can_move = false
	velocity = Vector2.ZERO
	body_rect.visible = false
	eye_rect.visible = false
	death_particles.emitting = true
	died.emit()


func respawn(pos: Vector2) -> void:
	is_dead = false
	can_move = true
	global_position = pos
	velocity = Vector2.ZERO
	body_rect.visible = true
	eye_rect.visible  = true
	death_particles.emitting = false
	_apply_colors()


func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector2.ZERO
