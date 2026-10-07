extends Node

# Global game state (autoload "GameManager").
# Scope is 3 levels, see docs/decisions/0006. Progress lives in memory only
# and resets when the game is closed. Good enough for a browser build.
# The ship is one scene (world.tscn, see decision 0014); rooms report progress here.

enum LevelState { LOCKED, UNLOCKED, COMPLETED }

const MAIN_MENU_SCENE := "res://main_menu.tscn"
const WORLD_SCENE := "res://world.tscn"
const HINT_AFTER_FAILURES := 3
# Shown at the bottom of every room. Rooms never write their own version.
const CONTROLS_TEXT := "Steuerung: WASD oder ← ↑ ↓ → = Bewegen  |  E = Interaktion  |  F = Schlagen  |  Esc = Menü"
# Room id of the cargo rail corridor between Level 0 and Level 1 (not a level, but it has hints).
const ROOM_CORRIDOR := 10

signal hint_triggered(hint_text: String)
signal level_completed(level_id: int)
signal level_failed(level_id: int, reason: String)

var current_level: int = 0
var level_states: Dictionary = {
	0: LevelState.UNLOCKED,
	1: LevelState.LOCKED,
	2: LevelState.LOCKED,
}
var level_failures: Dictionary = {}


# --- Scene flow -------------------------------------------------------------

func get_level_state(level_id: int) -> LevelState:
	return level_states.get(level_id, LevelState.LOCKED)


func go_to_world() -> void:
	_change_scene(WORLD_SCENE)


# Fresh game from the bridge. Used by the pause menu.
func restart_game() -> void:
	current_level = 0
	level_states = {0: LevelState.UNLOCKED, 1: LevelState.LOCKED, 2: LevelState.LOCKED}
	level_failures = {}
	go_to_world()


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)


# Deferred so scene changes are safe from inside physics callbacks.
func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)


# --- Progress ---------------------------------------------------------------

func register_failure(level_id: int, reason: String = "") -> void:
	level_failures[level_id] = level_failures.get(level_id, 0) + 1
	level_failed.emit(level_id, reason)
	if level_failures[level_id] >= HINT_AFTER_FAILURES:
		hint_triggered.emit(get_hint_for_level(level_id))


func complete_level(level_id: int) -> void:
	level_states[level_id] = LevelState.COMPLETED
	var next_level: int = level_id + 1
	if level_states.has(next_level) and level_states[next_level] == LevelState.LOCKED:
		level_states[next_level] = LevelState.UNLOCKED
	level_completed.emit(level_id)


func get_hint_for_level(level_id: int) -> String:
	match level_id:
		0: return "Kennst du den Trick mit dem alten Röhrenfernseher? Manchmal hilft rohe Gewalt mehr als Präzision!"
		1: return "Manchmal muss man Probleme direkt anfahren. Der Wagen hat keine Bremse, und das ist hier gut so."
		2: return "Vergiss alles, was logisch erscheint. Der falsche Weg ist der einzige Ausweg."
		ROOM_CORRIDOR: return "Der Wagen bremst nicht. Lenk früher, nicht stärker. Und lass die Taste wieder los."
		_: return "Denke anders herum."
