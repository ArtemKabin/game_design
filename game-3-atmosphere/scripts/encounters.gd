extends CanvasLayer
## Autoload "Encounters": talking to NPCs (npc.gd), data in
## data/encounters.json (see "_info" there for all keys).
##
## Meeting an NPC plays, in this order:
## 1. the next story beat, if this NPC is its speaker and its requirements
##    are met (GameState.story_index counts the beats played),
## 2. otherwise once per NPC and day a random encounter from the weighted
##    pool, seeded with NPC, day and GameState.encounter_seed (meeting the
##    same person again that day gives the same result, no rerolling),
## 3. otherwise a line of small talk.
## The dialogue box pauses the clock and the player; effects (notes, study
## points, stress, ...) are applied when it closes.

signal dialogue_closed

const DATA_PATH := "res://data/encounters.json"
const DEFAULT_MINUTES := 5

var _data := {}
var _npcs := {}   ## id -> npc entry

var _root: Control
var _panel: PanelContainer
var _style: StyleBoxFlat
var _name_label: Label
var _text_label: Label
var _fx_label: Label
var _button: Button

var _pages := PackedStringArray()
var _page := 0
var _effects := {}


func _ready() -> void:
	layer = 20
	_load()
	_build()
	_root.visible = false


func _load() -> void:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_warning("Encounters: data missing: " + DATA_PATH)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_data = parsed
	else:
		push_warning("Encounters: could not parse " + DATA_PATH)
	for n in _data.get("npcs", []):
		_npcs[n["id"]] = n


# --- Queries (used by npc.gd, npc_spawner.gd, HUD) -----------------------------

func npc_info(id: String) -> Dictionary:
	return _npcs.get(id, {"id": id, "name": id.capitalize(), "role": "", "color": [0.6, 0.6, 0.6]})


func npc_color(id: String) -> Color:
	var c: Array = npc_info(id).get("color", [0.6, 0.6, 0.6])
	return Color(c[0], c[1], c[2])


func npcs_for(place: String) -> Array:
	var out: Array = []
	for n in _data.get("npcs", []):
		if n.get("place", "outside") == place:
			out.append(n)
	return out


func story_total() -> int:
	return _data.get("story", []).size()


func next_story() -> Dictionary:
	var story: Array = _data.get("story", [])
	if GameState.story_index >= story.size():
		return {}
	return story[GameState.story_index]


## True if meeting this NPC now plays the next story beat (shows "!" above it).
func story_waiting_for(npc_id: String) -> bool:
	var beat := next_story()
	return not beat.is_empty() and beat.get("speaker", "") == npc_id and _meets(beat.get("requires", {}))


func is_open() -> bool:
	return _root != null and _root.visible


# --- Meeting --------------------------------------------------------------------

func meet(npc_id: String) -> void:
	if is_open() or GameState.in_minigame or not GameState.running:
		return
	var info := npc_info(npc_id)
	if story_waiting_for(npc_id):
		var beat := next_story()
		GameState.story_index += 1
		GameState.story_seen.append(str(beat.get("id", "")))
		_open(info, beat.get("lines", []), beat.get("effects", {}), true)
		return
	if not GameState.met_today(npc_id):
		GameState.mark_met(npc_id)
		var enc := _pick_random(npc_id)
		if not enc.is_empty():
			_open(info, enc.get("lines", []), enc.get("effects", {}), false)
			return
	var talk: Array = _data.get("small_talk", ["Hallo!"])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_open(info, [talk[rng.randi() % talk.size()]], {"minutes": 1}, false)


func _pick_random(npc_id: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|%d" % [npc_id, GameState.absolute_day(), GameState.encounter_seed])
	var pool: Array = []
	var total := 0.0
	for e in _data.get("random", []):
		if _meets(e.get("requires", {})):
			pool.append(e)
			total += float(e.get("weight", 1.0))
	if pool.is_empty():
		return {}
	var r := rng.randf() * total
	for e in pool:
		r -= float(e.get("weight", 1.0))
		if r <= 0.0:
			return e
	return pool[pool.size() - 1]


func _meets(req: Dictionary) -> bool:
	for key in req:
		var have := 0.0
		match key:
			"readiness":
				have = GameState.readiness
			"study_points":
				have = GameState.study_points
			"notes":
				have = GameState.notes_found
			"runs":
				have = GameState.total_runs()
			"day":
				have = GameState.absolute_day()
			"stress":
				have = GameState.stress
			_:
				push_warning("Encounters: unknown requirement " + str(key))
				continue
		if have < float(req[key]):
			return false
	return true


# --- Dialogue box ---------------------------------------------------------------

func _open(info: Dictionary, lines: Array, effects: Dictionary, story: bool) -> void:
	_pages = PackedStringArray()
	for l in lines:
		_pages.append(str(l).replace("{name}", info.get("name", "")))
	if _pages.is_empty():
		_pages.append("…")
	_effects = effects
	_page = 0
	var title: String = info.get("name", "")
	if info.get("role", "") != "":
		title += "  ·  " + info["role"]
	if story:
		title += "     ★ Story %d/%d" % [GameState.story_index, story_total()]
	_name_label.text = title
	var c: Array = info.get("color", [0.6, 0.6, 0.6])
	var color := Color(c[0], c[1], c[2])
	_name_label.add_theme_color_override("font_color", color.lightened(0.3))
	_style.border_color = color
	GameState.in_dialogue = true
	_root.visible = true
	_show_page()


func _show_page() -> void:
	_text_label.text = _pages[_page]
	var last := _page == _pages.size() - 1
	var fx := effect_text(_effects) if last else ""
	_fx_label.text = fx
	_fx_label.visible = fx != ""
	_fx_label.add_theme_color_override("font_color",
		Color(0.95, 0.45, 0.4) if float(_effects.get("stress", 0)) > 0.0 else Color(0.55, 0.85, 0.5))
	_button.text = "OK  [E]" if last else "Weiter  [E]"
	_button.grab_focus.call_deferred()


func _advance() -> void:
	if not is_open():
		return
	_page += 1
	if _page < _pages.size():
		_show_page()
	else:
		_close()


func _close() -> void:
	_root.visible = false
	GameState.in_dialogue = false
	_apply(_effects)
	dialogue_closed.emit()


func _apply(fx: Dictionary) -> void:
	var points := int(fx.get("points", 0))
	var notes := int(fx.get("notes", 0))
	if points != 0 or notes != 0:
		GameState.add_progress(points, notes)
	GameState.do_action(int(fx.get("minutes", DEFAULT_MINUTES)), float(fx.get("energy", 0.0)),
		float(fx.get("satiety", 0.0)), float(fx.get("readiness", 0.0)) + GameState.points_to_readiness(points),
		float(fx.get("stress", 0.0)), float(fx.get("money", 0.0)))
	var text := effect_text(fx)
	if text != "":
		GameState.message.emit(text)
	# HUD flash also for story progress and stress changes.
	GameState.progress_changed.emit()


static func effect_text(fx: Dictionary) -> String:
	var parts := PackedStringArray()
	var notes := int(fx.get("notes", 0))
	if notes > 0:
		parts.append("+%d Notiz%s" % [notes, "en" if notes > 1 else ""])
	elif notes < 0:
		parts.append("%d Notiz%s" % [notes, "en" if notes < -1 else ""])
	for key in [["points", "Lernpunkte"], ["readiness", "Prüfungssicherheit"], ["stress", "Stress"],
			["energy", "Energie"], ["satiety", "Sättigung"]]:
		var v := float(fx.get(key[0], 0.0))
		if v != 0.0:
			parts.append("%s %+d" % [key[1], int(v)])
	var money := float(fx.get("money", 0.0))
	if money != 0.0:
		parts.append("%+.2f €" % money)
	return "  ·  ".join(parts)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var holder := CenterContainer.new()
	holder.anchor_left = 0.0
	holder.anchor_right = 1.0
	holder.anchor_top = 1.0
	holder.anchor_bottom = 1.0
	holder.offset_top = -270.0
	holder.offset_bottom = -30.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(holder)
	_panel = PanelContainer.new()
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.08, 0.08, 0.1, 0.94)
	_style.set_corner_radius_all(12)
	_style.set_border_width_all(2)
	_style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", _style)
	holder.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 20)
	box.add_child(_name_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(640, 0)
	_text_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_text_label)
	_fx_label = Label.new()
	_fx_label.add_theme_font_size_override("font_size", 16)
	box.add_child(_fx_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)
	_button = Button.new()
	_button.custom_minimum_size = Vector2(160, 38)
	_button.pressed.connect(_advance)
	row.add_child(_button)
