extends Control
## Main menu (first scene): title, Neues Spiel, Steuerung, Einstellungen (a
## MaintenancePanel until settings exist). No Beenden: the demo runs in the browser.
## "Neues Spiel" plays the story intro (pages from data/week.json,
## typewriter text, Space/E/click = next, Esc = skip), then resets the week
## (GameState.reset_week) and loads the dorm. Built in code like the HUD,
## no assets yet. The stress vignette pulses slowly as a hint of the mood.

const GAME_SCENE := "res://scenes/main.tscn"
const C_BG := Color(0.06, 0.06, 0.08)
const C_TEXT := Color(0.93, 0.93, 0.95)
const C_DIM := Color(0.6, 0.62, 0.68)
const C_ACCENT := Color(0.35, 0.6, 1.0)
const C_HOT := Color(0.98, 0.8, 0.25)
const CHARS_PER_SECOND := 45.0
const CONTROLS := [
	["WASD / Pfeiltasten", "Laufen"],
	["Shift", "Rennen"],
	["E / Leertaste", "Interagieren, reden, Dialog weiter"],
	["Tab", "Handy: Karte, Kontakte, To-dos, Stundenplan"],
	["M", "Karte von oben an/aus (Maus ziehen = verschieben)"],
	["Mausrad", "Zoom"],
	["Maus", "Minispiele: ziehen, klicken"],
	["Esc", "Handy/Minispiel: zurück"],
]

var _menu: Control
var _controls: Control
var _settings: MaintenancePanel
var _intro: Control
var _page_label: Label
var _page_hint: Label
var _vignette: ColorRect
var _pages: Array = []
var _page := -1
var _typing: Tween
var _starting := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_vignette = ColorRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/stress_vignette.gdshader")
	_vignette.material = mat
	add_child(_vignette)
	_pages = GameState.week_data.get("intro", ["Eine Woche Uni."])
	_build_menu()
	_build_controls()
	_settings = MaintenancePanel.new("Einstellungen", PackedStringArray(["Lautstärke", "Vollbild", "Spieltempo", "Tastenbelegung"]))
	_settings.closed.connect(_show.bind(_menu))
	add_child(_settings)
	_build_intro()
	_show(_menu)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var s := 0.25 + 0.1 * sin(t * 1.3)
	(_vignette.material as ShaderMaterial).set_shader_parameter("stress", s)


func _unhandled_input(event: InputEvent) -> void:
	if _intro.visible:
		if event.is_action_pressed("ui_cancel"):
			_start_game()
		elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
				or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			_next_page()
		else:
			return
		get_viewport().set_input_as_handled()
	elif _controls.is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		_show(_menu)
		get_viewport().set_input_as_handled()


func _show(screen: Control) -> void:
	for c in [_menu, _controls, _settings, _intro]:
		# Menu and controls are boxes in a full-screen CenterContainer.
		var node: Control = c if c == _intro or c == _settings else c.get_parent()
		node.visible = c == screen
	if screen == _menu:
		(_menu.find_child("Start", true, false) as Button).grab_focus.call_deferred()


# --- Intro ----------------------------------------------------------------------

func _begin_intro() -> void:
	_show(_intro)
	_page = -1
	_next_page()


func _next_page() -> void:
	if _typing and _typing.is_running():
		_typing.kill()
		_page_label.visible_ratio = 1.0
		return
	_page += 1
	if _page >= _pages.size():
		_start_game()
		return
	_page_label.text = _pages[_page]
	_page_label.visible_ratio = 0.0
	_typing = create_tween()
	_typing.tween_property(_page_label, "visible_ratio", 1.0, _page_label.text.length() / CHARS_PER_SECOND)
	_page_hint.text = "%d / %d    ·    Leertaste / Klick: weiter    ·    Esc: überspringen" % [_page + 1, _pages.size()]


func _start_game() -> void:
	if _starting:
		return
	_starting = true
	if _typing:
		_typing.kill()
	_page_label.visible_ratio = 1.0
	_page_label.text = "Montag, 08:00."
	_page_hint.text = ""
	GameState.reset_week()
	var t := create_tween()
	t.tween_interval(0.9)
	t.tween_callback(get_tree().change_scene_to_file.bind(GAME_SCENE))


# --- UI -------------------------------------------------------------------------

func _build_menu() -> void:
	_menu = _centered_box(18)
	# Placeholder until the team has voted on the name (theme is "Atmosphere").
	_label(_menu, "[Name in Abstimmung]", 56, C_TEXT)
	_label(_menu, "Eine Woche Uni. Eine Abgabe. Und irgendwo dazwischen: du.", 20, C_DIM)
	_label(_menu, "Demo · Playtest 1", 14, C_ACCENT)
	_menu.add_child(_spacer(20))
	var start := _button(_menu, "Neues Spiel", _begin_intro)
	start.name = "Start"
	_button(_menu, "Steuerung", _show.bind(_controls))
	_button(_menu, "Einstellungen", _show.bind(_settings))
	if GameState.loops_done > 0:
		_menu.add_child(_spacer(12))
		_label(_menu, "Klausurpunkte bisher: %d  ·  Wochen gespielt: %d / %d" % [
			GameState.exam_points, GameState.loops_done, GameState.EXAM_LOOPS], 16, C_HOT)


func _build_controls() -> void:
	_controls = _centered_box(10)
	_label(_controls, "Steuerung", 40, C_TEXT)
	_controls.add_child(_spacer(8))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 8)
	_controls.add_child(grid)
	for c in CONTROLS:
		var k := _label(grid, c[0], 18, C_HOT)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var v := _label(grid, c[1], 18, C_TEXT)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_controls.add_child(_spacer(12))
	_label(_controls, "Jede Aktion kostet Spielzeit. Die Uhr steht nur im Handy, in Gesprächen und in Minispielen.", 15, C_DIM)
	_button(_controls, "Zurück  [Esc]", _show.bind(_menu))


func _build_intro() -> void:
	_intro = Control.new()
	_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intro)
	_page_label = Label.new()
	_page_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page_label.offset_left = 140
	_page_label.offset_right = -140
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_page_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_label.add_theme_font_size_override("font_size", 28)
	_page_label.add_theme_color_override("font_color", C_TEXT)
	_page_label.add_theme_constant_override("line_spacing", 8)
	_intro.add_child(_page_label)
	_page_hint = Label.new()
	_page_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_page_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_page_hint.position.y -= 50
	_page_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_hint.add_theme_font_size_override("font_size", 15)
	_page_hint.add_theme_color_override("font_color", C_DIM)
	_intro.add_child(_page_hint)


func _centered_box(separation: int) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", separation)
	center.add_child(box)
	return box


func _label(parent: Node, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
