# scoreboard_panel.gd
# Shows the local best list (Scoreboard autoload) in the pixel font.
# Children: Title (PixelText), Lines (PixelText, multi-line).
# refresh(highlight_rank) marks one rank with an arrow, e.g. the run just played.
class_name ScoreboardPanel
extends Control

@onready var title: PixelText = $Title
@onready var lines: PixelText = $Lines


func _ready() -> void:
	WorldState.world_flipped.connect(func(_d: bool) -> void: _apply_colors())
	refresh()


func refresh(highlight_rank: int = 0) -> void:
	var out := PackedStringArray()
	var scores: Array[int] = Scoreboard.scores
	if scores.is_empty():
		out.append("NOCH KEINE LÄUFE")
	for i in range(scores.size()):
		var rank := i + 1
		var marker := ">" if rank == highlight_rank else " "
		out.append("%s%2d. %5d" % [marker, rank, scores[i]])
	lines.text = "\n".join(out)
	_apply_colors()


func _apply_colors() -> void:
	var fg := WorldState.get_fg_color()
	title.color = fg
	lines.color = fg.darkened(0.15)
