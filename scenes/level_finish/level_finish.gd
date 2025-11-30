# Area2D invisible para que se detecte cuando el jugador llega al final del nivel.
extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
		
	var complete_screen = preload("res://scenes/ui/loading_screens/level_complete.tscn").instantiate()
	get_tree().root.add_child(complete_screen)
	
	await get_tree().create_timer(1.0).timeout
	
	GameManager.complete_level()
	
	if GameManager.current_level >= 0:
		GameManager.level_checkpoints.erase(GameManager.current_level)
		
	GameManager.return_to_level_selector()

	complete_screen.queue_free()