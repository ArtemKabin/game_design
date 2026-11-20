extends Minigame
## Level 1: Lernjournal. Study cards pile up on the left of the desk; drag
## them into the open journal on the right before they are forgotten.
## Cards of the current chapter count most and build a combo, the chapter
## changes every few seconds. Distractions (red: phone, group chat) cost
## points in the journal; drag them anywhere else to dismiss them.
## Notes found while cleaning raise the study points (GameState.note_multiplier).

const TOPICS := [
	{"name": "Analysis", "color": Color(0.35, 0.6, 1.0),
		"terms": ["Ableitung", "Integral", "Grenzwert", "Kettenregel", "Taylorreihe", "Extremwert"]},
	{"name": "Statistik", "color": Color(0.45, 0.8, 0.4),
		"terms": ["Varianz", "p-Wert", "Normalverteilung", "Regression", "Median", "Konfidenz"]},
	{"name": "Informatik", "color": Color(0.98, 0.8, 0.25),
		"terms": ["Rekursion", "O-Notation", "Hashmap", "Stack", "Quicksort", "Binärbaum"]},
]
const DISTRACTIONS := ["Insta: 12 neue Likes", "Gruppenchat (47)", "Nächste Folge in 5 s",
	"Meme von Tom", "Mensa: heute Pommes!", "Angebot: -50 %"]
const CARD_SIZE := Vector2(176, 64)
const CARD_LIFE := 7.0
const MAX_CARDS := 8
const CHAPTER_TIME := 12.0
const DISTRACTION_CHANCE := 0.3
const MAX_LINES := 14

var _cards: Array[DragItem] = []
var _spawn_timer := 0.0
var _chapter := 0
var _chapter_timer := CHAPTER_TIME
var _combo := 0
var _stack_rect := Rect2()
var _journal: Panel
var _chapter_stripe: Panel
var _chapter_label: Label
var _page_label: Label
var _lines: PackedStringArray = []
var _learned := 0


func _init() -> void:
	game_id = "study_journal"
	game_title = "Lernjournal"
	goal_text = "Die Prüfung rückt näher. Zieh die Lernkarten vom Stapel links in dein Journal rechts, bevor du sie wieder vergisst."
	controls_text = "Maus: Karten ziehen. Karten des aktuellen Kapitels geben am meisten und bauen eine Kombo auf. Rote Ablenkungen NICHT ins Journal – einfach irgendwo anders hinziehen."
	duration = 60.0
	par_score = 400.0
	accent = C_READINESS


func _setup() -> void:
	var w := board_size.x
	var h := board_size.y
	make_panel(board, Rect2(Vector2.ZERO, board_size), C_WOOD.darkened(0.2), 0)
	_stack_rect = Rect2(w * 0.03, h * 0.1, w * 0.42, h * 0.84)
	make_panel(board, _stack_rect, C_WOOD.darkened(0.4), 12)
	var stack_title := make_label(board, "Lernstapel", 18, C_PAPER)
	stack_title.position = _stack_rect.position + Vector2(8, -30)

	var j := Rect2(w * 0.5, h * 0.05, w * 0.47, h * 0.9)
	_journal = make_panel(board, j, C_WOOD.darkened(0.55), 14)
	var half := j.size.x * 0.5
	var page_h := j.size.y - 24
	make_panel(_journal, Rect2(12, 12, half - 16, page_h), C_PAPER, 6)
	make_panel(_journal, Rect2(half + 4, 12, half - 16, page_h), C_PAPER, 6)
	make_panel(_journal, Rect2(half - 3, 8, 6, j.size.y - 16), C_WOOD, 2)
	for i in int((page_h - 90) / 30.0):
		make_panel(_journal, Rect2(24, 90 + i * 30, half - 40, 2), Color(0.72, 0.8, 0.92), 0)
		make_panel(_journal, Rect2(half + 16, 90 + i * 30, half - 40, 2), Color(0.72, 0.8, 0.92), 0)

	_chapter_stripe = make_panel(_journal, Rect2(24, 24, half - 40, 44), Color.WHITE, 6)
	_chapter_label = make_label(_chapter_stripe, "", 19, C_TEXT_DARK, false)
	_chapter_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var hint := make_label(_journal, "Hierher ziehen", 15, Color(0.45, 0.45, 0.5), false)
	hint.position = Vector2(30, 80)

	_page_label = make_label(_journal, "Gelernt: 0", 16, Color(0.2, 0.25, 0.4), false)
	_page_label.position = Vector2(half + 24, 24)
	_page_label.size = Vector2(half - 48, page_h - 24)
	_page_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_chapter(0, false)


func _on_start() -> void:
	for i in 3:
		_spawn_card()
	_spawn_timer = 1.2


func _tick(delta: float) -> void:
	_chapter_timer -= delta
	if _chapter_timer <= 0.0:
		_chapter_timer = CHAPTER_TIME
		_set_chapter((_chapter + 1) % TOPICS.size(), true)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var pressure := 1.0 - time_left / duration
		_spawn_timer = lerpf(1.6, 0.8, pressure)
		if _cards.size() < MAX_CARDS:
			_spawn_card()

	for card in _cards.duplicate():
		if card.is_dragging():
			card.modulate.a = 1.0
			continue
		card.data["age"] += delta
		var left: float = CARD_LIFE - card.data["age"]
		if left < 3.0:
			card.modulate.a = 0.35 + 0.65 * absf(sin(left * 5.0))
		if left <= 0.0:
			_cards.erase(card)
			if card.kind == "study":
				toast("vergessen …", card.get_global_rect().get_center(), Color(0.7, 0.7, 0.72))
			card.vanish_to(card.get_global_rect().get_center(), 0.3)


func _on_finish() -> void:
	for card in _cards:
		card.draggable = false


func _spawn_card() -> void:
	var card := DragItem.new()
	if randf() < DISTRACTION_CHANCE:
		card.setup(DISTRACTIONS.pick_random(), C_STRESS, CARD_SIZE, 15)
		card.kind = "distraction"
	else:
		var t: int = _chapter if randf() < 0.45 else randi() % TOPICS.size()
		var topic: Dictionary = TOPICS[t]
		var term: String = topic["terms"].pick_random()
		card.setup("%s\n%s" % [term, topic["name"]], topic["color"], CARD_SIZE, 16)
		card.kind = "study"
		card.data["topic"] = t
		card.data["term"] = term
	card.data["age"] = 0.0
	card.position = random_point_in(_stack_rect.grow(-12), CARD_SIZE)
	card.home = card.position
	card.rotation = randf_range(-0.15, 0.15)
	board.add_child(card)
	card.pop_in()
	card.picked.connect(func(c: DragItem) -> void: c.rotation = 0.0)
	card.dropped.connect(_on_card_dropped)
	_cards.append(card)


func _on_card_dropped(card: DragItem, at: Vector2) -> void:
	if not is_playing() or not _cards.has(card):
		return
	var in_journal := _journal.get_global_rect().has_point(at)
	if card.kind == "distraction":
		_cards.erase(card)
		if in_journal:
			_combo = 0
			add_points(-10, at, "Abgelenkt! -10")
			_shake(_journal)
		else:
			add_points(2, at, "Fokus! +2")
		card.vanish_to(at, 0.2)
		return
	if not in_journal:
		clamp_to_board(card)
		return
	_cards.erase(card)
	var topic: int = card.data["topic"]
	if topic == _chapter:
		_combo += 1
		var mult := 1.0 + minf(_combo - 1, 10) * 0.2
		var pts := int(round(10 * mult))
		add_points(pts, at, "+%d  Kombo ×%.1f" % [pts, mult] if _combo > 1 else "+%d" % pts)
	else:
		_combo = 0
		add_points(4, at, "+4  (anderes Kapitel)")
	_write(card.data["term"])
	card.vanish_to(_page_label.get_global_rect().get_center())


func _write(term: String) -> void:
	_learned += 1
	_lines.append("• " + term)
	if _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	_page_label.text = "Gelernt: %d\n\n%s" % [_learned, "\n".join(_lines)]


func _set_chapter(index: int, announce: bool) -> void:
	_chapter = index
	var topic: Dictionary = TOPICS[index]
	(_chapter_stripe.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = topic["color"]
	_chapter_label.text = "Kapitel: " + topic["name"]
	if announce:
		_combo = 0
		toast("Neues Kapitel: " + topic["name"], _chapter_stripe.get_global_rect().get_center(), topic["color"])
		_chapter_stripe.pivot_offset = _chapter_stripe.size * 0.5
		_chapter_stripe.scale = Vector2(1.15, 1.15)
		create_tween().tween_property(_chapter_stripe, "scale", Vector2.ONE, 0.3)


func _shake(c: Control) -> void:
	var start := c.position
	var tw := create_tween()
	for dx in [12.0, -10.0, 6.0, 0.0]:
		tw.tween_property(c, "position:x", start.x + dx, 0.05)


func points_factor() -> float:
	return GameState.note_multiplier()


func stress_change(ratio: float) -> float:
	return 3.0 - 7.0 * ratio


func energy_change(_ratio: float) -> float:
	return -6.0


func _extra_text() -> String:
	var mult := 1.0 + minf(maxi(_combo - 1, 0), 10) * 0.2
	return "Kapitel %s  ·  Kombo ×%.1f  ·  Lernbonus ×%.1f" % [TOPICS[_chapter]["name"], mult, GameState.note_multiplier()]


func _intro_extra() -> String:
	if GameState.notes_found > 0:
		return "Deine %d gefundenen Notizen geben einen Lernbonus von ×%.1f." % [GameState.notes_found, GameState.note_multiplier()]
	return "Tipp: Beim Aufräumen findest du verlorene Notizen – jede macht das Lernen hier effektiver."
