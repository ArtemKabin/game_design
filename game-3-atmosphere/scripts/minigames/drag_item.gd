class_name DragItem
extends Panel
## Something on a minigame board that can be picked up with the mouse and
## dropped somewhere: study cards, clothes, dishes, hidden notes, ...
## The minigame decides on `dropped` where it landed (`at` = mouse position).

signal picked(item: DragItem)
signal dropped(item: DragItem, at: Vector2)

## What it is; decides where it belongs ("study", "laundry", "dish", ...).
var kind := ""
var data := {}
var draggable := true
## Where a wrong drop sends it back to (parent coordinates).
var home := Vector2.ZERO
var label: Label

var _dragging := false
var _grab := Vector2.ZERO


func setup(text: String, color: Color, item_size: Vector2, font_size := 15) -> DragItem:
	size = item_size
	pivot_offset = item_size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	sb.border_color = color.darkened(0.35)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(2, 3)
	add_theme_stylebox_override("panel", sb)
	label = Label.new()
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	var light_bg := color.get_luminance() > 0.5
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12) if light_bg else Color(0.97, 0.97, 0.97))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return self


func is_dragging() -> bool:
	return _dragging


func _gui_input(event: InputEvent) -> void:
	if not draggable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_grab = get_global_mouse_position() - global_position
			move_to_front()
			scale = Vector2(1.08, 1.08)
			picked.emit(self)
		elif _dragging:
			_dragging = false
			scale = Vector2.ONE
			dropped.emit(self, get_global_mouse_position())
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _grab
		accept_event()


## Flies to `target` (global), shrinks, fades and is freed.
func vanish_to(target: Vector2, time := 0.25) -> void:
	draggable = false
	_dragging = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "global_position", target - size * 0.5, time)
	tw.tween_property(self, "scale", Vector2(0.3, 0.3), time)
	tw.tween_property(self, "modulate:a", 0.0, time)
	tw.chain().tween_callback(queue_free)


func bounce_home() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", home, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var shake := create_tween()
	for a in [0.12, -0.12, 0.06, 0.0]:
		shake.tween_property(self, "rotation", a, 0.05)


## Pops in from small (after add_child).
func pop_in() -> void:
	scale = Vector2(0.5, 0.5)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
