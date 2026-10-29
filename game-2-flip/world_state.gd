# world_state.gd
# Autoload Singleton – manages the global flip state and the palette.
#   is_dark = false → RED world:  warm, dark wood, lit by the red lantern
#   is_dark = true  → BLUE world: greyer, blue cast, lit by the blue lantern
# (The names "white"/"black" in older comments mean red/blue.)
#
# The corridor art is one set of textures; the mood comes from world_filter.gd,
# a full-screen colour grade that uses get_tint()/get_saturation() below.
extends Node

signal world_flipped(is_dark: bool)

var is_dark: bool = false

# ── Palette ───────────────────────────────────────────────────────────────────
const BG_RED        := Color("2b1b12")   # fog / void / clear colour
const BG_BLUE       := Color("14171d")
const FG_RED        := Color("f3dcc0")   # text, outlines, markers, hazards
const FG_BLUE       := Color("d5deea")
const PLATFORM_RED  := Color("b98652")   # walkable boards
const PLATFORM_BLUE := Color("8a95a8")
# Colour grade (world_filter.gdshader): multiply + desaturate.
const TINT_RED      := Color(1.08, 0.88, 0.74)
const TINT_BLUE     := Color(0.80, 0.90, 1.12)
const SAT_RED       := 1.0
const SAT_BLUE      := 0.45


## Flip the world state and broadcast to all listeners.
func flip() -> void:
	is_dark = !is_dark
	world_flipped.emit(is_dark)


func reset() -> void:
	is_dark = false
	world_flipped.emit(is_dark)


# ── Colour helpers (current world) ───────────────────────────────────────────
func get_bg_color() -> Color:
	return get_bg_color_for(is_dark)

func get_fg_color() -> Color:
	return get_fg_color_for(is_dark)

func get_platform_color() -> Color:
	return get_platform_color_for(is_dark)

func get_player_color() -> Color:
	return get_fg_color()

func get_tint() -> Color:
	return TINT_BLUE if is_dark else TINT_RED

func get_saturation() -> float:
	return SAT_BLUE if is_dark else SAT_RED


# ── Colour helpers (explicit world; for things that exist in one world only) ─
func get_bg_color_for(dark: bool) -> Color:
	return BG_BLUE if dark else BG_RED

func get_fg_color_for(dark: bool) -> Color:
	return FG_BLUE if dark else FG_RED

func get_platform_color_for(dark: bool) -> Color:
	return PLATFORM_BLUE if dark else PLATFORM_RED
