class_name SleepSpot
extends Interactable
## Own bed: go to sleep now and end the day (GameState.sleep_now). On the
## submission day without a submission this ends the week, the prompt warns.


func prompt() -> String:
	var s := GameState.submission_info()
	if GameState.day == int(s["day"]) and not GameState.submission.get("done", false):
		return "[E] " + title + "  ·  Woche beenden – Abgabe wird verpasst!"
	return "[E] " + title + "  ·  Tag beenden, morgen 08:00"


func interact() -> void:
	GameState.sleep_now()
