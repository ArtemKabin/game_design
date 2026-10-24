# game.gd
# Endless runner: the PLAYER moves right at auto_speed (set each frame).
# Chunks are STATIONARY — they don't scroll. The camera follows the player.
# There is no back wall: hesitating costs nothing but time.
extends Node2D

# ── Constants ─────────────────────────────────────────────────────────────────
const SCROLL_SPEED_START := 140.0   # px/s
const SCROLL_SPEED_MAX   := 380.0
const SPEED_RAMP         :=   6.0   # px/s per second
const SPAWN_AHEAD        := 1100.0  # px ahead of player to keep chunks ready
const VOID_KILL_Y        :=  350.0  # y below which = fallen off (safety net, floor is continuous)
const CHUNK_PRE_SPAWN    :=  460.0  # how far left of spawn point to pre-seed ground

## Level rhythm: SAFE, HAZARD, SAFE, HAZARD, ...
## A safe zone (chunk_safe.tscn) is flat, never inverts, flipping there is harmless.
const SAFE_SCENE   := "res://chunk_safe.tscn"
const HOLE_SCENE   := "res://flip_chunk.tscn"
const SPHERE_SCENE := "res://sphere_chunk.tscn"

## Hazard pool. Each entry is a Dictionary with weights w0 (difficulty 0) and
## w1 (difficulty 1); the weight is interpolated in between, 0 = never.
##
## HOLE chunk:   {"holes": "<pattern>"}
##   '#' = ground in the WHITE world, '.' = hole in the WHITE world, BLACK = inverse.
##   One char = 80 px. Keep every run at least 2 chars (see FLIP_COOLDOWN in player.gd).
##
## SPHERE chunk: {"width": px, "spheres": [[x, in_dark, patrol_distance, patrol_speed], ...]}
##   Floor is solid in both worlds. A sphere exists (visible + deadly) only in
##   its world: in_dark=false -> WHITE, true -> BLACK. Pass it in the other world.
##   patrol_distance != 0 -> it moves that far (negative = left) and back at patrol_speed px/s.
##
## STAR entries:  "stars": [[x, in_dark], ...]  (same chunk type, may be mixed with spheres)
##   A star is visible, frozen and deadly in its world. In the other world it is
##   hidden, harmless and hunts the player while on screen (see star.gd).
const HAZARD_POOL: Array = [
	# holes
	{"holes": "####....####",     "w0": 6, "w1": 1},
	{"holes": "....####....",     "w0": 4, "w1": 1},
	{"holes": "####..####",       "w0": 3, "w1": 2},
	{"holes": "###...###...###",  "w0": 2, "w1": 3},
	{"holes": "...###...###...",  "w0": 1, "w1": 3},
	{"holes": "##..##..##..##",   "w0": 0, "w1": 4},
	{"holes": "..##..##..##..",   "w0": 0, "w1": 3},
	{"holes": "####..####..####", "w0": 1, "w1": 3},
	# spheres, stationary
	{"width": 560, "spheres": [[280, false, 0, 0]],                                        "w0": 5, "w1": 1},
	{"width": 560, "spheres": [[280, true,  0, 0]],                                        "w0": 5, "w1": 1},
	{"width": 800, "spheres": [[240, false, 0, 0], [560, true, 0, 0]],                     "w0": 2, "w1": 3},
	{"width": 880, "spheres": [[200, true, 0, 0], [440, false, 0, 0], [680, true, 0, 0]],  "w0": 0, "w1": 3},
	# spheres, patrolling
	{"width": 720, "spheres": [[200, false, 320, 140]],                                    "w0": 2, "w1": 2},
	{"width": 720, "spheres": [[520, true, -320, 180]],                                    "w0": 1, "w1": 2},
	{"width": 960, "spheres": [[160, false, 240, 120], [720, true, -240, 160]],            "w0": 0, "w1": 3},
	# stars (hunters)
	{"width": 640, "stars": [[400, false]],                                                "w0": 3, "w1": 2},
	{"width": 640, "stars": [[400, true]],                                                 "w0": 3, "w1": 2},
	{"width": 880, "stars": [[300, false], [620, true]],                                   "w0": 0, "w1": 3},
	{"width": 880, "spheres": [[300, false, 0, 0]], "stars": [[620, false]],               "w0": 1, "w1": 3},
]

# Player starts here. Enough pre-seeded ground behind for a clean landing.
const PLAYER_SPAWN := Vector2(200.0, -20.0)

# ── Onready ───────────────────────────────────────────────────────────────────
@onready var player:       CharacterBody2D = $Player
@onready var camera:       Camera2D        = $Player/Camera2D
@onready var hud:          Control         = $CanvasLayer/HUD
@onready var game_over_ui: Control         = $CanvasLayer/GameOverUI
@onready var chunk_root:   Node2D          = $ChunkRoot
@onready var sight_fog:    Node2D          = $Player/SightFog   # sight radius, see sight_fog.gd

# ── State ─────────────────────────────────────────────────────────────────────
var scroll_speed:    float = SCROLL_SPEED_START
var score:           int   = 0
var _last_score:     int   = -1
var _running:        bool  = false
var _chunk_right_x:  float = 0.0
var _chunks:         Array = []
var _die_reason:     String = ""
var _last_was_hazard: bool = false   # spawn rhythm: safe / hazard alternate


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
	_die_reason  = ""
	sight_fog.reset()
	hud.set_score(0)
	hud.show_status("Zögere — dann entscheide.\nFlippe genau an der Kante, wo Boden und Loch wechseln. Kugeln gibt es nur in einer Welt: weiche ihnen in der anderen aus. Sterne stehen still, solange du sie siehst. Siehst du sie nicht, kommen sie.\nJeder Schritt nimmt dir Sicht. Bleib stehen, um wieder zu sehen. Leuchtende Rauten zeigen, wo das sicher ist.\n[A] = langsamer   [D] = schneller   [Enter] = Welt wechseln", 7.0)


func _reset_chunks() -> void:
	for c in _chunks:
		if is_instance_valid(c):
			c.queue_free()
	_chunks.clear()

	# Seed ground well before the player so they land safely.
	_chunk_right_x = PLAYER_SPAWN.x - CHUNK_PRE_SPAWN

	# Start on a long safe stretch (3 safe chunks) so the first decision comes
	# after the controls hint has been read.
	for _i in range(3):
		_spawn_safe()
	_last_was_hazard = false
	# Then fill ahead with the safe/hazard rhythm.
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

	var px := player.global_position.x
	var py := player.global_position.y

	# Void kill — safety net only, the floor is continuous
	if py > VOID_KILL_Y and not player.is_dead:
		_die_reason = "Du bist gefallen."
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
## Alternates safe zone and hazard. `difficulty` 0..1 weights the hazard pool.
func _spawn_next_chunk(difficulty: float) -> void:
	if _last_was_hazard:
		_spawn_safe()
	else:
		_spawn_hazard(_pick_hazard(difficulty))
	_last_was_hazard = not _last_was_hazard


func _spawn_safe() -> void:
	var chunk := _instantiate_chunk(SAFE_SCENE)
	if chunk:
		_place_chunk(chunk)


func _spawn_hazard(spec: Dictionary) -> void:
	if spec.has("holes"):
		var chunk := _instantiate_chunk(HOLE_SCENE) as FlipChunk
		if chunk == null:
			return
		chunk.pattern = spec["holes"]       # must be set BEFORE add_child (built in _ready)
		_place_chunk(chunk)
		chunk.hole_entered.connect(_on_hole_entered)
	elif spec.has("spheres") or spec.has("stars"):
		var chunk := _instantiate_chunk(SPHERE_SCENE) as SphereChunk
		if chunk == null:
			return
		chunk.width   = float(spec["width"])
		chunk.spheres = spec.get("spheres", [])
		chunk.stars   = spec.get("stars", [])
		_place_chunk(chunk)
		chunk.sphere_hit.connect(_on_sphere_hit)
		chunk.star_hit.connect(_on_star_hit)
	else:
		push_error("game.gd: hazard entry has no 'holes', 'spheres' or 'stars': %s" % spec)


func _instantiate_chunk(path: String) -> Chunk:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("game.gd: cannot load '%s'" % path)
		return null
	return packed.instantiate() as Chunk


func _place_chunk(chunk: Chunk) -> void:
	chunk.position = Vector2(_chunk_right_x, 0.0)
	chunk_root.add_child(chunk)      # _ready runs here and sets the final width
	_chunks.append(chunk)
	_chunk_right_x += chunk.width


func _pick_hazard(difficulty: float) -> Dictionary:
	var pool: Array = []
	for entry in HAZARD_POOL:
		var w := int(round(lerpf(float(entry["w0"]), float(entry["w1"]), difficulty)))
		for _j in range(w):
			pool.append(entry)
	if pool.is_empty():
		return HAZARD_POOL[0]
	return pool[randi() % pool.size()]


# ── Callbacks ─────────────────────────────────────────────────────────────────
func _on_hole_entered(body: Node) -> void:
	# Holes only count while the run is live (not during death/restart).
	if _running and body == player and not player.is_dead:
		_die_reason = "Du bist in ein Loch gefallen.\nFlippe genau an der Kante, wo Boden und Loch wechseln."
		player.kill_by_fall()


func _on_sphere_hit(body: Node) -> void:
	if _running and body == player and not player.is_dead:
		_die_reason = "Die Kugel hat dich erwischt.\nSie existiert nur in einer Welt — weiche ihr in der anderen aus."
		player.kill()


func _on_star_hit(body: Node) -> void:
	if _running and body == player and not player.is_dead:
		_die_reason = "Der Stern hat dich.\nSolange du ihn siehst, steht er still. Siehst du ihn nicht, kommt er näher."
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
	camera.reset_smoothing()   # snap to the spawn; a lagging camera would "see" far stars and despawn them
	# Let the physics server apply the teleport BEFORE new kill zones exist.
	# Otherwise a fresh zone can overlap the player's old (death) position for
	# one step and kill them again before the run even starts.
	await get_tree().physics_frame
	_reset_chunks()
	# One physics frame pause so the reset chunks register collision.
	await get_tree().physics_frame
	_start()
