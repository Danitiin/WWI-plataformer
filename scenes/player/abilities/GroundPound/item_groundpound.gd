extends Area2D

func _ready():
	$AnimatedSprite2D.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Desbloquear habilidad temporal (ahora es Glide)
		if body.has_method("unlock_temp_ability"):
			body.unlock_temp_ability("Glide")

		# Efecto visual/sonido
		queue_free()