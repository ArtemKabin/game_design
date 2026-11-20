extends Node
## Dev tool: renders the demo's screens and saves PNGs (needs a window, not
## --headless):
##   Godot --path game-3-atmosphere res://tests/capture_screens.tscn -- <out_dir>
## Shots: menu, settings, dorm room, outside map (far + near the stations),
## each uni minigame while playing, week summary after a submission.

var _out := "user://screens"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _shot(name: String, wait := 1.0) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("saved ", name)


func _scene(path: String) -> Node:
	get_tree().change_scene_to_file(path)
	for i in 5:
		await get_tree().process_frame
	return get_tree().current_scene


func _run() -> void:
	var dummy := Node.new()
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	var gs: Node = get_tree().root.get_node("GameState")

	var menu := await _scene("res://scenes/ui/main_menu.tscn")
	await _shot("01_menu")
	menu.call("_show", menu.get("_settings"))
	await _shot("02_settings", 0.3)

	gs.call("reset_week")
	var dorm := await _scene("res://scenes/main.tscn")
	await _shot("03_dorm", 1.5)
	var player: Node3D = dorm.get_node("Player")
	var desk := dorm.find_child("Desk", true, false) as Node3D
	if desk:
		player.global_position = desk.global_position + Vector3(0.6, 0, 0.6)
		dorm.get_node("CameraRig").global_position = player.global_position
	await _shot("04_dorm_desk", 1.5)

	var outside := await _scene("res://scenes/outside.tscn")
	var rig: Node = outside.get_node("CameraRig")
	rig.call("set_overview", true)
	await _shot("05_map_far", 3.0)
	rig.set("overview_center", Vector3(-80, 0, -10))
	rig.set("overview_distance", 160.0)
	await _shot("06_map_stations", 2.0)
	rig.set("overview_center", Vector3(10, 0, -40))
	rig.set("overview_distance", 160.0)
	await _shot("07_map_dorm", 2.0)
	rig.call("set_overview", false)
	outside.get_node("Player").global_position = Vector3(-72, 0, -44)
	await _shot("08_stations_ground", 2.5)

	gs.readiness = 34.0
	for g in ["lecture", "study_group", "submission"]:
		var m := await _scene("res://scenes/minigames/%s.tscn" % g)
		await _shot("09_%s_intro" % g, 0.3)
		m.call("_start")
		if g == "study_group":
			var cards: Array = m.get("_cards")
			m.call("_on_card", cards[0])
		await _shot("10_%s_play" % g, 3.0)

	await _scene("res://scenes/main.tscn")
	gs.day = 4
	gs.minutes = 9 * 60
	gs.set("_pending_result", {"id": "submission", "title": "Abgabe", "completed": true, "score": 200,
			"points": 100, "notes": 2, "ratio": 0.8, "grade": "2,0", "level": "mittel"})
	gs.call("apply_minigame_result")
	for i in 5:
		await get_tree().process_frame
	await _shot("11_summary", 0.5)

	gs.call("reset_week")
	await _scene("res://scenes/main.tscn")
	gs.day = 4
	gs.call("sleep_now")
	for i in 5:
		await get_tree().process_frame
	await _shot("12_missed_stamp", 1.2)
	var stamp_btn := get_tree().current_scene.find_children("*", "Button", true, false)
	for b in stamp_btn:
		if (b as Button).text.begins_with("Zur Wochenbilanz"):
			(b as Button).pressed.emit()
	await _shot("13_missed_summary", 0.8)
	get_tree().quit()
