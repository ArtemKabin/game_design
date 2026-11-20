extends LectureGame
## Abgabe (Gebäude A, Friday 08:00–18:00): last check of the exercise sheet.
## Wrong formulas (red) pop up on the sheet, click them to fix them; correct
## ones (green) are traps. How hard it is comes from Prüfungssicherheit
## (GameState.difficulty): more readiness = errors stay longer, fewer traps.
## The result (0..1) becomes exam points (GameState.apply_minigame_result),
## then the week ends.

const ERRORS := ["(a+b)² = a²+b²", "e^0 = 0", "ln(1) = 1", "(x²)' = x", "sqrt(4) = -2",
	"2^3 = 6", "sin(0) = 1", "1/0 = 0", "(2x)' = 2x", "lim 1/n = 1", "x/x = 0"]
const CORRECT := ["(a+b)² = a²+2ab+b²", "e^0 = 1", "ln(1) = 0", "(x²)' = 2x", "sin(0) = 0", "2^3 = 8"]

var level := "mittel"


func _init() -> void:
	super()
	game_id = "submission"
	game_title = "Abgabe: Übungsblatt 1"
	goal_text = "Letzte Durchsicht vor der Abgabe. Falsche Rechnungen (rot) tauchen auf dem Blatt auf – klick sie an, um sie zu korrigieren, bevor sie wieder verschwinden."
	controls_text = "Maus: rote Fehler anklicken. Grüne Rechnungen sind richtig – NICHT anklicken."
	duration = 45.0
	accent = Color(0.9, 0.6, 0.25)
	use_slot_bonus = false
	combo_bonus = 0
	hit_points = 10
	decoy_penalty = 10
	miss_penalty = 5
	surface_title = "Übungsblatt 1 – Analysis"
	surface_color = C_PAPER
	title_color = C_TEXT_DARK
	term_color = Color(1.0, 0.86, 0.84)
	term_text = C_STRESS.darkened(0.45)
	decoy_color = Color(0.84, 0.95, 0.84)
	decoy_text = C_SATIETY.darkened(0.5)


func _setup() -> void:
	var r := GameState.difficulty()
	level = GameState.difficulty_name()
	life = lerpf(1.3, 2.6, r)
	interval = lerpf(0.5, 0.85, r)
	decoy_chance = lerpf(0.45, 0.15, r)
	# Par = every error caught: a 1,0 needs a nearly perfect run. Missed errors
	# and clicked traps cost points.
	par_score = roundf(duration / interval * (1.0 - decoy_chance) * hit_points)
	super()


func _next_word() -> Array:
	if randf() < decoy_chance:
		return [CORRECT.pick_random(), true]
	return [ERRORS.pick_random(), false]


func points_factor() -> float:
	return 0.5


func stress_change(ratio: float) -> float:
	return 6.0 - 16.0 * ratio


func energy_change(_ratio: float) -> float:
	return -8.0


func _result_extra() -> Dictionary:
	return {"on_time": false, "level": level}


func _intro_extra() -> String:
	return "Schwierigkeit: %s – deine Prüfungssicherheit liegt bei %d %%.\nJe sicherer du bist, desto länger bleiben Fehler sichtbar (jetzt %.1f s) und desto weniger Fallen gibt es (jetzt %d %%). Übersehene Fehler kosten Punkte.\nDas Ergebnis bringt bis zu %d Klausurpunkte. Danach ist die Woche vorbei." % [
		level, int(GameState.readiness), life, int(decoy_chance * 100.0), GameState.EXAM_POINTS_PER_SUBMISSION]


func _result_lines(ratio: float) -> PackedStringArray:
	var gained := int(round(ratio * GameState.EXAM_POINTS_PER_SUBMISSION))
	return PackedStringArray(["Klausurpunkte: +%d von %d  (Schwierigkeit %s)" % [gained, GameState.EXAM_POINTS_PER_SUBMISSION, level]])
