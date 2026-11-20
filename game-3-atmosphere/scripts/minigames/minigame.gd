class_name Minigame
extends Control
## Base of the full-screen minigames (scenes/minigames/). Builds the frame all
## of them share in code, like the HUD: top bar with title, timer, points and
## found notes, an intro card, a results card with a German grade, floating
## point toasts and the stress vignette (gets stronger in the last seconds).
##
## The clock in GameState stands still while a minigame runs. Leaving sends
## the result to GameState.end_minigame; the hub then charges the time of the
## trigger and adds the rewards.
##
## Subclasses set the vars below in _init() and override the hooks
## (_setup, _on_start, _tick, _on_note_found, points_factor, ...).
## Board coordinates: `board` starts below the top bar, size `board_size`.

enum Phase { INTRO, PLAY, RESULTS }

## Greybox palette: the colours of the 3D blocks and the HUD bars.
const C_BG := Color(0.13, 0.13, 0.15)
const C_WALL := Color(0.62, 0.6, 0.57)
const C_WOOD := Color(0.55, 0.42, 0.3)
const C_PAPER := Color(0.95, 0.93, 0.86)
const C_READINESS := Color(0.35, 0.6, 1.0)
const C_ENERGY := Color(0.98, 0.8, 0.25)
const C_SATIETY := Color(0.45, 0.8, 0.4)
const C_STRESS := Color(0.95, 0.3, 0.3)
const C_TEXT := Color(0.95, 0.95, 0.95)
const C_TEXT_DARK := Color(0.12, 0.12, 0.14)

const TOP_BAR := 64.0
const NOTE_POINTS := 15
const GRADES := [[0.95, "1,0"], [0.9, "1,3"], [0.85, "1,7"], [0.8, "2,0"], [0.75, "2,3"],
	[0.7, "2,7"], [0.65, "3,0"], [0.6, "3,3"], [0.55, "3,7"], [0.5, "4,0"]]

var game_id := "minigame"
var game_title := "Minispiel"
var goal_text := ""
var controls_text := ""
var duration := 60.0
## Score that counts as a perfect run (grade 1,0).
var par_score := 300.0
var accent := C_READINESS

var phase := Phase.INTRO
var score := 0
var notes := 0
var time_left := 0.0
var board: Control
var board_size := Vector2.ZERO

var _timer_fill: StyleBoxFlat
var _timer_bar: ProgressBar
var _time_label: Label
var _score_label: Label
var _notes_label: Label
var _extra_label: Label
var _vignette: ColorRect
var _overlay: Control
var _result := {}
var _leaving := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	board = Control.new()
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.position = Vector2(0, TOP_BAR)
	board_size = Vector2(view.x, view.y - TOP_BAR)
	board.size = board_size
	add_child(board)

	_vignette = ColorRect.new()
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/stress_vignette.gdshader")
	_vignette.material = mat
	add_child(_vignette)

	_build_top_bar(view)
	time_left = duration
	_setup()
	_update_top_bar()
	_show_intro()


func _process(delta: float) -> void:
	var urgency := 0.0
	if phase == Phase.PLAY:
		time_left = maxf(time_left - delta, 0.0)
		_tick(delta)
		_update_top_bar()
		urgency = clampf(1.0 - time_left / 10.0, 0.0, 1.0)
		if time_left <= 0.0:
			finish()
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
	var stress := GameState.stress / 100.0 + urgency * (0.35 + 0.25 * pulse)
	(_vignette.material as ShaderMaterial).set_shader_parameter("stress", clampf(stress, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match phase:
			Phase.INTRO:
				_abort()
			Phase.PLAY:
				finish()
			Phase.RESULTS:
				_leave()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		match phase:
			Phase.INTRO:
				_start()
			Phase.RESULTS:
				_leave()
		get_viewport().set_input_as_handled()


# --- Hooks for the minigames -------------------------------------------------

## Build the board (called once, before the intro card is shown).
func _setup() -> void:
	pass


func _on_start() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


## Called after the timer ran out (or the player gave up), before scoring.
func _on_finish() -> void:
	pass


func _on_note_found(_at: Vector2) -> void:
	pass


## Score -> study points.
func points_factor() -> float:
	return 1.0


func stress_change(_ratio: float) -> float:
	return 0.0


func energy_change(_ratio: float) -> float:
	return 0.0


## Extra fields for the result sent to GameState (e.g. on_time, level).
func _result_extra() -> Dictionary:
	return {}


## Extra lines on the results card, `ratio` = score / par_score (0..1).
func _result_lines(_ratio: float) -> PackedStringArray:
	return PackedStringArray()


## Shown under the title in the top bar while playing.
func _extra_text() -> String:
	return ""


## Extra line on the intro card.
func _intro_extra() -> String:
	return ""


# --- Helpers ----------------------------------------------------------------

func is_playing() -> bool:
	return phase == Phase.PLAY


func add_points(amount: int, at: Vector2, text := "") -> void:
	score = maxi(score + amount, 0)
	toast(text if text != "" else "%+d" % amount, at, C_SATIETY if amount >= 0 else C_STRESS)
	_flash(_score_label)


## A lost study note was found (clicked) at `at` (global).
func found_note(at: Vector2) -> void:
	notes += 1
	score += NOTE_POINTS
	toast("Notiz gefunden! +%d" % NOTE_POINTS, at, C_PAPER)
	_flash(_notes_label)
	_on_note_found(at)


## Hides a note slip under `item` (a child of `board`), a corner peeks out.
## Clicking it calls found_note.
func bury_note(item: Control) -> DragItem:
	var note := DragItem.new()
	note.setup("Notiz", C_PAPER, Vector2(66, 44), 14)
	note.label.add_theme_color_override("font_color", C_READINESS.darkened(0.3))
	note.kind = "note"
	note.rotation = randf_range(-0.35, 0.35)
	var peek := Vector2(item.size.x * 0.42 * (1 if randf() < 0.5 else -1),
			item.size.y * 0.45 * (1 if randf() < 0.5 else -1))
	note.position = item.position + item.size * 0.5 - note.size * 0.5 + peek
	note.home = note.position
	board.add_child(note)
	board.move_child(note, item.get_index())
	note.picked.connect(_on_note_picked)
	return note


func toast(text: String, at: Vector2, color: Color) -> void:
	var l := make_label(self, text, 22, color)
	l.position = at + Vector2(-50, -36)
	l.z_index = 10
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 50.0, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


func make_panel(parent: Node, rect: Rect2, color: Color, radius := 8, text := "",
		font_size := 18, text_color := C_TEXT) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	if text != "":
		var l := make_label(p, text, font_size, text_color)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return p


func make_label(parent: Node, text: String, font_size := 18, color := C_TEXT, outline := true) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 5)
	parent.add_child(l)
	return l


## Random top-left position so an item of `item_size` lies inside `rect`.
func random_point_in(rect: Rect2, item_size: Vector2) -> Vector2:
	return Vector2(randf_range(rect.position.x, rect.end.x - item_size.x),
			randf_range(rect.position.y, rect.end.y - item_size.y))


## Keeps a dropped item on the board.
func clamp_to_board(item: Control) -> void:
	item.position = item.position.clamp(Vector2.ZERO, board_size - item.size)
	if item is DragItem:
		(item as DragItem).home = item.position


func grade_for(ratio: float) -> String:
	for g in GRADES:
		if ratio >= g[0]:
			return g[1]
	return "5,0"


# --- Flow -------------------------------------------------------------------

func _start() -> void:
	if phase != Phase.INTRO:
		return
	_close_card()
	phase = Phase.PLAY
	_on_start()


func finish() -> void:
	if phase != Phase.PLAY:
		return
	phase = Phase.RESULTS
	_on_finish()
	_update_top_bar()
	var ratio := clampf(float(score) / par_score, 0.0, 1.0)
	var factor := points_factor()
	var points := maxi(int(round(score * factor)), 0)
	var readiness := GameState.readiness_for_points(points)
	var d_stress := stress_change(ratio)
	var d_energy := energy_change(ratio)
	var best := int(GameState.minigame_best.get(game_id, 0))
	_result = {
		"id": game_id, "title": game_title, "completed": true, "score": score,
		"points": points, "notes": notes, "d_energy": d_energy, "d_stress": d_stress,
	}
	var grade := grade_for(ratio)
	_result["ratio"] = ratio
	_result["grade"] = grade
	_result.merge(_result_extra(), true)
	var lines := PackedStringArray()
	lines.append("Punkte: %d%s" % [score, "   – neuer Rekord!" if score > best else ""])
	lines.append("Lernpunkte: +%d  (×%.2f)" % [points, factor])
	if notes > 0:
		lines.append("Gefundene Notizen: %d  (Lernbonus danach ×%.1f)" % [notes, GameState.note_multiplier(notes)])
	lines.append("Prüfungssicherheit: +%.1f" % readiness)
	lines.append("Stress %+d  ·  Energie %+d  ·  %d min vergangen" % [int(round(d_stress)), int(round(d_energy)), GameState.minigame_minutes()])
	lines.append_array(_result_lines(ratio))
	_open_card("Note %s – %s" % [grade, _grade_comment(grade)], "\n".join(lines),
			"Weiter  [E]", _leave)


func _abort() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.end_minigame({"id": game_id, "title": game_title, "completed": false})


func _leave() -> void:
	if _leaving or _result.is_empty():
		return
	_leaving = true
	GameState.end_minigame(_result)


func _show_intro() -> void:
	var lines := PackedStringArray([goal_text])
	if controls_text != "":
		lines.append(controls_text)
	var extra := _intro_extra()
	if extra != "":
		lines.append(extra)
	lines.append("Zeit: %d Sekunden  ·  kostet %d min Spielzeit" % [int(duration), GameState.minigame_minutes()])
	_open_card(game_title, "\n\n".join(lines), "Los geht's  [Leertaste]", _start, "Zurück  [Esc]", _abort)


func _grade_comment(grade: String) -> String:
	match grade[0]:
		"1":
			return "sehr gut!"
		"2":
			return "gut"
		"3":
			return "befriedigend"
		"4":
			return "gerade so bestanden"
	return "nicht bestanden – nochmal?"


func _on_note_picked(note: DragItem) -> void:
	if not is_playing():
		return
	found_note(note.get_global_rect().get_center())
	note.vanish_to(_notes_label.get_global_rect().get_center(), 0.4)


# --- UI ---------------------------------------------------------------------

func _build_top_bar(view: Vector2) -> void:
	make_panel(self, Rect2(0, 0, view.x, TOP_BAR), Color(0.07, 0.07, 0.09), 0)
	var title := make_label(self, game_title, 22, accent.lightened(0.2))
	title.position = Vector2(20, 6)
	_extra_label = make_label(self, "", 14, C_TEXT)
	_extra_label.position = Vector2(20, 36)

	var bar_w := view.x * 0.26
	_timer_bar = ProgressBar.new()
	_timer_bar.show_percentage = false
	_timer_bar.max_value = 100.0
	_timer_bar.position = Vector2(view.x * 0.5 - bar_w * 0.5, 22)
	_timer_bar.size = Vector2(bar_w, 20)
	_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.2, 0.2, 0.23)
	back.set_corner_radius_all(6)
	_timer_fill = StyleBoxFlat.new()
	_timer_fill.bg_color = accent
	_timer_fill.set_corner_radius_all(6)
	_timer_bar.add_theme_stylebox_override("background", back)
	_timer_bar.add_theme_stylebox_override("fill", _timer_fill)
	add_child(_timer_bar)
	_time_label = make_label(self, "", 20, C_TEXT)
	_time_label.position = Vector2(view.x * 0.5 + bar_w * 0.5 + 12, 18)

	_score_label = make_label(self, "", 22, C_TEXT)
	_score_label.position = Vector2(view.x - 330, 16)
	_notes_label = make_label(self, "", 18, C_PAPER)
	_notes_label.position = Vector2(view.x - 160, 19)


func _update_top_bar() -> void:
	_timer_bar.value = time_left / duration * 100.0
	_time_label.text = "%d s" % ceili(time_left)
	if time_left < 10.0 and phase == Phase.PLAY:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		_timer_fill.bg_color = C_STRESS.lerp(Color.WHITE, 0.4 * pulse)
		_time_label.add_theme_color_override("font_color", C_STRESS)
	else:
		_timer_fill.bg_color = accent
	_score_label.text = "Punkte %d" % score
	_notes_label.text = "Notizen %d" % notes
	_extra_label.text = _extra_text()


func _flash(c: Control) -> void:
	if c == null:
		return
	c.modulate = Color(2, 2, 2)
	c.create_tween().tween_property(c, "modulate", Color.WHITE, 0.4)


## Dimmed full-screen card with a title, text and one or two buttons.
func _open_card(title: String, body: String, ok_text: String, ok: Callable,
		cancel_text := "", cancel := Callable()) -> void:
	_close_card()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_overlay = dim
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = accent
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var head := make_label(box, title, 34, accent.lightened(0.25))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var text := make_label(box, body, 18, C_TEXT, false)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(minf(620.0, get_viewport_rect().size.x - 120.0), 0)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	var ok_button := _make_button(buttons, ok_text, ok)
	if cancel_text != "":
		_make_button(buttons, cancel_text, cancel)
	ok_button.grab_focus.call_deferred()


func _make_button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 46)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _close_card() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
