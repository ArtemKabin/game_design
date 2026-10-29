# player.gd
# CharacterBody2D — side-scrolling platformer.
# Controls:  A / ←  = slow down (hesitate)   D / →  = speed up   Enter / Space = world_flip
# The player auto-runs RIGHT at auto_speed (set by game.gd each frame).
# Pressing A slows to a stop; pressing D doubles speed briefly.
# There is NO jump. Holes are virtual (see flip_chunk.gd): the floor is always
# solid, a hole kills via kill_by_fall() which plays a short fall animation.
#
# LOOK: three stacked AnimatedSprite2D under $Visual — ArmBack, Body, ArmFront.
# All sheets share frame size, order and tags (art/README.md), so the arms just
# mirror the body's animation and frame. The world flip swaps the two arm
# sheets: WHITE world = RED lantern raised (right hand), BLACK world = BLUE
# lantern raised (left hand).
extends CharacterBody2D

signal died

const GRAVITY       := 900.0
const FLIP_COOLDOWN := 0.15   # prevent flip spam; must stay below the time to cross 2 segments at top speed
const FALL_DROP     := 60.0   # px the player sinks during the hole death animation
const FALL_TIME     := 0.35
const IDLE_SPEED    := 10.0   # px/s below which the idle animation plays
const RUN_REF_SPEED := 140.0  # velocity at which the run animation plays at 1x
# Horizontal speed eases towards its target instead of jumping: a short
# wind-up when starting, a much shorter skid when braking. (At 2800 px/s² a
# stop from the start speed takes ~0.05 s and ~3 px, well inside the 14 px
# flip grace.)
const ACCEL         := 900.0  # px/s² when speeding up
const DECEL         := 2800.0 # px/s² when slowing down — abrupt, just softened
# Footstep loop (assets/audio/sfx/step.mp3 via Audio.make_loop): runs a bit
# faster than recorded and speeds up with the player, but only up to a point.
const STEP_BASE_PITCH := 1.40   # at RUN_REF_SPEED (the start speed)
const STEP_MIN_PITCH  := 0.75   # crawling while hesitating (A held)
const STEP_MAX_PITCH  := 2.40   # cap, reached at about twice the start speed
const STEP_PITCH_POW  := 0.8    # nearly proportional to speed: slower steps when slow, faster when fast
# The flip whoosh: a little lower when dropping into the blue world, a little
# higher when coming back to red, on top of the random spread.
const FLIP_PITCH_BLUE := 0.92
const FLIP_PITCH_RED  := 1.08

# ── Sprite sheets (exported from art/shaggy.aseprite) ────────────────────────
const SHEET_DIR := "res://assets/player/"
const SHEETS := {
	"body":       "shaggy_body.png",
	"front_red":  "shaggy_arm_front_red.png",
	"back_red":   "shaggy_arm_back_red.png",
	"front_blue": "shaggy_arm_front_blue.png",
	"back_blue":  "shaggy_arm_back_blue.png",
}
const FRAME_W := 48
const FRAME_H := 68
const ANIMS := {
	"idle": {"from": 0, "to": 3, "fps": 1000.0 / 150.0},
	"run":  {"from": 4, "to": 7, "fps": 1000.0 / 90.0},
}
## Where $Visual sits relative to the collision box (28x36, centred): the
## sprite's ground line (y=66 of 68) lands on the box's bottom edge (+18).
const VISUAL_OFFSET := Vector2(-2.0, -14.0)

@onready var visual:          Node2D           = $Visual
@onready var body_sprite:     AnimatedSprite2D = $Visual/Body
@onready var arm_front:       AnimatedSprite2D = $Visual/ArmFront
@onready var arm_back:        AnimatedSprite2D = $Visual/ArmBack
@onready var death_particles: CPUParticles2D   = $DeathParticles

var is_dead:       bool  = false
var can_move:      bool  = true
var flip_cooldown: float = 0.0
var was_on_floor:  bool  = false
var coyote_timer:  float = 0.0
var _fall_tween:   Tween = null
var _frames:       Dictionary = {}   # key from SHEETS -> SpriteFrames
var _steps:        AudioStreamPlayer = null   # looping footsteps, see _update_steps
var _step_jitter:  float = 1.0                # random pitch picked each time the loop starts

const COYOTE_TIME  := 0.14

## Set each frame by game.gd. The base horizontal speed.
var auto_speed: float = 0.0


func _ready() -> void:
	_load_sheets()
	body_sprite.frame_changed.connect(_sync_arms)
	body_sprite.animation_changed.connect(_sync_arms)
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_world(WorldState.is_dark)
	body_sprite.play("idle")
	_steps = Audio.make_loop("step", false) as AudioStreamPlayer
	add_child(_steps)


func _load_sheets() -> void:
	for key in SHEETS:
		var path: String = SHEET_DIR + SHEETS[key]
		var tex := load(path) as Texture2D
		if tex == null:
			push_warning("player.gd: sprite sheet missing: %s" % path)
			continue
		_frames[key] = SpriteSheetFrames.build(tex, FRAME_W, FRAME_H, ANIMS)
	if _frames.has("body"):
		body_sprite.sprite_frames = _frames["body"]


func _physics_process(delta: float) -> void:
	if is_dead or not can_move:
		return

	# ── Horizontal: A slows to 0, D doubles, neither = auto_speed ────────────
	# The target changes instantly, the actual speed eases towards it.
	var dir := Input.get_axis("move_left", "move_right")
	var target := clampf(auto_speed + dir * auto_speed, 0.0, auto_speed * 2.2)
	var rate := ACCEL if target > velocity.x else DECEL
	velocity.x = move_toward(velocity.x, target, rate * delta)

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
	_update_animation()

	# ── World flip ────────────────────────────────────────────────────────────
	if Input.is_action_just_pressed("world_flip") and flip_cooldown <= 0.0:
		WorldState.flip()
		Audio.play("flip", FLIP_PITCH_BLUE if WorldState.is_dark else FLIP_PITCH_RED)
		flip_cooldown = FLIP_COOLDOWN


# ── Look ──────────────────────────────────────────────────────────────────────
func _update_animation() -> void:
	var want := "run" if absf(velocity.x) > IDLE_SPEED else "idle"
	if body_sprite.animation != want:
		body_sprite.play(want)
	# Faster legs when sprinting, slower when hesitating.
	body_sprite.speed_scale = clampf(velocity.x / RUN_REF_SPEED, 0.7, 2.2) if want == "run" else 1.0
	_update_steps(want == "run" and is_on_floor())


## Footsteps follow the legs: loop while running, pitched up with speed.
func _update_steps(running: bool) -> void:
	if _steps == null:
		return
	if not running:
		_stop_steps()
		return
	if not _steps.playing:
		_step_jitter = Audio.random_pitch("step")
		Audio.start_loop_desynced(_steps)
	var by_speed := STEP_BASE_PITCH * pow(maxf(velocity.x, 0.0) / RUN_REF_SPEED, STEP_PITCH_POW)
	_steps.pitch_scale = clampf(by_speed, STEP_MIN_PITCH, STEP_MAX_PITCH) * _step_jitter


func _stop_steps() -> void:
	if _steps and _steps.playing:
		_steps.stop()


## Arms show the same animation and frame as the body.
func _sync_arms() -> void:
	for arm in [arm_front, arm_back]:
		if arm.sprite_frames == null or not arm.sprite_frames.has_animation(body_sprite.animation):
			continue
		if arm.animation != body_sprite.animation:
			arm.animation = body_sprite.animation
		arm.frame = body_sprite.frame


func _on_world_flipped(is_dark: bool) -> void:
	_apply_world(is_dark)


## WHITE world → red lantern (right hand) raised; BLACK world → blue (left hand).
func _apply_world(is_dark: bool) -> void:
	var suffix := "blue" if is_dark else "red"
	if _frames.has("front_" + suffix):
		arm_front.sprite_frames = _frames["front_" + suffix]
	if _frames.has("back_" + suffix):
		arm_back.sprite_frames = _frames["back_" + suffix]
	_sync_arms()


# ── Death / respawn ───────────────────────────────────────────────────────────
func kill() -> void:
	if is_dead:
		return
	is_dead  = true
	can_move = false
	velocity = Vector2.ZERO
	_stop_steps()
	visual.visible           = false
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
	_stop_steps()
	body_sprite.pause()
	var tween := create_tween().set_parallel(true)
	_fall_tween = tween
	tween.tween_property(visual, "position:y", VISUAL_OFFSET.y + FALL_DROP, FALL_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(visual, "modulate:a", 0.0, FALL_TIME)
	tween.chain().tween_callback(_finish_fall)
	died.emit()


func _finish_fall() -> void:
	visual.visible           = false
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
	visual.visible           = true
	visual.position          = VISUAL_OFFSET
	visual.modulate.a        = 1.0
	death_particles.position = Vector2.ZERO
	death_particles.emitting = false
	WorldState.reset()
	body_sprite.play("idle")


func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector2.ZERO
		_update_animation()   # idle look, footsteps off
