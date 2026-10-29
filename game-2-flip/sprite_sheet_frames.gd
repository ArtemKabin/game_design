# sprite_sheet_frames.gd
# Builds a SpriteFrames resource from a horizontal sprite sheet (all frames in
# one row, equal size), as exported from Aseprite (see art/README.md).
#
#   var sf := SpriteSheetFrames.build(texture, 48, 68, {
#       "idle": {"from": 0, "to": 3, "fps": 6.67},
#       "run":  {"from": 4, "to": 7, "fps": 11.1},
#   })
#
# Frame indices are 0-based positions in the sheet. "loop" defaults to true.
class_name SpriteSheetFrames


static func build(sheet: Texture2D, frame_w: int, frame_h: int, anims: Dictionary) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim_name in anims:
		var a: Dictionary = anims[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(a.get("fps", 10.0)))
		sf.set_animation_loop(anim_name, bool(a.get("loop", true)))
		for i in range(int(a["from"]), int(a["to"]) + 1):
			var at := AtlasTexture.new()
			at.atlas  = sheet
			at.region = Rect2(i * frame_w, 0, frame_w, frame_h)
			sf.add_frame(anim_name, at)
	return sf
