# help_menu.gd
# HILFE overlay, opened from the main menu and the pause menu: the story in a
# few lines, then the tips. Three tips are always there; the others unlock
# when the player dies in a certain way (game.gd → Settings.unlock_tip), so
# the help grows with the player's deaths. Locked tips show as "? ? ?" so the
# player knows there is more to discover. Enter, Space or Escape closes.
# Works while the tree is paused (process_mode ALWAYS in the scene).
extends Control

signal closed

const STORY := """Du hast dich im Wald verirrt. Da steht es: ein riesiges, verlassenes Hotel.
Immer noch besser als draussen in der Kälte. Die Tür fällt hinter dir ins Schloss.
Der Gang nimmt kein Ende. Du spürst Gestalten um dich, als würdest du halluzinieren.
Du nimmst zwei Laternen von der Wand. Eine könnte ja leer gehen.
Doch jede zeigt dir einen anderen Gang. Was die eine zeigt, verbirgt die andere.
Du wirst immer ängstlicher und rennst, so schnell du kannst, um hier rauszukommen."""

## Order on screen. `always` tips are visible from the start; the others need
## their id unlocked. %s in the flip tip is the configured flip key.
const TIPS := [
	{"id": "flip",    "always": true,  "text": "%s oder Leertaste hebt die andere Laterne. Boden, Löcher und Geister wechseln mit."},
	{"id": "lantern", "always": true,  "text": "Laternen an der Wand markieren sicheren Boden. Dort kannst du stehen bleiben und atmen."},
	{"id": "light",   "always": true,  "text": "Dein Licht schrumpft, solange du läufst. Bleib stehen, und es wächst wieder."},
	{"id": "hole",    "always": false, "text": "Löcher gibt es nur in einer Welt. Flippe genau an der Kante, wo Boden und Loch wechseln."},
	{"id": "ghost",   "always": false, "text": "Geister leben nur in einer Welt. In der anderen sind sie fort. Lauf dort durch."},
	{"id": "hunter",  "always": false, "text": "Der Jäger erstarrt im Licht und weicht zurück. Siehst du ihn nicht, jagt er dich.\n    Hör auf sein Flüstern: es wird lauter, wenn er nah ist."},
	{"id": "sprint",  "always": false, "text": "Beschleunige nicht so viel. Wer rennt, sieht weniger und flippt zu spät."},
]
const LOCKED_TEXT := "? ? ? ? ? ? ? ? ? ?"

@onready var title:      PixelText = $Title
@onready var story:      PixelText = $Story
@onready var tips_title: PixelText = $TipsTitle
@onready var tips:       PixelText = $Tips
@onready var footer:     PixelText = $Footer


func _ready() -> void:
	visible = false
	WorldState.world_flipped.connect(func(_d: bool) -> void: _refresh())


func open() -> void:
	_refresh()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		Audio.play("ui_back")
		close()


func _refresh() -> void:
	story.text = STORY
	var lines: PackedStringArray = []
	for tip in TIPS:
		if tip["always"] or Settings.is_tip_unlocked(tip["id"]):
			lines.append("- " + (tip["text"] % Settings.control_name("world_flip") if "%s" in tip["text"] else tip["text"]))
		else:
			lines.append("- " + LOCKED_TEXT)
	tips.text = "\n".join(lines)
	var fg := WorldState.get_fg_color()
	title.color      = fg
	story.color      = fg.darkened(0.15)
	tips_title.color = fg
	tips.color       = fg.darkened(0.15)
	footer.color     = fg.darkened(0.35)
