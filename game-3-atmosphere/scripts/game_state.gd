extends Node
## Autoload "GameState": clock, week loop and player stats.
## Every action costs time (the core mechanic). Stress is derived from the
## other stats and lowers how much learning brings.

signal clock_changed(day: int, minutes: int)
signal stats_changed
signal message(text: String)
signal day_ended(day: int)
signal day_started(day: int)
## Study points or found notes changed (after a minigame).
signal progress_changed

const DAY_NAMES := ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
const DAY_START := 8 * 60   # 08:00
const DAY_END := 22 * 60    # 22:00
## 14 h game day in 14 min real time.
const GAME_MINUTES_PER_SECOND := 1.0

## Passive change per game hour.
const ENERGY_PER_HOUR := -3.0
const SATIETY_PER_HOUR := -6.0
## Overnight.
const SLEEP_ENERGY := 45.0
const NIGHT_SATIETY := -15.0

## Minigames (scripts/minigames/): every POINTS_PER_READINESS study points
## become 1 Prüfungssicherheit (scaled by learn_factor like any learning).
const POINTS_PER_READINESS := 40.0
## Each found note makes the study journal give 10 % more, up to +100 %.
const NOTE_BONUS_PER_NOTE := 0.1
const NOTE_BONUS_MAX := 1.0
const HUB_SCENE := "res://scenes/main.tscn"

var week := 1
var day := 0
var minutes := float(DAY_START)
var running := true

var energy := 80.0        ## 0..100, high is good
var satiety := 70.0       ## 0..100, high is good (low = hungry)
var readiness := 10.0     ## Prüfungssicherheit 0..100
var stress := 10.0        ## 0..100, derived, high is bad
var money := 40.0         ## Euro

## Set by a Portal before a scene change: name of the Marker3D under
## "Spawns" in the next scene, and a message to show after arriving.
var spawn_point := ""
var arrival_message := ""

## Progress from the minigames ("growing" exam readiness).
var study_points := 0     ## Lernpunkte, all time
var notes_found := 0      ## lost study notes found while cleaning
var minigame_best := {}   ## minigame id -> best score
var minigame_runs := {}   ## minigame id -> finished runs
var minigame_last_day := {}  ## minigame id -> absolute day of the last run

## While a minigame runs the clock stands still. Its time and rewards are
## applied when the player is back in the hub (apply_minigame_result).
var in_minigame := false
var _return_scene := ""
var _return_position := Vector3.ZERO
var _has_return := false
var _minigame_minutes := 0
var _pending_result := {}


## Loads another place (scene) and puts the player at `spawn` there.
func travel(scene_path: String, spawn: String, arrival_text := "") -> void:
	spawn_point = spawn
	arrival_message = arrival_text
	get_tree().change_scene_to_file.call_deferred(scene_path)


func _process(delta: float) -> void:
	if not running or in_minigame:
		return
	_advance(delta * GAME_MINUTES_PER_SECOND)
	stress = move_toward(stress, _stress_target(), delta * 4.0)
	stats_changed.emit()


func day_name() -> String:
	return DAY_NAMES[day]


func clock_text() -> String:
	var m := int(minutes)
	return "%02d:%02d" % [m / 60, m % 60]


func is_weekend() -> bool:
	return day >= 5


## Learning multiplier: full stress halves what learning brings.
func learn_factor() -> float:
	return 1.0 - stress / 200.0


func can_afford(cost: float) -> bool:
	return money >= cost


## Applies an action: spends time, then changes stats. Positive readiness
## gains are scaled by learn_factor(). Returns false if money is missing.
func do_action(spend_minutes: int, d_energy := 0.0, d_satiety := 0.0,
		d_readiness := 0.0, d_stress := 0.0, d_money := 0.0) -> bool:
	if d_money < 0.0 and not can_afford(-d_money):
		message.emit("Nicht genug Geld.")
		return false
	_advance(spend_minutes)
	energy = clampf(energy + d_energy, 0.0, 100.0)
	satiety = clampf(satiety + d_satiety, 0.0, 100.0)
	if d_readiness > 0.0:
		d_readiness *= learn_factor()
	readiness = clampf(readiness + d_readiness, 0.0, 100.0)
	stress = clampf(stress + d_stress, 0.0, 100.0)
	money += d_money
	stats_changed.emit()
	return true


## Study-point multiplier from found notes (used by the study journal).
## `extra`: notes not counted yet (preview on a results screen).
func note_multiplier(extra := 0) -> float:
	return 1.0 + minf((notes_found + extra) * NOTE_BONUS_PER_NOTE, NOTE_BONUS_MAX)


## How much Prüfungssicherheit `points` study points bring right now.
func readiness_for_points(points: int) -> float:
	return points / POINTS_PER_READINESS * learn_factor()


func absolute_day() -> int:
	return (week - 1) * DAY_NAMES.size() + day


func minigame_done_today(id: String) -> bool:
	return int(minigame_last_day.get(id, -1)) == absolute_day()


## Opens a full-screen minigame. The player comes back to `return_position`
## in the current scene; `spend_minutes` is charged on return.
func start_minigame(scene_path: String, return_position: Vector3, spend_minutes: int) -> void:
	_return_scene = get_tree().current_scene.scene_file_path
	_return_position = return_position
	_has_return = true
	_minigame_minutes = spend_minutes
	_pending_result = {}
	in_minigame = true
	get_tree().change_scene_to_file.call_deferred(scene_path)


func minigame_minutes() -> int:
	return _minigame_minutes


## Called by the minigame when the player leaves it. `result` keys: id, title,
## completed, score, points, notes, d_energy, d_stress.
func end_minigame(result: Dictionary) -> void:
	in_minigame = false
	_pending_result = result
	var scene := _return_scene if _return_scene != "" else HUB_SCENE
	get_tree().change_scene_to_file.call_deferred(scene)


## Used by level.gd after loading: where the player stood before the minigame.
func take_return_position() -> Variant:
	if not _has_return:
		return null
	_has_return = false
	return _return_position


## Called by level.gd once the hub is loaded (so the HUD sees the changes).
func apply_minigame_result() -> void:
	if _pending_result.is_empty():
		return
	var r := _pending_result
	_pending_result = {}
	var title: String = r.get("title", "Minispiel")
	if not r.get("completed", false):
		message.emit(title + " abgebrochen.")
		return
	var id: String = r.get("id", "")
	var points := int(r.get("points", 0))
	var notes := int(r.get("notes", 0))
	minigame_runs[id] = int(minigame_runs.get(id, 0)) + 1
	minigame_best[id] = maxi(int(minigame_best.get(id, 0)), int(r.get("score", 0)))
	minigame_last_day[id] = absolute_day()
	study_points += points
	notes_found += notes
	progress_changed.emit()
	var text := "%s: +%d Lernpunkte" % [title, points]
	if notes > 0:
		text += " · %d Notiz%s gefunden" % [notes, "en" if notes > 1 else ""]
	message.emit(text)
	do_action(_minigame_minutes, float(r.get("d_energy", 0.0)), 0.0,
			points / POINTS_PER_READINESS, float(r.get("d_stress", 0.0)))


func _advance(game_minutes: float) -> void:
	var hours := game_minutes / 60.0
	energy = clampf(energy + ENERGY_PER_HOUR * hours, 0.0, 100.0)
	satiety = clampf(satiety + SATIETY_PER_HOUR * hours, 0.0, 100.0)
	minutes += game_minutes
	clock_changed.emit(day, int(minutes))
	if minutes >= DAY_END and running:
		_end_day()


## Stress comes from being tired, hungry and from the deadline at the end of
## the week getting closer while readiness is low.
func _stress_target() -> float:
	var body := (100.0 - energy) * 0.3 + (100.0 - satiety) * 0.3
	var week_progress := clampf((day + (minutes - DAY_START) / (DAY_END - DAY_START)) / 5.0, 0.0, 1.0)
	var deadline := week_progress * 45.0 * (1.0 - readiness / 100.0)
	if is_weekend():
		deadline *= 0.3
	return clampf(body + deadline, 0.0, 100.0)


func _end_day() -> void:
	running = false
	minutes = DAY_END
	day_ended.emit(day)
	await get_tree().create_timer(2.5).timeout
	energy = clampf(energy + SLEEP_ENERGY, 0.0, 100.0)
	satiety = clampf(satiety + NIGHT_SATIETY, 0.0, 100.0)
	day += 1
	if day >= DAY_NAMES.size():
		day = 0
		week += 1
	minutes = DAY_START
	running = true
	day_started.emit(day)
	clock_changed.emit(day, int(minutes))
	stats_changed.emit()
