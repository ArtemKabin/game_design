# chunk.gd
# Base class for all level chunks. A chunk is a fixed-width slice of the level
# (e.g. a platform gap, a sphere section, a safe stretch). Chunks are spawned
# by game.gd to the right of the screen and destroyed when they scroll past the left edge.
#
# Coordinate convention: each chunk's local x=0 is its LEFT edge.
# The chunk WIDTH determines how far the next chunk starts.
class_name Chunk
extends Node2D

## Width in pixels — the game uses this to position the next chunk.
@export var width: float = 400.0

## True once the chunk is past the left camera edge and can be freed.
var _marked_for_removal: bool = false


func mark_for_removal() -> void:
	_marked_for_removal = true
	queue_free()
