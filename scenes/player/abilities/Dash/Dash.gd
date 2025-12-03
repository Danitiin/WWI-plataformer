extends AbilityBase

@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.20
@export var cooldown: float = 0.8

var cooldown_timer: float = 0.0
var dash_timer: float = 0.0

func physics_update(delta: float) -> bool:
	# Si hay cooldown se reduce gradualmente
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	#Si el dash esta activo
	if dash_timer > 0:
		dash_timer -= delta
		
		#A que direccion mira el player
		var dash_direction = player.get_facing_direction()
		#Aumenta la velocidad del player en la direccion que mire
		player.velocity.x = dash_direction * dash_speed
		#Anulamos la gravedad del player
		player.velocity.y = 0
		
		#Frena el jugador si se acabo el dash
		if dash_timer <= 0:
			player.velocity.x = 0
		
		return true #Dash activo
	
	return false #Dash no activo

#Si el dash no tiene cooldown
func activate():
	if cooldown_timer <= 0:
		#dash_timer = 0.2
		dash_timer = dash_duration
		#cooldown de 0.8
		cooldown_timer = cooldown

#Animación durante el dash
func get_animation_name() -> String:
	if dash_timer > 0:
		return "Dash"

	return ""
