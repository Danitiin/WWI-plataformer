extends Node
const DEBUG_MODE = false

var completed_levels: Array[int] = []
var collected_items: Dictionary = {}
var intro_dialogue_seen: bool = false

const SAVE_PATH = "user://savegame.save"

func save_game():
	if DEBUG_MODE:
		print("Guardado desactivado")
		return

	#Progreso del jugador
	var save_dict = {
		"completed_levels": completed_levels,
		"collected_items": collected_items,
		"intro_dialogue_seen": intro_dialogue_seen
	}
	#Guarda el progreso del jugador
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	save_file.store_var(save_dict)
	save_file.close()

func load_game():
	if DEBUG_MODE:
		print("Carga desactivado")
		return

	#Ver si existe el archivo de guardado
	if not FileAccess.file_exists(SAVE_PATH):
		return

	#Lee el archivo de guardado
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var save_dict = save_file.get_var()
	save_file.close()
	
	#Cargan los datos que estan guardados en el archivo
	#Si se corrompe el archivo se guardan datos por defecto
	completed_levels = save_dict.get("completed_levels", [])
	collected_items = save_dict.get("collected_items", {})
	intro_dialogue_seen = save_dict.get("intro_dialogue_seen", false)
	
func add_collectible(level_id: int, collectible_id: int):
	#Si el nivel no existe en collected_items
	if level_id not in collected_items:
		#Crea un array vacio
		collected_items[level_id] = []

	#Si el coleccionable no esta en el array
	if collectible_id not in collected_items[level_id]:
		#Añade el collectible y guarda
		collected_items[level_id].append(collectible_id)
		save_game()

#Cuantos coleccionables hay en un nivel (para hud)
func get_collected_count(level_id: int):
	if level_id in collected_items:
		return collected_items[level_id].size()
	return 0

#Verifica si un coleccionable en especifico esta recogido
func is_collectible_collected(level_id: int, collectible_id: int) -> bool:
	if level_id in collected_items:
		return collectible_id in collected_items[level_id]
	return false

#Verifica si un nivel esta completado
func is_level_completed(level_id: int) -> bool:
	return level_id in completed_levels

#Cuantos coleccionables hay en un nivel (para la señal de los portales)
func get_collected_items_for_level(level_id: int) -> Array:
	if level_id in collected_items:
		return collected_items[level_id]
		
	return []