class_name Portal
extends Interactable
## A door to another place (scene). Costs `minutes` like any action (e.g. the
## stairs), then loads `target_scene` and puts the player at the Marker3D
## `Spawns/<target_spawn>` there. `note` is shown after arriving.

@export_file("*.tscn") var target_scene := ""
@export var target_spawn := ""


func interact() -> void:
	if GameState.do_action(minutes, d_energy, d_satiety, d_readiness, d_stress, d_money):
		GameState.travel(target_scene, target_spawn, note)
