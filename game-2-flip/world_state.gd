# world_state.gd
# Autoload Singleton – manages the global flip state for the platformer.
# false = WHITE world (light background, dark platforms)
# true  = BLACK world (dark background, light platforms)
extends Node

signal world_flipped(is_dark: bool)

var is_dark: bool = false

## Flip the world state and broadcast to all listeners.
func flip() -> void:
	is_dark = !is_dark
	world_flipped.emit(is_dark)

## Convenience colour helpers.
func get_bg_color() -> Color:
	return Color(0.08, 0.08, 0.08) if is_dark else Color(0.95, 0.95, 0.95)

func get_fg_color() -> Color:
	return Color(0.95, 0.95, 0.95) if is_dark else Color(0.08, 0.08, 0.08)

func get_platform_color() -> Color:
	return Color(0.92, 0.92, 0.92) if is_dark else Color(0.12, 0.12, 0.12)

func get_player_color() -> Color:
	# Player is always the contrasting mid-tone so it pops in both worlds.
	return Color(0.95, 0.95, 0.95) if is_dark else Color(0.08, 0.08, 0.08)

func reset() -> void:
	is_dark = false
	world_flipped.emit(is_dark)
