class_name Phone
extends Control
## The player's smartphone (Tab), part of the HUD. Home screen with four apps:
## Karte (opens the map view of the CameraRig), Kontakte (all characters from
## data/encounters.json), To-dos and Stundenplan (both from data/week.json).
## While it is open the clock and the player stand still (GameState.in_phone).
## Built in code like the HUD.

const W := 360.0
const H := 620.0
const C_FRAME := Color(0.05, 0.05, 0.07)
const C_SCREEN := Color(0.11, 0.12, 0.15)
const C_TEXT := Color(0.93, 0.93, 0.95)
const C_DIM := Color(0.6, 0.62, 0.68)
const C_DONE := Color(0.45, 0.8, 0.4)
const C_HOT := Color(0.98, 0.8, 0.25)
const C_ALERT := Color(0.95, 0.3, 0.3)
const APPS := [
	["map", "Karte", Color(0.3, 0.55, 0.85)],
	["contacts", "Kontakte", Color(0.78, 0.45, 0.6)],
	["todos", "To-dos", Color(0.45, 0.75, 0.4)],
	["schedule", "Stundenplan", Color(0.9, 0.6, 0.25)],
]

var _status: Label
var _title: Label
var _home: GridContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _back: Button
var _app := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()


func is_open() -> bool:
	return visible


func open() -> void:
	if visible or not GameState.is_free() or GameState.in_minigame:
		return
	var rig := _camera_rig()
	if rig and rig.overview:
		rig.set_overview(false)
	visible = true
	GameState.in_phone = true
	_show_home()


func close() -> void:
	if not visible:
		return
	visible = false
	GameState.in_phone = false


func _process(_delta: float) -> void:
	if visible:
		_status.text = "%s  %s" % [GameState.day_name().substr(0, 2), GameState.clock_text()]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("phone"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		if _app != "":
			_show_home()
		else:
			close()
		get_viewport().set_input_as_handled()


# --- Screens ------------------------------------------------------------------

func _show_home() -> void:
	_app = ""
	_title.text = "Handy"
	_home.visible = true
	_scroll.visible = false
	_back.text = "Schließen  [Tab]"
	(_home.get_child(0) as Button).grab_focus.call_deferred()


func _open_app(id: String) -> void:
	if id == "map":
		close()
		var rig := _camera_rig()
		if rig:
			rig.set_overview(true)
			GameState.message.emit("Karte  ·  M oder Tab: zurück  ·  Maus ziehen: verschieben")
		return
	_app = id
	_home.visible = false
	_scroll.visible = true
	_back.text = "Zurück  [Esc]"
	for c in _list.get_children():
		c.queue_free()
	match id:
		"contacts":
			_title.text = "Kontakte"
			_fill_contacts()
		"todos":
			_title.text = "To-dos  ·  Woche %d" % GameState.week
			_fill_todos()
		"schedule":
			_title.text = "Stundenplan"
			_fill_schedule()
	_scroll.scroll_vertical = 0


func _fill_contacts() -> void:
	for n in Encounters.all_npcs():
		var id: String = n["id"]
		var row := _row(n["name"], 18, Encounters.npc_color(id).lightened(0.25))
		if Encounters.story_waiting_for(id):
			row.text += "   (!) hat Neuigkeiten"
			row.add_theme_color_override("font_color", C_HOT)
		var where := "im Wohnheim" if n.get("place", "outside") == "dorm" else "unterwegs auf dem Campus"
		var last := int(GameState.npc_last_met.get(id, -1))
		var met := "noch nicht getroffen"
		if last == GameState.absolute_day():
			met = "heute getroffen"
		elif last >= 0:
			met = "zuletzt: " + GameState.DAY_NAMES[last % GameState.DAY_NAMES.size()]
		_row("%s  ·  %s\n%s" % [n.get("role", ""), where, met], 14, C_DIM)
		_list.add_child(HSeparator.new())


func _fill_todos() -> void:
	for t in GameState.week_data.get("todos", []):
		var target := int(t.get("target", 1))
		var have := mini(GameState.todo_progress(t), target)
		var done := have >= target
		var text := "%s  %s" % ["[x]" if done else "[  ]", t["text"]]
		if target > 1:
			text += "  %d/%d" % [have, target]
		var urgent: bool = t.get("station", "") == "submission" and not done
		_row(text, 16, C_DONE if done else (C_ALERT if urgent else C_TEXT))
	_list.add_child(HSeparator.new())
	var s := GameState.submission_info()
	_row("Abgabe: %s, %s–%s, %s" % [GameState.DAY_NAMES[int(s["day"])], s["start"], s["end"], s["place"]], 14, C_HOT)
	_row("Prüfungssicherheit jetzt: %d %%  →  Abgabe wäre %s" % [int(GameState.readiness), GameState.difficulty_name()], 14, C_DIM)
	_row("Klausur in %d Wochen  ·  Klausurpunkte bisher: %d" % [maxi(GameState.EXAM_LOOPS - GameState.loops_done, 1), GameState.exam_points], 14, C_DIM)


func _fill_schedule() -> void:
	for d in 5:
		var head := _row(GameState.DAY_NAMES[d] + ("  ·  heute" if d == GameState.day else ""), 17,
				C_HOT if d == GameState.day else C_TEXT)
		head.add_theme_constant_override("outline_size", 0)
		var entries := GameState.schedule_for(d)
		if entries.is_empty():
			_row("   frei", 14, C_DIM)
		for e in entries:
			var start := GameState.parse_time(e["start"])
			var end := GameState.parse_time(e["end"])
			var color := C_TEXT
			var tag := ""
			var past: bool = d < GameState.day or (d == GameState.day and GameState.minutes >= end)
			if past:
				color = C_DIM
				tag = "  (vorbei)"
			elif d == GameState.day and GameState.minutes >= start - GameState.SLOT_EARLY_MINUTES:
				color = C_DONE
				tag = "  · JETZT"
			_row("   %s–%s  %s%s\n   %s" % [e["start"], e["end"], e["title"], tag, e["place"]], 14, color)
		_list.add_child(HSeparator.new())
	_row("Vorlesung zur Stundenplan-Zeit: Lernpunkte ×%.1f" % GameState.LECTURE_BONUS, 13, C_DIM)


# --- UI -------------------------------------------------------------------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	frame.size = Vector2(W, H)
	frame.position = Vector2(-W - 60.0, -H * 0.5)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_FRAME
	sb.set_corner_radius_all(36)
	frame.add_theme_stylebox_override("panel", sb)
	add_child(frame)

	var screen := Panel.new()
	screen.position = Vector2(12, 14)
	screen.size = Vector2(W - 24, H - 28)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = C_SCREEN
	ssb.set_corner_radius_all(26)
	screen.add_theme_stylebox_override("panel", ssb)
	frame.add_child(screen)

	var box := VBoxContainer.new()
	box.position = Vector2(18, 12)
	box.size = screen.size - Vector2(36, 24)
	box.add_theme_constant_override("separation", 10)
	screen.add_child(box)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", C_DIM)
	box.add_child(_status)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", C_TEXT)
	box.add_child(_title)

	_home = GridContainer.new()
	_home.columns = 2
	_home.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_home.add_theme_constant_override("h_separation", 12)
	_home.add_theme_constant_override("v_separation", 12)
	box.add_child(_home)
	for a in APPS:
		var b := Button.new()
		b.text = a[1]
		b.custom_minimum_size = Vector2(140, 120)
		b.add_theme_font_size_override("font_size", 18)
		for state in ["normal", "hover", "pressed", "focus"]:
			var st := StyleBoxFlat.new()
			st.bg_color = a[2] if state == "normal" else a[2].lightened(0.15)
			st.set_corner_radius_all(20)
			if state == "focus":
				st.set_border_width_all(3)
				st.border_color = Color.WHITE
			b.add_theme_stylebox_override(state, st)
		b.pressed.connect(_open_app.bind(a[0]))
		_home.add_child(b)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	_scroll.add_child(_list)

	_back = Button.new()
	_back.custom_minimum_size = Vector2(0, 40)
	_back.pressed.connect(func() -> void:
		if _app != "":
			_show_home()
		else:
			close())
	box.add_child(_back)


func _row(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(W - 70, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_list.add_child(l)
	return l


func _camera_rig() -> Node:
	var scene := get_tree().current_scene
	return scene.get_node_or_null("CameraRig") if scene else null
