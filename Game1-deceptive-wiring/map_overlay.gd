extends Control

# Ship map overlay, toggled with Tab or M (action "toggle_map"). Pauses the game while open.
# Draws every room the player has visited as a rectangle in true proportion to the world
# (fog of war: unvisited rooms are not drawn). Current room cyan, solved levels green.

const PANEL_SIZE := Vector2(900, 480)
const COLOR_VISITED := Color(0.18, 0.29, 0.42, 0.9)
const COLOR_CURRENT := Color(0.345, 0.8, 0.929, 0.9)
const COLOR_SOLVED := Color(0.3, 0.85, 0.45, 0.8)

@onready var rooms_container: Control = $RoomsContainer

var rooms: Array = []
var current_room: Room = null
var room_rects: Dictionary = {}   # Room -> ColorRect
var room_labels: Dictionary = {}  # Room -> Label


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(room_list: Array) -> void:
	rooms = room_list
	for room in rooms:
		var rect := ColorRect.new()
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
		rect.add_child(label)
		rooms_container.add_child(rect)
		room_rects[room] = rect
		room_labels[room] = label
	refresh()


func set_current(room: Room) -> void:
	current_room = room
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		toggle()


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		refresh()


func refresh() -> void:
	if rooms.is_empty():
		return
	var union: Rect2 = rooms[0].global_bounds()
	for room in rooms:
		union = union.merge(room.global_bounds())
	var scale_factor: float = minf(PANEL_SIZE.x / union.size.x, PANEL_SIZE.y / union.size.y)
	var offset: Vector2 = (PANEL_SIZE - union.size * scale_factor) / 2.0

	for room in rooms:
		var rect: ColorRect = room_rects[room]
		var label: Label = room_labels[room]
		var b: Rect2 = room.global_bounds()
		rect.position = offset + (b.position - union.position) * scale_factor
		rect.size = b.size * scale_factor
		label.position = Vector2.ZERO
		label.size = rect.size
		label.text = room.room_title
		rect.visible = room.was_visited
		if room == current_room:
			rect.color = COLOR_CURRENT
		elif GameManager.get_level_state(room.room_id) == GameManager.LevelState.COMPLETED:
			rect.color = COLOR_SOLVED
		else:
			rect.color = COLOR_VISITED
