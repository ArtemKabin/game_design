extends Node

# Global game state (autoload "GameManager").
# Scope is 3 levels, see docs/decisions/0006. Progress lives in memory only
# and resets when the game is closed. Good enough for a browser build.

enum LevelState { LOCKED, UNLOCKED, COMPLETED }

const MAIN_MENU_SCENE := "res://main_menu.tscn"
const MAP_SCENE := "res://map_ui.tscn"
# Empty string = level has no scene yet. The map shows it but cannot start it.
const LEVEL_SCENES := {
	0: "res://level_0_bridge.tscn",
	1: "res://level_1_cargo_bay.tscn",
	2: "",
}
const HINT_AFTER_FAILURES := 3
# Shown at the bottom of every level. Levels read it in _ready so the wording stays identical.
const CONTROLS_TEXT := "Steuerung: WASD oder ← ↑ ↓ → = Bewegen  |  E = Interaktion  |  F = Schlagen"

signal hint_triggered(hint_text: String)
signal level_completed(level_id: int)
signal level_failed(level_id: int, reason: String)

var current_level: int = 0
var level_states: Dictionary = {
	0: LevelState.UNLOCKED,
	1: LevelState.LOCKED,
	2: LevelState.LOCKED,
}
var level_failures: Dictionary = {0: 0, 1: 0, 2: 0}


# --- Scene flow -------------------------------------------------------------

func get_level_state(level_id: int) -> LevelState:
	return level_states.get(level_id, LevelState.LOCKED)


func has_level_scene(level_id: int) -> bool:
	var path: String = LEVEL_SCENES.get(level_id, "")
	return path != "" and ResourceLoader.exists(path)


func start_level(level_id: int) -> void:
	if not has_level_scene(level_id):
		push_warning("GameManager: level %d has no scene yet." % level_id)
		return
	current_level = level_id
	get_tree().change_scene_to_file(LEVEL_SCENES[level_id])


func go_to_map() -> void:
	get_tree().change_scene_to_file(MAP_SCENE)


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


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
		1: return "Manchmal muss man Probleme direkt anfahren. Und lass die Finger von den nervigen Quarantäne-Kabinen!"
		2: return "Vergiss alles, was logisch erscheint. Der falsche Weg ist der einzige Ausweg."
		_: return "Denke anders herum."
