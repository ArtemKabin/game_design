extends Node
## Autoload "GameState": clock, week loop and player stats.
## Every action costs time (the core mechanic). Stress is derived from the
## other stats and lowers how much learning brings. Events (actions,
## minigames, NPC encounters) also shift a slowly fading mood offset, so
## their effect on stress lasts a few hours.
## Also the persistent progress: study points, found notes, minigame records,
## story progress of the NPC encounters (see encounters.gd).

signal clock_changed(day: int, minutes: int)
signal stats_changed
signal message(text: String)
signal day_ended(day: int)
signal day_started(day: int)
## Study points or found notes changed (after a minigame).
signal progress_changed
## The demo week is over (submission done or deadline missed), before the
## week summary is loaded.
signal week_finished

const DAY_NAMES := ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
const DAY_START := 8 * 60   # 08:00
const DAY_END := 22 * 60    # 22:00
## 14 h game day in ~4.7 min real time (demo pace, see specs/001-demo-gameloop).
const GAME_MINUTES_PER_SECOND := 3.0

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
## Lasting stress offset from events, fades by this much per game hour.
const MOOD_DECAY_PER_HOUR := 4.0
const MOOD_LIMIT := 40.0

## Demo week (data/week.json): timetable, to-dos, Friday submission.
const WEEK_DATA := "res://data/week.json"
const SUMMARY_SCENE := "res://scenes/ui/week_summary.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## A lecture played during its timetable slot (or up to this many minutes
## before) gives more study points.
const SLOT_EARLY_MINUTES := 30
const LECTURE_BONUS := 1.3
## The submission's result (0..1) becomes up to this many exam points.
const EXAM_POINTS_PER_SUBMISSION := 25
## The big exam comes after this many week loops (final release).
const EXAM_LOOPS := 3
## Forgetting: time that is not spent learning (other actions, idling,
## sleeping) slowly takes Prüfungssicherheit away again, at most this share
## of everything learned so far. Grinding one thing and sleeping until the
## deadline therefore costs up to half of it.
const FORGET_PER_HOUR := 1.0
const FORGET_MAX_SHARE := 0.5
## Hours of forgetting per night.
const NIGHT_HOURS := 10.0

var week := 1
var day := 0
var minutes := float(DAY_START)
## False in the menu; reset_week() starts the clock.
var running := false
var started := false

var energy := 80.0        ## 0..100, high is good
var satiety := 70.0       ## 0..100, high is good (low = hungry)
var readiness := 10.0     ## Prüfungssicherheit 0..100
var stress := 10.0        ## 0..100, derived, high is bad
var money := 40.0         ## Euro
var mood := 0.0           ## lasting stress offset from events, fades over time

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

## NPC encounters (encounters.gd, data/encounters.json).
var story_index := 0         ## next scripted story beat
var story_seen: Array[String] = []
var npc_last_met := {}       ## npc id -> absolute day of the last random encounter
var encounter_seed := randi()  ## per playthrough; random encounters are seeded per NPC and day
var in_dialogue := false     ## clock and player stand still while talking
var in_phone := false        ## clock and player stand still while the phone is open

## Demo week loop.
var week_data := {}          ## data/week.json
var week_runs := {}          ## minigame id -> finished runs this week (to-dos)
var lectures_on_time := 0    ## lectures played during their timetable slot
var submission := {}         ## {done, grade, ratio, level, exam_points, reason}
var readiness_earned := 0.0  ## Prüfungssicherheit gained by learning this week
var readiness_forgotten := 0.0  ## taken away again by forgetting (<= FORGET_MAX_SHARE of earned)
var week_over := false
## Global exam preparation, kept across week loops (not reset by reset_week).
var exam_points := 0
var loops_done := 0


func _ready() -> void:
	var f := FileAccess.open(WEEK_DATA, FileAccess.READ)
	if f:
		var data: Variant = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			week_data = data
	if week_data.is_empty():
		push_error("Could not load " + WEEK_DATA)


## Start values for a new week loop ("Neues Spiel"). exam_points and
## loops_done stay: they are the progress towards the exam.
func reset_week() -> void:
	week = 1
	day = 0
	minutes = float(DAY_START)
	running = true
	started = true
	energy = 80.0
	satiety = 70.0
	readiness = 10.0
	stress = 10.0
	money = 40.0
	mood = 0.0
	spawn_point = ""
	arrival_message = ""
	study_points = 0
	notes_found = 0
	minigame_best = {}
	minigame_runs = {}
	minigame_last_day = {}
	in_minigame = false
	_return_scene = ""
	_has_return = false
	_pending_result = {}
	story_index = 0
	story_seen.clear()
	npc_last_met = {}
	encounter_seed = randi()
	in_dialogue = false
	in_phone = false
	week_runs = {}
	lectures_on_time = 0
	submission = {}
	readiness_earned = 0.0
	readiness_forgotten = 0.0
	week_over = false


## Used by level.gd: a scene started directly from the editor gets a fresh week.
func ensure_started() -> void:
	if not started:
		reset_week()


## True while the player may act (clock runs, nothing on top of the world).
func is_free() -> bool:
	return running and not in_dialogue and not in_phone and not week_over


static func parse_time(text: String) -> int:
	var parts := text.split(":")
	return int(parts[0]) * 60 + int(parts[1])


func schedule_for(d: int) -> Array:
	var out: Array = []
	for e in week_data.get("schedule", []):
		if int(e["day"]) == d:
			out.append(e)
	return out


## The timetable slot of `station` that runs today right now (or starts within
## SLOT_EARLY_MINUTES), else {}.
func slot_now(station: String) -> Dictionary:
	for e in schedule_for(day):
		if e.get("station", "") != station:
			continue
		if minutes >= parse_time(e["start"]) - SLOT_EARLY_MINUTES and minutes < parse_time(e["end"]):
			return e
	return {}


func submission_info() -> Dictionary:
	return week_data.get("submission", {"day": 4, "start": "08:00", "end": "18:00", "place": "Gebäude A"})


func submission_open() -> bool:
	var s := submission_info()
	return day == int(s["day"]) and minutes >= parse_time(s["start"]) \
			and minutes < parse_time(s["end"]) and not submission.get("done", false)


## 0..1, how easy the submission is: grows with Prüfungssicherheit.
func difficulty() -> float:
	return clampf(readiness / 100.0, 0.0, 1.0)


func difficulty_name() -> String:
	var r := difficulty()
	if r < 0.25:
		return "schwer"
	if r < 0.6:
		return "mittel"
	return "leicht"


func todo_progress(todo: Dictionary) -> int:
	var station: String = todo.get("station", "")
	if station == "submission":
		return 1 if submission.get("done", false) else 0
	return int(week_runs.get(station, 0))


func todos_done() -> int:
	var n := 0
	for t in week_data.get("todos", []):
		if todo_progress(t) >= int(t.get("target", 1)):
			n += 1
	return n


## Bed: ends the day now. On submission day without a submission this ends
## the week (deadline missed).
func sleep_now() -> void:
	if not is_free():
		return
	var s := submission_info()
	if day == int(s["day"]) and not submission.get("done", false):
		finish_week("slept")
		return
	var left := DAY_END - minutes
	_forget(left / 60.0)
	# Sleeping early: hunger keeps going, but the extra sleep restores a bit.
	satiety = clampf(satiety + SATIETY_PER_HOUR * left / 60.0, 0.0, 100.0)
	energy = clampf(energy + 2.0 * left / 60.0, 0.0, 100.0)
	minutes = DAY_END
	clock_changed.emit(day, int(minutes))
	_end_day()


## Ends the demo week and shows the week summary.
## `reason` for a missed submission: "deadline" or "slept".
func finish_week(reason := "deadline") -> void:
	if week_over:
		return
	week_over = true
	running = false
	in_phone = false
	if not submission.get("done", false):
		submission = {"done": false, "grade": "5,0", "ratio": 0.0, "exam_points": 0, "reason": reason}
	loops_done += 1
	week_finished.emit()
	get_tree().change_scene_to_file.call_deferred(SUMMARY_SCENE)


## Loads another place (scene) and puts the player at `spawn` there.
func travel(scene_path: String, spawn: String, arrival_text := "") -> void:
	spawn_point = spawn
	arrival_message = arrival_text
	get_tree().change_scene_to_file.call_deferred(scene_path)


func _process(delta: float) -> void:
	if not running or in_minigame or in_dialogue or in_phone:
		return
	_advance(delta * GAME_MINUTES_PER_SECOND, false)
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
	var learning := d_readiness > 0.0
	_advance(spend_minutes, learning)
	energy = clampf(energy + d_energy, 0.0, 100.0)
	satiety = clampf(satiety + d_satiety, 0.0, 100.0)
	if learning:
		d_readiness *= learn_factor()
	var before := readiness
	readiness = clampf(readiness + d_readiness, 0.0, 100.0)
	if learning:
		readiness_earned += readiness - before
	stress = clampf(stress + d_stress, 0.0, 100.0)
	mood = clampf(mood + d_stress, -MOOD_LIMIT, MOOD_LIMIT)
	money += d_money
	stats_changed.emit()
	return true


## Study-point multiplier from found notes (used by the study journal).
## `extra`: notes not counted yet (preview on a results screen).
func note_multiplier(extra := 0) -> float:
	return 1.0 + minf((notes_found + extra) * NOTE_BONUS_PER_NOTE, NOTE_BONUS_MAX)


## Adds study points and found notes (minigames, encounters). Notes can
## also be lost (lent to someone), never below 0.
func add_progress(points: int, notes: int) -> void:
	study_points += points
	notes_found = maxi(notes_found + notes, 0)
	progress_changed.emit()


## Prüfungssicherheit for `points` study points before learn_factor.
func points_to_readiness(points: int) -> float:
	return points / POINTS_PER_READINESS


func total_runs() -> int:
	var n := 0
	for id in minigame_runs:
		n += int(minigame_runs[id])
	return n


func met_today(npc_id: String) -> bool:
	return int(npc_last_met.get(npc_id, -1)) == absolute_day()


func mark_met(npc_id: String) -> void:
	npc_last_met[npc_id] = absolute_day()


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
	week_runs[id] = int(week_runs.get(id, 0)) + 1
	if r.get("on_time", false):
		lectures_on_time += 1
	if id == "submission":
		var gained := int(round(float(r.get("ratio", 0.0)) * EXAM_POINTS_PER_SUBMISSION))
		submission = {"done": true, "grade": r.get("grade", "5,0"), "ratio": r.get("ratio", 0.0),
				"level": r.get("level", ""), "exam_points": gained}
		exam_points += gained
	study_points += points
	notes_found += notes
	progress_changed.emit()
	var text := "%s: +%d Lernpunkte" % [title, points]
	if notes > 0:
		text += " · %d Notiz%s gefunden" % [notes, "en" if notes > 1 else ""]
	message.emit(text)
	do_action(_minigame_minutes, float(r.get("d_energy", 0.0)), 0.0,
			points / POINTS_PER_READINESS, float(r.get("d_stress", 0.0)))
	if id == "submission":
		finish_week()


## How much Prüfungssicherheit can still be forgotten.
func forgettable() -> float:
	return maxf(readiness_earned * FORGET_MAX_SHARE - readiness_forgotten, 0.0)


func _forget(hours: float) -> void:
	var amount := minf(FORGET_PER_HOUR * hours, minf(forgettable(), readiness))
	if amount <= 0.0:
		return
	readiness -= amount
	readiness_forgotten += amount


## `learning`: the time is spent learning, so nothing is forgotten.
func _advance(game_minutes: float, learning := false) -> void:
	var hours := game_minutes / 60.0
	if not learning:
		_forget(hours)
	energy = clampf(energy + ENERGY_PER_HOUR * hours, 0.0, 100.0)
	satiety = clampf(satiety + SATIETY_PER_HOUR * hours, 0.0, 100.0)
	mood = move_toward(mood, 0.0, MOOD_DECAY_PER_HOUR * hours)
	minutes += game_minutes
	clock_changed.emit(day, int(minutes))
	var s := submission_info()
	if running and day == int(s["day"]) and minutes >= parse_time(s["end"]) \
			and not submission.get("done", false):
		finish_week()
		return
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
	return clampf(body + deadline + mood, 0.0, 100.0)


func _end_day() -> void:
	running = false
	minutes = DAY_END
	day_ended.emit(day)
	await get_tree().create_timer(2.5).timeout
	if week_over:
		return
	_forget(NIGHT_HOURS)
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
