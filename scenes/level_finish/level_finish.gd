# Area2D invisible para que se detecte cuando el jugador llega al final del nivel.
extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	# Guardar coleccionables y completar nivel
	GameManager.complete_level()

	# Borrar checkpoint del nivel actual
	if GameManager.current_level >= 0:
		GameManager.level_checkpoints.erase(GameManager.current_level)

	# Volver al mapilla
	GameManager.return_to_level_selector()
