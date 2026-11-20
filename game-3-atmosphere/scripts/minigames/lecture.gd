class_name LectureGame
extends Minigame
## Vorlesung (Gebäude B): key terms pop up on the blackboard for a few
## seconds, click them to note them down (combo for a streak). Red phone
## distractions cost points. Played during its timetable slot (data/week.json)
## it gives LECTURE_BONUS times the study points.
## submission.gd reuses this with other words, a sheet of paper and a
## difficulty taken from Prüfungssicherheit.

const TERMS := ["Ableitung", "Integral", "Grenzwert", "Kettenregel", "Taylorreihe", "Extremwert",
	"Stetigkeit", "Folge", "Reihe", "Varianz", "Median", "Normalverteilung", "p-Wert", "Regression"]
const DISTRACTIONS := ["Insta: 12 neue Likes", "Gruppenchat (47)", "Mensa: Pommes!",
	"Meme von Tom", "Akku 5 %", "Story ansehen?"]
const TARGET_SIZE := Vector2(190, 58)

## Seconds a target stays, seconds between targets, share of distractions.
var life := 2.4
var interval := 0.62
var decoy_chance := 0.35
var hit_points := 10
var combo_bonus := 2
var decoy_penalty := 8
## Points lost when a key term disappears unclicked.
var miss_penalty := 3
var use_slot_bonus := true
var surface_title := "Analysis – Kapitel 3: Ableitungen"
var surface_color := Color(0.16, 0.3, 0.24)
var title_color := C_PAPER.darkened(0.1)
var term_color := C_PAPER
var term_text := C_TEXT_DARK
var decoy_color := C_STRESS
var decoy_text := C_TEXT

var on_time := false
var _surface := Rect2()
var _spawn := 0.0
var _combo := 0
var _targets: Array[Button] = []


func _init() -> void:
	game_id = "lecture"
	game_title = "Vorlesung"
	goal_text = "Der Prof redet schnell. Klick die Fachbegriffe an der Tafel an, bevor sie wieder weggewischt sind – so landen sie in deiner Mitschrift."
	controls_text = "Maus: Begriffe anklicken. Treffer in Folge geben eine Kombo. Rote Handy-Nachrichten NICHT anklicken."
	duration = 45.0
	par_score = 560.0
	accent = C_READINESS


func _setup() -> void:
	on_time = use_slot_bonus and not GameState.slot_now(game_id).is_empty()
	make_panel(board, Rect2(Vector2.ZERO, board_size), C_WALL.darkened(0.55), 0)
	_surface = Rect2(board_size.x * 0.06, board_size.y * 0.08, board_size.x * 0.88, board_size.y * 0.84)
	make_panel(board, _surface.grow(10), C_WOOD.darkened(0.3), 10)
	make_panel(board, _surface, surface_color, 6)
	var t := make_label(board, surface_title, 20, title_color, false)
	t.position = _surface.position + Vector2(18, 10)


func _tick(delta: float) -> void:
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = interval * randf_range(0.7, 1.3)
		_spawn_target()


func _on_finish() -> void:
	for b in _targets:
		if is_instance_valid(b):
			b.disabled = true


func points_factor() -> float:
	return 0.8 * (GameState.LECTURE_BONUS if on_time else 1.0)


func stress_change(ratio: float) -> float:
	return 3.0 - 9.0 * ratio


func energy_change(_ratio: float) -> float:
	return -6.0


func _result_extra() -> Dictionary:
	return {"on_time": on_time}


func _intro_extra() -> String:
	if not use_slot_bonus:
		return ""
	if on_time:
		return "Pünktlich laut Stundenplan: Lernpunkte ×%.1f." % GameState.LECTURE_BONUS
	return "Laut Stundenplan läuft gerade keine Vorlesung – du arbeitest die Aufzeichnung nach (kein Bonus)."


func _extra_text() -> String:
	return "Kombo ×%d" % _combo if _combo > 1 else ""


## Words for the next target: [text, is_decoy].
func _next_word() -> Array:
	if randf() < decoy_chance:
		return [DISTRACTIONS.pick_random(), true]
	return [TERMS.pick_random(), false]


func _spawn_target() -> void:
	var w := _next_word()
	var decoy: bool = w[1]
	var b := Button.new()
	b.text = w[0]
	b.size = TARGET_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 17)
	var col := decoy_color if decoy else term_color
	var txt := decoy_text if decoy else term_text
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col.lightened(0.12) if state == "hover" else col
		sb.set_corner_radius_all(8)
		sb.set_border_width_all(3)
		sb.border_color = col.darkened(0.35)
		b.add_theme_stylebox_override(state, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, txt)
	var area := Rect2(_surface.position + Vector2(10, 44), _surface.size - Vector2(20, 54))
	b.position = _free_spot(area)
	b.pivot_offset = TARGET_SIZE * 0.5
	board.add_child(b)
	_targets.append(b)
	b.pressed.connect(_on_hit.bind(b, decoy))
	b.scale = Vector2(0.6, 0.6)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.12)
	tw.tween_interval(life * 0.6)
	tw.tween_property(b, "modulate:a", 0.25, life * 0.4)
	tw.tween_callback(_on_expire.bind(b, decoy))


func _free_spot(area: Rect2) -> Vector2:
	var p := random_point_in(area, TARGET_SIZE)
	for _i in 12:
		var ok := true
		for o in _targets:
			if is_instance_valid(o) and Rect2(o.position, TARGET_SIZE).grow(6).intersects(Rect2(p, TARGET_SIZE)):
				ok = false
				break
		if ok:
			return p
		p = random_point_in(area, TARGET_SIZE)
	return p


func _on_hit(b: Button, decoy: bool) -> void:
	if not is_playing() or not is_instance_valid(b):
		return
	var at := b.get_global_rect().get_center()
	if decoy:
		_combo = 0
		add_points(-decoy_penalty, at, "Abgelenkt! -%d" % decoy_penalty)
	else:
		_combo += 1
		add_points(hit_points + combo_bonus * mini(_combo - 1, 5), at)
	_remove(b)


func _on_expire(b: Button, decoy: bool) -> void:
	if not is_instance_valid(b) or b.disabled:
		return
	if not decoy and is_playing():
		_combo = 0
		add_points(-miss_penalty, b.get_global_rect().get_center(), "verpasst -%d" % miss_penalty)
	_remove(b)


func _remove(b: Button) -> void:
	_targets.erase(b)
	b.disabled = true
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(0.2, 0.2), 0.12)
	tw.tween_callback(b.queue_free)
