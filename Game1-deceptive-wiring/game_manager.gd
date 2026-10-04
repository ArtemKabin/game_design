extends Node

enum LevelState { LOCKED, UNLOCKED, COMPLETED }

var current_level: int = 0
var level_states: Dictionary = {
	0: LevelState.UNLOCKED,
	1: LevelState.LOCKED,
	2: LevelState.LOCKED,
	3: LevelState.LOCKED,
	4: LevelState.LOCKED,
	5: LevelState.LOCKED
}

var level_failures: Dictionary = {
	0: 0,
	1: 0,
	2: 0,
	3: 0,
	4: 0,
	5: 0
}

signal hint_triggered(hint_text: String)
signal level_completed(level_id: int)
signal level_failed(level_id: int, reason: String)
signal oxygen_changed(current_oxygen: float, max_oxygen: float)

func register_failure(level_id: int, reason: String = "") -> void:
	level_failures[level_id] += 1
	emit_signal("level_failed", level_id, reason)
	if level_failures[level_id] >= 3:
		emit_signal("hint_triggered", get_hint_for_level(level_id))

func complete_level(level_id: int) -> void:
	level_states[level_id] = LevelState.COMPLETED
	var next_level: int = level_id + 1
	if level_states.has(next_level):
		level_states[next_level] = LevelState.UNLOCKED
	emit_signal("level_completed", level_id)

func get_hint_for_level(level_id: int) -> String:
	match level_id:
		0: return "Kennst du den Trick mit dem alten Röhrenfernseher? Manchmal hilft rohe Gewalt mehr als Präzision!"
		1: return "Manchmal muss man Probleme direkt anfahren. Und lass die Finger von den nervigen Quarantäne-Kabinen!"
		2: return "Wer steuert hier eigentlich das Schiff? Hör auf die Kabel und übernimm das Kommando!"
		3: return "Elektronik ist nicht alles. Manchmal braucht es handfestes Getriebe statt Digital-Schnickschnack."
		4: return "Glaub nicht alles, was das Handbuch dir sagt. Die Definition von Leistung ist hier verdreht."
		5: return "Vergiss alles, was logisch erscheint. Der falsche Weg ist der einzige Ausweg."
		_: return "Denke anders herum."
