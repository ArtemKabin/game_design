extends Minigame
## Lerngruppe (Gebäude LB): memory with the study group. Turn over two cards;
## a thing from student life and what it is for are a pair and stay open.
## Everyday pairs on purpose: it tests memory, not subject knowledge. All pairs found =
## time bonus. Talking it through lowers stress. Played during its timetable
## slot (data/week.json) it gives LECTURE_BONUS times the study points.

const PAIRS := [
	["Mensa", "Mittagessen"],
	["Bibliothek", "Bücher ausleihen"],
	["Wecker", "Aufstehen"],
	["Kaffee", "Wach bleiben"],
	["Fahrrad", "Zur Uni fahren"],
	["Waschmaschine", "Wäsche waschen"],
	["Kühlschrank", "Essen kühl halten"],
	["Hörsaal", "Vorlesung"],
	["Rucksack", "Sachen tragen"],
	["Stundenplan", "Termine"],
	["Deadline", "Abgabe"],
	["Bett", "Schlafen"],
]
const PAIR_COUNT := 8
const PAIR_POINTS := 25
const MISS_POINTS := 4
const TIME_BONUS := 2   ## points per second left when all pairs are found
const C_BACK := Color(0.3, 0.62, 0.62)

var on_time := false
var _cards: Array[Button] = []
var _open: Array[Button] = []
var _found := 0
var _locked := false


func _init() -> void:
	game_id = "study_group"
	game_title = "Lerngruppe"
	goal_text = "Pause in der Lerngruppe: Lena hat ein Memory mitgebracht. Deck je zwei Karten auf – eine Sache aus dem Uni-Alltag und wofür sie da ist (z. B. Mensa – Mittagessen) bleiben offen."
	controls_text = "Maus: Karten aufdecken. Falsche Paare kosten Punkte, alle Paare gefunden = Zeitbonus."
	duration = 55.0
	par_score = 260.0
	accent = C_BACK.lightened(0.2)


func _setup() -> void:
	on_time = not GameState.slot_now(game_id).is_empty()
	make_panel(board, Rect2(Vector2.ZERO, board_size), C_WOOD.darkened(0.45), 0)
	var pairs := PAIRS.duplicate()
	pairs.shuffle()
	var faces: Array = []
	for i in PAIR_COUNT:
		faces.append([pairs[i][0], i, true])
		faces.append([pairs[i][1], i, false])
	faces.shuffle()
	var cols := 4
	var rows := 4
	var gap := 16.0
	var area := Rect2(board_size.x * 0.08, board_size.y * 0.07, board_size.x * 0.84, board_size.y * 0.86)
	var cs := Vector2((area.size.x - gap * (cols - 1)) / cols, (area.size.y - gap * (rows - 1)) / rows)
	for i in faces.size():
		var b := Button.new()
		b.position = area.position + Vector2(i % cols, i / cols) * (cs + Vector2(gap, gap))
		b.size = cs
		b.focus_mode = Control.FOCUS_NONE
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 18)
		b.set_meta("face", faces[i][0])
		b.set_meta("pair", faces[i][1])
		b.set_meta("term", faces[i][2])
		_style(b, false)
		b.pressed.connect(_on_card.bind(b))
		board.add_child(b)
		_cards.append(b)


func points_factor() -> float:
	return 0.9 * (GameState.LECTURE_BONUS if on_time else 1.0)


func stress_change(ratio: float) -> float:
	return -4.0 - 6.0 * ratio


func energy_change(_ratio: float) -> float:
	return -4.0


func _result_extra() -> Dictionary:
	return {"on_time": on_time}


func _intro_extra() -> String:
	if on_time:
		return "Die Gruppe trifft sich laut Stundenplan genau jetzt: Lernpunkte ×%.1f." % GameState.LECTURE_BONUS
	return "Außerhalb des Termins sind nur ein paar Leute da (kein Bonus)."


func _extra_text() -> String:
	return "Paare %d / %d" % [_found, PAIR_COUNT]


func _on_card(b: Button) -> void:
	if not is_playing() or _locked or b.has_meta("done") or _open.has(b):
		return
	_style(b, true)
	_open.append(b)
	if _open.size() < 2:
		return
	var a := _open[0]
	var c := _open[1]
	if a.get_meta("pair") == c.get_meta("pair"):
		_open.clear()
		_found += 1
		for x in [a, c]:
			x.set_meta("done", true)
			_style(x, true, true)
		add_points(PAIR_POINTS, c.get_global_rect().get_center(), "Paar! +%d" % PAIR_POINTS)
		if _found >= PAIR_COUNT:
			var bonus := int(ceil(time_left)) * TIME_BONUS
			if bonus > 0:
				add_points(bonus, board.get_global_rect().get_center(), "Alle Paare! Zeitbonus +%d" % bonus)
			finish()
	else:
		_locked = true
		add_points(-MISS_POINTS, c.get_global_rect().get_center())
		await get_tree().create_timer(0.8).timeout
		for x in [a, c]:
			if is_instance_valid(x):
				_style(x, false)
		_open.clear()
		_locked = false


func _style(b: Button, face_up: bool, done := false) -> void:
	b.text = b.get_meta("face") if face_up else "?"
	var col := C_BACK
	var txt := C_TEXT
	if face_up:
		col = C_SATIETY.lightened(0.45) if done else C_PAPER
		txt = C_TEXT_DARK if not b.get_meta("term") else C_READINESS.darkened(0.45)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col.lightened(0.1) if state == "hover" and not face_up else col
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(3)
		sb.border_color = col.darkened(0.35)
		b.add_theme_stylebox_override(state, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, txt)
