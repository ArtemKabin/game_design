# game.gd
# Endless runner: the PLAYER moves right at auto_speed (set each frame).
# Chunks are STATIONARY — they don't scroll. The camera follows the player.
# There is no back wall: hesitating costs nothing but time.
extends Node2D

# ── Constants ─────────────────────────────────────────────────────────────────
const SCROLL_SPEED_START := 140.0   # px/s
const SCROLL_SPEED_MAX   := 380.0
const SPEED_RAMP         :=   6.0   # px/s per second
const SPRINT_TIP_FACTOR  :=   1.5   # dying above this x auto_speed counts as "sprinting" (D doubles it)
const SPAWN_AHEAD        := 1100.0  # px ahead of player to keep chunks ready
const VOID_KILL_Y        :=  350.0  # y below which = fallen off (safety net, floor is continuous)
const CHUNK_PRE_SPAWN    :=  460.0  # how far left of spawn point to pre-seed ground

## Level rhythm: SAFE, HAZARD, SAFE, HAZARD, ...
## A safe zone (chunk_safe.tscn) is flat, never inverts, flipping there is harmless.
const SAFE_SCENE   := "res://chunk_safe.tscn"
const HAZARD_SCENE := "res://flip_chunk.tscn"
const LANTERN_SCENE := "res://wall_lantern.tscn"

## Wall lanterns sit on the BackdropLanterns Parallax2D, which scrolls at this
## factor (must match the node in game.tscn). Parallax2D offsets its content by
## the screen's top-left corner times (1 - factor), so a lantern meant to hang
## over world x = X when the camera is centred there goes to parallax-local
## x = X * factor + half_screen_width * (1 - factor). See _lantern_local_x().
const BACKDROP_SCROLL := 0.85
const LANTERN_OFFSET  := Vector2(140.0, -40.0)   # over the middle of a safe chunk

## Hazard pool. Every entry is one FlipChunk (flip_chunk.gd) with weights
## w0 (difficulty 0) and w1 (difficulty 1); interpolated in between, 0 = never.
##
##   "floor":   pattern string, one char = 80 px
##              '#' ground only in WHITE   '.' ground only in BLACK   '=' ground in BOTH
##              Keep every one-world run at least 2 chars (see FLIP_COOLDOWN in player.gd).
##   "spheres": [[x, in_dark, patrol_distance, patrol_speed], ...]   (sphere.gd)
##              exists (visible + deadly) only in its world; patrol_distance != 0 → moves
##              that far (negative = left) and back at patrol_speed px/s.
##   "stars":   [[x, in_dark], ...]                                   (star.gd)
##              visible/frozen/deadly in its world; hidden and hunting in the other.
##   x is chunk-local; segment i has its centre at i*80+40. A hazard must stand on
##   ground of the world where it is HIDDEN (use '=' when in doubt), otherwise the
##   chunk is impassable — flip_chunk.gd warns about that.
const HAZARD_POOL: Array = [
	# ── floor only: flip at the edges ───────────────────────────────────────────
	{"floor": "####....####",     "w0": 6, "w1": 1},
	{"floor": "....####....",     "w0": 4, "w1": 1},
	{"floor": "####..####",       "w0": 3, "w1": 2},
	{"floor": "###...###...###",  "w0": 2, "w1": 3},
	{"floor": "...###...###...",  "w0": 1, "w1": 3},
	{"floor": "##..##..##..##",   "w0": 0, "w1": 4},
	{"floor": "..##..##..##..",   "w0": 0, "w1": 3},
	{"floor": "####..####..####", "w0": 1, "w1": 3},
	# ── spheres on solid floor: be in the other world when you pass ─────────────
	{"floor": "=======",      "spheres": [[280, false, 0, 0]],                                       "w0": 5, "w1": 1},
	{"floor": "=======",      "spheres": [[280, true,  0, 0]],                                       "w0": 5, "w1": 1},
	{"floor": "==========",   "spheres": [[240, false, 0, 0], [560, true, 0, 0]],                    "w0": 2, "w1": 3},
	{"floor": "===========",  "spheres": [[200, true, 0, 0], [440, false, 0, 0], [680, true, 0, 0]], "w0": 0, "w1": 3},
	{"floor": "=========",    "spheres": [[200, false, 320, 140]],                                   "w0": 2, "w1": 2},
	{"floor": "=========",    "spheres": [[520, true, -320, 180]],                                   "w0": 1, "w1": 2},
	{"floor": "============", "spheres": [[160, false, 240, 120], [720, true, -240, 160]],           "w0": 0, "w1": 3},
	# dance: two patrolling spheres, one per world, crossing each other
	{"floor": "========",     "spheres": [[80, false, 480, 150], [560, true, -480, 150]],            "w0": 0, "w1": 2},
	# ── stars on solid floor: hidden hunters ───────────────────────────────────
	{"floor": "========",     "stars": [[400, false]],                                               "w0": 3, "w1": 2},
	{"floor": "========",     "stars": [[400, true]],                                                "w0": 3, "w1": 2},
	{"floor": "===========",  "stars": [[300, false], [620, true]],                                  "w0": 0, "w1": 3},
	{"floor": "===========",  "spheres": [[300, false, 0, 0]], "stars": [[620, false]],              "w0": 1, "w1": 3},
	# ── combinations: floor + hazards ──────────────────────────────────────────
	# white sphere on the '==' bridge: flip to black on the bridge BEFORE the sphere,
	# cross the black-only stretch, flip back at the last edge.
	{"floor": "###==...###",  "spheres": [[360, false, 0, 0]],                                       "w0": 2, "w1": 3},
	# narrow window: the white star sits on the 2nd '=' → you must flip to black on
	# the 1st '=' (80 px) or die; it then hunts you from behind.
	{"floor": "####==....",   "stars": [[440, false]],                                               "w0": 1, "w1": 3},
	# hidden hunter over white ground: enter in black, flip to white, run through the
	# invisible black star, flip back at the end — but only if it is behind you.
	{"floor": "..####..",     "stars": [[440, true]],                                                "w0": 1, "w1": 3},
	# classic hole with a hunter: a black star hides on the white ground before the
	# hole. Slow down at the edge and it catches you right when you flip.
	{"floor": "####....####", "stars": [[200, true]],                                                "w0": 1, "w1": 3},
	# two bridges, one star each in opposite worlds: black → white → black.
	{"floor": "...==###==...", "stars": [[360, true], [680, false]],                                 "w0": 0, "w1": 3},
	# chaser behind, blocker ahead: black star on the first bridge, flip early to white,
	# cross, flip back on the second bridge (the star followed you in white).
	{"floor": "..==##==..",   "stars": [[200, true]],                                                "w0": 1, "w1": 2},
	# patrolling sphere guards the entry bridge, then a black-only stretch.
	{"floor": "===....===",   "spheres": [[40, false, 160, 120]],                                    "w0": 1, "w1": 2},
	# gauntlet: four flips, alternating hazards — late game only.
	{"floor": "===..==##==..===", "spheres": [[120, false, 0, 0], [1160, true, 0, 0]], "stars": [[520, true], [840, false]], "w0": 0, "w1": 3},
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
@onready var lantern_root: Node2D          = $BackdropLanterns
@onready var pause_menu:   CanvasLayer     = $PauseMenu

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
	game_over_ui.menu_requested.connect(_on_menu)
	game_over_ui.visible = false
	# Escape pauses, but not over the game-over screen or while dying.
	pause_menu.can_pause = func() -> bool: return _running and not player.is_dead
	Audio.play_music("run")

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


func _reset_chunks() -> void:
	for c in _chunks:
		if is_instance_valid(c):
			_free_chunk(c)
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

	# HUD lantern shows how much sight is left
	hud.set_sight_level(sight_fog.level())

	# Ramp difficulty
	scroll_speed = minf(scroll_speed + SPEED_RAMP * delta, SCROLL_SPEED_MAX)

	var px := player.global_position.x
	var py := player.global_position.y

	# Void kill — safety net only, the floor is continuous
	if py > VOID_KILL_Y and not player.is_dead:
		_die_reason = "Du bist gefallen."
		Audio.play("fall")
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
			_free_chunk(chunk)


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
	if chunk == null:
		return
	_place_chunk(chunk)
	# Wall lantern on the parallax layer, freed together with the chunk.
	var packed: PackedScene = load(LANTERN_SCENE)
	if packed:
		var lantern := packed.instantiate() as Node2D
		lantern.position = Vector2(_lantern_local_x(chunk.position.x + LANTERN_OFFSET.x), LANTERN_OFFSET.y)
		lantern_root.add_child(lantern)
		chunk.set_meta("lantern", lantern)


## Parallax-local x for a lantern that should sit over world x when the camera
## is centred on it (see BACKDROP_SCROLL).
func _lantern_local_x(world_x: float) -> float:
	var half_w := get_viewport().get_visible_rect().size.x * 0.5
	return world_x * BACKDROP_SCROLL + half_w * (1.0 - BACKDROP_SCROLL)


func _free_chunk(chunk: Node) -> void:
	if chunk.has_meta("lantern"):
		var lantern: Node = chunk.get_meta("lantern")
		if is_instance_valid(lantern):
			lantern.queue_free()
	chunk.queue_free()


func _spawn_hazard(spec: Dictionary) -> void:
	if spec.has("floor"):
		var chunk := _instantiate_chunk(HAZARD_SCENE) as FlipChunk
		if chunk == null:
			return
		# Must be set BEFORE add_child: the chunk is built in _ready.
		chunk.pattern = spec["floor"]
		chunk.spheres = spec.get("spheres", [])
		chunk.stars   = spec.get("stars", [])
		_place_chunk(chunk)
		chunk.hole_entered.connect(_on_hole_entered)
		chunk.sphere_hit.connect(_on_sphere_hit)
		chunk.star_hit.connect(_on_star_hit)
	else:
		push_error("game.gd: hazard entry has no 'floor' pattern: %s" % spec)


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
		_unlock_tips("hole")
		Audio.play("fall")
		player.kill_by_fall()


func _on_sphere_hit(body: Node) -> void:
	if _running and body == player and not player.is_dead:
		_die_reason = "Der Geist hat dich erwischt.\nEr existiert nur in einer Welt. Weiche ihm in der anderen aus."
		_unlock_tips("ghost")
		Audio.play("ghost_hit")   # every ghost kind shares this sound
		player.kill()


func _on_star_hit(body: Node) -> void:
	if _running and body == player and not player.is_dead:
		_die_reason = "Der Jäger hat dich.\nIm Licht weicht er zurück. Siehst du ihn nicht, kommt er näher."
		_unlock_tips("hunter")
		Audio.play("ghost_hit")
		player.kill()


## Each kind of death unlocks a tip in the help (help_menu.gd); dying while
## sprinting unlocks the sprint tip on top. The game-over text says when
## something new is there. The hunter's tip is spelled out at once, because
## its sound is the one thing the player cannot guess.
func _unlock_tips(cause: String) -> void:
	var fresh: Array[String] = []
	if Settings.unlock_tip(cause):
		fresh.append(cause)
	if player.velocity.x > player.auto_speed * SPRINT_TIP_FACTOR and Settings.unlock_tip("sprint"):
		fresh.append("sprint")
	if fresh.has("hunter"):
		_die_reason += "\nTipp: Hör auf das Flüstern. Es wird lauter, wenn ein Jäger nah ist."
	elif not fresh.is_empty():
		_die_reason += "\nNeuer Tipp in der Hilfe!"


func _on_player_died() -> void:
	_running = false
	player.set_movement_enabled(false)
	Audio.duck_music(true)
	await get_tree().create_timer(0.85).timeout
	if not game_over_ui.visible:
		var rank: int = Scoreboard.add(score)
		game_over_ui.show_game_over(score, _die_reason, rank)


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")


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
