extends Area2D

@onready var sprite = $AnimatedSprite2D

func _ready():
	sprite.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Desbloquear habilidad temporal
		if body.has_method("unlock_temp_ability"):
			body.unlock_temp_ability("Dash")

		# Efecto visual/sonido
		sprite.play("obtain")
		await sprite.animation_finished
		queue_free()