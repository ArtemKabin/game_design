# game.gd
# Endless runner: the PLAYER moves right at auto_speed (set each frame).
# Chunks are STATIONARY — they don't scroll. The camera follows the player.
# A "back wall" advances at scroll_speed; if the player falls too far behind it, they die.
# The wall is visible: the Wall node (wall.gd) is moved to _wall_x every frame.
# This avoids the StaticBody2D push bug from the old scrolling approach.
extends Node2D

# ── Constants ─────────────────────────────────────────────────────────────────
const SCROLL_SPEED_START := 140.0   # px/s
const SCROLL_SPEED_MAX   := 380.0
const SPEED_RAMP         :=   6.0   # px/s per second
const SPAWN_AHEAD        := 1100.0  # px ahead of player to keep chunks ready
const VOID_KILL_Y        :=  350.0  # y below which = fallen off
const WALL_GRACE         :=  260.0  # how far behind back-wall before death
const CHUNK_PRE_SPAWN    :=  460.0  # how far left of spawn point to pre-seed ground

## Chunk pool: [scene_path, base_weight]
const CHUNK_POOL: Array = [
	["res://chunk_flat.tscn",        8],
	["res://chunk_gap_small.tscn",   5],
	["res://chunk_gap_medium.tscn",  3],
	["res://chunk_gap_large.tscn",   1],
]

# Player starts here. Enough pre-seeded ground behind for a clean landing.
const PLAYER_SPAWN := Vector2(200.0, -20.0)

# ── Onready ───────────────────────────────────────────────────────────────────
@onready var player:       CharacterBody2D = $Player
@onready var camera:       Camera2D        = $Player/Camera2D
@onready var hud:          Control         = $CanvasLayer/HUD
@onready var game_over_ui: Control         = $CanvasLayer/GameOverUI
@onready var chunk_root:   Node2D          = $ChunkRoot
@onready var wall:         Node2D          = $Wall   # visible back wall, see wall.gd

# ── State ─────────────────────────────────────────────────────────────────────
var scroll_speed:    float = SCROLL_SPEED_START
var score:           int   = 0
var _last_score:     int   = -1
var _running:        bool  = false
var _chunk_right_x:  float = 0.0
var _chunks:         Array = []
var _wall_x:         float = 0.0   # the advancing back-wall world-x
var _die_reason:     String = ""


func _ready() -> void:
	WorldState.reset()
	player.died.connect(_on_player_died)
	game_over_ui.restart_requested.connect(_on_restart)
	game_over_ui.visible = false

	_reset_chunks()

	# Wait two physics frames so collision shapes register before gravity fires.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_start()


func _start() -> void:
	_running     = true
	score        = 0
	_last_score  = -1
	scroll_speed = SCROLL_SPEED_START
	_wall_x      = PLAYER_SPAWN.x - WALL_GRACE - 100.0
	wall.position.x = _wall_x
	_die_reason  = ""
	hud.set_score(0)
	hud.show_status("Zögere — dann entscheide.\n[A] = langsamer   [D] = schneller   [F] = Welt wechseln", 4.5)


func _reset_chunks() -> void:
	for c in _chunks:
		if is_instance_valid(c):
			c.queue_free()
	_chunks.clear()

	# Seed ground well before the player so they land safely.
	_chunk_right_x = PLAYER_SPAWN.x - CHUNK_PRE_SPAWN

	# Force first 3 chunks to be flat so the player has solid ground to start.
	for _i in range(3):
		_spawn_chunk("res://chunk_flat.tscn")
	# Then fill ahead with random chunks.
	while _chunk_right_x < PLAYER_SPAWN.x + SPAWN_AHEAD:
		_spawn_next_chunk(0.0)


# ── Main loop ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not _running:
		return

	# Push player auto_speed
	player.auto_speed = scroll_speed

	# Ramp difficulty
	scroll_speed = minf(scroll_speed + SPEED_RAMP * delta, SCROLL_SPEED_MAX)

	# Advance back wall (logic) and move its visual to match
	_wall_x += scroll_speed * delta
	wall.position.x = _wall_x

	var px := player.global_position.x
	var py := player.global_position.y

	# Void kill — fell off bottom
	if py > VOID_KILL_Y and not player.is_dead:
		_die_reason = "Du bist gefallen.\nZögere — aber spring ab bevor du fällst!"
		player.kill()
		return

	# Wall kill — hesitated too long
	if px < _wall_x and not player.is_dead:
		_die_reason = "Du hast zu lange gezögert.\nDie Wand hat dich erwischt!"
		player.kill()
		return

	# Score: distance in units of 100px
	score = maxi(int((px - PLAYER_SPAWN.x) / 100.0), 0)
	if score != _last_score:
		_last_score = score
		hud.set_score(score)

	# Spawn ahead of player
	while _chunk_right_x < px + SPAWN_AHEAD:
		var t := clampf((scroll_speed - SCROLL_SPEED_START) / (SCROLL_SPEED_MAX - SCROLL_SPEED_START), 0.0, 1.0)
		_spawn_next_chunk(t)

	# Free far behind player
	var free_threshold := px - 700.0
	for chunk in _chunks.duplicate():
		if not is_instance_valid(chunk):
			_chunks.erase(chunk)
			continue
		if (chunk as Chunk).global_position.x + (chunk as Chunk).width < free_threshold:
			_chunks.erase(chunk)
			chunk.queue_free()


# ── Chunk spawning ────────────────────────────────────────────────────────────
func _spawn_next_chunk(difficulty: float) -> void:
	var pool := _build_pool(difficulty)
	_spawn_chunk(pool[randi() % pool.size()])


func _spawn_chunk(path: String) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("game.gd: cannot load '%s'" % path)
		return
	var chunk := packed.instantiate() as Chunk
	chunk.position = Vector2(_chunk_right_x, 0.0)
	chunk_root.add_child(chunk)
	_chunks.append(chunk)
	_chunk_right_x += chunk.width
	_wire_spheres(chunk)


func _wire_spheres(chunk: Node) -> void:
	for child in chunk.get_children():
		if child.has_node("KillZone"):
			var kz := child.get_node("KillZone") as Area2D
			if kz and not kz.body_entered.is_connected(_on_sphere_kill):
				kz.body_entered.connect(_on_sphere_kill)


func _build_pool(difficulty: float) -> Array:
	var weights := [
		lerpf(8.0, 1.0, difficulty),
		lerpf(5.0, 5.0, difficulty),
		lerpf(3.0, 7.0, difficulty),
		lerpf(1.0, 5.0, difficulty),
	]
	var pool: Array = []
	for i in range(CHUNK_POOL.size()):
		for _j in range(maxi(int(weights[i]), 1)):
			pool.append(CHUNK_POOL[i][0])
	return pool


# ── Callbacks ─────────────────────────────────────────────────────────────────
func _on_sphere_kill(body: Node) -> void:
	if body == player and not player.is_dead:
		_die_reason = "Die Kugel in der schwarzen Welt hat dich erwischt.\nZögere — dann entscheide den richtigen Moment."
		player.kill()


func _on_player_died() -> void:
	_running = false
	player.set_movement_enabled(false)
	await get_tree().create_timer(0.85).timeout
	if not game_over_ui.visible:
		game_over_ui.show_game_over(
			"GAME OVER — SCORE: %d" % score,
			_die_reason
		)


func _on_restart() -> void:
	game_over_ui.visible = false
	WorldState.reset()
	player.respawn(PLAYER_SPAWN)
	_reset_chunks()
	# One physics frame pause so the reset chunks register collision.
	await get_tree().physics_frame
	_start()
