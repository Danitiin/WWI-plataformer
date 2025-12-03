extends Area2D

@onready var sprite = $AnimatedSprite2D

func _ready():
	sprite.play("idle")
	#Señal para saber cuando algo toca el item
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	#Si es el player
	if body.is_in_group("player"):
		# Desbloquear habilidad temporal
		if body.has_method("unlock_temp_ability"):
			body.unlock_temp_ability("Dash")

		# Efecto visual/sonido
		if has_node("PotionSound"):
			$PotionSound.play()
		sprite.play("obtain")
		await sprite.animation_finished
		queue_free()