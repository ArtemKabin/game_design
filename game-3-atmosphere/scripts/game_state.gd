extends Node
## Autoload "GameState": clock, week loop and player stats.
## Every action costs time (the core mechanic). Stress is derived from the
## other stats and lowers how much learning brings.

signal clock_changed(day: int, minutes: int)
signal stats_changed
signal message(text: String)
signal day_ended(day: int)
signal day_started(day: int)

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


## Loads another place (scene) and puts the player at `spawn` there.
func travel(scene_path: String, spawn: String, arrival_text := "") -> void:
	spawn_point = spawn
	arrival_message = arrival_text
	get_tree().change_scene_to_file.call_deferred(scene_path)


func _process(delta: float) -> void:
	if not running:
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
