# Area2D invisible para que se detecte cuando el jugador llega al final del nivel.
extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	#Quitar el sonido durante la pantalla de carga
	AudioServer.set_bus_mute(0, true)
		
	var complete_screen = preload("res://scenes/ui/loading_screens/level_complete.tscn").instantiate()
	get_tree().root.add_child(complete_screen)
	
	# Se espera un segundo para que se pueda leer que se completo el nivel
	await get_tree().create_timer(1.0).timeout
	
	#Volver a poner el sonido
	AudioServer.set_bus_mute(0, false)
	
	GameManager.complete_level()
	
	#se borra el checkpoint si esta activado
	if GameManager.current_level >= 0:
		GameManager.level_checkpoints.erase(GameManager.current_level)
		
	GameManager.return_to_level_selector()

	complete_screen.queue_free()