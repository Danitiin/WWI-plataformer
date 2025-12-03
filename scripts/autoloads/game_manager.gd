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
	#Crea archivo de configuración
	var config = ConfigFile.new()

	#Si ya existe uno, lo carga
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)

	#Audio
	#Valores por defecto
	var master_volume = config.get_value("audio", "master_volume", 0.8)
	var music_volume = config.get_value("audio", "music_volume", 0.7)
	var sfx_volume = config.get_value("audio", "sfx_volume", 0.8)

	#Convierte valores lineales a decibelios segun el slider en el bus master volume
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

	#Coge el bus Music
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
	#Convierte valores lineales a decibelios segun el slider en el bus Music
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))

	#Coge el bus SFX
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
	#Convierte valores lineales a decibelios segun el slider en el bus SFX
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))

	#Video
	var fullscreen = config.get_value("video", "fullscreen", false)
	DisplayServer.window_set_mode(
		#Cambia entre ventana y pantalla completa
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	
func load_levels():
	# Carga los datos de los niveles
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

	#Limpia el checkpoint y los coleccionables guardados
	temp_collected_items.clear()
	checkpoint_collected_items.clear()

	#limpiar checkpoint de otros niveles
	clear_other_level_checkpoints(level_id)

	#Verifica que el id del nivel sea correcto
	if level_id < 0 or level_id >= levels.size():
		push_error("Invalid level_id: " + str(level_id))
		return

	#Copia la habilidad disponible en el nivel actual
	var level_data = levels[level_id]
	current_level_ablities = level_data.abilities_in_level.duplicate()
	#Cambia a la escena precargada
	get_tree().change_scene_to_packed.call_deferred(level_scenes[level_id])

func complete_level():
	if current_level == -1:
		return

	if current_level < 0 or current_level >= levels.size():
		return

	#Guarda los coleccionbles temporales recogidos durante el nivel como coleccionables permanentementes
	for collectible_id in temp_collected_items:
		PlayerData.add_collectible(current_level, collectible_id)

	#Limpia los coleccionables temporales
	temp_collected_items.clear()

	#Marca ek nivel como completado
	if current_level not in PlayerData.completed_levels:
		PlayerData.completed_levels.append(current_level)

	#Emite la señal de nivel completado y guarda el progreso
	level_completed.emit(current_level)
	PlayerData.save_game()

#Vuelve al level selector y limpia las habilidades
func return_to_level_selector():
	current_level = -1
	current_level_ablities.clear()
	get_tree().change_scene_to_file.call_deferred("res://scenes/level_selector/level_selector_3d.tscn")

#Vuelve al menu principal y limpia las habilidades
func return_to_main_menu():
	current_level = -1
	current_level_ablities.clear()
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/main_menu/main_menu.tscn")

func get_level_abilities() -> Array[String]:
	return current_level_ablities
	
func clear_other_level_checkpoints(keep_level_id: int):
	#Busca los checkpoints de otros niveles
	var keys_to_remove = []
	for level_id in level_checkpoints.keys():
		if level_id != keep_level_id:
			keys_to_remove.append(level_id)

	#Borra los checkpoints anteriores
	for key in keys_to_remove:
		level_checkpoints.erase(key)
		checkpoint_collected_items.erase(key)
		checkpoint_unlocked_abilities.erase(key)

#Guarda los coleccionables temporales del nivel
func save_checkpoint_collectibles(level_id: int):
	checkpoint_collected_items[level_id] = temp_collected_items.duplicate()

#Guarda la habilidad desbloqueada del nivel
func save_checkpoint_abilities(level_id: int, abilities: Dictionary):
	checkpoint_unlocked_abilities[level_id] = abilities.duplicate()

func get_checkpoint_abilities(level_id: int) -> Dictionary:
	if level_id in checkpoint_unlocked_abilities:
		return checkpoint_unlocked_abilities[level_id].duplicate()
	return {}

#Restaura los coleccionables del checkpoint al morir
func restore_checkpoint_collectibles(level_id: int):
	if level_id in checkpoint_collected_items:
		temp_collected_items = checkpoint_collected_items[level_id].duplicate()
	else:
		temp_collected_items.clear()