extends Node
## Headless smoke test of the demo loop (specs/001-demo-gameloop/quickstart.md):
##   Godot --headless --path game-3-atmosphere res://tests/loop_smoke_test.tscn
## (run as main scene so the autoloads exist).
## Loads every new scene, opens all phone apps, plays each minigame for a few
## seconds, submits on Friday and checks the week summary and the reset.

var _fails := 0


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		_fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _scene(path: String) -> Node:
	get_tree().change_scene_to_file(path)
	await _frames(5)
	return get_tree().current_scene


func _run() -> void:
	# Keep this node alive across scene changes: hand "current scene" to a dummy.
	var dummy := Node.new()
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	var gs: Node = get_tree().root.get_node("GameState")
	var menu := await _scene("res://scenes/ui/main_menu.tscn")
	_check(menu != null and not gs.running, "menu loads, clock stopped")
	menu.call("_begin_intro")
	await _frames(2)
	menu.call("_start_game")
	await get_tree().create_timer(1.5).timeout
	await _frames(3)
	_check(get_tree().current_scene.scene_file_path == "res://scenes/main.tscn", "intro leads to dorm")
	_check(gs.running and gs.day == 0 and int(gs.minutes) <= 8 * 60 + 10, "week starts Monday 08:00")

	var phone: Node = get_tree().current_scene.get_node("HUD").find_children("*", "Phone", true, false)[0]
	phone.call("open")
	_check(gs.in_phone, "phone opens and pauses")
	for app in ["contacts", "todos", "schedule"]:
		phone.call("_open_app", app)
		await _frames(2)
		_check(phone.get("_list").get_child_count() > 0, "phone app " + app + " has rows")
	phone.call("_open_app", "map")
	_check(not gs.in_phone and get_tree().current_scene.get_node("CameraRig").overview, "map app opens map view")

	var outside := await _scene("res://scenes/outside.tscn")
	var stations := outside.get_node("UniStations").get_children()
	_check(stations.size() == 3, "3 uni stations outside")
	var placeholders := 0
	for c in outside.get_node("Campus").get_children():
		if c is Interactable and c.position.distance_to(stations[0].position) < 3.0:
			placeholders += 1
	_check(placeholders == 0, "no placeholder door action at stations")
	_check(not gs.call("submission_open"), "submission closed on Monday")

	gs.minutes = 10 * 60
	_check(not gs.call("slot_now", "lecture").is_empty(), "Monday 10:00 lecture slot")
	for path in ["res://scenes/minigames/lecture.tscn", "res://scenes/minigames/study_group.tscn",
			"res://scenes/minigames/submission.tscn"]:
		var g := await _scene(path)
		g.call("_start")
		await get_tree().create_timer(2.5).timeout
		g.call("finish")
		var r: Dictionary = g.get("_result")
		_check(r.get("completed", false) and r.has("ratio"), path.get_file() + " plays and scores")

	# Difficulty grows easier with readiness.
	gs.readiness = 10.0
	_check(gs.call("difficulty_name") == "schwer", "10 % readiness = schwer")
	gs.readiness = 80.0
	_check(gs.call("difficulty_name") == "leicht", "80 % readiness = leicht")

	await _scene("res://scenes/main.tscn")
	gs.day = 4
	gs.minutes = 9 * 60
	_check(gs.call("submission_open"), "submission open Friday 09:00")
	gs.set("_pending_result", {"id": "submission", "title": "Abgabe", "completed": true, "score": 200,
			"points": 100, "notes": 0, "ratio": 0.8, "grade": "2,0", "level": "leicht"})
	gs.set("_minigame_minutes", 30)
	gs.call("apply_minigame_result")
	await _frames(5)
	_check(get_tree().current_scene.scene_file_path == "res://scenes/ui/week_summary.tscn", "submission ends week -> summary")
	_check(gs.exam_points == 20, "0.8 ratio = 20 exam points")

	gs.call("reset_week")
	_check(gs.exam_points == 20 and gs.study_points == 0 and gs.submission.is_empty(), "reset keeps exam points only")
	await _scene("res://scenes/main.tscn")
	gs.day = 4
	gs.minutes = 17 * 60 + 58
	gs.call("_advance", 5.0)
	await _frames(5)
	_check(gs.week_over and not gs.submission.get("done", true), "deadline 18:00 missed -> week over")
	_check(get_tree().current_scene.scene_file_path == "res://scenes/ui/week_summary.tscn", "missed deadline -> summary")

	# Forgetting: idle time takes back at most half of what was learned.
	gs.call("reset_week")
	gs.call("do_action", 60, 0.0, 0.0, 20.0, 0.0, 0.0)
	var learned: float = gs.readiness_earned
	var peak: float = gs.readiness
	gs.call("_forget", 100.0)
	_check(learned > 0.0 and is_equal_approx(gs.readiness, peak - learned * 0.5), "forgetting stops at 50 % of learned")
	gs.call("reset_week")
	gs.call("_forget", 100.0)
	_check(is_equal_approx(gs.readiness, 10.0), "nothing learned, nothing forgotten")

	gs.call("reset_week")
	await _scene("res://scenes/main.tscn")
	gs.day = 4
	gs.call("sleep_now")
	await _frames(5)
	_check(gs.submission.get("grade", "") == "5,0" and gs.submission.get("reason", "") == "slept", "sleeping Friday = 5,0 (slept)")

	gs.call("reset_week")
	await _scene("res://scenes/main.tscn")
	gs.day = 1
	gs.call("sleep_now")
	await get_tree().create_timer(3.0).timeout
	_check(gs.day == 2 and int(gs.minutes) <= 8 * 60 + 15, "sleeping skips to next day 08:00")

	print("SMOKE TEST: %s (%d failures)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(1 if _fails > 0 else 0)
