extends Node
const DEBUG_MODE = true

var completed_levels: Array[int] = []
var collected_items: Dictionary = {}

const SAVE_PATH = "user://savegame.save"

func save_game():
	if DEBUG_MODE:
		print("Guardado desactivado")
		return

	var save_dict = {
		"completed_levels": completed_levels,
		"collected_items": collected_items
	}
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	save_file.store_var(save_dict)
	save_file.close()

func load_game():
	if DEBUG_MODE:
		print("Carga desactivado")
		return

	if not FileAccess.file_exists(SAVE_PATH):
		return
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var save_dict = save_file.get_var()
	save_file.close()
	
	completed_levels = save_dict.get("completed_levels", [])
	collected_items = save_dict.get("collected_items", {})
	
func add_collectible(level_id: int, collectible_id: int):
	if level_id not in collected_items:
		collected_items[level_id] = []
		
	if collectible_id not in collected_items[level_id]:
		collected_items[level_id].append(collectible_id)
		save_game()

func get_collected_count(level_id: int):
	if level_id in collected_items:
		return collected_items[level_id].size()
	return 0

func is_collectible_collected(level_id: int, collectible_id: int) -> bool:
	if level_id in collected_items:
		return collectible_id in collected_items[level_id]
	return false

func is_level_completed(level_id: int) -> bool:
	return level_id in completed_levels

func get_collected_items_for_level(level_id: int) -> Array:
	if level_id in collected_items:
		return collected_items[level_id]
		
	return []
