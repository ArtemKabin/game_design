extends Minigame
## Level 2: Zimmer aufräumen. The room is a mess: drag clothes into the
## laundry basket, trash into the bin and stuff onto the shelf. Wrong place
## costs points, and more clutter keeps turning up. Some lost study notes lie
## under the mess – click them. A tidy room lowers stress (which makes all
## learning more effective, see GameState.learn_factor).

const ITEMS := {
	"laundry": ["Socke", "T-Shirt", "Hoodie", "Jeans", "Handtuch", "Pulli", "Socken"],
	"trash": ["Pizzakarton", "Dose", "Chipstüte", "Papierknäuel", "Kaffeebecher", "Pfandflasche"],
	"shelf": ["Buch", "Ordner", "Ladekabel", "Taschenrechner", "Skript", "Kopfhörer"],
}
## kind -> [target name, target colour, item colour]
const TARGETS := {
	"laundry": ["Wäschekorb", Color(0.25, 0.45, 0.75), Color(0.6, 0.72, 0.95)],
	"trash": ["Mülleimer", Color(0.25, 0.25, 0.27), Color(0.68, 0.68, 0.64)],
	"shelf": ["Regal", Color(0.55, 0.42, 0.3), Color(0.86, 0.7, 0.5)],
}
const ITEM_SIZE := Vector2(124, 50)
const START_ITEMS := 16
const HIDDEN_NOTES := 3
const RESPAWN_TIME := 8.0

var _items: Array[DragItem] = []
var _targets := {}   ## kind -> Panel
var _counts := {}    ## kind -> Label
var _sorted := {"laundry": 0, "trash": 0, "shelf": 0}
var _clutter_rect := Rect2()
var _respawn := RESPAWN_TIME
var _spawned := 0


func _init() -> void:
	game_id = "room_cleanup"
	game_title = "Zimmer aufräumen"
	goal_text = "Chaos im Zimmer, Chaos im Kopf. Räum alles an seinen Platz, bevor die Zeit um ist."
	controls_text = "Maus: Sachen ziehen. Kleidung → Wäschekorb, Müll → Mülleimer, Bücher & Kram → Regal. Falscher Platz kostet Punkte. Unter dem Chaos liegen verlorene Notizen – anklicken!"
	duration = 40.0
	par_score = 290.0
	accent = C_ENERGY


func _setup() -> void:
	var w := board_size.x
	var h := board_size.y
	make_panel(board, Rect2(Vector2.ZERO, board_size), Color(0.62, 0.47, 0.32), 0)   # floor like the dorm room
	# Bed and desk as greybox, clutter lies around and on them.
	make_panel(board, Rect2(w * 0.02, h * 0.04, w * 0.2, h * 0.55), Color(0.25, 0.3, 0.5), 10, "Bett", 20)
	make_panel(board, Rect2(w * 0.04, h * 0.06, w * 0.16, h * 0.1), Color(0.92, 0.92, 0.9), 8)
	make_panel(board, Rect2(w * 0.42, h * 0.02, w * 0.26, h * 0.16), Color(0.55, 0.42, 0.3), 6, "Schreibtisch", 18)
	_clutter_rect = Rect2(w * 0.02, h * 0.06, w * 0.7, h * 0.9)

	var col_x := w * 0.76
	var col_w := w * 0.21
	var box_h := (h - 40.0) / 3.0
	var i := 0
	for kind in TARGETS:
		var t: Array = TARGETS[kind]
		var rect := Rect2(col_x, 10 + i * (box_h + 10), col_w, box_h)
		var panel := make_panel(board, rect, t[1], 12)
		var sb := panel.get_theme_stylebox("panel") as StyleBoxFlat
		sb.set_border_width_all(3)
		sb.border_color = t[2]
		var name_label := make_label(panel, t[0], 24, C_TEXT)
		name_label.position = Vector2(16, 12)
		var count := make_label(panel, "0", 40, t[2])
		count.position = Vector2(16, 48)
		_targets[kind] = panel
		_counts[kind] = count
		i += 1

	for n in START_ITEMS:
		_spawn_item(false)
	var candidates := _items.duplicate()
	candidates.shuffle()
	for n in mini(HIDDEN_NOTES, candidates.size()):
		bury_note(candidates[n])


func _tick(delta: float) -> void:
	_respawn -= delta
	if _respawn <= 0.0 and time_left > 10.0:
		_respawn = RESPAWN_TIME
		var amount := 1 + randi() % 2
		for n in amount:
			_spawn_item(true)
		toast("Unterm Bett liegt noch mehr …", board.global_position + Vector2(board_size.x * 0.12, board_size.y * 0.62), C_STRESS)
	if _items.is_empty():
		var bonus := int(ceil(time_left)) * 3
		add_points(bonus, board.global_position + board_size * 0.4, "Alles sauber! Zeitbonus +%d" % bonus)
		finish()


func _on_finish() -> void:
	for item in _items:
		item.draggable = false


func _spawn_item(animated: bool) -> void:
	var kinds := ITEMS.keys()
	var kind: String = kinds[_spawned % kinds.size()] if _spawned < START_ITEMS else kinds.pick_random()
	_spawned += 1
	var item := DragItem.new()
	item.setup(ITEMS[kind].pick_random(), TARGETS[kind][2], ITEM_SIZE, 15)
	item.kind = kind
	item.position = random_point_in(_clutter_rect, ITEM_SIZE)
	item.home = item.position
	item.rotation = randf_range(-0.4, 0.4)
	board.add_child(item)
	if animated:
		item.pop_in()
	item.picked.connect(func(c: DragItem) -> void: c.rotation = 0.0)
	item.dropped.connect(_on_item_dropped)
	_items.append(item)


func _on_item_dropped(item: DragItem, at: Vector2) -> void:
	if not is_playing() or not _items.has(item):
		return
	var target := ""
	for kind in _targets:
		if (_targets[kind] as Control).get_global_rect().has_point(at):
			target = kind
	if target == "":
		clamp_to_board(item)
		return
	if target != item.kind:
		add_points(-4, at, "Gehört da nicht hin! -4")
		item.bounce_home()
		return
	_items.erase(item)
	_sorted[target] += 1
	(_counts[target] as Label).text = str(_sorted[target])
	add_points(10, at)
	item.vanish_to((_targets[target] as Control).get_global_rect().get_center())


func points_factor() -> float:
	return 0.5


func stress_change(ratio: float) -> float:
	return -(4.0 + 8.0 * ratio)


func energy_change(_ratio: float) -> float:
	return -4.0


func _extra_text() -> String:
	var chaos := clampf(float(_items.size()) / START_ITEMS, 0.0, 1.5) * 100.0
	return "Chaos %d %%  ·  noch %d Sachen" % [int(chaos), _items.size()]
