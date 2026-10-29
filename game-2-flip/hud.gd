# hud.gd
# In-game HUD: score (pixel font), the big world lantern bottom-left with a
# breathing glow, status messages, and a brief flash on world flip.
# The HUD sits on CanvasLayer 2, above the world colour filter, so the lantern
# always shows its true colour: RED in the red world, BLUE in the blue world.
extends Control

const LANTERN_RED_PATH  := "res://assets/ui/lantern_big_red.png"
const LANTERN_BLUE_PATH := "res://assets/ui/lantern_big_blue.png"
const GLOW_RED  := Color("ff8c3b")
const GLOW_BLUE := Color("4fb8ff")

@onready var score_text:   PixelText   = $ScoreText
@onready var status_label: Label       = $StatusLabel
@onready var bg_overlay:   ColorRect   = $BGOverlay
@onready var lantern:      TextureRect = $WorldLantern

var _tex_red:  Texture2D = null
var _tex_blue: Texture2D = null
var _status_tween: Tween = null
var _pulse: float = 0.0
var _level: float = 1.0   # sight 0..1, drives the lantern meter and its glow


func _ready() -> void:
	_tex_red  = load(LANTERN_RED_PATH) as Texture2D
	_tex_blue = load(LANTERN_BLUE_PATH) as Texture2D
	WorldState.world_flipped.connect(_on_world_flipped)
	bg_overlay.color = Color(0, 0, 0, 0)   # fully transparent at rest
	_refresh()


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()


func _draw() -> void:
	# Glow behind the big lantern (the lantern's glass sits a bit above its
	# centre). Shrinks and fades with the sight level, gone at zero.
	if lantern.texture == null or _level <= 0.02:
		return
	var centre := lantern.position + lantern.size * 0.5 + Vector2(0.0, -8.0)
	var glow := GLOW_BLUE if WorldState.is_dark else GLOW_RED
	var outer := glow
	outer.a = (0.10 + 0.03 * sin(_pulse)) * _level
	draw_circle(centre, (78.0 + 4.0 * sin(_pulse)) * _level, outer)
	var inner := glow
	inner.a = (0.20 + 0.05 * sin(_pulse + 1.0)) * _level
	draw_circle(centre, (46.0 + 3.0 * sin(_pulse)) * _level, inner)


## Sight level 0..1 from the sight fog (game.gd calls this every physics frame).
func set_sight_level(level: float) -> void:
	_level = clampf(level, 0.0, 1.0)
	lantern.material.set_shader_parameter("fill", _level)


func _on_world_flipped(_is_dark: bool) -> void:
	_refresh()
	# Brief full-screen flash on flip, then fade out to transparent.
	var flash := WorldState.get_fg_color()
	flash.a = 0.18
	var tween := create_tween()
	tween.tween_property(bg_overlay, "color", flash,               0.06)
	tween.tween_property(bg_overlay, "color", Color(0, 0, 0, 0),  0.35)


func _refresh() -> void:
	score_text.color = WorldState.get_fg_color()
	lantern.texture  = _tex_blue if WorldState.is_dark else _tex_red
	queue_redraw()


func set_score(score: int) -> void:
	score_text.text = "SCORE %d" % score


## Show a message that fades out after `duration` seconds (0 = permanent).
func show_status(text: String, duration: float = 3.5) -> void:
	if _status_tween and _status_tween.is_running():
		_status_tween.kill()
	status_label.text       = text
	status_label.modulate.a = 1.0
	if duration > 0.0:
		_status_tween = create_tween()
		_status_tween.tween_interval(duration)
		_status_tween.tween_property(status_label, "modulate:a", 0.0, 0.6)
