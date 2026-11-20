class_name MaintenancePanel
extends CenterContainer
## Placeholder screen for things that are not built yet ("Wartungsarbeiten"):
## construction stripes, a title, a short text, an optional list of what is
## planned and a Zurück button. Esc also goes back. Reusable anywhere:
##   var p := MaintenancePanel.new("Einstellungen", ["Lautstärke", ...])
##   p.closed.connect(...)
##   add_child(p)

signal closed

const C_TEXT := Color(0.93, 0.93, 0.95)
const C_DIM := Color(0.6, 0.62, 0.68)
const C_STRIPE_A := Color(0.98, 0.8, 0.25)
const C_STRIPE_B := Color(0.08, 0.08, 0.1)

var title := "Wartungsarbeiten"
var planned: PackedStringArray = []
var text := "Hier wird noch gebaut. Schau im finalen Release wieder vorbei."
var _back: Button


func _init(p_title := "Wartungsarbeiten", p_planned: PackedStringArray = []) -> void:
	title = p_title
	planned = p_planned


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	box.add_child(_stripes())
	_label(box, title, 40, C_TEXT)
	_label(box, "WARTUNGSARBEITEN", 18, C_STRIPE_A)
	_label(box, text, 17, C_DIM)
	if not planned.is_empty():
		_label(box, "Geplant:  " + "  ·  ".join(planned), 16, C_TEXT)
	box.add_child(_stripes())
	_back = Button.new()
	_back.text = "Zurück  [Esc]"
	_back.custom_minimum_size = Vector2(300, 52)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.add_theme_font_size_override("font_size", 20)
	_back.pressed.connect(func() -> void: closed.emit())
	box.add_child(_back)
	visibility_changed.connect(func() -> void:
		if visible:
			_back.grab_focus.call_deferred())


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()


## Yellow/black construction tape, drawn in code (no assets).
func _stripes() -> Control:
	var tape := Control.new()
	tape.custom_minimum_size = Vector2(560, 22)
	tape.clip_contents = true
	tape.draw.connect(func() -> void:
		tape.draw_rect(Rect2(Vector2.ZERO, tape.size), C_STRIPE_B)
		var w := 22.0
		var x := -tape.size.y
		var i := 0
		while x < tape.size.x:
			if i % 2 == 0:
				tape.draw_colored_polygon(PackedVector2Array([
					Vector2(x, tape.size.y), Vector2(x + tape.size.y, 0),
					Vector2(x + tape.size.y + w, 0), Vector2(x + w, tape.size.y)]), C_STRIPE_A)
			x += w
			i += 1)
	return tape


func _label(parent: Node, t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l
