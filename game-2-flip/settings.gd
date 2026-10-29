# settings.gd
# Autoload "Settings": player options, saved to user://settings.cfg (browser
# IndexedDB in the web export, see scoreboard.gd). Applied on start and
# whenever changed via the options menu (options_menu.gd).
#   fullscreen  – window mode (in the browser this needs a key press to take
#                 effect, which the options menu provides)
#   music / sfx – 0..100, mapped to the audio buses "Music" and "SFX"; sounds
#                 added later should play on those buses
#   controls    – one rebindable key per action (move_left, move_right,
#                 world_flip). The secondary keys from project.godot (arrows,
#                 Space, keypad Enter) stay as they are.
#   tips        – ids of help tips the player has unlocked by dying in a
#                 certain way (game.gd unlocks, help_menu.gd shows). The
#                 hunter's tip also prints a hint on the game-over screen once.
extends Node

const PATH := "user://settings.cfg"

const DEFAULT_CONTROLS := {
	"move_left":  KEY_A,
	"move_right": KEY_D,
	"world_flip": KEY_ENTER,
}

var fullscreen: bool = false
var music: int = 30
var sfx: int = 30
var controls: Dictionary = DEFAULT_CONTROLS.duplicate()
var tips: PackedStringArray = PackedStringArray()   # unlocked tip ids, see help_menu.gd

var _applied: Dictionary = {}   # action -> keycode currently added to the InputMap


func _ready() -> void:
	_ensure_buses()
	load_settings()
	apply()


# ── Apply ─────────────────────────────────────────────────────────────────────
func apply() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	_apply_volume("Music", music)
	_apply_volume("SFX", sfx)
	apply_controls()


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _apply_volume(bus_name: String, percent: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, percent <= 0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(percent, 1) / 100.0))


## Swap the primary key of each action in the InputMap for the configured one.
func apply_controls() -> void:
	for action in DEFAULT_CONTROLS:
		if not InputMap.has_action(action):
			continue
		var want: int = int(controls.get(action, DEFAULT_CONTROLS[action]))
		var prev: int = int(_applied.get(action, DEFAULT_CONTROLS[action]))
		_remove_key(action, prev)
		_add_key(action, want)
		_applied[action] = want


func _remove_key(action: String, keycode: int) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).keycode == keycode:
			InputMap.action_erase_event(action, ev)


func _add_key(action: String, keycode: int) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).keycode == keycode:
			return   # already there
	var ev := InputEventKey.new()
	ev.keycode = keycode as Key
	InputMap.action_add_event(action, ev)


# ── Setters (apply + save) ────────────────────────────────────────────────────
func set_fullscreen(v: bool) -> void:
	fullscreen = v
	apply()
	save_settings()


func set_music(v: int) -> void:
	music = clampi(v, 0, 100)
	apply()
	save_settings()


func set_sfx(v: int) -> void:
	sfx = clampi(v, 0, 100)
	apply()
	save_settings()


func set_control(action: String, keycode: int) -> void:
	if not DEFAULT_CONTROLS.has(action):
		return
	controls[action] = keycode
	apply_controls()
	save_settings()


func reset_controls() -> void:
	controls = DEFAULT_CONTROLS.duplicate()
	apply_controls()
	save_settings()


## Unlock a help tip. Returns true if it was new (the game-over screen then
## points the player to the help).
func unlock_tip(id: String) -> bool:
	if tips.has(id):
		return false
	tips.append(id)
	save_settings()
	return true


func is_tip_unlocked(id: String) -> bool:
	return tips.has(id)


## Display name of an action's primary key, e.g. "A", "ENTER", "LEFT".
func control_name(action: String) -> String:
	return OS.get_keycode_string(int(controls.get(action, DEFAULT_CONTROLS[action]))).to_upper()


# ── Persistence ───────────────────────────────────────────────────────────────
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	music      = clampi(int(cfg.get_value("audio", "music", music)), 0, 100)
	sfx        = clampi(int(cfg.get_value("audio", "sfx", sfx)), 0, 100)
	for action in DEFAULT_CONTROLS:
		controls[action] = int(cfg.get_value("controls", action, DEFAULT_CONTROLS[action]))
	tips = PackedStringArray(cfg.get_value("hints", "tips", tips))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	for action in DEFAULT_CONTROLS:
		cfg.set_value("controls", action, int(controls[action]))
	cfg.set_value("hints", "tips", tips)
	if cfg.save(PATH) != OK:
		push_warning("settings.gd: cannot write %s" % PATH)
