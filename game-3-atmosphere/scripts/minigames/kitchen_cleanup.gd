extends Minigame
## Level 3: Küche aufräumen & Notizen suchen. The shared kitchen is a mess:
## drag dishes into the sink, food scraps into the bin and scrub the stains
## away (hold the mouse button and rub). Lost study notes are buried under the
## clutter: every note found raises the score multiplier of this run and adds
## to the found notes (lasting bonus for the study journal).

const DISHES := ["Teller", "Tasse", "Topf", "Pfanne", "Glas", "Besteck", "Schüssel", "Teller"]
const SCRAPS := ["Nudelreste", "Bananenschale", "Pizzarand", "Teebeutel", "Eierschalen"]
const C_COUNTER := Color(0.66, 0.64, 0.6)
const C_SINK := Color(0.55, 0.58, 0.62)
const C_DISH := Color(0.93, 0.93, 0.9)
const C_SCRAP := Color(0.62, 0.52, 0.3)
const C_SPILL := Color(0.5, 0.3, 0.14)
const ITEM_SIZE := Vector2(118, 52)
const START_DISHES := 9
const START_SCRAPS := 5
const START_SPILLS := 5
const HIDDEN_NOTES := 4
const NOTE_MULT_STEP := 0.25
const RESPAWN_TIME := 9.0


## A stain on the counter: hold the left button on it and rub until it's gone.
class Spill extends Panel:
	signal cleaned(spill: Panel)

	var dirt := 1.0
	var _scrubbing := false

	func setup(spill_size: Vector2, color: Color) -> void:
		size = spill_size
		pivot_offset = spill_size * 0.5
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_CROSS
		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(int(minf(spill_size.x, spill_size.y) * 0.5))
		add_theme_stylebox_override("panel", sb)
		var l := Label.new()
		l.text = "Fleck\nschrubben"
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 13)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)

	func _gui_input(event: InputEvent) -> void:
		if dirt <= 0.0:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_scrubbing = event.pressed
			accept_event()
		elif event is InputEventMouseMotion and _scrubbing:
			if Rect2(Vector2.ZERO, size).has_point(event.position):
				dirt -= event.relative.length() / 900.0
				modulate.a = 0.2 + 0.8 * maxf(dirt, 0.0)
				scale = Vector2.ONE * (1.0 + 0.04 * sin(Time.get_ticks_msec() * 0.05))
				if dirt <= 0.0:
					_scrubbing = false
					cleaned.emit(self)
			accept_event()


var _things: Array[Control] = []   ## dishes, scraps and spills still left
var _sink: Panel
var _bin: Panel
var _work_rect := Rect2()
var _note_mult := 1.0
var _respawn := RESPAWN_TIME


func _init() -> void:
	game_id = "kitchen_cleanup"
	game_title = "Küche & Notizsuche"
	goal_text = "Die Gemeinschaftsküche versinkt im Chaos – und irgendwo darunter liegen deine verlorenen Vorlesungsnotizen."
	controls_text = "Maus: Geschirr → Spüle, Essensreste → Mülleimer. Flecken: Maustaste halten und schrubben. Notizen unter dem Kram anklicken: jede erhöht den Multiplikator dieser Runde und deinen Lernbonus."
	duration = 45.0
	par_score = 310.0
	accent = C_SATIETY


func _setup() -> void:
	var w := board_size.x
	var h := board_size.y
	make_panel(board, Rect2(Vector2.ZERO, board_size), C_COUNTER, 0)
	# Back wall with the coloured cabinets from the 3D kitchen.
	make_panel(board, Rect2(0, 0, w, h * 0.16), C_WALL, 0)
	var cab_colors := [Color(0.25, 0.45, 0.75), Color(0.75, 0.35, 0.3), Color(0.4, 0.65, 0.35), Color(0.8, 0.65, 0.25)]
	for i in cab_colors.size():
		make_panel(board, Rect2(w * 0.04 + i * w * 0.13, h * 0.02, w * 0.11, h * 0.12), cab_colors[i], 6)
	make_panel(board, Rect2(w * 0.6, h * 0.02, w * 0.14, h * 0.12), Color(0.1, 0.1, 0.1), 6, "Herd", 16)

	_sink = make_panel(board, Rect2(w * 0.79, h * 0.2, w * 0.18, h * 0.4), C_SINK, 14, "Spüle", 24)
	_bin = make_panel(board, Rect2(w * 0.79, h * 0.65, w * 0.18, h * 0.31), Color(0.25, 0.25, 0.27), 14, "Mülleimer", 24)
	for p in [_sink, _bin]:
		var sb := (p as Panel).get_theme_stylebox("panel") as StyleBoxFlat
		sb.set_border_width_all(3)
		sb.border_color = C_TEXT.darkened(0.3)
	_work_rect = Rect2(w * 0.02, h * 0.2, w * 0.74, h * 0.77)

	for i in START_SPILLS:
		_spawn_spill()
	var buryable: Array[DragItem] = []
	for i in START_DISHES:
		buryable.append(_spawn_item("dish", false))
	for i in START_SCRAPS:
		buryable.append(_spawn_item("scrap", false))
	buryable.shuffle()
	for i in mini(HIDDEN_NOTES, buryable.size()):
		bury_note(buryable[i])


func _tick(delta: float) -> void:
	_respawn -= delta
	if _respawn <= 0.0 and time_left > 10.0:
		_respawn = RESPAWN_TIME
		_spawn_item("dish" if randf() < 0.7 else "scrap", true)
		toast("Mitbewohner stellt noch was ab …", board.global_position + Vector2(board_size.x * 0.3, board_size.y * 0.25), C_STRESS)
	if _things.is_empty():
		var bonus := int(ceil(time_left)) * 3
		add_points(bonus, board.global_position + board_size * 0.4, "Küche blitzt! Zeitbonus +%d" % bonus)
		finish()


func _on_finish() -> void:
	for t in _things:
		if t is DragItem:
			(t as DragItem).draggable = false
		else:
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _spawn_item(kind: String, animated: bool) -> DragItem:
	var item := DragItem.new()
	if kind == "dish":
		item.setup(DISHES.pick_random(), C_DISH, ITEM_SIZE, 15)
	else:
		item.setup(SCRAPS.pick_random(), C_SCRAP, ITEM_SIZE, 15)
	item.kind = kind
	item.position = random_point_in(_work_rect, ITEM_SIZE)
	item.home = item.position
	item.rotation = randf_range(-0.3, 0.3)
	board.add_child(item)
	if animated:
		item.pop_in()
	item.picked.connect(func(c: DragItem) -> void: c.rotation = 0.0)
	item.dropped.connect(_on_item_dropped)
	_things.append(item)
	return item


func _spawn_spill() -> void:
	var spill := Spill.new()
	var s := Vector2(randf_range(110, 160), randf_range(70, 100))
	spill.setup(s, C_SPILL)
	spill.position = random_point_in(_work_rect, s)
	board.add_child(spill)
	spill.cleaned.connect(_on_spill_cleaned)
	_things.append(spill)


func _on_item_dropped(item: DragItem, at: Vector2) -> void:
	if not is_playing() or not _things.has(item):
		return
	var target := ""
	if _sink.get_global_rect().has_point(at):
		target = "dish"
	elif _bin.get_global_rect().has_point(at):
		target = "scrap"
	if target == "":
		clamp_to_board(item)
		return
	if target != item.kind:
		add_points(-4, at, "Falsch! -4")
		item.bounce_home()
		return
	_things.erase(item)
	_score_action(8, at)
	item.vanish_to((_sink if target == "dish" else _bin).get_global_rect().get_center())


func _on_spill_cleaned(spill: Panel) -> void:
	if not is_playing() or not _things.has(spill):
		return
	_things.erase(spill)
	_score_action(6, spill.get_global_rect().get_center())
	var tw := spill.create_tween()
	tw.tween_property(spill, "modulate:a", 0.0, 0.2)
	tw.tween_callback(spill.queue_free)


func _score_action(base: int, at: Vector2) -> void:
	var pts := int(round(base * _note_mult))
	add_points(pts, at, "+%d" % pts if _note_mult <= 1.0 else "+%d  (×%.2f)" % [pts, _note_mult])


func _on_note_found(at: Vector2) -> void:
	_note_mult += NOTE_MULT_STEP
	toast("Multiplikator ×%.2f" % _note_mult, at + Vector2(0, 30), C_READINESS)


func points_factor() -> float:
	return 0.6


func stress_change(ratio: float) -> float:
	return -(3.0 + 5.0 * ratio)


func energy_change(_ratio: float) -> float:
	return -4.0


func _extra_text() -> String:
	return "Multiplikator ×%.2f  ·  noch %d Sachen" % [_note_mult, _things.size()]
