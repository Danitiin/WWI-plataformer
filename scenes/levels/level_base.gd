extends Node2D
class_name LevelBase

@export var level_data: LevelData
var player_scene = preload("res://scenes/player/player_level/player.tscn")
var player: CharacterBody2D
var player_spawn_position: Vector2 #Pos inicial del player
var active_checkpoint_position: Vector2
var has_active_checkpoint: bool = false

func _ready():
	#Configurar música en loop
	if has_node("LevelMusic"):
		var music = $LevelMusic
		music.finished.connect(_on_music_finished)

	#Se añade al player como hijo
	player = player_scene.instantiate()
	add_child(player)

	await get_tree().process_frame

	var spawn_marker = $PlayerSpawn
	#Si hay spawn_marker mueve al player a esa posicion y la guarda
	if spawn_marker:
		player.global_position = spawn_marker.global_position
		player_spawn_position = spawn_marker.global_position
	else:
		player_spawn_position = player.global_position
		push_warning("PlayerSpawn marker no encontrado, usando posición por defecto")

	#quitar habilidades al entrar al nivel
	if player.has_method("clear_temp_abilities"):
		player.clear_temp_abilities()

	restore_checkpoint_if_exits()

	# Si hay checkpoint activo, mover al player ahí y restaurar habilidades
	if has_active_checkpoint:
		player.global_position = active_checkpoint_position

		#Si hay datos y el player tiene el metodo indicado se restaura la habilidad
		if level_data and player.has_method("restore_unlocked_abilities"):
			#Vemos que habilidad del nivel es y si esta activa (si el player recogio la pocion)
			var saved_abilities = GameManager.get_checkpoint_abilities(level_data.level_id)
			if not saved_abilities.is_empty():
				#Se restaura la habilidad
				player.restore_unlocked_abilities(saved_abilities)

	if level_data:
		hide_collected_items()

func restore_checkpoint_if_exits():
	if not level_data:
		return
	#Ver el checkpoint esta guardado
	if GameManager.level_checkpoints.has(level_data.level_id):
		#Guardamos la posicion del checkpoint y lo activamos
		var checkpoint_pos = GameManager.level_checkpoints[level_data.level_id]
		active_checkpoint_position = checkpoint_pos
		has_active_checkpoint = true

		reactivate_checkpoint_visual(checkpoint_pos)

func hide_collected_items():
	var collectibles = get_tree().get_nodes_in_group("collectibles")

	for collectible in collectibles:
		if collectible.collectible_id != null:
			"""
			Si hay algun coleccionable guardado (temporal o permanente) este se destruye
			asi si activamos un checkpoint con un coleccionable recogido este no volvera a
			aparecer siempre y cuando el player aparezca desde el checkpoint
			"""
			if PlayerData.is_collectible_collected(level_data.level_id, collectible.collectible_id):
				collectible.queue_free()
			elif collectible.collectible_id in GameManager.temp_collected_items:
				collectible.queue_free()

func activate_checkpoint(checkpoint_position: Vector2, player_node = null):
	active_checkpoint_position = checkpoint_position
	has_active_checkpoint = true

	if level_data:
		#Guarda la posicion del checkpoint y los coleccionables recogidos hasta ese momento
		GameManager.level_checkpoints[level_data.level_id] = checkpoint_position
		GameManager.save_checkpoint_collectibles(level_data.level_id)

		#Guarda la habilidad que hayamos recogido hasta ese momento
		if player_node and player_node.has_method("get_unlocked_abilities"):
			var abilities = player_node.get_unlocked_abilities()
			GameManager.save_checkpoint_abilities(level_data.level_id, abilities)

	desactivate_other_checkpoints(checkpoint_position)

#Desactiva otros checkpoints activos
func desactivate_other_checkpoints(active_position: Vector2):
	var checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for checkpoint in checkpoints:
		if checkpoint.global_position != active_position:
			checkpoint.desactivate()

#Al morir (si habia un checkpoint activo) se reactiva el checkpoint
func reactivate_checkpoint_visual(checkpoint_position: Vector2):
	var checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for checkpoint in checkpoints:
		if checkpoint.global_position.distance_to(checkpoint_position) < 10:
			if checkpoint.has_method("activate"):
				checkpoint.activate(null)
			break

func respawn_player():
	if level_data:
		GameManager.restore_checkpoint_collectibles(level_data.level_id)
	# Recargar la escena completa para que reaparezcan las monedas
	# Los diamantes no reaparecen porque hide_collected_items() los destruye
	get_tree().reload_current_scene()

func _on_music_finished():
	if has_node("LevelMusic"):
		$LevelMusic.play()