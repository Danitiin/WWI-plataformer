extends Node

signal level_completed(level_id: int)

var levels: Array[LevelData] = []
var level_scenes: Array[PackedScene] = []  # Escenas pre-cargadas
var all_abilities: Array[String] = ["Dash", "DoubleJump", "Glide"]
var current_level: int = -1
var current_level_ablities: Array[String] = []
var level_checkpoints: Dictionary = {}
var checkpoint_collected_items: Dictionary = {}
var checkpoint_unlocked_abilities: Dictionary = {}  #Guardar hab del check
var temp_collected_items: Array[int] = []

const SETTINGS_PATH = "user://settings.cfg"

func _ready():
	load_and_apply_settings()
	load_levels()
	PlayerData.load_game()

func load_and_apply_settings():
	var config = ConfigFile.new()

	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)

	#audio
	var master_volume = config.get_value("audio", "master_volume", 0.8)
	var music_volume = config.get_value("audio", "music_volume", 0.7)
	var sfx_volume = config.get_value("audio", "sfx_volume", 0.8)

	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))

	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))

	#video
	var fullscreen = config.get_value("video", "fullscreen", false)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	
func load_levels():
	levels = [
		load("res://resources/levels/level_01_data.tres"),
		load("res://resources/levels/level_02_data.tres"),
		load("res://resources/levels/level_03_data.tres")
	]

	# Pre-cargar escenas para carga instantánea
	level_scenes = [
		load("res://scenes/levels/level_01/level_01.tscn"),
		load("res://scenes/levels/level_02/level_02.tscn"),
		load("res://scenes/levels/level_03/level_03.tscn")
	]

func load_level(level_id: int):
	current_level = level_id

	temp_collected_items.clear()
	checkpoint_collected_items.clear()

	#limpiar checkp
	clear_other_level_checkpoints(level_id)

	if level_id < 0 or level_id >= levels.size():
		push_error("Invalid level_id: " + str(level_id))
		return

	var level_data = levels[level_id]
	current_level_ablities = level_data.abilities_in_level.duplicate()
	get_tree().change_scene_to_packed.call_deferred(level_scenes[level_id])

func complete_level():
	if current_level == -1:
		return

	if current_level < 0 or current_level >= levels.size():
		return

	print("COMPLETANDO NIVEL ", current_level)
	print("Coleccionables temporales a guardar: ", temp_collected_items)

	for collectible_id in temp_collected_items:
		PlayerData.add_collectible(current_level, collectible_id)
		print("Guardado coleccionable ID: ", collectible_id)

	temp_collected_items.clear()

	if current_level not in PlayerData.completed_levels:
		PlayerData.completed_levels.append(current_level)

	print("Coleccionables guardados en PlayerData para nivel ", current_level, ": ", PlayerData.get_collected_items_for_level(current_level))
	print("FIN COMPLETAR NIVEL")

	level_completed.emit(current_level)
	PlayerData.save_game()

func return_to_level_selector():
	current_level = -1
	current_level_ablities.clear()
	get_tree().change_scene_to_file.call_deferred("res://scenes/level_selector/level_selector_3d.tscn")

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
		checkpoint_collected_items.erase(key)
		checkpoint_unlocked_abilities.erase(key)

	if keys_to_remove.size() > 0:
		print("Checkp limpiados", keys_to_remove)

func save_checkpoint_collectibles(level_id: int):
	checkpoint_collected_items[level_id] = temp_collected_items.duplicate()
	print("CHECKPOINT GUARDADO")
	print("Nivel: ", level_id)
	print("Coleccionables guardados en checkpoint: ", checkpoint_collected_items[level_id])
	print("temp_collected_items actual: ", temp_collected_items)

func save_checkpoint_abilities(level_id: int, abilities: Dictionary):
	checkpoint_unlocked_abilities[level_id] = abilities.duplicate()
	print("Habilidades guardadas en checkpoint para nivel ", level_id, ": ", abilities)

func get_checkpoint_abilities(level_id: int) -> Dictionary:
	if level_id in checkpoint_unlocked_abilities:
		return checkpoint_unlocked_abilities[level_id].duplicate()
	return {}

func restore_checkpoint_collectibles(level_id: int):
	print("RESTAURANDO CHECKPOINT")
	print("Nivel: ", level_id)
	print("temp_collected_items antes de restaurar: ", temp_collected_items)

	if level_id in checkpoint_collected_items:
		temp_collected_items = checkpoint_collected_items[level_id].duplicate()
		print("Coleccionables restaurados del checkpoint: ", temp_collected_items)
	else:
		temp_collected_items.clear()
		print("No habia checkpoint, temp_collected_items limpiado")

	print("temp_collected_items despues de restaurar: ", temp_collected_items)