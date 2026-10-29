# pause_menu.gd
# Escape pauses the game and shows this overlay: WEITER, OPTIONEN, ZUM MENÜ,
# plus the best list. Lives on CanvasLayer 3 with process_mode ALWAYS so it
# keeps working while the tree is paused. game.gd sets `can_pause` so the
# game-over screen cannot be paused over.
extends CanvasLayer

var can_pause: Callable = func() -> bool: return true

@onready var root:        Control         = $Root
@onready var menu:        LanternMenu     = $Root/Menu
@onready var resume_btn:  Button          = $Root/Menu/Buttons/Resume
@onready var options_btn: Button          = $Root/Menu/Buttons/Options
@onready var menu_btn:    Button          = $Root/Menu/Buttons/ToMenu
@onready var scoreboard:  ScoreboardPanel = $Root/ScoreboardPanel
@onready var options:     Control         = $Root/OptionsMenu
@onready var title:       PixelText       = $Root/Title


func _ready() -> void:
	root.visible = false
	resume_btn.pressed.connect(close)
	options_btn.pressed.connect(_open_options)
	menu_btn.pressed.connect(_to_menu)
	options.closed.connect(_close_options)
	WorldState.world_flipped.connect(func(_d: bool) -> void: title.color = WorldState.get_fg_color())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if options.visible:
		return   # the options overlay closes itself
	get_viewport().set_input_as_handled()
	if root.visible:
		close()
	elif can_pause.call():
		open()


func open() -> void:
	get_tree().paused = true
	title.color = WorldState.get_fg_color()
	scoreboard.refresh()
	root.visible = true
	menu.focus_first()


func close() -> void:
	root.visible = false
	options.visible = false
	get_tree().paused = false


# The options overlay replaces the pause content instead of sitting on top of it.
func _open_options() -> void:
	for n in [menu, scoreboard, title]:
		n.visible = false
	options.open()


func _close_options() -> void:
	for n in [menu, scoreboard, title]:
		n.visible = true
	menu.focus_button(options_btn)


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
