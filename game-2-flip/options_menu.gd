# options_menu.gd
# Options overlay, used by the main menu and the pause menu. Entries:
#   VOLLBILD        – Enter or left/right toggles
#   MUSIK / EFFEKTE – left/right in steps of 10, Enter steps up
#   LINKS / RECHTS / FLIP – Enter, then press the new key (Escape cancels)
#   STEUERUNG ZURÜCKSETZEN – defaults A / D / Enter
#   ZURÜCK          – closes (Escape does too)
# Works while the tree is paused (process_mode ALWAYS in the scene).
extends Control

signal closed

const STEP := 10
const CONTROL_ENTRIES := {   # button name -> action
	"KeyLeft":  "move_left",
	"KeyRight": "move_right",
	"KeyFlip":  "world_flip",
}
const CONTROL_LABELS := {
	"move_left":  "LINKS",
	"move_right": "RECHTS",
	"world_flip": "FLIP",
}

@onready var menu:  LanternMenu = $Menu
@onready var title: PixelText   = $Title
@onready var hint:  PixelText   = $Hint
@onready var fullscreen_btn: Button = $Menu/Buttons/Fullscreen
@onready var music_btn:      Button = $Menu/Buttons/Music
@onready var sfx_btn:        Button = $Menu/Buttons/Sfx
@onready var reset_btn:      Button = $Menu/Buttons/ResetKeys
@onready var back_btn:       Button = $Menu/Buttons/Back

var _listening_action: String = ""   # action waiting for a key press, "" = none


func _ready() -> void:
	visible = false
	fullscreen_btn.pressed.connect(func() -> void: Settings.set_fullscreen(not Settings.fullscreen); _refresh())
	music_btn.pressed.connect(func() -> void: _adjust_music(STEP))
	sfx_btn.pressed.connect(func() -> void: _adjust_sfx(STEP))
	for btn_name in CONTROL_ENTRIES:
		var btn := $Menu/Buttons.get_node(btn_name) as Button
		btn.pressed.connect(_start_listening.bind(CONTROL_ENTRIES[btn_name]))
	reset_btn.pressed.connect(func() -> void: Settings.reset_controls(); _refresh())
	back_btn.pressed.connect(close)
	WorldState.world_flipped.connect(func(_d: bool) -> void: _refresh())


func open() -> void:
	_listening_action = ""
	_refresh()
	visible = true
	menu.focus_first()


func close() -> void:
	_listening_action = ""
	visible = false
	closed.emit()


# _input (not _unhandled_input): the GUI focus system would otherwise swallow
# left/right before we see them, and a key being bound must not reach anyone.
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if _listening_action != "":
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			var key := (event as InputEventKey).keycode
			if key != KEY_ESCAPE:
				Settings.set_control(_listening_action, key)
			_listening_action = ""
			_refresh()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var dir := -STEP if event.is_action_pressed("ui_left") else STEP
		var focused: Button = menu.focused_button()
		if focused == music_btn:
			_adjust_music(dir)
		elif focused == sfx_btn:
			_adjust_sfx(dir)
		elif focused == fullscreen_btn:
			Settings.set_fullscreen(not Settings.fullscreen)
			_refresh()
		get_viewport().set_input_as_handled()


func _start_listening(action: String) -> void:
	_listening_action = action
	_refresh()


func _adjust_music(delta: int) -> void:
	Settings.set_music(0 if delta > 0 and Settings.music >= 100 else Settings.music + delta)
	_refresh()


func _adjust_sfx(delta: int) -> void:
	Settings.set_sfx(0 if delta > 0 and Settings.sfx >= 100 else Settings.sfx + delta)
	_refresh()


func _refresh() -> void:
	menu.label_of(fullscreen_btn).text = "VOLLBILD: %s" % ("AN" if Settings.fullscreen else "AUS")
	menu.label_of(music_btn).text      = "MUSIK: %d" % Settings.music
	menu.label_of(sfx_btn).text        = "EFFEKTE: %d" % Settings.sfx
	for btn_name in CONTROL_ENTRIES:
		var action: String = CONTROL_ENTRIES[btn_name]
		var btn := $Menu/Buttons.get_node(btn_name) as Button
		if _listening_action == action:
			menu.label_of(btn).text = "%s: TASTE DRÜCKEN" % CONTROL_LABELS[action]
		else:
			menu.label_of(btn).text = "%s: %s" % [CONTROL_LABELS[action], Settings.control_name(action)]
	menu.label_of(reset_btn).text = "STEUERUNG ZURÜCKSETZEN"
	menu.label_of(back_btn).text  = "ZURÜCK"
	var fg := WorldState.get_fg_color()
	title.color = fg
	hint.color  = fg.darkened(0.25)
	hint.text   = "ESC BRICHT AB" if _listening_action != "" else "LINKS UND RECHTS ÄNDERN, ENTER SCHALTET ODER BELEGT NEU"
