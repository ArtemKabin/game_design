# audio.gd
# Autoload "Audio": every sound in the game goes through here.
#   play(name)              one-shot effect from assets/audio/sfx/<name>.mp3 on
#                           the "SFX" bus. EVERY play gets a random pitch and a
#                           little volume spread (see SFX below), so the same
#                           file never sounds exactly the same twice.
#   make_loop(name, pos)    a looping player for a sound that belongs to a
#                           thing in the world (wall lantern fire, ghost voice,
#                           footsteps). pos = true gives an AudioStreamPlayer2D
#                           that pans and fades with distance to the camera.
#                           The caller adds it as a child and calls play().
#   random_pitch(name)      the pitch spread of a sound, for loops that restart
#   play_music(name)        crossfade to assets/audio/music/<name>.mp3, looped
#   duck_music(on)          lower the music while paused / on the game-over screen
# The blue world puts a low-pass filter on the Music bus (world_flipped), the
# way world_filter.gd greys the picture.
#
# "solo" sounds restart themselves instead of stacking (flip spam, UI clicks);
# the others may overlap. Files are MP3 (Godot imports them directly; small for
# the web export). The buses "Music" and "SFX" are created by settings.gd.
# process_mode ALWAYS: menu sounds and music keep working while the tree is paused.
extends Node

const SFX_DIR   := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

# name -> pitch: ± spread (0.10 = ±10 %), db: base volume, solo: restart instead of overlap
const SFX := {
	"flip":       {"pitch": 0.22, "db": -4.0,  "solo": true},   # heard constantly, so wide spread
	"step":       {"pitch": 0.06, "db": -9.0,  "solo": false},
	"fall":       {"pitch": 0.10, "db": -2.0,  "solo": true},
	"ghost_hit":  {"pitch": 0.18, "db":  0.0,  "solo": true},   # one sound for every ghost kind
	"ghost_hunt": {"pitch": 0.18, "db": -3.0,  "solo": false},  # ghost voice loop (positional)
	"lantern":    {"pitch": 0.10, "db": -6.0,  "solo": false},  # wall lantern fire loop (positional)
	"ui_move":    {"pitch": 0.06, "db": -8.0,  "solo": true},
	"ui_select":  {"pitch": 0.06, "db": -5.0,  "solo": true},
	"ui_back":    {"pitch": 0.06, "db": -5.0,  "solo": true},
	"game_over":  {"pitch": 0.05, "db":  0.0,  "solo": true},
	"record":     {"pitch": 0.05, "db": -2.0,  "solo": true},
}
const LOOPED := ["step", "ghost_hunt", "lantern"]   # streams that loop
const VOLUME_SPREAD_DB := 1.5
const POOL_SIZE := 12          # one-shots that can sound at the same time

const MUSIC_DB    := -6.0
const DUCK_DB     := -12.0     # on top of MUSIC_DB while ducked
const MUSIC_FADE  := 1.2       # s crossfade between tracks
const DUCK_FADE   := 0.4
const LOWPASS_RED  := 20500.0  # Hz, effectively off
const LOWPASS_BLUE := 2600.0   # Hz, muffled in the blue world
const LOWPASS_FADE := 0.35     # matches world_filter.gd

var _streams: Dictionary = {}          # path -> AudioStream
var _pool: Array[AudioStreamPlayer] = []
var _pool_next: int = 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music: AudioStreamPlayer = null   # the one currently playing
var _music_name: String = ""
var _music_tween: Tween = null
var _ducked: bool = false
var _lowpass: AudioEffectLowPassFilter = null
var _lowpass_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music_a = _new_music_player()
	_music_b = _new_music_player()
	_setup_lowpass()
	WorldState.world_flipped.connect(_on_world_flipped)
	_on_world_flipped(WorldState.is_dark)


## Stop everything on shutdown so no playback is left registered at exit.
func _exit_tree() -> void:
	for p in _pool:
		p.stop()
	for m in [_music_a, _music_b]:
		if m:
			m.stop()


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _new_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = -60.0
	add_child(p)
	return p


# ── One-shots ─────────────────────────────────────────────────────────────────
## Play an effect with a fresh random pitch and volume. `pitch_mul` shifts the
## whole spread (e.g. 0.9 for a darker variant). Returns the player (or null if
## the file is missing) in case the caller wants to stop it early.
func play(sfx_name: String, pitch_mul: float = 1.0) -> AudioStreamPlayer:
	var stream := _sfx_stream(sfx_name)
	if stream == null:
		return null
	var cfg: Dictionary = SFX.get(sfx_name, {})
	var p := _acquire(sfx_name, bool(cfg.get("solo", false)))
	p.set_meta("sfx", sfx_name)
	p.stream      = stream
	p.pitch_scale = random_pitch(sfx_name) * pitch_mul
	p.volume_db   = float(cfg.get("db", 0.0)) + randf_range(-VOLUME_SPREAD_DB, VOLUME_SPREAD_DB)
	p.play()
	return p


## 1.0 ± the configured spread of a sound.
func random_pitch(sfx_name: String) -> float:
	var spread := float(SFX.get(sfx_name, {}).get("pitch", 0.08))
	return 1.0 + randf_range(-spread, spread)


## A free pool player; a solo sound reuses its own running player (restart).
## If every player is busy the oldest one is taken over.
func _acquire(sfx_name: String, solo: bool) -> AudioStreamPlayer:
	if solo:
		for p in _pool:
			if p.playing and p.get_meta("sfx", "") == sfx_name:
				return p
	for p in _pool:
		if not p.playing:
			return p
	var victim := _pool[_pool_next]
	_pool_next = (_pool_next + 1) % _pool.size()
	return victim


# ── Loops in the world ────────────────────────────────────────────────────────
## A looping player for `sfx_name`, pitched randomly once. Positional players
## pan left/right with the camera and fade out beyond max_distance.
func make_loop(sfx_name: String, positional: bool, max_distance: float = 600.0,
		attenuation: float = 1.5) -> Node:
	var stream := _sfx_stream(sfx_name)
	var cfg: Dictionary = SFX.get(sfx_name, {})
	var db := float(cfg.get("db", 0.0)) + randf_range(-VOLUME_SPREAD_DB, VOLUME_SPREAD_DB)
	if positional:
		var p2 := AudioStreamPlayer2D.new()
		p2.bus          = "SFX"
		p2.stream       = stream
		p2.pitch_scale  = random_pitch(sfx_name)
		p2.volume_db    = db
		p2.max_distance = max_distance
		p2.attenuation  = attenuation
		return p2
	var p := AudioStreamPlayer.new()
	p.bus         = "SFX"
	p.stream      = stream
	p.pitch_scale = random_pitch(sfx_name)
	p.volume_db   = db
	return p


## Start a loop at a random point so several copies never run in step.
func start_loop_desynced(player: Node) -> void:
	var stream: AudioStream = player.get("stream")
	if stream == null:
		return
	player.call("play", randf() * stream.get_length())


# ── Music ─────────────────────────────────────────────────────────────────────
## Crossfade to a track; the same track keeps playing untouched.
func play_music(track: String) -> void:
	if track == _music_name and _music != null and _music.playing:
		return
	var stream := _music_stream(track)
	if stream == null:
		return
	_ducked = false   # a new scene starts at full volume
	var next := _music_b if _music == _music_a else _music_a
	var prev := _music
	next.stream    = stream
	next.volume_db = -60.0
	next.play()
	_music      = next
	_music_name = track
	_retween_music(prev, MUSIC_FADE)


func duck_music(on: bool) -> void:
	if _ducked == on:
		return
	_ducked = on
	_retween_music(null, DUCK_FADE)


func _music_target_db() -> float:
	return MUSIC_DB + (DUCK_DB if _ducked else 0.0)


func _retween_music(fade_out: AudioStreamPlayer, duration: float) -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	if _music:
		_music_tween.tween_property(_music, "volume_db", _music_target_db(), duration)
	if fade_out and fade_out != _music and fade_out.playing:
		_music_tween.tween_property(fade_out, "volume_db", -60.0, duration)
		_music_tween.chain().tween_callback(fade_out.stop)


# ── Blue-world filter on the music ────────────────────────────────────────────
func _setup_lowpass() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx == -1:
		return
	for i in range(AudioServer.get_bus_effect_count(idx)):
		var fx := AudioServer.get_bus_effect(idx, i)
		if fx is AudioEffectLowPassFilter:
			_lowpass = fx
			return
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = LOWPASS_RED
	_lowpass.resonance = 0.5
	AudioServer.add_bus_effect(idx, _lowpass)


func _on_world_flipped(is_dark: bool) -> void:
	if _lowpass == null:
		return
	if _lowpass_tween and _lowpass_tween.is_valid():
		_lowpass_tween.kill()
	_lowpass_tween = create_tween()
	_lowpass_tween.tween_property(_lowpass, "cutoff_hz",
		LOWPASS_BLUE if is_dark else LOWPASS_RED, LOWPASS_FADE)


# ── Streams ───────────────────────────────────────────────────────────────────
func _sfx_stream(sfx_name: String) -> AudioStream:
	return _load_stream(SFX_DIR + sfx_name + ".mp3", sfx_name in LOOPED)


func _music_stream(track: String) -> AudioStream:
	return _load_stream(MUSIC_DIR + track + ".mp3", true)


func _load_stream(path: String, looped: bool) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("audio.gd: sound missing: %s" % path)
		return null
	if looped and "loop" in stream:
		stream.set("loop", true)
	_streams[path] = stream
	return stream
