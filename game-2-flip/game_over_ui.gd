# game_over_ui.gd
# Game-over screen. Instance res://game_over_ui.tscn under a CanvasLayer above
# the world filter. show_game_over(score, reason, rank) shows it; the only way
# on is ZUM MENÜ (Enter/Space), which emits menu_requested. From the menu the
# player starts a new run with SPIELEN.
extends Control

signal menu_requested

@onready var title:       PixelText       = $Title
@onready var score_text:  PixelText       = $Score
@onready var rank_text:   PixelText       = $Rank
@onready var reason_text: PixelText       = $Reason
@onready var menu:        LanternMenu     = $Menu
@onready var menu_btn:    Button          = $Menu/Buttons/ToMenu
@onready var scoreboard:  ScoreboardPanel = $ScoreboardPanel


func _ready() -> void:
	visible = false
	menu_btn.pressed.connect(func() -> void: menu_requested.emit())


func show_game_over(score: int, reason: String, rank: int = 0) -> void:
	score_text.text  = "SCORE %d" % score
	# The pixel font has no dash variants; a plain hyphen reads fine.
	reason_text.text = reason.replace("—", "-").replace("–", "-")
	if rank == 1:
		rank_text.text = "NEUER REKORD!"
	elif rank > 0:
		rank_text.text = "PLATZ %d IN DER BESTENLISTE" % rank
	else:
		rank_text.text = ""
	var fg := WorldState.get_fg_color()
	title.color       = Color("3fa9f5") if WorldState.is_dark else Color("ff6b2b")
	score_text.color  = fg
	rank_text.color   = Color("ffc24b") if rank == 1 else fg
	reason_text.color = fg.darkened(0.2)
	scoreboard.refresh(rank)
	visible = true
	menu.focus_first()
