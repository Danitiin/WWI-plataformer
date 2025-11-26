extends Node2D
class_name LevelBase

@export var level_data: LevelData
var player_scene = preload("res://scenes/player/player.tscn")
var player: CharacterBody2D
var player_spawn_position: Vector2 #Pos inicial del player
var active_checkpoint_position: Vector2 
var has_active_checkpoint: bool = false

func _ready():
	player = player_scene.instantiate()
	add_child(player)

	await get_tree().process_frame
	player_spawn_position = player.global_position

	restore_checkpoint_if_exits()

	# Si hay checkpoint activo, mover al player ahí
	if has_active_checkpoint:
		player.global_position = active_checkpoint_position
		print("Player spawneado en checkpoint: ", active_checkpoint_position)

	if level_data:
		hide_collected_items()

func restore_checkpoint_if_exits():
	if not level_data:
		return
	#ver si ta guardao el checkpoint
	if GameManager.level_checkpoints.has(level_data.level_id):
		var checkpoint_pos = GameManager.level_checkpoints[level_data.level_id]
		active_checkpoint_position = checkpoint_pos
		has_active_checkpoint = true

		reactivate_checkpoint_visual(checkpoint_pos)

		print("Checkpoint restaurado en: ", checkpoint_pos)

func hide_collected_items():
	var collectibles = get_tree().get_nodes_in_group("collectibles")

	for collectible in collectibles:
		if collectible.collectible_id != null:
			#quitar si esta guardado permanentemente
			if PlayerData.is_collectible_collected(level_data.level_id, collectible.collectible_id):
				collectible.queue_free()
			elif collectible.collectible_id in GameManager.temp_collected_items:
				collectible.queue_free()

func activate_checkpoint(checkpoint_position: Vector2):
	active_checkpoint_position = checkpoint_position
	has_active_checkpoint = true

	if level_data:
		GameManager.level_checkpoints[level_data.level_id] = checkpoint_position
		GameManager.save_checkpoint_collectibles(level_data.level_id)
		print("Checkpoint guardado para el nivel: ", level_data.level_id)

	desactivate_other_checkpoints(checkpoint_position)

func desactivate_other_checkpoints(active_position: Vector2):
	var checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for checkpoint in checkpoints:
		if checkpoint.global_position != active_position:
			checkpoint.desactivate()

func reactivate_checkpoint_visual(checkpoint_position: Vector2):
	var checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for checkpoint in checkpoints:
		if checkpoint.global_position.distance_to(checkpoint_position) < 10:
			checkpoint.activate()
			break

func respawn_player():
	if level_data:
		GameManager.restore_checkpoint_collectibles(level_data.level_id)
	# Recargar la escena completa para que reaparezcan las monedas
	# Los diamantes no reaparecen porque hide_collected_items() los destruye
	get_tree().reload_current_scene()