extends Node

signal level_completed(level_id: int)

var levels: Array[LevelData] = []
var all_abilities: Array[String] = ["Dash", "DoubleJump", "GroundPound"]
var current_level: int = -1
var current_level_ablities: Array[String] = []
var level_checkpoints: Dictionary = {}
var temp_collected_items: Array[int] = []

func _ready():
	load_levels()
	PlayerData.load_game()
	
func load_levels():
	levels = [
		load("res://resources/levels/level_01_data.tres"),
		load("res://resources/levels/level_02_data.tres"),
		load("res://resources/levels/level_03_data.tres")
	]

func load_level(level_id: int):
	current_level = level_id

	temp_collected_items.clear()

	#limpiar checkp
	clear_other_level_checkpoints(level_id)

	#🗣️🔥 Solo para el nivel de prueba🗣️🔥
	if level_id == -1:
		current_level_ablities = all_abilities.duplicate()
		get_tree().change_scene_to_file.call_deferred("res://level_test.tscn")
		return
	#🗣️🔥 Solo para el nivel de prueba🗣️🔥

	if level_id < 0 or level_id >= levels.size():
		push_error("Invalid level_id: " + str(level_id))
		return

	var level_data = levels[level_id]
	current_level_ablities = level_data.abilities_in_level.duplicate()
	get_tree().change_scene_to_file.call_deferred(level_data.scene_path)

func complete_level():
	if current_level == -1:
		return

	if current_level < 0 or current_level >= levels.size():
		return

	for collectible_id in temp_collected_items:
		PlayerData.add_collectible(current_level, collectible_id)

	temp_collected_items.clear()

	if current_level not in PlayerData.completed_levels:
		PlayerData.completed_levels.append(current_level)

	level_completed.emit(current_level)
	PlayerData.save_game()

func return_to_level_selector():
	current_level = -1
	current_level_ablities.clear()
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/level_selector/scene_3d.tscn")

func return_to_main_menu():
	current_level = -1
	current_level_ablities.clear()
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/main_menu/main_menu.tscn")

func get_level_abilities() -> Array[String]:
	return current_level_ablities
	
func clear_other_level_checkpoints(keep_level_id: int):
	var keys_to_remove = []
	for level_id in level_checkpoints.keys():
		if level_id != keep_level_id:
			keys_to_remove.append(level_id)

	for key in keys_to_remove:
		level_checkpoints.erase(key)

	if keys_to_remove.size() > 0:
		print("Checkp limpiados", keys_to_remove)
