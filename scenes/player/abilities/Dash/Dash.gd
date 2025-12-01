extends AbilityBase

@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.20
@export var cooldown: float = 0.8

var cooldown_timer: float = 0.0
var dash_timer: float = 0.0

func physics_update(delta: float) -> bool:
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if dash_timer > 0:
		dash_timer -= delta
		
		# Con el dahs activo anulamos velocidad del jugador
		var dash_direction = player.get_facing_direction()
		player.velocity.x = dash_direction * dash_speed
		player.velocity.y = 0  # Anulamos la gravedad del payer
		
		if dash_timer <= 0:
			player.velocity.x = 0
		
		return true #Dash activo
	
	return false #Dash no activo

func activate():
	if cooldown_timer <= 0:
		dash_timer = dash_duration
		cooldown_timer = cooldown

func get_animation_name() -> String:
	if dash_timer > 0:
		return "Dash"

	return ""
