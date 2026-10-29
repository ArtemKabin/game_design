# scoreboard.gd
# Autoload "Scoreboard": the local best list, MAX_ENTRIES scores, highest first.
# Stored as JSON in user://scores.json. In the web export user:// lives in the
# browser's IndexedDB, so the list survives reloads and new visits without any
# download, login or server. On desktop it is a file in the Godot user folder.
extends Node

const PATH        := "user://scores.json"
const MAX_ENTRIES := 10

var scores: Array[int] = []   # sorted, highest first


func _ready() -> void:
	load_scores()


## Adds a score. Returns its 1-based rank in the list, or 0 if it did not make it.
func add(score: int) -> int:
	scores.append(score)
	scores.sort()
	scores.reverse()
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)
	save_scores()
	var rank := scores.find(score)
	return rank + 1 if rank >= 0 else 0


func best() -> int:
	return scores[0] if not scores.is_empty() else 0


func load_scores() -> void:
	scores.clear()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Array:
		for v in data:
			if v is float or v is int:
				scores.append(int(v))
	scores.sort()
	scores.reverse()
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)


func save_scores() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("scoreboard.gd: cannot write %s" % PATH)
		return
	f.store_string(JSON.stringify(scores))
	f.close()
