extends Control
## Week summary at the end of the demo week (after the submission, or when
## the deadline passed). Explains the result in numbers (submission grade and
## difficulty, Prüfungssicherheit, to-dos, stress) and shows the exam points
## that carry over to the exam after GameState.EXAM_LOOPS weeks.
## A missed submission first shows a full-screen 5,0 stamp with the reason
## (deadline passed or slept through it), then the summary.

const C_BG := Color(0.06, 0.06, 0.08)
const C_TEXT := Color(0.93, 0.93, 0.95)
const C_DIM := Color(0.6, 0.62, 0.68)
const C_GOOD := Color(0.45, 0.8, 0.4)
const C_BAD := Color(0.95, 0.3, 0.3)
const C_HOT := Color(0.98, 0.8, 0.25)

var _menu_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(820, 0)
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)

	var gs := GameState
	var sub: Dictionary = gs.submission
	var grade: String = sub.get("grade", "5,0")
	_label(box, "Woche %d ist vorbei" % gs.loops_done, 34, C_TEXT)
	_label(box, "Note %s" % grade, 54, grade_color(grade))
	if sub.get("done", false):
		_label(box, "Übungsblatt abgegeben  ·  Schwierigkeit: %s" % sub.get("level", "?"), 18, C_DIM)
	else:
		_label(box, "Übungsblatt NICHT abgegeben  ·  " + _missed_reason(sub), 18, C_BAD)
	box.add_child(HSeparator.new())

	var todos: Array = gs.week_data.get("todos", [])
	var lines := [
		["Prüfungssicherheit am Ende", "%d %%  (ab 60 %% leichte, unter 25 %% schwere Abgabe)" % int(gs.readiness)],
		["Lernpunkte diese Woche", str(gs.study_points)],
		["Wieder vergessen (Zeit ohne Lernen)", "%d  (höchstens die Hälfte des Gelernten)" % -int(gs.readiness_forgotten)],
		["Termine pünktlich besucht", str(gs.lectures_on_time)],
		["To-dos erledigt", "%d / %d" % [gs.todos_done(), todos.size()]],
		["Gefundene Notizen", str(gs.notes_found)],
		["Stress am Ende", "%d %%" % int(gs.stress)],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(grid)
	for l in lines:
		var k := _label(grid, l[0], 17, C_DIM)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var v := _label(grid, l[1], 17, C_TEXT)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(HSeparator.new())

	var max_points: int = gs.EXAM_POINTS_PER_SUBMISSION * gs.EXAM_LOOPS
	_label(box, "Klausurpunkte: +%d diese Woche  ·  gesamt %d / %d" % [
		int(sub.get("exam_points", 0)), gs.exam_points, max_points], 24, C_HOT)
	var left := maxi(gs.EXAM_LOOPS - gs.loops_done, 0)
	_label(box, "Die Analysis-Klausur kommt nach %d Wochen – noch %d. Deine Klausurpunkte machen sie leichter." % [gs.EXAM_LOOPS, left], 16, C_DIM)
	_label(box, _comment(sub), 18, C_TEXT)
	_label(box, "Das Wochenende verbringst du mit Schlaf nachholen und Wäsche.", 15, C_DIM)
	box.add_child(HSeparator.new())
	_label(box, "Danke fürs Testen! Das war die Demo – bitte füll jetzt den Feedbackbogen aus.", 16, C_HOT)
	var b := Button.new()
	b.text = "Hauptmenü"
	b.custom_minimum_size = Vector2(300, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func() -> void: get_tree().change_scene_to_file(GameState.MENU_SCENE))
	box.add_child(b)
	b.grab_focus.call_deferred()
	_menu_button = b
	if not sub.get("done", false):
		_show_fail_stamp(sub)


## Full-screen "5,0" for a missed submission; Space/E/click goes on to the summary.
func _show_fail_stamp(sub: Dictionary) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.16, 0.03, 0.04)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	_label(box, "ABGABE VERPASST", 26, C_BAD.lightened(0.3))
	var stamp := _label(box, "5,0", 180, C_BAD)
	stamp.add_theme_color_override("font_outline_color", Color.BLACK)
	stamp.add_theme_constant_override("outline_size", 14)
	_label(box, "nicht bestanden", 30, C_TEXT)
	_label(box, _missed_reason(sub), 18, C_DIM)
	_label(box, "Übungsblatt 1 zählt mit 0 Klausurpunkten.", 18, C_DIM)
	var go := Button.new()
	go.text = "Zur Wochenbilanz  [Leertaste]"
	go.custom_minimum_size = Vector2(300, 52)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.add_theme_font_size_override("font_size", 20)
	go.pressed.connect(func() -> void:
		var t := overlay.create_tween()
		t.tween_property(overlay, "modulate:a", 0.0, 0.4)
		t.tween_callback(overlay.queue_free)
		_menu_button.grab_focus())
	box.add_child(go)
	go.grab_focus.call_deferred()
	# Stamp slams down.
	stamp.pivot_offset = Vector2(stamp.get_combined_minimum_size().x * 0.5, 100)
	stamp.scale = Vector2(2.4, 2.4)
	stamp.modulate.a = 0.0
	var tw := stamp.create_tween().set_parallel()
	tw.tween_property(stamp, "scale", Vector2.ONE, 0.35).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(stamp, "modulate:a", 1.0, 0.2).set_delay(0.3)
	tw.tween_property(stamp, "rotation", -0.12, 0.35).set_delay(0.3)


func _missed_reason(sub: Dictionary) -> String:
	var s := GameState.submission_info()
	if sub.get("reason", "") == "slept":
		return "Du hast am %s geschlafen, statt bis %s Uhr in %s abzugeben." % [
			GameState.DAY_NAMES[int(s["day"])], s["end"], s["place"]]
	return "Die Frist (%s %s Uhr, %s) ist verstrichen." % [GameState.DAY_NAMES[int(s["day"])], s["end"], s["place"]]


static func grade_color(grade: String) -> Color:
	match grade.substr(0, 1):
		"1", "2":
			return C_GOOD
		"3", "4":
			return C_HOT
	return C_BAD


## One sentence that names the main reason for the result.
func _comment(sub: Dictionary) -> String:
	if not sub.get("done", false):
		return "Ohne Abgabe gibt es keine Klausurpunkte. Tipp: Das Handy (Tab) zeigt Frist und Ort."
	var ratio := float(sub.get("ratio", 0.0))
	if GameState.readiness < 25.0:
		return "Mit wenig Prüfungssicherheit war die Abgabe schwer. Mehr Vorlesungen und Lerngruppen machen sie leichter."
	if ratio >= 0.8:
		return "Stark! Gut vorbereitet und konzentriert abgegeben."
	if GameState.stress > 60.0:
		return "Viel Stress diese Woche. Essen, Schlaf und Aufräumen helfen beim Lernen."
	return "Solide Woche. Pünktliche Termine bringen mehr Lernpunkte."


func _label(parent: Node, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Only full-width lines wrap; grid cells keep their text on one line.
	if parent is VBoxContainer:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(820, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l
