extends CanvasLayer
## HUD: day and clock, stat bars, interaction prompt, short messages,
## stress vignette and the night fade between days. Built in code so it
## stays one small file while the layout is still changing.

@export var player: Player

var _clock: Label
var _money: Label
var _prompt: Label
var _message: Label
var _bars := {}
var _vignette: ColorRect
var _night: ColorRect
var _night_label: Label

const BARS := [
	["energy", "Energie", Color(0.98, 0.8, 0.25)],
	["satiety", "Sättigung", Color(0.45, 0.8, 0.4)],
	["readiness", "Prüfungssicherheit", Color(0.35, 0.6, 1.0)],
	["stress", "Stress", Color(0.95, 0.3, 0.3)],
]


func _ready() -> void:
	_build()
	GameState.stats_changed.connect(_refresh)
	GameState.message.connect(_show_message)
	GameState.day_ended.connect(_on_day_ended)
	GameState.day_started.connect(_on_day_started)
	if player:
		player.interactable_changed.connect(_on_focus)
	_refresh()


func _build() -> void:
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/stress_vignette.gdshader")
	_vignette.material = mat
	add_child(_vignette)

	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(260, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	_clock = Label.new()
	_clock.add_theme_font_size_override("font_size", 26)
	box.add_child(_clock)
	for b in BARS:
		var l := Label.new()
		l.text = b[1]
		l.add_theme_font_size_override("font_size", 13)
		box.add_child(l)
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 10)
		var fill := StyleBoxFlat.new()
		fill.bg_color = b[2]
		bar.add_theme_stylebox_override("fill", fill)
		box.add_child(bar)
		_bars[b[0]] = bar
	_money = Label.new()
	box.add_child(_money)

	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position.y -= 70
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	add_child(_prompt)

	_message = Label.new()
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.position.y += 24
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.add_theme_font_size_override("font_size", 22)
	_message.add_theme_color_override("font_outline_color", Color.BLACK)
	_message.add_theme_constant_override("outline_size", 6)
	_message.modulate.a = 0.0
	add_child(_message)

	_night = ColorRect.new()
	_night.set_anchors_preset(Control.PRESET_FULL_RECT)
	_night.color = Color(0.02, 0.02, 0.06)
	_night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_night.modulate.a = 0.0
	add_child(_night)
	_night_label = Label.new()
	_night_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_night_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_night_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_night_label.add_theme_font_size_override("font_size", 40)
	_night.add_child(_night_label)


func _refresh() -> void:
	_clock.text = "Woche %d · %s  %s" % [GameState.week, GameState.day_name(), GameState.clock_text()]
	_bars["energy"].value = GameState.energy
	_bars["satiety"].value = GameState.satiety
	_bars["readiness"].value = GameState.readiness
	_bars["stress"].value = GameState.stress
	_money.text = "Geld: %.2f €" % GameState.money
	(_vignette.material as ShaderMaterial).set_shader_parameter("stress", GameState.stress / 100.0)


func _on_focus(target: Interactable) -> void:
	_prompt.text = target.prompt() if target else ""


func _show_message(text: String) -> void:
	_message.text = text
	var t := create_tween()
	t.tween_property(_message, "modulate:a", 1.0, 0.15)
	t.tween_interval(1.6)
	t.tween_property(_message, "modulate:a", 0.0, 0.5)


func _on_day_ended(_day: int) -> void:
	_night_label.text = "22:00 · Feierabend.\nAb nach Hause."
	create_tween().tween_property(_night, "modulate:a", 1.0, 0.8)


func _on_day_started(_day: int) -> void:
	_night_label.text = "%s, 08:00" % GameState.day_name()
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_property(_night, "modulate:a", 0.0, 0.8)
